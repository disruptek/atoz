
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          CIDRIP: string = ""; Version: string = "2014-09-01";
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
                                 default = newJString("2014-09-01"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2014-09-01"): Recallable =
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
  Call_PostCopyDBParameterGroup_594143 = ref object of OpenApiRestCall_593421
proc url_PostCopyDBParameterGroup_594145(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBParameterGroup_594144(path: JsonNode; query: JsonNode;
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
  var valid_594146 = query.getOrDefault("Action")
  valid_594146 = validateParameter(valid_594146, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_594146 != nil:
    section.add "Action", valid_594146
  var valid_594147 = query.getOrDefault("Version")
  valid_594147 = validateParameter(valid_594147, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594147 != nil:
    section.add "Version", valid_594147
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
  var valid_594148 = header.getOrDefault("X-Amz-Date")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Date", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Security-Token")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Security-Token", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Content-Sha256", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Algorithm")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Algorithm", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Signature")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Signature", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-SignedHeaders", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Credential")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Credential", valid_594154
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   SourceDBParameterGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBParameterGroupIdentifier` field"
  var valid_594155 = formData.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_594155 = validateParameter(valid_594155, JString, required = true,
                                 default = nil)
  if valid_594155 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_594155
  var valid_594156 = formData.getOrDefault("Tags")
  valid_594156 = validateParameter(valid_594156, JArray, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "Tags", valid_594156
  var valid_594157 = formData.getOrDefault("TargetDBParameterGroupDescription")
  valid_594157 = validateParameter(valid_594157, JString, required = true,
                                 default = nil)
  if valid_594157 != nil:
    section.add "TargetDBParameterGroupDescription", valid_594157
  var valid_594158 = formData.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_594158 = validateParameter(valid_594158, JString, required = true,
                                 default = nil)
  if valid_594158 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_594158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594159: Call_PostCopyDBParameterGroup_594143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594159.validator(path, query, header, formData, body)
  let scheme = call_594159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594159.url(scheme.get, call_594159.host, call_594159.base,
                         call_594159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594159, url, valid)

proc call*(call_594160: Call_PostCopyDBParameterGroup_594143;
          TargetDBParameterGroupIdentifier: string;
          TargetDBParameterGroupDescription: string;
          SourceDBParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postCopyDBParameterGroup
  ##   TargetDBParameterGroupIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   TargetDBParameterGroupDescription: string (required)
  ##   SourceDBParameterGroupIdentifier: string (required)
  ##   Version: string (required)
  var query_594161 = newJObject()
  var formData_594162 = newJObject()
  add(formData_594162, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  if Tags != nil:
    formData_594162.add "Tags", Tags
  add(query_594161, "Action", newJString(Action))
  add(formData_594162, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(formData_594162, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_594161, "Version", newJString(Version))
  result = call_594160.call(nil, query_594161, nil, formData_594162, nil)

var postCopyDBParameterGroup* = Call_PostCopyDBParameterGroup_594143(
    name: "postCopyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_PostCopyDBParameterGroup_594144, base: "/",
    url: url_PostCopyDBParameterGroup_594145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBParameterGroup_594124 = ref object of OpenApiRestCall_593421
proc url_GetCopyDBParameterGroup_594126(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBParameterGroup_594125(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   SourceDBParameterGroupIdentifier: JString (required)
  ##   Version: JString (required)
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   TargetDBParameterGroupIdentifier: JString (required)
  section = newJObject()
  var valid_594127 = query.getOrDefault("Tags")
  valid_594127 = validateParameter(valid_594127, JArray, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "Tags", valid_594127
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594128 = query.getOrDefault("Action")
  valid_594128 = validateParameter(valid_594128, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_594128 != nil:
    section.add "Action", valid_594128
  var valid_594129 = query.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_594129 = validateParameter(valid_594129, JString, required = true,
                                 default = nil)
  if valid_594129 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_594129
  var valid_594130 = query.getOrDefault("Version")
  valid_594130 = validateParameter(valid_594130, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594130 != nil:
    section.add "Version", valid_594130
  var valid_594131 = query.getOrDefault("TargetDBParameterGroupDescription")
  valid_594131 = validateParameter(valid_594131, JString, required = true,
                                 default = nil)
  if valid_594131 != nil:
    section.add "TargetDBParameterGroupDescription", valid_594131
  var valid_594132 = query.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_594132 = validateParameter(valid_594132, JString, required = true,
                                 default = nil)
  if valid_594132 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_594132
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
  var valid_594133 = header.getOrDefault("X-Amz-Date")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Date", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Security-Token")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Security-Token", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Content-Sha256", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Algorithm")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Algorithm", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Signature")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Signature", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-SignedHeaders", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Credential")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Credential", valid_594139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594140: Call_GetCopyDBParameterGroup_594124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594140.validator(path, query, header, formData, body)
  let scheme = call_594140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594140.url(scheme.get, call_594140.host, call_594140.base,
                         call_594140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594140, url, valid)

proc call*(call_594141: Call_GetCopyDBParameterGroup_594124;
          SourceDBParameterGroupIdentifier: string;
          TargetDBParameterGroupDescription: string;
          TargetDBParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCopyDBParameterGroup
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBParameterGroupIdentifier: string (required)
  ##   Version: string (required)
  ##   TargetDBParameterGroupDescription: string (required)
  ##   TargetDBParameterGroupIdentifier: string (required)
  var query_594142 = newJObject()
  if Tags != nil:
    query_594142.add "Tags", Tags
  add(query_594142, "Action", newJString(Action))
  add(query_594142, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_594142, "Version", newJString(Version))
  add(query_594142, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_594142, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  result = call_594141.call(nil, query_594142, nil, nil, nil)

var getCopyDBParameterGroup* = Call_GetCopyDBParameterGroup_594124(
    name: "getCopyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_GetCopyDBParameterGroup_594125, base: "/",
    url: url_GetCopyDBParameterGroup_594126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_594181 = ref object of OpenApiRestCall_593421
proc url_PostCopyDBSnapshot_594183(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBSnapshot_594182(path: JsonNode; query: JsonNode;
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
  var valid_594184 = query.getOrDefault("Action")
  valid_594184 = validateParameter(valid_594184, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_594184 != nil:
    section.add "Action", valid_594184
  var valid_594185 = query.getOrDefault("Version")
  valid_594185 = validateParameter(valid_594185, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594185 != nil:
    section.add "Version", valid_594185
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
  var valid_594186 = header.getOrDefault("X-Amz-Date")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Date", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-Security-Token")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-Security-Token", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Content-Sha256", valid_594188
  var valid_594189 = header.getOrDefault("X-Amz-Algorithm")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "X-Amz-Algorithm", valid_594189
  var valid_594190 = header.getOrDefault("X-Amz-Signature")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-Signature", valid_594190
  var valid_594191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-SignedHeaders", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Credential")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Credential", valid_594192
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_594193 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_594193 = validateParameter(valid_594193, JString, required = true,
                                 default = nil)
  if valid_594193 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_594193
  var valid_594194 = formData.getOrDefault("Tags")
  valid_594194 = validateParameter(valid_594194, JArray, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "Tags", valid_594194
  var valid_594195 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_594195 = validateParameter(valid_594195, JString, required = true,
                                 default = nil)
  if valid_594195 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_594195
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594196: Call_PostCopyDBSnapshot_594181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594196.validator(path, query, header, formData, body)
  let scheme = call_594196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594196.url(scheme.get, call_594196.host, call_594196.base,
                         call_594196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594196, url, valid)

proc call*(call_594197: Call_PostCopyDBSnapshot_594181;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_594198 = newJObject()
  var formData_594199 = newJObject()
  add(formData_594199, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_594199.add "Tags", Tags
  add(query_594198, "Action", newJString(Action))
  add(formData_594199, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_594198, "Version", newJString(Version))
  result = call_594197.call(nil, query_594198, nil, formData_594199, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_594181(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_594182, base: "/",
    url: url_PostCopyDBSnapshot_594183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_594163 = ref object of OpenApiRestCall_593421
proc url_GetCopyDBSnapshot_594165(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBSnapshot_594164(path: JsonNode; query: JsonNode;
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
  var valid_594166 = query.getOrDefault("Tags")
  valid_594166 = validateParameter(valid_594166, JArray, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "Tags", valid_594166
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_594167 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_594167 = validateParameter(valid_594167, JString, required = true,
                                 default = nil)
  if valid_594167 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_594167
  var valid_594168 = query.getOrDefault("Action")
  valid_594168 = validateParameter(valid_594168, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_594168 != nil:
    section.add "Action", valid_594168
  var valid_594169 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_594169 = validateParameter(valid_594169, JString, required = true,
                                 default = nil)
  if valid_594169 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_594169
  var valid_594170 = query.getOrDefault("Version")
  valid_594170 = validateParameter(valid_594170, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594170 != nil:
    section.add "Version", valid_594170
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
  var valid_594171 = header.getOrDefault("X-Amz-Date")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Date", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Security-Token")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Security-Token", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Content-Sha256", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-Algorithm")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Algorithm", valid_594174
  var valid_594175 = header.getOrDefault("X-Amz-Signature")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-Signature", valid_594175
  var valid_594176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-SignedHeaders", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-Credential")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Credential", valid_594177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594178: Call_GetCopyDBSnapshot_594163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594178.validator(path, query, header, formData, body)
  let scheme = call_594178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594178.url(scheme.get, call_594178.host, call_594178.base,
                         call_594178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594178, url, valid)

proc call*(call_594179: Call_GetCopyDBSnapshot_594163;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_594180 = newJObject()
  if Tags != nil:
    query_594180.add "Tags", Tags
  add(query_594180, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_594180, "Action", newJString(Action))
  add(query_594180, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_594180, "Version", newJString(Version))
  result = call_594179.call(nil, query_594180, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_594163(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_594164,
    base: "/", url: url_GetCopyDBSnapshot_594165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyOptionGroup_594219 = ref object of OpenApiRestCall_593421
proc url_PostCopyOptionGroup_594221(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyOptionGroup_594220(path: JsonNode; query: JsonNode;
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
  var valid_594222 = query.getOrDefault("Action")
  valid_594222 = validateParameter(valid_594222, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_594222 != nil:
    section.add "Action", valid_594222
  var valid_594223 = query.getOrDefault("Version")
  valid_594223 = validateParameter(valid_594223, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594223 != nil:
    section.add "Version", valid_594223
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
  var valid_594224 = header.getOrDefault("X-Amz-Date")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Date", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Security-Token")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Security-Token", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Content-Sha256", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Algorithm")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Algorithm", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Signature")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Signature", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-SignedHeaders", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Credential")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Credential", valid_594230
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetOptionGroupDescription: JString (required)
  ##   Tags: JArray
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   TargetOptionGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetOptionGroupDescription` field"
  var valid_594231 = formData.getOrDefault("TargetOptionGroupDescription")
  valid_594231 = validateParameter(valid_594231, JString, required = true,
                                 default = nil)
  if valid_594231 != nil:
    section.add "TargetOptionGroupDescription", valid_594231
  var valid_594232 = formData.getOrDefault("Tags")
  valid_594232 = validateParameter(valid_594232, JArray, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "Tags", valid_594232
  var valid_594233 = formData.getOrDefault("SourceOptionGroupIdentifier")
  valid_594233 = validateParameter(valid_594233, JString, required = true,
                                 default = nil)
  if valid_594233 != nil:
    section.add "SourceOptionGroupIdentifier", valid_594233
  var valid_594234 = formData.getOrDefault("TargetOptionGroupIdentifier")
  valid_594234 = validateParameter(valid_594234, JString, required = true,
                                 default = nil)
  if valid_594234 != nil:
    section.add "TargetOptionGroupIdentifier", valid_594234
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594235: Call_PostCopyOptionGroup_594219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594235.validator(path, query, header, formData, body)
  let scheme = call_594235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594235.url(scheme.get, call_594235.host, call_594235.base,
                         call_594235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594235, url, valid)

proc call*(call_594236: Call_PostCopyOptionGroup_594219;
          TargetOptionGroupDescription: string;
          SourceOptionGroupIdentifier: string;
          TargetOptionGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postCopyOptionGroup
  ##   TargetOptionGroupDescription: string (required)
  ##   Tags: JArray
  ##   SourceOptionGroupIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetOptionGroupIdentifier: string (required)
  ##   Version: string (required)
  var query_594237 = newJObject()
  var formData_594238 = newJObject()
  add(formData_594238, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  if Tags != nil:
    formData_594238.add "Tags", Tags
  add(formData_594238, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_594237, "Action", newJString(Action))
  add(formData_594238, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(query_594237, "Version", newJString(Version))
  result = call_594236.call(nil, query_594237, nil, formData_594238, nil)

var postCopyOptionGroup* = Call_PostCopyOptionGroup_594219(
    name: "postCopyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_PostCopyOptionGroup_594220, base: "/",
    url: url_PostCopyOptionGroup_594221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyOptionGroup_594200 = ref object of OpenApiRestCall_593421
proc url_GetCopyOptionGroup_594202(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyOptionGroup_594201(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   TargetOptionGroupDescription: JString (required)
  ##   Version: JString (required)
  ##   TargetOptionGroupIdentifier: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceOptionGroupIdentifier` field"
  var valid_594203 = query.getOrDefault("SourceOptionGroupIdentifier")
  valid_594203 = validateParameter(valid_594203, JString, required = true,
                                 default = nil)
  if valid_594203 != nil:
    section.add "SourceOptionGroupIdentifier", valid_594203
  var valid_594204 = query.getOrDefault("Tags")
  valid_594204 = validateParameter(valid_594204, JArray, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "Tags", valid_594204
  var valid_594205 = query.getOrDefault("Action")
  valid_594205 = validateParameter(valid_594205, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_594205 != nil:
    section.add "Action", valid_594205
  var valid_594206 = query.getOrDefault("TargetOptionGroupDescription")
  valid_594206 = validateParameter(valid_594206, JString, required = true,
                                 default = nil)
  if valid_594206 != nil:
    section.add "TargetOptionGroupDescription", valid_594206
  var valid_594207 = query.getOrDefault("Version")
  valid_594207 = validateParameter(valid_594207, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594207 != nil:
    section.add "Version", valid_594207
  var valid_594208 = query.getOrDefault("TargetOptionGroupIdentifier")
  valid_594208 = validateParameter(valid_594208, JString, required = true,
                                 default = nil)
  if valid_594208 != nil:
    section.add "TargetOptionGroupIdentifier", valid_594208
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
  var valid_594209 = header.getOrDefault("X-Amz-Date")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Date", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Security-Token")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Security-Token", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Content-Sha256", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Algorithm")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Algorithm", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Signature")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Signature", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-SignedHeaders", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Credential")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Credential", valid_594215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594216: Call_GetCopyOptionGroup_594200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594216.validator(path, query, header, formData, body)
  let scheme = call_594216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594216.url(scheme.get, call_594216.host, call_594216.base,
                         call_594216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594216, url, valid)

proc call*(call_594217: Call_GetCopyOptionGroup_594200;
          SourceOptionGroupIdentifier: string;
          TargetOptionGroupDescription: string;
          TargetOptionGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCopyOptionGroup
  ##   SourceOptionGroupIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   TargetOptionGroupDescription: string (required)
  ##   Version: string (required)
  ##   TargetOptionGroupIdentifier: string (required)
  var query_594218 = newJObject()
  add(query_594218, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  if Tags != nil:
    query_594218.add "Tags", Tags
  add(query_594218, "Action", newJString(Action))
  add(query_594218, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(query_594218, "Version", newJString(Version))
  add(query_594218, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  result = call_594217.call(nil, query_594218, nil, nil, nil)

var getCopyOptionGroup* = Call_GetCopyOptionGroup_594200(
    name: "getCopyOptionGroup", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyOptionGroup", validator: validate_GetCopyOptionGroup_594201,
    base: "/", url: url_GetCopyOptionGroup_594202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_594282 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBInstance_594284(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_594283(path: JsonNode; query: JsonNode;
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
  var valid_594285 = query.getOrDefault("Action")
  valid_594285 = validateParameter(valid_594285, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_594285 != nil:
    section.add "Action", valid_594285
  var valid_594286 = query.getOrDefault("Version")
  valid_594286 = validateParameter(valid_594286, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594286 != nil:
    section.add "Version", valid_594286
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
  var valid_594287 = header.getOrDefault("X-Amz-Date")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Date", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Security-Token")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Security-Token", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Content-Sha256", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Algorithm")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Algorithm", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Signature")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Signature", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-SignedHeaders", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Credential")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Credential", valid_594293
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
  ##   TdeCredentialArn: JString
  ##   DBSubnetGroupName: JString
  ##   TdeCredentialPassword: JString
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   AllocatedStorage: JInt (required)
  ##   PubliclyAccessible: JBool
  ##   MasterUsername: JString (required)
  ##   StorageType: JString
  ##   DBInstanceClass: JString (required)
  ##   CharacterSetName: JString
  ##   PreferredBackupWindow: JString
  ##   LicenseModel: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   EngineVersion: JString
  ##   PreferredMaintenanceWindow: JString
  section = newJObject()
  var valid_594294 = formData.getOrDefault("DBSecurityGroups")
  valid_594294 = validateParameter(valid_594294, JArray, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "DBSecurityGroups", valid_594294
  var valid_594295 = formData.getOrDefault("Port")
  valid_594295 = validateParameter(valid_594295, JInt, required = false, default = nil)
  if valid_594295 != nil:
    section.add "Port", valid_594295
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_594296 = formData.getOrDefault("Engine")
  valid_594296 = validateParameter(valid_594296, JString, required = true,
                                 default = nil)
  if valid_594296 != nil:
    section.add "Engine", valid_594296
  var valid_594297 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_594297 = validateParameter(valid_594297, JArray, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "VpcSecurityGroupIds", valid_594297
  var valid_594298 = formData.getOrDefault("Iops")
  valid_594298 = validateParameter(valid_594298, JInt, required = false, default = nil)
  if valid_594298 != nil:
    section.add "Iops", valid_594298
  var valid_594299 = formData.getOrDefault("DBName")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "DBName", valid_594299
  var valid_594300 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594300 = validateParameter(valid_594300, JString, required = true,
                                 default = nil)
  if valid_594300 != nil:
    section.add "DBInstanceIdentifier", valid_594300
  var valid_594301 = formData.getOrDefault("BackupRetentionPeriod")
  valid_594301 = validateParameter(valid_594301, JInt, required = false, default = nil)
  if valid_594301 != nil:
    section.add "BackupRetentionPeriod", valid_594301
  var valid_594302 = formData.getOrDefault("DBParameterGroupName")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "DBParameterGroupName", valid_594302
  var valid_594303 = formData.getOrDefault("OptionGroupName")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "OptionGroupName", valid_594303
  var valid_594304 = formData.getOrDefault("Tags")
  valid_594304 = validateParameter(valid_594304, JArray, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "Tags", valid_594304
  var valid_594305 = formData.getOrDefault("MasterUserPassword")
  valid_594305 = validateParameter(valid_594305, JString, required = true,
                                 default = nil)
  if valid_594305 != nil:
    section.add "MasterUserPassword", valid_594305
  var valid_594306 = formData.getOrDefault("TdeCredentialArn")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "TdeCredentialArn", valid_594306
  var valid_594307 = formData.getOrDefault("DBSubnetGroupName")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "DBSubnetGroupName", valid_594307
  var valid_594308 = formData.getOrDefault("TdeCredentialPassword")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "TdeCredentialPassword", valid_594308
  var valid_594309 = formData.getOrDefault("AvailabilityZone")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "AvailabilityZone", valid_594309
  var valid_594310 = formData.getOrDefault("MultiAZ")
  valid_594310 = validateParameter(valid_594310, JBool, required = false, default = nil)
  if valid_594310 != nil:
    section.add "MultiAZ", valid_594310
  var valid_594311 = formData.getOrDefault("AllocatedStorage")
  valid_594311 = validateParameter(valid_594311, JInt, required = true, default = nil)
  if valid_594311 != nil:
    section.add "AllocatedStorage", valid_594311
  var valid_594312 = formData.getOrDefault("PubliclyAccessible")
  valid_594312 = validateParameter(valid_594312, JBool, required = false, default = nil)
  if valid_594312 != nil:
    section.add "PubliclyAccessible", valid_594312
  var valid_594313 = formData.getOrDefault("MasterUsername")
  valid_594313 = validateParameter(valid_594313, JString, required = true,
                                 default = nil)
  if valid_594313 != nil:
    section.add "MasterUsername", valid_594313
  var valid_594314 = formData.getOrDefault("StorageType")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "StorageType", valid_594314
  var valid_594315 = formData.getOrDefault("DBInstanceClass")
  valid_594315 = validateParameter(valid_594315, JString, required = true,
                                 default = nil)
  if valid_594315 != nil:
    section.add "DBInstanceClass", valid_594315
  var valid_594316 = formData.getOrDefault("CharacterSetName")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "CharacterSetName", valid_594316
  var valid_594317 = formData.getOrDefault("PreferredBackupWindow")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "PreferredBackupWindow", valid_594317
  var valid_594318 = formData.getOrDefault("LicenseModel")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "LicenseModel", valid_594318
  var valid_594319 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594319 = validateParameter(valid_594319, JBool, required = false, default = nil)
  if valid_594319 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594319
  var valid_594320 = formData.getOrDefault("EngineVersion")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "EngineVersion", valid_594320
  var valid_594321 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "PreferredMaintenanceWindow", valid_594321
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594322: Call_PostCreateDBInstance_594282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594322.validator(path, query, header, formData, body)
  let scheme = call_594322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594322.url(scheme.get, call_594322.host, call_594322.base,
                         call_594322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594322, url, valid)

proc call*(call_594323: Call_PostCreateDBInstance_594282; Engine: string;
          DBInstanceIdentifier: string; MasterUserPassword: string;
          AllocatedStorage: int; MasterUsername: string; DBInstanceClass: string;
          DBSecurityGroups: JsonNode = nil; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; Iops: int = 0; DBName: string = "";
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          OptionGroupName: string = ""; Tags: JsonNode = nil;
          TdeCredentialArn: string = ""; DBSubnetGroupName: string = "";
          TdeCredentialPassword: string = ""; AvailabilityZone: string = "";
          MultiAZ: bool = false; Action: string = "CreateDBInstance";
          PubliclyAccessible: bool = false; StorageType: string = "";
          CharacterSetName: string = ""; PreferredBackupWindow: string = "";
          LicenseModel: string = ""; AutoMinorVersionUpgrade: bool = false;
          EngineVersion: string = ""; Version: string = "2014-09-01";
          PreferredMaintenanceWindow: string = ""): Recallable =
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
  ##   TdeCredentialArn: string
  ##   DBSubnetGroupName: string
  ##   TdeCredentialPassword: string
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   AllocatedStorage: int (required)
  ##   PubliclyAccessible: bool
  ##   MasterUsername: string (required)
  ##   StorageType: string
  ##   DBInstanceClass: string (required)
  ##   CharacterSetName: string
  ##   PreferredBackupWindow: string
  ##   LicenseModel: string
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  var query_594324 = newJObject()
  var formData_594325 = newJObject()
  if DBSecurityGroups != nil:
    formData_594325.add "DBSecurityGroups", DBSecurityGroups
  add(formData_594325, "Port", newJInt(Port))
  add(formData_594325, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_594325.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_594325, "Iops", newJInt(Iops))
  add(formData_594325, "DBName", newJString(DBName))
  add(formData_594325, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594325, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_594325, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_594325, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_594325.add "Tags", Tags
  add(formData_594325, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_594325, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_594325, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_594325, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_594325, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_594325, "MultiAZ", newJBool(MultiAZ))
  add(query_594324, "Action", newJString(Action))
  add(formData_594325, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_594325, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_594325, "MasterUsername", newJString(MasterUsername))
  add(formData_594325, "StorageType", newJString(StorageType))
  add(formData_594325, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594325, "CharacterSetName", newJString(CharacterSetName))
  add(formData_594325, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_594325, "LicenseModel", newJString(LicenseModel))
  add(formData_594325, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_594325, "EngineVersion", newJString(EngineVersion))
  add(query_594324, "Version", newJString(Version))
  add(formData_594325, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_594323.call(nil, query_594324, nil, formData_594325, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_594282(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_594283, base: "/",
    url: url_PostCreateDBInstance_594284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_594239 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBInstance_594241(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_594240(path: JsonNode; query: JsonNode;
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
  ##   StorageType: JString
  ##   OptionGroupName: JString
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: JString (required)
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: JBool
  ##   TdeCredentialPassword: JString
  ##   LicenseModel: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBName: JString
  ##   DBParameterGroupName: JString
  ##   Tags: JArray
  ##   DBInstanceClass: JString (required)
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##   CharacterSetName: JString
  ##   TdeCredentialArn: JString
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
  var valid_594242 = query.getOrDefault("Engine")
  valid_594242 = validateParameter(valid_594242, JString, required = true,
                                 default = nil)
  if valid_594242 != nil:
    section.add "Engine", valid_594242
  var valid_594243 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "PreferredMaintenanceWindow", valid_594243
  var valid_594244 = query.getOrDefault("AllocatedStorage")
  valid_594244 = validateParameter(valid_594244, JInt, required = true, default = nil)
  if valid_594244 != nil:
    section.add "AllocatedStorage", valid_594244
  var valid_594245 = query.getOrDefault("StorageType")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "StorageType", valid_594245
  var valid_594246 = query.getOrDefault("OptionGroupName")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "OptionGroupName", valid_594246
  var valid_594247 = query.getOrDefault("DBSecurityGroups")
  valid_594247 = validateParameter(valid_594247, JArray, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "DBSecurityGroups", valid_594247
  var valid_594248 = query.getOrDefault("MasterUserPassword")
  valid_594248 = validateParameter(valid_594248, JString, required = true,
                                 default = nil)
  if valid_594248 != nil:
    section.add "MasterUserPassword", valid_594248
  var valid_594249 = query.getOrDefault("AvailabilityZone")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "AvailabilityZone", valid_594249
  var valid_594250 = query.getOrDefault("Iops")
  valid_594250 = validateParameter(valid_594250, JInt, required = false, default = nil)
  if valid_594250 != nil:
    section.add "Iops", valid_594250
  var valid_594251 = query.getOrDefault("VpcSecurityGroupIds")
  valid_594251 = validateParameter(valid_594251, JArray, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "VpcSecurityGroupIds", valid_594251
  var valid_594252 = query.getOrDefault("MultiAZ")
  valid_594252 = validateParameter(valid_594252, JBool, required = false, default = nil)
  if valid_594252 != nil:
    section.add "MultiAZ", valid_594252
  var valid_594253 = query.getOrDefault("TdeCredentialPassword")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "TdeCredentialPassword", valid_594253
  var valid_594254 = query.getOrDefault("LicenseModel")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "LicenseModel", valid_594254
  var valid_594255 = query.getOrDefault("BackupRetentionPeriod")
  valid_594255 = validateParameter(valid_594255, JInt, required = false, default = nil)
  if valid_594255 != nil:
    section.add "BackupRetentionPeriod", valid_594255
  var valid_594256 = query.getOrDefault("DBName")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "DBName", valid_594256
  var valid_594257 = query.getOrDefault("DBParameterGroupName")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "DBParameterGroupName", valid_594257
  var valid_594258 = query.getOrDefault("Tags")
  valid_594258 = validateParameter(valid_594258, JArray, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "Tags", valid_594258
  var valid_594259 = query.getOrDefault("DBInstanceClass")
  valid_594259 = validateParameter(valid_594259, JString, required = true,
                                 default = nil)
  if valid_594259 != nil:
    section.add "DBInstanceClass", valid_594259
  var valid_594260 = query.getOrDefault("Action")
  valid_594260 = validateParameter(valid_594260, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_594260 != nil:
    section.add "Action", valid_594260
  var valid_594261 = query.getOrDefault("DBSubnetGroupName")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "DBSubnetGroupName", valid_594261
  var valid_594262 = query.getOrDefault("CharacterSetName")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "CharacterSetName", valid_594262
  var valid_594263 = query.getOrDefault("TdeCredentialArn")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "TdeCredentialArn", valid_594263
  var valid_594264 = query.getOrDefault("PubliclyAccessible")
  valid_594264 = validateParameter(valid_594264, JBool, required = false, default = nil)
  if valid_594264 != nil:
    section.add "PubliclyAccessible", valid_594264
  var valid_594265 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594265 = validateParameter(valid_594265, JBool, required = false, default = nil)
  if valid_594265 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594265
  var valid_594266 = query.getOrDefault("EngineVersion")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "EngineVersion", valid_594266
  var valid_594267 = query.getOrDefault("Port")
  valid_594267 = validateParameter(valid_594267, JInt, required = false, default = nil)
  if valid_594267 != nil:
    section.add "Port", valid_594267
  var valid_594268 = query.getOrDefault("PreferredBackupWindow")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "PreferredBackupWindow", valid_594268
  var valid_594269 = query.getOrDefault("Version")
  valid_594269 = validateParameter(valid_594269, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594269 != nil:
    section.add "Version", valid_594269
  var valid_594270 = query.getOrDefault("DBInstanceIdentifier")
  valid_594270 = validateParameter(valid_594270, JString, required = true,
                                 default = nil)
  if valid_594270 != nil:
    section.add "DBInstanceIdentifier", valid_594270
  var valid_594271 = query.getOrDefault("MasterUsername")
  valid_594271 = validateParameter(valid_594271, JString, required = true,
                                 default = nil)
  if valid_594271 != nil:
    section.add "MasterUsername", valid_594271
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
  var valid_594272 = header.getOrDefault("X-Amz-Date")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Date", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Security-Token")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Security-Token", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Content-Sha256", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Algorithm")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Algorithm", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Signature")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Signature", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-SignedHeaders", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-Credential")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Credential", valid_594278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594279: Call_GetCreateDBInstance_594239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594279.validator(path, query, header, formData, body)
  let scheme = call_594279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594279.url(scheme.get, call_594279.host, call_594279.base,
                         call_594279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594279, url, valid)

proc call*(call_594280: Call_GetCreateDBInstance_594239; Engine: string;
          AllocatedStorage: int; MasterUserPassword: string;
          DBInstanceClass: string; DBInstanceIdentifier: string;
          MasterUsername: string; PreferredMaintenanceWindow: string = "";
          StorageType: string = ""; OptionGroupName: string = "";
          DBSecurityGroups: JsonNode = nil; AvailabilityZone: string = "";
          Iops: int = 0; VpcSecurityGroupIds: JsonNode = nil; MultiAZ: bool = false;
          TdeCredentialPassword: string = ""; LicenseModel: string = "";
          BackupRetentionPeriod: int = 0; DBName: string = "";
          DBParameterGroupName: string = ""; Tags: JsonNode = nil;
          Action: string = "CreateDBInstance"; DBSubnetGroupName: string = "";
          CharacterSetName: string = ""; TdeCredentialArn: string = "";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          EngineVersion: string = ""; Port: int = 0; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBInstance
  ##   Engine: string (required)
  ##   PreferredMaintenanceWindow: string
  ##   AllocatedStorage: int (required)
  ##   StorageType: string
  ##   OptionGroupName: string
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: string (required)
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: bool
  ##   TdeCredentialPassword: string
  ##   LicenseModel: string
  ##   BackupRetentionPeriod: int
  ##   DBName: string
  ##   DBParameterGroupName: string
  ##   Tags: JArray
  ##   DBInstanceClass: string (required)
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   CharacterSetName: string
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   Port: int
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   MasterUsername: string (required)
  var query_594281 = newJObject()
  add(query_594281, "Engine", newJString(Engine))
  add(query_594281, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_594281, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_594281, "StorageType", newJString(StorageType))
  add(query_594281, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_594281.add "DBSecurityGroups", DBSecurityGroups
  add(query_594281, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_594281, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594281, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_594281.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_594281, "MultiAZ", newJBool(MultiAZ))
  add(query_594281, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_594281, "LicenseModel", newJString(LicenseModel))
  add(query_594281, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_594281, "DBName", newJString(DBName))
  add(query_594281, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_594281.add "Tags", Tags
  add(query_594281, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594281, "Action", newJString(Action))
  add(query_594281, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594281, "CharacterSetName", newJString(CharacterSetName))
  add(query_594281, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_594281, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594281, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594281, "EngineVersion", newJString(EngineVersion))
  add(query_594281, "Port", newJInt(Port))
  add(query_594281, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_594281, "Version", newJString(Version))
  add(query_594281, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594281, "MasterUsername", newJString(MasterUsername))
  result = call_594280.call(nil, query_594281, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_594239(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_594240, base: "/",
    url: url_GetCreateDBInstance_594241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_594353 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBInstanceReadReplica_594355(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_594354(path: JsonNode;
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
  var valid_594356 = query.getOrDefault("Action")
  valid_594356 = validateParameter(valid_594356, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_594356 != nil:
    section.add "Action", valid_594356
  var valid_594357 = query.getOrDefault("Version")
  valid_594357 = validateParameter(valid_594357, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594357 != nil:
    section.add "Version", valid_594357
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
  var valid_594358 = header.getOrDefault("X-Amz-Date")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = nil)
  if valid_594358 != nil:
    section.add "X-Amz-Date", valid_594358
  var valid_594359 = header.getOrDefault("X-Amz-Security-Token")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Security-Token", valid_594359
  var valid_594360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "X-Amz-Content-Sha256", valid_594360
  var valid_594361 = header.getOrDefault("X-Amz-Algorithm")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Algorithm", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-Signature")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Signature", valid_594362
  var valid_594363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-SignedHeaders", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Credential")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Credential", valid_594364
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
  ##   StorageType: JString
  ##   DBInstanceClass: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_594365 = formData.getOrDefault("Port")
  valid_594365 = validateParameter(valid_594365, JInt, required = false, default = nil)
  if valid_594365 != nil:
    section.add "Port", valid_594365
  var valid_594366 = formData.getOrDefault("Iops")
  valid_594366 = validateParameter(valid_594366, JInt, required = false, default = nil)
  if valid_594366 != nil:
    section.add "Iops", valid_594366
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594367 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594367 = validateParameter(valid_594367, JString, required = true,
                                 default = nil)
  if valid_594367 != nil:
    section.add "DBInstanceIdentifier", valid_594367
  var valid_594368 = formData.getOrDefault("OptionGroupName")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "OptionGroupName", valid_594368
  var valid_594369 = formData.getOrDefault("Tags")
  valid_594369 = validateParameter(valid_594369, JArray, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "Tags", valid_594369
  var valid_594370 = formData.getOrDefault("DBSubnetGroupName")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "DBSubnetGroupName", valid_594370
  var valid_594371 = formData.getOrDefault("AvailabilityZone")
  valid_594371 = validateParameter(valid_594371, JString, required = false,
                                 default = nil)
  if valid_594371 != nil:
    section.add "AvailabilityZone", valid_594371
  var valid_594372 = formData.getOrDefault("PubliclyAccessible")
  valid_594372 = validateParameter(valid_594372, JBool, required = false, default = nil)
  if valid_594372 != nil:
    section.add "PubliclyAccessible", valid_594372
  var valid_594373 = formData.getOrDefault("StorageType")
  valid_594373 = validateParameter(valid_594373, JString, required = false,
                                 default = nil)
  if valid_594373 != nil:
    section.add "StorageType", valid_594373
  var valid_594374 = formData.getOrDefault("DBInstanceClass")
  valid_594374 = validateParameter(valid_594374, JString, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "DBInstanceClass", valid_594374
  var valid_594375 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_594375 = validateParameter(valid_594375, JString, required = true,
                                 default = nil)
  if valid_594375 != nil:
    section.add "SourceDBInstanceIdentifier", valid_594375
  var valid_594376 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594376 = validateParameter(valid_594376, JBool, required = false, default = nil)
  if valid_594376 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594376
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594377: Call_PostCreateDBInstanceReadReplica_594353;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594377.validator(path, query, header, formData, body)
  let scheme = call_594377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594377.url(scheme.get, call_594377.host, call_594377.base,
                         call_594377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594377, url, valid)

proc call*(call_594378: Call_PostCreateDBInstanceReadReplica_594353;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Port: int = 0; Iops: int = 0; OptionGroupName: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; AvailabilityZone: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          PubliclyAccessible: bool = false; StorageType: string = "";
          DBInstanceClass: string = ""; AutoMinorVersionUpgrade: bool = false;
          Version: string = "2014-09-01"): Recallable =
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
  ##   StorageType: string
  ##   DBInstanceClass: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   Version: string (required)
  var query_594379 = newJObject()
  var formData_594380 = newJObject()
  add(formData_594380, "Port", newJInt(Port))
  add(formData_594380, "Iops", newJInt(Iops))
  add(formData_594380, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594380, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_594380.add "Tags", Tags
  add(formData_594380, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_594380, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594379, "Action", newJString(Action))
  add(formData_594380, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_594380, "StorageType", newJString(StorageType))
  add(formData_594380, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594380, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_594380, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_594379, "Version", newJString(Version))
  result = call_594378.call(nil, query_594379, nil, formData_594380, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_594353(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_594354, base: "/",
    url: url_PostCreateDBInstanceReadReplica_594355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_594326 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBInstanceReadReplica_594328(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_594327(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   StorageType: JString
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
  var valid_594329 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_594329 = validateParameter(valid_594329, JString, required = true,
                                 default = nil)
  if valid_594329 != nil:
    section.add "SourceDBInstanceIdentifier", valid_594329
  var valid_594330 = query.getOrDefault("StorageType")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "StorageType", valid_594330
  var valid_594331 = query.getOrDefault("OptionGroupName")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "OptionGroupName", valid_594331
  var valid_594332 = query.getOrDefault("AvailabilityZone")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "AvailabilityZone", valid_594332
  var valid_594333 = query.getOrDefault("Iops")
  valid_594333 = validateParameter(valid_594333, JInt, required = false, default = nil)
  if valid_594333 != nil:
    section.add "Iops", valid_594333
  var valid_594334 = query.getOrDefault("Tags")
  valid_594334 = validateParameter(valid_594334, JArray, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "Tags", valid_594334
  var valid_594335 = query.getOrDefault("DBInstanceClass")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "DBInstanceClass", valid_594335
  var valid_594336 = query.getOrDefault("Action")
  valid_594336 = validateParameter(valid_594336, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_594336 != nil:
    section.add "Action", valid_594336
  var valid_594337 = query.getOrDefault("DBSubnetGroupName")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "DBSubnetGroupName", valid_594337
  var valid_594338 = query.getOrDefault("PubliclyAccessible")
  valid_594338 = validateParameter(valid_594338, JBool, required = false, default = nil)
  if valid_594338 != nil:
    section.add "PubliclyAccessible", valid_594338
  var valid_594339 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594339 = validateParameter(valid_594339, JBool, required = false, default = nil)
  if valid_594339 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594339
  var valid_594340 = query.getOrDefault("Port")
  valid_594340 = validateParameter(valid_594340, JInt, required = false, default = nil)
  if valid_594340 != nil:
    section.add "Port", valid_594340
  var valid_594341 = query.getOrDefault("Version")
  valid_594341 = validateParameter(valid_594341, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594341 != nil:
    section.add "Version", valid_594341
  var valid_594342 = query.getOrDefault("DBInstanceIdentifier")
  valid_594342 = validateParameter(valid_594342, JString, required = true,
                                 default = nil)
  if valid_594342 != nil:
    section.add "DBInstanceIdentifier", valid_594342
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
  var valid_594343 = header.getOrDefault("X-Amz-Date")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Date", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-Security-Token")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Security-Token", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-Content-Sha256", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-Algorithm")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Algorithm", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Signature")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Signature", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-SignedHeaders", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Credential")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Credential", valid_594349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594350: Call_GetCreateDBInstanceReadReplica_594326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594350.validator(path, query, header, formData, body)
  let scheme = call_594350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594350.url(scheme.get, call_594350.host, call_594350.base,
                         call_594350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594350, url, valid)

proc call*(call_594351: Call_GetCreateDBInstanceReadReplica_594326;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          StorageType: string = ""; OptionGroupName: string = "";
          AvailabilityZone: string = ""; Iops: int = 0; Tags: JsonNode = nil;
          DBInstanceClass: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Port: int = 0;
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   SourceDBInstanceIdentifier: string (required)
  ##   StorageType: string
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
  var query_594352 = newJObject()
  add(query_594352, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_594352, "StorageType", newJString(StorageType))
  add(query_594352, "OptionGroupName", newJString(OptionGroupName))
  add(query_594352, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594352, "Iops", newJInt(Iops))
  if Tags != nil:
    query_594352.add "Tags", Tags
  add(query_594352, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594352, "Action", newJString(Action))
  add(query_594352, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594352, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594352, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594352, "Port", newJInt(Port))
  add(query_594352, "Version", newJString(Version))
  add(query_594352, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594351.call(nil, query_594352, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_594326(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_594327, base: "/",
    url: url_GetCreateDBInstanceReadReplica_594328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_594400 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBParameterGroup_594402(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBParameterGroup_594401(path: JsonNode; query: JsonNode;
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
  var valid_594403 = query.getOrDefault("Action")
  valid_594403 = validateParameter(valid_594403, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_594403 != nil:
    section.add "Action", valid_594403
  var valid_594404 = query.getOrDefault("Version")
  valid_594404 = validateParameter(valid_594404, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594404 != nil:
    section.add "Version", valid_594404
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
  var valid_594405 = header.getOrDefault("X-Amz-Date")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "X-Amz-Date", valid_594405
  var valid_594406 = header.getOrDefault("X-Amz-Security-Token")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-Security-Token", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Content-Sha256", valid_594407
  var valid_594408 = header.getOrDefault("X-Amz-Algorithm")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "X-Amz-Algorithm", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-Signature")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Signature", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-SignedHeaders", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Credential")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Credential", valid_594411
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594412 = formData.getOrDefault("DBParameterGroupName")
  valid_594412 = validateParameter(valid_594412, JString, required = true,
                                 default = nil)
  if valid_594412 != nil:
    section.add "DBParameterGroupName", valid_594412
  var valid_594413 = formData.getOrDefault("Tags")
  valid_594413 = validateParameter(valid_594413, JArray, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "Tags", valid_594413
  var valid_594414 = formData.getOrDefault("DBParameterGroupFamily")
  valid_594414 = validateParameter(valid_594414, JString, required = true,
                                 default = nil)
  if valid_594414 != nil:
    section.add "DBParameterGroupFamily", valid_594414
  var valid_594415 = formData.getOrDefault("Description")
  valid_594415 = validateParameter(valid_594415, JString, required = true,
                                 default = nil)
  if valid_594415 != nil:
    section.add "Description", valid_594415
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594416: Call_PostCreateDBParameterGroup_594400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594416.validator(path, query, header, formData, body)
  let scheme = call_594416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594416.url(scheme.get, call_594416.host, call_594416.base,
                         call_594416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594416, url, valid)

proc call*(call_594417: Call_PostCreateDBParameterGroup_594400;
          DBParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Description: string (required)
  var query_594418 = newJObject()
  var formData_594419 = newJObject()
  add(formData_594419, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_594419.add "Tags", Tags
  add(query_594418, "Action", newJString(Action))
  add(formData_594419, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_594418, "Version", newJString(Version))
  add(formData_594419, "Description", newJString(Description))
  result = call_594417.call(nil, query_594418, nil, formData_594419, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_594400(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_594401, base: "/",
    url: url_PostCreateDBParameterGroup_594402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_594381 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBParameterGroup_594383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBParameterGroup_594382(path: JsonNode; query: JsonNode;
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
  var valid_594384 = query.getOrDefault("Description")
  valid_594384 = validateParameter(valid_594384, JString, required = true,
                                 default = nil)
  if valid_594384 != nil:
    section.add "Description", valid_594384
  var valid_594385 = query.getOrDefault("DBParameterGroupFamily")
  valid_594385 = validateParameter(valid_594385, JString, required = true,
                                 default = nil)
  if valid_594385 != nil:
    section.add "DBParameterGroupFamily", valid_594385
  var valid_594386 = query.getOrDefault("Tags")
  valid_594386 = validateParameter(valid_594386, JArray, required = false,
                                 default = nil)
  if valid_594386 != nil:
    section.add "Tags", valid_594386
  var valid_594387 = query.getOrDefault("DBParameterGroupName")
  valid_594387 = validateParameter(valid_594387, JString, required = true,
                                 default = nil)
  if valid_594387 != nil:
    section.add "DBParameterGroupName", valid_594387
  var valid_594388 = query.getOrDefault("Action")
  valid_594388 = validateParameter(valid_594388, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_594388 != nil:
    section.add "Action", valid_594388
  var valid_594389 = query.getOrDefault("Version")
  valid_594389 = validateParameter(valid_594389, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594389 != nil:
    section.add "Version", valid_594389
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
  var valid_594390 = header.getOrDefault("X-Amz-Date")
  valid_594390 = validateParameter(valid_594390, JString, required = false,
                                 default = nil)
  if valid_594390 != nil:
    section.add "X-Amz-Date", valid_594390
  var valid_594391 = header.getOrDefault("X-Amz-Security-Token")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-Security-Token", valid_594391
  var valid_594392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Content-Sha256", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-Algorithm")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Algorithm", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Signature")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Signature", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-SignedHeaders", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Credential")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Credential", valid_594396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594397: Call_GetCreateDBParameterGroup_594381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594397.validator(path, query, header, formData, body)
  let scheme = call_594397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594397.url(scheme.get, call_594397.host, call_594397.base,
                         call_594397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594397, url, valid)

proc call*(call_594398: Call_GetCreateDBParameterGroup_594381; Description: string;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Tags: JsonNode = nil; Action: string = "CreateDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Tags: JArray
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594399 = newJObject()
  add(query_594399, "Description", newJString(Description))
  add(query_594399, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_594399.add "Tags", Tags
  add(query_594399, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594399, "Action", newJString(Action))
  add(query_594399, "Version", newJString(Version))
  result = call_594398.call(nil, query_594399, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_594381(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_594382, base: "/",
    url: url_GetCreateDBParameterGroup_594383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_594438 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBSecurityGroup_594440(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSecurityGroup_594439(path: JsonNode; query: JsonNode;
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
  var valid_594441 = query.getOrDefault("Action")
  valid_594441 = validateParameter(valid_594441, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_594441 != nil:
    section.add "Action", valid_594441
  var valid_594442 = query.getOrDefault("Version")
  valid_594442 = validateParameter(valid_594442, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594442 != nil:
    section.add "Version", valid_594442
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
  var valid_594443 = header.getOrDefault("X-Amz-Date")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Date", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Security-Token")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Security-Token", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Content-Sha256", valid_594445
  var valid_594446 = header.getOrDefault("X-Amz-Algorithm")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "X-Amz-Algorithm", valid_594446
  var valid_594447 = header.getOrDefault("X-Amz-Signature")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-Signature", valid_594447
  var valid_594448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594448 = validateParameter(valid_594448, JString, required = false,
                                 default = nil)
  if valid_594448 != nil:
    section.add "X-Amz-SignedHeaders", valid_594448
  var valid_594449 = header.getOrDefault("X-Amz-Credential")
  valid_594449 = validateParameter(valid_594449, JString, required = false,
                                 default = nil)
  if valid_594449 != nil:
    section.add "X-Amz-Credential", valid_594449
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_594450 = formData.getOrDefault("DBSecurityGroupName")
  valid_594450 = validateParameter(valid_594450, JString, required = true,
                                 default = nil)
  if valid_594450 != nil:
    section.add "DBSecurityGroupName", valid_594450
  var valid_594451 = formData.getOrDefault("Tags")
  valid_594451 = validateParameter(valid_594451, JArray, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "Tags", valid_594451
  var valid_594452 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_594452 = validateParameter(valid_594452, JString, required = true,
                                 default = nil)
  if valid_594452 != nil:
    section.add "DBSecurityGroupDescription", valid_594452
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594453: Call_PostCreateDBSecurityGroup_594438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594453.validator(path, query, header, formData, body)
  let scheme = call_594453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594453.url(scheme.get, call_594453.host, call_594453.base,
                         call_594453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594453, url, valid)

proc call*(call_594454: Call_PostCreateDBSecurityGroup_594438;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_594455 = newJObject()
  var formData_594456 = newJObject()
  add(formData_594456, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_594456.add "Tags", Tags
  add(query_594455, "Action", newJString(Action))
  add(formData_594456, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_594455, "Version", newJString(Version))
  result = call_594454.call(nil, query_594455, nil, formData_594456, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_594438(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_594439, base: "/",
    url: url_PostCreateDBSecurityGroup_594440,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_594420 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBSecurityGroup_594422(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSecurityGroup_594421(path: JsonNode; query: JsonNode;
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
  var valid_594423 = query.getOrDefault("DBSecurityGroupName")
  valid_594423 = validateParameter(valid_594423, JString, required = true,
                                 default = nil)
  if valid_594423 != nil:
    section.add "DBSecurityGroupName", valid_594423
  var valid_594424 = query.getOrDefault("DBSecurityGroupDescription")
  valid_594424 = validateParameter(valid_594424, JString, required = true,
                                 default = nil)
  if valid_594424 != nil:
    section.add "DBSecurityGroupDescription", valid_594424
  var valid_594425 = query.getOrDefault("Tags")
  valid_594425 = validateParameter(valid_594425, JArray, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "Tags", valid_594425
  var valid_594426 = query.getOrDefault("Action")
  valid_594426 = validateParameter(valid_594426, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_594426 != nil:
    section.add "Action", valid_594426
  var valid_594427 = query.getOrDefault("Version")
  valid_594427 = validateParameter(valid_594427, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594427 != nil:
    section.add "Version", valid_594427
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
  var valid_594428 = header.getOrDefault("X-Amz-Date")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Date", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Security-Token")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Security-Token", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Content-Sha256", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-Algorithm")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-Algorithm", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-Signature")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-Signature", valid_594432
  var valid_594433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594433 = validateParameter(valid_594433, JString, required = false,
                                 default = nil)
  if valid_594433 != nil:
    section.add "X-Amz-SignedHeaders", valid_594433
  var valid_594434 = header.getOrDefault("X-Amz-Credential")
  valid_594434 = validateParameter(valid_594434, JString, required = false,
                                 default = nil)
  if valid_594434 != nil:
    section.add "X-Amz-Credential", valid_594434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594435: Call_GetCreateDBSecurityGroup_594420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594435.validator(path, query, header, formData, body)
  let scheme = call_594435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594435.url(scheme.get, call_594435.host, call_594435.base,
                         call_594435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594435, url, valid)

proc call*(call_594436: Call_GetCreateDBSecurityGroup_594420;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594437 = newJObject()
  add(query_594437, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594437, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_594437.add "Tags", Tags
  add(query_594437, "Action", newJString(Action))
  add(query_594437, "Version", newJString(Version))
  result = call_594436.call(nil, query_594437, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_594420(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_594421, base: "/",
    url: url_GetCreateDBSecurityGroup_594422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_594475 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBSnapshot_594477(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSnapshot_594476(path: JsonNode; query: JsonNode;
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
  var valid_594478 = query.getOrDefault("Action")
  valid_594478 = validateParameter(valid_594478, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_594478 != nil:
    section.add "Action", valid_594478
  var valid_594479 = query.getOrDefault("Version")
  valid_594479 = validateParameter(valid_594479, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594479 != nil:
    section.add "Version", valid_594479
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
  var valid_594480 = header.getOrDefault("X-Amz-Date")
  valid_594480 = validateParameter(valid_594480, JString, required = false,
                                 default = nil)
  if valid_594480 != nil:
    section.add "X-Amz-Date", valid_594480
  var valid_594481 = header.getOrDefault("X-Amz-Security-Token")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-Security-Token", valid_594481
  var valid_594482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "X-Amz-Content-Sha256", valid_594482
  var valid_594483 = header.getOrDefault("X-Amz-Algorithm")
  valid_594483 = validateParameter(valid_594483, JString, required = false,
                                 default = nil)
  if valid_594483 != nil:
    section.add "X-Amz-Algorithm", valid_594483
  var valid_594484 = header.getOrDefault("X-Amz-Signature")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-Signature", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-SignedHeaders", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Credential")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Credential", valid_594486
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594487 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594487 = validateParameter(valid_594487, JString, required = true,
                                 default = nil)
  if valid_594487 != nil:
    section.add "DBInstanceIdentifier", valid_594487
  var valid_594488 = formData.getOrDefault("Tags")
  valid_594488 = validateParameter(valid_594488, JArray, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "Tags", valid_594488
  var valid_594489 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_594489 = validateParameter(valid_594489, JString, required = true,
                                 default = nil)
  if valid_594489 != nil:
    section.add "DBSnapshotIdentifier", valid_594489
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594490: Call_PostCreateDBSnapshot_594475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594490.validator(path, query, header, formData, body)
  let scheme = call_594490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594490.url(scheme.get, call_594490.host, call_594490.base,
                         call_594490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594490, url, valid)

proc call*(call_594491: Call_PostCreateDBSnapshot_594475;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594492 = newJObject()
  var formData_594493 = newJObject()
  add(formData_594493, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_594493.add "Tags", Tags
  add(formData_594493, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_594492, "Action", newJString(Action))
  add(query_594492, "Version", newJString(Version))
  result = call_594491.call(nil, query_594492, nil, formData_594493, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_594475(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_594476, base: "/",
    url: url_PostCreateDBSnapshot_594477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_594457 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBSnapshot_594459(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSnapshot_594458(path: JsonNode; query: JsonNode;
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
  var valid_594460 = query.getOrDefault("Tags")
  valid_594460 = validateParameter(valid_594460, JArray, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "Tags", valid_594460
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594461 = query.getOrDefault("Action")
  valid_594461 = validateParameter(valid_594461, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_594461 != nil:
    section.add "Action", valid_594461
  var valid_594462 = query.getOrDefault("Version")
  valid_594462 = validateParameter(valid_594462, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594462 != nil:
    section.add "Version", valid_594462
  var valid_594463 = query.getOrDefault("DBInstanceIdentifier")
  valid_594463 = validateParameter(valid_594463, JString, required = true,
                                 default = nil)
  if valid_594463 != nil:
    section.add "DBInstanceIdentifier", valid_594463
  var valid_594464 = query.getOrDefault("DBSnapshotIdentifier")
  valid_594464 = validateParameter(valid_594464, JString, required = true,
                                 default = nil)
  if valid_594464 != nil:
    section.add "DBSnapshotIdentifier", valid_594464
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
  var valid_594465 = header.getOrDefault("X-Amz-Date")
  valid_594465 = validateParameter(valid_594465, JString, required = false,
                                 default = nil)
  if valid_594465 != nil:
    section.add "X-Amz-Date", valid_594465
  var valid_594466 = header.getOrDefault("X-Amz-Security-Token")
  valid_594466 = validateParameter(valid_594466, JString, required = false,
                                 default = nil)
  if valid_594466 != nil:
    section.add "X-Amz-Security-Token", valid_594466
  var valid_594467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594467 = validateParameter(valid_594467, JString, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "X-Amz-Content-Sha256", valid_594467
  var valid_594468 = header.getOrDefault("X-Amz-Algorithm")
  valid_594468 = validateParameter(valid_594468, JString, required = false,
                                 default = nil)
  if valid_594468 != nil:
    section.add "X-Amz-Algorithm", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-Signature")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-Signature", valid_594469
  var valid_594470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-SignedHeaders", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Credential")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Credential", valid_594471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594472: Call_GetCreateDBSnapshot_594457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594472.validator(path, query, header, formData, body)
  let scheme = call_594472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594472.url(scheme.get, call_594472.host, call_594472.base,
                         call_594472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594472, url, valid)

proc call*(call_594473: Call_GetCreateDBSnapshot_594457;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_594474 = newJObject()
  if Tags != nil:
    query_594474.add "Tags", Tags
  add(query_594474, "Action", newJString(Action))
  add(query_594474, "Version", newJString(Version))
  add(query_594474, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594474, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_594473.call(nil, query_594474, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_594457(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_594458, base: "/",
    url: url_GetCreateDBSnapshot_594459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_594513 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBSubnetGroup_594515(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_594514(path: JsonNode; query: JsonNode;
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
  var valid_594516 = query.getOrDefault("Action")
  valid_594516 = validateParameter(valid_594516, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_594516 != nil:
    section.add "Action", valid_594516
  var valid_594517 = query.getOrDefault("Version")
  valid_594517 = validateParameter(valid_594517, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594517 != nil:
    section.add "Version", valid_594517
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
  var valid_594518 = header.getOrDefault("X-Amz-Date")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Date", valid_594518
  var valid_594519 = header.getOrDefault("X-Amz-Security-Token")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Security-Token", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Content-Sha256", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-Algorithm")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Algorithm", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Signature")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Signature", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-SignedHeaders", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Credential")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Credential", valid_594524
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_594525 = formData.getOrDefault("Tags")
  valid_594525 = validateParameter(valid_594525, JArray, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "Tags", valid_594525
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_594526 = formData.getOrDefault("DBSubnetGroupName")
  valid_594526 = validateParameter(valid_594526, JString, required = true,
                                 default = nil)
  if valid_594526 != nil:
    section.add "DBSubnetGroupName", valid_594526
  var valid_594527 = formData.getOrDefault("SubnetIds")
  valid_594527 = validateParameter(valid_594527, JArray, required = true, default = nil)
  if valid_594527 != nil:
    section.add "SubnetIds", valid_594527
  var valid_594528 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_594528 = validateParameter(valid_594528, JString, required = true,
                                 default = nil)
  if valid_594528 != nil:
    section.add "DBSubnetGroupDescription", valid_594528
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594529: Call_PostCreateDBSubnetGroup_594513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594529.validator(path, query, header, formData, body)
  let scheme = call_594529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594529.url(scheme.get, call_594529.host, call_594529.base,
                         call_594529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594529, url, valid)

proc call*(call_594530: Call_PostCreateDBSubnetGroup_594513;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSubnetGroup
  ##   Tags: JArray
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_594531 = newJObject()
  var formData_594532 = newJObject()
  if Tags != nil:
    formData_594532.add "Tags", Tags
  add(formData_594532, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_594532.add "SubnetIds", SubnetIds
  add(query_594531, "Action", newJString(Action))
  add(formData_594532, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594531, "Version", newJString(Version))
  result = call_594530.call(nil, query_594531, nil, formData_594532, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_594513(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_594514, base: "/",
    url: url_PostCreateDBSubnetGroup_594515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_594494 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBSubnetGroup_594496(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_594495(path: JsonNode; query: JsonNode;
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
  var valid_594497 = query.getOrDefault("Tags")
  valid_594497 = validateParameter(valid_594497, JArray, required = false,
                                 default = nil)
  if valid_594497 != nil:
    section.add "Tags", valid_594497
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594498 = query.getOrDefault("Action")
  valid_594498 = validateParameter(valid_594498, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_594498 != nil:
    section.add "Action", valid_594498
  var valid_594499 = query.getOrDefault("DBSubnetGroupName")
  valid_594499 = validateParameter(valid_594499, JString, required = true,
                                 default = nil)
  if valid_594499 != nil:
    section.add "DBSubnetGroupName", valid_594499
  var valid_594500 = query.getOrDefault("SubnetIds")
  valid_594500 = validateParameter(valid_594500, JArray, required = true, default = nil)
  if valid_594500 != nil:
    section.add "SubnetIds", valid_594500
  var valid_594501 = query.getOrDefault("DBSubnetGroupDescription")
  valid_594501 = validateParameter(valid_594501, JString, required = true,
                                 default = nil)
  if valid_594501 != nil:
    section.add "DBSubnetGroupDescription", valid_594501
  var valid_594502 = query.getOrDefault("Version")
  valid_594502 = validateParameter(valid_594502, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594502 != nil:
    section.add "Version", valid_594502
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
  var valid_594503 = header.getOrDefault("X-Amz-Date")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Date", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-Security-Token")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Security-Token", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Content-Sha256", valid_594505
  var valid_594506 = header.getOrDefault("X-Amz-Algorithm")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-Algorithm", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-Signature")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Signature", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-SignedHeaders", valid_594508
  var valid_594509 = header.getOrDefault("X-Amz-Credential")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-Credential", valid_594509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594510: Call_GetCreateDBSubnetGroup_594494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594510.validator(path, query, header, formData, body)
  let scheme = call_594510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594510.url(scheme.get, call_594510.host, call_594510.base,
                         call_594510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594510, url, valid)

proc call*(call_594511: Call_GetCreateDBSubnetGroup_594494;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_594512 = newJObject()
  if Tags != nil:
    query_594512.add "Tags", Tags
  add(query_594512, "Action", newJString(Action))
  add(query_594512, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_594512.add "SubnetIds", SubnetIds
  add(query_594512, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594512, "Version", newJString(Version))
  result = call_594511.call(nil, query_594512, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_594494(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_594495, base: "/",
    url: url_GetCreateDBSubnetGroup_594496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_594555 = ref object of OpenApiRestCall_593421
proc url_PostCreateEventSubscription_594557(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEventSubscription_594556(path: JsonNode; query: JsonNode;
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
  var valid_594558 = query.getOrDefault("Action")
  valid_594558 = validateParameter(valid_594558, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_594558 != nil:
    section.add "Action", valid_594558
  var valid_594559 = query.getOrDefault("Version")
  valid_594559 = validateParameter(valid_594559, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594559 != nil:
    section.add "Version", valid_594559
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
  var valid_594560 = header.getOrDefault("X-Amz-Date")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Date", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-Security-Token")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-Security-Token", valid_594561
  var valid_594562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-Content-Sha256", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Algorithm")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Algorithm", valid_594563
  var valid_594564 = header.getOrDefault("X-Amz-Signature")
  valid_594564 = validateParameter(valid_594564, JString, required = false,
                                 default = nil)
  if valid_594564 != nil:
    section.add "X-Amz-Signature", valid_594564
  var valid_594565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-SignedHeaders", valid_594565
  var valid_594566 = header.getOrDefault("X-Amz-Credential")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-Credential", valid_594566
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
  var valid_594567 = formData.getOrDefault("Enabled")
  valid_594567 = validateParameter(valid_594567, JBool, required = false, default = nil)
  if valid_594567 != nil:
    section.add "Enabled", valid_594567
  var valid_594568 = formData.getOrDefault("EventCategories")
  valid_594568 = validateParameter(valid_594568, JArray, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "EventCategories", valid_594568
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_594569 = formData.getOrDefault("SnsTopicArn")
  valid_594569 = validateParameter(valid_594569, JString, required = true,
                                 default = nil)
  if valid_594569 != nil:
    section.add "SnsTopicArn", valid_594569
  var valid_594570 = formData.getOrDefault("SourceIds")
  valid_594570 = validateParameter(valid_594570, JArray, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "SourceIds", valid_594570
  var valid_594571 = formData.getOrDefault("Tags")
  valid_594571 = validateParameter(valid_594571, JArray, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "Tags", valid_594571
  var valid_594572 = formData.getOrDefault("SubscriptionName")
  valid_594572 = validateParameter(valid_594572, JString, required = true,
                                 default = nil)
  if valid_594572 != nil:
    section.add "SubscriptionName", valid_594572
  var valid_594573 = formData.getOrDefault("SourceType")
  valid_594573 = validateParameter(valid_594573, JString, required = false,
                                 default = nil)
  if valid_594573 != nil:
    section.add "SourceType", valid_594573
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594574: Call_PostCreateEventSubscription_594555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594574.validator(path, query, header, formData, body)
  let scheme = call_594574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594574.url(scheme.get, call_594574.host, call_594574.base,
                         call_594574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594574, url, valid)

proc call*(call_594575: Call_PostCreateEventSubscription_594555;
          SnsTopicArn: string; SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SourceIds: JsonNode = nil;
          Tags: JsonNode = nil; Action: string = "CreateEventSubscription";
          Version: string = "2014-09-01"; SourceType: string = ""): Recallable =
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
  var query_594576 = newJObject()
  var formData_594577 = newJObject()
  add(formData_594577, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_594577.add "EventCategories", EventCategories
  add(formData_594577, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_594577.add "SourceIds", SourceIds
  if Tags != nil:
    formData_594577.add "Tags", Tags
  add(formData_594577, "SubscriptionName", newJString(SubscriptionName))
  add(query_594576, "Action", newJString(Action))
  add(query_594576, "Version", newJString(Version))
  add(formData_594577, "SourceType", newJString(SourceType))
  result = call_594575.call(nil, query_594576, nil, formData_594577, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_594555(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_594556, base: "/",
    url: url_PostCreateEventSubscription_594557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_594533 = ref object of OpenApiRestCall_593421
proc url_GetCreateEventSubscription_594535(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEventSubscription_594534(path: JsonNode; query: JsonNode;
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
  var valid_594536 = query.getOrDefault("SourceType")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "SourceType", valid_594536
  var valid_594537 = query.getOrDefault("SourceIds")
  valid_594537 = validateParameter(valid_594537, JArray, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "SourceIds", valid_594537
  var valid_594538 = query.getOrDefault("Enabled")
  valid_594538 = validateParameter(valid_594538, JBool, required = false, default = nil)
  if valid_594538 != nil:
    section.add "Enabled", valid_594538
  var valid_594539 = query.getOrDefault("Tags")
  valid_594539 = validateParameter(valid_594539, JArray, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "Tags", valid_594539
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594540 = query.getOrDefault("Action")
  valid_594540 = validateParameter(valid_594540, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_594540 != nil:
    section.add "Action", valid_594540
  var valid_594541 = query.getOrDefault("SnsTopicArn")
  valid_594541 = validateParameter(valid_594541, JString, required = true,
                                 default = nil)
  if valid_594541 != nil:
    section.add "SnsTopicArn", valid_594541
  var valid_594542 = query.getOrDefault("EventCategories")
  valid_594542 = validateParameter(valid_594542, JArray, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "EventCategories", valid_594542
  var valid_594543 = query.getOrDefault("SubscriptionName")
  valid_594543 = validateParameter(valid_594543, JString, required = true,
                                 default = nil)
  if valid_594543 != nil:
    section.add "SubscriptionName", valid_594543
  var valid_594544 = query.getOrDefault("Version")
  valid_594544 = validateParameter(valid_594544, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594544 != nil:
    section.add "Version", valid_594544
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
  var valid_594545 = header.getOrDefault("X-Amz-Date")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-Date", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-Security-Token")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-Security-Token", valid_594546
  var valid_594547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "X-Amz-Content-Sha256", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-Algorithm")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-Algorithm", valid_594548
  var valid_594549 = header.getOrDefault("X-Amz-Signature")
  valid_594549 = validateParameter(valid_594549, JString, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "X-Amz-Signature", valid_594549
  var valid_594550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-SignedHeaders", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-Credential")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-Credential", valid_594551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594552: Call_GetCreateEventSubscription_594533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594552.validator(path, query, header, formData, body)
  let scheme = call_594552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594552.url(scheme.get, call_594552.host, call_594552.base,
                         call_594552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594552, url, valid)

proc call*(call_594553: Call_GetCreateEventSubscription_594533;
          SnsTopicArn: string; SubscriptionName: string; SourceType: string = "";
          SourceIds: JsonNode = nil; Enabled: bool = false; Tags: JsonNode = nil;
          Action: string = "CreateEventSubscription";
          EventCategories: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
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
  var query_594554 = newJObject()
  add(query_594554, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_594554.add "SourceIds", SourceIds
  add(query_594554, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_594554.add "Tags", Tags
  add(query_594554, "Action", newJString(Action))
  add(query_594554, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_594554.add "EventCategories", EventCategories
  add(query_594554, "SubscriptionName", newJString(SubscriptionName))
  add(query_594554, "Version", newJString(Version))
  result = call_594553.call(nil, query_594554, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_594533(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_594534, base: "/",
    url: url_GetCreateEventSubscription_594535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_594598 = ref object of OpenApiRestCall_593421
proc url_PostCreateOptionGroup_594600(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateOptionGroup_594599(path: JsonNode; query: JsonNode;
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
  var valid_594601 = query.getOrDefault("Action")
  valid_594601 = validateParameter(valid_594601, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_594601 != nil:
    section.add "Action", valid_594601
  var valid_594602 = query.getOrDefault("Version")
  valid_594602 = validateParameter(valid_594602, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594602 != nil:
    section.add "Version", valid_594602
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
  var valid_594603 = header.getOrDefault("X-Amz-Date")
  valid_594603 = validateParameter(valid_594603, JString, required = false,
                                 default = nil)
  if valid_594603 != nil:
    section.add "X-Amz-Date", valid_594603
  var valid_594604 = header.getOrDefault("X-Amz-Security-Token")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "X-Amz-Security-Token", valid_594604
  var valid_594605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-Content-Sha256", valid_594605
  var valid_594606 = header.getOrDefault("X-Amz-Algorithm")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-Algorithm", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-Signature")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-Signature", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-SignedHeaders", valid_594608
  var valid_594609 = header.getOrDefault("X-Amz-Credential")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Credential", valid_594609
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_594610 = formData.getOrDefault("MajorEngineVersion")
  valid_594610 = validateParameter(valid_594610, JString, required = true,
                                 default = nil)
  if valid_594610 != nil:
    section.add "MajorEngineVersion", valid_594610
  var valid_594611 = formData.getOrDefault("OptionGroupName")
  valid_594611 = validateParameter(valid_594611, JString, required = true,
                                 default = nil)
  if valid_594611 != nil:
    section.add "OptionGroupName", valid_594611
  var valid_594612 = formData.getOrDefault("Tags")
  valid_594612 = validateParameter(valid_594612, JArray, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "Tags", valid_594612
  var valid_594613 = formData.getOrDefault("EngineName")
  valid_594613 = validateParameter(valid_594613, JString, required = true,
                                 default = nil)
  if valid_594613 != nil:
    section.add "EngineName", valid_594613
  var valid_594614 = formData.getOrDefault("OptionGroupDescription")
  valid_594614 = validateParameter(valid_594614, JString, required = true,
                                 default = nil)
  if valid_594614 != nil:
    section.add "OptionGroupDescription", valid_594614
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594615: Call_PostCreateOptionGroup_594598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594615.validator(path, query, header, formData, body)
  let scheme = call_594615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594615.url(scheme.get, call_594615.host, call_594615.base,
                         call_594615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594615, url, valid)

proc call*(call_594616: Call_PostCreateOptionGroup_594598;
          MajorEngineVersion: string; OptionGroupName: string; EngineName: string;
          OptionGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postCreateOptionGroup
  ##   MajorEngineVersion: string (required)
  ##   OptionGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Version: string (required)
  var query_594617 = newJObject()
  var formData_594618 = newJObject()
  add(formData_594618, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_594618, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_594618.add "Tags", Tags
  add(query_594617, "Action", newJString(Action))
  add(formData_594618, "EngineName", newJString(EngineName))
  add(formData_594618, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_594617, "Version", newJString(Version))
  result = call_594616.call(nil, query_594617, nil, formData_594618, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_594598(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_594599, base: "/",
    url: url_PostCreateOptionGroup_594600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_594578 = ref object of OpenApiRestCall_593421
proc url_GetCreateOptionGroup_594580(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateOptionGroup_594579(path: JsonNode; query: JsonNode;
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
  var valid_594581 = query.getOrDefault("OptionGroupName")
  valid_594581 = validateParameter(valid_594581, JString, required = true,
                                 default = nil)
  if valid_594581 != nil:
    section.add "OptionGroupName", valid_594581
  var valid_594582 = query.getOrDefault("Tags")
  valid_594582 = validateParameter(valid_594582, JArray, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "Tags", valid_594582
  var valid_594583 = query.getOrDefault("OptionGroupDescription")
  valid_594583 = validateParameter(valid_594583, JString, required = true,
                                 default = nil)
  if valid_594583 != nil:
    section.add "OptionGroupDescription", valid_594583
  var valid_594584 = query.getOrDefault("Action")
  valid_594584 = validateParameter(valid_594584, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_594584 != nil:
    section.add "Action", valid_594584
  var valid_594585 = query.getOrDefault("Version")
  valid_594585 = validateParameter(valid_594585, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594585 != nil:
    section.add "Version", valid_594585
  var valid_594586 = query.getOrDefault("EngineName")
  valid_594586 = validateParameter(valid_594586, JString, required = true,
                                 default = nil)
  if valid_594586 != nil:
    section.add "EngineName", valid_594586
  var valid_594587 = query.getOrDefault("MajorEngineVersion")
  valid_594587 = validateParameter(valid_594587, JString, required = true,
                                 default = nil)
  if valid_594587 != nil:
    section.add "MajorEngineVersion", valid_594587
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
  var valid_594588 = header.getOrDefault("X-Amz-Date")
  valid_594588 = validateParameter(valid_594588, JString, required = false,
                                 default = nil)
  if valid_594588 != nil:
    section.add "X-Amz-Date", valid_594588
  var valid_594589 = header.getOrDefault("X-Amz-Security-Token")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "X-Amz-Security-Token", valid_594589
  var valid_594590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Content-Sha256", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-Algorithm")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Algorithm", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-Signature")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-Signature", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-SignedHeaders", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Credential")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Credential", valid_594594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594595: Call_GetCreateOptionGroup_594578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594595.validator(path, query, header, formData, body)
  let scheme = call_594595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594595.url(scheme.get, call_594595.host, call_594595.base,
                         call_594595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594595, url, valid)

proc call*(call_594596: Call_GetCreateOptionGroup_594578; OptionGroupName: string;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCreateOptionGroup
  ##   OptionGroupName: string (required)
  ##   Tags: JArray
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  var query_594597 = newJObject()
  add(query_594597, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_594597.add "Tags", Tags
  add(query_594597, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_594597, "Action", newJString(Action))
  add(query_594597, "Version", newJString(Version))
  add(query_594597, "EngineName", newJString(EngineName))
  add(query_594597, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_594596.call(nil, query_594597, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_594578(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_594579, base: "/",
    url: url_GetCreateOptionGroup_594580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_594637 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBInstance_594639(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_594638(path: JsonNode; query: JsonNode;
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
  var valid_594640 = query.getOrDefault("Action")
  valid_594640 = validateParameter(valid_594640, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_594640 != nil:
    section.add "Action", valid_594640
  var valid_594641 = query.getOrDefault("Version")
  valid_594641 = validateParameter(valid_594641, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594641 != nil:
    section.add "Version", valid_594641
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594649 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594649 = validateParameter(valid_594649, JString, required = true,
                                 default = nil)
  if valid_594649 != nil:
    section.add "DBInstanceIdentifier", valid_594649
  var valid_594650 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_594650 = validateParameter(valid_594650, JString, required = false,
                                 default = nil)
  if valid_594650 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_594650
  var valid_594651 = formData.getOrDefault("SkipFinalSnapshot")
  valid_594651 = validateParameter(valid_594651, JBool, required = false, default = nil)
  if valid_594651 != nil:
    section.add "SkipFinalSnapshot", valid_594651
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594652: Call_PostDeleteDBInstance_594637; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594652.validator(path, query, header, formData, body)
  let scheme = call_594652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594652.url(scheme.get, call_594652.host, call_594652.base,
                         call_594652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594652, url, valid)

proc call*(call_594653: Call_PostDeleteDBInstance_594637;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2014-09-01";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_594654 = newJObject()
  var formData_594655 = newJObject()
  add(formData_594655, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594655, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_594654, "Action", newJString(Action))
  add(query_594654, "Version", newJString(Version))
  add(formData_594655, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_594653.call(nil, query_594654, nil, formData_594655, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_594637(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_594638, base: "/",
    url: url_PostDeleteDBInstance_594639, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_594619 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBInstance_594621(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_594620(path: JsonNode; query: JsonNode;
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
  var valid_594622 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_594622
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594623 = query.getOrDefault("Action")
  valid_594623 = validateParameter(valid_594623, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_594623 != nil:
    section.add "Action", valid_594623
  var valid_594624 = query.getOrDefault("SkipFinalSnapshot")
  valid_594624 = validateParameter(valid_594624, JBool, required = false, default = nil)
  if valid_594624 != nil:
    section.add "SkipFinalSnapshot", valid_594624
  var valid_594625 = query.getOrDefault("Version")
  valid_594625 = validateParameter(valid_594625, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594625 != nil:
    section.add "Version", valid_594625
  var valid_594626 = query.getOrDefault("DBInstanceIdentifier")
  valid_594626 = validateParameter(valid_594626, JString, required = true,
                                 default = nil)
  if valid_594626 != nil:
    section.add "DBInstanceIdentifier", valid_594626
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
  var valid_594627 = header.getOrDefault("X-Amz-Date")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Date", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-Security-Token")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Security-Token", valid_594628
  var valid_594629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "X-Amz-Content-Sha256", valid_594629
  var valid_594630 = header.getOrDefault("X-Amz-Algorithm")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "X-Amz-Algorithm", valid_594630
  var valid_594631 = header.getOrDefault("X-Amz-Signature")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-Signature", valid_594631
  var valid_594632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "X-Amz-SignedHeaders", valid_594632
  var valid_594633 = header.getOrDefault("X-Amz-Credential")
  valid_594633 = validateParameter(valid_594633, JString, required = false,
                                 default = nil)
  if valid_594633 != nil:
    section.add "X-Amz-Credential", valid_594633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594634: Call_GetDeleteDBInstance_594619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594634.validator(path, query, header, formData, body)
  let scheme = call_594634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594634.url(scheme.get, call_594634.host, call_594634.base,
                         call_594634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594634, url, valid)

proc call*(call_594635: Call_GetDeleteDBInstance_594619;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_594636 = newJObject()
  add(query_594636, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_594636, "Action", newJString(Action))
  add(query_594636, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_594636, "Version", newJString(Version))
  add(query_594636, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594635.call(nil, query_594636, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_594619(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_594620, base: "/",
    url: url_GetDeleteDBInstance_594621, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_594672 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBParameterGroup_594674(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBParameterGroup_594673(path: JsonNode; query: JsonNode;
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
  var valid_594675 = query.getOrDefault("Action")
  valid_594675 = validateParameter(valid_594675, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_594675 != nil:
    section.add "Action", valid_594675
  var valid_594676 = query.getOrDefault("Version")
  valid_594676 = validateParameter(valid_594676, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594676 != nil:
    section.add "Version", valid_594676
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
  var valid_594677 = header.getOrDefault("X-Amz-Date")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "X-Amz-Date", valid_594677
  var valid_594678 = header.getOrDefault("X-Amz-Security-Token")
  valid_594678 = validateParameter(valid_594678, JString, required = false,
                                 default = nil)
  if valid_594678 != nil:
    section.add "X-Amz-Security-Token", valid_594678
  var valid_594679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "X-Amz-Content-Sha256", valid_594679
  var valid_594680 = header.getOrDefault("X-Amz-Algorithm")
  valid_594680 = validateParameter(valid_594680, JString, required = false,
                                 default = nil)
  if valid_594680 != nil:
    section.add "X-Amz-Algorithm", valid_594680
  var valid_594681 = header.getOrDefault("X-Amz-Signature")
  valid_594681 = validateParameter(valid_594681, JString, required = false,
                                 default = nil)
  if valid_594681 != nil:
    section.add "X-Amz-Signature", valid_594681
  var valid_594682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594682 = validateParameter(valid_594682, JString, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "X-Amz-SignedHeaders", valid_594682
  var valid_594683 = header.getOrDefault("X-Amz-Credential")
  valid_594683 = validateParameter(valid_594683, JString, required = false,
                                 default = nil)
  if valid_594683 != nil:
    section.add "X-Amz-Credential", valid_594683
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594684 = formData.getOrDefault("DBParameterGroupName")
  valid_594684 = validateParameter(valid_594684, JString, required = true,
                                 default = nil)
  if valid_594684 != nil:
    section.add "DBParameterGroupName", valid_594684
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594685: Call_PostDeleteDBParameterGroup_594672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594685.validator(path, query, header, formData, body)
  let scheme = call_594685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594685.url(scheme.get, call_594685.host, call_594685.base,
                         call_594685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594685, url, valid)

proc call*(call_594686: Call_PostDeleteDBParameterGroup_594672;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594687 = newJObject()
  var formData_594688 = newJObject()
  add(formData_594688, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594687, "Action", newJString(Action))
  add(query_594687, "Version", newJString(Version))
  result = call_594686.call(nil, query_594687, nil, formData_594688, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_594672(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_594673, base: "/",
    url: url_PostDeleteDBParameterGroup_594674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_594656 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBParameterGroup_594658(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBParameterGroup_594657(path: JsonNode; query: JsonNode;
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
  var valid_594659 = query.getOrDefault("DBParameterGroupName")
  valid_594659 = validateParameter(valid_594659, JString, required = true,
                                 default = nil)
  if valid_594659 != nil:
    section.add "DBParameterGroupName", valid_594659
  var valid_594660 = query.getOrDefault("Action")
  valid_594660 = validateParameter(valid_594660, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_594660 != nil:
    section.add "Action", valid_594660
  var valid_594661 = query.getOrDefault("Version")
  valid_594661 = validateParameter(valid_594661, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594661 != nil:
    section.add "Version", valid_594661
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
  var valid_594662 = header.getOrDefault("X-Amz-Date")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-Date", valid_594662
  var valid_594663 = header.getOrDefault("X-Amz-Security-Token")
  valid_594663 = validateParameter(valid_594663, JString, required = false,
                                 default = nil)
  if valid_594663 != nil:
    section.add "X-Amz-Security-Token", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-Content-Sha256", valid_594664
  var valid_594665 = header.getOrDefault("X-Amz-Algorithm")
  valid_594665 = validateParameter(valid_594665, JString, required = false,
                                 default = nil)
  if valid_594665 != nil:
    section.add "X-Amz-Algorithm", valid_594665
  var valid_594666 = header.getOrDefault("X-Amz-Signature")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "X-Amz-Signature", valid_594666
  var valid_594667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-SignedHeaders", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-Credential")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Credential", valid_594668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594669: Call_GetDeleteDBParameterGroup_594656; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594669.validator(path, query, header, formData, body)
  let scheme = call_594669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594669.url(scheme.get, call_594669.host, call_594669.base,
                         call_594669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594669, url, valid)

proc call*(call_594670: Call_GetDeleteDBParameterGroup_594656;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594671 = newJObject()
  add(query_594671, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594671, "Action", newJString(Action))
  add(query_594671, "Version", newJString(Version))
  result = call_594670.call(nil, query_594671, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_594656(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_594657, base: "/",
    url: url_GetDeleteDBParameterGroup_594658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_594705 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBSecurityGroup_594707(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSecurityGroup_594706(path: JsonNode; query: JsonNode;
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
  var valid_594708 = query.getOrDefault("Action")
  valid_594708 = validateParameter(valid_594708, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_594708 != nil:
    section.add "Action", valid_594708
  var valid_594709 = query.getOrDefault("Version")
  valid_594709 = validateParameter(valid_594709, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594709 != nil:
    section.add "Version", valid_594709
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
  var valid_594710 = header.getOrDefault("X-Amz-Date")
  valid_594710 = validateParameter(valid_594710, JString, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "X-Amz-Date", valid_594710
  var valid_594711 = header.getOrDefault("X-Amz-Security-Token")
  valid_594711 = validateParameter(valid_594711, JString, required = false,
                                 default = nil)
  if valid_594711 != nil:
    section.add "X-Amz-Security-Token", valid_594711
  var valid_594712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594712 = validateParameter(valid_594712, JString, required = false,
                                 default = nil)
  if valid_594712 != nil:
    section.add "X-Amz-Content-Sha256", valid_594712
  var valid_594713 = header.getOrDefault("X-Amz-Algorithm")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-Algorithm", valid_594713
  var valid_594714 = header.getOrDefault("X-Amz-Signature")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-Signature", valid_594714
  var valid_594715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594715 = validateParameter(valid_594715, JString, required = false,
                                 default = nil)
  if valid_594715 != nil:
    section.add "X-Amz-SignedHeaders", valid_594715
  var valid_594716 = header.getOrDefault("X-Amz-Credential")
  valid_594716 = validateParameter(valid_594716, JString, required = false,
                                 default = nil)
  if valid_594716 != nil:
    section.add "X-Amz-Credential", valid_594716
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_594717 = formData.getOrDefault("DBSecurityGroupName")
  valid_594717 = validateParameter(valid_594717, JString, required = true,
                                 default = nil)
  if valid_594717 != nil:
    section.add "DBSecurityGroupName", valid_594717
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594718: Call_PostDeleteDBSecurityGroup_594705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594718.validator(path, query, header, formData, body)
  let scheme = call_594718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594718.url(scheme.get, call_594718.host, call_594718.base,
                         call_594718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594718, url, valid)

proc call*(call_594719: Call_PostDeleteDBSecurityGroup_594705;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594720 = newJObject()
  var formData_594721 = newJObject()
  add(formData_594721, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594720, "Action", newJString(Action))
  add(query_594720, "Version", newJString(Version))
  result = call_594719.call(nil, query_594720, nil, formData_594721, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_594705(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_594706, base: "/",
    url: url_PostDeleteDBSecurityGroup_594707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_594689 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBSecurityGroup_594691(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSecurityGroup_594690(path: JsonNode; query: JsonNode;
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
  var valid_594692 = query.getOrDefault("DBSecurityGroupName")
  valid_594692 = validateParameter(valid_594692, JString, required = true,
                                 default = nil)
  if valid_594692 != nil:
    section.add "DBSecurityGroupName", valid_594692
  var valid_594693 = query.getOrDefault("Action")
  valid_594693 = validateParameter(valid_594693, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_594693 != nil:
    section.add "Action", valid_594693
  var valid_594694 = query.getOrDefault("Version")
  valid_594694 = validateParameter(valid_594694, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594694 != nil:
    section.add "Version", valid_594694
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
  var valid_594695 = header.getOrDefault("X-Amz-Date")
  valid_594695 = validateParameter(valid_594695, JString, required = false,
                                 default = nil)
  if valid_594695 != nil:
    section.add "X-Amz-Date", valid_594695
  var valid_594696 = header.getOrDefault("X-Amz-Security-Token")
  valid_594696 = validateParameter(valid_594696, JString, required = false,
                                 default = nil)
  if valid_594696 != nil:
    section.add "X-Amz-Security-Token", valid_594696
  var valid_594697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594697 = validateParameter(valid_594697, JString, required = false,
                                 default = nil)
  if valid_594697 != nil:
    section.add "X-Amz-Content-Sha256", valid_594697
  var valid_594698 = header.getOrDefault("X-Amz-Algorithm")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Algorithm", valid_594698
  var valid_594699 = header.getOrDefault("X-Amz-Signature")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "X-Amz-Signature", valid_594699
  var valid_594700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594700 = validateParameter(valid_594700, JString, required = false,
                                 default = nil)
  if valid_594700 != nil:
    section.add "X-Amz-SignedHeaders", valid_594700
  var valid_594701 = header.getOrDefault("X-Amz-Credential")
  valid_594701 = validateParameter(valid_594701, JString, required = false,
                                 default = nil)
  if valid_594701 != nil:
    section.add "X-Amz-Credential", valid_594701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594702: Call_GetDeleteDBSecurityGroup_594689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594702.validator(path, query, header, formData, body)
  let scheme = call_594702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594702.url(scheme.get, call_594702.host, call_594702.base,
                         call_594702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594702, url, valid)

proc call*(call_594703: Call_GetDeleteDBSecurityGroup_594689;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594704 = newJObject()
  add(query_594704, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594704, "Action", newJString(Action))
  add(query_594704, "Version", newJString(Version))
  result = call_594703.call(nil, query_594704, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_594689(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_594690, base: "/",
    url: url_GetDeleteDBSecurityGroup_594691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_594738 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBSnapshot_594740(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSnapshot_594739(path: JsonNode; query: JsonNode;
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
  var valid_594741 = query.getOrDefault("Action")
  valid_594741 = validateParameter(valid_594741, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_594741 != nil:
    section.add "Action", valid_594741
  var valid_594742 = query.getOrDefault("Version")
  valid_594742 = validateParameter(valid_594742, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594742 != nil:
    section.add "Version", valid_594742
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
  var valid_594743 = header.getOrDefault("X-Amz-Date")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Date", valid_594743
  var valid_594744 = header.getOrDefault("X-Amz-Security-Token")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "X-Amz-Security-Token", valid_594744
  var valid_594745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "X-Amz-Content-Sha256", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-Algorithm")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-Algorithm", valid_594746
  var valid_594747 = header.getOrDefault("X-Amz-Signature")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-Signature", valid_594747
  var valid_594748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594748 = validateParameter(valid_594748, JString, required = false,
                                 default = nil)
  if valid_594748 != nil:
    section.add "X-Amz-SignedHeaders", valid_594748
  var valid_594749 = header.getOrDefault("X-Amz-Credential")
  valid_594749 = validateParameter(valid_594749, JString, required = false,
                                 default = nil)
  if valid_594749 != nil:
    section.add "X-Amz-Credential", valid_594749
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_594750 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_594750 = validateParameter(valid_594750, JString, required = true,
                                 default = nil)
  if valid_594750 != nil:
    section.add "DBSnapshotIdentifier", valid_594750
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594751: Call_PostDeleteDBSnapshot_594738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594751.validator(path, query, header, formData, body)
  let scheme = call_594751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594751.url(scheme.get, call_594751.host, call_594751.base,
                         call_594751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594751, url, valid)

proc call*(call_594752: Call_PostDeleteDBSnapshot_594738;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594753 = newJObject()
  var formData_594754 = newJObject()
  add(formData_594754, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_594753, "Action", newJString(Action))
  add(query_594753, "Version", newJString(Version))
  result = call_594752.call(nil, query_594753, nil, formData_594754, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_594738(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_594739, base: "/",
    url: url_PostDeleteDBSnapshot_594740, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_594722 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBSnapshot_594724(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSnapshot_594723(path: JsonNode; query: JsonNode;
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
  var valid_594725 = query.getOrDefault("Action")
  valid_594725 = validateParameter(valid_594725, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_594725 != nil:
    section.add "Action", valid_594725
  var valid_594726 = query.getOrDefault("Version")
  valid_594726 = validateParameter(valid_594726, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594726 != nil:
    section.add "Version", valid_594726
  var valid_594727 = query.getOrDefault("DBSnapshotIdentifier")
  valid_594727 = validateParameter(valid_594727, JString, required = true,
                                 default = nil)
  if valid_594727 != nil:
    section.add "DBSnapshotIdentifier", valid_594727
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
  var valid_594728 = header.getOrDefault("X-Amz-Date")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-Date", valid_594728
  var valid_594729 = header.getOrDefault("X-Amz-Security-Token")
  valid_594729 = validateParameter(valid_594729, JString, required = false,
                                 default = nil)
  if valid_594729 != nil:
    section.add "X-Amz-Security-Token", valid_594729
  var valid_594730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594730 = validateParameter(valid_594730, JString, required = false,
                                 default = nil)
  if valid_594730 != nil:
    section.add "X-Amz-Content-Sha256", valid_594730
  var valid_594731 = header.getOrDefault("X-Amz-Algorithm")
  valid_594731 = validateParameter(valid_594731, JString, required = false,
                                 default = nil)
  if valid_594731 != nil:
    section.add "X-Amz-Algorithm", valid_594731
  var valid_594732 = header.getOrDefault("X-Amz-Signature")
  valid_594732 = validateParameter(valid_594732, JString, required = false,
                                 default = nil)
  if valid_594732 != nil:
    section.add "X-Amz-Signature", valid_594732
  var valid_594733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594733 = validateParameter(valid_594733, JString, required = false,
                                 default = nil)
  if valid_594733 != nil:
    section.add "X-Amz-SignedHeaders", valid_594733
  var valid_594734 = header.getOrDefault("X-Amz-Credential")
  valid_594734 = validateParameter(valid_594734, JString, required = false,
                                 default = nil)
  if valid_594734 != nil:
    section.add "X-Amz-Credential", valid_594734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594735: Call_GetDeleteDBSnapshot_594722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594735.validator(path, query, header, formData, body)
  let scheme = call_594735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594735.url(scheme.get, call_594735.host, call_594735.base,
                         call_594735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594735, url, valid)

proc call*(call_594736: Call_GetDeleteDBSnapshot_594722;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_594737 = newJObject()
  add(query_594737, "Action", newJString(Action))
  add(query_594737, "Version", newJString(Version))
  add(query_594737, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_594736.call(nil, query_594737, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_594722(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_594723, base: "/",
    url: url_GetDeleteDBSnapshot_594724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_594771 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBSubnetGroup_594773(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_594772(path: JsonNode; query: JsonNode;
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
  var valid_594774 = query.getOrDefault("Action")
  valid_594774 = validateParameter(valid_594774, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_594774 != nil:
    section.add "Action", valid_594774
  var valid_594775 = query.getOrDefault("Version")
  valid_594775 = validateParameter(valid_594775, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594775 != nil:
    section.add "Version", valid_594775
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
  var valid_594776 = header.getOrDefault("X-Amz-Date")
  valid_594776 = validateParameter(valid_594776, JString, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "X-Amz-Date", valid_594776
  var valid_594777 = header.getOrDefault("X-Amz-Security-Token")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "X-Amz-Security-Token", valid_594777
  var valid_594778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "X-Amz-Content-Sha256", valid_594778
  var valid_594779 = header.getOrDefault("X-Amz-Algorithm")
  valid_594779 = validateParameter(valid_594779, JString, required = false,
                                 default = nil)
  if valid_594779 != nil:
    section.add "X-Amz-Algorithm", valid_594779
  var valid_594780 = header.getOrDefault("X-Amz-Signature")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "X-Amz-Signature", valid_594780
  var valid_594781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-SignedHeaders", valid_594781
  var valid_594782 = header.getOrDefault("X-Amz-Credential")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "X-Amz-Credential", valid_594782
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_594783 = formData.getOrDefault("DBSubnetGroupName")
  valid_594783 = validateParameter(valid_594783, JString, required = true,
                                 default = nil)
  if valid_594783 != nil:
    section.add "DBSubnetGroupName", valid_594783
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594784: Call_PostDeleteDBSubnetGroup_594771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594784.validator(path, query, header, formData, body)
  let scheme = call_594784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594784.url(scheme.get, call_594784.host, call_594784.base,
                         call_594784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594784, url, valid)

proc call*(call_594785: Call_PostDeleteDBSubnetGroup_594771;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594786 = newJObject()
  var formData_594787 = newJObject()
  add(formData_594787, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594786, "Action", newJString(Action))
  add(query_594786, "Version", newJString(Version))
  result = call_594785.call(nil, query_594786, nil, formData_594787, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_594771(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_594772, base: "/",
    url: url_PostDeleteDBSubnetGroup_594773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_594755 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBSubnetGroup_594757(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_594756(path: JsonNode; query: JsonNode;
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
  var valid_594758 = query.getOrDefault("Action")
  valid_594758 = validateParameter(valid_594758, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_594758 != nil:
    section.add "Action", valid_594758
  var valid_594759 = query.getOrDefault("DBSubnetGroupName")
  valid_594759 = validateParameter(valid_594759, JString, required = true,
                                 default = nil)
  if valid_594759 != nil:
    section.add "DBSubnetGroupName", valid_594759
  var valid_594760 = query.getOrDefault("Version")
  valid_594760 = validateParameter(valid_594760, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594760 != nil:
    section.add "Version", valid_594760
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
  var valid_594761 = header.getOrDefault("X-Amz-Date")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "X-Amz-Date", valid_594761
  var valid_594762 = header.getOrDefault("X-Amz-Security-Token")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "X-Amz-Security-Token", valid_594762
  var valid_594763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594763 = validateParameter(valid_594763, JString, required = false,
                                 default = nil)
  if valid_594763 != nil:
    section.add "X-Amz-Content-Sha256", valid_594763
  var valid_594764 = header.getOrDefault("X-Amz-Algorithm")
  valid_594764 = validateParameter(valid_594764, JString, required = false,
                                 default = nil)
  if valid_594764 != nil:
    section.add "X-Amz-Algorithm", valid_594764
  var valid_594765 = header.getOrDefault("X-Amz-Signature")
  valid_594765 = validateParameter(valid_594765, JString, required = false,
                                 default = nil)
  if valid_594765 != nil:
    section.add "X-Amz-Signature", valid_594765
  var valid_594766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-SignedHeaders", valid_594766
  var valid_594767 = header.getOrDefault("X-Amz-Credential")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "X-Amz-Credential", valid_594767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594768: Call_GetDeleteDBSubnetGroup_594755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594768.validator(path, query, header, formData, body)
  let scheme = call_594768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594768.url(scheme.get, call_594768.host, call_594768.base,
                         call_594768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594768, url, valid)

proc call*(call_594769: Call_GetDeleteDBSubnetGroup_594755;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_594770 = newJObject()
  add(query_594770, "Action", newJString(Action))
  add(query_594770, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594770, "Version", newJString(Version))
  result = call_594769.call(nil, query_594770, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_594755(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_594756, base: "/",
    url: url_GetDeleteDBSubnetGroup_594757, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_594804 = ref object of OpenApiRestCall_593421
proc url_PostDeleteEventSubscription_594806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEventSubscription_594805(path: JsonNode; query: JsonNode;
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
  var valid_594807 = query.getOrDefault("Action")
  valid_594807 = validateParameter(valid_594807, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_594807 != nil:
    section.add "Action", valid_594807
  var valid_594808 = query.getOrDefault("Version")
  valid_594808 = validateParameter(valid_594808, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594808 != nil:
    section.add "Version", valid_594808
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
  var valid_594809 = header.getOrDefault("X-Amz-Date")
  valid_594809 = validateParameter(valid_594809, JString, required = false,
                                 default = nil)
  if valid_594809 != nil:
    section.add "X-Amz-Date", valid_594809
  var valid_594810 = header.getOrDefault("X-Amz-Security-Token")
  valid_594810 = validateParameter(valid_594810, JString, required = false,
                                 default = nil)
  if valid_594810 != nil:
    section.add "X-Amz-Security-Token", valid_594810
  var valid_594811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594811 = validateParameter(valid_594811, JString, required = false,
                                 default = nil)
  if valid_594811 != nil:
    section.add "X-Amz-Content-Sha256", valid_594811
  var valid_594812 = header.getOrDefault("X-Amz-Algorithm")
  valid_594812 = validateParameter(valid_594812, JString, required = false,
                                 default = nil)
  if valid_594812 != nil:
    section.add "X-Amz-Algorithm", valid_594812
  var valid_594813 = header.getOrDefault("X-Amz-Signature")
  valid_594813 = validateParameter(valid_594813, JString, required = false,
                                 default = nil)
  if valid_594813 != nil:
    section.add "X-Amz-Signature", valid_594813
  var valid_594814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594814 = validateParameter(valid_594814, JString, required = false,
                                 default = nil)
  if valid_594814 != nil:
    section.add "X-Amz-SignedHeaders", valid_594814
  var valid_594815 = header.getOrDefault("X-Amz-Credential")
  valid_594815 = validateParameter(valid_594815, JString, required = false,
                                 default = nil)
  if valid_594815 != nil:
    section.add "X-Amz-Credential", valid_594815
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_594816 = formData.getOrDefault("SubscriptionName")
  valid_594816 = validateParameter(valid_594816, JString, required = true,
                                 default = nil)
  if valid_594816 != nil:
    section.add "SubscriptionName", valid_594816
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594817: Call_PostDeleteEventSubscription_594804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594817.validator(path, query, header, formData, body)
  let scheme = call_594817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594817.url(scheme.get, call_594817.host, call_594817.base,
                         call_594817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594817, url, valid)

proc call*(call_594818: Call_PostDeleteEventSubscription_594804;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594819 = newJObject()
  var formData_594820 = newJObject()
  add(formData_594820, "SubscriptionName", newJString(SubscriptionName))
  add(query_594819, "Action", newJString(Action))
  add(query_594819, "Version", newJString(Version))
  result = call_594818.call(nil, query_594819, nil, formData_594820, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_594804(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_594805, base: "/",
    url: url_PostDeleteEventSubscription_594806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_594788 = ref object of OpenApiRestCall_593421
proc url_GetDeleteEventSubscription_594790(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEventSubscription_594789(path: JsonNode; query: JsonNode;
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
  var valid_594791 = query.getOrDefault("Action")
  valid_594791 = validateParameter(valid_594791, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_594791 != nil:
    section.add "Action", valid_594791
  var valid_594792 = query.getOrDefault("SubscriptionName")
  valid_594792 = validateParameter(valid_594792, JString, required = true,
                                 default = nil)
  if valid_594792 != nil:
    section.add "SubscriptionName", valid_594792
  var valid_594793 = query.getOrDefault("Version")
  valid_594793 = validateParameter(valid_594793, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594793 != nil:
    section.add "Version", valid_594793
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
  var valid_594794 = header.getOrDefault("X-Amz-Date")
  valid_594794 = validateParameter(valid_594794, JString, required = false,
                                 default = nil)
  if valid_594794 != nil:
    section.add "X-Amz-Date", valid_594794
  var valid_594795 = header.getOrDefault("X-Amz-Security-Token")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-Security-Token", valid_594795
  var valid_594796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-Content-Sha256", valid_594796
  var valid_594797 = header.getOrDefault("X-Amz-Algorithm")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "X-Amz-Algorithm", valid_594797
  var valid_594798 = header.getOrDefault("X-Amz-Signature")
  valid_594798 = validateParameter(valid_594798, JString, required = false,
                                 default = nil)
  if valid_594798 != nil:
    section.add "X-Amz-Signature", valid_594798
  var valid_594799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594799 = validateParameter(valid_594799, JString, required = false,
                                 default = nil)
  if valid_594799 != nil:
    section.add "X-Amz-SignedHeaders", valid_594799
  var valid_594800 = header.getOrDefault("X-Amz-Credential")
  valid_594800 = validateParameter(valid_594800, JString, required = false,
                                 default = nil)
  if valid_594800 != nil:
    section.add "X-Amz-Credential", valid_594800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594801: Call_GetDeleteEventSubscription_594788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594801.validator(path, query, header, formData, body)
  let scheme = call_594801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594801.url(scheme.get, call_594801.host, call_594801.base,
                         call_594801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594801, url, valid)

proc call*(call_594802: Call_GetDeleteEventSubscription_594788;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_594803 = newJObject()
  add(query_594803, "Action", newJString(Action))
  add(query_594803, "SubscriptionName", newJString(SubscriptionName))
  add(query_594803, "Version", newJString(Version))
  result = call_594802.call(nil, query_594803, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_594788(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_594789, base: "/",
    url: url_GetDeleteEventSubscription_594790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_594837 = ref object of OpenApiRestCall_593421
proc url_PostDeleteOptionGroup_594839(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteOptionGroup_594838(path: JsonNode; query: JsonNode;
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
  var valid_594840 = query.getOrDefault("Action")
  valid_594840 = validateParameter(valid_594840, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_594840 != nil:
    section.add "Action", valid_594840
  var valid_594841 = query.getOrDefault("Version")
  valid_594841 = validateParameter(valid_594841, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594841 != nil:
    section.add "Version", valid_594841
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
  var valid_594842 = header.getOrDefault("X-Amz-Date")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-Date", valid_594842
  var valid_594843 = header.getOrDefault("X-Amz-Security-Token")
  valid_594843 = validateParameter(valid_594843, JString, required = false,
                                 default = nil)
  if valid_594843 != nil:
    section.add "X-Amz-Security-Token", valid_594843
  var valid_594844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594844 = validateParameter(valid_594844, JString, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "X-Amz-Content-Sha256", valid_594844
  var valid_594845 = header.getOrDefault("X-Amz-Algorithm")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "X-Amz-Algorithm", valid_594845
  var valid_594846 = header.getOrDefault("X-Amz-Signature")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "X-Amz-Signature", valid_594846
  var valid_594847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "X-Amz-SignedHeaders", valid_594847
  var valid_594848 = header.getOrDefault("X-Amz-Credential")
  valid_594848 = validateParameter(valid_594848, JString, required = false,
                                 default = nil)
  if valid_594848 != nil:
    section.add "X-Amz-Credential", valid_594848
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_594849 = formData.getOrDefault("OptionGroupName")
  valid_594849 = validateParameter(valid_594849, JString, required = true,
                                 default = nil)
  if valid_594849 != nil:
    section.add "OptionGroupName", valid_594849
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594850: Call_PostDeleteOptionGroup_594837; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594850.validator(path, query, header, formData, body)
  let scheme = call_594850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594850.url(scheme.get, call_594850.host, call_594850.base,
                         call_594850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594850, url, valid)

proc call*(call_594851: Call_PostDeleteOptionGroup_594837; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594852 = newJObject()
  var formData_594853 = newJObject()
  add(formData_594853, "OptionGroupName", newJString(OptionGroupName))
  add(query_594852, "Action", newJString(Action))
  add(query_594852, "Version", newJString(Version))
  result = call_594851.call(nil, query_594852, nil, formData_594853, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_594837(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_594838, base: "/",
    url: url_PostDeleteOptionGroup_594839, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_594821 = ref object of OpenApiRestCall_593421
proc url_GetDeleteOptionGroup_594823(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteOptionGroup_594822(path: JsonNode; query: JsonNode;
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
  var valid_594824 = query.getOrDefault("OptionGroupName")
  valid_594824 = validateParameter(valid_594824, JString, required = true,
                                 default = nil)
  if valid_594824 != nil:
    section.add "OptionGroupName", valid_594824
  var valid_594825 = query.getOrDefault("Action")
  valid_594825 = validateParameter(valid_594825, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_594825 != nil:
    section.add "Action", valid_594825
  var valid_594826 = query.getOrDefault("Version")
  valid_594826 = validateParameter(valid_594826, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594826 != nil:
    section.add "Version", valid_594826
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
  var valid_594827 = header.getOrDefault("X-Amz-Date")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "X-Amz-Date", valid_594827
  var valid_594828 = header.getOrDefault("X-Amz-Security-Token")
  valid_594828 = validateParameter(valid_594828, JString, required = false,
                                 default = nil)
  if valid_594828 != nil:
    section.add "X-Amz-Security-Token", valid_594828
  var valid_594829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594829 = validateParameter(valid_594829, JString, required = false,
                                 default = nil)
  if valid_594829 != nil:
    section.add "X-Amz-Content-Sha256", valid_594829
  var valid_594830 = header.getOrDefault("X-Amz-Algorithm")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-Algorithm", valid_594830
  var valid_594831 = header.getOrDefault("X-Amz-Signature")
  valid_594831 = validateParameter(valid_594831, JString, required = false,
                                 default = nil)
  if valid_594831 != nil:
    section.add "X-Amz-Signature", valid_594831
  var valid_594832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594832 = validateParameter(valid_594832, JString, required = false,
                                 default = nil)
  if valid_594832 != nil:
    section.add "X-Amz-SignedHeaders", valid_594832
  var valid_594833 = header.getOrDefault("X-Amz-Credential")
  valid_594833 = validateParameter(valid_594833, JString, required = false,
                                 default = nil)
  if valid_594833 != nil:
    section.add "X-Amz-Credential", valid_594833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594834: Call_GetDeleteOptionGroup_594821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594834.validator(path, query, header, formData, body)
  let scheme = call_594834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594834.url(scheme.get, call_594834.host, call_594834.base,
                         call_594834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594834, url, valid)

proc call*(call_594835: Call_GetDeleteOptionGroup_594821; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594836 = newJObject()
  add(query_594836, "OptionGroupName", newJString(OptionGroupName))
  add(query_594836, "Action", newJString(Action))
  add(query_594836, "Version", newJString(Version))
  result = call_594835.call(nil, query_594836, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_594821(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_594822, base: "/",
    url: url_GetDeleteOptionGroup_594823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_594877 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBEngineVersions_594879(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_594878(path: JsonNode; query: JsonNode;
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
  var valid_594880 = query.getOrDefault("Action")
  valid_594880 = validateParameter(valid_594880, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_594880 != nil:
    section.add "Action", valid_594880
  var valid_594881 = query.getOrDefault("Version")
  valid_594881 = validateParameter(valid_594881, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594881 != nil:
    section.add "Version", valid_594881
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
  var valid_594882 = header.getOrDefault("X-Amz-Date")
  valid_594882 = validateParameter(valid_594882, JString, required = false,
                                 default = nil)
  if valid_594882 != nil:
    section.add "X-Amz-Date", valid_594882
  var valid_594883 = header.getOrDefault("X-Amz-Security-Token")
  valid_594883 = validateParameter(valid_594883, JString, required = false,
                                 default = nil)
  if valid_594883 != nil:
    section.add "X-Amz-Security-Token", valid_594883
  var valid_594884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594884 = validateParameter(valid_594884, JString, required = false,
                                 default = nil)
  if valid_594884 != nil:
    section.add "X-Amz-Content-Sha256", valid_594884
  var valid_594885 = header.getOrDefault("X-Amz-Algorithm")
  valid_594885 = validateParameter(valid_594885, JString, required = false,
                                 default = nil)
  if valid_594885 != nil:
    section.add "X-Amz-Algorithm", valid_594885
  var valid_594886 = header.getOrDefault("X-Amz-Signature")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "X-Amz-Signature", valid_594886
  var valid_594887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594887 = validateParameter(valid_594887, JString, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "X-Amz-SignedHeaders", valid_594887
  var valid_594888 = header.getOrDefault("X-Amz-Credential")
  valid_594888 = validateParameter(valid_594888, JString, required = false,
                                 default = nil)
  if valid_594888 != nil:
    section.add "X-Amz-Credential", valid_594888
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
  var valid_594889 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_594889 = validateParameter(valid_594889, JBool, required = false, default = nil)
  if valid_594889 != nil:
    section.add "ListSupportedCharacterSets", valid_594889
  var valid_594890 = formData.getOrDefault("Engine")
  valid_594890 = validateParameter(valid_594890, JString, required = false,
                                 default = nil)
  if valid_594890 != nil:
    section.add "Engine", valid_594890
  var valid_594891 = formData.getOrDefault("Marker")
  valid_594891 = validateParameter(valid_594891, JString, required = false,
                                 default = nil)
  if valid_594891 != nil:
    section.add "Marker", valid_594891
  var valid_594892 = formData.getOrDefault("DBParameterGroupFamily")
  valid_594892 = validateParameter(valid_594892, JString, required = false,
                                 default = nil)
  if valid_594892 != nil:
    section.add "DBParameterGroupFamily", valid_594892
  var valid_594893 = formData.getOrDefault("Filters")
  valid_594893 = validateParameter(valid_594893, JArray, required = false,
                                 default = nil)
  if valid_594893 != nil:
    section.add "Filters", valid_594893
  var valid_594894 = formData.getOrDefault("MaxRecords")
  valid_594894 = validateParameter(valid_594894, JInt, required = false, default = nil)
  if valid_594894 != nil:
    section.add "MaxRecords", valid_594894
  var valid_594895 = formData.getOrDefault("EngineVersion")
  valid_594895 = validateParameter(valid_594895, JString, required = false,
                                 default = nil)
  if valid_594895 != nil:
    section.add "EngineVersion", valid_594895
  var valid_594896 = formData.getOrDefault("DefaultOnly")
  valid_594896 = validateParameter(valid_594896, JBool, required = false, default = nil)
  if valid_594896 != nil:
    section.add "DefaultOnly", valid_594896
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594897: Call_PostDescribeDBEngineVersions_594877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594897.validator(path, query, header, formData, body)
  let scheme = call_594897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594897.url(scheme.get, call_594897.host, call_594897.base,
                         call_594897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594897, url, valid)

proc call*(call_594898: Call_PostDescribeDBEngineVersions_594877;
          ListSupportedCharacterSets: bool = false; Engine: string = "";
          Marker: string = ""; Action: string = "DescribeDBEngineVersions";
          DBParameterGroupFamily: string = ""; Filters: JsonNode = nil;
          MaxRecords: int = 0; EngineVersion: string = "";
          Version: string = "2014-09-01"; DefaultOnly: bool = false): Recallable =
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
  var query_594899 = newJObject()
  var formData_594900 = newJObject()
  add(formData_594900, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_594900, "Engine", newJString(Engine))
  add(formData_594900, "Marker", newJString(Marker))
  add(query_594899, "Action", newJString(Action))
  add(formData_594900, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_594900.add "Filters", Filters
  add(formData_594900, "MaxRecords", newJInt(MaxRecords))
  add(formData_594900, "EngineVersion", newJString(EngineVersion))
  add(query_594899, "Version", newJString(Version))
  add(formData_594900, "DefaultOnly", newJBool(DefaultOnly))
  result = call_594898.call(nil, query_594899, nil, formData_594900, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_594877(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_594878, base: "/",
    url: url_PostDescribeDBEngineVersions_594879,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_594854 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBEngineVersions_594856(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_594855(path: JsonNode; query: JsonNode;
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
  var valid_594857 = query.getOrDefault("Engine")
  valid_594857 = validateParameter(valid_594857, JString, required = false,
                                 default = nil)
  if valid_594857 != nil:
    section.add "Engine", valid_594857
  var valid_594858 = query.getOrDefault("ListSupportedCharacterSets")
  valid_594858 = validateParameter(valid_594858, JBool, required = false, default = nil)
  if valid_594858 != nil:
    section.add "ListSupportedCharacterSets", valid_594858
  var valid_594859 = query.getOrDefault("MaxRecords")
  valid_594859 = validateParameter(valid_594859, JInt, required = false, default = nil)
  if valid_594859 != nil:
    section.add "MaxRecords", valid_594859
  var valid_594860 = query.getOrDefault("DBParameterGroupFamily")
  valid_594860 = validateParameter(valid_594860, JString, required = false,
                                 default = nil)
  if valid_594860 != nil:
    section.add "DBParameterGroupFamily", valid_594860
  var valid_594861 = query.getOrDefault("Filters")
  valid_594861 = validateParameter(valid_594861, JArray, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "Filters", valid_594861
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594862 = query.getOrDefault("Action")
  valid_594862 = validateParameter(valid_594862, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_594862 != nil:
    section.add "Action", valid_594862
  var valid_594863 = query.getOrDefault("Marker")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "Marker", valid_594863
  var valid_594864 = query.getOrDefault("EngineVersion")
  valid_594864 = validateParameter(valid_594864, JString, required = false,
                                 default = nil)
  if valid_594864 != nil:
    section.add "EngineVersion", valid_594864
  var valid_594865 = query.getOrDefault("DefaultOnly")
  valid_594865 = validateParameter(valid_594865, JBool, required = false, default = nil)
  if valid_594865 != nil:
    section.add "DefaultOnly", valid_594865
  var valid_594866 = query.getOrDefault("Version")
  valid_594866 = validateParameter(valid_594866, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594866 != nil:
    section.add "Version", valid_594866
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
  var valid_594867 = header.getOrDefault("X-Amz-Date")
  valid_594867 = validateParameter(valid_594867, JString, required = false,
                                 default = nil)
  if valid_594867 != nil:
    section.add "X-Amz-Date", valid_594867
  var valid_594868 = header.getOrDefault("X-Amz-Security-Token")
  valid_594868 = validateParameter(valid_594868, JString, required = false,
                                 default = nil)
  if valid_594868 != nil:
    section.add "X-Amz-Security-Token", valid_594868
  var valid_594869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594869 = validateParameter(valid_594869, JString, required = false,
                                 default = nil)
  if valid_594869 != nil:
    section.add "X-Amz-Content-Sha256", valid_594869
  var valid_594870 = header.getOrDefault("X-Amz-Algorithm")
  valid_594870 = validateParameter(valid_594870, JString, required = false,
                                 default = nil)
  if valid_594870 != nil:
    section.add "X-Amz-Algorithm", valid_594870
  var valid_594871 = header.getOrDefault("X-Amz-Signature")
  valid_594871 = validateParameter(valid_594871, JString, required = false,
                                 default = nil)
  if valid_594871 != nil:
    section.add "X-Amz-Signature", valid_594871
  var valid_594872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594872 = validateParameter(valid_594872, JString, required = false,
                                 default = nil)
  if valid_594872 != nil:
    section.add "X-Amz-SignedHeaders", valid_594872
  var valid_594873 = header.getOrDefault("X-Amz-Credential")
  valid_594873 = validateParameter(valid_594873, JString, required = false,
                                 default = nil)
  if valid_594873 != nil:
    section.add "X-Amz-Credential", valid_594873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594874: Call_GetDescribeDBEngineVersions_594854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594874.validator(path, query, header, formData, body)
  let scheme = call_594874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594874.url(scheme.get, call_594874.host, call_594874.base,
                         call_594874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594874, url, valid)

proc call*(call_594875: Call_GetDescribeDBEngineVersions_594854;
          Engine: string = ""; ListSupportedCharacterSets: bool = false;
          MaxRecords: int = 0; DBParameterGroupFamily: string = "";
          Filters: JsonNode = nil; Action: string = "DescribeDBEngineVersions";
          Marker: string = ""; EngineVersion: string = ""; DefaultOnly: bool = false;
          Version: string = "2014-09-01"): Recallable =
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
  var query_594876 = newJObject()
  add(query_594876, "Engine", newJString(Engine))
  add(query_594876, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_594876, "MaxRecords", newJInt(MaxRecords))
  add(query_594876, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_594876.add "Filters", Filters
  add(query_594876, "Action", newJString(Action))
  add(query_594876, "Marker", newJString(Marker))
  add(query_594876, "EngineVersion", newJString(EngineVersion))
  add(query_594876, "DefaultOnly", newJBool(DefaultOnly))
  add(query_594876, "Version", newJString(Version))
  result = call_594875.call(nil, query_594876, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_594854(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_594855, base: "/",
    url: url_GetDescribeDBEngineVersions_594856,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_594920 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBInstances_594922(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_594921(path: JsonNode; query: JsonNode;
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
  var valid_594923 = query.getOrDefault("Action")
  valid_594923 = validateParameter(valid_594923, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_594923 != nil:
    section.add "Action", valid_594923
  var valid_594924 = query.getOrDefault("Version")
  valid_594924 = validateParameter(valid_594924, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594924 != nil:
    section.add "Version", valid_594924
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
  var valid_594925 = header.getOrDefault("X-Amz-Date")
  valid_594925 = validateParameter(valid_594925, JString, required = false,
                                 default = nil)
  if valid_594925 != nil:
    section.add "X-Amz-Date", valid_594925
  var valid_594926 = header.getOrDefault("X-Amz-Security-Token")
  valid_594926 = validateParameter(valid_594926, JString, required = false,
                                 default = nil)
  if valid_594926 != nil:
    section.add "X-Amz-Security-Token", valid_594926
  var valid_594927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594927 = validateParameter(valid_594927, JString, required = false,
                                 default = nil)
  if valid_594927 != nil:
    section.add "X-Amz-Content-Sha256", valid_594927
  var valid_594928 = header.getOrDefault("X-Amz-Algorithm")
  valid_594928 = validateParameter(valid_594928, JString, required = false,
                                 default = nil)
  if valid_594928 != nil:
    section.add "X-Amz-Algorithm", valid_594928
  var valid_594929 = header.getOrDefault("X-Amz-Signature")
  valid_594929 = validateParameter(valid_594929, JString, required = false,
                                 default = nil)
  if valid_594929 != nil:
    section.add "X-Amz-Signature", valid_594929
  var valid_594930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594930 = validateParameter(valid_594930, JString, required = false,
                                 default = nil)
  if valid_594930 != nil:
    section.add "X-Amz-SignedHeaders", valid_594930
  var valid_594931 = header.getOrDefault("X-Amz-Credential")
  valid_594931 = validateParameter(valid_594931, JString, required = false,
                                 default = nil)
  if valid_594931 != nil:
    section.add "X-Amz-Credential", valid_594931
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594932 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594932 = validateParameter(valid_594932, JString, required = false,
                                 default = nil)
  if valid_594932 != nil:
    section.add "DBInstanceIdentifier", valid_594932
  var valid_594933 = formData.getOrDefault("Marker")
  valid_594933 = validateParameter(valid_594933, JString, required = false,
                                 default = nil)
  if valid_594933 != nil:
    section.add "Marker", valid_594933
  var valid_594934 = formData.getOrDefault("Filters")
  valid_594934 = validateParameter(valid_594934, JArray, required = false,
                                 default = nil)
  if valid_594934 != nil:
    section.add "Filters", valid_594934
  var valid_594935 = formData.getOrDefault("MaxRecords")
  valid_594935 = validateParameter(valid_594935, JInt, required = false, default = nil)
  if valid_594935 != nil:
    section.add "MaxRecords", valid_594935
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594936: Call_PostDescribeDBInstances_594920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594936.validator(path, query, header, formData, body)
  let scheme = call_594936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594936.url(scheme.get, call_594936.host, call_594936.base,
                         call_594936.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594936, url, valid)

proc call*(call_594937: Call_PostDescribeDBInstances_594920;
          DBInstanceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeDBInstances"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBInstances
  ##   DBInstanceIdentifier: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_594938 = newJObject()
  var formData_594939 = newJObject()
  add(formData_594939, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594939, "Marker", newJString(Marker))
  add(query_594938, "Action", newJString(Action))
  if Filters != nil:
    formData_594939.add "Filters", Filters
  add(formData_594939, "MaxRecords", newJInt(MaxRecords))
  add(query_594938, "Version", newJString(Version))
  result = call_594937.call(nil, query_594938, nil, formData_594939, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_594920(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_594921, base: "/",
    url: url_PostDescribeDBInstances_594922, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_594901 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBInstances_594903(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_594902(path: JsonNode; query: JsonNode;
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
  var valid_594904 = query.getOrDefault("MaxRecords")
  valid_594904 = validateParameter(valid_594904, JInt, required = false, default = nil)
  if valid_594904 != nil:
    section.add "MaxRecords", valid_594904
  var valid_594905 = query.getOrDefault("Filters")
  valid_594905 = validateParameter(valid_594905, JArray, required = false,
                                 default = nil)
  if valid_594905 != nil:
    section.add "Filters", valid_594905
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594906 = query.getOrDefault("Action")
  valid_594906 = validateParameter(valid_594906, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_594906 != nil:
    section.add "Action", valid_594906
  var valid_594907 = query.getOrDefault("Marker")
  valid_594907 = validateParameter(valid_594907, JString, required = false,
                                 default = nil)
  if valid_594907 != nil:
    section.add "Marker", valid_594907
  var valid_594908 = query.getOrDefault("Version")
  valid_594908 = validateParameter(valid_594908, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594908 != nil:
    section.add "Version", valid_594908
  var valid_594909 = query.getOrDefault("DBInstanceIdentifier")
  valid_594909 = validateParameter(valid_594909, JString, required = false,
                                 default = nil)
  if valid_594909 != nil:
    section.add "DBInstanceIdentifier", valid_594909
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
  var valid_594910 = header.getOrDefault("X-Amz-Date")
  valid_594910 = validateParameter(valid_594910, JString, required = false,
                                 default = nil)
  if valid_594910 != nil:
    section.add "X-Amz-Date", valid_594910
  var valid_594911 = header.getOrDefault("X-Amz-Security-Token")
  valid_594911 = validateParameter(valid_594911, JString, required = false,
                                 default = nil)
  if valid_594911 != nil:
    section.add "X-Amz-Security-Token", valid_594911
  var valid_594912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594912 = validateParameter(valid_594912, JString, required = false,
                                 default = nil)
  if valid_594912 != nil:
    section.add "X-Amz-Content-Sha256", valid_594912
  var valid_594913 = header.getOrDefault("X-Amz-Algorithm")
  valid_594913 = validateParameter(valid_594913, JString, required = false,
                                 default = nil)
  if valid_594913 != nil:
    section.add "X-Amz-Algorithm", valid_594913
  var valid_594914 = header.getOrDefault("X-Amz-Signature")
  valid_594914 = validateParameter(valid_594914, JString, required = false,
                                 default = nil)
  if valid_594914 != nil:
    section.add "X-Amz-Signature", valid_594914
  var valid_594915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594915 = validateParameter(valid_594915, JString, required = false,
                                 default = nil)
  if valid_594915 != nil:
    section.add "X-Amz-SignedHeaders", valid_594915
  var valid_594916 = header.getOrDefault("X-Amz-Credential")
  valid_594916 = validateParameter(valid_594916, JString, required = false,
                                 default = nil)
  if valid_594916 != nil:
    section.add "X-Amz-Credential", valid_594916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594917: Call_GetDescribeDBInstances_594901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594917.validator(path, query, header, formData, body)
  let scheme = call_594917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594917.url(scheme.get, call_594917.host, call_594917.base,
                         call_594917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594917, url, valid)

proc call*(call_594918: Call_GetDescribeDBInstances_594901; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBInstances";
          Marker: string = ""; Version: string = "2014-09-01";
          DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  var query_594919 = newJObject()
  add(query_594919, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_594919.add "Filters", Filters
  add(query_594919, "Action", newJString(Action))
  add(query_594919, "Marker", newJString(Marker))
  add(query_594919, "Version", newJString(Version))
  add(query_594919, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594918.call(nil, query_594919, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_594901(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_594902, base: "/",
    url: url_GetDescribeDBInstances_594903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_594962 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBLogFiles_594964(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBLogFiles_594963(path: JsonNode; query: JsonNode;
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
  var valid_594965 = query.getOrDefault("Action")
  valid_594965 = validateParameter(valid_594965, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_594965 != nil:
    section.add "Action", valid_594965
  var valid_594966 = query.getOrDefault("Version")
  valid_594966 = validateParameter(valid_594966, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594966 != nil:
    section.add "Version", valid_594966
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
  var valid_594967 = header.getOrDefault("X-Amz-Date")
  valid_594967 = validateParameter(valid_594967, JString, required = false,
                                 default = nil)
  if valid_594967 != nil:
    section.add "X-Amz-Date", valid_594967
  var valid_594968 = header.getOrDefault("X-Amz-Security-Token")
  valid_594968 = validateParameter(valid_594968, JString, required = false,
                                 default = nil)
  if valid_594968 != nil:
    section.add "X-Amz-Security-Token", valid_594968
  var valid_594969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594969 = validateParameter(valid_594969, JString, required = false,
                                 default = nil)
  if valid_594969 != nil:
    section.add "X-Amz-Content-Sha256", valid_594969
  var valid_594970 = header.getOrDefault("X-Amz-Algorithm")
  valid_594970 = validateParameter(valid_594970, JString, required = false,
                                 default = nil)
  if valid_594970 != nil:
    section.add "X-Amz-Algorithm", valid_594970
  var valid_594971 = header.getOrDefault("X-Amz-Signature")
  valid_594971 = validateParameter(valid_594971, JString, required = false,
                                 default = nil)
  if valid_594971 != nil:
    section.add "X-Amz-Signature", valid_594971
  var valid_594972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594972 = validateParameter(valid_594972, JString, required = false,
                                 default = nil)
  if valid_594972 != nil:
    section.add "X-Amz-SignedHeaders", valid_594972
  var valid_594973 = header.getOrDefault("X-Amz-Credential")
  valid_594973 = validateParameter(valid_594973, JString, required = false,
                                 default = nil)
  if valid_594973 != nil:
    section.add "X-Amz-Credential", valid_594973
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
  var valid_594974 = formData.getOrDefault("FilenameContains")
  valid_594974 = validateParameter(valid_594974, JString, required = false,
                                 default = nil)
  if valid_594974 != nil:
    section.add "FilenameContains", valid_594974
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594975 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594975 = validateParameter(valid_594975, JString, required = true,
                                 default = nil)
  if valid_594975 != nil:
    section.add "DBInstanceIdentifier", valid_594975
  var valid_594976 = formData.getOrDefault("FileSize")
  valid_594976 = validateParameter(valid_594976, JInt, required = false, default = nil)
  if valid_594976 != nil:
    section.add "FileSize", valid_594976
  var valid_594977 = formData.getOrDefault("Marker")
  valid_594977 = validateParameter(valid_594977, JString, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "Marker", valid_594977
  var valid_594978 = formData.getOrDefault("Filters")
  valid_594978 = validateParameter(valid_594978, JArray, required = false,
                                 default = nil)
  if valid_594978 != nil:
    section.add "Filters", valid_594978
  var valid_594979 = formData.getOrDefault("MaxRecords")
  valid_594979 = validateParameter(valid_594979, JInt, required = false, default = nil)
  if valid_594979 != nil:
    section.add "MaxRecords", valid_594979
  var valid_594980 = formData.getOrDefault("FileLastWritten")
  valid_594980 = validateParameter(valid_594980, JInt, required = false, default = nil)
  if valid_594980 != nil:
    section.add "FileLastWritten", valid_594980
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594981: Call_PostDescribeDBLogFiles_594962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594981.validator(path, query, header, formData, body)
  let scheme = call_594981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594981.url(scheme.get, call_594981.host, call_594981.base,
                         call_594981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594981, url, valid)

proc call*(call_594982: Call_PostDescribeDBLogFiles_594962;
          DBInstanceIdentifier: string; FilenameContains: string = "";
          FileSize: int = 0; Marker: string = ""; Action: string = "DescribeDBLogFiles";
          Filters: JsonNode = nil; MaxRecords: int = 0; FileLastWritten: int = 0;
          Version: string = "2014-09-01"): Recallable =
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
  var query_594983 = newJObject()
  var formData_594984 = newJObject()
  add(formData_594984, "FilenameContains", newJString(FilenameContains))
  add(formData_594984, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594984, "FileSize", newJInt(FileSize))
  add(formData_594984, "Marker", newJString(Marker))
  add(query_594983, "Action", newJString(Action))
  if Filters != nil:
    formData_594984.add "Filters", Filters
  add(formData_594984, "MaxRecords", newJInt(MaxRecords))
  add(formData_594984, "FileLastWritten", newJInt(FileLastWritten))
  add(query_594983, "Version", newJString(Version))
  result = call_594982.call(nil, query_594983, nil, formData_594984, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_594962(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_594963, base: "/",
    url: url_PostDescribeDBLogFiles_594964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_594940 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBLogFiles_594942(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBLogFiles_594941(path: JsonNode; query: JsonNode;
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
  var valid_594943 = query.getOrDefault("FileLastWritten")
  valid_594943 = validateParameter(valid_594943, JInt, required = false, default = nil)
  if valid_594943 != nil:
    section.add "FileLastWritten", valid_594943
  var valid_594944 = query.getOrDefault("MaxRecords")
  valid_594944 = validateParameter(valid_594944, JInt, required = false, default = nil)
  if valid_594944 != nil:
    section.add "MaxRecords", valid_594944
  var valid_594945 = query.getOrDefault("FilenameContains")
  valid_594945 = validateParameter(valid_594945, JString, required = false,
                                 default = nil)
  if valid_594945 != nil:
    section.add "FilenameContains", valid_594945
  var valid_594946 = query.getOrDefault("FileSize")
  valid_594946 = validateParameter(valid_594946, JInt, required = false, default = nil)
  if valid_594946 != nil:
    section.add "FileSize", valid_594946
  var valid_594947 = query.getOrDefault("Filters")
  valid_594947 = validateParameter(valid_594947, JArray, required = false,
                                 default = nil)
  if valid_594947 != nil:
    section.add "Filters", valid_594947
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594948 = query.getOrDefault("Action")
  valid_594948 = validateParameter(valid_594948, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_594948 != nil:
    section.add "Action", valid_594948
  var valid_594949 = query.getOrDefault("Marker")
  valid_594949 = validateParameter(valid_594949, JString, required = false,
                                 default = nil)
  if valid_594949 != nil:
    section.add "Marker", valid_594949
  var valid_594950 = query.getOrDefault("Version")
  valid_594950 = validateParameter(valid_594950, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594950 != nil:
    section.add "Version", valid_594950
  var valid_594951 = query.getOrDefault("DBInstanceIdentifier")
  valid_594951 = validateParameter(valid_594951, JString, required = true,
                                 default = nil)
  if valid_594951 != nil:
    section.add "DBInstanceIdentifier", valid_594951
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
  var valid_594952 = header.getOrDefault("X-Amz-Date")
  valid_594952 = validateParameter(valid_594952, JString, required = false,
                                 default = nil)
  if valid_594952 != nil:
    section.add "X-Amz-Date", valid_594952
  var valid_594953 = header.getOrDefault("X-Amz-Security-Token")
  valid_594953 = validateParameter(valid_594953, JString, required = false,
                                 default = nil)
  if valid_594953 != nil:
    section.add "X-Amz-Security-Token", valid_594953
  var valid_594954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594954 = validateParameter(valid_594954, JString, required = false,
                                 default = nil)
  if valid_594954 != nil:
    section.add "X-Amz-Content-Sha256", valid_594954
  var valid_594955 = header.getOrDefault("X-Amz-Algorithm")
  valid_594955 = validateParameter(valid_594955, JString, required = false,
                                 default = nil)
  if valid_594955 != nil:
    section.add "X-Amz-Algorithm", valid_594955
  var valid_594956 = header.getOrDefault("X-Amz-Signature")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "X-Amz-Signature", valid_594956
  var valid_594957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-SignedHeaders", valid_594957
  var valid_594958 = header.getOrDefault("X-Amz-Credential")
  valid_594958 = validateParameter(valid_594958, JString, required = false,
                                 default = nil)
  if valid_594958 != nil:
    section.add "X-Amz-Credential", valid_594958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594959: Call_GetDescribeDBLogFiles_594940; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594959.validator(path, query, header, formData, body)
  let scheme = call_594959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594959.url(scheme.get, call_594959.host, call_594959.base,
                         call_594959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594959, url, valid)

proc call*(call_594960: Call_GetDescribeDBLogFiles_594940;
          DBInstanceIdentifier: string; FileLastWritten: int = 0; MaxRecords: int = 0;
          FilenameContains: string = ""; FileSize: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBLogFiles"; Marker: string = "";
          Version: string = "2014-09-01"): Recallable =
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
  var query_594961 = newJObject()
  add(query_594961, "FileLastWritten", newJInt(FileLastWritten))
  add(query_594961, "MaxRecords", newJInt(MaxRecords))
  add(query_594961, "FilenameContains", newJString(FilenameContains))
  add(query_594961, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_594961.add "Filters", Filters
  add(query_594961, "Action", newJString(Action))
  add(query_594961, "Marker", newJString(Marker))
  add(query_594961, "Version", newJString(Version))
  add(query_594961, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594960.call(nil, query_594961, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_594940(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_594941, base: "/",
    url: url_GetDescribeDBLogFiles_594942, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_595004 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBParameterGroups_595006(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_595005(path: JsonNode; query: JsonNode;
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
  var valid_595007 = query.getOrDefault("Action")
  valid_595007 = validateParameter(valid_595007, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_595007 != nil:
    section.add "Action", valid_595007
  var valid_595008 = query.getOrDefault("Version")
  valid_595008 = validateParameter(valid_595008, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595008 != nil:
    section.add "Version", valid_595008
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
  var valid_595009 = header.getOrDefault("X-Amz-Date")
  valid_595009 = validateParameter(valid_595009, JString, required = false,
                                 default = nil)
  if valid_595009 != nil:
    section.add "X-Amz-Date", valid_595009
  var valid_595010 = header.getOrDefault("X-Amz-Security-Token")
  valid_595010 = validateParameter(valid_595010, JString, required = false,
                                 default = nil)
  if valid_595010 != nil:
    section.add "X-Amz-Security-Token", valid_595010
  var valid_595011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595011 = validateParameter(valid_595011, JString, required = false,
                                 default = nil)
  if valid_595011 != nil:
    section.add "X-Amz-Content-Sha256", valid_595011
  var valid_595012 = header.getOrDefault("X-Amz-Algorithm")
  valid_595012 = validateParameter(valid_595012, JString, required = false,
                                 default = nil)
  if valid_595012 != nil:
    section.add "X-Amz-Algorithm", valid_595012
  var valid_595013 = header.getOrDefault("X-Amz-Signature")
  valid_595013 = validateParameter(valid_595013, JString, required = false,
                                 default = nil)
  if valid_595013 != nil:
    section.add "X-Amz-Signature", valid_595013
  var valid_595014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595014 = validateParameter(valid_595014, JString, required = false,
                                 default = nil)
  if valid_595014 != nil:
    section.add "X-Amz-SignedHeaders", valid_595014
  var valid_595015 = header.getOrDefault("X-Amz-Credential")
  valid_595015 = validateParameter(valid_595015, JString, required = false,
                                 default = nil)
  if valid_595015 != nil:
    section.add "X-Amz-Credential", valid_595015
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595016 = formData.getOrDefault("DBParameterGroupName")
  valid_595016 = validateParameter(valid_595016, JString, required = false,
                                 default = nil)
  if valid_595016 != nil:
    section.add "DBParameterGroupName", valid_595016
  var valid_595017 = formData.getOrDefault("Marker")
  valid_595017 = validateParameter(valid_595017, JString, required = false,
                                 default = nil)
  if valid_595017 != nil:
    section.add "Marker", valid_595017
  var valid_595018 = formData.getOrDefault("Filters")
  valid_595018 = validateParameter(valid_595018, JArray, required = false,
                                 default = nil)
  if valid_595018 != nil:
    section.add "Filters", valid_595018
  var valid_595019 = formData.getOrDefault("MaxRecords")
  valid_595019 = validateParameter(valid_595019, JInt, required = false, default = nil)
  if valid_595019 != nil:
    section.add "MaxRecords", valid_595019
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595020: Call_PostDescribeDBParameterGroups_595004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595020.validator(path, query, header, formData, body)
  let scheme = call_595020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595020.url(scheme.get, call_595020.host, call_595020.base,
                         call_595020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595020, url, valid)

proc call*(call_595021: Call_PostDescribeDBParameterGroups_595004;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595022 = newJObject()
  var formData_595023 = newJObject()
  add(formData_595023, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_595023, "Marker", newJString(Marker))
  add(query_595022, "Action", newJString(Action))
  if Filters != nil:
    formData_595023.add "Filters", Filters
  add(formData_595023, "MaxRecords", newJInt(MaxRecords))
  add(query_595022, "Version", newJString(Version))
  result = call_595021.call(nil, query_595022, nil, formData_595023, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_595004(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_595005, base: "/",
    url: url_PostDescribeDBParameterGroups_595006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_594985 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBParameterGroups_594987(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_594986(path: JsonNode; query: JsonNode;
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
  var valid_594988 = query.getOrDefault("MaxRecords")
  valid_594988 = validateParameter(valid_594988, JInt, required = false, default = nil)
  if valid_594988 != nil:
    section.add "MaxRecords", valid_594988
  var valid_594989 = query.getOrDefault("Filters")
  valid_594989 = validateParameter(valid_594989, JArray, required = false,
                                 default = nil)
  if valid_594989 != nil:
    section.add "Filters", valid_594989
  var valid_594990 = query.getOrDefault("DBParameterGroupName")
  valid_594990 = validateParameter(valid_594990, JString, required = false,
                                 default = nil)
  if valid_594990 != nil:
    section.add "DBParameterGroupName", valid_594990
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594991 = query.getOrDefault("Action")
  valid_594991 = validateParameter(valid_594991, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_594991 != nil:
    section.add "Action", valid_594991
  var valid_594992 = query.getOrDefault("Marker")
  valid_594992 = validateParameter(valid_594992, JString, required = false,
                                 default = nil)
  if valid_594992 != nil:
    section.add "Marker", valid_594992
  var valid_594993 = query.getOrDefault("Version")
  valid_594993 = validateParameter(valid_594993, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594993 != nil:
    section.add "Version", valid_594993
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
  var valid_594994 = header.getOrDefault("X-Amz-Date")
  valid_594994 = validateParameter(valid_594994, JString, required = false,
                                 default = nil)
  if valid_594994 != nil:
    section.add "X-Amz-Date", valid_594994
  var valid_594995 = header.getOrDefault("X-Amz-Security-Token")
  valid_594995 = validateParameter(valid_594995, JString, required = false,
                                 default = nil)
  if valid_594995 != nil:
    section.add "X-Amz-Security-Token", valid_594995
  var valid_594996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594996 = validateParameter(valid_594996, JString, required = false,
                                 default = nil)
  if valid_594996 != nil:
    section.add "X-Amz-Content-Sha256", valid_594996
  var valid_594997 = header.getOrDefault("X-Amz-Algorithm")
  valid_594997 = validateParameter(valid_594997, JString, required = false,
                                 default = nil)
  if valid_594997 != nil:
    section.add "X-Amz-Algorithm", valid_594997
  var valid_594998 = header.getOrDefault("X-Amz-Signature")
  valid_594998 = validateParameter(valid_594998, JString, required = false,
                                 default = nil)
  if valid_594998 != nil:
    section.add "X-Amz-Signature", valid_594998
  var valid_594999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594999 = validateParameter(valid_594999, JString, required = false,
                                 default = nil)
  if valid_594999 != nil:
    section.add "X-Amz-SignedHeaders", valid_594999
  var valid_595000 = header.getOrDefault("X-Amz-Credential")
  valid_595000 = validateParameter(valid_595000, JString, required = false,
                                 default = nil)
  if valid_595000 != nil:
    section.add "X-Amz-Credential", valid_595000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595001: Call_GetDescribeDBParameterGroups_594985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595001.validator(path, query, header, formData, body)
  let scheme = call_595001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595001.url(scheme.get, call_595001.host, call_595001.base,
                         call_595001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595001, url, valid)

proc call*(call_595002: Call_GetDescribeDBParameterGroups_594985;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_595003 = newJObject()
  add(query_595003, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595003.add "Filters", Filters
  add(query_595003, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_595003, "Action", newJString(Action))
  add(query_595003, "Marker", newJString(Marker))
  add(query_595003, "Version", newJString(Version))
  result = call_595002.call(nil, query_595003, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_594985(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_594986, base: "/",
    url: url_GetDescribeDBParameterGroups_594987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_595044 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBParameters_595046(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_595045(path: JsonNode; query: JsonNode;
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
  var valid_595047 = query.getOrDefault("Action")
  valid_595047 = validateParameter(valid_595047, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_595047 != nil:
    section.add "Action", valid_595047
  var valid_595048 = query.getOrDefault("Version")
  valid_595048 = validateParameter(valid_595048, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595048 != nil:
    section.add "Version", valid_595048
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
  var valid_595049 = header.getOrDefault("X-Amz-Date")
  valid_595049 = validateParameter(valid_595049, JString, required = false,
                                 default = nil)
  if valid_595049 != nil:
    section.add "X-Amz-Date", valid_595049
  var valid_595050 = header.getOrDefault("X-Amz-Security-Token")
  valid_595050 = validateParameter(valid_595050, JString, required = false,
                                 default = nil)
  if valid_595050 != nil:
    section.add "X-Amz-Security-Token", valid_595050
  var valid_595051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595051 = validateParameter(valid_595051, JString, required = false,
                                 default = nil)
  if valid_595051 != nil:
    section.add "X-Amz-Content-Sha256", valid_595051
  var valid_595052 = header.getOrDefault("X-Amz-Algorithm")
  valid_595052 = validateParameter(valid_595052, JString, required = false,
                                 default = nil)
  if valid_595052 != nil:
    section.add "X-Amz-Algorithm", valid_595052
  var valid_595053 = header.getOrDefault("X-Amz-Signature")
  valid_595053 = validateParameter(valid_595053, JString, required = false,
                                 default = nil)
  if valid_595053 != nil:
    section.add "X-Amz-Signature", valid_595053
  var valid_595054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595054 = validateParameter(valid_595054, JString, required = false,
                                 default = nil)
  if valid_595054 != nil:
    section.add "X-Amz-SignedHeaders", valid_595054
  var valid_595055 = header.getOrDefault("X-Amz-Credential")
  valid_595055 = validateParameter(valid_595055, JString, required = false,
                                 default = nil)
  if valid_595055 != nil:
    section.add "X-Amz-Credential", valid_595055
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_595056 = formData.getOrDefault("DBParameterGroupName")
  valid_595056 = validateParameter(valid_595056, JString, required = true,
                                 default = nil)
  if valid_595056 != nil:
    section.add "DBParameterGroupName", valid_595056
  var valid_595057 = formData.getOrDefault("Marker")
  valid_595057 = validateParameter(valid_595057, JString, required = false,
                                 default = nil)
  if valid_595057 != nil:
    section.add "Marker", valid_595057
  var valid_595058 = formData.getOrDefault("Filters")
  valid_595058 = validateParameter(valid_595058, JArray, required = false,
                                 default = nil)
  if valid_595058 != nil:
    section.add "Filters", valid_595058
  var valid_595059 = formData.getOrDefault("MaxRecords")
  valid_595059 = validateParameter(valid_595059, JInt, required = false, default = nil)
  if valid_595059 != nil:
    section.add "MaxRecords", valid_595059
  var valid_595060 = formData.getOrDefault("Source")
  valid_595060 = validateParameter(valid_595060, JString, required = false,
                                 default = nil)
  if valid_595060 != nil:
    section.add "Source", valid_595060
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595061: Call_PostDescribeDBParameters_595044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595061.validator(path, query, header, formData, body)
  let scheme = call_595061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595061.url(scheme.get, call_595061.host, call_595061.base,
                         call_595061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595061, url, valid)

proc call*(call_595062: Call_PostDescribeDBParameters_595044;
          DBParameterGroupName: string; Marker: string = "";
          Action: string = "DescribeDBParameters"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"; Source: string = ""): Recallable =
  ## postDescribeDBParameters
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  ##   Source: string
  var query_595063 = newJObject()
  var formData_595064 = newJObject()
  add(formData_595064, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_595064, "Marker", newJString(Marker))
  add(query_595063, "Action", newJString(Action))
  if Filters != nil:
    formData_595064.add "Filters", Filters
  add(formData_595064, "MaxRecords", newJInt(MaxRecords))
  add(query_595063, "Version", newJString(Version))
  add(formData_595064, "Source", newJString(Source))
  result = call_595062.call(nil, query_595063, nil, formData_595064, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_595044(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_595045, base: "/",
    url: url_PostDescribeDBParameters_595046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_595024 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBParameters_595026(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_595025(path: JsonNode; query: JsonNode;
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
  var valid_595027 = query.getOrDefault("MaxRecords")
  valid_595027 = validateParameter(valid_595027, JInt, required = false, default = nil)
  if valid_595027 != nil:
    section.add "MaxRecords", valid_595027
  var valid_595028 = query.getOrDefault("Filters")
  valid_595028 = validateParameter(valid_595028, JArray, required = false,
                                 default = nil)
  if valid_595028 != nil:
    section.add "Filters", valid_595028
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_595029 = query.getOrDefault("DBParameterGroupName")
  valid_595029 = validateParameter(valid_595029, JString, required = true,
                                 default = nil)
  if valid_595029 != nil:
    section.add "DBParameterGroupName", valid_595029
  var valid_595030 = query.getOrDefault("Action")
  valid_595030 = validateParameter(valid_595030, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_595030 != nil:
    section.add "Action", valid_595030
  var valid_595031 = query.getOrDefault("Marker")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "Marker", valid_595031
  var valid_595032 = query.getOrDefault("Source")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "Source", valid_595032
  var valid_595033 = query.getOrDefault("Version")
  valid_595033 = validateParameter(valid_595033, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595033 != nil:
    section.add "Version", valid_595033
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
  var valid_595034 = header.getOrDefault("X-Amz-Date")
  valid_595034 = validateParameter(valid_595034, JString, required = false,
                                 default = nil)
  if valid_595034 != nil:
    section.add "X-Amz-Date", valid_595034
  var valid_595035 = header.getOrDefault("X-Amz-Security-Token")
  valid_595035 = validateParameter(valid_595035, JString, required = false,
                                 default = nil)
  if valid_595035 != nil:
    section.add "X-Amz-Security-Token", valid_595035
  var valid_595036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595036 = validateParameter(valid_595036, JString, required = false,
                                 default = nil)
  if valid_595036 != nil:
    section.add "X-Amz-Content-Sha256", valid_595036
  var valid_595037 = header.getOrDefault("X-Amz-Algorithm")
  valid_595037 = validateParameter(valid_595037, JString, required = false,
                                 default = nil)
  if valid_595037 != nil:
    section.add "X-Amz-Algorithm", valid_595037
  var valid_595038 = header.getOrDefault("X-Amz-Signature")
  valid_595038 = validateParameter(valid_595038, JString, required = false,
                                 default = nil)
  if valid_595038 != nil:
    section.add "X-Amz-Signature", valid_595038
  var valid_595039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595039 = validateParameter(valid_595039, JString, required = false,
                                 default = nil)
  if valid_595039 != nil:
    section.add "X-Amz-SignedHeaders", valid_595039
  var valid_595040 = header.getOrDefault("X-Amz-Credential")
  valid_595040 = validateParameter(valid_595040, JString, required = false,
                                 default = nil)
  if valid_595040 != nil:
    section.add "X-Amz-Credential", valid_595040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595041: Call_GetDescribeDBParameters_595024; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595041.validator(path, query, header, formData, body)
  let scheme = call_595041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595041.url(scheme.get, call_595041.host, call_595041.base,
                         call_595041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595041, url, valid)

proc call*(call_595042: Call_GetDescribeDBParameters_595024;
          DBParameterGroupName: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBParameters"; Marker: string = "";
          Source: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getDescribeDBParameters
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Source: string
  ##   Version: string (required)
  var query_595043 = newJObject()
  add(query_595043, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595043.add "Filters", Filters
  add(query_595043, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_595043, "Action", newJString(Action))
  add(query_595043, "Marker", newJString(Marker))
  add(query_595043, "Source", newJString(Source))
  add(query_595043, "Version", newJString(Version))
  result = call_595042.call(nil, query_595043, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_595024(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_595025, base: "/",
    url: url_GetDescribeDBParameters_595026, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_595084 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBSecurityGroups_595086(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_595085(path: JsonNode; query: JsonNode;
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
  var valid_595087 = query.getOrDefault("Action")
  valid_595087 = validateParameter(valid_595087, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_595087 != nil:
    section.add "Action", valid_595087
  var valid_595088 = query.getOrDefault("Version")
  valid_595088 = validateParameter(valid_595088, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595088 != nil:
    section.add "Version", valid_595088
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
  var valid_595089 = header.getOrDefault("X-Amz-Date")
  valid_595089 = validateParameter(valid_595089, JString, required = false,
                                 default = nil)
  if valid_595089 != nil:
    section.add "X-Amz-Date", valid_595089
  var valid_595090 = header.getOrDefault("X-Amz-Security-Token")
  valid_595090 = validateParameter(valid_595090, JString, required = false,
                                 default = nil)
  if valid_595090 != nil:
    section.add "X-Amz-Security-Token", valid_595090
  var valid_595091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595091 = validateParameter(valid_595091, JString, required = false,
                                 default = nil)
  if valid_595091 != nil:
    section.add "X-Amz-Content-Sha256", valid_595091
  var valid_595092 = header.getOrDefault("X-Amz-Algorithm")
  valid_595092 = validateParameter(valid_595092, JString, required = false,
                                 default = nil)
  if valid_595092 != nil:
    section.add "X-Amz-Algorithm", valid_595092
  var valid_595093 = header.getOrDefault("X-Amz-Signature")
  valid_595093 = validateParameter(valid_595093, JString, required = false,
                                 default = nil)
  if valid_595093 != nil:
    section.add "X-Amz-Signature", valid_595093
  var valid_595094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595094 = validateParameter(valid_595094, JString, required = false,
                                 default = nil)
  if valid_595094 != nil:
    section.add "X-Amz-SignedHeaders", valid_595094
  var valid_595095 = header.getOrDefault("X-Amz-Credential")
  valid_595095 = validateParameter(valid_595095, JString, required = false,
                                 default = nil)
  if valid_595095 != nil:
    section.add "X-Amz-Credential", valid_595095
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595096 = formData.getOrDefault("DBSecurityGroupName")
  valid_595096 = validateParameter(valid_595096, JString, required = false,
                                 default = nil)
  if valid_595096 != nil:
    section.add "DBSecurityGroupName", valid_595096
  var valid_595097 = formData.getOrDefault("Marker")
  valid_595097 = validateParameter(valid_595097, JString, required = false,
                                 default = nil)
  if valid_595097 != nil:
    section.add "Marker", valid_595097
  var valid_595098 = formData.getOrDefault("Filters")
  valid_595098 = validateParameter(valid_595098, JArray, required = false,
                                 default = nil)
  if valid_595098 != nil:
    section.add "Filters", valid_595098
  var valid_595099 = formData.getOrDefault("MaxRecords")
  valid_595099 = validateParameter(valid_595099, JInt, required = false, default = nil)
  if valid_595099 != nil:
    section.add "MaxRecords", valid_595099
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595100: Call_PostDescribeDBSecurityGroups_595084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595100.validator(path, query, header, formData, body)
  let scheme = call_595100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595100.url(scheme.get, call_595100.host, call_595100.base,
                         call_595100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595100, url, valid)

proc call*(call_595101: Call_PostDescribeDBSecurityGroups_595084;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595102 = newJObject()
  var formData_595103 = newJObject()
  add(formData_595103, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_595103, "Marker", newJString(Marker))
  add(query_595102, "Action", newJString(Action))
  if Filters != nil:
    formData_595103.add "Filters", Filters
  add(formData_595103, "MaxRecords", newJInt(MaxRecords))
  add(query_595102, "Version", newJString(Version))
  result = call_595101.call(nil, query_595102, nil, formData_595103, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_595084(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_595085, base: "/",
    url: url_PostDescribeDBSecurityGroups_595086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_595065 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBSecurityGroups_595067(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_595066(path: JsonNode; query: JsonNode;
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
  var valid_595068 = query.getOrDefault("MaxRecords")
  valid_595068 = validateParameter(valid_595068, JInt, required = false, default = nil)
  if valid_595068 != nil:
    section.add "MaxRecords", valid_595068
  var valid_595069 = query.getOrDefault("DBSecurityGroupName")
  valid_595069 = validateParameter(valid_595069, JString, required = false,
                                 default = nil)
  if valid_595069 != nil:
    section.add "DBSecurityGroupName", valid_595069
  var valid_595070 = query.getOrDefault("Filters")
  valid_595070 = validateParameter(valid_595070, JArray, required = false,
                                 default = nil)
  if valid_595070 != nil:
    section.add "Filters", valid_595070
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595071 = query.getOrDefault("Action")
  valid_595071 = validateParameter(valid_595071, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_595071 != nil:
    section.add "Action", valid_595071
  var valid_595072 = query.getOrDefault("Marker")
  valid_595072 = validateParameter(valid_595072, JString, required = false,
                                 default = nil)
  if valid_595072 != nil:
    section.add "Marker", valid_595072
  var valid_595073 = query.getOrDefault("Version")
  valid_595073 = validateParameter(valid_595073, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595073 != nil:
    section.add "Version", valid_595073
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
  var valid_595074 = header.getOrDefault("X-Amz-Date")
  valid_595074 = validateParameter(valid_595074, JString, required = false,
                                 default = nil)
  if valid_595074 != nil:
    section.add "X-Amz-Date", valid_595074
  var valid_595075 = header.getOrDefault("X-Amz-Security-Token")
  valid_595075 = validateParameter(valid_595075, JString, required = false,
                                 default = nil)
  if valid_595075 != nil:
    section.add "X-Amz-Security-Token", valid_595075
  var valid_595076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595076 = validateParameter(valid_595076, JString, required = false,
                                 default = nil)
  if valid_595076 != nil:
    section.add "X-Amz-Content-Sha256", valid_595076
  var valid_595077 = header.getOrDefault("X-Amz-Algorithm")
  valid_595077 = validateParameter(valid_595077, JString, required = false,
                                 default = nil)
  if valid_595077 != nil:
    section.add "X-Amz-Algorithm", valid_595077
  var valid_595078 = header.getOrDefault("X-Amz-Signature")
  valid_595078 = validateParameter(valid_595078, JString, required = false,
                                 default = nil)
  if valid_595078 != nil:
    section.add "X-Amz-Signature", valid_595078
  var valid_595079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595079 = validateParameter(valid_595079, JString, required = false,
                                 default = nil)
  if valid_595079 != nil:
    section.add "X-Amz-SignedHeaders", valid_595079
  var valid_595080 = header.getOrDefault("X-Amz-Credential")
  valid_595080 = validateParameter(valid_595080, JString, required = false,
                                 default = nil)
  if valid_595080 != nil:
    section.add "X-Amz-Credential", valid_595080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595081: Call_GetDescribeDBSecurityGroups_595065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595081.validator(path, query, header, formData, body)
  let scheme = call_595081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595081.url(scheme.get, call_595081.host, call_595081.base,
                         call_595081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595081, url, valid)

proc call*(call_595082: Call_GetDescribeDBSecurityGroups_595065;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Filters: JsonNode = nil; Action: string = "DescribeDBSecurityGroups";
          Marker: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_595083 = newJObject()
  add(query_595083, "MaxRecords", newJInt(MaxRecords))
  add(query_595083, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_595083.add "Filters", Filters
  add(query_595083, "Action", newJString(Action))
  add(query_595083, "Marker", newJString(Marker))
  add(query_595083, "Version", newJString(Version))
  result = call_595082.call(nil, query_595083, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_595065(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_595066, base: "/",
    url: url_GetDescribeDBSecurityGroups_595067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_595125 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBSnapshots_595127(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSnapshots_595126(path: JsonNode; query: JsonNode;
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
  var valid_595128 = query.getOrDefault("Action")
  valid_595128 = validateParameter(valid_595128, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_595128 != nil:
    section.add "Action", valid_595128
  var valid_595129 = query.getOrDefault("Version")
  valid_595129 = validateParameter(valid_595129, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595129 != nil:
    section.add "Version", valid_595129
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
  var valid_595130 = header.getOrDefault("X-Amz-Date")
  valid_595130 = validateParameter(valid_595130, JString, required = false,
                                 default = nil)
  if valid_595130 != nil:
    section.add "X-Amz-Date", valid_595130
  var valid_595131 = header.getOrDefault("X-Amz-Security-Token")
  valid_595131 = validateParameter(valid_595131, JString, required = false,
                                 default = nil)
  if valid_595131 != nil:
    section.add "X-Amz-Security-Token", valid_595131
  var valid_595132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595132 = validateParameter(valid_595132, JString, required = false,
                                 default = nil)
  if valid_595132 != nil:
    section.add "X-Amz-Content-Sha256", valid_595132
  var valid_595133 = header.getOrDefault("X-Amz-Algorithm")
  valid_595133 = validateParameter(valid_595133, JString, required = false,
                                 default = nil)
  if valid_595133 != nil:
    section.add "X-Amz-Algorithm", valid_595133
  var valid_595134 = header.getOrDefault("X-Amz-Signature")
  valid_595134 = validateParameter(valid_595134, JString, required = false,
                                 default = nil)
  if valid_595134 != nil:
    section.add "X-Amz-Signature", valid_595134
  var valid_595135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595135 = validateParameter(valid_595135, JString, required = false,
                                 default = nil)
  if valid_595135 != nil:
    section.add "X-Amz-SignedHeaders", valid_595135
  var valid_595136 = header.getOrDefault("X-Amz-Credential")
  valid_595136 = validateParameter(valid_595136, JString, required = false,
                                 default = nil)
  if valid_595136 != nil:
    section.add "X-Amz-Credential", valid_595136
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595137 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595137 = validateParameter(valid_595137, JString, required = false,
                                 default = nil)
  if valid_595137 != nil:
    section.add "DBInstanceIdentifier", valid_595137
  var valid_595138 = formData.getOrDefault("SnapshotType")
  valid_595138 = validateParameter(valid_595138, JString, required = false,
                                 default = nil)
  if valid_595138 != nil:
    section.add "SnapshotType", valid_595138
  var valid_595139 = formData.getOrDefault("Marker")
  valid_595139 = validateParameter(valid_595139, JString, required = false,
                                 default = nil)
  if valid_595139 != nil:
    section.add "Marker", valid_595139
  var valid_595140 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_595140 = validateParameter(valid_595140, JString, required = false,
                                 default = nil)
  if valid_595140 != nil:
    section.add "DBSnapshotIdentifier", valid_595140
  var valid_595141 = formData.getOrDefault("Filters")
  valid_595141 = validateParameter(valid_595141, JArray, required = false,
                                 default = nil)
  if valid_595141 != nil:
    section.add "Filters", valid_595141
  var valid_595142 = formData.getOrDefault("MaxRecords")
  valid_595142 = validateParameter(valid_595142, JInt, required = false, default = nil)
  if valid_595142 != nil:
    section.add "MaxRecords", valid_595142
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595143: Call_PostDescribeDBSnapshots_595125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595143.validator(path, query, header, formData, body)
  let scheme = call_595143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595143.url(scheme.get, call_595143.host, call_595143.base,
                         call_595143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595143, url, valid)

proc call*(call_595144: Call_PostDescribeDBSnapshots_595125;
          DBInstanceIdentifier: string = ""; SnapshotType: string = "";
          Marker: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSnapshots
  ##   DBInstanceIdentifier: string
  ##   SnapshotType: string
  ##   Marker: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595145 = newJObject()
  var formData_595146 = newJObject()
  add(formData_595146, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595146, "SnapshotType", newJString(SnapshotType))
  add(formData_595146, "Marker", newJString(Marker))
  add(formData_595146, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_595145, "Action", newJString(Action))
  if Filters != nil:
    formData_595146.add "Filters", Filters
  add(formData_595146, "MaxRecords", newJInt(MaxRecords))
  add(query_595145, "Version", newJString(Version))
  result = call_595144.call(nil, query_595145, nil, formData_595146, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_595125(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_595126, base: "/",
    url: url_PostDescribeDBSnapshots_595127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_595104 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBSnapshots_595106(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_595105(path: JsonNode; query: JsonNode;
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
  var valid_595107 = query.getOrDefault("MaxRecords")
  valid_595107 = validateParameter(valid_595107, JInt, required = false, default = nil)
  if valid_595107 != nil:
    section.add "MaxRecords", valid_595107
  var valid_595108 = query.getOrDefault("Filters")
  valid_595108 = validateParameter(valid_595108, JArray, required = false,
                                 default = nil)
  if valid_595108 != nil:
    section.add "Filters", valid_595108
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595109 = query.getOrDefault("Action")
  valid_595109 = validateParameter(valid_595109, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_595109 != nil:
    section.add "Action", valid_595109
  var valid_595110 = query.getOrDefault("Marker")
  valid_595110 = validateParameter(valid_595110, JString, required = false,
                                 default = nil)
  if valid_595110 != nil:
    section.add "Marker", valid_595110
  var valid_595111 = query.getOrDefault("SnapshotType")
  valid_595111 = validateParameter(valid_595111, JString, required = false,
                                 default = nil)
  if valid_595111 != nil:
    section.add "SnapshotType", valid_595111
  var valid_595112 = query.getOrDefault("Version")
  valid_595112 = validateParameter(valid_595112, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595112 != nil:
    section.add "Version", valid_595112
  var valid_595113 = query.getOrDefault("DBInstanceIdentifier")
  valid_595113 = validateParameter(valid_595113, JString, required = false,
                                 default = nil)
  if valid_595113 != nil:
    section.add "DBInstanceIdentifier", valid_595113
  var valid_595114 = query.getOrDefault("DBSnapshotIdentifier")
  valid_595114 = validateParameter(valid_595114, JString, required = false,
                                 default = nil)
  if valid_595114 != nil:
    section.add "DBSnapshotIdentifier", valid_595114
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
  var valid_595115 = header.getOrDefault("X-Amz-Date")
  valid_595115 = validateParameter(valid_595115, JString, required = false,
                                 default = nil)
  if valid_595115 != nil:
    section.add "X-Amz-Date", valid_595115
  var valid_595116 = header.getOrDefault("X-Amz-Security-Token")
  valid_595116 = validateParameter(valid_595116, JString, required = false,
                                 default = nil)
  if valid_595116 != nil:
    section.add "X-Amz-Security-Token", valid_595116
  var valid_595117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595117 = validateParameter(valid_595117, JString, required = false,
                                 default = nil)
  if valid_595117 != nil:
    section.add "X-Amz-Content-Sha256", valid_595117
  var valid_595118 = header.getOrDefault("X-Amz-Algorithm")
  valid_595118 = validateParameter(valid_595118, JString, required = false,
                                 default = nil)
  if valid_595118 != nil:
    section.add "X-Amz-Algorithm", valid_595118
  var valid_595119 = header.getOrDefault("X-Amz-Signature")
  valid_595119 = validateParameter(valid_595119, JString, required = false,
                                 default = nil)
  if valid_595119 != nil:
    section.add "X-Amz-Signature", valid_595119
  var valid_595120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595120 = validateParameter(valid_595120, JString, required = false,
                                 default = nil)
  if valid_595120 != nil:
    section.add "X-Amz-SignedHeaders", valid_595120
  var valid_595121 = header.getOrDefault("X-Amz-Credential")
  valid_595121 = validateParameter(valid_595121, JString, required = false,
                                 default = nil)
  if valid_595121 != nil:
    section.add "X-Amz-Credential", valid_595121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595122: Call_GetDescribeDBSnapshots_595104; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595122.validator(path, query, header, formData, body)
  let scheme = call_595122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595122.url(scheme.get, call_595122.host, call_595122.base,
                         call_595122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595122, url, valid)

proc call*(call_595123: Call_GetDescribeDBSnapshots_595104; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBSnapshots";
          Marker: string = ""; SnapshotType: string = "";
          Version: string = "2014-09-01"; DBInstanceIdentifier: string = "";
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
  var query_595124 = newJObject()
  add(query_595124, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595124.add "Filters", Filters
  add(query_595124, "Action", newJString(Action))
  add(query_595124, "Marker", newJString(Marker))
  add(query_595124, "SnapshotType", newJString(SnapshotType))
  add(query_595124, "Version", newJString(Version))
  add(query_595124, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595124, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_595123.call(nil, query_595124, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_595104(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_595105, base: "/",
    url: url_GetDescribeDBSnapshots_595106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_595166 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBSubnetGroups_595168(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_595167(path: JsonNode; query: JsonNode;
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
  var valid_595169 = query.getOrDefault("Action")
  valid_595169 = validateParameter(valid_595169, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_595169 != nil:
    section.add "Action", valid_595169
  var valid_595170 = query.getOrDefault("Version")
  valid_595170 = validateParameter(valid_595170, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595170 != nil:
    section.add "Version", valid_595170
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
  var valid_595171 = header.getOrDefault("X-Amz-Date")
  valid_595171 = validateParameter(valid_595171, JString, required = false,
                                 default = nil)
  if valid_595171 != nil:
    section.add "X-Amz-Date", valid_595171
  var valid_595172 = header.getOrDefault("X-Amz-Security-Token")
  valid_595172 = validateParameter(valid_595172, JString, required = false,
                                 default = nil)
  if valid_595172 != nil:
    section.add "X-Amz-Security-Token", valid_595172
  var valid_595173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595173 = validateParameter(valid_595173, JString, required = false,
                                 default = nil)
  if valid_595173 != nil:
    section.add "X-Amz-Content-Sha256", valid_595173
  var valid_595174 = header.getOrDefault("X-Amz-Algorithm")
  valid_595174 = validateParameter(valid_595174, JString, required = false,
                                 default = nil)
  if valid_595174 != nil:
    section.add "X-Amz-Algorithm", valid_595174
  var valid_595175 = header.getOrDefault("X-Amz-Signature")
  valid_595175 = validateParameter(valid_595175, JString, required = false,
                                 default = nil)
  if valid_595175 != nil:
    section.add "X-Amz-Signature", valid_595175
  var valid_595176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595176 = validateParameter(valid_595176, JString, required = false,
                                 default = nil)
  if valid_595176 != nil:
    section.add "X-Amz-SignedHeaders", valid_595176
  var valid_595177 = header.getOrDefault("X-Amz-Credential")
  valid_595177 = validateParameter(valid_595177, JString, required = false,
                                 default = nil)
  if valid_595177 != nil:
    section.add "X-Amz-Credential", valid_595177
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595178 = formData.getOrDefault("DBSubnetGroupName")
  valid_595178 = validateParameter(valid_595178, JString, required = false,
                                 default = nil)
  if valid_595178 != nil:
    section.add "DBSubnetGroupName", valid_595178
  var valid_595179 = formData.getOrDefault("Marker")
  valid_595179 = validateParameter(valid_595179, JString, required = false,
                                 default = nil)
  if valid_595179 != nil:
    section.add "Marker", valid_595179
  var valid_595180 = formData.getOrDefault("Filters")
  valid_595180 = validateParameter(valid_595180, JArray, required = false,
                                 default = nil)
  if valid_595180 != nil:
    section.add "Filters", valid_595180
  var valid_595181 = formData.getOrDefault("MaxRecords")
  valid_595181 = validateParameter(valid_595181, JInt, required = false, default = nil)
  if valid_595181 != nil:
    section.add "MaxRecords", valid_595181
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595182: Call_PostDescribeDBSubnetGroups_595166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595182.validator(path, query, header, formData, body)
  let scheme = call_595182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595182.url(scheme.get, call_595182.host, call_595182.base,
                         call_595182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595182, url, valid)

proc call*(call_595183: Call_PostDescribeDBSubnetGroups_595166;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595184 = newJObject()
  var formData_595185 = newJObject()
  add(formData_595185, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_595185, "Marker", newJString(Marker))
  add(query_595184, "Action", newJString(Action))
  if Filters != nil:
    formData_595185.add "Filters", Filters
  add(formData_595185, "MaxRecords", newJInt(MaxRecords))
  add(query_595184, "Version", newJString(Version))
  result = call_595183.call(nil, query_595184, nil, formData_595185, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_595166(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_595167, base: "/",
    url: url_PostDescribeDBSubnetGroups_595168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_595147 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBSubnetGroups_595149(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_595148(path: JsonNode; query: JsonNode;
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
  var valid_595150 = query.getOrDefault("MaxRecords")
  valid_595150 = validateParameter(valid_595150, JInt, required = false, default = nil)
  if valid_595150 != nil:
    section.add "MaxRecords", valid_595150
  var valid_595151 = query.getOrDefault("Filters")
  valid_595151 = validateParameter(valid_595151, JArray, required = false,
                                 default = nil)
  if valid_595151 != nil:
    section.add "Filters", valid_595151
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595152 = query.getOrDefault("Action")
  valid_595152 = validateParameter(valid_595152, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_595152 != nil:
    section.add "Action", valid_595152
  var valid_595153 = query.getOrDefault("Marker")
  valid_595153 = validateParameter(valid_595153, JString, required = false,
                                 default = nil)
  if valid_595153 != nil:
    section.add "Marker", valid_595153
  var valid_595154 = query.getOrDefault("DBSubnetGroupName")
  valid_595154 = validateParameter(valid_595154, JString, required = false,
                                 default = nil)
  if valid_595154 != nil:
    section.add "DBSubnetGroupName", valid_595154
  var valid_595155 = query.getOrDefault("Version")
  valid_595155 = validateParameter(valid_595155, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595155 != nil:
    section.add "Version", valid_595155
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
  var valid_595156 = header.getOrDefault("X-Amz-Date")
  valid_595156 = validateParameter(valid_595156, JString, required = false,
                                 default = nil)
  if valid_595156 != nil:
    section.add "X-Amz-Date", valid_595156
  var valid_595157 = header.getOrDefault("X-Amz-Security-Token")
  valid_595157 = validateParameter(valid_595157, JString, required = false,
                                 default = nil)
  if valid_595157 != nil:
    section.add "X-Amz-Security-Token", valid_595157
  var valid_595158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595158 = validateParameter(valid_595158, JString, required = false,
                                 default = nil)
  if valid_595158 != nil:
    section.add "X-Amz-Content-Sha256", valid_595158
  var valid_595159 = header.getOrDefault("X-Amz-Algorithm")
  valid_595159 = validateParameter(valid_595159, JString, required = false,
                                 default = nil)
  if valid_595159 != nil:
    section.add "X-Amz-Algorithm", valid_595159
  var valid_595160 = header.getOrDefault("X-Amz-Signature")
  valid_595160 = validateParameter(valid_595160, JString, required = false,
                                 default = nil)
  if valid_595160 != nil:
    section.add "X-Amz-Signature", valid_595160
  var valid_595161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595161 = validateParameter(valid_595161, JString, required = false,
                                 default = nil)
  if valid_595161 != nil:
    section.add "X-Amz-SignedHeaders", valid_595161
  var valid_595162 = header.getOrDefault("X-Amz-Credential")
  valid_595162 = validateParameter(valid_595162, JString, required = false,
                                 default = nil)
  if valid_595162 != nil:
    section.add "X-Amz-Credential", valid_595162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595163: Call_GetDescribeDBSubnetGroups_595147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595163.validator(path, query, header, formData, body)
  let scheme = call_595163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595163.url(scheme.get, call_595163.host, call_595163.base,
                         call_595163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595163, url, valid)

proc call*(call_595164: Call_GetDescribeDBSubnetGroups_595147; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBSubnetGroups";
          Marker: string = ""; DBSubnetGroupName: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_595165 = newJObject()
  add(query_595165, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595165.add "Filters", Filters
  add(query_595165, "Action", newJString(Action))
  add(query_595165, "Marker", newJString(Marker))
  add(query_595165, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_595165, "Version", newJString(Version))
  result = call_595164.call(nil, query_595165, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_595147(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_595148, base: "/",
    url: url_GetDescribeDBSubnetGroups_595149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_595205 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEngineDefaultParameters_595207(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_595206(path: JsonNode;
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
  var valid_595208 = query.getOrDefault("Action")
  valid_595208 = validateParameter(valid_595208, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_595208 != nil:
    section.add "Action", valid_595208
  var valid_595209 = query.getOrDefault("Version")
  valid_595209 = validateParameter(valid_595209, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595209 != nil:
    section.add "Version", valid_595209
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
  var valid_595210 = header.getOrDefault("X-Amz-Date")
  valid_595210 = validateParameter(valid_595210, JString, required = false,
                                 default = nil)
  if valid_595210 != nil:
    section.add "X-Amz-Date", valid_595210
  var valid_595211 = header.getOrDefault("X-Amz-Security-Token")
  valid_595211 = validateParameter(valid_595211, JString, required = false,
                                 default = nil)
  if valid_595211 != nil:
    section.add "X-Amz-Security-Token", valid_595211
  var valid_595212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595212 = validateParameter(valid_595212, JString, required = false,
                                 default = nil)
  if valid_595212 != nil:
    section.add "X-Amz-Content-Sha256", valid_595212
  var valid_595213 = header.getOrDefault("X-Amz-Algorithm")
  valid_595213 = validateParameter(valid_595213, JString, required = false,
                                 default = nil)
  if valid_595213 != nil:
    section.add "X-Amz-Algorithm", valid_595213
  var valid_595214 = header.getOrDefault("X-Amz-Signature")
  valid_595214 = validateParameter(valid_595214, JString, required = false,
                                 default = nil)
  if valid_595214 != nil:
    section.add "X-Amz-Signature", valid_595214
  var valid_595215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595215 = validateParameter(valid_595215, JString, required = false,
                                 default = nil)
  if valid_595215 != nil:
    section.add "X-Amz-SignedHeaders", valid_595215
  var valid_595216 = header.getOrDefault("X-Amz-Credential")
  valid_595216 = validateParameter(valid_595216, JString, required = false,
                                 default = nil)
  if valid_595216 != nil:
    section.add "X-Amz-Credential", valid_595216
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595217 = formData.getOrDefault("Marker")
  valid_595217 = validateParameter(valid_595217, JString, required = false,
                                 default = nil)
  if valid_595217 != nil:
    section.add "Marker", valid_595217
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_595218 = formData.getOrDefault("DBParameterGroupFamily")
  valid_595218 = validateParameter(valid_595218, JString, required = true,
                                 default = nil)
  if valid_595218 != nil:
    section.add "DBParameterGroupFamily", valid_595218
  var valid_595219 = formData.getOrDefault("Filters")
  valid_595219 = validateParameter(valid_595219, JArray, required = false,
                                 default = nil)
  if valid_595219 != nil:
    section.add "Filters", valid_595219
  var valid_595220 = formData.getOrDefault("MaxRecords")
  valid_595220 = validateParameter(valid_595220, JInt, required = false, default = nil)
  if valid_595220 != nil:
    section.add "MaxRecords", valid_595220
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595221: Call_PostDescribeEngineDefaultParameters_595205;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595221.validator(path, query, header, formData, body)
  let scheme = call_595221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595221.url(scheme.get, call_595221.host, call_595221.base,
                         call_595221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595221, url, valid)

proc call*(call_595222: Call_PostDescribeEngineDefaultParameters_595205;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Filters: JsonNode = nil; MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595223 = newJObject()
  var formData_595224 = newJObject()
  add(formData_595224, "Marker", newJString(Marker))
  add(query_595223, "Action", newJString(Action))
  add(formData_595224, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_595224.add "Filters", Filters
  add(formData_595224, "MaxRecords", newJInt(MaxRecords))
  add(query_595223, "Version", newJString(Version))
  result = call_595222.call(nil, query_595223, nil, formData_595224, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_595205(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_595206, base: "/",
    url: url_PostDescribeEngineDefaultParameters_595207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_595186 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEngineDefaultParameters_595188(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_595187(path: JsonNode;
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
  var valid_595189 = query.getOrDefault("MaxRecords")
  valid_595189 = validateParameter(valid_595189, JInt, required = false, default = nil)
  if valid_595189 != nil:
    section.add "MaxRecords", valid_595189
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_595190 = query.getOrDefault("DBParameterGroupFamily")
  valid_595190 = validateParameter(valid_595190, JString, required = true,
                                 default = nil)
  if valid_595190 != nil:
    section.add "DBParameterGroupFamily", valid_595190
  var valid_595191 = query.getOrDefault("Filters")
  valid_595191 = validateParameter(valid_595191, JArray, required = false,
                                 default = nil)
  if valid_595191 != nil:
    section.add "Filters", valid_595191
  var valid_595192 = query.getOrDefault("Action")
  valid_595192 = validateParameter(valid_595192, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_595192 != nil:
    section.add "Action", valid_595192
  var valid_595193 = query.getOrDefault("Marker")
  valid_595193 = validateParameter(valid_595193, JString, required = false,
                                 default = nil)
  if valid_595193 != nil:
    section.add "Marker", valid_595193
  var valid_595194 = query.getOrDefault("Version")
  valid_595194 = validateParameter(valid_595194, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595194 != nil:
    section.add "Version", valid_595194
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
  var valid_595195 = header.getOrDefault("X-Amz-Date")
  valid_595195 = validateParameter(valid_595195, JString, required = false,
                                 default = nil)
  if valid_595195 != nil:
    section.add "X-Amz-Date", valid_595195
  var valid_595196 = header.getOrDefault("X-Amz-Security-Token")
  valid_595196 = validateParameter(valid_595196, JString, required = false,
                                 default = nil)
  if valid_595196 != nil:
    section.add "X-Amz-Security-Token", valid_595196
  var valid_595197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595197 = validateParameter(valid_595197, JString, required = false,
                                 default = nil)
  if valid_595197 != nil:
    section.add "X-Amz-Content-Sha256", valid_595197
  var valid_595198 = header.getOrDefault("X-Amz-Algorithm")
  valid_595198 = validateParameter(valid_595198, JString, required = false,
                                 default = nil)
  if valid_595198 != nil:
    section.add "X-Amz-Algorithm", valid_595198
  var valid_595199 = header.getOrDefault("X-Amz-Signature")
  valid_595199 = validateParameter(valid_595199, JString, required = false,
                                 default = nil)
  if valid_595199 != nil:
    section.add "X-Amz-Signature", valid_595199
  var valid_595200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595200 = validateParameter(valid_595200, JString, required = false,
                                 default = nil)
  if valid_595200 != nil:
    section.add "X-Amz-SignedHeaders", valid_595200
  var valid_595201 = header.getOrDefault("X-Amz-Credential")
  valid_595201 = validateParameter(valid_595201, JString, required = false,
                                 default = nil)
  if valid_595201 != nil:
    section.add "X-Amz-Credential", valid_595201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595202: Call_GetDescribeEngineDefaultParameters_595186;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595202.validator(path, query, header, formData, body)
  let scheme = call_595202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595202.url(scheme.get, call_595202.host, call_595202.base,
                         call_595202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595202, url, valid)

proc call*(call_595203: Call_GetDescribeEngineDefaultParameters_595186;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Filters: JsonNode = nil;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_595204 = newJObject()
  add(query_595204, "MaxRecords", newJInt(MaxRecords))
  add(query_595204, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_595204.add "Filters", Filters
  add(query_595204, "Action", newJString(Action))
  add(query_595204, "Marker", newJString(Marker))
  add(query_595204, "Version", newJString(Version))
  result = call_595203.call(nil, query_595204, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_595186(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_595187, base: "/",
    url: url_GetDescribeEngineDefaultParameters_595188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_595242 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEventCategories_595244(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_595243(path: JsonNode; query: JsonNode;
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
  var valid_595245 = query.getOrDefault("Action")
  valid_595245 = validateParameter(valid_595245, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_595245 != nil:
    section.add "Action", valid_595245
  var valid_595246 = query.getOrDefault("Version")
  valid_595246 = validateParameter(valid_595246, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595246 != nil:
    section.add "Version", valid_595246
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
  var valid_595247 = header.getOrDefault("X-Amz-Date")
  valid_595247 = validateParameter(valid_595247, JString, required = false,
                                 default = nil)
  if valid_595247 != nil:
    section.add "X-Amz-Date", valid_595247
  var valid_595248 = header.getOrDefault("X-Amz-Security-Token")
  valid_595248 = validateParameter(valid_595248, JString, required = false,
                                 default = nil)
  if valid_595248 != nil:
    section.add "X-Amz-Security-Token", valid_595248
  var valid_595249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595249 = validateParameter(valid_595249, JString, required = false,
                                 default = nil)
  if valid_595249 != nil:
    section.add "X-Amz-Content-Sha256", valid_595249
  var valid_595250 = header.getOrDefault("X-Amz-Algorithm")
  valid_595250 = validateParameter(valid_595250, JString, required = false,
                                 default = nil)
  if valid_595250 != nil:
    section.add "X-Amz-Algorithm", valid_595250
  var valid_595251 = header.getOrDefault("X-Amz-Signature")
  valid_595251 = validateParameter(valid_595251, JString, required = false,
                                 default = nil)
  if valid_595251 != nil:
    section.add "X-Amz-Signature", valid_595251
  var valid_595252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595252 = validateParameter(valid_595252, JString, required = false,
                                 default = nil)
  if valid_595252 != nil:
    section.add "X-Amz-SignedHeaders", valid_595252
  var valid_595253 = header.getOrDefault("X-Amz-Credential")
  valid_595253 = validateParameter(valid_595253, JString, required = false,
                                 default = nil)
  if valid_595253 != nil:
    section.add "X-Amz-Credential", valid_595253
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_595254 = formData.getOrDefault("Filters")
  valid_595254 = validateParameter(valid_595254, JArray, required = false,
                                 default = nil)
  if valid_595254 != nil:
    section.add "Filters", valid_595254
  var valid_595255 = formData.getOrDefault("SourceType")
  valid_595255 = validateParameter(valid_595255, JString, required = false,
                                 default = nil)
  if valid_595255 != nil:
    section.add "SourceType", valid_595255
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595256: Call_PostDescribeEventCategories_595242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595256.validator(path, query, header, formData, body)
  let scheme = call_595256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595256.url(scheme.get, call_595256.host, call_595256.base,
                         call_595256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595256, url, valid)

proc call*(call_595257: Call_PostDescribeEventCategories_595242;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_595258 = newJObject()
  var formData_595259 = newJObject()
  add(query_595258, "Action", newJString(Action))
  if Filters != nil:
    formData_595259.add "Filters", Filters
  add(query_595258, "Version", newJString(Version))
  add(formData_595259, "SourceType", newJString(SourceType))
  result = call_595257.call(nil, query_595258, nil, formData_595259, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_595242(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_595243, base: "/",
    url: url_PostDescribeEventCategories_595244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_595225 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEventCategories_595227(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_595226(path: JsonNode; query: JsonNode;
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
  var valid_595228 = query.getOrDefault("SourceType")
  valid_595228 = validateParameter(valid_595228, JString, required = false,
                                 default = nil)
  if valid_595228 != nil:
    section.add "SourceType", valid_595228
  var valid_595229 = query.getOrDefault("Filters")
  valid_595229 = validateParameter(valid_595229, JArray, required = false,
                                 default = nil)
  if valid_595229 != nil:
    section.add "Filters", valid_595229
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595230 = query.getOrDefault("Action")
  valid_595230 = validateParameter(valid_595230, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_595230 != nil:
    section.add "Action", valid_595230
  var valid_595231 = query.getOrDefault("Version")
  valid_595231 = validateParameter(valid_595231, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595231 != nil:
    section.add "Version", valid_595231
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
  var valid_595232 = header.getOrDefault("X-Amz-Date")
  valid_595232 = validateParameter(valid_595232, JString, required = false,
                                 default = nil)
  if valid_595232 != nil:
    section.add "X-Amz-Date", valid_595232
  var valid_595233 = header.getOrDefault("X-Amz-Security-Token")
  valid_595233 = validateParameter(valid_595233, JString, required = false,
                                 default = nil)
  if valid_595233 != nil:
    section.add "X-Amz-Security-Token", valid_595233
  var valid_595234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595234 = validateParameter(valid_595234, JString, required = false,
                                 default = nil)
  if valid_595234 != nil:
    section.add "X-Amz-Content-Sha256", valid_595234
  var valid_595235 = header.getOrDefault("X-Amz-Algorithm")
  valid_595235 = validateParameter(valid_595235, JString, required = false,
                                 default = nil)
  if valid_595235 != nil:
    section.add "X-Amz-Algorithm", valid_595235
  var valid_595236 = header.getOrDefault("X-Amz-Signature")
  valid_595236 = validateParameter(valid_595236, JString, required = false,
                                 default = nil)
  if valid_595236 != nil:
    section.add "X-Amz-Signature", valid_595236
  var valid_595237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595237 = validateParameter(valid_595237, JString, required = false,
                                 default = nil)
  if valid_595237 != nil:
    section.add "X-Amz-SignedHeaders", valid_595237
  var valid_595238 = header.getOrDefault("X-Amz-Credential")
  valid_595238 = validateParameter(valid_595238, JString, required = false,
                                 default = nil)
  if valid_595238 != nil:
    section.add "X-Amz-Credential", valid_595238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595239: Call_GetDescribeEventCategories_595225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595239.validator(path, query, header, formData, body)
  let scheme = call_595239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595239.url(scheme.get, call_595239.host, call_595239.base,
                         call_595239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595239, url, valid)

proc call*(call_595240: Call_GetDescribeEventCategories_595225;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2014-09-01"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595241 = newJObject()
  add(query_595241, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_595241.add "Filters", Filters
  add(query_595241, "Action", newJString(Action))
  add(query_595241, "Version", newJString(Version))
  result = call_595240.call(nil, query_595241, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_595225(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_595226, base: "/",
    url: url_GetDescribeEventCategories_595227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_595279 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEventSubscriptions_595281(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_595280(path: JsonNode;
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
  var valid_595282 = query.getOrDefault("Action")
  valid_595282 = validateParameter(valid_595282, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_595282 != nil:
    section.add "Action", valid_595282
  var valid_595283 = query.getOrDefault("Version")
  valid_595283 = validateParameter(valid_595283, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595283 != nil:
    section.add "Version", valid_595283
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
  var valid_595284 = header.getOrDefault("X-Amz-Date")
  valid_595284 = validateParameter(valid_595284, JString, required = false,
                                 default = nil)
  if valid_595284 != nil:
    section.add "X-Amz-Date", valid_595284
  var valid_595285 = header.getOrDefault("X-Amz-Security-Token")
  valid_595285 = validateParameter(valid_595285, JString, required = false,
                                 default = nil)
  if valid_595285 != nil:
    section.add "X-Amz-Security-Token", valid_595285
  var valid_595286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595286 = validateParameter(valid_595286, JString, required = false,
                                 default = nil)
  if valid_595286 != nil:
    section.add "X-Amz-Content-Sha256", valid_595286
  var valid_595287 = header.getOrDefault("X-Amz-Algorithm")
  valid_595287 = validateParameter(valid_595287, JString, required = false,
                                 default = nil)
  if valid_595287 != nil:
    section.add "X-Amz-Algorithm", valid_595287
  var valid_595288 = header.getOrDefault("X-Amz-Signature")
  valid_595288 = validateParameter(valid_595288, JString, required = false,
                                 default = nil)
  if valid_595288 != nil:
    section.add "X-Amz-Signature", valid_595288
  var valid_595289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595289 = validateParameter(valid_595289, JString, required = false,
                                 default = nil)
  if valid_595289 != nil:
    section.add "X-Amz-SignedHeaders", valid_595289
  var valid_595290 = header.getOrDefault("X-Amz-Credential")
  valid_595290 = validateParameter(valid_595290, JString, required = false,
                                 default = nil)
  if valid_595290 != nil:
    section.add "X-Amz-Credential", valid_595290
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595291 = formData.getOrDefault("Marker")
  valid_595291 = validateParameter(valid_595291, JString, required = false,
                                 default = nil)
  if valid_595291 != nil:
    section.add "Marker", valid_595291
  var valid_595292 = formData.getOrDefault("SubscriptionName")
  valid_595292 = validateParameter(valid_595292, JString, required = false,
                                 default = nil)
  if valid_595292 != nil:
    section.add "SubscriptionName", valid_595292
  var valid_595293 = formData.getOrDefault("Filters")
  valid_595293 = validateParameter(valid_595293, JArray, required = false,
                                 default = nil)
  if valid_595293 != nil:
    section.add "Filters", valid_595293
  var valid_595294 = formData.getOrDefault("MaxRecords")
  valid_595294 = validateParameter(valid_595294, JInt, required = false, default = nil)
  if valid_595294 != nil:
    section.add "MaxRecords", valid_595294
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595295: Call_PostDescribeEventSubscriptions_595279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595295.validator(path, query, header, formData, body)
  let scheme = call_595295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595295.url(scheme.get, call_595295.host, call_595295.base,
                         call_595295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595295, url, valid)

proc call*(call_595296: Call_PostDescribeEventSubscriptions_595279;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595297 = newJObject()
  var formData_595298 = newJObject()
  add(formData_595298, "Marker", newJString(Marker))
  add(formData_595298, "SubscriptionName", newJString(SubscriptionName))
  add(query_595297, "Action", newJString(Action))
  if Filters != nil:
    formData_595298.add "Filters", Filters
  add(formData_595298, "MaxRecords", newJInt(MaxRecords))
  add(query_595297, "Version", newJString(Version))
  result = call_595296.call(nil, query_595297, nil, formData_595298, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_595279(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_595280, base: "/",
    url: url_PostDescribeEventSubscriptions_595281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_595260 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEventSubscriptions_595262(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_595261(path: JsonNode; query: JsonNode;
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
  var valid_595263 = query.getOrDefault("MaxRecords")
  valid_595263 = validateParameter(valid_595263, JInt, required = false, default = nil)
  if valid_595263 != nil:
    section.add "MaxRecords", valid_595263
  var valid_595264 = query.getOrDefault("Filters")
  valid_595264 = validateParameter(valid_595264, JArray, required = false,
                                 default = nil)
  if valid_595264 != nil:
    section.add "Filters", valid_595264
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595265 = query.getOrDefault("Action")
  valid_595265 = validateParameter(valid_595265, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_595265 != nil:
    section.add "Action", valid_595265
  var valid_595266 = query.getOrDefault("Marker")
  valid_595266 = validateParameter(valid_595266, JString, required = false,
                                 default = nil)
  if valid_595266 != nil:
    section.add "Marker", valid_595266
  var valid_595267 = query.getOrDefault("SubscriptionName")
  valid_595267 = validateParameter(valid_595267, JString, required = false,
                                 default = nil)
  if valid_595267 != nil:
    section.add "SubscriptionName", valid_595267
  var valid_595268 = query.getOrDefault("Version")
  valid_595268 = validateParameter(valid_595268, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595268 != nil:
    section.add "Version", valid_595268
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
  var valid_595269 = header.getOrDefault("X-Amz-Date")
  valid_595269 = validateParameter(valid_595269, JString, required = false,
                                 default = nil)
  if valid_595269 != nil:
    section.add "X-Amz-Date", valid_595269
  var valid_595270 = header.getOrDefault("X-Amz-Security-Token")
  valid_595270 = validateParameter(valid_595270, JString, required = false,
                                 default = nil)
  if valid_595270 != nil:
    section.add "X-Amz-Security-Token", valid_595270
  var valid_595271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595271 = validateParameter(valid_595271, JString, required = false,
                                 default = nil)
  if valid_595271 != nil:
    section.add "X-Amz-Content-Sha256", valid_595271
  var valid_595272 = header.getOrDefault("X-Amz-Algorithm")
  valid_595272 = validateParameter(valid_595272, JString, required = false,
                                 default = nil)
  if valid_595272 != nil:
    section.add "X-Amz-Algorithm", valid_595272
  var valid_595273 = header.getOrDefault("X-Amz-Signature")
  valid_595273 = validateParameter(valid_595273, JString, required = false,
                                 default = nil)
  if valid_595273 != nil:
    section.add "X-Amz-Signature", valid_595273
  var valid_595274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595274 = validateParameter(valid_595274, JString, required = false,
                                 default = nil)
  if valid_595274 != nil:
    section.add "X-Amz-SignedHeaders", valid_595274
  var valid_595275 = header.getOrDefault("X-Amz-Credential")
  valid_595275 = validateParameter(valid_595275, JString, required = false,
                                 default = nil)
  if valid_595275 != nil:
    section.add "X-Amz-Credential", valid_595275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595276: Call_GetDescribeEventSubscriptions_595260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595276.validator(path, query, header, formData, body)
  let scheme = call_595276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595276.url(scheme.get, call_595276.host, call_595276.base,
                         call_595276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595276, url, valid)

proc call*(call_595277: Call_GetDescribeEventSubscriptions_595260;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeEventSubscriptions"; Marker: string = "";
          SubscriptionName: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_595278 = newJObject()
  add(query_595278, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595278.add "Filters", Filters
  add(query_595278, "Action", newJString(Action))
  add(query_595278, "Marker", newJString(Marker))
  add(query_595278, "SubscriptionName", newJString(SubscriptionName))
  add(query_595278, "Version", newJString(Version))
  result = call_595277.call(nil, query_595278, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_595260(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_595261, base: "/",
    url: url_GetDescribeEventSubscriptions_595262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_595323 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEvents_595325(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_595324(path: JsonNode; query: JsonNode;
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
  var valid_595326 = query.getOrDefault("Action")
  valid_595326 = validateParameter(valid_595326, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_595326 != nil:
    section.add "Action", valid_595326
  var valid_595327 = query.getOrDefault("Version")
  valid_595327 = validateParameter(valid_595327, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595327 != nil:
    section.add "Version", valid_595327
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
  var valid_595328 = header.getOrDefault("X-Amz-Date")
  valid_595328 = validateParameter(valid_595328, JString, required = false,
                                 default = nil)
  if valid_595328 != nil:
    section.add "X-Amz-Date", valid_595328
  var valid_595329 = header.getOrDefault("X-Amz-Security-Token")
  valid_595329 = validateParameter(valid_595329, JString, required = false,
                                 default = nil)
  if valid_595329 != nil:
    section.add "X-Amz-Security-Token", valid_595329
  var valid_595330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595330 = validateParameter(valid_595330, JString, required = false,
                                 default = nil)
  if valid_595330 != nil:
    section.add "X-Amz-Content-Sha256", valid_595330
  var valid_595331 = header.getOrDefault("X-Amz-Algorithm")
  valid_595331 = validateParameter(valid_595331, JString, required = false,
                                 default = nil)
  if valid_595331 != nil:
    section.add "X-Amz-Algorithm", valid_595331
  var valid_595332 = header.getOrDefault("X-Amz-Signature")
  valid_595332 = validateParameter(valid_595332, JString, required = false,
                                 default = nil)
  if valid_595332 != nil:
    section.add "X-Amz-Signature", valid_595332
  var valid_595333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595333 = validateParameter(valid_595333, JString, required = false,
                                 default = nil)
  if valid_595333 != nil:
    section.add "X-Amz-SignedHeaders", valid_595333
  var valid_595334 = header.getOrDefault("X-Amz-Credential")
  valid_595334 = validateParameter(valid_595334, JString, required = false,
                                 default = nil)
  if valid_595334 != nil:
    section.add "X-Amz-Credential", valid_595334
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
  var valid_595335 = formData.getOrDefault("SourceIdentifier")
  valid_595335 = validateParameter(valid_595335, JString, required = false,
                                 default = nil)
  if valid_595335 != nil:
    section.add "SourceIdentifier", valid_595335
  var valid_595336 = formData.getOrDefault("EventCategories")
  valid_595336 = validateParameter(valid_595336, JArray, required = false,
                                 default = nil)
  if valid_595336 != nil:
    section.add "EventCategories", valid_595336
  var valid_595337 = formData.getOrDefault("Marker")
  valid_595337 = validateParameter(valid_595337, JString, required = false,
                                 default = nil)
  if valid_595337 != nil:
    section.add "Marker", valid_595337
  var valid_595338 = formData.getOrDefault("StartTime")
  valid_595338 = validateParameter(valid_595338, JString, required = false,
                                 default = nil)
  if valid_595338 != nil:
    section.add "StartTime", valid_595338
  var valid_595339 = formData.getOrDefault("Duration")
  valid_595339 = validateParameter(valid_595339, JInt, required = false, default = nil)
  if valid_595339 != nil:
    section.add "Duration", valid_595339
  var valid_595340 = formData.getOrDefault("Filters")
  valid_595340 = validateParameter(valid_595340, JArray, required = false,
                                 default = nil)
  if valid_595340 != nil:
    section.add "Filters", valid_595340
  var valid_595341 = formData.getOrDefault("EndTime")
  valid_595341 = validateParameter(valid_595341, JString, required = false,
                                 default = nil)
  if valid_595341 != nil:
    section.add "EndTime", valid_595341
  var valid_595342 = formData.getOrDefault("MaxRecords")
  valid_595342 = validateParameter(valid_595342, JInt, required = false, default = nil)
  if valid_595342 != nil:
    section.add "MaxRecords", valid_595342
  var valid_595343 = formData.getOrDefault("SourceType")
  valid_595343 = validateParameter(valid_595343, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_595343 != nil:
    section.add "SourceType", valid_595343
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595344: Call_PostDescribeEvents_595323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595344.validator(path, query, header, formData, body)
  let scheme = call_595344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595344.url(scheme.get, call_595344.host, call_595344.base,
                         call_595344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595344, url, valid)

proc call*(call_595345: Call_PostDescribeEvents_595323;
          SourceIdentifier: string = ""; EventCategories: JsonNode = nil;
          Marker: string = ""; StartTime: string = "";
          Action: string = "DescribeEvents"; Duration: int = 0; Filters: JsonNode = nil;
          EndTime: string = ""; MaxRecords: int = 0; Version: string = "2014-09-01";
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
  var query_595346 = newJObject()
  var formData_595347 = newJObject()
  add(formData_595347, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_595347.add "EventCategories", EventCategories
  add(formData_595347, "Marker", newJString(Marker))
  add(formData_595347, "StartTime", newJString(StartTime))
  add(query_595346, "Action", newJString(Action))
  add(formData_595347, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_595347.add "Filters", Filters
  add(formData_595347, "EndTime", newJString(EndTime))
  add(formData_595347, "MaxRecords", newJInt(MaxRecords))
  add(query_595346, "Version", newJString(Version))
  add(formData_595347, "SourceType", newJString(SourceType))
  result = call_595345.call(nil, query_595346, nil, formData_595347, nil)

var postDescribeEvents* = Call_PostDescribeEvents_595323(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_595324, base: "/",
    url: url_PostDescribeEvents_595325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_595299 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEvents_595301(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_595300(path: JsonNode; query: JsonNode;
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
  var valid_595302 = query.getOrDefault("SourceType")
  valid_595302 = validateParameter(valid_595302, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_595302 != nil:
    section.add "SourceType", valid_595302
  var valid_595303 = query.getOrDefault("MaxRecords")
  valid_595303 = validateParameter(valid_595303, JInt, required = false, default = nil)
  if valid_595303 != nil:
    section.add "MaxRecords", valid_595303
  var valid_595304 = query.getOrDefault("StartTime")
  valid_595304 = validateParameter(valid_595304, JString, required = false,
                                 default = nil)
  if valid_595304 != nil:
    section.add "StartTime", valid_595304
  var valid_595305 = query.getOrDefault("Filters")
  valid_595305 = validateParameter(valid_595305, JArray, required = false,
                                 default = nil)
  if valid_595305 != nil:
    section.add "Filters", valid_595305
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595306 = query.getOrDefault("Action")
  valid_595306 = validateParameter(valid_595306, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_595306 != nil:
    section.add "Action", valid_595306
  var valid_595307 = query.getOrDefault("SourceIdentifier")
  valid_595307 = validateParameter(valid_595307, JString, required = false,
                                 default = nil)
  if valid_595307 != nil:
    section.add "SourceIdentifier", valid_595307
  var valid_595308 = query.getOrDefault("Marker")
  valid_595308 = validateParameter(valid_595308, JString, required = false,
                                 default = nil)
  if valid_595308 != nil:
    section.add "Marker", valid_595308
  var valid_595309 = query.getOrDefault("EventCategories")
  valid_595309 = validateParameter(valid_595309, JArray, required = false,
                                 default = nil)
  if valid_595309 != nil:
    section.add "EventCategories", valid_595309
  var valid_595310 = query.getOrDefault("Duration")
  valid_595310 = validateParameter(valid_595310, JInt, required = false, default = nil)
  if valid_595310 != nil:
    section.add "Duration", valid_595310
  var valid_595311 = query.getOrDefault("EndTime")
  valid_595311 = validateParameter(valid_595311, JString, required = false,
                                 default = nil)
  if valid_595311 != nil:
    section.add "EndTime", valid_595311
  var valid_595312 = query.getOrDefault("Version")
  valid_595312 = validateParameter(valid_595312, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595312 != nil:
    section.add "Version", valid_595312
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
  var valid_595313 = header.getOrDefault("X-Amz-Date")
  valid_595313 = validateParameter(valid_595313, JString, required = false,
                                 default = nil)
  if valid_595313 != nil:
    section.add "X-Amz-Date", valid_595313
  var valid_595314 = header.getOrDefault("X-Amz-Security-Token")
  valid_595314 = validateParameter(valid_595314, JString, required = false,
                                 default = nil)
  if valid_595314 != nil:
    section.add "X-Amz-Security-Token", valid_595314
  var valid_595315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595315 = validateParameter(valid_595315, JString, required = false,
                                 default = nil)
  if valid_595315 != nil:
    section.add "X-Amz-Content-Sha256", valid_595315
  var valid_595316 = header.getOrDefault("X-Amz-Algorithm")
  valid_595316 = validateParameter(valid_595316, JString, required = false,
                                 default = nil)
  if valid_595316 != nil:
    section.add "X-Amz-Algorithm", valid_595316
  var valid_595317 = header.getOrDefault("X-Amz-Signature")
  valid_595317 = validateParameter(valid_595317, JString, required = false,
                                 default = nil)
  if valid_595317 != nil:
    section.add "X-Amz-Signature", valid_595317
  var valid_595318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595318 = validateParameter(valid_595318, JString, required = false,
                                 default = nil)
  if valid_595318 != nil:
    section.add "X-Amz-SignedHeaders", valid_595318
  var valid_595319 = header.getOrDefault("X-Amz-Credential")
  valid_595319 = validateParameter(valid_595319, JString, required = false,
                                 default = nil)
  if valid_595319 != nil:
    section.add "X-Amz-Credential", valid_595319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595320: Call_GetDescribeEvents_595299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595320.validator(path, query, header, formData, body)
  let scheme = call_595320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595320.url(scheme.get, call_595320.host, call_595320.base,
                         call_595320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595320, url, valid)

proc call*(call_595321: Call_GetDescribeEvents_595299;
          SourceType: string = "db-instance"; MaxRecords: int = 0;
          StartTime: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEvents"; SourceIdentifier: string = "";
          Marker: string = ""; EventCategories: JsonNode = nil; Duration: int = 0;
          EndTime: string = ""; Version: string = "2014-09-01"): Recallable =
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
  var query_595322 = newJObject()
  add(query_595322, "SourceType", newJString(SourceType))
  add(query_595322, "MaxRecords", newJInt(MaxRecords))
  add(query_595322, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_595322.add "Filters", Filters
  add(query_595322, "Action", newJString(Action))
  add(query_595322, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_595322, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_595322.add "EventCategories", EventCategories
  add(query_595322, "Duration", newJInt(Duration))
  add(query_595322, "EndTime", newJString(EndTime))
  add(query_595322, "Version", newJString(Version))
  result = call_595321.call(nil, query_595322, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_595299(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_595300,
    base: "/", url: url_GetDescribeEvents_595301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_595368 = ref object of OpenApiRestCall_593421
proc url_PostDescribeOptionGroupOptions_595370(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_595369(path: JsonNode;
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
  var valid_595371 = query.getOrDefault("Action")
  valid_595371 = validateParameter(valid_595371, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_595371 != nil:
    section.add "Action", valid_595371
  var valid_595372 = query.getOrDefault("Version")
  valid_595372 = validateParameter(valid_595372, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595372 != nil:
    section.add "Version", valid_595372
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
  var valid_595373 = header.getOrDefault("X-Amz-Date")
  valid_595373 = validateParameter(valid_595373, JString, required = false,
                                 default = nil)
  if valid_595373 != nil:
    section.add "X-Amz-Date", valid_595373
  var valid_595374 = header.getOrDefault("X-Amz-Security-Token")
  valid_595374 = validateParameter(valid_595374, JString, required = false,
                                 default = nil)
  if valid_595374 != nil:
    section.add "X-Amz-Security-Token", valid_595374
  var valid_595375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595375 = validateParameter(valid_595375, JString, required = false,
                                 default = nil)
  if valid_595375 != nil:
    section.add "X-Amz-Content-Sha256", valid_595375
  var valid_595376 = header.getOrDefault("X-Amz-Algorithm")
  valid_595376 = validateParameter(valid_595376, JString, required = false,
                                 default = nil)
  if valid_595376 != nil:
    section.add "X-Amz-Algorithm", valid_595376
  var valid_595377 = header.getOrDefault("X-Amz-Signature")
  valid_595377 = validateParameter(valid_595377, JString, required = false,
                                 default = nil)
  if valid_595377 != nil:
    section.add "X-Amz-Signature", valid_595377
  var valid_595378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595378 = validateParameter(valid_595378, JString, required = false,
                                 default = nil)
  if valid_595378 != nil:
    section.add "X-Amz-SignedHeaders", valid_595378
  var valid_595379 = header.getOrDefault("X-Amz-Credential")
  valid_595379 = validateParameter(valid_595379, JString, required = false,
                                 default = nil)
  if valid_595379 != nil:
    section.add "X-Amz-Credential", valid_595379
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595380 = formData.getOrDefault("MajorEngineVersion")
  valid_595380 = validateParameter(valid_595380, JString, required = false,
                                 default = nil)
  if valid_595380 != nil:
    section.add "MajorEngineVersion", valid_595380
  var valid_595381 = formData.getOrDefault("Marker")
  valid_595381 = validateParameter(valid_595381, JString, required = false,
                                 default = nil)
  if valid_595381 != nil:
    section.add "Marker", valid_595381
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_595382 = formData.getOrDefault("EngineName")
  valid_595382 = validateParameter(valid_595382, JString, required = true,
                                 default = nil)
  if valid_595382 != nil:
    section.add "EngineName", valid_595382
  var valid_595383 = formData.getOrDefault("Filters")
  valid_595383 = validateParameter(valid_595383, JArray, required = false,
                                 default = nil)
  if valid_595383 != nil:
    section.add "Filters", valid_595383
  var valid_595384 = formData.getOrDefault("MaxRecords")
  valid_595384 = validateParameter(valid_595384, JInt, required = false, default = nil)
  if valid_595384 != nil:
    section.add "MaxRecords", valid_595384
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595385: Call_PostDescribeOptionGroupOptions_595368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595385.validator(path, query, header, formData, body)
  let scheme = call_595385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595385.url(scheme.get, call_595385.host, call_595385.base,
                         call_595385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595385, url, valid)

proc call*(call_595386: Call_PostDescribeOptionGroupOptions_595368;
          EngineName: string; MajorEngineVersion: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MajorEngineVersion: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595387 = newJObject()
  var formData_595388 = newJObject()
  add(formData_595388, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_595388, "Marker", newJString(Marker))
  add(query_595387, "Action", newJString(Action))
  add(formData_595388, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_595388.add "Filters", Filters
  add(formData_595388, "MaxRecords", newJInt(MaxRecords))
  add(query_595387, "Version", newJString(Version))
  result = call_595386.call(nil, query_595387, nil, formData_595388, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_595368(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_595369, base: "/",
    url: url_PostDescribeOptionGroupOptions_595370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_595348 = ref object of OpenApiRestCall_593421
proc url_GetDescribeOptionGroupOptions_595350(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_595349(path: JsonNode; query: JsonNode;
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
  var valid_595351 = query.getOrDefault("MaxRecords")
  valid_595351 = validateParameter(valid_595351, JInt, required = false, default = nil)
  if valid_595351 != nil:
    section.add "MaxRecords", valid_595351
  var valid_595352 = query.getOrDefault("Filters")
  valid_595352 = validateParameter(valid_595352, JArray, required = false,
                                 default = nil)
  if valid_595352 != nil:
    section.add "Filters", valid_595352
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595353 = query.getOrDefault("Action")
  valid_595353 = validateParameter(valid_595353, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_595353 != nil:
    section.add "Action", valid_595353
  var valid_595354 = query.getOrDefault("Marker")
  valid_595354 = validateParameter(valid_595354, JString, required = false,
                                 default = nil)
  if valid_595354 != nil:
    section.add "Marker", valid_595354
  var valid_595355 = query.getOrDefault("Version")
  valid_595355 = validateParameter(valid_595355, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595355 != nil:
    section.add "Version", valid_595355
  var valid_595356 = query.getOrDefault("EngineName")
  valid_595356 = validateParameter(valid_595356, JString, required = true,
                                 default = nil)
  if valid_595356 != nil:
    section.add "EngineName", valid_595356
  var valid_595357 = query.getOrDefault("MajorEngineVersion")
  valid_595357 = validateParameter(valid_595357, JString, required = false,
                                 default = nil)
  if valid_595357 != nil:
    section.add "MajorEngineVersion", valid_595357
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
  var valid_595358 = header.getOrDefault("X-Amz-Date")
  valid_595358 = validateParameter(valid_595358, JString, required = false,
                                 default = nil)
  if valid_595358 != nil:
    section.add "X-Amz-Date", valid_595358
  var valid_595359 = header.getOrDefault("X-Amz-Security-Token")
  valid_595359 = validateParameter(valid_595359, JString, required = false,
                                 default = nil)
  if valid_595359 != nil:
    section.add "X-Amz-Security-Token", valid_595359
  var valid_595360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595360 = validateParameter(valid_595360, JString, required = false,
                                 default = nil)
  if valid_595360 != nil:
    section.add "X-Amz-Content-Sha256", valid_595360
  var valid_595361 = header.getOrDefault("X-Amz-Algorithm")
  valid_595361 = validateParameter(valid_595361, JString, required = false,
                                 default = nil)
  if valid_595361 != nil:
    section.add "X-Amz-Algorithm", valid_595361
  var valid_595362 = header.getOrDefault("X-Amz-Signature")
  valid_595362 = validateParameter(valid_595362, JString, required = false,
                                 default = nil)
  if valid_595362 != nil:
    section.add "X-Amz-Signature", valid_595362
  var valid_595363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595363 = validateParameter(valid_595363, JString, required = false,
                                 default = nil)
  if valid_595363 != nil:
    section.add "X-Amz-SignedHeaders", valid_595363
  var valid_595364 = header.getOrDefault("X-Amz-Credential")
  valid_595364 = validateParameter(valid_595364, JString, required = false,
                                 default = nil)
  if valid_595364 != nil:
    section.add "X-Amz-Credential", valid_595364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595365: Call_GetDescribeOptionGroupOptions_595348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595365.validator(path, query, header, formData, body)
  let scheme = call_595365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595365.url(scheme.get, call_595365.host, call_595365.base,
                         call_595365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595365, url, valid)

proc call*(call_595366: Call_GetDescribeOptionGroupOptions_595348;
          EngineName: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeOptionGroupOptions"; Marker: string = "";
          Version: string = "2014-09-01"; MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  var query_595367 = newJObject()
  add(query_595367, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595367.add "Filters", Filters
  add(query_595367, "Action", newJString(Action))
  add(query_595367, "Marker", newJString(Marker))
  add(query_595367, "Version", newJString(Version))
  add(query_595367, "EngineName", newJString(EngineName))
  add(query_595367, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_595366.call(nil, query_595367, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_595348(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_595349, base: "/",
    url: url_GetDescribeOptionGroupOptions_595350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_595410 = ref object of OpenApiRestCall_593421
proc url_PostDescribeOptionGroups_595412(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_595411(path: JsonNode; query: JsonNode;
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
  var valid_595413 = query.getOrDefault("Action")
  valid_595413 = validateParameter(valid_595413, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_595413 != nil:
    section.add "Action", valid_595413
  var valid_595414 = query.getOrDefault("Version")
  valid_595414 = validateParameter(valid_595414, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595414 != nil:
    section.add "Version", valid_595414
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
  var valid_595415 = header.getOrDefault("X-Amz-Date")
  valid_595415 = validateParameter(valid_595415, JString, required = false,
                                 default = nil)
  if valid_595415 != nil:
    section.add "X-Amz-Date", valid_595415
  var valid_595416 = header.getOrDefault("X-Amz-Security-Token")
  valid_595416 = validateParameter(valid_595416, JString, required = false,
                                 default = nil)
  if valid_595416 != nil:
    section.add "X-Amz-Security-Token", valid_595416
  var valid_595417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595417 = validateParameter(valid_595417, JString, required = false,
                                 default = nil)
  if valid_595417 != nil:
    section.add "X-Amz-Content-Sha256", valid_595417
  var valid_595418 = header.getOrDefault("X-Amz-Algorithm")
  valid_595418 = validateParameter(valid_595418, JString, required = false,
                                 default = nil)
  if valid_595418 != nil:
    section.add "X-Amz-Algorithm", valid_595418
  var valid_595419 = header.getOrDefault("X-Amz-Signature")
  valid_595419 = validateParameter(valid_595419, JString, required = false,
                                 default = nil)
  if valid_595419 != nil:
    section.add "X-Amz-Signature", valid_595419
  var valid_595420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595420 = validateParameter(valid_595420, JString, required = false,
                                 default = nil)
  if valid_595420 != nil:
    section.add "X-Amz-SignedHeaders", valid_595420
  var valid_595421 = header.getOrDefault("X-Amz-Credential")
  valid_595421 = validateParameter(valid_595421, JString, required = false,
                                 default = nil)
  if valid_595421 != nil:
    section.add "X-Amz-Credential", valid_595421
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595422 = formData.getOrDefault("MajorEngineVersion")
  valid_595422 = validateParameter(valid_595422, JString, required = false,
                                 default = nil)
  if valid_595422 != nil:
    section.add "MajorEngineVersion", valid_595422
  var valid_595423 = formData.getOrDefault("OptionGroupName")
  valid_595423 = validateParameter(valid_595423, JString, required = false,
                                 default = nil)
  if valid_595423 != nil:
    section.add "OptionGroupName", valid_595423
  var valid_595424 = formData.getOrDefault("Marker")
  valid_595424 = validateParameter(valid_595424, JString, required = false,
                                 default = nil)
  if valid_595424 != nil:
    section.add "Marker", valid_595424
  var valid_595425 = formData.getOrDefault("EngineName")
  valid_595425 = validateParameter(valid_595425, JString, required = false,
                                 default = nil)
  if valid_595425 != nil:
    section.add "EngineName", valid_595425
  var valid_595426 = formData.getOrDefault("Filters")
  valid_595426 = validateParameter(valid_595426, JArray, required = false,
                                 default = nil)
  if valid_595426 != nil:
    section.add "Filters", valid_595426
  var valid_595427 = formData.getOrDefault("MaxRecords")
  valid_595427 = validateParameter(valid_595427, JInt, required = false, default = nil)
  if valid_595427 != nil:
    section.add "MaxRecords", valid_595427
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595428: Call_PostDescribeOptionGroups_595410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595428.validator(path, query, header, formData, body)
  let scheme = call_595428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595428.url(scheme.get, call_595428.host, call_595428.base,
                         call_595428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595428, url, valid)

proc call*(call_595429: Call_PostDescribeOptionGroups_595410;
          MajorEngineVersion: string = ""; OptionGroupName: string = "";
          Marker: string = ""; Action: string = "DescribeOptionGroups";
          EngineName: string = ""; Filters: JsonNode = nil; MaxRecords: int = 0;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeOptionGroups
  ##   MajorEngineVersion: string
  ##   OptionGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595430 = newJObject()
  var formData_595431 = newJObject()
  add(formData_595431, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_595431, "OptionGroupName", newJString(OptionGroupName))
  add(formData_595431, "Marker", newJString(Marker))
  add(query_595430, "Action", newJString(Action))
  add(formData_595431, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_595431.add "Filters", Filters
  add(formData_595431, "MaxRecords", newJInt(MaxRecords))
  add(query_595430, "Version", newJString(Version))
  result = call_595429.call(nil, query_595430, nil, formData_595431, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_595410(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_595411, base: "/",
    url: url_PostDescribeOptionGroups_595412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_595389 = ref object of OpenApiRestCall_593421
proc url_GetDescribeOptionGroups_595391(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_595390(path: JsonNode; query: JsonNode;
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
  var valid_595392 = query.getOrDefault("MaxRecords")
  valid_595392 = validateParameter(valid_595392, JInt, required = false, default = nil)
  if valid_595392 != nil:
    section.add "MaxRecords", valid_595392
  var valid_595393 = query.getOrDefault("OptionGroupName")
  valid_595393 = validateParameter(valid_595393, JString, required = false,
                                 default = nil)
  if valid_595393 != nil:
    section.add "OptionGroupName", valid_595393
  var valid_595394 = query.getOrDefault("Filters")
  valid_595394 = validateParameter(valid_595394, JArray, required = false,
                                 default = nil)
  if valid_595394 != nil:
    section.add "Filters", valid_595394
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595395 = query.getOrDefault("Action")
  valid_595395 = validateParameter(valid_595395, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_595395 != nil:
    section.add "Action", valid_595395
  var valid_595396 = query.getOrDefault("Marker")
  valid_595396 = validateParameter(valid_595396, JString, required = false,
                                 default = nil)
  if valid_595396 != nil:
    section.add "Marker", valid_595396
  var valid_595397 = query.getOrDefault("Version")
  valid_595397 = validateParameter(valid_595397, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595397 != nil:
    section.add "Version", valid_595397
  var valid_595398 = query.getOrDefault("EngineName")
  valid_595398 = validateParameter(valid_595398, JString, required = false,
                                 default = nil)
  if valid_595398 != nil:
    section.add "EngineName", valid_595398
  var valid_595399 = query.getOrDefault("MajorEngineVersion")
  valid_595399 = validateParameter(valid_595399, JString, required = false,
                                 default = nil)
  if valid_595399 != nil:
    section.add "MajorEngineVersion", valid_595399
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
  var valid_595400 = header.getOrDefault("X-Amz-Date")
  valid_595400 = validateParameter(valid_595400, JString, required = false,
                                 default = nil)
  if valid_595400 != nil:
    section.add "X-Amz-Date", valid_595400
  var valid_595401 = header.getOrDefault("X-Amz-Security-Token")
  valid_595401 = validateParameter(valid_595401, JString, required = false,
                                 default = nil)
  if valid_595401 != nil:
    section.add "X-Amz-Security-Token", valid_595401
  var valid_595402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595402 = validateParameter(valid_595402, JString, required = false,
                                 default = nil)
  if valid_595402 != nil:
    section.add "X-Amz-Content-Sha256", valid_595402
  var valid_595403 = header.getOrDefault("X-Amz-Algorithm")
  valid_595403 = validateParameter(valid_595403, JString, required = false,
                                 default = nil)
  if valid_595403 != nil:
    section.add "X-Amz-Algorithm", valid_595403
  var valid_595404 = header.getOrDefault("X-Amz-Signature")
  valid_595404 = validateParameter(valid_595404, JString, required = false,
                                 default = nil)
  if valid_595404 != nil:
    section.add "X-Amz-Signature", valid_595404
  var valid_595405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595405 = validateParameter(valid_595405, JString, required = false,
                                 default = nil)
  if valid_595405 != nil:
    section.add "X-Amz-SignedHeaders", valid_595405
  var valid_595406 = header.getOrDefault("X-Amz-Credential")
  valid_595406 = validateParameter(valid_595406, JString, required = false,
                                 default = nil)
  if valid_595406 != nil:
    section.add "X-Amz-Credential", valid_595406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595407: Call_GetDescribeOptionGroups_595389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595407.validator(path, query, header, formData, body)
  let scheme = call_595407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595407.url(scheme.get, call_595407.host, call_595407.base,
                         call_595407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595407, url, valid)

proc call*(call_595408: Call_GetDescribeOptionGroups_595389; MaxRecords: int = 0;
          OptionGroupName: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeOptionGroups"; Marker: string = "";
          Version: string = "2014-09-01"; EngineName: string = "";
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
  var query_595409 = newJObject()
  add(query_595409, "MaxRecords", newJInt(MaxRecords))
  add(query_595409, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_595409.add "Filters", Filters
  add(query_595409, "Action", newJString(Action))
  add(query_595409, "Marker", newJString(Marker))
  add(query_595409, "Version", newJString(Version))
  add(query_595409, "EngineName", newJString(EngineName))
  add(query_595409, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_595408.call(nil, query_595409, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_595389(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_595390, base: "/",
    url: url_GetDescribeOptionGroups_595391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_595455 = ref object of OpenApiRestCall_593421
proc url_PostDescribeOrderableDBInstanceOptions_595457(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_595456(path: JsonNode;
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
  var valid_595458 = query.getOrDefault("Action")
  valid_595458 = validateParameter(valid_595458, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_595458 != nil:
    section.add "Action", valid_595458
  var valid_595459 = query.getOrDefault("Version")
  valid_595459 = validateParameter(valid_595459, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595459 != nil:
    section.add "Version", valid_595459
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
  var valid_595460 = header.getOrDefault("X-Amz-Date")
  valid_595460 = validateParameter(valid_595460, JString, required = false,
                                 default = nil)
  if valid_595460 != nil:
    section.add "X-Amz-Date", valid_595460
  var valid_595461 = header.getOrDefault("X-Amz-Security-Token")
  valid_595461 = validateParameter(valid_595461, JString, required = false,
                                 default = nil)
  if valid_595461 != nil:
    section.add "X-Amz-Security-Token", valid_595461
  var valid_595462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595462 = validateParameter(valid_595462, JString, required = false,
                                 default = nil)
  if valid_595462 != nil:
    section.add "X-Amz-Content-Sha256", valid_595462
  var valid_595463 = header.getOrDefault("X-Amz-Algorithm")
  valid_595463 = validateParameter(valid_595463, JString, required = false,
                                 default = nil)
  if valid_595463 != nil:
    section.add "X-Amz-Algorithm", valid_595463
  var valid_595464 = header.getOrDefault("X-Amz-Signature")
  valid_595464 = validateParameter(valid_595464, JString, required = false,
                                 default = nil)
  if valid_595464 != nil:
    section.add "X-Amz-Signature", valid_595464
  var valid_595465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595465 = validateParameter(valid_595465, JString, required = false,
                                 default = nil)
  if valid_595465 != nil:
    section.add "X-Amz-SignedHeaders", valid_595465
  var valid_595466 = header.getOrDefault("X-Amz-Credential")
  valid_595466 = validateParameter(valid_595466, JString, required = false,
                                 default = nil)
  if valid_595466 != nil:
    section.add "X-Amz-Credential", valid_595466
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
  var valid_595467 = formData.getOrDefault("Engine")
  valid_595467 = validateParameter(valid_595467, JString, required = true,
                                 default = nil)
  if valid_595467 != nil:
    section.add "Engine", valid_595467
  var valid_595468 = formData.getOrDefault("Marker")
  valid_595468 = validateParameter(valid_595468, JString, required = false,
                                 default = nil)
  if valid_595468 != nil:
    section.add "Marker", valid_595468
  var valid_595469 = formData.getOrDefault("Vpc")
  valid_595469 = validateParameter(valid_595469, JBool, required = false, default = nil)
  if valid_595469 != nil:
    section.add "Vpc", valid_595469
  var valid_595470 = formData.getOrDefault("DBInstanceClass")
  valid_595470 = validateParameter(valid_595470, JString, required = false,
                                 default = nil)
  if valid_595470 != nil:
    section.add "DBInstanceClass", valid_595470
  var valid_595471 = formData.getOrDefault("Filters")
  valid_595471 = validateParameter(valid_595471, JArray, required = false,
                                 default = nil)
  if valid_595471 != nil:
    section.add "Filters", valid_595471
  var valid_595472 = formData.getOrDefault("LicenseModel")
  valid_595472 = validateParameter(valid_595472, JString, required = false,
                                 default = nil)
  if valid_595472 != nil:
    section.add "LicenseModel", valid_595472
  var valid_595473 = formData.getOrDefault("MaxRecords")
  valid_595473 = validateParameter(valid_595473, JInt, required = false, default = nil)
  if valid_595473 != nil:
    section.add "MaxRecords", valid_595473
  var valid_595474 = formData.getOrDefault("EngineVersion")
  valid_595474 = validateParameter(valid_595474, JString, required = false,
                                 default = nil)
  if valid_595474 != nil:
    section.add "EngineVersion", valid_595474
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595475: Call_PostDescribeOrderableDBInstanceOptions_595455;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595475.validator(path, query, header, formData, body)
  let scheme = call_595475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595475.url(scheme.get, call_595475.host, call_595475.base,
                         call_595475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595475, url, valid)

proc call*(call_595476: Call_PostDescribeOrderableDBInstanceOptions_595455;
          Engine: string; Marker: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions"; Vpc: bool = false;
          DBInstanceClass: string = ""; Filters: JsonNode = nil;
          LicenseModel: string = ""; MaxRecords: int = 0; EngineVersion: string = "";
          Version: string = "2014-09-01"): Recallable =
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
  var query_595477 = newJObject()
  var formData_595478 = newJObject()
  add(formData_595478, "Engine", newJString(Engine))
  add(formData_595478, "Marker", newJString(Marker))
  add(query_595477, "Action", newJString(Action))
  add(formData_595478, "Vpc", newJBool(Vpc))
  add(formData_595478, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_595478.add "Filters", Filters
  add(formData_595478, "LicenseModel", newJString(LicenseModel))
  add(formData_595478, "MaxRecords", newJInt(MaxRecords))
  add(formData_595478, "EngineVersion", newJString(EngineVersion))
  add(query_595477, "Version", newJString(Version))
  result = call_595476.call(nil, query_595477, nil, formData_595478, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_595455(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_595456, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_595457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_595432 = ref object of OpenApiRestCall_593421
proc url_GetDescribeOrderableDBInstanceOptions_595434(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_595433(path: JsonNode;
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
  var valid_595435 = query.getOrDefault("Engine")
  valid_595435 = validateParameter(valid_595435, JString, required = true,
                                 default = nil)
  if valid_595435 != nil:
    section.add "Engine", valid_595435
  var valid_595436 = query.getOrDefault("MaxRecords")
  valid_595436 = validateParameter(valid_595436, JInt, required = false, default = nil)
  if valid_595436 != nil:
    section.add "MaxRecords", valid_595436
  var valid_595437 = query.getOrDefault("Filters")
  valid_595437 = validateParameter(valid_595437, JArray, required = false,
                                 default = nil)
  if valid_595437 != nil:
    section.add "Filters", valid_595437
  var valid_595438 = query.getOrDefault("LicenseModel")
  valid_595438 = validateParameter(valid_595438, JString, required = false,
                                 default = nil)
  if valid_595438 != nil:
    section.add "LicenseModel", valid_595438
  var valid_595439 = query.getOrDefault("Vpc")
  valid_595439 = validateParameter(valid_595439, JBool, required = false, default = nil)
  if valid_595439 != nil:
    section.add "Vpc", valid_595439
  var valid_595440 = query.getOrDefault("DBInstanceClass")
  valid_595440 = validateParameter(valid_595440, JString, required = false,
                                 default = nil)
  if valid_595440 != nil:
    section.add "DBInstanceClass", valid_595440
  var valid_595441 = query.getOrDefault("Action")
  valid_595441 = validateParameter(valid_595441, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_595441 != nil:
    section.add "Action", valid_595441
  var valid_595442 = query.getOrDefault("Marker")
  valid_595442 = validateParameter(valid_595442, JString, required = false,
                                 default = nil)
  if valid_595442 != nil:
    section.add "Marker", valid_595442
  var valid_595443 = query.getOrDefault("EngineVersion")
  valid_595443 = validateParameter(valid_595443, JString, required = false,
                                 default = nil)
  if valid_595443 != nil:
    section.add "EngineVersion", valid_595443
  var valid_595444 = query.getOrDefault("Version")
  valid_595444 = validateParameter(valid_595444, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595444 != nil:
    section.add "Version", valid_595444
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
  var valid_595445 = header.getOrDefault("X-Amz-Date")
  valid_595445 = validateParameter(valid_595445, JString, required = false,
                                 default = nil)
  if valid_595445 != nil:
    section.add "X-Amz-Date", valid_595445
  var valid_595446 = header.getOrDefault("X-Amz-Security-Token")
  valid_595446 = validateParameter(valid_595446, JString, required = false,
                                 default = nil)
  if valid_595446 != nil:
    section.add "X-Amz-Security-Token", valid_595446
  var valid_595447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595447 = validateParameter(valid_595447, JString, required = false,
                                 default = nil)
  if valid_595447 != nil:
    section.add "X-Amz-Content-Sha256", valid_595447
  var valid_595448 = header.getOrDefault("X-Amz-Algorithm")
  valid_595448 = validateParameter(valid_595448, JString, required = false,
                                 default = nil)
  if valid_595448 != nil:
    section.add "X-Amz-Algorithm", valid_595448
  var valid_595449 = header.getOrDefault("X-Amz-Signature")
  valid_595449 = validateParameter(valid_595449, JString, required = false,
                                 default = nil)
  if valid_595449 != nil:
    section.add "X-Amz-Signature", valid_595449
  var valid_595450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595450 = validateParameter(valid_595450, JString, required = false,
                                 default = nil)
  if valid_595450 != nil:
    section.add "X-Amz-SignedHeaders", valid_595450
  var valid_595451 = header.getOrDefault("X-Amz-Credential")
  valid_595451 = validateParameter(valid_595451, JString, required = false,
                                 default = nil)
  if valid_595451 != nil:
    section.add "X-Amz-Credential", valid_595451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595452: Call_GetDescribeOrderableDBInstanceOptions_595432;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595452.validator(path, query, header, formData, body)
  let scheme = call_595452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595452.url(scheme.get, call_595452.host, call_595452.base,
                         call_595452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595452, url, valid)

proc call*(call_595453: Call_GetDescribeOrderableDBInstanceOptions_595432;
          Engine: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          LicenseModel: string = ""; Vpc: bool = false; DBInstanceClass: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Marker: string = ""; EngineVersion: string = "";
          Version: string = "2014-09-01"): Recallable =
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
  var query_595454 = newJObject()
  add(query_595454, "Engine", newJString(Engine))
  add(query_595454, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595454.add "Filters", Filters
  add(query_595454, "LicenseModel", newJString(LicenseModel))
  add(query_595454, "Vpc", newJBool(Vpc))
  add(query_595454, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595454, "Action", newJString(Action))
  add(query_595454, "Marker", newJString(Marker))
  add(query_595454, "EngineVersion", newJString(EngineVersion))
  add(query_595454, "Version", newJString(Version))
  result = call_595453.call(nil, query_595454, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_595432(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_595433, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_595434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_595504 = ref object of OpenApiRestCall_593421
proc url_PostDescribeReservedDBInstances_595506(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_595505(path: JsonNode;
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
  var valid_595507 = query.getOrDefault("Action")
  valid_595507 = validateParameter(valid_595507, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_595507 != nil:
    section.add "Action", valid_595507
  var valid_595508 = query.getOrDefault("Version")
  valid_595508 = validateParameter(valid_595508, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595508 != nil:
    section.add "Version", valid_595508
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
  var valid_595509 = header.getOrDefault("X-Amz-Date")
  valid_595509 = validateParameter(valid_595509, JString, required = false,
                                 default = nil)
  if valid_595509 != nil:
    section.add "X-Amz-Date", valid_595509
  var valid_595510 = header.getOrDefault("X-Amz-Security-Token")
  valid_595510 = validateParameter(valid_595510, JString, required = false,
                                 default = nil)
  if valid_595510 != nil:
    section.add "X-Amz-Security-Token", valid_595510
  var valid_595511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595511 = validateParameter(valid_595511, JString, required = false,
                                 default = nil)
  if valid_595511 != nil:
    section.add "X-Amz-Content-Sha256", valid_595511
  var valid_595512 = header.getOrDefault("X-Amz-Algorithm")
  valid_595512 = validateParameter(valid_595512, JString, required = false,
                                 default = nil)
  if valid_595512 != nil:
    section.add "X-Amz-Algorithm", valid_595512
  var valid_595513 = header.getOrDefault("X-Amz-Signature")
  valid_595513 = validateParameter(valid_595513, JString, required = false,
                                 default = nil)
  if valid_595513 != nil:
    section.add "X-Amz-Signature", valid_595513
  var valid_595514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595514 = validateParameter(valid_595514, JString, required = false,
                                 default = nil)
  if valid_595514 != nil:
    section.add "X-Amz-SignedHeaders", valid_595514
  var valid_595515 = header.getOrDefault("X-Amz-Credential")
  valid_595515 = validateParameter(valid_595515, JString, required = false,
                                 default = nil)
  if valid_595515 != nil:
    section.add "X-Amz-Credential", valid_595515
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
  var valid_595516 = formData.getOrDefault("OfferingType")
  valid_595516 = validateParameter(valid_595516, JString, required = false,
                                 default = nil)
  if valid_595516 != nil:
    section.add "OfferingType", valid_595516
  var valid_595517 = formData.getOrDefault("ReservedDBInstanceId")
  valid_595517 = validateParameter(valid_595517, JString, required = false,
                                 default = nil)
  if valid_595517 != nil:
    section.add "ReservedDBInstanceId", valid_595517
  var valid_595518 = formData.getOrDefault("Marker")
  valid_595518 = validateParameter(valid_595518, JString, required = false,
                                 default = nil)
  if valid_595518 != nil:
    section.add "Marker", valid_595518
  var valid_595519 = formData.getOrDefault("MultiAZ")
  valid_595519 = validateParameter(valid_595519, JBool, required = false, default = nil)
  if valid_595519 != nil:
    section.add "MultiAZ", valid_595519
  var valid_595520 = formData.getOrDefault("Duration")
  valid_595520 = validateParameter(valid_595520, JString, required = false,
                                 default = nil)
  if valid_595520 != nil:
    section.add "Duration", valid_595520
  var valid_595521 = formData.getOrDefault("DBInstanceClass")
  valid_595521 = validateParameter(valid_595521, JString, required = false,
                                 default = nil)
  if valid_595521 != nil:
    section.add "DBInstanceClass", valid_595521
  var valid_595522 = formData.getOrDefault("Filters")
  valid_595522 = validateParameter(valid_595522, JArray, required = false,
                                 default = nil)
  if valid_595522 != nil:
    section.add "Filters", valid_595522
  var valid_595523 = formData.getOrDefault("ProductDescription")
  valid_595523 = validateParameter(valid_595523, JString, required = false,
                                 default = nil)
  if valid_595523 != nil:
    section.add "ProductDescription", valid_595523
  var valid_595524 = formData.getOrDefault("MaxRecords")
  valid_595524 = validateParameter(valid_595524, JInt, required = false, default = nil)
  if valid_595524 != nil:
    section.add "MaxRecords", valid_595524
  var valid_595525 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595525 = validateParameter(valid_595525, JString, required = false,
                                 default = nil)
  if valid_595525 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595525
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595526: Call_PostDescribeReservedDBInstances_595504;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595526.validator(path, query, header, formData, body)
  let scheme = call_595526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595526.url(scheme.get, call_595526.host, call_595526.base,
                         call_595526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595526, url, valid)

proc call*(call_595527: Call_PostDescribeReservedDBInstances_595504;
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstances"; Duration: string = "";
          DBInstanceClass: string = ""; Filters: JsonNode = nil;
          ProductDescription: string = ""; MaxRecords: int = 0;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2014-09-01"): Recallable =
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
  var query_595528 = newJObject()
  var formData_595529 = newJObject()
  add(formData_595529, "OfferingType", newJString(OfferingType))
  add(formData_595529, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_595529, "Marker", newJString(Marker))
  add(formData_595529, "MultiAZ", newJBool(MultiAZ))
  add(query_595528, "Action", newJString(Action))
  add(formData_595529, "Duration", newJString(Duration))
  add(formData_595529, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_595529.add "Filters", Filters
  add(formData_595529, "ProductDescription", newJString(ProductDescription))
  add(formData_595529, "MaxRecords", newJInt(MaxRecords))
  add(formData_595529, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595528, "Version", newJString(Version))
  result = call_595527.call(nil, query_595528, nil, formData_595529, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_595504(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_595505, base: "/",
    url: url_PostDescribeReservedDBInstances_595506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_595479 = ref object of OpenApiRestCall_593421
proc url_GetDescribeReservedDBInstances_595481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_595480(path: JsonNode;
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
  var valid_595482 = query.getOrDefault("ProductDescription")
  valid_595482 = validateParameter(valid_595482, JString, required = false,
                                 default = nil)
  if valid_595482 != nil:
    section.add "ProductDescription", valid_595482
  var valid_595483 = query.getOrDefault("MaxRecords")
  valid_595483 = validateParameter(valid_595483, JInt, required = false, default = nil)
  if valid_595483 != nil:
    section.add "MaxRecords", valid_595483
  var valid_595484 = query.getOrDefault("OfferingType")
  valid_595484 = validateParameter(valid_595484, JString, required = false,
                                 default = nil)
  if valid_595484 != nil:
    section.add "OfferingType", valid_595484
  var valid_595485 = query.getOrDefault("Filters")
  valid_595485 = validateParameter(valid_595485, JArray, required = false,
                                 default = nil)
  if valid_595485 != nil:
    section.add "Filters", valid_595485
  var valid_595486 = query.getOrDefault("MultiAZ")
  valid_595486 = validateParameter(valid_595486, JBool, required = false, default = nil)
  if valid_595486 != nil:
    section.add "MultiAZ", valid_595486
  var valid_595487 = query.getOrDefault("ReservedDBInstanceId")
  valid_595487 = validateParameter(valid_595487, JString, required = false,
                                 default = nil)
  if valid_595487 != nil:
    section.add "ReservedDBInstanceId", valid_595487
  var valid_595488 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595488 = validateParameter(valid_595488, JString, required = false,
                                 default = nil)
  if valid_595488 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595488
  var valid_595489 = query.getOrDefault("DBInstanceClass")
  valid_595489 = validateParameter(valid_595489, JString, required = false,
                                 default = nil)
  if valid_595489 != nil:
    section.add "DBInstanceClass", valid_595489
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595490 = query.getOrDefault("Action")
  valid_595490 = validateParameter(valid_595490, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_595490 != nil:
    section.add "Action", valid_595490
  var valid_595491 = query.getOrDefault("Marker")
  valid_595491 = validateParameter(valid_595491, JString, required = false,
                                 default = nil)
  if valid_595491 != nil:
    section.add "Marker", valid_595491
  var valid_595492 = query.getOrDefault("Duration")
  valid_595492 = validateParameter(valid_595492, JString, required = false,
                                 default = nil)
  if valid_595492 != nil:
    section.add "Duration", valid_595492
  var valid_595493 = query.getOrDefault("Version")
  valid_595493 = validateParameter(valid_595493, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595493 != nil:
    section.add "Version", valid_595493
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
  var valid_595494 = header.getOrDefault("X-Amz-Date")
  valid_595494 = validateParameter(valid_595494, JString, required = false,
                                 default = nil)
  if valid_595494 != nil:
    section.add "X-Amz-Date", valid_595494
  var valid_595495 = header.getOrDefault("X-Amz-Security-Token")
  valid_595495 = validateParameter(valid_595495, JString, required = false,
                                 default = nil)
  if valid_595495 != nil:
    section.add "X-Amz-Security-Token", valid_595495
  var valid_595496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595496 = validateParameter(valid_595496, JString, required = false,
                                 default = nil)
  if valid_595496 != nil:
    section.add "X-Amz-Content-Sha256", valid_595496
  var valid_595497 = header.getOrDefault("X-Amz-Algorithm")
  valid_595497 = validateParameter(valid_595497, JString, required = false,
                                 default = nil)
  if valid_595497 != nil:
    section.add "X-Amz-Algorithm", valid_595497
  var valid_595498 = header.getOrDefault("X-Amz-Signature")
  valid_595498 = validateParameter(valid_595498, JString, required = false,
                                 default = nil)
  if valid_595498 != nil:
    section.add "X-Amz-Signature", valid_595498
  var valid_595499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595499 = validateParameter(valid_595499, JString, required = false,
                                 default = nil)
  if valid_595499 != nil:
    section.add "X-Amz-SignedHeaders", valid_595499
  var valid_595500 = header.getOrDefault("X-Amz-Credential")
  valid_595500 = validateParameter(valid_595500, JString, required = false,
                                 default = nil)
  if valid_595500 != nil:
    section.add "X-Amz-Credential", valid_595500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595501: Call_GetDescribeReservedDBInstances_595479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595501.validator(path, query, header, formData, body)
  let scheme = call_595501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595501.url(scheme.get, call_595501.host, call_595501.base,
                         call_595501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595501, url, valid)

proc call*(call_595502: Call_GetDescribeReservedDBInstances_595479;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; Filters: JsonNode = nil; MultiAZ: bool = false;
          ReservedDBInstanceId: string = "";
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstances"; Marker: string = "";
          Duration: string = ""; Version: string = "2014-09-01"): Recallable =
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
  var query_595503 = newJObject()
  add(query_595503, "ProductDescription", newJString(ProductDescription))
  add(query_595503, "MaxRecords", newJInt(MaxRecords))
  add(query_595503, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_595503.add "Filters", Filters
  add(query_595503, "MultiAZ", newJBool(MultiAZ))
  add(query_595503, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_595503, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595503, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595503, "Action", newJString(Action))
  add(query_595503, "Marker", newJString(Marker))
  add(query_595503, "Duration", newJString(Duration))
  add(query_595503, "Version", newJString(Version))
  result = call_595502.call(nil, query_595503, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_595479(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_595480, base: "/",
    url: url_GetDescribeReservedDBInstances_595481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_595554 = ref object of OpenApiRestCall_593421
proc url_PostDescribeReservedDBInstancesOfferings_595556(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_595555(path: JsonNode;
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
  var valid_595557 = query.getOrDefault("Action")
  valid_595557 = validateParameter(valid_595557, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_595557 != nil:
    section.add "Action", valid_595557
  var valid_595558 = query.getOrDefault("Version")
  valid_595558 = validateParameter(valid_595558, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595558 != nil:
    section.add "Version", valid_595558
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
  var valid_595559 = header.getOrDefault("X-Amz-Date")
  valid_595559 = validateParameter(valid_595559, JString, required = false,
                                 default = nil)
  if valid_595559 != nil:
    section.add "X-Amz-Date", valid_595559
  var valid_595560 = header.getOrDefault("X-Amz-Security-Token")
  valid_595560 = validateParameter(valid_595560, JString, required = false,
                                 default = nil)
  if valid_595560 != nil:
    section.add "X-Amz-Security-Token", valid_595560
  var valid_595561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595561 = validateParameter(valid_595561, JString, required = false,
                                 default = nil)
  if valid_595561 != nil:
    section.add "X-Amz-Content-Sha256", valid_595561
  var valid_595562 = header.getOrDefault("X-Amz-Algorithm")
  valid_595562 = validateParameter(valid_595562, JString, required = false,
                                 default = nil)
  if valid_595562 != nil:
    section.add "X-Amz-Algorithm", valid_595562
  var valid_595563 = header.getOrDefault("X-Amz-Signature")
  valid_595563 = validateParameter(valid_595563, JString, required = false,
                                 default = nil)
  if valid_595563 != nil:
    section.add "X-Amz-Signature", valid_595563
  var valid_595564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595564 = validateParameter(valid_595564, JString, required = false,
                                 default = nil)
  if valid_595564 != nil:
    section.add "X-Amz-SignedHeaders", valid_595564
  var valid_595565 = header.getOrDefault("X-Amz-Credential")
  valid_595565 = validateParameter(valid_595565, JString, required = false,
                                 default = nil)
  if valid_595565 != nil:
    section.add "X-Amz-Credential", valid_595565
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
  var valid_595566 = formData.getOrDefault("OfferingType")
  valid_595566 = validateParameter(valid_595566, JString, required = false,
                                 default = nil)
  if valid_595566 != nil:
    section.add "OfferingType", valid_595566
  var valid_595567 = formData.getOrDefault("Marker")
  valid_595567 = validateParameter(valid_595567, JString, required = false,
                                 default = nil)
  if valid_595567 != nil:
    section.add "Marker", valid_595567
  var valid_595568 = formData.getOrDefault("MultiAZ")
  valid_595568 = validateParameter(valid_595568, JBool, required = false, default = nil)
  if valid_595568 != nil:
    section.add "MultiAZ", valid_595568
  var valid_595569 = formData.getOrDefault("Duration")
  valid_595569 = validateParameter(valid_595569, JString, required = false,
                                 default = nil)
  if valid_595569 != nil:
    section.add "Duration", valid_595569
  var valid_595570 = formData.getOrDefault("DBInstanceClass")
  valid_595570 = validateParameter(valid_595570, JString, required = false,
                                 default = nil)
  if valid_595570 != nil:
    section.add "DBInstanceClass", valid_595570
  var valid_595571 = formData.getOrDefault("Filters")
  valid_595571 = validateParameter(valid_595571, JArray, required = false,
                                 default = nil)
  if valid_595571 != nil:
    section.add "Filters", valid_595571
  var valid_595572 = formData.getOrDefault("ProductDescription")
  valid_595572 = validateParameter(valid_595572, JString, required = false,
                                 default = nil)
  if valid_595572 != nil:
    section.add "ProductDescription", valid_595572
  var valid_595573 = formData.getOrDefault("MaxRecords")
  valid_595573 = validateParameter(valid_595573, JInt, required = false, default = nil)
  if valid_595573 != nil:
    section.add "MaxRecords", valid_595573
  var valid_595574 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595574 = validateParameter(valid_595574, JString, required = false,
                                 default = nil)
  if valid_595574 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595574
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595575: Call_PostDescribeReservedDBInstancesOfferings_595554;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595575.validator(path, query, header, formData, body)
  let scheme = call_595575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595575.url(scheme.get, call_595575.host, call_595575.base,
                         call_595575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595575, url, valid)

proc call*(call_595576: Call_PostDescribeReservedDBInstancesOfferings_595554;
          OfferingType: string = ""; Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstancesOfferings";
          Duration: string = ""; DBInstanceClass: string = ""; Filters: JsonNode = nil;
          ProductDescription: string = ""; MaxRecords: int = 0;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2014-09-01"): Recallable =
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
  var query_595577 = newJObject()
  var formData_595578 = newJObject()
  add(formData_595578, "OfferingType", newJString(OfferingType))
  add(formData_595578, "Marker", newJString(Marker))
  add(formData_595578, "MultiAZ", newJBool(MultiAZ))
  add(query_595577, "Action", newJString(Action))
  add(formData_595578, "Duration", newJString(Duration))
  add(formData_595578, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_595578.add "Filters", Filters
  add(formData_595578, "ProductDescription", newJString(ProductDescription))
  add(formData_595578, "MaxRecords", newJInt(MaxRecords))
  add(formData_595578, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595577, "Version", newJString(Version))
  result = call_595576.call(nil, query_595577, nil, formData_595578, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_595554(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_595555,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_595556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_595530 = ref object of OpenApiRestCall_593421
proc url_GetDescribeReservedDBInstancesOfferings_595532(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_595531(path: JsonNode;
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
  var valid_595533 = query.getOrDefault("ProductDescription")
  valid_595533 = validateParameter(valid_595533, JString, required = false,
                                 default = nil)
  if valid_595533 != nil:
    section.add "ProductDescription", valid_595533
  var valid_595534 = query.getOrDefault("MaxRecords")
  valid_595534 = validateParameter(valid_595534, JInt, required = false, default = nil)
  if valid_595534 != nil:
    section.add "MaxRecords", valid_595534
  var valid_595535 = query.getOrDefault("OfferingType")
  valid_595535 = validateParameter(valid_595535, JString, required = false,
                                 default = nil)
  if valid_595535 != nil:
    section.add "OfferingType", valid_595535
  var valid_595536 = query.getOrDefault("Filters")
  valid_595536 = validateParameter(valid_595536, JArray, required = false,
                                 default = nil)
  if valid_595536 != nil:
    section.add "Filters", valid_595536
  var valid_595537 = query.getOrDefault("MultiAZ")
  valid_595537 = validateParameter(valid_595537, JBool, required = false, default = nil)
  if valid_595537 != nil:
    section.add "MultiAZ", valid_595537
  var valid_595538 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595538 = validateParameter(valid_595538, JString, required = false,
                                 default = nil)
  if valid_595538 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595538
  var valid_595539 = query.getOrDefault("DBInstanceClass")
  valid_595539 = validateParameter(valid_595539, JString, required = false,
                                 default = nil)
  if valid_595539 != nil:
    section.add "DBInstanceClass", valid_595539
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595540 = query.getOrDefault("Action")
  valid_595540 = validateParameter(valid_595540, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_595540 != nil:
    section.add "Action", valid_595540
  var valid_595541 = query.getOrDefault("Marker")
  valid_595541 = validateParameter(valid_595541, JString, required = false,
                                 default = nil)
  if valid_595541 != nil:
    section.add "Marker", valid_595541
  var valid_595542 = query.getOrDefault("Duration")
  valid_595542 = validateParameter(valid_595542, JString, required = false,
                                 default = nil)
  if valid_595542 != nil:
    section.add "Duration", valid_595542
  var valid_595543 = query.getOrDefault("Version")
  valid_595543 = validateParameter(valid_595543, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595543 != nil:
    section.add "Version", valid_595543
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
  var valid_595544 = header.getOrDefault("X-Amz-Date")
  valid_595544 = validateParameter(valid_595544, JString, required = false,
                                 default = nil)
  if valid_595544 != nil:
    section.add "X-Amz-Date", valid_595544
  var valid_595545 = header.getOrDefault("X-Amz-Security-Token")
  valid_595545 = validateParameter(valid_595545, JString, required = false,
                                 default = nil)
  if valid_595545 != nil:
    section.add "X-Amz-Security-Token", valid_595545
  var valid_595546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595546 = validateParameter(valid_595546, JString, required = false,
                                 default = nil)
  if valid_595546 != nil:
    section.add "X-Amz-Content-Sha256", valid_595546
  var valid_595547 = header.getOrDefault("X-Amz-Algorithm")
  valid_595547 = validateParameter(valid_595547, JString, required = false,
                                 default = nil)
  if valid_595547 != nil:
    section.add "X-Amz-Algorithm", valid_595547
  var valid_595548 = header.getOrDefault("X-Amz-Signature")
  valid_595548 = validateParameter(valid_595548, JString, required = false,
                                 default = nil)
  if valid_595548 != nil:
    section.add "X-Amz-Signature", valid_595548
  var valid_595549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595549 = validateParameter(valid_595549, JString, required = false,
                                 default = nil)
  if valid_595549 != nil:
    section.add "X-Amz-SignedHeaders", valid_595549
  var valid_595550 = header.getOrDefault("X-Amz-Credential")
  valid_595550 = validateParameter(valid_595550, JString, required = false,
                                 default = nil)
  if valid_595550 != nil:
    section.add "X-Amz-Credential", valid_595550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595551: Call_GetDescribeReservedDBInstancesOfferings_595530;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595551.validator(path, query, header, formData, body)
  let scheme = call_595551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595551.url(scheme.get, call_595551.host, call_595551.base,
                         call_595551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595551, url, valid)

proc call*(call_595552: Call_GetDescribeReservedDBInstancesOfferings_595530;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; Filters: JsonNode = nil; MultiAZ: bool = false;
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          Marker: string = ""; Duration: string = ""; Version: string = "2014-09-01"): Recallable =
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
  var query_595553 = newJObject()
  add(query_595553, "ProductDescription", newJString(ProductDescription))
  add(query_595553, "MaxRecords", newJInt(MaxRecords))
  add(query_595553, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_595553.add "Filters", Filters
  add(query_595553, "MultiAZ", newJBool(MultiAZ))
  add(query_595553, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595553, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595553, "Action", newJString(Action))
  add(query_595553, "Marker", newJString(Marker))
  add(query_595553, "Duration", newJString(Duration))
  add(query_595553, "Version", newJString(Version))
  result = call_595552.call(nil, query_595553, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_595530(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_595531, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_595532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_595598 = ref object of OpenApiRestCall_593421
proc url_PostDownloadDBLogFilePortion_595600(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDownloadDBLogFilePortion_595599(path: JsonNode; query: JsonNode;
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
  var valid_595601 = query.getOrDefault("Action")
  valid_595601 = validateParameter(valid_595601, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_595601 != nil:
    section.add "Action", valid_595601
  var valid_595602 = query.getOrDefault("Version")
  valid_595602 = validateParameter(valid_595602, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595602 != nil:
    section.add "Version", valid_595602
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
  var valid_595603 = header.getOrDefault("X-Amz-Date")
  valid_595603 = validateParameter(valid_595603, JString, required = false,
                                 default = nil)
  if valid_595603 != nil:
    section.add "X-Amz-Date", valid_595603
  var valid_595604 = header.getOrDefault("X-Amz-Security-Token")
  valid_595604 = validateParameter(valid_595604, JString, required = false,
                                 default = nil)
  if valid_595604 != nil:
    section.add "X-Amz-Security-Token", valid_595604
  var valid_595605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595605 = validateParameter(valid_595605, JString, required = false,
                                 default = nil)
  if valid_595605 != nil:
    section.add "X-Amz-Content-Sha256", valid_595605
  var valid_595606 = header.getOrDefault("X-Amz-Algorithm")
  valid_595606 = validateParameter(valid_595606, JString, required = false,
                                 default = nil)
  if valid_595606 != nil:
    section.add "X-Amz-Algorithm", valid_595606
  var valid_595607 = header.getOrDefault("X-Amz-Signature")
  valid_595607 = validateParameter(valid_595607, JString, required = false,
                                 default = nil)
  if valid_595607 != nil:
    section.add "X-Amz-Signature", valid_595607
  var valid_595608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595608 = validateParameter(valid_595608, JString, required = false,
                                 default = nil)
  if valid_595608 != nil:
    section.add "X-Amz-SignedHeaders", valid_595608
  var valid_595609 = header.getOrDefault("X-Amz-Credential")
  valid_595609 = validateParameter(valid_595609, JString, required = false,
                                 default = nil)
  if valid_595609 != nil:
    section.add "X-Amz-Credential", valid_595609
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_595610 = formData.getOrDefault("NumberOfLines")
  valid_595610 = validateParameter(valid_595610, JInt, required = false, default = nil)
  if valid_595610 != nil:
    section.add "NumberOfLines", valid_595610
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595611 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595611 = validateParameter(valid_595611, JString, required = true,
                                 default = nil)
  if valid_595611 != nil:
    section.add "DBInstanceIdentifier", valid_595611
  var valid_595612 = formData.getOrDefault("Marker")
  valid_595612 = validateParameter(valid_595612, JString, required = false,
                                 default = nil)
  if valid_595612 != nil:
    section.add "Marker", valid_595612
  var valid_595613 = formData.getOrDefault("LogFileName")
  valid_595613 = validateParameter(valid_595613, JString, required = true,
                                 default = nil)
  if valid_595613 != nil:
    section.add "LogFileName", valid_595613
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595614: Call_PostDownloadDBLogFilePortion_595598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595614.validator(path, query, header, formData, body)
  let scheme = call_595614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595614.url(scheme.get, call_595614.host, call_595614.base,
                         call_595614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595614, url, valid)

proc call*(call_595615: Call_PostDownloadDBLogFilePortion_595598;
          DBInstanceIdentifier: string; LogFileName: string; NumberOfLines: int = 0;
          Marker: string = ""; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2014-09-01"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   DBInstanceIdentifier: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   LogFileName: string (required)
  ##   Version: string (required)
  var query_595616 = newJObject()
  var formData_595617 = newJObject()
  add(formData_595617, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_595617, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595617, "Marker", newJString(Marker))
  add(query_595616, "Action", newJString(Action))
  add(formData_595617, "LogFileName", newJString(LogFileName))
  add(query_595616, "Version", newJString(Version))
  result = call_595615.call(nil, query_595616, nil, formData_595617, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_595598(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_595599, base: "/",
    url: url_PostDownloadDBLogFilePortion_595600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_595579 = ref object of OpenApiRestCall_593421
proc url_GetDownloadDBLogFilePortion_595581(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDownloadDBLogFilePortion_595580(path: JsonNode; query: JsonNode;
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
  var valid_595582 = query.getOrDefault("NumberOfLines")
  valid_595582 = validateParameter(valid_595582, JInt, required = false, default = nil)
  if valid_595582 != nil:
    section.add "NumberOfLines", valid_595582
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_595583 = query.getOrDefault("LogFileName")
  valid_595583 = validateParameter(valid_595583, JString, required = true,
                                 default = nil)
  if valid_595583 != nil:
    section.add "LogFileName", valid_595583
  var valid_595584 = query.getOrDefault("Action")
  valid_595584 = validateParameter(valid_595584, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_595584 != nil:
    section.add "Action", valid_595584
  var valid_595585 = query.getOrDefault("Marker")
  valid_595585 = validateParameter(valid_595585, JString, required = false,
                                 default = nil)
  if valid_595585 != nil:
    section.add "Marker", valid_595585
  var valid_595586 = query.getOrDefault("Version")
  valid_595586 = validateParameter(valid_595586, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595586 != nil:
    section.add "Version", valid_595586
  var valid_595587 = query.getOrDefault("DBInstanceIdentifier")
  valid_595587 = validateParameter(valid_595587, JString, required = true,
                                 default = nil)
  if valid_595587 != nil:
    section.add "DBInstanceIdentifier", valid_595587
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
  var valid_595588 = header.getOrDefault("X-Amz-Date")
  valid_595588 = validateParameter(valid_595588, JString, required = false,
                                 default = nil)
  if valid_595588 != nil:
    section.add "X-Amz-Date", valid_595588
  var valid_595589 = header.getOrDefault("X-Amz-Security-Token")
  valid_595589 = validateParameter(valid_595589, JString, required = false,
                                 default = nil)
  if valid_595589 != nil:
    section.add "X-Amz-Security-Token", valid_595589
  var valid_595590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595590 = validateParameter(valid_595590, JString, required = false,
                                 default = nil)
  if valid_595590 != nil:
    section.add "X-Amz-Content-Sha256", valid_595590
  var valid_595591 = header.getOrDefault("X-Amz-Algorithm")
  valid_595591 = validateParameter(valid_595591, JString, required = false,
                                 default = nil)
  if valid_595591 != nil:
    section.add "X-Amz-Algorithm", valid_595591
  var valid_595592 = header.getOrDefault("X-Amz-Signature")
  valid_595592 = validateParameter(valid_595592, JString, required = false,
                                 default = nil)
  if valid_595592 != nil:
    section.add "X-Amz-Signature", valid_595592
  var valid_595593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595593 = validateParameter(valid_595593, JString, required = false,
                                 default = nil)
  if valid_595593 != nil:
    section.add "X-Amz-SignedHeaders", valid_595593
  var valid_595594 = header.getOrDefault("X-Amz-Credential")
  valid_595594 = validateParameter(valid_595594, JString, required = false,
                                 default = nil)
  if valid_595594 != nil:
    section.add "X-Amz-Credential", valid_595594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595595: Call_GetDownloadDBLogFilePortion_595579; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595595.validator(path, query, header, formData, body)
  let scheme = call_595595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595595.url(scheme.get, call_595595.host, call_595595.base,
                         call_595595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595595, url, valid)

proc call*(call_595596: Call_GetDownloadDBLogFilePortion_595579;
          LogFileName: string; DBInstanceIdentifier: string; NumberOfLines: int = 0;
          Action: string = "DownloadDBLogFilePortion"; Marker: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   LogFileName: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_595597 = newJObject()
  add(query_595597, "NumberOfLines", newJInt(NumberOfLines))
  add(query_595597, "LogFileName", newJString(LogFileName))
  add(query_595597, "Action", newJString(Action))
  add(query_595597, "Marker", newJString(Marker))
  add(query_595597, "Version", newJString(Version))
  add(query_595597, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_595596.call(nil, query_595597, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_595579(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_595580, base: "/",
    url: url_GetDownloadDBLogFilePortion_595581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_595635 = ref object of OpenApiRestCall_593421
proc url_PostListTagsForResource_595637(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_595636(path: JsonNode; query: JsonNode;
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
  var valid_595638 = query.getOrDefault("Action")
  valid_595638 = validateParameter(valid_595638, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_595638 != nil:
    section.add "Action", valid_595638
  var valid_595639 = query.getOrDefault("Version")
  valid_595639 = validateParameter(valid_595639, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595639 != nil:
    section.add "Version", valid_595639
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
  var valid_595640 = header.getOrDefault("X-Amz-Date")
  valid_595640 = validateParameter(valid_595640, JString, required = false,
                                 default = nil)
  if valid_595640 != nil:
    section.add "X-Amz-Date", valid_595640
  var valid_595641 = header.getOrDefault("X-Amz-Security-Token")
  valid_595641 = validateParameter(valid_595641, JString, required = false,
                                 default = nil)
  if valid_595641 != nil:
    section.add "X-Amz-Security-Token", valid_595641
  var valid_595642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595642 = validateParameter(valid_595642, JString, required = false,
                                 default = nil)
  if valid_595642 != nil:
    section.add "X-Amz-Content-Sha256", valid_595642
  var valid_595643 = header.getOrDefault("X-Amz-Algorithm")
  valid_595643 = validateParameter(valid_595643, JString, required = false,
                                 default = nil)
  if valid_595643 != nil:
    section.add "X-Amz-Algorithm", valid_595643
  var valid_595644 = header.getOrDefault("X-Amz-Signature")
  valid_595644 = validateParameter(valid_595644, JString, required = false,
                                 default = nil)
  if valid_595644 != nil:
    section.add "X-Amz-Signature", valid_595644
  var valid_595645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595645 = validateParameter(valid_595645, JString, required = false,
                                 default = nil)
  if valid_595645 != nil:
    section.add "X-Amz-SignedHeaders", valid_595645
  var valid_595646 = header.getOrDefault("X-Amz-Credential")
  valid_595646 = validateParameter(valid_595646, JString, required = false,
                                 default = nil)
  if valid_595646 != nil:
    section.add "X-Amz-Credential", valid_595646
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_595647 = formData.getOrDefault("Filters")
  valid_595647 = validateParameter(valid_595647, JArray, required = false,
                                 default = nil)
  if valid_595647 != nil:
    section.add "Filters", valid_595647
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_595648 = formData.getOrDefault("ResourceName")
  valid_595648 = validateParameter(valid_595648, JString, required = true,
                                 default = nil)
  if valid_595648 != nil:
    section.add "ResourceName", valid_595648
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595649: Call_PostListTagsForResource_595635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595649.validator(path, query, header, formData, body)
  let scheme = call_595649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595649.url(scheme.get, call_595649.host, call_595649.base,
                         call_595649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595649, url, valid)

proc call*(call_595650: Call_PostListTagsForResource_595635; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_595651 = newJObject()
  var formData_595652 = newJObject()
  add(query_595651, "Action", newJString(Action))
  if Filters != nil:
    formData_595652.add "Filters", Filters
  add(formData_595652, "ResourceName", newJString(ResourceName))
  add(query_595651, "Version", newJString(Version))
  result = call_595650.call(nil, query_595651, nil, formData_595652, nil)

var postListTagsForResource* = Call_PostListTagsForResource_595635(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_595636, base: "/",
    url: url_PostListTagsForResource_595637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_595618 = ref object of OpenApiRestCall_593421
proc url_GetListTagsForResource_595620(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_595619(path: JsonNode; query: JsonNode;
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
  var valid_595621 = query.getOrDefault("Filters")
  valid_595621 = validateParameter(valid_595621, JArray, required = false,
                                 default = nil)
  if valid_595621 != nil:
    section.add "Filters", valid_595621
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_595622 = query.getOrDefault("ResourceName")
  valid_595622 = validateParameter(valid_595622, JString, required = true,
                                 default = nil)
  if valid_595622 != nil:
    section.add "ResourceName", valid_595622
  var valid_595623 = query.getOrDefault("Action")
  valid_595623 = validateParameter(valid_595623, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_595623 != nil:
    section.add "Action", valid_595623
  var valid_595624 = query.getOrDefault("Version")
  valid_595624 = validateParameter(valid_595624, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595624 != nil:
    section.add "Version", valid_595624
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
  var valid_595625 = header.getOrDefault("X-Amz-Date")
  valid_595625 = validateParameter(valid_595625, JString, required = false,
                                 default = nil)
  if valid_595625 != nil:
    section.add "X-Amz-Date", valid_595625
  var valid_595626 = header.getOrDefault("X-Amz-Security-Token")
  valid_595626 = validateParameter(valid_595626, JString, required = false,
                                 default = nil)
  if valid_595626 != nil:
    section.add "X-Amz-Security-Token", valid_595626
  var valid_595627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595627 = validateParameter(valid_595627, JString, required = false,
                                 default = nil)
  if valid_595627 != nil:
    section.add "X-Amz-Content-Sha256", valid_595627
  var valid_595628 = header.getOrDefault("X-Amz-Algorithm")
  valid_595628 = validateParameter(valid_595628, JString, required = false,
                                 default = nil)
  if valid_595628 != nil:
    section.add "X-Amz-Algorithm", valid_595628
  var valid_595629 = header.getOrDefault("X-Amz-Signature")
  valid_595629 = validateParameter(valid_595629, JString, required = false,
                                 default = nil)
  if valid_595629 != nil:
    section.add "X-Amz-Signature", valid_595629
  var valid_595630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595630 = validateParameter(valid_595630, JString, required = false,
                                 default = nil)
  if valid_595630 != nil:
    section.add "X-Amz-SignedHeaders", valid_595630
  var valid_595631 = header.getOrDefault("X-Amz-Credential")
  valid_595631 = validateParameter(valid_595631, JString, required = false,
                                 default = nil)
  if valid_595631 != nil:
    section.add "X-Amz-Credential", valid_595631
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595632: Call_GetListTagsForResource_595618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595632.validator(path, query, header, formData, body)
  let scheme = call_595632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595632.url(scheme.get, call_595632.host, call_595632.base,
                         call_595632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595632, url, valid)

proc call*(call_595633: Call_GetListTagsForResource_595618; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2014-09-01"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595634 = newJObject()
  if Filters != nil:
    query_595634.add "Filters", Filters
  add(query_595634, "ResourceName", newJString(ResourceName))
  add(query_595634, "Action", newJString(Action))
  add(query_595634, "Version", newJString(Version))
  result = call_595633.call(nil, query_595634, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_595618(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_595619, base: "/",
    url: url_GetListTagsForResource_595620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_595689 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBInstance_595691(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_595690(path: JsonNode; query: JsonNode;
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
  var valid_595692 = query.getOrDefault("Action")
  valid_595692 = validateParameter(valid_595692, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_595692 != nil:
    section.add "Action", valid_595692
  var valid_595693 = query.getOrDefault("Version")
  valid_595693 = validateParameter(valid_595693, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595693 != nil:
    section.add "Version", valid_595693
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
  var valid_595694 = header.getOrDefault("X-Amz-Date")
  valid_595694 = validateParameter(valid_595694, JString, required = false,
                                 default = nil)
  if valid_595694 != nil:
    section.add "X-Amz-Date", valid_595694
  var valid_595695 = header.getOrDefault("X-Amz-Security-Token")
  valid_595695 = validateParameter(valid_595695, JString, required = false,
                                 default = nil)
  if valid_595695 != nil:
    section.add "X-Amz-Security-Token", valid_595695
  var valid_595696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595696 = validateParameter(valid_595696, JString, required = false,
                                 default = nil)
  if valid_595696 != nil:
    section.add "X-Amz-Content-Sha256", valid_595696
  var valid_595697 = header.getOrDefault("X-Amz-Algorithm")
  valid_595697 = validateParameter(valid_595697, JString, required = false,
                                 default = nil)
  if valid_595697 != nil:
    section.add "X-Amz-Algorithm", valid_595697
  var valid_595698 = header.getOrDefault("X-Amz-Signature")
  valid_595698 = validateParameter(valid_595698, JString, required = false,
                                 default = nil)
  if valid_595698 != nil:
    section.add "X-Amz-Signature", valid_595698
  var valid_595699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595699 = validateParameter(valid_595699, JString, required = false,
                                 default = nil)
  if valid_595699 != nil:
    section.add "X-Amz-SignedHeaders", valid_595699
  var valid_595700 = header.getOrDefault("X-Amz-Credential")
  valid_595700 = validateParameter(valid_595700, JString, required = false,
                                 default = nil)
  if valid_595700 != nil:
    section.add "X-Amz-Credential", valid_595700
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
  ##   TdeCredentialArn: JString
  ##   TdeCredentialPassword: JString
  ##   MultiAZ: JBool
  ##   AllocatedStorage: JInt
  ##   StorageType: JString
  ##   DBInstanceClass: JString
  ##   PreferredBackupWindow: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   EngineVersion: JString
  ##   AllowMajorVersionUpgrade: JBool
  section = newJObject()
  var valid_595701 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_595701 = validateParameter(valid_595701, JString, required = false,
                                 default = nil)
  if valid_595701 != nil:
    section.add "PreferredMaintenanceWindow", valid_595701
  var valid_595702 = formData.getOrDefault("DBSecurityGroups")
  valid_595702 = validateParameter(valid_595702, JArray, required = false,
                                 default = nil)
  if valid_595702 != nil:
    section.add "DBSecurityGroups", valid_595702
  var valid_595703 = formData.getOrDefault("ApplyImmediately")
  valid_595703 = validateParameter(valid_595703, JBool, required = false, default = nil)
  if valid_595703 != nil:
    section.add "ApplyImmediately", valid_595703
  var valid_595704 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_595704 = validateParameter(valid_595704, JArray, required = false,
                                 default = nil)
  if valid_595704 != nil:
    section.add "VpcSecurityGroupIds", valid_595704
  var valid_595705 = formData.getOrDefault("Iops")
  valid_595705 = validateParameter(valid_595705, JInt, required = false, default = nil)
  if valid_595705 != nil:
    section.add "Iops", valid_595705
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595706 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595706 = validateParameter(valid_595706, JString, required = true,
                                 default = nil)
  if valid_595706 != nil:
    section.add "DBInstanceIdentifier", valid_595706
  var valid_595707 = formData.getOrDefault("BackupRetentionPeriod")
  valid_595707 = validateParameter(valid_595707, JInt, required = false, default = nil)
  if valid_595707 != nil:
    section.add "BackupRetentionPeriod", valid_595707
  var valid_595708 = formData.getOrDefault("DBParameterGroupName")
  valid_595708 = validateParameter(valid_595708, JString, required = false,
                                 default = nil)
  if valid_595708 != nil:
    section.add "DBParameterGroupName", valid_595708
  var valid_595709 = formData.getOrDefault("OptionGroupName")
  valid_595709 = validateParameter(valid_595709, JString, required = false,
                                 default = nil)
  if valid_595709 != nil:
    section.add "OptionGroupName", valid_595709
  var valid_595710 = formData.getOrDefault("MasterUserPassword")
  valid_595710 = validateParameter(valid_595710, JString, required = false,
                                 default = nil)
  if valid_595710 != nil:
    section.add "MasterUserPassword", valid_595710
  var valid_595711 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_595711 = validateParameter(valid_595711, JString, required = false,
                                 default = nil)
  if valid_595711 != nil:
    section.add "NewDBInstanceIdentifier", valid_595711
  var valid_595712 = formData.getOrDefault("TdeCredentialArn")
  valid_595712 = validateParameter(valid_595712, JString, required = false,
                                 default = nil)
  if valid_595712 != nil:
    section.add "TdeCredentialArn", valid_595712
  var valid_595713 = formData.getOrDefault("TdeCredentialPassword")
  valid_595713 = validateParameter(valid_595713, JString, required = false,
                                 default = nil)
  if valid_595713 != nil:
    section.add "TdeCredentialPassword", valid_595713
  var valid_595714 = formData.getOrDefault("MultiAZ")
  valid_595714 = validateParameter(valid_595714, JBool, required = false, default = nil)
  if valid_595714 != nil:
    section.add "MultiAZ", valid_595714
  var valid_595715 = formData.getOrDefault("AllocatedStorage")
  valid_595715 = validateParameter(valid_595715, JInt, required = false, default = nil)
  if valid_595715 != nil:
    section.add "AllocatedStorage", valid_595715
  var valid_595716 = formData.getOrDefault("StorageType")
  valid_595716 = validateParameter(valid_595716, JString, required = false,
                                 default = nil)
  if valid_595716 != nil:
    section.add "StorageType", valid_595716
  var valid_595717 = formData.getOrDefault("DBInstanceClass")
  valid_595717 = validateParameter(valid_595717, JString, required = false,
                                 default = nil)
  if valid_595717 != nil:
    section.add "DBInstanceClass", valid_595717
  var valid_595718 = formData.getOrDefault("PreferredBackupWindow")
  valid_595718 = validateParameter(valid_595718, JString, required = false,
                                 default = nil)
  if valid_595718 != nil:
    section.add "PreferredBackupWindow", valid_595718
  var valid_595719 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_595719 = validateParameter(valid_595719, JBool, required = false, default = nil)
  if valid_595719 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595719
  var valid_595720 = formData.getOrDefault("EngineVersion")
  valid_595720 = validateParameter(valid_595720, JString, required = false,
                                 default = nil)
  if valid_595720 != nil:
    section.add "EngineVersion", valid_595720
  var valid_595721 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_595721 = validateParameter(valid_595721, JBool, required = false, default = nil)
  if valid_595721 != nil:
    section.add "AllowMajorVersionUpgrade", valid_595721
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595722: Call_PostModifyDBInstance_595689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595722.validator(path, query, header, formData, body)
  let scheme = call_595722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595722.url(scheme.get, call_595722.host, call_595722.base,
                         call_595722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595722, url, valid)

proc call*(call_595723: Call_PostModifyDBInstance_595689;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBSecurityGroups: JsonNode = nil; ApplyImmediately: bool = false;
          VpcSecurityGroupIds: JsonNode = nil; Iops: int = 0;
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          OptionGroupName: string = ""; MasterUserPassword: string = "";
          NewDBInstanceIdentifier: string = ""; TdeCredentialArn: string = "";
          TdeCredentialPassword: string = ""; MultiAZ: bool = false;
          Action: string = "ModifyDBInstance"; AllocatedStorage: int = 0;
          StorageType: string = ""; DBInstanceClass: string = "";
          PreferredBackupWindow: string = ""; AutoMinorVersionUpgrade: bool = false;
          EngineVersion: string = ""; Version: string = "2014-09-01";
          AllowMajorVersionUpgrade: bool = false): Recallable =
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
  ##   TdeCredentialArn: string
  ##   TdeCredentialPassword: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   AllocatedStorage: int
  ##   StorageType: string
  ##   DBInstanceClass: string
  ##   PreferredBackupWindow: string
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   Version: string (required)
  ##   AllowMajorVersionUpgrade: bool
  var query_595724 = newJObject()
  var formData_595725 = newJObject()
  add(formData_595725, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_595725.add "DBSecurityGroups", DBSecurityGroups
  add(formData_595725, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_595725.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_595725, "Iops", newJInt(Iops))
  add(formData_595725, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595725, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_595725, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_595725, "OptionGroupName", newJString(OptionGroupName))
  add(formData_595725, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_595725, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_595725, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_595725, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_595725, "MultiAZ", newJBool(MultiAZ))
  add(query_595724, "Action", newJString(Action))
  add(formData_595725, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_595725, "StorageType", newJString(StorageType))
  add(formData_595725, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595725, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_595725, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_595725, "EngineVersion", newJString(EngineVersion))
  add(query_595724, "Version", newJString(Version))
  add(formData_595725, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_595723.call(nil, query_595724, nil, formData_595725, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_595689(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_595690, base: "/",
    url: url_PostModifyDBInstance_595691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_595653 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBInstance_595655(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_595654(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PreferredMaintenanceWindow: JString
  ##   AllocatedStorage: JInt
  ##   StorageType: JString
  ##   OptionGroupName: JString
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: JString
  ##   Iops: JInt
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: JBool
  ##   TdeCredentialPassword: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBParameterGroupName: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   AllowMajorVersionUpgrade: JBool
  ##   NewDBInstanceIdentifier: JString
  ##   TdeCredentialArn: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   EngineVersion: JString
  ##   PreferredBackupWindow: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   ApplyImmediately: JBool
  section = newJObject()
  var valid_595656 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_595656 = validateParameter(valid_595656, JString, required = false,
                                 default = nil)
  if valid_595656 != nil:
    section.add "PreferredMaintenanceWindow", valid_595656
  var valid_595657 = query.getOrDefault("AllocatedStorage")
  valid_595657 = validateParameter(valid_595657, JInt, required = false, default = nil)
  if valid_595657 != nil:
    section.add "AllocatedStorage", valid_595657
  var valid_595658 = query.getOrDefault("StorageType")
  valid_595658 = validateParameter(valid_595658, JString, required = false,
                                 default = nil)
  if valid_595658 != nil:
    section.add "StorageType", valid_595658
  var valid_595659 = query.getOrDefault("OptionGroupName")
  valid_595659 = validateParameter(valid_595659, JString, required = false,
                                 default = nil)
  if valid_595659 != nil:
    section.add "OptionGroupName", valid_595659
  var valid_595660 = query.getOrDefault("DBSecurityGroups")
  valid_595660 = validateParameter(valid_595660, JArray, required = false,
                                 default = nil)
  if valid_595660 != nil:
    section.add "DBSecurityGroups", valid_595660
  var valid_595661 = query.getOrDefault("MasterUserPassword")
  valid_595661 = validateParameter(valid_595661, JString, required = false,
                                 default = nil)
  if valid_595661 != nil:
    section.add "MasterUserPassword", valid_595661
  var valid_595662 = query.getOrDefault("Iops")
  valid_595662 = validateParameter(valid_595662, JInt, required = false, default = nil)
  if valid_595662 != nil:
    section.add "Iops", valid_595662
  var valid_595663 = query.getOrDefault("VpcSecurityGroupIds")
  valid_595663 = validateParameter(valid_595663, JArray, required = false,
                                 default = nil)
  if valid_595663 != nil:
    section.add "VpcSecurityGroupIds", valid_595663
  var valid_595664 = query.getOrDefault("MultiAZ")
  valid_595664 = validateParameter(valid_595664, JBool, required = false, default = nil)
  if valid_595664 != nil:
    section.add "MultiAZ", valid_595664
  var valid_595665 = query.getOrDefault("TdeCredentialPassword")
  valid_595665 = validateParameter(valid_595665, JString, required = false,
                                 default = nil)
  if valid_595665 != nil:
    section.add "TdeCredentialPassword", valid_595665
  var valid_595666 = query.getOrDefault("BackupRetentionPeriod")
  valid_595666 = validateParameter(valid_595666, JInt, required = false, default = nil)
  if valid_595666 != nil:
    section.add "BackupRetentionPeriod", valid_595666
  var valid_595667 = query.getOrDefault("DBParameterGroupName")
  valid_595667 = validateParameter(valid_595667, JString, required = false,
                                 default = nil)
  if valid_595667 != nil:
    section.add "DBParameterGroupName", valid_595667
  var valid_595668 = query.getOrDefault("DBInstanceClass")
  valid_595668 = validateParameter(valid_595668, JString, required = false,
                                 default = nil)
  if valid_595668 != nil:
    section.add "DBInstanceClass", valid_595668
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595669 = query.getOrDefault("Action")
  valid_595669 = validateParameter(valid_595669, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_595669 != nil:
    section.add "Action", valid_595669
  var valid_595670 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_595670 = validateParameter(valid_595670, JBool, required = false, default = nil)
  if valid_595670 != nil:
    section.add "AllowMajorVersionUpgrade", valid_595670
  var valid_595671 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_595671 = validateParameter(valid_595671, JString, required = false,
                                 default = nil)
  if valid_595671 != nil:
    section.add "NewDBInstanceIdentifier", valid_595671
  var valid_595672 = query.getOrDefault("TdeCredentialArn")
  valid_595672 = validateParameter(valid_595672, JString, required = false,
                                 default = nil)
  if valid_595672 != nil:
    section.add "TdeCredentialArn", valid_595672
  var valid_595673 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_595673 = validateParameter(valid_595673, JBool, required = false, default = nil)
  if valid_595673 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595673
  var valid_595674 = query.getOrDefault("EngineVersion")
  valid_595674 = validateParameter(valid_595674, JString, required = false,
                                 default = nil)
  if valid_595674 != nil:
    section.add "EngineVersion", valid_595674
  var valid_595675 = query.getOrDefault("PreferredBackupWindow")
  valid_595675 = validateParameter(valid_595675, JString, required = false,
                                 default = nil)
  if valid_595675 != nil:
    section.add "PreferredBackupWindow", valid_595675
  var valid_595676 = query.getOrDefault("Version")
  valid_595676 = validateParameter(valid_595676, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595676 != nil:
    section.add "Version", valid_595676
  var valid_595677 = query.getOrDefault("DBInstanceIdentifier")
  valid_595677 = validateParameter(valid_595677, JString, required = true,
                                 default = nil)
  if valid_595677 != nil:
    section.add "DBInstanceIdentifier", valid_595677
  var valid_595678 = query.getOrDefault("ApplyImmediately")
  valid_595678 = validateParameter(valid_595678, JBool, required = false, default = nil)
  if valid_595678 != nil:
    section.add "ApplyImmediately", valid_595678
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
  var valid_595679 = header.getOrDefault("X-Amz-Date")
  valid_595679 = validateParameter(valid_595679, JString, required = false,
                                 default = nil)
  if valid_595679 != nil:
    section.add "X-Amz-Date", valid_595679
  var valid_595680 = header.getOrDefault("X-Amz-Security-Token")
  valid_595680 = validateParameter(valid_595680, JString, required = false,
                                 default = nil)
  if valid_595680 != nil:
    section.add "X-Amz-Security-Token", valid_595680
  var valid_595681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595681 = validateParameter(valid_595681, JString, required = false,
                                 default = nil)
  if valid_595681 != nil:
    section.add "X-Amz-Content-Sha256", valid_595681
  var valid_595682 = header.getOrDefault("X-Amz-Algorithm")
  valid_595682 = validateParameter(valid_595682, JString, required = false,
                                 default = nil)
  if valid_595682 != nil:
    section.add "X-Amz-Algorithm", valid_595682
  var valid_595683 = header.getOrDefault("X-Amz-Signature")
  valid_595683 = validateParameter(valid_595683, JString, required = false,
                                 default = nil)
  if valid_595683 != nil:
    section.add "X-Amz-Signature", valid_595683
  var valid_595684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595684 = validateParameter(valid_595684, JString, required = false,
                                 default = nil)
  if valid_595684 != nil:
    section.add "X-Amz-SignedHeaders", valid_595684
  var valid_595685 = header.getOrDefault("X-Amz-Credential")
  valid_595685 = validateParameter(valid_595685, JString, required = false,
                                 default = nil)
  if valid_595685 != nil:
    section.add "X-Amz-Credential", valid_595685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595686: Call_GetModifyDBInstance_595653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595686.validator(path, query, header, formData, body)
  let scheme = call_595686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595686.url(scheme.get, call_595686.host, call_595686.base,
                         call_595686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595686, url, valid)

proc call*(call_595687: Call_GetModifyDBInstance_595653;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          AllocatedStorage: int = 0; StorageType: string = "";
          OptionGroupName: string = ""; DBSecurityGroups: JsonNode = nil;
          MasterUserPassword: string = ""; Iops: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; MultiAZ: bool = false;
          TdeCredentialPassword: string = ""; BackupRetentionPeriod: int = 0;
          DBParameterGroupName: string = ""; DBInstanceClass: string = "";
          Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false;
          NewDBInstanceIdentifier: string = ""; TdeCredentialArn: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          PreferredBackupWindow: string = ""; Version: string = "2014-09-01";
          ApplyImmediately: bool = false): Recallable =
  ## getModifyDBInstance
  ##   PreferredMaintenanceWindow: string
  ##   AllocatedStorage: int
  ##   StorageType: string
  ##   OptionGroupName: string
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: string
  ##   Iops: int
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: bool
  ##   TdeCredentialPassword: string
  ##   BackupRetentionPeriod: int
  ##   DBParameterGroupName: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   AllowMajorVersionUpgrade: bool
  ##   NewDBInstanceIdentifier: string
  ##   TdeCredentialArn: string
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   ApplyImmediately: bool
  var query_595688 = newJObject()
  add(query_595688, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_595688, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_595688, "StorageType", newJString(StorageType))
  add(query_595688, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_595688.add "DBSecurityGroups", DBSecurityGroups
  add(query_595688, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_595688, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_595688.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_595688, "MultiAZ", newJBool(MultiAZ))
  add(query_595688, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_595688, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_595688, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_595688, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595688, "Action", newJString(Action))
  add(query_595688, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_595688, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_595688, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_595688, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_595688, "EngineVersion", newJString(EngineVersion))
  add(query_595688, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_595688, "Version", newJString(Version))
  add(query_595688, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595688, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_595687.call(nil, query_595688, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_595653(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_595654, base: "/",
    url: url_GetModifyDBInstance_595655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_595743 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBParameterGroup_595745(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_595744(path: JsonNode; query: JsonNode;
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
  var valid_595746 = query.getOrDefault("Action")
  valid_595746 = validateParameter(valid_595746, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_595746 != nil:
    section.add "Action", valid_595746
  var valid_595747 = query.getOrDefault("Version")
  valid_595747 = validateParameter(valid_595747, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595747 != nil:
    section.add "Version", valid_595747
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
  var valid_595748 = header.getOrDefault("X-Amz-Date")
  valid_595748 = validateParameter(valid_595748, JString, required = false,
                                 default = nil)
  if valid_595748 != nil:
    section.add "X-Amz-Date", valid_595748
  var valid_595749 = header.getOrDefault("X-Amz-Security-Token")
  valid_595749 = validateParameter(valid_595749, JString, required = false,
                                 default = nil)
  if valid_595749 != nil:
    section.add "X-Amz-Security-Token", valid_595749
  var valid_595750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595750 = validateParameter(valid_595750, JString, required = false,
                                 default = nil)
  if valid_595750 != nil:
    section.add "X-Amz-Content-Sha256", valid_595750
  var valid_595751 = header.getOrDefault("X-Amz-Algorithm")
  valid_595751 = validateParameter(valid_595751, JString, required = false,
                                 default = nil)
  if valid_595751 != nil:
    section.add "X-Amz-Algorithm", valid_595751
  var valid_595752 = header.getOrDefault("X-Amz-Signature")
  valid_595752 = validateParameter(valid_595752, JString, required = false,
                                 default = nil)
  if valid_595752 != nil:
    section.add "X-Amz-Signature", valid_595752
  var valid_595753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595753 = validateParameter(valid_595753, JString, required = false,
                                 default = nil)
  if valid_595753 != nil:
    section.add "X-Amz-SignedHeaders", valid_595753
  var valid_595754 = header.getOrDefault("X-Amz-Credential")
  valid_595754 = validateParameter(valid_595754, JString, required = false,
                                 default = nil)
  if valid_595754 != nil:
    section.add "X-Amz-Credential", valid_595754
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_595755 = formData.getOrDefault("DBParameterGroupName")
  valid_595755 = validateParameter(valid_595755, JString, required = true,
                                 default = nil)
  if valid_595755 != nil:
    section.add "DBParameterGroupName", valid_595755
  var valid_595756 = formData.getOrDefault("Parameters")
  valid_595756 = validateParameter(valid_595756, JArray, required = true, default = nil)
  if valid_595756 != nil:
    section.add "Parameters", valid_595756
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595757: Call_PostModifyDBParameterGroup_595743; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595757.validator(path, query, header, formData, body)
  let scheme = call_595757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595757.url(scheme.get, call_595757.host, call_595757.base,
                         call_595757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595757, url, valid)

proc call*(call_595758: Call_PostModifyDBParameterGroup_595743;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595759 = newJObject()
  var formData_595760 = newJObject()
  add(formData_595760, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_595760.add "Parameters", Parameters
  add(query_595759, "Action", newJString(Action))
  add(query_595759, "Version", newJString(Version))
  result = call_595758.call(nil, query_595759, nil, formData_595760, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_595743(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_595744, base: "/",
    url: url_PostModifyDBParameterGroup_595745,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_595726 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBParameterGroup_595728(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_595727(path: JsonNode; query: JsonNode;
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
  var valid_595729 = query.getOrDefault("DBParameterGroupName")
  valid_595729 = validateParameter(valid_595729, JString, required = true,
                                 default = nil)
  if valid_595729 != nil:
    section.add "DBParameterGroupName", valid_595729
  var valid_595730 = query.getOrDefault("Parameters")
  valid_595730 = validateParameter(valid_595730, JArray, required = true, default = nil)
  if valid_595730 != nil:
    section.add "Parameters", valid_595730
  var valid_595731 = query.getOrDefault("Action")
  valid_595731 = validateParameter(valid_595731, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_595731 != nil:
    section.add "Action", valid_595731
  var valid_595732 = query.getOrDefault("Version")
  valid_595732 = validateParameter(valid_595732, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595732 != nil:
    section.add "Version", valid_595732
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
  var valid_595733 = header.getOrDefault("X-Amz-Date")
  valid_595733 = validateParameter(valid_595733, JString, required = false,
                                 default = nil)
  if valid_595733 != nil:
    section.add "X-Amz-Date", valid_595733
  var valid_595734 = header.getOrDefault("X-Amz-Security-Token")
  valid_595734 = validateParameter(valid_595734, JString, required = false,
                                 default = nil)
  if valid_595734 != nil:
    section.add "X-Amz-Security-Token", valid_595734
  var valid_595735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595735 = validateParameter(valid_595735, JString, required = false,
                                 default = nil)
  if valid_595735 != nil:
    section.add "X-Amz-Content-Sha256", valid_595735
  var valid_595736 = header.getOrDefault("X-Amz-Algorithm")
  valid_595736 = validateParameter(valid_595736, JString, required = false,
                                 default = nil)
  if valid_595736 != nil:
    section.add "X-Amz-Algorithm", valid_595736
  var valid_595737 = header.getOrDefault("X-Amz-Signature")
  valid_595737 = validateParameter(valid_595737, JString, required = false,
                                 default = nil)
  if valid_595737 != nil:
    section.add "X-Amz-Signature", valid_595737
  var valid_595738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595738 = validateParameter(valid_595738, JString, required = false,
                                 default = nil)
  if valid_595738 != nil:
    section.add "X-Amz-SignedHeaders", valid_595738
  var valid_595739 = header.getOrDefault("X-Amz-Credential")
  valid_595739 = validateParameter(valid_595739, JString, required = false,
                                 default = nil)
  if valid_595739 != nil:
    section.add "X-Amz-Credential", valid_595739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595740: Call_GetModifyDBParameterGroup_595726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595740.validator(path, query, header, formData, body)
  let scheme = call_595740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595740.url(scheme.get, call_595740.host, call_595740.base,
                         call_595740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595740, url, valid)

proc call*(call_595741: Call_GetModifyDBParameterGroup_595726;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595742 = newJObject()
  add(query_595742, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_595742.add "Parameters", Parameters
  add(query_595742, "Action", newJString(Action))
  add(query_595742, "Version", newJString(Version))
  result = call_595741.call(nil, query_595742, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_595726(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_595727, base: "/",
    url: url_GetModifyDBParameterGroup_595728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_595779 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBSubnetGroup_595781(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_595780(path: JsonNode; query: JsonNode;
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
  var valid_595782 = query.getOrDefault("Action")
  valid_595782 = validateParameter(valid_595782, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_595782 != nil:
    section.add "Action", valid_595782
  var valid_595783 = query.getOrDefault("Version")
  valid_595783 = validateParameter(valid_595783, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595783 != nil:
    section.add "Version", valid_595783
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
  var valid_595784 = header.getOrDefault("X-Amz-Date")
  valid_595784 = validateParameter(valid_595784, JString, required = false,
                                 default = nil)
  if valid_595784 != nil:
    section.add "X-Amz-Date", valid_595784
  var valid_595785 = header.getOrDefault("X-Amz-Security-Token")
  valid_595785 = validateParameter(valid_595785, JString, required = false,
                                 default = nil)
  if valid_595785 != nil:
    section.add "X-Amz-Security-Token", valid_595785
  var valid_595786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595786 = validateParameter(valid_595786, JString, required = false,
                                 default = nil)
  if valid_595786 != nil:
    section.add "X-Amz-Content-Sha256", valid_595786
  var valid_595787 = header.getOrDefault("X-Amz-Algorithm")
  valid_595787 = validateParameter(valid_595787, JString, required = false,
                                 default = nil)
  if valid_595787 != nil:
    section.add "X-Amz-Algorithm", valid_595787
  var valid_595788 = header.getOrDefault("X-Amz-Signature")
  valid_595788 = validateParameter(valid_595788, JString, required = false,
                                 default = nil)
  if valid_595788 != nil:
    section.add "X-Amz-Signature", valid_595788
  var valid_595789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595789 = validateParameter(valid_595789, JString, required = false,
                                 default = nil)
  if valid_595789 != nil:
    section.add "X-Amz-SignedHeaders", valid_595789
  var valid_595790 = header.getOrDefault("X-Amz-Credential")
  valid_595790 = validateParameter(valid_595790, JString, required = false,
                                 default = nil)
  if valid_595790 != nil:
    section.add "X-Amz-Credential", valid_595790
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_595791 = formData.getOrDefault("DBSubnetGroupName")
  valid_595791 = validateParameter(valid_595791, JString, required = true,
                                 default = nil)
  if valid_595791 != nil:
    section.add "DBSubnetGroupName", valid_595791
  var valid_595792 = formData.getOrDefault("SubnetIds")
  valid_595792 = validateParameter(valid_595792, JArray, required = true, default = nil)
  if valid_595792 != nil:
    section.add "SubnetIds", valid_595792
  var valid_595793 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_595793 = validateParameter(valid_595793, JString, required = false,
                                 default = nil)
  if valid_595793 != nil:
    section.add "DBSubnetGroupDescription", valid_595793
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595794: Call_PostModifyDBSubnetGroup_595779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595794.validator(path, query, header, formData, body)
  let scheme = call_595794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595794.url(scheme.get, call_595794.host, call_595794.base,
                         call_595794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595794, url, valid)

proc call*(call_595795: Call_PostModifyDBSubnetGroup_595779;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_595796 = newJObject()
  var formData_595797 = newJObject()
  add(formData_595797, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_595797.add "SubnetIds", SubnetIds
  add(query_595796, "Action", newJString(Action))
  add(formData_595797, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_595796, "Version", newJString(Version))
  result = call_595795.call(nil, query_595796, nil, formData_595797, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_595779(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_595780, base: "/",
    url: url_PostModifyDBSubnetGroup_595781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_595761 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBSubnetGroup_595763(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_595762(path: JsonNode; query: JsonNode;
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
  var valid_595764 = query.getOrDefault("Action")
  valid_595764 = validateParameter(valid_595764, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_595764 != nil:
    section.add "Action", valid_595764
  var valid_595765 = query.getOrDefault("DBSubnetGroupName")
  valid_595765 = validateParameter(valid_595765, JString, required = true,
                                 default = nil)
  if valid_595765 != nil:
    section.add "DBSubnetGroupName", valid_595765
  var valid_595766 = query.getOrDefault("SubnetIds")
  valid_595766 = validateParameter(valid_595766, JArray, required = true, default = nil)
  if valid_595766 != nil:
    section.add "SubnetIds", valid_595766
  var valid_595767 = query.getOrDefault("DBSubnetGroupDescription")
  valid_595767 = validateParameter(valid_595767, JString, required = false,
                                 default = nil)
  if valid_595767 != nil:
    section.add "DBSubnetGroupDescription", valid_595767
  var valid_595768 = query.getOrDefault("Version")
  valid_595768 = validateParameter(valid_595768, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595768 != nil:
    section.add "Version", valid_595768
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
  var valid_595769 = header.getOrDefault("X-Amz-Date")
  valid_595769 = validateParameter(valid_595769, JString, required = false,
                                 default = nil)
  if valid_595769 != nil:
    section.add "X-Amz-Date", valid_595769
  var valid_595770 = header.getOrDefault("X-Amz-Security-Token")
  valid_595770 = validateParameter(valid_595770, JString, required = false,
                                 default = nil)
  if valid_595770 != nil:
    section.add "X-Amz-Security-Token", valid_595770
  var valid_595771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595771 = validateParameter(valid_595771, JString, required = false,
                                 default = nil)
  if valid_595771 != nil:
    section.add "X-Amz-Content-Sha256", valid_595771
  var valid_595772 = header.getOrDefault("X-Amz-Algorithm")
  valid_595772 = validateParameter(valid_595772, JString, required = false,
                                 default = nil)
  if valid_595772 != nil:
    section.add "X-Amz-Algorithm", valid_595772
  var valid_595773 = header.getOrDefault("X-Amz-Signature")
  valid_595773 = validateParameter(valid_595773, JString, required = false,
                                 default = nil)
  if valid_595773 != nil:
    section.add "X-Amz-Signature", valid_595773
  var valid_595774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595774 = validateParameter(valid_595774, JString, required = false,
                                 default = nil)
  if valid_595774 != nil:
    section.add "X-Amz-SignedHeaders", valid_595774
  var valid_595775 = header.getOrDefault("X-Amz-Credential")
  valid_595775 = validateParameter(valid_595775, JString, required = false,
                                 default = nil)
  if valid_595775 != nil:
    section.add "X-Amz-Credential", valid_595775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595776: Call_GetModifyDBSubnetGroup_595761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595776.validator(path, query, header, formData, body)
  let scheme = call_595776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595776.url(scheme.get, call_595776.host, call_595776.base,
                         call_595776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595776, url, valid)

proc call*(call_595777: Call_GetModifyDBSubnetGroup_595761;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_595778 = newJObject()
  add(query_595778, "Action", newJString(Action))
  add(query_595778, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_595778.add "SubnetIds", SubnetIds
  add(query_595778, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_595778, "Version", newJString(Version))
  result = call_595777.call(nil, query_595778, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_595761(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_595762, base: "/",
    url: url_GetModifyDBSubnetGroup_595763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_595818 = ref object of OpenApiRestCall_593421
proc url_PostModifyEventSubscription_595820(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_595819(path: JsonNode; query: JsonNode;
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
  var valid_595821 = query.getOrDefault("Action")
  valid_595821 = validateParameter(valid_595821, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_595821 != nil:
    section.add "Action", valid_595821
  var valid_595822 = query.getOrDefault("Version")
  valid_595822 = validateParameter(valid_595822, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595822 != nil:
    section.add "Version", valid_595822
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
  var valid_595823 = header.getOrDefault("X-Amz-Date")
  valid_595823 = validateParameter(valid_595823, JString, required = false,
                                 default = nil)
  if valid_595823 != nil:
    section.add "X-Amz-Date", valid_595823
  var valid_595824 = header.getOrDefault("X-Amz-Security-Token")
  valid_595824 = validateParameter(valid_595824, JString, required = false,
                                 default = nil)
  if valid_595824 != nil:
    section.add "X-Amz-Security-Token", valid_595824
  var valid_595825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595825 = validateParameter(valid_595825, JString, required = false,
                                 default = nil)
  if valid_595825 != nil:
    section.add "X-Amz-Content-Sha256", valid_595825
  var valid_595826 = header.getOrDefault("X-Amz-Algorithm")
  valid_595826 = validateParameter(valid_595826, JString, required = false,
                                 default = nil)
  if valid_595826 != nil:
    section.add "X-Amz-Algorithm", valid_595826
  var valid_595827 = header.getOrDefault("X-Amz-Signature")
  valid_595827 = validateParameter(valid_595827, JString, required = false,
                                 default = nil)
  if valid_595827 != nil:
    section.add "X-Amz-Signature", valid_595827
  var valid_595828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595828 = validateParameter(valid_595828, JString, required = false,
                                 default = nil)
  if valid_595828 != nil:
    section.add "X-Amz-SignedHeaders", valid_595828
  var valid_595829 = header.getOrDefault("X-Amz-Credential")
  valid_595829 = validateParameter(valid_595829, JString, required = false,
                                 default = nil)
  if valid_595829 != nil:
    section.add "X-Amz-Credential", valid_595829
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_595830 = formData.getOrDefault("Enabled")
  valid_595830 = validateParameter(valid_595830, JBool, required = false, default = nil)
  if valid_595830 != nil:
    section.add "Enabled", valid_595830
  var valid_595831 = formData.getOrDefault("EventCategories")
  valid_595831 = validateParameter(valid_595831, JArray, required = false,
                                 default = nil)
  if valid_595831 != nil:
    section.add "EventCategories", valid_595831
  var valid_595832 = formData.getOrDefault("SnsTopicArn")
  valid_595832 = validateParameter(valid_595832, JString, required = false,
                                 default = nil)
  if valid_595832 != nil:
    section.add "SnsTopicArn", valid_595832
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_595833 = formData.getOrDefault("SubscriptionName")
  valid_595833 = validateParameter(valid_595833, JString, required = true,
                                 default = nil)
  if valid_595833 != nil:
    section.add "SubscriptionName", valid_595833
  var valid_595834 = formData.getOrDefault("SourceType")
  valid_595834 = validateParameter(valid_595834, JString, required = false,
                                 default = nil)
  if valid_595834 != nil:
    section.add "SourceType", valid_595834
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595835: Call_PostModifyEventSubscription_595818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595835.validator(path, query, header, formData, body)
  let scheme = call_595835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595835.url(scheme.get, call_595835.host, call_595835.base,
                         call_595835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595835, url, valid)

proc call*(call_595836: Call_PostModifyEventSubscription_595818;
          SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SnsTopicArn: string = "";
          Action: string = "ModifyEventSubscription";
          Version: string = "2014-09-01"; SourceType: string = ""): Recallable =
  ## postModifyEventSubscription
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   SnsTopicArn: string
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_595837 = newJObject()
  var formData_595838 = newJObject()
  add(formData_595838, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_595838.add "EventCategories", EventCategories
  add(formData_595838, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_595838, "SubscriptionName", newJString(SubscriptionName))
  add(query_595837, "Action", newJString(Action))
  add(query_595837, "Version", newJString(Version))
  add(formData_595838, "SourceType", newJString(SourceType))
  result = call_595836.call(nil, query_595837, nil, formData_595838, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_595818(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_595819, base: "/",
    url: url_PostModifyEventSubscription_595820,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_595798 = ref object of OpenApiRestCall_593421
proc url_GetModifyEventSubscription_595800(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_595799(path: JsonNode; query: JsonNode;
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
  var valid_595801 = query.getOrDefault("SourceType")
  valid_595801 = validateParameter(valid_595801, JString, required = false,
                                 default = nil)
  if valid_595801 != nil:
    section.add "SourceType", valid_595801
  var valid_595802 = query.getOrDefault("Enabled")
  valid_595802 = validateParameter(valid_595802, JBool, required = false, default = nil)
  if valid_595802 != nil:
    section.add "Enabled", valid_595802
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595803 = query.getOrDefault("Action")
  valid_595803 = validateParameter(valid_595803, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_595803 != nil:
    section.add "Action", valid_595803
  var valid_595804 = query.getOrDefault("SnsTopicArn")
  valid_595804 = validateParameter(valid_595804, JString, required = false,
                                 default = nil)
  if valid_595804 != nil:
    section.add "SnsTopicArn", valid_595804
  var valid_595805 = query.getOrDefault("EventCategories")
  valid_595805 = validateParameter(valid_595805, JArray, required = false,
                                 default = nil)
  if valid_595805 != nil:
    section.add "EventCategories", valid_595805
  var valid_595806 = query.getOrDefault("SubscriptionName")
  valid_595806 = validateParameter(valid_595806, JString, required = true,
                                 default = nil)
  if valid_595806 != nil:
    section.add "SubscriptionName", valid_595806
  var valid_595807 = query.getOrDefault("Version")
  valid_595807 = validateParameter(valid_595807, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595807 != nil:
    section.add "Version", valid_595807
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
  var valid_595808 = header.getOrDefault("X-Amz-Date")
  valid_595808 = validateParameter(valid_595808, JString, required = false,
                                 default = nil)
  if valid_595808 != nil:
    section.add "X-Amz-Date", valid_595808
  var valid_595809 = header.getOrDefault("X-Amz-Security-Token")
  valid_595809 = validateParameter(valid_595809, JString, required = false,
                                 default = nil)
  if valid_595809 != nil:
    section.add "X-Amz-Security-Token", valid_595809
  var valid_595810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595810 = validateParameter(valid_595810, JString, required = false,
                                 default = nil)
  if valid_595810 != nil:
    section.add "X-Amz-Content-Sha256", valid_595810
  var valid_595811 = header.getOrDefault("X-Amz-Algorithm")
  valid_595811 = validateParameter(valid_595811, JString, required = false,
                                 default = nil)
  if valid_595811 != nil:
    section.add "X-Amz-Algorithm", valid_595811
  var valid_595812 = header.getOrDefault("X-Amz-Signature")
  valid_595812 = validateParameter(valid_595812, JString, required = false,
                                 default = nil)
  if valid_595812 != nil:
    section.add "X-Amz-Signature", valid_595812
  var valid_595813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595813 = validateParameter(valid_595813, JString, required = false,
                                 default = nil)
  if valid_595813 != nil:
    section.add "X-Amz-SignedHeaders", valid_595813
  var valid_595814 = header.getOrDefault("X-Amz-Credential")
  valid_595814 = validateParameter(valid_595814, JString, required = false,
                                 default = nil)
  if valid_595814 != nil:
    section.add "X-Amz-Credential", valid_595814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595815: Call_GetModifyEventSubscription_595798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595815.validator(path, query, header, formData, body)
  let scheme = call_595815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595815.url(scheme.get, call_595815.host, call_595815.base,
                         call_595815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595815, url, valid)

proc call*(call_595816: Call_GetModifyEventSubscription_595798;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          EventCategories: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   EventCategories: JArray
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_595817 = newJObject()
  add(query_595817, "SourceType", newJString(SourceType))
  add(query_595817, "Enabled", newJBool(Enabled))
  add(query_595817, "Action", newJString(Action))
  add(query_595817, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_595817.add "EventCategories", EventCategories
  add(query_595817, "SubscriptionName", newJString(SubscriptionName))
  add(query_595817, "Version", newJString(Version))
  result = call_595816.call(nil, query_595817, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_595798(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_595799, base: "/",
    url: url_GetModifyEventSubscription_595800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_595858 = ref object of OpenApiRestCall_593421
proc url_PostModifyOptionGroup_595860(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_595859(path: JsonNode; query: JsonNode;
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
  var valid_595861 = query.getOrDefault("Action")
  valid_595861 = validateParameter(valid_595861, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_595861 != nil:
    section.add "Action", valid_595861
  var valid_595862 = query.getOrDefault("Version")
  valid_595862 = validateParameter(valid_595862, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595862 != nil:
    section.add "Version", valid_595862
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
  var valid_595863 = header.getOrDefault("X-Amz-Date")
  valid_595863 = validateParameter(valid_595863, JString, required = false,
                                 default = nil)
  if valid_595863 != nil:
    section.add "X-Amz-Date", valid_595863
  var valid_595864 = header.getOrDefault("X-Amz-Security-Token")
  valid_595864 = validateParameter(valid_595864, JString, required = false,
                                 default = nil)
  if valid_595864 != nil:
    section.add "X-Amz-Security-Token", valid_595864
  var valid_595865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595865 = validateParameter(valid_595865, JString, required = false,
                                 default = nil)
  if valid_595865 != nil:
    section.add "X-Amz-Content-Sha256", valid_595865
  var valid_595866 = header.getOrDefault("X-Amz-Algorithm")
  valid_595866 = validateParameter(valid_595866, JString, required = false,
                                 default = nil)
  if valid_595866 != nil:
    section.add "X-Amz-Algorithm", valid_595866
  var valid_595867 = header.getOrDefault("X-Amz-Signature")
  valid_595867 = validateParameter(valid_595867, JString, required = false,
                                 default = nil)
  if valid_595867 != nil:
    section.add "X-Amz-Signature", valid_595867
  var valid_595868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595868 = validateParameter(valid_595868, JString, required = false,
                                 default = nil)
  if valid_595868 != nil:
    section.add "X-Amz-SignedHeaders", valid_595868
  var valid_595869 = header.getOrDefault("X-Amz-Credential")
  valid_595869 = validateParameter(valid_595869, JString, required = false,
                                 default = nil)
  if valid_595869 != nil:
    section.add "X-Amz-Credential", valid_595869
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_595870 = formData.getOrDefault("OptionsToRemove")
  valid_595870 = validateParameter(valid_595870, JArray, required = false,
                                 default = nil)
  if valid_595870 != nil:
    section.add "OptionsToRemove", valid_595870
  var valid_595871 = formData.getOrDefault("ApplyImmediately")
  valid_595871 = validateParameter(valid_595871, JBool, required = false, default = nil)
  if valid_595871 != nil:
    section.add "ApplyImmediately", valid_595871
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_595872 = formData.getOrDefault("OptionGroupName")
  valid_595872 = validateParameter(valid_595872, JString, required = true,
                                 default = nil)
  if valid_595872 != nil:
    section.add "OptionGroupName", valid_595872
  var valid_595873 = formData.getOrDefault("OptionsToInclude")
  valid_595873 = validateParameter(valid_595873, JArray, required = false,
                                 default = nil)
  if valid_595873 != nil:
    section.add "OptionsToInclude", valid_595873
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595874: Call_PostModifyOptionGroup_595858; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595874.validator(path, query, header, formData, body)
  let scheme = call_595874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595874.url(scheme.get, call_595874.host, call_595874.base,
                         call_595874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595874, url, valid)

proc call*(call_595875: Call_PostModifyOptionGroup_595858; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionGroupName: string (required)
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595876 = newJObject()
  var formData_595877 = newJObject()
  if OptionsToRemove != nil:
    formData_595877.add "OptionsToRemove", OptionsToRemove
  add(formData_595877, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_595877, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_595877.add "OptionsToInclude", OptionsToInclude
  add(query_595876, "Action", newJString(Action))
  add(query_595876, "Version", newJString(Version))
  result = call_595875.call(nil, query_595876, nil, formData_595877, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_595858(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_595859, base: "/",
    url: url_PostModifyOptionGroup_595860, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_595839 = ref object of OpenApiRestCall_593421
proc url_GetModifyOptionGroup_595841(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_595840(path: JsonNode; query: JsonNode;
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
  var valid_595842 = query.getOrDefault("OptionGroupName")
  valid_595842 = validateParameter(valid_595842, JString, required = true,
                                 default = nil)
  if valid_595842 != nil:
    section.add "OptionGroupName", valid_595842
  var valid_595843 = query.getOrDefault("OptionsToRemove")
  valid_595843 = validateParameter(valid_595843, JArray, required = false,
                                 default = nil)
  if valid_595843 != nil:
    section.add "OptionsToRemove", valid_595843
  var valid_595844 = query.getOrDefault("Action")
  valid_595844 = validateParameter(valid_595844, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_595844 != nil:
    section.add "Action", valid_595844
  var valid_595845 = query.getOrDefault("Version")
  valid_595845 = validateParameter(valid_595845, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595845 != nil:
    section.add "Version", valid_595845
  var valid_595846 = query.getOrDefault("ApplyImmediately")
  valid_595846 = validateParameter(valid_595846, JBool, required = false, default = nil)
  if valid_595846 != nil:
    section.add "ApplyImmediately", valid_595846
  var valid_595847 = query.getOrDefault("OptionsToInclude")
  valid_595847 = validateParameter(valid_595847, JArray, required = false,
                                 default = nil)
  if valid_595847 != nil:
    section.add "OptionsToInclude", valid_595847
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
  var valid_595848 = header.getOrDefault("X-Amz-Date")
  valid_595848 = validateParameter(valid_595848, JString, required = false,
                                 default = nil)
  if valid_595848 != nil:
    section.add "X-Amz-Date", valid_595848
  var valid_595849 = header.getOrDefault("X-Amz-Security-Token")
  valid_595849 = validateParameter(valid_595849, JString, required = false,
                                 default = nil)
  if valid_595849 != nil:
    section.add "X-Amz-Security-Token", valid_595849
  var valid_595850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595850 = validateParameter(valid_595850, JString, required = false,
                                 default = nil)
  if valid_595850 != nil:
    section.add "X-Amz-Content-Sha256", valid_595850
  var valid_595851 = header.getOrDefault("X-Amz-Algorithm")
  valid_595851 = validateParameter(valid_595851, JString, required = false,
                                 default = nil)
  if valid_595851 != nil:
    section.add "X-Amz-Algorithm", valid_595851
  var valid_595852 = header.getOrDefault("X-Amz-Signature")
  valid_595852 = validateParameter(valid_595852, JString, required = false,
                                 default = nil)
  if valid_595852 != nil:
    section.add "X-Amz-Signature", valid_595852
  var valid_595853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595853 = validateParameter(valid_595853, JString, required = false,
                                 default = nil)
  if valid_595853 != nil:
    section.add "X-Amz-SignedHeaders", valid_595853
  var valid_595854 = header.getOrDefault("X-Amz-Credential")
  valid_595854 = validateParameter(valid_595854, JString, required = false,
                                 default = nil)
  if valid_595854 != nil:
    section.add "X-Amz-Credential", valid_595854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595855: Call_GetModifyOptionGroup_595839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595855.validator(path, query, header, formData, body)
  let scheme = call_595855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595855.url(scheme.get, call_595855.host, call_595855.base,
                         call_595855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595855, url, valid)

proc call*(call_595856: Call_GetModifyOptionGroup_595839; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2014-09-01"; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil): Recallable =
  ## getModifyOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionsToRemove: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  var query_595857 = newJObject()
  add(query_595857, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_595857.add "OptionsToRemove", OptionsToRemove
  add(query_595857, "Action", newJString(Action))
  add(query_595857, "Version", newJString(Version))
  add(query_595857, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_595857.add "OptionsToInclude", OptionsToInclude
  result = call_595856.call(nil, query_595857, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_595839(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_595840, base: "/",
    url: url_GetModifyOptionGroup_595841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_595896 = ref object of OpenApiRestCall_593421
proc url_PostPromoteReadReplica_595898(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_595897(path: JsonNode; query: JsonNode;
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
  var valid_595899 = query.getOrDefault("Action")
  valid_595899 = validateParameter(valid_595899, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_595899 != nil:
    section.add "Action", valid_595899
  var valid_595900 = query.getOrDefault("Version")
  valid_595900 = validateParameter(valid_595900, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595900 != nil:
    section.add "Version", valid_595900
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
  var valid_595901 = header.getOrDefault("X-Amz-Date")
  valid_595901 = validateParameter(valid_595901, JString, required = false,
                                 default = nil)
  if valid_595901 != nil:
    section.add "X-Amz-Date", valid_595901
  var valid_595902 = header.getOrDefault("X-Amz-Security-Token")
  valid_595902 = validateParameter(valid_595902, JString, required = false,
                                 default = nil)
  if valid_595902 != nil:
    section.add "X-Amz-Security-Token", valid_595902
  var valid_595903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595903 = validateParameter(valid_595903, JString, required = false,
                                 default = nil)
  if valid_595903 != nil:
    section.add "X-Amz-Content-Sha256", valid_595903
  var valid_595904 = header.getOrDefault("X-Amz-Algorithm")
  valid_595904 = validateParameter(valid_595904, JString, required = false,
                                 default = nil)
  if valid_595904 != nil:
    section.add "X-Amz-Algorithm", valid_595904
  var valid_595905 = header.getOrDefault("X-Amz-Signature")
  valid_595905 = validateParameter(valid_595905, JString, required = false,
                                 default = nil)
  if valid_595905 != nil:
    section.add "X-Amz-Signature", valid_595905
  var valid_595906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595906 = validateParameter(valid_595906, JString, required = false,
                                 default = nil)
  if valid_595906 != nil:
    section.add "X-Amz-SignedHeaders", valid_595906
  var valid_595907 = header.getOrDefault("X-Amz-Credential")
  valid_595907 = validateParameter(valid_595907, JString, required = false,
                                 default = nil)
  if valid_595907 != nil:
    section.add "X-Amz-Credential", valid_595907
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595908 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595908 = validateParameter(valid_595908, JString, required = true,
                                 default = nil)
  if valid_595908 != nil:
    section.add "DBInstanceIdentifier", valid_595908
  var valid_595909 = formData.getOrDefault("BackupRetentionPeriod")
  valid_595909 = validateParameter(valid_595909, JInt, required = false, default = nil)
  if valid_595909 != nil:
    section.add "BackupRetentionPeriod", valid_595909
  var valid_595910 = formData.getOrDefault("PreferredBackupWindow")
  valid_595910 = validateParameter(valid_595910, JString, required = false,
                                 default = nil)
  if valid_595910 != nil:
    section.add "PreferredBackupWindow", valid_595910
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595911: Call_PostPromoteReadReplica_595896; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595911.validator(path, query, header, formData, body)
  let scheme = call_595911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595911.url(scheme.get, call_595911.host, call_595911.base,
                         call_595911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595911, url, valid)

proc call*(call_595912: Call_PostPromoteReadReplica_595896;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_595913 = newJObject()
  var formData_595914 = newJObject()
  add(formData_595914, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595914, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_595913, "Action", newJString(Action))
  add(formData_595914, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_595913, "Version", newJString(Version))
  result = call_595912.call(nil, query_595913, nil, formData_595914, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_595896(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_595897, base: "/",
    url: url_PostPromoteReadReplica_595898, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_595878 = ref object of OpenApiRestCall_593421
proc url_GetPromoteReadReplica_595880(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_595879(path: JsonNode; query: JsonNode;
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
  var valid_595881 = query.getOrDefault("BackupRetentionPeriod")
  valid_595881 = validateParameter(valid_595881, JInt, required = false, default = nil)
  if valid_595881 != nil:
    section.add "BackupRetentionPeriod", valid_595881
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595882 = query.getOrDefault("Action")
  valid_595882 = validateParameter(valid_595882, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_595882 != nil:
    section.add "Action", valid_595882
  var valid_595883 = query.getOrDefault("PreferredBackupWindow")
  valid_595883 = validateParameter(valid_595883, JString, required = false,
                                 default = nil)
  if valid_595883 != nil:
    section.add "PreferredBackupWindow", valid_595883
  var valid_595884 = query.getOrDefault("Version")
  valid_595884 = validateParameter(valid_595884, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595884 != nil:
    section.add "Version", valid_595884
  var valid_595885 = query.getOrDefault("DBInstanceIdentifier")
  valid_595885 = validateParameter(valid_595885, JString, required = true,
                                 default = nil)
  if valid_595885 != nil:
    section.add "DBInstanceIdentifier", valid_595885
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
  var valid_595886 = header.getOrDefault("X-Amz-Date")
  valid_595886 = validateParameter(valid_595886, JString, required = false,
                                 default = nil)
  if valid_595886 != nil:
    section.add "X-Amz-Date", valid_595886
  var valid_595887 = header.getOrDefault("X-Amz-Security-Token")
  valid_595887 = validateParameter(valid_595887, JString, required = false,
                                 default = nil)
  if valid_595887 != nil:
    section.add "X-Amz-Security-Token", valid_595887
  var valid_595888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595888 = validateParameter(valid_595888, JString, required = false,
                                 default = nil)
  if valid_595888 != nil:
    section.add "X-Amz-Content-Sha256", valid_595888
  var valid_595889 = header.getOrDefault("X-Amz-Algorithm")
  valid_595889 = validateParameter(valid_595889, JString, required = false,
                                 default = nil)
  if valid_595889 != nil:
    section.add "X-Amz-Algorithm", valid_595889
  var valid_595890 = header.getOrDefault("X-Amz-Signature")
  valid_595890 = validateParameter(valid_595890, JString, required = false,
                                 default = nil)
  if valid_595890 != nil:
    section.add "X-Amz-Signature", valid_595890
  var valid_595891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595891 = validateParameter(valid_595891, JString, required = false,
                                 default = nil)
  if valid_595891 != nil:
    section.add "X-Amz-SignedHeaders", valid_595891
  var valid_595892 = header.getOrDefault("X-Amz-Credential")
  valid_595892 = validateParameter(valid_595892, JString, required = false,
                                 default = nil)
  if valid_595892 != nil:
    section.add "X-Amz-Credential", valid_595892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595893: Call_GetPromoteReadReplica_595878; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595893.validator(path, query, header, formData, body)
  let scheme = call_595893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595893.url(scheme.get, call_595893.host, call_595893.base,
                         call_595893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595893, url, valid)

proc call*(call_595894: Call_GetPromoteReadReplica_595878;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_595895 = newJObject()
  add(query_595895, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_595895, "Action", newJString(Action))
  add(query_595895, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_595895, "Version", newJString(Version))
  add(query_595895, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_595894.call(nil, query_595895, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_595878(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_595879, base: "/",
    url: url_GetPromoteReadReplica_595880, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_595934 = ref object of OpenApiRestCall_593421
proc url_PostPurchaseReservedDBInstancesOffering_595936(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_595935(path: JsonNode;
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
  var valid_595937 = query.getOrDefault("Action")
  valid_595937 = validateParameter(valid_595937, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_595937 != nil:
    section.add "Action", valid_595937
  var valid_595938 = query.getOrDefault("Version")
  valid_595938 = validateParameter(valid_595938, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_595946 = formData.getOrDefault("ReservedDBInstanceId")
  valid_595946 = validateParameter(valid_595946, JString, required = false,
                                 default = nil)
  if valid_595946 != nil:
    section.add "ReservedDBInstanceId", valid_595946
  var valid_595947 = formData.getOrDefault("Tags")
  valid_595947 = validateParameter(valid_595947, JArray, required = false,
                                 default = nil)
  if valid_595947 != nil:
    section.add "Tags", valid_595947
  var valid_595948 = formData.getOrDefault("DBInstanceCount")
  valid_595948 = validateParameter(valid_595948, JInt, required = false, default = nil)
  if valid_595948 != nil:
    section.add "DBInstanceCount", valid_595948
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_595949 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595949 = validateParameter(valid_595949, JString, required = true,
                                 default = nil)
  if valid_595949 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595949
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595950: Call_PostPurchaseReservedDBInstancesOffering_595934;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595950.validator(path, query, header, formData, body)
  let scheme = call_595950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595950.url(scheme.get, call_595950.host, call_595950.base,
                         call_595950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595950, url, valid)

proc call*(call_595951: Call_PostPurchaseReservedDBInstancesOffering_595934;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = ""; Tags: JsonNode = nil;
          DBInstanceCount: int = 0;
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2014-09-01"): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Tags: JArray
  ##   DBInstanceCount: int
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_595952 = newJObject()
  var formData_595953 = newJObject()
  add(formData_595953, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_595953.add "Tags", Tags
  add(formData_595953, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_595952, "Action", newJString(Action))
  add(formData_595953, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595952, "Version", newJString(Version))
  result = call_595951.call(nil, query_595952, nil, formData_595953, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_595934(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_595935, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_595936,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_595915 = ref object of OpenApiRestCall_593421
proc url_GetPurchaseReservedDBInstancesOffering_595917(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_595916(path: JsonNode;
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
  var valid_595918 = query.getOrDefault("DBInstanceCount")
  valid_595918 = validateParameter(valid_595918, JInt, required = false, default = nil)
  if valid_595918 != nil:
    section.add "DBInstanceCount", valid_595918
  var valid_595919 = query.getOrDefault("Tags")
  valid_595919 = validateParameter(valid_595919, JArray, required = false,
                                 default = nil)
  if valid_595919 != nil:
    section.add "Tags", valid_595919
  var valid_595920 = query.getOrDefault("ReservedDBInstanceId")
  valid_595920 = validateParameter(valid_595920, JString, required = false,
                                 default = nil)
  if valid_595920 != nil:
    section.add "ReservedDBInstanceId", valid_595920
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_595921 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595921 = validateParameter(valid_595921, JString, required = true,
                                 default = nil)
  if valid_595921 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595921
  var valid_595922 = query.getOrDefault("Action")
  valid_595922 = validateParameter(valid_595922, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_595922 != nil:
    section.add "Action", valid_595922
  var valid_595923 = query.getOrDefault("Version")
  valid_595923 = validateParameter(valid_595923, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595923 != nil:
    section.add "Version", valid_595923
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
  var valid_595924 = header.getOrDefault("X-Amz-Date")
  valid_595924 = validateParameter(valid_595924, JString, required = false,
                                 default = nil)
  if valid_595924 != nil:
    section.add "X-Amz-Date", valid_595924
  var valid_595925 = header.getOrDefault("X-Amz-Security-Token")
  valid_595925 = validateParameter(valid_595925, JString, required = false,
                                 default = nil)
  if valid_595925 != nil:
    section.add "X-Amz-Security-Token", valid_595925
  var valid_595926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595926 = validateParameter(valid_595926, JString, required = false,
                                 default = nil)
  if valid_595926 != nil:
    section.add "X-Amz-Content-Sha256", valid_595926
  var valid_595927 = header.getOrDefault("X-Amz-Algorithm")
  valid_595927 = validateParameter(valid_595927, JString, required = false,
                                 default = nil)
  if valid_595927 != nil:
    section.add "X-Amz-Algorithm", valid_595927
  var valid_595928 = header.getOrDefault("X-Amz-Signature")
  valid_595928 = validateParameter(valid_595928, JString, required = false,
                                 default = nil)
  if valid_595928 != nil:
    section.add "X-Amz-Signature", valid_595928
  var valid_595929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595929 = validateParameter(valid_595929, JString, required = false,
                                 default = nil)
  if valid_595929 != nil:
    section.add "X-Amz-SignedHeaders", valid_595929
  var valid_595930 = header.getOrDefault("X-Amz-Credential")
  valid_595930 = validateParameter(valid_595930, JString, required = false,
                                 default = nil)
  if valid_595930 != nil:
    section.add "X-Amz-Credential", valid_595930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595931: Call_GetPurchaseReservedDBInstancesOffering_595915;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595931.validator(path, query, header, formData, body)
  let scheme = call_595931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595931.url(scheme.get, call_595931.host, call_595931.base,
                         call_595931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595931, url, valid)

proc call*(call_595932: Call_GetPurchaseReservedDBInstancesOffering_595915;
          ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
          Tags: JsonNode = nil; ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2014-09-01"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   Tags: JArray
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595933 = newJObject()
  add(query_595933, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_595933.add "Tags", Tags
  add(query_595933, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_595933, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595933, "Action", newJString(Action))
  add(query_595933, "Version", newJString(Version))
  result = call_595932.call(nil, query_595933, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_595915(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_595916, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_595917,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_595971 = ref object of OpenApiRestCall_593421
proc url_PostRebootDBInstance_595973(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_595972(path: JsonNode; query: JsonNode;
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
  var valid_595974 = query.getOrDefault("Action")
  valid_595974 = validateParameter(valid_595974, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_595974 != nil:
    section.add "Action", valid_595974
  var valid_595975 = query.getOrDefault("Version")
  valid_595975 = validateParameter(valid_595975, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595975 != nil:
    section.add "Version", valid_595975
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
  var valid_595976 = header.getOrDefault("X-Amz-Date")
  valid_595976 = validateParameter(valid_595976, JString, required = false,
                                 default = nil)
  if valid_595976 != nil:
    section.add "X-Amz-Date", valid_595976
  var valid_595977 = header.getOrDefault("X-Amz-Security-Token")
  valid_595977 = validateParameter(valid_595977, JString, required = false,
                                 default = nil)
  if valid_595977 != nil:
    section.add "X-Amz-Security-Token", valid_595977
  var valid_595978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595978 = validateParameter(valid_595978, JString, required = false,
                                 default = nil)
  if valid_595978 != nil:
    section.add "X-Amz-Content-Sha256", valid_595978
  var valid_595979 = header.getOrDefault("X-Amz-Algorithm")
  valid_595979 = validateParameter(valid_595979, JString, required = false,
                                 default = nil)
  if valid_595979 != nil:
    section.add "X-Amz-Algorithm", valid_595979
  var valid_595980 = header.getOrDefault("X-Amz-Signature")
  valid_595980 = validateParameter(valid_595980, JString, required = false,
                                 default = nil)
  if valid_595980 != nil:
    section.add "X-Amz-Signature", valid_595980
  var valid_595981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595981 = validateParameter(valid_595981, JString, required = false,
                                 default = nil)
  if valid_595981 != nil:
    section.add "X-Amz-SignedHeaders", valid_595981
  var valid_595982 = header.getOrDefault("X-Amz-Credential")
  valid_595982 = validateParameter(valid_595982, JString, required = false,
                                 default = nil)
  if valid_595982 != nil:
    section.add "X-Amz-Credential", valid_595982
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595983 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595983 = validateParameter(valid_595983, JString, required = true,
                                 default = nil)
  if valid_595983 != nil:
    section.add "DBInstanceIdentifier", valid_595983
  var valid_595984 = formData.getOrDefault("ForceFailover")
  valid_595984 = validateParameter(valid_595984, JBool, required = false, default = nil)
  if valid_595984 != nil:
    section.add "ForceFailover", valid_595984
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595985: Call_PostRebootDBInstance_595971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595985.validator(path, query, header, formData, body)
  let scheme = call_595985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595985.url(scheme.get, call_595985.host, call_595985.base,
                         call_595985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595985, url, valid)

proc call*(call_595986: Call_PostRebootDBInstance_595971;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_595987 = newJObject()
  var formData_595988 = newJObject()
  add(formData_595988, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595987, "Action", newJString(Action))
  add(formData_595988, "ForceFailover", newJBool(ForceFailover))
  add(query_595987, "Version", newJString(Version))
  result = call_595986.call(nil, query_595987, nil, formData_595988, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_595971(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_595972, base: "/",
    url: url_PostRebootDBInstance_595973, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_595954 = ref object of OpenApiRestCall_593421
proc url_GetRebootDBInstance_595956(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_595955(path: JsonNode; query: JsonNode;
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
  var valid_595957 = query.getOrDefault("Action")
  valid_595957 = validateParameter(valid_595957, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_595957 != nil:
    section.add "Action", valid_595957
  var valid_595958 = query.getOrDefault("ForceFailover")
  valid_595958 = validateParameter(valid_595958, JBool, required = false, default = nil)
  if valid_595958 != nil:
    section.add "ForceFailover", valid_595958
  var valid_595959 = query.getOrDefault("Version")
  valid_595959 = validateParameter(valid_595959, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595959 != nil:
    section.add "Version", valid_595959
  var valid_595960 = query.getOrDefault("DBInstanceIdentifier")
  valid_595960 = validateParameter(valid_595960, JString, required = true,
                                 default = nil)
  if valid_595960 != nil:
    section.add "DBInstanceIdentifier", valid_595960
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
  var valid_595961 = header.getOrDefault("X-Amz-Date")
  valid_595961 = validateParameter(valid_595961, JString, required = false,
                                 default = nil)
  if valid_595961 != nil:
    section.add "X-Amz-Date", valid_595961
  var valid_595962 = header.getOrDefault("X-Amz-Security-Token")
  valid_595962 = validateParameter(valid_595962, JString, required = false,
                                 default = nil)
  if valid_595962 != nil:
    section.add "X-Amz-Security-Token", valid_595962
  var valid_595963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595963 = validateParameter(valid_595963, JString, required = false,
                                 default = nil)
  if valid_595963 != nil:
    section.add "X-Amz-Content-Sha256", valid_595963
  var valid_595964 = header.getOrDefault("X-Amz-Algorithm")
  valid_595964 = validateParameter(valid_595964, JString, required = false,
                                 default = nil)
  if valid_595964 != nil:
    section.add "X-Amz-Algorithm", valid_595964
  var valid_595965 = header.getOrDefault("X-Amz-Signature")
  valid_595965 = validateParameter(valid_595965, JString, required = false,
                                 default = nil)
  if valid_595965 != nil:
    section.add "X-Amz-Signature", valid_595965
  var valid_595966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595966 = validateParameter(valid_595966, JString, required = false,
                                 default = nil)
  if valid_595966 != nil:
    section.add "X-Amz-SignedHeaders", valid_595966
  var valid_595967 = header.getOrDefault("X-Amz-Credential")
  valid_595967 = validateParameter(valid_595967, JString, required = false,
                                 default = nil)
  if valid_595967 != nil:
    section.add "X-Amz-Credential", valid_595967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595968: Call_GetRebootDBInstance_595954; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595968.validator(path, query, header, formData, body)
  let scheme = call_595968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595968.url(scheme.get, call_595968.host, call_595968.base,
                         call_595968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595968, url, valid)

proc call*(call_595969: Call_GetRebootDBInstance_595954;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_595970 = newJObject()
  add(query_595970, "Action", newJString(Action))
  add(query_595970, "ForceFailover", newJBool(ForceFailover))
  add(query_595970, "Version", newJString(Version))
  add(query_595970, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_595969.call(nil, query_595970, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_595954(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_595955, base: "/",
    url: url_GetRebootDBInstance_595956, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_596006 = ref object of OpenApiRestCall_593421
proc url_PostRemoveSourceIdentifierFromSubscription_596008(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_596007(path: JsonNode;
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
  var valid_596009 = query.getOrDefault("Action")
  valid_596009 = validateParameter(valid_596009, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_596009 != nil:
    section.add "Action", valid_596009
  var valid_596010 = query.getOrDefault("Version")
  valid_596010 = validateParameter(valid_596010, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_596010 != nil:
    section.add "Version", valid_596010
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
  var valid_596011 = header.getOrDefault("X-Amz-Date")
  valid_596011 = validateParameter(valid_596011, JString, required = false,
                                 default = nil)
  if valid_596011 != nil:
    section.add "X-Amz-Date", valid_596011
  var valid_596012 = header.getOrDefault("X-Amz-Security-Token")
  valid_596012 = validateParameter(valid_596012, JString, required = false,
                                 default = nil)
  if valid_596012 != nil:
    section.add "X-Amz-Security-Token", valid_596012
  var valid_596013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596013 = validateParameter(valid_596013, JString, required = false,
                                 default = nil)
  if valid_596013 != nil:
    section.add "X-Amz-Content-Sha256", valid_596013
  var valid_596014 = header.getOrDefault("X-Amz-Algorithm")
  valid_596014 = validateParameter(valid_596014, JString, required = false,
                                 default = nil)
  if valid_596014 != nil:
    section.add "X-Amz-Algorithm", valid_596014
  var valid_596015 = header.getOrDefault("X-Amz-Signature")
  valid_596015 = validateParameter(valid_596015, JString, required = false,
                                 default = nil)
  if valid_596015 != nil:
    section.add "X-Amz-Signature", valid_596015
  var valid_596016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596016 = validateParameter(valid_596016, JString, required = false,
                                 default = nil)
  if valid_596016 != nil:
    section.add "X-Amz-SignedHeaders", valid_596016
  var valid_596017 = header.getOrDefault("X-Amz-Credential")
  valid_596017 = validateParameter(valid_596017, JString, required = false,
                                 default = nil)
  if valid_596017 != nil:
    section.add "X-Amz-Credential", valid_596017
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_596018 = formData.getOrDefault("SourceIdentifier")
  valid_596018 = validateParameter(valid_596018, JString, required = true,
                                 default = nil)
  if valid_596018 != nil:
    section.add "SourceIdentifier", valid_596018
  var valid_596019 = formData.getOrDefault("SubscriptionName")
  valid_596019 = validateParameter(valid_596019, JString, required = true,
                                 default = nil)
  if valid_596019 != nil:
    section.add "SubscriptionName", valid_596019
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596020: Call_PostRemoveSourceIdentifierFromSubscription_596006;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596020.validator(path, query, header, formData, body)
  let scheme = call_596020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596020.url(scheme.get, call_596020.host, call_596020.base,
                         call_596020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596020, url, valid)

proc call*(call_596021: Call_PostRemoveSourceIdentifierFromSubscription_596006;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_596022 = newJObject()
  var formData_596023 = newJObject()
  add(formData_596023, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_596023, "SubscriptionName", newJString(SubscriptionName))
  add(query_596022, "Action", newJString(Action))
  add(query_596022, "Version", newJString(Version))
  result = call_596021.call(nil, query_596022, nil, formData_596023, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_596006(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_596007,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_596008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_595989 = ref object of OpenApiRestCall_593421
proc url_GetRemoveSourceIdentifierFromSubscription_595991(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_595990(path: JsonNode;
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
  var valid_595992 = query.getOrDefault("Action")
  valid_595992 = validateParameter(valid_595992, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_595992 != nil:
    section.add "Action", valid_595992
  var valid_595993 = query.getOrDefault("SourceIdentifier")
  valid_595993 = validateParameter(valid_595993, JString, required = true,
                                 default = nil)
  if valid_595993 != nil:
    section.add "SourceIdentifier", valid_595993
  var valid_595994 = query.getOrDefault("SubscriptionName")
  valid_595994 = validateParameter(valid_595994, JString, required = true,
                                 default = nil)
  if valid_595994 != nil:
    section.add "SubscriptionName", valid_595994
  var valid_595995 = query.getOrDefault("Version")
  valid_595995 = validateParameter(valid_595995, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595995 != nil:
    section.add "Version", valid_595995
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
  var valid_595996 = header.getOrDefault("X-Amz-Date")
  valid_595996 = validateParameter(valid_595996, JString, required = false,
                                 default = nil)
  if valid_595996 != nil:
    section.add "X-Amz-Date", valid_595996
  var valid_595997 = header.getOrDefault("X-Amz-Security-Token")
  valid_595997 = validateParameter(valid_595997, JString, required = false,
                                 default = nil)
  if valid_595997 != nil:
    section.add "X-Amz-Security-Token", valid_595997
  var valid_595998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595998 = validateParameter(valid_595998, JString, required = false,
                                 default = nil)
  if valid_595998 != nil:
    section.add "X-Amz-Content-Sha256", valid_595998
  var valid_595999 = header.getOrDefault("X-Amz-Algorithm")
  valid_595999 = validateParameter(valid_595999, JString, required = false,
                                 default = nil)
  if valid_595999 != nil:
    section.add "X-Amz-Algorithm", valid_595999
  var valid_596000 = header.getOrDefault("X-Amz-Signature")
  valid_596000 = validateParameter(valid_596000, JString, required = false,
                                 default = nil)
  if valid_596000 != nil:
    section.add "X-Amz-Signature", valid_596000
  var valid_596001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596001 = validateParameter(valid_596001, JString, required = false,
                                 default = nil)
  if valid_596001 != nil:
    section.add "X-Amz-SignedHeaders", valid_596001
  var valid_596002 = header.getOrDefault("X-Amz-Credential")
  valid_596002 = validateParameter(valid_596002, JString, required = false,
                                 default = nil)
  if valid_596002 != nil:
    section.add "X-Amz-Credential", valid_596002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596003: Call_GetRemoveSourceIdentifierFromSubscription_595989;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596003.validator(path, query, header, formData, body)
  let scheme = call_596003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596003.url(scheme.get, call_596003.host, call_596003.base,
                         call_596003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596003, url, valid)

proc call*(call_596004: Call_GetRemoveSourceIdentifierFromSubscription_595989;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_596005 = newJObject()
  add(query_596005, "Action", newJString(Action))
  add(query_596005, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_596005, "SubscriptionName", newJString(SubscriptionName))
  add(query_596005, "Version", newJString(Version))
  result = call_596004.call(nil, query_596005, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_595989(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_595990,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_595991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_596041 = ref object of OpenApiRestCall_593421
proc url_PostRemoveTagsFromResource_596043(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_596042(path: JsonNode; query: JsonNode;
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
  var valid_596044 = query.getOrDefault("Action")
  valid_596044 = validateParameter(valid_596044, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_596044 != nil:
    section.add "Action", valid_596044
  var valid_596045 = query.getOrDefault("Version")
  valid_596045 = validateParameter(valid_596045, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_596045 != nil:
    section.add "Version", valid_596045
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
  var valid_596046 = header.getOrDefault("X-Amz-Date")
  valid_596046 = validateParameter(valid_596046, JString, required = false,
                                 default = nil)
  if valid_596046 != nil:
    section.add "X-Amz-Date", valid_596046
  var valid_596047 = header.getOrDefault("X-Amz-Security-Token")
  valid_596047 = validateParameter(valid_596047, JString, required = false,
                                 default = nil)
  if valid_596047 != nil:
    section.add "X-Amz-Security-Token", valid_596047
  var valid_596048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596048 = validateParameter(valid_596048, JString, required = false,
                                 default = nil)
  if valid_596048 != nil:
    section.add "X-Amz-Content-Sha256", valid_596048
  var valid_596049 = header.getOrDefault("X-Amz-Algorithm")
  valid_596049 = validateParameter(valid_596049, JString, required = false,
                                 default = nil)
  if valid_596049 != nil:
    section.add "X-Amz-Algorithm", valid_596049
  var valid_596050 = header.getOrDefault("X-Amz-Signature")
  valid_596050 = validateParameter(valid_596050, JString, required = false,
                                 default = nil)
  if valid_596050 != nil:
    section.add "X-Amz-Signature", valid_596050
  var valid_596051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596051 = validateParameter(valid_596051, JString, required = false,
                                 default = nil)
  if valid_596051 != nil:
    section.add "X-Amz-SignedHeaders", valid_596051
  var valid_596052 = header.getOrDefault("X-Amz-Credential")
  valid_596052 = validateParameter(valid_596052, JString, required = false,
                                 default = nil)
  if valid_596052 != nil:
    section.add "X-Amz-Credential", valid_596052
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_596053 = formData.getOrDefault("TagKeys")
  valid_596053 = validateParameter(valid_596053, JArray, required = true, default = nil)
  if valid_596053 != nil:
    section.add "TagKeys", valid_596053
  var valid_596054 = formData.getOrDefault("ResourceName")
  valid_596054 = validateParameter(valid_596054, JString, required = true,
                                 default = nil)
  if valid_596054 != nil:
    section.add "ResourceName", valid_596054
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596055: Call_PostRemoveTagsFromResource_596041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_596055.validator(path, query, header, formData, body)
  let scheme = call_596055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596055.url(scheme.get, call_596055.host, call_596055.base,
                         call_596055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596055, url, valid)

proc call*(call_596056: Call_PostRemoveTagsFromResource_596041; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_596057 = newJObject()
  var formData_596058 = newJObject()
  add(query_596057, "Action", newJString(Action))
  if TagKeys != nil:
    formData_596058.add "TagKeys", TagKeys
  add(formData_596058, "ResourceName", newJString(ResourceName))
  add(query_596057, "Version", newJString(Version))
  result = call_596056.call(nil, query_596057, nil, formData_596058, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_596041(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_596042, base: "/",
    url: url_PostRemoveTagsFromResource_596043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_596024 = ref object of OpenApiRestCall_593421
proc url_GetRemoveTagsFromResource_596026(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_596025(path: JsonNode; query: JsonNode;
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
  var valid_596027 = query.getOrDefault("ResourceName")
  valid_596027 = validateParameter(valid_596027, JString, required = true,
                                 default = nil)
  if valid_596027 != nil:
    section.add "ResourceName", valid_596027
  var valid_596028 = query.getOrDefault("Action")
  valid_596028 = validateParameter(valid_596028, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_596028 != nil:
    section.add "Action", valid_596028
  var valid_596029 = query.getOrDefault("TagKeys")
  valid_596029 = validateParameter(valid_596029, JArray, required = true, default = nil)
  if valid_596029 != nil:
    section.add "TagKeys", valid_596029
  var valid_596030 = query.getOrDefault("Version")
  valid_596030 = validateParameter(valid_596030, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_596030 != nil:
    section.add "Version", valid_596030
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
  var valid_596031 = header.getOrDefault("X-Amz-Date")
  valid_596031 = validateParameter(valid_596031, JString, required = false,
                                 default = nil)
  if valid_596031 != nil:
    section.add "X-Amz-Date", valid_596031
  var valid_596032 = header.getOrDefault("X-Amz-Security-Token")
  valid_596032 = validateParameter(valid_596032, JString, required = false,
                                 default = nil)
  if valid_596032 != nil:
    section.add "X-Amz-Security-Token", valid_596032
  var valid_596033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596033 = validateParameter(valid_596033, JString, required = false,
                                 default = nil)
  if valid_596033 != nil:
    section.add "X-Amz-Content-Sha256", valid_596033
  var valid_596034 = header.getOrDefault("X-Amz-Algorithm")
  valid_596034 = validateParameter(valid_596034, JString, required = false,
                                 default = nil)
  if valid_596034 != nil:
    section.add "X-Amz-Algorithm", valid_596034
  var valid_596035 = header.getOrDefault("X-Amz-Signature")
  valid_596035 = validateParameter(valid_596035, JString, required = false,
                                 default = nil)
  if valid_596035 != nil:
    section.add "X-Amz-Signature", valid_596035
  var valid_596036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596036 = validateParameter(valid_596036, JString, required = false,
                                 default = nil)
  if valid_596036 != nil:
    section.add "X-Amz-SignedHeaders", valid_596036
  var valid_596037 = header.getOrDefault("X-Amz-Credential")
  valid_596037 = validateParameter(valid_596037, JString, required = false,
                                 default = nil)
  if valid_596037 != nil:
    section.add "X-Amz-Credential", valid_596037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596038: Call_GetRemoveTagsFromResource_596024; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_596038.validator(path, query, header, formData, body)
  let scheme = call_596038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596038.url(scheme.get, call_596038.host, call_596038.base,
                         call_596038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596038, url, valid)

proc call*(call_596039: Call_GetRemoveTagsFromResource_596024;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-09-01"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_596040 = newJObject()
  add(query_596040, "ResourceName", newJString(ResourceName))
  add(query_596040, "Action", newJString(Action))
  if TagKeys != nil:
    query_596040.add "TagKeys", TagKeys
  add(query_596040, "Version", newJString(Version))
  result = call_596039.call(nil, query_596040, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_596024(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_596025, base: "/",
    url: url_GetRemoveTagsFromResource_596026,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_596077 = ref object of OpenApiRestCall_593421
proc url_PostResetDBParameterGroup_596079(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_596078(path: JsonNode; query: JsonNode;
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
  var valid_596080 = query.getOrDefault("Action")
  valid_596080 = validateParameter(valid_596080, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_596080 != nil:
    section.add "Action", valid_596080
  var valid_596081 = query.getOrDefault("Version")
  valid_596081 = validateParameter(valid_596081, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_596081 != nil:
    section.add "Version", valid_596081
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
  var valid_596082 = header.getOrDefault("X-Amz-Date")
  valid_596082 = validateParameter(valid_596082, JString, required = false,
                                 default = nil)
  if valid_596082 != nil:
    section.add "X-Amz-Date", valid_596082
  var valid_596083 = header.getOrDefault("X-Amz-Security-Token")
  valid_596083 = validateParameter(valid_596083, JString, required = false,
                                 default = nil)
  if valid_596083 != nil:
    section.add "X-Amz-Security-Token", valid_596083
  var valid_596084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596084 = validateParameter(valid_596084, JString, required = false,
                                 default = nil)
  if valid_596084 != nil:
    section.add "X-Amz-Content-Sha256", valid_596084
  var valid_596085 = header.getOrDefault("X-Amz-Algorithm")
  valid_596085 = validateParameter(valid_596085, JString, required = false,
                                 default = nil)
  if valid_596085 != nil:
    section.add "X-Amz-Algorithm", valid_596085
  var valid_596086 = header.getOrDefault("X-Amz-Signature")
  valid_596086 = validateParameter(valid_596086, JString, required = false,
                                 default = nil)
  if valid_596086 != nil:
    section.add "X-Amz-Signature", valid_596086
  var valid_596087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596087 = validateParameter(valid_596087, JString, required = false,
                                 default = nil)
  if valid_596087 != nil:
    section.add "X-Amz-SignedHeaders", valid_596087
  var valid_596088 = header.getOrDefault("X-Amz-Credential")
  valid_596088 = validateParameter(valid_596088, JString, required = false,
                                 default = nil)
  if valid_596088 != nil:
    section.add "X-Amz-Credential", valid_596088
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_596089 = formData.getOrDefault("DBParameterGroupName")
  valid_596089 = validateParameter(valid_596089, JString, required = true,
                                 default = nil)
  if valid_596089 != nil:
    section.add "DBParameterGroupName", valid_596089
  var valid_596090 = formData.getOrDefault("Parameters")
  valid_596090 = validateParameter(valid_596090, JArray, required = false,
                                 default = nil)
  if valid_596090 != nil:
    section.add "Parameters", valid_596090
  var valid_596091 = formData.getOrDefault("ResetAllParameters")
  valid_596091 = validateParameter(valid_596091, JBool, required = false, default = nil)
  if valid_596091 != nil:
    section.add "ResetAllParameters", valid_596091
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596092: Call_PostResetDBParameterGroup_596077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_596092.validator(path, query, header, formData, body)
  let scheme = call_596092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596092.url(scheme.get, call_596092.host, call_596092.base,
                         call_596092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596092, url, valid)

proc call*(call_596093: Call_PostResetDBParameterGroup_596077;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_596094 = newJObject()
  var formData_596095 = newJObject()
  add(formData_596095, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_596095.add "Parameters", Parameters
  add(query_596094, "Action", newJString(Action))
  add(formData_596095, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_596094, "Version", newJString(Version))
  result = call_596093.call(nil, query_596094, nil, formData_596095, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_596077(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_596078, base: "/",
    url: url_PostResetDBParameterGroup_596079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_596059 = ref object of OpenApiRestCall_593421
proc url_GetResetDBParameterGroup_596061(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_596060(path: JsonNode; query: JsonNode;
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
  var valid_596062 = query.getOrDefault("DBParameterGroupName")
  valid_596062 = validateParameter(valid_596062, JString, required = true,
                                 default = nil)
  if valid_596062 != nil:
    section.add "DBParameterGroupName", valid_596062
  var valid_596063 = query.getOrDefault("Parameters")
  valid_596063 = validateParameter(valid_596063, JArray, required = false,
                                 default = nil)
  if valid_596063 != nil:
    section.add "Parameters", valid_596063
  var valid_596064 = query.getOrDefault("Action")
  valid_596064 = validateParameter(valid_596064, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_596064 != nil:
    section.add "Action", valid_596064
  var valid_596065 = query.getOrDefault("ResetAllParameters")
  valid_596065 = validateParameter(valid_596065, JBool, required = false, default = nil)
  if valid_596065 != nil:
    section.add "ResetAllParameters", valid_596065
  var valid_596066 = query.getOrDefault("Version")
  valid_596066 = validateParameter(valid_596066, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_596066 != nil:
    section.add "Version", valid_596066
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
  var valid_596067 = header.getOrDefault("X-Amz-Date")
  valid_596067 = validateParameter(valid_596067, JString, required = false,
                                 default = nil)
  if valid_596067 != nil:
    section.add "X-Amz-Date", valid_596067
  var valid_596068 = header.getOrDefault("X-Amz-Security-Token")
  valid_596068 = validateParameter(valid_596068, JString, required = false,
                                 default = nil)
  if valid_596068 != nil:
    section.add "X-Amz-Security-Token", valid_596068
  var valid_596069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596069 = validateParameter(valid_596069, JString, required = false,
                                 default = nil)
  if valid_596069 != nil:
    section.add "X-Amz-Content-Sha256", valid_596069
  var valid_596070 = header.getOrDefault("X-Amz-Algorithm")
  valid_596070 = validateParameter(valid_596070, JString, required = false,
                                 default = nil)
  if valid_596070 != nil:
    section.add "X-Amz-Algorithm", valid_596070
  var valid_596071 = header.getOrDefault("X-Amz-Signature")
  valid_596071 = validateParameter(valid_596071, JString, required = false,
                                 default = nil)
  if valid_596071 != nil:
    section.add "X-Amz-Signature", valid_596071
  var valid_596072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596072 = validateParameter(valid_596072, JString, required = false,
                                 default = nil)
  if valid_596072 != nil:
    section.add "X-Amz-SignedHeaders", valid_596072
  var valid_596073 = header.getOrDefault("X-Amz-Credential")
  valid_596073 = validateParameter(valid_596073, JString, required = false,
                                 default = nil)
  if valid_596073 != nil:
    section.add "X-Amz-Credential", valid_596073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596074: Call_GetResetDBParameterGroup_596059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_596074.validator(path, query, header, formData, body)
  let scheme = call_596074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596074.url(scheme.get, call_596074.host, call_596074.base,
                         call_596074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596074, url, valid)

proc call*(call_596075: Call_GetResetDBParameterGroup_596059;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_596076 = newJObject()
  add(query_596076, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_596076.add "Parameters", Parameters
  add(query_596076, "Action", newJString(Action))
  add(query_596076, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_596076, "Version", newJString(Version))
  result = call_596075.call(nil, query_596076, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_596059(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_596060, base: "/",
    url: url_GetResetDBParameterGroup_596061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_596129 = ref object of OpenApiRestCall_593421
proc url_PostRestoreDBInstanceFromDBSnapshot_596131(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_596130(path: JsonNode;
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
  var valid_596132 = query.getOrDefault("Action")
  valid_596132 = validateParameter(valid_596132, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_596132 != nil:
    section.add "Action", valid_596132
  var valid_596133 = query.getOrDefault("Version")
  valid_596133 = validateParameter(valid_596133, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_596133 != nil:
    section.add "Version", valid_596133
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
  var valid_596134 = header.getOrDefault("X-Amz-Date")
  valid_596134 = validateParameter(valid_596134, JString, required = false,
                                 default = nil)
  if valid_596134 != nil:
    section.add "X-Amz-Date", valid_596134
  var valid_596135 = header.getOrDefault("X-Amz-Security-Token")
  valid_596135 = validateParameter(valid_596135, JString, required = false,
                                 default = nil)
  if valid_596135 != nil:
    section.add "X-Amz-Security-Token", valid_596135
  var valid_596136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596136 = validateParameter(valid_596136, JString, required = false,
                                 default = nil)
  if valid_596136 != nil:
    section.add "X-Amz-Content-Sha256", valid_596136
  var valid_596137 = header.getOrDefault("X-Amz-Algorithm")
  valid_596137 = validateParameter(valid_596137, JString, required = false,
                                 default = nil)
  if valid_596137 != nil:
    section.add "X-Amz-Algorithm", valid_596137
  var valid_596138 = header.getOrDefault("X-Amz-Signature")
  valid_596138 = validateParameter(valid_596138, JString, required = false,
                                 default = nil)
  if valid_596138 != nil:
    section.add "X-Amz-Signature", valid_596138
  var valid_596139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596139 = validateParameter(valid_596139, JString, required = false,
                                 default = nil)
  if valid_596139 != nil:
    section.add "X-Amz-SignedHeaders", valid_596139
  var valid_596140 = header.getOrDefault("X-Amz-Credential")
  valid_596140 = validateParameter(valid_596140, JString, required = false,
                                 default = nil)
  if valid_596140 != nil:
    section.add "X-Amz-Credential", valid_596140
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   Engine: JString
  ##   Iops: JInt
  ##   DBName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   OptionGroupName: JString
  ##   Tags: JArray
  ##   TdeCredentialArn: JString
  ##   DBSubnetGroupName: JString
  ##   TdeCredentialPassword: JString
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   DBSnapshotIdentifier: JString (required)
  ##   PubliclyAccessible: JBool
  ##   StorageType: JString
  ##   DBInstanceClass: JString
  ##   LicenseModel: JString
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_596141 = formData.getOrDefault("Port")
  valid_596141 = validateParameter(valid_596141, JInt, required = false, default = nil)
  if valid_596141 != nil:
    section.add "Port", valid_596141
  var valid_596142 = formData.getOrDefault("Engine")
  valid_596142 = validateParameter(valid_596142, JString, required = false,
                                 default = nil)
  if valid_596142 != nil:
    section.add "Engine", valid_596142
  var valid_596143 = formData.getOrDefault("Iops")
  valid_596143 = validateParameter(valid_596143, JInt, required = false, default = nil)
  if valid_596143 != nil:
    section.add "Iops", valid_596143
  var valid_596144 = formData.getOrDefault("DBName")
  valid_596144 = validateParameter(valid_596144, JString, required = false,
                                 default = nil)
  if valid_596144 != nil:
    section.add "DBName", valid_596144
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_596145 = formData.getOrDefault("DBInstanceIdentifier")
  valid_596145 = validateParameter(valid_596145, JString, required = true,
                                 default = nil)
  if valid_596145 != nil:
    section.add "DBInstanceIdentifier", valid_596145
  var valid_596146 = formData.getOrDefault("OptionGroupName")
  valid_596146 = validateParameter(valid_596146, JString, required = false,
                                 default = nil)
  if valid_596146 != nil:
    section.add "OptionGroupName", valid_596146
  var valid_596147 = formData.getOrDefault("Tags")
  valid_596147 = validateParameter(valid_596147, JArray, required = false,
                                 default = nil)
  if valid_596147 != nil:
    section.add "Tags", valid_596147
  var valid_596148 = formData.getOrDefault("TdeCredentialArn")
  valid_596148 = validateParameter(valid_596148, JString, required = false,
                                 default = nil)
  if valid_596148 != nil:
    section.add "TdeCredentialArn", valid_596148
  var valid_596149 = formData.getOrDefault("DBSubnetGroupName")
  valid_596149 = validateParameter(valid_596149, JString, required = false,
                                 default = nil)
  if valid_596149 != nil:
    section.add "DBSubnetGroupName", valid_596149
  var valid_596150 = formData.getOrDefault("TdeCredentialPassword")
  valid_596150 = validateParameter(valid_596150, JString, required = false,
                                 default = nil)
  if valid_596150 != nil:
    section.add "TdeCredentialPassword", valid_596150
  var valid_596151 = formData.getOrDefault("AvailabilityZone")
  valid_596151 = validateParameter(valid_596151, JString, required = false,
                                 default = nil)
  if valid_596151 != nil:
    section.add "AvailabilityZone", valid_596151
  var valid_596152 = formData.getOrDefault("MultiAZ")
  valid_596152 = validateParameter(valid_596152, JBool, required = false, default = nil)
  if valid_596152 != nil:
    section.add "MultiAZ", valid_596152
  var valid_596153 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_596153 = validateParameter(valid_596153, JString, required = true,
                                 default = nil)
  if valid_596153 != nil:
    section.add "DBSnapshotIdentifier", valid_596153
  var valid_596154 = formData.getOrDefault("PubliclyAccessible")
  valid_596154 = validateParameter(valid_596154, JBool, required = false, default = nil)
  if valid_596154 != nil:
    section.add "PubliclyAccessible", valid_596154
  var valid_596155 = formData.getOrDefault("StorageType")
  valid_596155 = validateParameter(valid_596155, JString, required = false,
                                 default = nil)
  if valid_596155 != nil:
    section.add "StorageType", valid_596155
  var valid_596156 = formData.getOrDefault("DBInstanceClass")
  valid_596156 = validateParameter(valid_596156, JString, required = false,
                                 default = nil)
  if valid_596156 != nil:
    section.add "DBInstanceClass", valid_596156
  var valid_596157 = formData.getOrDefault("LicenseModel")
  valid_596157 = validateParameter(valid_596157, JString, required = false,
                                 default = nil)
  if valid_596157 != nil:
    section.add "LicenseModel", valid_596157
  var valid_596158 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_596158 = validateParameter(valid_596158, JBool, required = false, default = nil)
  if valid_596158 != nil:
    section.add "AutoMinorVersionUpgrade", valid_596158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596159: Call_PostRestoreDBInstanceFromDBSnapshot_596129;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596159.validator(path, query, header, formData, body)
  let scheme = call_596159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596159.url(scheme.get, call_596159.host, call_596159.base,
                         call_596159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596159, url, valid)

proc call*(call_596160: Call_PostRestoreDBInstanceFromDBSnapshot_596129;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          Engine: string = ""; Iops: int = 0; DBName: string = "";
          OptionGroupName: string = ""; Tags: JsonNode = nil;
          TdeCredentialArn: string = ""; DBSubnetGroupName: string = "";
          TdeCredentialPassword: string = ""; AvailabilityZone: string = "";
          MultiAZ: bool = false; Action: string = "RestoreDBInstanceFromDBSnapshot";
          PubliclyAccessible: bool = false; StorageType: string = "";
          DBInstanceClass: string = ""; LicenseModel: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postRestoreDBInstanceFromDBSnapshot
  ##   Port: int
  ##   Engine: string
  ##   Iops: int
  ##   DBName: string
  ##   DBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
  ##   Tags: JArray
  ##   TdeCredentialArn: string
  ##   DBSubnetGroupName: string
  ##   TdeCredentialPassword: string
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   PubliclyAccessible: bool
  ##   StorageType: string
  ##   DBInstanceClass: string
  ##   LicenseModel: string
  ##   AutoMinorVersionUpgrade: bool
  ##   Version: string (required)
  var query_596161 = newJObject()
  var formData_596162 = newJObject()
  add(formData_596162, "Port", newJInt(Port))
  add(formData_596162, "Engine", newJString(Engine))
  add(formData_596162, "Iops", newJInt(Iops))
  add(formData_596162, "DBName", newJString(DBName))
  add(formData_596162, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_596162, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_596162.add "Tags", Tags
  add(formData_596162, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_596162, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_596162, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_596162, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_596162, "MultiAZ", newJBool(MultiAZ))
  add(formData_596162, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_596161, "Action", newJString(Action))
  add(formData_596162, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_596162, "StorageType", newJString(StorageType))
  add(formData_596162, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_596162, "LicenseModel", newJString(LicenseModel))
  add(formData_596162, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_596161, "Version", newJString(Version))
  result = call_596160.call(nil, query_596161, nil, formData_596162, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_596129(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_596130, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_596131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_596096 = ref object of OpenApiRestCall_593421
proc url_GetRestoreDBInstanceFromDBSnapshot_596098(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_596097(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString
  ##   StorageType: JString
  ##   OptionGroupName: JString
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   MultiAZ: JBool
  ##   TdeCredentialPassword: JString
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBName: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##   TdeCredentialArn: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  var valid_596099 = query.getOrDefault("Engine")
  valid_596099 = validateParameter(valid_596099, JString, required = false,
                                 default = nil)
  if valid_596099 != nil:
    section.add "Engine", valid_596099
  var valid_596100 = query.getOrDefault("StorageType")
  valid_596100 = validateParameter(valid_596100, JString, required = false,
                                 default = nil)
  if valid_596100 != nil:
    section.add "StorageType", valid_596100
  var valid_596101 = query.getOrDefault("OptionGroupName")
  valid_596101 = validateParameter(valid_596101, JString, required = false,
                                 default = nil)
  if valid_596101 != nil:
    section.add "OptionGroupName", valid_596101
  var valid_596102 = query.getOrDefault("AvailabilityZone")
  valid_596102 = validateParameter(valid_596102, JString, required = false,
                                 default = nil)
  if valid_596102 != nil:
    section.add "AvailabilityZone", valid_596102
  var valid_596103 = query.getOrDefault("Iops")
  valid_596103 = validateParameter(valid_596103, JInt, required = false, default = nil)
  if valid_596103 != nil:
    section.add "Iops", valid_596103
  var valid_596104 = query.getOrDefault("MultiAZ")
  valid_596104 = validateParameter(valid_596104, JBool, required = false, default = nil)
  if valid_596104 != nil:
    section.add "MultiAZ", valid_596104
  var valid_596105 = query.getOrDefault("TdeCredentialPassword")
  valid_596105 = validateParameter(valid_596105, JString, required = false,
                                 default = nil)
  if valid_596105 != nil:
    section.add "TdeCredentialPassword", valid_596105
  var valid_596106 = query.getOrDefault("LicenseModel")
  valid_596106 = validateParameter(valid_596106, JString, required = false,
                                 default = nil)
  if valid_596106 != nil:
    section.add "LicenseModel", valid_596106
  var valid_596107 = query.getOrDefault("Tags")
  valid_596107 = validateParameter(valid_596107, JArray, required = false,
                                 default = nil)
  if valid_596107 != nil:
    section.add "Tags", valid_596107
  var valid_596108 = query.getOrDefault("DBName")
  valid_596108 = validateParameter(valid_596108, JString, required = false,
                                 default = nil)
  if valid_596108 != nil:
    section.add "DBName", valid_596108
  var valid_596109 = query.getOrDefault("DBInstanceClass")
  valid_596109 = validateParameter(valid_596109, JString, required = false,
                                 default = nil)
  if valid_596109 != nil:
    section.add "DBInstanceClass", valid_596109
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_596110 = query.getOrDefault("Action")
  valid_596110 = validateParameter(valid_596110, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_596110 != nil:
    section.add "Action", valid_596110
  var valid_596111 = query.getOrDefault("DBSubnetGroupName")
  valid_596111 = validateParameter(valid_596111, JString, required = false,
                                 default = nil)
  if valid_596111 != nil:
    section.add "DBSubnetGroupName", valid_596111
  var valid_596112 = query.getOrDefault("TdeCredentialArn")
  valid_596112 = validateParameter(valid_596112, JString, required = false,
                                 default = nil)
  if valid_596112 != nil:
    section.add "TdeCredentialArn", valid_596112
  var valid_596113 = query.getOrDefault("PubliclyAccessible")
  valid_596113 = validateParameter(valid_596113, JBool, required = false, default = nil)
  if valid_596113 != nil:
    section.add "PubliclyAccessible", valid_596113
  var valid_596114 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_596114 = validateParameter(valid_596114, JBool, required = false, default = nil)
  if valid_596114 != nil:
    section.add "AutoMinorVersionUpgrade", valid_596114
  var valid_596115 = query.getOrDefault("Port")
  valid_596115 = validateParameter(valid_596115, JInt, required = false, default = nil)
  if valid_596115 != nil:
    section.add "Port", valid_596115
  var valid_596116 = query.getOrDefault("Version")
  valid_596116 = validateParameter(valid_596116, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_596116 != nil:
    section.add "Version", valid_596116
  var valid_596117 = query.getOrDefault("DBInstanceIdentifier")
  valid_596117 = validateParameter(valid_596117, JString, required = true,
                                 default = nil)
  if valid_596117 != nil:
    section.add "DBInstanceIdentifier", valid_596117
  var valid_596118 = query.getOrDefault("DBSnapshotIdentifier")
  valid_596118 = validateParameter(valid_596118, JString, required = true,
                                 default = nil)
  if valid_596118 != nil:
    section.add "DBSnapshotIdentifier", valid_596118
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
  var valid_596119 = header.getOrDefault("X-Amz-Date")
  valid_596119 = validateParameter(valid_596119, JString, required = false,
                                 default = nil)
  if valid_596119 != nil:
    section.add "X-Amz-Date", valid_596119
  var valid_596120 = header.getOrDefault("X-Amz-Security-Token")
  valid_596120 = validateParameter(valid_596120, JString, required = false,
                                 default = nil)
  if valid_596120 != nil:
    section.add "X-Amz-Security-Token", valid_596120
  var valid_596121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596121 = validateParameter(valid_596121, JString, required = false,
                                 default = nil)
  if valid_596121 != nil:
    section.add "X-Amz-Content-Sha256", valid_596121
  var valid_596122 = header.getOrDefault("X-Amz-Algorithm")
  valid_596122 = validateParameter(valid_596122, JString, required = false,
                                 default = nil)
  if valid_596122 != nil:
    section.add "X-Amz-Algorithm", valid_596122
  var valid_596123 = header.getOrDefault("X-Amz-Signature")
  valid_596123 = validateParameter(valid_596123, JString, required = false,
                                 default = nil)
  if valid_596123 != nil:
    section.add "X-Amz-Signature", valid_596123
  var valid_596124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596124 = validateParameter(valid_596124, JString, required = false,
                                 default = nil)
  if valid_596124 != nil:
    section.add "X-Amz-SignedHeaders", valid_596124
  var valid_596125 = header.getOrDefault("X-Amz-Credential")
  valid_596125 = validateParameter(valid_596125, JString, required = false,
                                 default = nil)
  if valid_596125 != nil:
    section.add "X-Amz-Credential", valid_596125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596126: Call_GetRestoreDBInstanceFromDBSnapshot_596096;
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

proc call*(call_596127: Call_GetRestoreDBInstanceFromDBSnapshot_596096;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Engine: string = ""; StorageType: string = ""; OptionGroupName: string = "";
          AvailabilityZone: string = ""; Iops: int = 0; MultiAZ: bool = false;
          TdeCredentialPassword: string = ""; LicenseModel: string = "";
          Tags: JsonNode = nil; DBName: string = ""; DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          DBSubnetGroupName: string = ""; TdeCredentialArn: string = "";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Port: int = 0; Version: string = "2014-09-01"): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   Engine: string
  ##   StorageType: string
  ##   OptionGroupName: string
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   MultiAZ: bool
  ##   TdeCredentialPassword: string
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBName: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_596128 = newJObject()
  add(query_596128, "Engine", newJString(Engine))
  add(query_596128, "StorageType", newJString(StorageType))
  add(query_596128, "OptionGroupName", newJString(OptionGroupName))
  add(query_596128, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_596128, "Iops", newJInt(Iops))
  add(query_596128, "MultiAZ", newJBool(MultiAZ))
  add(query_596128, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_596128, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_596128.add "Tags", Tags
  add(query_596128, "DBName", newJString(DBName))
  add(query_596128, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_596128, "Action", newJString(Action))
  add(query_596128, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_596128, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_596128, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_596128, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_596128, "Port", newJInt(Port))
  add(query_596128, "Version", newJString(Version))
  add(query_596128, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_596128, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_596127.call(nil, query_596128, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_596096(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_596097, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_596098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_596198 = ref object of OpenApiRestCall_593421
proc url_PostRestoreDBInstanceToPointInTime_596200(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_596199(path: JsonNode;
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
  var valid_596201 = query.getOrDefault("Action")
  valid_596201 = validateParameter(valid_596201, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_596201 != nil:
    section.add "Action", valid_596201
  var valid_596202 = query.getOrDefault("Version")
  valid_596202 = validateParameter(valid_596202, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_596202 != nil:
    section.add "Version", valid_596202
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
  var valid_596203 = header.getOrDefault("X-Amz-Date")
  valid_596203 = validateParameter(valid_596203, JString, required = false,
                                 default = nil)
  if valid_596203 != nil:
    section.add "X-Amz-Date", valid_596203
  var valid_596204 = header.getOrDefault("X-Amz-Security-Token")
  valid_596204 = validateParameter(valid_596204, JString, required = false,
                                 default = nil)
  if valid_596204 != nil:
    section.add "X-Amz-Security-Token", valid_596204
  var valid_596205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596205 = validateParameter(valid_596205, JString, required = false,
                                 default = nil)
  if valid_596205 != nil:
    section.add "X-Amz-Content-Sha256", valid_596205
  var valid_596206 = header.getOrDefault("X-Amz-Algorithm")
  valid_596206 = validateParameter(valid_596206, JString, required = false,
                                 default = nil)
  if valid_596206 != nil:
    section.add "X-Amz-Algorithm", valid_596206
  var valid_596207 = header.getOrDefault("X-Amz-Signature")
  valid_596207 = validateParameter(valid_596207, JString, required = false,
                                 default = nil)
  if valid_596207 != nil:
    section.add "X-Amz-Signature", valid_596207
  var valid_596208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596208 = validateParameter(valid_596208, JString, required = false,
                                 default = nil)
  if valid_596208 != nil:
    section.add "X-Amz-SignedHeaders", valid_596208
  var valid_596209 = header.getOrDefault("X-Amz-Credential")
  valid_596209 = validateParameter(valid_596209, JString, required = false,
                                 default = nil)
  if valid_596209 != nil:
    section.add "X-Amz-Credential", valid_596209
  result.add "header", section
  ## parameters in `formData` object:
  ##   UseLatestRestorableTime: JBool
  ##   Port: JInt
  ##   Engine: JString
  ##   Iops: JInt
  ##   DBName: JString
  ##   OptionGroupName: JString
  ##   Tags: JArray
  ##   TdeCredentialArn: JString
  ##   DBSubnetGroupName: JString
  ##   TdeCredentialPassword: JString
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   RestoreTime: JString
  ##   PubliclyAccessible: JBool
  ##   StorageType: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   DBInstanceClass: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   LicenseModel: JString
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_596210 = formData.getOrDefault("UseLatestRestorableTime")
  valid_596210 = validateParameter(valid_596210, JBool, required = false, default = nil)
  if valid_596210 != nil:
    section.add "UseLatestRestorableTime", valid_596210
  var valid_596211 = formData.getOrDefault("Port")
  valid_596211 = validateParameter(valid_596211, JInt, required = false, default = nil)
  if valid_596211 != nil:
    section.add "Port", valid_596211
  var valid_596212 = formData.getOrDefault("Engine")
  valid_596212 = validateParameter(valid_596212, JString, required = false,
                                 default = nil)
  if valid_596212 != nil:
    section.add "Engine", valid_596212
  var valid_596213 = formData.getOrDefault("Iops")
  valid_596213 = validateParameter(valid_596213, JInt, required = false, default = nil)
  if valid_596213 != nil:
    section.add "Iops", valid_596213
  var valid_596214 = formData.getOrDefault("DBName")
  valid_596214 = validateParameter(valid_596214, JString, required = false,
                                 default = nil)
  if valid_596214 != nil:
    section.add "DBName", valid_596214
  var valid_596215 = formData.getOrDefault("OptionGroupName")
  valid_596215 = validateParameter(valid_596215, JString, required = false,
                                 default = nil)
  if valid_596215 != nil:
    section.add "OptionGroupName", valid_596215
  var valid_596216 = formData.getOrDefault("Tags")
  valid_596216 = validateParameter(valid_596216, JArray, required = false,
                                 default = nil)
  if valid_596216 != nil:
    section.add "Tags", valid_596216
  var valid_596217 = formData.getOrDefault("TdeCredentialArn")
  valid_596217 = validateParameter(valid_596217, JString, required = false,
                                 default = nil)
  if valid_596217 != nil:
    section.add "TdeCredentialArn", valid_596217
  var valid_596218 = formData.getOrDefault("DBSubnetGroupName")
  valid_596218 = validateParameter(valid_596218, JString, required = false,
                                 default = nil)
  if valid_596218 != nil:
    section.add "DBSubnetGroupName", valid_596218
  var valid_596219 = formData.getOrDefault("TdeCredentialPassword")
  valid_596219 = validateParameter(valid_596219, JString, required = false,
                                 default = nil)
  if valid_596219 != nil:
    section.add "TdeCredentialPassword", valid_596219
  var valid_596220 = formData.getOrDefault("AvailabilityZone")
  valid_596220 = validateParameter(valid_596220, JString, required = false,
                                 default = nil)
  if valid_596220 != nil:
    section.add "AvailabilityZone", valid_596220
  var valid_596221 = formData.getOrDefault("MultiAZ")
  valid_596221 = validateParameter(valid_596221, JBool, required = false, default = nil)
  if valid_596221 != nil:
    section.add "MultiAZ", valid_596221
  var valid_596222 = formData.getOrDefault("RestoreTime")
  valid_596222 = validateParameter(valid_596222, JString, required = false,
                                 default = nil)
  if valid_596222 != nil:
    section.add "RestoreTime", valid_596222
  var valid_596223 = formData.getOrDefault("PubliclyAccessible")
  valid_596223 = validateParameter(valid_596223, JBool, required = false, default = nil)
  if valid_596223 != nil:
    section.add "PubliclyAccessible", valid_596223
  var valid_596224 = formData.getOrDefault("StorageType")
  valid_596224 = validateParameter(valid_596224, JString, required = false,
                                 default = nil)
  if valid_596224 != nil:
    section.add "StorageType", valid_596224
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_596225 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_596225 = validateParameter(valid_596225, JString, required = true,
                                 default = nil)
  if valid_596225 != nil:
    section.add "TargetDBInstanceIdentifier", valid_596225
  var valid_596226 = formData.getOrDefault("DBInstanceClass")
  valid_596226 = validateParameter(valid_596226, JString, required = false,
                                 default = nil)
  if valid_596226 != nil:
    section.add "DBInstanceClass", valid_596226
  var valid_596227 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_596227 = validateParameter(valid_596227, JString, required = true,
                                 default = nil)
  if valid_596227 != nil:
    section.add "SourceDBInstanceIdentifier", valid_596227
  var valid_596228 = formData.getOrDefault("LicenseModel")
  valid_596228 = validateParameter(valid_596228, JString, required = false,
                                 default = nil)
  if valid_596228 != nil:
    section.add "LicenseModel", valid_596228
  var valid_596229 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_596229 = validateParameter(valid_596229, JBool, required = false, default = nil)
  if valid_596229 != nil:
    section.add "AutoMinorVersionUpgrade", valid_596229
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596230: Call_PostRestoreDBInstanceToPointInTime_596198;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596230.validator(path, query, header, formData, body)
  let scheme = call_596230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596230.url(scheme.get, call_596230.host, call_596230.base,
                         call_596230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596230, url, valid)

proc call*(call_596231: Call_PostRestoreDBInstanceToPointInTime_596198;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          UseLatestRestorableTime: bool = false; Port: int = 0; Engine: string = "";
          Iops: int = 0; DBName: string = ""; OptionGroupName: string = "";
          Tags: JsonNode = nil; TdeCredentialArn: string = "";
          DBSubnetGroupName: string = ""; TdeCredentialPassword: string = "";
          AvailabilityZone: string = ""; MultiAZ: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          RestoreTime: string = ""; PubliclyAccessible: bool = false;
          StorageType: string = ""; DBInstanceClass: string = "";
          LicenseModel: string = ""; AutoMinorVersionUpgrade: bool = false;
          Version: string = "2014-09-01"): Recallable =
  ## postRestoreDBInstanceToPointInTime
  ##   UseLatestRestorableTime: bool
  ##   Port: int
  ##   Engine: string
  ##   Iops: int
  ##   DBName: string
  ##   OptionGroupName: string
  ##   Tags: JArray
  ##   TdeCredentialArn: string
  ##   DBSubnetGroupName: string
  ##   TdeCredentialPassword: string
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   RestoreTime: string
  ##   PubliclyAccessible: bool
  ##   StorageType: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   DBInstanceClass: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   LicenseModel: string
  ##   AutoMinorVersionUpgrade: bool
  ##   Version: string (required)
  var query_596232 = newJObject()
  var formData_596233 = newJObject()
  add(formData_596233, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_596233, "Port", newJInt(Port))
  add(formData_596233, "Engine", newJString(Engine))
  add(formData_596233, "Iops", newJInt(Iops))
  add(formData_596233, "DBName", newJString(DBName))
  add(formData_596233, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_596233.add "Tags", Tags
  add(formData_596233, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_596233, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_596233, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_596233, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_596233, "MultiAZ", newJBool(MultiAZ))
  add(query_596232, "Action", newJString(Action))
  add(formData_596233, "RestoreTime", newJString(RestoreTime))
  add(formData_596233, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_596233, "StorageType", newJString(StorageType))
  add(formData_596233, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_596233, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_596233, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_596233, "LicenseModel", newJString(LicenseModel))
  add(formData_596233, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_596232, "Version", newJString(Version))
  result = call_596231.call(nil, query_596232, nil, formData_596233, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_596198(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_596199, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_596200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_596163 = ref object of OpenApiRestCall_593421
proc url_GetRestoreDBInstanceToPointInTime_596165(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_596164(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   StorageType: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   OptionGroupName: JString
  ##   RestoreTime: JString
  ##   MultiAZ: JBool
  ##   TdeCredentialPassword: JString
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBName: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   UseLatestRestorableTime: JBool
  ##   DBSubnetGroupName: JString
  ##   TdeCredentialArn: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Version: JString (required)
  section = newJObject()
  var valid_596166 = query.getOrDefault("Engine")
  valid_596166 = validateParameter(valid_596166, JString, required = false,
                                 default = nil)
  if valid_596166 != nil:
    section.add "Engine", valid_596166
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_596167 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_596167 = validateParameter(valid_596167, JString, required = true,
                                 default = nil)
  if valid_596167 != nil:
    section.add "SourceDBInstanceIdentifier", valid_596167
  var valid_596168 = query.getOrDefault("StorageType")
  valid_596168 = validateParameter(valid_596168, JString, required = false,
                                 default = nil)
  if valid_596168 != nil:
    section.add "StorageType", valid_596168
  var valid_596169 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_596169 = validateParameter(valid_596169, JString, required = true,
                                 default = nil)
  if valid_596169 != nil:
    section.add "TargetDBInstanceIdentifier", valid_596169
  var valid_596170 = query.getOrDefault("AvailabilityZone")
  valid_596170 = validateParameter(valid_596170, JString, required = false,
                                 default = nil)
  if valid_596170 != nil:
    section.add "AvailabilityZone", valid_596170
  var valid_596171 = query.getOrDefault("Iops")
  valid_596171 = validateParameter(valid_596171, JInt, required = false, default = nil)
  if valid_596171 != nil:
    section.add "Iops", valid_596171
  var valid_596172 = query.getOrDefault("OptionGroupName")
  valid_596172 = validateParameter(valid_596172, JString, required = false,
                                 default = nil)
  if valid_596172 != nil:
    section.add "OptionGroupName", valid_596172
  var valid_596173 = query.getOrDefault("RestoreTime")
  valid_596173 = validateParameter(valid_596173, JString, required = false,
                                 default = nil)
  if valid_596173 != nil:
    section.add "RestoreTime", valid_596173
  var valid_596174 = query.getOrDefault("MultiAZ")
  valid_596174 = validateParameter(valid_596174, JBool, required = false, default = nil)
  if valid_596174 != nil:
    section.add "MultiAZ", valid_596174
  var valid_596175 = query.getOrDefault("TdeCredentialPassword")
  valid_596175 = validateParameter(valid_596175, JString, required = false,
                                 default = nil)
  if valid_596175 != nil:
    section.add "TdeCredentialPassword", valid_596175
  var valid_596176 = query.getOrDefault("LicenseModel")
  valid_596176 = validateParameter(valid_596176, JString, required = false,
                                 default = nil)
  if valid_596176 != nil:
    section.add "LicenseModel", valid_596176
  var valid_596177 = query.getOrDefault("Tags")
  valid_596177 = validateParameter(valid_596177, JArray, required = false,
                                 default = nil)
  if valid_596177 != nil:
    section.add "Tags", valid_596177
  var valid_596178 = query.getOrDefault("DBName")
  valid_596178 = validateParameter(valid_596178, JString, required = false,
                                 default = nil)
  if valid_596178 != nil:
    section.add "DBName", valid_596178
  var valid_596179 = query.getOrDefault("DBInstanceClass")
  valid_596179 = validateParameter(valid_596179, JString, required = false,
                                 default = nil)
  if valid_596179 != nil:
    section.add "DBInstanceClass", valid_596179
  var valid_596180 = query.getOrDefault("Action")
  valid_596180 = validateParameter(valid_596180, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_596180 != nil:
    section.add "Action", valid_596180
  var valid_596181 = query.getOrDefault("UseLatestRestorableTime")
  valid_596181 = validateParameter(valid_596181, JBool, required = false, default = nil)
  if valid_596181 != nil:
    section.add "UseLatestRestorableTime", valid_596181
  var valid_596182 = query.getOrDefault("DBSubnetGroupName")
  valid_596182 = validateParameter(valid_596182, JString, required = false,
                                 default = nil)
  if valid_596182 != nil:
    section.add "DBSubnetGroupName", valid_596182
  var valid_596183 = query.getOrDefault("TdeCredentialArn")
  valid_596183 = validateParameter(valid_596183, JString, required = false,
                                 default = nil)
  if valid_596183 != nil:
    section.add "TdeCredentialArn", valid_596183
  var valid_596184 = query.getOrDefault("PubliclyAccessible")
  valid_596184 = validateParameter(valid_596184, JBool, required = false, default = nil)
  if valid_596184 != nil:
    section.add "PubliclyAccessible", valid_596184
  var valid_596185 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_596185 = validateParameter(valid_596185, JBool, required = false, default = nil)
  if valid_596185 != nil:
    section.add "AutoMinorVersionUpgrade", valid_596185
  var valid_596186 = query.getOrDefault("Port")
  valid_596186 = validateParameter(valid_596186, JInt, required = false, default = nil)
  if valid_596186 != nil:
    section.add "Port", valid_596186
  var valid_596187 = query.getOrDefault("Version")
  valid_596187 = validateParameter(valid_596187, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_596187 != nil:
    section.add "Version", valid_596187
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
  var valid_596188 = header.getOrDefault("X-Amz-Date")
  valid_596188 = validateParameter(valid_596188, JString, required = false,
                                 default = nil)
  if valid_596188 != nil:
    section.add "X-Amz-Date", valid_596188
  var valid_596189 = header.getOrDefault("X-Amz-Security-Token")
  valid_596189 = validateParameter(valid_596189, JString, required = false,
                                 default = nil)
  if valid_596189 != nil:
    section.add "X-Amz-Security-Token", valid_596189
  var valid_596190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596190 = validateParameter(valid_596190, JString, required = false,
                                 default = nil)
  if valid_596190 != nil:
    section.add "X-Amz-Content-Sha256", valid_596190
  var valid_596191 = header.getOrDefault("X-Amz-Algorithm")
  valid_596191 = validateParameter(valid_596191, JString, required = false,
                                 default = nil)
  if valid_596191 != nil:
    section.add "X-Amz-Algorithm", valid_596191
  var valid_596192 = header.getOrDefault("X-Amz-Signature")
  valid_596192 = validateParameter(valid_596192, JString, required = false,
                                 default = nil)
  if valid_596192 != nil:
    section.add "X-Amz-Signature", valid_596192
  var valid_596193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596193 = validateParameter(valid_596193, JString, required = false,
                                 default = nil)
  if valid_596193 != nil:
    section.add "X-Amz-SignedHeaders", valid_596193
  var valid_596194 = header.getOrDefault("X-Amz-Credential")
  valid_596194 = validateParameter(valid_596194, JString, required = false,
                                 default = nil)
  if valid_596194 != nil:
    section.add "X-Amz-Credential", valid_596194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596195: Call_GetRestoreDBInstanceToPointInTime_596163;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596195.validator(path, query, header, formData, body)
  let scheme = call_596195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596195.url(scheme.get, call_596195.host, call_596195.base,
                         call_596195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596195, url, valid)

proc call*(call_596196: Call_GetRestoreDBInstanceToPointInTime_596163;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Engine: string = ""; StorageType: string = ""; AvailabilityZone: string = "";
          Iops: int = 0; OptionGroupName: string = ""; RestoreTime: string = "";
          MultiAZ: bool = false; TdeCredentialPassword: string = "";
          LicenseModel: string = ""; Tags: JsonNode = nil; DBName: string = "";
          DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceToPointInTime";
          UseLatestRestorableTime: bool = false; DBSubnetGroupName: string = "";
          TdeCredentialArn: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Port: int = 0;
          Version: string = "2014-09-01"): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   Engine: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   StorageType: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   OptionGroupName: string
  ##   RestoreTime: string
  ##   MultiAZ: bool
  ##   TdeCredentialPassword: string
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBName: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   UseLatestRestorableTime: bool
  ##   DBSubnetGroupName: string
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Version: string (required)
  var query_596197 = newJObject()
  add(query_596197, "Engine", newJString(Engine))
  add(query_596197, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_596197, "StorageType", newJString(StorageType))
  add(query_596197, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_596197, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_596197, "Iops", newJInt(Iops))
  add(query_596197, "OptionGroupName", newJString(OptionGroupName))
  add(query_596197, "RestoreTime", newJString(RestoreTime))
  add(query_596197, "MultiAZ", newJBool(MultiAZ))
  add(query_596197, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_596197, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_596197.add "Tags", Tags
  add(query_596197, "DBName", newJString(DBName))
  add(query_596197, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_596197, "Action", newJString(Action))
  add(query_596197, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_596197, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_596197, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_596197, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_596197, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_596197, "Port", newJInt(Port))
  add(query_596197, "Version", newJString(Version))
  result = call_596196.call(nil, query_596197, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_596163(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_596164, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_596165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_596254 = ref object of OpenApiRestCall_593421
proc url_PostRevokeDBSecurityGroupIngress_596256(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_596255(path: JsonNode;
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
  var valid_596257 = query.getOrDefault("Action")
  valid_596257 = validateParameter(valid_596257, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_596257 != nil:
    section.add "Action", valid_596257
  var valid_596258 = query.getOrDefault("Version")
  valid_596258 = validateParameter(valid_596258, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_596258 != nil:
    section.add "Version", valid_596258
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
  var valid_596259 = header.getOrDefault("X-Amz-Date")
  valid_596259 = validateParameter(valid_596259, JString, required = false,
                                 default = nil)
  if valid_596259 != nil:
    section.add "X-Amz-Date", valid_596259
  var valid_596260 = header.getOrDefault("X-Amz-Security-Token")
  valid_596260 = validateParameter(valid_596260, JString, required = false,
                                 default = nil)
  if valid_596260 != nil:
    section.add "X-Amz-Security-Token", valid_596260
  var valid_596261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596261 = validateParameter(valid_596261, JString, required = false,
                                 default = nil)
  if valid_596261 != nil:
    section.add "X-Amz-Content-Sha256", valid_596261
  var valid_596262 = header.getOrDefault("X-Amz-Algorithm")
  valid_596262 = validateParameter(valid_596262, JString, required = false,
                                 default = nil)
  if valid_596262 != nil:
    section.add "X-Amz-Algorithm", valid_596262
  var valid_596263 = header.getOrDefault("X-Amz-Signature")
  valid_596263 = validateParameter(valid_596263, JString, required = false,
                                 default = nil)
  if valid_596263 != nil:
    section.add "X-Amz-Signature", valid_596263
  var valid_596264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596264 = validateParameter(valid_596264, JString, required = false,
                                 default = nil)
  if valid_596264 != nil:
    section.add "X-Amz-SignedHeaders", valid_596264
  var valid_596265 = header.getOrDefault("X-Amz-Credential")
  valid_596265 = validateParameter(valid_596265, JString, required = false,
                                 default = nil)
  if valid_596265 != nil:
    section.add "X-Amz-Credential", valid_596265
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_596266 = formData.getOrDefault("DBSecurityGroupName")
  valid_596266 = validateParameter(valid_596266, JString, required = true,
                                 default = nil)
  if valid_596266 != nil:
    section.add "DBSecurityGroupName", valid_596266
  var valid_596267 = formData.getOrDefault("EC2SecurityGroupName")
  valid_596267 = validateParameter(valid_596267, JString, required = false,
                                 default = nil)
  if valid_596267 != nil:
    section.add "EC2SecurityGroupName", valid_596267
  var valid_596268 = formData.getOrDefault("EC2SecurityGroupId")
  valid_596268 = validateParameter(valid_596268, JString, required = false,
                                 default = nil)
  if valid_596268 != nil:
    section.add "EC2SecurityGroupId", valid_596268
  var valid_596269 = formData.getOrDefault("CIDRIP")
  valid_596269 = validateParameter(valid_596269, JString, required = false,
                                 default = nil)
  if valid_596269 != nil:
    section.add "CIDRIP", valid_596269
  var valid_596270 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_596270 = validateParameter(valid_596270, JString, required = false,
                                 default = nil)
  if valid_596270 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_596270
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596271: Call_PostRevokeDBSecurityGroupIngress_596254;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596271.validator(path, query, header, formData, body)
  let scheme = call_596271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596271.url(scheme.get, call_596271.host, call_596271.base,
                         call_596271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596271, url, valid)

proc call*(call_596272: Call_PostRevokeDBSecurityGroupIngress_596254;
          DBSecurityGroupName: string;
          Action: string = "RevokeDBSecurityGroupIngress";
          EC2SecurityGroupName: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Version: string = "2014-09-01";
          EC2SecurityGroupOwnerId: string = ""): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Version: string (required)
  ##   EC2SecurityGroupOwnerId: string
  var query_596273 = newJObject()
  var formData_596274 = newJObject()
  add(formData_596274, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_596273, "Action", newJString(Action))
  add(formData_596274, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_596274, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_596274, "CIDRIP", newJString(CIDRIP))
  add(query_596273, "Version", newJString(Version))
  add(formData_596274, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_596272.call(nil, query_596273, nil, formData_596274, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_596254(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_596255, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_596256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_596234 = ref object of OpenApiRestCall_593421
proc url_GetRevokeDBSecurityGroupIngress_596236(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_596235(path: JsonNode;
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
  var valid_596237 = query.getOrDefault("EC2SecurityGroupId")
  valid_596237 = validateParameter(valid_596237, JString, required = false,
                                 default = nil)
  if valid_596237 != nil:
    section.add "EC2SecurityGroupId", valid_596237
  var valid_596238 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_596238 = validateParameter(valid_596238, JString, required = false,
                                 default = nil)
  if valid_596238 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_596238
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_596239 = query.getOrDefault("DBSecurityGroupName")
  valid_596239 = validateParameter(valid_596239, JString, required = true,
                                 default = nil)
  if valid_596239 != nil:
    section.add "DBSecurityGroupName", valid_596239
  var valid_596240 = query.getOrDefault("Action")
  valid_596240 = validateParameter(valid_596240, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_596240 != nil:
    section.add "Action", valid_596240
  var valid_596241 = query.getOrDefault("CIDRIP")
  valid_596241 = validateParameter(valid_596241, JString, required = false,
                                 default = nil)
  if valid_596241 != nil:
    section.add "CIDRIP", valid_596241
  var valid_596242 = query.getOrDefault("EC2SecurityGroupName")
  valid_596242 = validateParameter(valid_596242, JString, required = false,
                                 default = nil)
  if valid_596242 != nil:
    section.add "EC2SecurityGroupName", valid_596242
  var valid_596243 = query.getOrDefault("Version")
  valid_596243 = validateParameter(valid_596243, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_596243 != nil:
    section.add "Version", valid_596243
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
  var valid_596244 = header.getOrDefault("X-Amz-Date")
  valid_596244 = validateParameter(valid_596244, JString, required = false,
                                 default = nil)
  if valid_596244 != nil:
    section.add "X-Amz-Date", valid_596244
  var valid_596245 = header.getOrDefault("X-Amz-Security-Token")
  valid_596245 = validateParameter(valid_596245, JString, required = false,
                                 default = nil)
  if valid_596245 != nil:
    section.add "X-Amz-Security-Token", valid_596245
  var valid_596246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596246 = validateParameter(valid_596246, JString, required = false,
                                 default = nil)
  if valid_596246 != nil:
    section.add "X-Amz-Content-Sha256", valid_596246
  var valid_596247 = header.getOrDefault("X-Amz-Algorithm")
  valid_596247 = validateParameter(valid_596247, JString, required = false,
                                 default = nil)
  if valid_596247 != nil:
    section.add "X-Amz-Algorithm", valid_596247
  var valid_596248 = header.getOrDefault("X-Amz-Signature")
  valid_596248 = validateParameter(valid_596248, JString, required = false,
                                 default = nil)
  if valid_596248 != nil:
    section.add "X-Amz-Signature", valid_596248
  var valid_596249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596249 = validateParameter(valid_596249, JString, required = false,
                                 default = nil)
  if valid_596249 != nil:
    section.add "X-Amz-SignedHeaders", valid_596249
  var valid_596250 = header.getOrDefault("X-Amz-Credential")
  valid_596250 = validateParameter(valid_596250, JString, required = false,
                                 default = nil)
  if valid_596250 != nil:
    section.add "X-Amz-Credential", valid_596250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596251: Call_GetRevokeDBSecurityGroupIngress_596234;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596251.validator(path, query, header, formData, body)
  let scheme = call_596251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596251.url(scheme.get, call_596251.host, call_596251.base,
                         call_596251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596251, url, valid)

proc call*(call_596252: Call_GetRevokeDBSecurityGroupIngress_596234;
          DBSecurityGroupName: string; EC2SecurityGroupId: string = "";
          EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress"; CIDRIP: string = "";
          EC2SecurityGroupName: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   CIDRIP: string
  ##   EC2SecurityGroupName: string
  ##   Version: string (required)
  var query_596253 = newJObject()
  add(query_596253, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_596253, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_596253, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_596253, "Action", newJString(Action))
  add(query_596253, "CIDRIP", newJString(CIDRIP))
  add(query_596253, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_596253, "Version", newJString(Version))
  result = call_596252.call(nil, query_596253, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_596234(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_596235, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_596236,
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
