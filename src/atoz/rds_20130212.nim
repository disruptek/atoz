
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592348 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592348](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592348): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddSourceIdentifierToSubscription_592959 = ref object of OpenApiRestCall_592348
proc url_PostAddSourceIdentifierToSubscription_592961(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddSourceIdentifierToSubscription_592960(path: JsonNode;
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
  var valid_592962 = query.getOrDefault("Action")
  valid_592962 = validateParameter(valid_592962, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_592962 != nil:
    section.add "Action", valid_592962
  var valid_592963 = query.getOrDefault("Version")
  valid_592963 = validateParameter(valid_592963, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_592963 != nil:
    section.add "Version", valid_592963
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592964 = header.getOrDefault("X-Amz-Signature")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Signature", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Content-Sha256", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Date")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Date", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-Credential")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-Credential", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Security-Token")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Security-Token", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-Algorithm")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-Algorithm", valid_592969
  var valid_592970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592970 = validateParameter(valid_592970, JString, required = false,
                                 default = nil)
  if valid_592970 != nil:
    section.add "X-Amz-SignedHeaders", valid_592970
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_592971 = formData.getOrDefault("SubscriptionName")
  valid_592971 = validateParameter(valid_592971, JString, required = true,
                                 default = nil)
  if valid_592971 != nil:
    section.add "SubscriptionName", valid_592971
  var valid_592972 = formData.getOrDefault("SourceIdentifier")
  valid_592972 = validateParameter(valid_592972, JString, required = true,
                                 default = nil)
  if valid_592972 != nil:
    section.add "SourceIdentifier", valid_592972
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592973: Call_PostAddSourceIdentifierToSubscription_592959;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_592973.validator(path, query, header, formData, body)
  let scheme = call_592973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592973.url(scheme.get, call_592973.host, call_592973.base,
                         call_592973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592973, url, valid)

proc call*(call_592974: Call_PostAddSourceIdentifierToSubscription_592959;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_592975 = newJObject()
  var formData_592976 = newJObject()
  add(formData_592976, "SubscriptionName", newJString(SubscriptionName))
  add(formData_592976, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_592975, "Action", newJString(Action))
  add(query_592975, "Version", newJString(Version))
  result = call_592974.call(nil, query_592975, nil, formData_592976, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_592959(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_592960, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_592961,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_592687 = ref object of OpenApiRestCall_592348
proc url_GetAddSourceIdentifierToSubscription_592689(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddSourceIdentifierToSubscription_592688(path: JsonNode;
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
  var valid_592801 = query.getOrDefault("SourceIdentifier")
  valid_592801 = validateParameter(valid_592801, JString, required = true,
                                 default = nil)
  if valid_592801 != nil:
    section.add "SourceIdentifier", valid_592801
  var valid_592802 = query.getOrDefault("SubscriptionName")
  valid_592802 = validateParameter(valid_592802, JString, required = true,
                                 default = nil)
  if valid_592802 != nil:
    section.add "SubscriptionName", valid_592802
  var valid_592816 = query.getOrDefault("Action")
  valid_592816 = validateParameter(valid_592816, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_592816 != nil:
    section.add "Action", valid_592816
  var valid_592817 = query.getOrDefault("Version")
  valid_592817 = validateParameter(valid_592817, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_592817 != nil:
    section.add "Version", valid_592817
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592818 = header.getOrDefault("X-Amz-Signature")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Signature", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Content-Sha256", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Date")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Date", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Credential")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Credential", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Security-Token")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Security-Token", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Algorithm")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Algorithm", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-SignedHeaders", valid_592824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592847: Call_GetAddSourceIdentifierToSubscription_592687;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_592847.validator(path, query, header, formData, body)
  let scheme = call_592847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592847.url(scheme.get, call_592847.host, call_592847.base,
                         call_592847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592847, url, valid)

proc call*(call_592918: Call_GetAddSourceIdentifierToSubscription_592687;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_592919 = newJObject()
  add(query_592919, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_592919, "SubscriptionName", newJString(SubscriptionName))
  add(query_592919, "Action", newJString(Action))
  add(query_592919, "Version", newJString(Version))
  result = call_592918.call(nil, query_592919, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_592687(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_592688, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_592689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_592994 = ref object of OpenApiRestCall_592348
proc url_PostAddTagsToResource_592996(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTagsToResource_592995(path: JsonNode; query: JsonNode;
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
  var valid_592997 = query.getOrDefault("Action")
  valid_592997 = validateParameter(valid_592997, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_592997 != nil:
    section.add "Action", valid_592997
  var valid_592998 = query.getOrDefault("Version")
  valid_592998 = validateParameter(valid_592998, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_592998 != nil:
    section.add "Version", valid_592998
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592999 = header.getOrDefault("X-Amz-Signature")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Signature", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Content-Sha256", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Date")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Date", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Credential")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Credential", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Security-Token")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Security-Token", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Algorithm")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Algorithm", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-SignedHeaders", valid_593005
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_593006 = formData.getOrDefault("Tags")
  valid_593006 = validateParameter(valid_593006, JArray, required = true, default = nil)
  if valid_593006 != nil:
    section.add "Tags", valid_593006
  var valid_593007 = formData.getOrDefault("ResourceName")
  valid_593007 = validateParameter(valid_593007, JString, required = true,
                                 default = nil)
  if valid_593007 != nil:
    section.add "ResourceName", valid_593007
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593008: Call_PostAddTagsToResource_592994; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593008.validator(path, query, header, formData, body)
  let scheme = call_593008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593008.url(scheme.get, call_593008.host, call_593008.base,
                         call_593008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593008, url, valid)

proc call*(call_593009: Call_PostAddTagsToResource_592994; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-02-12"): Recallable =
  ## postAddTagsToResource
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_593010 = newJObject()
  var formData_593011 = newJObject()
  add(query_593010, "Action", newJString(Action))
  if Tags != nil:
    formData_593011.add "Tags", Tags
  add(query_593010, "Version", newJString(Version))
  add(formData_593011, "ResourceName", newJString(ResourceName))
  result = call_593009.call(nil, query_593010, nil, formData_593011, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_592994(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_592995, base: "/",
    url: url_PostAddTagsToResource_592996, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_592977 = ref object of OpenApiRestCall_592348
proc url_GetAddTagsToResource_592979(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTagsToResource_592978(path: JsonNode; query: JsonNode;
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
  var valid_592980 = query.getOrDefault("Tags")
  valid_592980 = validateParameter(valid_592980, JArray, required = true, default = nil)
  if valid_592980 != nil:
    section.add "Tags", valid_592980
  var valid_592981 = query.getOrDefault("ResourceName")
  valid_592981 = validateParameter(valid_592981, JString, required = true,
                                 default = nil)
  if valid_592981 != nil:
    section.add "ResourceName", valid_592981
  var valid_592982 = query.getOrDefault("Action")
  valid_592982 = validateParameter(valid_592982, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_592982 != nil:
    section.add "Action", valid_592982
  var valid_592983 = query.getOrDefault("Version")
  valid_592983 = validateParameter(valid_592983, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_592983 != nil:
    section.add "Version", valid_592983
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592984 = header.getOrDefault("X-Amz-Signature")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Signature", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Content-Sha256", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Date")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Date", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Credential")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Credential", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-Security-Token")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-Security-Token", valid_592988
  var valid_592989 = header.getOrDefault("X-Amz-Algorithm")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-Algorithm", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-SignedHeaders", valid_592990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592991: Call_GetAddTagsToResource_592977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_592991.validator(path, query, header, formData, body)
  let scheme = call_592991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592991.url(scheme.get, call_592991.host, call_592991.base,
                         call_592991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592991, url, valid)

proc call*(call_592992: Call_GetAddTagsToResource_592977; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-02-12"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_592993 = newJObject()
  if Tags != nil:
    query_592993.add "Tags", Tags
  add(query_592993, "ResourceName", newJString(ResourceName))
  add(query_592993, "Action", newJString(Action))
  add(query_592993, "Version", newJString(Version))
  result = call_592992.call(nil, query_592993, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_592977(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_592978, base: "/",
    url: url_GetAddTagsToResource_592979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_593032 = ref object of OpenApiRestCall_592348
proc url_PostAuthorizeDBSecurityGroupIngress_593034(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_593033(path: JsonNode;
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
  var valid_593035 = query.getOrDefault("Action")
  valid_593035 = validateParameter(valid_593035, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_593035 != nil:
    section.add "Action", valid_593035
  var valid_593036 = query.getOrDefault("Version")
  valid_593036 = validateParameter(valid_593036, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593036 != nil:
    section.add "Version", valid_593036
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593037 = header.getOrDefault("X-Amz-Signature")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Signature", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Content-Sha256", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Date")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Date", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Credential")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Credential", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Security-Token")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Security-Token", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Algorithm")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Algorithm", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-SignedHeaders", valid_593043
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_593044 = formData.getOrDefault("DBSecurityGroupName")
  valid_593044 = validateParameter(valid_593044, JString, required = true,
                                 default = nil)
  if valid_593044 != nil:
    section.add "DBSecurityGroupName", valid_593044
  var valid_593045 = formData.getOrDefault("EC2SecurityGroupName")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "EC2SecurityGroupName", valid_593045
  var valid_593046 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_593046
  var valid_593047 = formData.getOrDefault("EC2SecurityGroupId")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "EC2SecurityGroupId", valid_593047
  var valid_593048 = formData.getOrDefault("CIDRIP")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "CIDRIP", valid_593048
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593049: Call_PostAuthorizeDBSecurityGroupIngress_593032;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_593049.validator(path, query, header, formData, body)
  let scheme = call_593049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593049.url(scheme.get, call_593049.host, call_593049.base,
                         call_593049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593049, url, valid)

proc call*(call_593050: Call_PostAuthorizeDBSecurityGroupIngress_593032;
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
  var query_593051 = newJObject()
  var formData_593052 = newJObject()
  add(formData_593052, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_593052, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_593052, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_593052, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_593052, "CIDRIP", newJString(CIDRIP))
  add(query_593051, "Action", newJString(Action))
  add(query_593051, "Version", newJString(Version))
  result = call_593050.call(nil, query_593051, nil, formData_593052, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_593032(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_593033, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_593034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_593012 = ref object of OpenApiRestCall_592348
proc url_GetAuthorizeDBSecurityGroupIngress_593014(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_593013(path: JsonNode;
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
  var valid_593015 = query.getOrDefault("EC2SecurityGroupName")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "EC2SecurityGroupName", valid_593015
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_593016 = query.getOrDefault("DBSecurityGroupName")
  valid_593016 = validateParameter(valid_593016, JString, required = true,
                                 default = nil)
  if valid_593016 != nil:
    section.add "DBSecurityGroupName", valid_593016
  var valid_593017 = query.getOrDefault("EC2SecurityGroupId")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "EC2SecurityGroupId", valid_593017
  var valid_593018 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_593018
  var valid_593019 = query.getOrDefault("Action")
  valid_593019 = validateParameter(valid_593019, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_593019 != nil:
    section.add "Action", valid_593019
  var valid_593020 = query.getOrDefault("Version")
  valid_593020 = validateParameter(valid_593020, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593020 != nil:
    section.add "Version", valid_593020
  var valid_593021 = query.getOrDefault("CIDRIP")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "CIDRIP", valid_593021
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593022 = header.getOrDefault("X-Amz-Signature")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Signature", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Content-Sha256", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Date")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Date", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Credential")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Credential", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Security-Token")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Security-Token", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Algorithm")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Algorithm", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-SignedHeaders", valid_593028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593029: Call_GetAuthorizeDBSecurityGroupIngress_593012;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_593029.validator(path, query, header, formData, body)
  let scheme = call_593029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593029.url(scheme.get, call_593029.host, call_593029.base,
                         call_593029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593029, url, valid)

proc call*(call_593030: Call_GetAuthorizeDBSecurityGroupIngress_593012;
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
  var query_593031 = newJObject()
  add(query_593031, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_593031, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593031, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_593031, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_593031, "Action", newJString(Action))
  add(query_593031, "Version", newJString(Version))
  add(query_593031, "CIDRIP", newJString(CIDRIP))
  result = call_593030.call(nil, query_593031, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_593012(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_593013, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_593014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_593070 = ref object of OpenApiRestCall_592348
proc url_PostCopyDBSnapshot_593072(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBSnapshot_593071(path: JsonNode; query: JsonNode;
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
  var valid_593073 = query.getOrDefault("Action")
  valid_593073 = validateParameter(valid_593073, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_593073 != nil:
    section.add "Action", valid_593073
  var valid_593074 = query.getOrDefault("Version")
  valid_593074 = validateParameter(valid_593074, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593074 != nil:
    section.add "Version", valid_593074
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593075 = header.getOrDefault("X-Amz-Signature")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Signature", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Content-Sha256", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Date")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Date", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Credential")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Credential", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Security-Token")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Security-Token", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Algorithm")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Algorithm", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-SignedHeaders", valid_593081
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_593082 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_593082 = validateParameter(valid_593082, JString, required = true,
                                 default = nil)
  if valid_593082 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_593082
  var valid_593083 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_593083 = validateParameter(valid_593083, JString, required = true,
                                 default = nil)
  if valid_593083 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_593083
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593084: Call_PostCopyDBSnapshot_593070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593084.validator(path, query, header, formData, body)
  let scheme = call_593084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593084.url(scheme.get, call_593084.host, call_593084.base,
                         call_593084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593084, url, valid)

proc call*(call_593085: Call_PostCopyDBSnapshot_593070;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_593086 = newJObject()
  var formData_593087 = newJObject()
  add(formData_593087, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_593086, "Action", newJString(Action))
  add(formData_593087, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_593086, "Version", newJString(Version))
  result = call_593085.call(nil, query_593086, nil, formData_593087, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_593070(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_593071, base: "/",
    url: url_PostCopyDBSnapshot_593072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_593053 = ref object of OpenApiRestCall_592348
proc url_GetCopyDBSnapshot_593055(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBSnapshot_593054(path: JsonNode; query: JsonNode;
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
  var valid_593056 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_593056 = validateParameter(valid_593056, JString, required = true,
                                 default = nil)
  if valid_593056 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_593056
  var valid_593057 = query.getOrDefault("Action")
  valid_593057 = validateParameter(valid_593057, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_593057 != nil:
    section.add "Action", valid_593057
  var valid_593058 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_593058 = validateParameter(valid_593058, JString, required = true,
                                 default = nil)
  if valid_593058 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_593058
  var valid_593059 = query.getOrDefault("Version")
  valid_593059 = validateParameter(valid_593059, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593059 != nil:
    section.add "Version", valid_593059
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593060 = header.getOrDefault("X-Amz-Signature")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Signature", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Content-Sha256", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Date")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Date", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Credential")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Credential", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Security-Token")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Security-Token", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Algorithm")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Algorithm", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-SignedHeaders", valid_593066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593067: Call_GetCopyDBSnapshot_593053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593067.validator(path, query, header, formData, body)
  let scheme = call_593067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593067.url(scheme.get, call_593067.host, call_593067.base,
                         call_593067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593067, url, valid)

proc call*(call_593068: Call_GetCopyDBSnapshot_593053;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_593069 = newJObject()
  add(query_593069, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_593069, "Action", newJString(Action))
  add(query_593069, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_593069, "Version", newJString(Version))
  result = call_593068.call(nil, query_593069, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_593053(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_593054,
    base: "/", url: url_GetCopyDBSnapshot_593055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_593127 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBInstance_593129(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_593128(path: JsonNode; query: JsonNode;
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
  var valid_593130 = query.getOrDefault("Action")
  valid_593130 = validateParameter(valid_593130, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_593130 != nil:
    section.add "Action", valid_593130
  var valid_593131 = query.getOrDefault("Version")
  valid_593131 = validateParameter(valid_593131, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593131 != nil:
    section.add "Version", valid_593131
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593132 = header.getOrDefault("X-Amz-Signature")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Signature", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Content-Sha256", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-Date")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Date", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-Credential")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Credential", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Security-Token")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Security-Token", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Algorithm")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Algorithm", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-SignedHeaders", valid_593138
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
  var valid_593139 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "PreferredMaintenanceWindow", valid_593139
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_593140 = formData.getOrDefault("DBInstanceClass")
  valid_593140 = validateParameter(valid_593140, JString, required = true,
                                 default = nil)
  if valid_593140 != nil:
    section.add "DBInstanceClass", valid_593140
  var valid_593141 = formData.getOrDefault("Port")
  valid_593141 = validateParameter(valid_593141, JInt, required = false, default = nil)
  if valid_593141 != nil:
    section.add "Port", valid_593141
  var valid_593142 = formData.getOrDefault("PreferredBackupWindow")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "PreferredBackupWindow", valid_593142
  var valid_593143 = formData.getOrDefault("MasterUserPassword")
  valid_593143 = validateParameter(valid_593143, JString, required = true,
                                 default = nil)
  if valid_593143 != nil:
    section.add "MasterUserPassword", valid_593143
  var valid_593144 = formData.getOrDefault("MultiAZ")
  valid_593144 = validateParameter(valid_593144, JBool, required = false, default = nil)
  if valid_593144 != nil:
    section.add "MultiAZ", valid_593144
  var valid_593145 = formData.getOrDefault("MasterUsername")
  valid_593145 = validateParameter(valid_593145, JString, required = true,
                                 default = nil)
  if valid_593145 != nil:
    section.add "MasterUsername", valid_593145
  var valid_593146 = formData.getOrDefault("DBParameterGroupName")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "DBParameterGroupName", valid_593146
  var valid_593147 = formData.getOrDefault("EngineVersion")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "EngineVersion", valid_593147
  var valid_593148 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_593148 = validateParameter(valid_593148, JArray, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "VpcSecurityGroupIds", valid_593148
  var valid_593149 = formData.getOrDefault("AvailabilityZone")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "AvailabilityZone", valid_593149
  var valid_593150 = formData.getOrDefault("BackupRetentionPeriod")
  valid_593150 = validateParameter(valid_593150, JInt, required = false, default = nil)
  if valid_593150 != nil:
    section.add "BackupRetentionPeriod", valid_593150
  var valid_593151 = formData.getOrDefault("Engine")
  valid_593151 = validateParameter(valid_593151, JString, required = true,
                                 default = nil)
  if valid_593151 != nil:
    section.add "Engine", valid_593151
  var valid_593152 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_593152 = validateParameter(valid_593152, JBool, required = false, default = nil)
  if valid_593152 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593152
  var valid_593153 = formData.getOrDefault("DBName")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "DBName", valid_593153
  var valid_593154 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593154 = validateParameter(valid_593154, JString, required = true,
                                 default = nil)
  if valid_593154 != nil:
    section.add "DBInstanceIdentifier", valid_593154
  var valid_593155 = formData.getOrDefault("Iops")
  valid_593155 = validateParameter(valid_593155, JInt, required = false, default = nil)
  if valid_593155 != nil:
    section.add "Iops", valid_593155
  var valid_593156 = formData.getOrDefault("PubliclyAccessible")
  valid_593156 = validateParameter(valid_593156, JBool, required = false, default = nil)
  if valid_593156 != nil:
    section.add "PubliclyAccessible", valid_593156
  var valid_593157 = formData.getOrDefault("LicenseModel")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "LicenseModel", valid_593157
  var valid_593158 = formData.getOrDefault("DBSubnetGroupName")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "DBSubnetGroupName", valid_593158
  var valid_593159 = formData.getOrDefault("OptionGroupName")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "OptionGroupName", valid_593159
  var valid_593160 = formData.getOrDefault("CharacterSetName")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "CharacterSetName", valid_593160
  var valid_593161 = formData.getOrDefault("DBSecurityGroups")
  valid_593161 = validateParameter(valid_593161, JArray, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "DBSecurityGroups", valid_593161
  var valid_593162 = formData.getOrDefault("AllocatedStorage")
  valid_593162 = validateParameter(valid_593162, JInt, required = true, default = nil)
  if valid_593162 != nil:
    section.add "AllocatedStorage", valid_593162
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593163: Call_PostCreateDBInstance_593127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593163.validator(path, query, header, formData, body)
  let scheme = call_593163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593163.url(scheme.get, call_593163.host, call_593163.base,
                         call_593163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593163, url, valid)

proc call*(call_593164: Call_PostCreateDBInstance_593127; DBInstanceClass: string;
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
  var query_593165 = newJObject()
  var formData_593166 = newJObject()
  add(formData_593166, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_593166, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_593166, "Port", newJInt(Port))
  add(formData_593166, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_593166, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_593166, "MultiAZ", newJBool(MultiAZ))
  add(formData_593166, "MasterUsername", newJString(MasterUsername))
  add(formData_593166, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_593166, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_593166.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_593166, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_593166, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_593166, "Engine", newJString(Engine))
  add(formData_593166, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_593166, "DBName", newJString(DBName))
  add(formData_593166, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593166, "Iops", newJInt(Iops))
  add(formData_593166, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_593165, "Action", newJString(Action))
  add(formData_593166, "LicenseModel", newJString(LicenseModel))
  add(formData_593166, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_593166, "OptionGroupName", newJString(OptionGroupName))
  add(formData_593166, "CharacterSetName", newJString(CharacterSetName))
  add(query_593165, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_593166.add "DBSecurityGroups", DBSecurityGroups
  add(formData_593166, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_593164.call(nil, query_593165, nil, formData_593166, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_593127(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_593128, base: "/",
    url: url_PostCreateDBInstance_593129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_593088 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBInstance_593090(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_593089(path: JsonNode; query: JsonNode;
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
  var valid_593091 = query.getOrDefault("Version")
  valid_593091 = validateParameter(valid_593091, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593091 != nil:
    section.add "Version", valid_593091
  var valid_593092 = query.getOrDefault("DBName")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "DBName", valid_593092
  var valid_593093 = query.getOrDefault("Engine")
  valid_593093 = validateParameter(valid_593093, JString, required = true,
                                 default = nil)
  if valid_593093 != nil:
    section.add "Engine", valid_593093
  var valid_593094 = query.getOrDefault("DBParameterGroupName")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "DBParameterGroupName", valid_593094
  var valid_593095 = query.getOrDefault("CharacterSetName")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "CharacterSetName", valid_593095
  var valid_593096 = query.getOrDefault("LicenseModel")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "LicenseModel", valid_593096
  var valid_593097 = query.getOrDefault("DBInstanceIdentifier")
  valid_593097 = validateParameter(valid_593097, JString, required = true,
                                 default = nil)
  if valid_593097 != nil:
    section.add "DBInstanceIdentifier", valid_593097
  var valid_593098 = query.getOrDefault("MasterUsername")
  valid_593098 = validateParameter(valid_593098, JString, required = true,
                                 default = nil)
  if valid_593098 != nil:
    section.add "MasterUsername", valid_593098
  var valid_593099 = query.getOrDefault("BackupRetentionPeriod")
  valid_593099 = validateParameter(valid_593099, JInt, required = false, default = nil)
  if valid_593099 != nil:
    section.add "BackupRetentionPeriod", valid_593099
  var valid_593100 = query.getOrDefault("EngineVersion")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "EngineVersion", valid_593100
  var valid_593101 = query.getOrDefault("Action")
  valid_593101 = validateParameter(valid_593101, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_593101 != nil:
    section.add "Action", valid_593101
  var valid_593102 = query.getOrDefault("MultiAZ")
  valid_593102 = validateParameter(valid_593102, JBool, required = false, default = nil)
  if valid_593102 != nil:
    section.add "MultiAZ", valid_593102
  var valid_593103 = query.getOrDefault("DBSecurityGroups")
  valid_593103 = validateParameter(valid_593103, JArray, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "DBSecurityGroups", valid_593103
  var valid_593104 = query.getOrDefault("Port")
  valid_593104 = validateParameter(valid_593104, JInt, required = false, default = nil)
  if valid_593104 != nil:
    section.add "Port", valid_593104
  var valid_593105 = query.getOrDefault("VpcSecurityGroupIds")
  valid_593105 = validateParameter(valid_593105, JArray, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "VpcSecurityGroupIds", valid_593105
  var valid_593106 = query.getOrDefault("MasterUserPassword")
  valid_593106 = validateParameter(valid_593106, JString, required = true,
                                 default = nil)
  if valid_593106 != nil:
    section.add "MasterUserPassword", valid_593106
  var valid_593107 = query.getOrDefault("AvailabilityZone")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "AvailabilityZone", valid_593107
  var valid_593108 = query.getOrDefault("OptionGroupName")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "OptionGroupName", valid_593108
  var valid_593109 = query.getOrDefault("DBSubnetGroupName")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "DBSubnetGroupName", valid_593109
  var valid_593110 = query.getOrDefault("AllocatedStorage")
  valid_593110 = validateParameter(valid_593110, JInt, required = true, default = nil)
  if valid_593110 != nil:
    section.add "AllocatedStorage", valid_593110
  var valid_593111 = query.getOrDefault("DBInstanceClass")
  valid_593111 = validateParameter(valid_593111, JString, required = true,
                                 default = nil)
  if valid_593111 != nil:
    section.add "DBInstanceClass", valid_593111
  var valid_593112 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "PreferredMaintenanceWindow", valid_593112
  var valid_593113 = query.getOrDefault("PreferredBackupWindow")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "PreferredBackupWindow", valid_593113
  var valid_593114 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_593114 = validateParameter(valid_593114, JBool, required = false, default = nil)
  if valid_593114 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593114
  var valid_593115 = query.getOrDefault("Iops")
  valid_593115 = validateParameter(valid_593115, JInt, required = false, default = nil)
  if valid_593115 != nil:
    section.add "Iops", valid_593115
  var valid_593116 = query.getOrDefault("PubliclyAccessible")
  valid_593116 = validateParameter(valid_593116, JBool, required = false, default = nil)
  if valid_593116 != nil:
    section.add "PubliclyAccessible", valid_593116
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593117 = header.getOrDefault("X-Amz-Signature")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Signature", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Content-Sha256", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Date")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Date", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Credential")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Credential", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Security-Token")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Security-Token", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Algorithm")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Algorithm", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-SignedHeaders", valid_593123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593124: Call_GetCreateDBInstance_593088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593124.validator(path, query, header, formData, body)
  let scheme = call_593124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593124.url(scheme.get, call_593124.host, call_593124.base,
                         call_593124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593124, url, valid)

proc call*(call_593125: Call_GetCreateDBInstance_593088; Engine: string;
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
  var query_593126 = newJObject()
  add(query_593126, "Version", newJString(Version))
  add(query_593126, "DBName", newJString(DBName))
  add(query_593126, "Engine", newJString(Engine))
  add(query_593126, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593126, "CharacterSetName", newJString(CharacterSetName))
  add(query_593126, "LicenseModel", newJString(LicenseModel))
  add(query_593126, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593126, "MasterUsername", newJString(MasterUsername))
  add(query_593126, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_593126, "EngineVersion", newJString(EngineVersion))
  add(query_593126, "Action", newJString(Action))
  add(query_593126, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_593126.add "DBSecurityGroups", DBSecurityGroups
  add(query_593126, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_593126.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_593126, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_593126, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_593126, "OptionGroupName", newJString(OptionGroupName))
  add(query_593126, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593126, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_593126, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_593126, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_593126, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_593126, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_593126, "Iops", newJInt(Iops))
  add(query_593126, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_593125.call(nil, query_593126, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_593088(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_593089, base: "/",
    url: url_GetCreateDBInstance_593090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_593191 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBInstanceReadReplica_593193(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_593192(path: JsonNode;
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
  var valid_593194 = query.getOrDefault("Action")
  valid_593194 = validateParameter(valid_593194, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_593194 != nil:
    section.add "Action", valid_593194
  var valid_593195 = query.getOrDefault("Version")
  valid_593195 = validateParameter(valid_593195, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593195 != nil:
    section.add "Version", valid_593195
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593196 = header.getOrDefault("X-Amz-Signature")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Signature", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Content-Sha256", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-Date")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-Date", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-Credential")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Credential", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Security-Token")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Security-Token", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Algorithm")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Algorithm", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-SignedHeaders", valid_593202
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
  var valid_593203 = formData.getOrDefault("Port")
  valid_593203 = validateParameter(valid_593203, JInt, required = false, default = nil)
  if valid_593203 != nil:
    section.add "Port", valid_593203
  var valid_593204 = formData.getOrDefault("DBInstanceClass")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "DBInstanceClass", valid_593204
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_593205 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_593205 = validateParameter(valid_593205, JString, required = true,
                                 default = nil)
  if valid_593205 != nil:
    section.add "SourceDBInstanceIdentifier", valid_593205
  var valid_593206 = formData.getOrDefault("AvailabilityZone")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "AvailabilityZone", valid_593206
  var valid_593207 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_593207 = validateParameter(valid_593207, JBool, required = false, default = nil)
  if valid_593207 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593207
  var valid_593208 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593208 = validateParameter(valid_593208, JString, required = true,
                                 default = nil)
  if valid_593208 != nil:
    section.add "DBInstanceIdentifier", valid_593208
  var valid_593209 = formData.getOrDefault("Iops")
  valid_593209 = validateParameter(valid_593209, JInt, required = false, default = nil)
  if valid_593209 != nil:
    section.add "Iops", valid_593209
  var valid_593210 = formData.getOrDefault("PubliclyAccessible")
  valid_593210 = validateParameter(valid_593210, JBool, required = false, default = nil)
  if valid_593210 != nil:
    section.add "PubliclyAccessible", valid_593210
  var valid_593211 = formData.getOrDefault("OptionGroupName")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "OptionGroupName", valid_593211
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593212: Call_PostCreateDBInstanceReadReplica_593191;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_593212.validator(path, query, header, formData, body)
  let scheme = call_593212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593212.url(scheme.get, call_593212.host, call_593212.base,
                         call_593212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593212, url, valid)

proc call*(call_593213: Call_PostCreateDBInstanceReadReplica_593191;
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
  var query_593214 = newJObject()
  var formData_593215 = newJObject()
  add(formData_593215, "Port", newJInt(Port))
  add(formData_593215, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_593215, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_593215, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_593215, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_593215, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593215, "Iops", newJInt(Iops))
  add(formData_593215, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_593214, "Action", newJString(Action))
  add(formData_593215, "OptionGroupName", newJString(OptionGroupName))
  add(query_593214, "Version", newJString(Version))
  result = call_593213.call(nil, query_593214, nil, formData_593215, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_593191(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_593192, base: "/",
    url: url_PostCreateDBInstanceReadReplica_593193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_593167 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBInstanceReadReplica_593169(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_593168(path: JsonNode;
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
  var valid_593170 = query.getOrDefault("DBInstanceIdentifier")
  valid_593170 = validateParameter(valid_593170, JString, required = true,
                                 default = nil)
  if valid_593170 != nil:
    section.add "DBInstanceIdentifier", valid_593170
  var valid_593171 = query.getOrDefault("Action")
  valid_593171 = validateParameter(valid_593171, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_593171 != nil:
    section.add "Action", valid_593171
  var valid_593172 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_593172 = validateParameter(valid_593172, JString, required = true,
                                 default = nil)
  if valid_593172 != nil:
    section.add "SourceDBInstanceIdentifier", valid_593172
  var valid_593173 = query.getOrDefault("Port")
  valid_593173 = validateParameter(valid_593173, JInt, required = false, default = nil)
  if valid_593173 != nil:
    section.add "Port", valid_593173
  var valid_593174 = query.getOrDefault("AvailabilityZone")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "AvailabilityZone", valid_593174
  var valid_593175 = query.getOrDefault("OptionGroupName")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "OptionGroupName", valid_593175
  var valid_593176 = query.getOrDefault("Version")
  valid_593176 = validateParameter(valid_593176, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593176 != nil:
    section.add "Version", valid_593176
  var valid_593177 = query.getOrDefault("DBInstanceClass")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "DBInstanceClass", valid_593177
  var valid_593178 = query.getOrDefault("PubliclyAccessible")
  valid_593178 = validateParameter(valid_593178, JBool, required = false, default = nil)
  if valid_593178 != nil:
    section.add "PubliclyAccessible", valid_593178
  var valid_593179 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_593179 = validateParameter(valid_593179, JBool, required = false, default = nil)
  if valid_593179 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593179
  var valid_593180 = query.getOrDefault("Iops")
  valid_593180 = validateParameter(valid_593180, JInt, required = false, default = nil)
  if valid_593180 != nil:
    section.add "Iops", valid_593180
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593181 = header.getOrDefault("X-Amz-Signature")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Signature", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-Content-Sha256", valid_593182
  var valid_593183 = header.getOrDefault("X-Amz-Date")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Date", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Credential")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Credential", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-Security-Token")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Security-Token", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Algorithm")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Algorithm", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-SignedHeaders", valid_593187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593188: Call_GetCreateDBInstanceReadReplica_593167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593188.validator(path, query, header, formData, body)
  let scheme = call_593188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593188.url(scheme.get, call_593188.host, call_593188.base,
                         call_593188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593188, url, valid)

proc call*(call_593189: Call_GetCreateDBInstanceReadReplica_593167;
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
  var query_593190 = newJObject()
  add(query_593190, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593190, "Action", newJString(Action))
  add(query_593190, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_593190, "Port", newJInt(Port))
  add(query_593190, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_593190, "OptionGroupName", newJString(OptionGroupName))
  add(query_593190, "Version", newJString(Version))
  add(query_593190, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_593190, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_593190, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_593190, "Iops", newJInt(Iops))
  result = call_593189.call(nil, query_593190, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_593167(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_593168, base: "/",
    url: url_GetCreateDBInstanceReadReplica_593169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_593234 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBParameterGroup_593236(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBParameterGroup_593235(path: JsonNode; query: JsonNode;
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
  var valid_593237 = query.getOrDefault("Action")
  valid_593237 = validateParameter(valid_593237, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_593237 != nil:
    section.add "Action", valid_593237
  var valid_593238 = query.getOrDefault("Version")
  valid_593238 = validateParameter(valid_593238, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593238 != nil:
    section.add "Version", valid_593238
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593239 = header.getOrDefault("X-Amz-Signature")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Signature", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Content-Sha256", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-Date")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Date", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Credential")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Credential", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Security-Token")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Security-Token", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Algorithm")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Algorithm", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-SignedHeaders", valid_593245
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_593246 = formData.getOrDefault("Description")
  valid_593246 = validateParameter(valid_593246, JString, required = true,
                                 default = nil)
  if valid_593246 != nil:
    section.add "Description", valid_593246
  var valid_593247 = formData.getOrDefault("DBParameterGroupName")
  valid_593247 = validateParameter(valid_593247, JString, required = true,
                                 default = nil)
  if valid_593247 != nil:
    section.add "DBParameterGroupName", valid_593247
  var valid_593248 = formData.getOrDefault("DBParameterGroupFamily")
  valid_593248 = validateParameter(valid_593248, JString, required = true,
                                 default = nil)
  if valid_593248 != nil:
    section.add "DBParameterGroupFamily", valid_593248
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593249: Call_PostCreateDBParameterGroup_593234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593249.validator(path, query, header, formData, body)
  let scheme = call_593249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593249.url(scheme.get, call_593249.host, call_593249.base,
                         call_593249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593249, url, valid)

proc call*(call_593250: Call_PostCreateDBParameterGroup_593234;
          Description: string; DBParameterGroupName: string;
          DBParameterGroupFamily: string;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_593251 = newJObject()
  var formData_593252 = newJObject()
  add(formData_593252, "Description", newJString(Description))
  add(formData_593252, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593251, "Action", newJString(Action))
  add(query_593251, "Version", newJString(Version))
  add(formData_593252, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_593250.call(nil, query_593251, nil, formData_593252, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_593234(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_593235, base: "/",
    url: url_PostCreateDBParameterGroup_593236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_593216 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBParameterGroup_593218(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBParameterGroup_593217(path: JsonNode; query: JsonNode;
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
  var valid_593219 = query.getOrDefault("DBParameterGroupFamily")
  valid_593219 = validateParameter(valid_593219, JString, required = true,
                                 default = nil)
  if valid_593219 != nil:
    section.add "DBParameterGroupFamily", valid_593219
  var valid_593220 = query.getOrDefault("DBParameterGroupName")
  valid_593220 = validateParameter(valid_593220, JString, required = true,
                                 default = nil)
  if valid_593220 != nil:
    section.add "DBParameterGroupName", valid_593220
  var valid_593221 = query.getOrDefault("Action")
  valid_593221 = validateParameter(valid_593221, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_593221 != nil:
    section.add "Action", valid_593221
  var valid_593222 = query.getOrDefault("Description")
  valid_593222 = validateParameter(valid_593222, JString, required = true,
                                 default = nil)
  if valid_593222 != nil:
    section.add "Description", valid_593222
  var valid_593223 = query.getOrDefault("Version")
  valid_593223 = validateParameter(valid_593223, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593223 != nil:
    section.add "Version", valid_593223
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593224 = header.getOrDefault("X-Amz-Signature")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Signature", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Content-Sha256", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Date")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Date", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-Credential")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Credential", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Security-Token")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Security-Token", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-Algorithm")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-Algorithm", valid_593229
  var valid_593230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-SignedHeaders", valid_593230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593231: Call_GetCreateDBParameterGroup_593216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593231.validator(path, query, header, formData, body)
  let scheme = call_593231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593231.url(scheme.get, call_593231.host, call_593231.base,
                         call_593231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593231, url, valid)

proc call*(call_593232: Call_GetCreateDBParameterGroup_593216;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Description: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Description: string (required)
  ##   Version: string (required)
  var query_593233 = newJObject()
  add(query_593233, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_593233, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593233, "Action", newJString(Action))
  add(query_593233, "Description", newJString(Description))
  add(query_593233, "Version", newJString(Version))
  result = call_593232.call(nil, query_593233, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_593216(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_593217, base: "/",
    url: url_GetCreateDBParameterGroup_593218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_593270 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBSecurityGroup_593272(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSecurityGroup_593271(path: JsonNode; query: JsonNode;
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
  var valid_593273 = query.getOrDefault("Action")
  valid_593273 = validateParameter(valid_593273, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_593273 != nil:
    section.add "Action", valid_593273
  var valid_593274 = query.getOrDefault("Version")
  valid_593274 = validateParameter(valid_593274, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593274 != nil:
    section.add "Version", valid_593274
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593275 = header.getOrDefault("X-Amz-Signature")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Signature", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Content-Sha256", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Date")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Date", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Credential")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Credential", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Security-Token")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Security-Token", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Algorithm")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Algorithm", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-SignedHeaders", valid_593281
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_593282 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_593282 = validateParameter(valid_593282, JString, required = true,
                                 default = nil)
  if valid_593282 != nil:
    section.add "DBSecurityGroupDescription", valid_593282
  var valid_593283 = formData.getOrDefault("DBSecurityGroupName")
  valid_593283 = validateParameter(valid_593283, JString, required = true,
                                 default = nil)
  if valid_593283 != nil:
    section.add "DBSecurityGroupName", valid_593283
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593284: Call_PostCreateDBSecurityGroup_593270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593284.validator(path, query, header, formData, body)
  let scheme = call_593284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593284.url(scheme.get, call_593284.host, call_593284.base,
                         call_593284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593284, url, valid)

proc call*(call_593285: Call_PostCreateDBSecurityGroup_593270;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593286 = newJObject()
  var formData_593287 = newJObject()
  add(formData_593287, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_593287, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593286, "Action", newJString(Action))
  add(query_593286, "Version", newJString(Version))
  result = call_593285.call(nil, query_593286, nil, formData_593287, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_593270(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_593271, base: "/",
    url: url_PostCreateDBSecurityGroup_593272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_593253 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBSecurityGroup_593255(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSecurityGroup_593254(path: JsonNode; query: JsonNode;
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
  var valid_593256 = query.getOrDefault("DBSecurityGroupName")
  valid_593256 = validateParameter(valid_593256, JString, required = true,
                                 default = nil)
  if valid_593256 != nil:
    section.add "DBSecurityGroupName", valid_593256
  var valid_593257 = query.getOrDefault("DBSecurityGroupDescription")
  valid_593257 = validateParameter(valid_593257, JString, required = true,
                                 default = nil)
  if valid_593257 != nil:
    section.add "DBSecurityGroupDescription", valid_593257
  var valid_593258 = query.getOrDefault("Action")
  valid_593258 = validateParameter(valid_593258, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_593258 != nil:
    section.add "Action", valid_593258
  var valid_593259 = query.getOrDefault("Version")
  valid_593259 = validateParameter(valid_593259, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593259 != nil:
    section.add "Version", valid_593259
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593260 = header.getOrDefault("X-Amz-Signature")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Signature", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Content-Sha256", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Date")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Date", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-Credential")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Credential", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-Security-Token")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Security-Token", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-Algorithm")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-Algorithm", valid_593265
  var valid_593266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "X-Amz-SignedHeaders", valid_593266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593267: Call_GetCreateDBSecurityGroup_593253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593267.validator(path, query, header, formData, body)
  let scheme = call_593267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593267.url(scheme.get, call_593267.host, call_593267.base,
                         call_593267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593267, url, valid)

proc call*(call_593268: Call_GetCreateDBSecurityGroup_593253;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593269 = newJObject()
  add(query_593269, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593269, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_593269, "Action", newJString(Action))
  add(query_593269, "Version", newJString(Version))
  result = call_593268.call(nil, query_593269, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_593253(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_593254, base: "/",
    url: url_GetCreateDBSecurityGroup_593255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_593305 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBSnapshot_593307(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSnapshot_593306(path: JsonNode; query: JsonNode;
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
  var valid_593308 = query.getOrDefault("Action")
  valid_593308 = validateParameter(valid_593308, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_593308 != nil:
    section.add "Action", valid_593308
  var valid_593309 = query.getOrDefault("Version")
  valid_593309 = validateParameter(valid_593309, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593309 != nil:
    section.add "Version", valid_593309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593310 = header.getOrDefault("X-Amz-Signature")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Signature", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Content-Sha256", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-Date")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-Date", valid_593312
  var valid_593313 = header.getOrDefault("X-Amz-Credential")
  valid_593313 = validateParameter(valid_593313, JString, required = false,
                                 default = nil)
  if valid_593313 != nil:
    section.add "X-Amz-Credential", valid_593313
  var valid_593314 = header.getOrDefault("X-Amz-Security-Token")
  valid_593314 = validateParameter(valid_593314, JString, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "X-Amz-Security-Token", valid_593314
  var valid_593315 = header.getOrDefault("X-Amz-Algorithm")
  valid_593315 = validateParameter(valid_593315, JString, required = false,
                                 default = nil)
  if valid_593315 != nil:
    section.add "X-Amz-Algorithm", valid_593315
  var valid_593316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593316 = validateParameter(valid_593316, JString, required = false,
                                 default = nil)
  if valid_593316 != nil:
    section.add "X-Amz-SignedHeaders", valid_593316
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593317 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593317 = validateParameter(valid_593317, JString, required = true,
                                 default = nil)
  if valid_593317 != nil:
    section.add "DBInstanceIdentifier", valid_593317
  var valid_593318 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_593318 = validateParameter(valid_593318, JString, required = true,
                                 default = nil)
  if valid_593318 != nil:
    section.add "DBSnapshotIdentifier", valid_593318
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593319: Call_PostCreateDBSnapshot_593305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593319.validator(path, query, header, formData, body)
  let scheme = call_593319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593319.url(scheme.get, call_593319.host, call_593319.base,
                         call_593319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593319, url, valid)

proc call*(call_593320: Call_PostCreateDBSnapshot_593305;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593321 = newJObject()
  var formData_593322 = newJObject()
  add(formData_593322, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593322, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593321, "Action", newJString(Action))
  add(query_593321, "Version", newJString(Version))
  result = call_593320.call(nil, query_593321, nil, formData_593322, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_593305(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_593306, base: "/",
    url: url_PostCreateDBSnapshot_593307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_593288 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBSnapshot_593290(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSnapshot_593289(path: JsonNode; query: JsonNode;
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
  var valid_593291 = query.getOrDefault("DBInstanceIdentifier")
  valid_593291 = validateParameter(valid_593291, JString, required = true,
                                 default = nil)
  if valid_593291 != nil:
    section.add "DBInstanceIdentifier", valid_593291
  var valid_593292 = query.getOrDefault("DBSnapshotIdentifier")
  valid_593292 = validateParameter(valid_593292, JString, required = true,
                                 default = nil)
  if valid_593292 != nil:
    section.add "DBSnapshotIdentifier", valid_593292
  var valid_593293 = query.getOrDefault("Action")
  valid_593293 = validateParameter(valid_593293, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_593293 != nil:
    section.add "Action", valid_593293
  var valid_593294 = query.getOrDefault("Version")
  valid_593294 = validateParameter(valid_593294, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593294 != nil:
    section.add "Version", valid_593294
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593295 = header.getOrDefault("X-Amz-Signature")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-Signature", valid_593295
  var valid_593296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-Content-Sha256", valid_593296
  var valid_593297 = header.getOrDefault("X-Amz-Date")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-Date", valid_593297
  var valid_593298 = header.getOrDefault("X-Amz-Credential")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-Credential", valid_593298
  var valid_593299 = header.getOrDefault("X-Amz-Security-Token")
  valid_593299 = validateParameter(valid_593299, JString, required = false,
                                 default = nil)
  if valid_593299 != nil:
    section.add "X-Amz-Security-Token", valid_593299
  var valid_593300 = header.getOrDefault("X-Amz-Algorithm")
  valid_593300 = validateParameter(valid_593300, JString, required = false,
                                 default = nil)
  if valid_593300 != nil:
    section.add "X-Amz-Algorithm", valid_593300
  var valid_593301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "X-Amz-SignedHeaders", valid_593301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593302: Call_GetCreateDBSnapshot_593288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593302.validator(path, query, header, formData, body)
  let scheme = call_593302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593302.url(scheme.get, call_593302.host, call_593302.base,
                         call_593302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593302, url, valid)

proc call*(call_593303: Call_GetCreateDBSnapshot_593288;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593304 = newJObject()
  add(query_593304, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593304, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593304, "Action", newJString(Action))
  add(query_593304, "Version", newJString(Version))
  result = call_593303.call(nil, query_593304, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_593288(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_593289, base: "/",
    url: url_GetCreateDBSnapshot_593290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_593341 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBSubnetGroup_593343(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_593342(path: JsonNode; query: JsonNode;
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
  var valid_593344 = query.getOrDefault("Action")
  valid_593344 = validateParameter(valid_593344, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_593344 != nil:
    section.add "Action", valid_593344
  var valid_593345 = query.getOrDefault("Version")
  valid_593345 = validateParameter(valid_593345, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593345 != nil:
    section.add "Version", valid_593345
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593346 = header.getOrDefault("X-Amz-Signature")
  valid_593346 = validateParameter(valid_593346, JString, required = false,
                                 default = nil)
  if valid_593346 != nil:
    section.add "X-Amz-Signature", valid_593346
  var valid_593347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "X-Amz-Content-Sha256", valid_593347
  var valid_593348 = header.getOrDefault("X-Amz-Date")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Date", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-Credential")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Credential", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Security-Token")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Security-Token", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Algorithm")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Algorithm", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-SignedHeaders", valid_593352
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_593353 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_593353 = validateParameter(valid_593353, JString, required = true,
                                 default = nil)
  if valid_593353 != nil:
    section.add "DBSubnetGroupDescription", valid_593353
  var valid_593354 = formData.getOrDefault("DBSubnetGroupName")
  valid_593354 = validateParameter(valid_593354, JString, required = true,
                                 default = nil)
  if valid_593354 != nil:
    section.add "DBSubnetGroupName", valid_593354
  var valid_593355 = formData.getOrDefault("SubnetIds")
  valid_593355 = validateParameter(valid_593355, JArray, required = true, default = nil)
  if valid_593355 != nil:
    section.add "SubnetIds", valid_593355
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593356: Call_PostCreateDBSubnetGroup_593341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593356.validator(path, query, header, formData, body)
  let scheme = call_593356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593356.url(scheme.get, call_593356.host, call_593356.base,
                         call_593356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593356, url, valid)

proc call*(call_593357: Call_PostCreateDBSubnetGroup_593341;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          SubnetIds: JsonNode; Action: string = "CreateDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_593358 = newJObject()
  var formData_593359 = newJObject()
  add(formData_593359, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_593358, "Action", newJString(Action))
  add(formData_593359, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593358, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_593359.add "SubnetIds", SubnetIds
  result = call_593357.call(nil, query_593358, nil, formData_593359, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_593341(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_593342, base: "/",
    url: url_PostCreateDBSubnetGroup_593343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_593323 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBSubnetGroup_593325(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_593324(path: JsonNode; query: JsonNode;
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
  var valid_593326 = query.getOrDefault("SubnetIds")
  valid_593326 = validateParameter(valid_593326, JArray, required = true, default = nil)
  if valid_593326 != nil:
    section.add "SubnetIds", valid_593326
  var valid_593327 = query.getOrDefault("Action")
  valid_593327 = validateParameter(valid_593327, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_593327 != nil:
    section.add "Action", valid_593327
  var valid_593328 = query.getOrDefault("DBSubnetGroupDescription")
  valid_593328 = validateParameter(valid_593328, JString, required = true,
                                 default = nil)
  if valid_593328 != nil:
    section.add "DBSubnetGroupDescription", valid_593328
  var valid_593329 = query.getOrDefault("DBSubnetGroupName")
  valid_593329 = validateParameter(valid_593329, JString, required = true,
                                 default = nil)
  if valid_593329 != nil:
    section.add "DBSubnetGroupName", valid_593329
  var valid_593330 = query.getOrDefault("Version")
  valid_593330 = validateParameter(valid_593330, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593330 != nil:
    section.add "Version", valid_593330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593331 = header.getOrDefault("X-Amz-Signature")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Signature", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Content-Sha256", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Date")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Date", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Credential")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Credential", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Security-Token")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Security-Token", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Algorithm")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Algorithm", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-SignedHeaders", valid_593337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593338: Call_GetCreateDBSubnetGroup_593323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593338.validator(path, query, header, formData, body)
  let scheme = call_593338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593338.url(scheme.get, call_593338.host, call_593338.base,
                         call_593338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593338, url, valid)

proc call*(call_593339: Call_GetCreateDBSubnetGroup_593323; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_593340 = newJObject()
  if SubnetIds != nil:
    query_593340.add "SubnetIds", SubnetIds
  add(query_593340, "Action", newJString(Action))
  add(query_593340, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_593340, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593340, "Version", newJString(Version))
  result = call_593339.call(nil, query_593340, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_593323(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_593324, base: "/",
    url: url_GetCreateDBSubnetGroup_593325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_593381 = ref object of OpenApiRestCall_592348
proc url_PostCreateEventSubscription_593383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEventSubscription_593382(path: JsonNode; query: JsonNode;
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
  var valid_593384 = query.getOrDefault("Action")
  valid_593384 = validateParameter(valid_593384, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_593384 != nil:
    section.add "Action", valid_593384
  var valid_593385 = query.getOrDefault("Version")
  valid_593385 = validateParameter(valid_593385, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593385 != nil:
    section.add "Version", valid_593385
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593386 = header.getOrDefault("X-Amz-Signature")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Signature", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Content-Sha256", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-Date")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-Date", valid_593388
  var valid_593389 = header.getOrDefault("X-Amz-Credential")
  valid_593389 = validateParameter(valid_593389, JString, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "X-Amz-Credential", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-Security-Token")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Security-Token", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-Algorithm")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-Algorithm", valid_593391
  var valid_593392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-SignedHeaders", valid_593392
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIds: JArray
  ##   SnsTopicArn: JString (required)
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_593393 = formData.getOrDefault("SourceIds")
  valid_593393 = validateParameter(valid_593393, JArray, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "SourceIds", valid_593393
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_593394 = formData.getOrDefault("SnsTopicArn")
  valid_593394 = validateParameter(valid_593394, JString, required = true,
                                 default = nil)
  if valid_593394 != nil:
    section.add "SnsTopicArn", valid_593394
  var valid_593395 = formData.getOrDefault("Enabled")
  valid_593395 = validateParameter(valid_593395, JBool, required = false, default = nil)
  if valid_593395 != nil:
    section.add "Enabled", valid_593395
  var valid_593396 = formData.getOrDefault("SubscriptionName")
  valid_593396 = validateParameter(valid_593396, JString, required = true,
                                 default = nil)
  if valid_593396 != nil:
    section.add "SubscriptionName", valid_593396
  var valid_593397 = formData.getOrDefault("SourceType")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "SourceType", valid_593397
  var valid_593398 = formData.getOrDefault("EventCategories")
  valid_593398 = validateParameter(valid_593398, JArray, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "EventCategories", valid_593398
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593399: Call_PostCreateEventSubscription_593381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593399.validator(path, query, header, formData, body)
  let scheme = call_593399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593399.url(scheme.get, call_593399.host, call_593399.base,
                         call_593399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593399, url, valid)

proc call*(call_593400: Call_PostCreateEventSubscription_593381;
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
  var query_593401 = newJObject()
  var formData_593402 = newJObject()
  if SourceIds != nil:
    formData_593402.add "SourceIds", SourceIds
  add(formData_593402, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_593402, "Enabled", newJBool(Enabled))
  add(formData_593402, "SubscriptionName", newJString(SubscriptionName))
  add(formData_593402, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_593402.add "EventCategories", EventCategories
  add(query_593401, "Action", newJString(Action))
  add(query_593401, "Version", newJString(Version))
  result = call_593400.call(nil, query_593401, nil, formData_593402, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_593381(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_593382, base: "/",
    url: url_PostCreateEventSubscription_593383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_593360 = ref object of OpenApiRestCall_592348
proc url_GetCreateEventSubscription_593362(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEventSubscription_593361(path: JsonNode; query: JsonNode;
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
  var valid_593363 = query.getOrDefault("SourceType")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "SourceType", valid_593363
  var valid_593364 = query.getOrDefault("Enabled")
  valid_593364 = validateParameter(valid_593364, JBool, required = false, default = nil)
  if valid_593364 != nil:
    section.add "Enabled", valid_593364
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_593365 = query.getOrDefault("SubscriptionName")
  valid_593365 = validateParameter(valid_593365, JString, required = true,
                                 default = nil)
  if valid_593365 != nil:
    section.add "SubscriptionName", valid_593365
  var valid_593366 = query.getOrDefault("EventCategories")
  valid_593366 = validateParameter(valid_593366, JArray, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "EventCategories", valid_593366
  var valid_593367 = query.getOrDefault("SourceIds")
  valid_593367 = validateParameter(valid_593367, JArray, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "SourceIds", valid_593367
  var valid_593368 = query.getOrDefault("Action")
  valid_593368 = validateParameter(valid_593368, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_593368 != nil:
    section.add "Action", valid_593368
  var valid_593369 = query.getOrDefault("SnsTopicArn")
  valid_593369 = validateParameter(valid_593369, JString, required = true,
                                 default = nil)
  if valid_593369 != nil:
    section.add "SnsTopicArn", valid_593369
  var valid_593370 = query.getOrDefault("Version")
  valid_593370 = validateParameter(valid_593370, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593370 != nil:
    section.add "Version", valid_593370
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593371 = header.getOrDefault("X-Amz-Signature")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Signature", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Content-Sha256", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-Date")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-Date", valid_593373
  var valid_593374 = header.getOrDefault("X-Amz-Credential")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "X-Amz-Credential", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-Security-Token")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-Security-Token", valid_593375
  var valid_593376 = header.getOrDefault("X-Amz-Algorithm")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "X-Amz-Algorithm", valid_593376
  var valid_593377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593377 = validateParameter(valid_593377, JString, required = false,
                                 default = nil)
  if valid_593377 != nil:
    section.add "X-Amz-SignedHeaders", valid_593377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593378: Call_GetCreateEventSubscription_593360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593378.validator(path, query, header, formData, body)
  let scheme = call_593378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593378.url(scheme.get, call_593378.host, call_593378.base,
                         call_593378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593378, url, valid)

proc call*(call_593379: Call_GetCreateEventSubscription_593360;
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
  var query_593380 = newJObject()
  add(query_593380, "SourceType", newJString(SourceType))
  add(query_593380, "Enabled", newJBool(Enabled))
  add(query_593380, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_593380.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_593380.add "SourceIds", SourceIds
  add(query_593380, "Action", newJString(Action))
  add(query_593380, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_593380, "Version", newJString(Version))
  result = call_593379.call(nil, query_593380, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_593360(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_593361, base: "/",
    url: url_GetCreateEventSubscription_593362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_593422 = ref object of OpenApiRestCall_592348
proc url_PostCreateOptionGroup_593424(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateOptionGroup_593423(path: JsonNode; query: JsonNode;
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
  var valid_593425 = query.getOrDefault("Action")
  valid_593425 = validateParameter(valid_593425, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_593425 != nil:
    section.add "Action", valid_593425
  var valid_593426 = query.getOrDefault("Version")
  valid_593426 = validateParameter(valid_593426, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593426 != nil:
    section.add "Version", valid_593426
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593427 = header.getOrDefault("X-Amz-Signature")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Signature", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-Content-Sha256", valid_593428
  var valid_593429 = header.getOrDefault("X-Amz-Date")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Date", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-Credential")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-Credential", valid_593430
  var valid_593431 = header.getOrDefault("X-Amz-Security-Token")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Security-Token", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-Algorithm")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Algorithm", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-SignedHeaders", valid_593433
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_593434 = formData.getOrDefault("OptionGroupDescription")
  valid_593434 = validateParameter(valid_593434, JString, required = true,
                                 default = nil)
  if valid_593434 != nil:
    section.add "OptionGroupDescription", valid_593434
  var valid_593435 = formData.getOrDefault("EngineName")
  valid_593435 = validateParameter(valid_593435, JString, required = true,
                                 default = nil)
  if valid_593435 != nil:
    section.add "EngineName", valid_593435
  var valid_593436 = formData.getOrDefault("MajorEngineVersion")
  valid_593436 = validateParameter(valid_593436, JString, required = true,
                                 default = nil)
  if valid_593436 != nil:
    section.add "MajorEngineVersion", valid_593436
  var valid_593437 = formData.getOrDefault("OptionGroupName")
  valid_593437 = validateParameter(valid_593437, JString, required = true,
                                 default = nil)
  if valid_593437 != nil:
    section.add "OptionGroupName", valid_593437
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593438: Call_PostCreateOptionGroup_593422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593438.validator(path, query, header, formData, body)
  let scheme = call_593438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593438.url(scheme.get, call_593438.host, call_593438.base,
                         call_593438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593438, url, valid)

proc call*(call_593439: Call_PostCreateOptionGroup_593422;
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
  var query_593440 = newJObject()
  var formData_593441 = newJObject()
  add(formData_593441, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_593441, "EngineName", newJString(EngineName))
  add(formData_593441, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_593440, "Action", newJString(Action))
  add(formData_593441, "OptionGroupName", newJString(OptionGroupName))
  add(query_593440, "Version", newJString(Version))
  result = call_593439.call(nil, query_593440, nil, formData_593441, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_593422(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_593423, base: "/",
    url: url_PostCreateOptionGroup_593424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_593403 = ref object of OpenApiRestCall_592348
proc url_GetCreateOptionGroup_593405(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateOptionGroup_593404(path: JsonNode; query: JsonNode;
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
  var valid_593406 = query.getOrDefault("EngineName")
  valid_593406 = validateParameter(valid_593406, JString, required = true,
                                 default = nil)
  if valid_593406 != nil:
    section.add "EngineName", valid_593406
  var valid_593407 = query.getOrDefault("OptionGroupDescription")
  valid_593407 = validateParameter(valid_593407, JString, required = true,
                                 default = nil)
  if valid_593407 != nil:
    section.add "OptionGroupDescription", valid_593407
  var valid_593408 = query.getOrDefault("Action")
  valid_593408 = validateParameter(valid_593408, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_593408 != nil:
    section.add "Action", valid_593408
  var valid_593409 = query.getOrDefault("OptionGroupName")
  valid_593409 = validateParameter(valid_593409, JString, required = true,
                                 default = nil)
  if valid_593409 != nil:
    section.add "OptionGroupName", valid_593409
  var valid_593410 = query.getOrDefault("Version")
  valid_593410 = validateParameter(valid_593410, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593410 != nil:
    section.add "Version", valid_593410
  var valid_593411 = query.getOrDefault("MajorEngineVersion")
  valid_593411 = validateParameter(valid_593411, JString, required = true,
                                 default = nil)
  if valid_593411 != nil:
    section.add "MajorEngineVersion", valid_593411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593412 = header.getOrDefault("X-Amz-Signature")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Signature", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Content-Sha256", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-Date")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Date", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-Credential")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-Credential", valid_593415
  var valid_593416 = header.getOrDefault("X-Amz-Security-Token")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "X-Amz-Security-Token", valid_593416
  var valid_593417 = header.getOrDefault("X-Amz-Algorithm")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-Algorithm", valid_593417
  var valid_593418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-SignedHeaders", valid_593418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593419: Call_GetCreateOptionGroup_593403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593419.validator(path, query, header, formData, body)
  let scheme = call_593419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593419.url(scheme.get, call_593419.host, call_593419.base,
                         call_593419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593419, url, valid)

proc call*(call_593420: Call_GetCreateOptionGroup_593403; EngineName: string;
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
  var query_593421 = newJObject()
  add(query_593421, "EngineName", newJString(EngineName))
  add(query_593421, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_593421, "Action", newJString(Action))
  add(query_593421, "OptionGroupName", newJString(OptionGroupName))
  add(query_593421, "Version", newJString(Version))
  add(query_593421, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_593420.call(nil, query_593421, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_593403(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_593404, base: "/",
    url: url_GetCreateOptionGroup_593405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_593460 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBInstance_593462(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_593461(path: JsonNode; query: JsonNode;
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
  var valid_593463 = query.getOrDefault("Action")
  valid_593463 = validateParameter(valid_593463, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_593463 != nil:
    section.add "Action", valid_593463
  var valid_593464 = query.getOrDefault("Version")
  valid_593464 = validateParameter(valid_593464, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593464 != nil:
    section.add "Version", valid_593464
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593465 = header.getOrDefault("X-Amz-Signature")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-Signature", valid_593465
  var valid_593466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "X-Amz-Content-Sha256", valid_593466
  var valid_593467 = header.getOrDefault("X-Amz-Date")
  valid_593467 = validateParameter(valid_593467, JString, required = false,
                                 default = nil)
  if valid_593467 != nil:
    section.add "X-Amz-Date", valid_593467
  var valid_593468 = header.getOrDefault("X-Amz-Credential")
  valid_593468 = validateParameter(valid_593468, JString, required = false,
                                 default = nil)
  if valid_593468 != nil:
    section.add "X-Amz-Credential", valid_593468
  var valid_593469 = header.getOrDefault("X-Amz-Security-Token")
  valid_593469 = validateParameter(valid_593469, JString, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "X-Amz-Security-Token", valid_593469
  var valid_593470 = header.getOrDefault("X-Amz-Algorithm")
  valid_593470 = validateParameter(valid_593470, JString, required = false,
                                 default = nil)
  if valid_593470 != nil:
    section.add "X-Amz-Algorithm", valid_593470
  var valid_593471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593471 = validateParameter(valid_593471, JString, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "X-Amz-SignedHeaders", valid_593471
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593472 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593472 = validateParameter(valid_593472, JString, required = true,
                                 default = nil)
  if valid_593472 != nil:
    section.add "DBInstanceIdentifier", valid_593472
  var valid_593473 = formData.getOrDefault("SkipFinalSnapshot")
  valid_593473 = validateParameter(valid_593473, JBool, required = false, default = nil)
  if valid_593473 != nil:
    section.add "SkipFinalSnapshot", valid_593473
  var valid_593474 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_593474
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593475: Call_PostDeleteDBInstance_593460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593475.validator(path, query, header, formData, body)
  let scheme = call_593475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593475.url(scheme.get, call_593475.host, call_593475.base,
                         call_593475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593475, url, valid)

proc call*(call_593476: Call_PostDeleteDBInstance_593460;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_593477 = newJObject()
  var formData_593478 = newJObject()
  add(formData_593478, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593477, "Action", newJString(Action))
  add(formData_593478, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_593478, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_593477, "Version", newJString(Version))
  result = call_593476.call(nil, query_593477, nil, formData_593478, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_593460(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_593461, base: "/",
    url: url_PostDeleteDBInstance_593462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_593442 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBInstance_593444(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_593443(path: JsonNode; query: JsonNode;
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
  var valid_593445 = query.getOrDefault("DBInstanceIdentifier")
  valid_593445 = validateParameter(valid_593445, JString, required = true,
                                 default = nil)
  if valid_593445 != nil:
    section.add "DBInstanceIdentifier", valid_593445
  var valid_593446 = query.getOrDefault("SkipFinalSnapshot")
  valid_593446 = validateParameter(valid_593446, JBool, required = false, default = nil)
  if valid_593446 != nil:
    section.add "SkipFinalSnapshot", valid_593446
  var valid_593447 = query.getOrDefault("Action")
  valid_593447 = validateParameter(valid_593447, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_593447 != nil:
    section.add "Action", valid_593447
  var valid_593448 = query.getOrDefault("Version")
  valid_593448 = validateParameter(valid_593448, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593448 != nil:
    section.add "Version", valid_593448
  var valid_593449 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_593449
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593450 = header.getOrDefault("X-Amz-Signature")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Signature", valid_593450
  var valid_593451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Content-Sha256", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-Date")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-Date", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-Credential")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-Credential", valid_593453
  var valid_593454 = header.getOrDefault("X-Amz-Security-Token")
  valid_593454 = validateParameter(valid_593454, JString, required = false,
                                 default = nil)
  if valid_593454 != nil:
    section.add "X-Amz-Security-Token", valid_593454
  var valid_593455 = header.getOrDefault("X-Amz-Algorithm")
  valid_593455 = validateParameter(valid_593455, JString, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "X-Amz-Algorithm", valid_593455
  var valid_593456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593456 = validateParameter(valid_593456, JString, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "X-Amz-SignedHeaders", valid_593456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593457: Call_GetDeleteDBInstance_593442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593457.validator(path, query, header, formData, body)
  let scheme = call_593457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593457.url(scheme.get, call_593457.host, call_593457.base,
                         call_593457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593457, url, valid)

proc call*(call_593458: Call_GetDeleteDBInstance_593442;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2013-02-12";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_593459 = newJObject()
  add(query_593459, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593459, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_593459, "Action", newJString(Action))
  add(query_593459, "Version", newJString(Version))
  add(query_593459, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_593458.call(nil, query_593459, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_593442(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_593443, base: "/",
    url: url_GetDeleteDBInstance_593444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_593495 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBParameterGroup_593497(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBParameterGroup_593496(path: JsonNode; query: JsonNode;
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
  var valid_593498 = query.getOrDefault("Action")
  valid_593498 = validateParameter(valid_593498, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_593498 != nil:
    section.add "Action", valid_593498
  var valid_593499 = query.getOrDefault("Version")
  valid_593499 = validateParameter(valid_593499, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593499 != nil:
    section.add "Version", valid_593499
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593500 = header.getOrDefault("X-Amz-Signature")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-Signature", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Content-Sha256", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-Date")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-Date", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-Credential")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Credential", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-Security-Token")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-Security-Token", valid_593504
  var valid_593505 = header.getOrDefault("X-Amz-Algorithm")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "X-Amz-Algorithm", valid_593505
  var valid_593506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "X-Amz-SignedHeaders", valid_593506
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_593507 = formData.getOrDefault("DBParameterGroupName")
  valid_593507 = validateParameter(valid_593507, JString, required = true,
                                 default = nil)
  if valid_593507 != nil:
    section.add "DBParameterGroupName", valid_593507
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593508: Call_PostDeleteDBParameterGroup_593495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593508.validator(path, query, header, formData, body)
  let scheme = call_593508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593508.url(scheme.get, call_593508.host, call_593508.base,
                         call_593508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593508, url, valid)

proc call*(call_593509: Call_PostDeleteDBParameterGroup_593495;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593510 = newJObject()
  var formData_593511 = newJObject()
  add(formData_593511, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593510, "Action", newJString(Action))
  add(query_593510, "Version", newJString(Version))
  result = call_593509.call(nil, query_593510, nil, formData_593511, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_593495(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_593496, base: "/",
    url: url_PostDeleteDBParameterGroup_593497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_593479 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBParameterGroup_593481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBParameterGroup_593480(path: JsonNode; query: JsonNode;
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
  var valid_593482 = query.getOrDefault("DBParameterGroupName")
  valid_593482 = validateParameter(valid_593482, JString, required = true,
                                 default = nil)
  if valid_593482 != nil:
    section.add "DBParameterGroupName", valid_593482
  var valid_593483 = query.getOrDefault("Action")
  valid_593483 = validateParameter(valid_593483, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_593483 != nil:
    section.add "Action", valid_593483
  var valid_593484 = query.getOrDefault("Version")
  valid_593484 = validateParameter(valid_593484, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593484 != nil:
    section.add "Version", valid_593484
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593485 = header.getOrDefault("X-Amz-Signature")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-Signature", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Content-Sha256", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Date")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Date", valid_593487
  var valid_593488 = header.getOrDefault("X-Amz-Credential")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "X-Amz-Credential", valid_593488
  var valid_593489 = header.getOrDefault("X-Amz-Security-Token")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-Security-Token", valid_593489
  var valid_593490 = header.getOrDefault("X-Amz-Algorithm")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "X-Amz-Algorithm", valid_593490
  var valid_593491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "X-Amz-SignedHeaders", valid_593491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593492: Call_GetDeleteDBParameterGroup_593479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593492.validator(path, query, header, formData, body)
  let scheme = call_593492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593492.url(scheme.get, call_593492.host, call_593492.base,
                         call_593492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593492, url, valid)

proc call*(call_593493: Call_GetDeleteDBParameterGroup_593479;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593494 = newJObject()
  add(query_593494, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593494, "Action", newJString(Action))
  add(query_593494, "Version", newJString(Version))
  result = call_593493.call(nil, query_593494, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_593479(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_593480, base: "/",
    url: url_GetDeleteDBParameterGroup_593481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_593528 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBSecurityGroup_593530(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSecurityGroup_593529(path: JsonNode; query: JsonNode;
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
  var valid_593531 = query.getOrDefault("Action")
  valid_593531 = validateParameter(valid_593531, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_593531 != nil:
    section.add "Action", valid_593531
  var valid_593532 = query.getOrDefault("Version")
  valid_593532 = validateParameter(valid_593532, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593532 != nil:
    section.add "Version", valid_593532
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593533 = header.getOrDefault("X-Amz-Signature")
  valid_593533 = validateParameter(valid_593533, JString, required = false,
                                 default = nil)
  if valid_593533 != nil:
    section.add "X-Amz-Signature", valid_593533
  var valid_593534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "X-Amz-Content-Sha256", valid_593534
  var valid_593535 = header.getOrDefault("X-Amz-Date")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "X-Amz-Date", valid_593535
  var valid_593536 = header.getOrDefault("X-Amz-Credential")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "X-Amz-Credential", valid_593536
  var valid_593537 = header.getOrDefault("X-Amz-Security-Token")
  valid_593537 = validateParameter(valid_593537, JString, required = false,
                                 default = nil)
  if valid_593537 != nil:
    section.add "X-Amz-Security-Token", valid_593537
  var valid_593538 = header.getOrDefault("X-Amz-Algorithm")
  valid_593538 = validateParameter(valid_593538, JString, required = false,
                                 default = nil)
  if valid_593538 != nil:
    section.add "X-Amz-Algorithm", valid_593538
  var valid_593539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593539 = validateParameter(valid_593539, JString, required = false,
                                 default = nil)
  if valid_593539 != nil:
    section.add "X-Amz-SignedHeaders", valid_593539
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_593540 = formData.getOrDefault("DBSecurityGroupName")
  valid_593540 = validateParameter(valid_593540, JString, required = true,
                                 default = nil)
  if valid_593540 != nil:
    section.add "DBSecurityGroupName", valid_593540
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593541: Call_PostDeleteDBSecurityGroup_593528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593541.validator(path, query, header, formData, body)
  let scheme = call_593541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593541.url(scheme.get, call_593541.host, call_593541.base,
                         call_593541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593541, url, valid)

proc call*(call_593542: Call_PostDeleteDBSecurityGroup_593528;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593543 = newJObject()
  var formData_593544 = newJObject()
  add(formData_593544, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593543, "Action", newJString(Action))
  add(query_593543, "Version", newJString(Version))
  result = call_593542.call(nil, query_593543, nil, formData_593544, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_593528(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_593529, base: "/",
    url: url_PostDeleteDBSecurityGroup_593530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_593512 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBSecurityGroup_593514(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSecurityGroup_593513(path: JsonNode; query: JsonNode;
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
  var valid_593515 = query.getOrDefault("DBSecurityGroupName")
  valid_593515 = validateParameter(valid_593515, JString, required = true,
                                 default = nil)
  if valid_593515 != nil:
    section.add "DBSecurityGroupName", valid_593515
  var valid_593516 = query.getOrDefault("Action")
  valid_593516 = validateParameter(valid_593516, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_593516 != nil:
    section.add "Action", valid_593516
  var valid_593517 = query.getOrDefault("Version")
  valid_593517 = validateParameter(valid_593517, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593517 != nil:
    section.add "Version", valid_593517
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593518 = header.getOrDefault("X-Amz-Signature")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "X-Amz-Signature", valid_593518
  var valid_593519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-Content-Sha256", valid_593519
  var valid_593520 = header.getOrDefault("X-Amz-Date")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "X-Amz-Date", valid_593520
  var valid_593521 = header.getOrDefault("X-Amz-Credential")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-Credential", valid_593521
  var valid_593522 = header.getOrDefault("X-Amz-Security-Token")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-Security-Token", valid_593522
  var valid_593523 = header.getOrDefault("X-Amz-Algorithm")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "X-Amz-Algorithm", valid_593523
  var valid_593524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593524 = validateParameter(valid_593524, JString, required = false,
                                 default = nil)
  if valid_593524 != nil:
    section.add "X-Amz-SignedHeaders", valid_593524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593525: Call_GetDeleteDBSecurityGroup_593512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593525.validator(path, query, header, formData, body)
  let scheme = call_593525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593525.url(scheme.get, call_593525.host, call_593525.base,
                         call_593525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593525, url, valid)

proc call*(call_593526: Call_GetDeleteDBSecurityGroup_593512;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593527 = newJObject()
  add(query_593527, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593527, "Action", newJString(Action))
  add(query_593527, "Version", newJString(Version))
  result = call_593526.call(nil, query_593527, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_593512(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_593513, base: "/",
    url: url_GetDeleteDBSecurityGroup_593514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_593561 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBSnapshot_593563(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSnapshot_593562(path: JsonNode; query: JsonNode;
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
  var valid_593564 = query.getOrDefault("Action")
  valid_593564 = validateParameter(valid_593564, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_593564 != nil:
    section.add "Action", valid_593564
  var valid_593565 = query.getOrDefault("Version")
  valid_593565 = validateParameter(valid_593565, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593565 != nil:
    section.add "Version", valid_593565
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593566 = header.getOrDefault("X-Amz-Signature")
  valid_593566 = validateParameter(valid_593566, JString, required = false,
                                 default = nil)
  if valid_593566 != nil:
    section.add "X-Amz-Signature", valid_593566
  var valid_593567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "X-Amz-Content-Sha256", valid_593567
  var valid_593568 = header.getOrDefault("X-Amz-Date")
  valid_593568 = validateParameter(valid_593568, JString, required = false,
                                 default = nil)
  if valid_593568 != nil:
    section.add "X-Amz-Date", valid_593568
  var valid_593569 = header.getOrDefault("X-Amz-Credential")
  valid_593569 = validateParameter(valid_593569, JString, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "X-Amz-Credential", valid_593569
  var valid_593570 = header.getOrDefault("X-Amz-Security-Token")
  valid_593570 = validateParameter(valid_593570, JString, required = false,
                                 default = nil)
  if valid_593570 != nil:
    section.add "X-Amz-Security-Token", valid_593570
  var valid_593571 = header.getOrDefault("X-Amz-Algorithm")
  valid_593571 = validateParameter(valid_593571, JString, required = false,
                                 default = nil)
  if valid_593571 != nil:
    section.add "X-Amz-Algorithm", valid_593571
  var valid_593572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = nil)
  if valid_593572 != nil:
    section.add "X-Amz-SignedHeaders", valid_593572
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_593573 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_593573 = validateParameter(valid_593573, JString, required = true,
                                 default = nil)
  if valid_593573 != nil:
    section.add "DBSnapshotIdentifier", valid_593573
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593574: Call_PostDeleteDBSnapshot_593561; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593574.validator(path, query, header, formData, body)
  let scheme = call_593574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593574.url(scheme.get, call_593574.host, call_593574.base,
                         call_593574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593574, url, valid)

proc call*(call_593575: Call_PostDeleteDBSnapshot_593561;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593576 = newJObject()
  var formData_593577 = newJObject()
  add(formData_593577, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593576, "Action", newJString(Action))
  add(query_593576, "Version", newJString(Version))
  result = call_593575.call(nil, query_593576, nil, formData_593577, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_593561(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_593562, base: "/",
    url: url_PostDeleteDBSnapshot_593563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_593545 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBSnapshot_593547(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSnapshot_593546(path: JsonNode; query: JsonNode;
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
  var valid_593548 = query.getOrDefault("DBSnapshotIdentifier")
  valid_593548 = validateParameter(valid_593548, JString, required = true,
                                 default = nil)
  if valid_593548 != nil:
    section.add "DBSnapshotIdentifier", valid_593548
  var valid_593549 = query.getOrDefault("Action")
  valid_593549 = validateParameter(valid_593549, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_593549 != nil:
    section.add "Action", valid_593549
  var valid_593550 = query.getOrDefault("Version")
  valid_593550 = validateParameter(valid_593550, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593550 != nil:
    section.add "Version", valid_593550
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593551 = header.getOrDefault("X-Amz-Signature")
  valid_593551 = validateParameter(valid_593551, JString, required = false,
                                 default = nil)
  if valid_593551 != nil:
    section.add "X-Amz-Signature", valid_593551
  var valid_593552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593552 = validateParameter(valid_593552, JString, required = false,
                                 default = nil)
  if valid_593552 != nil:
    section.add "X-Amz-Content-Sha256", valid_593552
  var valid_593553 = header.getOrDefault("X-Amz-Date")
  valid_593553 = validateParameter(valid_593553, JString, required = false,
                                 default = nil)
  if valid_593553 != nil:
    section.add "X-Amz-Date", valid_593553
  var valid_593554 = header.getOrDefault("X-Amz-Credential")
  valid_593554 = validateParameter(valid_593554, JString, required = false,
                                 default = nil)
  if valid_593554 != nil:
    section.add "X-Amz-Credential", valid_593554
  var valid_593555 = header.getOrDefault("X-Amz-Security-Token")
  valid_593555 = validateParameter(valid_593555, JString, required = false,
                                 default = nil)
  if valid_593555 != nil:
    section.add "X-Amz-Security-Token", valid_593555
  var valid_593556 = header.getOrDefault("X-Amz-Algorithm")
  valid_593556 = validateParameter(valid_593556, JString, required = false,
                                 default = nil)
  if valid_593556 != nil:
    section.add "X-Amz-Algorithm", valid_593556
  var valid_593557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593557 = validateParameter(valid_593557, JString, required = false,
                                 default = nil)
  if valid_593557 != nil:
    section.add "X-Amz-SignedHeaders", valid_593557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593558: Call_GetDeleteDBSnapshot_593545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593558.validator(path, query, header, formData, body)
  let scheme = call_593558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593558.url(scheme.get, call_593558.host, call_593558.base,
                         call_593558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593558, url, valid)

proc call*(call_593559: Call_GetDeleteDBSnapshot_593545;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593560 = newJObject()
  add(query_593560, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593560, "Action", newJString(Action))
  add(query_593560, "Version", newJString(Version))
  result = call_593559.call(nil, query_593560, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_593545(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_593546, base: "/",
    url: url_GetDeleteDBSnapshot_593547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_593594 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBSubnetGroup_593596(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_593595(path: JsonNode; query: JsonNode;
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
  var valid_593597 = query.getOrDefault("Action")
  valid_593597 = validateParameter(valid_593597, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_593597 != nil:
    section.add "Action", valid_593597
  var valid_593598 = query.getOrDefault("Version")
  valid_593598 = validateParameter(valid_593598, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593598 != nil:
    section.add "Version", valid_593598
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593599 = header.getOrDefault("X-Amz-Signature")
  valid_593599 = validateParameter(valid_593599, JString, required = false,
                                 default = nil)
  if valid_593599 != nil:
    section.add "X-Amz-Signature", valid_593599
  var valid_593600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "X-Amz-Content-Sha256", valid_593600
  var valid_593601 = header.getOrDefault("X-Amz-Date")
  valid_593601 = validateParameter(valid_593601, JString, required = false,
                                 default = nil)
  if valid_593601 != nil:
    section.add "X-Amz-Date", valid_593601
  var valid_593602 = header.getOrDefault("X-Amz-Credential")
  valid_593602 = validateParameter(valid_593602, JString, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "X-Amz-Credential", valid_593602
  var valid_593603 = header.getOrDefault("X-Amz-Security-Token")
  valid_593603 = validateParameter(valid_593603, JString, required = false,
                                 default = nil)
  if valid_593603 != nil:
    section.add "X-Amz-Security-Token", valid_593603
  var valid_593604 = header.getOrDefault("X-Amz-Algorithm")
  valid_593604 = validateParameter(valid_593604, JString, required = false,
                                 default = nil)
  if valid_593604 != nil:
    section.add "X-Amz-Algorithm", valid_593604
  var valid_593605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593605 = validateParameter(valid_593605, JString, required = false,
                                 default = nil)
  if valid_593605 != nil:
    section.add "X-Amz-SignedHeaders", valid_593605
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_593606 = formData.getOrDefault("DBSubnetGroupName")
  valid_593606 = validateParameter(valid_593606, JString, required = true,
                                 default = nil)
  if valid_593606 != nil:
    section.add "DBSubnetGroupName", valid_593606
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593607: Call_PostDeleteDBSubnetGroup_593594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593607.validator(path, query, header, formData, body)
  let scheme = call_593607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593607.url(scheme.get, call_593607.host, call_593607.base,
                         call_593607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593607, url, valid)

proc call*(call_593608: Call_PostDeleteDBSubnetGroup_593594;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_593609 = newJObject()
  var formData_593610 = newJObject()
  add(query_593609, "Action", newJString(Action))
  add(formData_593610, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593609, "Version", newJString(Version))
  result = call_593608.call(nil, query_593609, nil, formData_593610, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_593594(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_593595, base: "/",
    url: url_PostDeleteDBSubnetGroup_593596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_593578 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBSubnetGroup_593580(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_593579(path: JsonNode; query: JsonNode;
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
  var valid_593581 = query.getOrDefault("Action")
  valid_593581 = validateParameter(valid_593581, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_593581 != nil:
    section.add "Action", valid_593581
  var valid_593582 = query.getOrDefault("DBSubnetGroupName")
  valid_593582 = validateParameter(valid_593582, JString, required = true,
                                 default = nil)
  if valid_593582 != nil:
    section.add "DBSubnetGroupName", valid_593582
  var valid_593583 = query.getOrDefault("Version")
  valid_593583 = validateParameter(valid_593583, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593583 != nil:
    section.add "Version", valid_593583
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593584 = header.getOrDefault("X-Amz-Signature")
  valid_593584 = validateParameter(valid_593584, JString, required = false,
                                 default = nil)
  if valid_593584 != nil:
    section.add "X-Amz-Signature", valid_593584
  var valid_593585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593585 = validateParameter(valid_593585, JString, required = false,
                                 default = nil)
  if valid_593585 != nil:
    section.add "X-Amz-Content-Sha256", valid_593585
  var valid_593586 = header.getOrDefault("X-Amz-Date")
  valid_593586 = validateParameter(valid_593586, JString, required = false,
                                 default = nil)
  if valid_593586 != nil:
    section.add "X-Amz-Date", valid_593586
  var valid_593587 = header.getOrDefault("X-Amz-Credential")
  valid_593587 = validateParameter(valid_593587, JString, required = false,
                                 default = nil)
  if valid_593587 != nil:
    section.add "X-Amz-Credential", valid_593587
  var valid_593588 = header.getOrDefault("X-Amz-Security-Token")
  valid_593588 = validateParameter(valid_593588, JString, required = false,
                                 default = nil)
  if valid_593588 != nil:
    section.add "X-Amz-Security-Token", valid_593588
  var valid_593589 = header.getOrDefault("X-Amz-Algorithm")
  valid_593589 = validateParameter(valid_593589, JString, required = false,
                                 default = nil)
  if valid_593589 != nil:
    section.add "X-Amz-Algorithm", valid_593589
  var valid_593590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593590 = validateParameter(valid_593590, JString, required = false,
                                 default = nil)
  if valid_593590 != nil:
    section.add "X-Amz-SignedHeaders", valid_593590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593591: Call_GetDeleteDBSubnetGroup_593578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593591.validator(path, query, header, formData, body)
  let scheme = call_593591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593591.url(scheme.get, call_593591.host, call_593591.base,
                         call_593591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593591, url, valid)

proc call*(call_593592: Call_GetDeleteDBSubnetGroup_593578;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_593593 = newJObject()
  add(query_593593, "Action", newJString(Action))
  add(query_593593, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593593, "Version", newJString(Version))
  result = call_593592.call(nil, query_593593, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_593578(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_593579, base: "/",
    url: url_GetDeleteDBSubnetGroup_593580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_593627 = ref object of OpenApiRestCall_592348
proc url_PostDeleteEventSubscription_593629(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEventSubscription_593628(path: JsonNode; query: JsonNode;
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
  var valid_593630 = query.getOrDefault("Action")
  valid_593630 = validateParameter(valid_593630, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_593630 != nil:
    section.add "Action", valid_593630
  var valid_593631 = query.getOrDefault("Version")
  valid_593631 = validateParameter(valid_593631, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593631 != nil:
    section.add "Version", valid_593631
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593632 = header.getOrDefault("X-Amz-Signature")
  valid_593632 = validateParameter(valid_593632, JString, required = false,
                                 default = nil)
  if valid_593632 != nil:
    section.add "X-Amz-Signature", valid_593632
  var valid_593633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593633 = validateParameter(valid_593633, JString, required = false,
                                 default = nil)
  if valid_593633 != nil:
    section.add "X-Amz-Content-Sha256", valid_593633
  var valid_593634 = header.getOrDefault("X-Amz-Date")
  valid_593634 = validateParameter(valid_593634, JString, required = false,
                                 default = nil)
  if valid_593634 != nil:
    section.add "X-Amz-Date", valid_593634
  var valid_593635 = header.getOrDefault("X-Amz-Credential")
  valid_593635 = validateParameter(valid_593635, JString, required = false,
                                 default = nil)
  if valid_593635 != nil:
    section.add "X-Amz-Credential", valid_593635
  var valid_593636 = header.getOrDefault("X-Amz-Security-Token")
  valid_593636 = validateParameter(valid_593636, JString, required = false,
                                 default = nil)
  if valid_593636 != nil:
    section.add "X-Amz-Security-Token", valid_593636
  var valid_593637 = header.getOrDefault("X-Amz-Algorithm")
  valid_593637 = validateParameter(valid_593637, JString, required = false,
                                 default = nil)
  if valid_593637 != nil:
    section.add "X-Amz-Algorithm", valid_593637
  var valid_593638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593638 = validateParameter(valid_593638, JString, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "X-Amz-SignedHeaders", valid_593638
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_593639 = formData.getOrDefault("SubscriptionName")
  valid_593639 = validateParameter(valid_593639, JString, required = true,
                                 default = nil)
  if valid_593639 != nil:
    section.add "SubscriptionName", valid_593639
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593640: Call_PostDeleteEventSubscription_593627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593640.validator(path, query, header, formData, body)
  let scheme = call_593640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593640.url(scheme.get, call_593640.host, call_593640.base,
                         call_593640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593640, url, valid)

proc call*(call_593641: Call_PostDeleteEventSubscription_593627;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593642 = newJObject()
  var formData_593643 = newJObject()
  add(formData_593643, "SubscriptionName", newJString(SubscriptionName))
  add(query_593642, "Action", newJString(Action))
  add(query_593642, "Version", newJString(Version))
  result = call_593641.call(nil, query_593642, nil, formData_593643, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_593627(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_593628, base: "/",
    url: url_PostDeleteEventSubscription_593629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_593611 = ref object of OpenApiRestCall_592348
proc url_GetDeleteEventSubscription_593613(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEventSubscription_593612(path: JsonNode; query: JsonNode;
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
  var valid_593614 = query.getOrDefault("SubscriptionName")
  valid_593614 = validateParameter(valid_593614, JString, required = true,
                                 default = nil)
  if valid_593614 != nil:
    section.add "SubscriptionName", valid_593614
  var valid_593615 = query.getOrDefault("Action")
  valid_593615 = validateParameter(valid_593615, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_593615 != nil:
    section.add "Action", valid_593615
  var valid_593616 = query.getOrDefault("Version")
  valid_593616 = validateParameter(valid_593616, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593616 != nil:
    section.add "Version", valid_593616
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593617 = header.getOrDefault("X-Amz-Signature")
  valid_593617 = validateParameter(valid_593617, JString, required = false,
                                 default = nil)
  if valid_593617 != nil:
    section.add "X-Amz-Signature", valid_593617
  var valid_593618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593618 = validateParameter(valid_593618, JString, required = false,
                                 default = nil)
  if valid_593618 != nil:
    section.add "X-Amz-Content-Sha256", valid_593618
  var valid_593619 = header.getOrDefault("X-Amz-Date")
  valid_593619 = validateParameter(valid_593619, JString, required = false,
                                 default = nil)
  if valid_593619 != nil:
    section.add "X-Amz-Date", valid_593619
  var valid_593620 = header.getOrDefault("X-Amz-Credential")
  valid_593620 = validateParameter(valid_593620, JString, required = false,
                                 default = nil)
  if valid_593620 != nil:
    section.add "X-Amz-Credential", valid_593620
  var valid_593621 = header.getOrDefault("X-Amz-Security-Token")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "X-Amz-Security-Token", valid_593621
  var valid_593622 = header.getOrDefault("X-Amz-Algorithm")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-Algorithm", valid_593622
  var valid_593623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-SignedHeaders", valid_593623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593624: Call_GetDeleteEventSubscription_593611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593624.validator(path, query, header, formData, body)
  let scheme = call_593624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593624.url(scheme.get, call_593624.host, call_593624.base,
                         call_593624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593624, url, valid)

proc call*(call_593625: Call_GetDeleteEventSubscription_593611;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593626 = newJObject()
  add(query_593626, "SubscriptionName", newJString(SubscriptionName))
  add(query_593626, "Action", newJString(Action))
  add(query_593626, "Version", newJString(Version))
  result = call_593625.call(nil, query_593626, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_593611(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_593612, base: "/",
    url: url_GetDeleteEventSubscription_593613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_593660 = ref object of OpenApiRestCall_592348
proc url_PostDeleteOptionGroup_593662(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteOptionGroup_593661(path: JsonNode; query: JsonNode;
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
  var valid_593663 = query.getOrDefault("Action")
  valid_593663 = validateParameter(valid_593663, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_593663 != nil:
    section.add "Action", valid_593663
  var valid_593664 = query.getOrDefault("Version")
  valid_593664 = validateParameter(valid_593664, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593664 != nil:
    section.add "Version", valid_593664
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593665 = header.getOrDefault("X-Amz-Signature")
  valid_593665 = validateParameter(valid_593665, JString, required = false,
                                 default = nil)
  if valid_593665 != nil:
    section.add "X-Amz-Signature", valid_593665
  var valid_593666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593666 = validateParameter(valid_593666, JString, required = false,
                                 default = nil)
  if valid_593666 != nil:
    section.add "X-Amz-Content-Sha256", valid_593666
  var valid_593667 = header.getOrDefault("X-Amz-Date")
  valid_593667 = validateParameter(valid_593667, JString, required = false,
                                 default = nil)
  if valid_593667 != nil:
    section.add "X-Amz-Date", valid_593667
  var valid_593668 = header.getOrDefault("X-Amz-Credential")
  valid_593668 = validateParameter(valid_593668, JString, required = false,
                                 default = nil)
  if valid_593668 != nil:
    section.add "X-Amz-Credential", valid_593668
  var valid_593669 = header.getOrDefault("X-Amz-Security-Token")
  valid_593669 = validateParameter(valid_593669, JString, required = false,
                                 default = nil)
  if valid_593669 != nil:
    section.add "X-Amz-Security-Token", valid_593669
  var valid_593670 = header.getOrDefault("X-Amz-Algorithm")
  valid_593670 = validateParameter(valid_593670, JString, required = false,
                                 default = nil)
  if valid_593670 != nil:
    section.add "X-Amz-Algorithm", valid_593670
  var valid_593671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593671 = validateParameter(valid_593671, JString, required = false,
                                 default = nil)
  if valid_593671 != nil:
    section.add "X-Amz-SignedHeaders", valid_593671
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_593672 = formData.getOrDefault("OptionGroupName")
  valid_593672 = validateParameter(valid_593672, JString, required = true,
                                 default = nil)
  if valid_593672 != nil:
    section.add "OptionGroupName", valid_593672
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593673: Call_PostDeleteOptionGroup_593660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593673.validator(path, query, header, formData, body)
  let scheme = call_593673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593673.url(scheme.get, call_593673.host, call_593673.base,
                         call_593673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593673, url, valid)

proc call*(call_593674: Call_PostDeleteOptionGroup_593660; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_593675 = newJObject()
  var formData_593676 = newJObject()
  add(query_593675, "Action", newJString(Action))
  add(formData_593676, "OptionGroupName", newJString(OptionGroupName))
  add(query_593675, "Version", newJString(Version))
  result = call_593674.call(nil, query_593675, nil, formData_593676, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_593660(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_593661, base: "/",
    url: url_PostDeleteOptionGroup_593662, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_593644 = ref object of OpenApiRestCall_592348
proc url_GetDeleteOptionGroup_593646(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteOptionGroup_593645(path: JsonNode; query: JsonNode;
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
  var valid_593647 = query.getOrDefault("Action")
  valid_593647 = validateParameter(valid_593647, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_593647 != nil:
    section.add "Action", valid_593647
  var valid_593648 = query.getOrDefault("OptionGroupName")
  valid_593648 = validateParameter(valid_593648, JString, required = true,
                                 default = nil)
  if valid_593648 != nil:
    section.add "OptionGroupName", valid_593648
  var valid_593649 = query.getOrDefault("Version")
  valid_593649 = validateParameter(valid_593649, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593649 != nil:
    section.add "Version", valid_593649
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593650 = header.getOrDefault("X-Amz-Signature")
  valid_593650 = validateParameter(valid_593650, JString, required = false,
                                 default = nil)
  if valid_593650 != nil:
    section.add "X-Amz-Signature", valid_593650
  var valid_593651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593651 = validateParameter(valid_593651, JString, required = false,
                                 default = nil)
  if valid_593651 != nil:
    section.add "X-Amz-Content-Sha256", valid_593651
  var valid_593652 = header.getOrDefault("X-Amz-Date")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = nil)
  if valid_593652 != nil:
    section.add "X-Amz-Date", valid_593652
  var valid_593653 = header.getOrDefault("X-Amz-Credential")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "X-Amz-Credential", valid_593653
  var valid_593654 = header.getOrDefault("X-Amz-Security-Token")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "X-Amz-Security-Token", valid_593654
  var valid_593655 = header.getOrDefault("X-Amz-Algorithm")
  valid_593655 = validateParameter(valid_593655, JString, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "X-Amz-Algorithm", valid_593655
  var valid_593656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593656 = validateParameter(valid_593656, JString, required = false,
                                 default = nil)
  if valid_593656 != nil:
    section.add "X-Amz-SignedHeaders", valid_593656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593657: Call_GetDeleteOptionGroup_593644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593657.validator(path, query, header, formData, body)
  let scheme = call_593657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593657.url(scheme.get, call_593657.host, call_593657.base,
                         call_593657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593657, url, valid)

proc call*(call_593658: Call_GetDeleteOptionGroup_593644; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_593659 = newJObject()
  add(query_593659, "Action", newJString(Action))
  add(query_593659, "OptionGroupName", newJString(OptionGroupName))
  add(query_593659, "Version", newJString(Version))
  result = call_593658.call(nil, query_593659, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_593644(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_593645, base: "/",
    url: url_GetDeleteOptionGroup_593646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_593699 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBEngineVersions_593701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_593700(path: JsonNode; query: JsonNode;
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
  var valid_593702 = query.getOrDefault("Action")
  valid_593702 = validateParameter(valid_593702, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_593702 != nil:
    section.add "Action", valid_593702
  var valid_593703 = query.getOrDefault("Version")
  valid_593703 = validateParameter(valid_593703, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593703 != nil:
    section.add "Version", valid_593703
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593704 = header.getOrDefault("X-Amz-Signature")
  valid_593704 = validateParameter(valid_593704, JString, required = false,
                                 default = nil)
  if valid_593704 != nil:
    section.add "X-Amz-Signature", valid_593704
  var valid_593705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593705 = validateParameter(valid_593705, JString, required = false,
                                 default = nil)
  if valid_593705 != nil:
    section.add "X-Amz-Content-Sha256", valid_593705
  var valid_593706 = header.getOrDefault("X-Amz-Date")
  valid_593706 = validateParameter(valid_593706, JString, required = false,
                                 default = nil)
  if valid_593706 != nil:
    section.add "X-Amz-Date", valid_593706
  var valid_593707 = header.getOrDefault("X-Amz-Credential")
  valid_593707 = validateParameter(valid_593707, JString, required = false,
                                 default = nil)
  if valid_593707 != nil:
    section.add "X-Amz-Credential", valid_593707
  var valid_593708 = header.getOrDefault("X-Amz-Security-Token")
  valid_593708 = validateParameter(valid_593708, JString, required = false,
                                 default = nil)
  if valid_593708 != nil:
    section.add "X-Amz-Security-Token", valid_593708
  var valid_593709 = header.getOrDefault("X-Amz-Algorithm")
  valid_593709 = validateParameter(valid_593709, JString, required = false,
                                 default = nil)
  if valid_593709 != nil:
    section.add "X-Amz-Algorithm", valid_593709
  var valid_593710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593710 = validateParameter(valid_593710, JString, required = false,
                                 default = nil)
  if valid_593710 != nil:
    section.add "X-Amz-SignedHeaders", valid_593710
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
  var valid_593711 = formData.getOrDefault("DefaultOnly")
  valid_593711 = validateParameter(valid_593711, JBool, required = false, default = nil)
  if valid_593711 != nil:
    section.add "DefaultOnly", valid_593711
  var valid_593712 = formData.getOrDefault("MaxRecords")
  valid_593712 = validateParameter(valid_593712, JInt, required = false, default = nil)
  if valid_593712 != nil:
    section.add "MaxRecords", valid_593712
  var valid_593713 = formData.getOrDefault("EngineVersion")
  valid_593713 = validateParameter(valid_593713, JString, required = false,
                                 default = nil)
  if valid_593713 != nil:
    section.add "EngineVersion", valid_593713
  var valid_593714 = formData.getOrDefault("Marker")
  valid_593714 = validateParameter(valid_593714, JString, required = false,
                                 default = nil)
  if valid_593714 != nil:
    section.add "Marker", valid_593714
  var valid_593715 = formData.getOrDefault("Engine")
  valid_593715 = validateParameter(valid_593715, JString, required = false,
                                 default = nil)
  if valid_593715 != nil:
    section.add "Engine", valid_593715
  var valid_593716 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_593716 = validateParameter(valid_593716, JBool, required = false, default = nil)
  if valid_593716 != nil:
    section.add "ListSupportedCharacterSets", valid_593716
  var valid_593717 = formData.getOrDefault("DBParameterGroupFamily")
  valid_593717 = validateParameter(valid_593717, JString, required = false,
                                 default = nil)
  if valid_593717 != nil:
    section.add "DBParameterGroupFamily", valid_593717
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593718: Call_PostDescribeDBEngineVersions_593699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593718.validator(path, query, header, formData, body)
  let scheme = call_593718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593718.url(scheme.get, call_593718.host, call_593718.base,
                         call_593718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593718, url, valid)

proc call*(call_593719: Call_PostDescribeDBEngineVersions_593699;
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
  var query_593720 = newJObject()
  var formData_593721 = newJObject()
  add(formData_593721, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_593721, "MaxRecords", newJInt(MaxRecords))
  add(formData_593721, "EngineVersion", newJString(EngineVersion))
  add(formData_593721, "Marker", newJString(Marker))
  add(formData_593721, "Engine", newJString(Engine))
  add(formData_593721, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_593720, "Action", newJString(Action))
  add(query_593720, "Version", newJString(Version))
  add(formData_593721, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_593719.call(nil, query_593720, nil, formData_593721, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_593699(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_593700, base: "/",
    url: url_PostDescribeDBEngineVersions_593701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_593677 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBEngineVersions_593679(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_593678(path: JsonNode; query: JsonNode;
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
  var valid_593680 = query.getOrDefault("Marker")
  valid_593680 = validateParameter(valid_593680, JString, required = false,
                                 default = nil)
  if valid_593680 != nil:
    section.add "Marker", valid_593680
  var valid_593681 = query.getOrDefault("DBParameterGroupFamily")
  valid_593681 = validateParameter(valid_593681, JString, required = false,
                                 default = nil)
  if valid_593681 != nil:
    section.add "DBParameterGroupFamily", valid_593681
  var valid_593682 = query.getOrDefault("Engine")
  valid_593682 = validateParameter(valid_593682, JString, required = false,
                                 default = nil)
  if valid_593682 != nil:
    section.add "Engine", valid_593682
  var valid_593683 = query.getOrDefault("EngineVersion")
  valid_593683 = validateParameter(valid_593683, JString, required = false,
                                 default = nil)
  if valid_593683 != nil:
    section.add "EngineVersion", valid_593683
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593684 = query.getOrDefault("Action")
  valid_593684 = validateParameter(valid_593684, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_593684 != nil:
    section.add "Action", valid_593684
  var valid_593685 = query.getOrDefault("ListSupportedCharacterSets")
  valid_593685 = validateParameter(valid_593685, JBool, required = false, default = nil)
  if valid_593685 != nil:
    section.add "ListSupportedCharacterSets", valid_593685
  var valid_593686 = query.getOrDefault("Version")
  valid_593686 = validateParameter(valid_593686, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593686 != nil:
    section.add "Version", valid_593686
  var valid_593687 = query.getOrDefault("MaxRecords")
  valid_593687 = validateParameter(valid_593687, JInt, required = false, default = nil)
  if valid_593687 != nil:
    section.add "MaxRecords", valid_593687
  var valid_593688 = query.getOrDefault("DefaultOnly")
  valid_593688 = validateParameter(valid_593688, JBool, required = false, default = nil)
  if valid_593688 != nil:
    section.add "DefaultOnly", valid_593688
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593689 = header.getOrDefault("X-Amz-Signature")
  valid_593689 = validateParameter(valid_593689, JString, required = false,
                                 default = nil)
  if valid_593689 != nil:
    section.add "X-Amz-Signature", valid_593689
  var valid_593690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593690 = validateParameter(valid_593690, JString, required = false,
                                 default = nil)
  if valid_593690 != nil:
    section.add "X-Amz-Content-Sha256", valid_593690
  var valid_593691 = header.getOrDefault("X-Amz-Date")
  valid_593691 = validateParameter(valid_593691, JString, required = false,
                                 default = nil)
  if valid_593691 != nil:
    section.add "X-Amz-Date", valid_593691
  var valid_593692 = header.getOrDefault("X-Amz-Credential")
  valid_593692 = validateParameter(valid_593692, JString, required = false,
                                 default = nil)
  if valid_593692 != nil:
    section.add "X-Amz-Credential", valid_593692
  var valid_593693 = header.getOrDefault("X-Amz-Security-Token")
  valid_593693 = validateParameter(valid_593693, JString, required = false,
                                 default = nil)
  if valid_593693 != nil:
    section.add "X-Amz-Security-Token", valid_593693
  var valid_593694 = header.getOrDefault("X-Amz-Algorithm")
  valid_593694 = validateParameter(valid_593694, JString, required = false,
                                 default = nil)
  if valid_593694 != nil:
    section.add "X-Amz-Algorithm", valid_593694
  var valid_593695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593695 = validateParameter(valid_593695, JString, required = false,
                                 default = nil)
  if valid_593695 != nil:
    section.add "X-Amz-SignedHeaders", valid_593695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593696: Call_GetDescribeDBEngineVersions_593677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593696.validator(path, query, header, formData, body)
  let scheme = call_593696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593696.url(scheme.get, call_593696.host, call_593696.base,
                         call_593696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593696, url, valid)

proc call*(call_593697: Call_GetDescribeDBEngineVersions_593677;
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
  var query_593698 = newJObject()
  add(query_593698, "Marker", newJString(Marker))
  add(query_593698, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_593698, "Engine", newJString(Engine))
  add(query_593698, "EngineVersion", newJString(EngineVersion))
  add(query_593698, "Action", newJString(Action))
  add(query_593698, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_593698, "Version", newJString(Version))
  add(query_593698, "MaxRecords", newJInt(MaxRecords))
  add(query_593698, "DefaultOnly", newJBool(DefaultOnly))
  result = call_593697.call(nil, query_593698, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_593677(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_593678, base: "/",
    url: url_GetDescribeDBEngineVersions_593679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_593740 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBInstances_593742(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_593741(path: JsonNode; query: JsonNode;
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
  var valid_593743 = query.getOrDefault("Action")
  valid_593743 = validateParameter(valid_593743, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_593743 != nil:
    section.add "Action", valid_593743
  var valid_593744 = query.getOrDefault("Version")
  valid_593744 = validateParameter(valid_593744, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593744 != nil:
    section.add "Version", valid_593744
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593745 = header.getOrDefault("X-Amz-Signature")
  valid_593745 = validateParameter(valid_593745, JString, required = false,
                                 default = nil)
  if valid_593745 != nil:
    section.add "X-Amz-Signature", valid_593745
  var valid_593746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593746 = validateParameter(valid_593746, JString, required = false,
                                 default = nil)
  if valid_593746 != nil:
    section.add "X-Amz-Content-Sha256", valid_593746
  var valid_593747 = header.getOrDefault("X-Amz-Date")
  valid_593747 = validateParameter(valid_593747, JString, required = false,
                                 default = nil)
  if valid_593747 != nil:
    section.add "X-Amz-Date", valid_593747
  var valid_593748 = header.getOrDefault("X-Amz-Credential")
  valid_593748 = validateParameter(valid_593748, JString, required = false,
                                 default = nil)
  if valid_593748 != nil:
    section.add "X-Amz-Credential", valid_593748
  var valid_593749 = header.getOrDefault("X-Amz-Security-Token")
  valid_593749 = validateParameter(valid_593749, JString, required = false,
                                 default = nil)
  if valid_593749 != nil:
    section.add "X-Amz-Security-Token", valid_593749
  var valid_593750 = header.getOrDefault("X-Amz-Algorithm")
  valid_593750 = validateParameter(valid_593750, JString, required = false,
                                 default = nil)
  if valid_593750 != nil:
    section.add "X-Amz-Algorithm", valid_593750
  var valid_593751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593751 = validateParameter(valid_593751, JString, required = false,
                                 default = nil)
  if valid_593751 != nil:
    section.add "X-Amz-SignedHeaders", valid_593751
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  section = newJObject()
  var valid_593752 = formData.getOrDefault("MaxRecords")
  valid_593752 = validateParameter(valid_593752, JInt, required = false, default = nil)
  if valid_593752 != nil:
    section.add "MaxRecords", valid_593752
  var valid_593753 = formData.getOrDefault("Marker")
  valid_593753 = validateParameter(valid_593753, JString, required = false,
                                 default = nil)
  if valid_593753 != nil:
    section.add "Marker", valid_593753
  var valid_593754 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593754 = validateParameter(valid_593754, JString, required = false,
                                 default = nil)
  if valid_593754 != nil:
    section.add "DBInstanceIdentifier", valid_593754
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593755: Call_PostDescribeDBInstances_593740; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593755.validator(path, query, header, formData, body)
  let scheme = call_593755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593755.url(scheme.get, call_593755.host, call_593755.base,
                         call_593755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593755, url, valid)

proc call*(call_593756: Call_PostDescribeDBInstances_593740; MaxRecords: int = 0;
          Marker: string = ""; DBInstanceIdentifier: string = "";
          Action: string = "DescribeDBInstances"; Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBInstances
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593757 = newJObject()
  var formData_593758 = newJObject()
  add(formData_593758, "MaxRecords", newJInt(MaxRecords))
  add(formData_593758, "Marker", newJString(Marker))
  add(formData_593758, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593757, "Action", newJString(Action))
  add(query_593757, "Version", newJString(Version))
  result = call_593756.call(nil, query_593757, nil, formData_593758, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_593740(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_593741, base: "/",
    url: url_PostDescribeDBInstances_593742, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_593722 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBInstances_593724(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_593723(path: JsonNode; query: JsonNode;
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
  var valid_593725 = query.getOrDefault("Marker")
  valid_593725 = validateParameter(valid_593725, JString, required = false,
                                 default = nil)
  if valid_593725 != nil:
    section.add "Marker", valid_593725
  var valid_593726 = query.getOrDefault("DBInstanceIdentifier")
  valid_593726 = validateParameter(valid_593726, JString, required = false,
                                 default = nil)
  if valid_593726 != nil:
    section.add "DBInstanceIdentifier", valid_593726
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593727 = query.getOrDefault("Action")
  valid_593727 = validateParameter(valid_593727, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_593727 != nil:
    section.add "Action", valid_593727
  var valid_593728 = query.getOrDefault("Version")
  valid_593728 = validateParameter(valid_593728, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593728 != nil:
    section.add "Version", valid_593728
  var valid_593729 = query.getOrDefault("MaxRecords")
  valid_593729 = validateParameter(valid_593729, JInt, required = false, default = nil)
  if valid_593729 != nil:
    section.add "MaxRecords", valid_593729
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593730 = header.getOrDefault("X-Amz-Signature")
  valid_593730 = validateParameter(valid_593730, JString, required = false,
                                 default = nil)
  if valid_593730 != nil:
    section.add "X-Amz-Signature", valid_593730
  var valid_593731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593731 = validateParameter(valid_593731, JString, required = false,
                                 default = nil)
  if valid_593731 != nil:
    section.add "X-Amz-Content-Sha256", valid_593731
  var valid_593732 = header.getOrDefault("X-Amz-Date")
  valid_593732 = validateParameter(valid_593732, JString, required = false,
                                 default = nil)
  if valid_593732 != nil:
    section.add "X-Amz-Date", valid_593732
  var valid_593733 = header.getOrDefault("X-Amz-Credential")
  valid_593733 = validateParameter(valid_593733, JString, required = false,
                                 default = nil)
  if valid_593733 != nil:
    section.add "X-Amz-Credential", valid_593733
  var valid_593734 = header.getOrDefault("X-Amz-Security-Token")
  valid_593734 = validateParameter(valid_593734, JString, required = false,
                                 default = nil)
  if valid_593734 != nil:
    section.add "X-Amz-Security-Token", valid_593734
  var valid_593735 = header.getOrDefault("X-Amz-Algorithm")
  valid_593735 = validateParameter(valid_593735, JString, required = false,
                                 default = nil)
  if valid_593735 != nil:
    section.add "X-Amz-Algorithm", valid_593735
  var valid_593736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593736 = validateParameter(valid_593736, JString, required = false,
                                 default = nil)
  if valid_593736 != nil:
    section.add "X-Amz-SignedHeaders", valid_593736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593737: Call_GetDescribeDBInstances_593722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593737.validator(path, query, header, formData, body)
  let scheme = call_593737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593737.url(scheme.get, call_593737.host, call_593737.base,
                         call_593737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593737, url, valid)

proc call*(call_593738: Call_GetDescribeDBInstances_593722; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_593739 = newJObject()
  add(query_593739, "Marker", newJString(Marker))
  add(query_593739, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593739, "Action", newJString(Action))
  add(query_593739, "Version", newJString(Version))
  add(query_593739, "MaxRecords", newJInt(MaxRecords))
  result = call_593738.call(nil, query_593739, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_593722(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_593723, base: "/",
    url: url_GetDescribeDBInstances_593724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_593780 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBLogFiles_593782(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBLogFiles_593781(path: JsonNode; query: JsonNode;
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
  var valid_593783 = query.getOrDefault("Action")
  valid_593783 = validateParameter(valid_593783, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_593783 != nil:
    section.add "Action", valid_593783
  var valid_593784 = query.getOrDefault("Version")
  valid_593784 = validateParameter(valid_593784, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593784 != nil:
    section.add "Version", valid_593784
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593785 = header.getOrDefault("X-Amz-Signature")
  valid_593785 = validateParameter(valid_593785, JString, required = false,
                                 default = nil)
  if valid_593785 != nil:
    section.add "X-Amz-Signature", valid_593785
  var valid_593786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593786 = validateParameter(valid_593786, JString, required = false,
                                 default = nil)
  if valid_593786 != nil:
    section.add "X-Amz-Content-Sha256", valid_593786
  var valid_593787 = header.getOrDefault("X-Amz-Date")
  valid_593787 = validateParameter(valid_593787, JString, required = false,
                                 default = nil)
  if valid_593787 != nil:
    section.add "X-Amz-Date", valid_593787
  var valid_593788 = header.getOrDefault("X-Amz-Credential")
  valid_593788 = validateParameter(valid_593788, JString, required = false,
                                 default = nil)
  if valid_593788 != nil:
    section.add "X-Amz-Credential", valid_593788
  var valid_593789 = header.getOrDefault("X-Amz-Security-Token")
  valid_593789 = validateParameter(valid_593789, JString, required = false,
                                 default = nil)
  if valid_593789 != nil:
    section.add "X-Amz-Security-Token", valid_593789
  var valid_593790 = header.getOrDefault("X-Amz-Algorithm")
  valid_593790 = validateParameter(valid_593790, JString, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "X-Amz-Algorithm", valid_593790
  var valid_593791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593791 = validateParameter(valid_593791, JString, required = false,
                                 default = nil)
  if valid_593791 != nil:
    section.add "X-Amz-SignedHeaders", valid_593791
  result.add "header", section
  ## parameters in `formData` object:
  ##   FileSize: JInt
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FilenameContains: JString
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_593792 = formData.getOrDefault("FileSize")
  valid_593792 = validateParameter(valid_593792, JInt, required = false, default = nil)
  if valid_593792 != nil:
    section.add "FileSize", valid_593792
  var valid_593793 = formData.getOrDefault("MaxRecords")
  valid_593793 = validateParameter(valid_593793, JInt, required = false, default = nil)
  if valid_593793 != nil:
    section.add "MaxRecords", valid_593793
  var valid_593794 = formData.getOrDefault("Marker")
  valid_593794 = validateParameter(valid_593794, JString, required = false,
                                 default = nil)
  if valid_593794 != nil:
    section.add "Marker", valid_593794
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593795 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593795 = validateParameter(valid_593795, JString, required = true,
                                 default = nil)
  if valid_593795 != nil:
    section.add "DBInstanceIdentifier", valid_593795
  var valid_593796 = formData.getOrDefault("FilenameContains")
  valid_593796 = validateParameter(valid_593796, JString, required = false,
                                 default = nil)
  if valid_593796 != nil:
    section.add "FilenameContains", valid_593796
  var valid_593797 = formData.getOrDefault("FileLastWritten")
  valid_593797 = validateParameter(valid_593797, JInt, required = false, default = nil)
  if valid_593797 != nil:
    section.add "FileLastWritten", valid_593797
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593798: Call_PostDescribeDBLogFiles_593780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593798.validator(path, query, header, formData, body)
  let scheme = call_593798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593798.url(scheme.get, call_593798.host, call_593798.base,
                         call_593798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593798, url, valid)

proc call*(call_593799: Call_PostDescribeDBLogFiles_593780;
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
  var query_593800 = newJObject()
  var formData_593801 = newJObject()
  add(formData_593801, "FileSize", newJInt(FileSize))
  add(formData_593801, "MaxRecords", newJInt(MaxRecords))
  add(formData_593801, "Marker", newJString(Marker))
  add(formData_593801, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593801, "FilenameContains", newJString(FilenameContains))
  add(query_593800, "Action", newJString(Action))
  add(query_593800, "Version", newJString(Version))
  add(formData_593801, "FileLastWritten", newJInt(FileLastWritten))
  result = call_593799.call(nil, query_593800, nil, formData_593801, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_593780(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_593781, base: "/",
    url: url_PostDescribeDBLogFiles_593782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_593759 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBLogFiles_593761(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBLogFiles_593760(path: JsonNode; query: JsonNode;
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
  var valid_593762 = query.getOrDefault("Marker")
  valid_593762 = validateParameter(valid_593762, JString, required = false,
                                 default = nil)
  if valid_593762 != nil:
    section.add "Marker", valid_593762
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593763 = query.getOrDefault("DBInstanceIdentifier")
  valid_593763 = validateParameter(valid_593763, JString, required = true,
                                 default = nil)
  if valid_593763 != nil:
    section.add "DBInstanceIdentifier", valid_593763
  var valid_593764 = query.getOrDefault("FileLastWritten")
  valid_593764 = validateParameter(valid_593764, JInt, required = false, default = nil)
  if valid_593764 != nil:
    section.add "FileLastWritten", valid_593764
  var valid_593765 = query.getOrDefault("Action")
  valid_593765 = validateParameter(valid_593765, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_593765 != nil:
    section.add "Action", valid_593765
  var valid_593766 = query.getOrDefault("FilenameContains")
  valid_593766 = validateParameter(valid_593766, JString, required = false,
                                 default = nil)
  if valid_593766 != nil:
    section.add "FilenameContains", valid_593766
  var valid_593767 = query.getOrDefault("Version")
  valid_593767 = validateParameter(valid_593767, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593767 != nil:
    section.add "Version", valid_593767
  var valid_593768 = query.getOrDefault("MaxRecords")
  valid_593768 = validateParameter(valid_593768, JInt, required = false, default = nil)
  if valid_593768 != nil:
    section.add "MaxRecords", valid_593768
  var valid_593769 = query.getOrDefault("FileSize")
  valid_593769 = validateParameter(valid_593769, JInt, required = false, default = nil)
  if valid_593769 != nil:
    section.add "FileSize", valid_593769
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593770 = header.getOrDefault("X-Amz-Signature")
  valid_593770 = validateParameter(valid_593770, JString, required = false,
                                 default = nil)
  if valid_593770 != nil:
    section.add "X-Amz-Signature", valid_593770
  var valid_593771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593771 = validateParameter(valid_593771, JString, required = false,
                                 default = nil)
  if valid_593771 != nil:
    section.add "X-Amz-Content-Sha256", valid_593771
  var valid_593772 = header.getOrDefault("X-Amz-Date")
  valid_593772 = validateParameter(valid_593772, JString, required = false,
                                 default = nil)
  if valid_593772 != nil:
    section.add "X-Amz-Date", valid_593772
  var valid_593773 = header.getOrDefault("X-Amz-Credential")
  valid_593773 = validateParameter(valid_593773, JString, required = false,
                                 default = nil)
  if valid_593773 != nil:
    section.add "X-Amz-Credential", valid_593773
  var valid_593774 = header.getOrDefault("X-Amz-Security-Token")
  valid_593774 = validateParameter(valid_593774, JString, required = false,
                                 default = nil)
  if valid_593774 != nil:
    section.add "X-Amz-Security-Token", valid_593774
  var valid_593775 = header.getOrDefault("X-Amz-Algorithm")
  valid_593775 = validateParameter(valid_593775, JString, required = false,
                                 default = nil)
  if valid_593775 != nil:
    section.add "X-Amz-Algorithm", valid_593775
  var valid_593776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593776 = validateParameter(valid_593776, JString, required = false,
                                 default = nil)
  if valid_593776 != nil:
    section.add "X-Amz-SignedHeaders", valid_593776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593777: Call_GetDescribeDBLogFiles_593759; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593777.validator(path, query, header, formData, body)
  let scheme = call_593777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593777.url(scheme.get, call_593777.host, call_593777.base,
                         call_593777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593777, url, valid)

proc call*(call_593778: Call_GetDescribeDBLogFiles_593759;
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
  var query_593779 = newJObject()
  add(query_593779, "Marker", newJString(Marker))
  add(query_593779, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593779, "FileLastWritten", newJInt(FileLastWritten))
  add(query_593779, "Action", newJString(Action))
  add(query_593779, "FilenameContains", newJString(FilenameContains))
  add(query_593779, "Version", newJString(Version))
  add(query_593779, "MaxRecords", newJInt(MaxRecords))
  add(query_593779, "FileSize", newJInt(FileSize))
  result = call_593778.call(nil, query_593779, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_593759(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_593760, base: "/",
    url: url_GetDescribeDBLogFiles_593761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_593820 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBParameterGroups_593822(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_593821(path: JsonNode; query: JsonNode;
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
  var valid_593823 = query.getOrDefault("Action")
  valid_593823 = validateParameter(valid_593823, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_593823 != nil:
    section.add "Action", valid_593823
  var valid_593824 = query.getOrDefault("Version")
  valid_593824 = validateParameter(valid_593824, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593824 != nil:
    section.add "Version", valid_593824
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593825 = header.getOrDefault("X-Amz-Signature")
  valid_593825 = validateParameter(valid_593825, JString, required = false,
                                 default = nil)
  if valid_593825 != nil:
    section.add "X-Amz-Signature", valid_593825
  var valid_593826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593826 = validateParameter(valid_593826, JString, required = false,
                                 default = nil)
  if valid_593826 != nil:
    section.add "X-Amz-Content-Sha256", valid_593826
  var valid_593827 = header.getOrDefault("X-Amz-Date")
  valid_593827 = validateParameter(valid_593827, JString, required = false,
                                 default = nil)
  if valid_593827 != nil:
    section.add "X-Amz-Date", valid_593827
  var valid_593828 = header.getOrDefault("X-Amz-Credential")
  valid_593828 = validateParameter(valid_593828, JString, required = false,
                                 default = nil)
  if valid_593828 != nil:
    section.add "X-Amz-Credential", valid_593828
  var valid_593829 = header.getOrDefault("X-Amz-Security-Token")
  valid_593829 = validateParameter(valid_593829, JString, required = false,
                                 default = nil)
  if valid_593829 != nil:
    section.add "X-Amz-Security-Token", valid_593829
  var valid_593830 = header.getOrDefault("X-Amz-Algorithm")
  valid_593830 = validateParameter(valid_593830, JString, required = false,
                                 default = nil)
  if valid_593830 != nil:
    section.add "X-Amz-Algorithm", valid_593830
  var valid_593831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593831 = validateParameter(valid_593831, JString, required = false,
                                 default = nil)
  if valid_593831 != nil:
    section.add "X-Amz-SignedHeaders", valid_593831
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  section = newJObject()
  var valid_593832 = formData.getOrDefault("MaxRecords")
  valid_593832 = validateParameter(valid_593832, JInt, required = false, default = nil)
  if valid_593832 != nil:
    section.add "MaxRecords", valid_593832
  var valid_593833 = formData.getOrDefault("DBParameterGroupName")
  valid_593833 = validateParameter(valid_593833, JString, required = false,
                                 default = nil)
  if valid_593833 != nil:
    section.add "DBParameterGroupName", valid_593833
  var valid_593834 = formData.getOrDefault("Marker")
  valid_593834 = validateParameter(valid_593834, JString, required = false,
                                 default = nil)
  if valid_593834 != nil:
    section.add "Marker", valid_593834
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593835: Call_PostDescribeDBParameterGroups_593820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593835.validator(path, query, header, formData, body)
  let scheme = call_593835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593835.url(scheme.get, call_593835.host, call_593835.base,
                         call_593835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593835, url, valid)

proc call*(call_593836: Call_PostDescribeDBParameterGroups_593820;
          MaxRecords: int = 0; DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593837 = newJObject()
  var formData_593838 = newJObject()
  add(formData_593838, "MaxRecords", newJInt(MaxRecords))
  add(formData_593838, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_593838, "Marker", newJString(Marker))
  add(query_593837, "Action", newJString(Action))
  add(query_593837, "Version", newJString(Version))
  result = call_593836.call(nil, query_593837, nil, formData_593838, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_593820(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_593821, base: "/",
    url: url_PostDescribeDBParameterGroups_593822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_593802 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBParameterGroups_593804(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_593803(path: JsonNode; query: JsonNode;
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
  var valid_593805 = query.getOrDefault("Marker")
  valid_593805 = validateParameter(valid_593805, JString, required = false,
                                 default = nil)
  if valid_593805 != nil:
    section.add "Marker", valid_593805
  var valid_593806 = query.getOrDefault("DBParameterGroupName")
  valid_593806 = validateParameter(valid_593806, JString, required = false,
                                 default = nil)
  if valid_593806 != nil:
    section.add "DBParameterGroupName", valid_593806
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593807 = query.getOrDefault("Action")
  valid_593807 = validateParameter(valid_593807, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_593807 != nil:
    section.add "Action", valid_593807
  var valid_593808 = query.getOrDefault("Version")
  valid_593808 = validateParameter(valid_593808, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593808 != nil:
    section.add "Version", valid_593808
  var valid_593809 = query.getOrDefault("MaxRecords")
  valid_593809 = validateParameter(valid_593809, JInt, required = false, default = nil)
  if valid_593809 != nil:
    section.add "MaxRecords", valid_593809
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593810 = header.getOrDefault("X-Amz-Signature")
  valid_593810 = validateParameter(valid_593810, JString, required = false,
                                 default = nil)
  if valid_593810 != nil:
    section.add "X-Amz-Signature", valid_593810
  var valid_593811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593811 = validateParameter(valid_593811, JString, required = false,
                                 default = nil)
  if valid_593811 != nil:
    section.add "X-Amz-Content-Sha256", valid_593811
  var valid_593812 = header.getOrDefault("X-Amz-Date")
  valid_593812 = validateParameter(valid_593812, JString, required = false,
                                 default = nil)
  if valid_593812 != nil:
    section.add "X-Amz-Date", valid_593812
  var valid_593813 = header.getOrDefault("X-Amz-Credential")
  valid_593813 = validateParameter(valid_593813, JString, required = false,
                                 default = nil)
  if valid_593813 != nil:
    section.add "X-Amz-Credential", valid_593813
  var valid_593814 = header.getOrDefault("X-Amz-Security-Token")
  valid_593814 = validateParameter(valid_593814, JString, required = false,
                                 default = nil)
  if valid_593814 != nil:
    section.add "X-Amz-Security-Token", valid_593814
  var valid_593815 = header.getOrDefault("X-Amz-Algorithm")
  valid_593815 = validateParameter(valid_593815, JString, required = false,
                                 default = nil)
  if valid_593815 != nil:
    section.add "X-Amz-Algorithm", valid_593815
  var valid_593816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593816 = validateParameter(valid_593816, JString, required = false,
                                 default = nil)
  if valid_593816 != nil:
    section.add "X-Amz-SignedHeaders", valid_593816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593817: Call_GetDescribeDBParameterGroups_593802; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593817.validator(path, query, header, formData, body)
  let scheme = call_593817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593817.url(scheme.get, call_593817.host, call_593817.base,
                         call_593817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593817, url, valid)

proc call*(call_593818: Call_GetDescribeDBParameterGroups_593802;
          Marker: string = ""; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameterGroups
  ##   Marker: string
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_593819 = newJObject()
  add(query_593819, "Marker", newJString(Marker))
  add(query_593819, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593819, "Action", newJString(Action))
  add(query_593819, "Version", newJString(Version))
  add(query_593819, "MaxRecords", newJInt(MaxRecords))
  result = call_593818.call(nil, query_593819, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_593802(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_593803, base: "/",
    url: url_GetDescribeDBParameterGroups_593804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_593858 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBParameters_593860(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_593859(path: JsonNode; query: JsonNode;
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
  var valid_593861 = query.getOrDefault("Action")
  valid_593861 = validateParameter(valid_593861, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_593861 != nil:
    section.add "Action", valid_593861
  var valid_593862 = query.getOrDefault("Version")
  valid_593862 = validateParameter(valid_593862, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593862 != nil:
    section.add "Version", valid_593862
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593863 = header.getOrDefault("X-Amz-Signature")
  valid_593863 = validateParameter(valid_593863, JString, required = false,
                                 default = nil)
  if valid_593863 != nil:
    section.add "X-Amz-Signature", valid_593863
  var valid_593864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593864 = validateParameter(valid_593864, JString, required = false,
                                 default = nil)
  if valid_593864 != nil:
    section.add "X-Amz-Content-Sha256", valid_593864
  var valid_593865 = header.getOrDefault("X-Amz-Date")
  valid_593865 = validateParameter(valid_593865, JString, required = false,
                                 default = nil)
  if valid_593865 != nil:
    section.add "X-Amz-Date", valid_593865
  var valid_593866 = header.getOrDefault("X-Amz-Credential")
  valid_593866 = validateParameter(valid_593866, JString, required = false,
                                 default = nil)
  if valid_593866 != nil:
    section.add "X-Amz-Credential", valid_593866
  var valid_593867 = header.getOrDefault("X-Amz-Security-Token")
  valid_593867 = validateParameter(valid_593867, JString, required = false,
                                 default = nil)
  if valid_593867 != nil:
    section.add "X-Amz-Security-Token", valid_593867
  var valid_593868 = header.getOrDefault("X-Amz-Algorithm")
  valid_593868 = validateParameter(valid_593868, JString, required = false,
                                 default = nil)
  if valid_593868 != nil:
    section.add "X-Amz-Algorithm", valid_593868
  var valid_593869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593869 = validateParameter(valid_593869, JString, required = false,
                                 default = nil)
  if valid_593869 != nil:
    section.add "X-Amz-SignedHeaders", valid_593869
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  section = newJObject()
  var valid_593870 = formData.getOrDefault("Source")
  valid_593870 = validateParameter(valid_593870, JString, required = false,
                                 default = nil)
  if valid_593870 != nil:
    section.add "Source", valid_593870
  var valid_593871 = formData.getOrDefault("MaxRecords")
  valid_593871 = validateParameter(valid_593871, JInt, required = false, default = nil)
  if valid_593871 != nil:
    section.add "MaxRecords", valid_593871
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_593872 = formData.getOrDefault("DBParameterGroupName")
  valid_593872 = validateParameter(valid_593872, JString, required = true,
                                 default = nil)
  if valid_593872 != nil:
    section.add "DBParameterGroupName", valid_593872
  var valid_593873 = formData.getOrDefault("Marker")
  valid_593873 = validateParameter(valid_593873, JString, required = false,
                                 default = nil)
  if valid_593873 != nil:
    section.add "Marker", valid_593873
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593874: Call_PostDescribeDBParameters_593858; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593874.validator(path, query, header, formData, body)
  let scheme = call_593874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593874.url(scheme.get, call_593874.host, call_593874.base,
                         call_593874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593874, url, valid)

proc call*(call_593875: Call_PostDescribeDBParameters_593858;
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
  var query_593876 = newJObject()
  var formData_593877 = newJObject()
  add(formData_593877, "Source", newJString(Source))
  add(formData_593877, "MaxRecords", newJInt(MaxRecords))
  add(formData_593877, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_593877, "Marker", newJString(Marker))
  add(query_593876, "Action", newJString(Action))
  add(query_593876, "Version", newJString(Version))
  result = call_593875.call(nil, query_593876, nil, formData_593877, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_593858(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_593859, base: "/",
    url: url_PostDescribeDBParameters_593860, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_593839 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBParameters_593841(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_593840(path: JsonNode; query: JsonNode;
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
  var valid_593842 = query.getOrDefault("Marker")
  valid_593842 = validateParameter(valid_593842, JString, required = false,
                                 default = nil)
  if valid_593842 != nil:
    section.add "Marker", valid_593842
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_593843 = query.getOrDefault("DBParameterGroupName")
  valid_593843 = validateParameter(valid_593843, JString, required = true,
                                 default = nil)
  if valid_593843 != nil:
    section.add "DBParameterGroupName", valid_593843
  var valid_593844 = query.getOrDefault("Source")
  valid_593844 = validateParameter(valid_593844, JString, required = false,
                                 default = nil)
  if valid_593844 != nil:
    section.add "Source", valid_593844
  var valid_593845 = query.getOrDefault("Action")
  valid_593845 = validateParameter(valid_593845, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_593845 != nil:
    section.add "Action", valid_593845
  var valid_593846 = query.getOrDefault("Version")
  valid_593846 = validateParameter(valid_593846, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593846 != nil:
    section.add "Version", valid_593846
  var valid_593847 = query.getOrDefault("MaxRecords")
  valid_593847 = validateParameter(valid_593847, JInt, required = false, default = nil)
  if valid_593847 != nil:
    section.add "MaxRecords", valid_593847
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593848 = header.getOrDefault("X-Amz-Signature")
  valid_593848 = validateParameter(valid_593848, JString, required = false,
                                 default = nil)
  if valid_593848 != nil:
    section.add "X-Amz-Signature", valid_593848
  var valid_593849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593849 = validateParameter(valid_593849, JString, required = false,
                                 default = nil)
  if valid_593849 != nil:
    section.add "X-Amz-Content-Sha256", valid_593849
  var valid_593850 = header.getOrDefault("X-Amz-Date")
  valid_593850 = validateParameter(valid_593850, JString, required = false,
                                 default = nil)
  if valid_593850 != nil:
    section.add "X-Amz-Date", valid_593850
  var valid_593851 = header.getOrDefault("X-Amz-Credential")
  valid_593851 = validateParameter(valid_593851, JString, required = false,
                                 default = nil)
  if valid_593851 != nil:
    section.add "X-Amz-Credential", valid_593851
  var valid_593852 = header.getOrDefault("X-Amz-Security-Token")
  valid_593852 = validateParameter(valid_593852, JString, required = false,
                                 default = nil)
  if valid_593852 != nil:
    section.add "X-Amz-Security-Token", valid_593852
  var valid_593853 = header.getOrDefault("X-Amz-Algorithm")
  valid_593853 = validateParameter(valid_593853, JString, required = false,
                                 default = nil)
  if valid_593853 != nil:
    section.add "X-Amz-Algorithm", valid_593853
  var valid_593854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593854 = validateParameter(valid_593854, JString, required = false,
                                 default = nil)
  if valid_593854 != nil:
    section.add "X-Amz-SignedHeaders", valid_593854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593855: Call_GetDescribeDBParameters_593839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593855.validator(path, query, header, formData, body)
  let scheme = call_593855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593855.url(scheme.get, call_593855.host, call_593855.base,
                         call_593855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593855, url, valid)

proc call*(call_593856: Call_GetDescribeDBParameters_593839;
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
  var query_593857 = newJObject()
  add(query_593857, "Marker", newJString(Marker))
  add(query_593857, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593857, "Source", newJString(Source))
  add(query_593857, "Action", newJString(Action))
  add(query_593857, "Version", newJString(Version))
  add(query_593857, "MaxRecords", newJInt(MaxRecords))
  result = call_593856.call(nil, query_593857, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_593839(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_593840, base: "/",
    url: url_GetDescribeDBParameters_593841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_593896 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBSecurityGroups_593898(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_593897(path: JsonNode; query: JsonNode;
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
  var valid_593899 = query.getOrDefault("Action")
  valid_593899 = validateParameter(valid_593899, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_593899 != nil:
    section.add "Action", valid_593899
  var valid_593900 = query.getOrDefault("Version")
  valid_593900 = validateParameter(valid_593900, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593900 != nil:
    section.add "Version", valid_593900
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593901 = header.getOrDefault("X-Amz-Signature")
  valid_593901 = validateParameter(valid_593901, JString, required = false,
                                 default = nil)
  if valid_593901 != nil:
    section.add "X-Amz-Signature", valid_593901
  var valid_593902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593902 = validateParameter(valid_593902, JString, required = false,
                                 default = nil)
  if valid_593902 != nil:
    section.add "X-Amz-Content-Sha256", valid_593902
  var valid_593903 = header.getOrDefault("X-Amz-Date")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "X-Amz-Date", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Credential")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Credential", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Security-Token")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Security-Token", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Algorithm")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Algorithm", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-SignedHeaders", valid_593907
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  section = newJObject()
  var valid_593908 = formData.getOrDefault("DBSecurityGroupName")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "DBSecurityGroupName", valid_593908
  var valid_593909 = formData.getOrDefault("MaxRecords")
  valid_593909 = validateParameter(valid_593909, JInt, required = false, default = nil)
  if valid_593909 != nil:
    section.add "MaxRecords", valid_593909
  var valid_593910 = formData.getOrDefault("Marker")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "Marker", valid_593910
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593911: Call_PostDescribeDBSecurityGroups_593896; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593911.validator(path, query, header, formData, body)
  let scheme = call_593911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593911.url(scheme.get, call_593911.host, call_593911.base,
                         call_593911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593911, url, valid)

proc call*(call_593912: Call_PostDescribeDBSecurityGroups_593896;
          DBSecurityGroupName: string = ""; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593913 = newJObject()
  var formData_593914 = newJObject()
  add(formData_593914, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_593914, "MaxRecords", newJInt(MaxRecords))
  add(formData_593914, "Marker", newJString(Marker))
  add(query_593913, "Action", newJString(Action))
  add(query_593913, "Version", newJString(Version))
  result = call_593912.call(nil, query_593913, nil, formData_593914, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_593896(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_593897, base: "/",
    url: url_PostDescribeDBSecurityGroups_593898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_593878 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBSecurityGroups_593880(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_593879(path: JsonNode; query: JsonNode;
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
  var valid_593881 = query.getOrDefault("Marker")
  valid_593881 = validateParameter(valid_593881, JString, required = false,
                                 default = nil)
  if valid_593881 != nil:
    section.add "Marker", valid_593881
  var valid_593882 = query.getOrDefault("DBSecurityGroupName")
  valid_593882 = validateParameter(valid_593882, JString, required = false,
                                 default = nil)
  if valid_593882 != nil:
    section.add "DBSecurityGroupName", valid_593882
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593883 = query.getOrDefault("Action")
  valid_593883 = validateParameter(valid_593883, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_593883 != nil:
    section.add "Action", valid_593883
  var valid_593884 = query.getOrDefault("Version")
  valid_593884 = validateParameter(valid_593884, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593884 != nil:
    section.add "Version", valid_593884
  var valid_593885 = query.getOrDefault("MaxRecords")
  valid_593885 = validateParameter(valid_593885, JInt, required = false, default = nil)
  if valid_593885 != nil:
    section.add "MaxRecords", valid_593885
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593886 = header.getOrDefault("X-Amz-Signature")
  valid_593886 = validateParameter(valid_593886, JString, required = false,
                                 default = nil)
  if valid_593886 != nil:
    section.add "X-Amz-Signature", valid_593886
  var valid_593887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593887 = validateParameter(valid_593887, JString, required = false,
                                 default = nil)
  if valid_593887 != nil:
    section.add "X-Amz-Content-Sha256", valid_593887
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Credential")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Credential", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Security-Token")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Security-Token", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Algorithm")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Algorithm", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-SignedHeaders", valid_593892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593893: Call_GetDescribeDBSecurityGroups_593878; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593893.validator(path, query, header, formData, body)
  let scheme = call_593893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593893.url(scheme.get, call_593893.host, call_593893.base,
                         call_593893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593893, url, valid)

proc call*(call_593894: Call_GetDescribeDBSecurityGroups_593878;
          Marker: string = ""; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Marker: string
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_593895 = newJObject()
  add(query_593895, "Marker", newJString(Marker))
  add(query_593895, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593895, "Action", newJString(Action))
  add(query_593895, "Version", newJString(Version))
  add(query_593895, "MaxRecords", newJInt(MaxRecords))
  result = call_593894.call(nil, query_593895, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_593878(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_593879, base: "/",
    url: url_GetDescribeDBSecurityGroups_593880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_593935 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBSnapshots_593937(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSnapshots_593936(path: JsonNode; query: JsonNode;
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
  var valid_593938 = query.getOrDefault("Action")
  valid_593938 = validateParameter(valid_593938, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_593938 != nil:
    section.add "Action", valid_593938
  var valid_593939 = query.getOrDefault("Version")
  valid_593939 = validateParameter(valid_593939, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593939 != nil:
    section.add "Version", valid_593939
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593940 = header.getOrDefault("X-Amz-Signature")
  valid_593940 = validateParameter(valid_593940, JString, required = false,
                                 default = nil)
  if valid_593940 != nil:
    section.add "X-Amz-Signature", valid_593940
  var valid_593941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593941 = validateParameter(valid_593941, JString, required = false,
                                 default = nil)
  if valid_593941 != nil:
    section.add "X-Amz-Content-Sha256", valid_593941
  var valid_593942 = header.getOrDefault("X-Amz-Date")
  valid_593942 = validateParameter(valid_593942, JString, required = false,
                                 default = nil)
  if valid_593942 != nil:
    section.add "X-Amz-Date", valid_593942
  var valid_593943 = header.getOrDefault("X-Amz-Credential")
  valid_593943 = validateParameter(valid_593943, JString, required = false,
                                 default = nil)
  if valid_593943 != nil:
    section.add "X-Amz-Credential", valid_593943
  var valid_593944 = header.getOrDefault("X-Amz-Security-Token")
  valid_593944 = validateParameter(valid_593944, JString, required = false,
                                 default = nil)
  if valid_593944 != nil:
    section.add "X-Amz-Security-Token", valid_593944
  var valid_593945 = header.getOrDefault("X-Amz-Algorithm")
  valid_593945 = validateParameter(valid_593945, JString, required = false,
                                 default = nil)
  if valid_593945 != nil:
    section.add "X-Amz-Algorithm", valid_593945
  var valid_593946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593946 = validateParameter(valid_593946, JString, required = false,
                                 default = nil)
  if valid_593946 != nil:
    section.add "X-Amz-SignedHeaders", valid_593946
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  section = newJObject()
  var valid_593947 = formData.getOrDefault("SnapshotType")
  valid_593947 = validateParameter(valid_593947, JString, required = false,
                                 default = nil)
  if valid_593947 != nil:
    section.add "SnapshotType", valid_593947
  var valid_593948 = formData.getOrDefault("MaxRecords")
  valid_593948 = validateParameter(valid_593948, JInt, required = false, default = nil)
  if valid_593948 != nil:
    section.add "MaxRecords", valid_593948
  var valid_593949 = formData.getOrDefault("Marker")
  valid_593949 = validateParameter(valid_593949, JString, required = false,
                                 default = nil)
  if valid_593949 != nil:
    section.add "Marker", valid_593949
  var valid_593950 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593950 = validateParameter(valid_593950, JString, required = false,
                                 default = nil)
  if valid_593950 != nil:
    section.add "DBInstanceIdentifier", valid_593950
  var valid_593951 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_593951 = validateParameter(valid_593951, JString, required = false,
                                 default = nil)
  if valid_593951 != nil:
    section.add "DBSnapshotIdentifier", valid_593951
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593952: Call_PostDescribeDBSnapshots_593935; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593952.validator(path, query, header, formData, body)
  let scheme = call_593952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593952.url(scheme.get, call_593952.host, call_593952.base,
                         call_593952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593952, url, valid)

proc call*(call_593953: Call_PostDescribeDBSnapshots_593935;
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
  var query_593954 = newJObject()
  var formData_593955 = newJObject()
  add(formData_593955, "SnapshotType", newJString(SnapshotType))
  add(formData_593955, "MaxRecords", newJInt(MaxRecords))
  add(formData_593955, "Marker", newJString(Marker))
  add(formData_593955, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593955, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593954, "Action", newJString(Action))
  add(query_593954, "Version", newJString(Version))
  result = call_593953.call(nil, query_593954, nil, formData_593955, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_593935(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_593936, base: "/",
    url: url_PostDescribeDBSnapshots_593937, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_593915 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBSnapshots_593917(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_593916(path: JsonNode; query: JsonNode;
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
  var valid_593918 = query.getOrDefault("Marker")
  valid_593918 = validateParameter(valid_593918, JString, required = false,
                                 default = nil)
  if valid_593918 != nil:
    section.add "Marker", valid_593918
  var valid_593919 = query.getOrDefault("DBInstanceIdentifier")
  valid_593919 = validateParameter(valid_593919, JString, required = false,
                                 default = nil)
  if valid_593919 != nil:
    section.add "DBInstanceIdentifier", valid_593919
  var valid_593920 = query.getOrDefault("DBSnapshotIdentifier")
  valid_593920 = validateParameter(valid_593920, JString, required = false,
                                 default = nil)
  if valid_593920 != nil:
    section.add "DBSnapshotIdentifier", valid_593920
  var valid_593921 = query.getOrDefault("SnapshotType")
  valid_593921 = validateParameter(valid_593921, JString, required = false,
                                 default = nil)
  if valid_593921 != nil:
    section.add "SnapshotType", valid_593921
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593922 = query.getOrDefault("Action")
  valid_593922 = validateParameter(valid_593922, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_593922 != nil:
    section.add "Action", valid_593922
  var valid_593923 = query.getOrDefault("Version")
  valid_593923 = validateParameter(valid_593923, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593923 != nil:
    section.add "Version", valid_593923
  var valid_593924 = query.getOrDefault("MaxRecords")
  valid_593924 = validateParameter(valid_593924, JInt, required = false, default = nil)
  if valid_593924 != nil:
    section.add "MaxRecords", valid_593924
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593925 = header.getOrDefault("X-Amz-Signature")
  valid_593925 = validateParameter(valid_593925, JString, required = false,
                                 default = nil)
  if valid_593925 != nil:
    section.add "X-Amz-Signature", valid_593925
  var valid_593926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593926 = validateParameter(valid_593926, JString, required = false,
                                 default = nil)
  if valid_593926 != nil:
    section.add "X-Amz-Content-Sha256", valid_593926
  var valid_593927 = header.getOrDefault("X-Amz-Date")
  valid_593927 = validateParameter(valid_593927, JString, required = false,
                                 default = nil)
  if valid_593927 != nil:
    section.add "X-Amz-Date", valid_593927
  var valid_593928 = header.getOrDefault("X-Amz-Credential")
  valid_593928 = validateParameter(valid_593928, JString, required = false,
                                 default = nil)
  if valid_593928 != nil:
    section.add "X-Amz-Credential", valid_593928
  var valid_593929 = header.getOrDefault("X-Amz-Security-Token")
  valid_593929 = validateParameter(valid_593929, JString, required = false,
                                 default = nil)
  if valid_593929 != nil:
    section.add "X-Amz-Security-Token", valid_593929
  var valid_593930 = header.getOrDefault("X-Amz-Algorithm")
  valid_593930 = validateParameter(valid_593930, JString, required = false,
                                 default = nil)
  if valid_593930 != nil:
    section.add "X-Amz-Algorithm", valid_593930
  var valid_593931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593931 = validateParameter(valid_593931, JString, required = false,
                                 default = nil)
  if valid_593931 != nil:
    section.add "X-Amz-SignedHeaders", valid_593931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593932: Call_GetDescribeDBSnapshots_593915; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_593933: Call_GetDescribeDBSnapshots_593915; Marker: string = "";
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
  var query_593934 = newJObject()
  add(query_593934, "Marker", newJString(Marker))
  add(query_593934, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593934, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593934, "SnapshotType", newJString(SnapshotType))
  add(query_593934, "Action", newJString(Action))
  add(query_593934, "Version", newJString(Version))
  add(query_593934, "MaxRecords", newJInt(MaxRecords))
  result = call_593933.call(nil, query_593934, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_593915(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_593916, base: "/",
    url: url_GetDescribeDBSnapshots_593917, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_593974 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBSubnetGroups_593976(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_593975(path: JsonNode; query: JsonNode;
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
  var valid_593977 = query.getOrDefault("Action")
  valid_593977 = validateParameter(valid_593977, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_593977 != nil:
    section.add "Action", valid_593977
  var valid_593978 = query.getOrDefault("Version")
  valid_593978 = validateParameter(valid_593978, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593978 != nil:
    section.add "Version", valid_593978
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593979 = header.getOrDefault("X-Amz-Signature")
  valid_593979 = validateParameter(valid_593979, JString, required = false,
                                 default = nil)
  if valid_593979 != nil:
    section.add "X-Amz-Signature", valid_593979
  var valid_593980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593980 = validateParameter(valid_593980, JString, required = false,
                                 default = nil)
  if valid_593980 != nil:
    section.add "X-Amz-Content-Sha256", valid_593980
  var valid_593981 = header.getOrDefault("X-Amz-Date")
  valid_593981 = validateParameter(valid_593981, JString, required = false,
                                 default = nil)
  if valid_593981 != nil:
    section.add "X-Amz-Date", valid_593981
  var valid_593982 = header.getOrDefault("X-Amz-Credential")
  valid_593982 = validateParameter(valid_593982, JString, required = false,
                                 default = nil)
  if valid_593982 != nil:
    section.add "X-Amz-Credential", valid_593982
  var valid_593983 = header.getOrDefault("X-Amz-Security-Token")
  valid_593983 = validateParameter(valid_593983, JString, required = false,
                                 default = nil)
  if valid_593983 != nil:
    section.add "X-Amz-Security-Token", valid_593983
  var valid_593984 = header.getOrDefault("X-Amz-Algorithm")
  valid_593984 = validateParameter(valid_593984, JString, required = false,
                                 default = nil)
  if valid_593984 != nil:
    section.add "X-Amz-Algorithm", valid_593984
  var valid_593985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593985 = validateParameter(valid_593985, JString, required = false,
                                 default = nil)
  if valid_593985 != nil:
    section.add "X-Amz-SignedHeaders", valid_593985
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  section = newJObject()
  var valid_593986 = formData.getOrDefault("MaxRecords")
  valid_593986 = validateParameter(valid_593986, JInt, required = false, default = nil)
  if valid_593986 != nil:
    section.add "MaxRecords", valid_593986
  var valid_593987 = formData.getOrDefault("Marker")
  valid_593987 = validateParameter(valid_593987, JString, required = false,
                                 default = nil)
  if valid_593987 != nil:
    section.add "Marker", valid_593987
  var valid_593988 = formData.getOrDefault("DBSubnetGroupName")
  valid_593988 = validateParameter(valid_593988, JString, required = false,
                                 default = nil)
  if valid_593988 != nil:
    section.add "DBSubnetGroupName", valid_593988
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593989: Call_PostDescribeDBSubnetGroups_593974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593989.validator(path, query, header, formData, body)
  let scheme = call_593989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593989.url(scheme.get, call_593989.host, call_593989.base,
                         call_593989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593989, url, valid)

proc call*(call_593990: Call_PostDescribeDBSubnetGroups_593974;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_593991 = newJObject()
  var formData_593992 = newJObject()
  add(formData_593992, "MaxRecords", newJInt(MaxRecords))
  add(formData_593992, "Marker", newJString(Marker))
  add(query_593991, "Action", newJString(Action))
  add(formData_593992, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593991, "Version", newJString(Version))
  result = call_593990.call(nil, query_593991, nil, formData_593992, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_593974(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_593975, base: "/",
    url: url_PostDescribeDBSubnetGroups_593976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_593956 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBSubnetGroups_593958(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_593957(path: JsonNode; query: JsonNode;
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
  var valid_593959 = query.getOrDefault("Marker")
  valid_593959 = validateParameter(valid_593959, JString, required = false,
                                 default = nil)
  if valid_593959 != nil:
    section.add "Marker", valid_593959
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593960 = query.getOrDefault("Action")
  valid_593960 = validateParameter(valid_593960, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_593960 != nil:
    section.add "Action", valid_593960
  var valid_593961 = query.getOrDefault("DBSubnetGroupName")
  valid_593961 = validateParameter(valid_593961, JString, required = false,
                                 default = nil)
  if valid_593961 != nil:
    section.add "DBSubnetGroupName", valid_593961
  var valid_593962 = query.getOrDefault("Version")
  valid_593962 = validateParameter(valid_593962, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593962 != nil:
    section.add "Version", valid_593962
  var valid_593963 = query.getOrDefault("MaxRecords")
  valid_593963 = validateParameter(valid_593963, JInt, required = false, default = nil)
  if valid_593963 != nil:
    section.add "MaxRecords", valid_593963
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593964 = header.getOrDefault("X-Amz-Signature")
  valid_593964 = validateParameter(valid_593964, JString, required = false,
                                 default = nil)
  if valid_593964 != nil:
    section.add "X-Amz-Signature", valid_593964
  var valid_593965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593965 = validateParameter(valid_593965, JString, required = false,
                                 default = nil)
  if valid_593965 != nil:
    section.add "X-Amz-Content-Sha256", valid_593965
  var valid_593966 = header.getOrDefault("X-Amz-Date")
  valid_593966 = validateParameter(valid_593966, JString, required = false,
                                 default = nil)
  if valid_593966 != nil:
    section.add "X-Amz-Date", valid_593966
  var valid_593967 = header.getOrDefault("X-Amz-Credential")
  valid_593967 = validateParameter(valid_593967, JString, required = false,
                                 default = nil)
  if valid_593967 != nil:
    section.add "X-Amz-Credential", valid_593967
  var valid_593968 = header.getOrDefault("X-Amz-Security-Token")
  valid_593968 = validateParameter(valid_593968, JString, required = false,
                                 default = nil)
  if valid_593968 != nil:
    section.add "X-Amz-Security-Token", valid_593968
  var valid_593969 = header.getOrDefault("X-Amz-Algorithm")
  valid_593969 = validateParameter(valid_593969, JString, required = false,
                                 default = nil)
  if valid_593969 != nil:
    section.add "X-Amz-Algorithm", valid_593969
  var valid_593970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593970 = validateParameter(valid_593970, JString, required = false,
                                 default = nil)
  if valid_593970 != nil:
    section.add "X-Amz-SignedHeaders", valid_593970
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593971: Call_GetDescribeDBSubnetGroups_593956; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593971.validator(path, query, header, formData, body)
  let scheme = call_593971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593971.url(scheme.get, call_593971.host, call_593971.base,
                         call_593971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593971, url, valid)

proc call*(call_593972: Call_GetDescribeDBSubnetGroups_593956; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_593973 = newJObject()
  add(query_593973, "Marker", newJString(Marker))
  add(query_593973, "Action", newJString(Action))
  add(query_593973, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593973, "Version", newJString(Version))
  add(query_593973, "MaxRecords", newJInt(MaxRecords))
  result = call_593972.call(nil, query_593973, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_593956(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_593957, base: "/",
    url: url_GetDescribeDBSubnetGroups_593958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_594011 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEngineDefaultParameters_594013(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_594012(path: JsonNode;
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
  var valid_594014 = query.getOrDefault("Action")
  valid_594014 = validateParameter(valid_594014, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_594014 != nil:
    section.add "Action", valid_594014
  var valid_594015 = query.getOrDefault("Version")
  valid_594015 = validateParameter(valid_594015, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594015 != nil:
    section.add "Version", valid_594015
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594016 = header.getOrDefault("X-Amz-Signature")
  valid_594016 = validateParameter(valid_594016, JString, required = false,
                                 default = nil)
  if valid_594016 != nil:
    section.add "X-Amz-Signature", valid_594016
  var valid_594017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "X-Amz-Content-Sha256", valid_594017
  var valid_594018 = header.getOrDefault("X-Amz-Date")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Date", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-Credential")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Credential", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-Security-Token")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Security-Token", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-Algorithm")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-Algorithm", valid_594021
  var valid_594022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594022 = validateParameter(valid_594022, JString, required = false,
                                 default = nil)
  if valid_594022 != nil:
    section.add "X-Amz-SignedHeaders", valid_594022
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_594023 = formData.getOrDefault("MaxRecords")
  valid_594023 = validateParameter(valid_594023, JInt, required = false, default = nil)
  if valid_594023 != nil:
    section.add "MaxRecords", valid_594023
  var valid_594024 = formData.getOrDefault("Marker")
  valid_594024 = validateParameter(valid_594024, JString, required = false,
                                 default = nil)
  if valid_594024 != nil:
    section.add "Marker", valid_594024
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_594025 = formData.getOrDefault("DBParameterGroupFamily")
  valid_594025 = validateParameter(valid_594025, JString, required = true,
                                 default = nil)
  if valid_594025 != nil:
    section.add "DBParameterGroupFamily", valid_594025
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594026: Call_PostDescribeEngineDefaultParameters_594011;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594026.validator(path, query, header, formData, body)
  let scheme = call_594026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594026.url(scheme.get, call_594026.host, call_594026.base,
                         call_594026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594026, url, valid)

proc call*(call_594027: Call_PostDescribeEngineDefaultParameters_594011;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_594028 = newJObject()
  var formData_594029 = newJObject()
  add(formData_594029, "MaxRecords", newJInt(MaxRecords))
  add(formData_594029, "Marker", newJString(Marker))
  add(query_594028, "Action", newJString(Action))
  add(query_594028, "Version", newJString(Version))
  add(formData_594029, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_594027.call(nil, query_594028, nil, formData_594029, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_594011(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_594012, base: "/",
    url: url_PostDescribeEngineDefaultParameters_594013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_593993 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEngineDefaultParameters_593995(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_593994(path: JsonNode;
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
  var valid_593996 = query.getOrDefault("Marker")
  valid_593996 = validateParameter(valid_593996, JString, required = false,
                                 default = nil)
  if valid_593996 != nil:
    section.add "Marker", valid_593996
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_593997 = query.getOrDefault("DBParameterGroupFamily")
  valid_593997 = validateParameter(valid_593997, JString, required = true,
                                 default = nil)
  if valid_593997 != nil:
    section.add "DBParameterGroupFamily", valid_593997
  var valid_593998 = query.getOrDefault("Action")
  valid_593998 = validateParameter(valid_593998, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_593998 != nil:
    section.add "Action", valid_593998
  var valid_593999 = query.getOrDefault("Version")
  valid_593999 = validateParameter(valid_593999, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_593999 != nil:
    section.add "Version", valid_593999
  var valid_594000 = query.getOrDefault("MaxRecords")
  valid_594000 = validateParameter(valid_594000, JInt, required = false, default = nil)
  if valid_594000 != nil:
    section.add "MaxRecords", valid_594000
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594001 = header.getOrDefault("X-Amz-Signature")
  valid_594001 = validateParameter(valid_594001, JString, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "X-Amz-Signature", valid_594001
  var valid_594002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "X-Amz-Content-Sha256", valid_594002
  var valid_594003 = header.getOrDefault("X-Amz-Date")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Date", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Credential")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Credential", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-Security-Token")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Security-Token", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-Algorithm")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-Algorithm", valid_594006
  var valid_594007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594007 = validateParameter(valid_594007, JString, required = false,
                                 default = nil)
  if valid_594007 != nil:
    section.add "X-Amz-SignedHeaders", valid_594007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594008: Call_GetDescribeEngineDefaultParameters_593993;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594008.validator(path, query, header, formData, body)
  let scheme = call_594008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594008.url(scheme.get, call_594008.host, call_594008.base,
                         call_594008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594008, url, valid)

proc call*(call_594009: Call_GetDescribeEngineDefaultParameters_593993;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_594010 = newJObject()
  add(query_594010, "Marker", newJString(Marker))
  add(query_594010, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_594010, "Action", newJString(Action))
  add(query_594010, "Version", newJString(Version))
  add(query_594010, "MaxRecords", newJInt(MaxRecords))
  result = call_594009.call(nil, query_594010, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_593993(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_593994, base: "/",
    url: url_GetDescribeEngineDefaultParameters_593995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_594046 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEventCategories_594048(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_594047(path: JsonNode; query: JsonNode;
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
  var valid_594049 = query.getOrDefault("Action")
  valid_594049 = validateParameter(valid_594049, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_594049 != nil:
    section.add "Action", valid_594049
  var valid_594050 = query.getOrDefault("Version")
  valid_594050 = validateParameter(valid_594050, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594050 != nil:
    section.add "Version", valid_594050
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Content-Sha256", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Date")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Date", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Credential")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Credential", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Security-Token")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Security-Token", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Algorithm")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Algorithm", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-SignedHeaders", valid_594057
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_594058 = formData.getOrDefault("SourceType")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "SourceType", valid_594058
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594059: Call_PostDescribeEventCategories_594046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594059.validator(path, query, header, formData, body)
  let scheme = call_594059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594059.url(scheme.get, call_594059.host, call_594059.base,
                         call_594059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594059, url, valid)

proc call*(call_594060: Call_PostDescribeEventCategories_594046;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594061 = newJObject()
  var formData_594062 = newJObject()
  add(formData_594062, "SourceType", newJString(SourceType))
  add(query_594061, "Action", newJString(Action))
  add(query_594061, "Version", newJString(Version))
  result = call_594060.call(nil, query_594061, nil, formData_594062, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_594046(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_594047, base: "/",
    url: url_PostDescribeEventCategories_594048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_594030 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEventCategories_594032(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_594031(path: JsonNode; query: JsonNode;
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
  var valid_594033 = query.getOrDefault("SourceType")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "SourceType", valid_594033
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594034 = query.getOrDefault("Action")
  valid_594034 = validateParameter(valid_594034, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_594034 != nil:
    section.add "Action", valid_594034
  var valid_594035 = query.getOrDefault("Version")
  valid_594035 = validateParameter(valid_594035, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594035 != nil:
    section.add "Version", valid_594035
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594036 = header.getOrDefault("X-Amz-Signature")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Signature", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Content-Sha256", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Date")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Date", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-Credential")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-Credential", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-Security-Token")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-Security-Token", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Algorithm")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Algorithm", valid_594041
  var valid_594042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "X-Amz-SignedHeaders", valid_594042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594043: Call_GetDescribeEventCategories_594030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594043.validator(path, query, header, formData, body)
  let scheme = call_594043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594043.url(scheme.get, call_594043.host, call_594043.base,
                         call_594043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594043, url, valid)

proc call*(call_594044: Call_GetDescribeEventCategories_594030;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594045 = newJObject()
  add(query_594045, "SourceType", newJString(SourceType))
  add(query_594045, "Action", newJString(Action))
  add(query_594045, "Version", newJString(Version))
  result = call_594044.call(nil, query_594045, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_594030(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_594031, base: "/",
    url: url_GetDescribeEventCategories_594032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_594081 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEventSubscriptions_594083(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_594082(path: JsonNode;
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
  var valid_594084 = query.getOrDefault("Action")
  valid_594084 = validateParameter(valid_594084, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_594084 != nil:
    section.add "Action", valid_594084
  var valid_594085 = query.getOrDefault("Version")
  valid_594085 = validateParameter(valid_594085, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594085 != nil:
    section.add "Version", valid_594085
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594086 = header.getOrDefault("X-Amz-Signature")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Signature", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Content-Sha256", valid_594087
  var valid_594088 = header.getOrDefault("X-Amz-Date")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-Date", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-Credential")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Credential", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Security-Token")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Security-Token", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Algorithm")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Algorithm", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-SignedHeaders", valid_594092
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  section = newJObject()
  var valid_594093 = formData.getOrDefault("MaxRecords")
  valid_594093 = validateParameter(valid_594093, JInt, required = false, default = nil)
  if valid_594093 != nil:
    section.add "MaxRecords", valid_594093
  var valid_594094 = formData.getOrDefault("Marker")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "Marker", valid_594094
  var valid_594095 = formData.getOrDefault("SubscriptionName")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "SubscriptionName", valid_594095
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594096: Call_PostDescribeEventSubscriptions_594081; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594096.validator(path, query, header, formData, body)
  let scheme = call_594096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594096.url(scheme.get, call_594096.host, call_594096.base,
                         call_594096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594096, url, valid)

proc call*(call_594097: Call_PostDescribeEventSubscriptions_594081;
          MaxRecords: int = 0; Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594098 = newJObject()
  var formData_594099 = newJObject()
  add(formData_594099, "MaxRecords", newJInt(MaxRecords))
  add(formData_594099, "Marker", newJString(Marker))
  add(formData_594099, "SubscriptionName", newJString(SubscriptionName))
  add(query_594098, "Action", newJString(Action))
  add(query_594098, "Version", newJString(Version))
  result = call_594097.call(nil, query_594098, nil, formData_594099, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_594081(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_594082, base: "/",
    url: url_PostDescribeEventSubscriptions_594083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_594063 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEventSubscriptions_594065(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_594064(path: JsonNode; query: JsonNode;
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
  var valid_594066 = query.getOrDefault("Marker")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "Marker", valid_594066
  var valid_594067 = query.getOrDefault("SubscriptionName")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "SubscriptionName", valid_594067
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594068 = query.getOrDefault("Action")
  valid_594068 = validateParameter(valid_594068, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_594068 != nil:
    section.add "Action", valid_594068
  var valid_594069 = query.getOrDefault("Version")
  valid_594069 = validateParameter(valid_594069, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594069 != nil:
    section.add "Version", valid_594069
  var valid_594070 = query.getOrDefault("MaxRecords")
  valid_594070 = validateParameter(valid_594070, JInt, required = false, default = nil)
  if valid_594070 != nil:
    section.add "MaxRecords", valid_594070
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594071 = header.getOrDefault("X-Amz-Signature")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Signature", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Content-Sha256", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Date")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Date", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Credential")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Credential", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Security-Token")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Security-Token", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Algorithm")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Algorithm", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-SignedHeaders", valid_594077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594078: Call_GetDescribeEventSubscriptions_594063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594078.validator(path, query, header, formData, body)
  let scheme = call_594078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594078.url(scheme.get, call_594078.host, call_594078.base,
                         call_594078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594078, url, valid)

proc call*(call_594079: Call_GetDescribeEventSubscriptions_594063;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_594080 = newJObject()
  add(query_594080, "Marker", newJString(Marker))
  add(query_594080, "SubscriptionName", newJString(SubscriptionName))
  add(query_594080, "Action", newJString(Action))
  add(query_594080, "Version", newJString(Version))
  add(query_594080, "MaxRecords", newJInt(MaxRecords))
  result = call_594079.call(nil, query_594080, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_594063(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_594064, base: "/",
    url: url_GetDescribeEventSubscriptions_594065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_594123 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEvents_594125(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_594124(path: JsonNode; query: JsonNode;
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
  var valid_594126 = query.getOrDefault("Action")
  valid_594126 = validateParameter(valid_594126, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_594126 != nil:
    section.add "Action", valid_594126
  var valid_594127 = query.getOrDefault("Version")
  valid_594127 = validateParameter(valid_594127, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594127 != nil:
    section.add "Version", valid_594127
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594128 = header.getOrDefault("X-Amz-Signature")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Signature", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Content-Sha256", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Date")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Date", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Credential")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Credential", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Security-Token")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Security-Token", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Algorithm")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Algorithm", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-SignedHeaders", valid_594134
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
  var valid_594135 = formData.getOrDefault("MaxRecords")
  valid_594135 = validateParameter(valid_594135, JInt, required = false, default = nil)
  if valid_594135 != nil:
    section.add "MaxRecords", valid_594135
  var valid_594136 = formData.getOrDefault("Marker")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "Marker", valid_594136
  var valid_594137 = formData.getOrDefault("SourceIdentifier")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "SourceIdentifier", valid_594137
  var valid_594138 = formData.getOrDefault("SourceType")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_594138 != nil:
    section.add "SourceType", valid_594138
  var valid_594139 = formData.getOrDefault("Duration")
  valid_594139 = validateParameter(valid_594139, JInt, required = false, default = nil)
  if valid_594139 != nil:
    section.add "Duration", valid_594139
  var valid_594140 = formData.getOrDefault("EndTime")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "EndTime", valid_594140
  var valid_594141 = formData.getOrDefault("StartTime")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "StartTime", valid_594141
  var valid_594142 = formData.getOrDefault("EventCategories")
  valid_594142 = validateParameter(valid_594142, JArray, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "EventCategories", valid_594142
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594143: Call_PostDescribeEvents_594123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594143.validator(path, query, header, formData, body)
  let scheme = call_594143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594143.url(scheme.get, call_594143.host, call_594143.base,
                         call_594143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594143, url, valid)

proc call*(call_594144: Call_PostDescribeEvents_594123; MaxRecords: int = 0;
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
  var query_594145 = newJObject()
  var formData_594146 = newJObject()
  add(formData_594146, "MaxRecords", newJInt(MaxRecords))
  add(formData_594146, "Marker", newJString(Marker))
  add(formData_594146, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_594146, "SourceType", newJString(SourceType))
  add(formData_594146, "Duration", newJInt(Duration))
  add(formData_594146, "EndTime", newJString(EndTime))
  add(formData_594146, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_594146.add "EventCategories", EventCategories
  add(query_594145, "Action", newJString(Action))
  add(query_594145, "Version", newJString(Version))
  result = call_594144.call(nil, query_594145, nil, formData_594146, nil)

var postDescribeEvents* = Call_PostDescribeEvents_594123(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_594124, base: "/",
    url: url_PostDescribeEvents_594125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_594100 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEvents_594102(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_594101(path: JsonNode; query: JsonNode;
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
  var valid_594103 = query.getOrDefault("Marker")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "Marker", valid_594103
  var valid_594104 = query.getOrDefault("SourceType")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_594104 != nil:
    section.add "SourceType", valid_594104
  var valid_594105 = query.getOrDefault("SourceIdentifier")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "SourceIdentifier", valid_594105
  var valid_594106 = query.getOrDefault("EventCategories")
  valid_594106 = validateParameter(valid_594106, JArray, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "EventCategories", valid_594106
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594107 = query.getOrDefault("Action")
  valid_594107 = validateParameter(valid_594107, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_594107 != nil:
    section.add "Action", valid_594107
  var valid_594108 = query.getOrDefault("StartTime")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "StartTime", valid_594108
  var valid_594109 = query.getOrDefault("Duration")
  valid_594109 = validateParameter(valid_594109, JInt, required = false, default = nil)
  if valid_594109 != nil:
    section.add "Duration", valid_594109
  var valid_594110 = query.getOrDefault("EndTime")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "EndTime", valid_594110
  var valid_594111 = query.getOrDefault("Version")
  valid_594111 = validateParameter(valid_594111, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594111 != nil:
    section.add "Version", valid_594111
  var valid_594112 = query.getOrDefault("MaxRecords")
  valid_594112 = validateParameter(valid_594112, JInt, required = false, default = nil)
  if valid_594112 != nil:
    section.add "MaxRecords", valid_594112
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594113 = header.getOrDefault("X-Amz-Signature")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Signature", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Content-Sha256", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Date")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Date", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Credential")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Credential", valid_594116
  var valid_594117 = header.getOrDefault("X-Amz-Security-Token")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-Security-Token", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-Algorithm")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-Algorithm", valid_594118
  var valid_594119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "X-Amz-SignedHeaders", valid_594119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594120: Call_GetDescribeEvents_594100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594120.validator(path, query, header, formData, body)
  let scheme = call_594120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594120.url(scheme.get, call_594120.host, call_594120.base,
                         call_594120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594120, url, valid)

proc call*(call_594121: Call_GetDescribeEvents_594100; Marker: string = "";
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
  var query_594122 = newJObject()
  add(query_594122, "Marker", newJString(Marker))
  add(query_594122, "SourceType", newJString(SourceType))
  add(query_594122, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_594122.add "EventCategories", EventCategories
  add(query_594122, "Action", newJString(Action))
  add(query_594122, "StartTime", newJString(StartTime))
  add(query_594122, "Duration", newJInt(Duration))
  add(query_594122, "EndTime", newJString(EndTime))
  add(query_594122, "Version", newJString(Version))
  add(query_594122, "MaxRecords", newJInt(MaxRecords))
  result = call_594121.call(nil, query_594122, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_594100(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_594101,
    base: "/", url: url_GetDescribeEvents_594102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_594166 = ref object of OpenApiRestCall_592348
proc url_PostDescribeOptionGroupOptions_594168(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_594167(path: JsonNode;
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
  var valid_594169 = query.getOrDefault("Action")
  valid_594169 = validateParameter(valid_594169, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_594169 != nil:
    section.add "Action", valid_594169
  var valid_594170 = query.getOrDefault("Version")
  valid_594170 = validateParameter(valid_594170, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594170 != nil:
    section.add "Version", valid_594170
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594171 = header.getOrDefault("X-Amz-Signature")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Signature", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Content-Sha256", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Date")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Date", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-Credential")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Credential", valid_594174
  var valid_594175 = header.getOrDefault("X-Amz-Security-Token")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-Security-Token", valid_594175
  var valid_594176 = header.getOrDefault("X-Amz-Algorithm")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Algorithm", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-SignedHeaders", valid_594177
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_594178 = formData.getOrDefault("MaxRecords")
  valid_594178 = validateParameter(valid_594178, JInt, required = false, default = nil)
  if valid_594178 != nil:
    section.add "MaxRecords", valid_594178
  var valid_594179 = formData.getOrDefault("Marker")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "Marker", valid_594179
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_594180 = formData.getOrDefault("EngineName")
  valid_594180 = validateParameter(valid_594180, JString, required = true,
                                 default = nil)
  if valid_594180 != nil:
    section.add "EngineName", valid_594180
  var valid_594181 = formData.getOrDefault("MajorEngineVersion")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "MajorEngineVersion", valid_594181
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594182: Call_PostDescribeOptionGroupOptions_594166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594182.validator(path, query, header, formData, body)
  let scheme = call_594182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594182.url(scheme.get, call_594182.host, call_594182.base,
                         call_594182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594182, url, valid)

proc call*(call_594183: Call_PostDescribeOptionGroupOptions_594166;
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
  var query_594184 = newJObject()
  var formData_594185 = newJObject()
  add(formData_594185, "MaxRecords", newJInt(MaxRecords))
  add(formData_594185, "Marker", newJString(Marker))
  add(formData_594185, "EngineName", newJString(EngineName))
  add(formData_594185, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_594184, "Action", newJString(Action))
  add(query_594184, "Version", newJString(Version))
  result = call_594183.call(nil, query_594184, nil, formData_594185, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_594166(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_594167, base: "/",
    url: url_PostDescribeOptionGroupOptions_594168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_594147 = ref object of OpenApiRestCall_592348
proc url_GetDescribeOptionGroupOptions_594149(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_594148(path: JsonNode; query: JsonNode;
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
  var valid_594150 = query.getOrDefault("EngineName")
  valid_594150 = validateParameter(valid_594150, JString, required = true,
                                 default = nil)
  if valid_594150 != nil:
    section.add "EngineName", valid_594150
  var valid_594151 = query.getOrDefault("Marker")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "Marker", valid_594151
  var valid_594152 = query.getOrDefault("Action")
  valid_594152 = validateParameter(valid_594152, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_594152 != nil:
    section.add "Action", valid_594152
  var valid_594153 = query.getOrDefault("Version")
  valid_594153 = validateParameter(valid_594153, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594153 != nil:
    section.add "Version", valid_594153
  var valid_594154 = query.getOrDefault("MaxRecords")
  valid_594154 = validateParameter(valid_594154, JInt, required = false, default = nil)
  if valid_594154 != nil:
    section.add "MaxRecords", valid_594154
  var valid_594155 = query.getOrDefault("MajorEngineVersion")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "MajorEngineVersion", valid_594155
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Content-Sha256", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Date")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Date", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-Credential")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Credential", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Security-Token")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Security-Token", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Algorithm")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Algorithm", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-SignedHeaders", valid_594162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594163: Call_GetDescribeOptionGroupOptions_594147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594163.validator(path, query, header, formData, body)
  let scheme = call_594163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594163.url(scheme.get, call_594163.host, call_594163.base,
                         call_594163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594163, url, valid)

proc call*(call_594164: Call_GetDescribeOptionGroupOptions_594147;
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
  var query_594165 = newJObject()
  add(query_594165, "EngineName", newJString(EngineName))
  add(query_594165, "Marker", newJString(Marker))
  add(query_594165, "Action", newJString(Action))
  add(query_594165, "Version", newJString(Version))
  add(query_594165, "MaxRecords", newJInt(MaxRecords))
  add(query_594165, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_594164.call(nil, query_594165, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_594147(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_594148, base: "/",
    url: url_GetDescribeOptionGroupOptions_594149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_594206 = ref object of OpenApiRestCall_592348
proc url_PostDescribeOptionGroups_594208(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_594207(path: JsonNode; query: JsonNode;
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
  var valid_594209 = query.getOrDefault("Action")
  valid_594209 = validateParameter(valid_594209, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_594209 != nil:
    section.add "Action", valid_594209
  var valid_594210 = query.getOrDefault("Version")
  valid_594210 = validateParameter(valid_594210, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594210 != nil:
    section.add "Version", valid_594210
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594211 = header.getOrDefault("X-Amz-Signature")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Signature", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Content-Sha256", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Date")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Date", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Credential")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Credential", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Security-Token")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Security-Token", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Algorithm")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Algorithm", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-SignedHeaders", valid_594217
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_594218 = formData.getOrDefault("MaxRecords")
  valid_594218 = validateParameter(valid_594218, JInt, required = false, default = nil)
  if valid_594218 != nil:
    section.add "MaxRecords", valid_594218
  var valid_594219 = formData.getOrDefault("Marker")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "Marker", valid_594219
  var valid_594220 = formData.getOrDefault("EngineName")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "EngineName", valid_594220
  var valid_594221 = formData.getOrDefault("MajorEngineVersion")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "MajorEngineVersion", valid_594221
  var valid_594222 = formData.getOrDefault("OptionGroupName")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "OptionGroupName", valid_594222
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594223: Call_PostDescribeOptionGroups_594206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594223.validator(path, query, header, formData, body)
  let scheme = call_594223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594223.url(scheme.get, call_594223.host, call_594223.base,
                         call_594223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594223, url, valid)

proc call*(call_594224: Call_PostDescribeOptionGroups_594206; MaxRecords: int = 0;
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
  var query_594225 = newJObject()
  var formData_594226 = newJObject()
  add(formData_594226, "MaxRecords", newJInt(MaxRecords))
  add(formData_594226, "Marker", newJString(Marker))
  add(formData_594226, "EngineName", newJString(EngineName))
  add(formData_594226, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_594225, "Action", newJString(Action))
  add(formData_594226, "OptionGroupName", newJString(OptionGroupName))
  add(query_594225, "Version", newJString(Version))
  result = call_594224.call(nil, query_594225, nil, formData_594226, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_594206(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_594207, base: "/",
    url: url_PostDescribeOptionGroups_594208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_594186 = ref object of OpenApiRestCall_592348
proc url_GetDescribeOptionGroups_594188(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_594187(path: JsonNode; query: JsonNode;
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
  var valid_594189 = query.getOrDefault("EngineName")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "EngineName", valid_594189
  var valid_594190 = query.getOrDefault("Marker")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "Marker", valid_594190
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594191 = query.getOrDefault("Action")
  valid_594191 = validateParameter(valid_594191, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_594191 != nil:
    section.add "Action", valid_594191
  var valid_594192 = query.getOrDefault("OptionGroupName")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "OptionGroupName", valid_594192
  var valid_594193 = query.getOrDefault("Version")
  valid_594193 = validateParameter(valid_594193, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594193 != nil:
    section.add "Version", valid_594193
  var valid_594194 = query.getOrDefault("MaxRecords")
  valid_594194 = validateParameter(valid_594194, JInt, required = false, default = nil)
  if valid_594194 != nil:
    section.add "MaxRecords", valid_594194
  var valid_594195 = query.getOrDefault("MajorEngineVersion")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "MajorEngineVersion", valid_594195
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594196 = header.getOrDefault("X-Amz-Signature")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Signature", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Content-Sha256", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Date")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Date", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Credential")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Credential", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Security-Token")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Security-Token", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Algorithm")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Algorithm", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594203: Call_GetDescribeOptionGroups_594186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594203.validator(path, query, header, formData, body)
  let scheme = call_594203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594203.url(scheme.get, call_594203.host, call_594203.base,
                         call_594203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594203, url, valid)

proc call*(call_594204: Call_GetDescribeOptionGroups_594186;
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
  var query_594205 = newJObject()
  add(query_594205, "EngineName", newJString(EngineName))
  add(query_594205, "Marker", newJString(Marker))
  add(query_594205, "Action", newJString(Action))
  add(query_594205, "OptionGroupName", newJString(OptionGroupName))
  add(query_594205, "Version", newJString(Version))
  add(query_594205, "MaxRecords", newJInt(MaxRecords))
  add(query_594205, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_594204.call(nil, query_594205, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_594186(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_594187, base: "/",
    url: url_GetDescribeOptionGroups_594188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_594249 = ref object of OpenApiRestCall_592348
proc url_PostDescribeOrderableDBInstanceOptions_594251(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_594250(path: JsonNode;
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
  var valid_594252 = query.getOrDefault("Action")
  valid_594252 = validateParameter(valid_594252, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_594252 != nil:
    section.add "Action", valid_594252
  var valid_594253 = query.getOrDefault("Version")
  valid_594253 = validateParameter(valid_594253, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594253 != nil:
    section.add "Version", valid_594253
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594254 = header.getOrDefault("X-Amz-Signature")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Signature", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Content-Sha256", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Date")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Date", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Credential")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Credential", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Security-Token")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Security-Token", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Algorithm")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Algorithm", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-SignedHeaders", valid_594260
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
  var valid_594261 = formData.getOrDefault("DBInstanceClass")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "DBInstanceClass", valid_594261
  var valid_594262 = formData.getOrDefault("MaxRecords")
  valid_594262 = validateParameter(valid_594262, JInt, required = false, default = nil)
  if valid_594262 != nil:
    section.add "MaxRecords", valid_594262
  var valid_594263 = formData.getOrDefault("EngineVersion")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "EngineVersion", valid_594263
  var valid_594264 = formData.getOrDefault("Marker")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "Marker", valid_594264
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_594265 = formData.getOrDefault("Engine")
  valid_594265 = validateParameter(valid_594265, JString, required = true,
                                 default = nil)
  if valid_594265 != nil:
    section.add "Engine", valid_594265
  var valid_594266 = formData.getOrDefault("Vpc")
  valid_594266 = validateParameter(valid_594266, JBool, required = false, default = nil)
  if valid_594266 != nil:
    section.add "Vpc", valid_594266
  var valid_594267 = formData.getOrDefault("LicenseModel")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "LicenseModel", valid_594267
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594268: Call_PostDescribeOrderableDBInstanceOptions_594249;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594268.validator(path, query, header, formData, body)
  let scheme = call_594268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594268.url(scheme.get, call_594268.host, call_594268.base,
                         call_594268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594268, url, valid)

proc call*(call_594269: Call_PostDescribeOrderableDBInstanceOptions_594249;
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
  var query_594270 = newJObject()
  var formData_594271 = newJObject()
  add(formData_594271, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594271, "MaxRecords", newJInt(MaxRecords))
  add(formData_594271, "EngineVersion", newJString(EngineVersion))
  add(formData_594271, "Marker", newJString(Marker))
  add(formData_594271, "Engine", newJString(Engine))
  add(formData_594271, "Vpc", newJBool(Vpc))
  add(query_594270, "Action", newJString(Action))
  add(formData_594271, "LicenseModel", newJString(LicenseModel))
  add(query_594270, "Version", newJString(Version))
  result = call_594269.call(nil, query_594270, nil, formData_594271, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_594249(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_594250, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_594251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_594227 = ref object of OpenApiRestCall_592348
proc url_GetDescribeOrderableDBInstanceOptions_594229(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_594228(path: JsonNode;
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
  var valid_594230 = query.getOrDefault("Marker")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "Marker", valid_594230
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_594231 = query.getOrDefault("Engine")
  valid_594231 = validateParameter(valid_594231, JString, required = true,
                                 default = nil)
  if valid_594231 != nil:
    section.add "Engine", valid_594231
  var valid_594232 = query.getOrDefault("LicenseModel")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "LicenseModel", valid_594232
  var valid_594233 = query.getOrDefault("Vpc")
  valid_594233 = validateParameter(valid_594233, JBool, required = false, default = nil)
  if valid_594233 != nil:
    section.add "Vpc", valid_594233
  var valid_594234 = query.getOrDefault("EngineVersion")
  valid_594234 = validateParameter(valid_594234, JString, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "EngineVersion", valid_594234
  var valid_594235 = query.getOrDefault("Action")
  valid_594235 = validateParameter(valid_594235, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_594235 != nil:
    section.add "Action", valid_594235
  var valid_594236 = query.getOrDefault("Version")
  valid_594236 = validateParameter(valid_594236, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594236 != nil:
    section.add "Version", valid_594236
  var valid_594237 = query.getOrDefault("DBInstanceClass")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "DBInstanceClass", valid_594237
  var valid_594238 = query.getOrDefault("MaxRecords")
  valid_594238 = validateParameter(valid_594238, JInt, required = false, default = nil)
  if valid_594238 != nil:
    section.add "MaxRecords", valid_594238
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594239 = header.getOrDefault("X-Amz-Signature")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Signature", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Content-Sha256", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Date")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Date", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Credential")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Credential", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Security-Token")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Security-Token", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Algorithm")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Algorithm", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-SignedHeaders", valid_594245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594246: Call_GetDescribeOrderableDBInstanceOptions_594227;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594246.validator(path, query, header, formData, body)
  let scheme = call_594246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594246.url(scheme.get, call_594246.host, call_594246.base,
                         call_594246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594246, url, valid)

proc call*(call_594247: Call_GetDescribeOrderableDBInstanceOptions_594227;
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
  var query_594248 = newJObject()
  add(query_594248, "Marker", newJString(Marker))
  add(query_594248, "Engine", newJString(Engine))
  add(query_594248, "LicenseModel", newJString(LicenseModel))
  add(query_594248, "Vpc", newJBool(Vpc))
  add(query_594248, "EngineVersion", newJString(EngineVersion))
  add(query_594248, "Action", newJString(Action))
  add(query_594248, "Version", newJString(Version))
  add(query_594248, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594248, "MaxRecords", newJInt(MaxRecords))
  result = call_594247.call(nil, query_594248, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_594227(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_594228, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_594229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_594296 = ref object of OpenApiRestCall_592348
proc url_PostDescribeReservedDBInstances_594298(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_594297(path: JsonNode;
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
  var valid_594299 = query.getOrDefault("Action")
  valid_594299 = validateParameter(valid_594299, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_594299 != nil:
    section.add "Action", valid_594299
  var valid_594300 = query.getOrDefault("Version")
  valid_594300 = validateParameter(valid_594300, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594300 != nil:
    section.add "Version", valid_594300
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594301 = header.getOrDefault("X-Amz-Signature")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Signature", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Content-Sha256", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Date")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Date", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Credential")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Credential", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Security-Token")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Security-Token", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Algorithm")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Algorithm", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-SignedHeaders", valid_594307
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
  var valid_594308 = formData.getOrDefault("DBInstanceClass")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "DBInstanceClass", valid_594308
  var valid_594309 = formData.getOrDefault("MultiAZ")
  valid_594309 = validateParameter(valid_594309, JBool, required = false, default = nil)
  if valid_594309 != nil:
    section.add "MultiAZ", valid_594309
  var valid_594310 = formData.getOrDefault("MaxRecords")
  valid_594310 = validateParameter(valid_594310, JInt, required = false, default = nil)
  if valid_594310 != nil:
    section.add "MaxRecords", valid_594310
  var valid_594311 = formData.getOrDefault("ReservedDBInstanceId")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "ReservedDBInstanceId", valid_594311
  var valid_594312 = formData.getOrDefault("Marker")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "Marker", valid_594312
  var valid_594313 = formData.getOrDefault("Duration")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "Duration", valid_594313
  var valid_594314 = formData.getOrDefault("OfferingType")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "OfferingType", valid_594314
  var valid_594315 = formData.getOrDefault("ProductDescription")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "ProductDescription", valid_594315
  var valid_594316 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594316
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594317: Call_PostDescribeReservedDBInstances_594296;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594317.validator(path, query, header, formData, body)
  let scheme = call_594317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594317.url(scheme.get, call_594317.host, call_594317.base,
                         call_594317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594317, url, valid)

proc call*(call_594318: Call_PostDescribeReservedDBInstances_594296;
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
  var query_594319 = newJObject()
  var formData_594320 = newJObject()
  add(formData_594320, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594320, "MultiAZ", newJBool(MultiAZ))
  add(formData_594320, "MaxRecords", newJInt(MaxRecords))
  add(formData_594320, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_594320, "Marker", newJString(Marker))
  add(formData_594320, "Duration", newJString(Duration))
  add(formData_594320, "OfferingType", newJString(OfferingType))
  add(formData_594320, "ProductDescription", newJString(ProductDescription))
  add(query_594319, "Action", newJString(Action))
  add(formData_594320, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594319, "Version", newJString(Version))
  result = call_594318.call(nil, query_594319, nil, formData_594320, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_594296(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_594297, base: "/",
    url: url_PostDescribeReservedDBInstances_594298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_594272 = ref object of OpenApiRestCall_592348
proc url_GetDescribeReservedDBInstances_594274(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_594273(path: JsonNode;
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
  var valid_594275 = query.getOrDefault("Marker")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "Marker", valid_594275
  var valid_594276 = query.getOrDefault("ProductDescription")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "ProductDescription", valid_594276
  var valid_594277 = query.getOrDefault("OfferingType")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "OfferingType", valid_594277
  var valid_594278 = query.getOrDefault("ReservedDBInstanceId")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "ReservedDBInstanceId", valid_594278
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594279 = query.getOrDefault("Action")
  valid_594279 = validateParameter(valid_594279, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_594279 != nil:
    section.add "Action", valid_594279
  var valid_594280 = query.getOrDefault("MultiAZ")
  valid_594280 = validateParameter(valid_594280, JBool, required = false, default = nil)
  if valid_594280 != nil:
    section.add "MultiAZ", valid_594280
  var valid_594281 = query.getOrDefault("Duration")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "Duration", valid_594281
  var valid_594282 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594282
  var valid_594283 = query.getOrDefault("Version")
  valid_594283 = validateParameter(valid_594283, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594283 != nil:
    section.add "Version", valid_594283
  var valid_594284 = query.getOrDefault("DBInstanceClass")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "DBInstanceClass", valid_594284
  var valid_594285 = query.getOrDefault("MaxRecords")
  valid_594285 = validateParameter(valid_594285, JInt, required = false, default = nil)
  if valid_594285 != nil:
    section.add "MaxRecords", valid_594285
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594286 = header.getOrDefault("X-Amz-Signature")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Signature", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Content-Sha256", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Date")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Date", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Credential")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Credential", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Security-Token")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Security-Token", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Algorithm")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Algorithm", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-SignedHeaders", valid_594292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594293: Call_GetDescribeReservedDBInstances_594272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594293.validator(path, query, header, formData, body)
  let scheme = call_594293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594293.url(scheme.get, call_594293.host, call_594293.base,
                         call_594293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594293, url, valid)

proc call*(call_594294: Call_GetDescribeReservedDBInstances_594272;
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
  var query_594295 = newJObject()
  add(query_594295, "Marker", newJString(Marker))
  add(query_594295, "ProductDescription", newJString(ProductDescription))
  add(query_594295, "OfferingType", newJString(OfferingType))
  add(query_594295, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_594295, "Action", newJString(Action))
  add(query_594295, "MultiAZ", newJBool(MultiAZ))
  add(query_594295, "Duration", newJString(Duration))
  add(query_594295, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594295, "Version", newJString(Version))
  add(query_594295, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594295, "MaxRecords", newJInt(MaxRecords))
  result = call_594294.call(nil, query_594295, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_594272(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_594273, base: "/",
    url: url_GetDescribeReservedDBInstances_594274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_594344 = ref object of OpenApiRestCall_592348
proc url_PostDescribeReservedDBInstancesOfferings_594346(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_594345(path: JsonNode;
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
  var valid_594347 = query.getOrDefault("Action")
  valid_594347 = validateParameter(valid_594347, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_594347 != nil:
    section.add "Action", valid_594347
  var valid_594348 = query.getOrDefault("Version")
  valid_594348 = validateParameter(valid_594348, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594348 != nil:
    section.add "Version", valid_594348
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594349 = header.getOrDefault("X-Amz-Signature")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Signature", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Content-Sha256", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Date")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Date", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-Credential")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-Credential", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Security-Token")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Security-Token", valid_594353
  var valid_594354 = header.getOrDefault("X-Amz-Algorithm")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "X-Amz-Algorithm", valid_594354
  var valid_594355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-SignedHeaders", valid_594355
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
  var valid_594356 = formData.getOrDefault("DBInstanceClass")
  valid_594356 = validateParameter(valid_594356, JString, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "DBInstanceClass", valid_594356
  var valid_594357 = formData.getOrDefault("MultiAZ")
  valid_594357 = validateParameter(valid_594357, JBool, required = false, default = nil)
  if valid_594357 != nil:
    section.add "MultiAZ", valid_594357
  var valid_594358 = formData.getOrDefault("MaxRecords")
  valid_594358 = validateParameter(valid_594358, JInt, required = false, default = nil)
  if valid_594358 != nil:
    section.add "MaxRecords", valid_594358
  var valid_594359 = formData.getOrDefault("Marker")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "Marker", valid_594359
  var valid_594360 = formData.getOrDefault("Duration")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "Duration", valid_594360
  var valid_594361 = formData.getOrDefault("OfferingType")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "OfferingType", valid_594361
  var valid_594362 = formData.getOrDefault("ProductDescription")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "ProductDescription", valid_594362
  var valid_594363 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594363
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594364: Call_PostDescribeReservedDBInstancesOfferings_594344;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594364.validator(path, query, header, formData, body)
  let scheme = call_594364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594364.url(scheme.get, call_594364.host, call_594364.base,
                         call_594364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594364, url, valid)

proc call*(call_594365: Call_PostDescribeReservedDBInstancesOfferings_594344;
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
  var query_594366 = newJObject()
  var formData_594367 = newJObject()
  add(formData_594367, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594367, "MultiAZ", newJBool(MultiAZ))
  add(formData_594367, "MaxRecords", newJInt(MaxRecords))
  add(formData_594367, "Marker", newJString(Marker))
  add(formData_594367, "Duration", newJString(Duration))
  add(formData_594367, "OfferingType", newJString(OfferingType))
  add(formData_594367, "ProductDescription", newJString(ProductDescription))
  add(query_594366, "Action", newJString(Action))
  add(formData_594367, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594366, "Version", newJString(Version))
  result = call_594365.call(nil, query_594366, nil, formData_594367, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_594344(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_594345,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_594346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_594321 = ref object of OpenApiRestCall_592348
proc url_GetDescribeReservedDBInstancesOfferings_594323(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_594322(path: JsonNode;
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
  var valid_594324 = query.getOrDefault("Marker")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "Marker", valid_594324
  var valid_594325 = query.getOrDefault("ProductDescription")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "ProductDescription", valid_594325
  var valid_594326 = query.getOrDefault("OfferingType")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "OfferingType", valid_594326
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594327 = query.getOrDefault("Action")
  valid_594327 = validateParameter(valid_594327, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_594327 != nil:
    section.add "Action", valid_594327
  var valid_594328 = query.getOrDefault("MultiAZ")
  valid_594328 = validateParameter(valid_594328, JBool, required = false, default = nil)
  if valid_594328 != nil:
    section.add "MultiAZ", valid_594328
  var valid_594329 = query.getOrDefault("Duration")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "Duration", valid_594329
  var valid_594330 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594330
  var valid_594331 = query.getOrDefault("Version")
  valid_594331 = validateParameter(valid_594331, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594331 != nil:
    section.add "Version", valid_594331
  var valid_594332 = query.getOrDefault("DBInstanceClass")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "DBInstanceClass", valid_594332
  var valid_594333 = query.getOrDefault("MaxRecords")
  valid_594333 = validateParameter(valid_594333, JInt, required = false, default = nil)
  if valid_594333 != nil:
    section.add "MaxRecords", valid_594333
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594334 = header.getOrDefault("X-Amz-Signature")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Signature", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Content-Sha256", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Date")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Date", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-Credential")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-Credential", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-Security-Token")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Security-Token", valid_594338
  var valid_594339 = header.getOrDefault("X-Amz-Algorithm")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-Algorithm", valid_594339
  var valid_594340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-SignedHeaders", valid_594340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594341: Call_GetDescribeReservedDBInstancesOfferings_594321;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594341.validator(path, query, header, formData, body)
  let scheme = call_594341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594341.url(scheme.get, call_594341.host, call_594341.base,
                         call_594341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594341, url, valid)

proc call*(call_594342: Call_GetDescribeReservedDBInstancesOfferings_594321;
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
  var query_594343 = newJObject()
  add(query_594343, "Marker", newJString(Marker))
  add(query_594343, "ProductDescription", newJString(ProductDescription))
  add(query_594343, "OfferingType", newJString(OfferingType))
  add(query_594343, "Action", newJString(Action))
  add(query_594343, "MultiAZ", newJBool(MultiAZ))
  add(query_594343, "Duration", newJString(Duration))
  add(query_594343, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594343, "Version", newJString(Version))
  add(query_594343, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594343, "MaxRecords", newJInt(MaxRecords))
  result = call_594342.call(nil, query_594343, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_594321(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_594322, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_594323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_594387 = ref object of OpenApiRestCall_592348
proc url_PostDownloadDBLogFilePortion_594389(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDownloadDBLogFilePortion_594388(path: JsonNode; query: JsonNode;
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
  var valid_594390 = query.getOrDefault("Action")
  valid_594390 = validateParameter(valid_594390, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_594390 != nil:
    section.add "Action", valid_594390
  var valid_594391 = query.getOrDefault("Version")
  valid_594391 = validateParameter(valid_594391, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594391 != nil:
    section.add "Version", valid_594391
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594392 = header.getOrDefault("X-Amz-Signature")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Signature", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Content-Sha256", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Date")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Date", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Credential")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Credential", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Security-Token")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Security-Token", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Algorithm")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Algorithm", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-SignedHeaders", valid_594398
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_594399 = formData.getOrDefault("NumberOfLines")
  valid_594399 = validateParameter(valid_594399, JInt, required = false, default = nil)
  if valid_594399 != nil:
    section.add "NumberOfLines", valid_594399
  var valid_594400 = formData.getOrDefault("Marker")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "Marker", valid_594400
  assert formData != nil,
        "formData argument is necessary due to required `LogFileName` field"
  var valid_594401 = formData.getOrDefault("LogFileName")
  valid_594401 = validateParameter(valid_594401, JString, required = true,
                                 default = nil)
  if valid_594401 != nil:
    section.add "LogFileName", valid_594401
  var valid_594402 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594402 = validateParameter(valid_594402, JString, required = true,
                                 default = nil)
  if valid_594402 != nil:
    section.add "DBInstanceIdentifier", valid_594402
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594403: Call_PostDownloadDBLogFilePortion_594387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594403.validator(path, query, header, formData, body)
  let scheme = call_594403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594403.url(scheme.get, call_594403.host, call_594403.base,
                         call_594403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594403, url, valid)

proc call*(call_594404: Call_PostDownloadDBLogFilePortion_594387;
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
  var query_594405 = newJObject()
  var formData_594406 = newJObject()
  add(formData_594406, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_594406, "Marker", newJString(Marker))
  add(formData_594406, "LogFileName", newJString(LogFileName))
  add(formData_594406, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594405, "Action", newJString(Action))
  add(query_594405, "Version", newJString(Version))
  result = call_594404.call(nil, query_594405, nil, formData_594406, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_594387(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_594388, base: "/",
    url: url_PostDownloadDBLogFilePortion_594389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_594368 = ref object of OpenApiRestCall_592348
proc url_GetDownloadDBLogFilePortion_594370(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDownloadDBLogFilePortion_594369(path: JsonNode; query: JsonNode;
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
  var valid_594371 = query.getOrDefault("Marker")
  valid_594371 = validateParameter(valid_594371, JString, required = false,
                                 default = nil)
  if valid_594371 != nil:
    section.add "Marker", valid_594371
  var valid_594372 = query.getOrDefault("NumberOfLines")
  valid_594372 = validateParameter(valid_594372, JInt, required = false, default = nil)
  if valid_594372 != nil:
    section.add "NumberOfLines", valid_594372
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594373 = query.getOrDefault("DBInstanceIdentifier")
  valid_594373 = validateParameter(valid_594373, JString, required = true,
                                 default = nil)
  if valid_594373 != nil:
    section.add "DBInstanceIdentifier", valid_594373
  var valid_594374 = query.getOrDefault("Action")
  valid_594374 = validateParameter(valid_594374, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_594374 != nil:
    section.add "Action", valid_594374
  var valid_594375 = query.getOrDefault("LogFileName")
  valid_594375 = validateParameter(valid_594375, JString, required = true,
                                 default = nil)
  if valid_594375 != nil:
    section.add "LogFileName", valid_594375
  var valid_594376 = query.getOrDefault("Version")
  valid_594376 = validateParameter(valid_594376, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594376 != nil:
    section.add "Version", valid_594376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594377 = header.getOrDefault("X-Amz-Signature")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Signature", valid_594377
  var valid_594378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "X-Amz-Content-Sha256", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Date")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Date", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Credential")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Credential", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Security-Token")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Security-Token", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Algorithm")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Algorithm", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-SignedHeaders", valid_594383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594384: Call_GetDownloadDBLogFilePortion_594368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594384.validator(path, query, header, formData, body)
  let scheme = call_594384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594384.url(scheme.get, call_594384.host, call_594384.base,
                         call_594384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594384, url, valid)

proc call*(call_594385: Call_GetDownloadDBLogFilePortion_594368;
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
  var query_594386 = newJObject()
  add(query_594386, "Marker", newJString(Marker))
  add(query_594386, "NumberOfLines", newJInt(NumberOfLines))
  add(query_594386, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594386, "Action", newJString(Action))
  add(query_594386, "LogFileName", newJString(LogFileName))
  add(query_594386, "Version", newJString(Version))
  result = call_594385.call(nil, query_594386, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_594368(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_594369, base: "/",
    url: url_GetDownloadDBLogFilePortion_594370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_594423 = ref object of OpenApiRestCall_592348
proc url_PostListTagsForResource_594425(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_594424(path: JsonNode; query: JsonNode;
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
  var valid_594426 = query.getOrDefault("Action")
  valid_594426 = validateParameter(valid_594426, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_594426 != nil:
    section.add "Action", valid_594426
  var valid_594427 = query.getOrDefault("Version")
  valid_594427 = validateParameter(valid_594427, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594427 != nil:
    section.add "Version", valid_594427
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594428 = header.getOrDefault("X-Amz-Signature")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Signature", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Content-Sha256", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Date")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Date", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-Credential")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-Credential", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-Security-Token")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-Security-Token", valid_594432
  var valid_594433 = header.getOrDefault("X-Amz-Algorithm")
  valid_594433 = validateParameter(valid_594433, JString, required = false,
                                 default = nil)
  if valid_594433 != nil:
    section.add "X-Amz-Algorithm", valid_594433
  var valid_594434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594434 = validateParameter(valid_594434, JString, required = false,
                                 default = nil)
  if valid_594434 != nil:
    section.add "X-Amz-SignedHeaders", valid_594434
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_594435 = formData.getOrDefault("ResourceName")
  valid_594435 = validateParameter(valid_594435, JString, required = true,
                                 default = nil)
  if valid_594435 != nil:
    section.add "ResourceName", valid_594435
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594436: Call_PostListTagsForResource_594423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594436.validator(path, query, header, formData, body)
  let scheme = call_594436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594436.url(scheme.get, call_594436.host, call_594436.base,
                         call_594436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594436, url, valid)

proc call*(call_594437: Call_PostListTagsForResource_594423; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_594438 = newJObject()
  var formData_594439 = newJObject()
  add(query_594438, "Action", newJString(Action))
  add(query_594438, "Version", newJString(Version))
  add(formData_594439, "ResourceName", newJString(ResourceName))
  result = call_594437.call(nil, query_594438, nil, formData_594439, nil)

var postListTagsForResource* = Call_PostListTagsForResource_594423(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_594424, base: "/",
    url: url_PostListTagsForResource_594425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_594407 = ref object of OpenApiRestCall_592348
proc url_GetListTagsForResource_594409(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_594408(path: JsonNode; query: JsonNode;
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
  var valid_594410 = query.getOrDefault("ResourceName")
  valid_594410 = validateParameter(valid_594410, JString, required = true,
                                 default = nil)
  if valid_594410 != nil:
    section.add "ResourceName", valid_594410
  var valid_594411 = query.getOrDefault("Action")
  valid_594411 = validateParameter(valid_594411, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_594411 != nil:
    section.add "Action", valid_594411
  var valid_594412 = query.getOrDefault("Version")
  valid_594412 = validateParameter(valid_594412, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594412 != nil:
    section.add "Version", valid_594412
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594413 = header.getOrDefault("X-Amz-Signature")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Signature", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Content-Sha256", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-Date")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Date", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-Credential")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-Credential", valid_594416
  var valid_594417 = header.getOrDefault("X-Amz-Security-Token")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-Security-Token", valid_594417
  var valid_594418 = header.getOrDefault("X-Amz-Algorithm")
  valid_594418 = validateParameter(valid_594418, JString, required = false,
                                 default = nil)
  if valid_594418 != nil:
    section.add "X-Amz-Algorithm", valid_594418
  var valid_594419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594419 = validateParameter(valid_594419, JString, required = false,
                                 default = nil)
  if valid_594419 != nil:
    section.add "X-Amz-SignedHeaders", valid_594419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594420: Call_GetListTagsForResource_594407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594420.validator(path, query, header, formData, body)
  let scheme = call_594420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594420.url(scheme.get, call_594420.host, call_594420.base,
                         call_594420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594420, url, valid)

proc call*(call_594421: Call_GetListTagsForResource_594407; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594422 = newJObject()
  add(query_594422, "ResourceName", newJString(ResourceName))
  add(query_594422, "Action", newJString(Action))
  add(query_594422, "Version", newJString(Version))
  result = call_594421.call(nil, query_594422, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_594407(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_594408, base: "/",
    url: url_GetListTagsForResource_594409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_594473 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBInstance_594475(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_594474(path: JsonNode; query: JsonNode;
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
  var valid_594476 = query.getOrDefault("Action")
  valid_594476 = validateParameter(valid_594476, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_594476 != nil:
    section.add "Action", valid_594476
  var valid_594477 = query.getOrDefault("Version")
  valid_594477 = validateParameter(valid_594477, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594477 != nil:
    section.add "Version", valid_594477
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594478 = header.getOrDefault("X-Amz-Signature")
  valid_594478 = validateParameter(valid_594478, JString, required = false,
                                 default = nil)
  if valid_594478 != nil:
    section.add "X-Amz-Signature", valid_594478
  var valid_594479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594479 = validateParameter(valid_594479, JString, required = false,
                                 default = nil)
  if valid_594479 != nil:
    section.add "X-Amz-Content-Sha256", valid_594479
  var valid_594480 = header.getOrDefault("X-Amz-Date")
  valid_594480 = validateParameter(valid_594480, JString, required = false,
                                 default = nil)
  if valid_594480 != nil:
    section.add "X-Amz-Date", valid_594480
  var valid_594481 = header.getOrDefault("X-Amz-Credential")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-Credential", valid_594481
  var valid_594482 = header.getOrDefault("X-Amz-Security-Token")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "X-Amz-Security-Token", valid_594482
  var valid_594483 = header.getOrDefault("X-Amz-Algorithm")
  valid_594483 = validateParameter(valid_594483, JString, required = false,
                                 default = nil)
  if valid_594483 != nil:
    section.add "X-Amz-Algorithm", valid_594483
  var valid_594484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-SignedHeaders", valid_594484
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
  var valid_594485 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "PreferredMaintenanceWindow", valid_594485
  var valid_594486 = formData.getOrDefault("DBInstanceClass")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "DBInstanceClass", valid_594486
  var valid_594487 = formData.getOrDefault("PreferredBackupWindow")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "PreferredBackupWindow", valid_594487
  var valid_594488 = formData.getOrDefault("MasterUserPassword")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "MasterUserPassword", valid_594488
  var valid_594489 = formData.getOrDefault("MultiAZ")
  valid_594489 = validateParameter(valid_594489, JBool, required = false, default = nil)
  if valid_594489 != nil:
    section.add "MultiAZ", valid_594489
  var valid_594490 = formData.getOrDefault("DBParameterGroupName")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "DBParameterGroupName", valid_594490
  var valid_594491 = formData.getOrDefault("EngineVersion")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "EngineVersion", valid_594491
  var valid_594492 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_594492 = validateParameter(valid_594492, JArray, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "VpcSecurityGroupIds", valid_594492
  var valid_594493 = formData.getOrDefault("BackupRetentionPeriod")
  valid_594493 = validateParameter(valid_594493, JInt, required = false, default = nil)
  if valid_594493 != nil:
    section.add "BackupRetentionPeriod", valid_594493
  var valid_594494 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594494 = validateParameter(valid_594494, JBool, required = false, default = nil)
  if valid_594494 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594494
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594495 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594495 = validateParameter(valid_594495, JString, required = true,
                                 default = nil)
  if valid_594495 != nil:
    section.add "DBInstanceIdentifier", valid_594495
  var valid_594496 = formData.getOrDefault("ApplyImmediately")
  valid_594496 = validateParameter(valid_594496, JBool, required = false, default = nil)
  if valid_594496 != nil:
    section.add "ApplyImmediately", valid_594496
  var valid_594497 = formData.getOrDefault("Iops")
  valid_594497 = validateParameter(valid_594497, JInt, required = false, default = nil)
  if valid_594497 != nil:
    section.add "Iops", valid_594497
  var valid_594498 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_594498 = validateParameter(valid_594498, JBool, required = false, default = nil)
  if valid_594498 != nil:
    section.add "AllowMajorVersionUpgrade", valid_594498
  var valid_594499 = formData.getOrDefault("OptionGroupName")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "OptionGroupName", valid_594499
  var valid_594500 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "NewDBInstanceIdentifier", valid_594500
  var valid_594501 = formData.getOrDefault("DBSecurityGroups")
  valid_594501 = validateParameter(valid_594501, JArray, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "DBSecurityGroups", valid_594501
  var valid_594502 = formData.getOrDefault("AllocatedStorage")
  valid_594502 = validateParameter(valid_594502, JInt, required = false, default = nil)
  if valid_594502 != nil:
    section.add "AllocatedStorage", valid_594502
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594503: Call_PostModifyDBInstance_594473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594503.validator(path, query, header, formData, body)
  let scheme = call_594503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594503.url(scheme.get, call_594503.host, call_594503.base,
                         call_594503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594503, url, valid)

proc call*(call_594504: Call_PostModifyDBInstance_594473;
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
  var query_594505 = newJObject()
  var formData_594506 = newJObject()
  add(formData_594506, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_594506, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594506, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_594506, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_594506, "MultiAZ", newJBool(MultiAZ))
  add(formData_594506, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_594506, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_594506.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_594506, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_594506, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_594506, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594506, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_594506, "Iops", newJInt(Iops))
  add(query_594505, "Action", newJString(Action))
  add(formData_594506, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_594506, "OptionGroupName", newJString(OptionGroupName))
  add(formData_594506, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_594505, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_594506.add "DBSecurityGroups", DBSecurityGroups
  add(formData_594506, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_594504.call(nil, query_594505, nil, formData_594506, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_594473(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_594474, base: "/",
    url: url_PostModifyDBInstance_594475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_594440 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBInstance_594442(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_594441(path: JsonNode; query: JsonNode;
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
  var valid_594443 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "NewDBInstanceIdentifier", valid_594443
  var valid_594444 = query.getOrDefault("DBParameterGroupName")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "DBParameterGroupName", valid_594444
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594445 = query.getOrDefault("DBInstanceIdentifier")
  valid_594445 = validateParameter(valid_594445, JString, required = true,
                                 default = nil)
  if valid_594445 != nil:
    section.add "DBInstanceIdentifier", valid_594445
  var valid_594446 = query.getOrDefault("BackupRetentionPeriod")
  valid_594446 = validateParameter(valid_594446, JInt, required = false, default = nil)
  if valid_594446 != nil:
    section.add "BackupRetentionPeriod", valid_594446
  var valid_594447 = query.getOrDefault("EngineVersion")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "EngineVersion", valid_594447
  var valid_594448 = query.getOrDefault("Action")
  valid_594448 = validateParameter(valid_594448, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_594448 != nil:
    section.add "Action", valid_594448
  var valid_594449 = query.getOrDefault("MultiAZ")
  valid_594449 = validateParameter(valid_594449, JBool, required = false, default = nil)
  if valid_594449 != nil:
    section.add "MultiAZ", valid_594449
  var valid_594450 = query.getOrDefault("DBSecurityGroups")
  valid_594450 = validateParameter(valid_594450, JArray, required = false,
                                 default = nil)
  if valid_594450 != nil:
    section.add "DBSecurityGroups", valid_594450
  var valid_594451 = query.getOrDefault("ApplyImmediately")
  valid_594451 = validateParameter(valid_594451, JBool, required = false, default = nil)
  if valid_594451 != nil:
    section.add "ApplyImmediately", valid_594451
  var valid_594452 = query.getOrDefault("VpcSecurityGroupIds")
  valid_594452 = validateParameter(valid_594452, JArray, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "VpcSecurityGroupIds", valid_594452
  var valid_594453 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_594453 = validateParameter(valid_594453, JBool, required = false, default = nil)
  if valid_594453 != nil:
    section.add "AllowMajorVersionUpgrade", valid_594453
  var valid_594454 = query.getOrDefault("MasterUserPassword")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "MasterUserPassword", valid_594454
  var valid_594455 = query.getOrDefault("OptionGroupName")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "OptionGroupName", valid_594455
  var valid_594456 = query.getOrDefault("Version")
  valid_594456 = validateParameter(valid_594456, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594456 != nil:
    section.add "Version", valid_594456
  var valid_594457 = query.getOrDefault("AllocatedStorage")
  valid_594457 = validateParameter(valid_594457, JInt, required = false, default = nil)
  if valid_594457 != nil:
    section.add "AllocatedStorage", valid_594457
  var valid_594458 = query.getOrDefault("DBInstanceClass")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "DBInstanceClass", valid_594458
  var valid_594459 = query.getOrDefault("PreferredBackupWindow")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "PreferredBackupWindow", valid_594459
  var valid_594460 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "PreferredMaintenanceWindow", valid_594460
  var valid_594461 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594461 = validateParameter(valid_594461, JBool, required = false, default = nil)
  if valid_594461 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594461
  var valid_594462 = query.getOrDefault("Iops")
  valid_594462 = validateParameter(valid_594462, JInt, required = false, default = nil)
  if valid_594462 != nil:
    section.add "Iops", valid_594462
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594463 = header.getOrDefault("X-Amz-Signature")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "X-Amz-Signature", valid_594463
  var valid_594464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594464 = validateParameter(valid_594464, JString, required = false,
                                 default = nil)
  if valid_594464 != nil:
    section.add "X-Amz-Content-Sha256", valid_594464
  var valid_594465 = header.getOrDefault("X-Amz-Date")
  valid_594465 = validateParameter(valid_594465, JString, required = false,
                                 default = nil)
  if valid_594465 != nil:
    section.add "X-Amz-Date", valid_594465
  var valid_594466 = header.getOrDefault("X-Amz-Credential")
  valid_594466 = validateParameter(valid_594466, JString, required = false,
                                 default = nil)
  if valid_594466 != nil:
    section.add "X-Amz-Credential", valid_594466
  var valid_594467 = header.getOrDefault("X-Amz-Security-Token")
  valid_594467 = validateParameter(valid_594467, JString, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "X-Amz-Security-Token", valid_594467
  var valid_594468 = header.getOrDefault("X-Amz-Algorithm")
  valid_594468 = validateParameter(valid_594468, JString, required = false,
                                 default = nil)
  if valid_594468 != nil:
    section.add "X-Amz-Algorithm", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-SignedHeaders", valid_594469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594470: Call_GetModifyDBInstance_594440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594470.validator(path, query, header, formData, body)
  let scheme = call_594470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594470.url(scheme.get, call_594470.host, call_594470.base,
                         call_594470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594470, url, valid)

proc call*(call_594471: Call_GetModifyDBInstance_594440;
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
  var query_594472 = newJObject()
  add(query_594472, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_594472, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594472, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594472, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_594472, "EngineVersion", newJString(EngineVersion))
  add(query_594472, "Action", newJString(Action))
  add(query_594472, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_594472.add "DBSecurityGroups", DBSecurityGroups
  add(query_594472, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_594472.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_594472, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_594472, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_594472, "OptionGroupName", newJString(OptionGroupName))
  add(query_594472, "Version", newJString(Version))
  add(query_594472, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_594472, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594472, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_594472, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_594472, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594472, "Iops", newJInt(Iops))
  result = call_594471.call(nil, query_594472, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_594440(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_594441, base: "/",
    url: url_GetModifyDBInstance_594442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_594524 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBParameterGroup_594526(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_594525(path: JsonNode; query: JsonNode;
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
  var valid_594527 = query.getOrDefault("Action")
  valid_594527 = validateParameter(valid_594527, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_594527 != nil:
    section.add "Action", valid_594527
  var valid_594528 = query.getOrDefault("Version")
  valid_594528 = validateParameter(valid_594528, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594528 != nil:
    section.add "Version", valid_594528
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594529 = header.getOrDefault("X-Amz-Signature")
  valid_594529 = validateParameter(valid_594529, JString, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "X-Amz-Signature", valid_594529
  var valid_594530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594530 = validateParameter(valid_594530, JString, required = false,
                                 default = nil)
  if valid_594530 != nil:
    section.add "X-Amz-Content-Sha256", valid_594530
  var valid_594531 = header.getOrDefault("X-Amz-Date")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Date", valid_594531
  var valid_594532 = header.getOrDefault("X-Amz-Credential")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "X-Amz-Credential", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-Security-Token")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Security-Token", valid_594533
  var valid_594534 = header.getOrDefault("X-Amz-Algorithm")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Algorithm", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-SignedHeaders", valid_594535
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594536 = formData.getOrDefault("DBParameterGroupName")
  valid_594536 = validateParameter(valid_594536, JString, required = true,
                                 default = nil)
  if valid_594536 != nil:
    section.add "DBParameterGroupName", valid_594536
  var valid_594537 = formData.getOrDefault("Parameters")
  valid_594537 = validateParameter(valid_594537, JArray, required = true, default = nil)
  if valid_594537 != nil:
    section.add "Parameters", valid_594537
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594538: Call_PostModifyDBParameterGroup_594524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594538.validator(path, query, header, formData, body)
  let scheme = call_594538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594538.url(scheme.get, call_594538.host, call_594538.base,
                         call_594538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594538, url, valid)

proc call*(call_594539: Call_PostModifyDBParameterGroup_594524;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_594540 = newJObject()
  var formData_594541 = newJObject()
  add(formData_594541, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594540, "Action", newJString(Action))
  if Parameters != nil:
    formData_594541.add "Parameters", Parameters
  add(query_594540, "Version", newJString(Version))
  result = call_594539.call(nil, query_594540, nil, formData_594541, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_594524(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_594525, base: "/",
    url: url_PostModifyDBParameterGroup_594526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_594507 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBParameterGroup_594509(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_594508(path: JsonNode; query: JsonNode;
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
  var valid_594510 = query.getOrDefault("DBParameterGroupName")
  valid_594510 = validateParameter(valid_594510, JString, required = true,
                                 default = nil)
  if valid_594510 != nil:
    section.add "DBParameterGroupName", valid_594510
  var valid_594511 = query.getOrDefault("Parameters")
  valid_594511 = validateParameter(valid_594511, JArray, required = true, default = nil)
  if valid_594511 != nil:
    section.add "Parameters", valid_594511
  var valid_594512 = query.getOrDefault("Action")
  valid_594512 = validateParameter(valid_594512, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_594512 != nil:
    section.add "Action", valid_594512
  var valid_594513 = query.getOrDefault("Version")
  valid_594513 = validateParameter(valid_594513, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594513 != nil:
    section.add "Version", valid_594513
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594514 = header.getOrDefault("X-Amz-Signature")
  valid_594514 = validateParameter(valid_594514, JString, required = false,
                                 default = nil)
  if valid_594514 != nil:
    section.add "X-Amz-Signature", valid_594514
  var valid_594515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594515 = validateParameter(valid_594515, JString, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "X-Amz-Content-Sha256", valid_594515
  var valid_594516 = header.getOrDefault("X-Amz-Date")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "X-Amz-Date", valid_594516
  var valid_594517 = header.getOrDefault("X-Amz-Credential")
  valid_594517 = validateParameter(valid_594517, JString, required = false,
                                 default = nil)
  if valid_594517 != nil:
    section.add "X-Amz-Credential", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-Security-Token")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Security-Token", valid_594518
  var valid_594519 = header.getOrDefault("X-Amz-Algorithm")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Algorithm", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-SignedHeaders", valid_594520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594521: Call_GetModifyDBParameterGroup_594507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594521.validator(path, query, header, formData, body)
  let scheme = call_594521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594521.url(scheme.get, call_594521.host, call_594521.base,
                         call_594521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594521, url, valid)

proc call*(call_594522: Call_GetModifyDBParameterGroup_594507;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594523 = newJObject()
  add(query_594523, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_594523.add "Parameters", Parameters
  add(query_594523, "Action", newJString(Action))
  add(query_594523, "Version", newJString(Version))
  result = call_594522.call(nil, query_594523, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_594507(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_594508, base: "/",
    url: url_GetModifyDBParameterGroup_594509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_594560 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBSubnetGroup_594562(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_594561(path: JsonNode; query: JsonNode;
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
  var valid_594563 = query.getOrDefault("Action")
  valid_594563 = validateParameter(valid_594563, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_594563 != nil:
    section.add "Action", valid_594563
  var valid_594564 = query.getOrDefault("Version")
  valid_594564 = validateParameter(valid_594564, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594564 != nil:
    section.add "Version", valid_594564
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594565 = header.getOrDefault("X-Amz-Signature")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-Signature", valid_594565
  var valid_594566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-Content-Sha256", valid_594566
  var valid_594567 = header.getOrDefault("X-Amz-Date")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-Date", valid_594567
  var valid_594568 = header.getOrDefault("X-Amz-Credential")
  valid_594568 = validateParameter(valid_594568, JString, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "X-Amz-Credential", valid_594568
  var valid_594569 = header.getOrDefault("X-Amz-Security-Token")
  valid_594569 = validateParameter(valid_594569, JString, required = false,
                                 default = nil)
  if valid_594569 != nil:
    section.add "X-Amz-Security-Token", valid_594569
  var valid_594570 = header.getOrDefault("X-Amz-Algorithm")
  valid_594570 = validateParameter(valid_594570, JString, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "X-Amz-Algorithm", valid_594570
  var valid_594571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-SignedHeaders", valid_594571
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_594572 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "DBSubnetGroupDescription", valid_594572
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_594573 = formData.getOrDefault("DBSubnetGroupName")
  valid_594573 = validateParameter(valid_594573, JString, required = true,
                                 default = nil)
  if valid_594573 != nil:
    section.add "DBSubnetGroupName", valid_594573
  var valid_594574 = formData.getOrDefault("SubnetIds")
  valid_594574 = validateParameter(valid_594574, JArray, required = true, default = nil)
  if valid_594574 != nil:
    section.add "SubnetIds", valid_594574
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594575: Call_PostModifyDBSubnetGroup_594560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594575.validator(path, query, header, formData, body)
  let scheme = call_594575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594575.url(scheme.get, call_594575.host, call_594575.base,
                         call_594575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594575, url, valid)

proc call*(call_594576: Call_PostModifyDBSubnetGroup_594560;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_594577 = newJObject()
  var formData_594578 = newJObject()
  add(formData_594578, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594577, "Action", newJString(Action))
  add(formData_594578, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594577, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_594578.add "SubnetIds", SubnetIds
  result = call_594576.call(nil, query_594577, nil, formData_594578, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_594560(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_594561, base: "/",
    url: url_PostModifyDBSubnetGroup_594562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_594542 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBSubnetGroup_594544(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_594543(path: JsonNode; query: JsonNode;
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
  var valid_594545 = query.getOrDefault("SubnetIds")
  valid_594545 = validateParameter(valid_594545, JArray, required = true, default = nil)
  if valid_594545 != nil:
    section.add "SubnetIds", valid_594545
  var valid_594546 = query.getOrDefault("Action")
  valid_594546 = validateParameter(valid_594546, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_594546 != nil:
    section.add "Action", valid_594546
  var valid_594547 = query.getOrDefault("DBSubnetGroupDescription")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "DBSubnetGroupDescription", valid_594547
  var valid_594548 = query.getOrDefault("DBSubnetGroupName")
  valid_594548 = validateParameter(valid_594548, JString, required = true,
                                 default = nil)
  if valid_594548 != nil:
    section.add "DBSubnetGroupName", valid_594548
  var valid_594549 = query.getOrDefault("Version")
  valid_594549 = validateParameter(valid_594549, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594549 != nil:
    section.add "Version", valid_594549
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594550 = header.getOrDefault("X-Amz-Signature")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Signature", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-Content-Sha256", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-Date")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Date", valid_594552
  var valid_594553 = header.getOrDefault("X-Amz-Credential")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-Credential", valid_594553
  var valid_594554 = header.getOrDefault("X-Amz-Security-Token")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "X-Amz-Security-Token", valid_594554
  var valid_594555 = header.getOrDefault("X-Amz-Algorithm")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-Algorithm", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-SignedHeaders", valid_594556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594557: Call_GetModifyDBSubnetGroup_594542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594557.validator(path, query, header, formData, body)
  let scheme = call_594557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594557.url(scheme.get, call_594557.host, call_594557.base,
                         call_594557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594557, url, valid)

proc call*(call_594558: Call_GetModifyDBSubnetGroup_594542; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_594559 = newJObject()
  if SubnetIds != nil:
    query_594559.add "SubnetIds", SubnetIds
  add(query_594559, "Action", newJString(Action))
  add(query_594559, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594559, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594559, "Version", newJString(Version))
  result = call_594558.call(nil, query_594559, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_594542(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_594543, base: "/",
    url: url_GetModifyDBSubnetGroup_594544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_594599 = ref object of OpenApiRestCall_592348
proc url_PostModifyEventSubscription_594601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_594600(path: JsonNode; query: JsonNode;
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
  var valid_594602 = query.getOrDefault("Action")
  valid_594602 = validateParameter(valid_594602, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_594602 != nil:
    section.add "Action", valid_594602
  var valid_594603 = query.getOrDefault("Version")
  valid_594603 = validateParameter(valid_594603, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594603 != nil:
    section.add "Version", valid_594603
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594604 = header.getOrDefault("X-Amz-Signature")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "X-Amz-Signature", valid_594604
  var valid_594605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-Content-Sha256", valid_594605
  var valid_594606 = header.getOrDefault("X-Amz-Date")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-Date", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-Credential")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-Credential", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Security-Token")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Security-Token", valid_594608
  var valid_594609 = header.getOrDefault("X-Amz-Algorithm")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Algorithm", valid_594609
  var valid_594610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-SignedHeaders", valid_594610
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_594611 = formData.getOrDefault("SnsTopicArn")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "SnsTopicArn", valid_594611
  var valid_594612 = formData.getOrDefault("Enabled")
  valid_594612 = validateParameter(valid_594612, JBool, required = false, default = nil)
  if valid_594612 != nil:
    section.add "Enabled", valid_594612
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_594613 = formData.getOrDefault("SubscriptionName")
  valid_594613 = validateParameter(valid_594613, JString, required = true,
                                 default = nil)
  if valid_594613 != nil:
    section.add "SubscriptionName", valid_594613
  var valid_594614 = formData.getOrDefault("SourceType")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "SourceType", valid_594614
  var valid_594615 = formData.getOrDefault("EventCategories")
  valid_594615 = validateParameter(valid_594615, JArray, required = false,
                                 default = nil)
  if valid_594615 != nil:
    section.add "EventCategories", valid_594615
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594616: Call_PostModifyEventSubscription_594599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594616.validator(path, query, header, formData, body)
  let scheme = call_594616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594616.url(scheme.get, call_594616.host, call_594616.base,
                         call_594616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594616, url, valid)

proc call*(call_594617: Call_PostModifyEventSubscription_594599;
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
  var query_594618 = newJObject()
  var formData_594619 = newJObject()
  add(formData_594619, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_594619, "Enabled", newJBool(Enabled))
  add(formData_594619, "SubscriptionName", newJString(SubscriptionName))
  add(formData_594619, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_594619.add "EventCategories", EventCategories
  add(query_594618, "Action", newJString(Action))
  add(query_594618, "Version", newJString(Version))
  result = call_594617.call(nil, query_594618, nil, formData_594619, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_594599(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_594600, base: "/",
    url: url_PostModifyEventSubscription_594601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_594579 = ref object of OpenApiRestCall_592348
proc url_GetModifyEventSubscription_594581(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_594580(path: JsonNode; query: JsonNode;
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
  var valid_594582 = query.getOrDefault("SourceType")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "SourceType", valid_594582
  var valid_594583 = query.getOrDefault("Enabled")
  valid_594583 = validateParameter(valid_594583, JBool, required = false, default = nil)
  if valid_594583 != nil:
    section.add "Enabled", valid_594583
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_594584 = query.getOrDefault("SubscriptionName")
  valid_594584 = validateParameter(valid_594584, JString, required = true,
                                 default = nil)
  if valid_594584 != nil:
    section.add "SubscriptionName", valid_594584
  var valid_594585 = query.getOrDefault("EventCategories")
  valid_594585 = validateParameter(valid_594585, JArray, required = false,
                                 default = nil)
  if valid_594585 != nil:
    section.add "EventCategories", valid_594585
  var valid_594586 = query.getOrDefault("Action")
  valid_594586 = validateParameter(valid_594586, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_594586 != nil:
    section.add "Action", valid_594586
  var valid_594587 = query.getOrDefault("SnsTopicArn")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "SnsTopicArn", valid_594587
  var valid_594588 = query.getOrDefault("Version")
  valid_594588 = validateParameter(valid_594588, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594588 != nil:
    section.add "Version", valid_594588
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594589 = header.getOrDefault("X-Amz-Signature")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "X-Amz-Signature", valid_594589
  var valid_594590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Content-Sha256", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-Date")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Date", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-Credential")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-Credential", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Security-Token")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Security-Token", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Algorithm")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Algorithm", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-SignedHeaders", valid_594595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594596: Call_GetModifyEventSubscription_594579; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594596.validator(path, query, header, formData, body)
  let scheme = call_594596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594596.url(scheme.get, call_594596.host, call_594596.base,
                         call_594596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594596, url, valid)

proc call*(call_594597: Call_GetModifyEventSubscription_594579;
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
  var query_594598 = newJObject()
  add(query_594598, "SourceType", newJString(SourceType))
  add(query_594598, "Enabled", newJBool(Enabled))
  add(query_594598, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_594598.add "EventCategories", EventCategories
  add(query_594598, "Action", newJString(Action))
  add(query_594598, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_594598, "Version", newJString(Version))
  result = call_594597.call(nil, query_594598, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_594579(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_594580, base: "/",
    url: url_GetModifyEventSubscription_594581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_594639 = ref object of OpenApiRestCall_592348
proc url_PostModifyOptionGroup_594641(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_594640(path: JsonNode; query: JsonNode;
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
  var valid_594642 = query.getOrDefault("Action")
  valid_594642 = validateParameter(valid_594642, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_594642 != nil:
    section.add "Action", valid_594642
  var valid_594643 = query.getOrDefault("Version")
  valid_594643 = validateParameter(valid_594643, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594643 != nil:
    section.add "Version", valid_594643
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594644 = header.getOrDefault("X-Amz-Signature")
  valid_594644 = validateParameter(valid_594644, JString, required = false,
                                 default = nil)
  if valid_594644 != nil:
    section.add "X-Amz-Signature", valid_594644
  var valid_594645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594645 = validateParameter(valid_594645, JString, required = false,
                                 default = nil)
  if valid_594645 != nil:
    section.add "X-Amz-Content-Sha256", valid_594645
  var valid_594646 = header.getOrDefault("X-Amz-Date")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "X-Amz-Date", valid_594646
  var valid_594647 = header.getOrDefault("X-Amz-Credential")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "X-Amz-Credential", valid_594647
  var valid_594648 = header.getOrDefault("X-Amz-Security-Token")
  valid_594648 = validateParameter(valid_594648, JString, required = false,
                                 default = nil)
  if valid_594648 != nil:
    section.add "X-Amz-Security-Token", valid_594648
  var valid_594649 = header.getOrDefault("X-Amz-Algorithm")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "X-Amz-Algorithm", valid_594649
  var valid_594650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594650 = validateParameter(valid_594650, JString, required = false,
                                 default = nil)
  if valid_594650 != nil:
    section.add "X-Amz-SignedHeaders", valid_594650
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_594651 = formData.getOrDefault("OptionsToRemove")
  valid_594651 = validateParameter(valid_594651, JArray, required = false,
                                 default = nil)
  if valid_594651 != nil:
    section.add "OptionsToRemove", valid_594651
  var valid_594652 = formData.getOrDefault("ApplyImmediately")
  valid_594652 = validateParameter(valid_594652, JBool, required = false, default = nil)
  if valid_594652 != nil:
    section.add "ApplyImmediately", valid_594652
  var valid_594653 = formData.getOrDefault("OptionsToInclude")
  valid_594653 = validateParameter(valid_594653, JArray, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "OptionsToInclude", valid_594653
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_594654 = formData.getOrDefault("OptionGroupName")
  valid_594654 = validateParameter(valid_594654, JString, required = true,
                                 default = nil)
  if valid_594654 != nil:
    section.add "OptionGroupName", valid_594654
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594655: Call_PostModifyOptionGroup_594639; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594655.validator(path, query, header, formData, body)
  let scheme = call_594655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594655.url(scheme.get, call_594655.host, call_594655.base,
                         call_594655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594655, url, valid)

proc call*(call_594656: Call_PostModifyOptionGroup_594639; OptionGroupName: string;
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
  var query_594657 = newJObject()
  var formData_594658 = newJObject()
  if OptionsToRemove != nil:
    formData_594658.add "OptionsToRemove", OptionsToRemove
  add(formData_594658, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_594658.add "OptionsToInclude", OptionsToInclude
  add(query_594657, "Action", newJString(Action))
  add(formData_594658, "OptionGroupName", newJString(OptionGroupName))
  add(query_594657, "Version", newJString(Version))
  result = call_594656.call(nil, query_594657, nil, formData_594658, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_594639(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_594640, base: "/",
    url: url_PostModifyOptionGroup_594641, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_594620 = ref object of OpenApiRestCall_592348
proc url_GetModifyOptionGroup_594622(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_594621(path: JsonNode; query: JsonNode;
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
  var valid_594623 = query.getOrDefault("Action")
  valid_594623 = validateParameter(valid_594623, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_594623 != nil:
    section.add "Action", valid_594623
  var valid_594624 = query.getOrDefault("ApplyImmediately")
  valid_594624 = validateParameter(valid_594624, JBool, required = false, default = nil)
  if valid_594624 != nil:
    section.add "ApplyImmediately", valid_594624
  var valid_594625 = query.getOrDefault("OptionsToRemove")
  valid_594625 = validateParameter(valid_594625, JArray, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "OptionsToRemove", valid_594625
  var valid_594626 = query.getOrDefault("OptionsToInclude")
  valid_594626 = validateParameter(valid_594626, JArray, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "OptionsToInclude", valid_594626
  var valid_594627 = query.getOrDefault("OptionGroupName")
  valid_594627 = validateParameter(valid_594627, JString, required = true,
                                 default = nil)
  if valid_594627 != nil:
    section.add "OptionGroupName", valid_594627
  var valid_594628 = query.getOrDefault("Version")
  valid_594628 = validateParameter(valid_594628, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594628 != nil:
    section.add "Version", valid_594628
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594629 = header.getOrDefault("X-Amz-Signature")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "X-Amz-Signature", valid_594629
  var valid_594630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "X-Amz-Content-Sha256", valid_594630
  var valid_594631 = header.getOrDefault("X-Amz-Date")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-Date", valid_594631
  var valid_594632 = header.getOrDefault("X-Amz-Credential")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "X-Amz-Credential", valid_594632
  var valid_594633 = header.getOrDefault("X-Amz-Security-Token")
  valid_594633 = validateParameter(valid_594633, JString, required = false,
                                 default = nil)
  if valid_594633 != nil:
    section.add "X-Amz-Security-Token", valid_594633
  var valid_594634 = header.getOrDefault("X-Amz-Algorithm")
  valid_594634 = validateParameter(valid_594634, JString, required = false,
                                 default = nil)
  if valid_594634 != nil:
    section.add "X-Amz-Algorithm", valid_594634
  var valid_594635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594635 = validateParameter(valid_594635, JString, required = false,
                                 default = nil)
  if valid_594635 != nil:
    section.add "X-Amz-SignedHeaders", valid_594635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594636: Call_GetModifyOptionGroup_594620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594636.validator(path, query, header, formData, body)
  let scheme = call_594636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594636.url(scheme.get, call_594636.host, call_594636.base,
                         call_594636.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594636, url, valid)

proc call*(call_594637: Call_GetModifyOptionGroup_594620; OptionGroupName: string;
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
  var query_594638 = newJObject()
  add(query_594638, "Action", newJString(Action))
  add(query_594638, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_594638.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_594638.add "OptionsToInclude", OptionsToInclude
  add(query_594638, "OptionGroupName", newJString(OptionGroupName))
  add(query_594638, "Version", newJString(Version))
  result = call_594637.call(nil, query_594638, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_594620(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_594621, base: "/",
    url: url_GetModifyOptionGroup_594622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_594677 = ref object of OpenApiRestCall_592348
proc url_PostPromoteReadReplica_594679(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_594678(path: JsonNode; query: JsonNode;
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
  var valid_594680 = query.getOrDefault("Action")
  valid_594680 = validateParameter(valid_594680, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_594680 != nil:
    section.add "Action", valid_594680
  var valid_594681 = query.getOrDefault("Version")
  valid_594681 = validateParameter(valid_594681, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594681 != nil:
    section.add "Version", valid_594681
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594682 = header.getOrDefault("X-Amz-Signature")
  valid_594682 = validateParameter(valid_594682, JString, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "X-Amz-Signature", valid_594682
  var valid_594683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594683 = validateParameter(valid_594683, JString, required = false,
                                 default = nil)
  if valid_594683 != nil:
    section.add "X-Amz-Content-Sha256", valid_594683
  var valid_594684 = header.getOrDefault("X-Amz-Date")
  valid_594684 = validateParameter(valid_594684, JString, required = false,
                                 default = nil)
  if valid_594684 != nil:
    section.add "X-Amz-Date", valid_594684
  var valid_594685 = header.getOrDefault("X-Amz-Credential")
  valid_594685 = validateParameter(valid_594685, JString, required = false,
                                 default = nil)
  if valid_594685 != nil:
    section.add "X-Amz-Credential", valid_594685
  var valid_594686 = header.getOrDefault("X-Amz-Security-Token")
  valid_594686 = validateParameter(valid_594686, JString, required = false,
                                 default = nil)
  if valid_594686 != nil:
    section.add "X-Amz-Security-Token", valid_594686
  var valid_594687 = header.getOrDefault("X-Amz-Algorithm")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "X-Amz-Algorithm", valid_594687
  var valid_594688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594688 = validateParameter(valid_594688, JString, required = false,
                                 default = nil)
  if valid_594688 != nil:
    section.add "X-Amz-SignedHeaders", valid_594688
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_594689 = formData.getOrDefault("PreferredBackupWindow")
  valid_594689 = validateParameter(valid_594689, JString, required = false,
                                 default = nil)
  if valid_594689 != nil:
    section.add "PreferredBackupWindow", valid_594689
  var valid_594690 = formData.getOrDefault("BackupRetentionPeriod")
  valid_594690 = validateParameter(valid_594690, JInt, required = false, default = nil)
  if valid_594690 != nil:
    section.add "BackupRetentionPeriod", valid_594690
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594691 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594691 = validateParameter(valid_594691, JString, required = true,
                                 default = nil)
  if valid_594691 != nil:
    section.add "DBInstanceIdentifier", valid_594691
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594692: Call_PostPromoteReadReplica_594677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594692.validator(path, query, header, formData, body)
  let scheme = call_594692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594692.url(scheme.get, call_594692.host, call_594692.base,
                         call_594692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594692, url, valid)

proc call*(call_594693: Call_PostPromoteReadReplica_594677;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2013-02-12"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594694 = newJObject()
  var formData_594695 = newJObject()
  add(formData_594695, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_594695, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_594695, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594694, "Action", newJString(Action))
  add(query_594694, "Version", newJString(Version))
  result = call_594693.call(nil, query_594694, nil, formData_594695, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_594677(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_594678, base: "/",
    url: url_PostPromoteReadReplica_594679, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_594659 = ref object of OpenApiRestCall_592348
proc url_GetPromoteReadReplica_594661(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_594660(path: JsonNode; query: JsonNode;
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
  var valid_594662 = query.getOrDefault("DBInstanceIdentifier")
  valid_594662 = validateParameter(valid_594662, JString, required = true,
                                 default = nil)
  if valid_594662 != nil:
    section.add "DBInstanceIdentifier", valid_594662
  var valid_594663 = query.getOrDefault("BackupRetentionPeriod")
  valid_594663 = validateParameter(valid_594663, JInt, required = false, default = nil)
  if valid_594663 != nil:
    section.add "BackupRetentionPeriod", valid_594663
  var valid_594664 = query.getOrDefault("Action")
  valid_594664 = validateParameter(valid_594664, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_594664 != nil:
    section.add "Action", valid_594664
  var valid_594665 = query.getOrDefault("Version")
  valid_594665 = validateParameter(valid_594665, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594665 != nil:
    section.add "Version", valid_594665
  var valid_594666 = query.getOrDefault("PreferredBackupWindow")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "PreferredBackupWindow", valid_594666
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594667 = header.getOrDefault("X-Amz-Signature")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-Signature", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Content-Sha256", valid_594668
  var valid_594669 = header.getOrDefault("X-Amz-Date")
  valid_594669 = validateParameter(valid_594669, JString, required = false,
                                 default = nil)
  if valid_594669 != nil:
    section.add "X-Amz-Date", valid_594669
  var valid_594670 = header.getOrDefault("X-Amz-Credential")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "X-Amz-Credential", valid_594670
  var valid_594671 = header.getOrDefault("X-Amz-Security-Token")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "X-Amz-Security-Token", valid_594671
  var valid_594672 = header.getOrDefault("X-Amz-Algorithm")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "X-Amz-Algorithm", valid_594672
  var valid_594673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "X-Amz-SignedHeaders", valid_594673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594674: Call_GetPromoteReadReplica_594659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594674.validator(path, query, header, formData, body)
  let scheme = call_594674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594674.url(scheme.get, call_594674.host, call_594674.base,
                         call_594674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594674, url, valid)

proc call*(call_594675: Call_GetPromoteReadReplica_594659;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2013-02-12";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_594676 = newJObject()
  add(query_594676, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594676, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_594676, "Action", newJString(Action))
  add(query_594676, "Version", newJString(Version))
  add(query_594676, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_594675.call(nil, query_594676, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_594659(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_594660, base: "/",
    url: url_GetPromoteReadReplica_594661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_594714 = ref object of OpenApiRestCall_592348
proc url_PostPurchaseReservedDBInstancesOffering_594716(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_594715(path: JsonNode;
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
  var valid_594717 = query.getOrDefault("Action")
  valid_594717 = validateParameter(valid_594717, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_594717 != nil:
    section.add "Action", valid_594717
  var valid_594718 = query.getOrDefault("Version")
  valid_594718 = validateParameter(valid_594718, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594718 != nil:
    section.add "Version", valid_594718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594719 = header.getOrDefault("X-Amz-Signature")
  valid_594719 = validateParameter(valid_594719, JString, required = false,
                                 default = nil)
  if valid_594719 != nil:
    section.add "X-Amz-Signature", valid_594719
  var valid_594720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594720 = validateParameter(valid_594720, JString, required = false,
                                 default = nil)
  if valid_594720 != nil:
    section.add "X-Amz-Content-Sha256", valid_594720
  var valid_594721 = header.getOrDefault("X-Amz-Date")
  valid_594721 = validateParameter(valid_594721, JString, required = false,
                                 default = nil)
  if valid_594721 != nil:
    section.add "X-Amz-Date", valid_594721
  var valid_594722 = header.getOrDefault("X-Amz-Credential")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "X-Amz-Credential", valid_594722
  var valid_594723 = header.getOrDefault("X-Amz-Security-Token")
  valid_594723 = validateParameter(valid_594723, JString, required = false,
                                 default = nil)
  if valid_594723 != nil:
    section.add "X-Amz-Security-Token", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-Algorithm")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-Algorithm", valid_594724
  var valid_594725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-SignedHeaders", valid_594725
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_594726 = formData.getOrDefault("ReservedDBInstanceId")
  valid_594726 = validateParameter(valid_594726, JString, required = false,
                                 default = nil)
  if valid_594726 != nil:
    section.add "ReservedDBInstanceId", valid_594726
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_594727 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594727 = validateParameter(valid_594727, JString, required = true,
                                 default = nil)
  if valid_594727 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594727
  var valid_594728 = formData.getOrDefault("DBInstanceCount")
  valid_594728 = validateParameter(valid_594728, JInt, required = false, default = nil)
  if valid_594728 != nil:
    section.add "DBInstanceCount", valid_594728
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594729: Call_PostPurchaseReservedDBInstancesOffering_594714;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594729.validator(path, query, header, formData, body)
  let scheme = call_594729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594729.url(scheme.get, call_594729.host, call_594729.base,
                         call_594729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594729, url, valid)

proc call*(call_594730: Call_PostPurchaseReservedDBInstancesOffering_594714;
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
  var query_594731 = newJObject()
  var formData_594732 = newJObject()
  add(formData_594732, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_594731, "Action", newJString(Action))
  add(formData_594732, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594731, "Version", newJString(Version))
  add(formData_594732, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_594730.call(nil, query_594731, nil, formData_594732, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_594714(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_594715, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_594716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_594696 = ref object of OpenApiRestCall_592348
proc url_GetPurchaseReservedDBInstancesOffering_594698(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_594697(path: JsonNode;
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
  var valid_594699 = query.getOrDefault("DBInstanceCount")
  valid_594699 = validateParameter(valid_594699, JInt, required = false, default = nil)
  if valid_594699 != nil:
    section.add "DBInstanceCount", valid_594699
  var valid_594700 = query.getOrDefault("ReservedDBInstanceId")
  valid_594700 = validateParameter(valid_594700, JString, required = false,
                                 default = nil)
  if valid_594700 != nil:
    section.add "ReservedDBInstanceId", valid_594700
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594701 = query.getOrDefault("Action")
  valid_594701 = validateParameter(valid_594701, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_594701 != nil:
    section.add "Action", valid_594701
  var valid_594702 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594702 = validateParameter(valid_594702, JString, required = true,
                                 default = nil)
  if valid_594702 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594702
  var valid_594703 = query.getOrDefault("Version")
  valid_594703 = validateParameter(valid_594703, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594703 != nil:
    section.add "Version", valid_594703
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594704 = header.getOrDefault("X-Amz-Signature")
  valid_594704 = validateParameter(valid_594704, JString, required = false,
                                 default = nil)
  if valid_594704 != nil:
    section.add "X-Amz-Signature", valid_594704
  var valid_594705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594705 = validateParameter(valid_594705, JString, required = false,
                                 default = nil)
  if valid_594705 != nil:
    section.add "X-Amz-Content-Sha256", valid_594705
  var valid_594706 = header.getOrDefault("X-Amz-Date")
  valid_594706 = validateParameter(valid_594706, JString, required = false,
                                 default = nil)
  if valid_594706 != nil:
    section.add "X-Amz-Date", valid_594706
  var valid_594707 = header.getOrDefault("X-Amz-Credential")
  valid_594707 = validateParameter(valid_594707, JString, required = false,
                                 default = nil)
  if valid_594707 != nil:
    section.add "X-Amz-Credential", valid_594707
  var valid_594708 = header.getOrDefault("X-Amz-Security-Token")
  valid_594708 = validateParameter(valid_594708, JString, required = false,
                                 default = nil)
  if valid_594708 != nil:
    section.add "X-Amz-Security-Token", valid_594708
  var valid_594709 = header.getOrDefault("X-Amz-Algorithm")
  valid_594709 = validateParameter(valid_594709, JString, required = false,
                                 default = nil)
  if valid_594709 != nil:
    section.add "X-Amz-Algorithm", valid_594709
  var valid_594710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594710 = validateParameter(valid_594710, JString, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "X-Amz-SignedHeaders", valid_594710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594711: Call_GetPurchaseReservedDBInstancesOffering_594696;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594711.validator(path, query, header, formData, body)
  let scheme = call_594711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594711.url(scheme.get, call_594711.host, call_594711.base,
                         call_594711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594711, url, valid)

proc call*(call_594712: Call_GetPurchaseReservedDBInstancesOffering_594696;
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
  var query_594713 = newJObject()
  add(query_594713, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_594713, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_594713, "Action", newJString(Action))
  add(query_594713, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594713, "Version", newJString(Version))
  result = call_594712.call(nil, query_594713, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_594696(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_594697, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_594698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_594750 = ref object of OpenApiRestCall_592348
proc url_PostRebootDBInstance_594752(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_594751(path: JsonNode; query: JsonNode;
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
  var valid_594753 = query.getOrDefault("Action")
  valid_594753 = validateParameter(valid_594753, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_594753 != nil:
    section.add "Action", valid_594753
  var valid_594754 = query.getOrDefault("Version")
  valid_594754 = validateParameter(valid_594754, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594754 != nil:
    section.add "Version", valid_594754
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594755 = header.getOrDefault("X-Amz-Signature")
  valid_594755 = validateParameter(valid_594755, JString, required = false,
                                 default = nil)
  if valid_594755 != nil:
    section.add "X-Amz-Signature", valid_594755
  var valid_594756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "X-Amz-Content-Sha256", valid_594756
  var valid_594757 = header.getOrDefault("X-Amz-Date")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-Date", valid_594757
  var valid_594758 = header.getOrDefault("X-Amz-Credential")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "X-Amz-Credential", valid_594758
  var valid_594759 = header.getOrDefault("X-Amz-Security-Token")
  valid_594759 = validateParameter(valid_594759, JString, required = false,
                                 default = nil)
  if valid_594759 != nil:
    section.add "X-Amz-Security-Token", valid_594759
  var valid_594760 = header.getOrDefault("X-Amz-Algorithm")
  valid_594760 = validateParameter(valid_594760, JString, required = false,
                                 default = nil)
  if valid_594760 != nil:
    section.add "X-Amz-Algorithm", valid_594760
  var valid_594761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "X-Amz-SignedHeaders", valid_594761
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_594762 = formData.getOrDefault("ForceFailover")
  valid_594762 = validateParameter(valid_594762, JBool, required = false, default = nil)
  if valid_594762 != nil:
    section.add "ForceFailover", valid_594762
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594763 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594763 = validateParameter(valid_594763, JString, required = true,
                                 default = nil)
  if valid_594763 != nil:
    section.add "DBInstanceIdentifier", valid_594763
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594764: Call_PostRebootDBInstance_594750; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594764.validator(path, query, header, formData, body)
  let scheme = call_594764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594764.url(scheme.get, call_594764.host, call_594764.base,
                         call_594764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594764, url, valid)

proc call*(call_594765: Call_PostRebootDBInstance_594750;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-02-12"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594766 = newJObject()
  var formData_594767 = newJObject()
  add(formData_594767, "ForceFailover", newJBool(ForceFailover))
  add(formData_594767, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594766, "Action", newJString(Action))
  add(query_594766, "Version", newJString(Version))
  result = call_594765.call(nil, query_594766, nil, formData_594767, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_594750(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_594751, base: "/",
    url: url_PostRebootDBInstance_594752, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_594733 = ref object of OpenApiRestCall_592348
proc url_GetRebootDBInstance_594735(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_594734(path: JsonNode; query: JsonNode;
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
  var valid_594736 = query.getOrDefault("ForceFailover")
  valid_594736 = validateParameter(valid_594736, JBool, required = false, default = nil)
  if valid_594736 != nil:
    section.add "ForceFailover", valid_594736
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594737 = query.getOrDefault("DBInstanceIdentifier")
  valid_594737 = validateParameter(valid_594737, JString, required = true,
                                 default = nil)
  if valid_594737 != nil:
    section.add "DBInstanceIdentifier", valid_594737
  var valid_594738 = query.getOrDefault("Action")
  valid_594738 = validateParameter(valid_594738, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_594738 != nil:
    section.add "Action", valid_594738
  var valid_594739 = query.getOrDefault("Version")
  valid_594739 = validateParameter(valid_594739, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594739 != nil:
    section.add "Version", valid_594739
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594740 = header.getOrDefault("X-Amz-Signature")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "X-Amz-Signature", valid_594740
  var valid_594741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "X-Amz-Content-Sha256", valid_594741
  var valid_594742 = header.getOrDefault("X-Amz-Date")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "X-Amz-Date", valid_594742
  var valid_594743 = header.getOrDefault("X-Amz-Credential")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Credential", valid_594743
  var valid_594744 = header.getOrDefault("X-Amz-Security-Token")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "X-Amz-Security-Token", valid_594744
  var valid_594745 = header.getOrDefault("X-Amz-Algorithm")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "X-Amz-Algorithm", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-SignedHeaders", valid_594746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594747: Call_GetRebootDBInstance_594733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594747.validator(path, query, header, formData, body)
  let scheme = call_594747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594747.url(scheme.get, call_594747.host, call_594747.base,
                         call_594747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594747, url, valid)

proc call*(call_594748: Call_GetRebootDBInstance_594733;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-02-12"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594749 = newJObject()
  add(query_594749, "ForceFailover", newJBool(ForceFailover))
  add(query_594749, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594749, "Action", newJString(Action))
  add(query_594749, "Version", newJString(Version))
  result = call_594748.call(nil, query_594749, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_594733(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_594734, base: "/",
    url: url_GetRebootDBInstance_594735, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_594785 = ref object of OpenApiRestCall_592348
proc url_PostRemoveSourceIdentifierFromSubscription_594787(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_594786(path: JsonNode;
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
  var valid_594788 = query.getOrDefault("Action")
  valid_594788 = validateParameter(valid_594788, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_594788 != nil:
    section.add "Action", valid_594788
  var valid_594789 = query.getOrDefault("Version")
  valid_594789 = validateParameter(valid_594789, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594789 != nil:
    section.add "Version", valid_594789
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594790 = header.getOrDefault("X-Amz-Signature")
  valid_594790 = validateParameter(valid_594790, JString, required = false,
                                 default = nil)
  if valid_594790 != nil:
    section.add "X-Amz-Signature", valid_594790
  var valid_594791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594791 = validateParameter(valid_594791, JString, required = false,
                                 default = nil)
  if valid_594791 != nil:
    section.add "X-Amz-Content-Sha256", valid_594791
  var valid_594792 = header.getOrDefault("X-Amz-Date")
  valid_594792 = validateParameter(valid_594792, JString, required = false,
                                 default = nil)
  if valid_594792 != nil:
    section.add "X-Amz-Date", valid_594792
  var valid_594793 = header.getOrDefault("X-Amz-Credential")
  valid_594793 = validateParameter(valid_594793, JString, required = false,
                                 default = nil)
  if valid_594793 != nil:
    section.add "X-Amz-Credential", valid_594793
  var valid_594794 = header.getOrDefault("X-Amz-Security-Token")
  valid_594794 = validateParameter(valid_594794, JString, required = false,
                                 default = nil)
  if valid_594794 != nil:
    section.add "X-Amz-Security-Token", valid_594794
  var valid_594795 = header.getOrDefault("X-Amz-Algorithm")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-Algorithm", valid_594795
  var valid_594796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-SignedHeaders", valid_594796
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_594797 = formData.getOrDefault("SubscriptionName")
  valid_594797 = validateParameter(valid_594797, JString, required = true,
                                 default = nil)
  if valid_594797 != nil:
    section.add "SubscriptionName", valid_594797
  var valid_594798 = formData.getOrDefault("SourceIdentifier")
  valid_594798 = validateParameter(valid_594798, JString, required = true,
                                 default = nil)
  if valid_594798 != nil:
    section.add "SourceIdentifier", valid_594798
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594799: Call_PostRemoveSourceIdentifierFromSubscription_594785;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594799.validator(path, query, header, formData, body)
  let scheme = call_594799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594799.url(scheme.get, call_594799.host, call_594799.base,
                         call_594799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594799, url, valid)

proc call*(call_594800: Call_PostRemoveSourceIdentifierFromSubscription_594785;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594801 = newJObject()
  var formData_594802 = newJObject()
  add(formData_594802, "SubscriptionName", newJString(SubscriptionName))
  add(formData_594802, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_594801, "Action", newJString(Action))
  add(query_594801, "Version", newJString(Version))
  result = call_594800.call(nil, query_594801, nil, formData_594802, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_594785(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_594786,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_594787,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_594768 = ref object of OpenApiRestCall_592348
proc url_GetRemoveSourceIdentifierFromSubscription_594770(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_594769(path: JsonNode;
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
  var valid_594771 = query.getOrDefault("SourceIdentifier")
  valid_594771 = validateParameter(valid_594771, JString, required = true,
                                 default = nil)
  if valid_594771 != nil:
    section.add "SourceIdentifier", valid_594771
  var valid_594772 = query.getOrDefault("SubscriptionName")
  valid_594772 = validateParameter(valid_594772, JString, required = true,
                                 default = nil)
  if valid_594772 != nil:
    section.add "SubscriptionName", valid_594772
  var valid_594773 = query.getOrDefault("Action")
  valid_594773 = validateParameter(valid_594773, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_594773 != nil:
    section.add "Action", valid_594773
  var valid_594774 = query.getOrDefault("Version")
  valid_594774 = validateParameter(valid_594774, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594774 != nil:
    section.add "Version", valid_594774
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594775 = header.getOrDefault("X-Amz-Signature")
  valid_594775 = validateParameter(valid_594775, JString, required = false,
                                 default = nil)
  if valid_594775 != nil:
    section.add "X-Amz-Signature", valid_594775
  var valid_594776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594776 = validateParameter(valid_594776, JString, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "X-Amz-Content-Sha256", valid_594776
  var valid_594777 = header.getOrDefault("X-Amz-Date")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "X-Amz-Date", valid_594777
  var valid_594778 = header.getOrDefault("X-Amz-Credential")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "X-Amz-Credential", valid_594778
  var valid_594779 = header.getOrDefault("X-Amz-Security-Token")
  valid_594779 = validateParameter(valid_594779, JString, required = false,
                                 default = nil)
  if valid_594779 != nil:
    section.add "X-Amz-Security-Token", valid_594779
  var valid_594780 = header.getOrDefault("X-Amz-Algorithm")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "X-Amz-Algorithm", valid_594780
  var valid_594781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-SignedHeaders", valid_594781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594782: Call_GetRemoveSourceIdentifierFromSubscription_594768;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594782.validator(path, query, header, formData, body)
  let scheme = call_594782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594782.url(scheme.get, call_594782.host, call_594782.base,
                         call_594782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594782, url, valid)

proc call*(call_594783: Call_GetRemoveSourceIdentifierFromSubscription_594768;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594784 = newJObject()
  add(query_594784, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_594784, "SubscriptionName", newJString(SubscriptionName))
  add(query_594784, "Action", newJString(Action))
  add(query_594784, "Version", newJString(Version))
  result = call_594783.call(nil, query_594784, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_594768(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_594769,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_594770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_594820 = ref object of OpenApiRestCall_592348
proc url_PostRemoveTagsFromResource_594822(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_594821(path: JsonNode; query: JsonNode;
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
  var valid_594823 = query.getOrDefault("Action")
  valid_594823 = validateParameter(valid_594823, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_594823 != nil:
    section.add "Action", valid_594823
  var valid_594824 = query.getOrDefault("Version")
  valid_594824 = validateParameter(valid_594824, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594824 != nil:
    section.add "Version", valid_594824
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594825 = header.getOrDefault("X-Amz-Signature")
  valid_594825 = validateParameter(valid_594825, JString, required = false,
                                 default = nil)
  if valid_594825 != nil:
    section.add "X-Amz-Signature", valid_594825
  var valid_594826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "X-Amz-Content-Sha256", valid_594826
  var valid_594827 = header.getOrDefault("X-Amz-Date")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "X-Amz-Date", valid_594827
  var valid_594828 = header.getOrDefault("X-Amz-Credential")
  valid_594828 = validateParameter(valid_594828, JString, required = false,
                                 default = nil)
  if valid_594828 != nil:
    section.add "X-Amz-Credential", valid_594828
  var valid_594829 = header.getOrDefault("X-Amz-Security-Token")
  valid_594829 = validateParameter(valid_594829, JString, required = false,
                                 default = nil)
  if valid_594829 != nil:
    section.add "X-Amz-Security-Token", valid_594829
  var valid_594830 = header.getOrDefault("X-Amz-Algorithm")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-Algorithm", valid_594830
  var valid_594831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594831 = validateParameter(valid_594831, JString, required = false,
                                 default = nil)
  if valid_594831 != nil:
    section.add "X-Amz-SignedHeaders", valid_594831
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_594832 = formData.getOrDefault("TagKeys")
  valid_594832 = validateParameter(valid_594832, JArray, required = true, default = nil)
  if valid_594832 != nil:
    section.add "TagKeys", valid_594832
  var valid_594833 = formData.getOrDefault("ResourceName")
  valid_594833 = validateParameter(valid_594833, JString, required = true,
                                 default = nil)
  if valid_594833 != nil:
    section.add "ResourceName", valid_594833
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594834: Call_PostRemoveTagsFromResource_594820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594834.validator(path, query, header, formData, body)
  let scheme = call_594834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594834.url(scheme.get, call_594834.host, call_594834.base,
                         call_594834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594834, url, valid)

proc call*(call_594835: Call_PostRemoveTagsFromResource_594820; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_594836 = newJObject()
  var formData_594837 = newJObject()
  if TagKeys != nil:
    formData_594837.add "TagKeys", TagKeys
  add(query_594836, "Action", newJString(Action))
  add(query_594836, "Version", newJString(Version))
  add(formData_594837, "ResourceName", newJString(ResourceName))
  result = call_594835.call(nil, query_594836, nil, formData_594837, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_594820(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_594821, base: "/",
    url: url_PostRemoveTagsFromResource_594822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_594803 = ref object of OpenApiRestCall_592348
proc url_GetRemoveTagsFromResource_594805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_594804(path: JsonNode; query: JsonNode;
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
  var valid_594806 = query.getOrDefault("ResourceName")
  valid_594806 = validateParameter(valid_594806, JString, required = true,
                                 default = nil)
  if valid_594806 != nil:
    section.add "ResourceName", valid_594806
  var valid_594807 = query.getOrDefault("TagKeys")
  valid_594807 = validateParameter(valid_594807, JArray, required = true, default = nil)
  if valid_594807 != nil:
    section.add "TagKeys", valid_594807
  var valid_594808 = query.getOrDefault("Action")
  valid_594808 = validateParameter(valid_594808, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_594808 != nil:
    section.add "Action", valid_594808
  var valid_594809 = query.getOrDefault("Version")
  valid_594809 = validateParameter(valid_594809, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594809 != nil:
    section.add "Version", valid_594809
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594810 = header.getOrDefault("X-Amz-Signature")
  valid_594810 = validateParameter(valid_594810, JString, required = false,
                                 default = nil)
  if valid_594810 != nil:
    section.add "X-Amz-Signature", valid_594810
  var valid_594811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594811 = validateParameter(valid_594811, JString, required = false,
                                 default = nil)
  if valid_594811 != nil:
    section.add "X-Amz-Content-Sha256", valid_594811
  var valid_594812 = header.getOrDefault("X-Amz-Date")
  valid_594812 = validateParameter(valid_594812, JString, required = false,
                                 default = nil)
  if valid_594812 != nil:
    section.add "X-Amz-Date", valid_594812
  var valid_594813 = header.getOrDefault("X-Amz-Credential")
  valid_594813 = validateParameter(valid_594813, JString, required = false,
                                 default = nil)
  if valid_594813 != nil:
    section.add "X-Amz-Credential", valid_594813
  var valid_594814 = header.getOrDefault("X-Amz-Security-Token")
  valid_594814 = validateParameter(valid_594814, JString, required = false,
                                 default = nil)
  if valid_594814 != nil:
    section.add "X-Amz-Security-Token", valid_594814
  var valid_594815 = header.getOrDefault("X-Amz-Algorithm")
  valid_594815 = validateParameter(valid_594815, JString, required = false,
                                 default = nil)
  if valid_594815 != nil:
    section.add "X-Amz-Algorithm", valid_594815
  var valid_594816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594816 = validateParameter(valid_594816, JString, required = false,
                                 default = nil)
  if valid_594816 != nil:
    section.add "X-Amz-SignedHeaders", valid_594816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594817: Call_GetRemoveTagsFromResource_594803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594817.validator(path, query, header, formData, body)
  let scheme = call_594817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594817.url(scheme.get, call_594817.host, call_594817.base,
                         call_594817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594817, url, valid)

proc call*(call_594818: Call_GetRemoveTagsFromResource_594803;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-02-12"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594819 = newJObject()
  add(query_594819, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_594819.add "TagKeys", TagKeys
  add(query_594819, "Action", newJString(Action))
  add(query_594819, "Version", newJString(Version))
  result = call_594818.call(nil, query_594819, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_594803(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_594804, base: "/",
    url: url_GetRemoveTagsFromResource_594805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_594856 = ref object of OpenApiRestCall_592348
proc url_PostResetDBParameterGroup_594858(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_594857(path: JsonNode; query: JsonNode;
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
  var valid_594859 = query.getOrDefault("Action")
  valid_594859 = validateParameter(valid_594859, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_594859 != nil:
    section.add "Action", valid_594859
  var valid_594860 = query.getOrDefault("Version")
  valid_594860 = validateParameter(valid_594860, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594860 != nil:
    section.add "Version", valid_594860
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594861 = header.getOrDefault("X-Amz-Signature")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "X-Amz-Signature", valid_594861
  var valid_594862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594862 = validateParameter(valid_594862, JString, required = false,
                                 default = nil)
  if valid_594862 != nil:
    section.add "X-Amz-Content-Sha256", valid_594862
  var valid_594863 = header.getOrDefault("X-Amz-Date")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "X-Amz-Date", valid_594863
  var valid_594864 = header.getOrDefault("X-Amz-Credential")
  valid_594864 = validateParameter(valid_594864, JString, required = false,
                                 default = nil)
  if valid_594864 != nil:
    section.add "X-Amz-Credential", valid_594864
  var valid_594865 = header.getOrDefault("X-Amz-Security-Token")
  valid_594865 = validateParameter(valid_594865, JString, required = false,
                                 default = nil)
  if valid_594865 != nil:
    section.add "X-Amz-Security-Token", valid_594865
  var valid_594866 = header.getOrDefault("X-Amz-Algorithm")
  valid_594866 = validateParameter(valid_594866, JString, required = false,
                                 default = nil)
  if valid_594866 != nil:
    section.add "X-Amz-Algorithm", valid_594866
  var valid_594867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594867 = validateParameter(valid_594867, JString, required = false,
                                 default = nil)
  if valid_594867 != nil:
    section.add "X-Amz-SignedHeaders", valid_594867
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_594868 = formData.getOrDefault("ResetAllParameters")
  valid_594868 = validateParameter(valid_594868, JBool, required = false, default = nil)
  if valid_594868 != nil:
    section.add "ResetAllParameters", valid_594868
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594869 = formData.getOrDefault("DBParameterGroupName")
  valid_594869 = validateParameter(valid_594869, JString, required = true,
                                 default = nil)
  if valid_594869 != nil:
    section.add "DBParameterGroupName", valid_594869
  var valid_594870 = formData.getOrDefault("Parameters")
  valid_594870 = validateParameter(valid_594870, JArray, required = false,
                                 default = nil)
  if valid_594870 != nil:
    section.add "Parameters", valid_594870
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594871: Call_PostResetDBParameterGroup_594856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594871.validator(path, query, header, formData, body)
  let scheme = call_594871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594871.url(scheme.get, call_594871.host, call_594871.base,
                         call_594871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594871, url, valid)

proc call*(call_594872: Call_PostResetDBParameterGroup_594856;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2013-02-12"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_594873 = newJObject()
  var formData_594874 = newJObject()
  add(formData_594874, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_594874, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594873, "Action", newJString(Action))
  if Parameters != nil:
    formData_594874.add "Parameters", Parameters
  add(query_594873, "Version", newJString(Version))
  result = call_594872.call(nil, query_594873, nil, formData_594874, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_594856(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_594857, base: "/",
    url: url_PostResetDBParameterGroup_594858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_594838 = ref object of OpenApiRestCall_592348
proc url_GetResetDBParameterGroup_594840(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_594839(path: JsonNode; query: JsonNode;
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
  var valid_594841 = query.getOrDefault("DBParameterGroupName")
  valid_594841 = validateParameter(valid_594841, JString, required = true,
                                 default = nil)
  if valid_594841 != nil:
    section.add "DBParameterGroupName", valid_594841
  var valid_594842 = query.getOrDefault("Parameters")
  valid_594842 = validateParameter(valid_594842, JArray, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "Parameters", valid_594842
  var valid_594843 = query.getOrDefault("ResetAllParameters")
  valid_594843 = validateParameter(valid_594843, JBool, required = false, default = nil)
  if valid_594843 != nil:
    section.add "ResetAllParameters", valid_594843
  var valid_594844 = query.getOrDefault("Action")
  valid_594844 = validateParameter(valid_594844, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_594844 != nil:
    section.add "Action", valid_594844
  var valid_594845 = query.getOrDefault("Version")
  valid_594845 = validateParameter(valid_594845, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594845 != nil:
    section.add "Version", valid_594845
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594846 = header.getOrDefault("X-Amz-Signature")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "X-Amz-Signature", valid_594846
  var valid_594847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "X-Amz-Content-Sha256", valid_594847
  var valid_594848 = header.getOrDefault("X-Amz-Date")
  valid_594848 = validateParameter(valid_594848, JString, required = false,
                                 default = nil)
  if valid_594848 != nil:
    section.add "X-Amz-Date", valid_594848
  var valid_594849 = header.getOrDefault("X-Amz-Credential")
  valid_594849 = validateParameter(valid_594849, JString, required = false,
                                 default = nil)
  if valid_594849 != nil:
    section.add "X-Amz-Credential", valid_594849
  var valid_594850 = header.getOrDefault("X-Amz-Security-Token")
  valid_594850 = validateParameter(valid_594850, JString, required = false,
                                 default = nil)
  if valid_594850 != nil:
    section.add "X-Amz-Security-Token", valid_594850
  var valid_594851 = header.getOrDefault("X-Amz-Algorithm")
  valid_594851 = validateParameter(valid_594851, JString, required = false,
                                 default = nil)
  if valid_594851 != nil:
    section.add "X-Amz-Algorithm", valid_594851
  var valid_594852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594852 = validateParameter(valid_594852, JString, required = false,
                                 default = nil)
  if valid_594852 != nil:
    section.add "X-Amz-SignedHeaders", valid_594852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594853: Call_GetResetDBParameterGroup_594838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594853.validator(path, query, header, formData, body)
  let scheme = call_594853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594853.url(scheme.get, call_594853.host, call_594853.base,
                         call_594853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594853, url, valid)

proc call*(call_594854: Call_GetResetDBParameterGroup_594838;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594855 = newJObject()
  add(query_594855, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_594855.add "Parameters", Parameters
  add(query_594855, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_594855, "Action", newJString(Action))
  add(query_594855, "Version", newJString(Version))
  result = call_594854.call(nil, query_594855, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_594838(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_594839, base: "/",
    url: url_GetResetDBParameterGroup_594840, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_594904 = ref object of OpenApiRestCall_592348
proc url_PostRestoreDBInstanceFromDBSnapshot_594906(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_594905(path: JsonNode;
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
  var valid_594907 = query.getOrDefault("Action")
  valid_594907 = validateParameter(valid_594907, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_594907 != nil:
    section.add "Action", valid_594907
  var valid_594908 = query.getOrDefault("Version")
  valid_594908 = validateParameter(valid_594908, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594908 != nil:
    section.add "Version", valid_594908
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594909 = header.getOrDefault("X-Amz-Signature")
  valid_594909 = validateParameter(valid_594909, JString, required = false,
                                 default = nil)
  if valid_594909 != nil:
    section.add "X-Amz-Signature", valid_594909
  var valid_594910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594910 = validateParameter(valid_594910, JString, required = false,
                                 default = nil)
  if valid_594910 != nil:
    section.add "X-Amz-Content-Sha256", valid_594910
  var valid_594911 = header.getOrDefault("X-Amz-Date")
  valid_594911 = validateParameter(valid_594911, JString, required = false,
                                 default = nil)
  if valid_594911 != nil:
    section.add "X-Amz-Date", valid_594911
  var valid_594912 = header.getOrDefault("X-Amz-Credential")
  valid_594912 = validateParameter(valid_594912, JString, required = false,
                                 default = nil)
  if valid_594912 != nil:
    section.add "X-Amz-Credential", valid_594912
  var valid_594913 = header.getOrDefault("X-Amz-Security-Token")
  valid_594913 = validateParameter(valid_594913, JString, required = false,
                                 default = nil)
  if valid_594913 != nil:
    section.add "X-Amz-Security-Token", valid_594913
  var valid_594914 = header.getOrDefault("X-Amz-Algorithm")
  valid_594914 = validateParameter(valid_594914, JString, required = false,
                                 default = nil)
  if valid_594914 != nil:
    section.add "X-Amz-Algorithm", valid_594914
  var valid_594915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594915 = validateParameter(valid_594915, JString, required = false,
                                 default = nil)
  if valid_594915 != nil:
    section.add "X-Amz-SignedHeaders", valid_594915
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
  var valid_594916 = formData.getOrDefault("Port")
  valid_594916 = validateParameter(valid_594916, JInt, required = false, default = nil)
  if valid_594916 != nil:
    section.add "Port", valid_594916
  var valid_594917 = formData.getOrDefault("DBInstanceClass")
  valid_594917 = validateParameter(valid_594917, JString, required = false,
                                 default = nil)
  if valid_594917 != nil:
    section.add "DBInstanceClass", valid_594917
  var valid_594918 = formData.getOrDefault("MultiAZ")
  valid_594918 = validateParameter(valid_594918, JBool, required = false, default = nil)
  if valid_594918 != nil:
    section.add "MultiAZ", valid_594918
  var valid_594919 = formData.getOrDefault("AvailabilityZone")
  valid_594919 = validateParameter(valid_594919, JString, required = false,
                                 default = nil)
  if valid_594919 != nil:
    section.add "AvailabilityZone", valid_594919
  var valid_594920 = formData.getOrDefault("Engine")
  valid_594920 = validateParameter(valid_594920, JString, required = false,
                                 default = nil)
  if valid_594920 != nil:
    section.add "Engine", valid_594920
  var valid_594921 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594921 = validateParameter(valid_594921, JBool, required = false, default = nil)
  if valid_594921 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594921
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594922 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594922 = validateParameter(valid_594922, JString, required = true,
                                 default = nil)
  if valid_594922 != nil:
    section.add "DBInstanceIdentifier", valid_594922
  var valid_594923 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_594923 = validateParameter(valid_594923, JString, required = true,
                                 default = nil)
  if valid_594923 != nil:
    section.add "DBSnapshotIdentifier", valid_594923
  var valid_594924 = formData.getOrDefault("DBName")
  valid_594924 = validateParameter(valid_594924, JString, required = false,
                                 default = nil)
  if valid_594924 != nil:
    section.add "DBName", valid_594924
  var valid_594925 = formData.getOrDefault("Iops")
  valid_594925 = validateParameter(valid_594925, JInt, required = false, default = nil)
  if valid_594925 != nil:
    section.add "Iops", valid_594925
  var valid_594926 = formData.getOrDefault("PubliclyAccessible")
  valid_594926 = validateParameter(valid_594926, JBool, required = false, default = nil)
  if valid_594926 != nil:
    section.add "PubliclyAccessible", valid_594926
  var valid_594927 = formData.getOrDefault("LicenseModel")
  valid_594927 = validateParameter(valid_594927, JString, required = false,
                                 default = nil)
  if valid_594927 != nil:
    section.add "LicenseModel", valid_594927
  var valid_594928 = formData.getOrDefault("DBSubnetGroupName")
  valid_594928 = validateParameter(valid_594928, JString, required = false,
                                 default = nil)
  if valid_594928 != nil:
    section.add "DBSubnetGroupName", valid_594928
  var valid_594929 = formData.getOrDefault("OptionGroupName")
  valid_594929 = validateParameter(valid_594929, JString, required = false,
                                 default = nil)
  if valid_594929 != nil:
    section.add "OptionGroupName", valid_594929
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594930: Call_PostRestoreDBInstanceFromDBSnapshot_594904;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594930.validator(path, query, header, formData, body)
  let scheme = call_594930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594930.url(scheme.get, call_594930.host, call_594930.base,
                         call_594930.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594930, url, valid)

proc call*(call_594931: Call_PostRestoreDBInstanceFromDBSnapshot_594904;
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
  var query_594932 = newJObject()
  var formData_594933 = newJObject()
  add(formData_594933, "Port", newJInt(Port))
  add(formData_594933, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594933, "MultiAZ", newJBool(MultiAZ))
  add(formData_594933, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_594933, "Engine", newJString(Engine))
  add(formData_594933, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_594933, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594933, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_594933, "DBName", newJString(DBName))
  add(formData_594933, "Iops", newJInt(Iops))
  add(formData_594933, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594932, "Action", newJString(Action))
  add(formData_594933, "LicenseModel", newJString(LicenseModel))
  add(formData_594933, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_594933, "OptionGroupName", newJString(OptionGroupName))
  add(query_594932, "Version", newJString(Version))
  result = call_594931.call(nil, query_594932, nil, formData_594933, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_594904(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_594905, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_594906,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_594875 = ref object of OpenApiRestCall_592348
proc url_GetRestoreDBInstanceFromDBSnapshot_594877(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_594876(path: JsonNode;
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
  var valid_594878 = query.getOrDefault("DBName")
  valid_594878 = validateParameter(valid_594878, JString, required = false,
                                 default = nil)
  if valid_594878 != nil:
    section.add "DBName", valid_594878
  var valid_594879 = query.getOrDefault("Engine")
  valid_594879 = validateParameter(valid_594879, JString, required = false,
                                 default = nil)
  if valid_594879 != nil:
    section.add "Engine", valid_594879
  var valid_594880 = query.getOrDefault("LicenseModel")
  valid_594880 = validateParameter(valid_594880, JString, required = false,
                                 default = nil)
  if valid_594880 != nil:
    section.add "LicenseModel", valid_594880
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594881 = query.getOrDefault("DBInstanceIdentifier")
  valid_594881 = validateParameter(valid_594881, JString, required = true,
                                 default = nil)
  if valid_594881 != nil:
    section.add "DBInstanceIdentifier", valid_594881
  var valid_594882 = query.getOrDefault("DBSnapshotIdentifier")
  valid_594882 = validateParameter(valid_594882, JString, required = true,
                                 default = nil)
  if valid_594882 != nil:
    section.add "DBSnapshotIdentifier", valid_594882
  var valid_594883 = query.getOrDefault("Action")
  valid_594883 = validateParameter(valid_594883, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_594883 != nil:
    section.add "Action", valid_594883
  var valid_594884 = query.getOrDefault("MultiAZ")
  valid_594884 = validateParameter(valid_594884, JBool, required = false, default = nil)
  if valid_594884 != nil:
    section.add "MultiAZ", valid_594884
  var valid_594885 = query.getOrDefault("Port")
  valid_594885 = validateParameter(valid_594885, JInt, required = false, default = nil)
  if valid_594885 != nil:
    section.add "Port", valid_594885
  var valid_594886 = query.getOrDefault("AvailabilityZone")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "AvailabilityZone", valid_594886
  var valid_594887 = query.getOrDefault("OptionGroupName")
  valid_594887 = validateParameter(valid_594887, JString, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "OptionGroupName", valid_594887
  var valid_594888 = query.getOrDefault("DBSubnetGroupName")
  valid_594888 = validateParameter(valid_594888, JString, required = false,
                                 default = nil)
  if valid_594888 != nil:
    section.add "DBSubnetGroupName", valid_594888
  var valid_594889 = query.getOrDefault("Version")
  valid_594889 = validateParameter(valid_594889, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594889 != nil:
    section.add "Version", valid_594889
  var valid_594890 = query.getOrDefault("DBInstanceClass")
  valid_594890 = validateParameter(valid_594890, JString, required = false,
                                 default = nil)
  if valid_594890 != nil:
    section.add "DBInstanceClass", valid_594890
  var valid_594891 = query.getOrDefault("PubliclyAccessible")
  valid_594891 = validateParameter(valid_594891, JBool, required = false, default = nil)
  if valid_594891 != nil:
    section.add "PubliclyAccessible", valid_594891
  var valid_594892 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594892 = validateParameter(valid_594892, JBool, required = false, default = nil)
  if valid_594892 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594892
  var valid_594893 = query.getOrDefault("Iops")
  valid_594893 = validateParameter(valid_594893, JInt, required = false, default = nil)
  if valid_594893 != nil:
    section.add "Iops", valid_594893
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594894 = header.getOrDefault("X-Amz-Signature")
  valid_594894 = validateParameter(valid_594894, JString, required = false,
                                 default = nil)
  if valid_594894 != nil:
    section.add "X-Amz-Signature", valid_594894
  var valid_594895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594895 = validateParameter(valid_594895, JString, required = false,
                                 default = nil)
  if valid_594895 != nil:
    section.add "X-Amz-Content-Sha256", valid_594895
  var valid_594896 = header.getOrDefault("X-Amz-Date")
  valid_594896 = validateParameter(valid_594896, JString, required = false,
                                 default = nil)
  if valid_594896 != nil:
    section.add "X-Amz-Date", valid_594896
  var valid_594897 = header.getOrDefault("X-Amz-Credential")
  valid_594897 = validateParameter(valid_594897, JString, required = false,
                                 default = nil)
  if valid_594897 != nil:
    section.add "X-Amz-Credential", valid_594897
  var valid_594898 = header.getOrDefault("X-Amz-Security-Token")
  valid_594898 = validateParameter(valid_594898, JString, required = false,
                                 default = nil)
  if valid_594898 != nil:
    section.add "X-Amz-Security-Token", valid_594898
  var valid_594899 = header.getOrDefault("X-Amz-Algorithm")
  valid_594899 = validateParameter(valid_594899, JString, required = false,
                                 default = nil)
  if valid_594899 != nil:
    section.add "X-Amz-Algorithm", valid_594899
  var valid_594900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594900 = validateParameter(valid_594900, JString, required = false,
                                 default = nil)
  if valid_594900 != nil:
    section.add "X-Amz-SignedHeaders", valid_594900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594901: Call_GetRestoreDBInstanceFromDBSnapshot_594875;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594901.validator(path, query, header, formData, body)
  let scheme = call_594901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594901.url(scheme.get, call_594901.host, call_594901.base,
                         call_594901.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594901, url, valid)

proc call*(call_594902: Call_GetRestoreDBInstanceFromDBSnapshot_594875;
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
  var query_594903 = newJObject()
  add(query_594903, "DBName", newJString(DBName))
  add(query_594903, "Engine", newJString(Engine))
  add(query_594903, "LicenseModel", newJString(LicenseModel))
  add(query_594903, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594903, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_594903, "Action", newJString(Action))
  add(query_594903, "MultiAZ", newJBool(MultiAZ))
  add(query_594903, "Port", newJInt(Port))
  add(query_594903, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594903, "OptionGroupName", newJString(OptionGroupName))
  add(query_594903, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594903, "Version", newJString(Version))
  add(query_594903, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594903, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594903, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594903, "Iops", newJInt(Iops))
  result = call_594902.call(nil, query_594903, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_594875(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_594876, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_594877,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_594965 = ref object of OpenApiRestCall_592348
proc url_PostRestoreDBInstanceToPointInTime_594967(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_594966(path: JsonNode;
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
  var valid_594968 = query.getOrDefault("Action")
  valid_594968 = validateParameter(valid_594968, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_594968 != nil:
    section.add "Action", valid_594968
  var valid_594969 = query.getOrDefault("Version")
  valid_594969 = validateParameter(valid_594969, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594969 != nil:
    section.add "Version", valid_594969
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594970 = header.getOrDefault("X-Amz-Signature")
  valid_594970 = validateParameter(valid_594970, JString, required = false,
                                 default = nil)
  if valid_594970 != nil:
    section.add "X-Amz-Signature", valid_594970
  var valid_594971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594971 = validateParameter(valid_594971, JString, required = false,
                                 default = nil)
  if valid_594971 != nil:
    section.add "X-Amz-Content-Sha256", valid_594971
  var valid_594972 = header.getOrDefault("X-Amz-Date")
  valid_594972 = validateParameter(valid_594972, JString, required = false,
                                 default = nil)
  if valid_594972 != nil:
    section.add "X-Amz-Date", valid_594972
  var valid_594973 = header.getOrDefault("X-Amz-Credential")
  valid_594973 = validateParameter(valid_594973, JString, required = false,
                                 default = nil)
  if valid_594973 != nil:
    section.add "X-Amz-Credential", valid_594973
  var valid_594974 = header.getOrDefault("X-Amz-Security-Token")
  valid_594974 = validateParameter(valid_594974, JString, required = false,
                                 default = nil)
  if valid_594974 != nil:
    section.add "X-Amz-Security-Token", valid_594974
  var valid_594975 = header.getOrDefault("X-Amz-Algorithm")
  valid_594975 = validateParameter(valid_594975, JString, required = false,
                                 default = nil)
  if valid_594975 != nil:
    section.add "X-Amz-Algorithm", valid_594975
  var valid_594976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "X-Amz-SignedHeaders", valid_594976
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
  var valid_594977 = formData.getOrDefault("Port")
  valid_594977 = validateParameter(valid_594977, JInt, required = false, default = nil)
  if valid_594977 != nil:
    section.add "Port", valid_594977
  var valid_594978 = formData.getOrDefault("DBInstanceClass")
  valid_594978 = validateParameter(valid_594978, JString, required = false,
                                 default = nil)
  if valid_594978 != nil:
    section.add "DBInstanceClass", valid_594978
  var valid_594979 = formData.getOrDefault("MultiAZ")
  valid_594979 = validateParameter(valid_594979, JBool, required = false, default = nil)
  if valid_594979 != nil:
    section.add "MultiAZ", valid_594979
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_594980 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_594980 = validateParameter(valid_594980, JString, required = true,
                                 default = nil)
  if valid_594980 != nil:
    section.add "SourceDBInstanceIdentifier", valid_594980
  var valid_594981 = formData.getOrDefault("AvailabilityZone")
  valid_594981 = validateParameter(valid_594981, JString, required = false,
                                 default = nil)
  if valid_594981 != nil:
    section.add "AvailabilityZone", valid_594981
  var valid_594982 = formData.getOrDefault("Engine")
  valid_594982 = validateParameter(valid_594982, JString, required = false,
                                 default = nil)
  if valid_594982 != nil:
    section.add "Engine", valid_594982
  var valid_594983 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594983 = validateParameter(valid_594983, JBool, required = false, default = nil)
  if valid_594983 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594983
  var valid_594984 = formData.getOrDefault("UseLatestRestorableTime")
  valid_594984 = validateParameter(valid_594984, JBool, required = false, default = nil)
  if valid_594984 != nil:
    section.add "UseLatestRestorableTime", valid_594984
  var valid_594985 = formData.getOrDefault("DBName")
  valid_594985 = validateParameter(valid_594985, JString, required = false,
                                 default = nil)
  if valid_594985 != nil:
    section.add "DBName", valid_594985
  var valid_594986 = formData.getOrDefault("Iops")
  valid_594986 = validateParameter(valid_594986, JInt, required = false, default = nil)
  if valid_594986 != nil:
    section.add "Iops", valid_594986
  var valid_594987 = formData.getOrDefault("PubliclyAccessible")
  valid_594987 = validateParameter(valid_594987, JBool, required = false, default = nil)
  if valid_594987 != nil:
    section.add "PubliclyAccessible", valid_594987
  var valid_594988 = formData.getOrDefault("LicenseModel")
  valid_594988 = validateParameter(valid_594988, JString, required = false,
                                 default = nil)
  if valid_594988 != nil:
    section.add "LicenseModel", valid_594988
  var valid_594989 = formData.getOrDefault("DBSubnetGroupName")
  valid_594989 = validateParameter(valid_594989, JString, required = false,
                                 default = nil)
  if valid_594989 != nil:
    section.add "DBSubnetGroupName", valid_594989
  var valid_594990 = formData.getOrDefault("OptionGroupName")
  valid_594990 = validateParameter(valid_594990, JString, required = false,
                                 default = nil)
  if valid_594990 != nil:
    section.add "OptionGroupName", valid_594990
  var valid_594991 = formData.getOrDefault("RestoreTime")
  valid_594991 = validateParameter(valid_594991, JString, required = false,
                                 default = nil)
  if valid_594991 != nil:
    section.add "RestoreTime", valid_594991
  var valid_594992 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_594992 = validateParameter(valid_594992, JString, required = true,
                                 default = nil)
  if valid_594992 != nil:
    section.add "TargetDBInstanceIdentifier", valid_594992
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594993: Call_PostRestoreDBInstanceToPointInTime_594965;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594993.validator(path, query, header, formData, body)
  let scheme = call_594993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594993.url(scheme.get, call_594993.host, call_594993.base,
                         call_594993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594993, url, valid)

proc call*(call_594994: Call_PostRestoreDBInstanceToPointInTime_594965;
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
  var query_594995 = newJObject()
  var formData_594996 = newJObject()
  add(formData_594996, "Port", newJInt(Port))
  add(formData_594996, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594996, "MultiAZ", newJBool(MultiAZ))
  add(formData_594996, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_594996, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_594996, "Engine", newJString(Engine))
  add(formData_594996, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_594996, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_594996, "DBName", newJString(DBName))
  add(formData_594996, "Iops", newJInt(Iops))
  add(formData_594996, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594995, "Action", newJString(Action))
  add(formData_594996, "LicenseModel", newJString(LicenseModel))
  add(formData_594996, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_594996, "OptionGroupName", newJString(OptionGroupName))
  add(formData_594996, "RestoreTime", newJString(RestoreTime))
  add(formData_594996, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_594995, "Version", newJString(Version))
  result = call_594994.call(nil, query_594995, nil, formData_594996, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_594965(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_594966, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_594967,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_594934 = ref object of OpenApiRestCall_592348
proc url_GetRestoreDBInstanceToPointInTime_594936(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_594935(path: JsonNode;
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
  var valid_594937 = query.getOrDefault("DBName")
  valid_594937 = validateParameter(valid_594937, JString, required = false,
                                 default = nil)
  if valid_594937 != nil:
    section.add "DBName", valid_594937
  var valid_594938 = query.getOrDefault("Engine")
  valid_594938 = validateParameter(valid_594938, JString, required = false,
                                 default = nil)
  if valid_594938 != nil:
    section.add "Engine", valid_594938
  var valid_594939 = query.getOrDefault("UseLatestRestorableTime")
  valid_594939 = validateParameter(valid_594939, JBool, required = false, default = nil)
  if valid_594939 != nil:
    section.add "UseLatestRestorableTime", valid_594939
  var valid_594940 = query.getOrDefault("LicenseModel")
  valid_594940 = validateParameter(valid_594940, JString, required = false,
                                 default = nil)
  if valid_594940 != nil:
    section.add "LicenseModel", valid_594940
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_594941 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_594941 = validateParameter(valid_594941, JString, required = true,
                                 default = nil)
  if valid_594941 != nil:
    section.add "TargetDBInstanceIdentifier", valid_594941
  var valid_594942 = query.getOrDefault("Action")
  valid_594942 = validateParameter(valid_594942, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_594942 != nil:
    section.add "Action", valid_594942
  var valid_594943 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_594943 = validateParameter(valid_594943, JString, required = true,
                                 default = nil)
  if valid_594943 != nil:
    section.add "SourceDBInstanceIdentifier", valid_594943
  var valid_594944 = query.getOrDefault("MultiAZ")
  valid_594944 = validateParameter(valid_594944, JBool, required = false, default = nil)
  if valid_594944 != nil:
    section.add "MultiAZ", valid_594944
  var valid_594945 = query.getOrDefault("Port")
  valid_594945 = validateParameter(valid_594945, JInt, required = false, default = nil)
  if valid_594945 != nil:
    section.add "Port", valid_594945
  var valid_594946 = query.getOrDefault("AvailabilityZone")
  valid_594946 = validateParameter(valid_594946, JString, required = false,
                                 default = nil)
  if valid_594946 != nil:
    section.add "AvailabilityZone", valid_594946
  var valid_594947 = query.getOrDefault("OptionGroupName")
  valid_594947 = validateParameter(valid_594947, JString, required = false,
                                 default = nil)
  if valid_594947 != nil:
    section.add "OptionGroupName", valid_594947
  var valid_594948 = query.getOrDefault("DBSubnetGroupName")
  valid_594948 = validateParameter(valid_594948, JString, required = false,
                                 default = nil)
  if valid_594948 != nil:
    section.add "DBSubnetGroupName", valid_594948
  var valid_594949 = query.getOrDefault("RestoreTime")
  valid_594949 = validateParameter(valid_594949, JString, required = false,
                                 default = nil)
  if valid_594949 != nil:
    section.add "RestoreTime", valid_594949
  var valid_594950 = query.getOrDefault("DBInstanceClass")
  valid_594950 = validateParameter(valid_594950, JString, required = false,
                                 default = nil)
  if valid_594950 != nil:
    section.add "DBInstanceClass", valid_594950
  var valid_594951 = query.getOrDefault("PubliclyAccessible")
  valid_594951 = validateParameter(valid_594951, JBool, required = false, default = nil)
  if valid_594951 != nil:
    section.add "PubliclyAccessible", valid_594951
  var valid_594952 = query.getOrDefault("Version")
  valid_594952 = validateParameter(valid_594952, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594952 != nil:
    section.add "Version", valid_594952
  var valid_594953 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594953 = validateParameter(valid_594953, JBool, required = false, default = nil)
  if valid_594953 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594953
  var valid_594954 = query.getOrDefault("Iops")
  valid_594954 = validateParameter(valid_594954, JInt, required = false, default = nil)
  if valid_594954 != nil:
    section.add "Iops", valid_594954
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594955 = header.getOrDefault("X-Amz-Signature")
  valid_594955 = validateParameter(valid_594955, JString, required = false,
                                 default = nil)
  if valid_594955 != nil:
    section.add "X-Amz-Signature", valid_594955
  var valid_594956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "X-Amz-Content-Sha256", valid_594956
  var valid_594957 = header.getOrDefault("X-Amz-Date")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-Date", valid_594957
  var valid_594958 = header.getOrDefault("X-Amz-Credential")
  valid_594958 = validateParameter(valid_594958, JString, required = false,
                                 default = nil)
  if valid_594958 != nil:
    section.add "X-Amz-Credential", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-Security-Token")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-Security-Token", valid_594959
  var valid_594960 = header.getOrDefault("X-Amz-Algorithm")
  valid_594960 = validateParameter(valid_594960, JString, required = false,
                                 default = nil)
  if valid_594960 != nil:
    section.add "X-Amz-Algorithm", valid_594960
  var valid_594961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594961 = validateParameter(valid_594961, JString, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "X-Amz-SignedHeaders", valid_594961
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594962: Call_GetRestoreDBInstanceToPointInTime_594934;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594962.validator(path, query, header, formData, body)
  let scheme = call_594962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594962.url(scheme.get, call_594962.host, call_594962.base,
                         call_594962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594962, url, valid)

proc call*(call_594963: Call_GetRestoreDBInstanceToPointInTime_594934;
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
  var query_594964 = newJObject()
  add(query_594964, "DBName", newJString(DBName))
  add(query_594964, "Engine", newJString(Engine))
  add(query_594964, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_594964, "LicenseModel", newJString(LicenseModel))
  add(query_594964, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_594964, "Action", newJString(Action))
  add(query_594964, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_594964, "MultiAZ", newJBool(MultiAZ))
  add(query_594964, "Port", newJInt(Port))
  add(query_594964, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594964, "OptionGroupName", newJString(OptionGroupName))
  add(query_594964, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594964, "RestoreTime", newJString(RestoreTime))
  add(query_594964, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594964, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594964, "Version", newJString(Version))
  add(query_594964, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594964, "Iops", newJInt(Iops))
  result = call_594963.call(nil, query_594964, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_594934(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_594935, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_594936,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_595017 = ref object of OpenApiRestCall_592348
proc url_PostRevokeDBSecurityGroupIngress_595019(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_595018(path: JsonNode;
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
  var valid_595020 = query.getOrDefault("Action")
  valid_595020 = validateParameter(valid_595020, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_595020 != nil:
    section.add "Action", valid_595020
  var valid_595021 = query.getOrDefault("Version")
  valid_595021 = validateParameter(valid_595021, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595021 != nil:
    section.add "Version", valid_595021
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595022 = header.getOrDefault("X-Amz-Signature")
  valid_595022 = validateParameter(valid_595022, JString, required = false,
                                 default = nil)
  if valid_595022 != nil:
    section.add "X-Amz-Signature", valid_595022
  var valid_595023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595023 = validateParameter(valid_595023, JString, required = false,
                                 default = nil)
  if valid_595023 != nil:
    section.add "X-Amz-Content-Sha256", valid_595023
  var valid_595024 = header.getOrDefault("X-Amz-Date")
  valid_595024 = validateParameter(valid_595024, JString, required = false,
                                 default = nil)
  if valid_595024 != nil:
    section.add "X-Amz-Date", valid_595024
  var valid_595025 = header.getOrDefault("X-Amz-Credential")
  valid_595025 = validateParameter(valid_595025, JString, required = false,
                                 default = nil)
  if valid_595025 != nil:
    section.add "X-Amz-Credential", valid_595025
  var valid_595026 = header.getOrDefault("X-Amz-Security-Token")
  valid_595026 = validateParameter(valid_595026, JString, required = false,
                                 default = nil)
  if valid_595026 != nil:
    section.add "X-Amz-Security-Token", valid_595026
  var valid_595027 = header.getOrDefault("X-Amz-Algorithm")
  valid_595027 = validateParameter(valid_595027, JString, required = false,
                                 default = nil)
  if valid_595027 != nil:
    section.add "X-Amz-Algorithm", valid_595027
  var valid_595028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595028 = validateParameter(valid_595028, JString, required = false,
                                 default = nil)
  if valid_595028 != nil:
    section.add "X-Amz-SignedHeaders", valid_595028
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_595029 = formData.getOrDefault("DBSecurityGroupName")
  valid_595029 = validateParameter(valid_595029, JString, required = true,
                                 default = nil)
  if valid_595029 != nil:
    section.add "DBSecurityGroupName", valid_595029
  var valid_595030 = formData.getOrDefault("EC2SecurityGroupName")
  valid_595030 = validateParameter(valid_595030, JString, required = false,
                                 default = nil)
  if valid_595030 != nil:
    section.add "EC2SecurityGroupName", valid_595030
  var valid_595031 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_595031
  var valid_595032 = formData.getOrDefault("EC2SecurityGroupId")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "EC2SecurityGroupId", valid_595032
  var valid_595033 = formData.getOrDefault("CIDRIP")
  valid_595033 = validateParameter(valid_595033, JString, required = false,
                                 default = nil)
  if valid_595033 != nil:
    section.add "CIDRIP", valid_595033
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595034: Call_PostRevokeDBSecurityGroupIngress_595017;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595034.validator(path, query, header, formData, body)
  let scheme = call_595034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595034.url(scheme.get, call_595034.host, call_595034.base,
                         call_595034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595034, url, valid)

proc call*(call_595035: Call_PostRevokeDBSecurityGroupIngress_595017;
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
  var query_595036 = newJObject()
  var formData_595037 = newJObject()
  add(formData_595037, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_595037, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_595037, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_595037, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_595037, "CIDRIP", newJString(CIDRIP))
  add(query_595036, "Action", newJString(Action))
  add(query_595036, "Version", newJString(Version))
  result = call_595035.call(nil, query_595036, nil, formData_595037, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_595017(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_595018, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_595019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_594997 = ref object of OpenApiRestCall_592348
proc url_GetRevokeDBSecurityGroupIngress_594999(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_594998(path: JsonNode;
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
  var valid_595000 = query.getOrDefault("EC2SecurityGroupName")
  valid_595000 = validateParameter(valid_595000, JString, required = false,
                                 default = nil)
  if valid_595000 != nil:
    section.add "EC2SecurityGroupName", valid_595000
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_595001 = query.getOrDefault("DBSecurityGroupName")
  valid_595001 = validateParameter(valid_595001, JString, required = true,
                                 default = nil)
  if valid_595001 != nil:
    section.add "DBSecurityGroupName", valid_595001
  var valid_595002 = query.getOrDefault("EC2SecurityGroupId")
  valid_595002 = validateParameter(valid_595002, JString, required = false,
                                 default = nil)
  if valid_595002 != nil:
    section.add "EC2SecurityGroupId", valid_595002
  var valid_595003 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_595003 = validateParameter(valid_595003, JString, required = false,
                                 default = nil)
  if valid_595003 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_595003
  var valid_595004 = query.getOrDefault("Action")
  valid_595004 = validateParameter(valid_595004, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_595004 != nil:
    section.add "Action", valid_595004
  var valid_595005 = query.getOrDefault("Version")
  valid_595005 = validateParameter(valid_595005, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595005 != nil:
    section.add "Version", valid_595005
  var valid_595006 = query.getOrDefault("CIDRIP")
  valid_595006 = validateParameter(valid_595006, JString, required = false,
                                 default = nil)
  if valid_595006 != nil:
    section.add "CIDRIP", valid_595006
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595007 = header.getOrDefault("X-Amz-Signature")
  valid_595007 = validateParameter(valid_595007, JString, required = false,
                                 default = nil)
  if valid_595007 != nil:
    section.add "X-Amz-Signature", valid_595007
  var valid_595008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595008 = validateParameter(valid_595008, JString, required = false,
                                 default = nil)
  if valid_595008 != nil:
    section.add "X-Amz-Content-Sha256", valid_595008
  var valid_595009 = header.getOrDefault("X-Amz-Date")
  valid_595009 = validateParameter(valid_595009, JString, required = false,
                                 default = nil)
  if valid_595009 != nil:
    section.add "X-Amz-Date", valid_595009
  var valid_595010 = header.getOrDefault("X-Amz-Credential")
  valid_595010 = validateParameter(valid_595010, JString, required = false,
                                 default = nil)
  if valid_595010 != nil:
    section.add "X-Amz-Credential", valid_595010
  var valid_595011 = header.getOrDefault("X-Amz-Security-Token")
  valid_595011 = validateParameter(valid_595011, JString, required = false,
                                 default = nil)
  if valid_595011 != nil:
    section.add "X-Amz-Security-Token", valid_595011
  var valid_595012 = header.getOrDefault("X-Amz-Algorithm")
  valid_595012 = validateParameter(valid_595012, JString, required = false,
                                 default = nil)
  if valid_595012 != nil:
    section.add "X-Amz-Algorithm", valid_595012
  var valid_595013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595013 = validateParameter(valid_595013, JString, required = false,
                                 default = nil)
  if valid_595013 != nil:
    section.add "X-Amz-SignedHeaders", valid_595013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595014: Call_GetRevokeDBSecurityGroupIngress_594997;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595014.validator(path, query, header, formData, body)
  let scheme = call_595014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595014.url(scheme.get, call_595014.host, call_595014.base,
                         call_595014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595014, url, valid)

proc call*(call_595015: Call_GetRevokeDBSecurityGroupIngress_594997;
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
  var query_595016 = newJObject()
  add(query_595016, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_595016, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_595016, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_595016, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_595016, "Action", newJString(Action))
  add(query_595016, "Version", newJString(Version))
  add(query_595016, "CIDRIP", newJString(CIDRIP))
  result = call_595015.call(nil, query_595016, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_594997(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_594998, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_594999,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
