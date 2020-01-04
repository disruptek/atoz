
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Relational Database Service
## version: 2013-09-09
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"; CIDRIP: string = ""): Recallable =
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
  Call_PostCopyDBSnapshot_602095 = ref object of OpenApiRestCall_601373
proc url_PostCopyDBSnapshot_602097(protocol: Scheme; host: string; base: string;
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

proc validate_PostCopyDBSnapshot_602096(path: JsonNode; query: JsonNode;
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
  var valid_602098 = query.getOrDefault("Action")
  valid_602098 = validateParameter(valid_602098, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_602098 != nil:
    section.add "Action", valid_602098
  var valid_602099 = query.getOrDefault("Version")
  valid_602099 = validateParameter(valid_602099, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602099 != nil:
    section.add "Version", valid_602099
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602100 = header.getOrDefault("X-Amz-Signature")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Signature", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Content-Sha256", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Date")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Date", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Credential")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Credential", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Security-Token")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Security-Token", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Algorithm")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Algorithm", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-SignedHeaders", valid_602106
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_602107 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_602107 = validateParameter(valid_602107, JString, required = true,
                                 default = nil)
  if valid_602107 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_602107
  var valid_602108 = formData.getOrDefault("Tags")
  valid_602108 = validateParameter(valid_602108, JArray, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "Tags", valid_602108
  var valid_602109 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_602109 = validateParameter(valid_602109, JString, required = true,
                                 default = nil)
  if valid_602109 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_602109
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602110: Call_PostCopyDBSnapshot_602095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602110.validator(path, query, header, formData, body)
  let scheme = call_602110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602110.url(scheme.get, call_602110.host, call_602110.base,
                         call_602110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602110, url, valid)

proc call*(call_602111: Call_PostCopyDBSnapshot_602095;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_602112 = newJObject()
  var formData_602113 = newJObject()
  add(formData_602113, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_602112, "Action", newJString(Action))
  if Tags != nil:
    formData_602113.add "Tags", Tags
  add(formData_602113, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_602112, "Version", newJString(Version))
  result = call_602111.call(nil, query_602112, nil, formData_602113, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_602095(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_602096, base: "/",
    url: url_PostCopyDBSnapshot_602097, schemes: {Scheme.Https, Scheme.Http})
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
  ##   Tags: JArray
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
  var valid_602081 = query.getOrDefault("Tags")
  valid_602081 = validateParameter(valid_602081, JArray, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "Tags", valid_602081
  var valid_602082 = query.getOrDefault("Action")
  valid_602082 = validateParameter(valid_602082, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_602082 != nil:
    section.add "Action", valid_602082
  var valid_602083 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_602083 = validateParameter(valid_602083, JString, required = true,
                                 default = nil)
  if valid_602083 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_602083
  var valid_602084 = query.getOrDefault("Version")
  valid_602084 = validateParameter(valid_602084, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602084 != nil:
    section.add "Version", valid_602084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602085 = header.getOrDefault("X-Amz-Signature")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Signature", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Content-Sha256", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Date")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Date", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Credential")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Credential", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Security-Token")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Security-Token", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Algorithm")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Algorithm", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-SignedHeaders", valid_602091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602092: Call_GetCopyDBSnapshot_602077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602092.validator(path, query, header, formData, body)
  let scheme = call_602092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602092.url(scheme.get, call_602092.host, call_602092.base,
                         call_602092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602092, url, valid)

proc call*(call_602093: Call_GetCopyDBSnapshot_602077;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_602094 = newJObject()
  add(query_602094, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  if Tags != nil:
    query_602094.add "Tags", Tags
  add(query_602094, "Action", newJString(Action))
  add(query_602094, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_602094, "Version", newJString(Version))
  result = call_602093.call(nil, query_602094, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_602077(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_602078,
    base: "/", url: url_GetCopyDBSnapshot_602079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_602154 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBInstance_602156(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBInstance_602155(path: JsonNode; query: JsonNode;
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
  var valid_602157 = query.getOrDefault("Action")
  valid_602157 = validateParameter(valid_602157, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_602157 != nil:
    section.add "Action", valid_602157
  var valid_602158 = query.getOrDefault("Version")
  valid_602158 = validateParameter(valid_602158, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602158 != nil:
    section.add "Version", valid_602158
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602159 = header.getOrDefault("X-Amz-Signature")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Signature", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Content-Sha256", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Date")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Date", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Credential")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Credential", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Security-Token")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Security-Token", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Algorithm")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Algorithm", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-SignedHeaders", valid_602165
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
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   CharacterSetName: JString
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: JInt (required)
  section = newJObject()
  var valid_602166 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "PreferredMaintenanceWindow", valid_602166
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_602167 = formData.getOrDefault("DBInstanceClass")
  valid_602167 = validateParameter(valid_602167, JString, required = true,
                                 default = nil)
  if valid_602167 != nil:
    section.add "DBInstanceClass", valid_602167
  var valid_602168 = formData.getOrDefault("Port")
  valid_602168 = validateParameter(valid_602168, JInt, required = false, default = nil)
  if valid_602168 != nil:
    section.add "Port", valid_602168
  var valid_602169 = formData.getOrDefault("PreferredBackupWindow")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "PreferredBackupWindow", valid_602169
  var valid_602170 = formData.getOrDefault("MasterUserPassword")
  valid_602170 = validateParameter(valid_602170, JString, required = true,
                                 default = nil)
  if valid_602170 != nil:
    section.add "MasterUserPassword", valid_602170
  var valid_602171 = formData.getOrDefault("MultiAZ")
  valid_602171 = validateParameter(valid_602171, JBool, required = false, default = nil)
  if valid_602171 != nil:
    section.add "MultiAZ", valid_602171
  var valid_602172 = formData.getOrDefault("MasterUsername")
  valid_602172 = validateParameter(valid_602172, JString, required = true,
                                 default = nil)
  if valid_602172 != nil:
    section.add "MasterUsername", valid_602172
  var valid_602173 = formData.getOrDefault("DBParameterGroupName")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "DBParameterGroupName", valid_602173
  var valid_602174 = formData.getOrDefault("EngineVersion")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "EngineVersion", valid_602174
  var valid_602175 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_602175 = validateParameter(valid_602175, JArray, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "VpcSecurityGroupIds", valid_602175
  var valid_602176 = formData.getOrDefault("AvailabilityZone")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "AvailabilityZone", valid_602176
  var valid_602177 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602177 = validateParameter(valid_602177, JInt, required = false, default = nil)
  if valid_602177 != nil:
    section.add "BackupRetentionPeriod", valid_602177
  var valid_602178 = formData.getOrDefault("Engine")
  valid_602178 = validateParameter(valid_602178, JString, required = true,
                                 default = nil)
  if valid_602178 != nil:
    section.add "Engine", valid_602178
  var valid_602179 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602179 = validateParameter(valid_602179, JBool, required = false, default = nil)
  if valid_602179 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602179
  var valid_602180 = formData.getOrDefault("DBName")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "DBName", valid_602180
  var valid_602181 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602181 = validateParameter(valid_602181, JString, required = true,
                                 default = nil)
  if valid_602181 != nil:
    section.add "DBInstanceIdentifier", valid_602181
  var valid_602182 = formData.getOrDefault("Iops")
  valid_602182 = validateParameter(valid_602182, JInt, required = false, default = nil)
  if valid_602182 != nil:
    section.add "Iops", valid_602182
  var valid_602183 = formData.getOrDefault("PubliclyAccessible")
  valid_602183 = validateParameter(valid_602183, JBool, required = false, default = nil)
  if valid_602183 != nil:
    section.add "PubliclyAccessible", valid_602183
  var valid_602184 = formData.getOrDefault("LicenseModel")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "LicenseModel", valid_602184
  var valid_602185 = formData.getOrDefault("Tags")
  valid_602185 = validateParameter(valid_602185, JArray, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "Tags", valid_602185
  var valid_602186 = formData.getOrDefault("DBSubnetGroupName")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "DBSubnetGroupName", valid_602186
  var valid_602187 = formData.getOrDefault("OptionGroupName")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "OptionGroupName", valid_602187
  var valid_602188 = formData.getOrDefault("CharacterSetName")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "CharacterSetName", valid_602188
  var valid_602189 = formData.getOrDefault("DBSecurityGroups")
  valid_602189 = validateParameter(valid_602189, JArray, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "DBSecurityGroups", valid_602189
  var valid_602190 = formData.getOrDefault("AllocatedStorage")
  valid_602190 = validateParameter(valid_602190, JInt, required = true, default = nil)
  if valid_602190 != nil:
    section.add "AllocatedStorage", valid_602190
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602191: Call_PostCreateDBInstance_602154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602191.validator(path, query, header, formData, body)
  let scheme = call_602191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602191.url(scheme.get, call_602191.host, call_602191.base,
                         call_602191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602191, url, valid)

proc call*(call_602192: Call_PostCreateDBInstance_602154; DBInstanceClass: string;
          MasterUserPassword: string; MasterUsername: string; Engine: string;
          DBInstanceIdentifier: string; AllocatedStorage: int;
          PreferredMaintenanceWindow: string = ""; Port: int = 0;
          PreferredBackupWindow: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZone: string = "";
          BackupRetentionPeriod: int = 0; AutoMinorVersionUpgrade: bool = false;
          DBName: string = ""; Iops: int = 0; PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstance"; LicenseModel: string = "";
          Tags: JsonNode = nil; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; CharacterSetName: string = "";
          Version: string = "2013-09-09"; DBSecurityGroups: JsonNode = nil): Recallable =
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
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   CharacterSetName: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: int (required)
  var query_602193 = newJObject()
  var formData_602194 = newJObject()
  add(formData_602194, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_602194, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602194, "Port", newJInt(Port))
  add(formData_602194, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_602194, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_602194, "MultiAZ", newJBool(MultiAZ))
  add(formData_602194, "MasterUsername", newJString(MasterUsername))
  add(formData_602194, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602194, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_602194.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_602194, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_602194, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_602194, "Engine", newJString(Engine))
  add(formData_602194, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_602194, "DBName", newJString(DBName))
  add(formData_602194, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602194, "Iops", newJInt(Iops))
  add(formData_602194, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602193, "Action", newJString(Action))
  add(formData_602194, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_602194.add "Tags", Tags
  add(formData_602194, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602194, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602194, "CharacterSetName", newJString(CharacterSetName))
  add(query_602193, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_602194.add "DBSecurityGroups", DBSecurityGroups
  add(formData_602194, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_602192.call(nil, query_602193, nil, formData_602194, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_602154(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_602155, base: "/",
    url: url_PostCreateDBInstance_602156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_602114 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBInstance_602116(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBInstance_602115(path: JsonNode; query: JsonNode;
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
  ##   Tags: JArray
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
  var valid_602117 = query.getOrDefault("Version")
  valid_602117 = validateParameter(valid_602117, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602117 != nil:
    section.add "Version", valid_602117
  var valid_602118 = query.getOrDefault("DBName")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "DBName", valid_602118
  var valid_602119 = query.getOrDefault("Engine")
  valid_602119 = validateParameter(valid_602119, JString, required = true,
                                 default = nil)
  if valid_602119 != nil:
    section.add "Engine", valid_602119
  var valid_602120 = query.getOrDefault("DBParameterGroupName")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "DBParameterGroupName", valid_602120
  var valid_602121 = query.getOrDefault("CharacterSetName")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "CharacterSetName", valid_602121
  var valid_602122 = query.getOrDefault("Tags")
  valid_602122 = validateParameter(valid_602122, JArray, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "Tags", valid_602122
  var valid_602123 = query.getOrDefault("LicenseModel")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "LicenseModel", valid_602123
  var valid_602124 = query.getOrDefault("DBInstanceIdentifier")
  valid_602124 = validateParameter(valid_602124, JString, required = true,
                                 default = nil)
  if valid_602124 != nil:
    section.add "DBInstanceIdentifier", valid_602124
  var valid_602125 = query.getOrDefault("MasterUsername")
  valid_602125 = validateParameter(valid_602125, JString, required = true,
                                 default = nil)
  if valid_602125 != nil:
    section.add "MasterUsername", valid_602125
  var valid_602126 = query.getOrDefault("BackupRetentionPeriod")
  valid_602126 = validateParameter(valid_602126, JInt, required = false, default = nil)
  if valid_602126 != nil:
    section.add "BackupRetentionPeriod", valid_602126
  var valid_602127 = query.getOrDefault("EngineVersion")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "EngineVersion", valid_602127
  var valid_602128 = query.getOrDefault("Action")
  valid_602128 = validateParameter(valid_602128, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_602128 != nil:
    section.add "Action", valid_602128
  var valid_602129 = query.getOrDefault("MultiAZ")
  valid_602129 = validateParameter(valid_602129, JBool, required = false, default = nil)
  if valid_602129 != nil:
    section.add "MultiAZ", valid_602129
  var valid_602130 = query.getOrDefault("DBSecurityGroups")
  valid_602130 = validateParameter(valid_602130, JArray, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "DBSecurityGroups", valid_602130
  var valid_602131 = query.getOrDefault("Port")
  valid_602131 = validateParameter(valid_602131, JInt, required = false, default = nil)
  if valid_602131 != nil:
    section.add "Port", valid_602131
  var valid_602132 = query.getOrDefault("VpcSecurityGroupIds")
  valid_602132 = validateParameter(valid_602132, JArray, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "VpcSecurityGroupIds", valid_602132
  var valid_602133 = query.getOrDefault("MasterUserPassword")
  valid_602133 = validateParameter(valid_602133, JString, required = true,
                                 default = nil)
  if valid_602133 != nil:
    section.add "MasterUserPassword", valid_602133
  var valid_602134 = query.getOrDefault("AvailabilityZone")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "AvailabilityZone", valid_602134
  var valid_602135 = query.getOrDefault("OptionGroupName")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "OptionGroupName", valid_602135
  var valid_602136 = query.getOrDefault("DBSubnetGroupName")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "DBSubnetGroupName", valid_602136
  var valid_602137 = query.getOrDefault("AllocatedStorage")
  valid_602137 = validateParameter(valid_602137, JInt, required = true, default = nil)
  if valid_602137 != nil:
    section.add "AllocatedStorage", valid_602137
  var valid_602138 = query.getOrDefault("DBInstanceClass")
  valid_602138 = validateParameter(valid_602138, JString, required = true,
                                 default = nil)
  if valid_602138 != nil:
    section.add "DBInstanceClass", valid_602138
  var valid_602139 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "PreferredMaintenanceWindow", valid_602139
  var valid_602140 = query.getOrDefault("PreferredBackupWindow")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "PreferredBackupWindow", valid_602140
  var valid_602141 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602141 = validateParameter(valid_602141, JBool, required = false, default = nil)
  if valid_602141 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602141
  var valid_602142 = query.getOrDefault("Iops")
  valid_602142 = validateParameter(valid_602142, JInt, required = false, default = nil)
  if valid_602142 != nil:
    section.add "Iops", valid_602142
  var valid_602143 = query.getOrDefault("PubliclyAccessible")
  valid_602143 = validateParameter(valid_602143, JBool, required = false, default = nil)
  if valid_602143 != nil:
    section.add "PubliclyAccessible", valid_602143
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602144 = header.getOrDefault("X-Amz-Signature")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Signature", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Content-Sha256", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Date")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Date", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Credential")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Credential", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Security-Token")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Security-Token", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Algorithm")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Algorithm", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-SignedHeaders", valid_602150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602151: Call_GetCreateDBInstance_602114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602151.validator(path, query, header, formData, body)
  let scheme = call_602151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602151.url(scheme.get, call_602151.host, call_602151.base,
                         call_602151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602151, url, valid)

proc call*(call_602152: Call_GetCreateDBInstance_602114; Engine: string;
          DBInstanceIdentifier: string; MasterUsername: string;
          MasterUserPassword: string; AllocatedStorage: int;
          DBInstanceClass: string; Version: string = "2013-09-09";
          DBName: string = ""; DBParameterGroupName: string = "";
          CharacterSetName: string = ""; Tags: JsonNode = nil;
          LicenseModel: string = ""; BackupRetentionPeriod: int = 0;
          EngineVersion: string = ""; Action: string = "CreateDBInstance";
          MultiAZ: bool = false; DBSecurityGroups: JsonNode = nil; Port: int = 0;
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
  ##   Tags: JArray
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
  var query_602153 = newJObject()
  add(query_602153, "Version", newJString(Version))
  add(query_602153, "DBName", newJString(DBName))
  add(query_602153, "Engine", newJString(Engine))
  add(query_602153, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602153, "CharacterSetName", newJString(CharacterSetName))
  if Tags != nil:
    query_602153.add "Tags", Tags
  add(query_602153, "LicenseModel", newJString(LicenseModel))
  add(query_602153, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602153, "MasterUsername", newJString(MasterUsername))
  add(query_602153, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602153, "EngineVersion", newJString(EngineVersion))
  add(query_602153, "Action", newJString(Action))
  add(query_602153, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_602153.add "DBSecurityGroups", DBSecurityGroups
  add(query_602153, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_602153.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_602153, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_602153, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_602153, "OptionGroupName", newJString(OptionGroupName))
  add(query_602153, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602153, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_602153, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602153, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_602153, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602153, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602153, "Iops", newJInt(Iops))
  add(query_602153, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_602152.call(nil, query_602153, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_602114(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_602115, base: "/",
    url: url_GetCreateDBInstance_602116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_602221 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBInstanceReadReplica_602223(protocol: Scheme; host: string;
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

proc validate_PostCreateDBInstanceReadReplica_602222(path: JsonNode;
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
  var valid_602224 = query.getOrDefault("Action")
  valid_602224 = validateParameter(valid_602224, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_602224 != nil:
    section.add "Action", valid_602224
  var valid_602225 = query.getOrDefault("Version")
  valid_602225 = validateParameter(valid_602225, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602225 != nil:
    section.add "Version", valid_602225
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602226 = header.getOrDefault("X-Amz-Signature")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Signature", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Content-Sha256", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Date")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Date", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Credential")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Credential", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Security-Token")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Security-Token", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Algorithm")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Algorithm", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-SignedHeaders", valid_602232
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
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_602233 = formData.getOrDefault("Port")
  valid_602233 = validateParameter(valid_602233, JInt, required = false, default = nil)
  if valid_602233 != nil:
    section.add "Port", valid_602233
  var valid_602234 = formData.getOrDefault("DBInstanceClass")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "DBInstanceClass", valid_602234
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_602235 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_602235 = validateParameter(valid_602235, JString, required = true,
                                 default = nil)
  if valid_602235 != nil:
    section.add "SourceDBInstanceIdentifier", valid_602235
  var valid_602236 = formData.getOrDefault("AvailabilityZone")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "AvailabilityZone", valid_602236
  var valid_602237 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602237 = validateParameter(valid_602237, JBool, required = false, default = nil)
  if valid_602237 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602237
  var valid_602238 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602238 = validateParameter(valid_602238, JString, required = true,
                                 default = nil)
  if valid_602238 != nil:
    section.add "DBInstanceIdentifier", valid_602238
  var valid_602239 = formData.getOrDefault("Iops")
  valid_602239 = validateParameter(valid_602239, JInt, required = false, default = nil)
  if valid_602239 != nil:
    section.add "Iops", valid_602239
  var valid_602240 = formData.getOrDefault("PubliclyAccessible")
  valid_602240 = validateParameter(valid_602240, JBool, required = false, default = nil)
  if valid_602240 != nil:
    section.add "PubliclyAccessible", valid_602240
  var valid_602241 = formData.getOrDefault("Tags")
  valid_602241 = validateParameter(valid_602241, JArray, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "Tags", valid_602241
  var valid_602242 = formData.getOrDefault("DBSubnetGroupName")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "DBSubnetGroupName", valid_602242
  var valid_602243 = formData.getOrDefault("OptionGroupName")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "OptionGroupName", valid_602243
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602244: Call_PostCreateDBInstanceReadReplica_602221;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602244.validator(path, query, header, formData, body)
  let scheme = call_602244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602244.url(scheme.get, call_602244.host, call_602244.base,
                         call_602244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602244, url, valid)

proc call*(call_602245: Call_PostCreateDBInstanceReadReplica_602221;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; AvailabilityZone: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstanceReadReplica"; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          Version: string = "2013-09-09"): Recallable =
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
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_602246 = newJObject()
  var formData_602247 = newJObject()
  add(formData_602247, "Port", newJInt(Port))
  add(formData_602247, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602247, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_602247, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_602247, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_602247, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602247, "Iops", newJInt(Iops))
  add(formData_602247, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602246, "Action", newJString(Action))
  if Tags != nil:
    formData_602247.add "Tags", Tags
  add(formData_602247, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602247, "OptionGroupName", newJString(OptionGroupName))
  add(query_602246, "Version", newJString(Version))
  result = call_602245.call(nil, query_602246, nil, formData_602247, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_602221(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_602222, base: "/",
    url: url_PostCreateDBInstanceReadReplica_602223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_602195 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBInstanceReadReplica_602197(protocol: Scheme; host: string;
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

proc validate_GetCreateDBInstanceReadReplica_602196(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   DBInstanceIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBInstanceIdentifier: JString (required)
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
  var valid_602198 = query.getOrDefault("Tags")
  valid_602198 = validateParameter(valid_602198, JArray, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "Tags", valid_602198
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602199 = query.getOrDefault("DBInstanceIdentifier")
  valid_602199 = validateParameter(valid_602199, JString, required = true,
                                 default = nil)
  if valid_602199 != nil:
    section.add "DBInstanceIdentifier", valid_602199
  var valid_602200 = query.getOrDefault("Action")
  valid_602200 = validateParameter(valid_602200, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_602200 != nil:
    section.add "Action", valid_602200
  var valid_602201 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_602201 = validateParameter(valid_602201, JString, required = true,
                                 default = nil)
  if valid_602201 != nil:
    section.add "SourceDBInstanceIdentifier", valid_602201
  var valid_602202 = query.getOrDefault("Port")
  valid_602202 = validateParameter(valid_602202, JInt, required = false, default = nil)
  if valid_602202 != nil:
    section.add "Port", valid_602202
  var valid_602203 = query.getOrDefault("AvailabilityZone")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "AvailabilityZone", valid_602203
  var valid_602204 = query.getOrDefault("OptionGroupName")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "OptionGroupName", valid_602204
  var valid_602205 = query.getOrDefault("DBSubnetGroupName")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "DBSubnetGroupName", valid_602205
  var valid_602206 = query.getOrDefault("Version")
  valid_602206 = validateParameter(valid_602206, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602206 != nil:
    section.add "Version", valid_602206
  var valid_602207 = query.getOrDefault("DBInstanceClass")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "DBInstanceClass", valid_602207
  var valid_602208 = query.getOrDefault("PubliclyAccessible")
  valid_602208 = validateParameter(valid_602208, JBool, required = false, default = nil)
  if valid_602208 != nil:
    section.add "PubliclyAccessible", valid_602208
  var valid_602209 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602209 = validateParameter(valid_602209, JBool, required = false, default = nil)
  if valid_602209 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602209
  var valid_602210 = query.getOrDefault("Iops")
  valid_602210 = validateParameter(valid_602210, JInt, required = false, default = nil)
  if valid_602210 != nil:
    section.add "Iops", valid_602210
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602211 = header.getOrDefault("X-Amz-Signature")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Signature", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Content-Sha256", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Date")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Date", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Credential")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Credential", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Security-Token")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Security-Token", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Algorithm")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Algorithm", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-SignedHeaders", valid_602217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602218: Call_GetCreateDBInstanceReadReplica_602195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602218.validator(path, query, header, formData, body)
  let scheme = call_602218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602218.url(scheme.get, call_602218.host, call_602218.base,
                         call_602218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602218, url, valid)

proc call*(call_602219: Call_GetCreateDBInstanceReadReplica_602195;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBInstanceReadReplica";
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-09-09";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBInstanceIdentifier: string (required)
  ##   Port: int
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_602220 = newJObject()
  if Tags != nil:
    query_602220.add "Tags", Tags
  add(query_602220, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602220, "Action", newJString(Action))
  add(query_602220, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_602220, "Port", newJInt(Port))
  add(query_602220, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_602220, "OptionGroupName", newJString(OptionGroupName))
  add(query_602220, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602220, "Version", newJString(Version))
  add(query_602220, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602220, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602220, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602220, "Iops", newJInt(Iops))
  result = call_602219.call(nil, query_602220, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_602195(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_602196, base: "/",
    url: url_GetCreateDBInstanceReadReplica_602197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_602267 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBParameterGroup_602269(protocol: Scheme; host: string;
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

proc validate_PostCreateDBParameterGroup_602268(path: JsonNode; query: JsonNode;
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
  var valid_602270 = query.getOrDefault("Action")
  valid_602270 = validateParameter(valid_602270, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_602270 != nil:
    section.add "Action", valid_602270
  var valid_602271 = query.getOrDefault("Version")
  valid_602271 = validateParameter(valid_602271, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602271 != nil:
    section.add "Version", valid_602271
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602272 = header.getOrDefault("X-Amz-Signature")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Signature", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Content-Sha256", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Date")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Date", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Credential")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Credential", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Security-Token")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Security-Token", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Algorithm")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Algorithm", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-SignedHeaders", valid_602278
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_602279 = formData.getOrDefault("Description")
  valid_602279 = validateParameter(valid_602279, JString, required = true,
                                 default = nil)
  if valid_602279 != nil:
    section.add "Description", valid_602279
  var valid_602280 = formData.getOrDefault("DBParameterGroupName")
  valid_602280 = validateParameter(valid_602280, JString, required = true,
                                 default = nil)
  if valid_602280 != nil:
    section.add "DBParameterGroupName", valid_602280
  var valid_602281 = formData.getOrDefault("Tags")
  valid_602281 = validateParameter(valid_602281, JArray, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "Tags", valid_602281
  var valid_602282 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602282 = validateParameter(valid_602282, JString, required = true,
                                 default = nil)
  if valid_602282 != nil:
    section.add "DBParameterGroupFamily", valid_602282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602283: Call_PostCreateDBParameterGroup_602267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602283.validator(path, query, header, formData, body)
  let scheme = call_602283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602283.url(scheme.get, call_602283.host, call_602283.base,
                         call_602283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602283, url, valid)

proc call*(call_602284: Call_PostCreateDBParameterGroup_602267;
          Description: string; DBParameterGroupName: string;
          DBParameterGroupFamily: string;
          Action: string = "CreateDBParameterGroup"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_602285 = newJObject()
  var formData_602286 = newJObject()
  add(formData_602286, "Description", newJString(Description))
  add(formData_602286, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602285, "Action", newJString(Action))
  if Tags != nil:
    formData_602286.add "Tags", Tags
  add(query_602285, "Version", newJString(Version))
  add(formData_602286, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_602284.call(nil, query_602285, nil, formData_602286, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_602267(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_602268, base: "/",
    url: url_PostCreateDBParameterGroup_602269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_602248 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBParameterGroup_602250(protocol: Scheme; host: string;
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

proc validate_GetCreateDBParameterGroup_602249(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupFamily: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   Description: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602251 = query.getOrDefault("DBParameterGroupFamily")
  valid_602251 = validateParameter(valid_602251, JString, required = true,
                                 default = nil)
  if valid_602251 != nil:
    section.add "DBParameterGroupFamily", valid_602251
  var valid_602252 = query.getOrDefault("DBParameterGroupName")
  valid_602252 = validateParameter(valid_602252, JString, required = true,
                                 default = nil)
  if valid_602252 != nil:
    section.add "DBParameterGroupName", valid_602252
  var valid_602253 = query.getOrDefault("Tags")
  valid_602253 = validateParameter(valid_602253, JArray, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "Tags", valid_602253
  var valid_602254 = query.getOrDefault("Action")
  valid_602254 = validateParameter(valid_602254, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_602254 != nil:
    section.add "Action", valid_602254
  var valid_602255 = query.getOrDefault("Description")
  valid_602255 = validateParameter(valid_602255, JString, required = true,
                                 default = nil)
  if valid_602255 != nil:
    section.add "Description", valid_602255
  var valid_602256 = query.getOrDefault("Version")
  valid_602256 = validateParameter(valid_602256, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602256 != nil:
    section.add "Version", valid_602256
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602257 = header.getOrDefault("X-Amz-Signature")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Signature", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Content-Sha256", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Date")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Date", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Credential")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Credential", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Security-Token")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Security-Token", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Algorithm")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Algorithm", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-SignedHeaders", valid_602263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602264: Call_GetCreateDBParameterGroup_602248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602264.validator(path, query, header, formData, body)
  let scheme = call_602264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602264.url(scheme.get, call_602264.host, call_602264.base,
                         call_602264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602264, url, valid)

proc call*(call_602265: Call_GetCreateDBParameterGroup_602248;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Description: string (required)
  ##   Version: string (required)
  var query_602266 = newJObject()
  add(query_602266, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_602266, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_602266.add "Tags", Tags
  add(query_602266, "Action", newJString(Action))
  add(query_602266, "Description", newJString(Description))
  add(query_602266, "Version", newJString(Version))
  result = call_602265.call(nil, query_602266, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_602248(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_602249, base: "/",
    url: url_GetCreateDBParameterGroup_602250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_602305 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBSecurityGroup_602307(protocol: Scheme; host: string;
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

proc validate_PostCreateDBSecurityGroup_602306(path: JsonNode; query: JsonNode;
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
  var valid_602308 = query.getOrDefault("Action")
  valid_602308 = validateParameter(valid_602308, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_602308 != nil:
    section.add "Action", valid_602308
  var valid_602309 = query.getOrDefault("Version")
  valid_602309 = validateParameter(valid_602309, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602309 != nil:
    section.add "Version", valid_602309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602310 = header.getOrDefault("X-Amz-Signature")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Signature", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Content-Sha256", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Date")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Date", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Credential")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Credential", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Security-Token")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Security-Token", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Algorithm")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Algorithm", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-SignedHeaders", valid_602316
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_602317 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_602317 = validateParameter(valid_602317, JString, required = true,
                                 default = nil)
  if valid_602317 != nil:
    section.add "DBSecurityGroupDescription", valid_602317
  var valid_602318 = formData.getOrDefault("DBSecurityGroupName")
  valid_602318 = validateParameter(valid_602318, JString, required = true,
                                 default = nil)
  if valid_602318 != nil:
    section.add "DBSecurityGroupName", valid_602318
  var valid_602319 = formData.getOrDefault("Tags")
  valid_602319 = validateParameter(valid_602319, JArray, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "Tags", valid_602319
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602320: Call_PostCreateDBSecurityGroup_602305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602320.validator(path, query, header, formData, body)
  let scheme = call_602320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602320.url(scheme.get, call_602320.host, call_602320.base,
                         call_602320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602320, url, valid)

proc call*(call_602321: Call_PostCreateDBSecurityGroup_602305;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_602322 = newJObject()
  var formData_602323 = newJObject()
  add(formData_602323, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_602323, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602322, "Action", newJString(Action))
  if Tags != nil:
    formData_602323.add "Tags", Tags
  add(query_602322, "Version", newJString(Version))
  result = call_602321.call(nil, query_602322, nil, formData_602323, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_602305(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_602306, base: "/",
    url: url_PostCreateDBSecurityGroup_602307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_602287 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBSecurityGroup_602289(protocol: Scheme; host: string;
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

proc validate_GetCreateDBSecurityGroup_602288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602290 = query.getOrDefault("DBSecurityGroupName")
  valid_602290 = validateParameter(valid_602290, JString, required = true,
                                 default = nil)
  if valid_602290 != nil:
    section.add "DBSecurityGroupName", valid_602290
  var valid_602291 = query.getOrDefault("Tags")
  valid_602291 = validateParameter(valid_602291, JArray, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "Tags", valid_602291
  var valid_602292 = query.getOrDefault("DBSecurityGroupDescription")
  valid_602292 = validateParameter(valid_602292, JString, required = true,
                                 default = nil)
  if valid_602292 != nil:
    section.add "DBSecurityGroupDescription", valid_602292
  var valid_602293 = query.getOrDefault("Action")
  valid_602293 = validateParameter(valid_602293, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_602293 != nil:
    section.add "Action", valid_602293
  var valid_602294 = query.getOrDefault("Version")
  valid_602294 = validateParameter(valid_602294, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602294 != nil:
    section.add "Version", valid_602294
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602295 = header.getOrDefault("X-Amz-Signature")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Signature", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Content-Sha256", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Date")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Date", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Credential")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Credential", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Security-Token")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Security-Token", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Algorithm")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Algorithm", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-SignedHeaders", valid_602301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602302: Call_GetCreateDBSecurityGroup_602287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602302.validator(path, query, header, formData, body)
  let scheme = call_602302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602302.url(scheme.get, call_602302.host, call_602302.base,
                         call_602302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602302, url, valid)

proc call*(call_602303: Call_GetCreateDBSecurityGroup_602287;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602304 = newJObject()
  add(query_602304, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    query_602304.add "Tags", Tags
  add(query_602304, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_602304, "Action", newJString(Action))
  add(query_602304, "Version", newJString(Version))
  result = call_602303.call(nil, query_602304, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_602287(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_602288, base: "/",
    url: url_GetCreateDBSecurityGroup_602289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_602342 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBSnapshot_602344(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSnapshot_602343(path: JsonNode; query: JsonNode;
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
  var valid_602345 = query.getOrDefault("Action")
  valid_602345 = validateParameter(valid_602345, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_602345 != nil:
    section.add "Action", valid_602345
  var valid_602346 = query.getOrDefault("Version")
  valid_602346 = validateParameter(valid_602346, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602346 != nil:
    section.add "Version", valid_602346
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602347 = header.getOrDefault("X-Amz-Signature")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Signature", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Content-Sha256", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Date")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Date", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Credential")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Credential", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Security-Token")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Security-Token", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Algorithm")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Algorithm", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-SignedHeaders", valid_602353
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602354 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602354 = validateParameter(valid_602354, JString, required = true,
                                 default = nil)
  if valid_602354 != nil:
    section.add "DBInstanceIdentifier", valid_602354
  var valid_602355 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602355 = validateParameter(valid_602355, JString, required = true,
                                 default = nil)
  if valid_602355 != nil:
    section.add "DBSnapshotIdentifier", valid_602355
  var valid_602356 = formData.getOrDefault("Tags")
  valid_602356 = validateParameter(valid_602356, JArray, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "Tags", valid_602356
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602357: Call_PostCreateDBSnapshot_602342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602357.validator(path, query, header, formData, body)
  let scheme = call_602357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602357.url(scheme.get, call_602357.host, call_602357.base,
                         call_602357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602357, url, valid)

proc call*(call_602358: Call_PostCreateDBSnapshot_602342;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_602359 = newJObject()
  var formData_602360 = newJObject()
  add(formData_602360, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602360, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602359, "Action", newJString(Action))
  if Tags != nil:
    formData_602360.add "Tags", Tags
  add(query_602359, "Version", newJString(Version))
  result = call_602358.call(nil, query_602359, nil, formData_602360, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_602342(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_602343, base: "/",
    url: url_PostCreateDBSnapshot_602344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_602324 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBSnapshot_602326(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSnapshot_602325(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_602327 = query.getOrDefault("Tags")
  valid_602327 = validateParameter(valid_602327, JArray, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "Tags", valid_602327
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602328 = query.getOrDefault("DBInstanceIdentifier")
  valid_602328 = validateParameter(valid_602328, JString, required = true,
                                 default = nil)
  if valid_602328 != nil:
    section.add "DBInstanceIdentifier", valid_602328
  var valid_602329 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602329 = validateParameter(valid_602329, JString, required = true,
                                 default = nil)
  if valid_602329 != nil:
    section.add "DBSnapshotIdentifier", valid_602329
  var valid_602330 = query.getOrDefault("Action")
  valid_602330 = validateParameter(valid_602330, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_602330 != nil:
    section.add "Action", valid_602330
  var valid_602331 = query.getOrDefault("Version")
  valid_602331 = validateParameter(valid_602331, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602331 != nil:
    section.add "Version", valid_602331
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602332 = header.getOrDefault("X-Amz-Signature")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Signature", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Content-Sha256", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Date")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Date", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Credential")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Credential", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-Security-Token")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Security-Token", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Algorithm")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Algorithm", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-SignedHeaders", valid_602338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602339: Call_GetCreateDBSnapshot_602324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602339.validator(path, query, header, formData, body)
  let scheme = call_602339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602339.url(scheme.get, call_602339.host, call_602339.base,
                         call_602339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602339, url, valid)

proc call*(call_602340: Call_GetCreateDBSnapshot_602324;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602341 = newJObject()
  if Tags != nil:
    query_602341.add "Tags", Tags
  add(query_602341, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602341, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602341, "Action", newJString(Action))
  add(query_602341, "Version", newJString(Version))
  result = call_602340.call(nil, query_602341, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_602324(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_602325, base: "/",
    url: url_GetCreateDBSnapshot_602326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_602380 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBSubnetGroup_602382(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSubnetGroup_602381(path: JsonNode; query: JsonNode;
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
  var valid_602383 = query.getOrDefault("Action")
  valid_602383 = validateParameter(valid_602383, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_602383 != nil:
    section.add "Action", valid_602383
  var valid_602384 = query.getOrDefault("Version")
  valid_602384 = validateParameter(valid_602384, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602384 != nil:
    section.add "Version", valid_602384
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602385 = header.getOrDefault("X-Amz-Signature")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Signature", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Content-Sha256", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Date")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Date", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-Credential")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-Credential", valid_602388
  var valid_602389 = header.getOrDefault("X-Amz-Security-Token")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "X-Amz-Security-Token", valid_602389
  var valid_602390 = header.getOrDefault("X-Amz-Algorithm")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Algorithm", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-SignedHeaders", valid_602391
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_602392 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_602392 = validateParameter(valid_602392, JString, required = true,
                                 default = nil)
  if valid_602392 != nil:
    section.add "DBSubnetGroupDescription", valid_602392
  var valid_602393 = formData.getOrDefault("Tags")
  valid_602393 = validateParameter(valid_602393, JArray, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "Tags", valid_602393
  var valid_602394 = formData.getOrDefault("DBSubnetGroupName")
  valid_602394 = validateParameter(valid_602394, JString, required = true,
                                 default = nil)
  if valid_602394 != nil:
    section.add "DBSubnetGroupName", valid_602394
  var valid_602395 = formData.getOrDefault("SubnetIds")
  valid_602395 = validateParameter(valid_602395, JArray, required = true, default = nil)
  if valid_602395 != nil:
    section.add "SubnetIds", valid_602395
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602396: Call_PostCreateDBSubnetGroup_602380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602396.validator(path, query, header, formData, body)
  let scheme = call_602396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602396.url(scheme.get, call_602396.host, call_602396.base,
                         call_602396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602396, url, valid)

proc call*(call_602397: Call_PostCreateDBSubnetGroup_602380;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          SubnetIds: JsonNode; Action: string = "CreateDBSubnetGroup";
          Tags: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_602398 = newJObject()
  var formData_602399 = newJObject()
  add(formData_602399, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602398, "Action", newJString(Action))
  if Tags != nil:
    formData_602399.add "Tags", Tags
  add(formData_602399, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602398, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_602399.add "SubnetIds", SubnetIds
  result = call_602397.call(nil, query_602398, nil, formData_602399, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_602380(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_602381, base: "/",
    url: url_PostCreateDBSubnetGroup_602382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_602361 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBSubnetGroup_602363(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSubnetGroup_602362(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   SubnetIds: JArray (required)
  ##   Action: JString (required)
  ##   DBSubnetGroupDescription: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_602364 = query.getOrDefault("Tags")
  valid_602364 = validateParameter(valid_602364, JArray, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "Tags", valid_602364
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_602365 = query.getOrDefault("SubnetIds")
  valid_602365 = validateParameter(valid_602365, JArray, required = true, default = nil)
  if valid_602365 != nil:
    section.add "SubnetIds", valid_602365
  var valid_602366 = query.getOrDefault("Action")
  valid_602366 = validateParameter(valid_602366, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_602366 != nil:
    section.add "Action", valid_602366
  var valid_602367 = query.getOrDefault("DBSubnetGroupDescription")
  valid_602367 = validateParameter(valid_602367, JString, required = true,
                                 default = nil)
  if valid_602367 != nil:
    section.add "DBSubnetGroupDescription", valid_602367
  var valid_602368 = query.getOrDefault("DBSubnetGroupName")
  valid_602368 = validateParameter(valid_602368, JString, required = true,
                                 default = nil)
  if valid_602368 != nil:
    section.add "DBSubnetGroupName", valid_602368
  var valid_602369 = query.getOrDefault("Version")
  valid_602369 = validateParameter(valid_602369, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602377: Call_GetCreateDBSubnetGroup_602361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602377.validator(path, query, header, formData, body)
  let scheme = call_602377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602377.url(scheme.get, call_602377.host, call_602377.base,
                         call_602377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602377, url, valid)

proc call*(call_602378: Call_GetCreateDBSubnetGroup_602361; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Tags: JArray
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_602379 = newJObject()
  if Tags != nil:
    query_602379.add "Tags", Tags
  if SubnetIds != nil:
    query_602379.add "SubnetIds", SubnetIds
  add(query_602379, "Action", newJString(Action))
  add(query_602379, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602379, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602379, "Version", newJString(Version))
  result = call_602378.call(nil, query_602379, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_602361(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_602362, base: "/",
    url: url_GetCreateDBSubnetGroup_602363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_602422 = ref object of OpenApiRestCall_601373
proc url_PostCreateEventSubscription_602424(protocol: Scheme; host: string;
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

proc validate_PostCreateEventSubscription_602423(path: JsonNode; query: JsonNode;
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
  var valid_602425 = query.getOrDefault("Action")
  valid_602425 = validateParameter(valid_602425, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_602425 != nil:
    section.add "Action", valid_602425
  var valid_602426 = query.getOrDefault("Version")
  valid_602426 = validateParameter(valid_602426, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602426 != nil:
    section.add "Version", valid_602426
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602427 = header.getOrDefault("X-Amz-Signature")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Signature", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Content-Sha256", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Date")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Date", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-Credential")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Credential", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-Security-Token")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Security-Token", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Algorithm")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Algorithm", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-SignedHeaders", valid_602433
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIds: JArray
  ##   SnsTopicArn: JString (required)
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  ##   Tags: JArray
  section = newJObject()
  var valid_602434 = formData.getOrDefault("SourceIds")
  valid_602434 = validateParameter(valid_602434, JArray, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "SourceIds", valid_602434
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_602435 = formData.getOrDefault("SnsTopicArn")
  valid_602435 = validateParameter(valid_602435, JString, required = true,
                                 default = nil)
  if valid_602435 != nil:
    section.add "SnsTopicArn", valid_602435
  var valid_602436 = formData.getOrDefault("Enabled")
  valid_602436 = validateParameter(valid_602436, JBool, required = false, default = nil)
  if valid_602436 != nil:
    section.add "Enabled", valid_602436
  var valid_602437 = formData.getOrDefault("SubscriptionName")
  valid_602437 = validateParameter(valid_602437, JString, required = true,
                                 default = nil)
  if valid_602437 != nil:
    section.add "SubscriptionName", valid_602437
  var valid_602438 = formData.getOrDefault("SourceType")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "SourceType", valid_602438
  var valid_602439 = formData.getOrDefault("EventCategories")
  valid_602439 = validateParameter(valid_602439, JArray, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "EventCategories", valid_602439
  var valid_602440 = formData.getOrDefault("Tags")
  valid_602440 = validateParameter(valid_602440, JArray, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "Tags", valid_602440
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602441: Call_PostCreateEventSubscription_602422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602441.validator(path, query, header, formData, body)
  let scheme = call_602441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602441.url(scheme.get, call_602441.host, call_602441.base,
                         call_602441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602441, url, valid)

proc call*(call_602442: Call_PostCreateEventSubscription_602422;
          SnsTopicArn: string; SubscriptionName: string; SourceIds: JsonNode = nil;
          Enabled: bool = false; SourceType: string = "";
          EventCategories: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateEventSubscription
  ##   SourceIds: JArray
  ##   SnsTopicArn: string (required)
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_602443 = newJObject()
  var formData_602444 = newJObject()
  if SourceIds != nil:
    formData_602444.add "SourceIds", SourceIds
  add(formData_602444, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_602444, "Enabled", newJBool(Enabled))
  add(formData_602444, "SubscriptionName", newJString(SubscriptionName))
  add(formData_602444, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_602444.add "EventCategories", EventCategories
  add(query_602443, "Action", newJString(Action))
  if Tags != nil:
    formData_602444.add "Tags", Tags
  add(query_602443, "Version", newJString(Version))
  result = call_602442.call(nil, query_602443, nil, formData_602444, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_602422(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_602423, base: "/",
    url: url_PostCreateEventSubscription_602424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_602400 = ref object of OpenApiRestCall_601373
proc url_GetCreateEventSubscription_602402(protocol: Scheme; host: string;
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

proc validate_GetCreateEventSubscription_602401(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   SourceType: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   EventCategories: JArray
  ##   SourceIds: JArray
  ##   Action: JString (required)
  ##   SnsTopicArn: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_602403 = query.getOrDefault("Tags")
  valid_602403 = validateParameter(valid_602403, JArray, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "Tags", valid_602403
  var valid_602404 = query.getOrDefault("SourceType")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "SourceType", valid_602404
  var valid_602405 = query.getOrDefault("Enabled")
  valid_602405 = validateParameter(valid_602405, JBool, required = false, default = nil)
  if valid_602405 != nil:
    section.add "Enabled", valid_602405
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_602406 = query.getOrDefault("SubscriptionName")
  valid_602406 = validateParameter(valid_602406, JString, required = true,
                                 default = nil)
  if valid_602406 != nil:
    section.add "SubscriptionName", valid_602406
  var valid_602407 = query.getOrDefault("EventCategories")
  valid_602407 = validateParameter(valid_602407, JArray, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "EventCategories", valid_602407
  var valid_602408 = query.getOrDefault("SourceIds")
  valid_602408 = validateParameter(valid_602408, JArray, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "SourceIds", valid_602408
  var valid_602409 = query.getOrDefault("Action")
  valid_602409 = validateParameter(valid_602409, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_602409 != nil:
    section.add "Action", valid_602409
  var valid_602410 = query.getOrDefault("SnsTopicArn")
  valid_602410 = validateParameter(valid_602410, JString, required = true,
                                 default = nil)
  if valid_602410 != nil:
    section.add "SnsTopicArn", valid_602410
  var valid_602411 = query.getOrDefault("Version")
  valid_602411 = validateParameter(valid_602411, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602411 != nil:
    section.add "Version", valid_602411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602412 = header.getOrDefault("X-Amz-Signature")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Signature", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Content-Sha256", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Date")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Date", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Credential")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Credential", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Security-Token")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Security-Token", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Algorithm")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Algorithm", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-SignedHeaders", valid_602418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602419: Call_GetCreateEventSubscription_602400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602419.validator(path, query, header, formData, body)
  let scheme = call_602419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602419.url(scheme.get, call_602419.host, call_602419.base,
                         call_602419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602419, url, valid)

proc call*(call_602420: Call_GetCreateEventSubscription_602400;
          SubscriptionName: string; SnsTopicArn: string; Tags: JsonNode = nil;
          SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil; SourceIds: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Version: string = "2013-09-09"): Recallable =
  ## getCreateEventSubscription
  ##   Tags: JArray
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   SourceIds: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string (required)
  ##   Version: string (required)
  var query_602421 = newJObject()
  if Tags != nil:
    query_602421.add "Tags", Tags
  add(query_602421, "SourceType", newJString(SourceType))
  add(query_602421, "Enabled", newJBool(Enabled))
  add(query_602421, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_602421.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_602421.add "SourceIds", SourceIds
  add(query_602421, "Action", newJString(Action))
  add(query_602421, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_602421, "Version", newJString(Version))
  result = call_602420.call(nil, query_602421, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_602400(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_602401, base: "/",
    url: url_GetCreateEventSubscription_602402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_602465 = ref object of OpenApiRestCall_601373
proc url_PostCreateOptionGroup_602467(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateOptionGroup_602466(path: JsonNode; query: JsonNode;
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
  var valid_602468 = query.getOrDefault("Action")
  valid_602468 = validateParameter(valid_602468, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_602468 != nil:
    section.add "Action", valid_602468
  var valid_602469 = query.getOrDefault("Version")
  valid_602469 = validateParameter(valid_602469, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602469 != nil:
    section.add "Version", valid_602469
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602470 = header.getOrDefault("X-Amz-Signature")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Signature", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Content-Sha256", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-Date")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-Date", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Credential")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Credential", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-Security-Token")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Security-Token", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Algorithm")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Algorithm", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-SignedHeaders", valid_602476
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   Tags: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_602477 = formData.getOrDefault("OptionGroupDescription")
  valid_602477 = validateParameter(valid_602477, JString, required = true,
                                 default = nil)
  if valid_602477 != nil:
    section.add "OptionGroupDescription", valid_602477
  var valid_602478 = formData.getOrDefault("EngineName")
  valid_602478 = validateParameter(valid_602478, JString, required = true,
                                 default = nil)
  if valid_602478 != nil:
    section.add "EngineName", valid_602478
  var valid_602479 = formData.getOrDefault("MajorEngineVersion")
  valid_602479 = validateParameter(valid_602479, JString, required = true,
                                 default = nil)
  if valid_602479 != nil:
    section.add "MajorEngineVersion", valid_602479
  var valid_602480 = formData.getOrDefault("Tags")
  valid_602480 = validateParameter(valid_602480, JArray, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "Tags", valid_602480
  var valid_602481 = formData.getOrDefault("OptionGroupName")
  valid_602481 = validateParameter(valid_602481, JString, required = true,
                                 default = nil)
  if valid_602481 != nil:
    section.add "OptionGroupName", valid_602481
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602482: Call_PostCreateOptionGroup_602465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602482.validator(path, query, header, formData, body)
  let scheme = call_602482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602482.url(scheme.get, call_602482.host, call_602482.base,
                         call_602482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602482, url, valid)

proc call*(call_602483: Call_PostCreateOptionGroup_602465;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; OptionGroupName: string;
          Action: string = "CreateOptionGroup"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateOptionGroup
  ##   OptionGroupDescription: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_602484 = newJObject()
  var formData_602485 = newJObject()
  add(formData_602485, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_602485, "EngineName", newJString(EngineName))
  add(formData_602485, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_602484, "Action", newJString(Action))
  if Tags != nil:
    formData_602485.add "Tags", Tags
  add(formData_602485, "OptionGroupName", newJString(OptionGroupName))
  add(query_602484, "Version", newJString(Version))
  result = call_602483.call(nil, query_602484, nil, formData_602485, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_602465(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_602466, base: "/",
    url: url_PostCreateOptionGroup_602467, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_602445 = ref object of OpenApiRestCall_601373
proc url_GetCreateOptionGroup_602447(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateOptionGroup_602446(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  ##   MajorEngineVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EngineName` field"
  var valid_602448 = query.getOrDefault("EngineName")
  valid_602448 = validateParameter(valid_602448, JString, required = true,
                                 default = nil)
  if valid_602448 != nil:
    section.add "EngineName", valid_602448
  var valid_602449 = query.getOrDefault("OptionGroupDescription")
  valid_602449 = validateParameter(valid_602449, JString, required = true,
                                 default = nil)
  if valid_602449 != nil:
    section.add "OptionGroupDescription", valid_602449
  var valid_602450 = query.getOrDefault("Tags")
  valid_602450 = validateParameter(valid_602450, JArray, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "Tags", valid_602450
  var valid_602451 = query.getOrDefault("Action")
  valid_602451 = validateParameter(valid_602451, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_602451 != nil:
    section.add "Action", valid_602451
  var valid_602452 = query.getOrDefault("OptionGroupName")
  valid_602452 = validateParameter(valid_602452, JString, required = true,
                                 default = nil)
  if valid_602452 != nil:
    section.add "OptionGroupName", valid_602452
  var valid_602453 = query.getOrDefault("Version")
  valid_602453 = validateParameter(valid_602453, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602453 != nil:
    section.add "Version", valid_602453
  var valid_602454 = query.getOrDefault("MajorEngineVersion")
  valid_602454 = validateParameter(valid_602454, JString, required = true,
                                 default = nil)
  if valid_602454 != nil:
    section.add "MajorEngineVersion", valid_602454
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602455 = header.getOrDefault("X-Amz-Signature")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Signature", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Content-Sha256", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-Date")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Date", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Credential")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Credential", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-Security-Token")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Security-Token", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Algorithm")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Algorithm", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-SignedHeaders", valid_602461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602462: Call_GetCreateOptionGroup_602445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602462.validator(path, query, header, formData, body)
  let scheme = call_602462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602462.url(scheme.get, call_602462.host, call_602462.base,
                         call_602462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602462, url, valid)

proc call*(call_602463: Call_GetCreateOptionGroup_602445; EngineName: string;
          OptionGroupDescription: string; OptionGroupName: string;
          MajorEngineVersion: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getCreateOptionGroup
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   MajorEngineVersion: string (required)
  var query_602464 = newJObject()
  add(query_602464, "EngineName", newJString(EngineName))
  add(query_602464, "OptionGroupDescription", newJString(OptionGroupDescription))
  if Tags != nil:
    query_602464.add "Tags", Tags
  add(query_602464, "Action", newJString(Action))
  add(query_602464, "OptionGroupName", newJString(OptionGroupName))
  add(query_602464, "Version", newJString(Version))
  add(query_602464, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602463.call(nil, query_602464, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_602445(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_602446, base: "/",
    url: url_GetCreateOptionGroup_602447, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_602504 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBInstance_602506(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBInstance_602505(path: JsonNode; query: JsonNode;
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
  var valid_602507 = query.getOrDefault("Action")
  valid_602507 = validateParameter(valid_602507, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_602507 != nil:
    section.add "Action", valid_602507
  var valid_602508 = query.getOrDefault("Version")
  valid_602508 = validateParameter(valid_602508, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602516 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602516 = validateParameter(valid_602516, JString, required = true,
                                 default = nil)
  if valid_602516 != nil:
    section.add "DBInstanceIdentifier", valid_602516
  var valid_602517 = formData.getOrDefault("SkipFinalSnapshot")
  valid_602517 = validateParameter(valid_602517, JBool, required = false, default = nil)
  if valid_602517 != nil:
    section.add "SkipFinalSnapshot", valid_602517
  var valid_602518 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_602518
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602519: Call_PostDeleteDBInstance_602504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602519.validator(path, query, header, formData, body)
  let scheme = call_602519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602519.url(scheme.get, call_602519.host, call_602519.base,
                         call_602519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602519, url, valid)

proc call*(call_602520: Call_PostDeleteDBInstance_602504;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_602521 = newJObject()
  var formData_602522 = newJObject()
  add(formData_602522, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602521, "Action", newJString(Action))
  add(formData_602522, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_602522, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_602521, "Version", newJString(Version))
  result = call_602520.call(nil, query_602521, nil, formData_602522, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_602504(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_602505, base: "/",
    url: url_PostDeleteDBInstance_602506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_602486 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBInstance_602488(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBInstance_602487(path: JsonNode; query: JsonNode;
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
  var valid_602489 = query.getOrDefault("DBInstanceIdentifier")
  valid_602489 = validateParameter(valid_602489, JString, required = true,
                                 default = nil)
  if valid_602489 != nil:
    section.add "DBInstanceIdentifier", valid_602489
  var valid_602490 = query.getOrDefault("SkipFinalSnapshot")
  valid_602490 = validateParameter(valid_602490, JBool, required = false, default = nil)
  if valid_602490 != nil:
    section.add "SkipFinalSnapshot", valid_602490
  var valid_602491 = query.getOrDefault("Action")
  valid_602491 = validateParameter(valid_602491, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_602491 != nil:
    section.add "Action", valid_602491
  var valid_602492 = query.getOrDefault("Version")
  valid_602492 = validateParameter(valid_602492, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602492 != nil:
    section.add "Version", valid_602492
  var valid_602493 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_602493
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602494 = header.getOrDefault("X-Amz-Signature")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Signature", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Content-Sha256", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Date")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Date", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Credential")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Credential", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Security-Token")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Security-Token", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-Algorithm")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Algorithm", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-SignedHeaders", valid_602500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602501: Call_GetDeleteDBInstance_602486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602501.validator(path, query, header, formData, body)
  let scheme = call_602501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602501.url(scheme.get, call_602501.host, call_602501.base,
                         call_602501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602501, url, valid)

proc call*(call_602502: Call_GetDeleteDBInstance_602486;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2013-09-09";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_602503 = newJObject()
  add(query_602503, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602503, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_602503, "Action", newJString(Action))
  add(query_602503, "Version", newJString(Version))
  add(query_602503, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_602502.call(nil, query_602503, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_602486(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_602487, base: "/",
    url: url_GetDeleteDBInstance_602488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_602539 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBParameterGroup_602541(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBParameterGroup_602540(path: JsonNode; query: JsonNode;
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
  var valid_602542 = query.getOrDefault("Action")
  valid_602542 = validateParameter(valid_602542, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_602542 != nil:
    section.add "Action", valid_602542
  var valid_602543 = query.getOrDefault("Version")
  valid_602543 = validateParameter(valid_602543, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602543 != nil:
    section.add "Version", valid_602543
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602544 = header.getOrDefault("X-Amz-Signature")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Signature", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Content-Sha256", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-Date")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Date", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-Credential")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-Credential", valid_602547
  var valid_602548 = header.getOrDefault("X-Amz-Security-Token")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-Security-Token", valid_602548
  var valid_602549 = header.getOrDefault("X-Amz-Algorithm")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-Algorithm", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-SignedHeaders", valid_602550
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602551 = formData.getOrDefault("DBParameterGroupName")
  valid_602551 = validateParameter(valid_602551, JString, required = true,
                                 default = nil)
  if valid_602551 != nil:
    section.add "DBParameterGroupName", valid_602551
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602552: Call_PostDeleteDBParameterGroup_602539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602552.validator(path, query, header, formData, body)
  let scheme = call_602552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602552.url(scheme.get, call_602552.host, call_602552.base,
                         call_602552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602552, url, valid)

proc call*(call_602553: Call_PostDeleteDBParameterGroup_602539;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602554 = newJObject()
  var formData_602555 = newJObject()
  add(formData_602555, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602554, "Action", newJString(Action))
  add(query_602554, "Version", newJString(Version))
  result = call_602553.call(nil, query_602554, nil, formData_602555, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_602539(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_602540, base: "/",
    url: url_PostDeleteDBParameterGroup_602541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_602523 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBParameterGroup_602525(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBParameterGroup_602524(path: JsonNode; query: JsonNode;
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
  var valid_602526 = query.getOrDefault("DBParameterGroupName")
  valid_602526 = validateParameter(valid_602526, JString, required = true,
                                 default = nil)
  if valid_602526 != nil:
    section.add "DBParameterGroupName", valid_602526
  var valid_602527 = query.getOrDefault("Action")
  valid_602527 = validateParameter(valid_602527, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_602527 != nil:
    section.add "Action", valid_602527
  var valid_602528 = query.getOrDefault("Version")
  valid_602528 = validateParameter(valid_602528, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602528 != nil:
    section.add "Version", valid_602528
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602529 = header.getOrDefault("X-Amz-Signature")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-Signature", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-Content-Sha256", valid_602530
  var valid_602531 = header.getOrDefault("X-Amz-Date")
  valid_602531 = validateParameter(valid_602531, JString, required = false,
                                 default = nil)
  if valid_602531 != nil:
    section.add "X-Amz-Date", valid_602531
  var valid_602532 = header.getOrDefault("X-Amz-Credential")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "X-Amz-Credential", valid_602532
  var valid_602533 = header.getOrDefault("X-Amz-Security-Token")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-Security-Token", valid_602533
  var valid_602534 = header.getOrDefault("X-Amz-Algorithm")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Algorithm", valid_602534
  var valid_602535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-SignedHeaders", valid_602535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602536: Call_GetDeleteDBParameterGroup_602523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602536.validator(path, query, header, formData, body)
  let scheme = call_602536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602536.url(scheme.get, call_602536.host, call_602536.base,
                         call_602536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602536, url, valid)

proc call*(call_602537: Call_GetDeleteDBParameterGroup_602523;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602538 = newJObject()
  add(query_602538, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602538, "Action", newJString(Action))
  add(query_602538, "Version", newJString(Version))
  result = call_602537.call(nil, query_602538, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_602523(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_602524, base: "/",
    url: url_GetDeleteDBParameterGroup_602525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_602572 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBSecurityGroup_602574(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBSecurityGroup_602573(path: JsonNode; query: JsonNode;
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
  var valid_602575 = query.getOrDefault("Action")
  valid_602575 = validateParameter(valid_602575, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_602575 != nil:
    section.add "Action", valid_602575
  var valid_602576 = query.getOrDefault("Version")
  valid_602576 = validateParameter(valid_602576, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602576 != nil:
    section.add "Version", valid_602576
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602577 = header.getOrDefault("X-Amz-Signature")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Signature", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Content-Sha256", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Date")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Date", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Credential")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Credential", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-Security-Token")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Security-Token", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Algorithm")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Algorithm", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-SignedHeaders", valid_602583
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602584 = formData.getOrDefault("DBSecurityGroupName")
  valid_602584 = validateParameter(valid_602584, JString, required = true,
                                 default = nil)
  if valid_602584 != nil:
    section.add "DBSecurityGroupName", valid_602584
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602585: Call_PostDeleteDBSecurityGroup_602572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602585.validator(path, query, header, formData, body)
  let scheme = call_602585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602585.url(scheme.get, call_602585.host, call_602585.base,
                         call_602585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602585, url, valid)

proc call*(call_602586: Call_PostDeleteDBSecurityGroup_602572;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602587 = newJObject()
  var formData_602588 = newJObject()
  add(formData_602588, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602587, "Action", newJString(Action))
  add(query_602587, "Version", newJString(Version))
  result = call_602586.call(nil, query_602587, nil, formData_602588, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_602572(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_602573, base: "/",
    url: url_PostDeleteDBSecurityGroup_602574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_602556 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBSecurityGroup_602558(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBSecurityGroup_602557(path: JsonNode; query: JsonNode;
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
  var valid_602559 = query.getOrDefault("DBSecurityGroupName")
  valid_602559 = validateParameter(valid_602559, JString, required = true,
                                 default = nil)
  if valid_602559 != nil:
    section.add "DBSecurityGroupName", valid_602559
  var valid_602560 = query.getOrDefault("Action")
  valid_602560 = validateParameter(valid_602560, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_602560 != nil:
    section.add "Action", valid_602560
  var valid_602561 = query.getOrDefault("Version")
  valid_602561 = validateParameter(valid_602561, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602561 != nil:
    section.add "Version", valid_602561
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602562 = header.getOrDefault("X-Amz-Signature")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Signature", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Content-Sha256", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-Date")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Date", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Credential")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Credential", valid_602565
  var valid_602566 = header.getOrDefault("X-Amz-Security-Token")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "X-Amz-Security-Token", valid_602566
  var valid_602567 = header.getOrDefault("X-Amz-Algorithm")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "X-Amz-Algorithm", valid_602567
  var valid_602568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "X-Amz-SignedHeaders", valid_602568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602569: Call_GetDeleteDBSecurityGroup_602556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602569.validator(path, query, header, formData, body)
  let scheme = call_602569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602569.url(scheme.get, call_602569.host, call_602569.base,
                         call_602569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602569, url, valid)

proc call*(call_602570: Call_GetDeleteDBSecurityGroup_602556;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602571 = newJObject()
  add(query_602571, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602571, "Action", newJString(Action))
  add(query_602571, "Version", newJString(Version))
  result = call_602570.call(nil, query_602571, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_602556(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_602557, base: "/",
    url: url_GetDeleteDBSecurityGroup_602558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_602605 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBSnapshot_602607(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSnapshot_602606(path: JsonNode; query: JsonNode;
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
  var valid_602608 = query.getOrDefault("Action")
  valid_602608 = validateParameter(valid_602608, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_602608 != nil:
    section.add "Action", valid_602608
  var valid_602609 = query.getOrDefault("Version")
  valid_602609 = validateParameter(valid_602609, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602609 != nil:
    section.add "Version", valid_602609
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602610 = header.getOrDefault("X-Amz-Signature")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-Signature", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Content-Sha256", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Date")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Date", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Credential")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Credential", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-Security-Token")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Security-Token", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-Algorithm")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-Algorithm", valid_602615
  var valid_602616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "X-Amz-SignedHeaders", valid_602616
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_602617 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602617 = validateParameter(valid_602617, JString, required = true,
                                 default = nil)
  if valid_602617 != nil:
    section.add "DBSnapshotIdentifier", valid_602617
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602618: Call_PostDeleteDBSnapshot_602605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602618.validator(path, query, header, formData, body)
  let scheme = call_602618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602618.url(scheme.get, call_602618.host, call_602618.base,
                         call_602618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602618, url, valid)

proc call*(call_602619: Call_PostDeleteDBSnapshot_602605;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602620 = newJObject()
  var formData_602621 = newJObject()
  add(formData_602621, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602620, "Action", newJString(Action))
  add(query_602620, "Version", newJString(Version))
  result = call_602619.call(nil, query_602620, nil, formData_602621, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_602605(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_602606, base: "/",
    url: url_PostDeleteDBSnapshot_602607, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_602589 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBSnapshot_602591(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSnapshot_602590(path: JsonNode; query: JsonNode;
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
  var valid_602592 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602592 = validateParameter(valid_602592, JString, required = true,
                                 default = nil)
  if valid_602592 != nil:
    section.add "DBSnapshotIdentifier", valid_602592
  var valid_602593 = query.getOrDefault("Action")
  valid_602593 = validateParameter(valid_602593, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_602593 != nil:
    section.add "Action", valid_602593
  var valid_602594 = query.getOrDefault("Version")
  valid_602594 = validateParameter(valid_602594, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602594 != nil:
    section.add "Version", valid_602594
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602595 = header.getOrDefault("X-Amz-Signature")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Signature", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Content-Sha256", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-Date")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Date", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Credential")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Credential", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-Security-Token")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-Security-Token", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Algorithm")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Algorithm", valid_602600
  var valid_602601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "X-Amz-SignedHeaders", valid_602601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602602: Call_GetDeleteDBSnapshot_602589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602602.validator(path, query, header, formData, body)
  let scheme = call_602602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602602.url(scheme.get, call_602602.host, call_602602.base,
                         call_602602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602602, url, valid)

proc call*(call_602603: Call_GetDeleteDBSnapshot_602589;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602604 = newJObject()
  add(query_602604, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602604, "Action", newJString(Action))
  add(query_602604, "Version", newJString(Version))
  result = call_602603.call(nil, query_602604, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_602589(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_602590, base: "/",
    url: url_GetDeleteDBSnapshot_602591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_602638 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBSubnetGroup_602640(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSubnetGroup_602639(path: JsonNode; query: JsonNode;
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
  var valid_602641 = query.getOrDefault("Action")
  valid_602641 = validateParameter(valid_602641, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_602641 != nil:
    section.add "Action", valid_602641
  var valid_602642 = query.getOrDefault("Version")
  valid_602642 = validateParameter(valid_602642, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602642 != nil:
    section.add "Version", valid_602642
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602643 = header.getOrDefault("X-Amz-Signature")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Signature", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Content-Sha256", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-Date")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Date", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-Credential")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-Credential", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-Security-Token")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-Security-Token", valid_602647
  var valid_602648 = header.getOrDefault("X-Amz-Algorithm")
  valid_602648 = validateParameter(valid_602648, JString, required = false,
                                 default = nil)
  if valid_602648 != nil:
    section.add "X-Amz-Algorithm", valid_602648
  var valid_602649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602649 = validateParameter(valid_602649, JString, required = false,
                                 default = nil)
  if valid_602649 != nil:
    section.add "X-Amz-SignedHeaders", valid_602649
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_602650 = formData.getOrDefault("DBSubnetGroupName")
  valid_602650 = validateParameter(valid_602650, JString, required = true,
                                 default = nil)
  if valid_602650 != nil:
    section.add "DBSubnetGroupName", valid_602650
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602651: Call_PostDeleteDBSubnetGroup_602638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602651.validator(path, query, header, formData, body)
  let scheme = call_602651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602651.url(scheme.get, call_602651.host, call_602651.base,
                         call_602651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602651, url, valid)

proc call*(call_602652: Call_PostDeleteDBSubnetGroup_602638;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_602653 = newJObject()
  var formData_602654 = newJObject()
  add(query_602653, "Action", newJString(Action))
  add(formData_602654, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602653, "Version", newJString(Version))
  result = call_602652.call(nil, query_602653, nil, formData_602654, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_602638(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_602639, base: "/",
    url: url_PostDeleteDBSubnetGroup_602640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_602622 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBSubnetGroup_602624(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSubnetGroup_602623(path: JsonNode; query: JsonNode;
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
  var valid_602625 = query.getOrDefault("Action")
  valid_602625 = validateParameter(valid_602625, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_602625 != nil:
    section.add "Action", valid_602625
  var valid_602626 = query.getOrDefault("DBSubnetGroupName")
  valid_602626 = validateParameter(valid_602626, JString, required = true,
                                 default = nil)
  if valid_602626 != nil:
    section.add "DBSubnetGroupName", valid_602626
  var valid_602627 = query.getOrDefault("Version")
  valid_602627 = validateParameter(valid_602627, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602627 != nil:
    section.add "Version", valid_602627
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602628 = header.getOrDefault("X-Amz-Signature")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Signature", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-Content-Sha256", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-Date")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Date", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Credential")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Credential", valid_602631
  var valid_602632 = header.getOrDefault("X-Amz-Security-Token")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "X-Amz-Security-Token", valid_602632
  var valid_602633 = header.getOrDefault("X-Amz-Algorithm")
  valid_602633 = validateParameter(valid_602633, JString, required = false,
                                 default = nil)
  if valid_602633 != nil:
    section.add "X-Amz-Algorithm", valid_602633
  var valid_602634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602634 = validateParameter(valid_602634, JString, required = false,
                                 default = nil)
  if valid_602634 != nil:
    section.add "X-Amz-SignedHeaders", valid_602634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602635: Call_GetDeleteDBSubnetGroup_602622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602635.validator(path, query, header, formData, body)
  let scheme = call_602635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602635.url(scheme.get, call_602635.host, call_602635.base,
                         call_602635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602635, url, valid)

proc call*(call_602636: Call_GetDeleteDBSubnetGroup_602622;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_602637 = newJObject()
  add(query_602637, "Action", newJString(Action))
  add(query_602637, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602637, "Version", newJString(Version))
  result = call_602636.call(nil, query_602637, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_602622(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_602623, base: "/",
    url: url_GetDeleteDBSubnetGroup_602624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_602671 = ref object of OpenApiRestCall_601373
proc url_PostDeleteEventSubscription_602673(protocol: Scheme; host: string;
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

proc validate_PostDeleteEventSubscription_602672(path: JsonNode; query: JsonNode;
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
  var valid_602674 = query.getOrDefault("Action")
  valid_602674 = validateParameter(valid_602674, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_602674 != nil:
    section.add "Action", valid_602674
  var valid_602675 = query.getOrDefault("Version")
  valid_602675 = validateParameter(valid_602675, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602675 != nil:
    section.add "Version", valid_602675
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602676 = header.getOrDefault("X-Amz-Signature")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Signature", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Content-Sha256", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-Date")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-Date", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-Credential")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Credential", valid_602679
  var valid_602680 = header.getOrDefault("X-Amz-Security-Token")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-Security-Token", valid_602680
  var valid_602681 = header.getOrDefault("X-Amz-Algorithm")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-Algorithm", valid_602681
  var valid_602682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602682 = validateParameter(valid_602682, JString, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "X-Amz-SignedHeaders", valid_602682
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_602683 = formData.getOrDefault("SubscriptionName")
  valid_602683 = validateParameter(valid_602683, JString, required = true,
                                 default = nil)
  if valid_602683 != nil:
    section.add "SubscriptionName", valid_602683
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602684: Call_PostDeleteEventSubscription_602671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602684.validator(path, query, header, formData, body)
  let scheme = call_602684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602684.url(scheme.get, call_602684.host, call_602684.base,
                         call_602684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602684, url, valid)

proc call*(call_602685: Call_PostDeleteEventSubscription_602671;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602686 = newJObject()
  var formData_602687 = newJObject()
  add(formData_602687, "SubscriptionName", newJString(SubscriptionName))
  add(query_602686, "Action", newJString(Action))
  add(query_602686, "Version", newJString(Version))
  result = call_602685.call(nil, query_602686, nil, formData_602687, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_602671(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_602672, base: "/",
    url: url_PostDeleteEventSubscription_602673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_602655 = ref object of OpenApiRestCall_601373
proc url_GetDeleteEventSubscription_602657(protocol: Scheme; host: string;
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

proc validate_GetDeleteEventSubscription_602656(path: JsonNode; query: JsonNode;
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
  var valid_602658 = query.getOrDefault("SubscriptionName")
  valid_602658 = validateParameter(valid_602658, JString, required = true,
                                 default = nil)
  if valid_602658 != nil:
    section.add "SubscriptionName", valid_602658
  var valid_602659 = query.getOrDefault("Action")
  valid_602659 = validateParameter(valid_602659, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_602659 != nil:
    section.add "Action", valid_602659
  var valid_602660 = query.getOrDefault("Version")
  valid_602660 = validateParameter(valid_602660, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602660 != nil:
    section.add "Version", valid_602660
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602661 = header.getOrDefault("X-Amz-Signature")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-Signature", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-Content-Sha256", valid_602662
  var valid_602663 = header.getOrDefault("X-Amz-Date")
  valid_602663 = validateParameter(valid_602663, JString, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "X-Amz-Date", valid_602663
  var valid_602664 = header.getOrDefault("X-Amz-Credential")
  valid_602664 = validateParameter(valid_602664, JString, required = false,
                                 default = nil)
  if valid_602664 != nil:
    section.add "X-Amz-Credential", valid_602664
  var valid_602665 = header.getOrDefault("X-Amz-Security-Token")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "X-Amz-Security-Token", valid_602665
  var valid_602666 = header.getOrDefault("X-Amz-Algorithm")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-Algorithm", valid_602666
  var valid_602667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "X-Amz-SignedHeaders", valid_602667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602668: Call_GetDeleteEventSubscription_602655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602668.validator(path, query, header, formData, body)
  let scheme = call_602668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602668.url(scheme.get, call_602668.host, call_602668.base,
                         call_602668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602668, url, valid)

proc call*(call_602669: Call_GetDeleteEventSubscription_602655;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602670 = newJObject()
  add(query_602670, "SubscriptionName", newJString(SubscriptionName))
  add(query_602670, "Action", newJString(Action))
  add(query_602670, "Version", newJString(Version))
  result = call_602669.call(nil, query_602670, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_602655(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_602656, base: "/",
    url: url_GetDeleteEventSubscription_602657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_602704 = ref object of OpenApiRestCall_601373
proc url_PostDeleteOptionGroup_602706(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteOptionGroup_602705(path: JsonNode; query: JsonNode;
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
  var valid_602707 = query.getOrDefault("Action")
  valid_602707 = validateParameter(valid_602707, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_602707 != nil:
    section.add "Action", valid_602707
  var valid_602708 = query.getOrDefault("Version")
  valid_602708 = validateParameter(valid_602708, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602708 != nil:
    section.add "Version", valid_602708
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602709 = header.getOrDefault("X-Amz-Signature")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-Signature", valid_602709
  var valid_602710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-Content-Sha256", valid_602710
  var valid_602711 = header.getOrDefault("X-Amz-Date")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "X-Amz-Date", valid_602711
  var valid_602712 = header.getOrDefault("X-Amz-Credential")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "X-Amz-Credential", valid_602712
  var valid_602713 = header.getOrDefault("X-Amz-Security-Token")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "X-Amz-Security-Token", valid_602713
  var valid_602714 = header.getOrDefault("X-Amz-Algorithm")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-Algorithm", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-SignedHeaders", valid_602715
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_602716 = formData.getOrDefault("OptionGroupName")
  valid_602716 = validateParameter(valid_602716, JString, required = true,
                                 default = nil)
  if valid_602716 != nil:
    section.add "OptionGroupName", valid_602716
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602717: Call_PostDeleteOptionGroup_602704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602717.validator(path, query, header, formData, body)
  let scheme = call_602717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602717.url(scheme.get, call_602717.host, call_602717.base,
                         call_602717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602717, url, valid)

proc call*(call_602718: Call_PostDeleteOptionGroup_602704; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_602719 = newJObject()
  var formData_602720 = newJObject()
  add(query_602719, "Action", newJString(Action))
  add(formData_602720, "OptionGroupName", newJString(OptionGroupName))
  add(query_602719, "Version", newJString(Version))
  result = call_602718.call(nil, query_602719, nil, formData_602720, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_602704(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_602705, base: "/",
    url: url_PostDeleteOptionGroup_602706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_602688 = ref object of OpenApiRestCall_601373
proc url_GetDeleteOptionGroup_602690(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteOptionGroup_602689(path: JsonNode; query: JsonNode;
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
  var valid_602691 = query.getOrDefault("Action")
  valid_602691 = validateParameter(valid_602691, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_602691 != nil:
    section.add "Action", valid_602691
  var valid_602692 = query.getOrDefault("OptionGroupName")
  valid_602692 = validateParameter(valid_602692, JString, required = true,
                                 default = nil)
  if valid_602692 != nil:
    section.add "OptionGroupName", valid_602692
  var valid_602693 = query.getOrDefault("Version")
  valid_602693 = validateParameter(valid_602693, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602693 != nil:
    section.add "Version", valid_602693
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602694 = header.getOrDefault("X-Amz-Signature")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-Signature", valid_602694
  var valid_602695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "X-Amz-Content-Sha256", valid_602695
  var valid_602696 = header.getOrDefault("X-Amz-Date")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-Date", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-Credential")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-Credential", valid_602697
  var valid_602698 = header.getOrDefault("X-Amz-Security-Token")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Security-Token", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-Algorithm")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-Algorithm", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-SignedHeaders", valid_602700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602701: Call_GetDeleteOptionGroup_602688; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602701.validator(path, query, header, formData, body)
  let scheme = call_602701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602701.url(scheme.get, call_602701.host, call_602701.base,
                         call_602701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602701, url, valid)

proc call*(call_602702: Call_GetDeleteOptionGroup_602688; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_602703 = newJObject()
  add(query_602703, "Action", newJString(Action))
  add(query_602703, "OptionGroupName", newJString(OptionGroupName))
  add(query_602703, "Version", newJString(Version))
  result = call_602702.call(nil, query_602703, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_602688(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_602689, base: "/",
    url: url_GetDeleteOptionGroup_602690, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_602744 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBEngineVersions_602746(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBEngineVersions_602745(path: JsonNode; query: JsonNode;
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
  var valid_602747 = query.getOrDefault("Action")
  valid_602747 = validateParameter(valid_602747, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_602747 != nil:
    section.add "Action", valid_602747
  var valid_602748 = query.getOrDefault("Version")
  valid_602748 = validateParameter(valid_602748, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602748 != nil:
    section.add "Version", valid_602748
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602749 = header.getOrDefault("X-Amz-Signature")
  valid_602749 = validateParameter(valid_602749, JString, required = false,
                                 default = nil)
  if valid_602749 != nil:
    section.add "X-Amz-Signature", valid_602749
  var valid_602750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602750 = validateParameter(valid_602750, JString, required = false,
                                 default = nil)
  if valid_602750 != nil:
    section.add "X-Amz-Content-Sha256", valid_602750
  var valid_602751 = header.getOrDefault("X-Amz-Date")
  valid_602751 = validateParameter(valid_602751, JString, required = false,
                                 default = nil)
  if valid_602751 != nil:
    section.add "X-Amz-Date", valid_602751
  var valid_602752 = header.getOrDefault("X-Amz-Credential")
  valid_602752 = validateParameter(valid_602752, JString, required = false,
                                 default = nil)
  if valid_602752 != nil:
    section.add "X-Amz-Credential", valid_602752
  var valid_602753 = header.getOrDefault("X-Amz-Security-Token")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "X-Amz-Security-Token", valid_602753
  var valid_602754 = header.getOrDefault("X-Amz-Algorithm")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Algorithm", valid_602754
  var valid_602755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602755 = validateParameter(valid_602755, JString, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "X-Amz-SignedHeaders", valid_602755
  result.add "header", section
  ## parameters in `formData` object:
  ##   DefaultOnly: JBool
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   Marker: JString
  ##   Engine: JString
  ##   ListSupportedCharacterSets: JBool
  ##   Filters: JArray
  ##   DBParameterGroupFamily: JString
  section = newJObject()
  var valid_602756 = formData.getOrDefault("DefaultOnly")
  valid_602756 = validateParameter(valid_602756, JBool, required = false, default = nil)
  if valid_602756 != nil:
    section.add "DefaultOnly", valid_602756
  var valid_602757 = formData.getOrDefault("MaxRecords")
  valid_602757 = validateParameter(valid_602757, JInt, required = false, default = nil)
  if valid_602757 != nil:
    section.add "MaxRecords", valid_602757
  var valid_602758 = formData.getOrDefault("EngineVersion")
  valid_602758 = validateParameter(valid_602758, JString, required = false,
                                 default = nil)
  if valid_602758 != nil:
    section.add "EngineVersion", valid_602758
  var valid_602759 = formData.getOrDefault("Marker")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "Marker", valid_602759
  var valid_602760 = formData.getOrDefault("Engine")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "Engine", valid_602760
  var valid_602761 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_602761 = validateParameter(valid_602761, JBool, required = false, default = nil)
  if valid_602761 != nil:
    section.add "ListSupportedCharacterSets", valid_602761
  var valid_602762 = formData.getOrDefault("Filters")
  valid_602762 = validateParameter(valid_602762, JArray, required = false,
                                 default = nil)
  if valid_602762 != nil:
    section.add "Filters", valid_602762
  var valid_602763 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602763 = validateParameter(valid_602763, JString, required = false,
                                 default = nil)
  if valid_602763 != nil:
    section.add "DBParameterGroupFamily", valid_602763
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602764: Call_PostDescribeDBEngineVersions_602744; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602764.validator(path, query, header, formData, body)
  let scheme = call_602764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602764.url(scheme.get, call_602764.host, call_602764.base,
                         call_602764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602764, url, valid)

proc call*(call_602765: Call_PostDescribeDBEngineVersions_602744;
          DefaultOnly: bool = false; MaxRecords: int = 0; EngineVersion: string = "";
          Marker: string = ""; Engine: string = "";
          ListSupportedCharacterSets: bool = false;
          Action: string = "DescribeDBEngineVersions"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"; DBParameterGroupFamily: string = ""): Recallable =
  ## postDescribeDBEngineVersions
  ##   DefaultOnly: bool
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Marker: string
  ##   Engine: string
  ##   ListSupportedCharacterSets: bool
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string
  var query_602766 = newJObject()
  var formData_602767 = newJObject()
  add(formData_602767, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_602767, "MaxRecords", newJInt(MaxRecords))
  add(formData_602767, "EngineVersion", newJString(EngineVersion))
  add(formData_602767, "Marker", newJString(Marker))
  add(formData_602767, "Engine", newJString(Engine))
  add(formData_602767, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_602766, "Action", newJString(Action))
  if Filters != nil:
    formData_602767.add "Filters", Filters
  add(query_602766, "Version", newJString(Version))
  add(formData_602767, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_602765.call(nil, query_602766, nil, formData_602767, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_602744(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_602745, base: "/",
    url: url_PostDescribeDBEngineVersions_602746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_602721 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBEngineVersions_602723(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBEngineVersions_602722(path: JsonNode; query: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   DefaultOnly: JBool
  section = newJObject()
  var valid_602724 = query.getOrDefault("Marker")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "Marker", valid_602724
  var valid_602725 = query.getOrDefault("DBParameterGroupFamily")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "DBParameterGroupFamily", valid_602725
  var valid_602726 = query.getOrDefault("Engine")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "Engine", valid_602726
  var valid_602727 = query.getOrDefault("EngineVersion")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "EngineVersion", valid_602727
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602728 = query.getOrDefault("Action")
  valid_602728 = validateParameter(valid_602728, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_602728 != nil:
    section.add "Action", valid_602728
  var valid_602729 = query.getOrDefault("ListSupportedCharacterSets")
  valid_602729 = validateParameter(valid_602729, JBool, required = false, default = nil)
  if valid_602729 != nil:
    section.add "ListSupportedCharacterSets", valid_602729
  var valid_602730 = query.getOrDefault("Version")
  valid_602730 = validateParameter(valid_602730, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602730 != nil:
    section.add "Version", valid_602730
  var valid_602731 = query.getOrDefault("Filters")
  valid_602731 = validateParameter(valid_602731, JArray, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "Filters", valid_602731
  var valid_602732 = query.getOrDefault("MaxRecords")
  valid_602732 = validateParameter(valid_602732, JInt, required = false, default = nil)
  if valid_602732 != nil:
    section.add "MaxRecords", valid_602732
  var valid_602733 = query.getOrDefault("DefaultOnly")
  valid_602733 = validateParameter(valid_602733, JBool, required = false, default = nil)
  if valid_602733 != nil:
    section.add "DefaultOnly", valid_602733
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602734 = header.getOrDefault("X-Amz-Signature")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "X-Amz-Signature", valid_602734
  var valid_602735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602735 = validateParameter(valid_602735, JString, required = false,
                                 default = nil)
  if valid_602735 != nil:
    section.add "X-Amz-Content-Sha256", valid_602735
  var valid_602736 = header.getOrDefault("X-Amz-Date")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "X-Amz-Date", valid_602736
  var valid_602737 = header.getOrDefault("X-Amz-Credential")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "X-Amz-Credential", valid_602737
  var valid_602738 = header.getOrDefault("X-Amz-Security-Token")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-Security-Token", valid_602738
  var valid_602739 = header.getOrDefault("X-Amz-Algorithm")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "X-Amz-Algorithm", valid_602739
  var valid_602740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "X-Amz-SignedHeaders", valid_602740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602741: Call_GetDescribeDBEngineVersions_602721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602741.validator(path, query, header, formData, body)
  let scheme = call_602741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602741.url(scheme.get, call_602741.host, call_602741.base,
                         call_602741.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602741, url, valid)

proc call*(call_602742: Call_GetDescribeDBEngineVersions_602721;
          Marker: string = ""; DBParameterGroupFamily: string = ""; Engine: string = "";
          EngineVersion: string = ""; Action: string = "DescribeDBEngineVersions";
          ListSupportedCharacterSets: bool = false; Version: string = "2013-09-09";
          Filters: JsonNode = nil; MaxRecords: int = 0; DefaultOnly: bool = false): Recallable =
  ## getDescribeDBEngineVersions
  ##   Marker: string
  ##   DBParameterGroupFamily: string
  ##   Engine: string
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   ListSupportedCharacterSets: bool
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   DefaultOnly: bool
  var query_602743 = newJObject()
  add(query_602743, "Marker", newJString(Marker))
  add(query_602743, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_602743, "Engine", newJString(Engine))
  add(query_602743, "EngineVersion", newJString(EngineVersion))
  add(query_602743, "Action", newJString(Action))
  add(query_602743, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_602743, "Version", newJString(Version))
  if Filters != nil:
    query_602743.add "Filters", Filters
  add(query_602743, "MaxRecords", newJInt(MaxRecords))
  add(query_602743, "DefaultOnly", newJBool(DefaultOnly))
  result = call_602742.call(nil, query_602743, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_602721(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_602722, base: "/",
    url: url_GetDescribeDBEngineVersions_602723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_602787 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBInstances_602789(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBInstances_602788(path: JsonNode; query: JsonNode;
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
  var valid_602790 = query.getOrDefault("Action")
  valid_602790 = validateParameter(valid_602790, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_602790 != nil:
    section.add "Action", valid_602790
  var valid_602791 = query.getOrDefault("Version")
  valid_602791 = validateParameter(valid_602791, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602791 != nil:
    section.add "Version", valid_602791
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602792 = header.getOrDefault("X-Amz-Signature")
  valid_602792 = validateParameter(valid_602792, JString, required = false,
                                 default = nil)
  if valid_602792 != nil:
    section.add "X-Amz-Signature", valid_602792
  var valid_602793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602793 = validateParameter(valid_602793, JString, required = false,
                                 default = nil)
  if valid_602793 != nil:
    section.add "X-Amz-Content-Sha256", valid_602793
  var valid_602794 = header.getOrDefault("X-Amz-Date")
  valid_602794 = validateParameter(valid_602794, JString, required = false,
                                 default = nil)
  if valid_602794 != nil:
    section.add "X-Amz-Date", valid_602794
  var valid_602795 = header.getOrDefault("X-Amz-Credential")
  valid_602795 = validateParameter(valid_602795, JString, required = false,
                                 default = nil)
  if valid_602795 != nil:
    section.add "X-Amz-Credential", valid_602795
  var valid_602796 = header.getOrDefault("X-Amz-Security-Token")
  valid_602796 = validateParameter(valid_602796, JString, required = false,
                                 default = nil)
  if valid_602796 != nil:
    section.add "X-Amz-Security-Token", valid_602796
  var valid_602797 = header.getOrDefault("X-Amz-Algorithm")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "X-Amz-Algorithm", valid_602797
  var valid_602798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "X-Amz-SignedHeaders", valid_602798
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_602799 = formData.getOrDefault("MaxRecords")
  valid_602799 = validateParameter(valid_602799, JInt, required = false, default = nil)
  if valid_602799 != nil:
    section.add "MaxRecords", valid_602799
  var valid_602800 = formData.getOrDefault("Marker")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "Marker", valid_602800
  var valid_602801 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "DBInstanceIdentifier", valid_602801
  var valid_602802 = formData.getOrDefault("Filters")
  valid_602802 = validateParameter(valid_602802, JArray, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "Filters", valid_602802
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602803: Call_PostDescribeDBInstances_602787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602803.validator(path, query, header, formData, body)
  let scheme = call_602803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602803.url(scheme.get, call_602803.host, call_602803.base,
                         call_602803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602803, url, valid)

proc call*(call_602804: Call_PostDescribeDBInstances_602787; MaxRecords: int = 0;
          Marker: string = ""; DBInstanceIdentifier: string = "";
          Action: string = "DescribeDBInstances"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBInstances
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_602805 = newJObject()
  var formData_602806 = newJObject()
  add(formData_602806, "MaxRecords", newJInt(MaxRecords))
  add(formData_602806, "Marker", newJString(Marker))
  add(formData_602806, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602805, "Action", newJString(Action))
  if Filters != nil:
    formData_602806.add "Filters", Filters
  add(query_602805, "Version", newJString(Version))
  result = call_602804.call(nil, query_602805, nil, formData_602806, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_602787(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_602788, base: "/",
    url: url_PostDescribeDBInstances_602789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_602768 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBInstances_602770(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBInstances_602769(path: JsonNode; query: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602771 = query.getOrDefault("Marker")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "Marker", valid_602771
  var valid_602772 = query.getOrDefault("DBInstanceIdentifier")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "DBInstanceIdentifier", valid_602772
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602773 = query.getOrDefault("Action")
  valid_602773 = validateParameter(valid_602773, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_602773 != nil:
    section.add "Action", valid_602773
  var valid_602774 = query.getOrDefault("Version")
  valid_602774 = validateParameter(valid_602774, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602774 != nil:
    section.add "Version", valid_602774
  var valid_602775 = query.getOrDefault("Filters")
  valid_602775 = validateParameter(valid_602775, JArray, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "Filters", valid_602775
  var valid_602776 = query.getOrDefault("MaxRecords")
  valid_602776 = validateParameter(valid_602776, JInt, required = false, default = nil)
  if valid_602776 != nil:
    section.add "MaxRecords", valid_602776
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602777 = header.getOrDefault("X-Amz-Signature")
  valid_602777 = validateParameter(valid_602777, JString, required = false,
                                 default = nil)
  if valid_602777 != nil:
    section.add "X-Amz-Signature", valid_602777
  var valid_602778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602778 = validateParameter(valid_602778, JString, required = false,
                                 default = nil)
  if valid_602778 != nil:
    section.add "X-Amz-Content-Sha256", valid_602778
  var valid_602779 = header.getOrDefault("X-Amz-Date")
  valid_602779 = validateParameter(valid_602779, JString, required = false,
                                 default = nil)
  if valid_602779 != nil:
    section.add "X-Amz-Date", valid_602779
  var valid_602780 = header.getOrDefault("X-Amz-Credential")
  valid_602780 = validateParameter(valid_602780, JString, required = false,
                                 default = nil)
  if valid_602780 != nil:
    section.add "X-Amz-Credential", valid_602780
  var valid_602781 = header.getOrDefault("X-Amz-Security-Token")
  valid_602781 = validateParameter(valid_602781, JString, required = false,
                                 default = nil)
  if valid_602781 != nil:
    section.add "X-Amz-Security-Token", valid_602781
  var valid_602782 = header.getOrDefault("X-Amz-Algorithm")
  valid_602782 = validateParameter(valid_602782, JString, required = false,
                                 default = nil)
  if valid_602782 != nil:
    section.add "X-Amz-Algorithm", valid_602782
  var valid_602783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602783 = validateParameter(valid_602783, JString, required = false,
                                 default = nil)
  if valid_602783 != nil:
    section.add "X-Amz-SignedHeaders", valid_602783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602784: Call_GetDescribeDBInstances_602768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602784.validator(path, query, header, formData, body)
  let scheme = call_602784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602784.url(scheme.get, call_602784.host, call_602784.base,
                         call_602784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602784, url, valid)

proc call*(call_602785: Call_GetDescribeDBInstances_602768; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_602786 = newJObject()
  add(query_602786, "Marker", newJString(Marker))
  add(query_602786, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602786, "Action", newJString(Action))
  add(query_602786, "Version", newJString(Version))
  if Filters != nil:
    query_602786.add "Filters", Filters
  add(query_602786, "MaxRecords", newJInt(MaxRecords))
  result = call_602785.call(nil, query_602786, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_602768(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_602769, base: "/",
    url: url_GetDescribeDBInstances_602770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_602829 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBLogFiles_602831(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBLogFiles_602830(path: JsonNode; query: JsonNode;
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
  var valid_602832 = query.getOrDefault("Action")
  valid_602832 = validateParameter(valid_602832, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_602832 != nil:
    section.add "Action", valid_602832
  var valid_602833 = query.getOrDefault("Version")
  valid_602833 = validateParameter(valid_602833, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602833 != nil:
    section.add "Version", valid_602833
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   FileSize: JInt
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FilenameContains: JString
  ##   Filters: JArray
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_602841 = formData.getOrDefault("FileSize")
  valid_602841 = validateParameter(valid_602841, JInt, required = false, default = nil)
  if valid_602841 != nil:
    section.add "FileSize", valid_602841
  var valid_602842 = formData.getOrDefault("MaxRecords")
  valid_602842 = validateParameter(valid_602842, JInt, required = false, default = nil)
  if valid_602842 != nil:
    section.add "MaxRecords", valid_602842
  var valid_602843 = formData.getOrDefault("Marker")
  valid_602843 = validateParameter(valid_602843, JString, required = false,
                                 default = nil)
  if valid_602843 != nil:
    section.add "Marker", valid_602843
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602844 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602844 = validateParameter(valid_602844, JString, required = true,
                                 default = nil)
  if valid_602844 != nil:
    section.add "DBInstanceIdentifier", valid_602844
  var valid_602845 = formData.getOrDefault("FilenameContains")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "FilenameContains", valid_602845
  var valid_602846 = formData.getOrDefault("Filters")
  valid_602846 = validateParameter(valid_602846, JArray, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "Filters", valid_602846
  var valid_602847 = formData.getOrDefault("FileLastWritten")
  valid_602847 = validateParameter(valid_602847, JInt, required = false, default = nil)
  if valid_602847 != nil:
    section.add "FileLastWritten", valid_602847
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602848: Call_PostDescribeDBLogFiles_602829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602848.validator(path, query, header, formData, body)
  let scheme = call_602848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602848.url(scheme.get, call_602848.host, call_602848.base,
                         call_602848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602848, url, valid)

proc call*(call_602849: Call_PostDescribeDBLogFiles_602829;
          DBInstanceIdentifier: string; FileSize: int = 0; MaxRecords: int = 0;
          Marker: string = ""; FilenameContains: string = "";
          Action: string = "DescribeDBLogFiles"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"; FileLastWritten: int = 0): Recallable =
  ## postDescribeDBLogFiles
  ##   FileSize: int
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string (required)
  ##   FilenameContains: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   FileLastWritten: int
  var query_602850 = newJObject()
  var formData_602851 = newJObject()
  add(formData_602851, "FileSize", newJInt(FileSize))
  add(formData_602851, "MaxRecords", newJInt(MaxRecords))
  add(formData_602851, "Marker", newJString(Marker))
  add(formData_602851, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602851, "FilenameContains", newJString(FilenameContains))
  add(query_602850, "Action", newJString(Action))
  if Filters != nil:
    formData_602851.add "Filters", Filters
  add(query_602850, "Version", newJString(Version))
  add(formData_602851, "FileLastWritten", newJInt(FileLastWritten))
  result = call_602849.call(nil, query_602850, nil, formData_602851, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_602829(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_602830, base: "/",
    url: url_PostDescribeDBLogFiles_602831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_602807 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBLogFiles_602809(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBLogFiles_602808(path: JsonNode; query: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   FileSize: JInt
  section = newJObject()
  var valid_602810 = query.getOrDefault("Marker")
  valid_602810 = validateParameter(valid_602810, JString, required = false,
                                 default = nil)
  if valid_602810 != nil:
    section.add "Marker", valid_602810
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602811 = query.getOrDefault("DBInstanceIdentifier")
  valid_602811 = validateParameter(valid_602811, JString, required = true,
                                 default = nil)
  if valid_602811 != nil:
    section.add "DBInstanceIdentifier", valid_602811
  var valid_602812 = query.getOrDefault("FileLastWritten")
  valid_602812 = validateParameter(valid_602812, JInt, required = false, default = nil)
  if valid_602812 != nil:
    section.add "FileLastWritten", valid_602812
  var valid_602813 = query.getOrDefault("Action")
  valid_602813 = validateParameter(valid_602813, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_602813 != nil:
    section.add "Action", valid_602813
  var valid_602814 = query.getOrDefault("FilenameContains")
  valid_602814 = validateParameter(valid_602814, JString, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "FilenameContains", valid_602814
  var valid_602815 = query.getOrDefault("Version")
  valid_602815 = validateParameter(valid_602815, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602815 != nil:
    section.add "Version", valid_602815
  var valid_602816 = query.getOrDefault("Filters")
  valid_602816 = validateParameter(valid_602816, JArray, required = false,
                                 default = nil)
  if valid_602816 != nil:
    section.add "Filters", valid_602816
  var valid_602817 = query.getOrDefault("MaxRecords")
  valid_602817 = validateParameter(valid_602817, JInt, required = false, default = nil)
  if valid_602817 != nil:
    section.add "MaxRecords", valid_602817
  var valid_602818 = query.getOrDefault("FileSize")
  valid_602818 = validateParameter(valid_602818, JInt, required = false, default = nil)
  if valid_602818 != nil:
    section.add "FileSize", valid_602818
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602819 = header.getOrDefault("X-Amz-Signature")
  valid_602819 = validateParameter(valid_602819, JString, required = false,
                                 default = nil)
  if valid_602819 != nil:
    section.add "X-Amz-Signature", valid_602819
  var valid_602820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-Content-Sha256", valid_602820
  var valid_602821 = header.getOrDefault("X-Amz-Date")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-Date", valid_602821
  var valid_602822 = header.getOrDefault("X-Amz-Credential")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-Credential", valid_602822
  var valid_602823 = header.getOrDefault("X-Amz-Security-Token")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-Security-Token", valid_602823
  var valid_602824 = header.getOrDefault("X-Amz-Algorithm")
  valid_602824 = validateParameter(valid_602824, JString, required = false,
                                 default = nil)
  if valid_602824 != nil:
    section.add "X-Amz-Algorithm", valid_602824
  var valid_602825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602825 = validateParameter(valid_602825, JString, required = false,
                                 default = nil)
  if valid_602825 != nil:
    section.add "X-Amz-SignedHeaders", valid_602825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602826: Call_GetDescribeDBLogFiles_602807; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602826.validator(path, query, header, formData, body)
  let scheme = call_602826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602826.url(scheme.get, call_602826.host, call_602826.base,
                         call_602826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602826, url, valid)

proc call*(call_602827: Call_GetDescribeDBLogFiles_602807;
          DBInstanceIdentifier: string; Marker: string = ""; FileLastWritten: int = 0;
          Action: string = "DescribeDBLogFiles"; FilenameContains: string = "";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0;
          FileSize: int = 0): Recallable =
  ## getDescribeDBLogFiles
  ##   Marker: string
  ##   DBInstanceIdentifier: string (required)
  ##   FileLastWritten: int
  ##   Action: string (required)
  ##   FilenameContains: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   FileSize: int
  var query_602828 = newJObject()
  add(query_602828, "Marker", newJString(Marker))
  add(query_602828, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602828, "FileLastWritten", newJInt(FileLastWritten))
  add(query_602828, "Action", newJString(Action))
  add(query_602828, "FilenameContains", newJString(FilenameContains))
  add(query_602828, "Version", newJString(Version))
  if Filters != nil:
    query_602828.add "Filters", Filters
  add(query_602828, "MaxRecords", newJInt(MaxRecords))
  add(query_602828, "FileSize", newJInt(FileSize))
  result = call_602827.call(nil, query_602828, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_602807(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_602808, base: "/",
    url: url_GetDescribeDBLogFiles_602809, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_602871 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBParameterGroups_602873(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameterGroups_602872(path: JsonNode; query: JsonNode;
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
  var valid_602874 = query.getOrDefault("Action")
  valid_602874 = validateParameter(valid_602874, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_602874 != nil:
    section.add "Action", valid_602874
  var valid_602875 = query.getOrDefault("Version")
  valid_602875 = validateParameter(valid_602875, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602875 != nil:
    section.add "Version", valid_602875
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602876 = header.getOrDefault("X-Amz-Signature")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-Signature", valid_602876
  var valid_602877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-Content-Sha256", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-Date")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-Date", valid_602878
  var valid_602879 = header.getOrDefault("X-Amz-Credential")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "X-Amz-Credential", valid_602879
  var valid_602880 = header.getOrDefault("X-Amz-Security-Token")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "X-Amz-Security-Token", valid_602880
  var valid_602881 = header.getOrDefault("X-Amz-Algorithm")
  valid_602881 = validateParameter(valid_602881, JString, required = false,
                                 default = nil)
  if valid_602881 != nil:
    section.add "X-Amz-Algorithm", valid_602881
  var valid_602882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602882 = validateParameter(valid_602882, JString, required = false,
                                 default = nil)
  if valid_602882 != nil:
    section.add "X-Amz-SignedHeaders", valid_602882
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_602883 = formData.getOrDefault("MaxRecords")
  valid_602883 = validateParameter(valid_602883, JInt, required = false, default = nil)
  if valid_602883 != nil:
    section.add "MaxRecords", valid_602883
  var valid_602884 = formData.getOrDefault("DBParameterGroupName")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "DBParameterGroupName", valid_602884
  var valid_602885 = formData.getOrDefault("Marker")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "Marker", valid_602885
  var valid_602886 = formData.getOrDefault("Filters")
  valid_602886 = validateParameter(valid_602886, JArray, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "Filters", valid_602886
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602887: Call_PostDescribeDBParameterGroups_602871; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602887.validator(path, query, header, formData, body)
  let scheme = call_602887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602887.url(scheme.get, call_602887.host, call_602887.base,
                         call_602887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602887, url, valid)

proc call*(call_602888: Call_PostDescribeDBParameterGroups_602871;
          MaxRecords: int = 0; DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_602889 = newJObject()
  var formData_602890 = newJObject()
  add(formData_602890, "MaxRecords", newJInt(MaxRecords))
  add(formData_602890, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602890, "Marker", newJString(Marker))
  add(query_602889, "Action", newJString(Action))
  if Filters != nil:
    formData_602890.add "Filters", Filters
  add(query_602889, "Version", newJString(Version))
  result = call_602888.call(nil, query_602889, nil, formData_602890, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_602871(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_602872, base: "/",
    url: url_PostDescribeDBParameterGroups_602873,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_602852 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBParameterGroups_602854(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBParameterGroups_602853(path: JsonNode; query: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602855 = query.getOrDefault("Marker")
  valid_602855 = validateParameter(valid_602855, JString, required = false,
                                 default = nil)
  if valid_602855 != nil:
    section.add "Marker", valid_602855
  var valid_602856 = query.getOrDefault("DBParameterGroupName")
  valid_602856 = validateParameter(valid_602856, JString, required = false,
                                 default = nil)
  if valid_602856 != nil:
    section.add "DBParameterGroupName", valid_602856
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602857 = query.getOrDefault("Action")
  valid_602857 = validateParameter(valid_602857, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_602857 != nil:
    section.add "Action", valid_602857
  var valid_602858 = query.getOrDefault("Version")
  valid_602858 = validateParameter(valid_602858, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602858 != nil:
    section.add "Version", valid_602858
  var valid_602859 = query.getOrDefault("Filters")
  valid_602859 = validateParameter(valid_602859, JArray, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "Filters", valid_602859
  var valid_602860 = query.getOrDefault("MaxRecords")
  valid_602860 = validateParameter(valid_602860, JInt, required = false, default = nil)
  if valid_602860 != nil:
    section.add "MaxRecords", valid_602860
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602861 = header.getOrDefault("X-Amz-Signature")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "X-Amz-Signature", valid_602861
  var valid_602862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "X-Amz-Content-Sha256", valid_602862
  var valid_602863 = header.getOrDefault("X-Amz-Date")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-Date", valid_602863
  var valid_602864 = header.getOrDefault("X-Amz-Credential")
  valid_602864 = validateParameter(valid_602864, JString, required = false,
                                 default = nil)
  if valid_602864 != nil:
    section.add "X-Amz-Credential", valid_602864
  var valid_602865 = header.getOrDefault("X-Amz-Security-Token")
  valid_602865 = validateParameter(valid_602865, JString, required = false,
                                 default = nil)
  if valid_602865 != nil:
    section.add "X-Amz-Security-Token", valid_602865
  var valid_602866 = header.getOrDefault("X-Amz-Algorithm")
  valid_602866 = validateParameter(valid_602866, JString, required = false,
                                 default = nil)
  if valid_602866 != nil:
    section.add "X-Amz-Algorithm", valid_602866
  var valid_602867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602867 = validateParameter(valid_602867, JString, required = false,
                                 default = nil)
  if valid_602867 != nil:
    section.add "X-Amz-SignedHeaders", valid_602867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602868: Call_GetDescribeDBParameterGroups_602852; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602868.validator(path, query, header, formData, body)
  let scheme = call_602868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602868.url(scheme.get, call_602868.host, call_602868.base,
                         call_602868.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602868, url, valid)

proc call*(call_602869: Call_GetDescribeDBParameterGroups_602852;
          Marker: string = ""; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameterGroups
  ##   Marker: string
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_602870 = newJObject()
  add(query_602870, "Marker", newJString(Marker))
  add(query_602870, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602870, "Action", newJString(Action))
  add(query_602870, "Version", newJString(Version))
  if Filters != nil:
    query_602870.add "Filters", Filters
  add(query_602870, "MaxRecords", newJInt(MaxRecords))
  result = call_602869.call(nil, query_602870, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_602852(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_602853, base: "/",
    url: url_GetDescribeDBParameterGroups_602854,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_602911 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBParameters_602913(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameters_602912(path: JsonNode; query: JsonNode;
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
  var valid_602914 = query.getOrDefault("Action")
  valid_602914 = validateParameter(valid_602914, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_602914 != nil:
    section.add "Action", valid_602914
  var valid_602915 = query.getOrDefault("Version")
  valid_602915 = validateParameter(valid_602915, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602915 != nil:
    section.add "Version", valid_602915
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602916 = header.getOrDefault("X-Amz-Signature")
  valid_602916 = validateParameter(valid_602916, JString, required = false,
                                 default = nil)
  if valid_602916 != nil:
    section.add "X-Amz-Signature", valid_602916
  var valid_602917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Content-Sha256", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Date")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Date", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-Credential")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Credential", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-Security-Token")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Security-Token", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-Algorithm")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Algorithm", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-SignedHeaders", valid_602922
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_602923 = formData.getOrDefault("Source")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "Source", valid_602923
  var valid_602924 = formData.getOrDefault("MaxRecords")
  valid_602924 = validateParameter(valid_602924, JInt, required = false, default = nil)
  if valid_602924 != nil:
    section.add "MaxRecords", valid_602924
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602925 = formData.getOrDefault("DBParameterGroupName")
  valid_602925 = validateParameter(valid_602925, JString, required = true,
                                 default = nil)
  if valid_602925 != nil:
    section.add "DBParameterGroupName", valid_602925
  var valid_602926 = formData.getOrDefault("Marker")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "Marker", valid_602926
  var valid_602927 = formData.getOrDefault("Filters")
  valid_602927 = validateParameter(valid_602927, JArray, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "Filters", valid_602927
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602928: Call_PostDescribeDBParameters_602911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602928.validator(path, query, header, formData, body)
  let scheme = call_602928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602928.url(scheme.get, call_602928.host, call_602928.base,
                         call_602928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602928, url, valid)

proc call*(call_602929: Call_PostDescribeDBParameters_602911;
          DBParameterGroupName: string; Source: string = ""; MaxRecords: int = 0;
          Marker: string = ""; Action: string = "DescribeDBParameters";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBParameters
  ##   Source: string
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_602930 = newJObject()
  var formData_602931 = newJObject()
  add(formData_602931, "Source", newJString(Source))
  add(formData_602931, "MaxRecords", newJInt(MaxRecords))
  add(formData_602931, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602931, "Marker", newJString(Marker))
  add(query_602930, "Action", newJString(Action))
  if Filters != nil:
    formData_602931.add "Filters", Filters
  add(query_602930, "Version", newJString(Version))
  result = call_602929.call(nil, query_602930, nil, formData_602931, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_602911(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_602912, base: "/",
    url: url_PostDescribeDBParameters_602913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_602891 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBParameters_602893(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBParameters_602892(path: JsonNode; query: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602894 = query.getOrDefault("Marker")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "Marker", valid_602894
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_602895 = query.getOrDefault("DBParameterGroupName")
  valid_602895 = validateParameter(valid_602895, JString, required = true,
                                 default = nil)
  if valid_602895 != nil:
    section.add "DBParameterGroupName", valid_602895
  var valid_602896 = query.getOrDefault("Source")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "Source", valid_602896
  var valid_602897 = query.getOrDefault("Action")
  valid_602897 = validateParameter(valid_602897, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_602897 != nil:
    section.add "Action", valid_602897
  var valid_602898 = query.getOrDefault("Version")
  valid_602898 = validateParameter(valid_602898, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602898 != nil:
    section.add "Version", valid_602898
  var valid_602899 = query.getOrDefault("Filters")
  valid_602899 = validateParameter(valid_602899, JArray, required = false,
                                 default = nil)
  if valid_602899 != nil:
    section.add "Filters", valid_602899
  var valid_602900 = query.getOrDefault("MaxRecords")
  valid_602900 = validateParameter(valid_602900, JInt, required = false, default = nil)
  if valid_602900 != nil:
    section.add "MaxRecords", valid_602900
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602901 = header.getOrDefault("X-Amz-Signature")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Signature", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Content-Sha256", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-Date")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Date", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Credential")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Credential", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Security-Token")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Security-Token", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-Algorithm")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-Algorithm", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-SignedHeaders", valid_602907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602908: Call_GetDescribeDBParameters_602891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602908.validator(path, query, header, formData, body)
  let scheme = call_602908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602908.url(scheme.get, call_602908.host, call_602908.base,
                         call_602908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602908, url, valid)

proc call*(call_602909: Call_GetDescribeDBParameters_602891;
          DBParameterGroupName: string; Marker: string = ""; Source: string = "";
          Action: string = "DescribeDBParameters"; Version: string = "2013-09-09";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameters
  ##   Marker: string
  ##   DBParameterGroupName: string (required)
  ##   Source: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_602910 = newJObject()
  add(query_602910, "Marker", newJString(Marker))
  add(query_602910, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602910, "Source", newJString(Source))
  add(query_602910, "Action", newJString(Action))
  add(query_602910, "Version", newJString(Version))
  if Filters != nil:
    query_602910.add "Filters", Filters
  add(query_602910, "MaxRecords", newJInt(MaxRecords))
  result = call_602909.call(nil, query_602910, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_602891(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_602892, base: "/",
    url: url_GetDescribeDBParameters_602893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_602951 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBSecurityGroups_602953(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSecurityGroups_602952(path: JsonNode; query: JsonNode;
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
  var valid_602954 = query.getOrDefault("Action")
  valid_602954 = validateParameter(valid_602954, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_602954 != nil:
    section.add "Action", valid_602954
  var valid_602955 = query.getOrDefault("Version")
  valid_602955 = validateParameter(valid_602955, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602955 != nil:
    section.add "Version", valid_602955
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602956 = header.getOrDefault("X-Amz-Signature")
  valid_602956 = validateParameter(valid_602956, JString, required = false,
                                 default = nil)
  if valid_602956 != nil:
    section.add "X-Amz-Signature", valid_602956
  var valid_602957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602957 = validateParameter(valid_602957, JString, required = false,
                                 default = nil)
  if valid_602957 != nil:
    section.add "X-Amz-Content-Sha256", valid_602957
  var valid_602958 = header.getOrDefault("X-Amz-Date")
  valid_602958 = validateParameter(valid_602958, JString, required = false,
                                 default = nil)
  if valid_602958 != nil:
    section.add "X-Amz-Date", valid_602958
  var valid_602959 = header.getOrDefault("X-Amz-Credential")
  valid_602959 = validateParameter(valid_602959, JString, required = false,
                                 default = nil)
  if valid_602959 != nil:
    section.add "X-Amz-Credential", valid_602959
  var valid_602960 = header.getOrDefault("X-Amz-Security-Token")
  valid_602960 = validateParameter(valid_602960, JString, required = false,
                                 default = nil)
  if valid_602960 != nil:
    section.add "X-Amz-Security-Token", valid_602960
  var valid_602961 = header.getOrDefault("X-Amz-Algorithm")
  valid_602961 = validateParameter(valid_602961, JString, required = false,
                                 default = nil)
  if valid_602961 != nil:
    section.add "X-Amz-Algorithm", valid_602961
  var valid_602962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602962 = validateParameter(valid_602962, JString, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "X-Amz-SignedHeaders", valid_602962
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_602963 = formData.getOrDefault("DBSecurityGroupName")
  valid_602963 = validateParameter(valid_602963, JString, required = false,
                                 default = nil)
  if valid_602963 != nil:
    section.add "DBSecurityGroupName", valid_602963
  var valid_602964 = formData.getOrDefault("MaxRecords")
  valid_602964 = validateParameter(valid_602964, JInt, required = false, default = nil)
  if valid_602964 != nil:
    section.add "MaxRecords", valid_602964
  var valid_602965 = formData.getOrDefault("Marker")
  valid_602965 = validateParameter(valid_602965, JString, required = false,
                                 default = nil)
  if valid_602965 != nil:
    section.add "Marker", valid_602965
  var valid_602966 = formData.getOrDefault("Filters")
  valid_602966 = validateParameter(valid_602966, JArray, required = false,
                                 default = nil)
  if valid_602966 != nil:
    section.add "Filters", valid_602966
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602967: Call_PostDescribeDBSecurityGroups_602951; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602967.validator(path, query, header, formData, body)
  let scheme = call_602967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602967.url(scheme.get, call_602967.host, call_602967.base,
                         call_602967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602967, url, valid)

proc call*(call_602968: Call_PostDescribeDBSecurityGroups_602951;
          DBSecurityGroupName: string = ""; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_602969 = newJObject()
  var formData_602970 = newJObject()
  add(formData_602970, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_602970, "MaxRecords", newJInt(MaxRecords))
  add(formData_602970, "Marker", newJString(Marker))
  add(query_602969, "Action", newJString(Action))
  if Filters != nil:
    formData_602970.add "Filters", Filters
  add(query_602969, "Version", newJString(Version))
  result = call_602968.call(nil, query_602969, nil, formData_602970, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_602951(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_602952, base: "/",
    url: url_PostDescribeDBSecurityGroups_602953,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_602932 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBSecurityGroups_602934(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSecurityGroups_602933(path: JsonNode; query: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602935 = query.getOrDefault("Marker")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "Marker", valid_602935
  var valid_602936 = query.getOrDefault("DBSecurityGroupName")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "DBSecurityGroupName", valid_602936
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602937 = query.getOrDefault("Action")
  valid_602937 = validateParameter(valid_602937, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_602937 != nil:
    section.add "Action", valid_602937
  var valid_602938 = query.getOrDefault("Version")
  valid_602938 = validateParameter(valid_602938, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602938 != nil:
    section.add "Version", valid_602938
  var valid_602939 = query.getOrDefault("Filters")
  valid_602939 = validateParameter(valid_602939, JArray, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "Filters", valid_602939
  var valid_602940 = query.getOrDefault("MaxRecords")
  valid_602940 = validateParameter(valid_602940, JInt, required = false, default = nil)
  if valid_602940 != nil:
    section.add "MaxRecords", valid_602940
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602941 = header.getOrDefault("X-Amz-Signature")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "X-Amz-Signature", valid_602941
  var valid_602942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602942 = validateParameter(valid_602942, JString, required = false,
                                 default = nil)
  if valid_602942 != nil:
    section.add "X-Amz-Content-Sha256", valid_602942
  var valid_602943 = header.getOrDefault("X-Amz-Date")
  valid_602943 = validateParameter(valid_602943, JString, required = false,
                                 default = nil)
  if valid_602943 != nil:
    section.add "X-Amz-Date", valid_602943
  var valid_602944 = header.getOrDefault("X-Amz-Credential")
  valid_602944 = validateParameter(valid_602944, JString, required = false,
                                 default = nil)
  if valid_602944 != nil:
    section.add "X-Amz-Credential", valid_602944
  var valid_602945 = header.getOrDefault("X-Amz-Security-Token")
  valid_602945 = validateParameter(valid_602945, JString, required = false,
                                 default = nil)
  if valid_602945 != nil:
    section.add "X-Amz-Security-Token", valid_602945
  var valid_602946 = header.getOrDefault("X-Amz-Algorithm")
  valid_602946 = validateParameter(valid_602946, JString, required = false,
                                 default = nil)
  if valid_602946 != nil:
    section.add "X-Amz-Algorithm", valid_602946
  var valid_602947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602947 = validateParameter(valid_602947, JString, required = false,
                                 default = nil)
  if valid_602947 != nil:
    section.add "X-Amz-SignedHeaders", valid_602947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602948: Call_GetDescribeDBSecurityGroups_602932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602948.validator(path, query, header, formData, body)
  let scheme = call_602948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602948.url(scheme.get, call_602948.host, call_602948.base,
                         call_602948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602948, url, valid)

proc call*(call_602949: Call_GetDescribeDBSecurityGroups_602932;
          Marker: string = ""; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Marker: string
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_602950 = newJObject()
  add(query_602950, "Marker", newJString(Marker))
  add(query_602950, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602950, "Action", newJString(Action))
  add(query_602950, "Version", newJString(Version))
  if Filters != nil:
    query_602950.add "Filters", Filters
  add(query_602950, "MaxRecords", newJInt(MaxRecords))
  result = call_602949.call(nil, query_602950, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_602932(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_602933, base: "/",
    url: url_GetDescribeDBSecurityGroups_602934,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_602992 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBSnapshots_602994(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBSnapshots_602993(path: JsonNode; query: JsonNode;
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
  var valid_602995 = query.getOrDefault("Action")
  valid_602995 = validateParameter(valid_602995, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602995 != nil:
    section.add "Action", valid_602995
  var valid_602996 = query.getOrDefault("Version")
  valid_602996 = validateParameter(valid_602996, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603004 = formData.getOrDefault("SnapshotType")
  valid_603004 = validateParameter(valid_603004, JString, required = false,
                                 default = nil)
  if valid_603004 != nil:
    section.add "SnapshotType", valid_603004
  var valid_603005 = formData.getOrDefault("MaxRecords")
  valid_603005 = validateParameter(valid_603005, JInt, required = false, default = nil)
  if valid_603005 != nil:
    section.add "MaxRecords", valid_603005
  var valid_603006 = formData.getOrDefault("Marker")
  valid_603006 = validateParameter(valid_603006, JString, required = false,
                                 default = nil)
  if valid_603006 != nil:
    section.add "Marker", valid_603006
  var valid_603007 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603007 = validateParameter(valid_603007, JString, required = false,
                                 default = nil)
  if valid_603007 != nil:
    section.add "DBInstanceIdentifier", valid_603007
  var valid_603008 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603008 = validateParameter(valid_603008, JString, required = false,
                                 default = nil)
  if valid_603008 != nil:
    section.add "DBSnapshotIdentifier", valid_603008
  var valid_603009 = formData.getOrDefault("Filters")
  valid_603009 = validateParameter(valid_603009, JArray, required = false,
                                 default = nil)
  if valid_603009 != nil:
    section.add "Filters", valid_603009
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603010: Call_PostDescribeDBSnapshots_602992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603010.validator(path, query, header, formData, body)
  let scheme = call_603010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603010.url(scheme.get, call_603010.host, call_603010.base,
                         call_603010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603010, url, valid)

proc call*(call_603011: Call_PostDescribeDBSnapshots_602992;
          SnapshotType: string = ""; MaxRecords: int = 0; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSnapshots
  ##   SnapshotType: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603012 = newJObject()
  var formData_603013 = newJObject()
  add(formData_603013, "SnapshotType", newJString(SnapshotType))
  add(formData_603013, "MaxRecords", newJInt(MaxRecords))
  add(formData_603013, "Marker", newJString(Marker))
  add(formData_603013, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603013, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603012, "Action", newJString(Action))
  if Filters != nil:
    formData_603013.add "Filters", Filters
  add(query_603012, "Version", newJString(Version))
  result = call_603011.call(nil, query_603012, nil, formData_603013, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_602992(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_602993, base: "/",
    url: url_PostDescribeDBSnapshots_602994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_602971 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBSnapshots_602973(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBSnapshots_602972(path: JsonNode; query: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602974 = query.getOrDefault("Marker")
  valid_602974 = validateParameter(valid_602974, JString, required = false,
                                 default = nil)
  if valid_602974 != nil:
    section.add "Marker", valid_602974
  var valid_602975 = query.getOrDefault("DBInstanceIdentifier")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = nil)
  if valid_602975 != nil:
    section.add "DBInstanceIdentifier", valid_602975
  var valid_602976 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602976 = validateParameter(valid_602976, JString, required = false,
                                 default = nil)
  if valid_602976 != nil:
    section.add "DBSnapshotIdentifier", valid_602976
  var valid_602977 = query.getOrDefault("SnapshotType")
  valid_602977 = validateParameter(valid_602977, JString, required = false,
                                 default = nil)
  if valid_602977 != nil:
    section.add "SnapshotType", valid_602977
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602978 = query.getOrDefault("Action")
  valid_602978 = validateParameter(valid_602978, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602978 != nil:
    section.add "Action", valid_602978
  var valid_602979 = query.getOrDefault("Version")
  valid_602979 = validateParameter(valid_602979, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602979 != nil:
    section.add "Version", valid_602979
  var valid_602980 = query.getOrDefault("Filters")
  valid_602980 = validateParameter(valid_602980, JArray, required = false,
                                 default = nil)
  if valid_602980 != nil:
    section.add "Filters", valid_602980
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

proc call*(call_602989: Call_GetDescribeDBSnapshots_602971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602989.validator(path, query, header, formData, body)
  let scheme = call_602989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602989.url(scheme.get, call_602989.host, call_602989.base,
                         call_602989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602989, url, valid)

proc call*(call_602990: Call_GetDescribeDBSnapshots_602971; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          SnapshotType: string = ""; Action: string = "DescribeDBSnapshots";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSnapshots
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   SnapshotType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_602991 = newJObject()
  add(query_602991, "Marker", newJString(Marker))
  add(query_602991, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602991, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602991, "SnapshotType", newJString(SnapshotType))
  add(query_602991, "Action", newJString(Action))
  add(query_602991, "Version", newJString(Version))
  if Filters != nil:
    query_602991.add "Filters", Filters
  add(query_602991, "MaxRecords", newJInt(MaxRecords))
  result = call_602990.call(nil, query_602991, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_602971(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_602972, base: "/",
    url: url_GetDescribeDBSnapshots_602973, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_603033 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBSubnetGroups_603035(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSubnetGroups_603034(path: JsonNode; query: JsonNode;
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
  var valid_603036 = query.getOrDefault("Action")
  valid_603036 = validateParameter(valid_603036, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_603036 != nil:
    section.add "Action", valid_603036
  var valid_603037 = query.getOrDefault("Version")
  valid_603037 = validateParameter(valid_603037, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603037 != nil:
    section.add "Version", valid_603037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603038 = header.getOrDefault("X-Amz-Signature")
  valid_603038 = validateParameter(valid_603038, JString, required = false,
                                 default = nil)
  if valid_603038 != nil:
    section.add "X-Amz-Signature", valid_603038
  var valid_603039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603039 = validateParameter(valid_603039, JString, required = false,
                                 default = nil)
  if valid_603039 != nil:
    section.add "X-Amz-Content-Sha256", valid_603039
  var valid_603040 = header.getOrDefault("X-Amz-Date")
  valid_603040 = validateParameter(valid_603040, JString, required = false,
                                 default = nil)
  if valid_603040 != nil:
    section.add "X-Amz-Date", valid_603040
  var valid_603041 = header.getOrDefault("X-Amz-Credential")
  valid_603041 = validateParameter(valid_603041, JString, required = false,
                                 default = nil)
  if valid_603041 != nil:
    section.add "X-Amz-Credential", valid_603041
  var valid_603042 = header.getOrDefault("X-Amz-Security-Token")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Security-Token", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Algorithm")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Algorithm", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-SignedHeaders", valid_603044
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603045 = formData.getOrDefault("MaxRecords")
  valid_603045 = validateParameter(valid_603045, JInt, required = false, default = nil)
  if valid_603045 != nil:
    section.add "MaxRecords", valid_603045
  var valid_603046 = formData.getOrDefault("Marker")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "Marker", valid_603046
  var valid_603047 = formData.getOrDefault("DBSubnetGroupName")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "DBSubnetGroupName", valid_603047
  var valid_603048 = formData.getOrDefault("Filters")
  valid_603048 = validateParameter(valid_603048, JArray, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "Filters", valid_603048
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603049: Call_PostDescribeDBSubnetGroups_603033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603049.validator(path, query, header, formData, body)
  let scheme = call_603049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603049.url(scheme.get, call_603049.host, call_603049.base,
                         call_603049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603049, url, valid)

proc call*(call_603050: Call_PostDescribeDBSubnetGroups_603033;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603051 = newJObject()
  var formData_603052 = newJObject()
  add(formData_603052, "MaxRecords", newJInt(MaxRecords))
  add(formData_603052, "Marker", newJString(Marker))
  add(query_603051, "Action", newJString(Action))
  add(formData_603052, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_603052.add "Filters", Filters
  add(query_603051, "Version", newJString(Version))
  result = call_603050.call(nil, query_603051, nil, formData_603052, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_603033(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_603034, base: "/",
    url: url_PostDescribeDBSubnetGroups_603035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_603014 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBSubnetGroups_603016(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSubnetGroups_603015(path: JsonNode; query: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603017 = query.getOrDefault("Marker")
  valid_603017 = validateParameter(valid_603017, JString, required = false,
                                 default = nil)
  if valid_603017 != nil:
    section.add "Marker", valid_603017
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603018 = query.getOrDefault("Action")
  valid_603018 = validateParameter(valid_603018, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_603018 != nil:
    section.add "Action", valid_603018
  var valid_603019 = query.getOrDefault("DBSubnetGroupName")
  valid_603019 = validateParameter(valid_603019, JString, required = false,
                                 default = nil)
  if valid_603019 != nil:
    section.add "DBSubnetGroupName", valid_603019
  var valid_603020 = query.getOrDefault("Version")
  valid_603020 = validateParameter(valid_603020, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603020 != nil:
    section.add "Version", valid_603020
  var valid_603021 = query.getOrDefault("Filters")
  valid_603021 = validateParameter(valid_603021, JArray, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "Filters", valid_603021
  var valid_603022 = query.getOrDefault("MaxRecords")
  valid_603022 = validateParameter(valid_603022, JInt, required = false, default = nil)
  if valid_603022 != nil:
    section.add "MaxRecords", valid_603022
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603023 = header.getOrDefault("X-Amz-Signature")
  valid_603023 = validateParameter(valid_603023, JString, required = false,
                                 default = nil)
  if valid_603023 != nil:
    section.add "X-Amz-Signature", valid_603023
  var valid_603024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603024 = validateParameter(valid_603024, JString, required = false,
                                 default = nil)
  if valid_603024 != nil:
    section.add "X-Amz-Content-Sha256", valid_603024
  var valid_603025 = header.getOrDefault("X-Amz-Date")
  valid_603025 = validateParameter(valid_603025, JString, required = false,
                                 default = nil)
  if valid_603025 != nil:
    section.add "X-Amz-Date", valid_603025
  var valid_603026 = header.getOrDefault("X-Amz-Credential")
  valid_603026 = validateParameter(valid_603026, JString, required = false,
                                 default = nil)
  if valid_603026 != nil:
    section.add "X-Amz-Credential", valid_603026
  var valid_603027 = header.getOrDefault("X-Amz-Security-Token")
  valid_603027 = validateParameter(valid_603027, JString, required = false,
                                 default = nil)
  if valid_603027 != nil:
    section.add "X-Amz-Security-Token", valid_603027
  var valid_603028 = header.getOrDefault("X-Amz-Algorithm")
  valid_603028 = validateParameter(valid_603028, JString, required = false,
                                 default = nil)
  if valid_603028 != nil:
    section.add "X-Amz-Algorithm", valid_603028
  var valid_603029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "X-Amz-SignedHeaders", valid_603029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603030: Call_GetDescribeDBSubnetGroups_603014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603030.validator(path, query, header, formData, body)
  let scheme = call_603030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603030.url(scheme.get, call_603030.host, call_603030.base,
                         call_603030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603030, url, valid)

proc call*(call_603031: Call_GetDescribeDBSubnetGroups_603014; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_603032 = newJObject()
  add(query_603032, "Marker", newJString(Marker))
  add(query_603032, "Action", newJString(Action))
  add(query_603032, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603032, "Version", newJString(Version))
  if Filters != nil:
    query_603032.add "Filters", Filters
  add(query_603032, "MaxRecords", newJInt(MaxRecords))
  result = call_603031.call(nil, query_603032, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_603014(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_603015, base: "/",
    url: url_GetDescribeDBSubnetGroups_603016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_603072 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEngineDefaultParameters_603074(protocol: Scheme; host: string;
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

proc validate_PostDescribeEngineDefaultParameters_603073(path: JsonNode;
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
  var valid_603075 = query.getOrDefault("Action")
  valid_603075 = validateParameter(valid_603075, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_603075 != nil:
    section.add "Action", valid_603075
  var valid_603076 = query.getOrDefault("Version")
  valid_603076 = validateParameter(valid_603076, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603076 != nil:
    section.add "Version", valid_603076
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603077 = header.getOrDefault("X-Amz-Signature")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Signature", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Date")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Date", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Credential")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Credential", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Security-Token")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Security-Token", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Algorithm")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Algorithm", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-SignedHeaders", valid_603083
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_603084 = formData.getOrDefault("MaxRecords")
  valid_603084 = validateParameter(valid_603084, JInt, required = false, default = nil)
  if valid_603084 != nil:
    section.add "MaxRecords", valid_603084
  var valid_603085 = formData.getOrDefault("Marker")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "Marker", valid_603085
  var valid_603086 = formData.getOrDefault("Filters")
  valid_603086 = validateParameter(valid_603086, JArray, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "Filters", valid_603086
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_603087 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603087 = validateParameter(valid_603087, JString, required = true,
                                 default = nil)
  if valid_603087 != nil:
    section.add "DBParameterGroupFamily", valid_603087
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603088: Call_PostDescribeEngineDefaultParameters_603072;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603088.validator(path, query, header, formData, body)
  let scheme = call_603088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603088.url(scheme.get, call_603088.host, call_603088.base,
                         call_603088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603088, url, valid)

proc call*(call_603089: Call_PostDescribeEngineDefaultParameters_603072;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_603090 = newJObject()
  var formData_603091 = newJObject()
  add(formData_603091, "MaxRecords", newJInt(MaxRecords))
  add(formData_603091, "Marker", newJString(Marker))
  add(query_603090, "Action", newJString(Action))
  if Filters != nil:
    formData_603091.add "Filters", Filters
  add(query_603090, "Version", newJString(Version))
  add(formData_603091, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_603089.call(nil, query_603090, nil, formData_603091, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_603072(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_603073, base: "/",
    url: url_PostDescribeEngineDefaultParameters_603074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_603053 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEngineDefaultParameters_603055(protocol: Scheme; host: string;
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

proc validate_GetDescribeEngineDefaultParameters_603054(path: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603056 = query.getOrDefault("Marker")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "Marker", valid_603056
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_603057 = query.getOrDefault("DBParameterGroupFamily")
  valid_603057 = validateParameter(valid_603057, JString, required = true,
                                 default = nil)
  if valid_603057 != nil:
    section.add "DBParameterGroupFamily", valid_603057
  var valid_603058 = query.getOrDefault("Action")
  valid_603058 = validateParameter(valid_603058, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_603058 != nil:
    section.add "Action", valid_603058
  var valid_603059 = query.getOrDefault("Version")
  valid_603059 = validateParameter(valid_603059, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603059 != nil:
    section.add "Version", valid_603059
  var valid_603060 = query.getOrDefault("Filters")
  valid_603060 = validateParameter(valid_603060, JArray, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "Filters", valid_603060
  var valid_603061 = query.getOrDefault("MaxRecords")
  valid_603061 = validateParameter(valid_603061, JInt, required = false, default = nil)
  if valid_603061 != nil:
    section.add "MaxRecords", valid_603061
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603062 = header.getOrDefault("X-Amz-Signature")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Signature", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Content-Sha256", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Date")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Date", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Credential")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Credential", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Security-Token")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Security-Token", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Algorithm")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Algorithm", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-SignedHeaders", valid_603068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603069: Call_GetDescribeEngineDefaultParameters_603053;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603069.validator(path, query, header, formData, body)
  let scheme = call_603069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603069.url(scheme.get, call_603069.host, call_603069.base,
                         call_603069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603069, url, valid)

proc call*(call_603070: Call_GetDescribeEngineDefaultParameters_603053;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_603071 = newJObject()
  add(query_603071, "Marker", newJString(Marker))
  add(query_603071, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_603071, "Action", newJString(Action))
  add(query_603071, "Version", newJString(Version))
  if Filters != nil:
    query_603071.add "Filters", Filters
  add(query_603071, "MaxRecords", newJInt(MaxRecords))
  result = call_603070.call(nil, query_603071, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_603053(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_603054, base: "/",
    url: url_GetDescribeEngineDefaultParameters_603055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_603109 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEventCategories_603111(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventCategories_603110(path: JsonNode; query: JsonNode;
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
  var valid_603112 = query.getOrDefault("Action")
  valid_603112 = validateParameter(valid_603112, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_603112 != nil:
    section.add "Action", valid_603112
  var valid_603113 = query.getOrDefault("Version")
  valid_603113 = validateParameter(valid_603113, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603113 != nil:
    section.add "Version", valid_603113
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603114 = header.getOrDefault("X-Amz-Signature")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Signature", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Content-Sha256", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Date")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Date", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Credential")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Credential", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Security-Token")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Security-Token", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Algorithm")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Algorithm", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-SignedHeaders", valid_603120
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603121 = formData.getOrDefault("SourceType")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "SourceType", valid_603121
  var valid_603122 = formData.getOrDefault("Filters")
  valid_603122 = validateParameter(valid_603122, JArray, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "Filters", valid_603122
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603123: Call_PostDescribeEventCategories_603109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603123.validator(path, query, header, formData, body)
  let scheme = call_603123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603123.url(scheme.get, call_603123.host, call_603123.base,
                         call_603123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603123, url, valid)

proc call*(call_603124: Call_PostDescribeEventCategories_603109;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603125 = newJObject()
  var formData_603126 = newJObject()
  add(formData_603126, "SourceType", newJString(SourceType))
  add(query_603125, "Action", newJString(Action))
  if Filters != nil:
    formData_603126.add "Filters", Filters
  add(query_603125, "Version", newJString(Version))
  result = call_603124.call(nil, query_603125, nil, formData_603126, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_603109(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_603110, base: "/",
    url: url_PostDescribeEventCategories_603111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_603092 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEventCategories_603094(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventCategories_603093(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  section = newJObject()
  var valid_603095 = query.getOrDefault("SourceType")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "SourceType", valid_603095
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603096 = query.getOrDefault("Action")
  valid_603096 = validateParameter(valid_603096, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_603096 != nil:
    section.add "Action", valid_603096
  var valid_603097 = query.getOrDefault("Version")
  valid_603097 = validateParameter(valid_603097, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603097 != nil:
    section.add "Version", valid_603097
  var valid_603098 = query.getOrDefault("Filters")
  valid_603098 = validateParameter(valid_603098, JArray, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "Filters", valid_603098
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603099 = header.getOrDefault("X-Amz-Signature")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Signature", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Content-Sha256", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Date")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Date", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Credential")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Credential", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Security-Token")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Security-Token", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Algorithm")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Algorithm", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-SignedHeaders", valid_603105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603106: Call_GetDescribeEventCategories_603092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603106.validator(path, query, header, formData, body)
  let scheme = call_603106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603106.url(scheme.get, call_603106.host, call_603106.base,
                         call_603106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603106, url, valid)

proc call*(call_603107: Call_GetDescribeEventCategories_603092;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-09-09"; Filters: JsonNode = nil): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_603108 = newJObject()
  add(query_603108, "SourceType", newJString(SourceType))
  add(query_603108, "Action", newJString(Action))
  add(query_603108, "Version", newJString(Version))
  if Filters != nil:
    query_603108.add "Filters", Filters
  result = call_603107.call(nil, query_603108, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_603092(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_603093, base: "/",
    url: url_GetDescribeEventCategories_603094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_603146 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEventSubscriptions_603148(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventSubscriptions_603147(path: JsonNode;
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
  var valid_603149 = query.getOrDefault("Action")
  valid_603149 = validateParameter(valid_603149, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_603149 != nil:
    section.add "Action", valid_603149
  var valid_603150 = query.getOrDefault("Version")
  valid_603150 = validateParameter(valid_603150, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603150 != nil:
    section.add "Version", valid_603150
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603151 = header.getOrDefault("X-Amz-Signature")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Signature", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Content-Sha256", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Date")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Date", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Credential")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Credential", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Security-Token")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Security-Token", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Algorithm")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Algorithm", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-SignedHeaders", valid_603157
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603158 = formData.getOrDefault("MaxRecords")
  valid_603158 = validateParameter(valid_603158, JInt, required = false, default = nil)
  if valid_603158 != nil:
    section.add "MaxRecords", valid_603158
  var valid_603159 = formData.getOrDefault("Marker")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "Marker", valid_603159
  var valid_603160 = formData.getOrDefault("SubscriptionName")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "SubscriptionName", valid_603160
  var valid_603161 = formData.getOrDefault("Filters")
  valid_603161 = validateParameter(valid_603161, JArray, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "Filters", valid_603161
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603162: Call_PostDescribeEventSubscriptions_603146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603162.validator(path, query, header, formData, body)
  let scheme = call_603162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603162.url(scheme.get, call_603162.host, call_603162.base,
                         call_603162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603162, url, valid)

proc call*(call_603163: Call_PostDescribeEventSubscriptions_603146;
          MaxRecords: int = 0; Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603164 = newJObject()
  var formData_603165 = newJObject()
  add(formData_603165, "MaxRecords", newJInt(MaxRecords))
  add(formData_603165, "Marker", newJString(Marker))
  add(formData_603165, "SubscriptionName", newJString(SubscriptionName))
  add(query_603164, "Action", newJString(Action))
  if Filters != nil:
    formData_603165.add "Filters", Filters
  add(query_603164, "Version", newJString(Version))
  result = call_603163.call(nil, query_603164, nil, formData_603165, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_603146(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_603147, base: "/",
    url: url_PostDescribeEventSubscriptions_603148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_603127 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEventSubscriptions_603129(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventSubscriptions_603128(path: JsonNode; query: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603130 = query.getOrDefault("Marker")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "Marker", valid_603130
  var valid_603131 = query.getOrDefault("SubscriptionName")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "SubscriptionName", valid_603131
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603132 = query.getOrDefault("Action")
  valid_603132 = validateParameter(valid_603132, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_603132 != nil:
    section.add "Action", valid_603132
  var valid_603133 = query.getOrDefault("Version")
  valid_603133 = validateParameter(valid_603133, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603133 != nil:
    section.add "Version", valid_603133
  var valid_603134 = query.getOrDefault("Filters")
  valid_603134 = validateParameter(valid_603134, JArray, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "Filters", valid_603134
  var valid_603135 = query.getOrDefault("MaxRecords")
  valid_603135 = validateParameter(valid_603135, JInt, required = false, default = nil)
  if valid_603135 != nil:
    section.add "MaxRecords", valid_603135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603136 = header.getOrDefault("X-Amz-Signature")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Signature", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Content-Sha256", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Date")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Date", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Credential")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Credential", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Security-Token")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Security-Token", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Algorithm")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Algorithm", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-SignedHeaders", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603143: Call_GetDescribeEventSubscriptions_603127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603143.validator(path, query, header, formData, body)
  let scheme = call_603143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603143.url(scheme.get, call_603143.host, call_603143.base,
                         call_603143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603143, url, valid)

proc call*(call_603144: Call_GetDescribeEventSubscriptions_603127;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_603145 = newJObject()
  add(query_603145, "Marker", newJString(Marker))
  add(query_603145, "SubscriptionName", newJString(SubscriptionName))
  add(query_603145, "Action", newJString(Action))
  add(query_603145, "Version", newJString(Version))
  if Filters != nil:
    query_603145.add "Filters", Filters
  add(query_603145, "MaxRecords", newJInt(MaxRecords))
  result = call_603144.call(nil, query_603145, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_603127(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_603128, base: "/",
    url: url_GetDescribeEventSubscriptions_603129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_603190 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEvents_603192(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_603191(path: JsonNode; query: JsonNode;
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
  var valid_603193 = query.getOrDefault("Action")
  valid_603193 = validateParameter(valid_603193, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_603193 != nil:
    section.add "Action", valid_603193
  var valid_603194 = query.getOrDefault("Version")
  valid_603194 = validateParameter(valid_603194, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   SourceIdentifier: JString
  ##   SourceType: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   StartTime: JString
  ##   EventCategories: JArray
  ##   Filters: JArray
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
  var valid_603204 = formData.getOrDefault("SourceIdentifier")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "SourceIdentifier", valid_603204
  var valid_603205 = formData.getOrDefault("SourceType")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_603205 != nil:
    section.add "SourceType", valid_603205
  var valid_603206 = formData.getOrDefault("Duration")
  valid_603206 = validateParameter(valid_603206, JInt, required = false, default = nil)
  if valid_603206 != nil:
    section.add "Duration", valid_603206
  var valid_603207 = formData.getOrDefault("EndTime")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "EndTime", valid_603207
  var valid_603208 = formData.getOrDefault("StartTime")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "StartTime", valid_603208
  var valid_603209 = formData.getOrDefault("EventCategories")
  valid_603209 = validateParameter(valid_603209, JArray, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "EventCategories", valid_603209
  var valid_603210 = formData.getOrDefault("Filters")
  valid_603210 = validateParameter(valid_603210, JArray, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "Filters", valid_603210
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603211: Call_PostDescribeEvents_603190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603211.validator(path, query, header, formData, body)
  let scheme = call_603211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603211.url(scheme.get, call_603211.host, call_603211.base,
                         call_603211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603211, url, valid)

proc call*(call_603212: Call_PostDescribeEvents_603190; MaxRecords: int = 0;
          Marker: string = ""; SourceIdentifier: string = "";
          SourceType: string = "db-instance"; Duration: int = 0; EndTime: string = "";
          StartTime: string = ""; EventCategories: JsonNode = nil;
          Action: string = "DescribeEvents"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
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
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603213 = newJObject()
  var formData_603214 = newJObject()
  add(formData_603214, "MaxRecords", newJInt(MaxRecords))
  add(formData_603214, "Marker", newJString(Marker))
  add(formData_603214, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_603214, "SourceType", newJString(SourceType))
  add(formData_603214, "Duration", newJInt(Duration))
  add(formData_603214, "EndTime", newJString(EndTime))
  add(formData_603214, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_603214.add "EventCategories", EventCategories
  add(query_603213, "Action", newJString(Action))
  if Filters != nil:
    formData_603214.add "Filters", Filters
  add(query_603213, "Version", newJString(Version))
  result = call_603212.call(nil, query_603213, nil, formData_603214, nil)

var postDescribeEvents* = Call_PostDescribeEvents_603190(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_603191, base: "/",
    url: url_PostDescribeEvents_603192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_603166 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEvents_603168(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_603167(path: JsonNode; query: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603169 = query.getOrDefault("Marker")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "Marker", valid_603169
  var valid_603170 = query.getOrDefault("SourceType")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_603170 != nil:
    section.add "SourceType", valid_603170
  var valid_603171 = query.getOrDefault("SourceIdentifier")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "SourceIdentifier", valid_603171
  var valid_603172 = query.getOrDefault("EventCategories")
  valid_603172 = validateParameter(valid_603172, JArray, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "EventCategories", valid_603172
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603173 = query.getOrDefault("Action")
  valid_603173 = validateParameter(valid_603173, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_603173 != nil:
    section.add "Action", valid_603173
  var valid_603174 = query.getOrDefault("StartTime")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "StartTime", valid_603174
  var valid_603175 = query.getOrDefault("Duration")
  valid_603175 = validateParameter(valid_603175, JInt, required = false, default = nil)
  if valid_603175 != nil:
    section.add "Duration", valid_603175
  var valid_603176 = query.getOrDefault("EndTime")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "EndTime", valid_603176
  var valid_603177 = query.getOrDefault("Version")
  valid_603177 = validateParameter(valid_603177, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603177 != nil:
    section.add "Version", valid_603177
  var valid_603178 = query.getOrDefault("Filters")
  valid_603178 = validateParameter(valid_603178, JArray, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "Filters", valid_603178
  var valid_603179 = query.getOrDefault("MaxRecords")
  valid_603179 = validateParameter(valid_603179, JInt, required = false, default = nil)
  if valid_603179 != nil:
    section.add "MaxRecords", valid_603179
  result.add "query", section
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

proc call*(call_603187: Call_GetDescribeEvents_603166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603187.validator(path, query, header, formData, body)
  let scheme = call_603187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603187.url(scheme.get, call_603187.host, call_603187.base,
                         call_603187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603187, url, valid)

proc call*(call_603188: Call_GetDescribeEvents_603166; Marker: string = "";
          SourceType: string = "db-instance"; SourceIdentifier: string = "";
          EventCategories: JsonNode = nil; Action: string = "DescribeEvents";
          StartTime: string = ""; Duration: int = 0; EndTime: string = "";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
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
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_603189 = newJObject()
  add(query_603189, "Marker", newJString(Marker))
  add(query_603189, "SourceType", newJString(SourceType))
  add(query_603189, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_603189.add "EventCategories", EventCategories
  add(query_603189, "Action", newJString(Action))
  add(query_603189, "StartTime", newJString(StartTime))
  add(query_603189, "Duration", newJInt(Duration))
  add(query_603189, "EndTime", newJString(EndTime))
  add(query_603189, "Version", newJString(Version))
  if Filters != nil:
    query_603189.add "Filters", Filters
  add(query_603189, "MaxRecords", newJInt(MaxRecords))
  result = call_603188.call(nil, query_603189, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_603166(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_603167,
    base: "/", url: url_GetDescribeEvents_603168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_603235 = ref object of OpenApiRestCall_601373
proc url_PostDescribeOptionGroupOptions_603237(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroupOptions_603236(path: JsonNode;
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
  var valid_603238 = query.getOrDefault("Action")
  valid_603238 = validateParameter(valid_603238, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_603238 != nil:
    section.add "Action", valid_603238
  var valid_603239 = query.getOrDefault("Version")
  valid_603239 = validateParameter(valid_603239, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603239 != nil:
    section.add "Version", valid_603239
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603240 = header.getOrDefault("X-Amz-Signature")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Signature", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Content-Sha256", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Date")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Date", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Credential")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Credential", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Security-Token")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Security-Token", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Algorithm")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Algorithm", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603247 = formData.getOrDefault("MaxRecords")
  valid_603247 = validateParameter(valid_603247, JInt, required = false, default = nil)
  if valid_603247 != nil:
    section.add "MaxRecords", valid_603247
  var valid_603248 = formData.getOrDefault("Marker")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "Marker", valid_603248
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_603249 = formData.getOrDefault("EngineName")
  valid_603249 = validateParameter(valid_603249, JString, required = true,
                                 default = nil)
  if valid_603249 != nil:
    section.add "EngineName", valid_603249
  var valid_603250 = formData.getOrDefault("MajorEngineVersion")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "MajorEngineVersion", valid_603250
  var valid_603251 = formData.getOrDefault("Filters")
  valid_603251 = validateParameter(valid_603251, JArray, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "Filters", valid_603251
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603252: Call_PostDescribeOptionGroupOptions_603235; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603252.validator(path, query, header, formData, body)
  let scheme = call_603252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603252.url(scheme.get, call_603252.host, call_603252.base,
                         call_603252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603252, url, valid)

proc call*(call_603253: Call_PostDescribeOptionGroupOptions_603235;
          EngineName: string; MaxRecords: int = 0; Marker: string = "";
          MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroupOptions"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603254 = newJObject()
  var formData_603255 = newJObject()
  add(formData_603255, "MaxRecords", newJInt(MaxRecords))
  add(formData_603255, "Marker", newJString(Marker))
  add(formData_603255, "EngineName", newJString(EngineName))
  add(formData_603255, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_603254, "Action", newJString(Action))
  if Filters != nil:
    formData_603255.add "Filters", Filters
  add(query_603254, "Version", newJString(Version))
  result = call_603253.call(nil, query_603254, nil, formData_603255, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_603235(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_603236, base: "/",
    url: url_PostDescribeOptionGroupOptions_603237,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_603215 = ref object of OpenApiRestCall_601373
proc url_GetDescribeOptionGroupOptions_603217(protocol: Scheme; host: string;
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

proc validate_GetDescribeOptionGroupOptions_603216(path: JsonNode; query: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   MajorEngineVersion: JString
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EngineName` field"
  var valid_603218 = query.getOrDefault("EngineName")
  valid_603218 = validateParameter(valid_603218, JString, required = true,
                                 default = nil)
  if valid_603218 != nil:
    section.add "EngineName", valid_603218
  var valid_603219 = query.getOrDefault("Marker")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "Marker", valid_603219
  var valid_603220 = query.getOrDefault("Action")
  valid_603220 = validateParameter(valid_603220, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_603220 != nil:
    section.add "Action", valid_603220
  var valid_603221 = query.getOrDefault("Version")
  valid_603221 = validateParameter(valid_603221, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603221 != nil:
    section.add "Version", valid_603221
  var valid_603222 = query.getOrDefault("Filters")
  valid_603222 = validateParameter(valid_603222, JArray, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "Filters", valid_603222
  var valid_603223 = query.getOrDefault("MaxRecords")
  valid_603223 = validateParameter(valid_603223, JInt, required = false, default = nil)
  if valid_603223 != nil:
    section.add "MaxRecords", valid_603223
  var valid_603224 = query.getOrDefault("MajorEngineVersion")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "MajorEngineVersion", valid_603224
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603225 = header.getOrDefault("X-Amz-Signature")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Signature", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Content-Sha256", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Date")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Date", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Credential")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Credential", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Security-Token")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Security-Token", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Algorithm")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Algorithm", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603232: Call_GetDescribeOptionGroupOptions_603215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603232.validator(path, query, header, formData, body)
  let scheme = call_603232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603232.url(scheme.get, call_603232.host, call_603232.base,
                         call_603232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603232, url, valid)

proc call*(call_603233: Call_GetDescribeOptionGroupOptions_603215;
          EngineName: string; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   EngineName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_603234 = newJObject()
  add(query_603234, "EngineName", newJString(EngineName))
  add(query_603234, "Marker", newJString(Marker))
  add(query_603234, "Action", newJString(Action))
  add(query_603234, "Version", newJString(Version))
  if Filters != nil:
    query_603234.add "Filters", Filters
  add(query_603234, "MaxRecords", newJInt(MaxRecords))
  add(query_603234, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_603233.call(nil, query_603234, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_603215(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_603216, base: "/",
    url: url_GetDescribeOptionGroupOptions_603217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_603277 = ref object of OpenApiRestCall_601373
proc url_PostDescribeOptionGroups_603279(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroups_603278(path: JsonNode; query: JsonNode;
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
  var valid_603280 = query.getOrDefault("Action")
  valid_603280 = validateParameter(valid_603280, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_603280 != nil:
    section.add "Action", valid_603280
  var valid_603281 = query.getOrDefault("Version")
  valid_603281 = validateParameter(valid_603281, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603289 = formData.getOrDefault("MaxRecords")
  valid_603289 = validateParameter(valid_603289, JInt, required = false, default = nil)
  if valid_603289 != nil:
    section.add "MaxRecords", valid_603289
  var valid_603290 = formData.getOrDefault("Marker")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "Marker", valid_603290
  var valid_603291 = formData.getOrDefault("EngineName")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "EngineName", valid_603291
  var valid_603292 = formData.getOrDefault("MajorEngineVersion")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "MajorEngineVersion", valid_603292
  var valid_603293 = formData.getOrDefault("OptionGroupName")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "OptionGroupName", valid_603293
  var valid_603294 = formData.getOrDefault("Filters")
  valid_603294 = validateParameter(valid_603294, JArray, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "Filters", valid_603294
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603295: Call_PostDescribeOptionGroups_603277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603295.validator(path, query, header, formData, body)
  let scheme = call_603295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603295.url(scheme.get, call_603295.host, call_603295.base,
                         call_603295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603295, url, valid)

proc call*(call_603296: Call_PostDescribeOptionGroups_603277; MaxRecords: int = 0;
          Marker: string = ""; EngineName: string = ""; MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeOptionGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603297 = newJObject()
  var formData_603298 = newJObject()
  add(formData_603298, "MaxRecords", newJInt(MaxRecords))
  add(formData_603298, "Marker", newJString(Marker))
  add(formData_603298, "EngineName", newJString(EngineName))
  add(formData_603298, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_603297, "Action", newJString(Action))
  add(formData_603298, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    formData_603298.add "Filters", Filters
  add(query_603297, "Version", newJString(Version))
  result = call_603296.call(nil, query_603297, nil, formData_603298, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_603277(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_603278, base: "/",
    url: url_PostDescribeOptionGroups_603279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_603256 = ref object of OpenApiRestCall_601373
proc url_GetDescribeOptionGroups_603258(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeOptionGroups_603257(path: JsonNode; query: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_603259 = query.getOrDefault("EngineName")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "EngineName", valid_603259
  var valid_603260 = query.getOrDefault("Marker")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "Marker", valid_603260
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603261 = query.getOrDefault("Action")
  valid_603261 = validateParameter(valid_603261, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_603261 != nil:
    section.add "Action", valid_603261
  var valid_603262 = query.getOrDefault("OptionGroupName")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "OptionGroupName", valid_603262
  var valid_603263 = query.getOrDefault("Version")
  valid_603263 = validateParameter(valid_603263, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603263 != nil:
    section.add "Version", valid_603263
  var valid_603264 = query.getOrDefault("Filters")
  valid_603264 = validateParameter(valid_603264, JArray, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "Filters", valid_603264
  var valid_603265 = query.getOrDefault("MaxRecords")
  valid_603265 = validateParameter(valid_603265, JInt, required = false, default = nil)
  if valid_603265 != nil:
    section.add "MaxRecords", valid_603265
  var valid_603266 = query.getOrDefault("MajorEngineVersion")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "MajorEngineVersion", valid_603266
  result.add "query", section
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

proc call*(call_603274: Call_GetDescribeOptionGroups_603256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603274.validator(path, query, header, formData, body)
  let scheme = call_603274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603274.url(scheme.get, call_603274.host, call_603274.base,
                         call_603274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603274, url, valid)

proc call*(call_603275: Call_GetDescribeOptionGroups_603256;
          EngineName: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   EngineName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_603276 = newJObject()
  add(query_603276, "EngineName", newJString(EngineName))
  add(query_603276, "Marker", newJString(Marker))
  add(query_603276, "Action", newJString(Action))
  add(query_603276, "OptionGroupName", newJString(OptionGroupName))
  add(query_603276, "Version", newJString(Version))
  if Filters != nil:
    query_603276.add "Filters", Filters
  add(query_603276, "MaxRecords", newJInt(MaxRecords))
  add(query_603276, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_603275.call(nil, query_603276, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_603256(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_603257, base: "/",
    url: url_GetDescribeOptionGroups_603258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_603322 = ref object of OpenApiRestCall_601373
proc url_PostDescribeOrderableDBInstanceOptions_603324(protocol: Scheme;
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

proc validate_PostDescribeOrderableDBInstanceOptions_603323(path: JsonNode;
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
  var valid_603325 = query.getOrDefault("Action")
  valid_603325 = validateParameter(valid_603325, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_603325 != nil:
    section.add "Action", valid_603325
  var valid_603326 = query.getOrDefault("Version")
  valid_603326 = validateParameter(valid_603326, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603326 != nil:
    section.add "Version", valid_603326
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603327 = header.getOrDefault("X-Amz-Signature")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Signature", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Content-Sha256", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Date")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Date", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Credential")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Credential", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Algorithm")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Algorithm", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-SignedHeaders", valid_603333
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   Marker: JString
  ##   Engine: JString (required)
  ##   Vpc: JBool
  ##   LicenseModel: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603334 = formData.getOrDefault("DBInstanceClass")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "DBInstanceClass", valid_603334
  var valid_603335 = formData.getOrDefault("MaxRecords")
  valid_603335 = validateParameter(valid_603335, JInt, required = false, default = nil)
  if valid_603335 != nil:
    section.add "MaxRecords", valid_603335
  var valid_603336 = formData.getOrDefault("EngineVersion")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "EngineVersion", valid_603336
  var valid_603337 = formData.getOrDefault("Marker")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "Marker", valid_603337
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_603338 = formData.getOrDefault("Engine")
  valid_603338 = validateParameter(valid_603338, JString, required = true,
                                 default = nil)
  if valid_603338 != nil:
    section.add "Engine", valid_603338
  var valid_603339 = formData.getOrDefault("Vpc")
  valid_603339 = validateParameter(valid_603339, JBool, required = false, default = nil)
  if valid_603339 != nil:
    section.add "Vpc", valid_603339
  var valid_603340 = formData.getOrDefault("LicenseModel")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "LicenseModel", valid_603340
  var valid_603341 = formData.getOrDefault("Filters")
  valid_603341 = validateParameter(valid_603341, JArray, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "Filters", valid_603341
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603342: Call_PostDescribeOrderableDBInstanceOptions_603322;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603342.validator(path, query, header, formData, body)
  let scheme = call_603342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603342.url(scheme.get, call_603342.host, call_603342.base,
                         call_603342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603342, url, valid)

proc call*(call_603343: Call_PostDescribeOrderableDBInstanceOptions_603322;
          Engine: string; DBInstanceClass: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Marker: string = ""; Vpc: bool = false;
          Action: string = "DescribeOrderableDBInstanceOptions";
          LicenseModel: string = ""; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ##   DBInstanceClass: string
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Marker: string
  ##   Engine: string (required)
  ##   Vpc: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603344 = newJObject()
  var formData_603345 = newJObject()
  add(formData_603345, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603345, "MaxRecords", newJInt(MaxRecords))
  add(formData_603345, "EngineVersion", newJString(EngineVersion))
  add(formData_603345, "Marker", newJString(Marker))
  add(formData_603345, "Engine", newJString(Engine))
  add(formData_603345, "Vpc", newJBool(Vpc))
  add(query_603344, "Action", newJString(Action))
  add(formData_603345, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_603345.add "Filters", Filters
  add(query_603344, "Version", newJString(Version))
  result = call_603343.call(nil, query_603344, nil, formData_603345, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_603322(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_603323, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_603324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_603299 = ref object of OpenApiRestCall_601373
proc url_GetDescribeOrderableDBInstanceOptions_603301(protocol: Scheme;
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

proc validate_GetDescribeOrderableDBInstanceOptions_603300(path: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603302 = query.getOrDefault("Marker")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "Marker", valid_603302
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_603303 = query.getOrDefault("Engine")
  valid_603303 = validateParameter(valid_603303, JString, required = true,
                                 default = nil)
  if valid_603303 != nil:
    section.add "Engine", valid_603303
  var valid_603304 = query.getOrDefault("LicenseModel")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "LicenseModel", valid_603304
  var valid_603305 = query.getOrDefault("Vpc")
  valid_603305 = validateParameter(valid_603305, JBool, required = false, default = nil)
  if valid_603305 != nil:
    section.add "Vpc", valid_603305
  var valid_603306 = query.getOrDefault("EngineVersion")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "EngineVersion", valid_603306
  var valid_603307 = query.getOrDefault("Action")
  valid_603307 = validateParameter(valid_603307, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_603307 != nil:
    section.add "Action", valid_603307
  var valid_603308 = query.getOrDefault("Version")
  valid_603308 = validateParameter(valid_603308, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603308 != nil:
    section.add "Version", valid_603308
  var valid_603309 = query.getOrDefault("DBInstanceClass")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "DBInstanceClass", valid_603309
  var valid_603310 = query.getOrDefault("Filters")
  valid_603310 = validateParameter(valid_603310, JArray, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "Filters", valid_603310
  var valid_603311 = query.getOrDefault("MaxRecords")
  valid_603311 = validateParameter(valid_603311, JInt, required = false, default = nil)
  if valid_603311 != nil:
    section.add "MaxRecords", valid_603311
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603312 = header.getOrDefault("X-Amz-Signature")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Signature", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Content-Sha256", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Date")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Date", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Credential")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Credential", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Algorithm")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Algorithm", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-SignedHeaders", valid_603318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603319: Call_GetDescribeOrderableDBInstanceOptions_603299;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603319.validator(path, query, header, formData, body)
  let scheme = call_603319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603319.url(scheme.get, call_603319.host, call_603319.base,
                         call_603319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603319, url, valid)

proc call*(call_603320: Call_GetDescribeOrderableDBInstanceOptions_603299;
          Engine: string; Marker: string = ""; LicenseModel: string = "";
          Vpc: bool = false; EngineVersion: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Version: string = "2013-09-09"; DBInstanceClass: string = "";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ##   Marker: string
  ##   Engine: string (required)
  ##   LicenseModel: string
  ##   Vpc: bool
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_603321 = newJObject()
  add(query_603321, "Marker", newJString(Marker))
  add(query_603321, "Engine", newJString(Engine))
  add(query_603321, "LicenseModel", newJString(LicenseModel))
  add(query_603321, "Vpc", newJBool(Vpc))
  add(query_603321, "EngineVersion", newJString(EngineVersion))
  add(query_603321, "Action", newJString(Action))
  add(query_603321, "Version", newJString(Version))
  add(query_603321, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_603321.add "Filters", Filters
  add(query_603321, "MaxRecords", newJInt(MaxRecords))
  result = call_603320.call(nil, query_603321, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_603299(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_603300, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_603301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_603371 = ref object of OpenApiRestCall_601373
proc url_PostDescribeReservedDBInstances_603373(protocol: Scheme; host: string;
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

proc validate_PostDescribeReservedDBInstances_603372(path: JsonNode;
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
  var valid_603374 = query.getOrDefault("Action")
  valid_603374 = validateParameter(valid_603374, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_603374 != nil:
    section.add "Action", valid_603374
  var valid_603375 = query.getOrDefault("Version")
  valid_603375 = validateParameter(valid_603375, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603375 != nil:
    section.add "Version", valid_603375
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603376 = header.getOrDefault("X-Amz-Signature")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Signature", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Content-Sha256", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Date")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Date", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Credential")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Credential", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Security-Token")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Security-Token", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-Algorithm")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Algorithm", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-SignedHeaders", valid_603382
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
  ##   Filters: JArray
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_603383 = formData.getOrDefault("DBInstanceClass")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "DBInstanceClass", valid_603383
  var valid_603384 = formData.getOrDefault("MultiAZ")
  valid_603384 = validateParameter(valid_603384, JBool, required = false, default = nil)
  if valid_603384 != nil:
    section.add "MultiAZ", valid_603384
  var valid_603385 = formData.getOrDefault("MaxRecords")
  valid_603385 = validateParameter(valid_603385, JInt, required = false, default = nil)
  if valid_603385 != nil:
    section.add "MaxRecords", valid_603385
  var valid_603386 = formData.getOrDefault("ReservedDBInstanceId")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "ReservedDBInstanceId", valid_603386
  var valid_603387 = formData.getOrDefault("Marker")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "Marker", valid_603387
  var valid_603388 = formData.getOrDefault("Duration")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "Duration", valid_603388
  var valid_603389 = formData.getOrDefault("OfferingType")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "OfferingType", valid_603389
  var valid_603390 = formData.getOrDefault("ProductDescription")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "ProductDescription", valid_603390
  var valid_603391 = formData.getOrDefault("Filters")
  valid_603391 = validateParameter(valid_603391, JArray, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "Filters", valid_603391
  var valid_603392 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603392
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603393: Call_PostDescribeReservedDBInstances_603371;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603393.validator(path, query, header, formData, body)
  let scheme = call_603393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603393.url(scheme.get, call_603393.host, call_603393.base,
                         call_603393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603393, url, valid)

proc call*(call_603394: Call_PostDescribeReservedDBInstances_603371;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          ReservedDBInstanceId: string = ""; Marker: string = ""; Duration: string = "";
          OfferingType: string = ""; ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstances"; Filters: JsonNode = nil;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-09-09"): Recallable =
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
  ##   Filters: JArray
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_603395 = newJObject()
  var formData_603396 = newJObject()
  add(formData_603396, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603396, "MultiAZ", newJBool(MultiAZ))
  add(formData_603396, "MaxRecords", newJInt(MaxRecords))
  add(formData_603396, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_603396, "Marker", newJString(Marker))
  add(formData_603396, "Duration", newJString(Duration))
  add(formData_603396, "OfferingType", newJString(OfferingType))
  add(formData_603396, "ProductDescription", newJString(ProductDescription))
  add(query_603395, "Action", newJString(Action))
  if Filters != nil:
    formData_603396.add "Filters", Filters
  add(formData_603396, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603395, "Version", newJString(Version))
  result = call_603394.call(nil, query_603395, nil, formData_603396, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_603371(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_603372, base: "/",
    url: url_PostDescribeReservedDBInstances_603373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_603346 = ref object of OpenApiRestCall_601373
proc url_GetDescribeReservedDBInstances_603348(protocol: Scheme; host: string;
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

proc validate_GetDescribeReservedDBInstances_603347(path: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603349 = query.getOrDefault("Marker")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "Marker", valid_603349
  var valid_603350 = query.getOrDefault("ProductDescription")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "ProductDescription", valid_603350
  var valid_603351 = query.getOrDefault("OfferingType")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "OfferingType", valid_603351
  var valid_603352 = query.getOrDefault("ReservedDBInstanceId")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "ReservedDBInstanceId", valid_603352
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603353 = query.getOrDefault("Action")
  valid_603353 = validateParameter(valid_603353, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_603353 != nil:
    section.add "Action", valid_603353
  var valid_603354 = query.getOrDefault("MultiAZ")
  valid_603354 = validateParameter(valid_603354, JBool, required = false, default = nil)
  if valid_603354 != nil:
    section.add "MultiAZ", valid_603354
  var valid_603355 = query.getOrDefault("Duration")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "Duration", valid_603355
  var valid_603356 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603356
  var valid_603357 = query.getOrDefault("Version")
  valid_603357 = validateParameter(valid_603357, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603357 != nil:
    section.add "Version", valid_603357
  var valid_603358 = query.getOrDefault("DBInstanceClass")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "DBInstanceClass", valid_603358
  var valid_603359 = query.getOrDefault("Filters")
  valid_603359 = validateParameter(valid_603359, JArray, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "Filters", valid_603359
  var valid_603360 = query.getOrDefault("MaxRecords")
  valid_603360 = validateParameter(valid_603360, JInt, required = false, default = nil)
  if valid_603360 != nil:
    section.add "MaxRecords", valid_603360
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603361 = header.getOrDefault("X-Amz-Signature")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Signature", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Content-Sha256", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Date")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Date", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Credential")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Credential", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Security-Token")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Security-Token", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Algorithm")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Algorithm", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-SignedHeaders", valid_603367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603368: Call_GetDescribeReservedDBInstances_603346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603368.validator(path, query, header, formData, body)
  let scheme = call_603368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603368.url(scheme.get, call_603368.host, call_603368.base,
                         call_603368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603368, url, valid)

proc call*(call_603369: Call_GetDescribeReservedDBInstances_603346;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Action: string = "DescribeReservedDBInstances"; MultiAZ: bool = false;
          Duration: string = ""; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-09-09"; DBInstanceClass: string = "";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
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
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_603370 = newJObject()
  add(query_603370, "Marker", newJString(Marker))
  add(query_603370, "ProductDescription", newJString(ProductDescription))
  add(query_603370, "OfferingType", newJString(OfferingType))
  add(query_603370, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_603370, "Action", newJString(Action))
  add(query_603370, "MultiAZ", newJBool(MultiAZ))
  add(query_603370, "Duration", newJString(Duration))
  add(query_603370, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603370, "Version", newJString(Version))
  add(query_603370, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_603370.add "Filters", Filters
  add(query_603370, "MaxRecords", newJInt(MaxRecords))
  result = call_603369.call(nil, query_603370, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_603346(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_603347, base: "/",
    url: url_GetDescribeReservedDBInstances_603348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_603421 = ref object of OpenApiRestCall_601373
proc url_PostDescribeReservedDBInstancesOfferings_603423(protocol: Scheme;
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

proc validate_PostDescribeReservedDBInstancesOfferings_603422(path: JsonNode;
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
  var valid_603424 = query.getOrDefault("Action")
  valid_603424 = validateParameter(valid_603424, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_603424 != nil:
    section.add "Action", valid_603424
  var valid_603425 = query.getOrDefault("Version")
  valid_603425 = validateParameter(valid_603425, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603425 != nil:
    section.add "Version", valid_603425
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603426 = header.getOrDefault("X-Amz-Signature")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Signature", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Content-Sha256", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Date")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Date", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Credential")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Credential", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Security-Token")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Security-Token", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Algorithm")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Algorithm", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-SignedHeaders", valid_603432
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Duration: JString
  ##   OfferingType: JString
  ##   ProductDescription: JString
  ##   Filters: JArray
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_603433 = formData.getOrDefault("DBInstanceClass")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "DBInstanceClass", valid_603433
  var valid_603434 = formData.getOrDefault("MultiAZ")
  valid_603434 = validateParameter(valid_603434, JBool, required = false, default = nil)
  if valid_603434 != nil:
    section.add "MultiAZ", valid_603434
  var valid_603435 = formData.getOrDefault("MaxRecords")
  valid_603435 = validateParameter(valid_603435, JInt, required = false, default = nil)
  if valid_603435 != nil:
    section.add "MaxRecords", valid_603435
  var valid_603436 = formData.getOrDefault("Marker")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "Marker", valid_603436
  var valid_603437 = formData.getOrDefault("Duration")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "Duration", valid_603437
  var valid_603438 = formData.getOrDefault("OfferingType")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "OfferingType", valid_603438
  var valid_603439 = formData.getOrDefault("ProductDescription")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "ProductDescription", valid_603439
  var valid_603440 = formData.getOrDefault("Filters")
  valid_603440 = validateParameter(valid_603440, JArray, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "Filters", valid_603440
  var valid_603441 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603441
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603442: Call_PostDescribeReservedDBInstancesOfferings_603421;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603442.validator(path, query, header, formData, body)
  let scheme = call_603442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603442.url(scheme.get, call_603442.host, call_603442.base,
                         call_603442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603442, url, valid)

proc call*(call_603443: Call_PostDescribeReservedDBInstancesOfferings_603421;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          Marker: string = ""; Duration: string = ""; OfferingType: string = "";
          ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          Filters: JsonNode = nil; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeReservedDBInstancesOfferings
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   MaxRecords: int
  ##   Marker: string
  ##   Duration: string
  ##   OfferingType: string
  ##   ProductDescription: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_603444 = newJObject()
  var formData_603445 = newJObject()
  add(formData_603445, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603445, "MultiAZ", newJBool(MultiAZ))
  add(formData_603445, "MaxRecords", newJInt(MaxRecords))
  add(formData_603445, "Marker", newJString(Marker))
  add(formData_603445, "Duration", newJString(Duration))
  add(formData_603445, "OfferingType", newJString(OfferingType))
  add(formData_603445, "ProductDescription", newJString(ProductDescription))
  add(query_603444, "Action", newJString(Action))
  if Filters != nil:
    formData_603445.add "Filters", Filters
  add(formData_603445, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603444, "Version", newJString(Version))
  result = call_603443.call(nil, query_603444, nil, formData_603445, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_603421(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_603422,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_603423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_603397 = ref object of OpenApiRestCall_601373
proc url_GetDescribeReservedDBInstancesOfferings_603399(protocol: Scheme;
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

proc validate_GetDescribeReservedDBInstancesOfferings_603398(path: JsonNode;
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
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603400 = query.getOrDefault("Marker")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "Marker", valid_603400
  var valid_603401 = query.getOrDefault("ProductDescription")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "ProductDescription", valid_603401
  var valid_603402 = query.getOrDefault("OfferingType")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "OfferingType", valid_603402
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603403 = query.getOrDefault("Action")
  valid_603403 = validateParameter(valid_603403, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_603403 != nil:
    section.add "Action", valid_603403
  var valid_603404 = query.getOrDefault("MultiAZ")
  valid_603404 = validateParameter(valid_603404, JBool, required = false, default = nil)
  if valid_603404 != nil:
    section.add "MultiAZ", valid_603404
  var valid_603405 = query.getOrDefault("Duration")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "Duration", valid_603405
  var valid_603406 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603406
  var valid_603407 = query.getOrDefault("Version")
  valid_603407 = validateParameter(valid_603407, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603407 != nil:
    section.add "Version", valid_603407
  var valid_603408 = query.getOrDefault("DBInstanceClass")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "DBInstanceClass", valid_603408
  var valid_603409 = query.getOrDefault("Filters")
  valid_603409 = validateParameter(valid_603409, JArray, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "Filters", valid_603409
  var valid_603410 = query.getOrDefault("MaxRecords")
  valid_603410 = validateParameter(valid_603410, JInt, required = false, default = nil)
  if valid_603410 != nil:
    section.add "MaxRecords", valid_603410
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603411 = header.getOrDefault("X-Amz-Signature")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Signature", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Content-Sha256", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Date")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Date", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Credential")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Credential", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Security-Token")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Security-Token", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Algorithm")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Algorithm", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-SignedHeaders", valid_603417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603418: Call_GetDescribeReservedDBInstancesOfferings_603397;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603418.validator(path, query, header, formData, body)
  let scheme = call_603418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603418.url(scheme.get, call_603418.host, call_603418.base,
                         call_603418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603418, url, valid)

proc call*(call_603419: Call_GetDescribeReservedDBInstancesOfferings_603397;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          MultiAZ: bool = false; Duration: string = "";
          ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-09-09"; DBInstanceClass: string = "";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
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
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_603420 = newJObject()
  add(query_603420, "Marker", newJString(Marker))
  add(query_603420, "ProductDescription", newJString(ProductDescription))
  add(query_603420, "OfferingType", newJString(OfferingType))
  add(query_603420, "Action", newJString(Action))
  add(query_603420, "MultiAZ", newJBool(MultiAZ))
  add(query_603420, "Duration", newJString(Duration))
  add(query_603420, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603420, "Version", newJString(Version))
  add(query_603420, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_603420.add "Filters", Filters
  add(query_603420, "MaxRecords", newJInt(MaxRecords))
  result = call_603419.call(nil, query_603420, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_603397(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_603398, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_603399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_603465 = ref object of OpenApiRestCall_601373
proc url_PostDownloadDBLogFilePortion_603467(protocol: Scheme; host: string;
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

proc validate_PostDownloadDBLogFilePortion_603466(path: JsonNode; query: JsonNode;
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
  var valid_603468 = query.getOrDefault("Action")
  valid_603468 = validateParameter(valid_603468, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_603468 != nil:
    section.add "Action", valid_603468
  var valid_603469 = query.getOrDefault("Version")
  valid_603469 = validateParameter(valid_603469, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603469 != nil:
    section.add "Version", valid_603469
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603470 = header.getOrDefault("X-Amz-Signature")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Signature", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Content-Sha256", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Date")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Date", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Credential")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Credential", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Security-Token")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Security-Token", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Algorithm")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Algorithm", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-SignedHeaders", valid_603476
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_603477 = formData.getOrDefault("NumberOfLines")
  valid_603477 = validateParameter(valid_603477, JInt, required = false, default = nil)
  if valid_603477 != nil:
    section.add "NumberOfLines", valid_603477
  var valid_603478 = formData.getOrDefault("Marker")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "Marker", valid_603478
  assert formData != nil,
        "formData argument is necessary due to required `LogFileName` field"
  var valid_603479 = formData.getOrDefault("LogFileName")
  valid_603479 = validateParameter(valid_603479, JString, required = true,
                                 default = nil)
  if valid_603479 != nil:
    section.add "LogFileName", valid_603479
  var valid_603480 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603480 = validateParameter(valid_603480, JString, required = true,
                                 default = nil)
  if valid_603480 != nil:
    section.add "DBInstanceIdentifier", valid_603480
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603481: Call_PostDownloadDBLogFilePortion_603465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603481.validator(path, query, header, formData, body)
  let scheme = call_603481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603481.url(scheme.get, call_603481.host, call_603481.base,
                         call_603481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603481, url, valid)

proc call*(call_603482: Call_PostDownloadDBLogFilePortion_603465;
          LogFileName: string; DBInstanceIdentifier: string; NumberOfLines: int = 0;
          Marker: string = ""; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2013-09-09"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   Marker: string
  ##   LogFileName: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603483 = newJObject()
  var formData_603484 = newJObject()
  add(formData_603484, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_603484, "Marker", newJString(Marker))
  add(formData_603484, "LogFileName", newJString(LogFileName))
  add(formData_603484, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603483, "Action", newJString(Action))
  add(query_603483, "Version", newJString(Version))
  result = call_603482.call(nil, query_603483, nil, formData_603484, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_603465(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_603466, base: "/",
    url: url_PostDownloadDBLogFilePortion_603467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_603446 = ref object of OpenApiRestCall_601373
proc url_GetDownloadDBLogFilePortion_603448(protocol: Scheme; host: string;
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

proc validate_GetDownloadDBLogFilePortion_603447(path: JsonNode; query: JsonNode;
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
  var valid_603449 = query.getOrDefault("Marker")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "Marker", valid_603449
  var valid_603450 = query.getOrDefault("NumberOfLines")
  valid_603450 = validateParameter(valid_603450, JInt, required = false, default = nil)
  if valid_603450 != nil:
    section.add "NumberOfLines", valid_603450
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603451 = query.getOrDefault("DBInstanceIdentifier")
  valid_603451 = validateParameter(valid_603451, JString, required = true,
                                 default = nil)
  if valid_603451 != nil:
    section.add "DBInstanceIdentifier", valid_603451
  var valid_603452 = query.getOrDefault("Action")
  valid_603452 = validateParameter(valid_603452, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_603452 != nil:
    section.add "Action", valid_603452
  var valid_603453 = query.getOrDefault("LogFileName")
  valid_603453 = validateParameter(valid_603453, JString, required = true,
                                 default = nil)
  if valid_603453 != nil:
    section.add "LogFileName", valid_603453
  var valid_603454 = query.getOrDefault("Version")
  valid_603454 = validateParameter(valid_603454, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603454 != nil:
    section.add "Version", valid_603454
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603455 = header.getOrDefault("X-Amz-Signature")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Signature", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Content-Sha256", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Date")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Date", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Credential")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Credential", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Security-Token")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Security-Token", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Algorithm")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Algorithm", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-SignedHeaders", valid_603461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603462: Call_GetDownloadDBLogFilePortion_603446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603462.validator(path, query, header, formData, body)
  let scheme = call_603462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603462.url(scheme.get, call_603462.host, call_603462.base,
                         call_603462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603462, url, valid)

proc call*(call_603463: Call_GetDownloadDBLogFilePortion_603446;
          DBInstanceIdentifier: string; LogFileName: string; Marker: string = "";
          NumberOfLines: int = 0; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2013-09-09"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   Marker: string
  ##   NumberOfLines: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   LogFileName: string (required)
  ##   Version: string (required)
  var query_603464 = newJObject()
  add(query_603464, "Marker", newJString(Marker))
  add(query_603464, "NumberOfLines", newJInt(NumberOfLines))
  add(query_603464, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603464, "Action", newJString(Action))
  add(query_603464, "LogFileName", newJString(LogFileName))
  add(query_603464, "Version", newJString(Version))
  result = call_603463.call(nil, query_603464, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_603446(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_603447, base: "/",
    url: url_GetDownloadDBLogFilePortion_603448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_603502 = ref object of OpenApiRestCall_601373
proc url_PostListTagsForResource_603504(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_603503(path: JsonNode; query: JsonNode;
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
                                 default = newJString("ListTagsForResource"))
  if valid_603505 != nil:
    section.add "Action", valid_603505
  var valid_603506 = query.getOrDefault("Version")
  valid_603506 = validateParameter(valid_603506, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_603514 = formData.getOrDefault("Filters")
  valid_603514 = validateParameter(valid_603514, JArray, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "Filters", valid_603514
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_603515 = formData.getOrDefault("ResourceName")
  valid_603515 = validateParameter(valid_603515, JString, required = true,
                                 default = nil)
  if valid_603515 != nil:
    section.add "ResourceName", valid_603515
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603516: Call_PostListTagsForResource_603502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603516.validator(path, query, header, formData, body)
  let scheme = call_603516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603516.url(scheme.get, call_603516.host, call_603516.base,
                         call_603516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603516, url, valid)

proc call*(call_603517: Call_PostListTagsForResource_603502; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_603518 = newJObject()
  var formData_603519 = newJObject()
  add(query_603518, "Action", newJString(Action))
  if Filters != nil:
    formData_603519.add "Filters", Filters
  add(query_603518, "Version", newJString(Version))
  add(formData_603519, "ResourceName", newJString(ResourceName))
  result = call_603517.call(nil, query_603518, nil, formData_603519, nil)

var postListTagsForResource* = Call_PostListTagsForResource_603502(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_603503, base: "/",
    url: url_PostListTagsForResource_603504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_603485 = ref object of OpenApiRestCall_601373
proc url_GetListTagsForResource_603487(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_603486(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_603488 = query.getOrDefault("ResourceName")
  valid_603488 = validateParameter(valid_603488, JString, required = true,
                                 default = nil)
  if valid_603488 != nil:
    section.add "ResourceName", valid_603488
  var valid_603489 = query.getOrDefault("Action")
  valid_603489 = validateParameter(valid_603489, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603489 != nil:
    section.add "Action", valid_603489
  var valid_603490 = query.getOrDefault("Version")
  valid_603490 = validateParameter(valid_603490, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603490 != nil:
    section.add "Version", valid_603490
  var valid_603491 = query.getOrDefault("Filters")
  valid_603491 = validateParameter(valid_603491, JArray, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "Filters", valid_603491
  result.add "query", section
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

proc call*(call_603499: Call_GetListTagsForResource_603485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603499.validator(path, query, header, formData, body)
  let scheme = call_603499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603499.url(scheme.get, call_603499.host, call_603499.base,
                         call_603499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603499, url, valid)

proc call*(call_603500: Call_GetListTagsForResource_603485; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-09-09";
          Filters: JsonNode = nil): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_603501 = newJObject()
  add(query_603501, "ResourceName", newJString(ResourceName))
  add(query_603501, "Action", newJString(Action))
  add(query_603501, "Version", newJString(Version))
  if Filters != nil:
    query_603501.add "Filters", Filters
  result = call_603500.call(nil, query_603501, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_603485(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_603486, base: "/",
    url: url_GetListTagsForResource_603487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_603553 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBInstance_603555(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBInstance_603554(path: JsonNode; query: JsonNode;
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
  var valid_603556 = query.getOrDefault("Action")
  valid_603556 = validateParameter(valid_603556, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_603556 != nil:
    section.add "Action", valid_603556
  var valid_603557 = query.getOrDefault("Version")
  valid_603557 = validateParameter(valid_603557, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603557 != nil:
    section.add "Version", valid_603557
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603558 = header.getOrDefault("X-Amz-Signature")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Signature", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Content-Sha256", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Date")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Date", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-Credential")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Credential", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Security-Token")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Security-Token", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Algorithm")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Algorithm", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-SignedHeaders", valid_603564
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
  var valid_603565 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "PreferredMaintenanceWindow", valid_603565
  var valid_603566 = formData.getOrDefault("DBInstanceClass")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "DBInstanceClass", valid_603566
  var valid_603567 = formData.getOrDefault("PreferredBackupWindow")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "PreferredBackupWindow", valid_603567
  var valid_603568 = formData.getOrDefault("MasterUserPassword")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "MasterUserPassword", valid_603568
  var valid_603569 = formData.getOrDefault("MultiAZ")
  valid_603569 = validateParameter(valid_603569, JBool, required = false, default = nil)
  if valid_603569 != nil:
    section.add "MultiAZ", valid_603569
  var valid_603570 = formData.getOrDefault("DBParameterGroupName")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "DBParameterGroupName", valid_603570
  var valid_603571 = formData.getOrDefault("EngineVersion")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "EngineVersion", valid_603571
  var valid_603572 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603572 = validateParameter(valid_603572, JArray, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "VpcSecurityGroupIds", valid_603572
  var valid_603573 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603573 = validateParameter(valid_603573, JInt, required = false, default = nil)
  if valid_603573 != nil:
    section.add "BackupRetentionPeriod", valid_603573
  var valid_603574 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603574 = validateParameter(valid_603574, JBool, required = false, default = nil)
  if valid_603574 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603574
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603575 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603575 = validateParameter(valid_603575, JString, required = true,
                                 default = nil)
  if valid_603575 != nil:
    section.add "DBInstanceIdentifier", valid_603575
  var valid_603576 = formData.getOrDefault("ApplyImmediately")
  valid_603576 = validateParameter(valid_603576, JBool, required = false, default = nil)
  if valid_603576 != nil:
    section.add "ApplyImmediately", valid_603576
  var valid_603577 = formData.getOrDefault("Iops")
  valid_603577 = validateParameter(valid_603577, JInt, required = false, default = nil)
  if valid_603577 != nil:
    section.add "Iops", valid_603577
  var valid_603578 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_603578 = validateParameter(valid_603578, JBool, required = false, default = nil)
  if valid_603578 != nil:
    section.add "AllowMajorVersionUpgrade", valid_603578
  var valid_603579 = formData.getOrDefault("OptionGroupName")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "OptionGroupName", valid_603579
  var valid_603580 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "NewDBInstanceIdentifier", valid_603580
  var valid_603581 = formData.getOrDefault("DBSecurityGroups")
  valid_603581 = validateParameter(valid_603581, JArray, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "DBSecurityGroups", valid_603581
  var valid_603582 = formData.getOrDefault("AllocatedStorage")
  valid_603582 = validateParameter(valid_603582, JInt, required = false, default = nil)
  if valid_603582 != nil:
    section.add "AllocatedStorage", valid_603582
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603583: Call_PostModifyDBInstance_603553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603583.validator(path, query, header, formData, body)
  let scheme = call_603583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603583.url(scheme.get, call_603583.host, call_603583.base,
                         call_603583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603583, url, valid)

proc call*(call_603584: Call_PostModifyDBInstance_603553;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          MasterUserPassword: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          AutoMinorVersionUpgrade: bool = false; ApplyImmediately: bool = false;
          Iops: int = 0; Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false; OptionGroupName: string = "";
          NewDBInstanceIdentifier: string = ""; Version: string = "2013-09-09";
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
  var query_603585 = newJObject()
  var formData_603586 = newJObject()
  add(formData_603586, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_603586, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603586, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603586, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_603586, "MultiAZ", newJBool(MultiAZ))
  add(formData_603586, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603586, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_603586.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_603586, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603586, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603586, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603586, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_603586, "Iops", newJInt(Iops))
  add(query_603585, "Action", newJString(Action))
  add(formData_603586, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_603586, "OptionGroupName", newJString(OptionGroupName))
  add(formData_603586, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_603585, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_603586.add "DBSecurityGroups", DBSecurityGroups
  add(formData_603586, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_603584.call(nil, query_603585, nil, formData_603586, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_603553(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_603554, base: "/",
    url: url_PostModifyDBInstance_603555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_603520 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBInstance_603522(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBInstance_603521(path: JsonNode; query: JsonNode;
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
  var valid_603523 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "NewDBInstanceIdentifier", valid_603523
  var valid_603524 = query.getOrDefault("DBParameterGroupName")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "DBParameterGroupName", valid_603524
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603525 = query.getOrDefault("DBInstanceIdentifier")
  valid_603525 = validateParameter(valid_603525, JString, required = true,
                                 default = nil)
  if valid_603525 != nil:
    section.add "DBInstanceIdentifier", valid_603525
  var valid_603526 = query.getOrDefault("BackupRetentionPeriod")
  valid_603526 = validateParameter(valid_603526, JInt, required = false, default = nil)
  if valid_603526 != nil:
    section.add "BackupRetentionPeriod", valid_603526
  var valid_603527 = query.getOrDefault("EngineVersion")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "EngineVersion", valid_603527
  var valid_603528 = query.getOrDefault("Action")
  valid_603528 = validateParameter(valid_603528, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_603528 != nil:
    section.add "Action", valid_603528
  var valid_603529 = query.getOrDefault("MultiAZ")
  valid_603529 = validateParameter(valid_603529, JBool, required = false, default = nil)
  if valid_603529 != nil:
    section.add "MultiAZ", valid_603529
  var valid_603530 = query.getOrDefault("DBSecurityGroups")
  valid_603530 = validateParameter(valid_603530, JArray, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "DBSecurityGroups", valid_603530
  var valid_603531 = query.getOrDefault("ApplyImmediately")
  valid_603531 = validateParameter(valid_603531, JBool, required = false, default = nil)
  if valid_603531 != nil:
    section.add "ApplyImmediately", valid_603531
  var valid_603532 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603532 = validateParameter(valid_603532, JArray, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "VpcSecurityGroupIds", valid_603532
  var valid_603533 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_603533 = validateParameter(valid_603533, JBool, required = false, default = nil)
  if valid_603533 != nil:
    section.add "AllowMajorVersionUpgrade", valid_603533
  var valid_603534 = query.getOrDefault("MasterUserPassword")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "MasterUserPassword", valid_603534
  var valid_603535 = query.getOrDefault("OptionGroupName")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "OptionGroupName", valid_603535
  var valid_603536 = query.getOrDefault("Version")
  valid_603536 = validateParameter(valid_603536, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603536 != nil:
    section.add "Version", valid_603536
  var valid_603537 = query.getOrDefault("AllocatedStorage")
  valid_603537 = validateParameter(valid_603537, JInt, required = false, default = nil)
  if valid_603537 != nil:
    section.add "AllocatedStorage", valid_603537
  var valid_603538 = query.getOrDefault("DBInstanceClass")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "DBInstanceClass", valid_603538
  var valid_603539 = query.getOrDefault("PreferredBackupWindow")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "PreferredBackupWindow", valid_603539
  var valid_603540 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "PreferredMaintenanceWindow", valid_603540
  var valid_603541 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603541 = validateParameter(valid_603541, JBool, required = false, default = nil)
  if valid_603541 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603541
  var valid_603542 = query.getOrDefault("Iops")
  valid_603542 = validateParameter(valid_603542, JInt, required = false, default = nil)
  if valid_603542 != nil:
    section.add "Iops", valid_603542
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603543 = header.getOrDefault("X-Amz-Signature")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Signature", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Content-Sha256", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Date")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Date", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-Credential")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Credential", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Security-Token")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Security-Token", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Algorithm")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Algorithm", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-SignedHeaders", valid_603549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603550: Call_GetModifyDBInstance_603520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603550.validator(path, query, header, formData, body)
  let scheme = call_603550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603550.url(scheme.get, call_603550.host, call_603550.base,
                         call_603550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603550, url, valid)

proc call*(call_603551: Call_GetModifyDBInstance_603520;
          DBInstanceIdentifier: string; NewDBInstanceIdentifier: string = "";
          DBParameterGroupName: string = ""; BackupRetentionPeriod: int = 0;
          EngineVersion: string = ""; Action: string = "ModifyDBInstance";
          MultiAZ: bool = false; DBSecurityGroups: JsonNode = nil;
          ApplyImmediately: bool = false; VpcSecurityGroupIds: JsonNode = nil;
          AllowMajorVersionUpgrade: bool = false; MasterUserPassword: string = "";
          OptionGroupName: string = ""; Version: string = "2013-09-09";
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
  var query_603552 = newJObject()
  add(query_603552, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_603552, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603552, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603552, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603552, "EngineVersion", newJString(EngineVersion))
  add(query_603552, "Action", newJString(Action))
  add(query_603552, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_603552.add "DBSecurityGroups", DBSecurityGroups
  add(query_603552, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_603552.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_603552, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_603552, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_603552, "OptionGroupName", newJString(OptionGroupName))
  add(query_603552, "Version", newJString(Version))
  add(query_603552, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_603552, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603552, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_603552, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603552, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603552, "Iops", newJInt(Iops))
  result = call_603551.call(nil, query_603552, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_603520(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_603521, base: "/",
    url: url_GetModifyDBInstance_603522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_603604 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBParameterGroup_603606(protocol: Scheme; host: string;
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

proc validate_PostModifyDBParameterGroup_603605(path: JsonNode; query: JsonNode;
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
  var valid_603607 = query.getOrDefault("Action")
  valid_603607 = validateParameter(valid_603607, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_603607 != nil:
    section.add "Action", valid_603607
  var valid_603608 = query.getOrDefault("Version")
  valid_603608 = validateParameter(valid_603608, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603608 != nil:
    section.add "Version", valid_603608
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603616 = formData.getOrDefault("DBParameterGroupName")
  valid_603616 = validateParameter(valid_603616, JString, required = true,
                                 default = nil)
  if valid_603616 != nil:
    section.add "DBParameterGroupName", valid_603616
  var valid_603617 = formData.getOrDefault("Parameters")
  valid_603617 = validateParameter(valid_603617, JArray, required = true, default = nil)
  if valid_603617 != nil:
    section.add "Parameters", valid_603617
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603618: Call_PostModifyDBParameterGroup_603604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603618.validator(path, query, header, formData, body)
  let scheme = call_603618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603618.url(scheme.get, call_603618.host, call_603618.base,
                         call_603618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603618, url, valid)

proc call*(call_603619: Call_PostModifyDBParameterGroup_603604;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_603620 = newJObject()
  var formData_603621 = newJObject()
  add(formData_603621, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603620, "Action", newJString(Action))
  if Parameters != nil:
    formData_603621.add "Parameters", Parameters
  add(query_603620, "Version", newJString(Version))
  result = call_603619.call(nil, query_603620, nil, formData_603621, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_603604(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_603605, base: "/",
    url: url_PostModifyDBParameterGroup_603606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_603587 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBParameterGroup_603589(protocol: Scheme; host: string;
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

proc validate_GetModifyDBParameterGroup_603588(path: JsonNode; query: JsonNode;
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
  var valid_603590 = query.getOrDefault("DBParameterGroupName")
  valid_603590 = validateParameter(valid_603590, JString, required = true,
                                 default = nil)
  if valid_603590 != nil:
    section.add "DBParameterGroupName", valid_603590
  var valid_603591 = query.getOrDefault("Parameters")
  valid_603591 = validateParameter(valid_603591, JArray, required = true, default = nil)
  if valid_603591 != nil:
    section.add "Parameters", valid_603591
  var valid_603592 = query.getOrDefault("Action")
  valid_603592 = validateParameter(valid_603592, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_603592 != nil:
    section.add "Action", valid_603592
  var valid_603593 = query.getOrDefault("Version")
  valid_603593 = validateParameter(valid_603593, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603593 != nil:
    section.add "Version", valid_603593
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603594 = header.getOrDefault("X-Amz-Signature")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-Signature", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Content-Sha256", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Date")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Date", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-Credential")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Credential", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-Security-Token")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Security-Token", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Algorithm")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Algorithm", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-SignedHeaders", valid_603600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603601: Call_GetModifyDBParameterGroup_603587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603601.validator(path, query, header, formData, body)
  let scheme = call_603601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603601.url(scheme.get, call_603601.host, call_603601.base,
                         call_603601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603601, url, valid)

proc call*(call_603602: Call_GetModifyDBParameterGroup_603587;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603603 = newJObject()
  add(query_603603, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_603603.add "Parameters", Parameters
  add(query_603603, "Action", newJString(Action))
  add(query_603603, "Version", newJString(Version))
  result = call_603602.call(nil, query_603603, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_603587(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_603588, base: "/",
    url: url_GetModifyDBParameterGroup_603589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_603640 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBSubnetGroup_603642(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBSubnetGroup_603641(path: JsonNode; query: JsonNode;
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
  var valid_603643 = query.getOrDefault("Action")
  valid_603643 = validateParameter(valid_603643, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_603643 != nil:
    section.add "Action", valid_603643
  var valid_603644 = query.getOrDefault("Version")
  valid_603644 = validateParameter(valid_603644, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603644 != nil:
    section.add "Version", valid_603644
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603645 = header.getOrDefault("X-Amz-Signature")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Signature", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Content-Sha256", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Date")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Date", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Credential")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Credential", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Security-Token")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Security-Token", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Algorithm")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Algorithm", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-SignedHeaders", valid_603651
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_603652 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "DBSubnetGroupDescription", valid_603652
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603653 = formData.getOrDefault("DBSubnetGroupName")
  valid_603653 = validateParameter(valid_603653, JString, required = true,
                                 default = nil)
  if valid_603653 != nil:
    section.add "DBSubnetGroupName", valid_603653
  var valid_603654 = formData.getOrDefault("SubnetIds")
  valid_603654 = validateParameter(valid_603654, JArray, required = true, default = nil)
  if valid_603654 != nil:
    section.add "SubnetIds", valid_603654
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603655: Call_PostModifyDBSubnetGroup_603640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603655.validator(path, query, header, formData, body)
  let scheme = call_603655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603655.url(scheme.get, call_603655.host, call_603655.base,
                         call_603655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603655, url, valid)

proc call*(call_603656: Call_PostModifyDBSubnetGroup_603640;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_603657 = newJObject()
  var formData_603658 = newJObject()
  add(formData_603658, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603657, "Action", newJString(Action))
  add(formData_603658, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603657, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_603658.add "SubnetIds", SubnetIds
  result = call_603656.call(nil, query_603657, nil, formData_603658, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_603640(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_603641, base: "/",
    url: url_PostModifyDBSubnetGroup_603642, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_603622 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBSubnetGroup_603624(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBSubnetGroup_603623(path: JsonNode; query: JsonNode;
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
  var valid_603625 = query.getOrDefault("SubnetIds")
  valid_603625 = validateParameter(valid_603625, JArray, required = true, default = nil)
  if valid_603625 != nil:
    section.add "SubnetIds", valid_603625
  var valid_603626 = query.getOrDefault("Action")
  valid_603626 = validateParameter(valid_603626, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_603626 != nil:
    section.add "Action", valid_603626
  var valid_603627 = query.getOrDefault("DBSubnetGroupDescription")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "DBSubnetGroupDescription", valid_603627
  var valid_603628 = query.getOrDefault("DBSubnetGroupName")
  valid_603628 = validateParameter(valid_603628, JString, required = true,
                                 default = nil)
  if valid_603628 != nil:
    section.add "DBSubnetGroupName", valid_603628
  var valid_603629 = query.getOrDefault("Version")
  valid_603629 = validateParameter(valid_603629, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603629 != nil:
    section.add "Version", valid_603629
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603630 = header.getOrDefault("X-Amz-Signature")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Signature", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Content-Sha256", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Date")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Date", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Credential")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Credential", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Security-Token")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Security-Token", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Algorithm")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Algorithm", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-SignedHeaders", valid_603636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603637: Call_GetModifyDBSubnetGroup_603622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603637.validator(path, query, header, formData, body)
  let scheme = call_603637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603637.url(scheme.get, call_603637.host, call_603637.base,
                         call_603637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603637, url, valid)

proc call*(call_603638: Call_GetModifyDBSubnetGroup_603622; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_603639 = newJObject()
  if SubnetIds != nil:
    query_603639.add "SubnetIds", SubnetIds
  add(query_603639, "Action", newJString(Action))
  add(query_603639, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603639, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603639, "Version", newJString(Version))
  result = call_603638.call(nil, query_603639, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_603622(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_603623, base: "/",
    url: url_GetModifyDBSubnetGroup_603624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_603679 = ref object of OpenApiRestCall_601373
proc url_PostModifyEventSubscription_603681(protocol: Scheme; host: string;
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

proc validate_PostModifyEventSubscription_603680(path: JsonNode; query: JsonNode;
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
  var valid_603682 = query.getOrDefault("Action")
  valid_603682 = validateParameter(valid_603682, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_603682 != nil:
    section.add "Action", valid_603682
  var valid_603683 = query.getOrDefault("Version")
  valid_603683 = validateParameter(valid_603683, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603683 != nil:
    section.add "Version", valid_603683
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603684 = header.getOrDefault("X-Amz-Signature")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Signature", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Content-Sha256", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Date")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Date", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-Credential")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Credential", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Security-Token")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Security-Token", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-Algorithm")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Algorithm", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-SignedHeaders", valid_603690
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_603691 = formData.getOrDefault("SnsTopicArn")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "SnsTopicArn", valid_603691
  var valid_603692 = formData.getOrDefault("Enabled")
  valid_603692 = validateParameter(valid_603692, JBool, required = false, default = nil)
  if valid_603692 != nil:
    section.add "Enabled", valid_603692
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_603693 = formData.getOrDefault("SubscriptionName")
  valid_603693 = validateParameter(valid_603693, JString, required = true,
                                 default = nil)
  if valid_603693 != nil:
    section.add "SubscriptionName", valid_603693
  var valid_603694 = formData.getOrDefault("SourceType")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "SourceType", valid_603694
  var valid_603695 = formData.getOrDefault("EventCategories")
  valid_603695 = validateParameter(valid_603695, JArray, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "EventCategories", valid_603695
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603696: Call_PostModifyEventSubscription_603679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603696.validator(path, query, header, formData, body)
  let scheme = call_603696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603696.url(scheme.get, call_603696.host, call_603696.base,
                         call_603696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603696, url, valid)

proc call*(call_603697: Call_PostModifyEventSubscription_603679;
          SubscriptionName: string; SnsTopicArn: string = ""; Enabled: bool = false;
          SourceType: string = ""; EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; Version: string = "2013-09-09"): Recallable =
  ## postModifyEventSubscription
  ##   SnsTopicArn: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603698 = newJObject()
  var formData_603699 = newJObject()
  add(formData_603699, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_603699, "Enabled", newJBool(Enabled))
  add(formData_603699, "SubscriptionName", newJString(SubscriptionName))
  add(formData_603699, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_603699.add "EventCategories", EventCategories
  add(query_603698, "Action", newJString(Action))
  add(query_603698, "Version", newJString(Version))
  result = call_603697.call(nil, query_603698, nil, formData_603699, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_603679(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_603680, base: "/",
    url: url_PostModifyEventSubscription_603681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_603659 = ref object of OpenApiRestCall_601373
proc url_GetModifyEventSubscription_603661(protocol: Scheme; host: string;
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

proc validate_GetModifyEventSubscription_603660(path: JsonNode; query: JsonNode;
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
  var valid_603662 = query.getOrDefault("SourceType")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "SourceType", valid_603662
  var valid_603663 = query.getOrDefault("Enabled")
  valid_603663 = validateParameter(valid_603663, JBool, required = false, default = nil)
  if valid_603663 != nil:
    section.add "Enabled", valid_603663
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_603664 = query.getOrDefault("SubscriptionName")
  valid_603664 = validateParameter(valid_603664, JString, required = true,
                                 default = nil)
  if valid_603664 != nil:
    section.add "SubscriptionName", valid_603664
  var valid_603665 = query.getOrDefault("EventCategories")
  valid_603665 = validateParameter(valid_603665, JArray, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "EventCategories", valid_603665
  var valid_603666 = query.getOrDefault("Action")
  valid_603666 = validateParameter(valid_603666, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_603666 != nil:
    section.add "Action", valid_603666
  var valid_603667 = query.getOrDefault("SnsTopicArn")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "SnsTopicArn", valid_603667
  var valid_603668 = query.getOrDefault("Version")
  valid_603668 = validateParameter(valid_603668, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603668 != nil:
    section.add "Version", valid_603668
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603669 = header.getOrDefault("X-Amz-Signature")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Signature", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Content-Sha256", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Date")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Date", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Credential")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Credential", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-Security-Token")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Security-Token", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Algorithm")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Algorithm", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-SignedHeaders", valid_603675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603676: Call_GetModifyEventSubscription_603659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603676.validator(path, query, header, formData, body)
  let scheme = call_603676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603676.url(scheme.get, call_603676.host, call_603676.base,
                         call_603676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603676, url, valid)

proc call*(call_603677: Call_GetModifyEventSubscription_603659;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   Version: string (required)
  var query_603678 = newJObject()
  add(query_603678, "SourceType", newJString(SourceType))
  add(query_603678, "Enabled", newJBool(Enabled))
  add(query_603678, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_603678.add "EventCategories", EventCategories
  add(query_603678, "Action", newJString(Action))
  add(query_603678, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_603678, "Version", newJString(Version))
  result = call_603677.call(nil, query_603678, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_603659(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_603660, base: "/",
    url: url_GetModifyEventSubscription_603661,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_603719 = ref object of OpenApiRestCall_601373
proc url_PostModifyOptionGroup_603721(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyOptionGroup_603720(path: JsonNode; query: JsonNode;
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
  var valid_603722 = query.getOrDefault("Action")
  valid_603722 = validateParameter(valid_603722, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_603722 != nil:
    section.add "Action", valid_603722
  var valid_603723 = query.getOrDefault("Version")
  valid_603723 = validateParameter(valid_603723, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603723 != nil:
    section.add "Version", valid_603723
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603724 = header.getOrDefault("X-Amz-Signature")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Signature", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Content-Sha256", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-Date")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-Date", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Credential")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Credential", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Security-Token")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Security-Token", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-Algorithm")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-Algorithm", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-SignedHeaders", valid_603730
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_603731 = formData.getOrDefault("OptionsToRemove")
  valid_603731 = validateParameter(valid_603731, JArray, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "OptionsToRemove", valid_603731
  var valid_603732 = formData.getOrDefault("ApplyImmediately")
  valid_603732 = validateParameter(valid_603732, JBool, required = false, default = nil)
  if valid_603732 != nil:
    section.add "ApplyImmediately", valid_603732
  var valid_603733 = formData.getOrDefault("OptionsToInclude")
  valid_603733 = validateParameter(valid_603733, JArray, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "OptionsToInclude", valid_603733
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_603734 = formData.getOrDefault("OptionGroupName")
  valid_603734 = validateParameter(valid_603734, JString, required = true,
                                 default = nil)
  if valid_603734 != nil:
    section.add "OptionGroupName", valid_603734
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603735: Call_PostModifyOptionGroup_603719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603735.validator(path, query, header, formData, body)
  let scheme = call_603735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603735.url(scheme.get, call_603735.host, call_603735.base,
                         call_603735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603735, url, valid)

proc call*(call_603736: Call_PostModifyOptionGroup_603719; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_603737 = newJObject()
  var formData_603738 = newJObject()
  if OptionsToRemove != nil:
    formData_603738.add "OptionsToRemove", OptionsToRemove
  add(formData_603738, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_603738.add "OptionsToInclude", OptionsToInclude
  add(query_603737, "Action", newJString(Action))
  add(formData_603738, "OptionGroupName", newJString(OptionGroupName))
  add(query_603737, "Version", newJString(Version))
  result = call_603736.call(nil, query_603737, nil, formData_603738, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_603719(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_603720, base: "/",
    url: url_PostModifyOptionGroup_603721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_603700 = ref object of OpenApiRestCall_601373
proc url_GetModifyOptionGroup_603702(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyOptionGroup_603701(path: JsonNode; query: JsonNode;
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
  var valid_603703 = query.getOrDefault("Action")
  valid_603703 = validateParameter(valid_603703, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_603703 != nil:
    section.add "Action", valid_603703
  var valid_603704 = query.getOrDefault("ApplyImmediately")
  valid_603704 = validateParameter(valid_603704, JBool, required = false, default = nil)
  if valid_603704 != nil:
    section.add "ApplyImmediately", valid_603704
  var valid_603705 = query.getOrDefault("OptionsToRemove")
  valid_603705 = validateParameter(valid_603705, JArray, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "OptionsToRemove", valid_603705
  var valid_603706 = query.getOrDefault("OptionsToInclude")
  valid_603706 = validateParameter(valid_603706, JArray, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "OptionsToInclude", valid_603706
  var valid_603707 = query.getOrDefault("OptionGroupName")
  valid_603707 = validateParameter(valid_603707, JString, required = true,
                                 default = nil)
  if valid_603707 != nil:
    section.add "OptionGroupName", valid_603707
  var valid_603708 = query.getOrDefault("Version")
  valid_603708 = validateParameter(valid_603708, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603708 != nil:
    section.add "Version", valid_603708
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603709 = header.getOrDefault("X-Amz-Signature")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Signature", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Content-Sha256", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-Date")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-Date", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Credential")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Credential", valid_603712
  var valid_603713 = header.getOrDefault("X-Amz-Security-Token")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Security-Token", valid_603713
  var valid_603714 = header.getOrDefault("X-Amz-Algorithm")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "X-Amz-Algorithm", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-SignedHeaders", valid_603715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603716: Call_GetModifyOptionGroup_603700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603716.validator(path, query, header, formData, body)
  let scheme = call_603716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603716.url(scheme.get, call_603716.host, call_603716.base,
                         call_603716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603716, url, valid)

proc call*(call_603717: Call_GetModifyOptionGroup_603700; OptionGroupName: string;
          Action: string = "ModifyOptionGroup"; ApplyImmediately: bool = false;
          OptionsToRemove: JsonNode = nil; OptionsToInclude: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## getModifyOptionGroup
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_603718 = newJObject()
  add(query_603718, "Action", newJString(Action))
  add(query_603718, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_603718.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_603718.add "OptionsToInclude", OptionsToInclude
  add(query_603718, "OptionGroupName", newJString(OptionGroupName))
  add(query_603718, "Version", newJString(Version))
  result = call_603717.call(nil, query_603718, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_603700(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_603701, base: "/",
    url: url_GetModifyOptionGroup_603702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_603757 = ref object of OpenApiRestCall_601373
proc url_PostPromoteReadReplica_603759(protocol: Scheme; host: string; base: string;
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

proc validate_PostPromoteReadReplica_603758(path: JsonNode; query: JsonNode;
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
  var valid_603760 = query.getOrDefault("Action")
  valid_603760 = validateParameter(valid_603760, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_603760 != nil:
    section.add "Action", valid_603760
  var valid_603761 = query.getOrDefault("Version")
  valid_603761 = validateParameter(valid_603761, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603761 != nil:
    section.add "Version", valid_603761
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603762 = header.getOrDefault("X-Amz-Signature")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Signature", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Content-Sha256", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-Date")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Date", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Credential")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Credential", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Security-Token")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Security-Token", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Algorithm")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Algorithm", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-SignedHeaders", valid_603768
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_603769 = formData.getOrDefault("PreferredBackupWindow")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "PreferredBackupWindow", valid_603769
  var valid_603770 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603770 = validateParameter(valid_603770, JInt, required = false, default = nil)
  if valid_603770 != nil:
    section.add "BackupRetentionPeriod", valid_603770
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603771 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603771 = validateParameter(valid_603771, JString, required = true,
                                 default = nil)
  if valid_603771 != nil:
    section.add "DBInstanceIdentifier", valid_603771
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603772: Call_PostPromoteReadReplica_603757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603772.validator(path, query, header, formData, body)
  let scheme = call_603772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603772.url(scheme.get, call_603772.host, call_603772.base,
                         call_603772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603772, url, valid)

proc call*(call_603773: Call_PostPromoteReadReplica_603757;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2013-09-09"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603774 = newJObject()
  var formData_603775 = newJObject()
  add(formData_603775, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603775, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603775, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603774, "Action", newJString(Action))
  add(query_603774, "Version", newJString(Version))
  result = call_603773.call(nil, query_603774, nil, formData_603775, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_603757(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_603758, base: "/",
    url: url_PostPromoteReadReplica_603759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_603739 = ref object of OpenApiRestCall_601373
proc url_GetPromoteReadReplica_603741(protocol: Scheme; host: string; base: string;
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

proc validate_GetPromoteReadReplica_603740(path: JsonNode; query: JsonNode;
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
  var valid_603742 = query.getOrDefault("DBInstanceIdentifier")
  valid_603742 = validateParameter(valid_603742, JString, required = true,
                                 default = nil)
  if valid_603742 != nil:
    section.add "DBInstanceIdentifier", valid_603742
  var valid_603743 = query.getOrDefault("BackupRetentionPeriod")
  valid_603743 = validateParameter(valid_603743, JInt, required = false, default = nil)
  if valid_603743 != nil:
    section.add "BackupRetentionPeriod", valid_603743
  var valid_603744 = query.getOrDefault("Action")
  valid_603744 = validateParameter(valid_603744, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_603744 != nil:
    section.add "Action", valid_603744
  var valid_603745 = query.getOrDefault("Version")
  valid_603745 = validateParameter(valid_603745, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603745 != nil:
    section.add "Version", valid_603745
  var valid_603746 = query.getOrDefault("PreferredBackupWindow")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "PreferredBackupWindow", valid_603746
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603747 = header.getOrDefault("X-Amz-Signature")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-Signature", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Content-Sha256", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-Date")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Date", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Credential")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Credential", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Security-Token")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Security-Token", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Algorithm")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Algorithm", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-SignedHeaders", valid_603753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603754: Call_GetPromoteReadReplica_603739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603754.validator(path, query, header, formData, body)
  let scheme = call_603754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603754.url(scheme.get, call_603754.host, call_603754.base,
                         call_603754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603754, url, valid)

proc call*(call_603755: Call_GetPromoteReadReplica_603739;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2013-09-09";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_603756 = newJObject()
  add(query_603756, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603756, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603756, "Action", newJString(Action))
  add(query_603756, "Version", newJString(Version))
  add(query_603756, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_603755.call(nil, query_603756, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_603739(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_603740, base: "/",
    url: url_GetPromoteReadReplica_603741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_603795 = ref object of OpenApiRestCall_601373
proc url_PostPurchaseReservedDBInstancesOffering_603797(protocol: Scheme;
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

proc validate_PostPurchaseReservedDBInstancesOffering_603796(path: JsonNode;
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
  var valid_603798 = query.getOrDefault("Action")
  valid_603798 = validateParameter(valid_603798, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_603798 != nil:
    section.add "Action", valid_603798
  var valid_603799 = query.getOrDefault("Version")
  valid_603799 = validateParameter(valid_603799, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603799 != nil:
    section.add "Version", valid_603799
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603800 = header.getOrDefault("X-Amz-Signature")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Signature", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Content-Sha256", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-Date")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Date", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Credential")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Credential", valid_603803
  var valid_603804 = header.getOrDefault("X-Amz-Security-Token")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "X-Amz-Security-Token", valid_603804
  var valid_603805 = header.getOrDefault("X-Amz-Algorithm")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-Algorithm", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-SignedHeaders", valid_603806
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_603807 = formData.getOrDefault("ReservedDBInstanceId")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "ReservedDBInstanceId", valid_603807
  var valid_603808 = formData.getOrDefault("Tags")
  valid_603808 = validateParameter(valid_603808, JArray, required = false,
                                 default = nil)
  if valid_603808 != nil:
    section.add "Tags", valid_603808
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_603809 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603809 = validateParameter(valid_603809, JString, required = true,
                                 default = nil)
  if valid_603809 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603809
  var valid_603810 = formData.getOrDefault("DBInstanceCount")
  valid_603810 = validateParameter(valid_603810, JInt, required = false, default = nil)
  if valid_603810 != nil:
    section.add "DBInstanceCount", valid_603810
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603811: Call_PostPurchaseReservedDBInstancesOffering_603795;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603811.validator(path, query, header, formData, body)
  let scheme = call_603811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603811.url(scheme.get, call_603811.host, call_603811.base,
                         call_603811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603811, url, valid)

proc call*(call_603812: Call_PostPurchaseReservedDBInstancesOffering_603795;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Tags: JsonNode = nil; Version: string = "2013-09-09"; DBInstanceCount: int = 0): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  ##   DBInstanceCount: int
  var query_603813 = newJObject()
  var formData_603814 = newJObject()
  add(formData_603814, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_603813, "Action", newJString(Action))
  if Tags != nil:
    formData_603814.add "Tags", Tags
  add(formData_603814, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603813, "Version", newJString(Version))
  add(formData_603814, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_603812.call(nil, query_603813, nil, formData_603814, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_603795(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_603796, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_603797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_603776 = ref object of OpenApiRestCall_601373
proc url_GetPurchaseReservedDBInstancesOffering_603778(protocol: Scheme;
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

proc validate_GetPurchaseReservedDBInstancesOffering_603777(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstanceId: JString
  ##   Action: JString (required)
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603779 = query.getOrDefault("Tags")
  valid_603779 = validateParameter(valid_603779, JArray, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "Tags", valid_603779
  var valid_603780 = query.getOrDefault("DBInstanceCount")
  valid_603780 = validateParameter(valid_603780, JInt, required = false, default = nil)
  if valid_603780 != nil:
    section.add "DBInstanceCount", valid_603780
  var valid_603781 = query.getOrDefault("ReservedDBInstanceId")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "ReservedDBInstanceId", valid_603781
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603782 = query.getOrDefault("Action")
  valid_603782 = validateParameter(valid_603782, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_603782 != nil:
    section.add "Action", valid_603782
  var valid_603783 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603783 = validateParameter(valid_603783, JString, required = true,
                                 default = nil)
  if valid_603783 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603783
  var valid_603784 = query.getOrDefault("Version")
  valid_603784 = validateParameter(valid_603784, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603784 != nil:
    section.add "Version", valid_603784
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603785 = header.getOrDefault("X-Amz-Signature")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Signature", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-Content-Sha256", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-Date")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-Date", valid_603787
  var valid_603788 = header.getOrDefault("X-Amz-Credential")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Credential", valid_603788
  var valid_603789 = header.getOrDefault("X-Amz-Security-Token")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Security-Token", valid_603789
  var valid_603790 = header.getOrDefault("X-Amz-Algorithm")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-Algorithm", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-SignedHeaders", valid_603791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603792: Call_GetPurchaseReservedDBInstancesOffering_603776;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603792.validator(path, query, header, formData, body)
  let scheme = call_603792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603792.url(scheme.get, call_603792.host, call_603792.base,
                         call_603792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603792, url, valid)

proc call*(call_603793: Call_GetPurchaseReservedDBInstancesOffering_603776;
          ReservedDBInstancesOfferingId: string; Tags: JsonNode = nil;
          DBInstanceCount: int = 0; ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-09-09"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   Tags: JArray
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_603794 = newJObject()
  if Tags != nil:
    query_603794.add "Tags", Tags
  add(query_603794, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_603794, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_603794, "Action", newJString(Action))
  add(query_603794, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603794, "Version", newJString(Version))
  result = call_603793.call(nil, query_603794, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_603776(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_603777, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_603778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_603832 = ref object of OpenApiRestCall_601373
proc url_PostRebootDBInstance_603834(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebootDBInstance_603833(path: JsonNode; query: JsonNode;
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
  var valid_603835 = query.getOrDefault("Action")
  valid_603835 = validateParameter(valid_603835, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_603835 != nil:
    section.add "Action", valid_603835
  var valid_603836 = query.getOrDefault("Version")
  valid_603836 = validateParameter(valid_603836, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603836 != nil:
    section.add "Version", valid_603836
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603837 = header.getOrDefault("X-Amz-Signature")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Signature", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Content-Sha256", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Date")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Date", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Credential")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Credential", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Security-Token")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Security-Token", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-Algorithm")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-Algorithm", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-SignedHeaders", valid_603843
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_603844 = formData.getOrDefault("ForceFailover")
  valid_603844 = validateParameter(valid_603844, JBool, required = false, default = nil)
  if valid_603844 != nil:
    section.add "ForceFailover", valid_603844
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603845 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603845 = validateParameter(valid_603845, JString, required = true,
                                 default = nil)
  if valid_603845 != nil:
    section.add "DBInstanceIdentifier", valid_603845
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603846: Call_PostRebootDBInstance_603832; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603846.validator(path, query, header, formData, body)
  let scheme = call_603846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603846.url(scheme.get, call_603846.host, call_603846.base,
                         call_603846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603846, url, valid)

proc call*(call_603847: Call_PostRebootDBInstance_603832;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-09-09"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603848 = newJObject()
  var formData_603849 = newJObject()
  add(formData_603849, "ForceFailover", newJBool(ForceFailover))
  add(formData_603849, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603848, "Action", newJString(Action))
  add(query_603848, "Version", newJString(Version))
  result = call_603847.call(nil, query_603848, nil, formData_603849, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_603832(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_603833, base: "/",
    url: url_PostRebootDBInstance_603834, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_603815 = ref object of OpenApiRestCall_601373
proc url_GetRebootDBInstance_603817(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebootDBInstance_603816(path: JsonNode; query: JsonNode;
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
  var valid_603818 = query.getOrDefault("ForceFailover")
  valid_603818 = validateParameter(valid_603818, JBool, required = false, default = nil)
  if valid_603818 != nil:
    section.add "ForceFailover", valid_603818
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603819 = query.getOrDefault("DBInstanceIdentifier")
  valid_603819 = validateParameter(valid_603819, JString, required = true,
                                 default = nil)
  if valid_603819 != nil:
    section.add "DBInstanceIdentifier", valid_603819
  var valid_603820 = query.getOrDefault("Action")
  valid_603820 = validateParameter(valid_603820, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_603820 != nil:
    section.add "Action", valid_603820
  var valid_603821 = query.getOrDefault("Version")
  valid_603821 = validateParameter(valid_603821, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603821 != nil:
    section.add "Version", valid_603821
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603822 = header.getOrDefault("X-Amz-Signature")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "X-Amz-Signature", valid_603822
  var valid_603823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Content-Sha256", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Date")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Date", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-Credential")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-Credential", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Security-Token")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Security-Token", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-Algorithm")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Algorithm", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-SignedHeaders", valid_603828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603829: Call_GetRebootDBInstance_603815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603829.validator(path, query, header, formData, body)
  let scheme = call_603829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603829.url(scheme.get, call_603829.host, call_603829.base,
                         call_603829.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603829, url, valid)

proc call*(call_603830: Call_GetRebootDBInstance_603815;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-09-09"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603831 = newJObject()
  add(query_603831, "ForceFailover", newJBool(ForceFailover))
  add(query_603831, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603831, "Action", newJString(Action))
  add(query_603831, "Version", newJString(Version))
  result = call_603830.call(nil, query_603831, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_603815(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_603816, base: "/",
    url: url_GetRebootDBInstance_603817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_603867 = ref object of OpenApiRestCall_601373
proc url_PostRemoveSourceIdentifierFromSubscription_603869(protocol: Scheme;
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

proc validate_PostRemoveSourceIdentifierFromSubscription_603868(path: JsonNode;
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
  var valid_603870 = query.getOrDefault("Action")
  valid_603870 = validateParameter(valid_603870, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_603870 != nil:
    section.add "Action", valid_603870
  var valid_603871 = query.getOrDefault("Version")
  valid_603871 = validateParameter(valid_603871, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603871 != nil:
    section.add "Version", valid_603871
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603872 = header.getOrDefault("X-Amz-Signature")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Signature", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Content-Sha256", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Date")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Date", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Credential")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Credential", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-Security-Token")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-Security-Token", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-Algorithm")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Algorithm", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-SignedHeaders", valid_603878
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_603879 = formData.getOrDefault("SubscriptionName")
  valid_603879 = validateParameter(valid_603879, JString, required = true,
                                 default = nil)
  if valid_603879 != nil:
    section.add "SubscriptionName", valid_603879
  var valid_603880 = formData.getOrDefault("SourceIdentifier")
  valid_603880 = validateParameter(valid_603880, JString, required = true,
                                 default = nil)
  if valid_603880 != nil:
    section.add "SourceIdentifier", valid_603880
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603881: Call_PostRemoveSourceIdentifierFromSubscription_603867;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603881.validator(path, query, header, formData, body)
  let scheme = call_603881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603881.url(scheme.get, call_603881.host, call_603881.base,
                         call_603881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603881, url, valid)

proc call*(call_603882: Call_PostRemoveSourceIdentifierFromSubscription_603867;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603883 = newJObject()
  var formData_603884 = newJObject()
  add(formData_603884, "SubscriptionName", newJString(SubscriptionName))
  add(formData_603884, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_603883, "Action", newJString(Action))
  add(query_603883, "Version", newJString(Version))
  result = call_603882.call(nil, query_603883, nil, formData_603884, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_603867(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_603868,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_603869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_603850 = ref object of OpenApiRestCall_601373
proc url_GetRemoveSourceIdentifierFromSubscription_603852(protocol: Scheme;
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

proc validate_GetRemoveSourceIdentifierFromSubscription_603851(path: JsonNode;
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
  var valid_603853 = query.getOrDefault("SourceIdentifier")
  valid_603853 = validateParameter(valid_603853, JString, required = true,
                                 default = nil)
  if valid_603853 != nil:
    section.add "SourceIdentifier", valid_603853
  var valid_603854 = query.getOrDefault("SubscriptionName")
  valid_603854 = validateParameter(valid_603854, JString, required = true,
                                 default = nil)
  if valid_603854 != nil:
    section.add "SubscriptionName", valid_603854
  var valid_603855 = query.getOrDefault("Action")
  valid_603855 = validateParameter(valid_603855, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_603855 != nil:
    section.add "Action", valid_603855
  var valid_603856 = query.getOrDefault("Version")
  valid_603856 = validateParameter(valid_603856, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603856 != nil:
    section.add "Version", valid_603856
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603857 = header.getOrDefault("X-Amz-Signature")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-Signature", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Content-Sha256", valid_603858
  var valid_603859 = header.getOrDefault("X-Amz-Date")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Date", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-Credential")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Credential", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-Security-Token")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-Security-Token", valid_603861
  var valid_603862 = header.getOrDefault("X-Amz-Algorithm")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Algorithm", valid_603862
  var valid_603863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-SignedHeaders", valid_603863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603864: Call_GetRemoveSourceIdentifierFromSubscription_603850;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603864.validator(path, query, header, formData, body)
  let scheme = call_603864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603864.url(scheme.get, call_603864.host, call_603864.base,
                         call_603864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603864, url, valid)

proc call*(call_603865: Call_GetRemoveSourceIdentifierFromSubscription_603850;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603866 = newJObject()
  add(query_603866, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_603866, "SubscriptionName", newJString(SubscriptionName))
  add(query_603866, "Action", newJString(Action))
  add(query_603866, "Version", newJString(Version))
  result = call_603865.call(nil, query_603866, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_603850(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_603851,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_603852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_603902 = ref object of OpenApiRestCall_601373
proc url_PostRemoveTagsFromResource_603904(protocol: Scheme; host: string;
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

proc validate_PostRemoveTagsFromResource_603903(path: JsonNode; query: JsonNode;
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
  var valid_603905 = query.getOrDefault("Action")
  valid_603905 = validateParameter(valid_603905, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_603905 != nil:
    section.add "Action", valid_603905
  var valid_603906 = query.getOrDefault("Version")
  valid_603906 = validateParameter(valid_603906, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603906 != nil:
    section.add "Version", valid_603906
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603907 = header.getOrDefault("X-Amz-Signature")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Signature", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Content-Sha256", valid_603908
  var valid_603909 = header.getOrDefault("X-Amz-Date")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-Date", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-Credential")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Credential", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-Security-Token")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Security-Token", valid_603911
  var valid_603912 = header.getOrDefault("X-Amz-Algorithm")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Algorithm", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-SignedHeaders", valid_603913
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_603914 = formData.getOrDefault("TagKeys")
  valid_603914 = validateParameter(valid_603914, JArray, required = true, default = nil)
  if valid_603914 != nil:
    section.add "TagKeys", valid_603914
  var valid_603915 = formData.getOrDefault("ResourceName")
  valid_603915 = validateParameter(valid_603915, JString, required = true,
                                 default = nil)
  if valid_603915 != nil:
    section.add "ResourceName", valid_603915
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603916: Call_PostRemoveTagsFromResource_603902; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603916.validator(path, query, header, formData, body)
  let scheme = call_603916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603916.url(scheme.get, call_603916.host, call_603916.base,
                         call_603916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603916, url, valid)

proc call*(call_603917: Call_PostRemoveTagsFromResource_603902; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_603918 = newJObject()
  var formData_603919 = newJObject()
  if TagKeys != nil:
    formData_603919.add "TagKeys", TagKeys
  add(query_603918, "Action", newJString(Action))
  add(query_603918, "Version", newJString(Version))
  add(formData_603919, "ResourceName", newJString(ResourceName))
  result = call_603917.call(nil, query_603918, nil, formData_603919, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_603902(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_603903, base: "/",
    url: url_PostRemoveTagsFromResource_603904,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_603885 = ref object of OpenApiRestCall_601373
proc url_GetRemoveTagsFromResource_603887(protocol: Scheme; host: string;
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

proc validate_GetRemoveTagsFromResource_603886(path: JsonNode; query: JsonNode;
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
  var valid_603888 = query.getOrDefault("ResourceName")
  valid_603888 = validateParameter(valid_603888, JString, required = true,
                                 default = nil)
  if valid_603888 != nil:
    section.add "ResourceName", valid_603888
  var valid_603889 = query.getOrDefault("TagKeys")
  valid_603889 = validateParameter(valid_603889, JArray, required = true, default = nil)
  if valid_603889 != nil:
    section.add "TagKeys", valid_603889
  var valid_603890 = query.getOrDefault("Action")
  valid_603890 = validateParameter(valid_603890, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_603890 != nil:
    section.add "Action", valid_603890
  var valid_603891 = query.getOrDefault("Version")
  valid_603891 = validateParameter(valid_603891, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603891 != nil:
    section.add "Version", valid_603891
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603892 = header.getOrDefault("X-Amz-Signature")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "X-Amz-Signature", valid_603892
  var valid_603893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603893 = validateParameter(valid_603893, JString, required = false,
                                 default = nil)
  if valid_603893 != nil:
    section.add "X-Amz-Content-Sha256", valid_603893
  var valid_603894 = header.getOrDefault("X-Amz-Date")
  valid_603894 = validateParameter(valid_603894, JString, required = false,
                                 default = nil)
  if valid_603894 != nil:
    section.add "X-Amz-Date", valid_603894
  var valid_603895 = header.getOrDefault("X-Amz-Credential")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "X-Amz-Credential", valid_603895
  var valid_603896 = header.getOrDefault("X-Amz-Security-Token")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Security-Token", valid_603896
  var valid_603897 = header.getOrDefault("X-Amz-Algorithm")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-Algorithm", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-SignedHeaders", valid_603898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603899: Call_GetRemoveTagsFromResource_603885; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603899.validator(path, query, header, formData, body)
  let scheme = call_603899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603899.url(scheme.get, call_603899.host, call_603899.base,
                         call_603899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603899, url, valid)

proc call*(call_603900: Call_GetRemoveTagsFromResource_603885;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-09-09"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603901 = newJObject()
  add(query_603901, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_603901.add "TagKeys", TagKeys
  add(query_603901, "Action", newJString(Action))
  add(query_603901, "Version", newJString(Version))
  result = call_603900.call(nil, query_603901, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_603885(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_603886, base: "/",
    url: url_GetRemoveTagsFromResource_603887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_603938 = ref object of OpenApiRestCall_601373
proc url_PostResetDBParameterGroup_603940(protocol: Scheme; host: string;
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

proc validate_PostResetDBParameterGroup_603939(path: JsonNode; query: JsonNode;
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
  var valid_603941 = query.getOrDefault("Action")
  valid_603941 = validateParameter(valid_603941, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_603941 != nil:
    section.add "Action", valid_603941
  var valid_603942 = query.getOrDefault("Version")
  valid_603942 = validateParameter(valid_603942, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603942 != nil:
    section.add "Version", valid_603942
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603943 = header.getOrDefault("X-Amz-Signature")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "X-Amz-Signature", valid_603943
  var valid_603944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "X-Amz-Content-Sha256", valid_603944
  var valid_603945 = header.getOrDefault("X-Amz-Date")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "X-Amz-Date", valid_603945
  var valid_603946 = header.getOrDefault("X-Amz-Credential")
  valid_603946 = validateParameter(valid_603946, JString, required = false,
                                 default = nil)
  if valid_603946 != nil:
    section.add "X-Amz-Credential", valid_603946
  var valid_603947 = header.getOrDefault("X-Amz-Security-Token")
  valid_603947 = validateParameter(valid_603947, JString, required = false,
                                 default = nil)
  if valid_603947 != nil:
    section.add "X-Amz-Security-Token", valid_603947
  var valid_603948 = header.getOrDefault("X-Amz-Algorithm")
  valid_603948 = validateParameter(valid_603948, JString, required = false,
                                 default = nil)
  if valid_603948 != nil:
    section.add "X-Amz-Algorithm", valid_603948
  var valid_603949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-SignedHeaders", valid_603949
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_603950 = formData.getOrDefault("ResetAllParameters")
  valid_603950 = validateParameter(valid_603950, JBool, required = false, default = nil)
  if valid_603950 != nil:
    section.add "ResetAllParameters", valid_603950
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603951 = formData.getOrDefault("DBParameterGroupName")
  valid_603951 = validateParameter(valid_603951, JString, required = true,
                                 default = nil)
  if valid_603951 != nil:
    section.add "DBParameterGroupName", valid_603951
  var valid_603952 = formData.getOrDefault("Parameters")
  valid_603952 = validateParameter(valid_603952, JArray, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "Parameters", valid_603952
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603953: Call_PostResetDBParameterGroup_603938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603953.validator(path, query, header, formData, body)
  let scheme = call_603953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603953.url(scheme.get, call_603953.host, call_603953.base,
                         call_603953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603953, url, valid)

proc call*(call_603954: Call_PostResetDBParameterGroup_603938;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_603955 = newJObject()
  var formData_603956 = newJObject()
  add(formData_603956, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_603956, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603955, "Action", newJString(Action))
  if Parameters != nil:
    formData_603956.add "Parameters", Parameters
  add(query_603955, "Version", newJString(Version))
  result = call_603954.call(nil, query_603955, nil, formData_603956, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_603938(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_603939, base: "/",
    url: url_PostResetDBParameterGroup_603940,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_603920 = ref object of OpenApiRestCall_601373
proc url_GetResetDBParameterGroup_603922(protocol: Scheme; host: string;
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

proc validate_GetResetDBParameterGroup_603921(path: JsonNode; query: JsonNode;
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
  var valid_603923 = query.getOrDefault("DBParameterGroupName")
  valid_603923 = validateParameter(valid_603923, JString, required = true,
                                 default = nil)
  if valid_603923 != nil:
    section.add "DBParameterGroupName", valid_603923
  var valid_603924 = query.getOrDefault("Parameters")
  valid_603924 = validateParameter(valid_603924, JArray, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "Parameters", valid_603924
  var valid_603925 = query.getOrDefault("ResetAllParameters")
  valid_603925 = validateParameter(valid_603925, JBool, required = false, default = nil)
  if valid_603925 != nil:
    section.add "ResetAllParameters", valid_603925
  var valid_603926 = query.getOrDefault("Action")
  valid_603926 = validateParameter(valid_603926, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_603926 != nil:
    section.add "Action", valid_603926
  var valid_603927 = query.getOrDefault("Version")
  valid_603927 = validateParameter(valid_603927, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603927 != nil:
    section.add "Version", valid_603927
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603928 = header.getOrDefault("X-Amz-Signature")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "X-Amz-Signature", valid_603928
  var valid_603929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603929 = validateParameter(valid_603929, JString, required = false,
                                 default = nil)
  if valid_603929 != nil:
    section.add "X-Amz-Content-Sha256", valid_603929
  var valid_603930 = header.getOrDefault("X-Amz-Date")
  valid_603930 = validateParameter(valid_603930, JString, required = false,
                                 default = nil)
  if valid_603930 != nil:
    section.add "X-Amz-Date", valid_603930
  var valid_603931 = header.getOrDefault("X-Amz-Credential")
  valid_603931 = validateParameter(valid_603931, JString, required = false,
                                 default = nil)
  if valid_603931 != nil:
    section.add "X-Amz-Credential", valid_603931
  var valid_603932 = header.getOrDefault("X-Amz-Security-Token")
  valid_603932 = validateParameter(valid_603932, JString, required = false,
                                 default = nil)
  if valid_603932 != nil:
    section.add "X-Amz-Security-Token", valid_603932
  var valid_603933 = header.getOrDefault("X-Amz-Algorithm")
  valid_603933 = validateParameter(valid_603933, JString, required = false,
                                 default = nil)
  if valid_603933 != nil:
    section.add "X-Amz-Algorithm", valid_603933
  var valid_603934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "X-Amz-SignedHeaders", valid_603934
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603935: Call_GetResetDBParameterGroup_603920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603935.validator(path, query, header, formData, body)
  let scheme = call_603935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603935.url(scheme.get, call_603935.host, call_603935.base,
                         call_603935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603935, url, valid)

proc call*(call_603936: Call_GetResetDBParameterGroup_603920;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603937 = newJObject()
  add(query_603937, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_603937.add "Parameters", Parameters
  add(query_603937, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_603937, "Action", newJString(Action))
  add(query_603937, "Version", newJString(Version))
  result = call_603936.call(nil, query_603937, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_603920(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_603921, base: "/",
    url: url_GetResetDBParameterGroup_603922, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_603987 = ref object of OpenApiRestCall_601373
proc url_PostRestoreDBInstanceFromDBSnapshot_603989(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceFromDBSnapshot_603988(path: JsonNode;
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
  var valid_603990 = query.getOrDefault("Action")
  valid_603990 = validateParameter(valid_603990, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_603990 != nil:
    section.add "Action", valid_603990
  var valid_603991 = query.getOrDefault("Version")
  valid_603991 = validateParameter(valid_603991, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603991 != nil:
    section.add "Version", valid_603991
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603992 = header.getOrDefault("X-Amz-Signature")
  valid_603992 = validateParameter(valid_603992, JString, required = false,
                                 default = nil)
  if valid_603992 != nil:
    section.add "X-Amz-Signature", valid_603992
  var valid_603993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603993 = validateParameter(valid_603993, JString, required = false,
                                 default = nil)
  if valid_603993 != nil:
    section.add "X-Amz-Content-Sha256", valid_603993
  var valid_603994 = header.getOrDefault("X-Amz-Date")
  valid_603994 = validateParameter(valid_603994, JString, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "X-Amz-Date", valid_603994
  var valid_603995 = header.getOrDefault("X-Amz-Credential")
  valid_603995 = validateParameter(valid_603995, JString, required = false,
                                 default = nil)
  if valid_603995 != nil:
    section.add "X-Amz-Credential", valid_603995
  var valid_603996 = header.getOrDefault("X-Amz-Security-Token")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "X-Amz-Security-Token", valid_603996
  var valid_603997 = header.getOrDefault("X-Amz-Algorithm")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "X-Amz-Algorithm", valid_603997
  var valid_603998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "X-Amz-SignedHeaders", valid_603998
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
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_603999 = formData.getOrDefault("Port")
  valid_603999 = validateParameter(valid_603999, JInt, required = false, default = nil)
  if valid_603999 != nil:
    section.add "Port", valid_603999
  var valid_604000 = formData.getOrDefault("DBInstanceClass")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "DBInstanceClass", valid_604000
  var valid_604001 = formData.getOrDefault("MultiAZ")
  valid_604001 = validateParameter(valid_604001, JBool, required = false, default = nil)
  if valid_604001 != nil:
    section.add "MultiAZ", valid_604001
  var valid_604002 = formData.getOrDefault("AvailabilityZone")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "AvailabilityZone", valid_604002
  var valid_604003 = formData.getOrDefault("Engine")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "Engine", valid_604003
  var valid_604004 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604004 = validateParameter(valid_604004, JBool, required = false, default = nil)
  if valid_604004 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604004
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604005 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604005 = validateParameter(valid_604005, JString, required = true,
                                 default = nil)
  if valid_604005 != nil:
    section.add "DBInstanceIdentifier", valid_604005
  var valid_604006 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_604006 = validateParameter(valid_604006, JString, required = true,
                                 default = nil)
  if valid_604006 != nil:
    section.add "DBSnapshotIdentifier", valid_604006
  var valid_604007 = formData.getOrDefault("DBName")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "DBName", valid_604007
  var valid_604008 = formData.getOrDefault("Iops")
  valid_604008 = validateParameter(valid_604008, JInt, required = false, default = nil)
  if valid_604008 != nil:
    section.add "Iops", valid_604008
  var valid_604009 = formData.getOrDefault("PubliclyAccessible")
  valid_604009 = validateParameter(valid_604009, JBool, required = false, default = nil)
  if valid_604009 != nil:
    section.add "PubliclyAccessible", valid_604009
  var valid_604010 = formData.getOrDefault("LicenseModel")
  valid_604010 = validateParameter(valid_604010, JString, required = false,
                                 default = nil)
  if valid_604010 != nil:
    section.add "LicenseModel", valid_604010
  var valid_604011 = formData.getOrDefault("Tags")
  valid_604011 = validateParameter(valid_604011, JArray, required = false,
                                 default = nil)
  if valid_604011 != nil:
    section.add "Tags", valid_604011
  var valid_604012 = formData.getOrDefault("DBSubnetGroupName")
  valid_604012 = validateParameter(valid_604012, JString, required = false,
                                 default = nil)
  if valid_604012 != nil:
    section.add "DBSubnetGroupName", valid_604012
  var valid_604013 = formData.getOrDefault("OptionGroupName")
  valid_604013 = validateParameter(valid_604013, JString, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "OptionGroupName", valid_604013
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604014: Call_PostRestoreDBInstanceFromDBSnapshot_603987;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604014.validator(path, query, header, formData, body)
  let scheme = call_604014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604014.url(scheme.get, call_604014.host, call_604014.base,
                         call_604014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604014, url, valid)

proc call*(call_604015: Call_PostRestoreDBInstanceFromDBSnapshot_603987;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          LicenseModel: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          Version: string = "2013-09-09"): Recallable =
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
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_604016 = newJObject()
  var formData_604017 = newJObject()
  add(formData_604017, "Port", newJInt(Port))
  add(formData_604017, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604017, "MultiAZ", newJBool(MultiAZ))
  add(formData_604017, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_604017, "Engine", newJString(Engine))
  add(formData_604017, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_604017, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604017, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_604017, "DBName", newJString(DBName))
  add(formData_604017, "Iops", newJInt(Iops))
  add(formData_604017, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_604016, "Action", newJString(Action))
  add(formData_604017, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_604017.add "Tags", Tags
  add(formData_604017, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_604017, "OptionGroupName", newJString(OptionGroupName))
  add(query_604016, "Version", newJString(Version))
  result = call_604015.call(nil, query_604016, nil, formData_604017, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_603987(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_603988, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_603989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_603957 = ref object of OpenApiRestCall_601373
proc url_GetRestoreDBInstanceFromDBSnapshot_603959(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceFromDBSnapshot_603958(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   Engine: JString
  ##   Tags: JArray
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
  var valid_603960 = query.getOrDefault("DBName")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "DBName", valid_603960
  var valid_603961 = query.getOrDefault("Engine")
  valid_603961 = validateParameter(valid_603961, JString, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "Engine", valid_603961
  var valid_603962 = query.getOrDefault("Tags")
  valid_603962 = validateParameter(valid_603962, JArray, required = false,
                                 default = nil)
  if valid_603962 != nil:
    section.add "Tags", valid_603962
  var valid_603963 = query.getOrDefault("LicenseModel")
  valid_603963 = validateParameter(valid_603963, JString, required = false,
                                 default = nil)
  if valid_603963 != nil:
    section.add "LicenseModel", valid_603963
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603964 = query.getOrDefault("DBInstanceIdentifier")
  valid_603964 = validateParameter(valid_603964, JString, required = true,
                                 default = nil)
  if valid_603964 != nil:
    section.add "DBInstanceIdentifier", valid_603964
  var valid_603965 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603965 = validateParameter(valid_603965, JString, required = true,
                                 default = nil)
  if valid_603965 != nil:
    section.add "DBSnapshotIdentifier", valid_603965
  var valid_603966 = query.getOrDefault("Action")
  valid_603966 = validateParameter(valid_603966, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_603966 != nil:
    section.add "Action", valid_603966
  var valid_603967 = query.getOrDefault("MultiAZ")
  valid_603967 = validateParameter(valid_603967, JBool, required = false, default = nil)
  if valid_603967 != nil:
    section.add "MultiAZ", valid_603967
  var valid_603968 = query.getOrDefault("Port")
  valid_603968 = validateParameter(valid_603968, JInt, required = false, default = nil)
  if valid_603968 != nil:
    section.add "Port", valid_603968
  var valid_603969 = query.getOrDefault("AvailabilityZone")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "AvailabilityZone", valid_603969
  var valid_603970 = query.getOrDefault("OptionGroupName")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "OptionGroupName", valid_603970
  var valid_603971 = query.getOrDefault("DBSubnetGroupName")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "DBSubnetGroupName", valid_603971
  var valid_603972 = query.getOrDefault("Version")
  valid_603972 = validateParameter(valid_603972, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603972 != nil:
    section.add "Version", valid_603972
  var valid_603973 = query.getOrDefault("DBInstanceClass")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "DBInstanceClass", valid_603973
  var valid_603974 = query.getOrDefault("PubliclyAccessible")
  valid_603974 = validateParameter(valid_603974, JBool, required = false, default = nil)
  if valid_603974 != nil:
    section.add "PubliclyAccessible", valid_603974
  var valid_603975 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603975 = validateParameter(valid_603975, JBool, required = false, default = nil)
  if valid_603975 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603975
  var valid_603976 = query.getOrDefault("Iops")
  valid_603976 = validateParameter(valid_603976, JInt, required = false, default = nil)
  if valid_603976 != nil:
    section.add "Iops", valid_603976
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603977 = header.getOrDefault("X-Amz-Signature")
  valid_603977 = validateParameter(valid_603977, JString, required = false,
                                 default = nil)
  if valid_603977 != nil:
    section.add "X-Amz-Signature", valid_603977
  var valid_603978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603978 = validateParameter(valid_603978, JString, required = false,
                                 default = nil)
  if valid_603978 != nil:
    section.add "X-Amz-Content-Sha256", valid_603978
  var valid_603979 = header.getOrDefault("X-Amz-Date")
  valid_603979 = validateParameter(valid_603979, JString, required = false,
                                 default = nil)
  if valid_603979 != nil:
    section.add "X-Amz-Date", valid_603979
  var valid_603980 = header.getOrDefault("X-Amz-Credential")
  valid_603980 = validateParameter(valid_603980, JString, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "X-Amz-Credential", valid_603980
  var valid_603981 = header.getOrDefault("X-Amz-Security-Token")
  valid_603981 = validateParameter(valid_603981, JString, required = false,
                                 default = nil)
  if valid_603981 != nil:
    section.add "X-Amz-Security-Token", valid_603981
  var valid_603982 = header.getOrDefault("X-Amz-Algorithm")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "X-Amz-Algorithm", valid_603982
  var valid_603983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-SignedHeaders", valid_603983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603984: Call_GetRestoreDBInstanceFromDBSnapshot_603957;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603984.validator(path, query, header, formData, body)
  let scheme = call_603984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603984.url(scheme.get, call_603984.host, call_603984.base,
                         call_603984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603984, url, valid)

proc call*(call_603985: Call_GetRestoreDBInstanceFromDBSnapshot_603957;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          DBName: string = ""; Engine: string = ""; Tags: JsonNode = nil;
          LicenseModel: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-09-09";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   DBName: string
  ##   Engine: string
  ##   Tags: JArray
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
  var query_603986 = newJObject()
  add(query_603986, "DBName", newJString(DBName))
  add(query_603986, "Engine", newJString(Engine))
  if Tags != nil:
    query_603986.add "Tags", Tags
  add(query_603986, "LicenseModel", newJString(LicenseModel))
  add(query_603986, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603986, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603986, "Action", newJString(Action))
  add(query_603986, "MultiAZ", newJBool(MultiAZ))
  add(query_603986, "Port", newJInt(Port))
  add(query_603986, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603986, "OptionGroupName", newJString(OptionGroupName))
  add(query_603986, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603986, "Version", newJString(Version))
  add(query_603986, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603986, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603986, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603986, "Iops", newJInt(Iops))
  result = call_603985.call(nil, query_603986, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_603957(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_603958, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_603959,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_604050 = ref object of OpenApiRestCall_601373
proc url_PostRestoreDBInstanceToPointInTime_604052(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceToPointInTime_604051(path: JsonNode;
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
  var valid_604053 = query.getOrDefault("Action")
  valid_604053 = validateParameter(valid_604053, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_604053 != nil:
    section.add "Action", valid_604053
  var valid_604054 = query.getOrDefault("Version")
  valid_604054 = validateParameter(valid_604054, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604054 != nil:
    section.add "Version", valid_604054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604055 = header.getOrDefault("X-Amz-Signature")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "X-Amz-Signature", valid_604055
  var valid_604056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "X-Amz-Content-Sha256", valid_604056
  var valid_604057 = header.getOrDefault("X-Amz-Date")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "X-Amz-Date", valid_604057
  var valid_604058 = header.getOrDefault("X-Amz-Credential")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "X-Amz-Credential", valid_604058
  var valid_604059 = header.getOrDefault("X-Amz-Security-Token")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "X-Amz-Security-Token", valid_604059
  var valid_604060 = header.getOrDefault("X-Amz-Algorithm")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "X-Amz-Algorithm", valid_604060
  var valid_604061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-SignedHeaders", valid_604061
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
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   RestoreTime: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_604062 = formData.getOrDefault("Port")
  valid_604062 = validateParameter(valid_604062, JInt, required = false, default = nil)
  if valid_604062 != nil:
    section.add "Port", valid_604062
  var valid_604063 = formData.getOrDefault("DBInstanceClass")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "DBInstanceClass", valid_604063
  var valid_604064 = formData.getOrDefault("MultiAZ")
  valid_604064 = validateParameter(valid_604064, JBool, required = false, default = nil)
  if valid_604064 != nil:
    section.add "MultiAZ", valid_604064
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_604065 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_604065 = validateParameter(valid_604065, JString, required = true,
                                 default = nil)
  if valid_604065 != nil:
    section.add "SourceDBInstanceIdentifier", valid_604065
  var valid_604066 = formData.getOrDefault("AvailabilityZone")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "AvailabilityZone", valid_604066
  var valid_604067 = formData.getOrDefault("Engine")
  valid_604067 = validateParameter(valid_604067, JString, required = false,
                                 default = nil)
  if valid_604067 != nil:
    section.add "Engine", valid_604067
  var valid_604068 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604068 = validateParameter(valid_604068, JBool, required = false, default = nil)
  if valid_604068 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604068
  var valid_604069 = formData.getOrDefault("UseLatestRestorableTime")
  valid_604069 = validateParameter(valid_604069, JBool, required = false, default = nil)
  if valid_604069 != nil:
    section.add "UseLatestRestorableTime", valid_604069
  var valid_604070 = formData.getOrDefault("DBName")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "DBName", valid_604070
  var valid_604071 = formData.getOrDefault("Iops")
  valid_604071 = validateParameter(valid_604071, JInt, required = false, default = nil)
  if valid_604071 != nil:
    section.add "Iops", valid_604071
  var valid_604072 = formData.getOrDefault("PubliclyAccessible")
  valid_604072 = validateParameter(valid_604072, JBool, required = false, default = nil)
  if valid_604072 != nil:
    section.add "PubliclyAccessible", valid_604072
  var valid_604073 = formData.getOrDefault("LicenseModel")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "LicenseModel", valid_604073
  var valid_604074 = formData.getOrDefault("Tags")
  valid_604074 = validateParameter(valid_604074, JArray, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "Tags", valid_604074
  var valid_604075 = formData.getOrDefault("DBSubnetGroupName")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "DBSubnetGroupName", valid_604075
  var valid_604076 = formData.getOrDefault("OptionGroupName")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "OptionGroupName", valid_604076
  var valid_604077 = formData.getOrDefault("RestoreTime")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "RestoreTime", valid_604077
  var valid_604078 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_604078 = validateParameter(valid_604078, JString, required = true,
                                 default = nil)
  if valid_604078 != nil:
    section.add "TargetDBInstanceIdentifier", valid_604078
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604079: Call_PostRestoreDBInstanceToPointInTime_604050;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604079.validator(path, query, header, formData, body)
  let scheme = call_604079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604079.url(scheme.get, call_604079.host, call_604079.base,
                         call_604079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604079, url, valid)

proc call*(call_604080: Call_PostRestoreDBInstanceToPointInTime_604050;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false;
          UseLatestRestorableTime: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          LicenseModel: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          RestoreTime: string = ""; Version: string = "2013-09-09"): Recallable =
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
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   RestoreTime: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   Version: string (required)
  var query_604081 = newJObject()
  var formData_604082 = newJObject()
  add(formData_604082, "Port", newJInt(Port))
  add(formData_604082, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604082, "MultiAZ", newJBool(MultiAZ))
  add(formData_604082, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_604082, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_604082, "Engine", newJString(Engine))
  add(formData_604082, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_604082, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_604082, "DBName", newJString(DBName))
  add(formData_604082, "Iops", newJInt(Iops))
  add(formData_604082, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_604081, "Action", newJString(Action))
  add(formData_604082, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_604082.add "Tags", Tags
  add(formData_604082, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_604082, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604082, "RestoreTime", newJString(RestoreTime))
  add(formData_604082, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_604081, "Version", newJString(Version))
  result = call_604080.call(nil, query_604081, nil, formData_604082, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_604050(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_604051, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_604052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_604018 = ref object of OpenApiRestCall_601373
proc url_GetRestoreDBInstanceToPointInTime_604020(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceToPointInTime_604019(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   Engine: JString
  ##   UseLatestRestorableTime: JBool
  ##   Tags: JArray
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
  var valid_604021 = query.getOrDefault("DBName")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "DBName", valid_604021
  var valid_604022 = query.getOrDefault("Engine")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "Engine", valid_604022
  var valid_604023 = query.getOrDefault("UseLatestRestorableTime")
  valid_604023 = validateParameter(valid_604023, JBool, required = false, default = nil)
  if valid_604023 != nil:
    section.add "UseLatestRestorableTime", valid_604023
  var valid_604024 = query.getOrDefault("Tags")
  valid_604024 = validateParameter(valid_604024, JArray, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "Tags", valid_604024
  var valid_604025 = query.getOrDefault("LicenseModel")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "LicenseModel", valid_604025
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_604026 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_604026 = validateParameter(valid_604026, JString, required = true,
                                 default = nil)
  if valid_604026 != nil:
    section.add "TargetDBInstanceIdentifier", valid_604026
  var valid_604027 = query.getOrDefault("Action")
  valid_604027 = validateParameter(valid_604027, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_604027 != nil:
    section.add "Action", valid_604027
  var valid_604028 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_604028 = validateParameter(valid_604028, JString, required = true,
                                 default = nil)
  if valid_604028 != nil:
    section.add "SourceDBInstanceIdentifier", valid_604028
  var valid_604029 = query.getOrDefault("MultiAZ")
  valid_604029 = validateParameter(valid_604029, JBool, required = false, default = nil)
  if valid_604029 != nil:
    section.add "MultiAZ", valid_604029
  var valid_604030 = query.getOrDefault("Port")
  valid_604030 = validateParameter(valid_604030, JInt, required = false, default = nil)
  if valid_604030 != nil:
    section.add "Port", valid_604030
  var valid_604031 = query.getOrDefault("AvailabilityZone")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "AvailabilityZone", valid_604031
  var valid_604032 = query.getOrDefault("OptionGroupName")
  valid_604032 = validateParameter(valid_604032, JString, required = false,
                                 default = nil)
  if valid_604032 != nil:
    section.add "OptionGroupName", valid_604032
  var valid_604033 = query.getOrDefault("DBSubnetGroupName")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "DBSubnetGroupName", valid_604033
  var valid_604034 = query.getOrDefault("RestoreTime")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "RestoreTime", valid_604034
  var valid_604035 = query.getOrDefault("DBInstanceClass")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "DBInstanceClass", valid_604035
  var valid_604036 = query.getOrDefault("PubliclyAccessible")
  valid_604036 = validateParameter(valid_604036, JBool, required = false, default = nil)
  if valid_604036 != nil:
    section.add "PubliclyAccessible", valid_604036
  var valid_604037 = query.getOrDefault("Version")
  valid_604037 = validateParameter(valid_604037, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604037 != nil:
    section.add "Version", valid_604037
  var valid_604038 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604038 = validateParameter(valid_604038, JBool, required = false, default = nil)
  if valid_604038 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604038
  var valid_604039 = query.getOrDefault("Iops")
  valid_604039 = validateParameter(valid_604039, JInt, required = false, default = nil)
  if valid_604039 != nil:
    section.add "Iops", valid_604039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604040 = header.getOrDefault("X-Amz-Signature")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Signature", valid_604040
  var valid_604041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-Content-Sha256", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-Date")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Date", valid_604042
  var valid_604043 = header.getOrDefault("X-Amz-Credential")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-Credential", valid_604043
  var valid_604044 = header.getOrDefault("X-Amz-Security-Token")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "X-Amz-Security-Token", valid_604044
  var valid_604045 = header.getOrDefault("X-Amz-Algorithm")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-Algorithm", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-SignedHeaders", valid_604046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604047: Call_GetRestoreDBInstanceToPointInTime_604018;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604047.validator(path, query, header, formData, body)
  let scheme = call_604047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604047.url(scheme.get, call_604047.host, call_604047.base,
                         call_604047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604047, url, valid)

proc call*(call_604048: Call_GetRestoreDBInstanceToPointInTime_604018;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          DBName: string = ""; Engine: string = "";
          UseLatestRestorableTime: bool = false; Tags: JsonNode = nil;
          LicenseModel: string = "";
          Action: string = "RestoreDBInstanceToPointInTime"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; RestoreTime: string = "";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          Version: string = "2013-09-09"; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   DBName: string
  ##   Engine: string
  ##   UseLatestRestorableTime: bool
  ##   Tags: JArray
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
  var query_604049 = newJObject()
  add(query_604049, "DBName", newJString(DBName))
  add(query_604049, "Engine", newJString(Engine))
  add(query_604049, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_604049.add "Tags", Tags
  add(query_604049, "LicenseModel", newJString(LicenseModel))
  add(query_604049, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_604049, "Action", newJString(Action))
  add(query_604049, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_604049, "MultiAZ", newJBool(MultiAZ))
  add(query_604049, "Port", newJInt(Port))
  add(query_604049, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_604049, "OptionGroupName", newJString(OptionGroupName))
  add(query_604049, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604049, "RestoreTime", newJString(RestoreTime))
  add(query_604049, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604049, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_604049, "Version", newJString(Version))
  add(query_604049, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604049, "Iops", newJInt(Iops))
  result = call_604048.call(nil, query_604049, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_604018(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_604019, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_604020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_604103 = ref object of OpenApiRestCall_601373
proc url_PostRevokeDBSecurityGroupIngress_604105(protocol: Scheme; host: string;
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

proc validate_PostRevokeDBSecurityGroupIngress_604104(path: JsonNode;
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
  var valid_604106 = query.getOrDefault("Action")
  valid_604106 = validateParameter(valid_604106, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_604106 != nil:
    section.add "Action", valid_604106
  var valid_604107 = query.getOrDefault("Version")
  valid_604107 = validateParameter(valid_604107, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604107 != nil:
    section.add "Version", valid_604107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604108 = header.getOrDefault("X-Amz-Signature")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "X-Amz-Signature", valid_604108
  var valid_604109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Content-Sha256", valid_604109
  var valid_604110 = header.getOrDefault("X-Amz-Date")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-Date", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-Credential")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Credential", valid_604111
  var valid_604112 = header.getOrDefault("X-Amz-Security-Token")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-Security-Token", valid_604112
  var valid_604113 = header.getOrDefault("X-Amz-Algorithm")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-Algorithm", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-SignedHeaders", valid_604114
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_604115 = formData.getOrDefault("DBSecurityGroupName")
  valid_604115 = validateParameter(valid_604115, JString, required = true,
                                 default = nil)
  if valid_604115 != nil:
    section.add "DBSecurityGroupName", valid_604115
  var valid_604116 = formData.getOrDefault("EC2SecurityGroupName")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "EC2SecurityGroupName", valid_604116
  var valid_604117 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_604117 = validateParameter(valid_604117, JString, required = false,
                                 default = nil)
  if valid_604117 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_604117
  var valid_604118 = formData.getOrDefault("EC2SecurityGroupId")
  valid_604118 = validateParameter(valid_604118, JString, required = false,
                                 default = nil)
  if valid_604118 != nil:
    section.add "EC2SecurityGroupId", valid_604118
  var valid_604119 = formData.getOrDefault("CIDRIP")
  valid_604119 = validateParameter(valid_604119, JString, required = false,
                                 default = nil)
  if valid_604119 != nil:
    section.add "CIDRIP", valid_604119
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604120: Call_PostRevokeDBSecurityGroupIngress_604103;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604120.validator(path, query, header, formData, body)
  let scheme = call_604120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604120.url(scheme.get, call_604120.host, call_604120.base,
                         call_604120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604120, url, valid)

proc call*(call_604121: Call_PostRevokeDBSecurityGroupIngress_604103;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupOwnerId: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-09-09"): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604122 = newJObject()
  var formData_604123 = newJObject()
  add(formData_604123, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_604123, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_604123, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_604123, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_604123, "CIDRIP", newJString(CIDRIP))
  add(query_604122, "Action", newJString(Action))
  add(query_604122, "Version", newJString(Version))
  result = call_604121.call(nil, query_604122, nil, formData_604123, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_604103(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_604104, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_604105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_604083 = ref object of OpenApiRestCall_601373
proc url_GetRevokeDBSecurityGroupIngress_604085(protocol: Scheme; host: string;
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

proc validate_GetRevokeDBSecurityGroupIngress_604084(path: JsonNode;
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
  var valid_604086 = query.getOrDefault("EC2SecurityGroupName")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "EC2SecurityGroupName", valid_604086
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_604087 = query.getOrDefault("DBSecurityGroupName")
  valid_604087 = validateParameter(valid_604087, JString, required = true,
                                 default = nil)
  if valid_604087 != nil:
    section.add "DBSecurityGroupName", valid_604087
  var valid_604088 = query.getOrDefault("EC2SecurityGroupId")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "EC2SecurityGroupId", valid_604088
  var valid_604089 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_604089 = validateParameter(valid_604089, JString, required = false,
                                 default = nil)
  if valid_604089 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_604089
  var valid_604090 = query.getOrDefault("Action")
  valid_604090 = validateParameter(valid_604090, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_604090 != nil:
    section.add "Action", valid_604090
  var valid_604091 = query.getOrDefault("Version")
  valid_604091 = validateParameter(valid_604091, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604091 != nil:
    section.add "Version", valid_604091
  var valid_604092 = query.getOrDefault("CIDRIP")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "CIDRIP", valid_604092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604093 = header.getOrDefault("X-Amz-Signature")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-Signature", valid_604093
  var valid_604094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-Content-Sha256", valid_604094
  var valid_604095 = header.getOrDefault("X-Amz-Date")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-Date", valid_604095
  var valid_604096 = header.getOrDefault("X-Amz-Credential")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-Credential", valid_604096
  var valid_604097 = header.getOrDefault("X-Amz-Security-Token")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "X-Amz-Security-Token", valid_604097
  var valid_604098 = header.getOrDefault("X-Amz-Algorithm")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "X-Amz-Algorithm", valid_604098
  var valid_604099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-SignedHeaders", valid_604099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604100: Call_GetRevokeDBSecurityGroupIngress_604083;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604100.validator(path, query, header, formData, body)
  let scheme = call_604100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604100.url(scheme.get, call_604100.host, call_604100.base,
                         call_604100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604100, url, valid)

proc call*(call_604101: Call_GetRevokeDBSecurityGroupIngress_604083;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupId: string = ""; EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-09-09"; CIDRIP: string = ""): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CIDRIP: string
  var query_604102 = newJObject()
  add(query_604102, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_604102, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_604102, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_604102, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_604102, "Action", newJString(Action))
  add(query_604102, "Version", newJString(Version))
  add(query_604102, "CIDRIP", newJString(CIDRIP))
  result = call_604101.call(nil, query_604102, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_604083(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_604084, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_604085,
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
