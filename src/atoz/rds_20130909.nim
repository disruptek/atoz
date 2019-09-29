
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593421 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593421](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593421): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
  Call_PostAddSourceIdentifierToSubscription_594030 = ref object of OpenApiRestCall_593421
proc url_PostAddSourceIdentifierToSubscription_594032(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddSourceIdentifierToSubscription_594031(path: JsonNode;
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
  var valid_594033 = query.getOrDefault("Action")
  valid_594033 = validateParameter(valid_594033, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_594033 != nil:
    section.add "Action", valid_594033
  var valid_594034 = query.getOrDefault("Version")
  valid_594034 = validateParameter(valid_594034, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594034 != nil:
    section.add "Version", valid_594034
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
  var valid_594035 = header.getOrDefault("X-Amz-Date")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Date", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-Security-Token")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Security-Token", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Content-Sha256", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Algorithm")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Algorithm", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-Signature")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-Signature", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-SignedHeaders", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Credential")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Credential", valid_594041
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_594042 = formData.getOrDefault("SourceIdentifier")
  valid_594042 = validateParameter(valid_594042, JString, required = true,
                                 default = nil)
  if valid_594042 != nil:
    section.add "SourceIdentifier", valid_594042
  var valid_594043 = formData.getOrDefault("SubscriptionName")
  valid_594043 = validateParameter(valid_594043, JString, required = true,
                                 default = nil)
  if valid_594043 != nil:
    section.add "SubscriptionName", valid_594043
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594044: Call_PostAddSourceIdentifierToSubscription_594030;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594044.validator(path, query, header, formData, body)
  let scheme = call_594044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594044.url(scheme.get, call_594044.host, call_594044.base,
                         call_594044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594044, url, valid)

proc call*(call_594045: Call_PostAddSourceIdentifierToSubscription_594030;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594046 = newJObject()
  var formData_594047 = newJObject()
  add(formData_594047, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_594047, "SubscriptionName", newJString(SubscriptionName))
  add(query_594046, "Action", newJString(Action))
  add(query_594046, "Version", newJString(Version))
  result = call_594045.call(nil, query_594046, nil, formData_594047, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_594030(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_594031, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_594032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_593758 = ref object of OpenApiRestCall_593421
proc url_GetAddSourceIdentifierToSubscription_593760(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddSourceIdentifierToSubscription_593759(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593885 = query.getOrDefault("Action")
  valid_593885 = validateParameter(valid_593885, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_593885 != nil:
    section.add "Action", valid_593885
  var valid_593886 = query.getOrDefault("SourceIdentifier")
  valid_593886 = validateParameter(valid_593886, JString, required = true,
                                 default = nil)
  if valid_593886 != nil:
    section.add "SourceIdentifier", valid_593886
  var valid_593887 = query.getOrDefault("SubscriptionName")
  valid_593887 = validateParameter(valid_593887, JString, required = true,
                                 default = nil)
  if valid_593887 != nil:
    section.add "SubscriptionName", valid_593887
  var valid_593888 = query.getOrDefault("Version")
  valid_593888 = validateParameter(valid_593888, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593888 != nil:
    section.add "Version", valid_593888
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
  var valid_593889 = header.getOrDefault("X-Amz-Date")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Date", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Security-Token")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Security-Token", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Content-Sha256", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-Algorithm")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Algorithm", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-Signature")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Signature", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-SignedHeaders", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-Credential")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-Credential", valid_593895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593918: Call_GetAddSourceIdentifierToSubscription_593758;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_593918.validator(path, query, header, formData, body)
  let scheme = call_593918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593918.url(scheme.get, call_593918.host, call_593918.base,
                         call_593918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593918, url, valid)

proc call*(call_593989: Call_GetAddSourceIdentifierToSubscription_593758;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_593990 = newJObject()
  add(query_593990, "Action", newJString(Action))
  add(query_593990, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_593990, "SubscriptionName", newJString(SubscriptionName))
  add(query_593990, "Version", newJString(Version))
  result = call_593989.call(nil, query_593990, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_593758(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_593759, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_593760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_594065 = ref object of OpenApiRestCall_593421
proc url_PostAddTagsToResource_594067(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTagsToResource_594066(path: JsonNode; query: JsonNode;
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
  var valid_594068 = query.getOrDefault("Action")
  valid_594068 = validateParameter(valid_594068, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_594068 != nil:
    section.add "Action", valid_594068
  var valid_594069 = query.getOrDefault("Version")
  valid_594069 = validateParameter(valid_594069, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594069 != nil:
    section.add "Version", valid_594069
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
  var valid_594070 = header.getOrDefault("X-Amz-Date")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Date", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Security-Token")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Security-Token", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Content-Sha256", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Algorithm")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Algorithm", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Signature")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Signature", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-SignedHeaders", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Credential")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Credential", valid_594076
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_594077 = formData.getOrDefault("Tags")
  valid_594077 = validateParameter(valid_594077, JArray, required = true, default = nil)
  if valid_594077 != nil:
    section.add "Tags", valid_594077
  var valid_594078 = formData.getOrDefault("ResourceName")
  valid_594078 = validateParameter(valid_594078, JString, required = true,
                                 default = nil)
  if valid_594078 != nil:
    section.add "ResourceName", valid_594078
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594079: Call_PostAddTagsToResource_594065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594079.validator(path, query, header, formData, body)
  let scheme = call_594079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594079.url(scheme.get, call_594079.host, call_594079.base,
                         call_594079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594079, url, valid)

proc call*(call_594080: Call_PostAddTagsToResource_594065; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-09-09"): Recallable =
  ## postAddTagsToResource
  ##   Tags: JArray (required)
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_594081 = newJObject()
  var formData_594082 = newJObject()
  if Tags != nil:
    formData_594082.add "Tags", Tags
  add(query_594081, "Action", newJString(Action))
  add(formData_594082, "ResourceName", newJString(ResourceName))
  add(query_594081, "Version", newJString(Version))
  result = call_594080.call(nil, query_594081, nil, formData_594082, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_594065(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_594066, base: "/",
    url: url_PostAddTagsToResource_594067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_594048 = ref object of OpenApiRestCall_593421
proc url_GetAddTagsToResource_594050(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTagsToResource_594049(path: JsonNode; query: JsonNode;
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
  var valid_594051 = query.getOrDefault("Tags")
  valid_594051 = validateParameter(valid_594051, JArray, required = true, default = nil)
  if valid_594051 != nil:
    section.add "Tags", valid_594051
  var valid_594052 = query.getOrDefault("ResourceName")
  valid_594052 = validateParameter(valid_594052, JString, required = true,
                                 default = nil)
  if valid_594052 != nil:
    section.add "ResourceName", valid_594052
  var valid_594053 = query.getOrDefault("Action")
  valid_594053 = validateParameter(valid_594053, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_594053 != nil:
    section.add "Action", valid_594053
  var valid_594054 = query.getOrDefault("Version")
  valid_594054 = validateParameter(valid_594054, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594054 != nil:
    section.add "Version", valid_594054
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
  var valid_594055 = header.getOrDefault("X-Amz-Date")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Date", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Security-Token")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Security-Token", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Content-Sha256", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Algorithm")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Algorithm", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-Signature")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Signature", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-SignedHeaders", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-Credential")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Credential", valid_594061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594062: Call_GetAddTagsToResource_594048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594062.validator(path, query, header, formData, body)
  let scheme = call_594062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594062.url(scheme.get, call_594062.host, call_594062.base,
                         call_594062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594062, url, valid)

proc call*(call_594063: Call_GetAddTagsToResource_594048; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-09-09"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594064 = newJObject()
  if Tags != nil:
    query_594064.add "Tags", Tags
  add(query_594064, "ResourceName", newJString(ResourceName))
  add(query_594064, "Action", newJString(Action))
  add(query_594064, "Version", newJString(Version))
  result = call_594063.call(nil, query_594064, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_594048(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_594049, base: "/",
    url: url_GetAddTagsToResource_594050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_594103 = ref object of OpenApiRestCall_593421
proc url_PostAuthorizeDBSecurityGroupIngress_594105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_594104(path: JsonNode;
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
  var valid_594106 = query.getOrDefault("Action")
  valid_594106 = validateParameter(valid_594106, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_594106 != nil:
    section.add "Action", valid_594106
  var valid_594107 = query.getOrDefault("Version")
  valid_594107 = validateParameter(valid_594107, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594107 != nil:
    section.add "Version", valid_594107
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
  var valid_594108 = header.getOrDefault("X-Amz-Date")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Date", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Security-Token")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Security-Token", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Content-Sha256", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Algorithm")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Algorithm", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Signature")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Signature", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-SignedHeaders", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Credential")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Credential", valid_594114
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_594115 = formData.getOrDefault("DBSecurityGroupName")
  valid_594115 = validateParameter(valid_594115, JString, required = true,
                                 default = nil)
  if valid_594115 != nil:
    section.add "DBSecurityGroupName", valid_594115
  var valid_594116 = formData.getOrDefault("EC2SecurityGroupName")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "EC2SecurityGroupName", valid_594116
  var valid_594117 = formData.getOrDefault("EC2SecurityGroupId")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "EC2SecurityGroupId", valid_594117
  var valid_594118 = formData.getOrDefault("CIDRIP")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "CIDRIP", valid_594118
  var valid_594119 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_594119
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594120: Call_PostAuthorizeDBSecurityGroupIngress_594103;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594120.validator(path, query, header, formData, body)
  let scheme = call_594120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594120.url(scheme.get, call_594120.host, call_594120.base,
                         call_594120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594120, url, valid)

proc call*(call_594121: Call_PostAuthorizeDBSecurityGroupIngress_594103;
          DBSecurityGroupName: string;
          Action: string = "AuthorizeDBSecurityGroupIngress";
          EC2SecurityGroupName: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Version: string = "2013-09-09";
          EC2SecurityGroupOwnerId: string = ""): Recallable =
  ## postAuthorizeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Version: string (required)
  ##   EC2SecurityGroupOwnerId: string
  var query_594122 = newJObject()
  var formData_594123 = newJObject()
  add(formData_594123, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594122, "Action", newJString(Action))
  add(formData_594123, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_594123, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_594123, "CIDRIP", newJString(CIDRIP))
  add(query_594122, "Version", newJString(Version))
  add(formData_594123, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_594121.call(nil, query_594122, nil, formData_594123, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_594103(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_594104, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_594105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_594083 = ref object of OpenApiRestCall_593421
proc url_GetAuthorizeDBSecurityGroupIngress_594085(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_594084(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EC2SecurityGroupId: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   DBSecurityGroupName: JString (required)
  ##   Action: JString (required)
  ##   CIDRIP: JString
  ##   EC2SecurityGroupName: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_594086 = query.getOrDefault("EC2SecurityGroupId")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "EC2SecurityGroupId", valid_594086
  var valid_594087 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_594087
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_594088 = query.getOrDefault("DBSecurityGroupName")
  valid_594088 = validateParameter(valid_594088, JString, required = true,
                                 default = nil)
  if valid_594088 != nil:
    section.add "DBSecurityGroupName", valid_594088
  var valid_594089 = query.getOrDefault("Action")
  valid_594089 = validateParameter(valid_594089, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_594089 != nil:
    section.add "Action", valid_594089
  var valid_594090 = query.getOrDefault("CIDRIP")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "CIDRIP", valid_594090
  var valid_594091 = query.getOrDefault("EC2SecurityGroupName")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "EC2SecurityGroupName", valid_594091
  var valid_594092 = query.getOrDefault("Version")
  valid_594092 = validateParameter(valid_594092, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594092 != nil:
    section.add "Version", valid_594092
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
  var valid_594093 = header.getOrDefault("X-Amz-Date")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Date", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Security-Token")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Security-Token", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Content-Sha256", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Algorithm")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Algorithm", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Signature")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Signature", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-SignedHeaders", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Credential")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Credential", valid_594099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_GetAuthorizeDBSecurityGroupIngress_594083;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_GetAuthorizeDBSecurityGroupIngress_594083;
          DBSecurityGroupName: string; EC2SecurityGroupId: string = "";
          EC2SecurityGroupOwnerId: string = "";
          Action: string = "AuthorizeDBSecurityGroupIngress"; CIDRIP: string = "";
          EC2SecurityGroupName: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getAuthorizeDBSecurityGroupIngress
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   CIDRIP: string
  ##   EC2SecurityGroupName: string
  ##   Version: string (required)
  var query_594102 = newJObject()
  add(query_594102, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_594102, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_594102, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594102, "Action", newJString(Action))
  add(query_594102, "CIDRIP", newJString(CIDRIP))
  add(query_594102, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_594102, "Version", newJString(Version))
  result = call_594101.call(nil, query_594102, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_594083(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_594084, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_594085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_594142 = ref object of OpenApiRestCall_593421
proc url_PostCopyDBSnapshot_594144(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBSnapshot_594143(path: JsonNode; query: JsonNode;
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
  var valid_594145 = query.getOrDefault("Action")
  valid_594145 = validateParameter(valid_594145, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_594145 != nil:
    section.add "Action", valid_594145
  var valid_594146 = query.getOrDefault("Version")
  valid_594146 = validateParameter(valid_594146, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594146 != nil:
    section.add "Version", valid_594146
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
  var valid_594147 = header.getOrDefault("X-Amz-Date")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Date", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Security-Token")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Security-Token", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Content-Sha256", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Algorithm")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Algorithm", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Signature")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Signature", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-SignedHeaders", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Credential")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Credential", valid_594153
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_594154 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_594154 = validateParameter(valid_594154, JString, required = true,
                                 default = nil)
  if valid_594154 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_594154
  var valid_594155 = formData.getOrDefault("Tags")
  valid_594155 = validateParameter(valid_594155, JArray, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "Tags", valid_594155
  var valid_594156 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_594156 = validateParameter(valid_594156, JString, required = true,
                                 default = nil)
  if valid_594156 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_594156
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594157: Call_PostCopyDBSnapshot_594142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594157.validator(path, query, header, formData, body)
  let scheme = call_594157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594157.url(scheme.get, call_594157.host, call_594157.base,
                         call_594157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594157, url, valid)

proc call*(call_594158: Call_PostCopyDBSnapshot_594142;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_594159 = newJObject()
  var formData_594160 = newJObject()
  add(formData_594160, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_594160.add "Tags", Tags
  add(query_594159, "Action", newJString(Action))
  add(formData_594160, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_594159, "Version", newJString(Version))
  result = call_594158.call(nil, query_594159, nil, formData_594160, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_594142(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_594143, base: "/",
    url: url_PostCopyDBSnapshot_594144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_594124 = ref object of OpenApiRestCall_593421
proc url_GetCopyDBSnapshot_594126(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBSnapshot_594125(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_594127 = query.getOrDefault("Tags")
  valid_594127 = validateParameter(valid_594127, JArray, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "Tags", valid_594127
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_594128 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_594128 = validateParameter(valid_594128, JString, required = true,
                                 default = nil)
  if valid_594128 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_594128
  var valid_594129 = query.getOrDefault("Action")
  valid_594129 = validateParameter(valid_594129, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_594129 != nil:
    section.add "Action", valid_594129
  var valid_594130 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_594130 = validateParameter(valid_594130, JString, required = true,
                                 default = nil)
  if valid_594130 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_594130
  var valid_594131 = query.getOrDefault("Version")
  valid_594131 = validateParameter(valid_594131, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594131 != nil:
    section.add "Version", valid_594131
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
  var valid_594132 = header.getOrDefault("X-Amz-Date")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Date", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Security-Token")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Security-Token", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Content-Sha256", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Algorithm")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Algorithm", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Signature")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Signature", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-SignedHeaders", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-Credential")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Credential", valid_594138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594139: Call_GetCopyDBSnapshot_594124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594139.validator(path, query, header, formData, body)
  let scheme = call_594139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594139.url(scheme.get, call_594139.host, call_594139.base,
                         call_594139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594139, url, valid)

proc call*(call_594140: Call_GetCopyDBSnapshot_594124;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_594141 = newJObject()
  if Tags != nil:
    query_594141.add "Tags", Tags
  add(query_594141, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_594141, "Action", newJString(Action))
  add(query_594141, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_594141, "Version", newJString(Version))
  result = call_594140.call(nil, query_594141, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_594124(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_594125,
    base: "/", url: url_GetCopyDBSnapshot_594126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_594201 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBInstance_594203(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_594202(path: JsonNode; query: JsonNode;
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
  var valid_594204 = query.getOrDefault("Action")
  valid_594204 = validateParameter(valid_594204, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_594204 != nil:
    section.add "Action", valid_594204
  var valid_594205 = query.getOrDefault("Version")
  valid_594205 = validateParameter(valid_594205, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594205 != nil:
    section.add "Version", valid_594205
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
  var valid_594206 = header.getOrDefault("X-Amz-Date")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Date", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-Security-Token")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Security-Token", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Content-Sha256", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Algorithm")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Algorithm", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Signature")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Signature", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-SignedHeaders", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Credential")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Credential", valid_594212
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroups: JArray
  ##   Port: JInt
  ##   Engine: JString (required)
  ##   VpcSecurityGroupIds: JArray
  ##   Iops: JInt
  ##   DBName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   DBParameterGroupName: JString
  ##   OptionGroupName: JString
  ##   Tags: JArray
  ##   MasterUserPassword: JString (required)
  ##   DBSubnetGroupName: JString
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   AllocatedStorage: JInt (required)
  ##   PubliclyAccessible: JBool
  ##   MasterUsername: JString (required)
  ##   DBInstanceClass: JString (required)
  ##   CharacterSetName: JString
  ##   PreferredBackupWindow: JString
  ##   LicenseModel: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   EngineVersion: JString
  ##   PreferredMaintenanceWindow: JString
  section = newJObject()
  var valid_594213 = formData.getOrDefault("DBSecurityGroups")
  valid_594213 = validateParameter(valid_594213, JArray, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "DBSecurityGroups", valid_594213
  var valid_594214 = formData.getOrDefault("Port")
  valid_594214 = validateParameter(valid_594214, JInt, required = false, default = nil)
  if valid_594214 != nil:
    section.add "Port", valid_594214
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_594215 = formData.getOrDefault("Engine")
  valid_594215 = validateParameter(valid_594215, JString, required = true,
                                 default = nil)
  if valid_594215 != nil:
    section.add "Engine", valid_594215
  var valid_594216 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_594216 = validateParameter(valid_594216, JArray, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "VpcSecurityGroupIds", valid_594216
  var valid_594217 = formData.getOrDefault("Iops")
  valid_594217 = validateParameter(valid_594217, JInt, required = false, default = nil)
  if valid_594217 != nil:
    section.add "Iops", valid_594217
  var valid_594218 = formData.getOrDefault("DBName")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "DBName", valid_594218
  var valid_594219 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594219 = validateParameter(valid_594219, JString, required = true,
                                 default = nil)
  if valid_594219 != nil:
    section.add "DBInstanceIdentifier", valid_594219
  var valid_594220 = formData.getOrDefault("BackupRetentionPeriod")
  valid_594220 = validateParameter(valid_594220, JInt, required = false, default = nil)
  if valid_594220 != nil:
    section.add "BackupRetentionPeriod", valid_594220
  var valid_594221 = formData.getOrDefault("DBParameterGroupName")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "DBParameterGroupName", valid_594221
  var valid_594222 = formData.getOrDefault("OptionGroupName")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "OptionGroupName", valid_594222
  var valid_594223 = formData.getOrDefault("Tags")
  valid_594223 = validateParameter(valid_594223, JArray, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "Tags", valid_594223
  var valid_594224 = formData.getOrDefault("MasterUserPassword")
  valid_594224 = validateParameter(valid_594224, JString, required = true,
                                 default = nil)
  if valid_594224 != nil:
    section.add "MasterUserPassword", valid_594224
  var valid_594225 = formData.getOrDefault("DBSubnetGroupName")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "DBSubnetGroupName", valid_594225
  var valid_594226 = formData.getOrDefault("AvailabilityZone")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "AvailabilityZone", valid_594226
  var valid_594227 = formData.getOrDefault("MultiAZ")
  valid_594227 = validateParameter(valid_594227, JBool, required = false, default = nil)
  if valid_594227 != nil:
    section.add "MultiAZ", valid_594227
  var valid_594228 = formData.getOrDefault("AllocatedStorage")
  valid_594228 = validateParameter(valid_594228, JInt, required = true, default = nil)
  if valid_594228 != nil:
    section.add "AllocatedStorage", valid_594228
  var valid_594229 = formData.getOrDefault("PubliclyAccessible")
  valid_594229 = validateParameter(valid_594229, JBool, required = false, default = nil)
  if valid_594229 != nil:
    section.add "PubliclyAccessible", valid_594229
  var valid_594230 = formData.getOrDefault("MasterUsername")
  valid_594230 = validateParameter(valid_594230, JString, required = true,
                                 default = nil)
  if valid_594230 != nil:
    section.add "MasterUsername", valid_594230
  var valid_594231 = formData.getOrDefault("DBInstanceClass")
  valid_594231 = validateParameter(valid_594231, JString, required = true,
                                 default = nil)
  if valid_594231 != nil:
    section.add "DBInstanceClass", valid_594231
  var valid_594232 = formData.getOrDefault("CharacterSetName")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "CharacterSetName", valid_594232
  var valid_594233 = formData.getOrDefault("PreferredBackupWindow")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "PreferredBackupWindow", valid_594233
  var valid_594234 = formData.getOrDefault("LicenseModel")
  valid_594234 = validateParameter(valid_594234, JString, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "LicenseModel", valid_594234
  var valid_594235 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594235 = validateParameter(valid_594235, JBool, required = false, default = nil)
  if valid_594235 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594235
  var valid_594236 = formData.getOrDefault("EngineVersion")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "EngineVersion", valid_594236
  var valid_594237 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "PreferredMaintenanceWindow", valid_594237
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594238: Call_PostCreateDBInstance_594201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594238.validator(path, query, header, formData, body)
  let scheme = call_594238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594238.url(scheme.get, call_594238.host, call_594238.base,
                         call_594238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594238, url, valid)

proc call*(call_594239: Call_PostCreateDBInstance_594201; Engine: string;
          DBInstanceIdentifier: string; MasterUserPassword: string;
          AllocatedStorage: int; MasterUsername: string; DBInstanceClass: string;
          DBSecurityGroups: JsonNode = nil; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; Iops: int = 0; DBName: string = "";
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          OptionGroupName: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; AvailabilityZone: string = "";
          MultiAZ: bool = false; Action: string = "CreateDBInstance";
          PubliclyAccessible: bool = false; CharacterSetName: string = "";
          PreferredBackupWindow: string = ""; LicenseModel: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          Version: string = "2013-09-09"; PreferredMaintenanceWindow: string = ""): Recallable =
  ## postCreateDBInstance
  ##   DBSecurityGroups: JArray
  ##   Port: int
  ##   Engine: string (required)
  ##   VpcSecurityGroupIds: JArray
  ##   Iops: int
  ##   DBName: string
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   DBParameterGroupName: string
  ##   OptionGroupName: string
  ##   Tags: JArray
  ##   MasterUserPassword: string (required)
  ##   DBSubnetGroupName: string
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   AllocatedStorage: int (required)
  ##   PubliclyAccessible: bool
  ##   MasterUsername: string (required)
  ##   DBInstanceClass: string (required)
  ##   CharacterSetName: string
  ##   PreferredBackupWindow: string
  ##   LicenseModel: string
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  var query_594240 = newJObject()
  var formData_594241 = newJObject()
  if DBSecurityGroups != nil:
    formData_594241.add "DBSecurityGroups", DBSecurityGroups
  add(formData_594241, "Port", newJInt(Port))
  add(formData_594241, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_594241.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_594241, "Iops", newJInt(Iops))
  add(formData_594241, "DBName", newJString(DBName))
  add(formData_594241, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594241, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_594241, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_594241, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_594241.add "Tags", Tags
  add(formData_594241, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_594241, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_594241, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_594241, "MultiAZ", newJBool(MultiAZ))
  add(query_594240, "Action", newJString(Action))
  add(formData_594241, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_594241, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_594241, "MasterUsername", newJString(MasterUsername))
  add(formData_594241, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594241, "CharacterSetName", newJString(CharacterSetName))
  add(formData_594241, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_594241, "LicenseModel", newJString(LicenseModel))
  add(formData_594241, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_594241, "EngineVersion", newJString(EngineVersion))
  add(query_594240, "Version", newJString(Version))
  add(formData_594241, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_594239.call(nil, query_594240, nil, formData_594241, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_594201(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_594202, base: "/",
    url: url_PostCreateDBInstance_594203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_594161 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBInstance_594163(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_594162(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##   PreferredMaintenanceWindow: JString
  ##   AllocatedStorage: JInt (required)
  ##   OptionGroupName: JString
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: JString (required)
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: JBool
  ##   LicenseModel: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBName: JString
  ##   DBParameterGroupName: JString
  ##   Tags: JArray
  ##   DBInstanceClass: JString (required)
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##   CharacterSetName: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   EngineVersion: JString
  ##   Port: JInt
  ##   PreferredBackupWindow: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   MasterUsername: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_594164 = query.getOrDefault("Engine")
  valid_594164 = validateParameter(valid_594164, JString, required = true,
                                 default = nil)
  if valid_594164 != nil:
    section.add "Engine", valid_594164
  var valid_594165 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "PreferredMaintenanceWindow", valid_594165
  var valid_594166 = query.getOrDefault("AllocatedStorage")
  valid_594166 = validateParameter(valid_594166, JInt, required = true, default = nil)
  if valid_594166 != nil:
    section.add "AllocatedStorage", valid_594166
  var valid_594167 = query.getOrDefault("OptionGroupName")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "OptionGroupName", valid_594167
  var valid_594168 = query.getOrDefault("DBSecurityGroups")
  valid_594168 = validateParameter(valid_594168, JArray, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "DBSecurityGroups", valid_594168
  var valid_594169 = query.getOrDefault("MasterUserPassword")
  valid_594169 = validateParameter(valid_594169, JString, required = true,
                                 default = nil)
  if valid_594169 != nil:
    section.add "MasterUserPassword", valid_594169
  var valid_594170 = query.getOrDefault("AvailabilityZone")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "AvailabilityZone", valid_594170
  var valid_594171 = query.getOrDefault("Iops")
  valid_594171 = validateParameter(valid_594171, JInt, required = false, default = nil)
  if valid_594171 != nil:
    section.add "Iops", valid_594171
  var valid_594172 = query.getOrDefault("VpcSecurityGroupIds")
  valid_594172 = validateParameter(valid_594172, JArray, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "VpcSecurityGroupIds", valid_594172
  var valid_594173 = query.getOrDefault("MultiAZ")
  valid_594173 = validateParameter(valid_594173, JBool, required = false, default = nil)
  if valid_594173 != nil:
    section.add "MultiAZ", valid_594173
  var valid_594174 = query.getOrDefault("LicenseModel")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "LicenseModel", valid_594174
  var valid_594175 = query.getOrDefault("BackupRetentionPeriod")
  valid_594175 = validateParameter(valid_594175, JInt, required = false, default = nil)
  if valid_594175 != nil:
    section.add "BackupRetentionPeriod", valid_594175
  var valid_594176 = query.getOrDefault("DBName")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "DBName", valid_594176
  var valid_594177 = query.getOrDefault("DBParameterGroupName")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "DBParameterGroupName", valid_594177
  var valid_594178 = query.getOrDefault("Tags")
  valid_594178 = validateParameter(valid_594178, JArray, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "Tags", valid_594178
  var valid_594179 = query.getOrDefault("DBInstanceClass")
  valid_594179 = validateParameter(valid_594179, JString, required = true,
                                 default = nil)
  if valid_594179 != nil:
    section.add "DBInstanceClass", valid_594179
  var valid_594180 = query.getOrDefault("Action")
  valid_594180 = validateParameter(valid_594180, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_594180 != nil:
    section.add "Action", valid_594180
  var valid_594181 = query.getOrDefault("DBSubnetGroupName")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "DBSubnetGroupName", valid_594181
  var valid_594182 = query.getOrDefault("CharacterSetName")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "CharacterSetName", valid_594182
  var valid_594183 = query.getOrDefault("PubliclyAccessible")
  valid_594183 = validateParameter(valid_594183, JBool, required = false, default = nil)
  if valid_594183 != nil:
    section.add "PubliclyAccessible", valid_594183
  var valid_594184 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594184 = validateParameter(valid_594184, JBool, required = false, default = nil)
  if valid_594184 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594184
  var valid_594185 = query.getOrDefault("EngineVersion")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "EngineVersion", valid_594185
  var valid_594186 = query.getOrDefault("Port")
  valid_594186 = validateParameter(valid_594186, JInt, required = false, default = nil)
  if valid_594186 != nil:
    section.add "Port", valid_594186
  var valid_594187 = query.getOrDefault("PreferredBackupWindow")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "PreferredBackupWindow", valid_594187
  var valid_594188 = query.getOrDefault("Version")
  valid_594188 = validateParameter(valid_594188, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594188 != nil:
    section.add "Version", valid_594188
  var valid_594189 = query.getOrDefault("DBInstanceIdentifier")
  valid_594189 = validateParameter(valid_594189, JString, required = true,
                                 default = nil)
  if valid_594189 != nil:
    section.add "DBInstanceIdentifier", valid_594189
  var valid_594190 = query.getOrDefault("MasterUsername")
  valid_594190 = validateParameter(valid_594190, JString, required = true,
                                 default = nil)
  if valid_594190 != nil:
    section.add "MasterUsername", valid_594190
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
  var valid_594191 = header.getOrDefault("X-Amz-Date")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Date", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Security-Token")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Security-Token", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Content-Sha256", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Algorithm")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Algorithm", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Signature")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Signature", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-SignedHeaders", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Credential")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Credential", valid_594197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594198: Call_GetCreateDBInstance_594161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594198.validator(path, query, header, formData, body)
  let scheme = call_594198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594198.url(scheme.get, call_594198.host, call_594198.base,
                         call_594198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594198, url, valid)

proc call*(call_594199: Call_GetCreateDBInstance_594161; Engine: string;
          AllocatedStorage: int; MasterUserPassword: string;
          DBInstanceClass: string; DBInstanceIdentifier: string;
          MasterUsername: string; PreferredMaintenanceWindow: string = "";
          OptionGroupName: string = ""; DBSecurityGroups: JsonNode = nil;
          AvailabilityZone: string = ""; Iops: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; MultiAZ: bool = false;
          LicenseModel: string = ""; BackupRetentionPeriod: int = 0;
          DBName: string = ""; DBParameterGroupName: string = ""; Tags: JsonNode = nil;
          Action: string = "CreateDBInstance"; DBSubnetGroupName: string = "";
          CharacterSetName: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          Port: int = 0; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBInstance
  ##   Engine: string (required)
  ##   PreferredMaintenanceWindow: string
  ##   AllocatedStorage: int (required)
  ##   OptionGroupName: string
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: string (required)
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: bool
  ##   LicenseModel: string
  ##   BackupRetentionPeriod: int
  ##   DBName: string
  ##   DBParameterGroupName: string
  ##   Tags: JArray
  ##   DBInstanceClass: string (required)
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   CharacterSetName: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   Port: int
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   MasterUsername: string (required)
  var query_594200 = newJObject()
  add(query_594200, "Engine", newJString(Engine))
  add(query_594200, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_594200, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_594200, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_594200.add "DBSecurityGroups", DBSecurityGroups
  add(query_594200, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_594200, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594200, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_594200.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_594200, "MultiAZ", newJBool(MultiAZ))
  add(query_594200, "LicenseModel", newJString(LicenseModel))
  add(query_594200, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_594200, "DBName", newJString(DBName))
  add(query_594200, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_594200.add "Tags", Tags
  add(query_594200, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594200, "Action", newJString(Action))
  add(query_594200, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594200, "CharacterSetName", newJString(CharacterSetName))
  add(query_594200, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594200, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594200, "EngineVersion", newJString(EngineVersion))
  add(query_594200, "Port", newJInt(Port))
  add(query_594200, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_594200, "Version", newJString(Version))
  add(query_594200, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594200, "MasterUsername", newJString(MasterUsername))
  result = call_594199.call(nil, query_594200, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_594161(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_594162, base: "/",
    url: url_GetCreateDBInstance_594163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_594268 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBInstanceReadReplica_594270(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_594269(path: JsonNode;
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
  var valid_594271 = query.getOrDefault("Action")
  valid_594271 = validateParameter(valid_594271, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_594271 != nil:
    section.add "Action", valid_594271
  var valid_594272 = query.getOrDefault("Version")
  valid_594272 = validateParameter(valid_594272, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594272 != nil:
    section.add "Version", valid_594272
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
  var valid_594273 = header.getOrDefault("X-Amz-Date")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Date", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Security-Token")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Security-Token", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Content-Sha256", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Algorithm")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Algorithm", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-Signature")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-Signature", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-SignedHeaders", valid_594278
  var valid_594279 = header.getOrDefault("X-Amz-Credential")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "X-Amz-Credential", valid_594279
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   Iops: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   OptionGroupName: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   AvailabilityZone: JString
  ##   PubliclyAccessible: JBool
  ##   DBInstanceClass: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_594280 = formData.getOrDefault("Port")
  valid_594280 = validateParameter(valid_594280, JInt, required = false, default = nil)
  if valid_594280 != nil:
    section.add "Port", valid_594280
  var valid_594281 = formData.getOrDefault("Iops")
  valid_594281 = validateParameter(valid_594281, JInt, required = false, default = nil)
  if valid_594281 != nil:
    section.add "Iops", valid_594281
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594282 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594282 = validateParameter(valid_594282, JString, required = true,
                                 default = nil)
  if valid_594282 != nil:
    section.add "DBInstanceIdentifier", valid_594282
  var valid_594283 = formData.getOrDefault("OptionGroupName")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "OptionGroupName", valid_594283
  var valid_594284 = formData.getOrDefault("Tags")
  valid_594284 = validateParameter(valid_594284, JArray, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "Tags", valid_594284
  var valid_594285 = formData.getOrDefault("DBSubnetGroupName")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "DBSubnetGroupName", valid_594285
  var valid_594286 = formData.getOrDefault("AvailabilityZone")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "AvailabilityZone", valid_594286
  var valid_594287 = formData.getOrDefault("PubliclyAccessible")
  valid_594287 = validateParameter(valid_594287, JBool, required = false, default = nil)
  if valid_594287 != nil:
    section.add "PubliclyAccessible", valid_594287
  var valid_594288 = formData.getOrDefault("DBInstanceClass")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "DBInstanceClass", valid_594288
  var valid_594289 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_594289 = validateParameter(valid_594289, JString, required = true,
                                 default = nil)
  if valid_594289 != nil:
    section.add "SourceDBInstanceIdentifier", valid_594289
  var valid_594290 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594290 = validateParameter(valid_594290, JBool, required = false, default = nil)
  if valid_594290 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594290
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594291: Call_PostCreateDBInstanceReadReplica_594268;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594291.validator(path, query, header, formData, body)
  let scheme = call_594291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594291.url(scheme.get, call_594291.host, call_594291.base,
                         call_594291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594291, url, valid)

proc call*(call_594292: Call_PostCreateDBInstanceReadReplica_594268;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Port: int = 0; Iops: int = 0; OptionGroupName: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; AvailabilityZone: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          PubliclyAccessible: bool = false; DBInstanceClass: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postCreateDBInstanceReadReplica
  ##   Port: int
  ##   Iops: int
  ##   DBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   AvailabilityZone: string
  ##   Action: string (required)
  ##   PubliclyAccessible: bool
  ##   DBInstanceClass: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   Version: string (required)
  var query_594293 = newJObject()
  var formData_594294 = newJObject()
  add(formData_594294, "Port", newJInt(Port))
  add(formData_594294, "Iops", newJInt(Iops))
  add(formData_594294, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594294, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_594294.add "Tags", Tags
  add(formData_594294, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_594294, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594293, "Action", newJString(Action))
  add(formData_594294, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_594294, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594294, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_594294, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_594293, "Version", newJString(Version))
  result = call_594292.call(nil, query_594293, nil, formData_594294, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_594268(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_594269, base: "/",
    url: url_PostCreateDBInstanceReadReplica_594270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_594242 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBInstanceReadReplica_594244(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_594243(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   OptionGroupName: JString
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   Tags: JArray
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_594245 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_594245 = validateParameter(valid_594245, JString, required = true,
                                 default = nil)
  if valid_594245 != nil:
    section.add "SourceDBInstanceIdentifier", valid_594245
  var valid_594246 = query.getOrDefault("OptionGroupName")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "OptionGroupName", valid_594246
  var valid_594247 = query.getOrDefault("AvailabilityZone")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "AvailabilityZone", valid_594247
  var valid_594248 = query.getOrDefault("Iops")
  valid_594248 = validateParameter(valid_594248, JInt, required = false, default = nil)
  if valid_594248 != nil:
    section.add "Iops", valid_594248
  var valid_594249 = query.getOrDefault("Tags")
  valid_594249 = validateParameter(valid_594249, JArray, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "Tags", valid_594249
  var valid_594250 = query.getOrDefault("DBInstanceClass")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "DBInstanceClass", valid_594250
  var valid_594251 = query.getOrDefault("Action")
  valid_594251 = validateParameter(valid_594251, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_594251 != nil:
    section.add "Action", valid_594251
  var valid_594252 = query.getOrDefault("DBSubnetGroupName")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "DBSubnetGroupName", valid_594252
  var valid_594253 = query.getOrDefault("PubliclyAccessible")
  valid_594253 = validateParameter(valid_594253, JBool, required = false, default = nil)
  if valid_594253 != nil:
    section.add "PubliclyAccessible", valid_594253
  var valid_594254 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594254 = validateParameter(valid_594254, JBool, required = false, default = nil)
  if valid_594254 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594254
  var valid_594255 = query.getOrDefault("Port")
  valid_594255 = validateParameter(valid_594255, JInt, required = false, default = nil)
  if valid_594255 != nil:
    section.add "Port", valid_594255
  var valid_594256 = query.getOrDefault("Version")
  valid_594256 = validateParameter(valid_594256, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594256 != nil:
    section.add "Version", valid_594256
  var valid_594257 = query.getOrDefault("DBInstanceIdentifier")
  valid_594257 = validateParameter(valid_594257, JString, required = true,
                                 default = nil)
  if valid_594257 != nil:
    section.add "DBInstanceIdentifier", valid_594257
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
  var valid_594258 = header.getOrDefault("X-Amz-Date")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Date", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Security-Token")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Security-Token", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Content-Sha256", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Algorithm")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Algorithm", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-Signature")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-Signature", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-SignedHeaders", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-Credential")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-Credential", valid_594264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594265: Call_GetCreateDBInstanceReadReplica_594242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594265.validator(path, query, header, formData, body)
  let scheme = call_594265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594265.url(scheme.get, call_594265.host, call_594265.base,
                         call_594265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594265, url, valid)

proc call*(call_594266: Call_GetCreateDBInstanceReadReplica_594242;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          OptionGroupName: string = ""; AvailabilityZone: string = ""; Iops: int = 0;
          Tags: JsonNode = nil; DBInstanceClass: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Port: int = 0;
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   SourceDBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   Tags: JArray
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_594267 = newJObject()
  add(query_594267, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_594267, "OptionGroupName", newJString(OptionGroupName))
  add(query_594267, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594267, "Iops", newJInt(Iops))
  if Tags != nil:
    query_594267.add "Tags", Tags
  add(query_594267, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594267, "Action", newJString(Action))
  add(query_594267, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594267, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594267, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594267, "Port", newJInt(Port))
  add(query_594267, "Version", newJString(Version))
  add(query_594267, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594266.call(nil, query_594267, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_594242(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_594243, base: "/",
    url: url_GetCreateDBInstanceReadReplica_594244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_594314 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBParameterGroup_594316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBParameterGroup_594315(path: JsonNode; query: JsonNode;
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
  var valid_594317 = query.getOrDefault("Action")
  valid_594317 = validateParameter(valid_594317, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_594317 != nil:
    section.add "Action", valid_594317
  var valid_594318 = query.getOrDefault("Version")
  valid_594318 = validateParameter(valid_594318, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594318 != nil:
    section.add "Version", valid_594318
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
  var valid_594319 = header.getOrDefault("X-Amz-Date")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Date", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Security-Token")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Security-Token", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Content-Sha256", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-Algorithm")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-Algorithm", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-Signature")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-Signature", valid_594323
  var valid_594324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "X-Amz-SignedHeaders", valid_594324
  var valid_594325 = header.getOrDefault("X-Amz-Credential")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-Credential", valid_594325
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594326 = formData.getOrDefault("DBParameterGroupName")
  valid_594326 = validateParameter(valid_594326, JString, required = true,
                                 default = nil)
  if valid_594326 != nil:
    section.add "DBParameterGroupName", valid_594326
  var valid_594327 = formData.getOrDefault("Tags")
  valid_594327 = validateParameter(valid_594327, JArray, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "Tags", valid_594327
  var valid_594328 = formData.getOrDefault("DBParameterGroupFamily")
  valid_594328 = validateParameter(valid_594328, JString, required = true,
                                 default = nil)
  if valid_594328 != nil:
    section.add "DBParameterGroupFamily", valid_594328
  var valid_594329 = formData.getOrDefault("Description")
  valid_594329 = validateParameter(valid_594329, JString, required = true,
                                 default = nil)
  if valid_594329 != nil:
    section.add "Description", valid_594329
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594330: Call_PostCreateDBParameterGroup_594314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594330.validator(path, query, header, formData, body)
  let scheme = call_594330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594330.url(scheme.get, call_594330.host, call_594330.base,
                         call_594330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594330, url, valid)

proc call*(call_594331: Call_PostCreateDBParameterGroup_594314;
          DBParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Description: string (required)
  var query_594332 = newJObject()
  var formData_594333 = newJObject()
  add(formData_594333, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_594333.add "Tags", Tags
  add(query_594332, "Action", newJString(Action))
  add(formData_594333, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_594332, "Version", newJString(Version))
  add(formData_594333, "Description", newJString(Description))
  result = call_594331.call(nil, query_594332, nil, formData_594333, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_594314(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_594315, base: "/",
    url: url_PostCreateDBParameterGroup_594316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_594295 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBParameterGroup_594297(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBParameterGroup_594296(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Description: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Description` field"
  var valid_594298 = query.getOrDefault("Description")
  valid_594298 = validateParameter(valid_594298, JString, required = true,
                                 default = nil)
  if valid_594298 != nil:
    section.add "Description", valid_594298
  var valid_594299 = query.getOrDefault("DBParameterGroupFamily")
  valid_594299 = validateParameter(valid_594299, JString, required = true,
                                 default = nil)
  if valid_594299 != nil:
    section.add "DBParameterGroupFamily", valid_594299
  var valid_594300 = query.getOrDefault("Tags")
  valid_594300 = validateParameter(valid_594300, JArray, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "Tags", valid_594300
  var valid_594301 = query.getOrDefault("DBParameterGroupName")
  valid_594301 = validateParameter(valid_594301, JString, required = true,
                                 default = nil)
  if valid_594301 != nil:
    section.add "DBParameterGroupName", valid_594301
  var valid_594302 = query.getOrDefault("Action")
  valid_594302 = validateParameter(valid_594302, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_594302 != nil:
    section.add "Action", valid_594302
  var valid_594303 = query.getOrDefault("Version")
  valid_594303 = validateParameter(valid_594303, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594303 != nil:
    section.add "Version", valid_594303
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
  var valid_594304 = header.getOrDefault("X-Amz-Date")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Date", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Security-Token")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Security-Token", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Content-Sha256", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-Algorithm")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-Algorithm", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Signature")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Signature", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-SignedHeaders", valid_594309
  var valid_594310 = header.getOrDefault("X-Amz-Credential")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-Credential", valid_594310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594311: Call_GetCreateDBParameterGroup_594295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594311.validator(path, query, header, formData, body)
  let scheme = call_594311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594311.url(scheme.get, call_594311.host, call_594311.base,
                         call_594311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594311, url, valid)

proc call*(call_594312: Call_GetCreateDBParameterGroup_594295; Description: string;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Tags: JsonNode = nil; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Tags: JArray
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594313 = newJObject()
  add(query_594313, "Description", newJString(Description))
  add(query_594313, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_594313.add "Tags", Tags
  add(query_594313, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594313, "Action", newJString(Action))
  add(query_594313, "Version", newJString(Version))
  result = call_594312.call(nil, query_594313, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_594295(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_594296, base: "/",
    url: url_GetCreateDBParameterGroup_594297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_594352 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBSecurityGroup_594354(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSecurityGroup_594353(path: JsonNode; query: JsonNode;
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
  var valid_594355 = query.getOrDefault("Action")
  valid_594355 = validateParameter(valid_594355, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_594355 != nil:
    section.add "Action", valid_594355
  var valid_594356 = query.getOrDefault("Version")
  valid_594356 = validateParameter(valid_594356, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594356 != nil:
    section.add "Version", valid_594356
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
  var valid_594357 = header.getOrDefault("X-Amz-Date")
  valid_594357 = validateParameter(valid_594357, JString, required = false,
                                 default = nil)
  if valid_594357 != nil:
    section.add "X-Amz-Date", valid_594357
  var valid_594358 = header.getOrDefault("X-Amz-Security-Token")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = nil)
  if valid_594358 != nil:
    section.add "X-Amz-Security-Token", valid_594358
  var valid_594359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Content-Sha256", valid_594359
  var valid_594360 = header.getOrDefault("X-Amz-Algorithm")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "X-Amz-Algorithm", valid_594360
  var valid_594361 = header.getOrDefault("X-Amz-Signature")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Signature", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-SignedHeaders", valid_594362
  var valid_594363 = header.getOrDefault("X-Amz-Credential")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Credential", valid_594363
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_594364 = formData.getOrDefault("DBSecurityGroupName")
  valid_594364 = validateParameter(valid_594364, JString, required = true,
                                 default = nil)
  if valid_594364 != nil:
    section.add "DBSecurityGroupName", valid_594364
  var valid_594365 = formData.getOrDefault("Tags")
  valid_594365 = validateParameter(valid_594365, JArray, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "Tags", valid_594365
  var valid_594366 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_594366 = validateParameter(valid_594366, JString, required = true,
                                 default = nil)
  if valid_594366 != nil:
    section.add "DBSecurityGroupDescription", valid_594366
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594367: Call_PostCreateDBSecurityGroup_594352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594367.validator(path, query, header, formData, body)
  let scheme = call_594367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594367.url(scheme.get, call_594367.host, call_594367.base,
                         call_594367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594367, url, valid)

proc call*(call_594368: Call_PostCreateDBSecurityGroup_594352;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_594369 = newJObject()
  var formData_594370 = newJObject()
  add(formData_594370, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_594370.add "Tags", Tags
  add(query_594369, "Action", newJString(Action))
  add(formData_594370, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_594369, "Version", newJString(Version))
  result = call_594368.call(nil, query_594369, nil, formData_594370, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_594352(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_594353, base: "/",
    url: url_PostCreateDBSecurityGroup_594354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_594334 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBSecurityGroup_594336(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSecurityGroup_594335(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSecurityGroupName: JString (required)
  ##   DBSecurityGroupDescription: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_594337 = query.getOrDefault("DBSecurityGroupName")
  valid_594337 = validateParameter(valid_594337, JString, required = true,
                                 default = nil)
  if valid_594337 != nil:
    section.add "DBSecurityGroupName", valid_594337
  var valid_594338 = query.getOrDefault("DBSecurityGroupDescription")
  valid_594338 = validateParameter(valid_594338, JString, required = true,
                                 default = nil)
  if valid_594338 != nil:
    section.add "DBSecurityGroupDescription", valid_594338
  var valid_594339 = query.getOrDefault("Tags")
  valid_594339 = validateParameter(valid_594339, JArray, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "Tags", valid_594339
  var valid_594340 = query.getOrDefault("Action")
  valid_594340 = validateParameter(valid_594340, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_594340 != nil:
    section.add "Action", valid_594340
  var valid_594341 = query.getOrDefault("Version")
  valid_594341 = validateParameter(valid_594341, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594341 != nil:
    section.add "Version", valid_594341
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
  var valid_594342 = header.getOrDefault("X-Amz-Date")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-Date", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-Security-Token")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Security-Token", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Content-Sha256", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-Algorithm")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-Algorithm", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-Signature")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Signature", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-SignedHeaders", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Credential")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Credential", valid_594348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594349: Call_GetCreateDBSecurityGroup_594334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594349.validator(path, query, header, formData, body)
  let scheme = call_594349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594349.url(scheme.get, call_594349.host, call_594349.base,
                         call_594349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594349, url, valid)

proc call*(call_594350: Call_GetCreateDBSecurityGroup_594334;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594351 = newJObject()
  add(query_594351, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594351, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_594351.add "Tags", Tags
  add(query_594351, "Action", newJString(Action))
  add(query_594351, "Version", newJString(Version))
  result = call_594350.call(nil, query_594351, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_594334(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_594335, base: "/",
    url: url_GetCreateDBSecurityGroup_594336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_594389 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBSnapshot_594391(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSnapshot_594390(path: JsonNode; query: JsonNode;
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
  var valid_594392 = query.getOrDefault("Action")
  valid_594392 = validateParameter(valid_594392, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_594392 != nil:
    section.add "Action", valid_594392
  var valid_594393 = query.getOrDefault("Version")
  valid_594393 = validateParameter(valid_594393, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594393 != nil:
    section.add "Version", valid_594393
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
  var valid_594394 = header.getOrDefault("X-Amz-Date")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Date", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Security-Token")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Security-Token", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Content-Sha256", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Algorithm")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Algorithm", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Signature")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Signature", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-SignedHeaders", valid_594399
  var valid_594400 = header.getOrDefault("X-Amz-Credential")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-Credential", valid_594400
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594401 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594401 = validateParameter(valid_594401, JString, required = true,
                                 default = nil)
  if valid_594401 != nil:
    section.add "DBInstanceIdentifier", valid_594401
  var valid_594402 = formData.getOrDefault("Tags")
  valid_594402 = validateParameter(valid_594402, JArray, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "Tags", valid_594402
  var valid_594403 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_594403 = validateParameter(valid_594403, JString, required = true,
                                 default = nil)
  if valid_594403 != nil:
    section.add "DBSnapshotIdentifier", valid_594403
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594404: Call_PostCreateDBSnapshot_594389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594404.validator(path, query, header, formData, body)
  let scheme = call_594404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594404.url(scheme.get, call_594404.host, call_594404.base,
                         call_594404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594404, url, valid)

proc call*(call_594405: Call_PostCreateDBSnapshot_594389;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594406 = newJObject()
  var formData_594407 = newJObject()
  add(formData_594407, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_594407.add "Tags", Tags
  add(formData_594407, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_594406, "Action", newJString(Action))
  add(query_594406, "Version", newJString(Version))
  result = call_594405.call(nil, query_594406, nil, formData_594407, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_594389(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_594390, base: "/",
    url: url_PostCreateDBSnapshot_594391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_594371 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBSnapshot_594373(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSnapshot_594372(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  var valid_594374 = query.getOrDefault("Tags")
  valid_594374 = validateParameter(valid_594374, JArray, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "Tags", valid_594374
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594375 = query.getOrDefault("Action")
  valid_594375 = validateParameter(valid_594375, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_594375 != nil:
    section.add "Action", valid_594375
  var valid_594376 = query.getOrDefault("Version")
  valid_594376 = validateParameter(valid_594376, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594376 != nil:
    section.add "Version", valid_594376
  var valid_594377 = query.getOrDefault("DBInstanceIdentifier")
  valid_594377 = validateParameter(valid_594377, JString, required = true,
                                 default = nil)
  if valid_594377 != nil:
    section.add "DBInstanceIdentifier", valid_594377
  var valid_594378 = query.getOrDefault("DBSnapshotIdentifier")
  valid_594378 = validateParameter(valid_594378, JString, required = true,
                                 default = nil)
  if valid_594378 != nil:
    section.add "DBSnapshotIdentifier", valid_594378
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
  var valid_594379 = header.getOrDefault("X-Amz-Date")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Date", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Security-Token")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Security-Token", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Content-Sha256", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Algorithm")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Algorithm", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Signature")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Signature", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-SignedHeaders", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-Credential")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-Credential", valid_594385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594386: Call_GetCreateDBSnapshot_594371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594386.validator(path, query, header, formData, body)
  let scheme = call_594386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594386.url(scheme.get, call_594386.host, call_594386.base,
                         call_594386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594386, url, valid)

proc call*(call_594387: Call_GetCreateDBSnapshot_594371;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_594388 = newJObject()
  if Tags != nil:
    query_594388.add "Tags", Tags
  add(query_594388, "Action", newJString(Action))
  add(query_594388, "Version", newJString(Version))
  add(query_594388, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594388, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_594387.call(nil, query_594388, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_594371(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_594372, base: "/",
    url: url_GetCreateDBSnapshot_594373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_594427 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBSubnetGroup_594429(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_594428(path: JsonNode; query: JsonNode;
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
  var valid_594430 = query.getOrDefault("Action")
  valid_594430 = validateParameter(valid_594430, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_594430 != nil:
    section.add "Action", valid_594430
  var valid_594431 = query.getOrDefault("Version")
  valid_594431 = validateParameter(valid_594431, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594431 != nil:
    section.add "Version", valid_594431
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
  var valid_594432 = header.getOrDefault("X-Amz-Date")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-Date", valid_594432
  var valid_594433 = header.getOrDefault("X-Amz-Security-Token")
  valid_594433 = validateParameter(valid_594433, JString, required = false,
                                 default = nil)
  if valid_594433 != nil:
    section.add "X-Amz-Security-Token", valid_594433
  var valid_594434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594434 = validateParameter(valid_594434, JString, required = false,
                                 default = nil)
  if valid_594434 != nil:
    section.add "X-Amz-Content-Sha256", valid_594434
  var valid_594435 = header.getOrDefault("X-Amz-Algorithm")
  valid_594435 = validateParameter(valid_594435, JString, required = false,
                                 default = nil)
  if valid_594435 != nil:
    section.add "X-Amz-Algorithm", valid_594435
  var valid_594436 = header.getOrDefault("X-Amz-Signature")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "X-Amz-Signature", valid_594436
  var valid_594437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-SignedHeaders", valid_594437
  var valid_594438 = header.getOrDefault("X-Amz-Credential")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "X-Amz-Credential", valid_594438
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_594439 = formData.getOrDefault("Tags")
  valid_594439 = validateParameter(valid_594439, JArray, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "Tags", valid_594439
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_594440 = formData.getOrDefault("DBSubnetGroupName")
  valid_594440 = validateParameter(valid_594440, JString, required = true,
                                 default = nil)
  if valid_594440 != nil:
    section.add "DBSubnetGroupName", valid_594440
  var valid_594441 = formData.getOrDefault("SubnetIds")
  valid_594441 = validateParameter(valid_594441, JArray, required = true, default = nil)
  if valid_594441 != nil:
    section.add "SubnetIds", valid_594441
  var valid_594442 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_594442 = validateParameter(valid_594442, JString, required = true,
                                 default = nil)
  if valid_594442 != nil:
    section.add "DBSubnetGroupDescription", valid_594442
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594443: Call_PostCreateDBSubnetGroup_594427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594443.validator(path, query, header, formData, body)
  let scheme = call_594443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594443.url(scheme.get, call_594443.host, call_594443.base,
                         call_594443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594443, url, valid)

proc call*(call_594444: Call_PostCreateDBSubnetGroup_594427;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSubnetGroup
  ##   Tags: JArray
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_594445 = newJObject()
  var formData_594446 = newJObject()
  if Tags != nil:
    formData_594446.add "Tags", Tags
  add(formData_594446, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_594446.add "SubnetIds", SubnetIds
  add(query_594445, "Action", newJString(Action))
  add(formData_594446, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594445, "Version", newJString(Version))
  result = call_594444.call(nil, query_594445, nil, formData_594446, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_594427(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_594428, base: "/",
    url: url_PostCreateDBSubnetGroup_594429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_594408 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBSubnetGroup_594410(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_594409(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_594411 = query.getOrDefault("Tags")
  valid_594411 = validateParameter(valid_594411, JArray, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "Tags", valid_594411
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594412 = query.getOrDefault("Action")
  valid_594412 = validateParameter(valid_594412, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_594412 != nil:
    section.add "Action", valid_594412
  var valid_594413 = query.getOrDefault("DBSubnetGroupName")
  valid_594413 = validateParameter(valid_594413, JString, required = true,
                                 default = nil)
  if valid_594413 != nil:
    section.add "DBSubnetGroupName", valid_594413
  var valid_594414 = query.getOrDefault("SubnetIds")
  valid_594414 = validateParameter(valid_594414, JArray, required = true, default = nil)
  if valid_594414 != nil:
    section.add "SubnetIds", valid_594414
  var valid_594415 = query.getOrDefault("DBSubnetGroupDescription")
  valid_594415 = validateParameter(valid_594415, JString, required = true,
                                 default = nil)
  if valid_594415 != nil:
    section.add "DBSubnetGroupDescription", valid_594415
  var valid_594416 = query.getOrDefault("Version")
  valid_594416 = validateParameter(valid_594416, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594416 != nil:
    section.add "Version", valid_594416
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
  var valid_594417 = header.getOrDefault("X-Amz-Date")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-Date", valid_594417
  var valid_594418 = header.getOrDefault("X-Amz-Security-Token")
  valid_594418 = validateParameter(valid_594418, JString, required = false,
                                 default = nil)
  if valid_594418 != nil:
    section.add "X-Amz-Security-Token", valid_594418
  var valid_594419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594419 = validateParameter(valid_594419, JString, required = false,
                                 default = nil)
  if valid_594419 != nil:
    section.add "X-Amz-Content-Sha256", valid_594419
  var valid_594420 = header.getOrDefault("X-Amz-Algorithm")
  valid_594420 = validateParameter(valid_594420, JString, required = false,
                                 default = nil)
  if valid_594420 != nil:
    section.add "X-Amz-Algorithm", valid_594420
  var valid_594421 = header.getOrDefault("X-Amz-Signature")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-Signature", valid_594421
  var valid_594422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-SignedHeaders", valid_594422
  var valid_594423 = header.getOrDefault("X-Amz-Credential")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "X-Amz-Credential", valid_594423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594424: Call_GetCreateDBSubnetGroup_594408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594424.validator(path, query, header, formData, body)
  let scheme = call_594424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594424.url(scheme.get, call_594424.host, call_594424.base,
                         call_594424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594424, url, valid)

proc call*(call_594425: Call_GetCreateDBSubnetGroup_594408;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_594426 = newJObject()
  if Tags != nil:
    query_594426.add "Tags", Tags
  add(query_594426, "Action", newJString(Action))
  add(query_594426, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_594426.add "SubnetIds", SubnetIds
  add(query_594426, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594426, "Version", newJString(Version))
  result = call_594425.call(nil, query_594426, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_594408(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_594409, base: "/",
    url: url_GetCreateDBSubnetGroup_594410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_594469 = ref object of OpenApiRestCall_593421
proc url_PostCreateEventSubscription_594471(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEventSubscription_594470(path: JsonNode; query: JsonNode;
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
  var valid_594472 = query.getOrDefault("Action")
  valid_594472 = validateParameter(valid_594472, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_594472 != nil:
    section.add "Action", valid_594472
  var valid_594473 = query.getOrDefault("Version")
  valid_594473 = validateParameter(valid_594473, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594473 != nil:
    section.add "Version", valid_594473
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
  var valid_594474 = header.getOrDefault("X-Amz-Date")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Date", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-Security-Token")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Security-Token", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-Content-Sha256", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-Algorithm")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-Algorithm", valid_594477
  var valid_594478 = header.getOrDefault("X-Amz-Signature")
  valid_594478 = validateParameter(valid_594478, JString, required = false,
                                 default = nil)
  if valid_594478 != nil:
    section.add "X-Amz-Signature", valid_594478
  var valid_594479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594479 = validateParameter(valid_594479, JString, required = false,
                                 default = nil)
  if valid_594479 != nil:
    section.add "X-Amz-SignedHeaders", valid_594479
  var valid_594480 = header.getOrDefault("X-Amz-Credential")
  valid_594480 = validateParameter(valid_594480, JString, required = false,
                                 default = nil)
  if valid_594480 != nil:
    section.add "X-Amz-Credential", valid_594480
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString (required)
  ##   SourceIds: JArray
  ##   Tags: JArray
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_594481 = formData.getOrDefault("Enabled")
  valid_594481 = validateParameter(valid_594481, JBool, required = false, default = nil)
  if valid_594481 != nil:
    section.add "Enabled", valid_594481
  var valid_594482 = formData.getOrDefault("EventCategories")
  valid_594482 = validateParameter(valid_594482, JArray, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "EventCategories", valid_594482
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_594483 = formData.getOrDefault("SnsTopicArn")
  valid_594483 = validateParameter(valid_594483, JString, required = true,
                                 default = nil)
  if valid_594483 != nil:
    section.add "SnsTopicArn", valid_594483
  var valid_594484 = formData.getOrDefault("SourceIds")
  valid_594484 = validateParameter(valid_594484, JArray, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "SourceIds", valid_594484
  var valid_594485 = formData.getOrDefault("Tags")
  valid_594485 = validateParameter(valid_594485, JArray, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "Tags", valid_594485
  var valid_594486 = formData.getOrDefault("SubscriptionName")
  valid_594486 = validateParameter(valid_594486, JString, required = true,
                                 default = nil)
  if valid_594486 != nil:
    section.add "SubscriptionName", valid_594486
  var valid_594487 = formData.getOrDefault("SourceType")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "SourceType", valid_594487
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594488: Call_PostCreateEventSubscription_594469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594488.validator(path, query, header, formData, body)
  let scheme = call_594488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594488.url(scheme.get, call_594488.host, call_594488.base,
                         call_594488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594488, url, valid)

proc call*(call_594489: Call_PostCreateEventSubscription_594469;
          SnsTopicArn: string; SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SourceIds: JsonNode = nil;
          Tags: JsonNode = nil; Action: string = "CreateEventSubscription";
          Version: string = "2013-09-09"; SourceType: string = ""): Recallable =
  ## postCreateEventSubscription
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   SnsTopicArn: string (required)
  ##   SourceIds: JArray
  ##   Tags: JArray
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_594490 = newJObject()
  var formData_594491 = newJObject()
  add(formData_594491, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_594491.add "EventCategories", EventCategories
  add(formData_594491, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_594491.add "SourceIds", SourceIds
  if Tags != nil:
    formData_594491.add "Tags", Tags
  add(formData_594491, "SubscriptionName", newJString(SubscriptionName))
  add(query_594490, "Action", newJString(Action))
  add(query_594490, "Version", newJString(Version))
  add(formData_594491, "SourceType", newJString(SourceType))
  result = call_594489.call(nil, query_594490, nil, formData_594491, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_594469(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_594470, base: "/",
    url: url_PostCreateEventSubscription_594471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_594447 = ref object of OpenApiRestCall_593421
proc url_GetCreateEventSubscription_594449(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEventSubscription_594448(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   SourceIds: JArray
  ##   Enabled: JBool
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   SnsTopicArn: JString (required)
  ##   EventCategories: JArray
  ##   SubscriptionName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_594450 = query.getOrDefault("SourceType")
  valid_594450 = validateParameter(valid_594450, JString, required = false,
                                 default = nil)
  if valid_594450 != nil:
    section.add "SourceType", valid_594450
  var valid_594451 = query.getOrDefault("SourceIds")
  valid_594451 = validateParameter(valid_594451, JArray, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "SourceIds", valid_594451
  var valid_594452 = query.getOrDefault("Enabled")
  valid_594452 = validateParameter(valid_594452, JBool, required = false, default = nil)
  if valid_594452 != nil:
    section.add "Enabled", valid_594452
  var valid_594453 = query.getOrDefault("Tags")
  valid_594453 = validateParameter(valid_594453, JArray, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "Tags", valid_594453
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594454 = query.getOrDefault("Action")
  valid_594454 = validateParameter(valid_594454, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_594454 != nil:
    section.add "Action", valid_594454
  var valid_594455 = query.getOrDefault("SnsTopicArn")
  valid_594455 = validateParameter(valid_594455, JString, required = true,
                                 default = nil)
  if valid_594455 != nil:
    section.add "SnsTopicArn", valid_594455
  var valid_594456 = query.getOrDefault("EventCategories")
  valid_594456 = validateParameter(valid_594456, JArray, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "EventCategories", valid_594456
  var valid_594457 = query.getOrDefault("SubscriptionName")
  valid_594457 = validateParameter(valid_594457, JString, required = true,
                                 default = nil)
  if valid_594457 != nil:
    section.add "SubscriptionName", valid_594457
  var valid_594458 = query.getOrDefault("Version")
  valid_594458 = validateParameter(valid_594458, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594458 != nil:
    section.add "Version", valid_594458
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
  var valid_594459 = header.getOrDefault("X-Amz-Date")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Date", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-Security-Token")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Security-Token", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-Content-Sha256", valid_594461
  var valid_594462 = header.getOrDefault("X-Amz-Algorithm")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "X-Amz-Algorithm", valid_594462
  var valid_594463 = header.getOrDefault("X-Amz-Signature")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "X-Amz-Signature", valid_594463
  var valid_594464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594464 = validateParameter(valid_594464, JString, required = false,
                                 default = nil)
  if valid_594464 != nil:
    section.add "X-Amz-SignedHeaders", valid_594464
  var valid_594465 = header.getOrDefault("X-Amz-Credential")
  valid_594465 = validateParameter(valid_594465, JString, required = false,
                                 default = nil)
  if valid_594465 != nil:
    section.add "X-Amz-Credential", valid_594465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594466: Call_GetCreateEventSubscription_594447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594466.validator(path, query, header, formData, body)
  let scheme = call_594466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594466.url(scheme.get, call_594466.host, call_594466.base,
                         call_594466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594466, url, valid)

proc call*(call_594467: Call_GetCreateEventSubscription_594447;
          SnsTopicArn: string; SubscriptionName: string; SourceType: string = "";
          SourceIds: JsonNode = nil; Enabled: bool = false; Tags: JsonNode = nil;
          Action: string = "CreateEventSubscription";
          EventCategories: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## getCreateEventSubscription
  ##   SourceType: string
  ##   SourceIds: JArray
  ##   Enabled: bool
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string (required)
  ##   EventCategories: JArray
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_594468 = newJObject()
  add(query_594468, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_594468.add "SourceIds", SourceIds
  add(query_594468, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_594468.add "Tags", Tags
  add(query_594468, "Action", newJString(Action))
  add(query_594468, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_594468.add "EventCategories", EventCategories
  add(query_594468, "SubscriptionName", newJString(SubscriptionName))
  add(query_594468, "Version", newJString(Version))
  result = call_594467.call(nil, query_594468, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_594447(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_594448, base: "/",
    url: url_GetCreateEventSubscription_594449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_594512 = ref object of OpenApiRestCall_593421
proc url_PostCreateOptionGroup_594514(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateOptionGroup_594513(path: JsonNode; query: JsonNode;
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
  var valid_594515 = query.getOrDefault("Action")
  valid_594515 = validateParameter(valid_594515, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_594515 != nil:
    section.add "Action", valid_594515
  var valid_594516 = query.getOrDefault("Version")
  valid_594516 = validateParameter(valid_594516, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594516 != nil:
    section.add "Version", valid_594516
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
  var valid_594517 = header.getOrDefault("X-Amz-Date")
  valid_594517 = validateParameter(valid_594517, JString, required = false,
                                 default = nil)
  if valid_594517 != nil:
    section.add "X-Amz-Date", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-Security-Token")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Security-Token", valid_594518
  var valid_594519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Content-Sha256", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-Algorithm")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Algorithm", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-Signature")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Signature", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-SignedHeaders", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-Credential")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-Credential", valid_594523
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_594524 = formData.getOrDefault("MajorEngineVersion")
  valid_594524 = validateParameter(valid_594524, JString, required = true,
                                 default = nil)
  if valid_594524 != nil:
    section.add "MajorEngineVersion", valid_594524
  var valid_594525 = formData.getOrDefault("OptionGroupName")
  valid_594525 = validateParameter(valid_594525, JString, required = true,
                                 default = nil)
  if valid_594525 != nil:
    section.add "OptionGroupName", valid_594525
  var valid_594526 = formData.getOrDefault("Tags")
  valid_594526 = validateParameter(valid_594526, JArray, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "Tags", valid_594526
  var valid_594527 = formData.getOrDefault("EngineName")
  valid_594527 = validateParameter(valid_594527, JString, required = true,
                                 default = nil)
  if valid_594527 != nil:
    section.add "EngineName", valid_594527
  var valid_594528 = formData.getOrDefault("OptionGroupDescription")
  valid_594528 = validateParameter(valid_594528, JString, required = true,
                                 default = nil)
  if valid_594528 != nil:
    section.add "OptionGroupDescription", valid_594528
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594529: Call_PostCreateOptionGroup_594512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594529.validator(path, query, header, formData, body)
  let scheme = call_594529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594529.url(scheme.get, call_594529.host, call_594529.base,
                         call_594529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594529, url, valid)

proc call*(call_594530: Call_PostCreateOptionGroup_594512;
          MajorEngineVersion: string; OptionGroupName: string; EngineName: string;
          OptionGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postCreateOptionGroup
  ##   MajorEngineVersion: string (required)
  ##   OptionGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Version: string (required)
  var query_594531 = newJObject()
  var formData_594532 = newJObject()
  add(formData_594532, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_594532, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_594532.add "Tags", Tags
  add(query_594531, "Action", newJString(Action))
  add(formData_594532, "EngineName", newJString(EngineName))
  add(formData_594532, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_594531, "Version", newJString(Version))
  result = call_594530.call(nil, query_594531, nil, formData_594532, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_594512(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_594513, base: "/",
    url: url_PostCreateOptionGroup_594514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_594492 = ref object of OpenApiRestCall_593421
proc url_GetCreateOptionGroup_594494(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateOptionGroup_594493(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   OptionGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `OptionGroupName` field"
  var valid_594495 = query.getOrDefault("OptionGroupName")
  valid_594495 = validateParameter(valid_594495, JString, required = true,
                                 default = nil)
  if valid_594495 != nil:
    section.add "OptionGroupName", valid_594495
  var valid_594496 = query.getOrDefault("Tags")
  valid_594496 = validateParameter(valid_594496, JArray, required = false,
                                 default = nil)
  if valid_594496 != nil:
    section.add "Tags", valid_594496
  var valid_594497 = query.getOrDefault("OptionGroupDescription")
  valid_594497 = validateParameter(valid_594497, JString, required = true,
                                 default = nil)
  if valid_594497 != nil:
    section.add "OptionGroupDescription", valid_594497
  var valid_594498 = query.getOrDefault("Action")
  valid_594498 = validateParameter(valid_594498, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_594498 != nil:
    section.add "Action", valid_594498
  var valid_594499 = query.getOrDefault("Version")
  valid_594499 = validateParameter(valid_594499, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594499 != nil:
    section.add "Version", valid_594499
  var valid_594500 = query.getOrDefault("EngineName")
  valid_594500 = validateParameter(valid_594500, JString, required = true,
                                 default = nil)
  if valid_594500 != nil:
    section.add "EngineName", valid_594500
  var valid_594501 = query.getOrDefault("MajorEngineVersion")
  valid_594501 = validateParameter(valid_594501, JString, required = true,
                                 default = nil)
  if valid_594501 != nil:
    section.add "MajorEngineVersion", valid_594501
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
  var valid_594502 = header.getOrDefault("X-Amz-Date")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-Date", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Security-Token")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Security-Token", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Content-Sha256", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Algorithm")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Algorithm", valid_594505
  var valid_594506 = header.getOrDefault("X-Amz-Signature")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-Signature", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-SignedHeaders", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-Credential")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-Credential", valid_594508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594509: Call_GetCreateOptionGroup_594492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594509.validator(path, query, header, formData, body)
  let scheme = call_594509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594509.url(scheme.get, call_594509.host, call_594509.base,
                         call_594509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594509, url, valid)

proc call*(call_594510: Call_GetCreateOptionGroup_594492; OptionGroupName: string;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getCreateOptionGroup
  ##   OptionGroupName: string (required)
  ##   Tags: JArray
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  var query_594511 = newJObject()
  add(query_594511, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_594511.add "Tags", Tags
  add(query_594511, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_594511, "Action", newJString(Action))
  add(query_594511, "Version", newJString(Version))
  add(query_594511, "EngineName", newJString(EngineName))
  add(query_594511, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_594510.call(nil, query_594511, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_594492(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_594493, base: "/",
    url: url_GetCreateOptionGroup_594494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_594551 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBInstance_594553(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_594552(path: JsonNode; query: JsonNode;
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
  var valid_594554 = query.getOrDefault("Action")
  valid_594554 = validateParameter(valid_594554, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_594554 != nil:
    section.add "Action", valid_594554
  var valid_594555 = query.getOrDefault("Version")
  valid_594555 = validateParameter(valid_594555, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594555 != nil:
    section.add "Version", valid_594555
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
  var valid_594556 = header.getOrDefault("X-Amz-Date")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Date", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-Security-Token")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-Security-Token", valid_594557
  var valid_594558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594558 = validateParameter(valid_594558, JString, required = false,
                                 default = nil)
  if valid_594558 != nil:
    section.add "X-Amz-Content-Sha256", valid_594558
  var valid_594559 = header.getOrDefault("X-Amz-Algorithm")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-Algorithm", valid_594559
  var valid_594560 = header.getOrDefault("X-Amz-Signature")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Signature", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-SignedHeaders", valid_594561
  var valid_594562 = header.getOrDefault("X-Amz-Credential")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-Credential", valid_594562
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594563 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594563 = validateParameter(valid_594563, JString, required = true,
                                 default = nil)
  if valid_594563 != nil:
    section.add "DBInstanceIdentifier", valid_594563
  var valid_594564 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_594564 = validateParameter(valid_594564, JString, required = false,
                                 default = nil)
  if valid_594564 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_594564
  var valid_594565 = formData.getOrDefault("SkipFinalSnapshot")
  valid_594565 = validateParameter(valid_594565, JBool, required = false, default = nil)
  if valid_594565 != nil:
    section.add "SkipFinalSnapshot", valid_594565
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594566: Call_PostDeleteDBInstance_594551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594566.validator(path, query, header, formData, body)
  let scheme = call_594566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594566.url(scheme.get, call_594566.host, call_594566.base,
                         call_594566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594566, url, valid)

proc call*(call_594567: Call_PostDeleteDBInstance_594551;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-09-09";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_594568 = newJObject()
  var formData_594569 = newJObject()
  add(formData_594569, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594569, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_594568, "Action", newJString(Action))
  add(query_594568, "Version", newJString(Version))
  add(formData_594569, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_594567.call(nil, query_594568, nil, formData_594569, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_594551(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_594552, base: "/",
    url: url_PostDeleteDBInstance_594553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_594533 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBInstance_594535(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_594534(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FinalDBSnapshotIdentifier: JString
  ##   Action: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_594536 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_594536
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594537 = query.getOrDefault("Action")
  valid_594537 = validateParameter(valid_594537, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_594537 != nil:
    section.add "Action", valid_594537
  var valid_594538 = query.getOrDefault("SkipFinalSnapshot")
  valid_594538 = validateParameter(valid_594538, JBool, required = false, default = nil)
  if valid_594538 != nil:
    section.add "SkipFinalSnapshot", valid_594538
  var valid_594539 = query.getOrDefault("Version")
  valid_594539 = validateParameter(valid_594539, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594539 != nil:
    section.add "Version", valid_594539
  var valid_594540 = query.getOrDefault("DBInstanceIdentifier")
  valid_594540 = validateParameter(valid_594540, JString, required = true,
                                 default = nil)
  if valid_594540 != nil:
    section.add "DBInstanceIdentifier", valid_594540
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
  var valid_594541 = header.getOrDefault("X-Amz-Date")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-Date", valid_594541
  var valid_594542 = header.getOrDefault("X-Amz-Security-Token")
  valid_594542 = validateParameter(valid_594542, JString, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "X-Amz-Security-Token", valid_594542
  var valid_594543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594543 = validateParameter(valid_594543, JString, required = false,
                                 default = nil)
  if valid_594543 != nil:
    section.add "X-Amz-Content-Sha256", valid_594543
  var valid_594544 = header.getOrDefault("X-Amz-Algorithm")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "X-Amz-Algorithm", valid_594544
  var valid_594545 = header.getOrDefault("X-Amz-Signature")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-Signature", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-SignedHeaders", valid_594546
  var valid_594547 = header.getOrDefault("X-Amz-Credential")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "X-Amz-Credential", valid_594547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594548: Call_GetDeleteDBInstance_594533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594548.validator(path, query, header, formData, body)
  let scheme = call_594548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594548.url(scheme.get, call_594548.host, call_594548.base,
                         call_594548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594548, url, valid)

proc call*(call_594549: Call_GetDeleteDBInstance_594533;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_594550 = newJObject()
  add(query_594550, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_594550, "Action", newJString(Action))
  add(query_594550, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_594550, "Version", newJString(Version))
  add(query_594550, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594549.call(nil, query_594550, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_594533(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_594534, base: "/",
    url: url_GetDeleteDBInstance_594535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_594586 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBParameterGroup_594588(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBParameterGroup_594587(path: JsonNode; query: JsonNode;
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
  var valid_594589 = query.getOrDefault("Action")
  valid_594589 = validateParameter(valid_594589, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_594589 != nil:
    section.add "Action", valid_594589
  var valid_594590 = query.getOrDefault("Version")
  valid_594590 = validateParameter(valid_594590, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594590 != nil:
    section.add "Version", valid_594590
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
  var valid_594591 = header.getOrDefault("X-Amz-Date")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Date", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-Security-Token")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-Security-Token", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Content-Sha256", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Algorithm")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Algorithm", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-Signature")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-Signature", valid_594595
  var valid_594596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-SignedHeaders", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-Credential")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-Credential", valid_594597
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594598 = formData.getOrDefault("DBParameterGroupName")
  valid_594598 = validateParameter(valid_594598, JString, required = true,
                                 default = nil)
  if valid_594598 != nil:
    section.add "DBParameterGroupName", valid_594598
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594599: Call_PostDeleteDBParameterGroup_594586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594599.validator(path, query, header, formData, body)
  let scheme = call_594599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594599.url(scheme.get, call_594599.host, call_594599.base,
                         call_594599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594599, url, valid)

proc call*(call_594600: Call_PostDeleteDBParameterGroup_594586;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594601 = newJObject()
  var formData_594602 = newJObject()
  add(formData_594602, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594601, "Action", newJString(Action))
  add(query_594601, "Version", newJString(Version))
  result = call_594600.call(nil, query_594601, nil, formData_594602, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_594586(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_594587, base: "/",
    url: url_PostDeleteDBParameterGroup_594588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_594570 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBParameterGroup_594572(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBParameterGroup_594571(path: JsonNode; query: JsonNode;
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
  var valid_594573 = query.getOrDefault("DBParameterGroupName")
  valid_594573 = validateParameter(valid_594573, JString, required = true,
                                 default = nil)
  if valid_594573 != nil:
    section.add "DBParameterGroupName", valid_594573
  var valid_594574 = query.getOrDefault("Action")
  valid_594574 = validateParameter(valid_594574, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_594574 != nil:
    section.add "Action", valid_594574
  var valid_594575 = query.getOrDefault("Version")
  valid_594575 = validateParameter(valid_594575, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594575 != nil:
    section.add "Version", valid_594575
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
  var valid_594576 = header.getOrDefault("X-Amz-Date")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-Date", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-Security-Token")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-Security-Token", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Content-Sha256", valid_594578
  var valid_594579 = header.getOrDefault("X-Amz-Algorithm")
  valid_594579 = validateParameter(valid_594579, JString, required = false,
                                 default = nil)
  if valid_594579 != nil:
    section.add "X-Amz-Algorithm", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Signature")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Signature", valid_594580
  var valid_594581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594581 = validateParameter(valid_594581, JString, required = false,
                                 default = nil)
  if valid_594581 != nil:
    section.add "X-Amz-SignedHeaders", valid_594581
  var valid_594582 = header.getOrDefault("X-Amz-Credential")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-Credential", valid_594582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594583: Call_GetDeleteDBParameterGroup_594570; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594583.validator(path, query, header, formData, body)
  let scheme = call_594583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594583.url(scheme.get, call_594583.host, call_594583.base,
                         call_594583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594583, url, valid)

proc call*(call_594584: Call_GetDeleteDBParameterGroup_594570;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594585 = newJObject()
  add(query_594585, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594585, "Action", newJString(Action))
  add(query_594585, "Version", newJString(Version))
  result = call_594584.call(nil, query_594585, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_594570(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_594571, base: "/",
    url: url_GetDeleteDBParameterGroup_594572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_594619 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBSecurityGroup_594621(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSecurityGroup_594620(path: JsonNode; query: JsonNode;
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
  var valid_594622 = query.getOrDefault("Action")
  valid_594622 = validateParameter(valid_594622, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_594622 != nil:
    section.add "Action", valid_594622
  var valid_594623 = query.getOrDefault("Version")
  valid_594623 = validateParameter(valid_594623, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594623 != nil:
    section.add "Version", valid_594623
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
  var valid_594624 = header.getOrDefault("X-Amz-Date")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-Date", valid_594624
  var valid_594625 = header.getOrDefault("X-Amz-Security-Token")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Security-Token", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Content-Sha256", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-Algorithm")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Algorithm", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-Signature")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Signature", valid_594628
  var valid_594629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "X-Amz-SignedHeaders", valid_594629
  var valid_594630 = header.getOrDefault("X-Amz-Credential")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "X-Amz-Credential", valid_594630
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_594631 = formData.getOrDefault("DBSecurityGroupName")
  valid_594631 = validateParameter(valid_594631, JString, required = true,
                                 default = nil)
  if valid_594631 != nil:
    section.add "DBSecurityGroupName", valid_594631
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594632: Call_PostDeleteDBSecurityGroup_594619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594632.validator(path, query, header, formData, body)
  let scheme = call_594632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594632.url(scheme.get, call_594632.host, call_594632.base,
                         call_594632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594632, url, valid)

proc call*(call_594633: Call_PostDeleteDBSecurityGroup_594619;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594634 = newJObject()
  var formData_594635 = newJObject()
  add(formData_594635, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594634, "Action", newJString(Action))
  add(query_594634, "Version", newJString(Version))
  result = call_594633.call(nil, query_594634, nil, formData_594635, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_594619(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_594620, base: "/",
    url: url_PostDeleteDBSecurityGroup_594621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_594603 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBSecurityGroup_594605(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSecurityGroup_594604(path: JsonNode; query: JsonNode;
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
  var valid_594606 = query.getOrDefault("DBSecurityGroupName")
  valid_594606 = validateParameter(valid_594606, JString, required = true,
                                 default = nil)
  if valid_594606 != nil:
    section.add "DBSecurityGroupName", valid_594606
  var valid_594607 = query.getOrDefault("Action")
  valid_594607 = validateParameter(valid_594607, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_594607 != nil:
    section.add "Action", valid_594607
  var valid_594608 = query.getOrDefault("Version")
  valid_594608 = validateParameter(valid_594608, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594608 != nil:
    section.add "Version", valid_594608
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
  var valid_594609 = header.getOrDefault("X-Amz-Date")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Date", valid_594609
  var valid_594610 = header.getOrDefault("X-Amz-Security-Token")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-Security-Token", valid_594610
  var valid_594611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Content-Sha256", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-Algorithm")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-Algorithm", valid_594612
  var valid_594613 = header.getOrDefault("X-Amz-Signature")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "X-Amz-Signature", valid_594613
  var valid_594614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "X-Amz-SignedHeaders", valid_594614
  var valid_594615 = header.getOrDefault("X-Amz-Credential")
  valid_594615 = validateParameter(valid_594615, JString, required = false,
                                 default = nil)
  if valid_594615 != nil:
    section.add "X-Amz-Credential", valid_594615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594616: Call_GetDeleteDBSecurityGroup_594603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594616.validator(path, query, header, formData, body)
  let scheme = call_594616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594616.url(scheme.get, call_594616.host, call_594616.base,
                         call_594616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594616, url, valid)

proc call*(call_594617: Call_GetDeleteDBSecurityGroup_594603;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594618 = newJObject()
  add(query_594618, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594618, "Action", newJString(Action))
  add(query_594618, "Version", newJString(Version))
  result = call_594617.call(nil, query_594618, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_594603(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_594604, base: "/",
    url: url_GetDeleteDBSecurityGroup_594605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_594652 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBSnapshot_594654(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSnapshot_594653(path: JsonNode; query: JsonNode;
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
  var valid_594655 = query.getOrDefault("Action")
  valid_594655 = validateParameter(valid_594655, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_594655 != nil:
    section.add "Action", valid_594655
  var valid_594656 = query.getOrDefault("Version")
  valid_594656 = validateParameter(valid_594656, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594656 != nil:
    section.add "Version", valid_594656
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
  var valid_594657 = header.getOrDefault("X-Amz-Date")
  valid_594657 = validateParameter(valid_594657, JString, required = false,
                                 default = nil)
  if valid_594657 != nil:
    section.add "X-Amz-Date", valid_594657
  var valid_594658 = header.getOrDefault("X-Amz-Security-Token")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-Security-Token", valid_594658
  var valid_594659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594659 = validateParameter(valid_594659, JString, required = false,
                                 default = nil)
  if valid_594659 != nil:
    section.add "X-Amz-Content-Sha256", valid_594659
  var valid_594660 = header.getOrDefault("X-Amz-Algorithm")
  valid_594660 = validateParameter(valid_594660, JString, required = false,
                                 default = nil)
  if valid_594660 != nil:
    section.add "X-Amz-Algorithm", valid_594660
  var valid_594661 = header.getOrDefault("X-Amz-Signature")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-Signature", valid_594661
  var valid_594662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-SignedHeaders", valid_594662
  var valid_594663 = header.getOrDefault("X-Amz-Credential")
  valid_594663 = validateParameter(valid_594663, JString, required = false,
                                 default = nil)
  if valid_594663 != nil:
    section.add "X-Amz-Credential", valid_594663
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_594664 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_594664 = validateParameter(valid_594664, JString, required = true,
                                 default = nil)
  if valid_594664 != nil:
    section.add "DBSnapshotIdentifier", valid_594664
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594665: Call_PostDeleteDBSnapshot_594652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594665.validator(path, query, header, formData, body)
  let scheme = call_594665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594665.url(scheme.get, call_594665.host, call_594665.base,
                         call_594665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594665, url, valid)

proc call*(call_594666: Call_PostDeleteDBSnapshot_594652;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594667 = newJObject()
  var formData_594668 = newJObject()
  add(formData_594668, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_594667, "Action", newJString(Action))
  add(query_594667, "Version", newJString(Version))
  result = call_594666.call(nil, query_594667, nil, formData_594668, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_594652(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_594653, base: "/",
    url: url_PostDeleteDBSnapshot_594654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_594636 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBSnapshot_594638(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSnapshot_594637(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594639 = query.getOrDefault("Action")
  valid_594639 = validateParameter(valid_594639, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_594639 != nil:
    section.add "Action", valid_594639
  var valid_594640 = query.getOrDefault("Version")
  valid_594640 = validateParameter(valid_594640, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594640 != nil:
    section.add "Version", valid_594640
  var valid_594641 = query.getOrDefault("DBSnapshotIdentifier")
  valid_594641 = validateParameter(valid_594641, JString, required = true,
                                 default = nil)
  if valid_594641 != nil:
    section.add "DBSnapshotIdentifier", valid_594641
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
  var valid_594642 = header.getOrDefault("X-Amz-Date")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "X-Amz-Date", valid_594642
  var valid_594643 = header.getOrDefault("X-Amz-Security-Token")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "X-Amz-Security-Token", valid_594643
  var valid_594644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594644 = validateParameter(valid_594644, JString, required = false,
                                 default = nil)
  if valid_594644 != nil:
    section.add "X-Amz-Content-Sha256", valid_594644
  var valid_594645 = header.getOrDefault("X-Amz-Algorithm")
  valid_594645 = validateParameter(valid_594645, JString, required = false,
                                 default = nil)
  if valid_594645 != nil:
    section.add "X-Amz-Algorithm", valid_594645
  var valid_594646 = header.getOrDefault("X-Amz-Signature")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "X-Amz-Signature", valid_594646
  var valid_594647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "X-Amz-SignedHeaders", valid_594647
  var valid_594648 = header.getOrDefault("X-Amz-Credential")
  valid_594648 = validateParameter(valid_594648, JString, required = false,
                                 default = nil)
  if valid_594648 != nil:
    section.add "X-Amz-Credential", valid_594648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594649: Call_GetDeleteDBSnapshot_594636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594649.validator(path, query, header, formData, body)
  let scheme = call_594649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594649.url(scheme.get, call_594649.host, call_594649.base,
                         call_594649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594649, url, valid)

proc call*(call_594650: Call_GetDeleteDBSnapshot_594636;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_594651 = newJObject()
  add(query_594651, "Action", newJString(Action))
  add(query_594651, "Version", newJString(Version))
  add(query_594651, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_594650.call(nil, query_594651, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_594636(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_594637, base: "/",
    url: url_GetDeleteDBSnapshot_594638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_594685 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBSubnetGroup_594687(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_594686(path: JsonNode; query: JsonNode;
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
  var valid_594688 = query.getOrDefault("Action")
  valid_594688 = validateParameter(valid_594688, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_594688 != nil:
    section.add "Action", valid_594688
  var valid_594689 = query.getOrDefault("Version")
  valid_594689 = validateParameter(valid_594689, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594689 != nil:
    section.add "Version", valid_594689
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
  var valid_594690 = header.getOrDefault("X-Amz-Date")
  valid_594690 = validateParameter(valid_594690, JString, required = false,
                                 default = nil)
  if valid_594690 != nil:
    section.add "X-Amz-Date", valid_594690
  var valid_594691 = header.getOrDefault("X-Amz-Security-Token")
  valid_594691 = validateParameter(valid_594691, JString, required = false,
                                 default = nil)
  if valid_594691 != nil:
    section.add "X-Amz-Security-Token", valid_594691
  var valid_594692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594692 = validateParameter(valid_594692, JString, required = false,
                                 default = nil)
  if valid_594692 != nil:
    section.add "X-Amz-Content-Sha256", valid_594692
  var valid_594693 = header.getOrDefault("X-Amz-Algorithm")
  valid_594693 = validateParameter(valid_594693, JString, required = false,
                                 default = nil)
  if valid_594693 != nil:
    section.add "X-Amz-Algorithm", valid_594693
  var valid_594694 = header.getOrDefault("X-Amz-Signature")
  valid_594694 = validateParameter(valid_594694, JString, required = false,
                                 default = nil)
  if valid_594694 != nil:
    section.add "X-Amz-Signature", valid_594694
  var valid_594695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594695 = validateParameter(valid_594695, JString, required = false,
                                 default = nil)
  if valid_594695 != nil:
    section.add "X-Amz-SignedHeaders", valid_594695
  var valid_594696 = header.getOrDefault("X-Amz-Credential")
  valid_594696 = validateParameter(valid_594696, JString, required = false,
                                 default = nil)
  if valid_594696 != nil:
    section.add "X-Amz-Credential", valid_594696
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_594697 = formData.getOrDefault("DBSubnetGroupName")
  valid_594697 = validateParameter(valid_594697, JString, required = true,
                                 default = nil)
  if valid_594697 != nil:
    section.add "DBSubnetGroupName", valid_594697
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594698: Call_PostDeleteDBSubnetGroup_594685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594698.validator(path, query, header, formData, body)
  let scheme = call_594698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594698.url(scheme.get, call_594698.host, call_594698.base,
                         call_594698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594698, url, valid)

proc call*(call_594699: Call_PostDeleteDBSubnetGroup_594685;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594700 = newJObject()
  var formData_594701 = newJObject()
  add(formData_594701, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594700, "Action", newJString(Action))
  add(query_594700, "Version", newJString(Version))
  result = call_594699.call(nil, query_594700, nil, formData_594701, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_594685(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_594686, base: "/",
    url: url_PostDeleteDBSubnetGroup_594687, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_594669 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBSubnetGroup_594671(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_594670(path: JsonNode; query: JsonNode;
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
  var valid_594672 = query.getOrDefault("Action")
  valid_594672 = validateParameter(valid_594672, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_594672 != nil:
    section.add "Action", valid_594672
  var valid_594673 = query.getOrDefault("DBSubnetGroupName")
  valid_594673 = validateParameter(valid_594673, JString, required = true,
                                 default = nil)
  if valid_594673 != nil:
    section.add "DBSubnetGroupName", valid_594673
  var valid_594674 = query.getOrDefault("Version")
  valid_594674 = validateParameter(valid_594674, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594674 != nil:
    section.add "Version", valid_594674
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
  var valid_594675 = header.getOrDefault("X-Amz-Date")
  valid_594675 = validateParameter(valid_594675, JString, required = false,
                                 default = nil)
  if valid_594675 != nil:
    section.add "X-Amz-Date", valid_594675
  var valid_594676 = header.getOrDefault("X-Amz-Security-Token")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "X-Amz-Security-Token", valid_594676
  var valid_594677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "X-Amz-Content-Sha256", valid_594677
  var valid_594678 = header.getOrDefault("X-Amz-Algorithm")
  valid_594678 = validateParameter(valid_594678, JString, required = false,
                                 default = nil)
  if valid_594678 != nil:
    section.add "X-Amz-Algorithm", valid_594678
  var valid_594679 = header.getOrDefault("X-Amz-Signature")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "X-Amz-Signature", valid_594679
  var valid_594680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594680 = validateParameter(valid_594680, JString, required = false,
                                 default = nil)
  if valid_594680 != nil:
    section.add "X-Amz-SignedHeaders", valid_594680
  var valid_594681 = header.getOrDefault("X-Amz-Credential")
  valid_594681 = validateParameter(valid_594681, JString, required = false,
                                 default = nil)
  if valid_594681 != nil:
    section.add "X-Amz-Credential", valid_594681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594682: Call_GetDeleteDBSubnetGroup_594669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594682.validator(path, query, header, formData, body)
  let scheme = call_594682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594682.url(scheme.get, call_594682.host, call_594682.base,
                         call_594682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594682, url, valid)

proc call*(call_594683: Call_GetDeleteDBSubnetGroup_594669;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_594684 = newJObject()
  add(query_594684, "Action", newJString(Action))
  add(query_594684, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594684, "Version", newJString(Version))
  result = call_594683.call(nil, query_594684, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_594669(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_594670, base: "/",
    url: url_GetDeleteDBSubnetGroup_594671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_594718 = ref object of OpenApiRestCall_593421
proc url_PostDeleteEventSubscription_594720(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEventSubscription_594719(path: JsonNode; query: JsonNode;
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
  var valid_594721 = query.getOrDefault("Action")
  valid_594721 = validateParameter(valid_594721, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_594721 != nil:
    section.add "Action", valid_594721
  var valid_594722 = query.getOrDefault("Version")
  valid_594722 = validateParameter(valid_594722, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594722 != nil:
    section.add "Version", valid_594722
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
  var valid_594723 = header.getOrDefault("X-Amz-Date")
  valid_594723 = validateParameter(valid_594723, JString, required = false,
                                 default = nil)
  if valid_594723 != nil:
    section.add "X-Amz-Date", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-Security-Token")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-Security-Token", valid_594724
  var valid_594725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-Content-Sha256", valid_594725
  var valid_594726 = header.getOrDefault("X-Amz-Algorithm")
  valid_594726 = validateParameter(valid_594726, JString, required = false,
                                 default = nil)
  if valid_594726 != nil:
    section.add "X-Amz-Algorithm", valid_594726
  var valid_594727 = header.getOrDefault("X-Amz-Signature")
  valid_594727 = validateParameter(valid_594727, JString, required = false,
                                 default = nil)
  if valid_594727 != nil:
    section.add "X-Amz-Signature", valid_594727
  var valid_594728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-SignedHeaders", valid_594728
  var valid_594729 = header.getOrDefault("X-Amz-Credential")
  valid_594729 = validateParameter(valid_594729, JString, required = false,
                                 default = nil)
  if valid_594729 != nil:
    section.add "X-Amz-Credential", valid_594729
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_594730 = formData.getOrDefault("SubscriptionName")
  valid_594730 = validateParameter(valid_594730, JString, required = true,
                                 default = nil)
  if valid_594730 != nil:
    section.add "SubscriptionName", valid_594730
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594731: Call_PostDeleteEventSubscription_594718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594731.validator(path, query, header, formData, body)
  let scheme = call_594731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594731.url(scheme.get, call_594731.host, call_594731.base,
                         call_594731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594731, url, valid)

proc call*(call_594732: Call_PostDeleteEventSubscription_594718;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594733 = newJObject()
  var formData_594734 = newJObject()
  add(formData_594734, "SubscriptionName", newJString(SubscriptionName))
  add(query_594733, "Action", newJString(Action))
  add(query_594733, "Version", newJString(Version))
  result = call_594732.call(nil, query_594733, nil, formData_594734, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_594718(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_594719, base: "/",
    url: url_PostDeleteEventSubscription_594720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_594702 = ref object of OpenApiRestCall_593421
proc url_GetDeleteEventSubscription_594704(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEventSubscription_594703(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594705 = query.getOrDefault("Action")
  valid_594705 = validateParameter(valid_594705, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_594705 != nil:
    section.add "Action", valid_594705
  var valid_594706 = query.getOrDefault("SubscriptionName")
  valid_594706 = validateParameter(valid_594706, JString, required = true,
                                 default = nil)
  if valid_594706 != nil:
    section.add "SubscriptionName", valid_594706
  var valid_594707 = query.getOrDefault("Version")
  valid_594707 = validateParameter(valid_594707, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594707 != nil:
    section.add "Version", valid_594707
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
  var valid_594708 = header.getOrDefault("X-Amz-Date")
  valid_594708 = validateParameter(valid_594708, JString, required = false,
                                 default = nil)
  if valid_594708 != nil:
    section.add "X-Amz-Date", valid_594708
  var valid_594709 = header.getOrDefault("X-Amz-Security-Token")
  valid_594709 = validateParameter(valid_594709, JString, required = false,
                                 default = nil)
  if valid_594709 != nil:
    section.add "X-Amz-Security-Token", valid_594709
  var valid_594710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594710 = validateParameter(valid_594710, JString, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "X-Amz-Content-Sha256", valid_594710
  var valid_594711 = header.getOrDefault("X-Amz-Algorithm")
  valid_594711 = validateParameter(valid_594711, JString, required = false,
                                 default = nil)
  if valid_594711 != nil:
    section.add "X-Amz-Algorithm", valid_594711
  var valid_594712 = header.getOrDefault("X-Amz-Signature")
  valid_594712 = validateParameter(valid_594712, JString, required = false,
                                 default = nil)
  if valid_594712 != nil:
    section.add "X-Amz-Signature", valid_594712
  var valid_594713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-SignedHeaders", valid_594713
  var valid_594714 = header.getOrDefault("X-Amz-Credential")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-Credential", valid_594714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594715: Call_GetDeleteEventSubscription_594702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594715.validator(path, query, header, formData, body)
  let scheme = call_594715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594715.url(scheme.get, call_594715.host, call_594715.base,
                         call_594715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594715, url, valid)

proc call*(call_594716: Call_GetDeleteEventSubscription_594702;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_594717 = newJObject()
  add(query_594717, "Action", newJString(Action))
  add(query_594717, "SubscriptionName", newJString(SubscriptionName))
  add(query_594717, "Version", newJString(Version))
  result = call_594716.call(nil, query_594717, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_594702(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_594703, base: "/",
    url: url_GetDeleteEventSubscription_594704,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_594751 = ref object of OpenApiRestCall_593421
proc url_PostDeleteOptionGroup_594753(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteOptionGroup_594752(path: JsonNode; query: JsonNode;
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
  var valid_594754 = query.getOrDefault("Action")
  valid_594754 = validateParameter(valid_594754, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_594754 != nil:
    section.add "Action", valid_594754
  var valid_594755 = query.getOrDefault("Version")
  valid_594755 = validateParameter(valid_594755, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594755 != nil:
    section.add "Version", valid_594755
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
  var valid_594756 = header.getOrDefault("X-Amz-Date")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "X-Amz-Date", valid_594756
  var valid_594757 = header.getOrDefault("X-Amz-Security-Token")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-Security-Token", valid_594757
  var valid_594758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "X-Amz-Content-Sha256", valid_594758
  var valid_594759 = header.getOrDefault("X-Amz-Algorithm")
  valid_594759 = validateParameter(valid_594759, JString, required = false,
                                 default = nil)
  if valid_594759 != nil:
    section.add "X-Amz-Algorithm", valid_594759
  var valid_594760 = header.getOrDefault("X-Amz-Signature")
  valid_594760 = validateParameter(valid_594760, JString, required = false,
                                 default = nil)
  if valid_594760 != nil:
    section.add "X-Amz-Signature", valid_594760
  var valid_594761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "X-Amz-SignedHeaders", valid_594761
  var valid_594762 = header.getOrDefault("X-Amz-Credential")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "X-Amz-Credential", valid_594762
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_594763 = formData.getOrDefault("OptionGroupName")
  valid_594763 = validateParameter(valid_594763, JString, required = true,
                                 default = nil)
  if valid_594763 != nil:
    section.add "OptionGroupName", valid_594763
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594764: Call_PostDeleteOptionGroup_594751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594764.validator(path, query, header, formData, body)
  let scheme = call_594764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594764.url(scheme.get, call_594764.host, call_594764.base,
                         call_594764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594764, url, valid)

proc call*(call_594765: Call_PostDeleteOptionGroup_594751; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594766 = newJObject()
  var formData_594767 = newJObject()
  add(formData_594767, "OptionGroupName", newJString(OptionGroupName))
  add(query_594766, "Action", newJString(Action))
  add(query_594766, "Version", newJString(Version))
  result = call_594765.call(nil, query_594766, nil, formData_594767, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_594751(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_594752, base: "/",
    url: url_PostDeleteOptionGroup_594753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_594735 = ref object of OpenApiRestCall_593421
proc url_GetDeleteOptionGroup_594737(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteOptionGroup_594736(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OptionGroupName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `OptionGroupName` field"
  var valid_594738 = query.getOrDefault("OptionGroupName")
  valid_594738 = validateParameter(valid_594738, JString, required = true,
                                 default = nil)
  if valid_594738 != nil:
    section.add "OptionGroupName", valid_594738
  var valid_594739 = query.getOrDefault("Action")
  valid_594739 = validateParameter(valid_594739, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_594739 != nil:
    section.add "Action", valid_594739
  var valid_594740 = query.getOrDefault("Version")
  valid_594740 = validateParameter(valid_594740, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594740 != nil:
    section.add "Version", valid_594740
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
  var valid_594741 = header.getOrDefault("X-Amz-Date")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "X-Amz-Date", valid_594741
  var valid_594742 = header.getOrDefault("X-Amz-Security-Token")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "X-Amz-Security-Token", valid_594742
  var valid_594743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Content-Sha256", valid_594743
  var valid_594744 = header.getOrDefault("X-Amz-Algorithm")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "X-Amz-Algorithm", valid_594744
  var valid_594745 = header.getOrDefault("X-Amz-Signature")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "X-Amz-Signature", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-SignedHeaders", valid_594746
  var valid_594747 = header.getOrDefault("X-Amz-Credential")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-Credential", valid_594747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594748: Call_GetDeleteOptionGroup_594735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594748.validator(path, query, header, formData, body)
  let scheme = call_594748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594748.url(scheme.get, call_594748.host, call_594748.base,
                         call_594748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594748, url, valid)

proc call*(call_594749: Call_GetDeleteOptionGroup_594735; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594750 = newJObject()
  add(query_594750, "OptionGroupName", newJString(OptionGroupName))
  add(query_594750, "Action", newJString(Action))
  add(query_594750, "Version", newJString(Version))
  result = call_594749.call(nil, query_594750, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_594735(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_594736, base: "/",
    url: url_GetDeleteOptionGroup_594737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_594791 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBEngineVersions_594793(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_594792(path: JsonNode; query: JsonNode;
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
  var valid_594794 = query.getOrDefault("Action")
  valid_594794 = validateParameter(valid_594794, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_594794 != nil:
    section.add "Action", valid_594794
  var valid_594795 = query.getOrDefault("Version")
  valid_594795 = validateParameter(valid_594795, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594795 != nil:
    section.add "Version", valid_594795
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
  var valid_594796 = header.getOrDefault("X-Amz-Date")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-Date", valid_594796
  var valid_594797 = header.getOrDefault("X-Amz-Security-Token")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "X-Amz-Security-Token", valid_594797
  var valid_594798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594798 = validateParameter(valid_594798, JString, required = false,
                                 default = nil)
  if valid_594798 != nil:
    section.add "X-Amz-Content-Sha256", valid_594798
  var valid_594799 = header.getOrDefault("X-Amz-Algorithm")
  valid_594799 = validateParameter(valid_594799, JString, required = false,
                                 default = nil)
  if valid_594799 != nil:
    section.add "X-Amz-Algorithm", valid_594799
  var valid_594800 = header.getOrDefault("X-Amz-Signature")
  valid_594800 = validateParameter(valid_594800, JString, required = false,
                                 default = nil)
  if valid_594800 != nil:
    section.add "X-Amz-Signature", valid_594800
  var valid_594801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594801 = validateParameter(valid_594801, JString, required = false,
                                 default = nil)
  if valid_594801 != nil:
    section.add "X-Amz-SignedHeaders", valid_594801
  var valid_594802 = header.getOrDefault("X-Amz-Credential")
  valid_594802 = validateParameter(valid_594802, JString, required = false,
                                 default = nil)
  if valid_594802 != nil:
    section.add "X-Amz-Credential", valid_594802
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListSupportedCharacterSets: JBool
  ##   Engine: JString
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   DefaultOnly: JBool
  section = newJObject()
  var valid_594803 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_594803 = validateParameter(valid_594803, JBool, required = false, default = nil)
  if valid_594803 != nil:
    section.add "ListSupportedCharacterSets", valid_594803
  var valid_594804 = formData.getOrDefault("Engine")
  valid_594804 = validateParameter(valid_594804, JString, required = false,
                                 default = nil)
  if valid_594804 != nil:
    section.add "Engine", valid_594804
  var valid_594805 = formData.getOrDefault("Marker")
  valid_594805 = validateParameter(valid_594805, JString, required = false,
                                 default = nil)
  if valid_594805 != nil:
    section.add "Marker", valid_594805
  var valid_594806 = formData.getOrDefault("DBParameterGroupFamily")
  valid_594806 = validateParameter(valid_594806, JString, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "DBParameterGroupFamily", valid_594806
  var valid_594807 = formData.getOrDefault("Filters")
  valid_594807 = validateParameter(valid_594807, JArray, required = false,
                                 default = nil)
  if valid_594807 != nil:
    section.add "Filters", valid_594807
  var valid_594808 = formData.getOrDefault("MaxRecords")
  valid_594808 = validateParameter(valid_594808, JInt, required = false, default = nil)
  if valid_594808 != nil:
    section.add "MaxRecords", valid_594808
  var valid_594809 = formData.getOrDefault("EngineVersion")
  valid_594809 = validateParameter(valid_594809, JString, required = false,
                                 default = nil)
  if valid_594809 != nil:
    section.add "EngineVersion", valid_594809
  var valid_594810 = formData.getOrDefault("DefaultOnly")
  valid_594810 = validateParameter(valid_594810, JBool, required = false, default = nil)
  if valid_594810 != nil:
    section.add "DefaultOnly", valid_594810
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594811: Call_PostDescribeDBEngineVersions_594791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594811.validator(path, query, header, formData, body)
  let scheme = call_594811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594811.url(scheme.get, call_594811.host, call_594811.base,
                         call_594811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594811, url, valid)

proc call*(call_594812: Call_PostDescribeDBEngineVersions_594791;
          ListSupportedCharacterSets: bool = false; Engine: string = "";
          Marker: string = ""; Action: string = "DescribeDBEngineVersions";
          DBParameterGroupFamily: string = ""; Filters: JsonNode = nil;
          MaxRecords: int = 0; EngineVersion: string = "";
          Version: string = "2013-09-09"; DefaultOnly: bool = false): Recallable =
  ## postDescribeDBEngineVersions
  ##   ListSupportedCharacterSets: bool
  ##   Engine: string
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Version: string (required)
  ##   DefaultOnly: bool
  var query_594813 = newJObject()
  var formData_594814 = newJObject()
  add(formData_594814, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_594814, "Engine", newJString(Engine))
  add(formData_594814, "Marker", newJString(Marker))
  add(query_594813, "Action", newJString(Action))
  add(formData_594814, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_594814.add "Filters", Filters
  add(formData_594814, "MaxRecords", newJInt(MaxRecords))
  add(formData_594814, "EngineVersion", newJString(EngineVersion))
  add(query_594813, "Version", newJString(Version))
  add(formData_594814, "DefaultOnly", newJBool(DefaultOnly))
  result = call_594812.call(nil, query_594813, nil, formData_594814, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_594791(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_594792, base: "/",
    url: url_PostDescribeDBEngineVersions_594793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_594768 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBEngineVersions_594770(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_594769(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString
  ##   ListSupportedCharacterSets: JBool
  ##   MaxRecords: JInt
  ##   DBParameterGroupFamily: JString
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   EngineVersion: JString
  ##   DefaultOnly: JBool
  ##   Version: JString (required)
  section = newJObject()
  var valid_594771 = query.getOrDefault("Engine")
  valid_594771 = validateParameter(valid_594771, JString, required = false,
                                 default = nil)
  if valid_594771 != nil:
    section.add "Engine", valid_594771
  var valid_594772 = query.getOrDefault("ListSupportedCharacterSets")
  valid_594772 = validateParameter(valid_594772, JBool, required = false, default = nil)
  if valid_594772 != nil:
    section.add "ListSupportedCharacterSets", valid_594772
  var valid_594773 = query.getOrDefault("MaxRecords")
  valid_594773 = validateParameter(valid_594773, JInt, required = false, default = nil)
  if valid_594773 != nil:
    section.add "MaxRecords", valid_594773
  var valid_594774 = query.getOrDefault("DBParameterGroupFamily")
  valid_594774 = validateParameter(valid_594774, JString, required = false,
                                 default = nil)
  if valid_594774 != nil:
    section.add "DBParameterGroupFamily", valid_594774
  var valid_594775 = query.getOrDefault("Filters")
  valid_594775 = validateParameter(valid_594775, JArray, required = false,
                                 default = nil)
  if valid_594775 != nil:
    section.add "Filters", valid_594775
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594776 = query.getOrDefault("Action")
  valid_594776 = validateParameter(valid_594776, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_594776 != nil:
    section.add "Action", valid_594776
  var valid_594777 = query.getOrDefault("Marker")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "Marker", valid_594777
  var valid_594778 = query.getOrDefault("EngineVersion")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "EngineVersion", valid_594778
  var valid_594779 = query.getOrDefault("DefaultOnly")
  valid_594779 = validateParameter(valid_594779, JBool, required = false, default = nil)
  if valid_594779 != nil:
    section.add "DefaultOnly", valid_594779
  var valid_594780 = query.getOrDefault("Version")
  valid_594780 = validateParameter(valid_594780, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594780 != nil:
    section.add "Version", valid_594780
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
  var valid_594781 = header.getOrDefault("X-Amz-Date")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-Date", valid_594781
  var valid_594782 = header.getOrDefault("X-Amz-Security-Token")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "X-Amz-Security-Token", valid_594782
  var valid_594783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594783 = validateParameter(valid_594783, JString, required = false,
                                 default = nil)
  if valid_594783 != nil:
    section.add "X-Amz-Content-Sha256", valid_594783
  var valid_594784 = header.getOrDefault("X-Amz-Algorithm")
  valid_594784 = validateParameter(valid_594784, JString, required = false,
                                 default = nil)
  if valid_594784 != nil:
    section.add "X-Amz-Algorithm", valid_594784
  var valid_594785 = header.getOrDefault("X-Amz-Signature")
  valid_594785 = validateParameter(valid_594785, JString, required = false,
                                 default = nil)
  if valid_594785 != nil:
    section.add "X-Amz-Signature", valid_594785
  var valid_594786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594786 = validateParameter(valid_594786, JString, required = false,
                                 default = nil)
  if valid_594786 != nil:
    section.add "X-Amz-SignedHeaders", valid_594786
  var valid_594787 = header.getOrDefault("X-Amz-Credential")
  valid_594787 = validateParameter(valid_594787, JString, required = false,
                                 default = nil)
  if valid_594787 != nil:
    section.add "X-Amz-Credential", valid_594787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594788: Call_GetDescribeDBEngineVersions_594768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594788.validator(path, query, header, formData, body)
  let scheme = call_594788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594788.url(scheme.get, call_594788.host, call_594788.base,
                         call_594788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594788, url, valid)

proc call*(call_594789: Call_GetDescribeDBEngineVersions_594768;
          Engine: string = ""; ListSupportedCharacterSets: bool = false;
          MaxRecords: int = 0; DBParameterGroupFamily: string = "";
          Filters: JsonNode = nil; Action: string = "DescribeDBEngineVersions";
          Marker: string = ""; EngineVersion: string = ""; DefaultOnly: bool = false;
          Version: string = "2013-09-09"): Recallable =
  ## getDescribeDBEngineVersions
  ##   Engine: string
  ##   ListSupportedCharacterSets: bool
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   EngineVersion: string
  ##   DefaultOnly: bool
  ##   Version: string (required)
  var query_594790 = newJObject()
  add(query_594790, "Engine", newJString(Engine))
  add(query_594790, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_594790, "MaxRecords", newJInt(MaxRecords))
  add(query_594790, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_594790.add "Filters", Filters
  add(query_594790, "Action", newJString(Action))
  add(query_594790, "Marker", newJString(Marker))
  add(query_594790, "EngineVersion", newJString(EngineVersion))
  add(query_594790, "DefaultOnly", newJBool(DefaultOnly))
  add(query_594790, "Version", newJString(Version))
  result = call_594789.call(nil, query_594790, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_594768(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_594769, base: "/",
    url: url_GetDescribeDBEngineVersions_594770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_594834 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBInstances_594836(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_594835(path: JsonNode; query: JsonNode;
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
  var valid_594837 = query.getOrDefault("Action")
  valid_594837 = validateParameter(valid_594837, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_594837 != nil:
    section.add "Action", valid_594837
  var valid_594838 = query.getOrDefault("Version")
  valid_594838 = validateParameter(valid_594838, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594838 != nil:
    section.add "Version", valid_594838
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
  var valid_594839 = header.getOrDefault("X-Amz-Date")
  valid_594839 = validateParameter(valid_594839, JString, required = false,
                                 default = nil)
  if valid_594839 != nil:
    section.add "X-Amz-Date", valid_594839
  var valid_594840 = header.getOrDefault("X-Amz-Security-Token")
  valid_594840 = validateParameter(valid_594840, JString, required = false,
                                 default = nil)
  if valid_594840 != nil:
    section.add "X-Amz-Security-Token", valid_594840
  var valid_594841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594841 = validateParameter(valid_594841, JString, required = false,
                                 default = nil)
  if valid_594841 != nil:
    section.add "X-Amz-Content-Sha256", valid_594841
  var valid_594842 = header.getOrDefault("X-Amz-Algorithm")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-Algorithm", valid_594842
  var valid_594843 = header.getOrDefault("X-Amz-Signature")
  valid_594843 = validateParameter(valid_594843, JString, required = false,
                                 default = nil)
  if valid_594843 != nil:
    section.add "X-Amz-Signature", valid_594843
  var valid_594844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594844 = validateParameter(valid_594844, JString, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "X-Amz-SignedHeaders", valid_594844
  var valid_594845 = header.getOrDefault("X-Amz-Credential")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "X-Amz-Credential", valid_594845
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594846 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "DBInstanceIdentifier", valid_594846
  var valid_594847 = formData.getOrDefault("Marker")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "Marker", valid_594847
  var valid_594848 = formData.getOrDefault("Filters")
  valid_594848 = validateParameter(valid_594848, JArray, required = false,
                                 default = nil)
  if valid_594848 != nil:
    section.add "Filters", valid_594848
  var valid_594849 = formData.getOrDefault("MaxRecords")
  valid_594849 = validateParameter(valid_594849, JInt, required = false, default = nil)
  if valid_594849 != nil:
    section.add "MaxRecords", valid_594849
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594850: Call_PostDescribeDBInstances_594834; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594850.validator(path, query, header, formData, body)
  let scheme = call_594850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594850.url(scheme.get, call_594850.host, call_594850.base,
                         call_594850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594850, url, valid)

proc call*(call_594851: Call_PostDescribeDBInstances_594834;
          DBInstanceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeDBInstances"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBInstances
  ##   DBInstanceIdentifier: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_594852 = newJObject()
  var formData_594853 = newJObject()
  add(formData_594853, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594853, "Marker", newJString(Marker))
  add(query_594852, "Action", newJString(Action))
  if Filters != nil:
    formData_594853.add "Filters", Filters
  add(formData_594853, "MaxRecords", newJInt(MaxRecords))
  add(query_594852, "Version", newJString(Version))
  result = call_594851.call(nil, query_594852, nil, formData_594853, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_594834(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_594835, base: "/",
    url: url_PostDescribeDBInstances_594836, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_594815 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBInstances_594817(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_594816(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString
  section = newJObject()
  var valid_594818 = query.getOrDefault("MaxRecords")
  valid_594818 = validateParameter(valid_594818, JInt, required = false, default = nil)
  if valid_594818 != nil:
    section.add "MaxRecords", valid_594818
  var valid_594819 = query.getOrDefault("Filters")
  valid_594819 = validateParameter(valid_594819, JArray, required = false,
                                 default = nil)
  if valid_594819 != nil:
    section.add "Filters", valid_594819
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594820 = query.getOrDefault("Action")
  valid_594820 = validateParameter(valid_594820, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_594820 != nil:
    section.add "Action", valid_594820
  var valid_594821 = query.getOrDefault("Marker")
  valid_594821 = validateParameter(valid_594821, JString, required = false,
                                 default = nil)
  if valid_594821 != nil:
    section.add "Marker", valid_594821
  var valid_594822 = query.getOrDefault("Version")
  valid_594822 = validateParameter(valid_594822, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594822 != nil:
    section.add "Version", valid_594822
  var valid_594823 = query.getOrDefault("DBInstanceIdentifier")
  valid_594823 = validateParameter(valid_594823, JString, required = false,
                                 default = nil)
  if valid_594823 != nil:
    section.add "DBInstanceIdentifier", valid_594823
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
  var valid_594824 = header.getOrDefault("X-Amz-Date")
  valid_594824 = validateParameter(valid_594824, JString, required = false,
                                 default = nil)
  if valid_594824 != nil:
    section.add "X-Amz-Date", valid_594824
  var valid_594825 = header.getOrDefault("X-Amz-Security-Token")
  valid_594825 = validateParameter(valid_594825, JString, required = false,
                                 default = nil)
  if valid_594825 != nil:
    section.add "X-Amz-Security-Token", valid_594825
  var valid_594826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "X-Amz-Content-Sha256", valid_594826
  var valid_594827 = header.getOrDefault("X-Amz-Algorithm")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "X-Amz-Algorithm", valid_594827
  var valid_594828 = header.getOrDefault("X-Amz-Signature")
  valid_594828 = validateParameter(valid_594828, JString, required = false,
                                 default = nil)
  if valid_594828 != nil:
    section.add "X-Amz-Signature", valid_594828
  var valid_594829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594829 = validateParameter(valid_594829, JString, required = false,
                                 default = nil)
  if valid_594829 != nil:
    section.add "X-Amz-SignedHeaders", valid_594829
  var valid_594830 = header.getOrDefault("X-Amz-Credential")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-Credential", valid_594830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594831: Call_GetDescribeDBInstances_594815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594831.validator(path, query, header, formData, body)
  let scheme = call_594831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594831.url(scheme.get, call_594831.host, call_594831.base,
                         call_594831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594831, url, valid)

proc call*(call_594832: Call_GetDescribeDBInstances_594815; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBInstances";
          Marker: string = ""; Version: string = "2013-09-09";
          DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  var query_594833 = newJObject()
  add(query_594833, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_594833.add "Filters", Filters
  add(query_594833, "Action", newJString(Action))
  add(query_594833, "Marker", newJString(Marker))
  add(query_594833, "Version", newJString(Version))
  add(query_594833, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594832.call(nil, query_594833, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_594815(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_594816, base: "/",
    url: url_GetDescribeDBInstances_594817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_594876 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBLogFiles_594878(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBLogFiles_594877(path: JsonNode; query: JsonNode;
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
  var valid_594879 = query.getOrDefault("Action")
  valid_594879 = validateParameter(valid_594879, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_594879 != nil:
    section.add "Action", valid_594879
  var valid_594880 = query.getOrDefault("Version")
  valid_594880 = validateParameter(valid_594880, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594880 != nil:
    section.add "Version", valid_594880
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
  var valid_594881 = header.getOrDefault("X-Amz-Date")
  valid_594881 = validateParameter(valid_594881, JString, required = false,
                                 default = nil)
  if valid_594881 != nil:
    section.add "X-Amz-Date", valid_594881
  var valid_594882 = header.getOrDefault("X-Amz-Security-Token")
  valid_594882 = validateParameter(valid_594882, JString, required = false,
                                 default = nil)
  if valid_594882 != nil:
    section.add "X-Amz-Security-Token", valid_594882
  var valid_594883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594883 = validateParameter(valid_594883, JString, required = false,
                                 default = nil)
  if valid_594883 != nil:
    section.add "X-Amz-Content-Sha256", valid_594883
  var valid_594884 = header.getOrDefault("X-Amz-Algorithm")
  valid_594884 = validateParameter(valid_594884, JString, required = false,
                                 default = nil)
  if valid_594884 != nil:
    section.add "X-Amz-Algorithm", valid_594884
  var valid_594885 = header.getOrDefault("X-Amz-Signature")
  valid_594885 = validateParameter(valid_594885, JString, required = false,
                                 default = nil)
  if valid_594885 != nil:
    section.add "X-Amz-Signature", valid_594885
  var valid_594886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "X-Amz-SignedHeaders", valid_594886
  var valid_594887 = header.getOrDefault("X-Amz-Credential")
  valid_594887 = validateParameter(valid_594887, JString, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "X-Amz-Credential", valid_594887
  result.add "header", section
  ## parameters in `formData` object:
  ##   FilenameContains: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FileSize: JInt
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_594888 = formData.getOrDefault("FilenameContains")
  valid_594888 = validateParameter(valid_594888, JString, required = false,
                                 default = nil)
  if valid_594888 != nil:
    section.add "FilenameContains", valid_594888
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594889 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594889 = validateParameter(valid_594889, JString, required = true,
                                 default = nil)
  if valid_594889 != nil:
    section.add "DBInstanceIdentifier", valid_594889
  var valid_594890 = formData.getOrDefault("FileSize")
  valid_594890 = validateParameter(valid_594890, JInt, required = false, default = nil)
  if valid_594890 != nil:
    section.add "FileSize", valid_594890
  var valid_594891 = formData.getOrDefault("Marker")
  valid_594891 = validateParameter(valid_594891, JString, required = false,
                                 default = nil)
  if valid_594891 != nil:
    section.add "Marker", valid_594891
  var valid_594892 = formData.getOrDefault("Filters")
  valid_594892 = validateParameter(valid_594892, JArray, required = false,
                                 default = nil)
  if valid_594892 != nil:
    section.add "Filters", valid_594892
  var valid_594893 = formData.getOrDefault("MaxRecords")
  valid_594893 = validateParameter(valid_594893, JInt, required = false, default = nil)
  if valid_594893 != nil:
    section.add "MaxRecords", valid_594893
  var valid_594894 = formData.getOrDefault("FileLastWritten")
  valid_594894 = validateParameter(valid_594894, JInt, required = false, default = nil)
  if valid_594894 != nil:
    section.add "FileLastWritten", valid_594894
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594895: Call_PostDescribeDBLogFiles_594876; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594895.validator(path, query, header, formData, body)
  let scheme = call_594895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594895.url(scheme.get, call_594895.host, call_594895.base,
                         call_594895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594895, url, valid)

proc call*(call_594896: Call_PostDescribeDBLogFiles_594876;
          DBInstanceIdentifier: string; FilenameContains: string = "";
          FileSize: int = 0; Marker: string = ""; Action: string = "DescribeDBLogFiles";
          Filters: JsonNode = nil; MaxRecords: int = 0; FileLastWritten: int = 0;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBLogFiles
  ##   FilenameContains: string
  ##   DBInstanceIdentifier: string (required)
  ##   FileSize: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   FileLastWritten: int
  ##   Version: string (required)
  var query_594897 = newJObject()
  var formData_594898 = newJObject()
  add(formData_594898, "FilenameContains", newJString(FilenameContains))
  add(formData_594898, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594898, "FileSize", newJInt(FileSize))
  add(formData_594898, "Marker", newJString(Marker))
  add(query_594897, "Action", newJString(Action))
  if Filters != nil:
    formData_594898.add "Filters", Filters
  add(formData_594898, "MaxRecords", newJInt(MaxRecords))
  add(formData_594898, "FileLastWritten", newJInt(FileLastWritten))
  add(query_594897, "Version", newJString(Version))
  result = call_594896.call(nil, query_594897, nil, formData_594898, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_594876(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_594877, base: "/",
    url: url_PostDescribeDBLogFiles_594878, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_594854 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBLogFiles_594856(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBLogFiles_594855(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FileLastWritten: JInt
  ##   MaxRecords: JInt
  ##   FilenameContains: JString
  ##   FileSize: JInt
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_594857 = query.getOrDefault("FileLastWritten")
  valid_594857 = validateParameter(valid_594857, JInt, required = false, default = nil)
  if valid_594857 != nil:
    section.add "FileLastWritten", valid_594857
  var valid_594858 = query.getOrDefault("MaxRecords")
  valid_594858 = validateParameter(valid_594858, JInt, required = false, default = nil)
  if valid_594858 != nil:
    section.add "MaxRecords", valid_594858
  var valid_594859 = query.getOrDefault("FilenameContains")
  valid_594859 = validateParameter(valid_594859, JString, required = false,
                                 default = nil)
  if valid_594859 != nil:
    section.add "FilenameContains", valid_594859
  var valid_594860 = query.getOrDefault("FileSize")
  valid_594860 = validateParameter(valid_594860, JInt, required = false, default = nil)
  if valid_594860 != nil:
    section.add "FileSize", valid_594860
  var valid_594861 = query.getOrDefault("Filters")
  valid_594861 = validateParameter(valid_594861, JArray, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "Filters", valid_594861
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594862 = query.getOrDefault("Action")
  valid_594862 = validateParameter(valid_594862, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_594862 != nil:
    section.add "Action", valid_594862
  var valid_594863 = query.getOrDefault("Marker")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "Marker", valid_594863
  var valid_594864 = query.getOrDefault("Version")
  valid_594864 = validateParameter(valid_594864, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594864 != nil:
    section.add "Version", valid_594864
  var valid_594865 = query.getOrDefault("DBInstanceIdentifier")
  valid_594865 = validateParameter(valid_594865, JString, required = true,
                                 default = nil)
  if valid_594865 != nil:
    section.add "DBInstanceIdentifier", valid_594865
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
  var valid_594866 = header.getOrDefault("X-Amz-Date")
  valid_594866 = validateParameter(valid_594866, JString, required = false,
                                 default = nil)
  if valid_594866 != nil:
    section.add "X-Amz-Date", valid_594866
  var valid_594867 = header.getOrDefault("X-Amz-Security-Token")
  valid_594867 = validateParameter(valid_594867, JString, required = false,
                                 default = nil)
  if valid_594867 != nil:
    section.add "X-Amz-Security-Token", valid_594867
  var valid_594868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594868 = validateParameter(valid_594868, JString, required = false,
                                 default = nil)
  if valid_594868 != nil:
    section.add "X-Amz-Content-Sha256", valid_594868
  var valid_594869 = header.getOrDefault("X-Amz-Algorithm")
  valid_594869 = validateParameter(valid_594869, JString, required = false,
                                 default = nil)
  if valid_594869 != nil:
    section.add "X-Amz-Algorithm", valid_594869
  var valid_594870 = header.getOrDefault("X-Amz-Signature")
  valid_594870 = validateParameter(valid_594870, JString, required = false,
                                 default = nil)
  if valid_594870 != nil:
    section.add "X-Amz-Signature", valid_594870
  var valid_594871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594871 = validateParameter(valid_594871, JString, required = false,
                                 default = nil)
  if valid_594871 != nil:
    section.add "X-Amz-SignedHeaders", valid_594871
  var valid_594872 = header.getOrDefault("X-Amz-Credential")
  valid_594872 = validateParameter(valid_594872, JString, required = false,
                                 default = nil)
  if valid_594872 != nil:
    section.add "X-Amz-Credential", valid_594872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594873: Call_GetDescribeDBLogFiles_594854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594873.validator(path, query, header, formData, body)
  let scheme = call_594873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594873.url(scheme.get, call_594873.host, call_594873.base,
                         call_594873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594873, url, valid)

proc call*(call_594874: Call_GetDescribeDBLogFiles_594854;
          DBInstanceIdentifier: string; FileLastWritten: int = 0; MaxRecords: int = 0;
          FilenameContains: string = ""; FileSize: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBLogFiles"; Marker: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getDescribeDBLogFiles
  ##   FileLastWritten: int
  ##   MaxRecords: int
  ##   FilenameContains: string
  ##   FileSize: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_594875 = newJObject()
  add(query_594875, "FileLastWritten", newJInt(FileLastWritten))
  add(query_594875, "MaxRecords", newJInt(MaxRecords))
  add(query_594875, "FilenameContains", newJString(FilenameContains))
  add(query_594875, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_594875.add "Filters", Filters
  add(query_594875, "Action", newJString(Action))
  add(query_594875, "Marker", newJString(Marker))
  add(query_594875, "Version", newJString(Version))
  add(query_594875, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594874.call(nil, query_594875, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_594854(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_594855, base: "/",
    url: url_GetDescribeDBLogFiles_594856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_594918 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBParameterGroups_594920(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_594919(path: JsonNode; query: JsonNode;
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
  var valid_594921 = query.getOrDefault("Action")
  valid_594921 = validateParameter(valid_594921, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_594921 != nil:
    section.add "Action", valid_594921
  var valid_594922 = query.getOrDefault("Version")
  valid_594922 = validateParameter(valid_594922, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594922 != nil:
    section.add "Version", valid_594922
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
  var valid_594923 = header.getOrDefault("X-Amz-Date")
  valid_594923 = validateParameter(valid_594923, JString, required = false,
                                 default = nil)
  if valid_594923 != nil:
    section.add "X-Amz-Date", valid_594923
  var valid_594924 = header.getOrDefault("X-Amz-Security-Token")
  valid_594924 = validateParameter(valid_594924, JString, required = false,
                                 default = nil)
  if valid_594924 != nil:
    section.add "X-Amz-Security-Token", valid_594924
  var valid_594925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594925 = validateParameter(valid_594925, JString, required = false,
                                 default = nil)
  if valid_594925 != nil:
    section.add "X-Amz-Content-Sha256", valid_594925
  var valid_594926 = header.getOrDefault("X-Amz-Algorithm")
  valid_594926 = validateParameter(valid_594926, JString, required = false,
                                 default = nil)
  if valid_594926 != nil:
    section.add "X-Amz-Algorithm", valid_594926
  var valid_594927 = header.getOrDefault("X-Amz-Signature")
  valid_594927 = validateParameter(valid_594927, JString, required = false,
                                 default = nil)
  if valid_594927 != nil:
    section.add "X-Amz-Signature", valid_594927
  var valid_594928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594928 = validateParameter(valid_594928, JString, required = false,
                                 default = nil)
  if valid_594928 != nil:
    section.add "X-Amz-SignedHeaders", valid_594928
  var valid_594929 = header.getOrDefault("X-Amz-Credential")
  valid_594929 = validateParameter(valid_594929, JString, required = false,
                                 default = nil)
  if valid_594929 != nil:
    section.add "X-Amz-Credential", valid_594929
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594930 = formData.getOrDefault("DBParameterGroupName")
  valid_594930 = validateParameter(valid_594930, JString, required = false,
                                 default = nil)
  if valid_594930 != nil:
    section.add "DBParameterGroupName", valid_594930
  var valid_594931 = formData.getOrDefault("Marker")
  valid_594931 = validateParameter(valid_594931, JString, required = false,
                                 default = nil)
  if valid_594931 != nil:
    section.add "Marker", valid_594931
  var valid_594932 = formData.getOrDefault("Filters")
  valid_594932 = validateParameter(valid_594932, JArray, required = false,
                                 default = nil)
  if valid_594932 != nil:
    section.add "Filters", valid_594932
  var valid_594933 = formData.getOrDefault("MaxRecords")
  valid_594933 = validateParameter(valid_594933, JInt, required = false, default = nil)
  if valid_594933 != nil:
    section.add "MaxRecords", valid_594933
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594934: Call_PostDescribeDBParameterGroups_594918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594934.validator(path, query, header, formData, body)
  let scheme = call_594934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594934.url(scheme.get, call_594934.host, call_594934.base,
                         call_594934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594934, url, valid)

proc call*(call_594935: Call_PostDescribeDBParameterGroups_594918;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_594936 = newJObject()
  var formData_594937 = newJObject()
  add(formData_594937, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_594937, "Marker", newJString(Marker))
  add(query_594936, "Action", newJString(Action))
  if Filters != nil:
    formData_594937.add "Filters", Filters
  add(formData_594937, "MaxRecords", newJInt(MaxRecords))
  add(query_594936, "Version", newJString(Version))
  result = call_594935.call(nil, query_594936, nil, formData_594937, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_594918(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_594919, base: "/",
    url: url_PostDescribeDBParameterGroups_594920,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_594899 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBParameterGroups_594901(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_594900(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   DBParameterGroupName: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_594902 = query.getOrDefault("MaxRecords")
  valid_594902 = validateParameter(valid_594902, JInt, required = false, default = nil)
  if valid_594902 != nil:
    section.add "MaxRecords", valid_594902
  var valid_594903 = query.getOrDefault("Filters")
  valid_594903 = validateParameter(valid_594903, JArray, required = false,
                                 default = nil)
  if valid_594903 != nil:
    section.add "Filters", valid_594903
  var valid_594904 = query.getOrDefault("DBParameterGroupName")
  valid_594904 = validateParameter(valid_594904, JString, required = false,
                                 default = nil)
  if valid_594904 != nil:
    section.add "DBParameterGroupName", valid_594904
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594905 = query.getOrDefault("Action")
  valid_594905 = validateParameter(valid_594905, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_594905 != nil:
    section.add "Action", valid_594905
  var valid_594906 = query.getOrDefault("Marker")
  valid_594906 = validateParameter(valid_594906, JString, required = false,
                                 default = nil)
  if valid_594906 != nil:
    section.add "Marker", valid_594906
  var valid_594907 = query.getOrDefault("Version")
  valid_594907 = validateParameter(valid_594907, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594907 != nil:
    section.add "Version", valid_594907
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
  var valid_594908 = header.getOrDefault("X-Amz-Date")
  valid_594908 = validateParameter(valid_594908, JString, required = false,
                                 default = nil)
  if valid_594908 != nil:
    section.add "X-Amz-Date", valid_594908
  var valid_594909 = header.getOrDefault("X-Amz-Security-Token")
  valid_594909 = validateParameter(valid_594909, JString, required = false,
                                 default = nil)
  if valid_594909 != nil:
    section.add "X-Amz-Security-Token", valid_594909
  var valid_594910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594910 = validateParameter(valid_594910, JString, required = false,
                                 default = nil)
  if valid_594910 != nil:
    section.add "X-Amz-Content-Sha256", valid_594910
  var valid_594911 = header.getOrDefault("X-Amz-Algorithm")
  valid_594911 = validateParameter(valid_594911, JString, required = false,
                                 default = nil)
  if valid_594911 != nil:
    section.add "X-Amz-Algorithm", valid_594911
  var valid_594912 = header.getOrDefault("X-Amz-Signature")
  valid_594912 = validateParameter(valid_594912, JString, required = false,
                                 default = nil)
  if valid_594912 != nil:
    section.add "X-Amz-Signature", valid_594912
  var valid_594913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594913 = validateParameter(valid_594913, JString, required = false,
                                 default = nil)
  if valid_594913 != nil:
    section.add "X-Amz-SignedHeaders", valid_594913
  var valid_594914 = header.getOrDefault("X-Amz-Credential")
  valid_594914 = validateParameter(valid_594914, JString, required = false,
                                 default = nil)
  if valid_594914 != nil:
    section.add "X-Amz-Credential", valid_594914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594915: Call_GetDescribeDBParameterGroups_594899; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594915.validator(path, query, header, formData, body)
  let scheme = call_594915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594915.url(scheme.get, call_594915.host, call_594915.base,
                         call_594915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594915, url, valid)

proc call*(call_594916: Call_GetDescribeDBParameterGroups_594899;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_594917 = newJObject()
  add(query_594917, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_594917.add "Filters", Filters
  add(query_594917, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594917, "Action", newJString(Action))
  add(query_594917, "Marker", newJString(Marker))
  add(query_594917, "Version", newJString(Version))
  result = call_594916.call(nil, query_594917, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_594899(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_594900, base: "/",
    url: url_GetDescribeDBParameterGroups_594901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_594958 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBParameters_594960(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_594959(path: JsonNode; query: JsonNode;
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
  var valid_594961 = query.getOrDefault("Action")
  valid_594961 = validateParameter(valid_594961, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_594961 != nil:
    section.add "Action", valid_594961
  var valid_594962 = query.getOrDefault("Version")
  valid_594962 = validateParameter(valid_594962, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594962 != nil:
    section.add "Version", valid_594962
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
  var valid_594963 = header.getOrDefault("X-Amz-Date")
  valid_594963 = validateParameter(valid_594963, JString, required = false,
                                 default = nil)
  if valid_594963 != nil:
    section.add "X-Amz-Date", valid_594963
  var valid_594964 = header.getOrDefault("X-Amz-Security-Token")
  valid_594964 = validateParameter(valid_594964, JString, required = false,
                                 default = nil)
  if valid_594964 != nil:
    section.add "X-Amz-Security-Token", valid_594964
  var valid_594965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594965 = validateParameter(valid_594965, JString, required = false,
                                 default = nil)
  if valid_594965 != nil:
    section.add "X-Amz-Content-Sha256", valid_594965
  var valid_594966 = header.getOrDefault("X-Amz-Algorithm")
  valid_594966 = validateParameter(valid_594966, JString, required = false,
                                 default = nil)
  if valid_594966 != nil:
    section.add "X-Amz-Algorithm", valid_594966
  var valid_594967 = header.getOrDefault("X-Amz-Signature")
  valid_594967 = validateParameter(valid_594967, JString, required = false,
                                 default = nil)
  if valid_594967 != nil:
    section.add "X-Amz-Signature", valid_594967
  var valid_594968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594968 = validateParameter(valid_594968, JString, required = false,
                                 default = nil)
  if valid_594968 != nil:
    section.add "X-Amz-SignedHeaders", valid_594968
  var valid_594969 = header.getOrDefault("X-Amz-Credential")
  valid_594969 = validateParameter(valid_594969, JString, required = false,
                                 default = nil)
  if valid_594969 != nil:
    section.add "X-Amz-Credential", valid_594969
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594970 = formData.getOrDefault("DBParameterGroupName")
  valid_594970 = validateParameter(valid_594970, JString, required = true,
                                 default = nil)
  if valid_594970 != nil:
    section.add "DBParameterGroupName", valid_594970
  var valid_594971 = formData.getOrDefault("Marker")
  valid_594971 = validateParameter(valid_594971, JString, required = false,
                                 default = nil)
  if valid_594971 != nil:
    section.add "Marker", valid_594971
  var valid_594972 = formData.getOrDefault("Filters")
  valid_594972 = validateParameter(valid_594972, JArray, required = false,
                                 default = nil)
  if valid_594972 != nil:
    section.add "Filters", valid_594972
  var valid_594973 = formData.getOrDefault("MaxRecords")
  valid_594973 = validateParameter(valid_594973, JInt, required = false, default = nil)
  if valid_594973 != nil:
    section.add "MaxRecords", valid_594973
  var valid_594974 = formData.getOrDefault("Source")
  valid_594974 = validateParameter(valid_594974, JString, required = false,
                                 default = nil)
  if valid_594974 != nil:
    section.add "Source", valid_594974
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594975: Call_PostDescribeDBParameters_594958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594975.validator(path, query, header, formData, body)
  let scheme = call_594975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594975.url(scheme.get, call_594975.host, call_594975.base,
                         call_594975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594975, url, valid)

proc call*(call_594976: Call_PostDescribeDBParameters_594958;
          DBParameterGroupName: string; Marker: string = "";
          Action: string = "DescribeDBParameters"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"; Source: string = ""): Recallable =
  ## postDescribeDBParameters
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  ##   Source: string
  var query_594977 = newJObject()
  var formData_594978 = newJObject()
  add(formData_594978, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_594978, "Marker", newJString(Marker))
  add(query_594977, "Action", newJString(Action))
  if Filters != nil:
    formData_594978.add "Filters", Filters
  add(formData_594978, "MaxRecords", newJInt(MaxRecords))
  add(query_594977, "Version", newJString(Version))
  add(formData_594978, "Source", newJString(Source))
  result = call_594976.call(nil, query_594977, nil, formData_594978, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_594958(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_594959, base: "/",
    url: url_PostDescribeDBParameters_594960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_594938 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBParameters_594940(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_594939(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   DBParameterGroupName: JString (required)
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Source: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_594941 = query.getOrDefault("MaxRecords")
  valid_594941 = validateParameter(valid_594941, JInt, required = false, default = nil)
  if valid_594941 != nil:
    section.add "MaxRecords", valid_594941
  var valid_594942 = query.getOrDefault("Filters")
  valid_594942 = validateParameter(valid_594942, JArray, required = false,
                                 default = nil)
  if valid_594942 != nil:
    section.add "Filters", valid_594942
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_594943 = query.getOrDefault("DBParameterGroupName")
  valid_594943 = validateParameter(valid_594943, JString, required = true,
                                 default = nil)
  if valid_594943 != nil:
    section.add "DBParameterGroupName", valid_594943
  var valid_594944 = query.getOrDefault("Action")
  valid_594944 = validateParameter(valid_594944, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_594944 != nil:
    section.add "Action", valid_594944
  var valid_594945 = query.getOrDefault("Marker")
  valid_594945 = validateParameter(valid_594945, JString, required = false,
                                 default = nil)
  if valid_594945 != nil:
    section.add "Marker", valid_594945
  var valid_594946 = query.getOrDefault("Source")
  valid_594946 = validateParameter(valid_594946, JString, required = false,
                                 default = nil)
  if valid_594946 != nil:
    section.add "Source", valid_594946
  var valid_594947 = query.getOrDefault("Version")
  valid_594947 = validateParameter(valid_594947, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594947 != nil:
    section.add "Version", valid_594947
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
  var valid_594948 = header.getOrDefault("X-Amz-Date")
  valid_594948 = validateParameter(valid_594948, JString, required = false,
                                 default = nil)
  if valid_594948 != nil:
    section.add "X-Amz-Date", valid_594948
  var valid_594949 = header.getOrDefault("X-Amz-Security-Token")
  valid_594949 = validateParameter(valid_594949, JString, required = false,
                                 default = nil)
  if valid_594949 != nil:
    section.add "X-Amz-Security-Token", valid_594949
  var valid_594950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594950 = validateParameter(valid_594950, JString, required = false,
                                 default = nil)
  if valid_594950 != nil:
    section.add "X-Amz-Content-Sha256", valid_594950
  var valid_594951 = header.getOrDefault("X-Amz-Algorithm")
  valid_594951 = validateParameter(valid_594951, JString, required = false,
                                 default = nil)
  if valid_594951 != nil:
    section.add "X-Amz-Algorithm", valid_594951
  var valid_594952 = header.getOrDefault("X-Amz-Signature")
  valid_594952 = validateParameter(valid_594952, JString, required = false,
                                 default = nil)
  if valid_594952 != nil:
    section.add "X-Amz-Signature", valid_594952
  var valid_594953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594953 = validateParameter(valid_594953, JString, required = false,
                                 default = nil)
  if valid_594953 != nil:
    section.add "X-Amz-SignedHeaders", valid_594953
  var valid_594954 = header.getOrDefault("X-Amz-Credential")
  valid_594954 = validateParameter(valid_594954, JString, required = false,
                                 default = nil)
  if valid_594954 != nil:
    section.add "X-Amz-Credential", valid_594954
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594955: Call_GetDescribeDBParameters_594938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594955.validator(path, query, header, formData, body)
  let scheme = call_594955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594955.url(scheme.get, call_594955.host, call_594955.base,
                         call_594955.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594955, url, valid)

proc call*(call_594956: Call_GetDescribeDBParameters_594938;
          DBParameterGroupName: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBParameters"; Marker: string = "";
          Source: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getDescribeDBParameters
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Source: string
  ##   Version: string (required)
  var query_594957 = newJObject()
  add(query_594957, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_594957.add "Filters", Filters
  add(query_594957, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594957, "Action", newJString(Action))
  add(query_594957, "Marker", newJString(Marker))
  add(query_594957, "Source", newJString(Source))
  add(query_594957, "Version", newJString(Version))
  result = call_594956.call(nil, query_594957, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_594938(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_594939, base: "/",
    url: url_GetDescribeDBParameters_594940, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_594998 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBSecurityGroups_595000(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_594999(path: JsonNode; query: JsonNode;
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
  var valid_595001 = query.getOrDefault("Action")
  valid_595001 = validateParameter(valid_595001, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_595001 != nil:
    section.add "Action", valid_595001
  var valid_595002 = query.getOrDefault("Version")
  valid_595002 = validateParameter(valid_595002, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595002 != nil:
    section.add "Version", valid_595002
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
  var valid_595003 = header.getOrDefault("X-Amz-Date")
  valid_595003 = validateParameter(valid_595003, JString, required = false,
                                 default = nil)
  if valid_595003 != nil:
    section.add "X-Amz-Date", valid_595003
  var valid_595004 = header.getOrDefault("X-Amz-Security-Token")
  valid_595004 = validateParameter(valid_595004, JString, required = false,
                                 default = nil)
  if valid_595004 != nil:
    section.add "X-Amz-Security-Token", valid_595004
  var valid_595005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595005 = validateParameter(valid_595005, JString, required = false,
                                 default = nil)
  if valid_595005 != nil:
    section.add "X-Amz-Content-Sha256", valid_595005
  var valid_595006 = header.getOrDefault("X-Amz-Algorithm")
  valid_595006 = validateParameter(valid_595006, JString, required = false,
                                 default = nil)
  if valid_595006 != nil:
    section.add "X-Amz-Algorithm", valid_595006
  var valid_595007 = header.getOrDefault("X-Amz-Signature")
  valid_595007 = validateParameter(valid_595007, JString, required = false,
                                 default = nil)
  if valid_595007 != nil:
    section.add "X-Amz-Signature", valid_595007
  var valid_595008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595008 = validateParameter(valid_595008, JString, required = false,
                                 default = nil)
  if valid_595008 != nil:
    section.add "X-Amz-SignedHeaders", valid_595008
  var valid_595009 = header.getOrDefault("X-Amz-Credential")
  valid_595009 = validateParameter(valid_595009, JString, required = false,
                                 default = nil)
  if valid_595009 != nil:
    section.add "X-Amz-Credential", valid_595009
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595010 = formData.getOrDefault("DBSecurityGroupName")
  valid_595010 = validateParameter(valid_595010, JString, required = false,
                                 default = nil)
  if valid_595010 != nil:
    section.add "DBSecurityGroupName", valid_595010
  var valid_595011 = formData.getOrDefault("Marker")
  valid_595011 = validateParameter(valid_595011, JString, required = false,
                                 default = nil)
  if valid_595011 != nil:
    section.add "Marker", valid_595011
  var valid_595012 = formData.getOrDefault("Filters")
  valid_595012 = validateParameter(valid_595012, JArray, required = false,
                                 default = nil)
  if valid_595012 != nil:
    section.add "Filters", valid_595012
  var valid_595013 = formData.getOrDefault("MaxRecords")
  valid_595013 = validateParameter(valid_595013, JInt, required = false, default = nil)
  if valid_595013 != nil:
    section.add "MaxRecords", valid_595013
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595014: Call_PostDescribeDBSecurityGroups_594998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595014.validator(path, query, header, formData, body)
  let scheme = call_595014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595014.url(scheme.get, call_595014.host, call_595014.base,
                         call_595014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595014, url, valid)

proc call*(call_595015: Call_PostDescribeDBSecurityGroups_594998;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595016 = newJObject()
  var formData_595017 = newJObject()
  add(formData_595017, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_595017, "Marker", newJString(Marker))
  add(query_595016, "Action", newJString(Action))
  if Filters != nil:
    formData_595017.add "Filters", Filters
  add(formData_595017, "MaxRecords", newJInt(MaxRecords))
  add(query_595016, "Version", newJString(Version))
  result = call_595015.call(nil, query_595016, nil, formData_595017, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_594998(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_594999, base: "/",
    url: url_PostDescribeDBSecurityGroups_595000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_594979 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBSecurityGroups_594981(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_594980(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   DBSecurityGroupName: JString
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_594982 = query.getOrDefault("MaxRecords")
  valid_594982 = validateParameter(valid_594982, JInt, required = false, default = nil)
  if valid_594982 != nil:
    section.add "MaxRecords", valid_594982
  var valid_594983 = query.getOrDefault("DBSecurityGroupName")
  valid_594983 = validateParameter(valid_594983, JString, required = false,
                                 default = nil)
  if valid_594983 != nil:
    section.add "DBSecurityGroupName", valid_594983
  var valid_594984 = query.getOrDefault("Filters")
  valid_594984 = validateParameter(valid_594984, JArray, required = false,
                                 default = nil)
  if valid_594984 != nil:
    section.add "Filters", valid_594984
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594985 = query.getOrDefault("Action")
  valid_594985 = validateParameter(valid_594985, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_594985 != nil:
    section.add "Action", valid_594985
  var valid_594986 = query.getOrDefault("Marker")
  valid_594986 = validateParameter(valid_594986, JString, required = false,
                                 default = nil)
  if valid_594986 != nil:
    section.add "Marker", valid_594986
  var valid_594987 = query.getOrDefault("Version")
  valid_594987 = validateParameter(valid_594987, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594987 != nil:
    section.add "Version", valid_594987
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
  var valid_594988 = header.getOrDefault("X-Amz-Date")
  valid_594988 = validateParameter(valid_594988, JString, required = false,
                                 default = nil)
  if valid_594988 != nil:
    section.add "X-Amz-Date", valid_594988
  var valid_594989 = header.getOrDefault("X-Amz-Security-Token")
  valid_594989 = validateParameter(valid_594989, JString, required = false,
                                 default = nil)
  if valid_594989 != nil:
    section.add "X-Amz-Security-Token", valid_594989
  var valid_594990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594990 = validateParameter(valid_594990, JString, required = false,
                                 default = nil)
  if valid_594990 != nil:
    section.add "X-Amz-Content-Sha256", valid_594990
  var valid_594991 = header.getOrDefault("X-Amz-Algorithm")
  valid_594991 = validateParameter(valid_594991, JString, required = false,
                                 default = nil)
  if valid_594991 != nil:
    section.add "X-Amz-Algorithm", valid_594991
  var valid_594992 = header.getOrDefault("X-Amz-Signature")
  valid_594992 = validateParameter(valid_594992, JString, required = false,
                                 default = nil)
  if valid_594992 != nil:
    section.add "X-Amz-Signature", valid_594992
  var valid_594993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594993 = validateParameter(valid_594993, JString, required = false,
                                 default = nil)
  if valid_594993 != nil:
    section.add "X-Amz-SignedHeaders", valid_594993
  var valid_594994 = header.getOrDefault("X-Amz-Credential")
  valid_594994 = validateParameter(valid_594994, JString, required = false,
                                 default = nil)
  if valid_594994 != nil:
    section.add "X-Amz-Credential", valid_594994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594995: Call_GetDescribeDBSecurityGroups_594979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594995.validator(path, query, header, formData, body)
  let scheme = call_594995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594995.url(scheme.get, call_594995.host, call_594995.base,
                         call_594995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594995, url, valid)

proc call*(call_594996: Call_GetDescribeDBSecurityGroups_594979;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Filters: JsonNode = nil; Action: string = "DescribeDBSecurityGroups";
          Marker: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_594997 = newJObject()
  add(query_594997, "MaxRecords", newJInt(MaxRecords))
  add(query_594997, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_594997.add "Filters", Filters
  add(query_594997, "Action", newJString(Action))
  add(query_594997, "Marker", newJString(Marker))
  add(query_594997, "Version", newJString(Version))
  result = call_594996.call(nil, query_594997, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_594979(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_594980, base: "/",
    url: url_GetDescribeDBSecurityGroups_594981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_595039 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBSnapshots_595041(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSnapshots_595040(path: JsonNode; query: JsonNode;
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
  var valid_595042 = query.getOrDefault("Action")
  valid_595042 = validateParameter(valid_595042, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_595042 != nil:
    section.add "Action", valid_595042
  var valid_595043 = query.getOrDefault("Version")
  valid_595043 = validateParameter(valid_595043, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595043 != nil:
    section.add "Version", valid_595043
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
  var valid_595044 = header.getOrDefault("X-Amz-Date")
  valid_595044 = validateParameter(valid_595044, JString, required = false,
                                 default = nil)
  if valid_595044 != nil:
    section.add "X-Amz-Date", valid_595044
  var valid_595045 = header.getOrDefault("X-Amz-Security-Token")
  valid_595045 = validateParameter(valid_595045, JString, required = false,
                                 default = nil)
  if valid_595045 != nil:
    section.add "X-Amz-Security-Token", valid_595045
  var valid_595046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595046 = validateParameter(valid_595046, JString, required = false,
                                 default = nil)
  if valid_595046 != nil:
    section.add "X-Amz-Content-Sha256", valid_595046
  var valid_595047 = header.getOrDefault("X-Amz-Algorithm")
  valid_595047 = validateParameter(valid_595047, JString, required = false,
                                 default = nil)
  if valid_595047 != nil:
    section.add "X-Amz-Algorithm", valid_595047
  var valid_595048 = header.getOrDefault("X-Amz-Signature")
  valid_595048 = validateParameter(valid_595048, JString, required = false,
                                 default = nil)
  if valid_595048 != nil:
    section.add "X-Amz-Signature", valid_595048
  var valid_595049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595049 = validateParameter(valid_595049, JString, required = false,
                                 default = nil)
  if valid_595049 != nil:
    section.add "X-Amz-SignedHeaders", valid_595049
  var valid_595050 = header.getOrDefault("X-Amz-Credential")
  valid_595050 = validateParameter(valid_595050, JString, required = false,
                                 default = nil)
  if valid_595050 != nil:
    section.add "X-Amz-Credential", valid_595050
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595051 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595051 = validateParameter(valid_595051, JString, required = false,
                                 default = nil)
  if valid_595051 != nil:
    section.add "DBInstanceIdentifier", valid_595051
  var valid_595052 = formData.getOrDefault("SnapshotType")
  valid_595052 = validateParameter(valid_595052, JString, required = false,
                                 default = nil)
  if valid_595052 != nil:
    section.add "SnapshotType", valid_595052
  var valid_595053 = formData.getOrDefault("Marker")
  valid_595053 = validateParameter(valid_595053, JString, required = false,
                                 default = nil)
  if valid_595053 != nil:
    section.add "Marker", valid_595053
  var valid_595054 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_595054 = validateParameter(valid_595054, JString, required = false,
                                 default = nil)
  if valid_595054 != nil:
    section.add "DBSnapshotIdentifier", valid_595054
  var valid_595055 = formData.getOrDefault("Filters")
  valid_595055 = validateParameter(valid_595055, JArray, required = false,
                                 default = nil)
  if valid_595055 != nil:
    section.add "Filters", valid_595055
  var valid_595056 = formData.getOrDefault("MaxRecords")
  valid_595056 = validateParameter(valid_595056, JInt, required = false, default = nil)
  if valid_595056 != nil:
    section.add "MaxRecords", valid_595056
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595057: Call_PostDescribeDBSnapshots_595039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595057.validator(path, query, header, formData, body)
  let scheme = call_595057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595057.url(scheme.get, call_595057.host, call_595057.base,
                         call_595057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595057, url, valid)

proc call*(call_595058: Call_PostDescribeDBSnapshots_595039;
          DBInstanceIdentifier: string = ""; SnapshotType: string = "";
          Marker: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSnapshots
  ##   DBInstanceIdentifier: string
  ##   SnapshotType: string
  ##   Marker: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595059 = newJObject()
  var formData_595060 = newJObject()
  add(formData_595060, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595060, "SnapshotType", newJString(SnapshotType))
  add(formData_595060, "Marker", newJString(Marker))
  add(formData_595060, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_595059, "Action", newJString(Action))
  if Filters != nil:
    formData_595060.add "Filters", Filters
  add(formData_595060, "MaxRecords", newJInt(MaxRecords))
  add(query_595059, "Version", newJString(Version))
  result = call_595058.call(nil, query_595059, nil, formData_595060, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_595039(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_595040, base: "/",
    url: url_PostDescribeDBSnapshots_595041, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_595018 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBSnapshots_595020(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_595019(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   SnapshotType: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  section = newJObject()
  var valid_595021 = query.getOrDefault("MaxRecords")
  valid_595021 = validateParameter(valid_595021, JInt, required = false, default = nil)
  if valid_595021 != nil:
    section.add "MaxRecords", valid_595021
  var valid_595022 = query.getOrDefault("Filters")
  valid_595022 = validateParameter(valid_595022, JArray, required = false,
                                 default = nil)
  if valid_595022 != nil:
    section.add "Filters", valid_595022
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595023 = query.getOrDefault("Action")
  valid_595023 = validateParameter(valid_595023, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_595023 != nil:
    section.add "Action", valid_595023
  var valid_595024 = query.getOrDefault("Marker")
  valid_595024 = validateParameter(valid_595024, JString, required = false,
                                 default = nil)
  if valid_595024 != nil:
    section.add "Marker", valid_595024
  var valid_595025 = query.getOrDefault("SnapshotType")
  valid_595025 = validateParameter(valid_595025, JString, required = false,
                                 default = nil)
  if valid_595025 != nil:
    section.add "SnapshotType", valid_595025
  var valid_595026 = query.getOrDefault("Version")
  valid_595026 = validateParameter(valid_595026, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595026 != nil:
    section.add "Version", valid_595026
  var valid_595027 = query.getOrDefault("DBInstanceIdentifier")
  valid_595027 = validateParameter(valid_595027, JString, required = false,
                                 default = nil)
  if valid_595027 != nil:
    section.add "DBInstanceIdentifier", valid_595027
  var valid_595028 = query.getOrDefault("DBSnapshotIdentifier")
  valid_595028 = validateParameter(valid_595028, JString, required = false,
                                 default = nil)
  if valid_595028 != nil:
    section.add "DBSnapshotIdentifier", valid_595028
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
  var valid_595029 = header.getOrDefault("X-Amz-Date")
  valid_595029 = validateParameter(valid_595029, JString, required = false,
                                 default = nil)
  if valid_595029 != nil:
    section.add "X-Amz-Date", valid_595029
  var valid_595030 = header.getOrDefault("X-Amz-Security-Token")
  valid_595030 = validateParameter(valid_595030, JString, required = false,
                                 default = nil)
  if valid_595030 != nil:
    section.add "X-Amz-Security-Token", valid_595030
  var valid_595031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "X-Amz-Content-Sha256", valid_595031
  var valid_595032 = header.getOrDefault("X-Amz-Algorithm")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "X-Amz-Algorithm", valid_595032
  var valid_595033 = header.getOrDefault("X-Amz-Signature")
  valid_595033 = validateParameter(valid_595033, JString, required = false,
                                 default = nil)
  if valid_595033 != nil:
    section.add "X-Amz-Signature", valid_595033
  var valid_595034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595034 = validateParameter(valid_595034, JString, required = false,
                                 default = nil)
  if valid_595034 != nil:
    section.add "X-Amz-SignedHeaders", valid_595034
  var valid_595035 = header.getOrDefault("X-Amz-Credential")
  valid_595035 = validateParameter(valid_595035, JString, required = false,
                                 default = nil)
  if valid_595035 != nil:
    section.add "X-Amz-Credential", valid_595035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595036: Call_GetDescribeDBSnapshots_595018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595036.validator(path, query, header, formData, body)
  let scheme = call_595036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595036.url(scheme.get, call_595036.host, call_595036.base,
                         call_595036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595036, url, valid)

proc call*(call_595037: Call_GetDescribeDBSnapshots_595018; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBSnapshots";
          Marker: string = ""; SnapshotType: string = "";
          Version: string = "2013-09-09"; DBInstanceIdentifier: string = "";
          DBSnapshotIdentifier: string = ""): Recallable =
  ## getDescribeDBSnapshots
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   SnapshotType: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  var query_595038 = newJObject()
  add(query_595038, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595038.add "Filters", Filters
  add(query_595038, "Action", newJString(Action))
  add(query_595038, "Marker", newJString(Marker))
  add(query_595038, "SnapshotType", newJString(SnapshotType))
  add(query_595038, "Version", newJString(Version))
  add(query_595038, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595038, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_595037.call(nil, query_595038, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_595018(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_595019, base: "/",
    url: url_GetDescribeDBSnapshots_595020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_595080 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBSubnetGroups_595082(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_595081(path: JsonNode; query: JsonNode;
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
  var valid_595083 = query.getOrDefault("Action")
  valid_595083 = validateParameter(valid_595083, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_595083 != nil:
    section.add "Action", valid_595083
  var valid_595084 = query.getOrDefault("Version")
  valid_595084 = validateParameter(valid_595084, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595084 != nil:
    section.add "Version", valid_595084
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
  var valid_595085 = header.getOrDefault("X-Amz-Date")
  valid_595085 = validateParameter(valid_595085, JString, required = false,
                                 default = nil)
  if valid_595085 != nil:
    section.add "X-Amz-Date", valid_595085
  var valid_595086 = header.getOrDefault("X-Amz-Security-Token")
  valid_595086 = validateParameter(valid_595086, JString, required = false,
                                 default = nil)
  if valid_595086 != nil:
    section.add "X-Amz-Security-Token", valid_595086
  var valid_595087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595087 = validateParameter(valid_595087, JString, required = false,
                                 default = nil)
  if valid_595087 != nil:
    section.add "X-Amz-Content-Sha256", valid_595087
  var valid_595088 = header.getOrDefault("X-Amz-Algorithm")
  valid_595088 = validateParameter(valid_595088, JString, required = false,
                                 default = nil)
  if valid_595088 != nil:
    section.add "X-Amz-Algorithm", valid_595088
  var valid_595089 = header.getOrDefault("X-Amz-Signature")
  valid_595089 = validateParameter(valid_595089, JString, required = false,
                                 default = nil)
  if valid_595089 != nil:
    section.add "X-Amz-Signature", valid_595089
  var valid_595090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595090 = validateParameter(valid_595090, JString, required = false,
                                 default = nil)
  if valid_595090 != nil:
    section.add "X-Amz-SignedHeaders", valid_595090
  var valid_595091 = header.getOrDefault("X-Amz-Credential")
  valid_595091 = validateParameter(valid_595091, JString, required = false,
                                 default = nil)
  if valid_595091 != nil:
    section.add "X-Amz-Credential", valid_595091
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595092 = formData.getOrDefault("DBSubnetGroupName")
  valid_595092 = validateParameter(valid_595092, JString, required = false,
                                 default = nil)
  if valid_595092 != nil:
    section.add "DBSubnetGroupName", valid_595092
  var valid_595093 = formData.getOrDefault("Marker")
  valid_595093 = validateParameter(valid_595093, JString, required = false,
                                 default = nil)
  if valid_595093 != nil:
    section.add "Marker", valid_595093
  var valid_595094 = formData.getOrDefault("Filters")
  valid_595094 = validateParameter(valid_595094, JArray, required = false,
                                 default = nil)
  if valid_595094 != nil:
    section.add "Filters", valid_595094
  var valid_595095 = formData.getOrDefault("MaxRecords")
  valid_595095 = validateParameter(valid_595095, JInt, required = false, default = nil)
  if valid_595095 != nil:
    section.add "MaxRecords", valid_595095
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595096: Call_PostDescribeDBSubnetGroups_595080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595096.validator(path, query, header, formData, body)
  let scheme = call_595096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595096.url(scheme.get, call_595096.host, call_595096.base,
                         call_595096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595096, url, valid)

proc call*(call_595097: Call_PostDescribeDBSubnetGroups_595080;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595098 = newJObject()
  var formData_595099 = newJObject()
  add(formData_595099, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_595099, "Marker", newJString(Marker))
  add(query_595098, "Action", newJString(Action))
  if Filters != nil:
    formData_595099.add "Filters", Filters
  add(formData_595099, "MaxRecords", newJInt(MaxRecords))
  add(query_595098, "Version", newJString(Version))
  result = call_595097.call(nil, query_595098, nil, formData_595099, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_595080(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_595081, base: "/",
    url: url_PostDescribeDBSubnetGroups_595082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_595061 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBSubnetGroups_595063(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_595062(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_595064 = query.getOrDefault("MaxRecords")
  valid_595064 = validateParameter(valid_595064, JInt, required = false, default = nil)
  if valid_595064 != nil:
    section.add "MaxRecords", valid_595064
  var valid_595065 = query.getOrDefault("Filters")
  valid_595065 = validateParameter(valid_595065, JArray, required = false,
                                 default = nil)
  if valid_595065 != nil:
    section.add "Filters", valid_595065
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595066 = query.getOrDefault("Action")
  valid_595066 = validateParameter(valid_595066, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_595066 != nil:
    section.add "Action", valid_595066
  var valid_595067 = query.getOrDefault("Marker")
  valid_595067 = validateParameter(valid_595067, JString, required = false,
                                 default = nil)
  if valid_595067 != nil:
    section.add "Marker", valid_595067
  var valid_595068 = query.getOrDefault("DBSubnetGroupName")
  valid_595068 = validateParameter(valid_595068, JString, required = false,
                                 default = nil)
  if valid_595068 != nil:
    section.add "DBSubnetGroupName", valid_595068
  var valid_595069 = query.getOrDefault("Version")
  valid_595069 = validateParameter(valid_595069, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595069 != nil:
    section.add "Version", valid_595069
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
  var valid_595070 = header.getOrDefault("X-Amz-Date")
  valid_595070 = validateParameter(valid_595070, JString, required = false,
                                 default = nil)
  if valid_595070 != nil:
    section.add "X-Amz-Date", valid_595070
  var valid_595071 = header.getOrDefault("X-Amz-Security-Token")
  valid_595071 = validateParameter(valid_595071, JString, required = false,
                                 default = nil)
  if valid_595071 != nil:
    section.add "X-Amz-Security-Token", valid_595071
  var valid_595072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595072 = validateParameter(valid_595072, JString, required = false,
                                 default = nil)
  if valid_595072 != nil:
    section.add "X-Amz-Content-Sha256", valid_595072
  var valid_595073 = header.getOrDefault("X-Amz-Algorithm")
  valid_595073 = validateParameter(valid_595073, JString, required = false,
                                 default = nil)
  if valid_595073 != nil:
    section.add "X-Amz-Algorithm", valid_595073
  var valid_595074 = header.getOrDefault("X-Amz-Signature")
  valid_595074 = validateParameter(valid_595074, JString, required = false,
                                 default = nil)
  if valid_595074 != nil:
    section.add "X-Amz-Signature", valid_595074
  var valid_595075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595075 = validateParameter(valid_595075, JString, required = false,
                                 default = nil)
  if valid_595075 != nil:
    section.add "X-Amz-SignedHeaders", valid_595075
  var valid_595076 = header.getOrDefault("X-Amz-Credential")
  valid_595076 = validateParameter(valid_595076, JString, required = false,
                                 default = nil)
  if valid_595076 != nil:
    section.add "X-Amz-Credential", valid_595076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595077: Call_GetDescribeDBSubnetGroups_595061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595077.validator(path, query, header, formData, body)
  let scheme = call_595077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595077.url(scheme.get, call_595077.host, call_595077.base,
                         call_595077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595077, url, valid)

proc call*(call_595078: Call_GetDescribeDBSubnetGroups_595061; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBSubnetGroups";
          Marker: string = ""; DBSubnetGroupName: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_595079 = newJObject()
  add(query_595079, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595079.add "Filters", Filters
  add(query_595079, "Action", newJString(Action))
  add(query_595079, "Marker", newJString(Marker))
  add(query_595079, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_595079, "Version", newJString(Version))
  result = call_595078.call(nil, query_595079, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_595061(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_595062, base: "/",
    url: url_GetDescribeDBSubnetGroups_595063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_595119 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEngineDefaultParameters_595121(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_595120(path: JsonNode;
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
  var valid_595122 = query.getOrDefault("Action")
  valid_595122 = validateParameter(valid_595122, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_595122 != nil:
    section.add "Action", valid_595122
  var valid_595123 = query.getOrDefault("Version")
  valid_595123 = validateParameter(valid_595123, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595123 != nil:
    section.add "Version", valid_595123
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
  var valid_595124 = header.getOrDefault("X-Amz-Date")
  valid_595124 = validateParameter(valid_595124, JString, required = false,
                                 default = nil)
  if valid_595124 != nil:
    section.add "X-Amz-Date", valid_595124
  var valid_595125 = header.getOrDefault("X-Amz-Security-Token")
  valid_595125 = validateParameter(valid_595125, JString, required = false,
                                 default = nil)
  if valid_595125 != nil:
    section.add "X-Amz-Security-Token", valid_595125
  var valid_595126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595126 = validateParameter(valid_595126, JString, required = false,
                                 default = nil)
  if valid_595126 != nil:
    section.add "X-Amz-Content-Sha256", valid_595126
  var valid_595127 = header.getOrDefault("X-Amz-Algorithm")
  valid_595127 = validateParameter(valid_595127, JString, required = false,
                                 default = nil)
  if valid_595127 != nil:
    section.add "X-Amz-Algorithm", valid_595127
  var valid_595128 = header.getOrDefault("X-Amz-Signature")
  valid_595128 = validateParameter(valid_595128, JString, required = false,
                                 default = nil)
  if valid_595128 != nil:
    section.add "X-Amz-Signature", valid_595128
  var valid_595129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595129 = validateParameter(valid_595129, JString, required = false,
                                 default = nil)
  if valid_595129 != nil:
    section.add "X-Amz-SignedHeaders", valid_595129
  var valid_595130 = header.getOrDefault("X-Amz-Credential")
  valid_595130 = validateParameter(valid_595130, JString, required = false,
                                 default = nil)
  if valid_595130 != nil:
    section.add "X-Amz-Credential", valid_595130
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595131 = formData.getOrDefault("Marker")
  valid_595131 = validateParameter(valid_595131, JString, required = false,
                                 default = nil)
  if valid_595131 != nil:
    section.add "Marker", valid_595131
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_595132 = formData.getOrDefault("DBParameterGroupFamily")
  valid_595132 = validateParameter(valid_595132, JString, required = true,
                                 default = nil)
  if valid_595132 != nil:
    section.add "DBParameterGroupFamily", valid_595132
  var valid_595133 = formData.getOrDefault("Filters")
  valid_595133 = validateParameter(valid_595133, JArray, required = false,
                                 default = nil)
  if valid_595133 != nil:
    section.add "Filters", valid_595133
  var valid_595134 = formData.getOrDefault("MaxRecords")
  valid_595134 = validateParameter(valid_595134, JInt, required = false, default = nil)
  if valid_595134 != nil:
    section.add "MaxRecords", valid_595134
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595135: Call_PostDescribeEngineDefaultParameters_595119;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595135.validator(path, query, header, formData, body)
  let scheme = call_595135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595135.url(scheme.get, call_595135.host, call_595135.base,
                         call_595135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595135, url, valid)

proc call*(call_595136: Call_PostDescribeEngineDefaultParameters_595119;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Filters: JsonNode = nil; MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595137 = newJObject()
  var formData_595138 = newJObject()
  add(formData_595138, "Marker", newJString(Marker))
  add(query_595137, "Action", newJString(Action))
  add(formData_595138, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_595138.add "Filters", Filters
  add(formData_595138, "MaxRecords", newJInt(MaxRecords))
  add(query_595137, "Version", newJString(Version))
  result = call_595136.call(nil, query_595137, nil, formData_595138, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_595119(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_595120, base: "/",
    url: url_PostDescribeEngineDefaultParameters_595121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_595100 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEngineDefaultParameters_595102(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_595101(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_595103 = query.getOrDefault("MaxRecords")
  valid_595103 = validateParameter(valid_595103, JInt, required = false, default = nil)
  if valid_595103 != nil:
    section.add "MaxRecords", valid_595103
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_595104 = query.getOrDefault("DBParameterGroupFamily")
  valid_595104 = validateParameter(valid_595104, JString, required = true,
                                 default = nil)
  if valid_595104 != nil:
    section.add "DBParameterGroupFamily", valid_595104
  var valid_595105 = query.getOrDefault("Filters")
  valid_595105 = validateParameter(valid_595105, JArray, required = false,
                                 default = nil)
  if valid_595105 != nil:
    section.add "Filters", valid_595105
  var valid_595106 = query.getOrDefault("Action")
  valid_595106 = validateParameter(valid_595106, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_595106 != nil:
    section.add "Action", valid_595106
  var valid_595107 = query.getOrDefault("Marker")
  valid_595107 = validateParameter(valid_595107, JString, required = false,
                                 default = nil)
  if valid_595107 != nil:
    section.add "Marker", valid_595107
  var valid_595108 = query.getOrDefault("Version")
  valid_595108 = validateParameter(valid_595108, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595108 != nil:
    section.add "Version", valid_595108
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
  var valid_595109 = header.getOrDefault("X-Amz-Date")
  valid_595109 = validateParameter(valid_595109, JString, required = false,
                                 default = nil)
  if valid_595109 != nil:
    section.add "X-Amz-Date", valid_595109
  var valid_595110 = header.getOrDefault("X-Amz-Security-Token")
  valid_595110 = validateParameter(valid_595110, JString, required = false,
                                 default = nil)
  if valid_595110 != nil:
    section.add "X-Amz-Security-Token", valid_595110
  var valid_595111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595111 = validateParameter(valid_595111, JString, required = false,
                                 default = nil)
  if valid_595111 != nil:
    section.add "X-Amz-Content-Sha256", valid_595111
  var valid_595112 = header.getOrDefault("X-Amz-Algorithm")
  valid_595112 = validateParameter(valid_595112, JString, required = false,
                                 default = nil)
  if valid_595112 != nil:
    section.add "X-Amz-Algorithm", valid_595112
  var valid_595113 = header.getOrDefault("X-Amz-Signature")
  valid_595113 = validateParameter(valid_595113, JString, required = false,
                                 default = nil)
  if valid_595113 != nil:
    section.add "X-Amz-Signature", valid_595113
  var valid_595114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595114 = validateParameter(valid_595114, JString, required = false,
                                 default = nil)
  if valid_595114 != nil:
    section.add "X-Amz-SignedHeaders", valid_595114
  var valid_595115 = header.getOrDefault("X-Amz-Credential")
  valid_595115 = validateParameter(valid_595115, JString, required = false,
                                 default = nil)
  if valid_595115 != nil:
    section.add "X-Amz-Credential", valid_595115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595116: Call_GetDescribeEngineDefaultParameters_595100;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595116.validator(path, query, header, formData, body)
  let scheme = call_595116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595116.url(scheme.get, call_595116.host, call_595116.base,
                         call_595116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595116, url, valid)

proc call*(call_595117: Call_GetDescribeEngineDefaultParameters_595100;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Filters: JsonNode = nil;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_595118 = newJObject()
  add(query_595118, "MaxRecords", newJInt(MaxRecords))
  add(query_595118, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_595118.add "Filters", Filters
  add(query_595118, "Action", newJString(Action))
  add(query_595118, "Marker", newJString(Marker))
  add(query_595118, "Version", newJString(Version))
  result = call_595117.call(nil, query_595118, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_595100(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_595101, base: "/",
    url: url_GetDescribeEngineDefaultParameters_595102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_595156 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEventCategories_595158(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_595157(path: JsonNode; query: JsonNode;
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
  var valid_595159 = query.getOrDefault("Action")
  valid_595159 = validateParameter(valid_595159, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_595159 != nil:
    section.add "Action", valid_595159
  var valid_595160 = query.getOrDefault("Version")
  valid_595160 = validateParameter(valid_595160, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595160 != nil:
    section.add "Version", valid_595160
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
  var valid_595161 = header.getOrDefault("X-Amz-Date")
  valid_595161 = validateParameter(valid_595161, JString, required = false,
                                 default = nil)
  if valid_595161 != nil:
    section.add "X-Amz-Date", valid_595161
  var valid_595162 = header.getOrDefault("X-Amz-Security-Token")
  valid_595162 = validateParameter(valid_595162, JString, required = false,
                                 default = nil)
  if valid_595162 != nil:
    section.add "X-Amz-Security-Token", valid_595162
  var valid_595163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595163 = validateParameter(valid_595163, JString, required = false,
                                 default = nil)
  if valid_595163 != nil:
    section.add "X-Amz-Content-Sha256", valid_595163
  var valid_595164 = header.getOrDefault("X-Amz-Algorithm")
  valid_595164 = validateParameter(valid_595164, JString, required = false,
                                 default = nil)
  if valid_595164 != nil:
    section.add "X-Amz-Algorithm", valid_595164
  var valid_595165 = header.getOrDefault("X-Amz-Signature")
  valid_595165 = validateParameter(valid_595165, JString, required = false,
                                 default = nil)
  if valid_595165 != nil:
    section.add "X-Amz-Signature", valid_595165
  var valid_595166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595166 = validateParameter(valid_595166, JString, required = false,
                                 default = nil)
  if valid_595166 != nil:
    section.add "X-Amz-SignedHeaders", valid_595166
  var valid_595167 = header.getOrDefault("X-Amz-Credential")
  valid_595167 = validateParameter(valid_595167, JString, required = false,
                                 default = nil)
  if valid_595167 != nil:
    section.add "X-Amz-Credential", valid_595167
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_595168 = formData.getOrDefault("Filters")
  valid_595168 = validateParameter(valid_595168, JArray, required = false,
                                 default = nil)
  if valid_595168 != nil:
    section.add "Filters", valid_595168
  var valid_595169 = formData.getOrDefault("SourceType")
  valid_595169 = validateParameter(valid_595169, JString, required = false,
                                 default = nil)
  if valid_595169 != nil:
    section.add "SourceType", valid_595169
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595170: Call_PostDescribeEventCategories_595156; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595170.validator(path, query, header, formData, body)
  let scheme = call_595170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595170.url(scheme.get, call_595170.host, call_595170.base,
                         call_595170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595170, url, valid)

proc call*(call_595171: Call_PostDescribeEventCategories_595156;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_595172 = newJObject()
  var formData_595173 = newJObject()
  add(query_595172, "Action", newJString(Action))
  if Filters != nil:
    formData_595173.add "Filters", Filters
  add(query_595172, "Version", newJString(Version))
  add(formData_595173, "SourceType", newJString(SourceType))
  result = call_595171.call(nil, query_595172, nil, formData_595173, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_595156(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_595157, base: "/",
    url: url_PostDescribeEventCategories_595158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_595139 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEventCategories_595141(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_595140(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_595142 = query.getOrDefault("SourceType")
  valid_595142 = validateParameter(valid_595142, JString, required = false,
                                 default = nil)
  if valid_595142 != nil:
    section.add "SourceType", valid_595142
  var valid_595143 = query.getOrDefault("Filters")
  valid_595143 = validateParameter(valid_595143, JArray, required = false,
                                 default = nil)
  if valid_595143 != nil:
    section.add "Filters", valid_595143
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595144 = query.getOrDefault("Action")
  valid_595144 = validateParameter(valid_595144, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_595144 != nil:
    section.add "Action", valid_595144
  var valid_595145 = query.getOrDefault("Version")
  valid_595145 = validateParameter(valid_595145, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595145 != nil:
    section.add "Version", valid_595145
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
  var valid_595146 = header.getOrDefault("X-Amz-Date")
  valid_595146 = validateParameter(valid_595146, JString, required = false,
                                 default = nil)
  if valid_595146 != nil:
    section.add "X-Amz-Date", valid_595146
  var valid_595147 = header.getOrDefault("X-Amz-Security-Token")
  valid_595147 = validateParameter(valid_595147, JString, required = false,
                                 default = nil)
  if valid_595147 != nil:
    section.add "X-Amz-Security-Token", valid_595147
  var valid_595148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595148 = validateParameter(valid_595148, JString, required = false,
                                 default = nil)
  if valid_595148 != nil:
    section.add "X-Amz-Content-Sha256", valid_595148
  var valid_595149 = header.getOrDefault("X-Amz-Algorithm")
  valid_595149 = validateParameter(valid_595149, JString, required = false,
                                 default = nil)
  if valid_595149 != nil:
    section.add "X-Amz-Algorithm", valid_595149
  var valid_595150 = header.getOrDefault("X-Amz-Signature")
  valid_595150 = validateParameter(valid_595150, JString, required = false,
                                 default = nil)
  if valid_595150 != nil:
    section.add "X-Amz-Signature", valid_595150
  var valid_595151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595151 = validateParameter(valid_595151, JString, required = false,
                                 default = nil)
  if valid_595151 != nil:
    section.add "X-Amz-SignedHeaders", valid_595151
  var valid_595152 = header.getOrDefault("X-Amz-Credential")
  valid_595152 = validateParameter(valid_595152, JString, required = false,
                                 default = nil)
  if valid_595152 != nil:
    section.add "X-Amz-Credential", valid_595152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595153: Call_GetDescribeEventCategories_595139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595153.validator(path, query, header, formData, body)
  let scheme = call_595153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595153.url(scheme.get, call_595153.host, call_595153.base,
                         call_595153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595153, url, valid)

proc call*(call_595154: Call_GetDescribeEventCategories_595139;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2013-09-09"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595155 = newJObject()
  add(query_595155, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_595155.add "Filters", Filters
  add(query_595155, "Action", newJString(Action))
  add(query_595155, "Version", newJString(Version))
  result = call_595154.call(nil, query_595155, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_595139(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_595140, base: "/",
    url: url_GetDescribeEventCategories_595141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_595193 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEventSubscriptions_595195(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_595194(path: JsonNode;
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
  var valid_595196 = query.getOrDefault("Action")
  valid_595196 = validateParameter(valid_595196, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_595196 != nil:
    section.add "Action", valid_595196
  var valid_595197 = query.getOrDefault("Version")
  valid_595197 = validateParameter(valid_595197, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595197 != nil:
    section.add "Version", valid_595197
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
  var valid_595198 = header.getOrDefault("X-Amz-Date")
  valid_595198 = validateParameter(valid_595198, JString, required = false,
                                 default = nil)
  if valid_595198 != nil:
    section.add "X-Amz-Date", valid_595198
  var valid_595199 = header.getOrDefault("X-Amz-Security-Token")
  valid_595199 = validateParameter(valid_595199, JString, required = false,
                                 default = nil)
  if valid_595199 != nil:
    section.add "X-Amz-Security-Token", valid_595199
  var valid_595200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595200 = validateParameter(valid_595200, JString, required = false,
                                 default = nil)
  if valid_595200 != nil:
    section.add "X-Amz-Content-Sha256", valid_595200
  var valid_595201 = header.getOrDefault("X-Amz-Algorithm")
  valid_595201 = validateParameter(valid_595201, JString, required = false,
                                 default = nil)
  if valid_595201 != nil:
    section.add "X-Amz-Algorithm", valid_595201
  var valid_595202 = header.getOrDefault("X-Amz-Signature")
  valid_595202 = validateParameter(valid_595202, JString, required = false,
                                 default = nil)
  if valid_595202 != nil:
    section.add "X-Amz-Signature", valid_595202
  var valid_595203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595203 = validateParameter(valid_595203, JString, required = false,
                                 default = nil)
  if valid_595203 != nil:
    section.add "X-Amz-SignedHeaders", valid_595203
  var valid_595204 = header.getOrDefault("X-Amz-Credential")
  valid_595204 = validateParameter(valid_595204, JString, required = false,
                                 default = nil)
  if valid_595204 != nil:
    section.add "X-Amz-Credential", valid_595204
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595205 = formData.getOrDefault("Marker")
  valid_595205 = validateParameter(valid_595205, JString, required = false,
                                 default = nil)
  if valid_595205 != nil:
    section.add "Marker", valid_595205
  var valid_595206 = formData.getOrDefault("SubscriptionName")
  valid_595206 = validateParameter(valid_595206, JString, required = false,
                                 default = nil)
  if valid_595206 != nil:
    section.add "SubscriptionName", valid_595206
  var valid_595207 = formData.getOrDefault("Filters")
  valid_595207 = validateParameter(valid_595207, JArray, required = false,
                                 default = nil)
  if valid_595207 != nil:
    section.add "Filters", valid_595207
  var valid_595208 = formData.getOrDefault("MaxRecords")
  valid_595208 = validateParameter(valid_595208, JInt, required = false, default = nil)
  if valid_595208 != nil:
    section.add "MaxRecords", valid_595208
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595209: Call_PostDescribeEventSubscriptions_595193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595209.validator(path, query, header, formData, body)
  let scheme = call_595209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595209.url(scheme.get, call_595209.host, call_595209.base,
                         call_595209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595209, url, valid)

proc call*(call_595210: Call_PostDescribeEventSubscriptions_595193;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595211 = newJObject()
  var formData_595212 = newJObject()
  add(formData_595212, "Marker", newJString(Marker))
  add(formData_595212, "SubscriptionName", newJString(SubscriptionName))
  add(query_595211, "Action", newJString(Action))
  if Filters != nil:
    formData_595212.add "Filters", Filters
  add(formData_595212, "MaxRecords", newJInt(MaxRecords))
  add(query_595211, "Version", newJString(Version))
  result = call_595210.call(nil, query_595211, nil, formData_595212, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_595193(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_595194, base: "/",
    url: url_PostDescribeEventSubscriptions_595195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_595174 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEventSubscriptions_595176(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_595175(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_595177 = query.getOrDefault("MaxRecords")
  valid_595177 = validateParameter(valid_595177, JInt, required = false, default = nil)
  if valid_595177 != nil:
    section.add "MaxRecords", valid_595177
  var valid_595178 = query.getOrDefault("Filters")
  valid_595178 = validateParameter(valid_595178, JArray, required = false,
                                 default = nil)
  if valid_595178 != nil:
    section.add "Filters", valid_595178
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595179 = query.getOrDefault("Action")
  valid_595179 = validateParameter(valid_595179, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_595179 != nil:
    section.add "Action", valid_595179
  var valid_595180 = query.getOrDefault("Marker")
  valid_595180 = validateParameter(valid_595180, JString, required = false,
                                 default = nil)
  if valid_595180 != nil:
    section.add "Marker", valid_595180
  var valid_595181 = query.getOrDefault("SubscriptionName")
  valid_595181 = validateParameter(valid_595181, JString, required = false,
                                 default = nil)
  if valid_595181 != nil:
    section.add "SubscriptionName", valid_595181
  var valid_595182 = query.getOrDefault("Version")
  valid_595182 = validateParameter(valid_595182, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595182 != nil:
    section.add "Version", valid_595182
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
  var valid_595183 = header.getOrDefault("X-Amz-Date")
  valid_595183 = validateParameter(valid_595183, JString, required = false,
                                 default = nil)
  if valid_595183 != nil:
    section.add "X-Amz-Date", valid_595183
  var valid_595184 = header.getOrDefault("X-Amz-Security-Token")
  valid_595184 = validateParameter(valid_595184, JString, required = false,
                                 default = nil)
  if valid_595184 != nil:
    section.add "X-Amz-Security-Token", valid_595184
  var valid_595185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595185 = validateParameter(valid_595185, JString, required = false,
                                 default = nil)
  if valid_595185 != nil:
    section.add "X-Amz-Content-Sha256", valid_595185
  var valid_595186 = header.getOrDefault("X-Amz-Algorithm")
  valid_595186 = validateParameter(valid_595186, JString, required = false,
                                 default = nil)
  if valid_595186 != nil:
    section.add "X-Amz-Algorithm", valid_595186
  var valid_595187 = header.getOrDefault("X-Amz-Signature")
  valid_595187 = validateParameter(valid_595187, JString, required = false,
                                 default = nil)
  if valid_595187 != nil:
    section.add "X-Amz-Signature", valid_595187
  var valid_595188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595188 = validateParameter(valid_595188, JString, required = false,
                                 default = nil)
  if valid_595188 != nil:
    section.add "X-Amz-SignedHeaders", valid_595188
  var valid_595189 = header.getOrDefault("X-Amz-Credential")
  valid_595189 = validateParameter(valid_595189, JString, required = false,
                                 default = nil)
  if valid_595189 != nil:
    section.add "X-Amz-Credential", valid_595189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595190: Call_GetDescribeEventSubscriptions_595174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595190.validator(path, query, header, formData, body)
  let scheme = call_595190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595190.url(scheme.get, call_595190.host, call_595190.base,
                         call_595190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595190, url, valid)

proc call*(call_595191: Call_GetDescribeEventSubscriptions_595174;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeEventSubscriptions"; Marker: string = "";
          SubscriptionName: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_595192 = newJObject()
  add(query_595192, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595192.add "Filters", Filters
  add(query_595192, "Action", newJString(Action))
  add(query_595192, "Marker", newJString(Marker))
  add(query_595192, "SubscriptionName", newJString(SubscriptionName))
  add(query_595192, "Version", newJString(Version))
  result = call_595191.call(nil, query_595192, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_595174(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_595175, base: "/",
    url: url_GetDescribeEventSubscriptions_595176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_595237 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEvents_595239(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_595238(path: JsonNode; query: JsonNode;
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
  var valid_595240 = query.getOrDefault("Action")
  valid_595240 = validateParameter(valid_595240, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_595240 != nil:
    section.add "Action", valid_595240
  var valid_595241 = query.getOrDefault("Version")
  valid_595241 = validateParameter(valid_595241, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595241 != nil:
    section.add "Version", valid_595241
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
  var valid_595242 = header.getOrDefault("X-Amz-Date")
  valid_595242 = validateParameter(valid_595242, JString, required = false,
                                 default = nil)
  if valid_595242 != nil:
    section.add "X-Amz-Date", valid_595242
  var valid_595243 = header.getOrDefault("X-Amz-Security-Token")
  valid_595243 = validateParameter(valid_595243, JString, required = false,
                                 default = nil)
  if valid_595243 != nil:
    section.add "X-Amz-Security-Token", valid_595243
  var valid_595244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595244 = validateParameter(valid_595244, JString, required = false,
                                 default = nil)
  if valid_595244 != nil:
    section.add "X-Amz-Content-Sha256", valid_595244
  var valid_595245 = header.getOrDefault("X-Amz-Algorithm")
  valid_595245 = validateParameter(valid_595245, JString, required = false,
                                 default = nil)
  if valid_595245 != nil:
    section.add "X-Amz-Algorithm", valid_595245
  var valid_595246 = header.getOrDefault("X-Amz-Signature")
  valid_595246 = validateParameter(valid_595246, JString, required = false,
                                 default = nil)
  if valid_595246 != nil:
    section.add "X-Amz-Signature", valid_595246
  var valid_595247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595247 = validateParameter(valid_595247, JString, required = false,
                                 default = nil)
  if valid_595247 != nil:
    section.add "X-Amz-SignedHeaders", valid_595247
  var valid_595248 = header.getOrDefault("X-Amz-Credential")
  valid_595248 = validateParameter(valid_595248, JString, required = false,
                                 default = nil)
  if valid_595248 != nil:
    section.add "X-Amz-Credential", valid_595248
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString
  ##   EventCategories: JArray
  ##   Marker: JString
  ##   StartTime: JString
  ##   Duration: JInt
  ##   Filters: JArray
  ##   EndTime: JString
  ##   MaxRecords: JInt
  ##   SourceType: JString
  section = newJObject()
  var valid_595249 = formData.getOrDefault("SourceIdentifier")
  valid_595249 = validateParameter(valid_595249, JString, required = false,
                                 default = nil)
  if valid_595249 != nil:
    section.add "SourceIdentifier", valid_595249
  var valid_595250 = formData.getOrDefault("EventCategories")
  valid_595250 = validateParameter(valid_595250, JArray, required = false,
                                 default = nil)
  if valid_595250 != nil:
    section.add "EventCategories", valid_595250
  var valid_595251 = formData.getOrDefault("Marker")
  valid_595251 = validateParameter(valid_595251, JString, required = false,
                                 default = nil)
  if valid_595251 != nil:
    section.add "Marker", valid_595251
  var valid_595252 = formData.getOrDefault("StartTime")
  valid_595252 = validateParameter(valid_595252, JString, required = false,
                                 default = nil)
  if valid_595252 != nil:
    section.add "StartTime", valid_595252
  var valid_595253 = formData.getOrDefault("Duration")
  valid_595253 = validateParameter(valid_595253, JInt, required = false, default = nil)
  if valid_595253 != nil:
    section.add "Duration", valid_595253
  var valid_595254 = formData.getOrDefault("Filters")
  valid_595254 = validateParameter(valid_595254, JArray, required = false,
                                 default = nil)
  if valid_595254 != nil:
    section.add "Filters", valid_595254
  var valid_595255 = formData.getOrDefault("EndTime")
  valid_595255 = validateParameter(valid_595255, JString, required = false,
                                 default = nil)
  if valid_595255 != nil:
    section.add "EndTime", valid_595255
  var valid_595256 = formData.getOrDefault("MaxRecords")
  valid_595256 = validateParameter(valid_595256, JInt, required = false, default = nil)
  if valid_595256 != nil:
    section.add "MaxRecords", valid_595256
  var valid_595257 = formData.getOrDefault("SourceType")
  valid_595257 = validateParameter(valid_595257, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_595257 != nil:
    section.add "SourceType", valid_595257
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595258: Call_PostDescribeEvents_595237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595258.validator(path, query, header, formData, body)
  let scheme = call_595258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595258.url(scheme.get, call_595258.host, call_595258.base,
                         call_595258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595258, url, valid)

proc call*(call_595259: Call_PostDescribeEvents_595237;
          SourceIdentifier: string = ""; EventCategories: JsonNode = nil;
          Marker: string = ""; StartTime: string = "";
          Action: string = "DescribeEvents"; Duration: int = 0; Filters: JsonNode = nil;
          EndTime: string = ""; MaxRecords: int = 0; Version: string = "2013-09-09";
          SourceType: string = "db-instance"): Recallable =
  ## postDescribeEvents
  ##   SourceIdentifier: string
  ##   EventCategories: JArray
  ##   Marker: string
  ##   StartTime: string
  ##   Action: string (required)
  ##   Duration: int
  ##   Filters: JArray
  ##   EndTime: string
  ##   MaxRecords: int
  ##   Version: string (required)
  ##   SourceType: string
  var query_595260 = newJObject()
  var formData_595261 = newJObject()
  add(formData_595261, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_595261.add "EventCategories", EventCategories
  add(formData_595261, "Marker", newJString(Marker))
  add(formData_595261, "StartTime", newJString(StartTime))
  add(query_595260, "Action", newJString(Action))
  add(formData_595261, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_595261.add "Filters", Filters
  add(formData_595261, "EndTime", newJString(EndTime))
  add(formData_595261, "MaxRecords", newJInt(MaxRecords))
  add(query_595260, "Version", newJString(Version))
  add(formData_595261, "SourceType", newJString(SourceType))
  result = call_595259.call(nil, query_595260, nil, formData_595261, nil)

var postDescribeEvents* = Call_PostDescribeEvents_595237(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_595238, base: "/",
    url: url_PostDescribeEvents_595239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_595213 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEvents_595215(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_595214(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   MaxRecords: JInt
  ##   StartTime: JString
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   SourceIdentifier: JString
  ##   Marker: JString
  ##   EventCategories: JArray
  ##   Duration: JInt
  ##   EndTime: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_595216 = query.getOrDefault("SourceType")
  valid_595216 = validateParameter(valid_595216, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_595216 != nil:
    section.add "SourceType", valid_595216
  var valid_595217 = query.getOrDefault("MaxRecords")
  valid_595217 = validateParameter(valid_595217, JInt, required = false, default = nil)
  if valid_595217 != nil:
    section.add "MaxRecords", valid_595217
  var valid_595218 = query.getOrDefault("StartTime")
  valid_595218 = validateParameter(valid_595218, JString, required = false,
                                 default = nil)
  if valid_595218 != nil:
    section.add "StartTime", valid_595218
  var valid_595219 = query.getOrDefault("Filters")
  valid_595219 = validateParameter(valid_595219, JArray, required = false,
                                 default = nil)
  if valid_595219 != nil:
    section.add "Filters", valid_595219
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595220 = query.getOrDefault("Action")
  valid_595220 = validateParameter(valid_595220, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_595220 != nil:
    section.add "Action", valid_595220
  var valid_595221 = query.getOrDefault("SourceIdentifier")
  valid_595221 = validateParameter(valid_595221, JString, required = false,
                                 default = nil)
  if valid_595221 != nil:
    section.add "SourceIdentifier", valid_595221
  var valid_595222 = query.getOrDefault("Marker")
  valid_595222 = validateParameter(valid_595222, JString, required = false,
                                 default = nil)
  if valid_595222 != nil:
    section.add "Marker", valid_595222
  var valid_595223 = query.getOrDefault("EventCategories")
  valid_595223 = validateParameter(valid_595223, JArray, required = false,
                                 default = nil)
  if valid_595223 != nil:
    section.add "EventCategories", valid_595223
  var valid_595224 = query.getOrDefault("Duration")
  valid_595224 = validateParameter(valid_595224, JInt, required = false, default = nil)
  if valid_595224 != nil:
    section.add "Duration", valid_595224
  var valid_595225 = query.getOrDefault("EndTime")
  valid_595225 = validateParameter(valid_595225, JString, required = false,
                                 default = nil)
  if valid_595225 != nil:
    section.add "EndTime", valid_595225
  var valid_595226 = query.getOrDefault("Version")
  valid_595226 = validateParameter(valid_595226, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595226 != nil:
    section.add "Version", valid_595226
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
  var valid_595227 = header.getOrDefault("X-Amz-Date")
  valid_595227 = validateParameter(valid_595227, JString, required = false,
                                 default = nil)
  if valid_595227 != nil:
    section.add "X-Amz-Date", valid_595227
  var valid_595228 = header.getOrDefault("X-Amz-Security-Token")
  valid_595228 = validateParameter(valid_595228, JString, required = false,
                                 default = nil)
  if valid_595228 != nil:
    section.add "X-Amz-Security-Token", valid_595228
  var valid_595229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595229 = validateParameter(valid_595229, JString, required = false,
                                 default = nil)
  if valid_595229 != nil:
    section.add "X-Amz-Content-Sha256", valid_595229
  var valid_595230 = header.getOrDefault("X-Amz-Algorithm")
  valid_595230 = validateParameter(valid_595230, JString, required = false,
                                 default = nil)
  if valid_595230 != nil:
    section.add "X-Amz-Algorithm", valid_595230
  var valid_595231 = header.getOrDefault("X-Amz-Signature")
  valid_595231 = validateParameter(valid_595231, JString, required = false,
                                 default = nil)
  if valid_595231 != nil:
    section.add "X-Amz-Signature", valid_595231
  var valid_595232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595232 = validateParameter(valid_595232, JString, required = false,
                                 default = nil)
  if valid_595232 != nil:
    section.add "X-Amz-SignedHeaders", valid_595232
  var valid_595233 = header.getOrDefault("X-Amz-Credential")
  valid_595233 = validateParameter(valid_595233, JString, required = false,
                                 default = nil)
  if valid_595233 != nil:
    section.add "X-Amz-Credential", valid_595233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595234: Call_GetDescribeEvents_595213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595234.validator(path, query, header, formData, body)
  let scheme = call_595234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595234.url(scheme.get, call_595234.host, call_595234.base,
                         call_595234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595234, url, valid)

proc call*(call_595235: Call_GetDescribeEvents_595213;
          SourceType: string = "db-instance"; MaxRecords: int = 0;
          StartTime: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEvents"; SourceIdentifier: string = "";
          Marker: string = ""; EventCategories: JsonNode = nil; Duration: int = 0;
          EndTime: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getDescribeEvents
  ##   SourceType: string
  ##   MaxRecords: int
  ##   StartTime: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   SourceIdentifier: string
  ##   Marker: string
  ##   EventCategories: JArray
  ##   Duration: int
  ##   EndTime: string
  ##   Version: string (required)
  var query_595236 = newJObject()
  add(query_595236, "SourceType", newJString(SourceType))
  add(query_595236, "MaxRecords", newJInt(MaxRecords))
  add(query_595236, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_595236.add "Filters", Filters
  add(query_595236, "Action", newJString(Action))
  add(query_595236, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_595236, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_595236.add "EventCategories", EventCategories
  add(query_595236, "Duration", newJInt(Duration))
  add(query_595236, "EndTime", newJString(EndTime))
  add(query_595236, "Version", newJString(Version))
  result = call_595235.call(nil, query_595236, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_595213(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_595214,
    base: "/", url: url_GetDescribeEvents_595215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_595282 = ref object of OpenApiRestCall_593421
proc url_PostDescribeOptionGroupOptions_595284(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_595283(path: JsonNode;
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
  var valid_595285 = query.getOrDefault("Action")
  valid_595285 = validateParameter(valid_595285, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_595285 != nil:
    section.add "Action", valid_595285
  var valid_595286 = query.getOrDefault("Version")
  valid_595286 = validateParameter(valid_595286, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595286 != nil:
    section.add "Version", valid_595286
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
  var valid_595287 = header.getOrDefault("X-Amz-Date")
  valid_595287 = validateParameter(valid_595287, JString, required = false,
                                 default = nil)
  if valid_595287 != nil:
    section.add "X-Amz-Date", valid_595287
  var valid_595288 = header.getOrDefault("X-Amz-Security-Token")
  valid_595288 = validateParameter(valid_595288, JString, required = false,
                                 default = nil)
  if valid_595288 != nil:
    section.add "X-Amz-Security-Token", valid_595288
  var valid_595289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595289 = validateParameter(valid_595289, JString, required = false,
                                 default = nil)
  if valid_595289 != nil:
    section.add "X-Amz-Content-Sha256", valid_595289
  var valid_595290 = header.getOrDefault("X-Amz-Algorithm")
  valid_595290 = validateParameter(valid_595290, JString, required = false,
                                 default = nil)
  if valid_595290 != nil:
    section.add "X-Amz-Algorithm", valid_595290
  var valid_595291 = header.getOrDefault("X-Amz-Signature")
  valid_595291 = validateParameter(valid_595291, JString, required = false,
                                 default = nil)
  if valid_595291 != nil:
    section.add "X-Amz-Signature", valid_595291
  var valid_595292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595292 = validateParameter(valid_595292, JString, required = false,
                                 default = nil)
  if valid_595292 != nil:
    section.add "X-Amz-SignedHeaders", valid_595292
  var valid_595293 = header.getOrDefault("X-Amz-Credential")
  valid_595293 = validateParameter(valid_595293, JString, required = false,
                                 default = nil)
  if valid_595293 != nil:
    section.add "X-Amz-Credential", valid_595293
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595294 = formData.getOrDefault("MajorEngineVersion")
  valid_595294 = validateParameter(valid_595294, JString, required = false,
                                 default = nil)
  if valid_595294 != nil:
    section.add "MajorEngineVersion", valid_595294
  var valid_595295 = formData.getOrDefault("Marker")
  valid_595295 = validateParameter(valid_595295, JString, required = false,
                                 default = nil)
  if valid_595295 != nil:
    section.add "Marker", valid_595295
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_595296 = formData.getOrDefault("EngineName")
  valid_595296 = validateParameter(valid_595296, JString, required = true,
                                 default = nil)
  if valid_595296 != nil:
    section.add "EngineName", valid_595296
  var valid_595297 = formData.getOrDefault("Filters")
  valid_595297 = validateParameter(valid_595297, JArray, required = false,
                                 default = nil)
  if valid_595297 != nil:
    section.add "Filters", valid_595297
  var valid_595298 = formData.getOrDefault("MaxRecords")
  valid_595298 = validateParameter(valid_595298, JInt, required = false, default = nil)
  if valid_595298 != nil:
    section.add "MaxRecords", valid_595298
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595299: Call_PostDescribeOptionGroupOptions_595282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595299.validator(path, query, header, formData, body)
  let scheme = call_595299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595299.url(scheme.get, call_595299.host, call_595299.base,
                         call_595299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595299, url, valid)

proc call*(call_595300: Call_PostDescribeOptionGroupOptions_595282;
          EngineName: string; MajorEngineVersion: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MajorEngineVersion: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595301 = newJObject()
  var formData_595302 = newJObject()
  add(formData_595302, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_595302, "Marker", newJString(Marker))
  add(query_595301, "Action", newJString(Action))
  add(formData_595302, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_595302.add "Filters", Filters
  add(formData_595302, "MaxRecords", newJInt(MaxRecords))
  add(query_595301, "Version", newJString(Version))
  result = call_595300.call(nil, query_595301, nil, formData_595302, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_595282(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_595283, base: "/",
    url: url_PostDescribeOptionGroupOptions_595284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_595262 = ref object of OpenApiRestCall_593421
proc url_GetDescribeOptionGroupOptions_595264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_595263(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_595265 = query.getOrDefault("MaxRecords")
  valid_595265 = validateParameter(valid_595265, JInt, required = false, default = nil)
  if valid_595265 != nil:
    section.add "MaxRecords", valid_595265
  var valid_595266 = query.getOrDefault("Filters")
  valid_595266 = validateParameter(valid_595266, JArray, required = false,
                                 default = nil)
  if valid_595266 != nil:
    section.add "Filters", valid_595266
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595267 = query.getOrDefault("Action")
  valid_595267 = validateParameter(valid_595267, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_595267 != nil:
    section.add "Action", valid_595267
  var valid_595268 = query.getOrDefault("Marker")
  valid_595268 = validateParameter(valid_595268, JString, required = false,
                                 default = nil)
  if valid_595268 != nil:
    section.add "Marker", valid_595268
  var valid_595269 = query.getOrDefault("Version")
  valid_595269 = validateParameter(valid_595269, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595269 != nil:
    section.add "Version", valid_595269
  var valid_595270 = query.getOrDefault("EngineName")
  valid_595270 = validateParameter(valid_595270, JString, required = true,
                                 default = nil)
  if valid_595270 != nil:
    section.add "EngineName", valid_595270
  var valid_595271 = query.getOrDefault("MajorEngineVersion")
  valid_595271 = validateParameter(valid_595271, JString, required = false,
                                 default = nil)
  if valid_595271 != nil:
    section.add "MajorEngineVersion", valid_595271
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
  var valid_595272 = header.getOrDefault("X-Amz-Date")
  valid_595272 = validateParameter(valid_595272, JString, required = false,
                                 default = nil)
  if valid_595272 != nil:
    section.add "X-Amz-Date", valid_595272
  var valid_595273 = header.getOrDefault("X-Amz-Security-Token")
  valid_595273 = validateParameter(valid_595273, JString, required = false,
                                 default = nil)
  if valid_595273 != nil:
    section.add "X-Amz-Security-Token", valid_595273
  var valid_595274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595274 = validateParameter(valid_595274, JString, required = false,
                                 default = nil)
  if valid_595274 != nil:
    section.add "X-Amz-Content-Sha256", valid_595274
  var valid_595275 = header.getOrDefault("X-Amz-Algorithm")
  valid_595275 = validateParameter(valid_595275, JString, required = false,
                                 default = nil)
  if valid_595275 != nil:
    section.add "X-Amz-Algorithm", valid_595275
  var valid_595276 = header.getOrDefault("X-Amz-Signature")
  valid_595276 = validateParameter(valid_595276, JString, required = false,
                                 default = nil)
  if valid_595276 != nil:
    section.add "X-Amz-Signature", valid_595276
  var valid_595277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595277 = validateParameter(valid_595277, JString, required = false,
                                 default = nil)
  if valid_595277 != nil:
    section.add "X-Amz-SignedHeaders", valid_595277
  var valid_595278 = header.getOrDefault("X-Amz-Credential")
  valid_595278 = validateParameter(valid_595278, JString, required = false,
                                 default = nil)
  if valid_595278 != nil:
    section.add "X-Amz-Credential", valid_595278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595279: Call_GetDescribeOptionGroupOptions_595262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595279.validator(path, query, header, formData, body)
  let scheme = call_595279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595279.url(scheme.get, call_595279.host, call_595279.base,
                         call_595279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595279, url, valid)

proc call*(call_595280: Call_GetDescribeOptionGroupOptions_595262;
          EngineName: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeOptionGroupOptions"; Marker: string = "";
          Version: string = "2013-09-09"; MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  var query_595281 = newJObject()
  add(query_595281, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595281.add "Filters", Filters
  add(query_595281, "Action", newJString(Action))
  add(query_595281, "Marker", newJString(Marker))
  add(query_595281, "Version", newJString(Version))
  add(query_595281, "EngineName", newJString(EngineName))
  add(query_595281, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_595280.call(nil, query_595281, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_595262(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_595263, base: "/",
    url: url_GetDescribeOptionGroupOptions_595264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_595324 = ref object of OpenApiRestCall_593421
proc url_PostDescribeOptionGroups_595326(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_595325(path: JsonNode; query: JsonNode;
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
  var valid_595327 = query.getOrDefault("Action")
  valid_595327 = validateParameter(valid_595327, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_595327 != nil:
    section.add "Action", valid_595327
  var valid_595328 = query.getOrDefault("Version")
  valid_595328 = validateParameter(valid_595328, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595328 != nil:
    section.add "Version", valid_595328
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
  var valid_595329 = header.getOrDefault("X-Amz-Date")
  valid_595329 = validateParameter(valid_595329, JString, required = false,
                                 default = nil)
  if valid_595329 != nil:
    section.add "X-Amz-Date", valid_595329
  var valid_595330 = header.getOrDefault("X-Amz-Security-Token")
  valid_595330 = validateParameter(valid_595330, JString, required = false,
                                 default = nil)
  if valid_595330 != nil:
    section.add "X-Amz-Security-Token", valid_595330
  var valid_595331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595331 = validateParameter(valid_595331, JString, required = false,
                                 default = nil)
  if valid_595331 != nil:
    section.add "X-Amz-Content-Sha256", valid_595331
  var valid_595332 = header.getOrDefault("X-Amz-Algorithm")
  valid_595332 = validateParameter(valid_595332, JString, required = false,
                                 default = nil)
  if valid_595332 != nil:
    section.add "X-Amz-Algorithm", valid_595332
  var valid_595333 = header.getOrDefault("X-Amz-Signature")
  valid_595333 = validateParameter(valid_595333, JString, required = false,
                                 default = nil)
  if valid_595333 != nil:
    section.add "X-Amz-Signature", valid_595333
  var valid_595334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595334 = validateParameter(valid_595334, JString, required = false,
                                 default = nil)
  if valid_595334 != nil:
    section.add "X-Amz-SignedHeaders", valid_595334
  var valid_595335 = header.getOrDefault("X-Amz-Credential")
  valid_595335 = validateParameter(valid_595335, JString, required = false,
                                 default = nil)
  if valid_595335 != nil:
    section.add "X-Amz-Credential", valid_595335
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595336 = formData.getOrDefault("MajorEngineVersion")
  valid_595336 = validateParameter(valid_595336, JString, required = false,
                                 default = nil)
  if valid_595336 != nil:
    section.add "MajorEngineVersion", valid_595336
  var valid_595337 = formData.getOrDefault("OptionGroupName")
  valid_595337 = validateParameter(valid_595337, JString, required = false,
                                 default = nil)
  if valid_595337 != nil:
    section.add "OptionGroupName", valid_595337
  var valid_595338 = formData.getOrDefault("Marker")
  valid_595338 = validateParameter(valid_595338, JString, required = false,
                                 default = nil)
  if valid_595338 != nil:
    section.add "Marker", valid_595338
  var valid_595339 = formData.getOrDefault("EngineName")
  valid_595339 = validateParameter(valid_595339, JString, required = false,
                                 default = nil)
  if valid_595339 != nil:
    section.add "EngineName", valid_595339
  var valid_595340 = formData.getOrDefault("Filters")
  valid_595340 = validateParameter(valid_595340, JArray, required = false,
                                 default = nil)
  if valid_595340 != nil:
    section.add "Filters", valid_595340
  var valid_595341 = formData.getOrDefault("MaxRecords")
  valid_595341 = validateParameter(valid_595341, JInt, required = false, default = nil)
  if valid_595341 != nil:
    section.add "MaxRecords", valid_595341
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595342: Call_PostDescribeOptionGroups_595324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595342.validator(path, query, header, formData, body)
  let scheme = call_595342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595342.url(scheme.get, call_595342.host, call_595342.base,
                         call_595342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595342, url, valid)

proc call*(call_595343: Call_PostDescribeOptionGroups_595324;
          MajorEngineVersion: string = ""; OptionGroupName: string = "";
          Marker: string = ""; Action: string = "DescribeOptionGroups";
          EngineName: string = ""; Filters: JsonNode = nil; MaxRecords: int = 0;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeOptionGroups
  ##   MajorEngineVersion: string
  ##   OptionGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595344 = newJObject()
  var formData_595345 = newJObject()
  add(formData_595345, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_595345, "OptionGroupName", newJString(OptionGroupName))
  add(formData_595345, "Marker", newJString(Marker))
  add(query_595344, "Action", newJString(Action))
  add(formData_595345, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_595345.add "Filters", Filters
  add(formData_595345, "MaxRecords", newJInt(MaxRecords))
  add(query_595344, "Version", newJString(Version))
  result = call_595343.call(nil, query_595344, nil, formData_595345, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_595324(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_595325, base: "/",
    url: url_PostDescribeOptionGroups_595326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_595303 = ref object of OpenApiRestCall_593421
proc url_GetDescribeOptionGroups_595305(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_595304(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   OptionGroupName: JString
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_595306 = query.getOrDefault("MaxRecords")
  valid_595306 = validateParameter(valid_595306, JInt, required = false, default = nil)
  if valid_595306 != nil:
    section.add "MaxRecords", valid_595306
  var valid_595307 = query.getOrDefault("OptionGroupName")
  valid_595307 = validateParameter(valid_595307, JString, required = false,
                                 default = nil)
  if valid_595307 != nil:
    section.add "OptionGroupName", valid_595307
  var valid_595308 = query.getOrDefault("Filters")
  valid_595308 = validateParameter(valid_595308, JArray, required = false,
                                 default = nil)
  if valid_595308 != nil:
    section.add "Filters", valid_595308
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595309 = query.getOrDefault("Action")
  valid_595309 = validateParameter(valid_595309, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_595309 != nil:
    section.add "Action", valid_595309
  var valid_595310 = query.getOrDefault("Marker")
  valid_595310 = validateParameter(valid_595310, JString, required = false,
                                 default = nil)
  if valid_595310 != nil:
    section.add "Marker", valid_595310
  var valid_595311 = query.getOrDefault("Version")
  valid_595311 = validateParameter(valid_595311, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595311 != nil:
    section.add "Version", valid_595311
  var valid_595312 = query.getOrDefault("EngineName")
  valid_595312 = validateParameter(valid_595312, JString, required = false,
                                 default = nil)
  if valid_595312 != nil:
    section.add "EngineName", valid_595312
  var valid_595313 = query.getOrDefault("MajorEngineVersion")
  valid_595313 = validateParameter(valid_595313, JString, required = false,
                                 default = nil)
  if valid_595313 != nil:
    section.add "MajorEngineVersion", valid_595313
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
  var valid_595314 = header.getOrDefault("X-Amz-Date")
  valid_595314 = validateParameter(valid_595314, JString, required = false,
                                 default = nil)
  if valid_595314 != nil:
    section.add "X-Amz-Date", valid_595314
  var valid_595315 = header.getOrDefault("X-Amz-Security-Token")
  valid_595315 = validateParameter(valid_595315, JString, required = false,
                                 default = nil)
  if valid_595315 != nil:
    section.add "X-Amz-Security-Token", valid_595315
  var valid_595316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595316 = validateParameter(valid_595316, JString, required = false,
                                 default = nil)
  if valid_595316 != nil:
    section.add "X-Amz-Content-Sha256", valid_595316
  var valid_595317 = header.getOrDefault("X-Amz-Algorithm")
  valid_595317 = validateParameter(valid_595317, JString, required = false,
                                 default = nil)
  if valid_595317 != nil:
    section.add "X-Amz-Algorithm", valid_595317
  var valid_595318 = header.getOrDefault("X-Amz-Signature")
  valid_595318 = validateParameter(valid_595318, JString, required = false,
                                 default = nil)
  if valid_595318 != nil:
    section.add "X-Amz-Signature", valid_595318
  var valid_595319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595319 = validateParameter(valid_595319, JString, required = false,
                                 default = nil)
  if valid_595319 != nil:
    section.add "X-Amz-SignedHeaders", valid_595319
  var valid_595320 = header.getOrDefault("X-Amz-Credential")
  valid_595320 = validateParameter(valid_595320, JString, required = false,
                                 default = nil)
  if valid_595320 != nil:
    section.add "X-Amz-Credential", valid_595320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595321: Call_GetDescribeOptionGroups_595303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595321.validator(path, query, header, formData, body)
  let scheme = call_595321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595321.url(scheme.get, call_595321.host, call_595321.base,
                         call_595321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595321, url, valid)

proc call*(call_595322: Call_GetDescribeOptionGroups_595303; MaxRecords: int = 0;
          OptionGroupName: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeOptionGroups"; Marker: string = "";
          Version: string = "2013-09-09"; EngineName: string = "";
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   MaxRecords: int
  ##   OptionGroupName: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string
  ##   MajorEngineVersion: string
  var query_595323 = newJObject()
  add(query_595323, "MaxRecords", newJInt(MaxRecords))
  add(query_595323, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_595323.add "Filters", Filters
  add(query_595323, "Action", newJString(Action))
  add(query_595323, "Marker", newJString(Marker))
  add(query_595323, "Version", newJString(Version))
  add(query_595323, "EngineName", newJString(EngineName))
  add(query_595323, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_595322.call(nil, query_595323, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_595303(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_595304, base: "/",
    url: url_GetDescribeOptionGroups_595305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_595369 = ref object of OpenApiRestCall_593421
proc url_PostDescribeOrderableDBInstanceOptions_595371(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_595370(path: JsonNode;
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
  var valid_595372 = query.getOrDefault("Action")
  valid_595372 = validateParameter(valid_595372, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_595372 != nil:
    section.add "Action", valid_595372
  var valid_595373 = query.getOrDefault("Version")
  valid_595373 = validateParameter(valid_595373, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595373 != nil:
    section.add "Version", valid_595373
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
  var valid_595374 = header.getOrDefault("X-Amz-Date")
  valid_595374 = validateParameter(valid_595374, JString, required = false,
                                 default = nil)
  if valid_595374 != nil:
    section.add "X-Amz-Date", valid_595374
  var valid_595375 = header.getOrDefault("X-Amz-Security-Token")
  valid_595375 = validateParameter(valid_595375, JString, required = false,
                                 default = nil)
  if valid_595375 != nil:
    section.add "X-Amz-Security-Token", valid_595375
  var valid_595376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595376 = validateParameter(valid_595376, JString, required = false,
                                 default = nil)
  if valid_595376 != nil:
    section.add "X-Amz-Content-Sha256", valid_595376
  var valid_595377 = header.getOrDefault("X-Amz-Algorithm")
  valid_595377 = validateParameter(valid_595377, JString, required = false,
                                 default = nil)
  if valid_595377 != nil:
    section.add "X-Amz-Algorithm", valid_595377
  var valid_595378 = header.getOrDefault("X-Amz-Signature")
  valid_595378 = validateParameter(valid_595378, JString, required = false,
                                 default = nil)
  if valid_595378 != nil:
    section.add "X-Amz-Signature", valid_595378
  var valid_595379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595379 = validateParameter(valid_595379, JString, required = false,
                                 default = nil)
  if valid_595379 != nil:
    section.add "X-Amz-SignedHeaders", valid_595379
  var valid_595380 = header.getOrDefault("X-Amz-Credential")
  valid_595380 = validateParameter(valid_595380, JString, required = false,
                                 default = nil)
  if valid_595380 != nil:
    section.add "X-Amz-Credential", valid_595380
  result.add "header", section
  ## parameters in `formData` object:
  ##   Engine: JString (required)
  ##   Marker: JString
  ##   Vpc: JBool
  ##   DBInstanceClass: JString
  ##   Filters: JArray
  ##   LicenseModel: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_595381 = formData.getOrDefault("Engine")
  valid_595381 = validateParameter(valid_595381, JString, required = true,
                                 default = nil)
  if valid_595381 != nil:
    section.add "Engine", valid_595381
  var valid_595382 = formData.getOrDefault("Marker")
  valid_595382 = validateParameter(valid_595382, JString, required = false,
                                 default = nil)
  if valid_595382 != nil:
    section.add "Marker", valid_595382
  var valid_595383 = formData.getOrDefault("Vpc")
  valid_595383 = validateParameter(valid_595383, JBool, required = false, default = nil)
  if valid_595383 != nil:
    section.add "Vpc", valid_595383
  var valid_595384 = formData.getOrDefault("DBInstanceClass")
  valid_595384 = validateParameter(valid_595384, JString, required = false,
                                 default = nil)
  if valid_595384 != nil:
    section.add "DBInstanceClass", valid_595384
  var valid_595385 = formData.getOrDefault("Filters")
  valid_595385 = validateParameter(valid_595385, JArray, required = false,
                                 default = nil)
  if valid_595385 != nil:
    section.add "Filters", valid_595385
  var valid_595386 = formData.getOrDefault("LicenseModel")
  valid_595386 = validateParameter(valid_595386, JString, required = false,
                                 default = nil)
  if valid_595386 != nil:
    section.add "LicenseModel", valid_595386
  var valid_595387 = formData.getOrDefault("MaxRecords")
  valid_595387 = validateParameter(valid_595387, JInt, required = false, default = nil)
  if valid_595387 != nil:
    section.add "MaxRecords", valid_595387
  var valid_595388 = formData.getOrDefault("EngineVersion")
  valid_595388 = validateParameter(valid_595388, JString, required = false,
                                 default = nil)
  if valid_595388 != nil:
    section.add "EngineVersion", valid_595388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595389: Call_PostDescribeOrderableDBInstanceOptions_595369;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595389.validator(path, query, header, formData, body)
  let scheme = call_595389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595389.url(scheme.get, call_595389.host, call_595389.base,
                         call_595389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595389, url, valid)

proc call*(call_595390: Call_PostDescribeOrderableDBInstanceOptions_595369;
          Engine: string; Marker: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions"; Vpc: bool = false;
          DBInstanceClass: string = ""; Filters: JsonNode = nil;
          LicenseModel: string = ""; MaxRecords: int = 0; EngineVersion: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ##   Engine: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Vpc: bool
  ##   DBInstanceClass: string
  ##   Filters: JArray
  ##   LicenseModel: string
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Version: string (required)
  var query_595391 = newJObject()
  var formData_595392 = newJObject()
  add(formData_595392, "Engine", newJString(Engine))
  add(formData_595392, "Marker", newJString(Marker))
  add(query_595391, "Action", newJString(Action))
  add(formData_595392, "Vpc", newJBool(Vpc))
  add(formData_595392, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_595392.add "Filters", Filters
  add(formData_595392, "LicenseModel", newJString(LicenseModel))
  add(formData_595392, "MaxRecords", newJInt(MaxRecords))
  add(formData_595392, "EngineVersion", newJString(EngineVersion))
  add(query_595391, "Version", newJString(Version))
  result = call_595390.call(nil, query_595391, nil, formData_595392, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_595369(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_595370, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_595371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_595346 = ref object of OpenApiRestCall_593421
proc url_GetDescribeOrderableDBInstanceOptions_595348(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_595347(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   LicenseModel: JString
  ##   Vpc: JBool
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   EngineVersion: JString
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_595349 = query.getOrDefault("Engine")
  valid_595349 = validateParameter(valid_595349, JString, required = true,
                                 default = nil)
  if valid_595349 != nil:
    section.add "Engine", valid_595349
  var valid_595350 = query.getOrDefault("MaxRecords")
  valid_595350 = validateParameter(valid_595350, JInt, required = false, default = nil)
  if valid_595350 != nil:
    section.add "MaxRecords", valid_595350
  var valid_595351 = query.getOrDefault("Filters")
  valid_595351 = validateParameter(valid_595351, JArray, required = false,
                                 default = nil)
  if valid_595351 != nil:
    section.add "Filters", valid_595351
  var valid_595352 = query.getOrDefault("LicenseModel")
  valid_595352 = validateParameter(valid_595352, JString, required = false,
                                 default = nil)
  if valid_595352 != nil:
    section.add "LicenseModel", valid_595352
  var valid_595353 = query.getOrDefault("Vpc")
  valid_595353 = validateParameter(valid_595353, JBool, required = false, default = nil)
  if valid_595353 != nil:
    section.add "Vpc", valid_595353
  var valid_595354 = query.getOrDefault("DBInstanceClass")
  valid_595354 = validateParameter(valid_595354, JString, required = false,
                                 default = nil)
  if valid_595354 != nil:
    section.add "DBInstanceClass", valid_595354
  var valid_595355 = query.getOrDefault("Action")
  valid_595355 = validateParameter(valid_595355, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_595355 != nil:
    section.add "Action", valid_595355
  var valid_595356 = query.getOrDefault("Marker")
  valid_595356 = validateParameter(valid_595356, JString, required = false,
                                 default = nil)
  if valid_595356 != nil:
    section.add "Marker", valid_595356
  var valid_595357 = query.getOrDefault("EngineVersion")
  valid_595357 = validateParameter(valid_595357, JString, required = false,
                                 default = nil)
  if valid_595357 != nil:
    section.add "EngineVersion", valid_595357
  var valid_595358 = query.getOrDefault("Version")
  valid_595358 = validateParameter(valid_595358, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595358 != nil:
    section.add "Version", valid_595358
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
  var valid_595359 = header.getOrDefault("X-Amz-Date")
  valid_595359 = validateParameter(valid_595359, JString, required = false,
                                 default = nil)
  if valid_595359 != nil:
    section.add "X-Amz-Date", valid_595359
  var valid_595360 = header.getOrDefault("X-Amz-Security-Token")
  valid_595360 = validateParameter(valid_595360, JString, required = false,
                                 default = nil)
  if valid_595360 != nil:
    section.add "X-Amz-Security-Token", valid_595360
  var valid_595361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595361 = validateParameter(valid_595361, JString, required = false,
                                 default = nil)
  if valid_595361 != nil:
    section.add "X-Amz-Content-Sha256", valid_595361
  var valid_595362 = header.getOrDefault("X-Amz-Algorithm")
  valid_595362 = validateParameter(valid_595362, JString, required = false,
                                 default = nil)
  if valid_595362 != nil:
    section.add "X-Amz-Algorithm", valid_595362
  var valid_595363 = header.getOrDefault("X-Amz-Signature")
  valid_595363 = validateParameter(valid_595363, JString, required = false,
                                 default = nil)
  if valid_595363 != nil:
    section.add "X-Amz-Signature", valid_595363
  var valid_595364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595364 = validateParameter(valid_595364, JString, required = false,
                                 default = nil)
  if valid_595364 != nil:
    section.add "X-Amz-SignedHeaders", valid_595364
  var valid_595365 = header.getOrDefault("X-Amz-Credential")
  valid_595365 = validateParameter(valid_595365, JString, required = false,
                                 default = nil)
  if valid_595365 != nil:
    section.add "X-Amz-Credential", valid_595365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595366: Call_GetDescribeOrderableDBInstanceOptions_595346;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595366.validator(path, query, header, formData, body)
  let scheme = call_595366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595366.url(scheme.get, call_595366.host, call_595366.base,
                         call_595366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595366, url, valid)

proc call*(call_595367: Call_GetDescribeOrderableDBInstanceOptions_595346;
          Engine: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          LicenseModel: string = ""; Vpc: bool = false; DBInstanceClass: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Marker: string = ""; EngineVersion: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ##   Engine: string (required)
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   LicenseModel: string
  ##   Vpc: bool
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   Marker: string
  ##   EngineVersion: string
  ##   Version: string (required)
  var query_595368 = newJObject()
  add(query_595368, "Engine", newJString(Engine))
  add(query_595368, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595368.add "Filters", Filters
  add(query_595368, "LicenseModel", newJString(LicenseModel))
  add(query_595368, "Vpc", newJBool(Vpc))
  add(query_595368, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595368, "Action", newJString(Action))
  add(query_595368, "Marker", newJString(Marker))
  add(query_595368, "EngineVersion", newJString(EngineVersion))
  add(query_595368, "Version", newJString(Version))
  result = call_595367.call(nil, query_595368, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_595346(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_595347, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_595348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_595418 = ref object of OpenApiRestCall_593421
proc url_PostDescribeReservedDBInstances_595420(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_595419(path: JsonNode;
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
  var valid_595421 = query.getOrDefault("Action")
  valid_595421 = validateParameter(valid_595421, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_595421 != nil:
    section.add "Action", valid_595421
  var valid_595422 = query.getOrDefault("Version")
  valid_595422 = validateParameter(valid_595422, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595422 != nil:
    section.add "Version", valid_595422
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
  var valid_595423 = header.getOrDefault("X-Amz-Date")
  valid_595423 = validateParameter(valid_595423, JString, required = false,
                                 default = nil)
  if valid_595423 != nil:
    section.add "X-Amz-Date", valid_595423
  var valid_595424 = header.getOrDefault("X-Amz-Security-Token")
  valid_595424 = validateParameter(valid_595424, JString, required = false,
                                 default = nil)
  if valid_595424 != nil:
    section.add "X-Amz-Security-Token", valid_595424
  var valid_595425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595425 = validateParameter(valid_595425, JString, required = false,
                                 default = nil)
  if valid_595425 != nil:
    section.add "X-Amz-Content-Sha256", valid_595425
  var valid_595426 = header.getOrDefault("X-Amz-Algorithm")
  valid_595426 = validateParameter(valid_595426, JString, required = false,
                                 default = nil)
  if valid_595426 != nil:
    section.add "X-Amz-Algorithm", valid_595426
  var valid_595427 = header.getOrDefault("X-Amz-Signature")
  valid_595427 = validateParameter(valid_595427, JString, required = false,
                                 default = nil)
  if valid_595427 != nil:
    section.add "X-Amz-Signature", valid_595427
  var valid_595428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595428 = validateParameter(valid_595428, JString, required = false,
                                 default = nil)
  if valid_595428 != nil:
    section.add "X-Amz-SignedHeaders", valid_595428
  var valid_595429 = header.getOrDefault("X-Amz-Credential")
  valid_595429 = validateParameter(valid_595429, JString, required = false,
                                 default = nil)
  if valid_595429 != nil:
    section.add "X-Amz-Credential", valid_595429
  result.add "header", section
  ## parameters in `formData` object:
  ##   OfferingType: JString
  ##   ReservedDBInstanceId: JString
  ##   Marker: JString
  ##   MultiAZ: JBool
  ##   Duration: JString
  ##   DBInstanceClass: JString
  ##   Filters: JArray
  ##   ProductDescription: JString
  ##   MaxRecords: JInt
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_595430 = formData.getOrDefault("OfferingType")
  valid_595430 = validateParameter(valid_595430, JString, required = false,
                                 default = nil)
  if valid_595430 != nil:
    section.add "OfferingType", valid_595430
  var valid_595431 = formData.getOrDefault("ReservedDBInstanceId")
  valid_595431 = validateParameter(valid_595431, JString, required = false,
                                 default = nil)
  if valid_595431 != nil:
    section.add "ReservedDBInstanceId", valid_595431
  var valid_595432 = formData.getOrDefault("Marker")
  valid_595432 = validateParameter(valid_595432, JString, required = false,
                                 default = nil)
  if valid_595432 != nil:
    section.add "Marker", valid_595432
  var valid_595433 = formData.getOrDefault("MultiAZ")
  valid_595433 = validateParameter(valid_595433, JBool, required = false, default = nil)
  if valid_595433 != nil:
    section.add "MultiAZ", valid_595433
  var valid_595434 = formData.getOrDefault("Duration")
  valid_595434 = validateParameter(valid_595434, JString, required = false,
                                 default = nil)
  if valid_595434 != nil:
    section.add "Duration", valid_595434
  var valid_595435 = formData.getOrDefault("DBInstanceClass")
  valid_595435 = validateParameter(valid_595435, JString, required = false,
                                 default = nil)
  if valid_595435 != nil:
    section.add "DBInstanceClass", valid_595435
  var valid_595436 = formData.getOrDefault("Filters")
  valid_595436 = validateParameter(valid_595436, JArray, required = false,
                                 default = nil)
  if valid_595436 != nil:
    section.add "Filters", valid_595436
  var valid_595437 = formData.getOrDefault("ProductDescription")
  valid_595437 = validateParameter(valid_595437, JString, required = false,
                                 default = nil)
  if valid_595437 != nil:
    section.add "ProductDescription", valid_595437
  var valid_595438 = formData.getOrDefault("MaxRecords")
  valid_595438 = validateParameter(valid_595438, JInt, required = false, default = nil)
  if valid_595438 != nil:
    section.add "MaxRecords", valid_595438
  var valid_595439 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595439 = validateParameter(valid_595439, JString, required = false,
                                 default = nil)
  if valid_595439 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595439
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595440: Call_PostDescribeReservedDBInstances_595418;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595440.validator(path, query, header, formData, body)
  let scheme = call_595440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595440.url(scheme.get, call_595440.host, call_595440.base,
                         call_595440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595440, url, valid)

proc call*(call_595441: Call_PostDescribeReservedDBInstances_595418;
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstances"; Duration: string = "";
          DBInstanceClass: string = ""; Filters: JsonNode = nil;
          ProductDescription: string = ""; MaxRecords: int = 0;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-09-09"): Recallable =
  ## postDescribeReservedDBInstances
  ##   OfferingType: string
  ##   ReservedDBInstanceId: string
  ##   Marker: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   Duration: string
  ##   DBInstanceClass: string
  ##   Filters: JArray
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_595442 = newJObject()
  var formData_595443 = newJObject()
  add(formData_595443, "OfferingType", newJString(OfferingType))
  add(formData_595443, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_595443, "Marker", newJString(Marker))
  add(formData_595443, "MultiAZ", newJBool(MultiAZ))
  add(query_595442, "Action", newJString(Action))
  add(formData_595443, "Duration", newJString(Duration))
  add(formData_595443, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_595443.add "Filters", Filters
  add(formData_595443, "ProductDescription", newJString(ProductDescription))
  add(formData_595443, "MaxRecords", newJInt(MaxRecords))
  add(formData_595443, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595442, "Version", newJString(Version))
  result = call_595441.call(nil, query_595442, nil, formData_595443, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_595418(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_595419, base: "/",
    url: url_PostDescribeReservedDBInstances_595420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_595393 = ref object of OpenApiRestCall_593421
proc url_GetDescribeReservedDBInstances_595395(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_595394(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ProductDescription: JString
  ##   MaxRecords: JInt
  ##   OfferingType: JString
  ##   Filters: JArray
  ##   MultiAZ: JBool
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Duration: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_595396 = query.getOrDefault("ProductDescription")
  valid_595396 = validateParameter(valid_595396, JString, required = false,
                                 default = nil)
  if valid_595396 != nil:
    section.add "ProductDescription", valid_595396
  var valid_595397 = query.getOrDefault("MaxRecords")
  valid_595397 = validateParameter(valid_595397, JInt, required = false, default = nil)
  if valid_595397 != nil:
    section.add "MaxRecords", valid_595397
  var valid_595398 = query.getOrDefault("OfferingType")
  valid_595398 = validateParameter(valid_595398, JString, required = false,
                                 default = nil)
  if valid_595398 != nil:
    section.add "OfferingType", valid_595398
  var valid_595399 = query.getOrDefault("Filters")
  valid_595399 = validateParameter(valid_595399, JArray, required = false,
                                 default = nil)
  if valid_595399 != nil:
    section.add "Filters", valid_595399
  var valid_595400 = query.getOrDefault("MultiAZ")
  valid_595400 = validateParameter(valid_595400, JBool, required = false, default = nil)
  if valid_595400 != nil:
    section.add "MultiAZ", valid_595400
  var valid_595401 = query.getOrDefault("ReservedDBInstanceId")
  valid_595401 = validateParameter(valid_595401, JString, required = false,
                                 default = nil)
  if valid_595401 != nil:
    section.add "ReservedDBInstanceId", valid_595401
  var valid_595402 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595402 = validateParameter(valid_595402, JString, required = false,
                                 default = nil)
  if valid_595402 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595402
  var valid_595403 = query.getOrDefault("DBInstanceClass")
  valid_595403 = validateParameter(valid_595403, JString, required = false,
                                 default = nil)
  if valid_595403 != nil:
    section.add "DBInstanceClass", valid_595403
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595404 = query.getOrDefault("Action")
  valid_595404 = validateParameter(valid_595404, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_595404 != nil:
    section.add "Action", valid_595404
  var valid_595405 = query.getOrDefault("Marker")
  valid_595405 = validateParameter(valid_595405, JString, required = false,
                                 default = nil)
  if valid_595405 != nil:
    section.add "Marker", valid_595405
  var valid_595406 = query.getOrDefault("Duration")
  valid_595406 = validateParameter(valid_595406, JString, required = false,
                                 default = nil)
  if valid_595406 != nil:
    section.add "Duration", valid_595406
  var valid_595407 = query.getOrDefault("Version")
  valid_595407 = validateParameter(valid_595407, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595407 != nil:
    section.add "Version", valid_595407
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
  var valid_595408 = header.getOrDefault("X-Amz-Date")
  valid_595408 = validateParameter(valid_595408, JString, required = false,
                                 default = nil)
  if valid_595408 != nil:
    section.add "X-Amz-Date", valid_595408
  var valid_595409 = header.getOrDefault("X-Amz-Security-Token")
  valid_595409 = validateParameter(valid_595409, JString, required = false,
                                 default = nil)
  if valid_595409 != nil:
    section.add "X-Amz-Security-Token", valid_595409
  var valid_595410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595410 = validateParameter(valid_595410, JString, required = false,
                                 default = nil)
  if valid_595410 != nil:
    section.add "X-Amz-Content-Sha256", valid_595410
  var valid_595411 = header.getOrDefault("X-Amz-Algorithm")
  valid_595411 = validateParameter(valid_595411, JString, required = false,
                                 default = nil)
  if valid_595411 != nil:
    section.add "X-Amz-Algorithm", valid_595411
  var valid_595412 = header.getOrDefault("X-Amz-Signature")
  valid_595412 = validateParameter(valid_595412, JString, required = false,
                                 default = nil)
  if valid_595412 != nil:
    section.add "X-Amz-Signature", valid_595412
  var valid_595413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595413 = validateParameter(valid_595413, JString, required = false,
                                 default = nil)
  if valid_595413 != nil:
    section.add "X-Amz-SignedHeaders", valid_595413
  var valid_595414 = header.getOrDefault("X-Amz-Credential")
  valid_595414 = validateParameter(valid_595414, JString, required = false,
                                 default = nil)
  if valid_595414 != nil:
    section.add "X-Amz-Credential", valid_595414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595415: Call_GetDescribeReservedDBInstances_595393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595415.validator(path, query, header, formData, body)
  let scheme = call_595415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595415.url(scheme.get, call_595415.host, call_595415.base,
                         call_595415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595415, url, valid)

proc call*(call_595416: Call_GetDescribeReservedDBInstances_595393;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; Filters: JsonNode = nil; MultiAZ: bool = false;
          ReservedDBInstanceId: string = "";
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstances"; Marker: string = "";
          Duration: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getDescribeReservedDBInstances
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   OfferingType: string
  ##   Filters: JArray
  ##   MultiAZ: bool
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Duration: string
  ##   Version: string (required)
  var query_595417 = newJObject()
  add(query_595417, "ProductDescription", newJString(ProductDescription))
  add(query_595417, "MaxRecords", newJInt(MaxRecords))
  add(query_595417, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_595417.add "Filters", Filters
  add(query_595417, "MultiAZ", newJBool(MultiAZ))
  add(query_595417, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_595417, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595417, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595417, "Action", newJString(Action))
  add(query_595417, "Marker", newJString(Marker))
  add(query_595417, "Duration", newJString(Duration))
  add(query_595417, "Version", newJString(Version))
  result = call_595416.call(nil, query_595417, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_595393(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_595394, base: "/",
    url: url_GetDescribeReservedDBInstances_595395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_595468 = ref object of OpenApiRestCall_593421
proc url_PostDescribeReservedDBInstancesOfferings_595470(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_595469(path: JsonNode;
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
  var valid_595471 = query.getOrDefault("Action")
  valid_595471 = validateParameter(valid_595471, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_595471 != nil:
    section.add "Action", valid_595471
  var valid_595472 = query.getOrDefault("Version")
  valid_595472 = validateParameter(valid_595472, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595472 != nil:
    section.add "Version", valid_595472
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
  var valid_595473 = header.getOrDefault("X-Amz-Date")
  valid_595473 = validateParameter(valid_595473, JString, required = false,
                                 default = nil)
  if valid_595473 != nil:
    section.add "X-Amz-Date", valid_595473
  var valid_595474 = header.getOrDefault("X-Amz-Security-Token")
  valid_595474 = validateParameter(valid_595474, JString, required = false,
                                 default = nil)
  if valid_595474 != nil:
    section.add "X-Amz-Security-Token", valid_595474
  var valid_595475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595475 = validateParameter(valid_595475, JString, required = false,
                                 default = nil)
  if valid_595475 != nil:
    section.add "X-Amz-Content-Sha256", valid_595475
  var valid_595476 = header.getOrDefault("X-Amz-Algorithm")
  valid_595476 = validateParameter(valid_595476, JString, required = false,
                                 default = nil)
  if valid_595476 != nil:
    section.add "X-Amz-Algorithm", valid_595476
  var valid_595477 = header.getOrDefault("X-Amz-Signature")
  valid_595477 = validateParameter(valid_595477, JString, required = false,
                                 default = nil)
  if valid_595477 != nil:
    section.add "X-Amz-Signature", valid_595477
  var valid_595478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595478 = validateParameter(valid_595478, JString, required = false,
                                 default = nil)
  if valid_595478 != nil:
    section.add "X-Amz-SignedHeaders", valid_595478
  var valid_595479 = header.getOrDefault("X-Amz-Credential")
  valid_595479 = validateParameter(valid_595479, JString, required = false,
                                 default = nil)
  if valid_595479 != nil:
    section.add "X-Amz-Credential", valid_595479
  result.add "header", section
  ## parameters in `formData` object:
  ##   OfferingType: JString
  ##   Marker: JString
  ##   MultiAZ: JBool
  ##   Duration: JString
  ##   DBInstanceClass: JString
  ##   Filters: JArray
  ##   ProductDescription: JString
  ##   MaxRecords: JInt
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_595480 = formData.getOrDefault("OfferingType")
  valid_595480 = validateParameter(valid_595480, JString, required = false,
                                 default = nil)
  if valid_595480 != nil:
    section.add "OfferingType", valid_595480
  var valid_595481 = formData.getOrDefault("Marker")
  valid_595481 = validateParameter(valid_595481, JString, required = false,
                                 default = nil)
  if valid_595481 != nil:
    section.add "Marker", valid_595481
  var valid_595482 = formData.getOrDefault("MultiAZ")
  valid_595482 = validateParameter(valid_595482, JBool, required = false, default = nil)
  if valid_595482 != nil:
    section.add "MultiAZ", valid_595482
  var valid_595483 = formData.getOrDefault("Duration")
  valid_595483 = validateParameter(valid_595483, JString, required = false,
                                 default = nil)
  if valid_595483 != nil:
    section.add "Duration", valid_595483
  var valid_595484 = formData.getOrDefault("DBInstanceClass")
  valid_595484 = validateParameter(valid_595484, JString, required = false,
                                 default = nil)
  if valid_595484 != nil:
    section.add "DBInstanceClass", valid_595484
  var valid_595485 = formData.getOrDefault("Filters")
  valid_595485 = validateParameter(valid_595485, JArray, required = false,
                                 default = nil)
  if valid_595485 != nil:
    section.add "Filters", valid_595485
  var valid_595486 = formData.getOrDefault("ProductDescription")
  valid_595486 = validateParameter(valid_595486, JString, required = false,
                                 default = nil)
  if valid_595486 != nil:
    section.add "ProductDescription", valid_595486
  var valid_595487 = formData.getOrDefault("MaxRecords")
  valid_595487 = validateParameter(valid_595487, JInt, required = false, default = nil)
  if valid_595487 != nil:
    section.add "MaxRecords", valid_595487
  var valid_595488 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595488 = validateParameter(valid_595488, JString, required = false,
                                 default = nil)
  if valid_595488 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595488
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595489: Call_PostDescribeReservedDBInstancesOfferings_595468;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595489.validator(path, query, header, formData, body)
  let scheme = call_595489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595489.url(scheme.get, call_595489.host, call_595489.base,
                         call_595489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595489, url, valid)

proc call*(call_595490: Call_PostDescribeReservedDBInstancesOfferings_595468;
          OfferingType: string = ""; Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstancesOfferings";
          Duration: string = ""; DBInstanceClass: string = ""; Filters: JsonNode = nil;
          ProductDescription: string = ""; MaxRecords: int = 0;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-09-09"): Recallable =
  ## postDescribeReservedDBInstancesOfferings
  ##   OfferingType: string
  ##   Marker: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   Duration: string
  ##   DBInstanceClass: string
  ##   Filters: JArray
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_595491 = newJObject()
  var formData_595492 = newJObject()
  add(formData_595492, "OfferingType", newJString(OfferingType))
  add(formData_595492, "Marker", newJString(Marker))
  add(formData_595492, "MultiAZ", newJBool(MultiAZ))
  add(query_595491, "Action", newJString(Action))
  add(formData_595492, "Duration", newJString(Duration))
  add(formData_595492, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_595492.add "Filters", Filters
  add(formData_595492, "ProductDescription", newJString(ProductDescription))
  add(formData_595492, "MaxRecords", newJInt(MaxRecords))
  add(formData_595492, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595491, "Version", newJString(Version))
  result = call_595490.call(nil, query_595491, nil, formData_595492, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_595468(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_595469,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_595470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_595444 = ref object of OpenApiRestCall_593421
proc url_GetDescribeReservedDBInstancesOfferings_595446(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_595445(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ProductDescription: JString
  ##   MaxRecords: JInt
  ##   OfferingType: JString
  ##   Filters: JArray
  ##   MultiAZ: JBool
  ##   ReservedDBInstancesOfferingId: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Duration: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_595447 = query.getOrDefault("ProductDescription")
  valid_595447 = validateParameter(valid_595447, JString, required = false,
                                 default = nil)
  if valid_595447 != nil:
    section.add "ProductDescription", valid_595447
  var valid_595448 = query.getOrDefault("MaxRecords")
  valid_595448 = validateParameter(valid_595448, JInt, required = false, default = nil)
  if valid_595448 != nil:
    section.add "MaxRecords", valid_595448
  var valid_595449 = query.getOrDefault("OfferingType")
  valid_595449 = validateParameter(valid_595449, JString, required = false,
                                 default = nil)
  if valid_595449 != nil:
    section.add "OfferingType", valid_595449
  var valid_595450 = query.getOrDefault("Filters")
  valid_595450 = validateParameter(valid_595450, JArray, required = false,
                                 default = nil)
  if valid_595450 != nil:
    section.add "Filters", valid_595450
  var valid_595451 = query.getOrDefault("MultiAZ")
  valid_595451 = validateParameter(valid_595451, JBool, required = false, default = nil)
  if valid_595451 != nil:
    section.add "MultiAZ", valid_595451
  var valid_595452 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595452 = validateParameter(valid_595452, JString, required = false,
                                 default = nil)
  if valid_595452 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595452
  var valid_595453 = query.getOrDefault("DBInstanceClass")
  valid_595453 = validateParameter(valid_595453, JString, required = false,
                                 default = nil)
  if valid_595453 != nil:
    section.add "DBInstanceClass", valid_595453
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595454 = query.getOrDefault("Action")
  valid_595454 = validateParameter(valid_595454, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_595454 != nil:
    section.add "Action", valid_595454
  var valid_595455 = query.getOrDefault("Marker")
  valid_595455 = validateParameter(valid_595455, JString, required = false,
                                 default = nil)
  if valid_595455 != nil:
    section.add "Marker", valid_595455
  var valid_595456 = query.getOrDefault("Duration")
  valid_595456 = validateParameter(valid_595456, JString, required = false,
                                 default = nil)
  if valid_595456 != nil:
    section.add "Duration", valid_595456
  var valid_595457 = query.getOrDefault("Version")
  valid_595457 = validateParameter(valid_595457, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595457 != nil:
    section.add "Version", valid_595457
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
  var valid_595458 = header.getOrDefault("X-Amz-Date")
  valid_595458 = validateParameter(valid_595458, JString, required = false,
                                 default = nil)
  if valid_595458 != nil:
    section.add "X-Amz-Date", valid_595458
  var valid_595459 = header.getOrDefault("X-Amz-Security-Token")
  valid_595459 = validateParameter(valid_595459, JString, required = false,
                                 default = nil)
  if valid_595459 != nil:
    section.add "X-Amz-Security-Token", valid_595459
  var valid_595460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595460 = validateParameter(valid_595460, JString, required = false,
                                 default = nil)
  if valid_595460 != nil:
    section.add "X-Amz-Content-Sha256", valid_595460
  var valid_595461 = header.getOrDefault("X-Amz-Algorithm")
  valid_595461 = validateParameter(valid_595461, JString, required = false,
                                 default = nil)
  if valid_595461 != nil:
    section.add "X-Amz-Algorithm", valid_595461
  var valid_595462 = header.getOrDefault("X-Amz-Signature")
  valid_595462 = validateParameter(valid_595462, JString, required = false,
                                 default = nil)
  if valid_595462 != nil:
    section.add "X-Amz-Signature", valid_595462
  var valid_595463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595463 = validateParameter(valid_595463, JString, required = false,
                                 default = nil)
  if valid_595463 != nil:
    section.add "X-Amz-SignedHeaders", valid_595463
  var valid_595464 = header.getOrDefault("X-Amz-Credential")
  valid_595464 = validateParameter(valid_595464, JString, required = false,
                                 default = nil)
  if valid_595464 != nil:
    section.add "X-Amz-Credential", valid_595464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595465: Call_GetDescribeReservedDBInstancesOfferings_595444;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595465.validator(path, query, header, formData, body)
  let scheme = call_595465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595465.url(scheme.get, call_595465.host, call_595465.base,
                         call_595465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595465, url, valid)

proc call*(call_595466: Call_GetDescribeReservedDBInstancesOfferings_595444;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; Filters: JsonNode = nil; MultiAZ: bool = false;
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          Marker: string = ""; Duration: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getDescribeReservedDBInstancesOfferings
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   OfferingType: string
  ##   Filters: JArray
  ##   MultiAZ: bool
  ##   ReservedDBInstancesOfferingId: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Duration: string
  ##   Version: string (required)
  var query_595467 = newJObject()
  add(query_595467, "ProductDescription", newJString(ProductDescription))
  add(query_595467, "MaxRecords", newJInt(MaxRecords))
  add(query_595467, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_595467.add "Filters", Filters
  add(query_595467, "MultiAZ", newJBool(MultiAZ))
  add(query_595467, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595467, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595467, "Action", newJString(Action))
  add(query_595467, "Marker", newJString(Marker))
  add(query_595467, "Duration", newJString(Duration))
  add(query_595467, "Version", newJString(Version))
  result = call_595466.call(nil, query_595467, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_595444(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_595445, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_595446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_595512 = ref object of OpenApiRestCall_593421
proc url_PostDownloadDBLogFilePortion_595514(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDownloadDBLogFilePortion_595513(path: JsonNode; query: JsonNode;
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
  var valid_595515 = query.getOrDefault("Action")
  valid_595515 = validateParameter(valid_595515, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_595515 != nil:
    section.add "Action", valid_595515
  var valid_595516 = query.getOrDefault("Version")
  valid_595516 = validateParameter(valid_595516, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595516 != nil:
    section.add "Version", valid_595516
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
  var valid_595517 = header.getOrDefault("X-Amz-Date")
  valid_595517 = validateParameter(valid_595517, JString, required = false,
                                 default = nil)
  if valid_595517 != nil:
    section.add "X-Amz-Date", valid_595517
  var valid_595518 = header.getOrDefault("X-Amz-Security-Token")
  valid_595518 = validateParameter(valid_595518, JString, required = false,
                                 default = nil)
  if valid_595518 != nil:
    section.add "X-Amz-Security-Token", valid_595518
  var valid_595519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595519 = validateParameter(valid_595519, JString, required = false,
                                 default = nil)
  if valid_595519 != nil:
    section.add "X-Amz-Content-Sha256", valid_595519
  var valid_595520 = header.getOrDefault("X-Amz-Algorithm")
  valid_595520 = validateParameter(valid_595520, JString, required = false,
                                 default = nil)
  if valid_595520 != nil:
    section.add "X-Amz-Algorithm", valid_595520
  var valid_595521 = header.getOrDefault("X-Amz-Signature")
  valid_595521 = validateParameter(valid_595521, JString, required = false,
                                 default = nil)
  if valid_595521 != nil:
    section.add "X-Amz-Signature", valid_595521
  var valid_595522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595522 = validateParameter(valid_595522, JString, required = false,
                                 default = nil)
  if valid_595522 != nil:
    section.add "X-Amz-SignedHeaders", valid_595522
  var valid_595523 = header.getOrDefault("X-Amz-Credential")
  valid_595523 = validateParameter(valid_595523, JString, required = false,
                                 default = nil)
  if valid_595523 != nil:
    section.add "X-Amz-Credential", valid_595523
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_595524 = formData.getOrDefault("NumberOfLines")
  valid_595524 = validateParameter(valid_595524, JInt, required = false, default = nil)
  if valid_595524 != nil:
    section.add "NumberOfLines", valid_595524
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595525 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595525 = validateParameter(valid_595525, JString, required = true,
                                 default = nil)
  if valid_595525 != nil:
    section.add "DBInstanceIdentifier", valid_595525
  var valid_595526 = formData.getOrDefault("Marker")
  valid_595526 = validateParameter(valid_595526, JString, required = false,
                                 default = nil)
  if valid_595526 != nil:
    section.add "Marker", valid_595526
  var valid_595527 = formData.getOrDefault("LogFileName")
  valid_595527 = validateParameter(valid_595527, JString, required = true,
                                 default = nil)
  if valid_595527 != nil:
    section.add "LogFileName", valid_595527
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595528: Call_PostDownloadDBLogFilePortion_595512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595528.validator(path, query, header, formData, body)
  let scheme = call_595528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595528.url(scheme.get, call_595528.host, call_595528.base,
                         call_595528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595528, url, valid)

proc call*(call_595529: Call_PostDownloadDBLogFilePortion_595512;
          DBInstanceIdentifier: string; LogFileName: string; NumberOfLines: int = 0;
          Marker: string = ""; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2013-09-09"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   DBInstanceIdentifier: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   LogFileName: string (required)
  ##   Version: string (required)
  var query_595530 = newJObject()
  var formData_595531 = newJObject()
  add(formData_595531, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_595531, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595531, "Marker", newJString(Marker))
  add(query_595530, "Action", newJString(Action))
  add(formData_595531, "LogFileName", newJString(LogFileName))
  add(query_595530, "Version", newJString(Version))
  result = call_595529.call(nil, query_595530, nil, formData_595531, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_595512(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_595513, base: "/",
    url: url_PostDownloadDBLogFilePortion_595514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_595493 = ref object of OpenApiRestCall_593421
proc url_GetDownloadDBLogFilePortion_595495(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDownloadDBLogFilePortion_595494(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NumberOfLines: JInt
  ##   LogFileName: JString (required)
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_595496 = query.getOrDefault("NumberOfLines")
  valid_595496 = validateParameter(valid_595496, JInt, required = false, default = nil)
  if valid_595496 != nil:
    section.add "NumberOfLines", valid_595496
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_595497 = query.getOrDefault("LogFileName")
  valid_595497 = validateParameter(valid_595497, JString, required = true,
                                 default = nil)
  if valid_595497 != nil:
    section.add "LogFileName", valid_595497
  var valid_595498 = query.getOrDefault("Action")
  valid_595498 = validateParameter(valid_595498, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_595498 != nil:
    section.add "Action", valid_595498
  var valid_595499 = query.getOrDefault("Marker")
  valid_595499 = validateParameter(valid_595499, JString, required = false,
                                 default = nil)
  if valid_595499 != nil:
    section.add "Marker", valid_595499
  var valid_595500 = query.getOrDefault("Version")
  valid_595500 = validateParameter(valid_595500, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595500 != nil:
    section.add "Version", valid_595500
  var valid_595501 = query.getOrDefault("DBInstanceIdentifier")
  valid_595501 = validateParameter(valid_595501, JString, required = true,
                                 default = nil)
  if valid_595501 != nil:
    section.add "DBInstanceIdentifier", valid_595501
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
  var valid_595502 = header.getOrDefault("X-Amz-Date")
  valid_595502 = validateParameter(valid_595502, JString, required = false,
                                 default = nil)
  if valid_595502 != nil:
    section.add "X-Amz-Date", valid_595502
  var valid_595503 = header.getOrDefault("X-Amz-Security-Token")
  valid_595503 = validateParameter(valid_595503, JString, required = false,
                                 default = nil)
  if valid_595503 != nil:
    section.add "X-Amz-Security-Token", valid_595503
  var valid_595504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595504 = validateParameter(valid_595504, JString, required = false,
                                 default = nil)
  if valid_595504 != nil:
    section.add "X-Amz-Content-Sha256", valid_595504
  var valid_595505 = header.getOrDefault("X-Amz-Algorithm")
  valid_595505 = validateParameter(valid_595505, JString, required = false,
                                 default = nil)
  if valid_595505 != nil:
    section.add "X-Amz-Algorithm", valid_595505
  var valid_595506 = header.getOrDefault("X-Amz-Signature")
  valid_595506 = validateParameter(valid_595506, JString, required = false,
                                 default = nil)
  if valid_595506 != nil:
    section.add "X-Amz-Signature", valid_595506
  var valid_595507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595507 = validateParameter(valid_595507, JString, required = false,
                                 default = nil)
  if valid_595507 != nil:
    section.add "X-Amz-SignedHeaders", valid_595507
  var valid_595508 = header.getOrDefault("X-Amz-Credential")
  valid_595508 = validateParameter(valid_595508, JString, required = false,
                                 default = nil)
  if valid_595508 != nil:
    section.add "X-Amz-Credential", valid_595508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595509: Call_GetDownloadDBLogFilePortion_595493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595509.validator(path, query, header, formData, body)
  let scheme = call_595509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595509.url(scheme.get, call_595509.host, call_595509.base,
                         call_595509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595509, url, valid)

proc call*(call_595510: Call_GetDownloadDBLogFilePortion_595493;
          LogFileName: string; DBInstanceIdentifier: string; NumberOfLines: int = 0;
          Action: string = "DownloadDBLogFilePortion"; Marker: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   LogFileName: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_595511 = newJObject()
  add(query_595511, "NumberOfLines", newJInt(NumberOfLines))
  add(query_595511, "LogFileName", newJString(LogFileName))
  add(query_595511, "Action", newJString(Action))
  add(query_595511, "Marker", newJString(Marker))
  add(query_595511, "Version", newJString(Version))
  add(query_595511, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_595510.call(nil, query_595511, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_595493(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_595494, base: "/",
    url: url_GetDownloadDBLogFilePortion_595495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_595549 = ref object of OpenApiRestCall_593421
proc url_PostListTagsForResource_595551(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_595550(path: JsonNode; query: JsonNode;
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
  var valid_595552 = query.getOrDefault("Action")
  valid_595552 = validateParameter(valid_595552, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_595552 != nil:
    section.add "Action", valid_595552
  var valid_595553 = query.getOrDefault("Version")
  valid_595553 = validateParameter(valid_595553, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595553 != nil:
    section.add "Version", valid_595553
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
  var valid_595554 = header.getOrDefault("X-Amz-Date")
  valid_595554 = validateParameter(valid_595554, JString, required = false,
                                 default = nil)
  if valid_595554 != nil:
    section.add "X-Amz-Date", valid_595554
  var valid_595555 = header.getOrDefault("X-Amz-Security-Token")
  valid_595555 = validateParameter(valid_595555, JString, required = false,
                                 default = nil)
  if valid_595555 != nil:
    section.add "X-Amz-Security-Token", valid_595555
  var valid_595556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595556 = validateParameter(valid_595556, JString, required = false,
                                 default = nil)
  if valid_595556 != nil:
    section.add "X-Amz-Content-Sha256", valid_595556
  var valid_595557 = header.getOrDefault("X-Amz-Algorithm")
  valid_595557 = validateParameter(valid_595557, JString, required = false,
                                 default = nil)
  if valid_595557 != nil:
    section.add "X-Amz-Algorithm", valid_595557
  var valid_595558 = header.getOrDefault("X-Amz-Signature")
  valid_595558 = validateParameter(valid_595558, JString, required = false,
                                 default = nil)
  if valid_595558 != nil:
    section.add "X-Amz-Signature", valid_595558
  var valid_595559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595559 = validateParameter(valid_595559, JString, required = false,
                                 default = nil)
  if valid_595559 != nil:
    section.add "X-Amz-SignedHeaders", valid_595559
  var valid_595560 = header.getOrDefault("X-Amz-Credential")
  valid_595560 = validateParameter(valid_595560, JString, required = false,
                                 default = nil)
  if valid_595560 != nil:
    section.add "X-Amz-Credential", valid_595560
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_595561 = formData.getOrDefault("Filters")
  valid_595561 = validateParameter(valid_595561, JArray, required = false,
                                 default = nil)
  if valid_595561 != nil:
    section.add "Filters", valid_595561
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_595562 = formData.getOrDefault("ResourceName")
  valid_595562 = validateParameter(valid_595562, JString, required = true,
                                 default = nil)
  if valid_595562 != nil:
    section.add "ResourceName", valid_595562
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595563: Call_PostListTagsForResource_595549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595563.validator(path, query, header, formData, body)
  let scheme = call_595563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595563.url(scheme.get, call_595563.host, call_595563.base,
                         call_595563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595563, url, valid)

proc call*(call_595564: Call_PostListTagsForResource_595549; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_595565 = newJObject()
  var formData_595566 = newJObject()
  add(query_595565, "Action", newJString(Action))
  if Filters != nil:
    formData_595566.add "Filters", Filters
  add(formData_595566, "ResourceName", newJString(ResourceName))
  add(query_595565, "Version", newJString(Version))
  result = call_595564.call(nil, query_595565, nil, formData_595566, nil)

var postListTagsForResource* = Call_PostListTagsForResource_595549(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_595550, base: "/",
    url: url_PostListTagsForResource_595551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_595532 = ref object of OpenApiRestCall_593421
proc url_GetListTagsForResource_595534(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_595533(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_595535 = query.getOrDefault("Filters")
  valid_595535 = validateParameter(valid_595535, JArray, required = false,
                                 default = nil)
  if valid_595535 != nil:
    section.add "Filters", valid_595535
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_595536 = query.getOrDefault("ResourceName")
  valid_595536 = validateParameter(valid_595536, JString, required = true,
                                 default = nil)
  if valid_595536 != nil:
    section.add "ResourceName", valid_595536
  var valid_595537 = query.getOrDefault("Action")
  valid_595537 = validateParameter(valid_595537, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_595537 != nil:
    section.add "Action", valid_595537
  var valid_595538 = query.getOrDefault("Version")
  valid_595538 = validateParameter(valid_595538, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595538 != nil:
    section.add "Version", valid_595538
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
  var valid_595539 = header.getOrDefault("X-Amz-Date")
  valid_595539 = validateParameter(valid_595539, JString, required = false,
                                 default = nil)
  if valid_595539 != nil:
    section.add "X-Amz-Date", valid_595539
  var valid_595540 = header.getOrDefault("X-Amz-Security-Token")
  valid_595540 = validateParameter(valid_595540, JString, required = false,
                                 default = nil)
  if valid_595540 != nil:
    section.add "X-Amz-Security-Token", valid_595540
  var valid_595541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595541 = validateParameter(valid_595541, JString, required = false,
                                 default = nil)
  if valid_595541 != nil:
    section.add "X-Amz-Content-Sha256", valid_595541
  var valid_595542 = header.getOrDefault("X-Amz-Algorithm")
  valid_595542 = validateParameter(valid_595542, JString, required = false,
                                 default = nil)
  if valid_595542 != nil:
    section.add "X-Amz-Algorithm", valid_595542
  var valid_595543 = header.getOrDefault("X-Amz-Signature")
  valid_595543 = validateParameter(valid_595543, JString, required = false,
                                 default = nil)
  if valid_595543 != nil:
    section.add "X-Amz-Signature", valid_595543
  var valid_595544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595544 = validateParameter(valid_595544, JString, required = false,
                                 default = nil)
  if valid_595544 != nil:
    section.add "X-Amz-SignedHeaders", valid_595544
  var valid_595545 = header.getOrDefault("X-Amz-Credential")
  valid_595545 = validateParameter(valid_595545, JString, required = false,
                                 default = nil)
  if valid_595545 != nil:
    section.add "X-Amz-Credential", valid_595545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595546: Call_GetListTagsForResource_595532; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595546.validator(path, query, header, formData, body)
  let scheme = call_595546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595546.url(scheme.get, call_595546.host, call_595546.base,
                         call_595546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595546, url, valid)

proc call*(call_595547: Call_GetListTagsForResource_595532; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2013-09-09"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595548 = newJObject()
  if Filters != nil:
    query_595548.add "Filters", Filters
  add(query_595548, "ResourceName", newJString(ResourceName))
  add(query_595548, "Action", newJString(Action))
  add(query_595548, "Version", newJString(Version))
  result = call_595547.call(nil, query_595548, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_595532(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_595533, base: "/",
    url: url_GetListTagsForResource_595534, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_595600 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBInstance_595602(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_595601(path: JsonNode; query: JsonNode;
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
  var valid_595603 = query.getOrDefault("Action")
  valid_595603 = validateParameter(valid_595603, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_595603 != nil:
    section.add "Action", valid_595603
  var valid_595604 = query.getOrDefault("Version")
  valid_595604 = validateParameter(valid_595604, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595604 != nil:
    section.add "Version", valid_595604
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
  var valid_595605 = header.getOrDefault("X-Amz-Date")
  valid_595605 = validateParameter(valid_595605, JString, required = false,
                                 default = nil)
  if valid_595605 != nil:
    section.add "X-Amz-Date", valid_595605
  var valid_595606 = header.getOrDefault("X-Amz-Security-Token")
  valid_595606 = validateParameter(valid_595606, JString, required = false,
                                 default = nil)
  if valid_595606 != nil:
    section.add "X-Amz-Security-Token", valid_595606
  var valid_595607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595607 = validateParameter(valid_595607, JString, required = false,
                                 default = nil)
  if valid_595607 != nil:
    section.add "X-Amz-Content-Sha256", valid_595607
  var valid_595608 = header.getOrDefault("X-Amz-Algorithm")
  valid_595608 = validateParameter(valid_595608, JString, required = false,
                                 default = nil)
  if valid_595608 != nil:
    section.add "X-Amz-Algorithm", valid_595608
  var valid_595609 = header.getOrDefault("X-Amz-Signature")
  valid_595609 = validateParameter(valid_595609, JString, required = false,
                                 default = nil)
  if valid_595609 != nil:
    section.add "X-Amz-Signature", valid_595609
  var valid_595610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595610 = validateParameter(valid_595610, JString, required = false,
                                 default = nil)
  if valid_595610 != nil:
    section.add "X-Amz-SignedHeaders", valid_595610
  var valid_595611 = header.getOrDefault("X-Amz-Credential")
  valid_595611 = validateParameter(valid_595611, JString, required = false,
                                 default = nil)
  if valid_595611 != nil:
    section.add "X-Amz-Credential", valid_595611
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredMaintenanceWindow: JString
  ##   DBSecurityGroups: JArray
  ##   ApplyImmediately: JBool
  ##   VpcSecurityGroupIds: JArray
  ##   Iops: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   DBParameterGroupName: JString
  ##   OptionGroupName: JString
  ##   MasterUserPassword: JString
  ##   NewDBInstanceIdentifier: JString
  ##   MultiAZ: JBool
  ##   AllocatedStorage: JInt
  ##   DBInstanceClass: JString
  ##   PreferredBackupWindow: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   EngineVersion: JString
  ##   AllowMajorVersionUpgrade: JBool
  section = newJObject()
  var valid_595612 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_595612 = validateParameter(valid_595612, JString, required = false,
                                 default = nil)
  if valid_595612 != nil:
    section.add "PreferredMaintenanceWindow", valid_595612
  var valid_595613 = formData.getOrDefault("DBSecurityGroups")
  valid_595613 = validateParameter(valid_595613, JArray, required = false,
                                 default = nil)
  if valid_595613 != nil:
    section.add "DBSecurityGroups", valid_595613
  var valid_595614 = formData.getOrDefault("ApplyImmediately")
  valid_595614 = validateParameter(valid_595614, JBool, required = false, default = nil)
  if valid_595614 != nil:
    section.add "ApplyImmediately", valid_595614
  var valid_595615 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_595615 = validateParameter(valid_595615, JArray, required = false,
                                 default = nil)
  if valid_595615 != nil:
    section.add "VpcSecurityGroupIds", valid_595615
  var valid_595616 = formData.getOrDefault("Iops")
  valid_595616 = validateParameter(valid_595616, JInt, required = false, default = nil)
  if valid_595616 != nil:
    section.add "Iops", valid_595616
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595617 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595617 = validateParameter(valid_595617, JString, required = true,
                                 default = nil)
  if valid_595617 != nil:
    section.add "DBInstanceIdentifier", valid_595617
  var valid_595618 = formData.getOrDefault("BackupRetentionPeriod")
  valid_595618 = validateParameter(valid_595618, JInt, required = false, default = nil)
  if valid_595618 != nil:
    section.add "BackupRetentionPeriod", valid_595618
  var valid_595619 = formData.getOrDefault("DBParameterGroupName")
  valid_595619 = validateParameter(valid_595619, JString, required = false,
                                 default = nil)
  if valid_595619 != nil:
    section.add "DBParameterGroupName", valid_595619
  var valid_595620 = formData.getOrDefault("OptionGroupName")
  valid_595620 = validateParameter(valid_595620, JString, required = false,
                                 default = nil)
  if valid_595620 != nil:
    section.add "OptionGroupName", valid_595620
  var valid_595621 = formData.getOrDefault("MasterUserPassword")
  valid_595621 = validateParameter(valid_595621, JString, required = false,
                                 default = nil)
  if valid_595621 != nil:
    section.add "MasterUserPassword", valid_595621
  var valid_595622 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_595622 = validateParameter(valid_595622, JString, required = false,
                                 default = nil)
  if valid_595622 != nil:
    section.add "NewDBInstanceIdentifier", valid_595622
  var valid_595623 = formData.getOrDefault("MultiAZ")
  valid_595623 = validateParameter(valid_595623, JBool, required = false, default = nil)
  if valid_595623 != nil:
    section.add "MultiAZ", valid_595623
  var valid_595624 = formData.getOrDefault("AllocatedStorage")
  valid_595624 = validateParameter(valid_595624, JInt, required = false, default = nil)
  if valid_595624 != nil:
    section.add "AllocatedStorage", valid_595624
  var valid_595625 = formData.getOrDefault("DBInstanceClass")
  valid_595625 = validateParameter(valid_595625, JString, required = false,
                                 default = nil)
  if valid_595625 != nil:
    section.add "DBInstanceClass", valid_595625
  var valid_595626 = formData.getOrDefault("PreferredBackupWindow")
  valid_595626 = validateParameter(valid_595626, JString, required = false,
                                 default = nil)
  if valid_595626 != nil:
    section.add "PreferredBackupWindow", valid_595626
  var valid_595627 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_595627 = validateParameter(valid_595627, JBool, required = false, default = nil)
  if valid_595627 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595627
  var valid_595628 = formData.getOrDefault("EngineVersion")
  valid_595628 = validateParameter(valid_595628, JString, required = false,
                                 default = nil)
  if valid_595628 != nil:
    section.add "EngineVersion", valid_595628
  var valid_595629 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_595629 = validateParameter(valid_595629, JBool, required = false, default = nil)
  if valid_595629 != nil:
    section.add "AllowMajorVersionUpgrade", valid_595629
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595630: Call_PostModifyDBInstance_595600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595630.validator(path, query, header, formData, body)
  let scheme = call_595630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595630.url(scheme.get, call_595630.host, call_595630.base,
                         call_595630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595630, url, valid)

proc call*(call_595631: Call_PostModifyDBInstance_595600;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBSecurityGroups: JsonNode = nil; ApplyImmediately: bool = false;
          VpcSecurityGroupIds: JsonNode = nil; Iops: int = 0;
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          OptionGroupName: string = ""; MasterUserPassword: string = "";
          NewDBInstanceIdentifier: string = ""; MultiAZ: bool = false;
          Action: string = "ModifyDBInstance"; AllocatedStorage: int = 0;
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          Version: string = "2013-09-09"; AllowMajorVersionUpgrade: bool = false): Recallable =
  ## postModifyDBInstance
  ##   PreferredMaintenanceWindow: string
  ##   DBSecurityGroups: JArray
  ##   ApplyImmediately: bool
  ##   VpcSecurityGroupIds: JArray
  ##   Iops: int
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   DBParameterGroupName: string
  ##   OptionGroupName: string
  ##   MasterUserPassword: string
  ##   NewDBInstanceIdentifier: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   AllocatedStorage: int
  ##   DBInstanceClass: string
  ##   PreferredBackupWindow: string
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   Version: string (required)
  ##   AllowMajorVersionUpgrade: bool
  var query_595632 = newJObject()
  var formData_595633 = newJObject()
  add(formData_595633, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_595633.add "DBSecurityGroups", DBSecurityGroups
  add(formData_595633, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_595633.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_595633, "Iops", newJInt(Iops))
  add(formData_595633, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595633, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_595633, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_595633, "OptionGroupName", newJString(OptionGroupName))
  add(formData_595633, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_595633, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_595633, "MultiAZ", newJBool(MultiAZ))
  add(query_595632, "Action", newJString(Action))
  add(formData_595633, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_595633, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595633, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_595633, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_595633, "EngineVersion", newJString(EngineVersion))
  add(query_595632, "Version", newJString(Version))
  add(formData_595633, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_595631.call(nil, query_595632, nil, formData_595633, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_595600(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_595601, base: "/",
    url: url_PostModifyDBInstance_595602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_595567 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBInstance_595569(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_595568(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PreferredMaintenanceWindow: JString
  ##   AllocatedStorage: JInt
  ##   OptionGroupName: JString
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: JString
  ##   Iops: JInt
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: JBool
  ##   BackupRetentionPeriod: JInt
  ##   DBParameterGroupName: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   AllowMajorVersionUpgrade: JBool
  ##   NewDBInstanceIdentifier: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   EngineVersion: JString
  ##   PreferredBackupWindow: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   ApplyImmediately: JBool
  section = newJObject()
  var valid_595570 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_595570 = validateParameter(valid_595570, JString, required = false,
                                 default = nil)
  if valid_595570 != nil:
    section.add "PreferredMaintenanceWindow", valid_595570
  var valid_595571 = query.getOrDefault("AllocatedStorage")
  valid_595571 = validateParameter(valid_595571, JInt, required = false, default = nil)
  if valid_595571 != nil:
    section.add "AllocatedStorage", valid_595571
  var valid_595572 = query.getOrDefault("OptionGroupName")
  valid_595572 = validateParameter(valid_595572, JString, required = false,
                                 default = nil)
  if valid_595572 != nil:
    section.add "OptionGroupName", valid_595572
  var valid_595573 = query.getOrDefault("DBSecurityGroups")
  valid_595573 = validateParameter(valid_595573, JArray, required = false,
                                 default = nil)
  if valid_595573 != nil:
    section.add "DBSecurityGroups", valid_595573
  var valid_595574 = query.getOrDefault("MasterUserPassword")
  valid_595574 = validateParameter(valid_595574, JString, required = false,
                                 default = nil)
  if valid_595574 != nil:
    section.add "MasterUserPassword", valid_595574
  var valid_595575 = query.getOrDefault("Iops")
  valid_595575 = validateParameter(valid_595575, JInt, required = false, default = nil)
  if valid_595575 != nil:
    section.add "Iops", valid_595575
  var valid_595576 = query.getOrDefault("VpcSecurityGroupIds")
  valid_595576 = validateParameter(valid_595576, JArray, required = false,
                                 default = nil)
  if valid_595576 != nil:
    section.add "VpcSecurityGroupIds", valid_595576
  var valid_595577 = query.getOrDefault("MultiAZ")
  valid_595577 = validateParameter(valid_595577, JBool, required = false, default = nil)
  if valid_595577 != nil:
    section.add "MultiAZ", valid_595577
  var valid_595578 = query.getOrDefault("BackupRetentionPeriod")
  valid_595578 = validateParameter(valid_595578, JInt, required = false, default = nil)
  if valid_595578 != nil:
    section.add "BackupRetentionPeriod", valid_595578
  var valid_595579 = query.getOrDefault("DBParameterGroupName")
  valid_595579 = validateParameter(valid_595579, JString, required = false,
                                 default = nil)
  if valid_595579 != nil:
    section.add "DBParameterGroupName", valid_595579
  var valid_595580 = query.getOrDefault("DBInstanceClass")
  valid_595580 = validateParameter(valid_595580, JString, required = false,
                                 default = nil)
  if valid_595580 != nil:
    section.add "DBInstanceClass", valid_595580
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595581 = query.getOrDefault("Action")
  valid_595581 = validateParameter(valid_595581, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_595581 != nil:
    section.add "Action", valid_595581
  var valid_595582 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_595582 = validateParameter(valid_595582, JBool, required = false, default = nil)
  if valid_595582 != nil:
    section.add "AllowMajorVersionUpgrade", valid_595582
  var valid_595583 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_595583 = validateParameter(valid_595583, JString, required = false,
                                 default = nil)
  if valid_595583 != nil:
    section.add "NewDBInstanceIdentifier", valid_595583
  var valid_595584 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_595584 = validateParameter(valid_595584, JBool, required = false, default = nil)
  if valid_595584 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595584
  var valid_595585 = query.getOrDefault("EngineVersion")
  valid_595585 = validateParameter(valid_595585, JString, required = false,
                                 default = nil)
  if valid_595585 != nil:
    section.add "EngineVersion", valid_595585
  var valid_595586 = query.getOrDefault("PreferredBackupWindow")
  valid_595586 = validateParameter(valid_595586, JString, required = false,
                                 default = nil)
  if valid_595586 != nil:
    section.add "PreferredBackupWindow", valid_595586
  var valid_595587 = query.getOrDefault("Version")
  valid_595587 = validateParameter(valid_595587, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595587 != nil:
    section.add "Version", valid_595587
  var valid_595588 = query.getOrDefault("DBInstanceIdentifier")
  valid_595588 = validateParameter(valid_595588, JString, required = true,
                                 default = nil)
  if valid_595588 != nil:
    section.add "DBInstanceIdentifier", valid_595588
  var valid_595589 = query.getOrDefault("ApplyImmediately")
  valid_595589 = validateParameter(valid_595589, JBool, required = false, default = nil)
  if valid_595589 != nil:
    section.add "ApplyImmediately", valid_595589
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
  var valid_595590 = header.getOrDefault("X-Amz-Date")
  valid_595590 = validateParameter(valid_595590, JString, required = false,
                                 default = nil)
  if valid_595590 != nil:
    section.add "X-Amz-Date", valid_595590
  var valid_595591 = header.getOrDefault("X-Amz-Security-Token")
  valid_595591 = validateParameter(valid_595591, JString, required = false,
                                 default = nil)
  if valid_595591 != nil:
    section.add "X-Amz-Security-Token", valid_595591
  var valid_595592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595592 = validateParameter(valid_595592, JString, required = false,
                                 default = nil)
  if valid_595592 != nil:
    section.add "X-Amz-Content-Sha256", valid_595592
  var valid_595593 = header.getOrDefault("X-Amz-Algorithm")
  valid_595593 = validateParameter(valid_595593, JString, required = false,
                                 default = nil)
  if valid_595593 != nil:
    section.add "X-Amz-Algorithm", valid_595593
  var valid_595594 = header.getOrDefault("X-Amz-Signature")
  valid_595594 = validateParameter(valid_595594, JString, required = false,
                                 default = nil)
  if valid_595594 != nil:
    section.add "X-Amz-Signature", valid_595594
  var valid_595595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595595 = validateParameter(valid_595595, JString, required = false,
                                 default = nil)
  if valid_595595 != nil:
    section.add "X-Amz-SignedHeaders", valid_595595
  var valid_595596 = header.getOrDefault("X-Amz-Credential")
  valid_595596 = validateParameter(valid_595596, JString, required = false,
                                 default = nil)
  if valid_595596 != nil:
    section.add "X-Amz-Credential", valid_595596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595597: Call_GetModifyDBInstance_595567; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595597.validator(path, query, header, formData, body)
  let scheme = call_595597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595597.url(scheme.get, call_595597.host, call_595597.base,
                         call_595597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595597, url, valid)

proc call*(call_595598: Call_GetModifyDBInstance_595567;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          AllocatedStorage: int = 0; OptionGroupName: string = "";
          DBSecurityGroups: JsonNode = nil; MasterUserPassword: string = "";
          Iops: int = 0; VpcSecurityGroupIds: JsonNode = nil; MultiAZ: bool = false;
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          DBInstanceClass: string = ""; Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false;
          NewDBInstanceIdentifier: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          PreferredBackupWindow: string = ""; Version: string = "2013-09-09";
          ApplyImmediately: bool = false): Recallable =
  ## getModifyDBInstance
  ##   PreferredMaintenanceWindow: string
  ##   AllocatedStorage: int
  ##   OptionGroupName: string
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: string
  ##   Iops: int
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: bool
  ##   BackupRetentionPeriod: int
  ##   DBParameterGroupName: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   AllowMajorVersionUpgrade: bool
  ##   NewDBInstanceIdentifier: string
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   ApplyImmediately: bool
  var query_595599 = newJObject()
  add(query_595599, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_595599, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_595599, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_595599.add "DBSecurityGroups", DBSecurityGroups
  add(query_595599, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_595599, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_595599.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_595599, "MultiAZ", newJBool(MultiAZ))
  add(query_595599, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_595599, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_595599, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595599, "Action", newJString(Action))
  add(query_595599, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_595599, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_595599, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_595599, "EngineVersion", newJString(EngineVersion))
  add(query_595599, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_595599, "Version", newJString(Version))
  add(query_595599, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595599, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_595598.call(nil, query_595599, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_595567(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_595568, base: "/",
    url: url_GetModifyDBInstance_595569, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_595651 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBParameterGroup_595653(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_595652(path: JsonNode; query: JsonNode;
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
  var valid_595654 = query.getOrDefault("Action")
  valid_595654 = validateParameter(valid_595654, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_595654 != nil:
    section.add "Action", valid_595654
  var valid_595655 = query.getOrDefault("Version")
  valid_595655 = validateParameter(valid_595655, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595655 != nil:
    section.add "Version", valid_595655
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
  var valid_595656 = header.getOrDefault("X-Amz-Date")
  valid_595656 = validateParameter(valid_595656, JString, required = false,
                                 default = nil)
  if valid_595656 != nil:
    section.add "X-Amz-Date", valid_595656
  var valid_595657 = header.getOrDefault("X-Amz-Security-Token")
  valid_595657 = validateParameter(valid_595657, JString, required = false,
                                 default = nil)
  if valid_595657 != nil:
    section.add "X-Amz-Security-Token", valid_595657
  var valid_595658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595658 = validateParameter(valid_595658, JString, required = false,
                                 default = nil)
  if valid_595658 != nil:
    section.add "X-Amz-Content-Sha256", valid_595658
  var valid_595659 = header.getOrDefault("X-Amz-Algorithm")
  valid_595659 = validateParameter(valid_595659, JString, required = false,
                                 default = nil)
  if valid_595659 != nil:
    section.add "X-Amz-Algorithm", valid_595659
  var valid_595660 = header.getOrDefault("X-Amz-Signature")
  valid_595660 = validateParameter(valid_595660, JString, required = false,
                                 default = nil)
  if valid_595660 != nil:
    section.add "X-Amz-Signature", valid_595660
  var valid_595661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595661 = validateParameter(valid_595661, JString, required = false,
                                 default = nil)
  if valid_595661 != nil:
    section.add "X-Amz-SignedHeaders", valid_595661
  var valid_595662 = header.getOrDefault("X-Amz-Credential")
  valid_595662 = validateParameter(valid_595662, JString, required = false,
                                 default = nil)
  if valid_595662 != nil:
    section.add "X-Amz-Credential", valid_595662
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_595663 = formData.getOrDefault("DBParameterGroupName")
  valid_595663 = validateParameter(valid_595663, JString, required = true,
                                 default = nil)
  if valid_595663 != nil:
    section.add "DBParameterGroupName", valid_595663
  var valid_595664 = formData.getOrDefault("Parameters")
  valid_595664 = validateParameter(valid_595664, JArray, required = true, default = nil)
  if valid_595664 != nil:
    section.add "Parameters", valid_595664
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595665: Call_PostModifyDBParameterGroup_595651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595665.validator(path, query, header, formData, body)
  let scheme = call_595665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595665.url(scheme.get, call_595665.host, call_595665.base,
                         call_595665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595665, url, valid)

proc call*(call_595666: Call_PostModifyDBParameterGroup_595651;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595667 = newJObject()
  var formData_595668 = newJObject()
  add(formData_595668, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_595668.add "Parameters", Parameters
  add(query_595667, "Action", newJString(Action))
  add(query_595667, "Version", newJString(Version))
  result = call_595666.call(nil, query_595667, nil, formData_595668, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_595651(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_595652, base: "/",
    url: url_PostModifyDBParameterGroup_595653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_595634 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBParameterGroup_595636(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_595635(path: JsonNode; query: JsonNode;
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
  var valid_595637 = query.getOrDefault("DBParameterGroupName")
  valid_595637 = validateParameter(valid_595637, JString, required = true,
                                 default = nil)
  if valid_595637 != nil:
    section.add "DBParameterGroupName", valid_595637
  var valid_595638 = query.getOrDefault("Parameters")
  valid_595638 = validateParameter(valid_595638, JArray, required = true, default = nil)
  if valid_595638 != nil:
    section.add "Parameters", valid_595638
  var valid_595639 = query.getOrDefault("Action")
  valid_595639 = validateParameter(valid_595639, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_595639 != nil:
    section.add "Action", valid_595639
  var valid_595640 = query.getOrDefault("Version")
  valid_595640 = validateParameter(valid_595640, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595640 != nil:
    section.add "Version", valid_595640
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
  var valid_595641 = header.getOrDefault("X-Amz-Date")
  valid_595641 = validateParameter(valid_595641, JString, required = false,
                                 default = nil)
  if valid_595641 != nil:
    section.add "X-Amz-Date", valid_595641
  var valid_595642 = header.getOrDefault("X-Amz-Security-Token")
  valid_595642 = validateParameter(valid_595642, JString, required = false,
                                 default = nil)
  if valid_595642 != nil:
    section.add "X-Amz-Security-Token", valid_595642
  var valid_595643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595643 = validateParameter(valid_595643, JString, required = false,
                                 default = nil)
  if valid_595643 != nil:
    section.add "X-Amz-Content-Sha256", valid_595643
  var valid_595644 = header.getOrDefault("X-Amz-Algorithm")
  valid_595644 = validateParameter(valid_595644, JString, required = false,
                                 default = nil)
  if valid_595644 != nil:
    section.add "X-Amz-Algorithm", valid_595644
  var valid_595645 = header.getOrDefault("X-Amz-Signature")
  valid_595645 = validateParameter(valid_595645, JString, required = false,
                                 default = nil)
  if valid_595645 != nil:
    section.add "X-Amz-Signature", valid_595645
  var valid_595646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595646 = validateParameter(valid_595646, JString, required = false,
                                 default = nil)
  if valid_595646 != nil:
    section.add "X-Amz-SignedHeaders", valid_595646
  var valid_595647 = header.getOrDefault("X-Amz-Credential")
  valid_595647 = validateParameter(valid_595647, JString, required = false,
                                 default = nil)
  if valid_595647 != nil:
    section.add "X-Amz-Credential", valid_595647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595648: Call_GetModifyDBParameterGroup_595634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595648.validator(path, query, header, formData, body)
  let scheme = call_595648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595648.url(scheme.get, call_595648.host, call_595648.base,
                         call_595648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595648, url, valid)

proc call*(call_595649: Call_GetModifyDBParameterGroup_595634;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595650 = newJObject()
  add(query_595650, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_595650.add "Parameters", Parameters
  add(query_595650, "Action", newJString(Action))
  add(query_595650, "Version", newJString(Version))
  result = call_595649.call(nil, query_595650, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_595634(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_595635, base: "/",
    url: url_GetModifyDBParameterGroup_595636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_595687 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBSubnetGroup_595689(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_595688(path: JsonNode; query: JsonNode;
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
  var valid_595690 = query.getOrDefault("Action")
  valid_595690 = validateParameter(valid_595690, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_595690 != nil:
    section.add "Action", valid_595690
  var valid_595691 = query.getOrDefault("Version")
  valid_595691 = validateParameter(valid_595691, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595691 != nil:
    section.add "Version", valid_595691
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
  var valid_595692 = header.getOrDefault("X-Amz-Date")
  valid_595692 = validateParameter(valid_595692, JString, required = false,
                                 default = nil)
  if valid_595692 != nil:
    section.add "X-Amz-Date", valid_595692
  var valid_595693 = header.getOrDefault("X-Amz-Security-Token")
  valid_595693 = validateParameter(valid_595693, JString, required = false,
                                 default = nil)
  if valid_595693 != nil:
    section.add "X-Amz-Security-Token", valid_595693
  var valid_595694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595694 = validateParameter(valid_595694, JString, required = false,
                                 default = nil)
  if valid_595694 != nil:
    section.add "X-Amz-Content-Sha256", valid_595694
  var valid_595695 = header.getOrDefault("X-Amz-Algorithm")
  valid_595695 = validateParameter(valid_595695, JString, required = false,
                                 default = nil)
  if valid_595695 != nil:
    section.add "X-Amz-Algorithm", valid_595695
  var valid_595696 = header.getOrDefault("X-Amz-Signature")
  valid_595696 = validateParameter(valid_595696, JString, required = false,
                                 default = nil)
  if valid_595696 != nil:
    section.add "X-Amz-Signature", valid_595696
  var valid_595697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595697 = validateParameter(valid_595697, JString, required = false,
                                 default = nil)
  if valid_595697 != nil:
    section.add "X-Amz-SignedHeaders", valid_595697
  var valid_595698 = header.getOrDefault("X-Amz-Credential")
  valid_595698 = validateParameter(valid_595698, JString, required = false,
                                 default = nil)
  if valid_595698 != nil:
    section.add "X-Amz-Credential", valid_595698
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_595699 = formData.getOrDefault("DBSubnetGroupName")
  valid_595699 = validateParameter(valid_595699, JString, required = true,
                                 default = nil)
  if valid_595699 != nil:
    section.add "DBSubnetGroupName", valid_595699
  var valid_595700 = formData.getOrDefault("SubnetIds")
  valid_595700 = validateParameter(valid_595700, JArray, required = true, default = nil)
  if valid_595700 != nil:
    section.add "SubnetIds", valid_595700
  var valid_595701 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_595701 = validateParameter(valid_595701, JString, required = false,
                                 default = nil)
  if valid_595701 != nil:
    section.add "DBSubnetGroupDescription", valid_595701
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595702: Call_PostModifyDBSubnetGroup_595687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595702.validator(path, query, header, formData, body)
  let scheme = call_595702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595702.url(scheme.get, call_595702.host, call_595702.base,
                         call_595702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595702, url, valid)

proc call*(call_595703: Call_PostModifyDBSubnetGroup_595687;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_595704 = newJObject()
  var formData_595705 = newJObject()
  add(formData_595705, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_595705.add "SubnetIds", SubnetIds
  add(query_595704, "Action", newJString(Action))
  add(formData_595705, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_595704, "Version", newJString(Version))
  result = call_595703.call(nil, query_595704, nil, formData_595705, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_595687(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_595688, base: "/",
    url: url_PostModifyDBSubnetGroup_595689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_595669 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBSubnetGroup_595671(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_595670(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595672 = query.getOrDefault("Action")
  valid_595672 = validateParameter(valid_595672, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_595672 != nil:
    section.add "Action", valid_595672
  var valid_595673 = query.getOrDefault("DBSubnetGroupName")
  valid_595673 = validateParameter(valid_595673, JString, required = true,
                                 default = nil)
  if valid_595673 != nil:
    section.add "DBSubnetGroupName", valid_595673
  var valid_595674 = query.getOrDefault("SubnetIds")
  valid_595674 = validateParameter(valid_595674, JArray, required = true, default = nil)
  if valid_595674 != nil:
    section.add "SubnetIds", valid_595674
  var valid_595675 = query.getOrDefault("DBSubnetGroupDescription")
  valid_595675 = validateParameter(valid_595675, JString, required = false,
                                 default = nil)
  if valid_595675 != nil:
    section.add "DBSubnetGroupDescription", valid_595675
  var valid_595676 = query.getOrDefault("Version")
  valid_595676 = validateParameter(valid_595676, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595676 != nil:
    section.add "Version", valid_595676
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
  var valid_595677 = header.getOrDefault("X-Amz-Date")
  valid_595677 = validateParameter(valid_595677, JString, required = false,
                                 default = nil)
  if valid_595677 != nil:
    section.add "X-Amz-Date", valid_595677
  var valid_595678 = header.getOrDefault("X-Amz-Security-Token")
  valid_595678 = validateParameter(valid_595678, JString, required = false,
                                 default = nil)
  if valid_595678 != nil:
    section.add "X-Amz-Security-Token", valid_595678
  var valid_595679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595679 = validateParameter(valid_595679, JString, required = false,
                                 default = nil)
  if valid_595679 != nil:
    section.add "X-Amz-Content-Sha256", valid_595679
  var valid_595680 = header.getOrDefault("X-Amz-Algorithm")
  valid_595680 = validateParameter(valid_595680, JString, required = false,
                                 default = nil)
  if valid_595680 != nil:
    section.add "X-Amz-Algorithm", valid_595680
  var valid_595681 = header.getOrDefault("X-Amz-Signature")
  valid_595681 = validateParameter(valid_595681, JString, required = false,
                                 default = nil)
  if valid_595681 != nil:
    section.add "X-Amz-Signature", valid_595681
  var valid_595682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595682 = validateParameter(valid_595682, JString, required = false,
                                 default = nil)
  if valid_595682 != nil:
    section.add "X-Amz-SignedHeaders", valid_595682
  var valid_595683 = header.getOrDefault("X-Amz-Credential")
  valid_595683 = validateParameter(valid_595683, JString, required = false,
                                 default = nil)
  if valid_595683 != nil:
    section.add "X-Amz-Credential", valid_595683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595684: Call_GetModifyDBSubnetGroup_595669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595684.validator(path, query, header, formData, body)
  let scheme = call_595684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595684.url(scheme.get, call_595684.host, call_595684.base,
                         call_595684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595684, url, valid)

proc call*(call_595685: Call_GetModifyDBSubnetGroup_595669;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_595686 = newJObject()
  add(query_595686, "Action", newJString(Action))
  add(query_595686, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_595686.add "SubnetIds", SubnetIds
  add(query_595686, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_595686, "Version", newJString(Version))
  result = call_595685.call(nil, query_595686, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_595669(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_595670, base: "/",
    url: url_GetModifyDBSubnetGroup_595671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_595726 = ref object of OpenApiRestCall_593421
proc url_PostModifyEventSubscription_595728(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_595727(path: JsonNode; query: JsonNode;
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
  var valid_595729 = query.getOrDefault("Action")
  valid_595729 = validateParameter(valid_595729, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_595729 != nil:
    section.add "Action", valid_595729
  var valid_595730 = query.getOrDefault("Version")
  valid_595730 = validateParameter(valid_595730, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595730 != nil:
    section.add "Version", valid_595730
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
  var valid_595731 = header.getOrDefault("X-Amz-Date")
  valid_595731 = validateParameter(valid_595731, JString, required = false,
                                 default = nil)
  if valid_595731 != nil:
    section.add "X-Amz-Date", valid_595731
  var valid_595732 = header.getOrDefault("X-Amz-Security-Token")
  valid_595732 = validateParameter(valid_595732, JString, required = false,
                                 default = nil)
  if valid_595732 != nil:
    section.add "X-Amz-Security-Token", valid_595732
  var valid_595733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595733 = validateParameter(valid_595733, JString, required = false,
                                 default = nil)
  if valid_595733 != nil:
    section.add "X-Amz-Content-Sha256", valid_595733
  var valid_595734 = header.getOrDefault("X-Amz-Algorithm")
  valid_595734 = validateParameter(valid_595734, JString, required = false,
                                 default = nil)
  if valid_595734 != nil:
    section.add "X-Amz-Algorithm", valid_595734
  var valid_595735 = header.getOrDefault("X-Amz-Signature")
  valid_595735 = validateParameter(valid_595735, JString, required = false,
                                 default = nil)
  if valid_595735 != nil:
    section.add "X-Amz-Signature", valid_595735
  var valid_595736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595736 = validateParameter(valid_595736, JString, required = false,
                                 default = nil)
  if valid_595736 != nil:
    section.add "X-Amz-SignedHeaders", valid_595736
  var valid_595737 = header.getOrDefault("X-Amz-Credential")
  valid_595737 = validateParameter(valid_595737, JString, required = false,
                                 default = nil)
  if valid_595737 != nil:
    section.add "X-Amz-Credential", valid_595737
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_595738 = formData.getOrDefault("Enabled")
  valid_595738 = validateParameter(valid_595738, JBool, required = false, default = nil)
  if valid_595738 != nil:
    section.add "Enabled", valid_595738
  var valid_595739 = formData.getOrDefault("EventCategories")
  valid_595739 = validateParameter(valid_595739, JArray, required = false,
                                 default = nil)
  if valid_595739 != nil:
    section.add "EventCategories", valid_595739
  var valid_595740 = formData.getOrDefault("SnsTopicArn")
  valid_595740 = validateParameter(valid_595740, JString, required = false,
                                 default = nil)
  if valid_595740 != nil:
    section.add "SnsTopicArn", valid_595740
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_595741 = formData.getOrDefault("SubscriptionName")
  valid_595741 = validateParameter(valid_595741, JString, required = true,
                                 default = nil)
  if valid_595741 != nil:
    section.add "SubscriptionName", valid_595741
  var valid_595742 = formData.getOrDefault("SourceType")
  valid_595742 = validateParameter(valid_595742, JString, required = false,
                                 default = nil)
  if valid_595742 != nil:
    section.add "SourceType", valid_595742
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595743: Call_PostModifyEventSubscription_595726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595743.validator(path, query, header, formData, body)
  let scheme = call_595743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595743.url(scheme.get, call_595743.host, call_595743.base,
                         call_595743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595743, url, valid)

proc call*(call_595744: Call_PostModifyEventSubscription_595726;
          SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SnsTopicArn: string = "";
          Action: string = "ModifyEventSubscription";
          Version: string = "2013-09-09"; SourceType: string = ""): Recallable =
  ## postModifyEventSubscription
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   SnsTopicArn: string
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_595745 = newJObject()
  var formData_595746 = newJObject()
  add(formData_595746, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_595746.add "EventCategories", EventCategories
  add(formData_595746, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_595746, "SubscriptionName", newJString(SubscriptionName))
  add(query_595745, "Action", newJString(Action))
  add(query_595745, "Version", newJString(Version))
  add(formData_595746, "SourceType", newJString(SourceType))
  result = call_595744.call(nil, query_595745, nil, formData_595746, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_595726(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_595727, base: "/",
    url: url_PostModifyEventSubscription_595728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_595706 = ref object of OpenApiRestCall_593421
proc url_GetModifyEventSubscription_595708(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_595707(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Enabled: JBool
  ##   Action: JString (required)
  ##   SnsTopicArn: JString
  ##   EventCategories: JArray
  ##   SubscriptionName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_595709 = query.getOrDefault("SourceType")
  valid_595709 = validateParameter(valid_595709, JString, required = false,
                                 default = nil)
  if valid_595709 != nil:
    section.add "SourceType", valid_595709
  var valid_595710 = query.getOrDefault("Enabled")
  valid_595710 = validateParameter(valid_595710, JBool, required = false, default = nil)
  if valid_595710 != nil:
    section.add "Enabled", valid_595710
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595711 = query.getOrDefault("Action")
  valid_595711 = validateParameter(valid_595711, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_595711 != nil:
    section.add "Action", valid_595711
  var valid_595712 = query.getOrDefault("SnsTopicArn")
  valid_595712 = validateParameter(valid_595712, JString, required = false,
                                 default = nil)
  if valid_595712 != nil:
    section.add "SnsTopicArn", valid_595712
  var valid_595713 = query.getOrDefault("EventCategories")
  valid_595713 = validateParameter(valid_595713, JArray, required = false,
                                 default = nil)
  if valid_595713 != nil:
    section.add "EventCategories", valid_595713
  var valid_595714 = query.getOrDefault("SubscriptionName")
  valid_595714 = validateParameter(valid_595714, JString, required = true,
                                 default = nil)
  if valid_595714 != nil:
    section.add "SubscriptionName", valid_595714
  var valid_595715 = query.getOrDefault("Version")
  valid_595715 = validateParameter(valid_595715, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595715 != nil:
    section.add "Version", valid_595715
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
  var valid_595716 = header.getOrDefault("X-Amz-Date")
  valid_595716 = validateParameter(valid_595716, JString, required = false,
                                 default = nil)
  if valid_595716 != nil:
    section.add "X-Amz-Date", valid_595716
  var valid_595717 = header.getOrDefault("X-Amz-Security-Token")
  valid_595717 = validateParameter(valid_595717, JString, required = false,
                                 default = nil)
  if valid_595717 != nil:
    section.add "X-Amz-Security-Token", valid_595717
  var valid_595718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595718 = validateParameter(valid_595718, JString, required = false,
                                 default = nil)
  if valid_595718 != nil:
    section.add "X-Amz-Content-Sha256", valid_595718
  var valid_595719 = header.getOrDefault("X-Amz-Algorithm")
  valid_595719 = validateParameter(valid_595719, JString, required = false,
                                 default = nil)
  if valid_595719 != nil:
    section.add "X-Amz-Algorithm", valid_595719
  var valid_595720 = header.getOrDefault("X-Amz-Signature")
  valid_595720 = validateParameter(valid_595720, JString, required = false,
                                 default = nil)
  if valid_595720 != nil:
    section.add "X-Amz-Signature", valid_595720
  var valid_595721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595721 = validateParameter(valid_595721, JString, required = false,
                                 default = nil)
  if valid_595721 != nil:
    section.add "X-Amz-SignedHeaders", valid_595721
  var valid_595722 = header.getOrDefault("X-Amz-Credential")
  valid_595722 = validateParameter(valid_595722, JString, required = false,
                                 default = nil)
  if valid_595722 != nil:
    section.add "X-Amz-Credential", valid_595722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595723: Call_GetModifyEventSubscription_595706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595723.validator(path, query, header, formData, body)
  let scheme = call_595723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595723.url(scheme.get, call_595723.host, call_595723.base,
                         call_595723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595723, url, valid)

proc call*(call_595724: Call_GetModifyEventSubscription_595706;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          EventCategories: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   EventCategories: JArray
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_595725 = newJObject()
  add(query_595725, "SourceType", newJString(SourceType))
  add(query_595725, "Enabled", newJBool(Enabled))
  add(query_595725, "Action", newJString(Action))
  add(query_595725, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_595725.add "EventCategories", EventCategories
  add(query_595725, "SubscriptionName", newJString(SubscriptionName))
  add(query_595725, "Version", newJString(Version))
  result = call_595724.call(nil, query_595725, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_595706(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_595707, base: "/",
    url: url_GetModifyEventSubscription_595708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_595766 = ref object of OpenApiRestCall_593421
proc url_PostModifyOptionGroup_595768(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_595767(path: JsonNode; query: JsonNode;
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
  var valid_595769 = query.getOrDefault("Action")
  valid_595769 = validateParameter(valid_595769, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_595769 != nil:
    section.add "Action", valid_595769
  var valid_595770 = query.getOrDefault("Version")
  valid_595770 = validateParameter(valid_595770, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595770 != nil:
    section.add "Version", valid_595770
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
  var valid_595771 = header.getOrDefault("X-Amz-Date")
  valid_595771 = validateParameter(valid_595771, JString, required = false,
                                 default = nil)
  if valid_595771 != nil:
    section.add "X-Amz-Date", valid_595771
  var valid_595772 = header.getOrDefault("X-Amz-Security-Token")
  valid_595772 = validateParameter(valid_595772, JString, required = false,
                                 default = nil)
  if valid_595772 != nil:
    section.add "X-Amz-Security-Token", valid_595772
  var valid_595773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595773 = validateParameter(valid_595773, JString, required = false,
                                 default = nil)
  if valid_595773 != nil:
    section.add "X-Amz-Content-Sha256", valid_595773
  var valid_595774 = header.getOrDefault("X-Amz-Algorithm")
  valid_595774 = validateParameter(valid_595774, JString, required = false,
                                 default = nil)
  if valid_595774 != nil:
    section.add "X-Amz-Algorithm", valid_595774
  var valid_595775 = header.getOrDefault("X-Amz-Signature")
  valid_595775 = validateParameter(valid_595775, JString, required = false,
                                 default = nil)
  if valid_595775 != nil:
    section.add "X-Amz-Signature", valid_595775
  var valid_595776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595776 = validateParameter(valid_595776, JString, required = false,
                                 default = nil)
  if valid_595776 != nil:
    section.add "X-Amz-SignedHeaders", valid_595776
  var valid_595777 = header.getOrDefault("X-Amz-Credential")
  valid_595777 = validateParameter(valid_595777, JString, required = false,
                                 default = nil)
  if valid_595777 != nil:
    section.add "X-Amz-Credential", valid_595777
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_595778 = formData.getOrDefault("OptionsToRemove")
  valid_595778 = validateParameter(valid_595778, JArray, required = false,
                                 default = nil)
  if valid_595778 != nil:
    section.add "OptionsToRemove", valid_595778
  var valid_595779 = formData.getOrDefault("ApplyImmediately")
  valid_595779 = validateParameter(valid_595779, JBool, required = false, default = nil)
  if valid_595779 != nil:
    section.add "ApplyImmediately", valid_595779
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_595780 = formData.getOrDefault("OptionGroupName")
  valid_595780 = validateParameter(valid_595780, JString, required = true,
                                 default = nil)
  if valid_595780 != nil:
    section.add "OptionGroupName", valid_595780
  var valid_595781 = formData.getOrDefault("OptionsToInclude")
  valid_595781 = validateParameter(valid_595781, JArray, required = false,
                                 default = nil)
  if valid_595781 != nil:
    section.add "OptionsToInclude", valid_595781
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595782: Call_PostModifyOptionGroup_595766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595782.validator(path, query, header, formData, body)
  let scheme = call_595782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595782.url(scheme.get, call_595782.host, call_595782.base,
                         call_595782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595782, url, valid)

proc call*(call_595783: Call_PostModifyOptionGroup_595766; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionGroupName: string (required)
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595784 = newJObject()
  var formData_595785 = newJObject()
  if OptionsToRemove != nil:
    formData_595785.add "OptionsToRemove", OptionsToRemove
  add(formData_595785, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_595785, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_595785.add "OptionsToInclude", OptionsToInclude
  add(query_595784, "Action", newJString(Action))
  add(query_595784, "Version", newJString(Version))
  result = call_595783.call(nil, query_595784, nil, formData_595785, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_595766(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_595767, base: "/",
    url: url_PostModifyOptionGroup_595768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_595747 = ref object of OpenApiRestCall_593421
proc url_GetModifyOptionGroup_595749(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_595748(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OptionGroupName: JString (required)
  ##   OptionsToRemove: JArray
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `OptionGroupName` field"
  var valid_595750 = query.getOrDefault("OptionGroupName")
  valid_595750 = validateParameter(valid_595750, JString, required = true,
                                 default = nil)
  if valid_595750 != nil:
    section.add "OptionGroupName", valid_595750
  var valid_595751 = query.getOrDefault("OptionsToRemove")
  valid_595751 = validateParameter(valid_595751, JArray, required = false,
                                 default = nil)
  if valid_595751 != nil:
    section.add "OptionsToRemove", valid_595751
  var valid_595752 = query.getOrDefault("Action")
  valid_595752 = validateParameter(valid_595752, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_595752 != nil:
    section.add "Action", valid_595752
  var valid_595753 = query.getOrDefault("Version")
  valid_595753 = validateParameter(valid_595753, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595753 != nil:
    section.add "Version", valid_595753
  var valid_595754 = query.getOrDefault("ApplyImmediately")
  valid_595754 = validateParameter(valid_595754, JBool, required = false, default = nil)
  if valid_595754 != nil:
    section.add "ApplyImmediately", valid_595754
  var valid_595755 = query.getOrDefault("OptionsToInclude")
  valid_595755 = validateParameter(valid_595755, JArray, required = false,
                                 default = nil)
  if valid_595755 != nil:
    section.add "OptionsToInclude", valid_595755
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
  var valid_595756 = header.getOrDefault("X-Amz-Date")
  valid_595756 = validateParameter(valid_595756, JString, required = false,
                                 default = nil)
  if valid_595756 != nil:
    section.add "X-Amz-Date", valid_595756
  var valid_595757 = header.getOrDefault("X-Amz-Security-Token")
  valid_595757 = validateParameter(valid_595757, JString, required = false,
                                 default = nil)
  if valid_595757 != nil:
    section.add "X-Amz-Security-Token", valid_595757
  var valid_595758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595758 = validateParameter(valid_595758, JString, required = false,
                                 default = nil)
  if valid_595758 != nil:
    section.add "X-Amz-Content-Sha256", valid_595758
  var valid_595759 = header.getOrDefault("X-Amz-Algorithm")
  valid_595759 = validateParameter(valid_595759, JString, required = false,
                                 default = nil)
  if valid_595759 != nil:
    section.add "X-Amz-Algorithm", valid_595759
  var valid_595760 = header.getOrDefault("X-Amz-Signature")
  valid_595760 = validateParameter(valid_595760, JString, required = false,
                                 default = nil)
  if valid_595760 != nil:
    section.add "X-Amz-Signature", valid_595760
  var valid_595761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595761 = validateParameter(valid_595761, JString, required = false,
                                 default = nil)
  if valid_595761 != nil:
    section.add "X-Amz-SignedHeaders", valid_595761
  var valid_595762 = header.getOrDefault("X-Amz-Credential")
  valid_595762 = validateParameter(valid_595762, JString, required = false,
                                 default = nil)
  if valid_595762 != nil:
    section.add "X-Amz-Credential", valid_595762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595763: Call_GetModifyOptionGroup_595747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595763.validator(path, query, header, formData, body)
  let scheme = call_595763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595763.url(scheme.get, call_595763.host, call_595763.base,
                         call_595763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595763, url, valid)

proc call*(call_595764: Call_GetModifyOptionGroup_595747; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-09-09"; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil): Recallable =
  ## getModifyOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionsToRemove: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  var query_595765 = newJObject()
  add(query_595765, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_595765.add "OptionsToRemove", OptionsToRemove
  add(query_595765, "Action", newJString(Action))
  add(query_595765, "Version", newJString(Version))
  add(query_595765, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_595765.add "OptionsToInclude", OptionsToInclude
  result = call_595764.call(nil, query_595765, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_595747(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_595748, base: "/",
    url: url_GetModifyOptionGroup_595749, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_595804 = ref object of OpenApiRestCall_593421
proc url_PostPromoteReadReplica_595806(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_595805(path: JsonNode; query: JsonNode;
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
  var valid_595807 = query.getOrDefault("Action")
  valid_595807 = validateParameter(valid_595807, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_595807 != nil:
    section.add "Action", valid_595807
  var valid_595808 = query.getOrDefault("Version")
  valid_595808 = validateParameter(valid_595808, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595808 != nil:
    section.add "Version", valid_595808
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
  var valid_595809 = header.getOrDefault("X-Amz-Date")
  valid_595809 = validateParameter(valid_595809, JString, required = false,
                                 default = nil)
  if valid_595809 != nil:
    section.add "X-Amz-Date", valid_595809
  var valid_595810 = header.getOrDefault("X-Amz-Security-Token")
  valid_595810 = validateParameter(valid_595810, JString, required = false,
                                 default = nil)
  if valid_595810 != nil:
    section.add "X-Amz-Security-Token", valid_595810
  var valid_595811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595811 = validateParameter(valid_595811, JString, required = false,
                                 default = nil)
  if valid_595811 != nil:
    section.add "X-Amz-Content-Sha256", valid_595811
  var valid_595812 = header.getOrDefault("X-Amz-Algorithm")
  valid_595812 = validateParameter(valid_595812, JString, required = false,
                                 default = nil)
  if valid_595812 != nil:
    section.add "X-Amz-Algorithm", valid_595812
  var valid_595813 = header.getOrDefault("X-Amz-Signature")
  valid_595813 = validateParameter(valid_595813, JString, required = false,
                                 default = nil)
  if valid_595813 != nil:
    section.add "X-Amz-Signature", valid_595813
  var valid_595814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595814 = validateParameter(valid_595814, JString, required = false,
                                 default = nil)
  if valid_595814 != nil:
    section.add "X-Amz-SignedHeaders", valid_595814
  var valid_595815 = header.getOrDefault("X-Amz-Credential")
  valid_595815 = validateParameter(valid_595815, JString, required = false,
                                 default = nil)
  if valid_595815 != nil:
    section.add "X-Amz-Credential", valid_595815
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595816 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595816 = validateParameter(valid_595816, JString, required = true,
                                 default = nil)
  if valid_595816 != nil:
    section.add "DBInstanceIdentifier", valid_595816
  var valid_595817 = formData.getOrDefault("BackupRetentionPeriod")
  valid_595817 = validateParameter(valid_595817, JInt, required = false, default = nil)
  if valid_595817 != nil:
    section.add "BackupRetentionPeriod", valid_595817
  var valid_595818 = formData.getOrDefault("PreferredBackupWindow")
  valid_595818 = validateParameter(valid_595818, JString, required = false,
                                 default = nil)
  if valid_595818 != nil:
    section.add "PreferredBackupWindow", valid_595818
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595819: Call_PostPromoteReadReplica_595804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595819.validator(path, query, header, formData, body)
  let scheme = call_595819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595819.url(scheme.get, call_595819.host, call_595819.base,
                         call_595819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595819, url, valid)

proc call*(call_595820: Call_PostPromoteReadReplica_595804;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_595821 = newJObject()
  var formData_595822 = newJObject()
  add(formData_595822, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595822, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_595821, "Action", newJString(Action))
  add(formData_595822, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_595821, "Version", newJString(Version))
  result = call_595820.call(nil, query_595821, nil, formData_595822, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_595804(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_595805, base: "/",
    url: url_PostPromoteReadReplica_595806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_595786 = ref object of OpenApiRestCall_593421
proc url_GetPromoteReadReplica_595788(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_595787(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   BackupRetentionPeriod: JInt
  ##   Action: JString (required)
  ##   PreferredBackupWindow: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_595789 = query.getOrDefault("BackupRetentionPeriod")
  valid_595789 = validateParameter(valid_595789, JInt, required = false, default = nil)
  if valid_595789 != nil:
    section.add "BackupRetentionPeriod", valid_595789
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595790 = query.getOrDefault("Action")
  valid_595790 = validateParameter(valid_595790, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_595790 != nil:
    section.add "Action", valid_595790
  var valid_595791 = query.getOrDefault("PreferredBackupWindow")
  valid_595791 = validateParameter(valid_595791, JString, required = false,
                                 default = nil)
  if valid_595791 != nil:
    section.add "PreferredBackupWindow", valid_595791
  var valid_595792 = query.getOrDefault("Version")
  valid_595792 = validateParameter(valid_595792, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595792 != nil:
    section.add "Version", valid_595792
  var valid_595793 = query.getOrDefault("DBInstanceIdentifier")
  valid_595793 = validateParameter(valid_595793, JString, required = true,
                                 default = nil)
  if valid_595793 != nil:
    section.add "DBInstanceIdentifier", valid_595793
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
  var valid_595794 = header.getOrDefault("X-Amz-Date")
  valid_595794 = validateParameter(valid_595794, JString, required = false,
                                 default = nil)
  if valid_595794 != nil:
    section.add "X-Amz-Date", valid_595794
  var valid_595795 = header.getOrDefault("X-Amz-Security-Token")
  valid_595795 = validateParameter(valid_595795, JString, required = false,
                                 default = nil)
  if valid_595795 != nil:
    section.add "X-Amz-Security-Token", valid_595795
  var valid_595796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595796 = validateParameter(valid_595796, JString, required = false,
                                 default = nil)
  if valid_595796 != nil:
    section.add "X-Amz-Content-Sha256", valid_595796
  var valid_595797 = header.getOrDefault("X-Amz-Algorithm")
  valid_595797 = validateParameter(valid_595797, JString, required = false,
                                 default = nil)
  if valid_595797 != nil:
    section.add "X-Amz-Algorithm", valid_595797
  var valid_595798 = header.getOrDefault("X-Amz-Signature")
  valid_595798 = validateParameter(valid_595798, JString, required = false,
                                 default = nil)
  if valid_595798 != nil:
    section.add "X-Amz-Signature", valid_595798
  var valid_595799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595799 = validateParameter(valid_595799, JString, required = false,
                                 default = nil)
  if valid_595799 != nil:
    section.add "X-Amz-SignedHeaders", valid_595799
  var valid_595800 = header.getOrDefault("X-Amz-Credential")
  valid_595800 = validateParameter(valid_595800, JString, required = false,
                                 default = nil)
  if valid_595800 != nil:
    section.add "X-Amz-Credential", valid_595800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595801: Call_GetPromoteReadReplica_595786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595801.validator(path, query, header, formData, body)
  let scheme = call_595801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595801.url(scheme.get, call_595801.host, call_595801.base,
                         call_595801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595801, url, valid)

proc call*(call_595802: Call_GetPromoteReadReplica_595786;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_595803 = newJObject()
  add(query_595803, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_595803, "Action", newJString(Action))
  add(query_595803, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_595803, "Version", newJString(Version))
  add(query_595803, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_595802.call(nil, query_595803, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_595786(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_595787, base: "/",
    url: url_GetPromoteReadReplica_595788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_595842 = ref object of OpenApiRestCall_593421
proc url_PostPurchaseReservedDBInstancesOffering_595844(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_595843(path: JsonNode;
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
  var valid_595845 = query.getOrDefault("Action")
  valid_595845 = validateParameter(valid_595845, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_595845 != nil:
    section.add "Action", valid_595845
  var valid_595846 = query.getOrDefault("Version")
  valid_595846 = validateParameter(valid_595846, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595846 != nil:
    section.add "Version", valid_595846
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
  var valid_595847 = header.getOrDefault("X-Amz-Date")
  valid_595847 = validateParameter(valid_595847, JString, required = false,
                                 default = nil)
  if valid_595847 != nil:
    section.add "X-Amz-Date", valid_595847
  var valid_595848 = header.getOrDefault("X-Amz-Security-Token")
  valid_595848 = validateParameter(valid_595848, JString, required = false,
                                 default = nil)
  if valid_595848 != nil:
    section.add "X-Amz-Security-Token", valid_595848
  var valid_595849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595849 = validateParameter(valid_595849, JString, required = false,
                                 default = nil)
  if valid_595849 != nil:
    section.add "X-Amz-Content-Sha256", valid_595849
  var valid_595850 = header.getOrDefault("X-Amz-Algorithm")
  valid_595850 = validateParameter(valid_595850, JString, required = false,
                                 default = nil)
  if valid_595850 != nil:
    section.add "X-Amz-Algorithm", valid_595850
  var valid_595851 = header.getOrDefault("X-Amz-Signature")
  valid_595851 = validateParameter(valid_595851, JString, required = false,
                                 default = nil)
  if valid_595851 != nil:
    section.add "X-Amz-Signature", valid_595851
  var valid_595852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595852 = validateParameter(valid_595852, JString, required = false,
                                 default = nil)
  if valid_595852 != nil:
    section.add "X-Amz-SignedHeaders", valid_595852
  var valid_595853 = header.getOrDefault("X-Amz-Credential")
  valid_595853 = validateParameter(valid_595853, JString, required = false,
                                 default = nil)
  if valid_595853 != nil:
    section.add "X-Amz-Credential", valid_595853
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_595854 = formData.getOrDefault("ReservedDBInstanceId")
  valid_595854 = validateParameter(valid_595854, JString, required = false,
                                 default = nil)
  if valid_595854 != nil:
    section.add "ReservedDBInstanceId", valid_595854
  var valid_595855 = formData.getOrDefault("Tags")
  valid_595855 = validateParameter(valid_595855, JArray, required = false,
                                 default = nil)
  if valid_595855 != nil:
    section.add "Tags", valid_595855
  var valid_595856 = formData.getOrDefault("DBInstanceCount")
  valid_595856 = validateParameter(valid_595856, JInt, required = false, default = nil)
  if valid_595856 != nil:
    section.add "DBInstanceCount", valid_595856
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_595857 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595857 = validateParameter(valid_595857, JString, required = true,
                                 default = nil)
  if valid_595857 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595857
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595858: Call_PostPurchaseReservedDBInstancesOffering_595842;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595858.validator(path, query, header, formData, body)
  let scheme = call_595858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595858.url(scheme.get, call_595858.host, call_595858.base,
                         call_595858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595858, url, valid)

proc call*(call_595859: Call_PostPurchaseReservedDBInstancesOffering_595842;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = ""; Tags: JsonNode = nil;
          DBInstanceCount: int = 0;
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-09-09"): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Tags: JArray
  ##   DBInstanceCount: int
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_595860 = newJObject()
  var formData_595861 = newJObject()
  add(formData_595861, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_595861.add "Tags", Tags
  add(formData_595861, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_595860, "Action", newJString(Action))
  add(formData_595861, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595860, "Version", newJString(Version))
  result = call_595859.call(nil, query_595860, nil, formData_595861, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_595842(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_595843, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_595844,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_595823 = ref object of OpenApiRestCall_593421
proc url_GetPurchaseReservedDBInstancesOffering_595825(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_595824(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceCount: JInt
  ##   Tags: JArray
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_595826 = query.getOrDefault("DBInstanceCount")
  valid_595826 = validateParameter(valid_595826, JInt, required = false, default = nil)
  if valid_595826 != nil:
    section.add "DBInstanceCount", valid_595826
  var valid_595827 = query.getOrDefault("Tags")
  valid_595827 = validateParameter(valid_595827, JArray, required = false,
                                 default = nil)
  if valid_595827 != nil:
    section.add "Tags", valid_595827
  var valid_595828 = query.getOrDefault("ReservedDBInstanceId")
  valid_595828 = validateParameter(valid_595828, JString, required = false,
                                 default = nil)
  if valid_595828 != nil:
    section.add "ReservedDBInstanceId", valid_595828
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_595829 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595829 = validateParameter(valid_595829, JString, required = true,
                                 default = nil)
  if valid_595829 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595829
  var valid_595830 = query.getOrDefault("Action")
  valid_595830 = validateParameter(valid_595830, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_595830 != nil:
    section.add "Action", valid_595830
  var valid_595831 = query.getOrDefault("Version")
  valid_595831 = validateParameter(valid_595831, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595831 != nil:
    section.add "Version", valid_595831
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
  var valid_595832 = header.getOrDefault("X-Amz-Date")
  valid_595832 = validateParameter(valid_595832, JString, required = false,
                                 default = nil)
  if valid_595832 != nil:
    section.add "X-Amz-Date", valid_595832
  var valid_595833 = header.getOrDefault("X-Amz-Security-Token")
  valid_595833 = validateParameter(valid_595833, JString, required = false,
                                 default = nil)
  if valid_595833 != nil:
    section.add "X-Amz-Security-Token", valid_595833
  var valid_595834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595834 = validateParameter(valid_595834, JString, required = false,
                                 default = nil)
  if valid_595834 != nil:
    section.add "X-Amz-Content-Sha256", valid_595834
  var valid_595835 = header.getOrDefault("X-Amz-Algorithm")
  valid_595835 = validateParameter(valid_595835, JString, required = false,
                                 default = nil)
  if valid_595835 != nil:
    section.add "X-Amz-Algorithm", valid_595835
  var valid_595836 = header.getOrDefault("X-Amz-Signature")
  valid_595836 = validateParameter(valid_595836, JString, required = false,
                                 default = nil)
  if valid_595836 != nil:
    section.add "X-Amz-Signature", valid_595836
  var valid_595837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595837 = validateParameter(valid_595837, JString, required = false,
                                 default = nil)
  if valid_595837 != nil:
    section.add "X-Amz-SignedHeaders", valid_595837
  var valid_595838 = header.getOrDefault("X-Amz-Credential")
  valid_595838 = validateParameter(valid_595838, JString, required = false,
                                 default = nil)
  if valid_595838 != nil:
    section.add "X-Amz-Credential", valid_595838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595839: Call_GetPurchaseReservedDBInstancesOffering_595823;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595839.validator(path, query, header, formData, body)
  let scheme = call_595839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595839.url(scheme.get, call_595839.host, call_595839.base,
                         call_595839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595839, url, valid)

proc call*(call_595840: Call_GetPurchaseReservedDBInstancesOffering_595823;
          ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
          Tags: JsonNode = nil; ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-09-09"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   Tags: JArray
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595841 = newJObject()
  add(query_595841, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_595841.add "Tags", Tags
  add(query_595841, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_595841, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595841, "Action", newJString(Action))
  add(query_595841, "Version", newJString(Version))
  result = call_595840.call(nil, query_595841, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_595823(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_595824, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_595825,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_595879 = ref object of OpenApiRestCall_593421
proc url_PostRebootDBInstance_595881(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_595880(path: JsonNode; query: JsonNode;
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
  var valid_595882 = query.getOrDefault("Action")
  valid_595882 = validateParameter(valid_595882, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_595882 != nil:
    section.add "Action", valid_595882
  var valid_595883 = query.getOrDefault("Version")
  valid_595883 = validateParameter(valid_595883, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595883 != nil:
    section.add "Version", valid_595883
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
  var valid_595884 = header.getOrDefault("X-Amz-Date")
  valid_595884 = validateParameter(valid_595884, JString, required = false,
                                 default = nil)
  if valid_595884 != nil:
    section.add "X-Amz-Date", valid_595884
  var valid_595885 = header.getOrDefault("X-Amz-Security-Token")
  valid_595885 = validateParameter(valid_595885, JString, required = false,
                                 default = nil)
  if valid_595885 != nil:
    section.add "X-Amz-Security-Token", valid_595885
  var valid_595886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595886 = validateParameter(valid_595886, JString, required = false,
                                 default = nil)
  if valid_595886 != nil:
    section.add "X-Amz-Content-Sha256", valid_595886
  var valid_595887 = header.getOrDefault("X-Amz-Algorithm")
  valid_595887 = validateParameter(valid_595887, JString, required = false,
                                 default = nil)
  if valid_595887 != nil:
    section.add "X-Amz-Algorithm", valid_595887
  var valid_595888 = header.getOrDefault("X-Amz-Signature")
  valid_595888 = validateParameter(valid_595888, JString, required = false,
                                 default = nil)
  if valid_595888 != nil:
    section.add "X-Amz-Signature", valid_595888
  var valid_595889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595889 = validateParameter(valid_595889, JString, required = false,
                                 default = nil)
  if valid_595889 != nil:
    section.add "X-Amz-SignedHeaders", valid_595889
  var valid_595890 = header.getOrDefault("X-Amz-Credential")
  valid_595890 = validateParameter(valid_595890, JString, required = false,
                                 default = nil)
  if valid_595890 != nil:
    section.add "X-Amz-Credential", valid_595890
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595891 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595891 = validateParameter(valid_595891, JString, required = true,
                                 default = nil)
  if valid_595891 != nil:
    section.add "DBInstanceIdentifier", valid_595891
  var valid_595892 = formData.getOrDefault("ForceFailover")
  valid_595892 = validateParameter(valid_595892, JBool, required = false, default = nil)
  if valid_595892 != nil:
    section.add "ForceFailover", valid_595892
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595893: Call_PostRebootDBInstance_595879; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595893.validator(path, query, header, formData, body)
  let scheme = call_595893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595893.url(scheme.get, call_595893.host, call_595893.base,
                         call_595893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595893, url, valid)

proc call*(call_595894: Call_PostRebootDBInstance_595879;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_595895 = newJObject()
  var formData_595896 = newJObject()
  add(formData_595896, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595895, "Action", newJString(Action))
  add(formData_595896, "ForceFailover", newJBool(ForceFailover))
  add(query_595895, "Version", newJString(Version))
  result = call_595894.call(nil, query_595895, nil, formData_595896, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_595879(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_595880, base: "/",
    url: url_PostRebootDBInstance_595881, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_595862 = ref object of OpenApiRestCall_593421
proc url_GetRebootDBInstance_595864(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_595863(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ForceFailover: JBool
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595865 = query.getOrDefault("Action")
  valid_595865 = validateParameter(valid_595865, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_595865 != nil:
    section.add "Action", valid_595865
  var valid_595866 = query.getOrDefault("ForceFailover")
  valid_595866 = validateParameter(valid_595866, JBool, required = false, default = nil)
  if valid_595866 != nil:
    section.add "ForceFailover", valid_595866
  var valid_595867 = query.getOrDefault("Version")
  valid_595867 = validateParameter(valid_595867, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595867 != nil:
    section.add "Version", valid_595867
  var valid_595868 = query.getOrDefault("DBInstanceIdentifier")
  valid_595868 = validateParameter(valid_595868, JString, required = true,
                                 default = nil)
  if valid_595868 != nil:
    section.add "DBInstanceIdentifier", valid_595868
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
  var valid_595869 = header.getOrDefault("X-Amz-Date")
  valid_595869 = validateParameter(valid_595869, JString, required = false,
                                 default = nil)
  if valid_595869 != nil:
    section.add "X-Amz-Date", valid_595869
  var valid_595870 = header.getOrDefault("X-Amz-Security-Token")
  valid_595870 = validateParameter(valid_595870, JString, required = false,
                                 default = nil)
  if valid_595870 != nil:
    section.add "X-Amz-Security-Token", valid_595870
  var valid_595871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595871 = validateParameter(valid_595871, JString, required = false,
                                 default = nil)
  if valid_595871 != nil:
    section.add "X-Amz-Content-Sha256", valid_595871
  var valid_595872 = header.getOrDefault("X-Amz-Algorithm")
  valid_595872 = validateParameter(valid_595872, JString, required = false,
                                 default = nil)
  if valid_595872 != nil:
    section.add "X-Amz-Algorithm", valid_595872
  var valid_595873 = header.getOrDefault("X-Amz-Signature")
  valid_595873 = validateParameter(valid_595873, JString, required = false,
                                 default = nil)
  if valid_595873 != nil:
    section.add "X-Amz-Signature", valid_595873
  var valid_595874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595874 = validateParameter(valid_595874, JString, required = false,
                                 default = nil)
  if valid_595874 != nil:
    section.add "X-Amz-SignedHeaders", valid_595874
  var valid_595875 = header.getOrDefault("X-Amz-Credential")
  valid_595875 = validateParameter(valid_595875, JString, required = false,
                                 default = nil)
  if valid_595875 != nil:
    section.add "X-Amz-Credential", valid_595875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595876: Call_GetRebootDBInstance_595862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595876.validator(path, query, header, formData, body)
  let scheme = call_595876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595876.url(scheme.get, call_595876.host, call_595876.base,
                         call_595876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595876, url, valid)

proc call*(call_595877: Call_GetRebootDBInstance_595862;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_595878 = newJObject()
  add(query_595878, "Action", newJString(Action))
  add(query_595878, "ForceFailover", newJBool(ForceFailover))
  add(query_595878, "Version", newJString(Version))
  add(query_595878, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_595877.call(nil, query_595878, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_595862(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_595863, base: "/",
    url: url_GetRebootDBInstance_595864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_595914 = ref object of OpenApiRestCall_593421
proc url_PostRemoveSourceIdentifierFromSubscription_595916(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_595915(path: JsonNode;
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
  var valid_595917 = query.getOrDefault("Action")
  valid_595917 = validateParameter(valid_595917, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_595917 != nil:
    section.add "Action", valid_595917
  var valid_595918 = query.getOrDefault("Version")
  valid_595918 = validateParameter(valid_595918, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595918 != nil:
    section.add "Version", valid_595918
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
  var valid_595919 = header.getOrDefault("X-Amz-Date")
  valid_595919 = validateParameter(valid_595919, JString, required = false,
                                 default = nil)
  if valid_595919 != nil:
    section.add "X-Amz-Date", valid_595919
  var valid_595920 = header.getOrDefault("X-Amz-Security-Token")
  valid_595920 = validateParameter(valid_595920, JString, required = false,
                                 default = nil)
  if valid_595920 != nil:
    section.add "X-Amz-Security-Token", valid_595920
  var valid_595921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595921 = validateParameter(valid_595921, JString, required = false,
                                 default = nil)
  if valid_595921 != nil:
    section.add "X-Amz-Content-Sha256", valid_595921
  var valid_595922 = header.getOrDefault("X-Amz-Algorithm")
  valid_595922 = validateParameter(valid_595922, JString, required = false,
                                 default = nil)
  if valid_595922 != nil:
    section.add "X-Amz-Algorithm", valid_595922
  var valid_595923 = header.getOrDefault("X-Amz-Signature")
  valid_595923 = validateParameter(valid_595923, JString, required = false,
                                 default = nil)
  if valid_595923 != nil:
    section.add "X-Amz-Signature", valid_595923
  var valid_595924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595924 = validateParameter(valid_595924, JString, required = false,
                                 default = nil)
  if valid_595924 != nil:
    section.add "X-Amz-SignedHeaders", valid_595924
  var valid_595925 = header.getOrDefault("X-Amz-Credential")
  valid_595925 = validateParameter(valid_595925, JString, required = false,
                                 default = nil)
  if valid_595925 != nil:
    section.add "X-Amz-Credential", valid_595925
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_595926 = formData.getOrDefault("SourceIdentifier")
  valid_595926 = validateParameter(valid_595926, JString, required = true,
                                 default = nil)
  if valid_595926 != nil:
    section.add "SourceIdentifier", valid_595926
  var valid_595927 = formData.getOrDefault("SubscriptionName")
  valid_595927 = validateParameter(valid_595927, JString, required = true,
                                 default = nil)
  if valid_595927 != nil:
    section.add "SubscriptionName", valid_595927
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595928: Call_PostRemoveSourceIdentifierFromSubscription_595914;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595928.validator(path, query, header, formData, body)
  let scheme = call_595928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595928.url(scheme.get, call_595928.host, call_595928.base,
                         call_595928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595928, url, valid)

proc call*(call_595929: Call_PostRemoveSourceIdentifierFromSubscription_595914;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595930 = newJObject()
  var formData_595931 = newJObject()
  add(formData_595931, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_595931, "SubscriptionName", newJString(SubscriptionName))
  add(query_595930, "Action", newJString(Action))
  add(query_595930, "Version", newJString(Version))
  result = call_595929.call(nil, query_595930, nil, formData_595931, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_595914(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_595915,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_595916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_595897 = ref object of OpenApiRestCall_593421
proc url_GetRemoveSourceIdentifierFromSubscription_595899(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_595898(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595900 = query.getOrDefault("Action")
  valid_595900 = validateParameter(valid_595900, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_595900 != nil:
    section.add "Action", valid_595900
  var valid_595901 = query.getOrDefault("SourceIdentifier")
  valid_595901 = validateParameter(valid_595901, JString, required = true,
                                 default = nil)
  if valid_595901 != nil:
    section.add "SourceIdentifier", valid_595901
  var valid_595902 = query.getOrDefault("SubscriptionName")
  valid_595902 = validateParameter(valid_595902, JString, required = true,
                                 default = nil)
  if valid_595902 != nil:
    section.add "SubscriptionName", valid_595902
  var valid_595903 = query.getOrDefault("Version")
  valid_595903 = validateParameter(valid_595903, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595903 != nil:
    section.add "Version", valid_595903
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
  var valid_595904 = header.getOrDefault("X-Amz-Date")
  valid_595904 = validateParameter(valid_595904, JString, required = false,
                                 default = nil)
  if valid_595904 != nil:
    section.add "X-Amz-Date", valid_595904
  var valid_595905 = header.getOrDefault("X-Amz-Security-Token")
  valid_595905 = validateParameter(valid_595905, JString, required = false,
                                 default = nil)
  if valid_595905 != nil:
    section.add "X-Amz-Security-Token", valid_595905
  var valid_595906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595906 = validateParameter(valid_595906, JString, required = false,
                                 default = nil)
  if valid_595906 != nil:
    section.add "X-Amz-Content-Sha256", valid_595906
  var valid_595907 = header.getOrDefault("X-Amz-Algorithm")
  valid_595907 = validateParameter(valid_595907, JString, required = false,
                                 default = nil)
  if valid_595907 != nil:
    section.add "X-Amz-Algorithm", valid_595907
  var valid_595908 = header.getOrDefault("X-Amz-Signature")
  valid_595908 = validateParameter(valid_595908, JString, required = false,
                                 default = nil)
  if valid_595908 != nil:
    section.add "X-Amz-Signature", valid_595908
  var valid_595909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595909 = validateParameter(valid_595909, JString, required = false,
                                 default = nil)
  if valid_595909 != nil:
    section.add "X-Amz-SignedHeaders", valid_595909
  var valid_595910 = header.getOrDefault("X-Amz-Credential")
  valid_595910 = validateParameter(valid_595910, JString, required = false,
                                 default = nil)
  if valid_595910 != nil:
    section.add "X-Amz-Credential", valid_595910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595911: Call_GetRemoveSourceIdentifierFromSubscription_595897;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595911.validator(path, query, header, formData, body)
  let scheme = call_595911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595911.url(scheme.get, call_595911.host, call_595911.base,
                         call_595911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595911, url, valid)

proc call*(call_595912: Call_GetRemoveSourceIdentifierFromSubscription_595897;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_595913 = newJObject()
  add(query_595913, "Action", newJString(Action))
  add(query_595913, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_595913, "SubscriptionName", newJString(SubscriptionName))
  add(query_595913, "Version", newJString(Version))
  result = call_595912.call(nil, query_595913, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_595897(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_595898,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_595899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_595949 = ref object of OpenApiRestCall_593421
proc url_PostRemoveTagsFromResource_595951(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_595950(path: JsonNode; query: JsonNode;
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
  var valid_595952 = query.getOrDefault("Action")
  valid_595952 = validateParameter(valid_595952, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_595952 != nil:
    section.add "Action", valid_595952
  var valid_595953 = query.getOrDefault("Version")
  valid_595953 = validateParameter(valid_595953, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595953 != nil:
    section.add "Version", valid_595953
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
  var valid_595954 = header.getOrDefault("X-Amz-Date")
  valid_595954 = validateParameter(valid_595954, JString, required = false,
                                 default = nil)
  if valid_595954 != nil:
    section.add "X-Amz-Date", valid_595954
  var valid_595955 = header.getOrDefault("X-Amz-Security-Token")
  valid_595955 = validateParameter(valid_595955, JString, required = false,
                                 default = nil)
  if valid_595955 != nil:
    section.add "X-Amz-Security-Token", valid_595955
  var valid_595956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595956 = validateParameter(valid_595956, JString, required = false,
                                 default = nil)
  if valid_595956 != nil:
    section.add "X-Amz-Content-Sha256", valid_595956
  var valid_595957 = header.getOrDefault("X-Amz-Algorithm")
  valid_595957 = validateParameter(valid_595957, JString, required = false,
                                 default = nil)
  if valid_595957 != nil:
    section.add "X-Amz-Algorithm", valid_595957
  var valid_595958 = header.getOrDefault("X-Amz-Signature")
  valid_595958 = validateParameter(valid_595958, JString, required = false,
                                 default = nil)
  if valid_595958 != nil:
    section.add "X-Amz-Signature", valid_595958
  var valid_595959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595959 = validateParameter(valid_595959, JString, required = false,
                                 default = nil)
  if valid_595959 != nil:
    section.add "X-Amz-SignedHeaders", valid_595959
  var valid_595960 = header.getOrDefault("X-Amz-Credential")
  valid_595960 = validateParameter(valid_595960, JString, required = false,
                                 default = nil)
  if valid_595960 != nil:
    section.add "X-Amz-Credential", valid_595960
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_595961 = formData.getOrDefault("TagKeys")
  valid_595961 = validateParameter(valid_595961, JArray, required = true, default = nil)
  if valid_595961 != nil:
    section.add "TagKeys", valid_595961
  var valid_595962 = formData.getOrDefault("ResourceName")
  valid_595962 = validateParameter(valid_595962, JString, required = true,
                                 default = nil)
  if valid_595962 != nil:
    section.add "ResourceName", valid_595962
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595963: Call_PostRemoveTagsFromResource_595949; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595963.validator(path, query, header, formData, body)
  let scheme = call_595963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595963.url(scheme.get, call_595963.host, call_595963.base,
                         call_595963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595963, url, valid)

proc call*(call_595964: Call_PostRemoveTagsFromResource_595949; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_595965 = newJObject()
  var formData_595966 = newJObject()
  add(query_595965, "Action", newJString(Action))
  if TagKeys != nil:
    formData_595966.add "TagKeys", TagKeys
  add(formData_595966, "ResourceName", newJString(ResourceName))
  add(query_595965, "Version", newJString(Version))
  result = call_595964.call(nil, query_595965, nil, formData_595966, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_595949(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_595950, base: "/",
    url: url_PostRemoveTagsFromResource_595951,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_595932 = ref object of OpenApiRestCall_593421
proc url_GetRemoveTagsFromResource_595934(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_595933(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  ##   TagKeys: JArray (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_595935 = query.getOrDefault("ResourceName")
  valid_595935 = validateParameter(valid_595935, JString, required = true,
                                 default = nil)
  if valid_595935 != nil:
    section.add "ResourceName", valid_595935
  var valid_595936 = query.getOrDefault("Action")
  valid_595936 = validateParameter(valid_595936, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_595936 != nil:
    section.add "Action", valid_595936
  var valid_595937 = query.getOrDefault("TagKeys")
  valid_595937 = validateParameter(valid_595937, JArray, required = true, default = nil)
  if valid_595937 != nil:
    section.add "TagKeys", valid_595937
  var valid_595938 = query.getOrDefault("Version")
  valid_595938 = validateParameter(valid_595938, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595938 != nil:
    section.add "Version", valid_595938
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
  var valid_595939 = header.getOrDefault("X-Amz-Date")
  valid_595939 = validateParameter(valid_595939, JString, required = false,
                                 default = nil)
  if valid_595939 != nil:
    section.add "X-Amz-Date", valid_595939
  var valid_595940 = header.getOrDefault("X-Amz-Security-Token")
  valid_595940 = validateParameter(valid_595940, JString, required = false,
                                 default = nil)
  if valid_595940 != nil:
    section.add "X-Amz-Security-Token", valid_595940
  var valid_595941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595941 = validateParameter(valid_595941, JString, required = false,
                                 default = nil)
  if valid_595941 != nil:
    section.add "X-Amz-Content-Sha256", valid_595941
  var valid_595942 = header.getOrDefault("X-Amz-Algorithm")
  valid_595942 = validateParameter(valid_595942, JString, required = false,
                                 default = nil)
  if valid_595942 != nil:
    section.add "X-Amz-Algorithm", valid_595942
  var valid_595943 = header.getOrDefault("X-Amz-Signature")
  valid_595943 = validateParameter(valid_595943, JString, required = false,
                                 default = nil)
  if valid_595943 != nil:
    section.add "X-Amz-Signature", valid_595943
  var valid_595944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595944 = validateParameter(valid_595944, JString, required = false,
                                 default = nil)
  if valid_595944 != nil:
    section.add "X-Amz-SignedHeaders", valid_595944
  var valid_595945 = header.getOrDefault("X-Amz-Credential")
  valid_595945 = validateParameter(valid_595945, JString, required = false,
                                 default = nil)
  if valid_595945 != nil:
    section.add "X-Amz-Credential", valid_595945
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595946: Call_GetRemoveTagsFromResource_595932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595946.validator(path, query, header, formData, body)
  let scheme = call_595946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595946.url(scheme.get, call_595946.host, call_595946.base,
                         call_595946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595946, url, valid)

proc call*(call_595947: Call_GetRemoveTagsFromResource_595932;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-09-09"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_595948 = newJObject()
  add(query_595948, "ResourceName", newJString(ResourceName))
  add(query_595948, "Action", newJString(Action))
  if TagKeys != nil:
    query_595948.add "TagKeys", TagKeys
  add(query_595948, "Version", newJString(Version))
  result = call_595947.call(nil, query_595948, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_595932(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_595933, base: "/",
    url: url_GetRemoveTagsFromResource_595934,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_595985 = ref object of OpenApiRestCall_593421
proc url_PostResetDBParameterGroup_595987(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_595986(path: JsonNode; query: JsonNode;
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
  var valid_595988 = query.getOrDefault("Action")
  valid_595988 = validateParameter(valid_595988, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_595988 != nil:
    section.add "Action", valid_595988
  var valid_595989 = query.getOrDefault("Version")
  valid_595989 = validateParameter(valid_595989, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595989 != nil:
    section.add "Version", valid_595989
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
  var valid_595990 = header.getOrDefault("X-Amz-Date")
  valid_595990 = validateParameter(valid_595990, JString, required = false,
                                 default = nil)
  if valid_595990 != nil:
    section.add "X-Amz-Date", valid_595990
  var valid_595991 = header.getOrDefault("X-Amz-Security-Token")
  valid_595991 = validateParameter(valid_595991, JString, required = false,
                                 default = nil)
  if valid_595991 != nil:
    section.add "X-Amz-Security-Token", valid_595991
  var valid_595992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595992 = validateParameter(valid_595992, JString, required = false,
                                 default = nil)
  if valid_595992 != nil:
    section.add "X-Amz-Content-Sha256", valid_595992
  var valid_595993 = header.getOrDefault("X-Amz-Algorithm")
  valid_595993 = validateParameter(valid_595993, JString, required = false,
                                 default = nil)
  if valid_595993 != nil:
    section.add "X-Amz-Algorithm", valid_595993
  var valid_595994 = header.getOrDefault("X-Amz-Signature")
  valid_595994 = validateParameter(valid_595994, JString, required = false,
                                 default = nil)
  if valid_595994 != nil:
    section.add "X-Amz-Signature", valid_595994
  var valid_595995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595995 = validateParameter(valid_595995, JString, required = false,
                                 default = nil)
  if valid_595995 != nil:
    section.add "X-Amz-SignedHeaders", valid_595995
  var valid_595996 = header.getOrDefault("X-Amz-Credential")
  valid_595996 = validateParameter(valid_595996, JString, required = false,
                                 default = nil)
  if valid_595996 != nil:
    section.add "X-Amz-Credential", valid_595996
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_595997 = formData.getOrDefault("DBParameterGroupName")
  valid_595997 = validateParameter(valid_595997, JString, required = true,
                                 default = nil)
  if valid_595997 != nil:
    section.add "DBParameterGroupName", valid_595997
  var valid_595998 = formData.getOrDefault("Parameters")
  valid_595998 = validateParameter(valid_595998, JArray, required = false,
                                 default = nil)
  if valid_595998 != nil:
    section.add "Parameters", valid_595998
  var valid_595999 = formData.getOrDefault("ResetAllParameters")
  valid_595999 = validateParameter(valid_595999, JBool, required = false, default = nil)
  if valid_595999 != nil:
    section.add "ResetAllParameters", valid_595999
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596000: Call_PostResetDBParameterGroup_595985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_596000.validator(path, query, header, formData, body)
  let scheme = call_596000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596000.url(scheme.get, call_596000.host, call_596000.base,
                         call_596000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596000, url, valid)

proc call*(call_596001: Call_PostResetDBParameterGroup_595985;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_596002 = newJObject()
  var formData_596003 = newJObject()
  add(formData_596003, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_596003.add "Parameters", Parameters
  add(query_596002, "Action", newJString(Action))
  add(formData_596003, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_596002, "Version", newJString(Version))
  result = call_596001.call(nil, query_596002, nil, formData_596003, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_595985(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_595986, base: "/",
    url: url_PostResetDBParameterGroup_595987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_595967 = ref object of OpenApiRestCall_593421
proc url_GetResetDBParameterGroup_595969(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_595968(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   Action: JString (required)
  ##   ResetAllParameters: JBool
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_595970 = query.getOrDefault("DBParameterGroupName")
  valid_595970 = validateParameter(valid_595970, JString, required = true,
                                 default = nil)
  if valid_595970 != nil:
    section.add "DBParameterGroupName", valid_595970
  var valid_595971 = query.getOrDefault("Parameters")
  valid_595971 = validateParameter(valid_595971, JArray, required = false,
                                 default = nil)
  if valid_595971 != nil:
    section.add "Parameters", valid_595971
  var valid_595972 = query.getOrDefault("Action")
  valid_595972 = validateParameter(valid_595972, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_595972 != nil:
    section.add "Action", valid_595972
  var valid_595973 = query.getOrDefault("ResetAllParameters")
  valid_595973 = validateParameter(valid_595973, JBool, required = false, default = nil)
  if valid_595973 != nil:
    section.add "ResetAllParameters", valid_595973
  var valid_595974 = query.getOrDefault("Version")
  valid_595974 = validateParameter(valid_595974, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595974 != nil:
    section.add "Version", valid_595974
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
  var valid_595975 = header.getOrDefault("X-Amz-Date")
  valid_595975 = validateParameter(valid_595975, JString, required = false,
                                 default = nil)
  if valid_595975 != nil:
    section.add "X-Amz-Date", valid_595975
  var valid_595976 = header.getOrDefault("X-Amz-Security-Token")
  valid_595976 = validateParameter(valid_595976, JString, required = false,
                                 default = nil)
  if valid_595976 != nil:
    section.add "X-Amz-Security-Token", valid_595976
  var valid_595977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595977 = validateParameter(valid_595977, JString, required = false,
                                 default = nil)
  if valid_595977 != nil:
    section.add "X-Amz-Content-Sha256", valid_595977
  var valid_595978 = header.getOrDefault("X-Amz-Algorithm")
  valid_595978 = validateParameter(valid_595978, JString, required = false,
                                 default = nil)
  if valid_595978 != nil:
    section.add "X-Amz-Algorithm", valid_595978
  var valid_595979 = header.getOrDefault("X-Amz-Signature")
  valid_595979 = validateParameter(valid_595979, JString, required = false,
                                 default = nil)
  if valid_595979 != nil:
    section.add "X-Amz-Signature", valid_595979
  var valid_595980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595980 = validateParameter(valid_595980, JString, required = false,
                                 default = nil)
  if valid_595980 != nil:
    section.add "X-Amz-SignedHeaders", valid_595980
  var valid_595981 = header.getOrDefault("X-Amz-Credential")
  valid_595981 = validateParameter(valid_595981, JString, required = false,
                                 default = nil)
  if valid_595981 != nil:
    section.add "X-Amz-Credential", valid_595981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595982: Call_GetResetDBParameterGroup_595967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595982.validator(path, query, header, formData, body)
  let scheme = call_595982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595982.url(scheme.get, call_595982.host, call_595982.base,
                         call_595982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595982, url, valid)

proc call*(call_595983: Call_GetResetDBParameterGroup_595967;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_595984 = newJObject()
  add(query_595984, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_595984.add "Parameters", Parameters
  add(query_595984, "Action", newJString(Action))
  add(query_595984, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_595984, "Version", newJString(Version))
  result = call_595983.call(nil, query_595984, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_595967(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_595968, base: "/",
    url: url_GetResetDBParameterGroup_595969, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_596034 = ref object of OpenApiRestCall_593421
proc url_PostRestoreDBInstanceFromDBSnapshot_596036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_596035(path: JsonNode;
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
  var valid_596037 = query.getOrDefault("Action")
  valid_596037 = validateParameter(valid_596037, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_596037 != nil:
    section.add "Action", valid_596037
  var valid_596038 = query.getOrDefault("Version")
  valid_596038 = validateParameter(valid_596038, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_596038 != nil:
    section.add "Version", valid_596038
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
  var valid_596039 = header.getOrDefault("X-Amz-Date")
  valid_596039 = validateParameter(valid_596039, JString, required = false,
                                 default = nil)
  if valid_596039 != nil:
    section.add "X-Amz-Date", valid_596039
  var valid_596040 = header.getOrDefault("X-Amz-Security-Token")
  valid_596040 = validateParameter(valid_596040, JString, required = false,
                                 default = nil)
  if valid_596040 != nil:
    section.add "X-Amz-Security-Token", valid_596040
  var valid_596041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596041 = validateParameter(valid_596041, JString, required = false,
                                 default = nil)
  if valid_596041 != nil:
    section.add "X-Amz-Content-Sha256", valid_596041
  var valid_596042 = header.getOrDefault("X-Amz-Algorithm")
  valid_596042 = validateParameter(valid_596042, JString, required = false,
                                 default = nil)
  if valid_596042 != nil:
    section.add "X-Amz-Algorithm", valid_596042
  var valid_596043 = header.getOrDefault("X-Amz-Signature")
  valid_596043 = validateParameter(valid_596043, JString, required = false,
                                 default = nil)
  if valid_596043 != nil:
    section.add "X-Amz-Signature", valid_596043
  var valid_596044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596044 = validateParameter(valid_596044, JString, required = false,
                                 default = nil)
  if valid_596044 != nil:
    section.add "X-Amz-SignedHeaders", valid_596044
  var valid_596045 = header.getOrDefault("X-Amz-Credential")
  valid_596045 = validateParameter(valid_596045, JString, required = false,
                                 default = nil)
  if valid_596045 != nil:
    section.add "X-Amz-Credential", valid_596045
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   Engine: JString
  ##   Iops: JInt
  ##   DBName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   OptionGroupName: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   DBSnapshotIdentifier: JString (required)
  ##   PubliclyAccessible: JBool
  ##   DBInstanceClass: JString
  ##   LicenseModel: JString
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_596046 = formData.getOrDefault("Port")
  valid_596046 = validateParameter(valid_596046, JInt, required = false, default = nil)
  if valid_596046 != nil:
    section.add "Port", valid_596046
  var valid_596047 = formData.getOrDefault("Engine")
  valid_596047 = validateParameter(valid_596047, JString, required = false,
                                 default = nil)
  if valid_596047 != nil:
    section.add "Engine", valid_596047
  var valid_596048 = formData.getOrDefault("Iops")
  valid_596048 = validateParameter(valid_596048, JInt, required = false, default = nil)
  if valid_596048 != nil:
    section.add "Iops", valid_596048
  var valid_596049 = formData.getOrDefault("DBName")
  valid_596049 = validateParameter(valid_596049, JString, required = false,
                                 default = nil)
  if valid_596049 != nil:
    section.add "DBName", valid_596049
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_596050 = formData.getOrDefault("DBInstanceIdentifier")
  valid_596050 = validateParameter(valid_596050, JString, required = true,
                                 default = nil)
  if valid_596050 != nil:
    section.add "DBInstanceIdentifier", valid_596050
  var valid_596051 = formData.getOrDefault("OptionGroupName")
  valid_596051 = validateParameter(valid_596051, JString, required = false,
                                 default = nil)
  if valid_596051 != nil:
    section.add "OptionGroupName", valid_596051
  var valid_596052 = formData.getOrDefault("Tags")
  valid_596052 = validateParameter(valid_596052, JArray, required = false,
                                 default = nil)
  if valid_596052 != nil:
    section.add "Tags", valid_596052
  var valid_596053 = formData.getOrDefault("DBSubnetGroupName")
  valid_596053 = validateParameter(valid_596053, JString, required = false,
                                 default = nil)
  if valid_596053 != nil:
    section.add "DBSubnetGroupName", valid_596053
  var valid_596054 = formData.getOrDefault("AvailabilityZone")
  valid_596054 = validateParameter(valid_596054, JString, required = false,
                                 default = nil)
  if valid_596054 != nil:
    section.add "AvailabilityZone", valid_596054
  var valid_596055 = formData.getOrDefault("MultiAZ")
  valid_596055 = validateParameter(valid_596055, JBool, required = false, default = nil)
  if valid_596055 != nil:
    section.add "MultiAZ", valid_596055
  var valid_596056 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_596056 = validateParameter(valid_596056, JString, required = true,
                                 default = nil)
  if valid_596056 != nil:
    section.add "DBSnapshotIdentifier", valid_596056
  var valid_596057 = formData.getOrDefault("PubliclyAccessible")
  valid_596057 = validateParameter(valid_596057, JBool, required = false, default = nil)
  if valid_596057 != nil:
    section.add "PubliclyAccessible", valid_596057
  var valid_596058 = formData.getOrDefault("DBInstanceClass")
  valid_596058 = validateParameter(valid_596058, JString, required = false,
                                 default = nil)
  if valid_596058 != nil:
    section.add "DBInstanceClass", valid_596058
  var valid_596059 = formData.getOrDefault("LicenseModel")
  valid_596059 = validateParameter(valid_596059, JString, required = false,
                                 default = nil)
  if valid_596059 != nil:
    section.add "LicenseModel", valid_596059
  var valid_596060 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_596060 = validateParameter(valid_596060, JBool, required = false, default = nil)
  if valid_596060 != nil:
    section.add "AutoMinorVersionUpgrade", valid_596060
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596061: Call_PostRestoreDBInstanceFromDBSnapshot_596034;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596061.validator(path, query, header, formData, body)
  let scheme = call_596061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596061.url(scheme.get, call_596061.host, call_596061.base,
                         call_596061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596061, url, valid)

proc call*(call_596062: Call_PostRestoreDBInstanceFromDBSnapshot_596034;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          Engine: string = ""; Iops: int = 0; DBName: string = "";
          OptionGroupName: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; AvailabilityZone: string = "";
          MultiAZ: bool = false; Action: string = "RestoreDBInstanceFromDBSnapshot";
          PubliclyAccessible: bool = false; DBInstanceClass: string = "";
          LicenseModel: string = ""; AutoMinorVersionUpgrade: bool = false;
          Version: string = "2013-09-09"): Recallable =
  ## postRestoreDBInstanceFromDBSnapshot
  ##   Port: int
  ##   Engine: string
  ##   Iops: int
  ##   DBName: string
  ##   DBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   PubliclyAccessible: bool
  ##   DBInstanceClass: string
  ##   LicenseModel: string
  ##   AutoMinorVersionUpgrade: bool
  ##   Version: string (required)
  var query_596063 = newJObject()
  var formData_596064 = newJObject()
  add(formData_596064, "Port", newJInt(Port))
  add(formData_596064, "Engine", newJString(Engine))
  add(formData_596064, "Iops", newJInt(Iops))
  add(formData_596064, "DBName", newJString(DBName))
  add(formData_596064, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_596064, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_596064.add "Tags", Tags
  add(formData_596064, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_596064, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_596064, "MultiAZ", newJBool(MultiAZ))
  add(formData_596064, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_596063, "Action", newJString(Action))
  add(formData_596064, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_596064, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_596064, "LicenseModel", newJString(LicenseModel))
  add(formData_596064, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_596063, "Version", newJString(Version))
  result = call_596062.call(nil, query_596063, nil, formData_596064, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_596034(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_596035, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_596036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_596004 = ref object of OpenApiRestCall_593421
proc url_GetRestoreDBInstanceFromDBSnapshot_596006(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_596005(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString
  ##   OptionGroupName: JString
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   MultiAZ: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBName: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  var valid_596007 = query.getOrDefault("Engine")
  valid_596007 = validateParameter(valid_596007, JString, required = false,
                                 default = nil)
  if valid_596007 != nil:
    section.add "Engine", valid_596007
  var valid_596008 = query.getOrDefault("OptionGroupName")
  valid_596008 = validateParameter(valid_596008, JString, required = false,
                                 default = nil)
  if valid_596008 != nil:
    section.add "OptionGroupName", valid_596008
  var valid_596009 = query.getOrDefault("AvailabilityZone")
  valid_596009 = validateParameter(valid_596009, JString, required = false,
                                 default = nil)
  if valid_596009 != nil:
    section.add "AvailabilityZone", valid_596009
  var valid_596010 = query.getOrDefault("Iops")
  valid_596010 = validateParameter(valid_596010, JInt, required = false, default = nil)
  if valid_596010 != nil:
    section.add "Iops", valid_596010
  var valid_596011 = query.getOrDefault("MultiAZ")
  valid_596011 = validateParameter(valid_596011, JBool, required = false, default = nil)
  if valid_596011 != nil:
    section.add "MultiAZ", valid_596011
  var valid_596012 = query.getOrDefault("LicenseModel")
  valid_596012 = validateParameter(valid_596012, JString, required = false,
                                 default = nil)
  if valid_596012 != nil:
    section.add "LicenseModel", valid_596012
  var valid_596013 = query.getOrDefault("Tags")
  valid_596013 = validateParameter(valid_596013, JArray, required = false,
                                 default = nil)
  if valid_596013 != nil:
    section.add "Tags", valid_596013
  var valid_596014 = query.getOrDefault("DBName")
  valid_596014 = validateParameter(valid_596014, JString, required = false,
                                 default = nil)
  if valid_596014 != nil:
    section.add "DBName", valid_596014
  var valid_596015 = query.getOrDefault("DBInstanceClass")
  valid_596015 = validateParameter(valid_596015, JString, required = false,
                                 default = nil)
  if valid_596015 != nil:
    section.add "DBInstanceClass", valid_596015
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_596016 = query.getOrDefault("Action")
  valid_596016 = validateParameter(valid_596016, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_596016 != nil:
    section.add "Action", valid_596016
  var valid_596017 = query.getOrDefault("DBSubnetGroupName")
  valid_596017 = validateParameter(valid_596017, JString, required = false,
                                 default = nil)
  if valid_596017 != nil:
    section.add "DBSubnetGroupName", valid_596017
  var valid_596018 = query.getOrDefault("PubliclyAccessible")
  valid_596018 = validateParameter(valid_596018, JBool, required = false, default = nil)
  if valid_596018 != nil:
    section.add "PubliclyAccessible", valid_596018
  var valid_596019 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_596019 = validateParameter(valid_596019, JBool, required = false, default = nil)
  if valid_596019 != nil:
    section.add "AutoMinorVersionUpgrade", valid_596019
  var valid_596020 = query.getOrDefault("Port")
  valid_596020 = validateParameter(valid_596020, JInt, required = false, default = nil)
  if valid_596020 != nil:
    section.add "Port", valid_596020
  var valid_596021 = query.getOrDefault("Version")
  valid_596021 = validateParameter(valid_596021, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_596021 != nil:
    section.add "Version", valid_596021
  var valid_596022 = query.getOrDefault("DBInstanceIdentifier")
  valid_596022 = validateParameter(valid_596022, JString, required = true,
                                 default = nil)
  if valid_596022 != nil:
    section.add "DBInstanceIdentifier", valid_596022
  var valid_596023 = query.getOrDefault("DBSnapshotIdentifier")
  valid_596023 = validateParameter(valid_596023, JString, required = true,
                                 default = nil)
  if valid_596023 != nil:
    section.add "DBSnapshotIdentifier", valid_596023
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
  var valid_596024 = header.getOrDefault("X-Amz-Date")
  valid_596024 = validateParameter(valid_596024, JString, required = false,
                                 default = nil)
  if valid_596024 != nil:
    section.add "X-Amz-Date", valid_596024
  var valid_596025 = header.getOrDefault("X-Amz-Security-Token")
  valid_596025 = validateParameter(valid_596025, JString, required = false,
                                 default = nil)
  if valid_596025 != nil:
    section.add "X-Amz-Security-Token", valid_596025
  var valid_596026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596026 = validateParameter(valid_596026, JString, required = false,
                                 default = nil)
  if valid_596026 != nil:
    section.add "X-Amz-Content-Sha256", valid_596026
  var valid_596027 = header.getOrDefault("X-Amz-Algorithm")
  valid_596027 = validateParameter(valid_596027, JString, required = false,
                                 default = nil)
  if valid_596027 != nil:
    section.add "X-Amz-Algorithm", valid_596027
  var valid_596028 = header.getOrDefault("X-Amz-Signature")
  valid_596028 = validateParameter(valid_596028, JString, required = false,
                                 default = nil)
  if valid_596028 != nil:
    section.add "X-Amz-Signature", valid_596028
  var valid_596029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596029 = validateParameter(valid_596029, JString, required = false,
                                 default = nil)
  if valid_596029 != nil:
    section.add "X-Amz-SignedHeaders", valid_596029
  var valid_596030 = header.getOrDefault("X-Amz-Credential")
  valid_596030 = validateParameter(valid_596030, JString, required = false,
                                 default = nil)
  if valid_596030 != nil:
    section.add "X-Amz-Credential", valid_596030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596031: Call_GetRestoreDBInstanceFromDBSnapshot_596004;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596031.validator(path, query, header, formData, body)
  let scheme = call_596031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596031.url(scheme.get, call_596031.host, call_596031.base,
                         call_596031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596031, url, valid)

proc call*(call_596032: Call_GetRestoreDBInstanceFromDBSnapshot_596004;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Engine: string = ""; OptionGroupName: string = "";
          AvailabilityZone: string = ""; Iops: int = 0; MultiAZ: bool = false;
          LicenseModel: string = ""; Tags: JsonNode = nil; DBName: string = "";
          DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Port: int = 0;
          Version: string = "2013-09-09"): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   Engine: string
  ##   OptionGroupName: string
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   MultiAZ: bool
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBName: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_596033 = newJObject()
  add(query_596033, "Engine", newJString(Engine))
  add(query_596033, "OptionGroupName", newJString(OptionGroupName))
  add(query_596033, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_596033, "Iops", newJInt(Iops))
  add(query_596033, "MultiAZ", newJBool(MultiAZ))
  add(query_596033, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_596033.add "Tags", Tags
  add(query_596033, "DBName", newJString(DBName))
  add(query_596033, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_596033, "Action", newJString(Action))
  add(query_596033, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_596033, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_596033, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_596033, "Port", newJInt(Port))
  add(query_596033, "Version", newJString(Version))
  add(query_596033, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_596033, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_596032.call(nil, query_596033, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_596004(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_596005, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_596006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_596097 = ref object of OpenApiRestCall_593421
proc url_PostRestoreDBInstanceToPointInTime_596099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_596098(path: JsonNode;
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
  var valid_596100 = query.getOrDefault("Action")
  valid_596100 = validateParameter(valid_596100, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_596100 != nil:
    section.add "Action", valid_596100
  var valid_596101 = query.getOrDefault("Version")
  valid_596101 = validateParameter(valid_596101, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_596101 != nil:
    section.add "Version", valid_596101
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
  var valid_596102 = header.getOrDefault("X-Amz-Date")
  valid_596102 = validateParameter(valid_596102, JString, required = false,
                                 default = nil)
  if valid_596102 != nil:
    section.add "X-Amz-Date", valid_596102
  var valid_596103 = header.getOrDefault("X-Amz-Security-Token")
  valid_596103 = validateParameter(valid_596103, JString, required = false,
                                 default = nil)
  if valid_596103 != nil:
    section.add "X-Amz-Security-Token", valid_596103
  var valid_596104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596104 = validateParameter(valid_596104, JString, required = false,
                                 default = nil)
  if valid_596104 != nil:
    section.add "X-Amz-Content-Sha256", valid_596104
  var valid_596105 = header.getOrDefault("X-Amz-Algorithm")
  valid_596105 = validateParameter(valid_596105, JString, required = false,
                                 default = nil)
  if valid_596105 != nil:
    section.add "X-Amz-Algorithm", valid_596105
  var valid_596106 = header.getOrDefault("X-Amz-Signature")
  valid_596106 = validateParameter(valid_596106, JString, required = false,
                                 default = nil)
  if valid_596106 != nil:
    section.add "X-Amz-Signature", valid_596106
  var valid_596107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596107 = validateParameter(valid_596107, JString, required = false,
                                 default = nil)
  if valid_596107 != nil:
    section.add "X-Amz-SignedHeaders", valid_596107
  var valid_596108 = header.getOrDefault("X-Amz-Credential")
  valid_596108 = validateParameter(valid_596108, JString, required = false,
                                 default = nil)
  if valid_596108 != nil:
    section.add "X-Amz-Credential", valid_596108
  result.add "header", section
  ## parameters in `formData` object:
  ##   UseLatestRestorableTime: JBool
  ##   Port: JInt
  ##   Engine: JString
  ##   Iops: JInt
  ##   DBName: JString
  ##   OptionGroupName: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   RestoreTime: JString
  ##   PubliclyAccessible: JBool
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   DBInstanceClass: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   LicenseModel: JString
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_596109 = formData.getOrDefault("UseLatestRestorableTime")
  valid_596109 = validateParameter(valid_596109, JBool, required = false, default = nil)
  if valid_596109 != nil:
    section.add "UseLatestRestorableTime", valid_596109
  var valid_596110 = formData.getOrDefault("Port")
  valid_596110 = validateParameter(valid_596110, JInt, required = false, default = nil)
  if valid_596110 != nil:
    section.add "Port", valid_596110
  var valid_596111 = formData.getOrDefault("Engine")
  valid_596111 = validateParameter(valid_596111, JString, required = false,
                                 default = nil)
  if valid_596111 != nil:
    section.add "Engine", valid_596111
  var valid_596112 = formData.getOrDefault("Iops")
  valid_596112 = validateParameter(valid_596112, JInt, required = false, default = nil)
  if valid_596112 != nil:
    section.add "Iops", valid_596112
  var valid_596113 = formData.getOrDefault("DBName")
  valid_596113 = validateParameter(valid_596113, JString, required = false,
                                 default = nil)
  if valid_596113 != nil:
    section.add "DBName", valid_596113
  var valid_596114 = formData.getOrDefault("OptionGroupName")
  valid_596114 = validateParameter(valid_596114, JString, required = false,
                                 default = nil)
  if valid_596114 != nil:
    section.add "OptionGroupName", valid_596114
  var valid_596115 = formData.getOrDefault("Tags")
  valid_596115 = validateParameter(valid_596115, JArray, required = false,
                                 default = nil)
  if valid_596115 != nil:
    section.add "Tags", valid_596115
  var valid_596116 = formData.getOrDefault("DBSubnetGroupName")
  valid_596116 = validateParameter(valid_596116, JString, required = false,
                                 default = nil)
  if valid_596116 != nil:
    section.add "DBSubnetGroupName", valid_596116
  var valid_596117 = formData.getOrDefault("AvailabilityZone")
  valid_596117 = validateParameter(valid_596117, JString, required = false,
                                 default = nil)
  if valid_596117 != nil:
    section.add "AvailabilityZone", valid_596117
  var valid_596118 = formData.getOrDefault("MultiAZ")
  valid_596118 = validateParameter(valid_596118, JBool, required = false, default = nil)
  if valid_596118 != nil:
    section.add "MultiAZ", valid_596118
  var valid_596119 = formData.getOrDefault("RestoreTime")
  valid_596119 = validateParameter(valid_596119, JString, required = false,
                                 default = nil)
  if valid_596119 != nil:
    section.add "RestoreTime", valid_596119
  var valid_596120 = formData.getOrDefault("PubliclyAccessible")
  valid_596120 = validateParameter(valid_596120, JBool, required = false, default = nil)
  if valid_596120 != nil:
    section.add "PubliclyAccessible", valid_596120
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_596121 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_596121 = validateParameter(valid_596121, JString, required = true,
                                 default = nil)
  if valid_596121 != nil:
    section.add "TargetDBInstanceIdentifier", valid_596121
  var valid_596122 = formData.getOrDefault("DBInstanceClass")
  valid_596122 = validateParameter(valid_596122, JString, required = false,
                                 default = nil)
  if valid_596122 != nil:
    section.add "DBInstanceClass", valid_596122
  var valid_596123 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_596123 = validateParameter(valid_596123, JString, required = true,
                                 default = nil)
  if valid_596123 != nil:
    section.add "SourceDBInstanceIdentifier", valid_596123
  var valid_596124 = formData.getOrDefault("LicenseModel")
  valid_596124 = validateParameter(valid_596124, JString, required = false,
                                 default = nil)
  if valid_596124 != nil:
    section.add "LicenseModel", valid_596124
  var valid_596125 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_596125 = validateParameter(valid_596125, JBool, required = false, default = nil)
  if valid_596125 != nil:
    section.add "AutoMinorVersionUpgrade", valid_596125
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596126: Call_PostRestoreDBInstanceToPointInTime_596097;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596126.validator(path, query, header, formData, body)
  let scheme = call_596126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596126.url(scheme.get, call_596126.host, call_596126.base,
                         call_596126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596126, url, valid)

proc call*(call_596127: Call_PostRestoreDBInstanceToPointInTime_596097;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          UseLatestRestorableTime: bool = false; Port: int = 0; Engine: string = "";
          Iops: int = 0; DBName: string = ""; OptionGroupName: string = "";
          Tags: JsonNode = nil; DBSubnetGroupName: string = "";
          AvailabilityZone: string = ""; MultiAZ: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          RestoreTime: string = ""; PubliclyAccessible: bool = false;
          DBInstanceClass: string = ""; LicenseModel: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postRestoreDBInstanceToPointInTime
  ##   UseLatestRestorableTime: bool
  ##   Port: int
  ##   Engine: string
  ##   Iops: int
  ##   DBName: string
  ##   OptionGroupName: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   RestoreTime: string
  ##   PubliclyAccessible: bool
  ##   TargetDBInstanceIdentifier: string (required)
  ##   DBInstanceClass: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   LicenseModel: string
  ##   AutoMinorVersionUpgrade: bool
  ##   Version: string (required)
  var query_596128 = newJObject()
  var formData_596129 = newJObject()
  add(formData_596129, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_596129, "Port", newJInt(Port))
  add(formData_596129, "Engine", newJString(Engine))
  add(formData_596129, "Iops", newJInt(Iops))
  add(formData_596129, "DBName", newJString(DBName))
  add(formData_596129, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_596129.add "Tags", Tags
  add(formData_596129, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_596129, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_596129, "MultiAZ", newJBool(MultiAZ))
  add(query_596128, "Action", newJString(Action))
  add(formData_596129, "RestoreTime", newJString(RestoreTime))
  add(formData_596129, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_596129, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_596129, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_596129, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_596129, "LicenseModel", newJString(LicenseModel))
  add(formData_596129, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_596128, "Version", newJString(Version))
  result = call_596127.call(nil, query_596128, nil, formData_596129, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_596097(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_596098, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_596099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_596065 = ref object of OpenApiRestCall_593421
proc url_GetRestoreDBInstanceToPointInTime_596067(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_596066(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   OptionGroupName: JString
  ##   RestoreTime: JString
  ##   MultiAZ: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBName: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   UseLatestRestorableTime: JBool
  ##   DBSubnetGroupName: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Version: JString (required)
  section = newJObject()
  var valid_596068 = query.getOrDefault("Engine")
  valid_596068 = validateParameter(valid_596068, JString, required = false,
                                 default = nil)
  if valid_596068 != nil:
    section.add "Engine", valid_596068
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_596069 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_596069 = validateParameter(valid_596069, JString, required = true,
                                 default = nil)
  if valid_596069 != nil:
    section.add "SourceDBInstanceIdentifier", valid_596069
  var valid_596070 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_596070 = validateParameter(valid_596070, JString, required = true,
                                 default = nil)
  if valid_596070 != nil:
    section.add "TargetDBInstanceIdentifier", valid_596070
  var valid_596071 = query.getOrDefault("AvailabilityZone")
  valid_596071 = validateParameter(valid_596071, JString, required = false,
                                 default = nil)
  if valid_596071 != nil:
    section.add "AvailabilityZone", valid_596071
  var valid_596072 = query.getOrDefault("Iops")
  valid_596072 = validateParameter(valid_596072, JInt, required = false, default = nil)
  if valid_596072 != nil:
    section.add "Iops", valid_596072
  var valid_596073 = query.getOrDefault("OptionGroupName")
  valid_596073 = validateParameter(valid_596073, JString, required = false,
                                 default = nil)
  if valid_596073 != nil:
    section.add "OptionGroupName", valid_596073
  var valid_596074 = query.getOrDefault("RestoreTime")
  valid_596074 = validateParameter(valid_596074, JString, required = false,
                                 default = nil)
  if valid_596074 != nil:
    section.add "RestoreTime", valid_596074
  var valid_596075 = query.getOrDefault("MultiAZ")
  valid_596075 = validateParameter(valid_596075, JBool, required = false, default = nil)
  if valid_596075 != nil:
    section.add "MultiAZ", valid_596075
  var valid_596076 = query.getOrDefault("LicenseModel")
  valid_596076 = validateParameter(valid_596076, JString, required = false,
                                 default = nil)
  if valid_596076 != nil:
    section.add "LicenseModel", valid_596076
  var valid_596077 = query.getOrDefault("Tags")
  valid_596077 = validateParameter(valid_596077, JArray, required = false,
                                 default = nil)
  if valid_596077 != nil:
    section.add "Tags", valid_596077
  var valid_596078 = query.getOrDefault("DBName")
  valid_596078 = validateParameter(valid_596078, JString, required = false,
                                 default = nil)
  if valid_596078 != nil:
    section.add "DBName", valid_596078
  var valid_596079 = query.getOrDefault("DBInstanceClass")
  valid_596079 = validateParameter(valid_596079, JString, required = false,
                                 default = nil)
  if valid_596079 != nil:
    section.add "DBInstanceClass", valid_596079
  var valid_596080 = query.getOrDefault("Action")
  valid_596080 = validateParameter(valid_596080, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_596080 != nil:
    section.add "Action", valid_596080
  var valid_596081 = query.getOrDefault("UseLatestRestorableTime")
  valid_596081 = validateParameter(valid_596081, JBool, required = false, default = nil)
  if valid_596081 != nil:
    section.add "UseLatestRestorableTime", valid_596081
  var valid_596082 = query.getOrDefault("DBSubnetGroupName")
  valid_596082 = validateParameter(valid_596082, JString, required = false,
                                 default = nil)
  if valid_596082 != nil:
    section.add "DBSubnetGroupName", valid_596082
  var valid_596083 = query.getOrDefault("PubliclyAccessible")
  valid_596083 = validateParameter(valid_596083, JBool, required = false, default = nil)
  if valid_596083 != nil:
    section.add "PubliclyAccessible", valid_596083
  var valid_596084 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_596084 = validateParameter(valid_596084, JBool, required = false, default = nil)
  if valid_596084 != nil:
    section.add "AutoMinorVersionUpgrade", valid_596084
  var valid_596085 = query.getOrDefault("Port")
  valid_596085 = validateParameter(valid_596085, JInt, required = false, default = nil)
  if valid_596085 != nil:
    section.add "Port", valid_596085
  var valid_596086 = query.getOrDefault("Version")
  valid_596086 = validateParameter(valid_596086, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_596086 != nil:
    section.add "Version", valid_596086
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
  var valid_596087 = header.getOrDefault("X-Amz-Date")
  valid_596087 = validateParameter(valid_596087, JString, required = false,
                                 default = nil)
  if valid_596087 != nil:
    section.add "X-Amz-Date", valid_596087
  var valid_596088 = header.getOrDefault("X-Amz-Security-Token")
  valid_596088 = validateParameter(valid_596088, JString, required = false,
                                 default = nil)
  if valid_596088 != nil:
    section.add "X-Amz-Security-Token", valid_596088
  var valid_596089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596089 = validateParameter(valid_596089, JString, required = false,
                                 default = nil)
  if valid_596089 != nil:
    section.add "X-Amz-Content-Sha256", valid_596089
  var valid_596090 = header.getOrDefault("X-Amz-Algorithm")
  valid_596090 = validateParameter(valid_596090, JString, required = false,
                                 default = nil)
  if valid_596090 != nil:
    section.add "X-Amz-Algorithm", valid_596090
  var valid_596091 = header.getOrDefault("X-Amz-Signature")
  valid_596091 = validateParameter(valid_596091, JString, required = false,
                                 default = nil)
  if valid_596091 != nil:
    section.add "X-Amz-Signature", valid_596091
  var valid_596092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596092 = validateParameter(valid_596092, JString, required = false,
                                 default = nil)
  if valid_596092 != nil:
    section.add "X-Amz-SignedHeaders", valid_596092
  var valid_596093 = header.getOrDefault("X-Amz-Credential")
  valid_596093 = validateParameter(valid_596093, JString, required = false,
                                 default = nil)
  if valid_596093 != nil:
    section.add "X-Amz-Credential", valid_596093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596094: Call_GetRestoreDBInstanceToPointInTime_596065;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596094.validator(path, query, header, formData, body)
  let scheme = call_596094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596094.url(scheme.get, call_596094.host, call_596094.base,
                         call_596094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596094, url, valid)

proc call*(call_596095: Call_GetRestoreDBInstanceToPointInTime_596065;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Engine: string = ""; AvailabilityZone: string = ""; Iops: int = 0;
          OptionGroupName: string = ""; RestoreTime: string = ""; MultiAZ: bool = false;
          LicenseModel: string = ""; Tags: JsonNode = nil; DBName: string = "";
          DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceToPointInTime";
          UseLatestRestorableTime: bool = false; DBSubnetGroupName: string = "";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Port: int = 0; Version: string = "2013-09-09"): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   Engine: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   TargetDBInstanceIdentifier: string (required)
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   OptionGroupName: string
  ##   RestoreTime: string
  ##   MultiAZ: bool
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBName: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   UseLatestRestorableTime: bool
  ##   DBSubnetGroupName: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Version: string (required)
  var query_596096 = newJObject()
  add(query_596096, "Engine", newJString(Engine))
  add(query_596096, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_596096, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_596096, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_596096, "Iops", newJInt(Iops))
  add(query_596096, "OptionGroupName", newJString(OptionGroupName))
  add(query_596096, "RestoreTime", newJString(RestoreTime))
  add(query_596096, "MultiAZ", newJBool(MultiAZ))
  add(query_596096, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_596096.add "Tags", Tags
  add(query_596096, "DBName", newJString(DBName))
  add(query_596096, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_596096, "Action", newJString(Action))
  add(query_596096, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_596096, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_596096, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_596096, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_596096, "Port", newJInt(Port))
  add(query_596096, "Version", newJString(Version))
  result = call_596095.call(nil, query_596096, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_596065(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_596066, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_596067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_596150 = ref object of OpenApiRestCall_593421
proc url_PostRevokeDBSecurityGroupIngress_596152(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_596151(path: JsonNode;
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
  var valid_596153 = query.getOrDefault("Action")
  valid_596153 = validateParameter(valid_596153, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_596153 != nil:
    section.add "Action", valid_596153
  var valid_596154 = query.getOrDefault("Version")
  valid_596154 = validateParameter(valid_596154, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_596154 != nil:
    section.add "Version", valid_596154
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
  var valid_596155 = header.getOrDefault("X-Amz-Date")
  valid_596155 = validateParameter(valid_596155, JString, required = false,
                                 default = nil)
  if valid_596155 != nil:
    section.add "X-Amz-Date", valid_596155
  var valid_596156 = header.getOrDefault("X-Amz-Security-Token")
  valid_596156 = validateParameter(valid_596156, JString, required = false,
                                 default = nil)
  if valid_596156 != nil:
    section.add "X-Amz-Security-Token", valid_596156
  var valid_596157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596157 = validateParameter(valid_596157, JString, required = false,
                                 default = nil)
  if valid_596157 != nil:
    section.add "X-Amz-Content-Sha256", valid_596157
  var valid_596158 = header.getOrDefault("X-Amz-Algorithm")
  valid_596158 = validateParameter(valid_596158, JString, required = false,
                                 default = nil)
  if valid_596158 != nil:
    section.add "X-Amz-Algorithm", valid_596158
  var valid_596159 = header.getOrDefault("X-Amz-Signature")
  valid_596159 = validateParameter(valid_596159, JString, required = false,
                                 default = nil)
  if valid_596159 != nil:
    section.add "X-Amz-Signature", valid_596159
  var valid_596160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596160 = validateParameter(valid_596160, JString, required = false,
                                 default = nil)
  if valid_596160 != nil:
    section.add "X-Amz-SignedHeaders", valid_596160
  var valid_596161 = header.getOrDefault("X-Amz-Credential")
  valid_596161 = validateParameter(valid_596161, JString, required = false,
                                 default = nil)
  if valid_596161 != nil:
    section.add "X-Amz-Credential", valid_596161
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_596162 = formData.getOrDefault("DBSecurityGroupName")
  valid_596162 = validateParameter(valid_596162, JString, required = true,
                                 default = nil)
  if valid_596162 != nil:
    section.add "DBSecurityGroupName", valid_596162
  var valid_596163 = formData.getOrDefault("EC2SecurityGroupName")
  valid_596163 = validateParameter(valid_596163, JString, required = false,
                                 default = nil)
  if valid_596163 != nil:
    section.add "EC2SecurityGroupName", valid_596163
  var valid_596164 = formData.getOrDefault("EC2SecurityGroupId")
  valid_596164 = validateParameter(valid_596164, JString, required = false,
                                 default = nil)
  if valid_596164 != nil:
    section.add "EC2SecurityGroupId", valid_596164
  var valid_596165 = formData.getOrDefault("CIDRIP")
  valid_596165 = validateParameter(valid_596165, JString, required = false,
                                 default = nil)
  if valid_596165 != nil:
    section.add "CIDRIP", valid_596165
  var valid_596166 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_596166 = validateParameter(valid_596166, JString, required = false,
                                 default = nil)
  if valid_596166 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_596166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596167: Call_PostRevokeDBSecurityGroupIngress_596150;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596167.validator(path, query, header, formData, body)
  let scheme = call_596167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596167.url(scheme.get, call_596167.host, call_596167.base,
                         call_596167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596167, url, valid)

proc call*(call_596168: Call_PostRevokeDBSecurityGroupIngress_596150;
          DBSecurityGroupName: string;
          Action: string = "RevokeDBSecurityGroupIngress";
          EC2SecurityGroupName: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Version: string = "2013-09-09";
          EC2SecurityGroupOwnerId: string = ""): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Version: string (required)
  ##   EC2SecurityGroupOwnerId: string
  var query_596169 = newJObject()
  var formData_596170 = newJObject()
  add(formData_596170, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_596169, "Action", newJString(Action))
  add(formData_596170, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_596170, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_596170, "CIDRIP", newJString(CIDRIP))
  add(query_596169, "Version", newJString(Version))
  add(formData_596170, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_596168.call(nil, query_596169, nil, formData_596170, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_596150(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_596151, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_596152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_596130 = ref object of OpenApiRestCall_593421
proc url_GetRevokeDBSecurityGroupIngress_596132(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_596131(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EC2SecurityGroupId: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   DBSecurityGroupName: JString (required)
  ##   Action: JString (required)
  ##   CIDRIP: JString
  ##   EC2SecurityGroupName: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_596133 = query.getOrDefault("EC2SecurityGroupId")
  valid_596133 = validateParameter(valid_596133, JString, required = false,
                                 default = nil)
  if valid_596133 != nil:
    section.add "EC2SecurityGroupId", valid_596133
  var valid_596134 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_596134 = validateParameter(valid_596134, JString, required = false,
                                 default = nil)
  if valid_596134 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_596134
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_596135 = query.getOrDefault("DBSecurityGroupName")
  valid_596135 = validateParameter(valid_596135, JString, required = true,
                                 default = nil)
  if valid_596135 != nil:
    section.add "DBSecurityGroupName", valid_596135
  var valid_596136 = query.getOrDefault("Action")
  valid_596136 = validateParameter(valid_596136, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_596136 != nil:
    section.add "Action", valid_596136
  var valid_596137 = query.getOrDefault("CIDRIP")
  valid_596137 = validateParameter(valid_596137, JString, required = false,
                                 default = nil)
  if valid_596137 != nil:
    section.add "CIDRIP", valid_596137
  var valid_596138 = query.getOrDefault("EC2SecurityGroupName")
  valid_596138 = validateParameter(valid_596138, JString, required = false,
                                 default = nil)
  if valid_596138 != nil:
    section.add "EC2SecurityGroupName", valid_596138
  var valid_596139 = query.getOrDefault("Version")
  valid_596139 = validateParameter(valid_596139, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_596139 != nil:
    section.add "Version", valid_596139
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
  var valid_596140 = header.getOrDefault("X-Amz-Date")
  valid_596140 = validateParameter(valid_596140, JString, required = false,
                                 default = nil)
  if valid_596140 != nil:
    section.add "X-Amz-Date", valid_596140
  var valid_596141 = header.getOrDefault("X-Amz-Security-Token")
  valid_596141 = validateParameter(valid_596141, JString, required = false,
                                 default = nil)
  if valid_596141 != nil:
    section.add "X-Amz-Security-Token", valid_596141
  var valid_596142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596142 = validateParameter(valid_596142, JString, required = false,
                                 default = nil)
  if valid_596142 != nil:
    section.add "X-Amz-Content-Sha256", valid_596142
  var valid_596143 = header.getOrDefault("X-Amz-Algorithm")
  valid_596143 = validateParameter(valid_596143, JString, required = false,
                                 default = nil)
  if valid_596143 != nil:
    section.add "X-Amz-Algorithm", valid_596143
  var valid_596144 = header.getOrDefault("X-Amz-Signature")
  valid_596144 = validateParameter(valid_596144, JString, required = false,
                                 default = nil)
  if valid_596144 != nil:
    section.add "X-Amz-Signature", valid_596144
  var valid_596145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596145 = validateParameter(valid_596145, JString, required = false,
                                 default = nil)
  if valid_596145 != nil:
    section.add "X-Amz-SignedHeaders", valid_596145
  var valid_596146 = header.getOrDefault("X-Amz-Credential")
  valid_596146 = validateParameter(valid_596146, JString, required = false,
                                 default = nil)
  if valid_596146 != nil:
    section.add "X-Amz-Credential", valid_596146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596147: Call_GetRevokeDBSecurityGroupIngress_596130;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596147.validator(path, query, header, formData, body)
  let scheme = call_596147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596147.url(scheme.get, call_596147.host, call_596147.base,
                         call_596147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596147, url, valid)

proc call*(call_596148: Call_GetRevokeDBSecurityGroupIngress_596130;
          DBSecurityGroupName: string; EC2SecurityGroupId: string = "";
          EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress"; CIDRIP: string = "";
          EC2SecurityGroupName: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   CIDRIP: string
  ##   EC2SecurityGroupName: string
  ##   Version: string (required)
  var query_596149 = newJObject()
  add(query_596149, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_596149, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_596149, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_596149, "Action", newJString(Action))
  add(query_596149, "CIDRIP", newJString(CIDRIP))
  add(query_596149, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_596149, "Version", newJString(Version))
  result = call_596148.call(nil, query_596149, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_596130(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_596131, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_596132,
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
