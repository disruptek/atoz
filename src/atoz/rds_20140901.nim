
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Relational Database Service
## version: 2014-09-01
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"; CIDRIP: string = ""): Recallable =
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
  Call_PostCopyDBParameterGroup_602096 = ref object of OpenApiRestCall_601373
proc url_PostCopyDBParameterGroup_602098(protocol: Scheme; host: string;
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

proc validate_PostCopyDBParameterGroup_602097(path: JsonNode; query: JsonNode;
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
  var valid_602099 = query.getOrDefault("Action")
  valid_602099 = validateParameter(valid_602099, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_602099 != nil:
    section.add "Action", valid_602099
  var valid_602100 = query.getOrDefault("Version")
  valid_602100 = validateParameter(valid_602100, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602100 != nil:
    section.add "Version", valid_602100
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602101 = header.getOrDefault("X-Amz-Signature")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Signature", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Content-Sha256", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Date")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Date", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Credential")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Credential", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Security-Token")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Security-Token", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Algorithm")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Algorithm", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-SignedHeaders", valid_602107
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBParameterGroupIdentifier: JString (required)
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBParameterGroupIdentifier` field"
  var valid_602108 = formData.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_602108 = validateParameter(valid_602108, JString, required = true,
                                 default = nil)
  if valid_602108 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_602108
  var valid_602109 = formData.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_602109 = validateParameter(valid_602109, JString, required = true,
                                 default = nil)
  if valid_602109 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_602109
  var valid_602110 = formData.getOrDefault("TargetDBParameterGroupDescription")
  valid_602110 = validateParameter(valid_602110, JString, required = true,
                                 default = nil)
  if valid_602110 != nil:
    section.add "TargetDBParameterGroupDescription", valid_602110
  var valid_602111 = formData.getOrDefault("Tags")
  valid_602111 = validateParameter(valid_602111, JArray, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "Tags", valid_602111
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602112: Call_PostCopyDBParameterGroup_602096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602112.validator(path, query, header, formData, body)
  let scheme = call_602112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602112.url(scheme.get, call_602112.host, call_602112.base,
                         call_602112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602112, url, valid)

proc call*(call_602113: Call_PostCopyDBParameterGroup_602096;
          SourceDBParameterGroupIdentifier: string;
          TargetDBParameterGroupIdentifier: string;
          TargetDBParameterGroupDescription: string;
          Action: string = "CopyDBParameterGroup"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBParameterGroup
  ##   SourceDBParameterGroupIdentifier: string (required)
  ##   TargetDBParameterGroupIdentifier: string (required)
  ##   TargetDBParameterGroupDescription: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_602114 = newJObject()
  var formData_602115 = newJObject()
  add(formData_602115, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(formData_602115, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  add(formData_602115, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_602114, "Action", newJString(Action))
  if Tags != nil:
    formData_602115.add "Tags", Tags
  add(query_602114, "Version", newJString(Version))
  result = call_602113.call(nil, query_602114, nil, formData_602115, nil)

var postCopyDBParameterGroup* = Call_PostCopyDBParameterGroup_602096(
    name: "postCopyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_PostCopyDBParameterGroup_602097, base: "/",
    url: url_PostCopyDBParameterGroup_602098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBParameterGroup_602077 = ref object of OpenApiRestCall_601373
proc url_GetCopyDBParameterGroup_602079(protocol: Scheme; host: string; base: string;
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

proc validate_GetCopyDBParameterGroup_602078(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBParameterGroupIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBParameterGroupIdentifier` field"
  var valid_602080 = query.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_602080 = validateParameter(valid_602080, JString, required = true,
                                 default = nil)
  if valid_602080 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_602080
  var valid_602081 = query.getOrDefault("Tags")
  valid_602081 = validateParameter(valid_602081, JArray, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "Tags", valid_602081
  var valid_602082 = query.getOrDefault("TargetDBParameterGroupDescription")
  valid_602082 = validateParameter(valid_602082, JString, required = true,
                                 default = nil)
  if valid_602082 != nil:
    section.add "TargetDBParameterGroupDescription", valid_602082
  var valid_602083 = query.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_602083 = validateParameter(valid_602083, JString, required = true,
                                 default = nil)
  if valid_602083 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_602083
  var valid_602084 = query.getOrDefault("Action")
  valid_602084 = validateParameter(valid_602084, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_602084 != nil:
    section.add "Action", valid_602084
  var valid_602085 = query.getOrDefault("Version")
  valid_602085 = validateParameter(valid_602085, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602085 != nil:
    section.add "Version", valid_602085
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602086 = header.getOrDefault("X-Amz-Signature")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Signature", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Content-Sha256", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Date")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Date", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Credential")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Credential", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Security-Token")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Security-Token", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Algorithm")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Algorithm", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-SignedHeaders", valid_602092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602093: Call_GetCopyDBParameterGroup_602077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602093.validator(path, query, header, formData, body)
  let scheme = call_602093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602093.url(scheme.get, call_602093.host, call_602093.base,
                         call_602093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602093, url, valid)

proc call*(call_602094: Call_GetCopyDBParameterGroup_602077;
          SourceDBParameterGroupIdentifier: string;
          TargetDBParameterGroupDescription: string;
          TargetDBParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCopyDBParameterGroup
  ##   SourceDBParameterGroupIdentifier: string (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupDescription: string (required)
  ##   TargetDBParameterGroupIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602095 = newJObject()
  add(query_602095, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  if Tags != nil:
    query_602095.add "Tags", Tags
  add(query_602095, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_602095, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  add(query_602095, "Action", newJString(Action))
  add(query_602095, "Version", newJString(Version))
  result = call_602094.call(nil, query_602095, nil, nil, nil)

var getCopyDBParameterGroup* = Call_GetCopyDBParameterGroup_602077(
    name: "getCopyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_GetCopyDBParameterGroup_602078, base: "/",
    url: url_GetCopyDBParameterGroup_602079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_602134 = ref object of OpenApiRestCall_601373
proc url_PostCopyDBSnapshot_602136(protocol: Scheme; host: string; base: string;
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

proc validate_PostCopyDBSnapshot_602135(path: JsonNode; query: JsonNode;
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
  var valid_602137 = query.getOrDefault("Action")
  valid_602137 = validateParameter(valid_602137, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_602137 != nil:
    section.add "Action", valid_602137
  var valid_602138 = query.getOrDefault("Version")
  valid_602138 = validateParameter(valid_602138, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602138 != nil:
    section.add "Version", valid_602138
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602139 = header.getOrDefault("X-Amz-Signature")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Signature", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Content-Sha256", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Date")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Date", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Credential")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Credential", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Security-Token")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Security-Token", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Algorithm")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Algorithm", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-SignedHeaders", valid_602145
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_602146 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_602146 = validateParameter(valid_602146, JString, required = true,
                                 default = nil)
  if valid_602146 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_602146
  var valid_602147 = formData.getOrDefault("Tags")
  valid_602147 = validateParameter(valid_602147, JArray, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "Tags", valid_602147
  var valid_602148 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_602148 = validateParameter(valid_602148, JString, required = true,
                                 default = nil)
  if valid_602148 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_602148
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602149: Call_PostCopyDBSnapshot_602134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602149.validator(path, query, header, formData, body)
  let scheme = call_602149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602149.url(scheme.get, call_602149.host, call_602149.base,
                         call_602149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602149, url, valid)

proc call*(call_602150: Call_PostCopyDBSnapshot_602134;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_602151 = newJObject()
  var formData_602152 = newJObject()
  add(formData_602152, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_602151, "Action", newJString(Action))
  if Tags != nil:
    formData_602152.add "Tags", Tags
  add(formData_602152, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_602151, "Version", newJString(Version))
  result = call_602150.call(nil, query_602151, nil, formData_602152, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_602134(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_602135, base: "/",
    url: url_PostCopyDBSnapshot_602136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_602116 = ref object of OpenApiRestCall_601373
proc url_GetCopyDBSnapshot_602118(protocol: Scheme; host: string; base: string;
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

proc validate_GetCopyDBSnapshot_602117(path: JsonNode; query: JsonNode;
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
  var valid_602119 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_602119 = validateParameter(valid_602119, JString, required = true,
                                 default = nil)
  if valid_602119 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_602119
  var valid_602120 = query.getOrDefault("Tags")
  valid_602120 = validateParameter(valid_602120, JArray, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "Tags", valid_602120
  var valid_602121 = query.getOrDefault("Action")
  valid_602121 = validateParameter(valid_602121, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_602121 != nil:
    section.add "Action", valid_602121
  var valid_602122 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_602122 = validateParameter(valid_602122, JString, required = true,
                                 default = nil)
  if valid_602122 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_602122
  var valid_602123 = query.getOrDefault("Version")
  valid_602123 = validateParameter(valid_602123, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602123 != nil:
    section.add "Version", valid_602123
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602124 = header.getOrDefault("X-Amz-Signature")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Signature", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Content-Sha256", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Date")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Date", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Credential")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Credential", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Security-Token")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Security-Token", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Algorithm")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Algorithm", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-SignedHeaders", valid_602130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602131: Call_GetCopyDBSnapshot_602116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602131.validator(path, query, header, formData, body)
  let scheme = call_602131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602131.url(scheme.get, call_602131.host, call_602131.base,
                         call_602131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602131, url, valid)

proc call*(call_602132: Call_GetCopyDBSnapshot_602116;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_602133 = newJObject()
  add(query_602133, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  if Tags != nil:
    query_602133.add "Tags", Tags
  add(query_602133, "Action", newJString(Action))
  add(query_602133, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_602133, "Version", newJString(Version))
  result = call_602132.call(nil, query_602133, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_602116(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_602117,
    base: "/", url: url_GetCopyDBSnapshot_602118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyOptionGroup_602172 = ref object of OpenApiRestCall_601373
proc url_PostCopyOptionGroup_602174(protocol: Scheme; host: string; base: string;
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

proc validate_PostCopyOptionGroup_602173(path: JsonNode; query: JsonNode;
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
  var valid_602175 = query.getOrDefault("Action")
  valid_602175 = validateParameter(valid_602175, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_602175 != nil:
    section.add "Action", valid_602175
  var valid_602176 = query.getOrDefault("Version")
  valid_602176 = validateParameter(valid_602176, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602176 != nil:
    section.add "Version", valid_602176
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602177 = header.getOrDefault("X-Amz-Signature")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Signature", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Content-Sha256", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Date")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Date", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Credential")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Credential", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Security-Token")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Security-Token", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Algorithm")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Algorithm", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-SignedHeaders", valid_602183
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetOptionGroupIdentifier: JString (required)
  ##   TargetOptionGroupDescription: JString (required)
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetOptionGroupIdentifier` field"
  var valid_602184 = formData.getOrDefault("TargetOptionGroupIdentifier")
  valid_602184 = validateParameter(valid_602184, JString, required = true,
                                 default = nil)
  if valid_602184 != nil:
    section.add "TargetOptionGroupIdentifier", valid_602184
  var valid_602185 = formData.getOrDefault("TargetOptionGroupDescription")
  valid_602185 = validateParameter(valid_602185, JString, required = true,
                                 default = nil)
  if valid_602185 != nil:
    section.add "TargetOptionGroupDescription", valid_602185
  var valid_602186 = formData.getOrDefault("SourceOptionGroupIdentifier")
  valid_602186 = validateParameter(valid_602186, JString, required = true,
                                 default = nil)
  if valid_602186 != nil:
    section.add "SourceOptionGroupIdentifier", valid_602186
  var valid_602187 = formData.getOrDefault("Tags")
  valid_602187 = validateParameter(valid_602187, JArray, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "Tags", valid_602187
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602188: Call_PostCopyOptionGroup_602172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602188.validator(path, query, header, formData, body)
  let scheme = call_602188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602188.url(scheme.get, call_602188.host, call_602188.base,
                         call_602188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602188, url, valid)

proc call*(call_602189: Call_PostCopyOptionGroup_602172;
          TargetOptionGroupIdentifier: string;
          TargetOptionGroupDescription: string;
          SourceOptionGroupIdentifier: string; Action: string = "CopyOptionGroup";
          Tags: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postCopyOptionGroup
  ##   TargetOptionGroupIdentifier: string (required)
  ##   TargetOptionGroupDescription: string (required)
  ##   SourceOptionGroupIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_602190 = newJObject()
  var formData_602191 = newJObject()
  add(formData_602191, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(formData_602191, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(formData_602191, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_602190, "Action", newJString(Action))
  if Tags != nil:
    formData_602191.add "Tags", Tags
  add(query_602190, "Version", newJString(Version))
  result = call_602189.call(nil, query_602190, nil, formData_602191, nil)

var postCopyOptionGroup* = Call_PostCopyOptionGroup_602172(
    name: "postCopyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_PostCopyOptionGroup_602173, base: "/",
    url: url_PostCopyOptionGroup_602174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyOptionGroup_602153 = ref object of OpenApiRestCall_601373
proc url_GetCopyOptionGroup_602155(protocol: Scheme; host: string; base: string;
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

proc validate_GetCopyOptionGroup_602154(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   TargetOptionGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   TargetOptionGroupIdentifier: JString (required)
  ##   Version: JString (required)
  ##   SourceOptionGroupIdentifier: JString (required)
  section = newJObject()
  var valid_602156 = query.getOrDefault("Tags")
  valid_602156 = validateParameter(valid_602156, JArray, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "Tags", valid_602156
  assert query != nil, "query argument is necessary due to required `TargetOptionGroupDescription` field"
  var valid_602157 = query.getOrDefault("TargetOptionGroupDescription")
  valid_602157 = validateParameter(valid_602157, JString, required = true,
                                 default = nil)
  if valid_602157 != nil:
    section.add "TargetOptionGroupDescription", valid_602157
  var valid_602158 = query.getOrDefault("Action")
  valid_602158 = validateParameter(valid_602158, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_602158 != nil:
    section.add "Action", valid_602158
  var valid_602159 = query.getOrDefault("TargetOptionGroupIdentifier")
  valid_602159 = validateParameter(valid_602159, JString, required = true,
                                 default = nil)
  if valid_602159 != nil:
    section.add "TargetOptionGroupIdentifier", valid_602159
  var valid_602160 = query.getOrDefault("Version")
  valid_602160 = validateParameter(valid_602160, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602160 != nil:
    section.add "Version", valid_602160
  var valid_602161 = query.getOrDefault("SourceOptionGroupIdentifier")
  valid_602161 = validateParameter(valid_602161, JString, required = true,
                                 default = nil)
  if valid_602161 != nil:
    section.add "SourceOptionGroupIdentifier", valid_602161
  result.add "query", section
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

proc call*(call_602169: Call_GetCopyOptionGroup_602153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602169.validator(path, query, header, formData, body)
  let scheme = call_602169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602169.url(scheme.get, call_602169.host, call_602169.base,
                         call_602169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602169, url, valid)

proc call*(call_602170: Call_GetCopyOptionGroup_602153;
          TargetOptionGroupDescription: string;
          TargetOptionGroupIdentifier: string;
          SourceOptionGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCopyOptionGroup
  ##   Tags: JArray
  ##   TargetOptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   TargetOptionGroupIdentifier: string (required)
  ##   Version: string (required)
  ##   SourceOptionGroupIdentifier: string (required)
  var query_602171 = newJObject()
  if Tags != nil:
    query_602171.add "Tags", Tags
  add(query_602171, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(query_602171, "Action", newJString(Action))
  add(query_602171, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(query_602171, "Version", newJString(Version))
  add(query_602171, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  result = call_602170.call(nil, query_602171, nil, nil, nil)

var getCopyOptionGroup* = Call_GetCopyOptionGroup_602153(
    name: "getCopyOptionGroup", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyOptionGroup", validator: validate_GetCopyOptionGroup_602154,
    base: "/", url: url_GetCopyOptionGroup_602155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_602235 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBInstance_602237(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBInstance_602236(path: JsonNode; query: JsonNode;
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
  var valid_602238 = query.getOrDefault("Action")
  valid_602238 = validateParameter(valid_602238, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_602238 != nil:
    section.add "Action", valid_602238
  var valid_602239 = query.getOrDefault("Version")
  valid_602239 = validateParameter(valid_602239, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602239 != nil:
    section.add "Version", valid_602239
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602240 = header.getOrDefault("X-Amz-Signature")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Signature", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Content-Sha256", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Date")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Date", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Credential")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Credential", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Security-Token")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Security-Token", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Algorithm")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Algorithm", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-SignedHeaders", valid_602246
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
  ##   TdeCredentialPassword: JString
  ##   DBName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   Iops: JInt
  ##   TdeCredentialArn: JString
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   CharacterSetName: JString
  ##   DBSecurityGroups: JArray
  ##   StorageType: JString
  ##   AllocatedStorage: JInt (required)
  section = newJObject()
  var valid_602247 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "PreferredMaintenanceWindow", valid_602247
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_602248 = formData.getOrDefault("DBInstanceClass")
  valid_602248 = validateParameter(valid_602248, JString, required = true,
                                 default = nil)
  if valid_602248 != nil:
    section.add "DBInstanceClass", valid_602248
  var valid_602249 = formData.getOrDefault("Port")
  valid_602249 = validateParameter(valid_602249, JInt, required = false, default = nil)
  if valid_602249 != nil:
    section.add "Port", valid_602249
  var valid_602250 = formData.getOrDefault("PreferredBackupWindow")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "PreferredBackupWindow", valid_602250
  var valid_602251 = formData.getOrDefault("MasterUserPassword")
  valid_602251 = validateParameter(valid_602251, JString, required = true,
                                 default = nil)
  if valid_602251 != nil:
    section.add "MasterUserPassword", valid_602251
  var valid_602252 = formData.getOrDefault("MultiAZ")
  valid_602252 = validateParameter(valid_602252, JBool, required = false, default = nil)
  if valid_602252 != nil:
    section.add "MultiAZ", valid_602252
  var valid_602253 = formData.getOrDefault("MasterUsername")
  valid_602253 = validateParameter(valid_602253, JString, required = true,
                                 default = nil)
  if valid_602253 != nil:
    section.add "MasterUsername", valid_602253
  var valid_602254 = formData.getOrDefault("DBParameterGroupName")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "DBParameterGroupName", valid_602254
  var valid_602255 = formData.getOrDefault("EngineVersion")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "EngineVersion", valid_602255
  var valid_602256 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_602256 = validateParameter(valid_602256, JArray, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "VpcSecurityGroupIds", valid_602256
  var valid_602257 = formData.getOrDefault("AvailabilityZone")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "AvailabilityZone", valid_602257
  var valid_602258 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602258 = validateParameter(valid_602258, JInt, required = false, default = nil)
  if valid_602258 != nil:
    section.add "BackupRetentionPeriod", valid_602258
  var valid_602259 = formData.getOrDefault("Engine")
  valid_602259 = validateParameter(valid_602259, JString, required = true,
                                 default = nil)
  if valid_602259 != nil:
    section.add "Engine", valid_602259
  var valid_602260 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602260 = validateParameter(valid_602260, JBool, required = false, default = nil)
  if valid_602260 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602260
  var valid_602261 = formData.getOrDefault("TdeCredentialPassword")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "TdeCredentialPassword", valid_602261
  var valid_602262 = formData.getOrDefault("DBName")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "DBName", valid_602262
  var valid_602263 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602263 = validateParameter(valid_602263, JString, required = true,
                                 default = nil)
  if valid_602263 != nil:
    section.add "DBInstanceIdentifier", valid_602263
  var valid_602264 = formData.getOrDefault("Iops")
  valid_602264 = validateParameter(valid_602264, JInt, required = false, default = nil)
  if valid_602264 != nil:
    section.add "Iops", valid_602264
  var valid_602265 = formData.getOrDefault("TdeCredentialArn")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "TdeCredentialArn", valid_602265
  var valid_602266 = formData.getOrDefault("PubliclyAccessible")
  valid_602266 = validateParameter(valid_602266, JBool, required = false, default = nil)
  if valid_602266 != nil:
    section.add "PubliclyAccessible", valid_602266
  var valid_602267 = formData.getOrDefault("LicenseModel")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "LicenseModel", valid_602267
  var valid_602268 = formData.getOrDefault("Tags")
  valid_602268 = validateParameter(valid_602268, JArray, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "Tags", valid_602268
  var valid_602269 = formData.getOrDefault("DBSubnetGroupName")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "DBSubnetGroupName", valid_602269
  var valid_602270 = formData.getOrDefault("OptionGroupName")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "OptionGroupName", valid_602270
  var valid_602271 = formData.getOrDefault("CharacterSetName")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "CharacterSetName", valid_602271
  var valid_602272 = formData.getOrDefault("DBSecurityGroups")
  valid_602272 = validateParameter(valid_602272, JArray, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "DBSecurityGroups", valid_602272
  var valid_602273 = formData.getOrDefault("StorageType")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "StorageType", valid_602273
  var valid_602274 = formData.getOrDefault("AllocatedStorage")
  valid_602274 = validateParameter(valid_602274, JInt, required = true, default = nil)
  if valid_602274 != nil:
    section.add "AllocatedStorage", valid_602274
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602275: Call_PostCreateDBInstance_602235; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602275.validator(path, query, header, formData, body)
  let scheme = call_602275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602275.url(scheme.get, call_602275.host, call_602275.base,
                         call_602275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602275, url, valid)

proc call*(call_602276: Call_PostCreateDBInstance_602235; DBInstanceClass: string;
          MasterUserPassword: string; MasterUsername: string; Engine: string;
          DBInstanceIdentifier: string; AllocatedStorage: int;
          PreferredMaintenanceWindow: string = ""; Port: int = 0;
          PreferredBackupWindow: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZone: string = "";
          BackupRetentionPeriod: int = 0; AutoMinorVersionUpgrade: bool = false;
          TdeCredentialPassword: string = ""; DBName: string = ""; Iops: int = 0;
          TdeCredentialArn: string = ""; PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstance"; LicenseModel: string = "";
          Tags: JsonNode = nil; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; CharacterSetName: string = "";
          Version: string = "2014-09-01"; DBSecurityGroups: JsonNode = nil;
          StorageType: string = ""): Recallable =
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
  ##   TdeCredentialPassword: string
  ##   DBName: string
  ##   DBInstanceIdentifier: string (required)
  ##   Iops: int
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   CharacterSetName: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   StorageType: string
  ##   AllocatedStorage: int (required)
  var query_602277 = newJObject()
  var formData_602278 = newJObject()
  add(formData_602278, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_602278, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602278, "Port", newJInt(Port))
  add(formData_602278, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_602278, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_602278, "MultiAZ", newJBool(MultiAZ))
  add(formData_602278, "MasterUsername", newJString(MasterUsername))
  add(formData_602278, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602278, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_602278.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_602278, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_602278, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_602278, "Engine", newJString(Engine))
  add(formData_602278, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_602278, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_602278, "DBName", newJString(DBName))
  add(formData_602278, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602278, "Iops", newJInt(Iops))
  add(formData_602278, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_602278, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602277, "Action", newJString(Action))
  add(formData_602278, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_602278.add "Tags", Tags
  add(formData_602278, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602278, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602278, "CharacterSetName", newJString(CharacterSetName))
  add(query_602277, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_602278.add "DBSecurityGroups", DBSecurityGroups
  add(formData_602278, "StorageType", newJString(StorageType))
  add(formData_602278, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_602276.call(nil, query_602277, nil, formData_602278, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_602235(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_602236, base: "/",
    url: url_PostCreateDBInstance_602237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_602192 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBInstance_602194(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBInstance_602193(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   DBName: JString
  ##   TdeCredentialPassword: JString
  ##   Engine: JString (required)
  ##   DBParameterGroupName: JString
  ##   CharacterSetName: JString
  ##   Tags: JArray
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   TdeCredentialArn: JString
  ##   MasterUsername: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   StorageType: JString
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
  var valid_602195 = query.getOrDefault("Version")
  valid_602195 = validateParameter(valid_602195, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602195 != nil:
    section.add "Version", valid_602195
  var valid_602196 = query.getOrDefault("DBName")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "DBName", valid_602196
  var valid_602197 = query.getOrDefault("TdeCredentialPassword")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "TdeCredentialPassword", valid_602197
  var valid_602198 = query.getOrDefault("Engine")
  valid_602198 = validateParameter(valid_602198, JString, required = true,
                                 default = nil)
  if valid_602198 != nil:
    section.add "Engine", valid_602198
  var valid_602199 = query.getOrDefault("DBParameterGroupName")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "DBParameterGroupName", valid_602199
  var valid_602200 = query.getOrDefault("CharacterSetName")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "CharacterSetName", valid_602200
  var valid_602201 = query.getOrDefault("Tags")
  valid_602201 = validateParameter(valid_602201, JArray, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "Tags", valid_602201
  var valid_602202 = query.getOrDefault("LicenseModel")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "LicenseModel", valid_602202
  var valid_602203 = query.getOrDefault("DBInstanceIdentifier")
  valid_602203 = validateParameter(valid_602203, JString, required = true,
                                 default = nil)
  if valid_602203 != nil:
    section.add "DBInstanceIdentifier", valid_602203
  var valid_602204 = query.getOrDefault("TdeCredentialArn")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "TdeCredentialArn", valid_602204
  var valid_602205 = query.getOrDefault("MasterUsername")
  valid_602205 = validateParameter(valid_602205, JString, required = true,
                                 default = nil)
  if valid_602205 != nil:
    section.add "MasterUsername", valid_602205
  var valid_602206 = query.getOrDefault("BackupRetentionPeriod")
  valid_602206 = validateParameter(valid_602206, JInt, required = false, default = nil)
  if valid_602206 != nil:
    section.add "BackupRetentionPeriod", valid_602206
  var valid_602207 = query.getOrDefault("StorageType")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "StorageType", valid_602207
  var valid_602208 = query.getOrDefault("EngineVersion")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "EngineVersion", valid_602208
  var valid_602209 = query.getOrDefault("Action")
  valid_602209 = validateParameter(valid_602209, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_602209 != nil:
    section.add "Action", valid_602209
  var valid_602210 = query.getOrDefault("MultiAZ")
  valid_602210 = validateParameter(valid_602210, JBool, required = false, default = nil)
  if valid_602210 != nil:
    section.add "MultiAZ", valid_602210
  var valid_602211 = query.getOrDefault("DBSecurityGroups")
  valid_602211 = validateParameter(valid_602211, JArray, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "DBSecurityGroups", valid_602211
  var valid_602212 = query.getOrDefault("Port")
  valid_602212 = validateParameter(valid_602212, JInt, required = false, default = nil)
  if valid_602212 != nil:
    section.add "Port", valid_602212
  var valid_602213 = query.getOrDefault("VpcSecurityGroupIds")
  valid_602213 = validateParameter(valid_602213, JArray, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "VpcSecurityGroupIds", valid_602213
  var valid_602214 = query.getOrDefault("MasterUserPassword")
  valid_602214 = validateParameter(valid_602214, JString, required = true,
                                 default = nil)
  if valid_602214 != nil:
    section.add "MasterUserPassword", valid_602214
  var valid_602215 = query.getOrDefault("AvailabilityZone")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "AvailabilityZone", valid_602215
  var valid_602216 = query.getOrDefault("OptionGroupName")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "OptionGroupName", valid_602216
  var valid_602217 = query.getOrDefault("DBSubnetGroupName")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "DBSubnetGroupName", valid_602217
  var valid_602218 = query.getOrDefault("AllocatedStorage")
  valid_602218 = validateParameter(valid_602218, JInt, required = true, default = nil)
  if valid_602218 != nil:
    section.add "AllocatedStorage", valid_602218
  var valid_602219 = query.getOrDefault("DBInstanceClass")
  valid_602219 = validateParameter(valid_602219, JString, required = true,
                                 default = nil)
  if valid_602219 != nil:
    section.add "DBInstanceClass", valid_602219
  var valid_602220 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "PreferredMaintenanceWindow", valid_602220
  var valid_602221 = query.getOrDefault("PreferredBackupWindow")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "PreferredBackupWindow", valid_602221
  var valid_602222 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602222 = validateParameter(valid_602222, JBool, required = false, default = nil)
  if valid_602222 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602222
  var valid_602223 = query.getOrDefault("Iops")
  valid_602223 = validateParameter(valid_602223, JInt, required = false, default = nil)
  if valid_602223 != nil:
    section.add "Iops", valid_602223
  var valid_602224 = query.getOrDefault("PubliclyAccessible")
  valid_602224 = validateParameter(valid_602224, JBool, required = false, default = nil)
  if valid_602224 != nil:
    section.add "PubliclyAccessible", valid_602224
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602225 = header.getOrDefault("X-Amz-Signature")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Signature", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Content-Sha256", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Date")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Date", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Credential")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Credential", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Security-Token")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Security-Token", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Algorithm")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Algorithm", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-SignedHeaders", valid_602231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602232: Call_GetCreateDBInstance_602192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602232.validator(path, query, header, formData, body)
  let scheme = call_602232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602232.url(scheme.get, call_602232.host, call_602232.base,
                         call_602232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602232, url, valid)

proc call*(call_602233: Call_GetCreateDBInstance_602192; Engine: string;
          DBInstanceIdentifier: string; MasterUsername: string;
          MasterUserPassword: string; AllocatedStorage: int;
          DBInstanceClass: string; Version: string = "2014-09-01";
          DBName: string = ""; TdeCredentialPassword: string = "";
          DBParameterGroupName: string = ""; CharacterSetName: string = "";
          Tags: JsonNode = nil; LicenseModel: string = "";
          TdeCredentialArn: string = ""; BackupRetentionPeriod: int = 0;
          StorageType: string = ""; EngineVersion: string = "";
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
  ##   TdeCredentialPassword: string
  ##   Engine: string (required)
  ##   DBParameterGroupName: string
  ##   CharacterSetName: string
  ##   Tags: JArray
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   TdeCredentialArn: string
  ##   MasterUsername: string (required)
  ##   BackupRetentionPeriod: int
  ##   StorageType: string
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
  var query_602234 = newJObject()
  add(query_602234, "Version", newJString(Version))
  add(query_602234, "DBName", newJString(DBName))
  add(query_602234, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_602234, "Engine", newJString(Engine))
  add(query_602234, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602234, "CharacterSetName", newJString(CharacterSetName))
  if Tags != nil:
    query_602234.add "Tags", Tags
  add(query_602234, "LicenseModel", newJString(LicenseModel))
  add(query_602234, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602234, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_602234, "MasterUsername", newJString(MasterUsername))
  add(query_602234, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602234, "StorageType", newJString(StorageType))
  add(query_602234, "EngineVersion", newJString(EngineVersion))
  add(query_602234, "Action", newJString(Action))
  add(query_602234, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_602234.add "DBSecurityGroups", DBSecurityGroups
  add(query_602234, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_602234.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_602234, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_602234, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_602234, "OptionGroupName", newJString(OptionGroupName))
  add(query_602234, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602234, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_602234, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602234, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_602234, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602234, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602234, "Iops", newJInt(Iops))
  add(query_602234, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_602233.call(nil, query_602234, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_602192(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_602193, base: "/",
    url: url_GetCreateDBInstance_602194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_602306 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBInstanceReadReplica_602308(protocol: Scheme; host: string;
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

proc validate_PostCreateDBInstanceReadReplica_602307(path: JsonNode;
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
  var valid_602309 = query.getOrDefault("Action")
  valid_602309 = validateParameter(valid_602309, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_602309 != nil:
    section.add "Action", valid_602309
  var valid_602310 = query.getOrDefault("Version")
  valid_602310 = validateParameter(valid_602310, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602310 != nil:
    section.add "Version", valid_602310
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602311 = header.getOrDefault("X-Amz-Signature")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Signature", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Content-Sha256", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Date")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Date", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Credential")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Credential", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Security-Token")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Security-Token", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Algorithm")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Algorithm", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-SignedHeaders", valid_602317
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
  ##   StorageType: JString
  section = newJObject()
  var valid_602318 = formData.getOrDefault("Port")
  valid_602318 = validateParameter(valid_602318, JInt, required = false, default = nil)
  if valid_602318 != nil:
    section.add "Port", valid_602318
  var valid_602319 = formData.getOrDefault("DBInstanceClass")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "DBInstanceClass", valid_602319
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_602320 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_602320 = validateParameter(valid_602320, JString, required = true,
                                 default = nil)
  if valid_602320 != nil:
    section.add "SourceDBInstanceIdentifier", valid_602320
  var valid_602321 = formData.getOrDefault("AvailabilityZone")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "AvailabilityZone", valid_602321
  var valid_602322 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602322 = validateParameter(valid_602322, JBool, required = false, default = nil)
  if valid_602322 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602322
  var valid_602323 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602323 = validateParameter(valid_602323, JString, required = true,
                                 default = nil)
  if valid_602323 != nil:
    section.add "DBInstanceIdentifier", valid_602323
  var valid_602324 = formData.getOrDefault("Iops")
  valid_602324 = validateParameter(valid_602324, JInt, required = false, default = nil)
  if valid_602324 != nil:
    section.add "Iops", valid_602324
  var valid_602325 = formData.getOrDefault("PubliclyAccessible")
  valid_602325 = validateParameter(valid_602325, JBool, required = false, default = nil)
  if valid_602325 != nil:
    section.add "PubliclyAccessible", valid_602325
  var valid_602326 = formData.getOrDefault("Tags")
  valid_602326 = validateParameter(valid_602326, JArray, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "Tags", valid_602326
  var valid_602327 = formData.getOrDefault("DBSubnetGroupName")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "DBSubnetGroupName", valid_602327
  var valid_602328 = formData.getOrDefault("OptionGroupName")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "OptionGroupName", valid_602328
  var valid_602329 = formData.getOrDefault("StorageType")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "StorageType", valid_602329
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602330: Call_PostCreateDBInstanceReadReplica_602306;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602330.validator(path, query, header, formData, body)
  let scheme = call_602330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602330.url(scheme.get, call_602330.host, call_602330.base,
                         call_602330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602330, url, valid)

proc call*(call_602331: Call_PostCreateDBInstanceReadReplica_602306;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; AvailabilityZone: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstanceReadReplica"; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          Version: string = "2014-09-01"; StorageType: string = ""): Recallable =
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
  ##   StorageType: string
  var query_602332 = newJObject()
  var formData_602333 = newJObject()
  add(formData_602333, "Port", newJInt(Port))
  add(formData_602333, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602333, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_602333, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_602333, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_602333, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602333, "Iops", newJInt(Iops))
  add(formData_602333, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602332, "Action", newJString(Action))
  if Tags != nil:
    formData_602333.add "Tags", Tags
  add(formData_602333, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602333, "OptionGroupName", newJString(OptionGroupName))
  add(query_602332, "Version", newJString(Version))
  add(formData_602333, "StorageType", newJString(StorageType))
  result = call_602331.call(nil, query_602332, nil, formData_602333, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_602306(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_602307, base: "/",
    url: url_PostCreateDBInstanceReadReplica_602308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_602279 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBInstanceReadReplica_602281(protocol: Scheme; host: string;
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

proc validate_GetCreateDBInstanceReadReplica_602280(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   DBInstanceIdentifier: JString (required)
  ##   StorageType: JString
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
  var valid_602282 = query.getOrDefault("Tags")
  valid_602282 = validateParameter(valid_602282, JArray, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "Tags", valid_602282
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602283 = query.getOrDefault("DBInstanceIdentifier")
  valid_602283 = validateParameter(valid_602283, JString, required = true,
                                 default = nil)
  if valid_602283 != nil:
    section.add "DBInstanceIdentifier", valid_602283
  var valid_602284 = query.getOrDefault("StorageType")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "StorageType", valid_602284
  var valid_602285 = query.getOrDefault("Action")
  valid_602285 = validateParameter(valid_602285, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_602285 != nil:
    section.add "Action", valid_602285
  var valid_602286 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_602286 = validateParameter(valid_602286, JString, required = true,
                                 default = nil)
  if valid_602286 != nil:
    section.add "SourceDBInstanceIdentifier", valid_602286
  var valid_602287 = query.getOrDefault("Port")
  valid_602287 = validateParameter(valid_602287, JInt, required = false, default = nil)
  if valid_602287 != nil:
    section.add "Port", valid_602287
  var valid_602288 = query.getOrDefault("AvailabilityZone")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "AvailabilityZone", valid_602288
  var valid_602289 = query.getOrDefault("OptionGroupName")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "OptionGroupName", valid_602289
  var valid_602290 = query.getOrDefault("DBSubnetGroupName")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "DBSubnetGroupName", valid_602290
  var valid_602291 = query.getOrDefault("Version")
  valid_602291 = validateParameter(valid_602291, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602291 != nil:
    section.add "Version", valid_602291
  var valid_602292 = query.getOrDefault("DBInstanceClass")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "DBInstanceClass", valid_602292
  var valid_602293 = query.getOrDefault("PubliclyAccessible")
  valid_602293 = validateParameter(valid_602293, JBool, required = false, default = nil)
  if valid_602293 != nil:
    section.add "PubliclyAccessible", valid_602293
  var valid_602294 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602294 = validateParameter(valid_602294, JBool, required = false, default = nil)
  if valid_602294 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602294
  var valid_602295 = query.getOrDefault("Iops")
  valid_602295 = validateParameter(valid_602295, JInt, required = false, default = nil)
  if valid_602295 != nil:
    section.add "Iops", valid_602295
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602296 = header.getOrDefault("X-Amz-Signature")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Signature", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Content-Sha256", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Date")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Date", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Credential")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Credential", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Security-Token")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Security-Token", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Algorithm")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Algorithm", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-SignedHeaders", valid_602302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602303: Call_GetCreateDBInstanceReadReplica_602279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602303.validator(path, query, header, formData, body)
  let scheme = call_602303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602303.url(scheme.get, call_602303.host, call_602303.base,
                         call_602303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602303, url, valid)

proc call*(call_602304: Call_GetCreateDBInstanceReadReplica_602279;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Tags: JsonNode = nil; StorageType: string = "";
          Action: string = "CreateDBInstanceReadReplica"; Port: int = 0;
          AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2014-09-01";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   StorageType: string
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
  var query_602305 = newJObject()
  if Tags != nil:
    query_602305.add "Tags", Tags
  add(query_602305, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602305, "StorageType", newJString(StorageType))
  add(query_602305, "Action", newJString(Action))
  add(query_602305, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_602305, "Port", newJInt(Port))
  add(query_602305, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_602305, "OptionGroupName", newJString(OptionGroupName))
  add(query_602305, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602305, "Version", newJString(Version))
  add(query_602305, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602305, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602305, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602305, "Iops", newJInt(Iops))
  result = call_602304.call(nil, query_602305, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_602279(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_602280, base: "/",
    url: url_GetCreateDBInstanceReadReplica_602281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_602353 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBParameterGroup_602355(protocol: Scheme; host: string;
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

proc validate_PostCreateDBParameterGroup_602354(path: JsonNode; query: JsonNode;
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
  var valid_602356 = query.getOrDefault("Action")
  valid_602356 = validateParameter(valid_602356, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_602356 != nil:
    section.add "Action", valid_602356
  var valid_602357 = query.getOrDefault("Version")
  valid_602357 = validateParameter(valid_602357, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602357 != nil:
    section.add "Version", valid_602357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602358 = header.getOrDefault("X-Amz-Signature")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Signature", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Content-Sha256", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Date")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Date", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Credential")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Credential", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Security-Token")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Security-Token", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Algorithm")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Algorithm", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-SignedHeaders", valid_602364
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_602365 = formData.getOrDefault("Description")
  valid_602365 = validateParameter(valid_602365, JString, required = true,
                                 default = nil)
  if valid_602365 != nil:
    section.add "Description", valid_602365
  var valid_602366 = formData.getOrDefault("DBParameterGroupName")
  valid_602366 = validateParameter(valid_602366, JString, required = true,
                                 default = nil)
  if valid_602366 != nil:
    section.add "DBParameterGroupName", valid_602366
  var valid_602367 = formData.getOrDefault("Tags")
  valid_602367 = validateParameter(valid_602367, JArray, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "Tags", valid_602367
  var valid_602368 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602368 = validateParameter(valid_602368, JString, required = true,
                                 default = nil)
  if valid_602368 != nil:
    section.add "DBParameterGroupFamily", valid_602368
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602369: Call_PostCreateDBParameterGroup_602353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602369.validator(path, query, header, formData, body)
  let scheme = call_602369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602369.url(scheme.get, call_602369.host, call_602369.base,
                         call_602369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602369, url, valid)

proc call*(call_602370: Call_PostCreateDBParameterGroup_602353;
          Description: string; DBParameterGroupName: string;
          DBParameterGroupFamily: string;
          Action: string = "CreateDBParameterGroup"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_602371 = newJObject()
  var formData_602372 = newJObject()
  add(formData_602372, "Description", newJString(Description))
  add(formData_602372, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602371, "Action", newJString(Action))
  if Tags != nil:
    formData_602372.add "Tags", Tags
  add(query_602371, "Version", newJString(Version))
  add(formData_602372, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_602370.call(nil, query_602371, nil, formData_602372, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_602353(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_602354, base: "/",
    url: url_PostCreateDBParameterGroup_602355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_602334 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBParameterGroup_602336(protocol: Scheme; host: string;
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

proc validate_GetCreateDBParameterGroup_602335(path: JsonNode; query: JsonNode;
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
  var valid_602337 = query.getOrDefault("DBParameterGroupFamily")
  valid_602337 = validateParameter(valid_602337, JString, required = true,
                                 default = nil)
  if valid_602337 != nil:
    section.add "DBParameterGroupFamily", valid_602337
  var valid_602338 = query.getOrDefault("DBParameterGroupName")
  valid_602338 = validateParameter(valid_602338, JString, required = true,
                                 default = nil)
  if valid_602338 != nil:
    section.add "DBParameterGroupName", valid_602338
  var valid_602339 = query.getOrDefault("Tags")
  valid_602339 = validateParameter(valid_602339, JArray, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "Tags", valid_602339
  var valid_602340 = query.getOrDefault("Action")
  valid_602340 = validateParameter(valid_602340, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_602340 != nil:
    section.add "Action", valid_602340
  var valid_602341 = query.getOrDefault("Description")
  valid_602341 = validateParameter(valid_602341, JString, required = true,
                                 default = nil)
  if valid_602341 != nil:
    section.add "Description", valid_602341
  var valid_602342 = query.getOrDefault("Version")
  valid_602342 = validateParameter(valid_602342, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602342 != nil:
    section.add "Version", valid_602342
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602343 = header.getOrDefault("X-Amz-Signature")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-Signature", valid_602343
  var valid_602344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Content-Sha256", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Date")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Date", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Credential")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Credential", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Security-Token")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Security-Token", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Algorithm")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Algorithm", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-SignedHeaders", valid_602349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602350: Call_GetCreateDBParameterGroup_602334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602350.validator(path, query, header, formData, body)
  let scheme = call_602350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602350.url(scheme.get, call_602350.host, call_602350.base,
                         call_602350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602350, url, valid)

proc call*(call_602351: Call_GetCreateDBParameterGroup_602334;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Description: string (required)
  ##   Version: string (required)
  var query_602352 = newJObject()
  add(query_602352, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_602352, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_602352.add "Tags", Tags
  add(query_602352, "Action", newJString(Action))
  add(query_602352, "Description", newJString(Description))
  add(query_602352, "Version", newJString(Version))
  result = call_602351.call(nil, query_602352, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_602334(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_602335, base: "/",
    url: url_GetCreateDBParameterGroup_602336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_602391 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBSecurityGroup_602393(protocol: Scheme; host: string;
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

proc validate_PostCreateDBSecurityGroup_602392(path: JsonNode; query: JsonNode;
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
  var valid_602394 = query.getOrDefault("Action")
  valid_602394 = validateParameter(valid_602394, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_602394 != nil:
    section.add "Action", valid_602394
  var valid_602395 = query.getOrDefault("Version")
  valid_602395 = validateParameter(valid_602395, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602395 != nil:
    section.add "Version", valid_602395
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602396 = header.getOrDefault("X-Amz-Signature")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Signature", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Content-Sha256", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Date")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Date", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Credential")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Credential", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Security-Token")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Security-Token", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Algorithm")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Algorithm", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-SignedHeaders", valid_602402
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_602403 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_602403 = validateParameter(valid_602403, JString, required = true,
                                 default = nil)
  if valid_602403 != nil:
    section.add "DBSecurityGroupDescription", valid_602403
  var valid_602404 = formData.getOrDefault("DBSecurityGroupName")
  valid_602404 = validateParameter(valid_602404, JString, required = true,
                                 default = nil)
  if valid_602404 != nil:
    section.add "DBSecurityGroupName", valid_602404
  var valid_602405 = formData.getOrDefault("Tags")
  valid_602405 = validateParameter(valid_602405, JArray, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "Tags", valid_602405
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602406: Call_PostCreateDBSecurityGroup_602391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602406.validator(path, query, header, formData, body)
  let scheme = call_602406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602406.url(scheme.get, call_602406.host, call_602406.base,
                         call_602406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602406, url, valid)

proc call*(call_602407: Call_PostCreateDBSecurityGroup_602391;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_602408 = newJObject()
  var formData_602409 = newJObject()
  add(formData_602409, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_602409, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602408, "Action", newJString(Action))
  if Tags != nil:
    formData_602409.add "Tags", Tags
  add(query_602408, "Version", newJString(Version))
  result = call_602407.call(nil, query_602408, nil, formData_602409, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_602391(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_602392, base: "/",
    url: url_PostCreateDBSecurityGroup_602393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_602373 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBSecurityGroup_602375(protocol: Scheme; host: string;
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

proc validate_GetCreateDBSecurityGroup_602374(path: JsonNode; query: JsonNode;
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
  var valid_602376 = query.getOrDefault("DBSecurityGroupName")
  valid_602376 = validateParameter(valid_602376, JString, required = true,
                                 default = nil)
  if valid_602376 != nil:
    section.add "DBSecurityGroupName", valid_602376
  var valid_602377 = query.getOrDefault("Tags")
  valid_602377 = validateParameter(valid_602377, JArray, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "Tags", valid_602377
  var valid_602378 = query.getOrDefault("DBSecurityGroupDescription")
  valid_602378 = validateParameter(valid_602378, JString, required = true,
                                 default = nil)
  if valid_602378 != nil:
    section.add "DBSecurityGroupDescription", valid_602378
  var valid_602379 = query.getOrDefault("Action")
  valid_602379 = validateParameter(valid_602379, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_602379 != nil:
    section.add "Action", valid_602379
  var valid_602380 = query.getOrDefault("Version")
  valid_602380 = validateParameter(valid_602380, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602380 != nil:
    section.add "Version", valid_602380
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602381 = header.getOrDefault("X-Amz-Signature")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Signature", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Content-Sha256", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Date")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Date", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Credential")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Credential", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Security-Token")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Security-Token", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Algorithm")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Algorithm", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-SignedHeaders", valid_602387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602388: Call_GetCreateDBSecurityGroup_602373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602388.validator(path, query, header, formData, body)
  let scheme = call_602388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602388.url(scheme.get, call_602388.host, call_602388.base,
                         call_602388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602388, url, valid)

proc call*(call_602389: Call_GetCreateDBSecurityGroup_602373;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602390 = newJObject()
  add(query_602390, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    query_602390.add "Tags", Tags
  add(query_602390, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_602390, "Action", newJString(Action))
  add(query_602390, "Version", newJString(Version))
  result = call_602389.call(nil, query_602390, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_602373(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_602374, base: "/",
    url: url_GetCreateDBSecurityGroup_602375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_602428 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBSnapshot_602430(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSnapshot_602429(path: JsonNode; query: JsonNode;
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
  var valid_602431 = query.getOrDefault("Action")
  valid_602431 = validateParameter(valid_602431, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_602431 != nil:
    section.add "Action", valid_602431
  var valid_602432 = query.getOrDefault("Version")
  valid_602432 = validateParameter(valid_602432, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602432 != nil:
    section.add "Version", valid_602432
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602433 = header.getOrDefault("X-Amz-Signature")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-Signature", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Content-Sha256", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Date")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Date", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Credential")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Credential", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Security-Token")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Security-Token", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-Algorithm")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Algorithm", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-SignedHeaders", valid_602439
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602440 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602440 = validateParameter(valid_602440, JString, required = true,
                                 default = nil)
  if valid_602440 != nil:
    section.add "DBInstanceIdentifier", valid_602440
  var valid_602441 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602441 = validateParameter(valid_602441, JString, required = true,
                                 default = nil)
  if valid_602441 != nil:
    section.add "DBSnapshotIdentifier", valid_602441
  var valid_602442 = formData.getOrDefault("Tags")
  valid_602442 = validateParameter(valid_602442, JArray, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "Tags", valid_602442
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602443: Call_PostCreateDBSnapshot_602428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602443.validator(path, query, header, formData, body)
  let scheme = call_602443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602443.url(scheme.get, call_602443.host, call_602443.base,
                         call_602443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602443, url, valid)

proc call*(call_602444: Call_PostCreateDBSnapshot_602428;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_602445 = newJObject()
  var formData_602446 = newJObject()
  add(formData_602446, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602446, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602445, "Action", newJString(Action))
  if Tags != nil:
    formData_602446.add "Tags", Tags
  add(query_602445, "Version", newJString(Version))
  result = call_602444.call(nil, query_602445, nil, formData_602446, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_602428(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_602429, base: "/",
    url: url_PostCreateDBSnapshot_602430, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_602410 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBSnapshot_602412(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSnapshot_602411(path: JsonNode; query: JsonNode;
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
  var valid_602413 = query.getOrDefault("Tags")
  valid_602413 = validateParameter(valid_602413, JArray, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "Tags", valid_602413
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602414 = query.getOrDefault("DBInstanceIdentifier")
  valid_602414 = validateParameter(valid_602414, JString, required = true,
                                 default = nil)
  if valid_602414 != nil:
    section.add "DBInstanceIdentifier", valid_602414
  var valid_602415 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602415 = validateParameter(valid_602415, JString, required = true,
                                 default = nil)
  if valid_602415 != nil:
    section.add "DBSnapshotIdentifier", valid_602415
  var valid_602416 = query.getOrDefault("Action")
  valid_602416 = validateParameter(valid_602416, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_602416 != nil:
    section.add "Action", valid_602416
  var valid_602417 = query.getOrDefault("Version")
  valid_602417 = validateParameter(valid_602417, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602417 != nil:
    section.add "Version", valid_602417
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602418 = header.getOrDefault("X-Amz-Signature")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Signature", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-Content-Sha256", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Date")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Date", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Credential")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Credential", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-Security-Token")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-Security-Token", valid_602422
  var valid_602423 = header.getOrDefault("X-Amz-Algorithm")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Algorithm", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-SignedHeaders", valid_602424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602425: Call_GetCreateDBSnapshot_602410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602425.validator(path, query, header, formData, body)
  let scheme = call_602425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602425.url(scheme.get, call_602425.host, call_602425.base,
                         call_602425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602425, url, valid)

proc call*(call_602426: Call_GetCreateDBSnapshot_602410;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602427 = newJObject()
  if Tags != nil:
    query_602427.add "Tags", Tags
  add(query_602427, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602427, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602427, "Action", newJString(Action))
  add(query_602427, "Version", newJString(Version))
  result = call_602426.call(nil, query_602427, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_602410(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_602411, base: "/",
    url: url_GetCreateDBSnapshot_602412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_602466 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBSubnetGroup_602468(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSubnetGroup_602467(path: JsonNode; query: JsonNode;
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
  var valid_602469 = query.getOrDefault("Action")
  valid_602469 = validateParameter(valid_602469, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_602469 != nil:
    section.add "Action", valid_602469
  var valid_602470 = query.getOrDefault("Version")
  valid_602470 = validateParameter(valid_602470, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602470 != nil:
    section.add "Version", valid_602470
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602471 = header.getOrDefault("X-Amz-Signature")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Signature", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-Content-Sha256", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Date")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Date", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-Credential")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Credential", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Security-Token")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Security-Token", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Algorithm")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Algorithm", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-SignedHeaders", valid_602477
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_602478 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_602478 = validateParameter(valid_602478, JString, required = true,
                                 default = nil)
  if valid_602478 != nil:
    section.add "DBSubnetGroupDescription", valid_602478
  var valid_602479 = formData.getOrDefault("Tags")
  valid_602479 = validateParameter(valid_602479, JArray, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "Tags", valid_602479
  var valid_602480 = formData.getOrDefault("DBSubnetGroupName")
  valid_602480 = validateParameter(valid_602480, JString, required = true,
                                 default = nil)
  if valid_602480 != nil:
    section.add "DBSubnetGroupName", valid_602480
  var valid_602481 = formData.getOrDefault("SubnetIds")
  valid_602481 = validateParameter(valid_602481, JArray, required = true, default = nil)
  if valid_602481 != nil:
    section.add "SubnetIds", valid_602481
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602482: Call_PostCreateDBSubnetGroup_602466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602482.validator(path, query, header, formData, body)
  let scheme = call_602482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602482.url(scheme.get, call_602482.host, call_602482.base,
                         call_602482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602482, url, valid)

proc call*(call_602483: Call_PostCreateDBSubnetGroup_602466;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          SubnetIds: JsonNode; Action: string = "CreateDBSubnetGroup";
          Tags: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_602484 = newJObject()
  var formData_602485 = newJObject()
  add(formData_602485, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602484, "Action", newJString(Action))
  if Tags != nil:
    formData_602485.add "Tags", Tags
  add(formData_602485, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602484, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_602485.add "SubnetIds", SubnetIds
  result = call_602483.call(nil, query_602484, nil, formData_602485, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_602466(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_602467, base: "/",
    url: url_PostCreateDBSubnetGroup_602468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_602447 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBSubnetGroup_602449(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSubnetGroup_602448(path: JsonNode; query: JsonNode;
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
  var valid_602450 = query.getOrDefault("Tags")
  valid_602450 = validateParameter(valid_602450, JArray, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "Tags", valid_602450
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_602451 = query.getOrDefault("SubnetIds")
  valid_602451 = validateParameter(valid_602451, JArray, required = true, default = nil)
  if valid_602451 != nil:
    section.add "SubnetIds", valid_602451
  var valid_602452 = query.getOrDefault("Action")
  valid_602452 = validateParameter(valid_602452, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_602452 != nil:
    section.add "Action", valid_602452
  var valid_602453 = query.getOrDefault("DBSubnetGroupDescription")
  valid_602453 = validateParameter(valid_602453, JString, required = true,
                                 default = nil)
  if valid_602453 != nil:
    section.add "DBSubnetGroupDescription", valid_602453
  var valid_602454 = query.getOrDefault("DBSubnetGroupName")
  valid_602454 = validateParameter(valid_602454, JString, required = true,
                                 default = nil)
  if valid_602454 != nil:
    section.add "DBSubnetGroupName", valid_602454
  var valid_602455 = query.getOrDefault("Version")
  valid_602455 = validateParameter(valid_602455, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602455 != nil:
    section.add "Version", valid_602455
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602456 = header.getOrDefault("X-Amz-Signature")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Signature", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Content-Sha256", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Date")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Date", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-Credential")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Credential", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Security-Token")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Security-Token", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Algorithm")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Algorithm", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-SignedHeaders", valid_602462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602463: Call_GetCreateDBSubnetGroup_602447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602463.validator(path, query, header, formData, body)
  let scheme = call_602463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602463.url(scheme.get, call_602463.host, call_602463.base,
                         call_602463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602463, url, valid)

proc call*(call_602464: Call_GetCreateDBSubnetGroup_602447; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Tags: JArray
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_602465 = newJObject()
  if Tags != nil:
    query_602465.add "Tags", Tags
  if SubnetIds != nil:
    query_602465.add "SubnetIds", SubnetIds
  add(query_602465, "Action", newJString(Action))
  add(query_602465, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602465, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602465, "Version", newJString(Version))
  result = call_602464.call(nil, query_602465, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_602447(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_602448, base: "/",
    url: url_GetCreateDBSubnetGroup_602449, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_602508 = ref object of OpenApiRestCall_601373
proc url_PostCreateEventSubscription_602510(protocol: Scheme; host: string;
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

proc validate_PostCreateEventSubscription_602509(path: JsonNode; query: JsonNode;
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
  var valid_602511 = query.getOrDefault("Action")
  valid_602511 = validateParameter(valid_602511, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_602511 != nil:
    section.add "Action", valid_602511
  var valid_602512 = query.getOrDefault("Version")
  valid_602512 = validateParameter(valid_602512, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602512 != nil:
    section.add "Version", valid_602512
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602513 = header.getOrDefault("X-Amz-Signature")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Signature", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-Content-Sha256", valid_602514
  var valid_602515 = header.getOrDefault("X-Amz-Date")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "X-Amz-Date", valid_602515
  var valid_602516 = header.getOrDefault("X-Amz-Credential")
  valid_602516 = validateParameter(valid_602516, JString, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "X-Amz-Credential", valid_602516
  var valid_602517 = header.getOrDefault("X-Amz-Security-Token")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "X-Amz-Security-Token", valid_602517
  var valid_602518 = header.getOrDefault("X-Amz-Algorithm")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "X-Amz-Algorithm", valid_602518
  var valid_602519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-SignedHeaders", valid_602519
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
  var valid_602520 = formData.getOrDefault("SourceIds")
  valid_602520 = validateParameter(valid_602520, JArray, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "SourceIds", valid_602520
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_602521 = formData.getOrDefault("SnsTopicArn")
  valid_602521 = validateParameter(valid_602521, JString, required = true,
                                 default = nil)
  if valid_602521 != nil:
    section.add "SnsTopicArn", valid_602521
  var valid_602522 = formData.getOrDefault("Enabled")
  valid_602522 = validateParameter(valid_602522, JBool, required = false, default = nil)
  if valid_602522 != nil:
    section.add "Enabled", valid_602522
  var valid_602523 = formData.getOrDefault("SubscriptionName")
  valid_602523 = validateParameter(valid_602523, JString, required = true,
                                 default = nil)
  if valid_602523 != nil:
    section.add "SubscriptionName", valid_602523
  var valid_602524 = formData.getOrDefault("SourceType")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "SourceType", valid_602524
  var valid_602525 = formData.getOrDefault("EventCategories")
  valid_602525 = validateParameter(valid_602525, JArray, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "EventCategories", valid_602525
  var valid_602526 = formData.getOrDefault("Tags")
  valid_602526 = validateParameter(valid_602526, JArray, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "Tags", valid_602526
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602527: Call_PostCreateEventSubscription_602508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602527.validator(path, query, header, formData, body)
  let scheme = call_602527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602527.url(scheme.get, call_602527.host, call_602527.base,
                         call_602527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602527, url, valid)

proc call*(call_602528: Call_PostCreateEventSubscription_602508;
          SnsTopicArn: string; SubscriptionName: string; SourceIds: JsonNode = nil;
          Enabled: bool = false; SourceType: string = "";
          EventCategories: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
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
  var query_602529 = newJObject()
  var formData_602530 = newJObject()
  if SourceIds != nil:
    formData_602530.add "SourceIds", SourceIds
  add(formData_602530, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_602530, "Enabled", newJBool(Enabled))
  add(formData_602530, "SubscriptionName", newJString(SubscriptionName))
  add(formData_602530, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_602530.add "EventCategories", EventCategories
  add(query_602529, "Action", newJString(Action))
  if Tags != nil:
    formData_602530.add "Tags", Tags
  add(query_602529, "Version", newJString(Version))
  result = call_602528.call(nil, query_602529, nil, formData_602530, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_602508(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_602509, base: "/",
    url: url_PostCreateEventSubscription_602510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_602486 = ref object of OpenApiRestCall_601373
proc url_GetCreateEventSubscription_602488(protocol: Scheme; host: string;
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

proc validate_GetCreateEventSubscription_602487(path: JsonNode; query: JsonNode;
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
  var valid_602489 = query.getOrDefault("Tags")
  valid_602489 = validateParameter(valid_602489, JArray, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "Tags", valid_602489
  var valid_602490 = query.getOrDefault("SourceType")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "SourceType", valid_602490
  var valid_602491 = query.getOrDefault("Enabled")
  valid_602491 = validateParameter(valid_602491, JBool, required = false, default = nil)
  if valid_602491 != nil:
    section.add "Enabled", valid_602491
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_602492 = query.getOrDefault("SubscriptionName")
  valid_602492 = validateParameter(valid_602492, JString, required = true,
                                 default = nil)
  if valid_602492 != nil:
    section.add "SubscriptionName", valid_602492
  var valid_602493 = query.getOrDefault("EventCategories")
  valid_602493 = validateParameter(valid_602493, JArray, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "EventCategories", valid_602493
  var valid_602494 = query.getOrDefault("SourceIds")
  valid_602494 = validateParameter(valid_602494, JArray, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "SourceIds", valid_602494
  var valid_602495 = query.getOrDefault("Action")
  valid_602495 = validateParameter(valid_602495, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_602495 != nil:
    section.add "Action", valid_602495
  var valid_602496 = query.getOrDefault("SnsTopicArn")
  valid_602496 = validateParameter(valid_602496, JString, required = true,
                                 default = nil)
  if valid_602496 != nil:
    section.add "SnsTopicArn", valid_602496
  var valid_602497 = query.getOrDefault("Version")
  valid_602497 = validateParameter(valid_602497, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602497 != nil:
    section.add "Version", valid_602497
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602498 = header.getOrDefault("X-Amz-Signature")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Signature", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Content-Sha256", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-Date")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Date", valid_602500
  var valid_602501 = header.getOrDefault("X-Amz-Credential")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-Credential", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-Security-Token")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-Security-Token", valid_602502
  var valid_602503 = header.getOrDefault("X-Amz-Algorithm")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Algorithm", valid_602503
  var valid_602504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-SignedHeaders", valid_602504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602505: Call_GetCreateEventSubscription_602486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602505.validator(path, query, header, formData, body)
  let scheme = call_602505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602505.url(scheme.get, call_602505.host, call_602505.base,
                         call_602505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602505, url, valid)

proc call*(call_602506: Call_GetCreateEventSubscription_602486;
          SubscriptionName: string; SnsTopicArn: string; Tags: JsonNode = nil;
          SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil; SourceIds: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Version: string = "2014-09-01"): Recallable =
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
  var query_602507 = newJObject()
  if Tags != nil:
    query_602507.add "Tags", Tags
  add(query_602507, "SourceType", newJString(SourceType))
  add(query_602507, "Enabled", newJBool(Enabled))
  add(query_602507, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_602507.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_602507.add "SourceIds", SourceIds
  add(query_602507, "Action", newJString(Action))
  add(query_602507, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_602507, "Version", newJString(Version))
  result = call_602506.call(nil, query_602507, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_602486(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_602487, base: "/",
    url: url_GetCreateEventSubscription_602488,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_602551 = ref object of OpenApiRestCall_601373
proc url_PostCreateOptionGroup_602553(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateOptionGroup_602552(path: JsonNode; query: JsonNode;
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
  var valid_602554 = query.getOrDefault("Action")
  valid_602554 = validateParameter(valid_602554, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_602554 != nil:
    section.add "Action", valid_602554
  var valid_602555 = query.getOrDefault("Version")
  valid_602555 = validateParameter(valid_602555, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602555 != nil:
    section.add "Version", valid_602555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602556 = header.getOrDefault("X-Amz-Signature")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Signature", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Content-Sha256", valid_602557
  var valid_602558 = header.getOrDefault("X-Amz-Date")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "X-Amz-Date", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Credential")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Credential", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-Security-Token")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Security-Token", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-Algorithm")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-Algorithm", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-SignedHeaders", valid_602562
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   Tags: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_602563 = formData.getOrDefault("OptionGroupDescription")
  valid_602563 = validateParameter(valid_602563, JString, required = true,
                                 default = nil)
  if valid_602563 != nil:
    section.add "OptionGroupDescription", valid_602563
  var valid_602564 = formData.getOrDefault("EngineName")
  valid_602564 = validateParameter(valid_602564, JString, required = true,
                                 default = nil)
  if valid_602564 != nil:
    section.add "EngineName", valid_602564
  var valid_602565 = formData.getOrDefault("MajorEngineVersion")
  valid_602565 = validateParameter(valid_602565, JString, required = true,
                                 default = nil)
  if valid_602565 != nil:
    section.add "MajorEngineVersion", valid_602565
  var valid_602566 = formData.getOrDefault("Tags")
  valid_602566 = validateParameter(valid_602566, JArray, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "Tags", valid_602566
  var valid_602567 = formData.getOrDefault("OptionGroupName")
  valid_602567 = validateParameter(valid_602567, JString, required = true,
                                 default = nil)
  if valid_602567 != nil:
    section.add "OptionGroupName", valid_602567
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602568: Call_PostCreateOptionGroup_602551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602568.validator(path, query, header, formData, body)
  let scheme = call_602568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602568.url(scheme.get, call_602568.host, call_602568.base,
                         call_602568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602568, url, valid)

proc call*(call_602569: Call_PostCreateOptionGroup_602551;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; OptionGroupName: string;
          Action: string = "CreateOptionGroup"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateOptionGroup
  ##   OptionGroupDescription: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_602570 = newJObject()
  var formData_602571 = newJObject()
  add(formData_602571, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_602571, "EngineName", newJString(EngineName))
  add(formData_602571, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_602570, "Action", newJString(Action))
  if Tags != nil:
    formData_602571.add "Tags", Tags
  add(formData_602571, "OptionGroupName", newJString(OptionGroupName))
  add(query_602570, "Version", newJString(Version))
  result = call_602569.call(nil, query_602570, nil, formData_602571, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_602551(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_602552, base: "/",
    url: url_PostCreateOptionGroup_602553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_602531 = ref object of OpenApiRestCall_601373
proc url_GetCreateOptionGroup_602533(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateOptionGroup_602532(path: JsonNode; query: JsonNode;
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
  var valid_602534 = query.getOrDefault("EngineName")
  valid_602534 = validateParameter(valid_602534, JString, required = true,
                                 default = nil)
  if valid_602534 != nil:
    section.add "EngineName", valid_602534
  var valid_602535 = query.getOrDefault("OptionGroupDescription")
  valid_602535 = validateParameter(valid_602535, JString, required = true,
                                 default = nil)
  if valid_602535 != nil:
    section.add "OptionGroupDescription", valid_602535
  var valid_602536 = query.getOrDefault("Tags")
  valid_602536 = validateParameter(valid_602536, JArray, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "Tags", valid_602536
  var valid_602537 = query.getOrDefault("Action")
  valid_602537 = validateParameter(valid_602537, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_602537 != nil:
    section.add "Action", valid_602537
  var valid_602538 = query.getOrDefault("OptionGroupName")
  valid_602538 = validateParameter(valid_602538, JString, required = true,
                                 default = nil)
  if valid_602538 != nil:
    section.add "OptionGroupName", valid_602538
  var valid_602539 = query.getOrDefault("Version")
  valid_602539 = validateParameter(valid_602539, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602539 != nil:
    section.add "Version", valid_602539
  var valid_602540 = query.getOrDefault("MajorEngineVersion")
  valid_602540 = validateParameter(valid_602540, JString, required = true,
                                 default = nil)
  if valid_602540 != nil:
    section.add "MajorEngineVersion", valid_602540
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602541 = header.getOrDefault("X-Amz-Signature")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Signature", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Content-Sha256", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-Date")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Date", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Credential")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Credential", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Security-Token")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Security-Token", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-Algorithm")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Algorithm", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-SignedHeaders", valid_602547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602548: Call_GetCreateOptionGroup_602531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602548.validator(path, query, header, formData, body)
  let scheme = call_602548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602548.url(scheme.get, call_602548.host, call_602548.base,
                         call_602548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602548, url, valid)

proc call*(call_602549: Call_GetCreateOptionGroup_602531; EngineName: string;
          OptionGroupDescription: string; OptionGroupName: string;
          MajorEngineVersion: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCreateOptionGroup
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   MajorEngineVersion: string (required)
  var query_602550 = newJObject()
  add(query_602550, "EngineName", newJString(EngineName))
  add(query_602550, "OptionGroupDescription", newJString(OptionGroupDescription))
  if Tags != nil:
    query_602550.add "Tags", Tags
  add(query_602550, "Action", newJString(Action))
  add(query_602550, "OptionGroupName", newJString(OptionGroupName))
  add(query_602550, "Version", newJString(Version))
  add(query_602550, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602549.call(nil, query_602550, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_602531(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_602532, base: "/",
    url: url_GetCreateOptionGroup_602533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_602590 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBInstance_602592(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBInstance_602591(path: JsonNode; query: JsonNode;
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
  var valid_602593 = query.getOrDefault("Action")
  valid_602593 = validateParameter(valid_602593, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_602593 != nil:
    section.add "Action", valid_602593
  var valid_602594 = query.getOrDefault("Version")
  valid_602594 = validateParameter(valid_602594, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602602 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602602 = validateParameter(valid_602602, JString, required = true,
                                 default = nil)
  if valid_602602 != nil:
    section.add "DBInstanceIdentifier", valid_602602
  var valid_602603 = formData.getOrDefault("SkipFinalSnapshot")
  valid_602603 = validateParameter(valid_602603, JBool, required = false, default = nil)
  if valid_602603 != nil:
    section.add "SkipFinalSnapshot", valid_602603
  var valid_602604 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_602604
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602605: Call_PostDeleteDBInstance_602590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602605.validator(path, query, header, formData, body)
  let scheme = call_602605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602605.url(scheme.get, call_602605.host, call_602605.base,
                         call_602605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602605, url, valid)

proc call*(call_602606: Call_PostDeleteDBInstance_602590;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_602607 = newJObject()
  var formData_602608 = newJObject()
  add(formData_602608, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602607, "Action", newJString(Action))
  add(formData_602608, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_602608, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_602607, "Version", newJString(Version))
  result = call_602606.call(nil, query_602607, nil, formData_602608, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_602590(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_602591, base: "/",
    url: url_PostDeleteDBInstance_602592, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_602572 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBInstance_602574(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBInstance_602573(path: JsonNode; query: JsonNode;
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
  var valid_602575 = query.getOrDefault("DBInstanceIdentifier")
  valid_602575 = validateParameter(valid_602575, JString, required = true,
                                 default = nil)
  if valid_602575 != nil:
    section.add "DBInstanceIdentifier", valid_602575
  var valid_602576 = query.getOrDefault("SkipFinalSnapshot")
  valid_602576 = validateParameter(valid_602576, JBool, required = false, default = nil)
  if valid_602576 != nil:
    section.add "SkipFinalSnapshot", valid_602576
  var valid_602577 = query.getOrDefault("Action")
  valid_602577 = validateParameter(valid_602577, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_602577 != nil:
    section.add "Action", valid_602577
  var valid_602578 = query.getOrDefault("Version")
  valid_602578 = validateParameter(valid_602578, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602578 != nil:
    section.add "Version", valid_602578
  var valid_602579 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_602579
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602580 = header.getOrDefault("X-Amz-Signature")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Signature", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Content-Sha256", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Date")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Date", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-Credential")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Credential", valid_602583
  var valid_602584 = header.getOrDefault("X-Amz-Security-Token")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-Security-Token", valid_602584
  var valid_602585 = header.getOrDefault("X-Amz-Algorithm")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-Algorithm", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-SignedHeaders", valid_602586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602587: Call_GetDeleteDBInstance_602572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602587.validator(path, query, header, formData, body)
  let scheme = call_602587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602587.url(scheme.get, call_602587.host, call_602587.base,
                         call_602587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602587, url, valid)

proc call*(call_602588: Call_GetDeleteDBInstance_602572;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2014-09-01";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_602589 = newJObject()
  add(query_602589, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602589, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_602589, "Action", newJString(Action))
  add(query_602589, "Version", newJString(Version))
  add(query_602589, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_602588.call(nil, query_602589, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_602572(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_602573, base: "/",
    url: url_GetDeleteDBInstance_602574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_602625 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBParameterGroup_602627(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBParameterGroup_602626(path: JsonNode; query: JsonNode;
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
  var valid_602628 = query.getOrDefault("Action")
  valid_602628 = validateParameter(valid_602628, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_602628 != nil:
    section.add "Action", valid_602628
  var valid_602629 = query.getOrDefault("Version")
  valid_602629 = validateParameter(valid_602629, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602629 != nil:
    section.add "Version", valid_602629
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602630 = header.getOrDefault("X-Amz-Signature")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Signature", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Content-Sha256", valid_602631
  var valid_602632 = header.getOrDefault("X-Amz-Date")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "X-Amz-Date", valid_602632
  var valid_602633 = header.getOrDefault("X-Amz-Credential")
  valid_602633 = validateParameter(valid_602633, JString, required = false,
                                 default = nil)
  if valid_602633 != nil:
    section.add "X-Amz-Credential", valid_602633
  var valid_602634 = header.getOrDefault("X-Amz-Security-Token")
  valid_602634 = validateParameter(valid_602634, JString, required = false,
                                 default = nil)
  if valid_602634 != nil:
    section.add "X-Amz-Security-Token", valid_602634
  var valid_602635 = header.getOrDefault("X-Amz-Algorithm")
  valid_602635 = validateParameter(valid_602635, JString, required = false,
                                 default = nil)
  if valid_602635 != nil:
    section.add "X-Amz-Algorithm", valid_602635
  var valid_602636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602636 = validateParameter(valid_602636, JString, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "X-Amz-SignedHeaders", valid_602636
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602637 = formData.getOrDefault("DBParameterGroupName")
  valid_602637 = validateParameter(valid_602637, JString, required = true,
                                 default = nil)
  if valid_602637 != nil:
    section.add "DBParameterGroupName", valid_602637
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602638: Call_PostDeleteDBParameterGroup_602625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602638.validator(path, query, header, formData, body)
  let scheme = call_602638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602638.url(scheme.get, call_602638.host, call_602638.base,
                         call_602638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602638, url, valid)

proc call*(call_602639: Call_PostDeleteDBParameterGroup_602625;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602640 = newJObject()
  var formData_602641 = newJObject()
  add(formData_602641, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602640, "Action", newJString(Action))
  add(query_602640, "Version", newJString(Version))
  result = call_602639.call(nil, query_602640, nil, formData_602641, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_602625(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_602626, base: "/",
    url: url_PostDeleteDBParameterGroup_602627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_602609 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBParameterGroup_602611(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBParameterGroup_602610(path: JsonNode; query: JsonNode;
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
  var valid_602612 = query.getOrDefault("DBParameterGroupName")
  valid_602612 = validateParameter(valid_602612, JString, required = true,
                                 default = nil)
  if valid_602612 != nil:
    section.add "DBParameterGroupName", valid_602612
  var valid_602613 = query.getOrDefault("Action")
  valid_602613 = validateParameter(valid_602613, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_602613 != nil:
    section.add "Action", valid_602613
  var valid_602614 = query.getOrDefault("Version")
  valid_602614 = validateParameter(valid_602614, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602614 != nil:
    section.add "Version", valid_602614
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602615 = header.getOrDefault("X-Amz-Signature")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-Signature", valid_602615
  var valid_602616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "X-Amz-Content-Sha256", valid_602616
  var valid_602617 = header.getOrDefault("X-Amz-Date")
  valid_602617 = validateParameter(valid_602617, JString, required = false,
                                 default = nil)
  if valid_602617 != nil:
    section.add "X-Amz-Date", valid_602617
  var valid_602618 = header.getOrDefault("X-Amz-Credential")
  valid_602618 = validateParameter(valid_602618, JString, required = false,
                                 default = nil)
  if valid_602618 != nil:
    section.add "X-Amz-Credential", valid_602618
  var valid_602619 = header.getOrDefault("X-Amz-Security-Token")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "X-Amz-Security-Token", valid_602619
  var valid_602620 = header.getOrDefault("X-Amz-Algorithm")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "X-Amz-Algorithm", valid_602620
  var valid_602621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "X-Amz-SignedHeaders", valid_602621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602622: Call_GetDeleteDBParameterGroup_602609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602622.validator(path, query, header, formData, body)
  let scheme = call_602622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602622.url(scheme.get, call_602622.host, call_602622.base,
                         call_602622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602622, url, valid)

proc call*(call_602623: Call_GetDeleteDBParameterGroup_602609;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602624 = newJObject()
  add(query_602624, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602624, "Action", newJString(Action))
  add(query_602624, "Version", newJString(Version))
  result = call_602623.call(nil, query_602624, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_602609(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_602610, base: "/",
    url: url_GetDeleteDBParameterGroup_602611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_602658 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBSecurityGroup_602660(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBSecurityGroup_602659(path: JsonNode; query: JsonNode;
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
  var valid_602661 = query.getOrDefault("Action")
  valid_602661 = validateParameter(valid_602661, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_602661 != nil:
    section.add "Action", valid_602661
  var valid_602662 = query.getOrDefault("Version")
  valid_602662 = validateParameter(valid_602662, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602662 != nil:
    section.add "Version", valid_602662
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602663 = header.getOrDefault("X-Amz-Signature")
  valid_602663 = validateParameter(valid_602663, JString, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "X-Amz-Signature", valid_602663
  var valid_602664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602664 = validateParameter(valid_602664, JString, required = false,
                                 default = nil)
  if valid_602664 != nil:
    section.add "X-Amz-Content-Sha256", valid_602664
  var valid_602665 = header.getOrDefault("X-Amz-Date")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "X-Amz-Date", valid_602665
  var valid_602666 = header.getOrDefault("X-Amz-Credential")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-Credential", valid_602666
  var valid_602667 = header.getOrDefault("X-Amz-Security-Token")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "X-Amz-Security-Token", valid_602667
  var valid_602668 = header.getOrDefault("X-Amz-Algorithm")
  valid_602668 = validateParameter(valid_602668, JString, required = false,
                                 default = nil)
  if valid_602668 != nil:
    section.add "X-Amz-Algorithm", valid_602668
  var valid_602669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602669 = validateParameter(valid_602669, JString, required = false,
                                 default = nil)
  if valid_602669 != nil:
    section.add "X-Amz-SignedHeaders", valid_602669
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602670 = formData.getOrDefault("DBSecurityGroupName")
  valid_602670 = validateParameter(valid_602670, JString, required = true,
                                 default = nil)
  if valid_602670 != nil:
    section.add "DBSecurityGroupName", valid_602670
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602671: Call_PostDeleteDBSecurityGroup_602658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602671.validator(path, query, header, formData, body)
  let scheme = call_602671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602671.url(scheme.get, call_602671.host, call_602671.base,
                         call_602671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602671, url, valid)

proc call*(call_602672: Call_PostDeleteDBSecurityGroup_602658;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602673 = newJObject()
  var formData_602674 = newJObject()
  add(formData_602674, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602673, "Action", newJString(Action))
  add(query_602673, "Version", newJString(Version))
  result = call_602672.call(nil, query_602673, nil, formData_602674, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_602658(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_602659, base: "/",
    url: url_PostDeleteDBSecurityGroup_602660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_602642 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBSecurityGroup_602644(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBSecurityGroup_602643(path: JsonNode; query: JsonNode;
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
  var valid_602645 = query.getOrDefault("DBSecurityGroupName")
  valid_602645 = validateParameter(valid_602645, JString, required = true,
                                 default = nil)
  if valid_602645 != nil:
    section.add "DBSecurityGroupName", valid_602645
  var valid_602646 = query.getOrDefault("Action")
  valid_602646 = validateParameter(valid_602646, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_602646 != nil:
    section.add "Action", valid_602646
  var valid_602647 = query.getOrDefault("Version")
  valid_602647 = validateParameter(valid_602647, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602647 != nil:
    section.add "Version", valid_602647
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602648 = header.getOrDefault("X-Amz-Signature")
  valid_602648 = validateParameter(valid_602648, JString, required = false,
                                 default = nil)
  if valid_602648 != nil:
    section.add "X-Amz-Signature", valid_602648
  var valid_602649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602649 = validateParameter(valid_602649, JString, required = false,
                                 default = nil)
  if valid_602649 != nil:
    section.add "X-Amz-Content-Sha256", valid_602649
  var valid_602650 = header.getOrDefault("X-Amz-Date")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "X-Amz-Date", valid_602650
  var valid_602651 = header.getOrDefault("X-Amz-Credential")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "X-Amz-Credential", valid_602651
  var valid_602652 = header.getOrDefault("X-Amz-Security-Token")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "X-Amz-Security-Token", valid_602652
  var valid_602653 = header.getOrDefault("X-Amz-Algorithm")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "X-Amz-Algorithm", valid_602653
  var valid_602654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "X-Amz-SignedHeaders", valid_602654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602655: Call_GetDeleteDBSecurityGroup_602642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602655.validator(path, query, header, formData, body)
  let scheme = call_602655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602655.url(scheme.get, call_602655.host, call_602655.base,
                         call_602655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602655, url, valid)

proc call*(call_602656: Call_GetDeleteDBSecurityGroup_602642;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602657 = newJObject()
  add(query_602657, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602657, "Action", newJString(Action))
  add(query_602657, "Version", newJString(Version))
  result = call_602656.call(nil, query_602657, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_602642(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_602643, base: "/",
    url: url_GetDeleteDBSecurityGroup_602644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_602691 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBSnapshot_602693(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSnapshot_602692(path: JsonNode; query: JsonNode;
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
  var valid_602694 = query.getOrDefault("Action")
  valid_602694 = validateParameter(valid_602694, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_602694 != nil:
    section.add "Action", valid_602694
  var valid_602695 = query.getOrDefault("Version")
  valid_602695 = validateParameter(valid_602695, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602695 != nil:
    section.add "Version", valid_602695
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602696 = header.getOrDefault("X-Amz-Signature")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-Signature", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-Content-Sha256", valid_602697
  var valid_602698 = header.getOrDefault("X-Amz-Date")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Date", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-Credential")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-Credential", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-Security-Token")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Security-Token", valid_602700
  var valid_602701 = header.getOrDefault("X-Amz-Algorithm")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "X-Amz-Algorithm", valid_602701
  var valid_602702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "X-Amz-SignedHeaders", valid_602702
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_602703 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602703 = validateParameter(valid_602703, JString, required = true,
                                 default = nil)
  if valid_602703 != nil:
    section.add "DBSnapshotIdentifier", valid_602703
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602704: Call_PostDeleteDBSnapshot_602691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602704.validator(path, query, header, formData, body)
  let scheme = call_602704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602704.url(scheme.get, call_602704.host, call_602704.base,
                         call_602704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602704, url, valid)

proc call*(call_602705: Call_PostDeleteDBSnapshot_602691;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602706 = newJObject()
  var formData_602707 = newJObject()
  add(formData_602707, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602706, "Action", newJString(Action))
  add(query_602706, "Version", newJString(Version))
  result = call_602705.call(nil, query_602706, nil, formData_602707, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_602691(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_602692, base: "/",
    url: url_PostDeleteDBSnapshot_602693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_602675 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBSnapshot_602677(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSnapshot_602676(path: JsonNode; query: JsonNode;
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
  var valid_602678 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602678 = validateParameter(valid_602678, JString, required = true,
                                 default = nil)
  if valid_602678 != nil:
    section.add "DBSnapshotIdentifier", valid_602678
  var valid_602679 = query.getOrDefault("Action")
  valid_602679 = validateParameter(valid_602679, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_602679 != nil:
    section.add "Action", valid_602679
  var valid_602680 = query.getOrDefault("Version")
  valid_602680 = validateParameter(valid_602680, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602680 != nil:
    section.add "Version", valid_602680
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602681 = header.getOrDefault("X-Amz-Signature")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-Signature", valid_602681
  var valid_602682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602682 = validateParameter(valid_602682, JString, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "X-Amz-Content-Sha256", valid_602682
  var valid_602683 = header.getOrDefault("X-Amz-Date")
  valid_602683 = validateParameter(valid_602683, JString, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "X-Amz-Date", valid_602683
  var valid_602684 = header.getOrDefault("X-Amz-Credential")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "X-Amz-Credential", valid_602684
  var valid_602685 = header.getOrDefault("X-Amz-Security-Token")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-Security-Token", valid_602685
  var valid_602686 = header.getOrDefault("X-Amz-Algorithm")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-Algorithm", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-SignedHeaders", valid_602687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602688: Call_GetDeleteDBSnapshot_602675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602688.validator(path, query, header, formData, body)
  let scheme = call_602688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602688.url(scheme.get, call_602688.host, call_602688.base,
                         call_602688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602688, url, valid)

proc call*(call_602689: Call_GetDeleteDBSnapshot_602675;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602690 = newJObject()
  add(query_602690, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602690, "Action", newJString(Action))
  add(query_602690, "Version", newJString(Version))
  result = call_602689.call(nil, query_602690, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_602675(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_602676, base: "/",
    url: url_GetDeleteDBSnapshot_602677, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_602724 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBSubnetGroup_602726(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSubnetGroup_602725(path: JsonNode; query: JsonNode;
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
  var valid_602727 = query.getOrDefault("Action")
  valid_602727 = validateParameter(valid_602727, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_602727 != nil:
    section.add "Action", valid_602727
  var valid_602728 = query.getOrDefault("Version")
  valid_602728 = validateParameter(valid_602728, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602728 != nil:
    section.add "Version", valid_602728
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602729 = header.getOrDefault("X-Amz-Signature")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-Signature", valid_602729
  var valid_602730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "X-Amz-Content-Sha256", valid_602730
  var valid_602731 = header.getOrDefault("X-Amz-Date")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "X-Amz-Date", valid_602731
  var valid_602732 = header.getOrDefault("X-Amz-Credential")
  valid_602732 = validateParameter(valid_602732, JString, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "X-Amz-Credential", valid_602732
  var valid_602733 = header.getOrDefault("X-Amz-Security-Token")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "X-Amz-Security-Token", valid_602733
  var valid_602734 = header.getOrDefault("X-Amz-Algorithm")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "X-Amz-Algorithm", valid_602734
  var valid_602735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602735 = validateParameter(valid_602735, JString, required = false,
                                 default = nil)
  if valid_602735 != nil:
    section.add "X-Amz-SignedHeaders", valid_602735
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_602736 = formData.getOrDefault("DBSubnetGroupName")
  valid_602736 = validateParameter(valid_602736, JString, required = true,
                                 default = nil)
  if valid_602736 != nil:
    section.add "DBSubnetGroupName", valid_602736
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602737: Call_PostDeleteDBSubnetGroup_602724; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602737.validator(path, query, header, formData, body)
  let scheme = call_602737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602737.url(scheme.get, call_602737.host, call_602737.base,
                         call_602737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602737, url, valid)

proc call*(call_602738: Call_PostDeleteDBSubnetGroup_602724;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_602739 = newJObject()
  var formData_602740 = newJObject()
  add(query_602739, "Action", newJString(Action))
  add(formData_602740, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602739, "Version", newJString(Version))
  result = call_602738.call(nil, query_602739, nil, formData_602740, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_602724(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_602725, base: "/",
    url: url_PostDeleteDBSubnetGroup_602726, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_602708 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBSubnetGroup_602710(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSubnetGroup_602709(path: JsonNode; query: JsonNode;
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
  var valid_602711 = query.getOrDefault("Action")
  valid_602711 = validateParameter(valid_602711, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_602711 != nil:
    section.add "Action", valid_602711
  var valid_602712 = query.getOrDefault("DBSubnetGroupName")
  valid_602712 = validateParameter(valid_602712, JString, required = true,
                                 default = nil)
  if valid_602712 != nil:
    section.add "DBSubnetGroupName", valid_602712
  var valid_602713 = query.getOrDefault("Version")
  valid_602713 = validateParameter(valid_602713, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602713 != nil:
    section.add "Version", valid_602713
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602714 = header.getOrDefault("X-Amz-Signature")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-Signature", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-Content-Sha256", valid_602715
  var valid_602716 = header.getOrDefault("X-Amz-Date")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "X-Amz-Date", valid_602716
  var valid_602717 = header.getOrDefault("X-Amz-Credential")
  valid_602717 = validateParameter(valid_602717, JString, required = false,
                                 default = nil)
  if valid_602717 != nil:
    section.add "X-Amz-Credential", valid_602717
  var valid_602718 = header.getOrDefault("X-Amz-Security-Token")
  valid_602718 = validateParameter(valid_602718, JString, required = false,
                                 default = nil)
  if valid_602718 != nil:
    section.add "X-Amz-Security-Token", valid_602718
  var valid_602719 = header.getOrDefault("X-Amz-Algorithm")
  valid_602719 = validateParameter(valid_602719, JString, required = false,
                                 default = nil)
  if valid_602719 != nil:
    section.add "X-Amz-Algorithm", valid_602719
  var valid_602720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602720 = validateParameter(valid_602720, JString, required = false,
                                 default = nil)
  if valid_602720 != nil:
    section.add "X-Amz-SignedHeaders", valid_602720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602721: Call_GetDeleteDBSubnetGroup_602708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602721.validator(path, query, header, formData, body)
  let scheme = call_602721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602721.url(scheme.get, call_602721.host, call_602721.base,
                         call_602721.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602721, url, valid)

proc call*(call_602722: Call_GetDeleteDBSubnetGroup_602708;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_602723 = newJObject()
  add(query_602723, "Action", newJString(Action))
  add(query_602723, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602723, "Version", newJString(Version))
  result = call_602722.call(nil, query_602723, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_602708(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_602709, base: "/",
    url: url_GetDeleteDBSubnetGroup_602710, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_602757 = ref object of OpenApiRestCall_601373
proc url_PostDeleteEventSubscription_602759(protocol: Scheme; host: string;
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

proc validate_PostDeleteEventSubscription_602758(path: JsonNode; query: JsonNode;
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
  var valid_602760 = query.getOrDefault("Action")
  valid_602760 = validateParameter(valid_602760, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_602760 != nil:
    section.add "Action", valid_602760
  var valid_602761 = query.getOrDefault("Version")
  valid_602761 = validateParameter(valid_602761, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602761 != nil:
    section.add "Version", valid_602761
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602762 = header.getOrDefault("X-Amz-Signature")
  valid_602762 = validateParameter(valid_602762, JString, required = false,
                                 default = nil)
  if valid_602762 != nil:
    section.add "X-Amz-Signature", valid_602762
  var valid_602763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602763 = validateParameter(valid_602763, JString, required = false,
                                 default = nil)
  if valid_602763 != nil:
    section.add "X-Amz-Content-Sha256", valid_602763
  var valid_602764 = header.getOrDefault("X-Amz-Date")
  valid_602764 = validateParameter(valid_602764, JString, required = false,
                                 default = nil)
  if valid_602764 != nil:
    section.add "X-Amz-Date", valid_602764
  var valid_602765 = header.getOrDefault("X-Amz-Credential")
  valid_602765 = validateParameter(valid_602765, JString, required = false,
                                 default = nil)
  if valid_602765 != nil:
    section.add "X-Amz-Credential", valid_602765
  var valid_602766 = header.getOrDefault("X-Amz-Security-Token")
  valid_602766 = validateParameter(valid_602766, JString, required = false,
                                 default = nil)
  if valid_602766 != nil:
    section.add "X-Amz-Security-Token", valid_602766
  var valid_602767 = header.getOrDefault("X-Amz-Algorithm")
  valid_602767 = validateParameter(valid_602767, JString, required = false,
                                 default = nil)
  if valid_602767 != nil:
    section.add "X-Amz-Algorithm", valid_602767
  var valid_602768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602768 = validateParameter(valid_602768, JString, required = false,
                                 default = nil)
  if valid_602768 != nil:
    section.add "X-Amz-SignedHeaders", valid_602768
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_602769 = formData.getOrDefault("SubscriptionName")
  valid_602769 = validateParameter(valid_602769, JString, required = true,
                                 default = nil)
  if valid_602769 != nil:
    section.add "SubscriptionName", valid_602769
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602770: Call_PostDeleteEventSubscription_602757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602770.validator(path, query, header, formData, body)
  let scheme = call_602770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602770.url(scheme.get, call_602770.host, call_602770.base,
                         call_602770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602770, url, valid)

proc call*(call_602771: Call_PostDeleteEventSubscription_602757;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602772 = newJObject()
  var formData_602773 = newJObject()
  add(formData_602773, "SubscriptionName", newJString(SubscriptionName))
  add(query_602772, "Action", newJString(Action))
  add(query_602772, "Version", newJString(Version))
  result = call_602771.call(nil, query_602772, nil, formData_602773, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_602757(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_602758, base: "/",
    url: url_PostDeleteEventSubscription_602759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_602741 = ref object of OpenApiRestCall_601373
proc url_GetDeleteEventSubscription_602743(protocol: Scheme; host: string;
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

proc validate_GetDeleteEventSubscription_602742(path: JsonNode; query: JsonNode;
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
  var valid_602744 = query.getOrDefault("SubscriptionName")
  valid_602744 = validateParameter(valid_602744, JString, required = true,
                                 default = nil)
  if valid_602744 != nil:
    section.add "SubscriptionName", valid_602744
  var valid_602745 = query.getOrDefault("Action")
  valid_602745 = validateParameter(valid_602745, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_602745 != nil:
    section.add "Action", valid_602745
  var valid_602746 = query.getOrDefault("Version")
  valid_602746 = validateParameter(valid_602746, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602746 != nil:
    section.add "Version", valid_602746
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602747 = header.getOrDefault("X-Amz-Signature")
  valid_602747 = validateParameter(valid_602747, JString, required = false,
                                 default = nil)
  if valid_602747 != nil:
    section.add "X-Amz-Signature", valid_602747
  var valid_602748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602748 = validateParameter(valid_602748, JString, required = false,
                                 default = nil)
  if valid_602748 != nil:
    section.add "X-Amz-Content-Sha256", valid_602748
  var valid_602749 = header.getOrDefault("X-Amz-Date")
  valid_602749 = validateParameter(valid_602749, JString, required = false,
                                 default = nil)
  if valid_602749 != nil:
    section.add "X-Amz-Date", valid_602749
  var valid_602750 = header.getOrDefault("X-Amz-Credential")
  valid_602750 = validateParameter(valid_602750, JString, required = false,
                                 default = nil)
  if valid_602750 != nil:
    section.add "X-Amz-Credential", valid_602750
  var valid_602751 = header.getOrDefault("X-Amz-Security-Token")
  valid_602751 = validateParameter(valid_602751, JString, required = false,
                                 default = nil)
  if valid_602751 != nil:
    section.add "X-Amz-Security-Token", valid_602751
  var valid_602752 = header.getOrDefault("X-Amz-Algorithm")
  valid_602752 = validateParameter(valid_602752, JString, required = false,
                                 default = nil)
  if valid_602752 != nil:
    section.add "X-Amz-Algorithm", valid_602752
  var valid_602753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "X-Amz-SignedHeaders", valid_602753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602754: Call_GetDeleteEventSubscription_602741; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602754.validator(path, query, header, formData, body)
  let scheme = call_602754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602754.url(scheme.get, call_602754.host, call_602754.base,
                         call_602754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602754, url, valid)

proc call*(call_602755: Call_GetDeleteEventSubscription_602741;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602756 = newJObject()
  add(query_602756, "SubscriptionName", newJString(SubscriptionName))
  add(query_602756, "Action", newJString(Action))
  add(query_602756, "Version", newJString(Version))
  result = call_602755.call(nil, query_602756, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_602741(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_602742, base: "/",
    url: url_GetDeleteEventSubscription_602743,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_602790 = ref object of OpenApiRestCall_601373
proc url_PostDeleteOptionGroup_602792(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteOptionGroup_602791(path: JsonNode; query: JsonNode;
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
  var valid_602793 = query.getOrDefault("Action")
  valid_602793 = validateParameter(valid_602793, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_602793 != nil:
    section.add "Action", valid_602793
  var valid_602794 = query.getOrDefault("Version")
  valid_602794 = validateParameter(valid_602794, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602794 != nil:
    section.add "Version", valid_602794
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602795 = header.getOrDefault("X-Amz-Signature")
  valid_602795 = validateParameter(valid_602795, JString, required = false,
                                 default = nil)
  if valid_602795 != nil:
    section.add "X-Amz-Signature", valid_602795
  var valid_602796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602796 = validateParameter(valid_602796, JString, required = false,
                                 default = nil)
  if valid_602796 != nil:
    section.add "X-Amz-Content-Sha256", valid_602796
  var valid_602797 = header.getOrDefault("X-Amz-Date")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "X-Amz-Date", valid_602797
  var valid_602798 = header.getOrDefault("X-Amz-Credential")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "X-Amz-Credential", valid_602798
  var valid_602799 = header.getOrDefault("X-Amz-Security-Token")
  valid_602799 = validateParameter(valid_602799, JString, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "X-Amz-Security-Token", valid_602799
  var valid_602800 = header.getOrDefault("X-Amz-Algorithm")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-Algorithm", valid_602800
  var valid_602801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "X-Amz-SignedHeaders", valid_602801
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_602802 = formData.getOrDefault("OptionGroupName")
  valid_602802 = validateParameter(valid_602802, JString, required = true,
                                 default = nil)
  if valid_602802 != nil:
    section.add "OptionGroupName", valid_602802
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602803: Call_PostDeleteOptionGroup_602790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602803.validator(path, query, header, formData, body)
  let scheme = call_602803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602803.url(scheme.get, call_602803.host, call_602803.base,
                         call_602803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602803, url, valid)

proc call*(call_602804: Call_PostDeleteOptionGroup_602790; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_602805 = newJObject()
  var formData_602806 = newJObject()
  add(query_602805, "Action", newJString(Action))
  add(formData_602806, "OptionGroupName", newJString(OptionGroupName))
  add(query_602805, "Version", newJString(Version))
  result = call_602804.call(nil, query_602805, nil, formData_602806, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_602790(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_602791, base: "/",
    url: url_PostDeleteOptionGroup_602792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_602774 = ref object of OpenApiRestCall_601373
proc url_GetDeleteOptionGroup_602776(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteOptionGroup_602775(path: JsonNode; query: JsonNode;
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
  var valid_602777 = query.getOrDefault("Action")
  valid_602777 = validateParameter(valid_602777, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_602777 != nil:
    section.add "Action", valid_602777
  var valid_602778 = query.getOrDefault("OptionGroupName")
  valid_602778 = validateParameter(valid_602778, JString, required = true,
                                 default = nil)
  if valid_602778 != nil:
    section.add "OptionGroupName", valid_602778
  var valid_602779 = query.getOrDefault("Version")
  valid_602779 = validateParameter(valid_602779, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602779 != nil:
    section.add "Version", valid_602779
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602780 = header.getOrDefault("X-Amz-Signature")
  valid_602780 = validateParameter(valid_602780, JString, required = false,
                                 default = nil)
  if valid_602780 != nil:
    section.add "X-Amz-Signature", valid_602780
  var valid_602781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602781 = validateParameter(valid_602781, JString, required = false,
                                 default = nil)
  if valid_602781 != nil:
    section.add "X-Amz-Content-Sha256", valid_602781
  var valid_602782 = header.getOrDefault("X-Amz-Date")
  valid_602782 = validateParameter(valid_602782, JString, required = false,
                                 default = nil)
  if valid_602782 != nil:
    section.add "X-Amz-Date", valid_602782
  var valid_602783 = header.getOrDefault("X-Amz-Credential")
  valid_602783 = validateParameter(valid_602783, JString, required = false,
                                 default = nil)
  if valid_602783 != nil:
    section.add "X-Amz-Credential", valid_602783
  var valid_602784 = header.getOrDefault("X-Amz-Security-Token")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Security-Token", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-Algorithm")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Algorithm", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-SignedHeaders", valid_602786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602787: Call_GetDeleteOptionGroup_602774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602787.validator(path, query, header, formData, body)
  let scheme = call_602787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602787.url(scheme.get, call_602787.host, call_602787.base,
                         call_602787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602787, url, valid)

proc call*(call_602788: Call_GetDeleteOptionGroup_602774; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_602789 = newJObject()
  add(query_602789, "Action", newJString(Action))
  add(query_602789, "OptionGroupName", newJString(OptionGroupName))
  add(query_602789, "Version", newJString(Version))
  result = call_602788.call(nil, query_602789, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_602774(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_602775, base: "/",
    url: url_GetDeleteOptionGroup_602776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_602830 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBEngineVersions_602832(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBEngineVersions_602831(path: JsonNode; query: JsonNode;
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
  var valid_602833 = query.getOrDefault("Action")
  valid_602833 = validateParameter(valid_602833, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_602833 != nil:
    section.add "Action", valid_602833
  var valid_602834 = query.getOrDefault("Version")
  valid_602834 = validateParameter(valid_602834, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602834 != nil:
    section.add "Version", valid_602834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602835 = header.getOrDefault("X-Amz-Signature")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-Signature", valid_602835
  var valid_602836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602836 = validateParameter(valid_602836, JString, required = false,
                                 default = nil)
  if valid_602836 != nil:
    section.add "X-Amz-Content-Sha256", valid_602836
  var valid_602837 = header.getOrDefault("X-Amz-Date")
  valid_602837 = validateParameter(valid_602837, JString, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "X-Amz-Date", valid_602837
  var valid_602838 = header.getOrDefault("X-Amz-Credential")
  valid_602838 = validateParameter(valid_602838, JString, required = false,
                                 default = nil)
  if valid_602838 != nil:
    section.add "X-Amz-Credential", valid_602838
  var valid_602839 = header.getOrDefault("X-Amz-Security-Token")
  valid_602839 = validateParameter(valid_602839, JString, required = false,
                                 default = nil)
  if valid_602839 != nil:
    section.add "X-Amz-Security-Token", valid_602839
  var valid_602840 = header.getOrDefault("X-Amz-Algorithm")
  valid_602840 = validateParameter(valid_602840, JString, required = false,
                                 default = nil)
  if valid_602840 != nil:
    section.add "X-Amz-Algorithm", valid_602840
  var valid_602841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602841 = validateParameter(valid_602841, JString, required = false,
                                 default = nil)
  if valid_602841 != nil:
    section.add "X-Amz-SignedHeaders", valid_602841
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
  var valid_602842 = formData.getOrDefault("DefaultOnly")
  valid_602842 = validateParameter(valid_602842, JBool, required = false, default = nil)
  if valid_602842 != nil:
    section.add "DefaultOnly", valid_602842
  var valid_602843 = formData.getOrDefault("MaxRecords")
  valid_602843 = validateParameter(valid_602843, JInt, required = false, default = nil)
  if valid_602843 != nil:
    section.add "MaxRecords", valid_602843
  var valid_602844 = formData.getOrDefault("EngineVersion")
  valid_602844 = validateParameter(valid_602844, JString, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "EngineVersion", valid_602844
  var valid_602845 = formData.getOrDefault("Marker")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "Marker", valid_602845
  var valid_602846 = formData.getOrDefault("Engine")
  valid_602846 = validateParameter(valid_602846, JString, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "Engine", valid_602846
  var valid_602847 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_602847 = validateParameter(valid_602847, JBool, required = false, default = nil)
  if valid_602847 != nil:
    section.add "ListSupportedCharacterSets", valid_602847
  var valid_602848 = formData.getOrDefault("Filters")
  valid_602848 = validateParameter(valid_602848, JArray, required = false,
                                 default = nil)
  if valid_602848 != nil:
    section.add "Filters", valid_602848
  var valid_602849 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602849 = validateParameter(valid_602849, JString, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "DBParameterGroupFamily", valid_602849
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602850: Call_PostDescribeDBEngineVersions_602830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602850.validator(path, query, header, formData, body)
  let scheme = call_602850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602850.url(scheme.get, call_602850.host, call_602850.base,
                         call_602850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602850, url, valid)

proc call*(call_602851: Call_PostDescribeDBEngineVersions_602830;
          DefaultOnly: bool = false; MaxRecords: int = 0; EngineVersion: string = "";
          Marker: string = ""; Engine: string = "";
          ListSupportedCharacterSets: bool = false;
          Action: string = "DescribeDBEngineVersions"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"; DBParameterGroupFamily: string = ""): Recallable =
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
  var query_602852 = newJObject()
  var formData_602853 = newJObject()
  add(formData_602853, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_602853, "MaxRecords", newJInt(MaxRecords))
  add(formData_602853, "EngineVersion", newJString(EngineVersion))
  add(formData_602853, "Marker", newJString(Marker))
  add(formData_602853, "Engine", newJString(Engine))
  add(formData_602853, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_602852, "Action", newJString(Action))
  if Filters != nil:
    formData_602853.add "Filters", Filters
  add(query_602852, "Version", newJString(Version))
  add(formData_602853, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_602851.call(nil, query_602852, nil, formData_602853, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_602830(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_602831, base: "/",
    url: url_PostDescribeDBEngineVersions_602832,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_602807 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBEngineVersions_602809(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBEngineVersions_602808(path: JsonNode; query: JsonNode;
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
  var valid_602810 = query.getOrDefault("Marker")
  valid_602810 = validateParameter(valid_602810, JString, required = false,
                                 default = nil)
  if valid_602810 != nil:
    section.add "Marker", valid_602810
  var valid_602811 = query.getOrDefault("DBParameterGroupFamily")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "DBParameterGroupFamily", valid_602811
  var valid_602812 = query.getOrDefault("Engine")
  valid_602812 = validateParameter(valid_602812, JString, required = false,
                                 default = nil)
  if valid_602812 != nil:
    section.add "Engine", valid_602812
  var valid_602813 = query.getOrDefault("EngineVersion")
  valid_602813 = validateParameter(valid_602813, JString, required = false,
                                 default = nil)
  if valid_602813 != nil:
    section.add "EngineVersion", valid_602813
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602814 = query.getOrDefault("Action")
  valid_602814 = validateParameter(valid_602814, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_602814 != nil:
    section.add "Action", valid_602814
  var valid_602815 = query.getOrDefault("ListSupportedCharacterSets")
  valid_602815 = validateParameter(valid_602815, JBool, required = false, default = nil)
  if valid_602815 != nil:
    section.add "ListSupportedCharacterSets", valid_602815
  var valid_602816 = query.getOrDefault("Version")
  valid_602816 = validateParameter(valid_602816, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602816 != nil:
    section.add "Version", valid_602816
  var valid_602817 = query.getOrDefault("Filters")
  valid_602817 = validateParameter(valid_602817, JArray, required = false,
                                 default = nil)
  if valid_602817 != nil:
    section.add "Filters", valid_602817
  var valid_602818 = query.getOrDefault("MaxRecords")
  valid_602818 = validateParameter(valid_602818, JInt, required = false, default = nil)
  if valid_602818 != nil:
    section.add "MaxRecords", valid_602818
  var valid_602819 = query.getOrDefault("DefaultOnly")
  valid_602819 = validateParameter(valid_602819, JBool, required = false, default = nil)
  if valid_602819 != nil:
    section.add "DefaultOnly", valid_602819
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602820 = header.getOrDefault("X-Amz-Signature")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-Signature", valid_602820
  var valid_602821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-Content-Sha256", valid_602821
  var valid_602822 = header.getOrDefault("X-Amz-Date")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-Date", valid_602822
  var valid_602823 = header.getOrDefault("X-Amz-Credential")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-Credential", valid_602823
  var valid_602824 = header.getOrDefault("X-Amz-Security-Token")
  valid_602824 = validateParameter(valid_602824, JString, required = false,
                                 default = nil)
  if valid_602824 != nil:
    section.add "X-Amz-Security-Token", valid_602824
  var valid_602825 = header.getOrDefault("X-Amz-Algorithm")
  valid_602825 = validateParameter(valid_602825, JString, required = false,
                                 default = nil)
  if valid_602825 != nil:
    section.add "X-Amz-Algorithm", valid_602825
  var valid_602826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602826 = validateParameter(valid_602826, JString, required = false,
                                 default = nil)
  if valid_602826 != nil:
    section.add "X-Amz-SignedHeaders", valid_602826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602827: Call_GetDescribeDBEngineVersions_602807; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602827.validator(path, query, header, formData, body)
  let scheme = call_602827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602827.url(scheme.get, call_602827.host, call_602827.base,
                         call_602827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602827, url, valid)

proc call*(call_602828: Call_GetDescribeDBEngineVersions_602807;
          Marker: string = ""; DBParameterGroupFamily: string = ""; Engine: string = "";
          EngineVersion: string = ""; Action: string = "DescribeDBEngineVersions";
          ListSupportedCharacterSets: bool = false; Version: string = "2014-09-01";
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
  var query_602829 = newJObject()
  add(query_602829, "Marker", newJString(Marker))
  add(query_602829, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_602829, "Engine", newJString(Engine))
  add(query_602829, "EngineVersion", newJString(EngineVersion))
  add(query_602829, "Action", newJString(Action))
  add(query_602829, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_602829, "Version", newJString(Version))
  if Filters != nil:
    query_602829.add "Filters", Filters
  add(query_602829, "MaxRecords", newJInt(MaxRecords))
  add(query_602829, "DefaultOnly", newJBool(DefaultOnly))
  result = call_602828.call(nil, query_602829, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_602807(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_602808, base: "/",
    url: url_GetDescribeDBEngineVersions_602809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_602873 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBInstances_602875(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBInstances_602874(path: JsonNode; query: JsonNode;
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
  var valid_602876 = query.getOrDefault("Action")
  valid_602876 = validateParameter(valid_602876, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_602876 != nil:
    section.add "Action", valid_602876
  var valid_602877 = query.getOrDefault("Version")
  valid_602877 = validateParameter(valid_602877, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602877 != nil:
    section.add "Version", valid_602877
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602878 = header.getOrDefault("X-Amz-Signature")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-Signature", valid_602878
  var valid_602879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "X-Amz-Content-Sha256", valid_602879
  var valid_602880 = header.getOrDefault("X-Amz-Date")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "X-Amz-Date", valid_602880
  var valid_602881 = header.getOrDefault("X-Amz-Credential")
  valid_602881 = validateParameter(valid_602881, JString, required = false,
                                 default = nil)
  if valid_602881 != nil:
    section.add "X-Amz-Credential", valid_602881
  var valid_602882 = header.getOrDefault("X-Amz-Security-Token")
  valid_602882 = validateParameter(valid_602882, JString, required = false,
                                 default = nil)
  if valid_602882 != nil:
    section.add "X-Amz-Security-Token", valid_602882
  var valid_602883 = header.getOrDefault("X-Amz-Algorithm")
  valid_602883 = validateParameter(valid_602883, JString, required = false,
                                 default = nil)
  if valid_602883 != nil:
    section.add "X-Amz-Algorithm", valid_602883
  var valid_602884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-SignedHeaders", valid_602884
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_602885 = formData.getOrDefault("MaxRecords")
  valid_602885 = validateParameter(valid_602885, JInt, required = false, default = nil)
  if valid_602885 != nil:
    section.add "MaxRecords", valid_602885
  var valid_602886 = formData.getOrDefault("Marker")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "Marker", valid_602886
  var valid_602887 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "DBInstanceIdentifier", valid_602887
  var valid_602888 = formData.getOrDefault("Filters")
  valid_602888 = validateParameter(valid_602888, JArray, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "Filters", valid_602888
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602889: Call_PostDescribeDBInstances_602873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602889.validator(path, query, header, formData, body)
  let scheme = call_602889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602889.url(scheme.get, call_602889.host, call_602889.base,
                         call_602889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602889, url, valid)

proc call*(call_602890: Call_PostDescribeDBInstances_602873; MaxRecords: int = 0;
          Marker: string = ""; DBInstanceIdentifier: string = "";
          Action: string = "DescribeDBInstances"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBInstances
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_602891 = newJObject()
  var formData_602892 = newJObject()
  add(formData_602892, "MaxRecords", newJInt(MaxRecords))
  add(formData_602892, "Marker", newJString(Marker))
  add(formData_602892, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602891, "Action", newJString(Action))
  if Filters != nil:
    formData_602892.add "Filters", Filters
  add(query_602891, "Version", newJString(Version))
  result = call_602890.call(nil, query_602891, nil, formData_602892, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_602873(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_602874, base: "/",
    url: url_PostDescribeDBInstances_602875, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_602854 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBInstances_602856(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBInstances_602855(path: JsonNode; query: JsonNode;
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
  var valid_602857 = query.getOrDefault("Marker")
  valid_602857 = validateParameter(valid_602857, JString, required = false,
                                 default = nil)
  if valid_602857 != nil:
    section.add "Marker", valid_602857
  var valid_602858 = query.getOrDefault("DBInstanceIdentifier")
  valid_602858 = validateParameter(valid_602858, JString, required = false,
                                 default = nil)
  if valid_602858 != nil:
    section.add "DBInstanceIdentifier", valid_602858
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602859 = query.getOrDefault("Action")
  valid_602859 = validateParameter(valid_602859, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_602859 != nil:
    section.add "Action", valid_602859
  var valid_602860 = query.getOrDefault("Version")
  valid_602860 = validateParameter(valid_602860, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602860 != nil:
    section.add "Version", valid_602860
  var valid_602861 = query.getOrDefault("Filters")
  valid_602861 = validateParameter(valid_602861, JArray, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "Filters", valid_602861
  var valid_602862 = query.getOrDefault("MaxRecords")
  valid_602862 = validateParameter(valid_602862, JInt, required = false, default = nil)
  if valid_602862 != nil:
    section.add "MaxRecords", valid_602862
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602863 = header.getOrDefault("X-Amz-Signature")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-Signature", valid_602863
  var valid_602864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602864 = validateParameter(valid_602864, JString, required = false,
                                 default = nil)
  if valid_602864 != nil:
    section.add "X-Amz-Content-Sha256", valid_602864
  var valid_602865 = header.getOrDefault("X-Amz-Date")
  valid_602865 = validateParameter(valid_602865, JString, required = false,
                                 default = nil)
  if valid_602865 != nil:
    section.add "X-Amz-Date", valid_602865
  var valid_602866 = header.getOrDefault("X-Amz-Credential")
  valid_602866 = validateParameter(valid_602866, JString, required = false,
                                 default = nil)
  if valid_602866 != nil:
    section.add "X-Amz-Credential", valid_602866
  var valid_602867 = header.getOrDefault("X-Amz-Security-Token")
  valid_602867 = validateParameter(valid_602867, JString, required = false,
                                 default = nil)
  if valid_602867 != nil:
    section.add "X-Amz-Security-Token", valid_602867
  var valid_602868 = header.getOrDefault("X-Amz-Algorithm")
  valid_602868 = validateParameter(valid_602868, JString, required = false,
                                 default = nil)
  if valid_602868 != nil:
    section.add "X-Amz-Algorithm", valid_602868
  var valid_602869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602869 = validateParameter(valid_602869, JString, required = false,
                                 default = nil)
  if valid_602869 != nil:
    section.add "X-Amz-SignedHeaders", valid_602869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602870: Call_GetDescribeDBInstances_602854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602870.validator(path, query, header, formData, body)
  let scheme = call_602870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602870.url(scheme.get, call_602870.host, call_602870.base,
                         call_602870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602870, url, valid)

proc call*(call_602871: Call_GetDescribeDBInstances_602854; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_602872 = newJObject()
  add(query_602872, "Marker", newJString(Marker))
  add(query_602872, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602872, "Action", newJString(Action))
  add(query_602872, "Version", newJString(Version))
  if Filters != nil:
    query_602872.add "Filters", Filters
  add(query_602872, "MaxRecords", newJInt(MaxRecords))
  result = call_602871.call(nil, query_602872, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_602854(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_602855, base: "/",
    url: url_GetDescribeDBInstances_602856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_602915 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBLogFiles_602917(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBLogFiles_602916(path: JsonNode; query: JsonNode;
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
  var valid_602918 = query.getOrDefault("Action")
  valid_602918 = validateParameter(valid_602918, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_602918 != nil:
    section.add "Action", valid_602918
  var valid_602919 = query.getOrDefault("Version")
  valid_602919 = validateParameter(valid_602919, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602919 != nil:
    section.add "Version", valid_602919
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602920 = header.getOrDefault("X-Amz-Signature")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Signature", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Content-Sha256", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Date")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Date", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-Credential")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Credential", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-Security-Token")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Security-Token", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Algorithm")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Algorithm", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-SignedHeaders", valid_602926
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
  var valid_602927 = formData.getOrDefault("FileSize")
  valid_602927 = validateParameter(valid_602927, JInt, required = false, default = nil)
  if valid_602927 != nil:
    section.add "FileSize", valid_602927
  var valid_602928 = formData.getOrDefault("MaxRecords")
  valid_602928 = validateParameter(valid_602928, JInt, required = false, default = nil)
  if valid_602928 != nil:
    section.add "MaxRecords", valid_602928
  var valid_602929 = formData.getOrDefault("Marker")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "Marker", valid_602929
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602930 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602930 = validateParameter(valid_602930, JString, required = true,
                                 default = nil)
  if valid_602930 != nil:
    section.add "DBInstanceIdentifier", valid_602930
  var valid_602931 = formData.getOrDefault("FilenameContains")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "FilenameContains", valid_602931
  var valid_602932 = formData.getOrDefault("Filters")
  valid_602932 = validateParameter(valid_602932, JArray, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "Filters", valid_602932
  var valid_602933 = formData.getOrDefault("FileLastWritten")
  valid_602933 = validateParameter(valid_602933, JInt, required = false, default = nil)
  if valid_602933 != nil:
    section.add "FileLastWritten", valid_602933
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602934: Call_PostDescribeDBLogFiles_602915; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602934.validator(path, query, header, formData, body)
  let scheme = call_602934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602934.url(scheme.get, call_602934.host, call_602934.base,
                         call_602934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602934, url, valid)

proc call*(call_602935: Call_PostDescribeDBLogFiles_602915;
          DBInstanceIdentifier: string; FileSize: int = 0; MaxRecords: int = 0;
          Marker: string = ""; FilenameContains: string = "";
          Action: string = "DescribeDBLogFiles"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"; FileLastWritten: int = 0): Recallable =
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
  var query_602936 = newJObject()
  var formData_602937 = newJObject()
  add(formData_602937, "FileSize", newJInt(FileSize))
  add(formData_602937, "MaxRecords", newJInt(MaxRecords))
  add(formData_602937, "Marker", newJString(Marker))
  add(formData_602937, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602937, "FilenameContains", newJString(FilenameContains))
  add(query_602936, "Action", newJString(Action))
  if Filters != nil:
    formData_602937.add "Filters", Filters
  add(query_602936, "Version", newJString(Version))
  add(formData_602937, "FileLastWritten", newJInt(FileLastWritten))
  result = call_602935.call(nil, query_602936, nil, formData_602937, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_602915(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_602916, base: "/",
    url: url_PostDescribeDBLogFiles_602917, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_602893 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBLogFiles_602895(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBLogFiles_602894(path: JsonNode; query: JsonNode;
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
  var valid_602896 = query.getOrDefault("Marker")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "Marker", valid_602896
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602897 = query.getOrDefault("DBInstanceIdentifier")
  valid_602897 = validateParameter(valid_602897, JString, required = true,
                                 default = nil)
  if valid_602897 != nil:
    section.add "DBInstanceIdentifier", valid_602897
  var valid_602898 = query.getOrDefault("FileLastWritten")
  valid_602898 = validateParameter(valid_602898, JInt, required = false, default = nil)
  if valid_602898 != nil:
    section.add "FileLastWritten", valid_602898
  var valid_602899 = query.getOrDefault("Action")
  valid_602899 = validateParameter(valid_602899, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_602899 != nil:
    section.add "Action", valid_602899
  var valid_602900 = query.getOrDefault("FilenameContains")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "FilenameContains", valid_602900
  var valid_602901 = query.getOrDefault("Version")
  valid_602901 = validateParameter(valid_602901, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602901 != nil:
    section.add "Version", valid_602901
  var valid_602902 = query.getOrDefault("Filters")
  valid_602902 = validateParameter(valid_602902, JArray, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "Filters", valid_602902
  var valid_602903 = query.getOrDefault("MaxRecords")
  valid_602903 = validateParameter(valid_602903, JInt, required = false, default = nil)
  if valid_602903 != nil:
    section.add "MaxRecords", valid_602903
  var valid_602904 = query.getOrDefault("FileSize")
  valid_602904 = validateParameter(valid_602904, JInt, required = false, default = nil)
  if valid_602904 != nil:
    section.add "FileSize", valid_602904
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602905 = header.getOrDefault("X-Amz-Signature")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Signature", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-Content-Sha256", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-Date")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Date", valid_602907
  var valid_602908 = header.getOrDefault("X-Amz-Credential")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Credential", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Security-Token")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Security-Token", valid_602909
  var valid_602910 = header.getOrDefault("X-Amz-Algorithm")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Algorithm", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-SignedHeaders", valid_602911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602912: Call_GetDescribeDBLogFiles_602893; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602912.validator(path, query, header, formData, body)
  let scheme = call_602912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602912.url(scheme.get, call_602912.host, call_602912.base,
                         call_602912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602912, url, valid)

proc call*(call_602913: Call_GetDescribeDBLogFiles_602893;
          DBInstanceIdentifier: string; Marker: string = ""; FileLastWritten: int = 0;
          Action: string = "DescribeDBLogFiles"; FilenameContains: string = "";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0;
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
  var query_602914 = newJObject()
  add(query_602914, "Marker", newJString(Marker))
  add(query_602914, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602914, "FileLastWritten", newJInt(FileLastWritten))
  add(query_602914, "Action", newJString(Action))
  add(query_602914, "FilenameContains", newJString(FilenameContains))
  add(query_602914, "Version", newJString(Version))
  if Filters != nil:
    query_602914.add "Filters", Filters
  add(query_602914, "MaxRecords", newJInt(MaxRecords))
  add(query_602914, "FileSize", newJInt(FileSize))
  result = call_602913.call(nil, query_602914, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_602893(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_602894, base: "/",
    url: url_GetDescribeDBLogFiles_602895, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_602957 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBParameterGroups_602959(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameterGroups_602958(path: JsonNode; query: JsonNode;
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
  var valid_602960 = query.getOrDefault("Action")
  valid_602960 = validateParameter(valid_602960, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_602960 != nil:
    section.add "Action", valid_602960
  var valid_602961 = query.getOrDefault("Version")
  valid_602961 = validateParameter(valid_602961, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602961 != nil:
    section.add "Version", valid_602961
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602962 = header.getOrDefault("X-Amz-Signature")
  valid_602962 = validateParameter(valid_602962, JString, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "X-Amz-Signature", valid_602962
  var valid_602963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602963 = validateParameter(valid_602963, JString, required = false,
                                 default = nil)
  if valid_602963 != nil:
    section.add "X-Amz-Content-Sha256", valid_602963
  var valid_602964 = header.getOrDefault("X-Amz-Date")
  valid_602964 = validateParameter(valid_602964, JString, required = false,
                                 default = nil)
  if valid_602964 != nil:
    section.add "X-Amz-Date", valid_602964
  var valid_602965 = header.getOrDefault("X-Amz-Credential")
  valid_602965 = validateParameter(valid_602965, JString, required = false,
                                 default = nil)
  if valid_602965 != nil:
    section.add "X-Amz-Credential", valid_602965
  var valid_602966 = header.getOrDefault("X-Amz-Security-Token")
  valid_602966 = validateParameter(valid_602966, JString, required = false,
                                 default = nil)
  if valid_602966 != nil:
    section.add "X-Amz-Security-Token", valid_602966
  var valid_602967 = header.getOrDefault("X-Amz-Algorithm")
  valid_602967 = validateParameter(valid_602967, JString, required = false,
                                 default = nil)
  if valid_602967 != nil:
    section.add "X-Amz-Algorithm", valid_602967
  var valid_602968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602968 = validateParameter(valid_602968, JString, required = false,
                                 default = nil)
  if valid_602968 != nil:
    section.add "X-Amz-SignedHeaders", valid_602968
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_602969 = formData.getOrDefault("MaxRecords")
  valid_602969 = validateParameter(valid_602969, JInt, required = false, default = nil)
  if valid_602969 != nil:
    section.add "MaxRecords", valid_602969
  var valid_602970 = formData.getOrDefault("DBParameterGroupName")
  valid_602970 = validateParameter(valid_602970, JString, required = false,
                                 default = nil)
  if valid_602970 != nil:
    section.add "DBParameterGroupName", valid_602970
  var valid_602971 = formData.getOrDefault("Marker")
  valid_602971 = validateParameter(valid_602971, JString, required = false,
                                 default = nil)
  if valid_602971 != nil:
    section.add "Marker", valid_602971
  var valid_602972 = formData.getOrDefault("Filters")
  valid_602972 = validateParameter(valid_602972, JArray, required = false,
                                 default = nil)
  if valid_602972 != nil:
    section.add "Filters", valid_602972
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602973: Call_PostDescribeDBParameterGroups_602957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602973.validator(path, query, header, formData, body)
  let scheme = call_602973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602973.url(scheme.get, call_602973.host, call_602973.base,
                         call_602973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602973, url, valid)

proc call*(call_602974: Call_PostDescribeDBParameterGroups_602957;
          MaxRecords: int = 0; DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_602975 = newJObject()
  var formData_602976 = newJObject()
  add(formData_602976, "MaxRecords", newJInt(MaxRecords))
  add(formData_602976, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602976, "Marker", newJString(Marker))
  add(query_602975, "Action", newJString(Action))
  if Filters != nil:
    formData_602976.add "Filters", Filters
  add(query_602975, "Version", newJString(Version))
  result = call_602974.call(nil, query_602975, nil, formData_602976, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_602957(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_602958, base: "/",
    url: url_PostDescribeDBParameterGroups_602959,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_602938 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBParameterGroups_602940(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBParameterGroups_602939(path: JsonNode; query: JsonNode;
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
  var valid_602941 = query.getOrDefault("Marker")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "Marker", valid_602941
  var valid_602942 = query.getOrDefault("DBParameterGroupName")
  valid_602942 = validateParameter(valid_602942, JString, required = false,
                                 default = nil)
  if valid_602942 != nil:
    section.add "DBParameterGroupName", valid_602942
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602943 = query.getOrDefault("Action")
  valid_602943 = validateParameter(valid_602943, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_602943 != nil:
    section.add "Action", valid_602943
  var valid_602944 = query.getOrDefault("Version")
  valid_602944 = validateParameter(valid_602944, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602944 != nil:
    section.add "Version", valid_602944
  var valid_602945 = query.getOrDefault("Filters")
  valid_602945 = validateParameter(valid_602945, JArray, required = false,
                                 default = nil)
  if valid_602945 != nil:
    section.add "Filters", valid_602945
  var valid_602946 = query.getOrDefault("MaxRecords")
  valid_602946 = validateParameter(valid_602946, JInt, required = false, default = nil)
  if valid_602946 != nil:
    section.add "MaxRecords", valid_602946
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602947 = header.getOrDefault("X-Amz-Signature")
  valid_602947 = validateParameter(valid_602947, JString, required = false,
                                 default = nil)
  if valid_602947 != nil:
    section.add "X-Amz-Signature", valid_602947
  var valid_602948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602948 = validateParameter(valid_602948, JString, required = false,
                                 default = nil)
  if valid_602948 != nil:
    section.add "X-Amz-Content-Sha256", valid_602948
  var valid_602949 = header.getOrDefault("X-Amz-Date")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "X-Amz-Date", valid_602949
  var valid_602950 = header.getOrDefault("X-Amz-Credential")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "X-Amz-Credential", valid_602950
  var valid_602951 = header.getOrDefault("X-Amz-Security-Token")
  valid_602951 = validateParameter(valid_602951, JString, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "X-Amz-Security-Token", valid_602951
  var valid_602952 = header.getOrDefault("X-Amz-Algorithm")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "X-Amz-Algorithm", valid_602952
  var valid_602953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "X-Amz-SignedHeaders", valid_602953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602954: Call_GetDescribeDBParameterGroups_602938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602954.validator(path, query, header, formData, body)
  let scheme = call_602954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602954.url(scheme.get, call_602954.host, call_602954.base,
                         call_602954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602954, url, valid)

proc call*(call_602955: Call_GetDescribeDBParameterGroups_602938;
          Marker: string = ""; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameterGroups
  ##   Marker: string
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_602956 = newJObject()
  add(query_602956, "Marker", newJString(Marker))
  add(query_602956, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602956, "Action", newJString(Action))
  add(query_602956, "Version", newJString(Version))
  if Filters != nil:
    query_602956.add "Filters", Filters
  add(query_602956, "MaxRecords", newJInt(MaxRecords))
  result = call_602955.call(nil, query_602956, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_602938(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_602939, base: "/",
    url: url_GetDescribeDBParameterGroups_602940,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_602997 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBParameters_602999(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameters_602998(path: JsonNode; query: JsonNode;
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
  var valid_603000 = query.getOrDefault("Action")
  valid_603000 = validateParameter(valid_603000, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_603000 != nil:
    section.add "Action", valid_603000
  var valid_603001 = query.getOrDefault("Version")
  valid_603001 = validateParameter(valid_603001, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603001 != nil:
    section.add "Version", valid_603001
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603002 = header.getOrDefault("X-Amz-Signature")
  valid_603002 = validateParameter(valid_603002, JString, required = false,
                                 default = nil)
  if valid_603002 != nil:
    section.add "X-Amz-Signature", valid_603002
  var valid_603003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603003 = validateParameter(valid_603003, JString, required = false,
                                 default = nil)
  if valid_603003 != nil:
    section.add "X-Amz-Content-Sha256", valid_603003
  var valid_603004 = header.getOrDefault("X-Amz-Date")
  valid_603004 = validateParameter(valid_603004, JString, required = false,
                                 default = nil)
  if valid_603004 != nil:
    section.add "X-Amz-Date", valid_603004
  var valid_603005 = header.getOrDefault("X-Amz-Credential")
  valid_603005 = validateParameter(valid_603005, JString, required = false,
                                 default = nil)
  if valid_603005 != nil:
    section.add "X-Amz-Credential", valid_603005
  var valid_603006 = header.getOrDefault("X-Amz-Security-Token")
  valid_603006 = validateParameter(valid_603006, JString, required = false,
                                 default = nil)
  if valid_603006 != nil:
    section.add "X-Amz-Security-Token", valid_603006
  var valid_603007 = header.getOrDefault("X-Amz-Algorithm")
  valid_603007 = validateParameter(valid_603007, JString, required = false,
                                 default = nil)
  if valid_603007 != nil:
    section.add "X-Amz-Algorithm", valid_603007
  var valid_603008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603008 = validateParameter(valid_603008, JString, required = false,
                                 default = nil)
  if valid_603008 != nil:
    section.add "X-Amz-SignedHeaders", valid_603008
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603009 = formData.getOrDefault("Source")
  valid_603009 = validateParameter(valid_603009, JString, required = false,
                                 default = nil)
  if valid_603009 != nil:
    section.add "Source", valid_603009
  var valid_603010 = formData.getOrDefault("MaxRecords")
  valid_603010 = validateParameter(valid_603010, JInt, required = false, default = nil)
  if valid_603010 != nil:
    section.add "MaxRecords", valid_603010
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603011 = formData.getOrDefault("DBParameterGroupName")
  valid_603011 = validateParameter(valid_603011, JString, required = true,
                                 default = nil)
  if valid_603011 != nil:
    section.add "DBParameterGroupName", valid_603011
  var valid_603012 = formData.getOrDefault("Marker")
  valid_603012 = validateParameter(valid_603012, JString, required = false,
                                 default = nil)
  if valid_603012 != nil:
    section.add "Marker", valid_603012
  var valid_603013 = formData.getOrDefault("Filters")
  valid_603013 = validateParameter(valid_603013, JArray, required = false,
                                 default = nil)
  if valid_603013 != nil:
    section.add "Filters", valid_603013
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603014: Call_PostDescribeDBParameters_602997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603014.validator(path, query, header, formData, body)
  let scheme = call_603014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603014.url(scheme.get, call_603014.host, call_603014.base,
                         call_603014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603014, url, valid)

proc call*(call_603015: Call_PostDescribeDBParameters_602997;
          DBParameterGroupName: string; Source: string = ""; MaxRecords: int = 0;
          Marker: string = ""; Action: string = "DescribeDBParameters";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBParameters
  ##   Source: string
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603016 = newJObject()
  var formData_603017 = newJObject()
  add(formData_603017, "Source", newJString(Source))
  add(formData_603017, "MaxRecords", newJInt(MaxRecords))
  add(formData_603017, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603017, "Marker", newJString(Marker))
  add(query_603016, "Action", newJString(Action))
  if Filters != nil:
    formData_603017.add "Filters", Filters
  add(query_603016, "Version", newJString(Version))
  result = call_603015.call(nil, query_603016, nil, formData_603017, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_602997(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_602998, base: "/",
    url: url_PostDescribeDBParameters_602999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_602977 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBParameters_602979(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBParameters_602978(path: JsonNode; query: JsonNode;
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
  var valid_602980 = query.getOrDefault("Marker")
  valid_602980 = validateParameter(valid_602980, JString, required = false,
                                 default = nil)
  if valid_602980 != nil:
    section.add "Marker", valid_602980
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_602981 = query.getOrDefault("DBParameterGroupName")
  valid_602981 = validateParameter(valid_602981, JString, required = true,
                                 default = nil)
  if valid_602981 != nil:
    section.add "DBParameterGroupName", valid_602981
  var valid_602982 = query.getOrDefault("Source")
  valid_602982 = validateParameter(valid_602982, JString, required = false,
                                 default = nil)
  if valid_602982 != nil:
    section.add "Source", valid_602982
  var valid_602983 = query.getOrDefault("Action")
  valid_602983 = validateParameter(valid_602983, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_602983 != nil:
    section.add "Action", valid_602983
  var valid_602984 = query.getOrDefault("Version")
  valid_602984 = validateParameter(valid_602984, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602984 != nil:
    section.add "Version", valid_602984
  var valid_602985 = query.getOrDefault("Filters")
  valid_602985 = validateParameter(valid_602985, JArray, required = false,
                                 default = nil)
  if valid_602985 != nil:
    section.add "Filters", valid_602985
  var valid_602986 = query.getOrDefault("MaxRecords")
  valid_602986 = validateParameter(valid_602986, JInt, required = false, default = nil)
  if valid_602986 != nil:
    section.add "MaxRecords", valid_602986
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602987 = header.getOrDefault("X-Amz-Signature")
  valid_602987 = validateParameter(valid_602987, JString, required = false,
                                 default = nil)
  if valid_602987 != nil:
    section.add "X-Amz-Signature", valid_602987
  var valid_602988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602988 = validateParameter(valid_602988, JString, required = false,
                                 default = nil)
  if valid_602988 != nil:
    section.add "X-Amz-Content-Sha256", valid_602988
  var valid_602989 = header.getOrDefault("X-Amz-Date")
  valid_602989 = validateParameter(valid_602989, JString, required = false,
                                 default = nil)
  if valid_602989 != nil:
    section.add "X-Amz-Date", valid_602989
  var valid_602990 = header.getOrDefault("X-Amz-Credential")
  valid_602990 = validateParameter(valid_602990, JString, required = false,
                                 default = nil)
  if valid_602990 != nil:
    section.add "X-Amz-Credential", valid_602990
  var valid_602991 = header.getOrDefault("X-Amz-Security-Token")
  valid_602991 = validateParameter(valid_602991, JString, required = false,
                                 default = nil)
  if valid_602991 != nil:
    section.add "X-Amz-Security-Token", valid_602991
  var valid_602992 = header.getOrDefault("X-Amz-Algorithm")
  valid_602992 = validateParameter(valid_602992, JString, required = false,
                                 default = nil)
  if valid_602992 != nil:
    section.add "X-Amz-Algorithm", valid_602992
  var valid_602993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602993 = validateParameter(valid_602993, JString, required = false,
                                 default = nil)
  if valid_602993 != nil:
    section.add "X-Amz-SignedHeaders", valid_602993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602994: Call_GetDescribeDBParameters_602977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602994.validator(path, query, header, formData, body)
  let scheme = call_602994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602994.url(scheme.get, call_602994.host, call_602994.base,
                         call_602994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602994, url, valid)

proc call*(call_602995: Call_GetDescribeDBParameters_602977;
          DBParameterGroupName: string; Marker: string = ""; Source: string = "";
          Action: string = "DescribeDBParameters"; Version: string = "2014-09-01";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameters
  ##   Marker: string
  ##   DBParameterGroupName: string (required)
  ##   Source: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_602996 = newJObject()
  add(query_602996, "Marker", newJString(Marker))
  add(query_602996, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602996, "Source", newJString(Source))
  add(query_602996, "Action", newJString(Action))
  add(query_602996, "Version", newJString(Version))
  if Filters != nil:
    query_602996.add "Filters", Filters
  add(query_602996, "MaxRecords", newJInt(MaxRecords))
  result = call_602995.call(nil, query_602996, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_602977(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_602978, base: "/",
    url: url_GetDescribeDBParameters_602979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_603037 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBSecurityGroups_603039(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSecurityGroups_603038(path: JsonNode; query: JsonNode;
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
  var valid_603040 = query.getOrDefault("Action")
  valid_603040 = validateParameter(valid_603040, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_603040 != nil:
    section.add "Action", valid_603040
  var valid_603041 = query.getOrDefault("Version")
  valid_603041 = validateParameter(valid_603041, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603041 != nil:
    section.add "Version", valid_603041
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603042 = header.getOrDefault("X-Amz-Signature")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Signature", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Content-Sha256", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-Date")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-Date", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Credential")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Credential", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Security-Token")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Security-Token", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Algorithm")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Algorithm", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-SignedHeaders", valid_603048
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603049 = formData.getOrDefault("DBSecurityGroupName")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "DBSecurityGroupName", valid_603049
  var valid_603050 = formData.getOrDefault("MaxRecords")
  valid_603050 = validateParameter(valid_603050, JInt, required = false, default = nil)
  if valid_603050 != nil:
    section.add "MaxRecords", valid_603050
  var valid_603051 = formData.getOrDefault("Marker")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "Marker", valid_603051
  var valid_603052 = formData.getOrDefault("Filters")
  valid_603052 = validateParameter(valid_603052, JArray, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "Filters", valid_603052
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603053: Call_PostDescribeDBSecurityGroups_603037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603053.validator(path, query, header, formData, body)
  let scheme = call_603053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603053.url(scheme.get, call_603053.host, call_603053.base,
                         call_603053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603053, url, valid)

proc call*(call_603054: Call_PostDescribeDBSecurityGroups_603037;
          DBSecurityGroupName: string = ""; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603055 = newJObject()
  var formData_603056 = newJObject()
  add(formData_603056, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_603056, "MaxRecords", newJInt(MaxRecords))
  add(formData_603056, "Marker", newJString(Marker))
  add(query_603055, "Action", newJString(Action))
  if Filters != nil:
    formData_603056.add "Filters", Filters
  add(query_603055, "Version", newJString(Version))
  result = call_603054.call(nil, query_603055, nil, formData_603056, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_603037(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_603038, base: "/",
    url: url_PostDescribeDBSecurityGroups_603039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_603018 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBSecurityGroups_603020(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSecurityGroups_603019(path: JsonNode; query: JsonNode;
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
  var valid_603021 = query.getOrDefault("Marker")
  valid_603021 = validateParameter(valid_603021, JString, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "Marker", valid_603021
  var valid_603022 = query.getOrDefault("DBSecurityGroupName")
  valid_603022 = validateParameter(valid_603022, JString, required = false,
                                 default = nil)
  if valid_603022 != nil:
    section.add "DBSecurityGroupName", valid_603022
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603023 = query.getOrDefault("Action")
  valid_603023 = validateParameter(valid_603023, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_603023 != nil:
    section.add "Action", valid_603023
  var valid_603024 = query.getOrDefault("Version")
  valid_603024 = validateParameter(valid_603024, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603024 != nil:
    section.add "Version", valid_603024
  var valid_603025 = query.getOrDefault("Filters")
  valid_603025 = validateParameter(valid_603025, JArray, required = false,
                                 default = nil)
  if valid_603025 != nil:
    section.add "Filters", valid_603025
  var valid_603026 = query.getOrDefault("MaxRecords")
  valid_603026 = validateParameter(valid_603026, JInt, required = false, default = nil)
  if valid_603026 != nil:
    section.add "MaxRecords", valid_603026
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603027 = header.getOrDefault("X-Amz-Signature")
  valid_603027 = validateParameter(valid_603027, JString, required = false,
                                 default = nil)
  if valid_603027 != nil:
    section.add "X-Amz-Signature", valid_603027
  var valid_603028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603028 = validateParameter(valid_603028, JString, required = false,
                                 default = nil)
  if valid_603028 != nil:
    section.add "X-Amz-Content-Sha256", valid_603028
  var valid_603029 = header.getOrDefault("X-Amz-Date")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "X-Amz-Date", valid_603029
  var valid_603030 = header.getOrDefault("X-Amz-Credential")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "X-Amz-Credential", valid_603030
  var valid_603031 = header.getOrDefault("X-Amz-Security-Token")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-Security-Token", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Algorithm")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Algorithm", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-SignedHeaders", valid_603033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603034: Call_GetDescribeDBSecurityGroups_603018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603034.validator(path, query, header, formData, body)
  let scheme = call_603034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603034.url(scheme.get, call_603034.host, call_603034.base,
                         call_603034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603034, url, valid)

proc call*(call_603035: Call_GetDescribeDBSecurityGroups_603018;
          Marker: string = ""; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Marker: string
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_603036 = newJObject()
  add(query_603036, "Marker", newJString(Marker))
  add(query_603036, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603036, "Action", newJString(Action))
  add(query_603036, "Version", newJString(Version))
  if Filters != nil:
    query_603036.add "Filters", Filters
  add(query_603036, "MaxRecords", newJInt(MaxRecords))
  result = call_603035.call(nil, query_603036, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_603018(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_603019, base: "/",
    url: url_GetDescribeDBSecurityGroups_603020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_603078 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBSnapshots_603080(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBSnapshots_603079(path: JsonNode; query: JsonNode;
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
  var valid_603081 = query.getOrDefault("Action")
  valid_603081 = validateParameter(valid_603081, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_603081 != nil:
    section.add "Action", valid_603081
  var valid_603082 = query.getOrDefault("Version")
  valid_603082 = validateParameter(valid_603082, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603082 != nil:
    section.add "Version", valid_603082
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603083 = header.getOrDefault("X-Amz-Signature")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Signature", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Content-Sha256", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Date")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Date", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Credential")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Credential", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Security-Token")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Security-Token", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Algorithm")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Algorithm", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-SignedHeaders", valid_603089
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603090 = formData.getOrDefault("SnapshotType")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "SnapshotType", valid_603090
  var valid_603091 = formData.getOrDefault("MaxRecords")
  valid_603091 = validateParameter(valid_603091, JInt, required = false, default = nil)
  if valid_603091 != nil:
    section.add "MaxRecords", valid_603091
  var valid_603092 = formData.getOrDefault("Marker")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "Marker", valid_603092
  var valid_603093 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "DBInstanceIdentifier", valid_603093
  var valid_603094 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "DBSnapshotIdentifier", valid_603094
  var valid_603095 = formData.getOrDefault("Filters")
  valid_603095 = validateParameter(valid_603095, JArray, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "Filters", valid_603095
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603096: Call_PostDescribeDBSnapshots_603078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603096.validator(path, query, header, formData, body)
  let scheme = call_603096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603096.url(scheme.get, call_603096.host, call_603096.base,
                         call_603096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603096, url, valid)

proc call*(call_603097: Call_PostDescribeDBSnapshots_603078;
          SnapshotType: string = ""; MaxRecords: int = 0; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSnapshots
  ##   SnapshotType: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603098 = newJObject()
  var formData_603099 = newJObject()
  add(formData_603099, "SnapshotType", newJString(SnapshotType))
  add(formData_603099, "MaxRecords", newJInt(MaxRecords))
  add(formData_603099, "Marker", newJString(Marker))
  add(formData_603099, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603099, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603098, "Action", newJString(Action))
  if Filters != nil:
    formData_603099.add "Filters", Filters
  add(query_603098, "Version", newJString(Version))
  result = call_603097.call(nil, query_603098, nil, formData_603099, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_603078(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_603079, base: "/",
    url: url_PostDescribeDBSnapshots_603080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_603057 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBSnapshots_603059(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBSnapshots_603058(path: JsonNode; query: JsonNode;
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
  var valid_603060 = query.getOrDefault("Marker")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "Marker", valid_603060
  var valid_603061 = query.getOrDefault("DBInstanceIdentifier")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "DBInstanceIdentifier", valid_603061
  var valid_603062 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "DBSnapshotIdentifier", valid_603062
  var valid_603063 = query.getOrDefault("SnapshotType")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "SnapshotType", valid_603063
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603064 = query.getOrDefault("Action")
  valid_603064 = validateParameter(valid_603064, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_603064 != nil:
    section.add "Action", valid_603064
  var valid_603065 = query.getOrDefault("Version")
  valid_603065 = validateParameter(valid_603065, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603065 != nil:
    section.add "Version", valid_603065
  var valid_603066 = query.getOrDefault("Filters")
  valid_603066 = validateParameter(valid_603066, JArray, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "Filters", valid_603066
  var valid_603067 = query.getOrDefault("MaxRecords")
  valid_603067 = validateParameter(valid_603067, JInt, required = false, default = nil)
  if valid_603067 != nil:
    section.add "MaxRecords", valid_603067
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603068 = header.getOrDefault("X-Amz-Signature")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Signature", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Content-Sha256", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Date")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Date", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Credential")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Credential", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-Security-Token")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Security-Token", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Algorithm")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Algorithm", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-SignedHeaders", valid_603074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603075: Call_GetDescribeDBSnapshots_603057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603075.validator(path, query, header, formData, body)
  let scheme = call_603075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603075.url(scheme.get, call_603075.host, call_603075.base,
                         call_603075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603075, url, valid)

proc call*(call_603076: Call_GetDescribeDBSnapshots_603057; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          SnapshotType: string = ""; Action: string = "DescribeDBSnapshots";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSnapshots
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   SnapshotType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_603077 = newJObject()
  add(query_603077, "Marker", newJString(Marker))
  add(query_603077, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603077, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603077, "SnapshotType", newJString(SnapshotType))
  add(query_603077, "Action", newJString(Action))
  add(query_603077, "Version", newJString(Version))
  if Filters != nil:
    query_603077.add "Filters", Filters
  add(query_603077, "MaxRecords", newJInt(MaxRecords))
  result = call_603076.call(nil, query_603077, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_603057(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_603058, base: "/",
    url: url_GetDescribeDBSnapshots_603059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_603119 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBSubnetGroups_603121(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSubnetGroups_603120(path: JsonNode; query: JsonNode;
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
  var valid_603122 = query.getOrDefault("Action")
  valid_603122 = validateParameter(valid_603122, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_603122 != nil:
    section.add "Action", valid_603122
  var valid_603123 = query.getOrDefault("Version")
  valid_603123 = validateParameter(valid_603123, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603123 != nil:
    section.add "Version", valid_603123
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603124 = header.getOrDefault("X-Amz-Signature")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Signature", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Content-Sha256", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Date")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Date", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Security-Token")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Security-Token", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Algorithm")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Algorithm", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-SignedHeaders", valid_603130
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603131 = formData.getOrDefault("MaxRecords")
  valid_603131 = validateParameter(valid_603131, JInt, required = false, default = nil)
  if valid_603131 != nil:
    section.add "MaxRecords", valid_603131
  var valid_603132 = formData.getOrDefault("Marker")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "Marker", valid_603132
  var valid_603133 = formData.getOrDefault("DBSubnetGroupName")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "DBSubnetGroupName", valid_603133
  var valid_603134 = formData.getOrDefault("Filters")
  valid_603134 = validateParameter(valid_603134, JArray, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "Filters", valid_603134
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603135: Call_PostDescribeDBSubnetGroups_603119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603135.validator(path, query, header, formData, body)
  let scheme = call_603135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603135.url(scheme.get, call_603135.host, call_603135.base,
                         call_603135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603135, url, valid)

proc call*(call_603136: Call_PostDescribeDBSubnetGroups_603119;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603137 = newJObject()
  var formData_603138 = newJObject()
  add(formData_603138, "MaxRecords", newJInt(MaxRecords))
  add(formData_603138, "Marker", newJString(Marker))
  add(query_603137, "Action", newJString(Action))
  add(formData_603138, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_603138.add "Filters", Filters
  add(query_603137, "Version", newJString(Version))
  result = call_603136.call(nil, query_603137, nil, formData_603138, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_603119(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_603120, base: "/",
    url: url_PostDescribeDBSubnetGroups_603121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_603100 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBSubnetGroups_603102(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSubnetGroups_603101(path: JsonNode; query: JsonNode;
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
  var valid_603103 = query.getOrDefault("Marker")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "Marker", valid_603103
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603104 = query.getOrDefault("Action")
  valid_603104 = validateParameter(valid_603104, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_603104 != nil:
    section.add "Action", valid_603104
  var valid_603105 = query.getOrDefault("DBSubnetGroupName")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "DBSubnetGroupName", valid_603105
  var valid_603106 = query.getOrDefault("Version")
  valid_603106 = validateParameter(valid_603106, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603106 != nil:
    section.add "Version", valid_603106
  var valid_603107 = query.getOrDefault("Filters")
  valid_603107 = validateParameter(valid_603107, JArray, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "Filters", valid_603107
  var valid_603108 = query.getOrDefault("MaxRecords")
  valid_603108 = validateParameter(valid_603108, JInt, required = false, default = nil)
  if valid_603108 != nil:
    section.add "MaxRecords", valid_603108
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603116: Call_GetDescribeDBSubnetGroups_603100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603116.validator(path, query, header, formData, body)
  let scheme = call_603116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603116.url(scheme.get, call_603116.host, call_603116.base,
                         call_603116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603116, url, valid)

proc call*(call_603117: Call_GetDescribeDBSubnetGroups_603100; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_603118 = newJObject()
  add(query_603118, "Marker", newJString(Marker))
  add(query_603118, "Action", newJString(Action))
  add(query_603118, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603118, "Version", newJString(Version))
  if Filters != nil:
    query_603118.add "Filters", Filters
  add(query_603118, "MaxRecords", newJInt(MaxRecords))
  result = call_603117.call(nil, query_603118, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_603100(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_603101, base: "/",
    url: url_GetDescribeDBSubnetGroups_603102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_603158 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEngineDefaultParameters_603160(protocol: Scheme; host: string;
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

proc validate_PostDescribeEngineDefaultParameters_603159(path: JsonNode;
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
  var valid_603161 = query.getOrDefault("Action")
  valid_603161 = validateParameter(valid_603161, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_603161 != nil:
    section.add "Action", valid_603161
  var valid_603162 = query.getOrDefault("Version")
  valid_603162 = validateParameter(valid_603162, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603162 != nil:
    section.add "Version", valid_603162
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603163 = header.getOrDefault("X-Amz-Signature")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Signature", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Content-Sha256", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Credential")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Credential", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Security-Token")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Security-Token", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Algorithm")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Algorithm", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-SignedHeaders", valid_603169
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_603170 = formData.getOrDefault("MaxRecords")
  valid_603170 = validateParameter(valid_603170, JInt, required = false, default = nil)
  if valid_603170 != nil:
    section.add "MaxRecords", valid_603170
  var valid_603171 = formData.getOrDefault("Marker")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "Marker", valid_603171
  var valid_603172 = formData.getOrDefault("Filters")
  valid_603172 = validateParameter(valid_603172, JArray, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "Filters", valid_603172
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_603173 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603173 = validateParameter(valid_603173, JString, required = true,
                                 default = nil)
  if valid_603173 != nil:
    section.add "DBParameterGroupFamily", valid_603173
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_PostDescribeEngineDefaultParameters_603158;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603174, url, valid)

proc call*(call_603175: Call_PostDescribeEngineDefaultParameters_603158;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_603176 = newJObject()
  var formData_603177 = newJObject()
  add(formData_603177, "MaxRecords", newJInt(MaxRecords))
  add(formData_603177, "Marker", newJString(Marker))
  add(query_603176, "Action", newJString(Action))
  if Filters != nil:
    formData_603177.add "Filters", Filters
  add(query_603176, "Version", newJString(Version))
  add(formData_603177, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_603175.call(nil, query_603176, nil, formData_603177, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_603158(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_603159, base: "/",
    url: url_PostDescribeEngineDefaultParameters_603160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_603139 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEngineDefaultParameters_603141(protocol: Scheme; host: string;
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

proc validate_GetDescribeEngineDefaultParameters_603140(path: JsonNode;
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
  var valid_603142 = query.getOrDefault("Marker")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "Marker", valid_603142
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_603143 = query.getOrDefault("DBParameterGroupFamily")
  valid_603143 = validateParameter(valid_603143, JString, required = true,
                                 default = nil)
  if valid_603143 != nil:
    section.add "DBParameterGroupFamily", valid_603143
  var valid_603144 = query.getOrDefault("Action")
  valid_603144 = validateParameter(valid_603144, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_603144 != nil:
    section.add "Action", valid_603144
  var valid_603145 = query.getOrDefault("Version")
  valid_603145 = validateParameter(valid_603145, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603145 != nil:
    section.add "Version", valid_603145
  var valid_603146 = query.getOrDefault("Filters")
  valid_603146 = validateParameter(valid_603146, JArray, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "Filters", valid_603146
  var valid_603147 = query.getOrDefault("MaxRecords")
  valid_603147 = validateParameter(valid_603147, JInt, required = false, default = nil)
  if valid_603147 != nil:
    section.add "MaxRecords", valid_603147
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603148 = header.getOrDefault("X-Amz-Signature")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Signature", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Content-Sha256", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Credential")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Credential", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Security-Token")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Security-Token", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Algorithm")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Algorithm", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-SignedHeaders", valid_603154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603155: Call_GetDescribeEngineDefaultParameters_603139;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603155.validator(path, query, header, formData, body)
  let scheme = call_603155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603155.url(scheme.get, call_603155.host, call_603155.base,
                         call_603155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603155, url, valid)

proc call*(call_603156: Call_GetDescribeEngineDefaultParameters_603139;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_603157 = newJObject()
  add(query_603157, "Marker", newJString(Marker))
  add(query_603157, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_603157, "Action", newJString(Action))
  add(query_603157, "Version", newJString(Version))
  if Filters != nil:
    query_603157.add "Filters", Filters
  add(query_603157, "MaxRecords", newJInt(MaxRecords))
  result = call_603156.call(nil, query_603157, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_603139(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_603140, base: "/",
    url: url_GetDescribeEngineDefaultParameters_603141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_603195 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEventCategories_603197(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventCategories_603196(path: JsonNode; query: JsonNode;
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
  var valid_603198 = query.getOrDefault("Action")
  valid_603198 = validateParameter(valid_603198, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_603198 != nil:
    section.add "Action", valid_603198
  var valid_603199 = query.getOrDefault("Version")
  valid_603199 = validateParameter(valid_603199, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603199 != nil:
    section.add "Version", valid_603199
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Content-Sha256", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Date")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Date", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Credential")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Credential", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Security-Token")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Security-Token", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Algorithm")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Algorithm", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-SignedHeaders", valid_603206
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603207 = formData.getOrDefault("SourceType")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "SourceType", valid_603207
  var valid_603208 = formData.getOrDefault("Filters")
  valid_603208 = validateParameter(valid_603208, JArray, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "Filters", valid_603208
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603209: Call_PostDescribeEventCategories_603195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603209.validator(path, query, header, formData, body)
  let scheme = call_603209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603209.url(scheme.get, call_603209.host, call_603209.base,
                         call_603209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603209, url, valid)

proc call*(call_603210: Call_PostDescribeEventCategories_603195;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603211 = newJObject()
  var formData_603212 = newJObject()
  add(formData_603212, "SourceType", newJString(SourceType))
  add(query_603211, "Action", newJString(Action))
  if Filters != nil:
    formData_603212.add "Filters", Filters
  add(query_603211, "Version", newJString(Version))
  result = call_603210.call(nil, query_603211, nil, formData_603212, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_603195(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_603196, base: "/",
    url: url_PostDescribeEventCategories_603197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_603178 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEventCategories_603180(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventCategories_603179(path: JsonNode; query: JsonNode;
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
  var valid_603181 = query.getOrDefault("SourceType")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "SourceType", valid_603181
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603182 = query.getOrDefault("Action")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_603182 != nil:
    section.add "Action", valid_603182
  var valid_603183 = query.getOrDefault("Version")
  valid_603183 = validateParameter(valid_603183, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603183 != nil:
    section.add "Version", valid_603183
  var valid_603184 = query.getOrDefault("Filters")
  valid_603184 = validateParameter(valid_603184, JArray, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "Filters", valid_603184
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Content-Sha256", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Date")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Date", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Credential")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Credential", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Security-Token")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Security-Token", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Algorithm")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Algorithm", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-SignedHeaders", valid_603191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603192: Call_GetDescribeEventCategories_603178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603192.validator(path, query, header, formData, body)
  let scheme = call_603192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603192.url(scheme.get, call_603192.host, call_603192.base,
                         call_603192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603192, url, valid)

proc call*(call_603193: Call_GetDescribeEventCategories_603178;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2014-09-01"; Filters: JsonNode = nil): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_603194 = newJObject()
  add(query_603194, "SourceType", newJString(SourceType))
  add(query_603194, "Action", newJString(Action))
  add(query_603194, "Version", newJString(Version))
  if Filters != nil:
    query_603194.add "Filters", Filters
  result = call_603193.call(nil, query_603194, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_603178(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_603179, base: "/",
    url: url_GetDescribeEventCategories_603180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_603232 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEventSubscriptions_603234(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventSubscriptions_603233(path: JsonNode;
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
  var valid_603235 = query.getOrDefault("Action")
  valid_603235 = validateParameter(valid_603235, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_603235 != nil:
    section.add "Action", valid_603235
  var valid_603236 = query.getOrDefault("Version")
  valid_603236 = validateParameter(valid_603236, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603236 != nil:
    section.add "Version", valid_603236
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603237 = header.getOrDefault("X-Amz-Signature")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Signature", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Content-Sha256", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Date")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Date", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Credential")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Credential", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Algorithm")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Algorithm", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-SignedHeaders", valid_603243
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603244 = formData.getOrDefault("MaxRecords")
  valid_603244 = validateParameter(valid_603244, JInt, required = false, default = nil)
  if valid_603244 != nil:
    section.add "MaxRecords", valid_603244
  var valid_603245 = formData.getOrDefault("Marker")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "Marker", valid_603245
  var valid_603246 = formData.getOrDefault("SubscriptionName")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "SubscriptionName", valid_603246
  var valid_603247 = formData.getOrDefault("Filters")
  valid_603247 = validateParameter(valid_603247, JArray, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "Filters", valid_603247
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603248: Call_PostDescribeEventSubscriptions_603232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603248.validator(path, query, header, formData, body)
  let scheme = call_603248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603248.url(scheme.get, call_603248.host, call_603248.base,
                         call_603248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603248, url, valid)

proc call*(call_603249: Call_PostDescribeEventSubscriptions_603232;
          MaxRecords: int = 0; Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603250 = newJObject()
  var formData_603251 = newJObject()
  add(formData_603251, "MaxRecords", newJInt(MaxRecords))
  add(formData_603251, "Marker", newJString(Marker))
  add(formData_603251, "SubscriptionName", newJString(SubscriptionName))
  add(query_603250, "Action", newJString(Action))
  if Filters != nil:
    formData_603251.add "Filters", Filters
  add(query_603250, "Version", newJString(Version))
  result = call_603249.call(nil, query_603250, nil, formData_603251, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_603232(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_603233, base: "/",
    url: url_PostDescribeEventSubscriptions_603234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_603213 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEventSubscriptions_603215(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventSubscriptions_603214(path: JsonNode; query: JsonNode;
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
  var valid_603216 = query.getOrDefault("Marker")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "Marker", valid_603216
  var valid_603217 = query.getOrDefault("SubscriptionName")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "SubscriptionName", valid_603217
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603218 = query.getOrDefault("Action")
  valid_603218 = validateParameter(valid_603218, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_603218 != nil:
    section.add "Action", valid_603218
  var valid_603219 = query.getOrDefault("Version")
  valid_603219 = validateParameter(valid_603219, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603219 != nil:
    section.add "Version", valid_603219
  var valid_603220 = query.getOrDefault("Filters")
  valid_603220 = validateParameter(valid_603220, JArray, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "Filters", valid_603220
  var valid_603221 = query.getOrDefault("MaxRecords")
  valid_603221 = validateParameter(valid_603221, JInt, required = false, default = nil)
  if valid_603221 != nil:
    section.add "MaxRecords", valid_603221
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603222 = header.getOrDefault("X-Amz-Signature")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Signature", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Content-Sha256", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Date")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Date", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Credential")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Credential", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Algorithm")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Algorithm", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-SignedHeaders", valid_603228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603229: Call_GetDescribeEventSubscriptions_603213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603229.validator(path, query, header, formData, body)
  let scheme = call_603229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603229.url(scheme.get, call_603229.host, call_603229.base,
                         call_603229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603229, url, valid)

proc call*(call_603230: Call_GetDescribeEventSubscriptions_603213;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_603231 = newJObject()
  add(query_603231, "Marker", newJString(Marker))
  add(query_603231, "SubscriptionName", newJString(SubscriptionName))
  add(query_603231, "Action", newJString(Action))
  add(query_603231, "Version", newJString(Version))
  if Filters != nil:
    query_603231.add "Filters", Filters
  add(query_603231, "MaxRecords", newJInt(MaxRecords))
  result = call_603230.call(nil, query_603231, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_603213(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_603214, base: "/",
    url: url_GetDescribeEventSubscriptions_603215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_603276 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEvents_603278(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_603277(path: JsonNode; query: JsonNode;
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
  var valid_603279 = query.getOrDefault("Action")
  valid_603279 = validateParameter(valid_603279, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_603279 != nil:
    section.add "Action", valid_603279
  var valid_603280 = query.getOrDefault("Version")
  valid_603280 = validateParameter(valid_603280, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603280 != nil:
    section.add "Version", valid_603280
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603281 = header.getOrDefault("X-Amz-Signature")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Signature", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Content-Sha256", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Date")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Date", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Credential")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Credential", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Security-Token")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Security-Token", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Algorithm")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Algorithm", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-SignedHeaders", valid_603287
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
  var valid_603288 = formData.getOrDefault("MaxRecords")
  valid_603288 = validateParameter(valid_603288, JInt, required = false, default = nil)
  if valid_603288 != nil:
    section.add "MaxRecords", valid_603288
  var valid_603289 = formData.getOrDefault("Marker")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "Marker", valid_603289
  var valid_603290 = formData.getOrDefault("SourceIdentifier")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "SourceIdentifier", valid_603290
  var valid_603291 = formData.getOrDefault("SourceType")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_603291 != nil:
    section.add "SourceType", valid_603291
  var valid_603292 = formData.getOrDefault("Duration")
  valid_603292 = validateParameter(valid_603292, JInt, required = false, default = nil)
  if valid_603292 != nil:
    section.add "Duration", valid_603292
  var valid_603293 = formData.getOrDefault("EndTime")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "EndTime", valid_603293
  var valid_603294 = formData.getOrDefault("StartTime")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "StartTime", valid_603294
  var valid_603295 = formData.getOrDefault("EventCategories")
  valid_603295 = validateParameter(valid_603295, JArray, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "EventCategories", valid_603295
  var valid_603296 = formData.getOrDefault("Filters")
  valid_603296 = validateParameter(valid_603296, JArray, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "Filters", valid_603296
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603297: Call_PostDescribeEvents_603276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603297.validator(path, query, header, formData, body)
  let scheme = call_603297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603297.url(scheme.get, call_603297.host, call_603297.base,
                         call_603297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603297, url, valid)

proc call*(call_603298: Call_PostDescribeEvents_603276; MaxRecords: int = 0;
          Marker: string = ""; SourceIdentifier: string = "";
          SourceType: string = "db-instance"; Duration: int = 0; EndTime: string = "";
          StartTime: string = ""; EventCategories: JsonNode = nil;
          Action: string = "DescribeEvents"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
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
  var query_603299 = newJObject()
  var formData_603300 = newJObject()
  add(formData_603300, "MaxRecords", newJInt(MaxRecords))
  add(formData_603300, "Marker", newJString(Marker))
  add(formData_603300, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_603300, "SourceType", newJString(SourceType))
  add(formData_603300, "Duration", newJInt(Duration))
  add(formData_603300, "EndTime", newJString(EndTime))
  add(formData_603300, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_603300.add "EventCategories", EventCategories
  add(query_603299, "Action", newJString(Action))
  if Filters != nil:
    formData_603300.add "Filters", Filters
  add(query_603299, "Version", newJString(Version))
  result = call_603298.call(nil, query_603299, nil, formData_603300, nil)

var postDescribeEvents* = Call_PostDescribeEvents_603276(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_603277, base: "/",
    url: url_PostDescribeEvents_603278, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_603252 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEvents_603254(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_603253(path: JsonNode; query: JsonNode;
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
  var valid_603255 = query.getOrDefault("Marker")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "Marker", valid_603255
  var valid_603256 = query.getOrDefault("SourceType")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_603256 != nil:
    section.add "SourceType", valid_603256
  var valid_603257 = query.getOrDefault("SourceIdentifier")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "SourceIdentifier", valid_603257
  var valid_603258 = query.getOrDefault("EventCategories")
  valid_603258 = validateParameter(valid_603258, JArray, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "EventCategories", valid_603258
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603259 = query.getOrDefault("Action")
  valid_603259 = validateParameter(valid_603259, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_603259 != nil:
    section.add "Action", valid_603259
  var valid_603260 = query.getOrDefault("StartTime")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "StartTime", valid_603260
  var valid_603261 = query.getOrDefault("Duration")
  valid_603261 = validateParameter(valid_603261, JInt, required = false, default = nil)
  if valid_603261 != nil:
    section.add "Duration", valid_603261
  var valid_603262 = query.getOrDefault("EndTime")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "EndTime", valid_603262
  var valid_603263 = query.getOrDefault("Version")
  valid_603263 = validateParameter(valid_603263, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603266 = header.getOrDefault("X-Amz-Signature")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Signature", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Content-Sha256", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Date")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Date", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Credential")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Credential", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Security-Token")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Security-Token", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Algorithm")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Algorithm", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-SignedHeaders", valid_603272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603273: Call_GetDescribeEvents_603252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603273.validator(path, query, header, formData, body)
  let scheme = call_603273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603273.url(scheme.get, call_603273.host, call_603273.base,
                         call_603273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603273, url, valid)

proc call*(call_603274: Call_GetDescribeEvents_603252; Marker: string = "";
          SourceType: string = "db-instance"; SourceIdentifier: string = "";
          EventCategories: JsonNode = nil; Action: string = "DescribeEvents";
          StartTime: string = ""; Duration: int = 0; EndTime: string = "";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
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
  var query_603275 = newJObject()
  add(query_603275, "Marker", newJString(Marker))
  add(query_603275, "SourceType", newJString(SourceType))
  add(query_603275, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_603275.add "EventCategories", EventCategories
  add(query_603275, "Action", newJString(Action))
  add(query_603275, "StartTime", newJString(StartTime))
  add(query_603275, "Duration", newJInt(Duration))
  add(query_603275, "EndTime", newJString(EndTime))
  add(query_603275, "Version", newJString(Version))
  if Filters != nil:
    query_603275.add "Filters", Filters
  add(query_603275, "MaxRecords", newJInt(MaxRecords))
  result = call_603274.call(nil, query_603275, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_603252(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_603253,
    base: "/", url: url_GetDescribeEvents_603254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_603321 = ref object of OpenApiRestCall_601373
proc url_PostDescribeOptionGroupOptions_603323(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroupOptions_603322(path: JsonNode;
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
  var valid_603324 = query.getOrDefault("Action")
  valid_603324 = validateParameter(valid_603324, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_603324 != nil:
    section.add "Action", valid_603324
  var valid_603325 = query.getOrDefault("Version")
  valid_603325 = validateParameter(valid_603325, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603325 != nil:
    section.add "Version", valid_603325
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603326 = header.getOrDefault("X-Amz-Signature")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Signature", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Content-Sha256", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Date")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Date", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Credential")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Credential", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Security-Token")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Security-Token", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Algorithm")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Algorithm", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-SignedHeaders", valid_603332
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603333 = formData.getOrDefault("MaxRecords")
  valid_603333 = validateParameter(valid_603333, JInt, required = false, default = nil)
  if valid_603333 != nil:
    section.add "MaxRecords", valid_603333
  var valid_603334 = formData.getOrDefault("Marker")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "Marker", valid_603334
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_603335 = formData.getOrDefault("EngineName")
  valid_603335 = validateParameter(valid_603335, JString, required = true,
                                 default = nil)
  if valid_603335 != nil:
    section.add "EngineName", valid_603335
  var valid_603336 = formData.getOrDefault("MajorEngineVersion")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "MajorEngineVersion", valid_603336
  var valid_603337 = formData.getOrDefault("Filters")
  valid_603337 = validateParameter(valid_603337, JArray, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "Filters", valid_603337
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603338: Call_PostDescribeOptionGroupOptions_603321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603338.validator(path, query, header, formData, body)
  let scheme = call_603338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603338.url(scheme.get, call_603338.host, call_603338.base,
                         call_603338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603338, url, valid)

proc call*(call_603339: Call_PostDescribeOptionGroupOptions_603321;
          EngineName: string; MaxRecords: int = 0; Marker: string = "";
          MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroupOptions"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603340 = newJObject()
  var formData_603341 = newJObject()
  add(formData_603341, "MaxRecords", newJInt(MaxRecords))
  add(formData_603341, "Marker", newJString(Marker))
  add(formData_603341, "EngineName", newJString(EngineName))
  add(formData_603341, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_603340, "Action", newJString(Action))
  if Filters != nil:
    formData_603341.add "Filters", Filters
  add(query_603340, "Version", newJString(Version))
  result = call_603339.call(nil, query_603340, nil, formData_603341, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_603321(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_603322, base: "/",
    url: url_PostDescribeOptionGroupOptions_603323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_603301 = ref object of OpenApiRestCall_601373
proc url_GetDescribeOptionGroupOptions_603303(protocol: Scheme; host: string;
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

proc validate_GetDescribeOptionGroupOptions_603302(path: JsonNode; query: JsonNode;
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
  var valid_603304 = query.getOrDefault("EngineName")
  valid_603304 = validateParameter(valid_603304, JString, required = true,
                                 default = nil)
  if valid_603304 != nil:
    section.add "EngineName", valid_603304
  var valid_603305 = query.getOrDefault("Marker")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "Marker", valid_603305
  var valid_603306 = query.getOrDefault("Action")
  valid_603306 = validateParameter(valid_603306, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_603306 != nil:
    section.add "Action", valid_603306
  var valid_603307 = query.getOrDefault("Version")
  valid_603307 = validateParameter(valid_603307, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603307 != nil:
    section.add "Version", valid_603307
  var valid_603308 = query.getOrDefault("Filters")
  valid_603308 = validateParameter(valid_603308, JArray, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "Filters", valid_603308
  var valid_603309 = query.getOrDefault("MaxRecords")
  valid_603309 = validateParameter(valid_603309, JInt, required = false, default = nil)
  if valid_603309 != nil:
    section.add "MaxRecords", valid_603309
  var valid_603310 = query.getOrDefault("MajorEngineVersion")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "MajorEngineVersion", valid_603310
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603311 = header.getOrDefault("X-Amz-Signature")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Signature", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Content-Sha256", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Date")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Date", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Credential")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Credential", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Security-Token")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Security-Token", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Algorithm")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Algorithm", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-SignedHeaders", valid_603317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603318: Call_GetDescribeOptionGroupOptions_603301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603318.validator(path, query, header, formData, body)
  let scheme = call_603318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603318.url(scheme.get, call_603318.host, call_603318.base,
                         call_603318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603318, url, valid)

proc call*(call_603319: Call_GetDescribeOptionGroupOptions_603301;
          EngineName: string; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   EngineName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_603320 = newJObject()
  add(query_603320, "EngineName", newJString(EngineName))
  add(query_603320, "Marker", newJString(Marker))
  add(query_603320, "Action", newJString(Action))
  add(query_603320, "Version", newJString(Version))
  if Filters != nil:
    query_603320.add "Filters", Filters
  add(query_603320, "MaxRecords", newJInt(MaxRecords))
  add(query_603320, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_603319.call(nil, query_603320, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_603301(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_603302, base: "/",
    url: url_GetDescribeOptionGroupOptions_603303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_603363 = ref object of OpenApiRestCall_601373
proc url_PostDescribeOptionGroups_603365(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroups_603364(path: JsonNode; query: JsonNode;
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
  var valid_603366 = query.getOrDefault("Action")
  valid_603366 = validateParameter(valid_603366, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_603366 != nil:
    section.add "Action", valid_603366
  var valid_603367 = query.getOrDefault("Version")
  valid_603367 = validateParameter(valid_603367, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603367 != nil:
    section.add "Version", valid_603367
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603368 = header.getOrDefault("X-Amz-Signature")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Signature", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Content-Sha256", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Date")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Date", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Credential")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Credential", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Security-Token")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Security-Token", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Algorithm")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Algorithm", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-SignedHeaders", valid_603374
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_603375 = formData.getOrDefault("MaxRecords")
  valid_603375 = validateParameter(valid_603375, JInt, required = false, default = nil)
  if valid_603375 != nil:
    section.add "MaxRecords", valid_603375
  var valid_603376 = formData.getOrDefault("Marker")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "Marker", valid_603376
  var valid_603377 = formData.getOrDefault("EngineName")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "EngineName", valid_603377
  var valid_603378 = formData.getOrDefault("MajorEngineVersion")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "MajorEngineVersion", valid_603378
  var valid_603379 = formData.getOrDefault("OptionGroupName")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "OptionGroupName", valid_603379
  var valid_603380 = formData.getOrDefault("Filters")
  valid_603380 = validateParameter(valid_603380, JArray, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "Filters", valid_603380
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603381: Call_PostDescribeOptionGroups_603363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603381.validator(path, query, header, formData, body)
  let scheme = call_603381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603381.url(scheme.get, call_603381.host, call_603381.base,
                         call_603381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603381, url, valid)

proc call*(call_603382: Call_PostDescribeOptionGroups_603363; MaxRecords: int = 0;
          Marker: string = ""; EngineName: string = ""; MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeOptionGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_603383 = newJObject()
  var formData_603384 = newJObject()
  add(formData_603384, "MaxRecords", newJInt(MaxRecords))
  add(formData_603384, "Marker", newJString(Marker))
  add(formData_603384, "EngineName", newJString(EngineName))
  add(formData_603384, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_603383, "Action", newJString(Action))
  add(formData_603384, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    formData_603384.add "Filters", Filters
  add(query_603383, "Version", newJString(Version))
  result = call_603382.call(nil, query_603383, nil, formData_603384, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_603363(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_603364, base: "/",
    url: url_PostDescribeOptionGroups_603365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_603342 = ref object of OpenApiRestCall_601373
proc url_GetDescribeOptionGroups_603344(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeOptionGroups_603343(path: JsonNode; query: JsonNode;
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
  var valid_603345 = query.getOrDefault("EngineName")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "EngineName", valid_603345
  var valid_603346 = query.getOrDefault("Marker")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "Marker", valid_603346
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603347 = query.getOrDefault("Action")
  valid_603347 = validateParameter(valid_603347, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_603347 != nil:
    section.add "Action", valid_603347
  var valid_603348 = query.getOrDefault("OptionGroupName")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "OptionGroupName", valid_603348
  var valid_603349 = query.getOrDefault("Version")
  valid_603349 = validateParameter(valid_603349, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603349 != nil:
    section.add "Version", valid_603349
  var valid_603350 = query.getOrDefault("Filters")
  valid_603350 = validateParameter(valid_603350, JArray, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "Filters", valid_603350
  var valid_603351 = query.getOrDefault("MaxRecords")
  valid_603351 = validateParameter(valid_603351, JInt, required = false, default = nil)
  if valid_603351 != nil:
    section.add "MaxRecords", valid_603351
  var valid_603352 = query.getOrDefault("MajorEngineVersion")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "MajorEngineVersion", valid_603352
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603353 = header.getOrDefault("X-Amz-Signature")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Signature", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Content-Sha256", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Date")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Date", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Credential")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Credential", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Security-Token")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Security-Token", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Algorithm")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Algorithm", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-SignedHeaders", valid_603359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603360: Call_GetDescribeOptionGroups_603342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603360.validator(path, query, header, formData, body)
  let scheme = call_603360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603360.url(scheme.get, call_603360.host, call_603360.base,
                         call_603360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603360, url, valid)

proc call*(call_603361: Call_GetDescribeOptionGroups_603342;
          EngineName: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0;
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
  var query_603362 = newJObject()
  add(query_603362, "EngineName", newJString(EngineName))
  add(query_603362, "Marker", newJString(Marker))
  add(query_603362, "Action", newJString(Action))
  add(query_603362, "OptionGroupName", newJString(OptionGroupName))
  add(query_603362, "Version", newJString(Version))
  if Filters != nil:
    query_603362.add "Filters", Filters
  add(query_603362, "MaxRecords", newJInt(MaxRecords))
  add(query_603362, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_603361.call(nil, query_603362, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_603342(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_603343, base: "/",
    url: url_GetDescribeOptionGroups_603344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_603408 = ref object of OpenApiRestCall_601373
proc url_PostDescribeOrderableDBInstanceOptions_603410(protocol: Scheme;
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

proc validate_PostDescribeOrderableDBInstanceOptions_603409(path: JsonNode;
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
  var valid_603411 = query.getOrDefault("Action")
  valid_603411 = validateParameter(valid_603411, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_603411 != nil:
    section.add "Action", valid_603411
  var valid_603412 = query.getOrDefault("Version")
  valid_603412 = validateParameter(valid_603412, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603412 != nil:
    section.add "Version", valid_603412
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603413 = header.getOrDefault("X-Amz-Signature")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Signature", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Content-Sha256", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Date")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Date", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Credential")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Credential", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Security-Token")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Security-Token", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Algorithm")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Algorithm", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-SignedHeaders", valid_603419
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
  var valid_603420 = formData.getOrDefault("DBInstanceClass")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "DBInstanceClass", valid_603420
  var valid_603421 = formData.getOrDefault("MaxRecords")
  valid_603421 = validateParameter(valid_603421, JInt, required = false, default = nil)
  if valid_603421 != nil:
    section.add "MaxRecords", valid_603421
  var valid_603422 = formData.getOrDefault("EngineVersion")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "EngineVersion", valid_603422
  var valid_603423 = formData.getOrDefault("Marker")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "Marker", valid_603423
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_603424 = formData.getOrDefault("Engine")
  valid_603424 = validateParameter(valid_603424, JString, required = true,
                                 default = nil)
  if valid_603424 != nil:
    section.add "Engine", valid_603424
  var valid_603425 = formData.getOrDefault("Vpc")
  valid_603425 = validateParameter(valid_603425, JBool, required = false, default = nil)
  if valid_603425 != nil:
    section.add "Vpc", valid_603425
  var valid_603426 = formData.getOrDefault("LicenseModel")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "LicenseModel", valid_603426
  var valid_603427 = formData.getOrDefault("Filters")
  valid_603427 = validateParameter(valid_603427, JArray, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "Filters", valid_603427
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603428: Call_PostDescribeOrderableDBInstanceOptions_603408;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603428.validator(path, query, header, formData, body)
  let scheme = call_603428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603428.url(scheme.get, call_603428.host, call_603428.base,
                         call_603428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603428, url, valid)

proc call*(call_603429: Call_PostDescribeOrderableDBInstanceOptions_603408;
          Engine: string; DBInstanceClass: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Marker: string = ""; Vpc: bool = false;
          Action: string = "DescribeOrderableDBInstanceOptions";
          LicenseModel: string = ""; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
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
  var query_603430 = newJObject()
  var formData_603431 = newJObject()
  add(formData_603431, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603431, "MaxRecords", newJInt(MaxRecords))
  add(formData_603431, "EngineVersion", newJString(EngineVersion))
  add(formData_603431, "Marker", newJString(Marker))
  add(formData_603431, "Engine", newJString(Engine))
  add(formData_603431, "Vpc", newJBool(Vpc))
  add(query_603430, "Action", newJString(Action))
  add(formData_603431, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_603431.add "Filters", Filters
  add(query_603430, "Version", newJString(Version))
  result = call_603429.call(nil, query_603430, nil, formData_603431, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_603408(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_603409, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_603410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_603385 = ref object of OpenApiRestCall_601373
proc url_GetDescribeOrderableDBInstanceOptions_603387(protocol: Scheme;
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

proc validate_GetDescribeOrderableDBInstanceOptions_603386(path: JsonNode;
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
  var valid_603388 = query.getOrDefault("Marker")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "Marker", valid_603388
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_603389 = query.getOrDefault("Engine")
  valid_603389 = validateParameter(valid_603389, JString, required = true,
                                 default = nil)
  if valid_603389 != nil:
    section.add "Engine", valid_603389
  var valid_603390 = query.getOrDefault("LicenseModel")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "LicenseModel", valid_603390
  var valid_603391 = query.getOrDefault("Vpc")
  valid_603391 = validateParameter(valid_603391, JBool, required = false, default = nil)
  if valid_603391 != nil:
    section.add "Vpc", valid_603391
  var valid_603392 = query.getOrDefault("EngineVersion")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "EngineVersion", valid_603392
  var valid_603393 = query.getOrDefault("Action")
  valid_603393 = validateParameter(valid_603393, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_603393 != nil:
    section.add "Action", valid_603393
  var valid_603394 = query.getOrDefault("Version")
  valid_603394 = validateParameter(valid_603394, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603394 != nil:
    section.add "Version", valid_603394
  var valid_603395 = query.getOrDefault("DBInstanceClass")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "DBInstanceClass", valid_603395
  var valid_603396 = query.getOrDefault("Filters")
  valid_603396 = validateParameter(valid_603396, JArray, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "Filters", valid_603396
  var valid_603397 = query.getOrDefault("MaxRecords")
  valid_603397 = validateParameter(valid_603397, JInt, required = false, default = nil)
  if valid_603397 != nil:
    section.add "MaxRecords", valid_603397
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603398 = header.getOrDefault("X-Amz-Signature")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Signature", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Content-Sha256", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Date")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Date", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Credential")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Credential", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-Security-Token")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Security-Token", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Algorithm")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Algorithm", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-SignedHeaders", valid_603404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603405: Call_GetDescribeOrderableDBInstanceOptions_603385;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603405.validator(path, query, header, formData, body)
  let scheme = call_603405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603405.url(scheme.get, call_603405.host, call_603405.base,
                         call_603405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603405, url, valid)

proc call*(call_603406: Call_GetDescribeOrderableDBInstanceOptions_603385;
          Engine: string; Marker: string = ""; LicenseModel: string = "";
          Vpc: bool = false; EngineVersion: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Version: string = "2014-09-01"; DBInstanceClass: string = "";
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
  var query_603407 = newJObject()
  add(query_603407, "Marker", newJString(Marker))
  add(query_603407, "Engine", newJString(Engine))
  add(query_603407, "LicenseModel", newJString(LicenseModel))
  add(query_603407, "Vpc", newJBool(Vpc))
  add(query_603407, "EngineVersion", newJString(EngineVersion))
  add(query_603407, "Action", newJString(Action))
  add(query_603407, "Version", newJString(Version))
  add(query_603407, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_603407.add "Filters", Filters
  add(query_603407, "MaxRecords", newJInt(MaxRecords))
  result = call_603406.call(nil, query_603407, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_603385(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_603386, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_603387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_603457 = ref object of OpenApiRestCall_601373
proc url_PostDescribeReservedDBInstances_603459(protocol: Scheme; host: string;
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

proc validate_PostDescribeReservedDBInstances_603458(path: JsonNode;
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
  var valid_603460 = query.getOrDefault("Action")
  valid_603460 = validateParameter(valid_603460, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_603460 != nil:
    section.add "Action", valid_603460
  var valid_603461 = query.getOrDefault("Version")
  valid_603461 = validateParameter(valid_603461, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603461 != nil:
    section.add "Version", valid_603461
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603462 = header.getOrDefault("X-Amz-Signature")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Signature", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Content-Sha256", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-Date")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Date", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-Credential")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Credential", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Security-Token")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Security-Token", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Algorithm")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Algorithm", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-SignedHeaders", valid_603468
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
  var valid_603469 = formData.getOrDefault("DBInstanceClass")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "DBInstanceClass", valid_603469
  var valid_603470 = formData.getOrDefault("MultiAZ")
  valid_603470 = validateParameter(valid_603470, JBool, required = false, default = nil)
  if valid_603470 != nil:
    section.add "MultiAZ", valid_603470
  var valid_603471 = formData.getOrDefault("MaxRecords")
  valid_603471 = validateParameter(valid_603471, JInt, required = false, default = nil)
  if valid_603471 != nil:
    section.add "MaxRecords", valid_603471
  var valid_603472 = formData.getOrDefault("ReservedDBInstanceId")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "ReservedDBInstanceId", valid_603472
  var valid_603473 = formData.getOrDefault("Marker")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "Marker", valid_603473
  var valid_603474 = formData.getOrDefault("Duration")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "Duration", valid_603474
  var valid_603475 = formData.getOrDefault("OfferingType")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "OfferingType", valid_603475
  var valid_603476 = formData.getOrDefault("ProductDescription")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "ProductDescription", valid_603476
  var valid_603477 = formData.getOrDefault("Filters")
  valid_603477 = validateParameter(valid_603477, JArray, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "Filters", valid_603477
  var valid_603478 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603478
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603479: Call_PostDescribeReservedDBInstances_603457;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603479.validator(path, query, header, formData, body)
  let scheme = call_603479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603479.url(scheme.get, call_603479.host, call_603479.base,
                         call_603479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603479, url, valid)

proc call*(call_603480: Call_PostDescribeReservedDBInstances_603457;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          ReservedDBInstanceId: string = ""; Marker: string = ""; Duration: string = "";
          OfferingType: string = ""; ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstances"; Filters: JsonNode = nil;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2014-09-01"): Recallable =
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
  var query_603481 = newJObject()
  var formData_603482 = newJObject()
  add(formData_603482, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603482, "MultiAZ", newJBool(MultiAZ))
  add(formData_603482, "MaxRecords", newJInt(MaxRecords))
  add(formData_603482, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_603482, "Marker", newJString(Marker))
  add(formData_603482, "Duration", newJString(Duration))
  add(formData_603482, "OfferingType", newJString(OfferingType))
  add(formData_603482, "ProductDescription", newJString(ProductDescription))
  add(query_603481, "Action", newJString(Action))
  if Filters != nil:
    formData_603482.add "Filters", Filters
  add(formData_603482, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603481, "Version", newJString(Version))
  result = call_603480.call(nil, query_603481, nil, formData_603482, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_603457(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_603458, base: "/",
    url: url_PostDescribeReservedDBInstances_603459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_603432 = ref object of OpenApiRestCall_601373
proc url_GetDescribeReservedDBInstances_603434(protocol: Scheme; host: string;
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

proc validate_GetDescribeReservedDBInstances_603433(path: JsonNode;
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
  var valid_603435 = query.getOrDefault("Marker")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "Marker", valid_603435
  var valid_603436 = query.getOrDefault("ProductDescription")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "ProductDescription", valid_603436
  var valid_603437 = query.getOrDefault("OfferingType")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "OfferingType", valid_603437
  var valid_603438 = query.getOrDefault("ReservedDBInstanceId")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "ReservedDBInstanceId", valid_603438
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603439 = query.getOrDefault("Action")
  valid_603439 = validateParameter(valid_603439, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_603439 != nil:
    section.add "Action", valid_603439
  var valid_603440 = query.getOrDefault("MultiAZ")
  valid_603440 = validateParameter(valid_603440, JBool, required = false, default = nil)
  if valid_603440 != nil:
    section.add "MultiAZ", valid_603440
  var valid_603441 = query.getOrDefault("Duration")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "Duration", valid_603441
  var valid_603442 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603442
  var valid_603443 = query.getOrDefault("Version")
  valid_603443 = validateParameter(valid_603443, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603443 != nil:
    section.add "Version", valid_603443
  var valid_603444 = query.getOrDefault("DBInstanceClass")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "DBInstanceClass", valid_603444
  var valid_603445 = query.getOrDefault("Filters")
  valid_603445 = validateParameter(valid_603445, JArray, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "Filters", valid_603445
  var valid_603446 = query.getOrDefault("MaxRecords")
  valid_603446 = validateParameter(valid_603446, JInt, required = false, default = nil)
  if valid_603446 != nil:
    section.add "MaxRecords", valid_603446
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603447 = header.getOrDefault("X-Amz-Signature")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Signature", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Content-Sha256", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-Date")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Date", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-Credential")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Credential", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Security-Token")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Security-Token", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Algorithm")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Algorithm", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-SignedHeaders", valid_603453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603454: Call_GetDescribeReservedDBInstances_603432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603454.validator(path, query, header, formData, body)
  let scheme = call_603454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603454.url(scheme.get, call_603454.host, call_603454.base,
                         call_603454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603454, url, valid)

proc call*(call_603455: Call_GetDescribeReservedDBInstances_603432;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Action: string = "DescribeReservedDBInstances"; MultiAZ: bool = false;
          Duration: string = ""; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2014-09-01"; DBInstanceClass: string = "";
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
  var query_603456 = newJObject()
  add(query_603456, "Marker", newJString(Marker))
  add(query_603456, "ProductDescription", newJString(ProductDescription))
  add(query_603456, "OfferingType", newJString(OfferingType))
  add(query_603456, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_603456, "Action", newJString(Action))
  add(query_603456, "MultiAZ", newJBool(MultiAZ))
  add(query_603456, "Duration", newJString(Duration))
  add(query_603456, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603456, "Version", newJString(Version))
  add(query_603456, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_603456.add "Filters", Filters
  add(query_603456, "MaxRecords", newJInt(MaxRecords))
  result = call_603455.call(nil, query_603456, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_603432(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_603433, base: "/",
    url: url_GetDescribeReservedDBInstances_603434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_603507 = ref object of OpenApiRestCall_601373
proc url_PostDescribeReservedDBInstancesOfferings_603509(protocol: Scheme;
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

proc validate_PostDescribeReservedDBInstancesOfferings_603508(path: JsonNode;
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
  var valid_603510 = query.getOrDefault("Action")
  valid_603510 = validateParameter(valid_603510, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_603510 != nil:
    section.add "Action", valid_603510
  var valid_603511 = query.getOrDefault("Version")
  valid_603511 = validateParameter(valid_603511, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603511 != nil:
    section.add "Version", valid_603511
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603512 = header.getOrDefault("X-Amz-Signature")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Signature", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Content-Sha256", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Date")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Date", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Credential")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Credential", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Security-Token")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Security-Token", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Algorithm")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Algorithm", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-SignedHeaders", valid_603518
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
  var valid_603519 = formData.getOrDefault("DBInstanceClass")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "DBInstanceClass", valid_603519
  var valid_603520 = formData.getOrDefault("MultiAZ")
  valid_603520 = validateParameter(valid_603520, JBool, required = false, default = nil)
  if valid_603520 != nil:
    section.add "MultiAZ", valid_603520
  var valid_603521 = formData.getOrDefault("MaxRecords")
  valid_603521 = validateParameter(valid_603521, JInt, required = false, default = nil)
  if valid_603521 != nil:
    section.add "MaxRecords", valid_603521
  var valid_603522 = formData.getOrDefault("Marker")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "Marker", valid_603522
  var valid_603523 = formData.getOrDefault("Duration")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "Duration", valid_603523
  var valid_603524 = formData.getOrDefault("OfferingType")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "OfferingType", valid_603524
  var valid_603525 = formData.getOrDefault("ProductDescription")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "ProductDescription", valid_603525
  var valid_603526 = formData.getOrDefault("Filters")
  valid_603526 = validateParameter(valid_603526, JArray, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "Filters", valid_603526
  var valid_603527 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603527
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603528: Call_PostDescribeReservedDBInstancesOfferings_603507;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603528.validator(path, query, header, formData, body)
  let scheme = call_603528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603528.url(scheme.get, call_603528.host, call_603528.base,
                         call_603528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603528, url, valid)

proc call*(call_603529: Call_PostDescribeReservedDBInstancesOfferings_603507;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          Marker: string = ""; Duration: string = ""; OfferingType: string = "";
          ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          Filters: JsonNode = nil; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2014-09-01"): Recallable =
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
  var query_603530 = newJObject()
  var formData_603531 = newJObject()
  add(formData_603531, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603531, "MultiAZ", newJBool(MultiAZ))
  add(formData_603531, "MaxRecords", newJInt(MaxRecords))
  add(formData_603531, "Marker", newJString(Marker))
  add(formData_603531, "Duration", newJString(Duration))
  add(formData_603531, "OfferingType", newJString(OfferingType))
  add(formData_603531, "ProductDescription", newJString(ProductDescription))
  add(query_603530, "Action", newJString(Action))
  if Filters != nil:
    formData_603531.add "Filters", Filters
  add(formData_603531, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603530, "Version", newJString(Version))
  result = call_603529.call(nil, query_603530, nil, formData_603531, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_603507(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_603508,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_603509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_603483 = ref object of OpenApiRestCall_601373
proc url_GetDescribeReservedDBInstancesOfferings_603485(protocol: Scheme;
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

proc validate_GetDescribeReservedDBInstancesOfferings_603484(path: JsonNode;
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
  var valid_603486 = query.getOrDefault("Marker")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "Marker", valid_603486
  var valid_603487 = query.getOrDefault("ProductDescription")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "ProductDescription", valid_603487
  var valid_603488 = query.getOrDefault("OfferingType")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "OfferingType", valid_603488
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603489 = query.getOrDefault("Action")
  valid_603489 = validateParameter(valid_603489, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_603489 != nil:
    section.add "Action", valid_603489
  var valid_603490 = query.getOrDefault("MultiAZ")
  valid_603490 = validateParameter(valid_603490, JBool, required = false, default = nil)
  if valid_603490 != nil:
    section.add "MultiAZ", valid_603490
  var valid_603491 = query.getOrDefault("Duration")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "Duration", valid_603491
  var valid_603492 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603492
  var valid_603493 = query.getOrDefault("Version")
  valid_603493 = validateParameter(valid_603493, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603493 != nil:
    section.add "Version", valid_603493
  var valid_603494 = query.getOrDefault("DBInstanceClass")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "DBInstanceClass", valid_603494
  var valid_603495 = query.getOrDefault("Filters")
  valid_603495 = validateParameter(valid_603495, JArray, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "Filters", valid_603495
  var valid_603496 = query.getOrDefault("MaxRecords")
  valid_603496 = validateParameter(valid_603496, JInt, required = false, default = nil)
  if valid_603496 != nil:
    section.add "MaxRecords", valid_603496
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603497 = header.getOrDefault("X-Amz-Signature")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Signature", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Content-Sha256", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Date")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Date", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Credential")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Credential", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Security-Token")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Security-Token", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Algorithm")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Algorithm", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-SignedHeaders", valid_603503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603504: Call_GetDescribeReservedDBInstancesOfferings_603483;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603504.validator(path, query, header, formData, body)
  let scheme = call_603504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603504.url(scheme.get, call_603504.host, call_603504.base,
                         call_603504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603504, url, valid)

proc call*(call_603505: Call_GetDescribeReservedDBInstancesOfferings_603483;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          MultiAZ: bool = false; Duration: string = "";
          ReservedDBInstancesOfferingId: string = "";
          Version: string = "2014-09-01"; DBInstanceClass: string = "";
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
  var query_603506 = newJObject()
  add(query_603506, "Marker", newJString(Marker))
  add(query_603506, "ProductDescription", newJString(ProductDescription))
  add(query_603506, "OfferingType", newJString(OfferingType))
  add(query_603506, "Action", newJString(Action))
  add(query_603506, "MultiAZ", newJBool(MultiAZ))
  add(query_603506, "Duration", newJString(Duration))
  add(query_603506, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603506, "Version", newJString(Version))
  add(query_603506, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_603506.add "Filters", Filters
  add(query_603506, "MaxRecords", newJInt(MaxRecords))
  result = call_603505.call(nil, query_603506, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_603483(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_603484, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_603485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_603551 = ref object of OpenApiRestCall_601373
proc url_PostDownloadDBLogFilePortion_603553(protocol: Scheme; host: string;
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

proc validate_PostDownloadDBLogFilePortion_603552(path: JsonNode; query: JsonNode;
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
  var valid_603554 = query.getOrDefault("Action")
  valid_603554 = validateParameter(valid_603554, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_603554 != nil:
    section.add "Action", valid_603554
  var valid_603555 = query.getOrDefault("Version")
  valid_603555 = validateParameter(valid_603555, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603555 != nil:
    section.add "Version", valid_603555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603556 = header.getOrDefault("X-Amz-Signature")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Signature", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Content-Sha256", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Date")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Date", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Credential")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Credential", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Security-Token")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Security-Token", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-Algorithm")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Algorithm", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-SignedHeaders", valid_603562
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_603563 = formData.getOrDefault("NumberOfLines")
  valid_603563 = validateParameter(valid_603563, JInt, required = false, default = nil)
  if valid_603563 != nil:
    section.add "NumberOfLines", valid_603563
  var valid_603564 = formData.getOrDefault("Marker")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "Marker", valid_603564
  assert formData != nil,
        "formData argument is necessary due to required `LogFileName` field"
  var valid_603565 = formData.getOrDefault("LogFileName")
  valid_603565 = validateParameter(valid_603565, JString, required = true,
                                 default = nil)
  if valid_603565 != nil:
    section.add "LogFileName", valid_603565
  var valid_603566 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603566 = validateParameter(valid_603566, JString, required = true,
                                 default = nil)
  if valid_603566 != nil:
    section.add "DBInstanceIdentifier", valid_603566
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603567: Call_PostDownloadDBLogFilePortion_603551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603567.validator(path, query, header, formData, body)
  let scheme = call_603567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603567.url(scheme.get, call_603567.host, call_603567.base,
                         call_603567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603567, url, valid)

proc call*(call_603568: Call_PostDownloadDBLogFilePortion_603551;
          LogFileName: string; DBInstanceIdentifier: string; NumberOfLines: int = 0;
          Marker: string = ""; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2014-09-01"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   Marker: string
  ##   LogFileName: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603569 = newJObject()
  var formData_603570 = newJObject()
  add(formData_603570, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_603570, "Marker", newJString(Marker))
  add(formData_603570, "LogFileName", newJString(LogFileName))
  add(formData_603570, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603569, "Action", newJString(Action))
  add(query_603569, "Version", newJString(Version))
  result = call_603568.call(nil, query_603569, nil, formData_603570, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_603551(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_603552, base: "/",
    url: url_PostDownloadDBLogFilePortion_603553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_603532 = ref object of OpenApiRestCall_601373
proc url_GetDownloadDBLogFilePortion_603534(protocol: Scheme; host: string;
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

proc validate_GetDownloadDBLogFilePortion_603533(path: JsonNode; query: JsonNode;
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
  var valid_603535 = query.getOrDefault("Marker")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "Marker", valid_603535
  var valid_603536 = query.getOrDefault("NumberOfLines")
  valid_603536 = validateParameter(valid_603536, JInt, required = false, default = nil)
  if valid_603536 != nil:
    section.add "NumberOfLines", valid_603536
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603537 = query.getOrDefault("DBInstanceIdentifier")
  valid_603537 = validateParameter(valid_603537, JString, required = true,
                                 default = nil)
  if valid_603537 != nil:
    section.add "DBInstanceIdentifier", valid_603537
  var valid_603538 = query.getOrDefault("Action")
  valid_603538 = validateParameter(valid_603538, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_603538 != nil:
    section.add "Action", valid_603538
  var valid_603539 = query.getOrDefault("LogFileName")
  valid_603539 = validateParameter(valid_603539, JString, required = true,
                                 default = nil)
  if valid_603539 != nil:
    section.add "LogFileName", valid_603539
  var valid_603540 = query.getOrDefault("Version")
  valid_603540 = validateParameter(valid_603540, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603540 != nil:
    section.add "Version", valid_603540
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603541 = header.getOrDefault("X-Amz-Signature")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Signature", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Content-Sha256", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Date")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Date", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Credential")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Credential", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Security-Token")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Security-Token", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-Algorithm")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Algorithm", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-SignedHeaders", valid_603547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603548: Call_GetDownloadDBLogFilePortion_603532; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603548.validator(path, query, header, formData, body)
  let scheme = call_603548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603548.url(scheme.get, call_603548.host, call_603548.base,
                         call_603548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603548, url, valid)

proc call*(call_603549: Call_GetDownloadDBLogFilePortion_603532;
          DBInstanceIdentifier: string; LogFileName: string; Marker: string = "";
          NumberOfLines: int = 0; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2014-09-01"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   Marker: string
  ##   NumberOfLines: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   LogFileName: string (required)
  ##   Version: string (required)
  var query_603550 = newJObject()
  add(query_603550, "Marker", newJString(Marker))
  add(query_603550, "NumberOfLines", newJInt(NumberOfLines))
  add(query_603550, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603550, "Action", newJString(Action))
  add(query_603550, "LogFileName", newJString(LogFileName))
  add(query_603550, "Version", newJString(Version))
  result = call_603549.call(nil, query_603550, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_603532(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_603533, base: "/",
    url: url_GetDownloadDBLogFilePortion_603534,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_603588 = ref object of OpenApiRestCall_601373
proc url_PostListTagsForResource_603590(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_603589(path: JsonNode; query: JsonNode;
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
  var valid_603591 = query.getOrDefault("Action")
  valid_603591 = validateParameter(valid_603591, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603591 != nil:
    section.add "Action", valid_603591
  var valid_603592 = query.getOrDefault("Version")
  valid_603592 = validateParameter(valid_603592, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603592 != nil:
    section.add "Version", valid_603592
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603593 = header.getOrDefault("X-Amz-Signature")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Signature", valid_603593
  var valid_603594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-Content-Sha256", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-Date")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Date", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Credential")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Credential", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-Security-Token")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Security-Token", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-Algorithm")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Algorithm", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-SignedHeaders", valid_603599
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_603600 = formData.getOrDefault("Filters")
  valid_603600 = validateParameter(valid_603600, JArray, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "Filters", valid_603600
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_603601 = formData.getOrDefault("ResourceName")
  valid_603601 = validateParameter(valid_603601, JString, required = true,
                                 default = nil)
  if valid_603601 != nil:
    section.add "ResourceName", valid_603601
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603602: Call_PostListTagsForResource_603588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603602.validator(path, query, header, formData, body)
  let scheme = call_603602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603602.url(scheme.get, call_603602.host, call_603602.base,
                         call_603602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603602, url, valid)

proc call*(call_603603: Call_PostListTagsForResource_603588; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_603604 = newJObject()
  var formData_603605 = newJObject()
  add(query_603604, "Action", newJString(Action))
  if Filters != nil:
    formData_603605.add "Filters", Filters
  add(query_603604, "Version", newJString(Version))
  add(formData_603605, "ResourceName", newJString(ResourceName))
  result = call_603603.call(nil, query_603604, nil, formData_603605, nil)

var postListTagsForResource* = Call_PostListTagsForResource_603588(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_603589, base: "/",
    url: url_PostListTagsForResource_603590, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_603571 = ref object of OpenApiRestCall_601373
proc url_GetListTagsForResource_603573(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_603572(path: JsonNode; query: JsonNode;
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
  var valid_603574 = query.getOrDefault("ResourceName")
  valid_603574 = validateParameter(valid_603574, JString, required = true,
                                 default = nil)
  if valid_603574 != nil:
    section.add "ResourceName", valid_603574
  var valid_603575 = query.getOrDefault("Action")
  valid_603575 = validateParameter(valid_603575, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603575 != nil:
    section.add "Action", valid_603575
  var valid_603576 = query.getOrDefault("Version")
  valid_603576 = validateParameter(valid_603576, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603576 != nil:
    section.add "Version", valid_603576
  var valid_603577 = query.getOrDefault("Filters")
  valid_603577 = validateParameter(valid_603577, JArray, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "Filters", valid_603577
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603578 = header.getOrDefault("X-Amz-Signature")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Signature", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Content-Sha256", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Date")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Date", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Credential")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Credential", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-Security-Token")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Security-Token", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-Algorithm")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Algorithm", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-SignedHeaders", valid_603584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603585: Call_GetListTagsForResource_603571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603585.validator(path, query, header, formData, body)
  let scheme = call_603585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603585.url(scheme.get, call_603585.host, call_603585.base,
                         call_603585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603585, url, valid)

proc call*(call_603586: Call_GetListTagsForResource_603571; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2014-09-01";
          Filters: JsonNode = nil): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_603587 = newJObject()
  add(query_603587, "ResourceName", newJString(ResourceName))
  add(query_603587, "Action", newJString(Action))
  add(query_603587, "Version", newJString(Version))
  if Filters != nil:
    query_603587.add "Filters", Filters
  result = call_603586.call(nil, query_603587, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_603571(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_603572, base: "/",
    url: url_GetListTagsForResource_603573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_603642 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBInstance_603644(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBInstance_603643(path: JsonNode; query: JsonNode;
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
  var valid_603645 = query.getOrDefault("Action")
  valid_603645 = validateParameter(valid_603645, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_603645 != nil:
    section.add "Action", valid_603645
  var valid_603646 = query.getOrDefault("Version")
  valid_603646 = validateParameter(valid_603646, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603646 != nil:
    section.add "Version", valid_603646
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603647 = header.getOrDefault("X-Amz-Signature")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Signature", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Content-Sha256", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Date")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Date", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Credential")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Credential", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-Security-Token")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-Security-Token", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Algorithm")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Algorithm", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-SignedHeaders", valid_603653
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
  ##   TdeCredentialPassword: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   ApplyImmediately: JBool
  ##   Iops: JInt
  ##   TdeCredentialArn: JString
  ##   AllowMajorVersionUpgrade: JBool
  ##   OptionGroupName: JString
  ##   NewDBInstanceIdentifier: JString
  ##   DBSecurityGroups: JArray
  ##   StorageType: JString
  ##   AllocatedStorage: JInt
  section = newJObject()
  var valid_603654 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "PreferredMaintenanceWindow", valid_603654
  var valid_603655 = formData.getOrDefault("DBInstanceClass")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "DBInstanceClass", valid_603655
  var valid_603656 = formData.getOrDefault("PreferredBackupWindow")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "PreferredBackupWindow", valid_603656
  var valid_603657 = formData.getOrDefault("MasterUserPassword")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "MasterUserPassword", valid_603657
  var valid_603658 = formData.getOrDefault("MultiAZ")
  valid_603658 = validateParameter(valid_603658, JBool, required = false, default = nil)
  if valid_603658 != nil:
    section.add "MultiAZ", valid_603658
  var valid_603659 = formData.getOrDefault("DBParameterGroupName")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "DBParameterGroupName", valid_603659
  var valid_603660 = formData.getOrDefault("EngineVersion")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "EngineVersion", valid_603660
  var valid_603661 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603661 = validateParameter(valid_603661, JArray, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "VpcSecurityGroupIds", valid_603661
  var valid_603662 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603662 = validateParameter(valid_603662, JInt, required = false, default = nil)
  if valid_603662 != nil:
    section.add "BackupRetentionPeriod", valid_603662
  var valid_603663 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603663 = validateParameter(valid_603663, JBool, required = false, default = nil)
  if valid_603663 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603663
  var valid_603664 = formData.getOrDefault("TdeCredentialPassword")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "TdeCredentialPassword", valid_603664
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603665 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603665 = validateParameter(valid_603665, JString, required = true,
                                 default = nil)
  if valid_603665 != nil:
    section.add "DBInstanceIdentifier", valid_603665
  var valid_603666 = formData.getOrDefault("ApplyImmediately")
  valid_603666 = validateParameter(valid_603666, JBool, required = false, default = nil)
  if valid_603666 != nil:
    section.add "ApplyImmediately", valid_603666
  var valid_603667 = formData.getOrDefault("Iops")
  valid_603667 = validateParameter(valid_603667, JInt, required = false, default = nil)
  if valid_603667 != nil:
    section.add "Iops", valid_603667
  var valid_603668 = formData.getOrDefault("TdeCredentialArn")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "TdeCredentialArn", valid_603668
  var valid_603669 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_603669 = validateParameter(valid_603669, JBool, required = false, default = nil)
  if valid_603669 != nil:
    section.add "AllowMajorVersionUpgrade", valid_603669
  var valid_603670 = formData.getOrDefault("OptionGroupName")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "OptionGroupName", valid_603670
  var valid_603671 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "NewDBInstanceIdentifier", valid_603671
  var valid_603672 = formData.getOrDefault("DBSecurityGroups")
  valid_603672 = validateParameter(valid_603672, JArray, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "DBSecurityGroups", valid_603672
  var valid_603673 = formData.getOrDefault("StorageType")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "StorageType", valid_603673
  var valid_603674 = formData.getOrDefault("AllocatedStorage")
  valid_603674 = validateParameter(valid_603674, JInt, required = false, default = nil)
  if valid_603674 != nil:
    section.add "AllocatedStorage", valid_603674
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603675: Call_PostModifyDBInstance_603642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603675.validator(path, query, header, formData, body)
  let scheme = call_603675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603675.url(scheme.get, call_603675.host, call_603675.base,
                         call_603675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603675, url, valid)

proc call*(call_603676: Call_PostModifyDBInstance_603642;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          MasterUserPassword: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          AutoMinorVersionUpgrade: bool = false; TdeCredentialPassword: string = "";
          ApplyImmediately: bool = false; Iops: int = 0; TdeCredentialArn: string = "";
          Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false; OptionGroupName: string = "";
          NewDBInstanceIdentifier: string = ""; Version: string = "2014-09-01";
          DBSecurityGroups: JsonNode = nil; StorageType: string = "";
          AllocatedStorage: int = 0): Recallable =
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
  ##   TdeCredentialPassword: string
  ##   DBInstanceIdentifier: string (required)
  ##   ApplyImmediately: bool
  ##   Iops: int
  ##   TdeCredentialArn: string
  ##   Action: string (required)
  ##   AllowMajorVersionUpgrade: bool
  ##   OptionGroupName: string
  ##   NewDBInstanceIdentifier: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   StorageType: string
  ##   AllocatedStorage: int
  var query_603677 = newJObject()
  var formData_603678 = newJObject()
  add(formData_603678, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_603678, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603678, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603678, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_603678, "MultiAZ", newJBool(MultiAZ))
  add(formData_603678, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603678, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_603678.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_603678, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603678, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603678, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_603678, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603678, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_603678, "Iops", newJInt(Iops))
  add(formData_603678, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_603677, "Action", newJString(Action))
  add(formData_603678, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_603678, "OptionGroupName", newJString(OptionGroupName))
  add(formData_603678, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_603677, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_603678.add "DBSecurityGroups", DBSecurityGroups
  add(formData_603678, "StorageType", newJString(StorageType))
  add(formData_603678, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_603676.call(nil, query_603677, nil, formData_603678, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_603642(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_603643, base: "/",
    url: url_PostModifyDBInstance_603644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_603606 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBInstance_603608(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBInstance_603607(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NewDBInstanceIdentifier: JString
  ##   TdeCredentialPassword: JString
  ##   DBParameterGroupName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   TdeCredentialArn: JString
  ##   BackupRetentionPeriod: JInt
  ##   StorageType: JString
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
  var valid_603609 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "NewDBInstanceIdentifier", valid_603609
  var valid_603610 = query.getOrDefault("TdeCredentialPassword")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "TdeCredentialPassword", valid_603610
  var valid_603611 = query.getOrDefault("DBParameterGroupName")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "DBParameterGroupName", valid_603611
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603612 = query.getOrDefault("DBInstanceIdentifier")
  valid_603612 = validateParameter(valid_603612, JString, required = true,
                                 default = nil)
  if valid_603612 != nil:
    section.add "DBInstanceIdentifier", valid_603612
  var valid_603613 = query.getOrDefault("TdeCredentialArn")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "TdeCredentialArn", valid_603613
  var valid_603614 = query.getOrDefault("BackupRetentionPeriod")
  valid_603614 = validateParameter(valid_603614, JInt, required = false, default = nil)
  if valid_603614 != nil:
    section.add "BackupRetentionPeriod", valid_603614
  var valid_603615 = query.getOrDefault("StorageType")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "StorageType", valid_603615
  var valid_603616 = query.getOrDefault("EngineVersion")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "EngineVersion", valid_603616
  var valid_603617 = query.getOrDefault("Action")
  valid_603617 = validateParameter(valid_603617, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_603617 != nil:
    section.add "Action", valid_603617
  var valid_603618 = query.getOrDefault("MultiAZ")
  valid_603618 = validateParameter(valid_603618, JBool, required = false, default = nil)
  if valid_603618 != nil:
    section.add "MultiAZ", valid_603618
  var valid_603619 = query.getOrDefault("DBSecurityGroups")
  valid_603619 = validateParameter(valid_603619, JArray, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "DBSecurityGroups", valid_603619
  var valid_603620 = query.getOrDefault("ApplyImmediately")
  valid_603620 = validateParameter(valid_603620, JBool, required = false, default = nil)
  if valid_603620 != nil:
    section.add "ApplyImmediately", valid_603620
  var valid_603621 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603621 = validateParameter(valid_603621, JArray, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "VpcSecurityGroupIds", valid_603621
  var valid_603622 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_603622 = validateParameter(valid_603622, JBool, required = false, default = nil)
  if valid_603622 != nil:
    section.add "AllowMajorVersionUpgrade", valid_603622
  var valid_603623 = query.getOrDefault("MasterUserPassword")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "MasterUserPassword", valid_603623
  var valid_603624 = query.getOrDefault("OptionGroupName")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "OptionGroupName", valid_603624
  var valid_603625 = query.getOrDefault("Version")
  valid_603625 = validateParameter(valid_603625, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603625 != nil:
    section.add "Version", valid_603625
  var valid_603626 = query.getOrDefault("AllocatedStorage")
  valid_603626 = validateParameter(valid_603626, JInt, required = false, default = nil)
  if valid_603626 != nil:
    section.add "AllocatedStorage", valid_603626
  var valid_603627 = query.getOrDefault("DBInstanceClass")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "DBInstanceClass", valid_603627
  var valid_603628 = query.getOrDefault("PreferredBackupWindow")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "PreferredBackupWindow", valid_603628
  var valid_603629 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "PreferredMaintenanceWindow", valid_603629
  var valid_603630 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603630 = validateParameter(valid_603630, JBool, required = false, default = nil)
  if valid_603630 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603630
  var valid_603631 = query.getOrDefault("Iops")
  valid_603631 = validateParameter(valid_603631, JInt, required = false, default = nil)
  if valid_603631 != nil:
    section.add "Iops", valid_603631
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603632 = header.getOrDefault("X-Amz-Signature")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Signature", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Content-Sha256", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Date")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Date", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Credential")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Credential", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-Security-Token")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Security-Token", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Algorithm")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Algorithm", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-SignedHeaders", valid_603638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603639: Call_GetModifyDBInstance_603606; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603639.validator(path, query, header, formData, body)
  let scheme = call_603639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603639.url(scheme.get, call_603639.host, call_603639.base,
                         call_603639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603639, url, valid)

proc call*(call_603640: Call_GetModifyDBInstance_603606;
          DBInstanceIdentifier: string; NewDBInstanceIdentifier: string = "";
          TdeCredentialPassword: string = ""; DBParameterGroupName: string = "";
          TdeCredentialArn: string = ""; BackupRetentionPeriod: int = 0;
          StorageType: string = ""; EngineVersion: string = "";
          Action: string = "ModifyDBInstance"; MultiAZ: bool = false;
          DBSecurityGroups: JsonNode = nil; ApplyImmediately: bool = false;
          VpcSecurityGroupIds: JsonNode = nil;
          AllowMajorVersionUpgrade: bool = false; MasterUserPassword: string = "";
          OptionGroupName: string = ""; Version: string = "2014-09-01";
          AllocatedStorage: int = 0; DBInstanceClass: string = "";
          PreferredBackupWindow: string = "";
          PreferredMaintenanceWindow: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getModifyDBInstance
  ##   NewDBInstanceIdentifier: string
  ##   TdeCredentialPassword: string
  ##   DBParameterGroupName: string
  ##   DBInstanceIdentifier: string (required)
  ##   TdeCredentialArn: string
  ##   BackupRetentionPeriod: int
  ##   StorageType: string
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
  var query_603641 = newJObject()
  add(query_603641, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_603641, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_603641, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603641, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603641, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_603641, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603641, "StorageType", newJString(StorageType))
  add(query_603641, "EngineVersion", newJString(EngineVersion))
  add(query_603641, "Action", newJString(Action))
  add(query_603641, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_603641.add "DBSecurityGroups", DBSecurityGroups
  add(query_603641, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_603641.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_603641, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_603641, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_603641, "OptionGroupName", newJString(OptionGroupName))
  add(query_603641, "Version", newJString(Version))
  add(query_603641, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_603641, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603641, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_603641, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603641, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603641, "Iops", newJInt(Iops))
  result = call_603640.call(nil, query_603641, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_603606(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_603607, base: "/",
    url: url_GetModifyDBInstance_603608, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_603696 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBParameterGroup_603698(protocol: Scheme; host: string;
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

proc validate_PostModifyDBParameterGroup_603697(path: JsonNode; query: JsonNode;
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
  var valid_603699 = query.getOrDefault("Action")
  valid_603699 = validateParameter(valid_603699, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_603699 != nil:
    section.add "Action", valid_603699
  var valid_603700 = query.getOrDefault("Version")
  valid_603700 = validateParameter(valid_603700, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603700 != nil:
    section.add "Version", valid_603700
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603701 = header.getOrDefault("X-Amz-Signature")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Signature", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Content-Sha256", valid_603702
  var valid_603703 = header.getOrDefault("X-Amz-Date")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-Date", valid_603703
  var valid_603704 = header.getOrDefault("X-Amz-Credential")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Credential", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-Security-Token")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Security-Token", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Algorithm")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Algorithm", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-SignedHeaders", valid_603707
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603708 = formData.getOrDefault("DBParameterGroupName")
  valid_603708 = validateParameter(valid_603708, JString, required = true,
                                 default = nil)
  if valid_603708 != nil:
    section.add "DBParameterGroupName", valid_603708
  var valid_603709 = formData.getOrDefault("Parameters")
  valid_603709 = validateParameter(valid_603709, JArray, required = true, default = nil)
  if valid_603709 != nil:
    section.add "Parameters", valid_603709
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603710: Call_PostModifyDBParameterGroup_603696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603710.validator(path, query, header, formData, body)
  let scheme = call_603710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603710.url(scheme.get, call_603710.host, call_603710.base,
                         call_603710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603710, url, valid)

proc call*(call_603711: Call_PostModifyDBParameterGroup_603696;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_603712 = newJObject()
  var formData_603713 = newJObject()
  add(formData_603713, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603712, "Action", newJString(Action))
  if Parameters != nil:
    formData_603713.add "Parameters", Parameters
  add(query_603712, "Version", newJString(Version))
  result = call_603711.call(nil, query_603712, nil, formData_603713, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_603696(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_603697, base: "/",
    url: url_PostModifyDBParameterGroup_603698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_603679 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBParameterGroup_603681(protocol: Scheme; host: string;
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

proc validate_GetModifyDBParameterGroup_603680(path: JsonNode; query: JsonNode;
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
  var valid_603682 = query.getOrDefault("DBParameterGroupName")
  valid_603682 = validateParameter(valid_603682, JString, required = true,
                                 default = nil)
  if valid_603682 != nil:
    section.add "DBParameterGroupName", valid_603682
  var valid_603683 = query.getOrDefault("Parameters")
  valid_603683 = validateParameter(valid_603683, JArray, required = true, default = nil)
  if valid_603683 != nil:
    section.add "Parameters", valid_603683
  var valid_603684 = query.getOrDefault("Action")
  valid_603684 = validateParameter(valid_603684, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_603684 != nil:
    section.add "Action", valid_603684
  var valid_603685 = query.getOrDefault("Version")
  valid_603685 = validateParameter(valid_603685, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603685 != nil:
    section.add "Version", valid_603685
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603686 = header.getOrDefault("X-Amz-Signature")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Signature", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Content-Sha256", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Date")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Date", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-Credential")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Credential", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Security-Token")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Security-Token", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Algorithm")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Algorithm", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-SignedHeaders", valid_603692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603693: Call_GetModifyDBParameterGroup_603679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603693.validator(path, query, header, formData, body)
  let scheme = call_603693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603693.url(scheme.get, call_603693.host, call_603693.base,
                         call_603693.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603693, url, valid)

proc call*(call_603694: Call_GetModifyDBParameterGroup_603679;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603695 = newJObject()
  add(query_603695, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_603695.add "Parameters", Parameters
  add(query_603695, "Action", newJString(Action))
  add(query_603695, "Version", newJString(Version))
  result = call_603694.call(nil, query_603695, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_603679(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_603680, base: "/",
    url: url_GetModifyDBParameterGroup_603681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_603732 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBSubnetGroup_603734(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBSubnetGroup_603733(path: JsonNode; query: JsonNode;
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
  var valid_603735 = query.getOrDefault("Action")
  valid_603735 = validateParameter(valid_603735, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_603735 != nil:
    section.add "Action", valid_603735
  var valid_603736 = query.getOrDefault("Version")
  valid_603736 = validateParameter(valid_603736, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603736 != nil:
    section.add "Version", valid_603736
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603737 = header.getOrDefault("X-Amz-Signature")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-Signature", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Content-Sha256", valid_603738
  var valid_603739 = header.getOrDefault("X-Amz-Date")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Date", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Credential")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Credential", valid_603740
  var valid_603741 = header.getOrDefault("X-Amz-Security-Token")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "X-Amz-Security-Token", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-Algorithm")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Algorithm", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-SignedHeaders", valid_603743
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_603744 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "DBSubnetGroupDescription", valid_603744
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603745 = formData.getOrDefault("DBSubnetGroupName")
  valid_603745 = validateParameter(valid_603745, JString, required = true,
                                 default = nil)
  if valid_603745 != nil:
    section.add "DBSubnetGroupName", valid_603745
  var valid_603746 = formData.getOrDefault("SubnetIds")
  valid_603746 = validateParameter(valid_603746, JArray, required = true, default = nil)
  if valid_603746 != nil:
    section.add "SubnetIds", valid_603746
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603747: Call_PostModifyDBSubnetGroup_603732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603747.validator(path, query, header, formData, body)
  let scheme = call_603747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603747.url(scheme.get, call_603747.host, call_603747.base,
                         call_603747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603747, url, valid)

proc call*(call_603748: Call_PostModifyDBSubnetGroup_603732;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_603749 = newJObject()
  var formData_603750 = newJObject()
  add(formData_603750, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603749, "Action", newJString(Action))
  add(formData_603750, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603749, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_603750.add "SubnetIds", SubnetIds
  result = call_603748.call(nil, query_603749, nil, formData_603750, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_603732(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_603733, base: "/",
    url: url_PostModifyDBSubnetGroup_603734, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_603714 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBSubnetGroup_603716(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBSubnetGroup_603715(path: JsonNode; query: JsonNode;
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
  var valid_603717 = query.getOrDefault("SubnetIds")
  valid_603717 = validateParameter(valid_603717, JArray, required = true, default = nil)
  if valid_603717 != nil:
    section.add "SubnetIds", valid_603717
  var valid_603718 = query.getOrDefault("Action")
  valid_603718 = validateParameter(valid_603718, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_603718 != nil:
    section.add "Action", valid_603718
  var valid_603719 = query.getOrDefault("DBSubnetGroupDescription")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "DBSubnetGroupDescription", valid_603719
  var valid_603720 = query.getOrDefault("DBSubnetGroupName")
  valid_603720 = validateParameter(valid_603720, JString, required = true,
                                 default = nil)
  if valid_603720 != nil:
    section.add "DBSubnetGroupName", valid_603720
  var valid_603721 = query.getOrDefault("Version")
  valid_603721 = validateParameter(valid_603721, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603721 != nil:
    section.add "Version", valid_603721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603722 = header.getOrDefault("X-Amz-Signature")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Signature", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Content-Sha256", valid_603723
  var valid_603724 = header.getOrDefault("X-Amz-Date")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Date", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Credential")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Credential", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-Security-Token")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-Security-Token", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Algorithm")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Algorithm", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-SignedHeaders", valid_603728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603729: Call_GetModifyDBSubnetGroup_603714; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603729.validator(path, query, header, formData, body)
  let scheme = call_603729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603729.url(scheme.get, call_603729.host, call_603729.base,
                         call_603729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603729, url, valid)

proc call*(call_603730: Call_GetModifyDBSubnetGroup_603714; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_603731 = newJObject()
  if SubnetIds != nil:
    query_603731.add "SubnetIds", SubnetIds
  add(query_603731, "Action", newJString(Action))
  add(query_603731, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603731, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603731, "Version", newJString(Version))
  result = call_603730.call(nil, query_603731, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_603714(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_603715, base: "/",
    url: url_GetModifyDBSubnetGroup_603716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_603771 = ref object of OpenApiRestCall_601373
proc url_PostModifyEventSubscription_603773(protocol: Scheme; host: string;
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

proc validate_PostModifyEventSubscription_603772(path: JsonNode; query: JsonNode;
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
  var valid_603774 = query.getOrDefault("Action")
  valid_603774 = validateParameter(valid_603774, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_603774 != nil:
    section.add "Action", valid_603774
  var valid_603775 = query.getOrDefault("Version")
  valid_603775 = validateParameter(valid_603775, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603775 != nil:
    section.add "Version", valid_603775
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603776 = header.getOrDefault("X-Amz-Signature")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Signature", valid_603776
  var valid_603777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Content-Sha256", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-Date")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-Date", valid_603778
  var valid_603779 = header.getOrDefault("X-Amz-Credential")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-Credential", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Security-Token")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Security-Token", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Algorithm")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Algorithm", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-SignedHeaders", valid_603782
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_603783 = formData.getOrDefault("SnsTopicArn")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "SnsTopicArn", valid_603783
  var valid_603784 = formData.getOrDefault("Enabled")
  valid_603784 = validateParameter(valid_603784, JBool, required = false, default = nil)
  if valid_603784 != nil:
    section.add "Enabled", valid_603784
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_603785 = formData.getOrDefault("SubscriptionName")
  valid_603785 = validateParameter(valid_603785, JString, required = true,
                                 default = nil)
  if valid_603785 != nil:
    section.add "SubscriptionName", valid_603785
  var valid_603786 = formData.getOrDefault("SourceType")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "SourceType", valid_603786
  var valid_603787 = formData.getOrDefault("EventCategories")
  valid_603787 = validateParameter(valid_603787, JArray, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "EventCategories", valid_603787
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603788: Call_PostModifyEventSubscription_603771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603788.validator(path, query, header, formData, body)
  let scheme = call_603788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603788.url(scheme.get, call_603788.host, call_603788.base,
                         call_603788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603788, url, valid)

proc call*(call_603789: Call_PostModifyEventSubscription_603771;
          SubscriptionName: string; SnsTopicArn: string = ""; Enabled: bool = false;
          SourceType: string = ""; EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; Version: string = "2014-09-01"): Recallable =
  ## postModifyEventSubscription
  ##   SnsTopicArn: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603790 = newJObject()
  var formData_603791 = newJObject()
  add(formData_603791, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_603791, "Enabled", newJBool(Enabled))
  add(formData_603791, "SubscriptionName", newJString(SubscriptionName))
  add(formData_603791, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_603791.add "EventCategories", EventCategories
  add(query_603790, "Action", newJString(Action))
  add(query_603790, "Version", newJString(Version))
  result = call_603789.call(nil, query_603790, nil, formData_603791, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_603771(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_603772, base: "/",
    url: url_PostModifyEventSubscription_603773,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_603751 = ref object of OpenApiRestCall_601373
proc url_GetModifyEventSubscription_603753(protocol: Scheme; host: string;
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

proc validate_GetModifyEventSubscription_603752(path: JsonNode; query: JsonNode;
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
  var valid_603754 = query.getOrDefault("SourceType")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "SourceType", valid_603754
  var valid_603755 = query.getOrDefault("Enabled")
  valid_603755 = validateParameter(valid_603755, JBool, required = false, default = nil)
  if valid_603755 != nil:
    section.add "Enabled", valid_603755
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_603756 = query.getOrDefault("SubscriptionName")
  valid_603756 = validateParameter(valid_603756, JString, required = true,
                                 default = nil)
  if valid_603756 != nil:
    section.add "SubscriptionName", valid_603756
  var valid_603757 = query.getOrDefault("EventCategories")
  valid_603757 = validateParameter(valid_603757, JArray, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "EventCategories", valid_603757
  var valid_603758 = query.getOrDefault("Action")
  valid_603758 = validateParameter(valid_603758, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_603758 != nil:
    section.add "Action", valid_603758
  var valid_603759 = query.getOrDefault("SnsTopicArn")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "SnsTopicArn", valid_603759
  var valid_603760 = query.getOrDefault("Version")
  valid_603760 = validateParameter(valid_603760, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603760 != nil:
    section.add "Version", valid_603760
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603761 = header.getOrDefault("X-Amz-Signature")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Signature", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Content-Sha256", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-Date")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Date", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-Credential")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Credential", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Security-Token")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Security-Token", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Algorithm")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Algorithm", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-SignedHeaders", valid_603767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603768: Call_GetModifyEventSubscription_603751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603768.validator(path, query, header, formData, body)
  let scheme = call_603768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603768.url(scheme.get, call_603768.host, call_603768.base,
                         call_603768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603768, url, valid)

proc call*(call_603769: Call_GetModifyEventSubscription_603751;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   Version: string (required)
  var query_603770 = newJObject()
  add(query_603770, "SourceType", newJString(SourceType))
  add(query_603770, "Enabled", newJBool(Enabled))
  add(query_603770, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_603770.add "EventCategories", EventCategories
  add(query_603770, "Action", newJString(Action))
  add(query_603770, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_603770, "Version", newJString(Version))
  result = call_603769.call(nil, query_603770, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_603751(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_603752, base: "/",
    url: url_GetModifyEventSubscription_603753,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_603811 = ref object of OpenApiRestCall_601373
proc url_PostModifyOptionGroup_603813(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyOptionGroup_603812(path: JsonNode; query: JsonNode;
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
  var valid_603814 = query.getOrDefault("Action")
  valid_603814 = validateParameter(valid_603814, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_603814 != nil:
    section.add "Action", valid_603814
  var valid_603815 = query.getOrDefault("Version")
  valid_603815 = validateParameter(valid_603815, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603815 != nil:
    section.add "Version", valid_603815
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603816 = header.getOrDefault("X-Amz-Signature")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-Signature", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-Content-Sha256", valid_603817
  var valid_603818 = header.getOrDefault("X-Amz-Date")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-Date", valid_603818
  var valid_603819 = header.getOrDefault("X-Amz-Credential")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "X-Amz-Credential", valid_603819
  var valid_603820 = header.getOrDefault("X-Amz-Security-Token")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-Security-Token", valid_603820
  var valid_603821 = header.getOrDefault("X-Amz-Algorithm")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Algorithm", valid_603821
  var valid_603822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "X-Amz-SignedHeaders", valid_603822
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_603823 = formData.getOrDefault("OptionsToRemove")
  valid_603823 = validateParameter(valid_603823, JArray, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "OptionsToRemove", valid_603823
  var valid_603824 = formData.getOrDefault("ApplyImmediately")
  valid_603824 = validateParameter(valid_603824, JBool, required = false, default = nil)
  if valid_603824 != nil:
    section.add "ApplyImmediately", valid_603824
  var valid_603825 = formData.getOrDefault("OptionsToInclude")
  valid_603825 = validateParameter(valid_603825, JArray, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "OptionsToInclude", valid_603825
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_603826 = formData.getOrDefault("OptionGroupName")
  valid_603826 = validateParameter(valid_603826, JString, required = true,
                                 default = nil)
  if valid_603826 != nil:
    section.add "OptionGroupName", valid_603826
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603827: Call_PostModifyOptionGroup_603811; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603827.validator(path, query, header, formData, body)
  let scheme = call_603827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603827.url(scheme.get, call_603827.host, call_603827.base,
                         call_603827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603827, url, valid)

proc call*(call_603828: Call_PostModifyOptionGroup_603811; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_603829 = newJObject()
  var formData_603830 = newJObject()
  if OptionsToRemove != nil:
    formData_603830.add "OptionsToRemove", OptionsToRemove
  add(formData_603830, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_603830.add "OptionsToInclude", OptionsToInclude
  add(query_603829, "Action", newJString(Action))
  add(formData_603830, "OptionGroupName", newJString(OptionGroupName))
  add(query_603829, "Version", newJString(Version))
  result = call_603828.call(nil, query_603829, nil, formData_603830, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_603811(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_603812, base: "/",
    url: url_PostModifyOptionGroup_603813, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_603792 = ref object of OpenApiRestCall_601373
proc url_GetModifyOptionGroup_603794(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyOptionGroup_603793(path: JsonNode; query: JsonNode;
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
  var valid_603795 = query.getOrDefault("Action")
  valid_603795 = validateParameter(valid_603795, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_603795 != nil:
    section.add "Action", valid_603795
  var valid_603796 = query.getOrDefault("ApplyImmediately")
  valid_603796 = validateParameter(valid_603796, JBool, required = false, default = nil)
  if valid_603796 != nil:
    section.add "ApplyImmediately", valid_603796
  var valid_603797 = query.getOrDefault("OptionsToRemove")
  valid_603797 = validateParameter(valid_603797, JArray, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "OptionsToRemove", valid_603797
  var valid_603798 = query.getOrDefault("OptionsToInclude")
  valid_603798 = validateParameter(valid_603798, JArray, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "OptionsToInclude", valid_603798
  var valid_603799 = query.getOrDefault("OptionGroupName")
  valid_603799 = validateParameter(valid_603799, JString, required = true,
                                 default = nil)
  if valid_603799 != nil:
    section.add "OptionGroupName", valid_603799
  var valid_603800 = query.getOrDefault("Version")
  valid_603800 = validateParameter(valid_603800, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603800 != nil:
    section.add "Version", valid_603800
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603801 = header.getOrDefault("X-Amz-Signature")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Signature", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Content-Sha256", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Date")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Date", valid_603803
  var valid_603804 = header.getOrDefault("X-Amz-Credential")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "X-Amz-Credential", valid_603804
  var valid_603805 = header.getOrDefault("X-Amz-Security-Token")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-Security-Token", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-Algorithm")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Algorithm", valid_603806
  var valid_603807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "X-Amz-SignedHeaders", valid_603807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603808: Call_GetModifyOptionGroup_603792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603808.validator(path, query, header, formData, body)
  let scheme = call_603808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603808.url(scheme.get, call_603808.host, call_603808.base,
                         call_603808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603808, url, valid)

proc call*(call_603809: Call_GetModifyOptionGroup_603792; OptionGroupName: string;
          Action: string = "ModifyOptionGroup"; ApplyImmediately: bool = false;
          OptionsToRemove: JsonNode = nil; OptionsToInclude: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## getModifyOptionGroup
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_603810 = newJObject()
  add(query_603810, "Action", newJString(Action))
  add(query_603810, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_603810.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_603810.add "OptionsToInclude", OptionsToInclude
  add(query_603810, "OptionGroupName", newJString(OptionGroupName))
  add(query_603810, "Version", newJString(Version))
  result = call_603809.call(nil, query_603810, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_603792(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_603793, base: "/",
    url: url_GetModifyOptionGroup_603794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_603849 = ref object of OpenApiRestCall_601373
proc url_PostPromoteReadReplica_603851(protocol: Scheme; host: string; base: string;
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

proc validate_PostPromoteReadReplica_603850(path: JsonNode; query: JsonNode;
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
  var valid_603852 = query.getOrDefault("Action")
  valid_603852 = validateParameter(valid_603852, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_603852 != nil:
    section.add "Action", valid_603852
  var valid_603853 = query.getOrDefault("Version")
  valid_603853 = validateParameter(valid_603853, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603853 != nil:
    section.add "Version", valid_603853
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603854 = header.getOrDefault("X-Amz-Signature")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-Signature", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Content-Sha256", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-Date")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Date", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-Credential")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-Credential", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Security-Token")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Security-Token", valid_603858
  var valid_603859 = header.getOrDefault("X-Amz-Algorithm")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Algorithm", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-SignedHeaders", valid_603860
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_603861 = formData.getOrDefault("PreferredBackupWindow")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "PreferredBackupWindow", valid_603861
  var valid_603862 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603862 = validateParameter(valid_603862, JInt, required = false, default = nil)
  if valid_603862 != nil:
    section.add "BackupRetentionPeriod", valid_603862
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603863 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603863 = validateParameter(valid_603863, JString, required = true,
                                 default = nil)
  if valid_603863 != nil:
    section.add "DBInstanceIdentifier", valid_603863
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603864: Call_PostPromoteReadReplica_603849; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603864.validator(path, query, header, formData, body)
  let scheme = call_603864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603864.url(scheme.get, call_603864.host, call_603864.base,
                         call_603864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603864, url, valid)

proc call*(call_603865: Call_PostPromoteReadReplica_603849;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2014-09-01"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603866 = newJObject()
  var formData_603867 = newJObject()
  add(formData_603867, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603867, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603867, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603866, "Action", newJString(Action))
  add(query_603866, "Version", newJString(Version))
  result = call_603865.call(nil, query_603866, nil, formData_603867, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_603849(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_603850, base: "/",
    url: url_PostPromoteReadReplica_603851, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_603831 = ref object of OpenApiRestCall_601373
proc url_GetPromoteReadReplica_603833(protocol: Scheme; host: string; base: string;
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

proc validate_GetPromoteReadReplica_603832(path: JsonNode; query: JsonNode;
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
  var valid_603834 = query.getOrDefault("DBInstanceIdentifier")
  valid_603834 = validateParameter(valid_603834, JString, required = true,
                                 default = nil)
  if valid_603834 != nil:
    section.add "DBInstanceIdentifier", valid_603834
  var valid_603835 = query.getOrDefault("BackupRetentionPeriod")
  valid_603835 = validateParameter(valid_603835, JInt, required = false, default = nil)
  if valid_603835 != nil:
    section.add "BackupRetentionPeriod", valid_603835
  var valid_603836 = query.getOrDefault("Action")
  valid_603836 = validateParameter(valid_603836, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_603836 != nil:
    section.add "Action", valid_603836
  var valid_603837 = query.getOrDefault("Version")
  valid_603837 = validateParameter(valid_603837, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603837 != nil:
    section.add "Version", valid_603837
  var valid_603838 = query.getOrDefault("PreferredBackupWindow")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "PreferredBackupWindow", valid_603838
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603839 = header.getOrDefault("X-Amz-Signature")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Signature", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Content-Sha256", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Date")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Date", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-Credential")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-Credential", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-Security-Token")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-Security-Token", valid_603843
  var valid_603844 = header.getOrDefault("X-Amz-Algorithm")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-Algorithm", valid_603844
  var valid_603845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "X-Amz-SignedHeaders", valid_603845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603846: Call_GetPromoteReadReplica_603831; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603846.validator(path, query, header, formData, body)
  let scheme = call_603846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603846.url(scheme.get, call_603846.host, call_603846.base,
                         call_603846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603846, url, valid)

proc call*(call_603847: Call_GetPromoteReadReplica_603831;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2014-09-01";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_603848 = newJObject()
  add(query_603848, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603848, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603848, "Action", newJString(Action))
  add(query_603848, "Version", newJString(Version))
  add(query_603848, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_603847.call(nil, query_603848, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_603831(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_603832, base: "/",
    url: url_GetPromoteReadReplica_603833, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_603887 = ref object of OpenApiRestCall_601373
proc url_PostPurchaseReservedDBInstancesOffering_603889(protocol: Scheme;
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

proc validate_PostPurchaseReservedDBInstancesOffering_603888(path: JsonNode;
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
  var valid_603890 = query.getOrDefault("Action")
  valid_603890 = validateParameter(valid_603890, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_603890 != nil:
    section.add "Action", valid_603890
  var valid_603891 = query.getOrDefault("Version")
  valid_603891 = validateParameter(valid_603891, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_603899 = formData.getOrDefault("ReservedDBInstanceId")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "ReservedDBInstanceId", valid_603899
  var valid_603900 = formData.getOrDefault("Tags")
  valid_603900 = validateParameter(valid_603900, JArray, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "Tags", valid_603900
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_603901 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603901 = validateParameter(valid_603901, JString, required = true,
                                 default = nil)
  if valid_603901 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603901
  var valid_603902 = formData.getOrDefault("DBInstanceCount")
  valid_603902 = validateParameter(valid_603902, JInt, required = false, default = nil)
  if valid_603902 != nil:
    section.add "DBInstanceCount", valid_603902
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603903: Call_PostPurchaseReservedDBInstancesOffering_603887;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603903.validator(path, query, header, formData, body)
  let scheme = call_603903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603903.url(scheme.get, call_603903.host, call_603903.base,
                         call_603903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603903, url, valid)

proc call*(call_603904: Call_PostPurchaseReservedDBInstancesOffering_603887;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Tags: JsonNode = nil; Version: string = "2014-09-01"; DBInstanceCount: int = 0): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  ##   DBInstanceCount: int
  var query_603905 = newJObject()
  var formData_603906 = newJObject()
  add(formData_603906, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_603905, "Action", newJString(Action))
  if Tags != nil:
    formData_603906.add "Tags", Tags
  add(formData_603906, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603905, "Version", newJString(Version))
  add(formData_603906, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_603904.call(nil, query_603905, nil, formData_603906, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_603887(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_603888, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_603889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_603868 = ref object of OpenApiRestCall_601373
proc url_GetPurchaseReservedDBInstancesOffering_603870(protocol: Scheme;
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

proc validate_GetPurchaseReservedDBInstancesOffering_603869(path: JsonNode;
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
  var valid_603871 = query.getOrDefault("Tags")
  valid_603871 = validateParameter(valid_603871, JArray, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "Tags", valid_603871
  var valid_603872 = query.getOrDefault("DBInstanceCount")
  valid_603872 = validateParameter(valid_603872, JInt, required = false, default = nil)
  if valid_603872 != nil:
    section.add "DBInstanceCount", valid_603872
  var valid_603873 = query.getOrDefault("ReservedDBInstanceId")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "ReservedDBInstanceId", valid_603873
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603874 = query.getOrDefault("Action")
  valid_603874 = validateParameter(valid_603874, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_603874 != nil:
    section.add "Action", valid_603874
  var valid_603875 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_603875 = validateParameter(valid_603875, JString, required = true,
                                 default = nil)
  if valid_603875 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_603875
  var valid_603876 = query.getOrDefault("Version")
  valid_603876 = validateParameter(valid_603876, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603876 != nil:
    section.add "Version", valid_603876
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603877 = header.getOrDefault("X-Amz-Signature")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Signature", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Content-Sha256", valid_603878
  var valid_603879 = header.getOrDefault("X-Amz-Date")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "X-Amz-Date", valid_603879
  var valid_603880 = header.getOrDefault("X-Amz-Credential")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-Credential", valid_603880
  var valid_603881 = header.getOrDefault("X-Amz-Security-Token")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-Security-Token", valid_603881
  var valid_603882 = header.getOrDefault("X-Amz-Algorithm")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-Algorithm", valid_603882
  var valid_603883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-SignedHeaders", valid_603883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603884: Call_GetPurchaseReservedDBInstancesOffering_603868;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603884.validator(path, query, header, formData, body)
  let scheme = call_603884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603884.url(scheme.get, call_603884.host, call_603884.base,
                         call_603884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603884, url, valid)

proc call*(call_603885: Call_GetPurchaseReservedDBInstancesOffering_603868;
          ReservedDBInstancesOfferingId: string; Tags: JsonNode = nil;
          DBInstanceCount: int = 0; ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2014-09-01"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   Tags: JArray
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_603886 = newJObject()
  if Tags != nil:
    query_603886.add "Tags", Tags
  add(query_603886, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_603886, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_603886, "Action", newJString(Action))
  add(query_603886, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_603886, "Version", newJString(Version))
  result = call_603885.call(nil, query_603886, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_603868(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_603869, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_603870,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_603924 = ref object of OpenApiRestCall_601373
proc url_PostRebootDBInstance_603926(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebootDBInstance_603925(path: JsonNode; query: JsonNode;
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
  var valid_603927 = query.getOrDefault("Action")
  valid_603927 = validateParameter(valid_603927, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_603927 != nil:
    section.add "Action", valid_603927
  var valid_603928 = query.getOrDefault("Version")
  valid_603928 = validateParameter(valid_603928, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603928 != nil:
    section.add "Version", valid_603928
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603929 = header.getOrDefault("X-Amz-Signature")
  valid_603929 = validateParameter(valid_603929, JString, required = false,
                                 default = nil)
  if valid_603929 != nil:
    section.add "X-Amz-Signature", valid_603929
  var valid_603930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603930 = validateParameter(valid_603930, JString, required = false,
                                 default = nil)
  if valid_603930 != nil:
    section.add "X-Amz-Content-Sha256", valid_603930
  var valid_603931 = header.getOrDefault("X-Amz-Date")
  valid_603931 = validateParameter(valid_603931, JString, required = false,
                                 default = nil)
  if valid_603931 != nil:
    section.add "X-Amz-Date", valid_603931
  var valid_603932 = header.getOrDefault("X-Amz-Credential")
  valid_603932 = validateParameter(valid_603932, JString, required = false,
                                 default = nil)
  if valid_603932 != nil:
    section.add "X-Amz-Credential", valid_603932
  var valid_603933 = header.getOrDefault("X-Amz-Security-Token")
  valid_603933 = validateParameter(valid_603933, JString, required = false,
                                 default = nil)
  if valid_603933 != nil:
    section.add "X-Amz-Security-Token", valid_603933
  var valid_603934 = header.getOrDefault("X-Amz-Algorithm")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "X-Amz-Algorithm", valid_603934
  var valid_603935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-SignedHeaders", valid_603935
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_603936 = formData.getOrDefault("ForceFailover")
  valid_603936 = validateParameter(valid_603936, JBool, required = false, default = nil)
  if valid_603936 != nil:
    section.add "ForceFailover", valid_603936
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603937 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603937 = validateParameter(valid_603937, JString, required = true,
                                 default = nil)
  if valid_603937 != nil:
    section.add "DBInstanceIdentifier", valid_603937
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603938: Call_PostRebootDBInstance_603924; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603938.validator(path, query, header, formData, body)
  let scheme = call_603938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603938.url(scheme.get, call_603938.host, call_603938.base,
                         call_603938.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603938, url, valid)

proc call*(call_603939: Call_PostRebootDBInstance_603924;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2014-09-01"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603940 = newJObject()
  var formData_603941 = newJObject()
  add(formData_603941, "ForceFailover", newJBool(ForceFailover))
  add(formData_603941, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603940, "Action", newJString(Action))
  add(query_603940, "Version", newJString(Version))
  result = call_603939.call(nil, query_603940, nil, formData_603941, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_603924(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_603925, base: "/",
    url: url_PostRebootDBInstance_603926, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_603907 = ref object of OpenApiRestCall_601373
proc url_GetRebootDBInstance_603909(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebootDBInstance_603908(path: JsonNode; query: JsonNode;
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
  var valid_603910 = query.getOrDefault("ForceFailover")
  valid_603910 = validateParameter(valid_603910, JBool, required = false, default = nil)
  if valid_603910 != nil:
    section.add "ForceFailover", valid_603910
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603911 = query.getOrDefault("DBInstanceIdentifier")
  valid_603911 = validateParameter(valid_603911, JString, required = true,
                                 default = nil)
  if valid_603911 != nil:
    section.add "DBInstanceIdentifier", valid_603911
  var valid_603912 = query.getOrDefault("Action")
  valid_603912 = validateParameter(valid_603912, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_603912 != nil:
    section.add "Action", valid_603912
  var valid_603913 = query.getOrDefault("Version")
  valid_603913 = validateParameter(valid_603913, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603913 != nil:
    section.add "Version", valid_603913
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603914 = header.getOrDefault("X-Amz-Signature")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-Signature", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Content-Sha256", valid_603915
  var valid_603916 = header.getOrDefault("X-Amz-Date")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-Date", valid_603916
  var valid_603917 = header.getOrDefault("X-Amz-Credential")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-Credential", valid_603917
  var valid_603918 = header.getOrDefault("X-Amz-Security-Token")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-Security-Token", valid_603918
  var valid_603919 = header.getOrDefault("X-Amz-Algorithm")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Algorithm", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-SignedHeaders", valid_603920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603921: Call_GetRebootDBInstance_603907; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603921.validator(path, query, header, formData, body)
  let scheme = call_603921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603921.url(scheme.get, call_603921.host, call_603921.base,
                         call_603921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603921, url, valid)

proc call*(call_603922: Call_GetRebootDBInstance_603907;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2014-09-01"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603923 = newJObject()
  add(query_603923, "ForceFailover", newJBool(ForceFailover))
  add(query_603923, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603923, "Action", newJString(Action))
  add(query_603923, "Version", newJString(Version))
  result = call_603922.call(nil, query_603923, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_603907(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_603908, base: "/",
    url: url_GetRebootDBInstance_603909, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_603959 = ref object of OpenApiRestCall_601373
proc url_PostRemoveSourceIdentifierFromSubscription_603961(protocol: Scheme;
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

proc validate_PostRemoveSourceIdentifierFromSubscription_603960(path: JsonNode;
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
      "RemoveSourceIdentifierFromSubscription"))
  if valid_603962 != nil:
    section.add "Action", valid_603962
  var valid_603963 = query.getOrDefault("Version")
  valid_603963 = validateParameter(valid_603963, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_603971 = formData.getOrDefault("SubscriptionName")
  valid_603971 = validateParameter(valid_603971, JString, required = true,
                                 default = nil)
  if valid_603971 != nil:
    section.add "SubscriptionName", valid_603971
  var valid_603972 = formData.getOrDefault("SourceIdentifier")
  valid_603972 = validateParameter(valid_603972, JString, required = true,
                                 default = nil)
  if valid_603972 != nil:
    section.add "SourceIdentifier", valid_603972
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603973: Call_PostRemoveSourceIdentifierFromSubscription_603959;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603973.validator(path, query, header, formData, body)
  let scheme = call_603973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603973.url(scheme.get, call_603973.host, call_603973.base,
                         call_603973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603973, url, valid)

proc call*(call_603974: Call_PostRemoveSourceIdentifierFromSubscription_603959;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603975 = newJObject()
  var formData_603976 = newJObject()
  add(formData_603976, "SubscriptionName", newJString(SubscriptionName))
  add(formData_603976, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_603975, "Action", newJString(Action))
  add(query_603975, "Version", newJString(Version))
  result = call_603974.call(nil, query_603975, nil, formData_603976, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_603959(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_603960,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_603961,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_603942 = ref object of OpenApiRestCall_601373
proc url_GetRemoveSourceIdentifierFromSubscription_603944(protocol: Scheme;
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

proc validate_GetRemoveSourceIdentifierFromSubscription_603943(path: JsonNode;
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
  var valid_603945 = query.getOrDefault("SourceIdentifier")
  valid_603945 = validateParameter(valid_603945, JString, required = true,
                                 default = nil)
  if valid_603945 != nil:
    section.add "SourceIdentifier", valid_603945
  var valid_603946 = query.getOrDefault("SubscriptionName")
  valid_603946 = validateParameter(valid_603946, JString, required = true,
                                 default = nil)
  if valid_603946 != nil:
    section.add "SubscriptionName", valid_603946
  var valid_603947 = query.getOrDefault("Action")
  valid_603947 = validateParameter(valid_603947, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_603947 != nil:
    section.add "Action", valid_603947
  var valid_603948 = query.getOrDefault("Version")
  valid_603948 = validateParameter(valid_603948, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603948 != nil:
    section.add "Version", valid_603948
  result.add "query", section
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

proc call*(call_603956: Call_GetRemoveSourceIdentifierFromSubscription_603942;
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

proc call*(call_603957: Call_GetRemoveSourceIdentifierFromSubscription_603942;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603958 = newJObject()
  add(query_603958, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_603958, "SubscriptionName", newJString(SubscriptionName))
  add(query_603958, "Action", newJString(Action))
  add(query_603958, "Version", newJString(Version))
  result = call_603957.call(nil, query_603958, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_603942(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_603943,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_603944,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_603994 = ref object of OpenApiRestCall_601373
proc url_PostRemoveTagsFromResource_603996(protocol: Scheme; host: string;
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

proc validate_PostRemoveTagsFromResource_603995(path: JsonNode; query: JsonNode;
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
  var valid_603997 = query.getOrDefault("Action")
  valid_603997 = validateParameter(valid_603997, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_603997 != nil:
    section.add "Action", valid_603997
  var valid_603998 = query.getOrDefault("Version")
  valid_603998 = validateParameter(valid_603998, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603998 != nil:
    section.add "Version", valid_603998
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603999 = header.getOrDefault("X-Amz-Signature")
  valid_603999 = validateParameter(valid_603999, JString, required = false,
                                 default = nil)
  if valid_603999 != nil:
    section.add "X-Amz-Signature", valid_603999
  var valid_604000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-Content-Sha256", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-Date")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Date", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-Credential")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-Credential", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-Security-Token")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-Security-Token", valid_604003
  var valid_604004 = header.getOrDefault("X-Amz-Algorithm")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-Algorithm", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-SignedHeaders", valid_604005
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_604006 = formData.getOrDefault("TagKeys")
  valid_604006 = validateParameter(valid_604006, JArray, required = true, default = nil)
  if valid_604006 != nil:
    section.add "TagKeys", valid_604006
  var valid_604007 = formData.getOrDefault("ResourceName")
  valid_604007 = validateParameter(valid_604007, JString, required = true,
                                 default = nil)
  if valid_604007 != nil:
    section.add "ResourceName", valid_604007
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604008: Call_PostRemoveTagsFromResource_603994; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604008.validator(path, query, header, formData, body)
  let scheme = call_604008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604008.url(scheme.get, call_604008.host, call_604008.base,
                         call_604008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604008, url, valid)

proc call*(call_604009: Call_PostRemoveTagsFromResource_603994; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_604010 = newJObject()
  var formData_604011 = newJObject()
  if TagKeys != nil:
    formData_604011.add "TagKeys", TagKeys
  add(query_604010, "Action", newJString(Action))
  add(query_604010, "Version", newJString(Version))
  add(formData_604011, "ResourceName", newJString(ResourceName))
  result = call_604009.call(nil, query_604010, nil, formData_604011, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_603994(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_603995, base: "/",
    url: url_PostRemoveTagsFromResource_603996,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_603977 = ref object of OpenApiRestCall_601373
proc url_GetRemoveTagsFromResource_603979(protocol: Scheme; host: string;
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

proc validate_GetRemoveTagsFromResource_603978(path: JsonNode; query: JsonNode;
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
  var valid_603980 = query.getOrDefault("ResourceName")
  valid_603980 = validateParameter(valid_603980, JString, required = true,
                                 default = nil)
  if valid_603980 != nil:
    section.add "ResourceName", valid_603980
  var valid_603981 = query.getOrDefault("TagKeys")
  valid_603981 = validateParameter(valid_603981, JArray, required = true, default = nil)
  if valid_603981 != nil:
    section.add "TagKeys", valid_603981
  var valid_603982 = query.getOrDefault("Action")
  valid_603982 = validateParameter(valid_603982, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_603982 != nil:
    section.add "Action", valid_603982
  var valid_603983 = query.getOrDefault("Version")
  valid_603983 = validateParameter(valid_603983, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603983 != nil:
    section.add "Version", valid_603983
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603984 = header.getOrDefault("X-Amz-Signature")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Signature", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Content-Sha256", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Date")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Date", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Credential")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Credential", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-Security-Token")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-Security-Token", valid_603988
  var valid_603989 = header.getOrDefault("X-Amz-Algorithm")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-Algorithm", valid_603989
  var valid_603990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-SignedHeaders", valid_603990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603991: Call_GetRemoveTagsFromResource_603977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603991.validator(path, query, header, formData, body)
  let scheme = call_603991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603991.url(scheme.get, call_603991.host, call_603991.base,
                         call_603991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603991, url, valid)

proc call*(call_603992: Call_GetRemoveTagsFromResource_603977;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-09-01"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603993 = newJObject()
  add(query_603993, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_603993.add "TagKeys", TagKeys
  add(query_603993, "Action", newJString(Action))
  add(query_603993, "Version", newJString(Version))
  result = call_603992.call(nil, query_603993, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_603977(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_603978, base: "/",
    url: url_GetRemoveTagsFromResource_603979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_604030 = ref object of OpenApiRestCall_601373
proc url_PostResetDBParameterGroup_604032(protocol: Scheme; host: string;
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

proc validate_PostResetDBParameterGroup_604031(path: JsonNode; query: JsonNode;
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
  var valid_604033 = query.getOrDefault("Action")
  valid_604033 = validateParameter(valid_604033, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_604033 != nil:
    section.add "Action", valid_604033
  var valid_604034 = query.getOrDefault("Version")
  valid_604034 = validateParameter(valid_604034, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604034 != nil:
    section.add "Version", valid_604034
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604035 = header.getOrDefault("X-Amz-Signature")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "X-Amz-Signature", valid_604035
  var valid_604036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-Content-Sha256", valid_604036
  var valid_604037 = header.getOrDefault("X-Amz-Date")
  valid_604037 = validateParameter(valid_604037, JString, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "X-Amz-Date", valid_604037
  var valid_604038 = header.getOrDefault("X-Amz-Credential")
  valid_604038 = validateParameter(valid_604038, JString, required = false,
                                 default = nil)
  if valid_604038 != nil:
    section.add "X-Amz-Credential", valid_604038
  var valid_604039 = header.getOrDefault("X-Amz-Security-Token")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-Security-Token", valid_604039
  var valid_604040 = header.getOrDefault("X-Amz-Algorithm")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Algorithm", valid_604040
  var valid_604041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-SignedHeaders", valid_604041
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_604042 = formData.getOrDefault("ResetAllParameters")
  valid_604042 = validateParameter(valid_604042, JBool, required = false, default = nil)
  if valid_604042 != nil:
    section.add "ResetAllParameters", valid_604042
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_604043 = formData.getOrDefault("DBParameterGroupName")
  valid_604043 = validateParameter(valid_604043, JString, required = true,
                                 default = nil)
  if valid_604043 != nil:
    section.add "DBParameterGroupName", valid_604043
  var valid_604044 = formData.getOrDefault("Parameters")
  valid_604044 = validateParameter(valid_604044, JArray, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "Parameters", valid_604044
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604045: Call_PostResetDBParameterGroup_604030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604045.validator(path, query, header, formData, body)
  let scheme = call_604045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604045.url(scheme.get, call_604045.host, call_604045.base,
                         call_604045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604045, url, valid)

proc call*(call_604046: Call_PostResetDBParameterGroup_604030;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_604047 = newJObject()
  var formData_604048 = newJObject()
  add(formData_604048, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_604048, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_604047, "Action", newJString(Action))
  if Parameters != nil:
    formData_604048.add "Parameters", Parameters
  add(query_604047, "Version", newJString(Version))
  result = call_604046.call(nil, query_604047, nil, formData_604048, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_604030(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_604031, base: "/",
    url: url_PostResetDBParameterGroup_604032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_604012 = ref object of OpenApiRestCall_601373
proc url_GetResetDBParameterGroup_604014(protocol: Scheme; host: string;
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

proc validate_GetResetDBParameterGroup_604013(path: JsonNode; query: JsonNode;
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
  var valid_604015 = query.getOrDefault("DBParameterGroupName")
  valid_604015 = validateParameter(valid_604015, JString, required = true,
                                 default = nil)
  if valid_604015 != nil:
    section.add "DBParameterGroupName", valid_604015
  var valid_604016 = query.getOrDefault("Parameters")
  valid_604016 = validateParameter(valid_604016, JArray, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "Parameters", valid_604016
  var valid_604017 = query.getOrDefault("ResetAllParameters")
  valid_604017 = validateParameter(valid_604017, JBool, required = false, default = nil)
  if valid_604017 != nil:
    section.add "ResetAllParameters", valid_604017
  var valid_604018 = query.getOrDefault("Action")
  valid_604018 = validateParameter(valid_604018, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_604018 != nil:
    section.add "Action", valid_604018
  var valid_604019 = query.getOrDefault("Version")
  valid_604019 = validateParameter(valid_604019, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604019 != nil:
    section.add "Version", valid_604019
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604020 = header.getOrDefault("X-Amz-Signature")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Signature", valid_604020
  var valid_604021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-Content-Sha256", valid_604021
  var valid_604022 = header.getOrDefault("X-Amz-Date")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "X-Amz-Date", valid_604022
  var valid_604023 = header.getOrDefault("X-Amz-Credential")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "X-Amz-Credential", valid_604023
  var valid_604024 = header.getOrDefault("X-Amz-Security-Token")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "X-Amz-Security-Token", valid_604024
  var valid_604025 = header.getOrDefault("X-Amz-Algorithm")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-Algorithm", valid_604025
  var valid_604026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "X-Amz-SignedHeaders", valid_604026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604027: Call_GetResetDBParameterGroup_604012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604027.validator(path, query, header, formData, body)
  let scheme = call_604027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604027.url(scheme.get, call_604027.host, call_604027.base,
                         call_604027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604027, url, valid)

proc call*(call_604028: Call_GetResetDBParameterGroup_604012;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604029 = newJObject()
  add(query_604029, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_604029.add "Parameters", Parameters
  add(query_604029, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_604029, "Action", newJString(Action))
  add(query_604029, "Version", newJString(Version))
  result = call_604028.call(nil, query_604029, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_604012(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_604013, base: "/",
    url: url_GetResetDBParameterGroup_604014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_604082 = ref object of OpenApiRestCall_601373
proc url_PostRestoreDBInstanceFromDBSnapshot_604084(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceFromDBSnapshot_604083(path: JsonNode;
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
  var valid_604085 = query.getOrDefault("Action")
  valid_604085 = validateParameter(valid_604085, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_604085 != nil:
    section.add "Action", valid_604085
  var valid_604086 = query.getOrDefault("Version")
  valid_604086 = validateParameter(valid_604086, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604086 != nil:
    section.add "Version", valid_604086
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604087 = header.getOrDefault("X-Amz-Signature")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "X-Amz-Signature", valid_604087
  var valid_604088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "X-Amz-Content-Sha256", valid_604088
  var valid_604089 = header.getOrDefault("X-Amz-Date")
  valid_604089 = validateParameter(valid_604089, JString, required = false,
                                 default = nil)
  if valid_604089 != nil:
    section.add "X-Amz-Date", valid_604089
  var valid_604090 = header.getOrDefault("X-Amz-Credential")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "X-Amz-Credential", valid_604090
  var valid_604091 = header.getOrDefault("X-Amz-Security-Token")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "X-Amz-Security-Token", valid_604091
  var valid_604092 = header.getOrDefault("X-Amz-Algorithm")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "X-Amz-Algorithm", valid_604092
  var valid_604093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-SignedHeaders", valid_604093
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   AvailabilityZone: JString
  ##   Engine: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   TdeCredentialPassword: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   DBName: JString
  ##   Iops: JInt
  ##   TdeCredentialArn: JString
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   StorageType: JString
  section = newJObject()
  var valid_604094 = formData.getOrDefault("Port")
  valid_604094 = validateParameter(valid_604094, JInt, required = false, default = nil)
  if valid_604094 != nil:
    section.add "Port", valid_604094
  var valid_604095 = formData.getOrDefault("DBInstanceClass")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "DBInstanceClass", valid_604095
  var valid_604096 = formData.getOrDefault("MultiAZ")
  valid_604096 = validateParameter(valid_604096, JBool, required = false, default = nil)
  if valid_604096 != nil:
    section.add "MultiAZ", valid_604096
  var valid_604097 = formData.getOrDefault("AvailabilityZone")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "AvailabilityZone", valid_604097
  var valid_604098 = formData.getOrDefault("Engine")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "Engine", valid_604098
  var valid_604099 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604099 = validateParameter(valid_604099, JBool, required = false, default = nil)
  if valid_604099 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604099
  var valid_604100 = formData.getOrDefault("TdeCredentialPassword")
  valid_604100 = validateParameter(valid_604100, JString, required = false,
                                 default = nil)
  if valid_604100 != nil:
    section.add "TdeCredentialPassword", valid_604100
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604101 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604101 = validateParameter(valid_604101, JString, required = true,
                                 default = nil)
  if valid_604101 != nil:
    section.add "DBInstanceIdentifier", valid_604101
  var valid_604102 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_604102 = validateParameter(valid_604102, JString, required = true,
                                 default = nil)
  if valid_604102 != nil:
    section.add "DBSnapshotIdentifier", valid_604102
  var valid_604103 = formData.getOrDefault("DBName")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "DBName", valid_604103
  var valid_604104 = formData.getOrDefault("Iops")
  valid_604104 = validateParameter(valid_604104, JInt, required = false, default = nil)
  if valid_604104 != nil:
    section.add "Iops", valid_604104
  var valid_604105 = formData.getOrDefault("TdeCredentialArn")
  valid_604105 = validateParameter(valid_604105, JString, required = false,
                                 default = nil)
  if valid_604105 != nil:
    section.add "TdeCredentialArn", valid_604105
  var valid_604106 = formData.getOrDefault("PubliclyAccessible")
  valid_604106 = validateParameter(valid_604106, JBool, required = false, default = nil)
  if valid_604106 != nil:
    section.add "PubliclyAccessible", valid_604106
  var valid_604107 = formData.getOrDefault("LicenseModel")
  valid_604107 = validateParameter(valid_604107, JString, required = false,
                                 default = nil)
  if valid_604107 != nil:
    section.add "LicenseModel", valid_604107
  var valid_604108 = formData.getOrDefault("Tags")
  valid_604108 = validateParameter(valid_604108, JArray, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "Tags", valid_604108
  var valid_604109 = formData.getOrDefault("DBSubnetGroupName")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "DBSubnetGroupName", valid_604109
  var valid_604110 = formData.getOrDefault("OptionGroupName")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "OptionGroupName", valid_604110
  var valid_604111 = formData.getOrDefault("StorageType")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "StorageType", valid_604111
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604112: Call_PostRestoreDBInstanceFromDBSnapshot_604082;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604112.validator(path, query, header, formData, body)
  let scheme = call_604112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604112.url(scheme.get, call_604112.host, call_604112.base,
                         call_604112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604112, url, valid)

proc call*(call_604113: Call_PostRestoreDBInstanceFromDBSnapshot_604082;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false; TdeCredentialPassword: string = "";
          DBName: string = ""; Iops: int = 0; TdeCredentialArn: string = "";
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          LicenseModel: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          Version: string = "2014-09-01"; StorageType: string = ""): Recallable =
  ## postRestoreDBInstanceFromDBSnapshot
  ##   Port: int
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   AvailabilityZone: string
  ##   Engine: string
  ##   AutoMinorVersionUpgrade: bool
  ##   TdeCredentialPassword: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   DBName: string
  ##   Iops: int
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   StorageType: string
  var query_604114 = newJObject()
  var formData_604115 = newJObject()
  add(formData_604115, "Port", newJInt(Port))
  add(formData_604115, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604115, "MultiAZ", newJBool(MultiAZ))
  add(formData_604115, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_604115, "Engine", newJString(Engine))
  add(formData_604115, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_604115, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_604115, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604115, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_604115, "DBName", newJString(DBName))
  add(formData_604115, "Iops", newJInt(Iops))
  add(formData_604115, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_604115, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_604114, "Action", newJString(Action))
  add(formData_604115, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_604115.add "Tags", Tags
  add(formData_604115, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_604115, "OptionGroupName", newJString(OptionGroupName))
  add(query_604114, "Version", newJString(Version))
  add(formData_604115, "StorageType", newJString(StorageType))
  result = call_604113.call(nil, query_604114, nil, formData_604115, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_604082(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_604083, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_604084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_604049 = ref object of OpenApiRestCall_601373
proc url_GetRestoreDBInstanceFromDBSnapshot_604051(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceFromDBSnapshot_604050(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   TdeCredentialPassword: JString
  ##   Engine: JString
  ##   Tags: JArray
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   TdeCredentialArn: JString
  ##   StorageType: JString
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
  var valid_604052 = query.getOrDefault("DBName")
  valid_604052 = validateParameter(valid_604052, JString, required = false,
                                 default = nil)
  if valid_604052 != nil:
    section.add "DBName", valid_604052
  var valid_604053 = query.getOrDefault("TdeCredentialPassword")
  valid_604053 = validateParameter(valid_604053, JString, required = false,
                                 default = nil)
  if valid_604053 != nil:
    section.add "TdeCredentialPassword", valid_604053
  var valid_604054 = query.getOrDefault("Engine")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "Engine", valid_604054
  var valid_604055 = query.getOrDefault("Tags")
  valid_604055 = validateParameter(valid_604055, JArray, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "Tags", valid_604055
  var valid_604056 = query.getOrDefault("LicenseModel")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "LicenseModel", valid_604056
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604057 = query.getOrDefault("DBInstanceIdentifier")
  valid_604057 = validateParameter(valid_604057, JString, required = true,
                                 default = nil)
  if valid_604057 != nil:
    section.add "DBInstanceIdentifier", valid_604057
  var valid_604058 = query.getOrDefault("DBSnapshotIdentifier")
  valid_604058 = validateParameter(valid_604058, JString, required = true,
                                 default = nil)
  if valid_604058 != nil:
    section.add "DBSnapshotIdentifier", valid_604058
  var valid_604059 = query.getOrDefault("TdeCredentialArn")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "TdeCredentialArn", valid_604059
  var valid_604060 = query.getOrDefault("StorageType")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "StorageType", valid_604060
  var valid_604061 = query.getOrDefault("Action")
  valid_604061 = validateParameter(valid_604061, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_604061 != nil:
    section.add "Action", valid_604061
  var valid_604062 = query.getOrDefault("MultiAZ")
  valid_604062 = validateParameter(valid_604062, JBool, required = false, default = nil)
  if valid_604062 != nil:
    section.add "MultiAZ", valid_604062
  var valid_604063 = query.getOrDefault("Port")
  valid_604063 = validateParameter(valid_604063, JInt, required = false, default = nil)
  if valid_604063 != nil:
    section.add "Port", valid_604063
  var valid_604064 = query.getOrDefault("AvailabilityZone")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "AvailabilityZone", valid_604064
  var valid_604065 = query.getOrDefault("OptionGroupName")
  valid_604065 = validateParameter(valid_604065, JString, required = false,
                                 default = nil)
  if valid_604065 != nil:
    section.add "OptionGroupName", valid_604065
  var valid_604066 = query.getOrDefault("DBSubnetGroupName")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "DBSubnetGroupName", valid_604066
  var valid_604067 = query.getOrDefault("Version")
  valid_604067 = validateParameter(valid_604067, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604067 != nil:
    section.add "Version", valid_604067
  var valid_604068 = query.getOrDefault("DBInstanceClass")
  valid_604068 = validateParameter(valid_604068, JString, required = false,
                                 default = nil)
  if valid_604068 != nil:
    section.add "DBInstanceClass", valid_604068
  var valid_604069 = query.getOrDefault("PubliclyAccessible")
  valid_604069 = validateParameter(valid_604069, JBool, required = false, default = nil)
  if valid_604069 != nil:
    section.add "PubliclyAccessible", valid_604069
  var valid_604070 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604070 = validateParameter(valid_604070, JBool, required = false, default = nil)
  if valid_604070 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604070
  var valid_604071 = query.getOrDefault("Iops")
  valid_604071 = validateParameter(valid_604071, JInt, required = false, default = nil)
  if valid_604071 != nil:
    section.add "Iops", valid_604071
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604072 = header.getOrDefault("X-Amz-Signature")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-Signature", valid_604072
  var valid_604073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-Content-Sha256", valid_604073
  var valid_604074 = header.getOrDefault("X-Amz-Date")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "X-Amz-Date", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-Credential")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Credential", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-Security-Token")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Security-Token", valid_604076
  var valid_604077 = header.getOrDefault("X-Amz-Algorithm")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-Algorithm", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-SignedHeaders", valid_604078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604079: Call_GetRestoreDBInstanceFromDBSnapshot_604049;
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

proc call*(call_604080: Call_GetRestoreDBInstanceFromDBSnapshot_604049;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          DBName: string = ""; TdeCredentialPassword: string = ""; Engine: string = "";
          Tags: JsonNode = nil; LicenseModel: string = "";
          TdeCredentialArn: string = ""; StorageType: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2014-09-01";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   DBName: string
  ##   TdeCredentialPassword: string
  ##   Engine: string
  ##   Tags: JArray
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   TdeCredentialArn: string
  ##   StorageType: string
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
  var query_604081 = newJObject()
  add(query_604081, "DBName", newJString(DBName))
  add(query_604081, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_604081, "Engine", newJString(Engine))
  if Tags != nil:
    query_604081.add "Tags", Tags
  add(query_604081, "LicenseModel", newJString(LicenseModel))
  add(query_604081, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604081, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_604081, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_604081, "StorageType", newJString(StorageType))
  add(query_604081, "Action", newJString(Action))
  add(query_604081, "MultiAZ", newJBool(MultiAZ))
  add(query_604081, "Port", newJInt(Port))
  add(query_604081, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_604081, "OptionGroupName", newJString(OptionGroupName))
  add(query_604081, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604081, "Version", newJString(Version))
  add(query_604081, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604081, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_604081, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604081, "Iops", newJInt(Iops))
  result = call_604080.call(nil, query_604081, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_604049(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_604050, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_604051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_604151 = ref object of OpenApiRestCall_601373
proc url_PostRestoreDBInstanceToPointInTime_604153(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceToPointInTime_604152(path: JsonNode;
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
  var valid_604154 = query.getOrDefault("Action")
  valid_604154 = validateParameter(valid_604154, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_604154 != nil:
    section.add "Action", valid_604154
  var valid_604155 = query.getOrDefault("Version")
  valid_604155 = validateParameter(valid_604155, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604155 != nil:
    section.add "Version", valid_604155
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604156 = header.getOrDefault("X-Amz-Signature")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "X-Amz-Signature", valid_604156
  var valid_604157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "X-Amz-Content-Sha256", valid_604157
  var valid_604158 = header.getOrDefault("X-Amz-Date")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "X-Amz-Date", valid_604158
  var valid_604159 = header.getOrDefault("X-Amz-Credential")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Credential", valid_604159
  var valid_604160 = header.getOrDefault("X-Amz-Security-Token")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "X-Amz-Security-Token", valid_604160
  var valid_604161 = header.getOrDefault("X-Amz-Algorithm")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "X-Amz-Algorithm", valid_604161
  var valid_604162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-SignedHeaders", valid_604162
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AvailabilityZone: JString
  ##   Engine: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   TdeCredentialPassword: JString
  ##   UseLatestRestorableTime: JBool
  ##   DBName: JString
  ##   Iops: JInt
  ##   TdeCredentialArn: JString
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   RestoreTime: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   StorageType: JString
  section = newJObject()
  var valid_604163 = formData.getOrDefault("Port")
  valid_604163 = validateParameter(valid_604163, JInt, required = false, default = nil)
  if valid_604163 != nil:
    section.add "Port", valid_604163
  var valid_604164 = formData.getOrDefault("DBInstanceClass")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "DBInstanceClass", valid_604164
  var valid_604165 = formData.getOrDefault("MultiAZ")
  valid_604165 = validateParameter(valid_604165, JBool, required = false, default = nil)
  if valid_604165 != nil:
    section.add "MultiAZ", valid_604165
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_604166 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_604166 = validateParameter(valid_604166, JString, required = true,
                                 default = nil)
  if valid_604166 != nil:
    section.add "SourceDBInstanceIdentifier", valid_604166
  var valid_604167 = formData.getOrDefault("AvailabilityZone")
  valid_604167 = validateParameter(valid_604167, JString, required = false,
                                 default = nil)
  if valid_604167 != nil:
    section.add "AvailabilityZone", valid_604167
  var valid_604168 = formData.getOrDefault("Engine")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "Engine", valid_604168
  var valid_604169 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604169 = validateParameter(valid_604169, JBool, required = false, default = nil)
  if valid_604169 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604169
  var valid_604170 = formData.getOrDefault("TdeCredentialPassword")
  valid_604170 = validateParameter(valid_604170, JString, required = false,
                                 default = nil)
  if valid_604170 != nil:
    section.add "TdeCredentialPassword", valid_604170
  var valid_604171 = formData.getOrDefault("UseLatestRestorableTime")
  valid_604171 = validateParameter(valid_604171, JBool, required = false, default = nil)
  if valid_604171 != nil:
    section.add "UseLatestRestorableTime", valid_604171
  var valid_604172 = formData.getOrDefault("DBName")
  valid_604172 = validateParameter(valid_604172, JString, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "DBName", valid_604172
  var valid_604173 = formData.getOrDefault("Iops")
  valid_604173 = validateParameter(valid_604173, JInt, required = false, default = nil)
  if valid_604173 != nil:
    section.add "Iops", valid_604173
  var valid_604174 = formData.getOrDefault("TdeCredentialArn")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "TdeCredentialArn", valid_604174
  var valid_604175 = formData.getOrDefault("PubliclyAccessible")
  valid_604175 = validateParameter(valid_604175, JBool, required = false, default = nil)
  if valid_604175 != nil:
    section.add "PubliclyAccessible", valid_604175
  var valid_604176 = formData.getOrDefault("LicenseModel")
  valid_604176 = validateParameter(valid_604176, JString, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "LicenseModel", valid_604176
  var valid_604177 = formData.getOrDefault("Tags")
  valid_604177 = validateParameter(valid_604177, JArray, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "Tags", valid_604177
  var valid_604178 = formData.getOrDefault("DBSubnetGroupName")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "DBSubnetGroupName", valid_604178
  var valid_604179 = formData.getOrDefault("OptionGroupName")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "OptionGroupName", valid_604179
  var valid_604180 = formData.getOrDefault("RestoreTime")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "RestoreTime", valid_604180
  var valid_604181 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_604181 = validateParameter(valid_604181, JString, required = true,
                                 default = nil)
  if valid_604181 != nil:
    section.add "TargetDBInstanceIdentifier", valid_604181
  var valid_604182 = formData.getOrDefault("StorageType")
  valid_604182 = validateParameter(valid_604182, JString, required = false,
                                 default = nil)
  if valid_604182 != nil:
    section.add "StorageType", valid_604182
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604183: Call_PostRestoreDBInstanceToPointInTime_604151;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604183.validator(path, query, header, formData, body)
  let scheme = call_604183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604183.url(scheme.get, call_604183.host, call_604183.base,
                         call_604183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604183, url, valid)

proc call*(call_604184: Call_PostRestoreDBInstanceToPointInTime_604151;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false; TdeCredentialPassword: string = "";
          UseLatestRestorableTime: bool = false; DBName: string = ""; Iops: int = 0;
          TdeCredentialArn: string = ""; PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          LicenseModel: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          RestoreTime: string = ""; Version: string = "2014-09-01";
          StorageType: string = ""): Recallable =
  ## postRestoreDBInstanceToPointInTime
  ##   Port: int
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AvailabilityZone: string
  ##   Engine: string
  ##   AutoMinorVersionUpgrade: bool
  ##   TdeCredentialPassword: string
  ##   UseLatestRestorableTime: bool
  ##   DBName: string
  ##   Iops: int
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   RestoreTime: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   StorageType: string
  var query_604185 = newJObject()
  var formData_604186 = newJObject()
  add(formData_604186, "Port", newJInt(Port))
  add(formData_604186, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604186, "MultiAZ", newJBool(MultiAZ))
  add(formData_604186, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_604186, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_604186, "Engine", newJString(Engine))
  add(formData_604186, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_604186, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_604186, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_604186, "DBName", newJString(DBName))
  add(formData_604186, "Iops", newJInt(Iops))
  add(formData_604186, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_604186, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_604185, "Action", newJString(Action))
  add(formData_604186, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_604186.add "Tags", Tags
  add(formData_604186, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_604186, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604186, "RestoreTime", newJString(RestoreTime))
  add(formData_604186, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_604185, "Version", newJString(Version))
  add(formData_604186, "StorageType", newJString(StorageType))
  result = call_604184.call(nil, query_604185, nil, formData_604186, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_604151(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_604152, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_604153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_604116 = ref object of OpenApiRestCall_601373
proc url_GetRestoreDBInstanceToPointInTime_604118(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceToPointInTime_604117(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   TdeCredentialPassword: JString
  ##   Engine: JString
  ##   UseLatestRestorableTime: JBool
  ##   Tags: JArray
  ##   LicenseModel: JString
  ##   TdeCredentialArn: JString
  ##   StorageType: JString
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
  var valid_604119 = query.getOrDefault("DBName")
  valid_604119 = validateParameter(valid_604119, JString, required = false,
                                 default = nil)
  if valid_604119 != nil:
    section.add "DBName", valid_604119
  var valid_604120 = query.getOrDefault("TdeCredentialPassword")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "TdeCredentialPassword", valid_604120
  var valid_604121 = query.getOrDefault("Engine")
  valid_604121 = validateParameter(valid_604121, JString, required = false,
                                 default = nil)
  if valid_604121 != nil:
    section.add "Engine", valid_604121
  var valid_604122 = query.getOrDefault("UseLatestRestorableTime")
  valid_604122 = validateParameter(valid_604122, JBool, required = false, default = nil)
  if valid_604122 != nil:
    section.add "UseLatestRestorableTime", valid_604122
  var valid_604123 = query.getOrDefault("Tags")
  valid_604123 = validateParameter(valid_604123, JArray, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "Tags", valid_604123
  var valid_604124 = query.getOrDefault("LicenseModel")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "LicenseModel", valid_604124
  var valid_604125 = query.getOrDefault("TdeCredentialArn")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "TdeCredentialArn", valid_604125
  var valid_604126 = query.getOrDefault("StorageType")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "StorageType", valid_604126
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_604127 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_604127 = validateParameter(valid_604127, JString, required = true,
                                 default = nil)
  if valid_604127 != nil:
    section.add "TargetDBInstanceIdentifier", valid_604127
  var valid_604128 = query.getOrDefault("Action")
  valid_604128 = validateParameter(valid_604128, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_604128 != nil:
    section.add "Action", valid_604128
  var valid_604129 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_604129 = validateParameter(valid_604129, JString, required = true,
                                 default = nil)
  if valid_604129 != nil:
    section.add "SourceDBInstanceIdentifier", valid_604129
  var valid_604130 = query.getOrDefault("MultiAZ")
  valid_604130 = validateParameter(valid_604130, JBool, required = false, default = nil)
  if valid_604130 != nil:
    section.add "MultiAZ", valid_604130
  var valid_604131 = query.getOrDefault("Port")
  valid_604131 = validateParameter(valid_604131, JInt, required = false, default = nil)
  if valid_604131 != nil:
    section.add "Port", valid_604131
  var valid_604132 = query.getOrDefault("AvailabilityZone")
  valid_604132 = validateParameter(valid_604132, JString, required = false,
                                 default = nil)
  if valid_604132 != nil:
    section.add "AvailabilityZone", valid_604132
  var valid_604133 = query.getOrDefault("OptionGroupName")
  valid_604133 = validateParameter(valid_604133, JString, required = false,
                                 default = nil)
  if valid_604133 != nil:
    section.add "OptionGroupName", valid_604133
  var valid_604134 = query.getOrDefault("DBSubnetGroupName")
  valid_604134 = validateParameter(valid_604134, JString, required = false,
                                 default = nil)
  if valid_604134 != nil:
    section.add "DBSubnetGroupName", valid_604134
  var valid_604135 = query.getOrDefault("RestoreTime")
  valid_604135 = validateParameter(valid_604135, JString, required = false,
                                 default = nil)
  if valid_604135 != nil:
    section.add "RestoreTime", valid_604135
  var valid_604136 = query.getOrDefault("DBInstanceClass")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "DBInstanceClass", valid_604136
  var valid_604137 = query.getOrDefault("PubliclyAccessible")
  valid_604137 = validateParameter(valid_604137, JBool, required = false, default = nil)
  if valid_604137 != nil:
    section.add "PubliclyAccessible", valid_604137
  var valid_604138 = query.getOrDefault("Version")
  valid_604138 = validateParameter(valid_604138, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604138 != nil:
    section.add "Version", valid_604138
  var valid_604139 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604139 = validateParameter(valid_604139, JBool, required = false, default = nil)
  if valid_604139 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604139
  var valid_604140 = query.getOrDefault("Iops")
  valid_604140 = validateParameter(valid_604140, JInt, required = false, default = nil)
  if valid_604140 != nil:
    section.add "Iops", valid_604140
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604141 = header.getOrDefault("X-Amz-Signature")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "X-Amz-Signature", valid_604141
  var valid_604142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "X-Amz-Content-Sha256", valid_604142
  var valid_604143 = header.getOrDefault("X-Amz-Date")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "X-Amz-Date", valid_604143
  var valid_604144 = header.getOrDefault("X-Amz-Credential")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Credential", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Security-Token")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Security-Token", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-Algorithm")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-Algorithm", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-SignedHeaders", valid_604147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604148: Call_GetRestoreDBInstanceToPointInTime_604116;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604148.validator(path, query, header, formData, body)
  let scheme = call_604148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604148.url(scheme.get, call_604148.host, call_604148.base,
                         call_604148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604148, url, valid)

proc call*(call_604149: Call_GetRestoreDBInstanceToPointInTime_604116;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          DBName: string = ""; TdeCredentialPassword: string = ""; Engine: string = "";
          UseLatestRestorableTime: bool = false; Tags: JsonNode = nil;
          LicenseModel: string = ""; TdeCredentialArn: string = "";
          StorageType: string = "";
          Action: string = "RestoreDBInstanceToPointInTime"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; RestoreTime: string = "";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          Version: string = "2014-09-01"; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   DBName: string
  ##   TdeCredentialPassword: string
  ##   Engine: string
  ##   UseLatestRestorableTime: bool
  ##   Tags: JArray
  ##   LicenseModel: string
  ##   TdeCredentialArn: string
  ##   StorageType: string
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
  var query_604150 = newJObject()
  add(query_604150, "DBName", newJString(DBName))
  add(query_604150, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_604150, "Engine", newJString(Engine))
  add(query_604150, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_604150.add "Tags", Tags
  add(query_604150, "LicenseModel", newJString(LicenseModel))
  add(query_604150, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_604150, "StorageType", newJString(StorageType))
  add(query_604150, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_604150, "Action", newJString(Action))
  add(query_604150, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_604150, "MultiAZ", newJBool(MultiAZ))
  add(query_604150, "Port", newJInt(Port))
  add(query_604150, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_604150, "OptionGroupName", newJString(OptionGroupName))
  add(query_604150, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604150, "RestoreTime", newJString(RestoreTime))
  add(query_604150, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604150, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_604150, "Version", newJString(Version))
  add(query_604150, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604150, "Iops", newJInt(Iops))
  result = call_604149.call(nil, query_604150, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_604116(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_604117, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_604118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_604207 = ref object of OpenApiRestCall_601373
proc url_PostRevokeDBSecurityGroupIngress_604209(protocol: Scheme; host: string;
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

proc validate_PostRevokeDBSecurityGroupIngress_604208(path: JsonNode;
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
  var valid_604210 = query.getOrDefault("Action")
  valid_604210 = validateParameter(valid_604210, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_604210 != nil:
    section.add "Action", valid_604210
  var valid_604211 = query.getOrDefault("Version")
  valid_604211 = validateParameter(valid_604211, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604211 != nil:
    section.add "Version", valid_604211
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604212 = header.getOrDefault("X-Amz-Signature")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Signature", valid_604212
  var valid_604213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Content-Sha256", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Date")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Date", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-Credential")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Credential", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-Security-Token")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-Security-Token", valid_604216
  var valid_604217 = header.getOrDefault("X-Amz-Algorithm")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "X-Amz-Algorithm", valid_604217
  var valid_604218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604218 = validateParameter(valid_604218, JString, required = false,
                                 default = nil)
  if valid_604218 != nil:
    section.add "X-Amz-SignedHeaders", valid_604218
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_604219 = formData.getOrDefault("DBSecurityGroupName")
  valid_604219 = validateParameter(valid_604219, JString, required = true,
                                 default = nil)
  if valid_604219 != nil:
    section.add "DBSecurityGroupName", valid_604219
  var valid_604220 = formData.getOrDefault("EC2SecurityGroupName")
  valid_604220 = validateParameter(valid_604220, JString, required = false,
                                 default = nil)
  if valid_604220 != nil:
    section.add "EC2SecurityGroupName", valid_604220
  var valid_604221 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_604221 = validateParameter(valid_604221, JString, required = false,
                                 default = nil)
  if valid_604221 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_604221
  var valid_604222 = formData.getOrDefault("EC2SecurityGroupId")
  valid_604222 = validateParameter(valid_604222, JString, required = false,
                                 default = nil)
  if valid_604222 != nil:
    section.add "EC2SecurityGroupId", valid_604222
  var valid_604223 = formData.getOrDefault("CIDRIP")
  valid_604223 = validateParameter(valid_604223, JString, required = false,
                                 default = nil)
  if valid_604223 != nil:
    section.add "CIDRIP", valid_604223
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604224: Call_PostRevokeDBSecurityGroupIngress_604207;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604224.validator(path, query, header, formData, body)
  let scheme = call_604224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604224.url(scheme.get, call_604224.host, call_604224.base,
                         call_604224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604224, url, valid)

proc call*(call_604225: Call_PostRevokeDBSecurityGroupIngress_604207;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupOwnerId: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2014-09-01"): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604226 = newJObject()
  var formData_604227 = newJObject()
  add(formData_604227, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_604227, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_604227, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_604227, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_604227, "CIDRIP", newJString(CIDRIP))
  add(query_604226, "Action", newJString(Action))
  add(query_604226, "Version", newJString(Version))
  result = call_604225.call(nil, query_604226, nil, formData_604227, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_604207(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_604208, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_604209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_604187 = ref object of OpenApiRestCall_601373
proc url_GetRevokeDBSecurityGroupIngress_604189(protocol: Scheme; host: string;
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

proc validate_GetRevokeDBSecurityGroupIngress_604188(path: JsonNode;
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
  var valid_604190 = query.getOrDefault("EC2SecurityGroupName")
  valid_604190 = validateParameter(valid_604190, JString, required = false,
                                 default = nil)
  if valid_604190 != nil:
    section.add "EC2SecurityGroupName", valid_604190
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_604191 = query.getOrDefault("DBSecurityGroupName")
  valid_604191 = validateParameter(valid_604191, JString, required = true,
                                 default = nil)
  if valid_604191 != nil:
    section.add "DBSecurityGroupName", valid_604191
  var valid_604192 = query.getOrDefault("EC2SecurityGroupId")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "EC2SecurityGroupId", valid_604192
  var valid_604193 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_604193 = validateParameter(valid_604193, JString, required = false,
                                 default = nil)
  if valid_604193 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_604193
  var valid_604194 = query.getOrDefault("Action")
  valid_604194 = validateParameter(valid_604194, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_604194 != nil:
    section.add "Action", valid_604194
  var valid_604195 = query.getOrDefault("Version")
  valid_604195 = validateParameter(valid_604195, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604195 != nil:
    section.add "Version", valid_604195
  var valid_604196 = query.getOrDefault("CIDRIP")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "CIDRIP", valid_604196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_604197 = header.getOrDefault("X-Amz-Signature")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-Signature", valid_604197
  var valid_604198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Content-Sha256", valid_604198
  var valid_604199 = header.getOrDefault("X-Amz-Date")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "X-Amz-Date", valid_604199
  var valid_604200 = header.getOrDefault("X-Amz-Credential")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "X-Amz-Credential", valid_604200
  var valid_604201 = header.getOrDefault("X-Amz-Security-Token")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "X-Amz-Security-Token", valid_604201
  var valid_604202 = header.getOrDefault("X-Amz-Algorithm")
  valid_604202 = validateParameter(valid_604202, JString, required = false,
                                 default = nil)
  if valid_604202 != nil:
    section.add "X-Amz-Algorithm", valid_604202
  var valid_604203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604203 = validateParameter(valid_604203, JString, required = false,
                                 default = nil)
  if valid_604203 != nil:
    section.add "X-Amz-SignedHeaders", valid_604203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604204: Call_GetRevokeDBSecurityGroupIngress_604187;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604204.validator(path, query, header, formData, body)
  let scheme = call_604204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604204.url(scheme.get, call_604204.host, call_604204.base,
                         call_604204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604204, url, valid)

proc call*(call_604205: Call_GetRevokeDBSecurityGroupIngress_604187;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupId: string = ""; EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2014-09-01"; CIDRIP: string = ""): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CIDRIP: string
  var query_604206 = newJObject()
  add(query_604206, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_604206, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_604206, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_604206, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_604206, "Action", newJString(Action))
  add(query_604206, "Version", newJString(Version))
  add(query_604206, "CIDRIP", newJString(CIDRIP))
  result = call_604205.call(nil, query_604206, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_604187(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_604188, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_604189,
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
