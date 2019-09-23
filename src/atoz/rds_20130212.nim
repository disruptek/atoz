
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600421 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600421](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600421): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  Call_PostAddSourceIdentifierToSubscription_601030 = ref object of OpenApiRestCall_600421
proc url_PostAddSourceIdentifierToSubscription_601032(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddSourceIdentifierToSubscription_601031(path: JsonNode;
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
  var valid_601033 = query.getOrDefault("Action")
  valid_601033 = validateParameter(valid_601033, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_601033 != nil:
    section.add "Action", valid_601033
  var valid_601034 = query.getOrDefault("Version")
  valid_601034 = validateParameter(valid_601034, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601034 != nil:
    section.add "Version", valid_601034
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
  var valid_601035 = header.getOrDefault("X-Amz-Date")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Date", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-Security-Token")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-Security-Token", valid_601036
  var valid_601037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601037 = validateParameter(valid_601037, JString, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "X-Amz-Content-Sha256", valid_601037
  var valid_601038 = header.getOrDefault("X-Amz-Algorithm")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-Algorithm", valid_601038
  var valid_601039 = header.getOrDefault("X-Amz-Signature")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-Signature", valid_601039
  var valid_601040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-SignedHeaders", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Credential")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Credential", valid_601041
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_601042 = formData.getOrDefault("SourceIdentifier")
  valid_601042 = validateParameter(valid_601042, JString, required = true,
                                 default = nil)
  if valid_601042 != nil:
    section.add "SourceIdentifier", valid_601042
  var valid_601043 = formData.getOrDefault("SubscriptionName")
  valid_601043 = validateParameter(valid_601043, JString, required = true,
                                 default = nil)
  if valid_601043 != nil:
    section.add "SubscriptionName", valid_601043
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601044: Call_PostAddSourceIdentifierToSubscription_601030;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601044.validator(path, query, header, formData, body)
  let scheme = call_601044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601044.url(scheme.get, call_601044.host, call_601044.base,
                         call_601044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601044, url, valid)

proc call*(call_601045: Call_PostAddSourceIdentifierToSubscription_601030;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601046 = newJObject()
  var formData_601047 = newJObject()
  add(formData_601047, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_601047, "SubscriptionName", newJString(SubscriptionName))
  add(query_601046, "Action", newJString(Action))
  add(query_601046, "Version", newJString(Version))
  result = call_601045.call(nil, query_601046, nil, formData_601047, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_601030(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_601031, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_601032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_600758 = ref object of OpenApiRestCall_600421
proc url_GetAddSourceIdentifierToSubscription_600760(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddSourceIdentifierToSubscription_600759(path: JsonNode;
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
  var valid_600885 = query.getOrDefault("Action")
  valid_600885 = validateParameter(valid_600885, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_600885 != nil:
    section.add "Action", valid_600885
  var valid_600886 = query.getOrDefault("SourceIdentifier")
  valid_600886 = validateParameter(valid_600886, JString, required = true,
                                 default = nil)
  if valid_600886 != nil:
    section.add "SourceIdentifier", valid_600886
  var valid_600887 = query.getOrDefault("SubscriptionName")
  valid_600887 = validateParameter(valid_600887, JString, required = true,
                                 default = nil)
  if valid_600887 != nil:
    section.add "SubscriptionName", valid_600887
  var valid_600888 = query.getOrDefault("Version")
  valid_600888 = validateParameter(valid_600888, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600888 != nil:
    section.add "Version", valid_600888
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
  var valid_600889 = header.getOrDefault("X-Amz-Date")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Date", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Security-Token")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Security-Token", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Content-Sha256", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Algorithm")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Algorithm", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Signature")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Signature", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-SignedHeaders", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-Credential")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-Credential", valid_600895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600918: Call_GetAddSourceIdentifierToSubscription_600758;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_600918.validator(path, query, header, formData, body)
  let scheme = call_600918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600918.url(scheme.get, call_600918.host, call_600918.base,
                         call_600918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600918, url, valid)

proc call*(call_600989: Call_GetAddSourceIdentifierToSubscription_600758;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_600990 = newJObject()
  add(query_600990, "Action", newJString(Action))
  add(query_600990, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_600990, "SubscriptionName", newJString(SubscriptionName))
  add(query_600990, "Version", newJString(Version))
  result = call_600989.call(nil, query_600990, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_600758(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_600759, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_600760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_601065 = ref object of OpenApiRestCall_600421
proc url_PostAddTagsToResource_601067(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTagsToResource_601066(path: JsonNode; query: JsonNode;
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
  var valid_601068 = query.getOrDefault("Action")
  valid_601068 = validateParameter(valid_601068, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_601068 != nil:
    section.add "Action", valid_601068
  var valid_601069 = query.getOrDefault("Version")
  valid_601069 = validateParameter(valid_601069, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601069 != nil:
    section.add "Version", valid_601069
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
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Content-Sha256", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Algorithm")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Algorithm", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Signature")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Signature", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-SignedHeaders", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Credential")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Credential", valid_601076
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_601077 = formData.getOrDefault("Tags")
  valid_601077 = validateParameter(valid_601077, JArray, required = true, default = nil)
  if valid_601077 != nil:
    section.add "Tags", valid_601077
  var valid_601078 = formData.getOrDefault("ResourceName")
  valid_601078 = validateParameter(valid_601078, JString, required = true,
                                 default = nil)
  if valid_601078 != nil:
    section.add "ResourceName", valid_601078
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_PostAddTagsToResource_601065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_PostAddTagsToResource_601065; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-02-12"): Recallable =
  ## postAddTagsToResource
  ##   Tags: JArray (required)
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_601081 = newJObject()
  var formData_601082 = newJObject()
  if Tags != nil:
    formData_601082.add "Tags", Tags
  add(query_601081, "Action", newJString(Action))
  add(formData_601082, "ResourceName", newJString(ResourceName))
  add(query_601081, "Version", newJString(Version))
  result = call_601080.call(nil, query_601081, nil, formData_601082, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_601065(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_601066, base: "/",
    url: url_PostAddTagsToResource_601067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_601048 = ref object of OpenApiRestCall_600421
proc url_GetAddTagsToResource_601050(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTagsToResource_601049(path: JsonNode; query: JsonNode;
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
  var valid_601051 = query.getOrDefault("Tags")
  valid_601051 = validateParameter(valid_601051, JArray, required = true, default = nil)
  if valid_601051 != nil:
    section.add "Tags", valid_601051
  var valid_601052 = query.getOrDefault("ResourceName")
  valid_601052 = validateParameter(valid_601052, JString, required = true,
                                 default = nil)
  if valid_601052 != nil:
    section.add "ResourceName", valid_601052
  var valid_601053 = query.getOrDefault("Action")
  valid_601053 = validateParameter(valid_601053, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_601053 != nil:
    section.add "Action", valid_601053
  var valid_601054 = query.getOrDefault("Version")
  valid_601054 = validateParameter(valid_601054, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601054 != nil:
    section.add "Version", valid_601054
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
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Content-Sha256", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Algorithm")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Algorithm", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Signature")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Signature", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-SignedHeaders", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Credential")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Credential", valid_601061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601062: Call_GetAddTagsToResource_601048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601062.validator(path, query, header, formData, body)
  let scheme = call_601062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601062.url(scheme.get, call_601062.host, call_601062.base,
                         call_601062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601062, url, valid)

proc call*(call_601063: Call_GetAddTagsToResource_601048; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-02-12"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601064 = newJObject()
  if Tags != nil:
    query_601064.add "Tags", Tags
  add(query_601064, "ResourceName", newJString(ResourceName))
  add(query_601064, "Action", newJString(Action))
  add(query_601064, "Version", newJString(Version))
  result = call_601063.call(nil, query_601064, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_601048(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_601049, base: "/",
    url: url_GetAddTagsToResource_601050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_601103 = ref object of OpenApiRestCall_600421
proc url_PostAuthorizeDBSecurityGroupIngress_601105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_601104(path: JsonNode;
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
  var valid_601106 = query.getOrDefault("Action")
  valid_601106 = validateParameter(valid_601106, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_601106 != nil:
    section.add "Action", valid_601106
  var valid_601107 = query.getOrDefault("Version")
  valid_601107 = validateParameter(valid_601107, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601107 != nil:
    section.add "Version", valid_601107
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
  var valid_601108 = header.getOrDefault("X-Amz-Date")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Date", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Security-Token")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Security-Token", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Content-Sha256", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Algorithm")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Algorithm", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Signature")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Signature", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-SignedHeaders", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Credential")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Credential", valid_601114
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601115 = formData.getOrDefault("DBSecurityGroupName")
  valid_601115 = validateParameter(valid_601115, JString, required = true,
                                 default = nil)
  if valid_601115 != nil:
    section.add "DBSecurityGroupName", valid_601115
  var valid_601116 = formData.getOrDefault("EC2SecurityGroupName")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "EC2SecurityGroupName", valid_601116
  var valid_601117 = formData.getOrDefault("EC2SecurityGroupId")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "EC2SecurityGroupId", valid_601117
  var valid_601118 = formData.getOrDefault("CIDRIP")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "CIDRIP", valid_601118
  var valid_601119 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_601119
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601120: Call_PostAuthorizeDBSecurityGroupIngress_601103;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601120.validator(path, query, header, formData, body)
  let scheme = call_601120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601120.url(scheme.get, call_601120.host, call_601120.base,
                         call_601120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601120, url, valid)

proc call*(call_601121: Call_PostAuthorizeDBSecurityGroupIngress_601103;
          DBSecurityGroupName: string;
          Action: string = "AuthorizeDBSecurityGroupIngress";
          EC2SecurityGroupName: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Version: string = "2013-02-12";
          EC2SecurityGroupOwnerId: string = ""): Recallable =
  ## postAuthorizeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Version: string (required)
  ##   EC2SecurityGroupOwnerId: string
  var query_601122 = newJObject()
  var formData_601123 = newJObject()
  add(formData_601123, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601122, "Action", newJString(Action))
  add(formData_601123, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_601123, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_601123, "CIDRIP", newJString(CIDRIP))
  add(query_601122, "Version", newJString(Version))
  add(formData_601123, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_601121.call(nil, query_601122, nil, formData_601123, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_601103(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_601104, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_601105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_601083 = ref object of OpenApiRestCall_600421
proc url_GetAuthorizeDBSecurityGroupIngress_601085(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_601084(path: JsonNode;
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
  var valid_601086 = query.getOrDefault("EC2SecurityGroupId")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "EC2SecurityGroupId", valid_601086
  var valid_601087 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_601087
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601088 = query.getOrDefault("DBSecurityGroupName")
  valid_601088 = validateParameter(valid_601088, JString, required = true,
                                 default = nil)
  if valid_601088 != nil:
    section.add "DBSecurityGroupName", valid_601088
  var valid_601089 = query.getOrDefault("Action")
  valid_601089 = validateParameter(valid_601089, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_601089 != nil:
    section.add "Action", valid_601089
  var valid_601090 = query.getOrDefault("CIDRIP")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "CIDRIP", valid_601090
  var valid_601091 = query.getOrDefault("EC2SecurityGroupName")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "EC2SecurityGroupName", valid_601091
  var valid_601092 = query.getOrDefault("Version")
  valid_601092 = validateParameter(valid_601092, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601092 != nil:
    section.add "Version", valid_601092
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
  var valid_601093 = header.getOrDefault("X-Amz-Date")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Date", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Security-Token")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Security-Token", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Content-Sha256", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Algorithm")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Algorithm", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Signature")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Signature", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-SignedHeaders", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Credential")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Credential", valid_601099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601100: Call_GetAuthorizeDBSecurityGroupIngress_601083;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601100.validator(path, query, header, formData, body)
  let scheme = call_601100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601100.url(scheme.get, call_601100.host, call_601100.base,
                         call_601100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601100, url, valid)

proc call*(call_601101: Call_GetAuthorizeDBSecurityGroupIngress_601083;
          DBSecurityGroupName: string; EC2SecurityGroupId: string = "";
          EC2SecurityGroupOwnerId: string = "";
          Action: string = "AuthorizeDBSecurityGroupIngress"; CIDRIP: string = "";
          EC2SecurityGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getAuthorizeDBSecurityGroupIngress
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   CIDRIP: string
  ##   EC2SecurityGroupName: string
  ##   Version: string (required)
  var query_601102 = newJObject()
  add(query_601102, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_601102, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_601102, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601102, "Action", newJString(Action))
  add(query_601102, "CIDRIP", newJString(CIDRIP))
  add(query_601102, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_601102, "Version", newJString(Version))
  result = call_601101.call(nil, query_601102, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_601083(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_601084, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_601085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_601141 = ref object of OpenApiRestCall_600421
proc url_PostCopyDBSnapshot_601143(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBSnapshot_601142(path: JsonNode; query: JsonNode;
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
  var valid_601144 = query.getOrDefault("Action")
  valid_601144 = validateParameter(valid_601144, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_601144 != nil:
    section.add "Action", valid_601144
  var valid_601145 = query.getOrDefault("Version")
  valid_601145 = validateParameter(valid_601145, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601145 != nil:
    section.add "Version", valid_601145
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
  var valid_601146 = header.getOrDefault("X-Amz-Date")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Date", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Security-Token")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Security-Token", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_601153 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_601153 = validateParameter(valid_601153, JString, required = true,
                                 default = nil)
  if valid_601153 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_601153
  var valid_601154 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_601154 = validateParameter(valid_601154, JString, required = true,
                                 default = nil)
  if valid_601154 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_601154
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601155: Call_PostCopyDBSnapshot_601141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601155.validator(path, query, header, formData, body)
  let scheme = call_601155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601155.url(scheme.get, call_601155.host, call_601155.base,
                         call_601155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601155, url, valid)

proc call*(call_601156: Call_PostCopyDBSnapshot_601141;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_601157 = newJObject()
  var formData_601158 = newJObject()
  add(formData_601158, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_601157, "Action", newJString(Action))
  add(formData_601158, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_601157, "Version", newJString(Version))
  result = call_601156.call(nil, query_601157, nil, formData_601158, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_601141(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_601142, base: "/",
    url: url_PostCopyDBSnapshot_601143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_601124 = ref object of OpenApiRestCall_600421
proc url_GetCopyDBSnapshot_601126(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBSnapshot_601125(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_601127 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_601127 = validateParameter(valid_601127, JString, required = true,
                                 default = nil)
  if valid_601127 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_601127
  var valid_601128 = query.getOrDefault("Action")
  valid_601128 = validateParameter(valid_601128, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_601128 != nil:
    section.add "Action", valid_601128
  var valid_601129 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_601129 = validateParameter(valid_601129, JString, required = true,
                                 default = nil)
  if valid_601129 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_601129
  var valid_601130 = query.getOrDefault("Version")
  valid_601130 = validateParameter(valid_601130, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601130 != nil:
    section.add "Version", valid_601130
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
  var valid_601131 = header.getOrDefault("X-Amz-Date")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Date", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Security-Token")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Security-Token", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601138: Call_GetCopyDBSnapshot_601124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601138.validator(path, query, header, formData, body)
  let scheme = call_601138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601138.url(scheme.get, call_601138.host, call_601138.base,
                         call_601138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601138, url, valid)

proc call*(call_601139: Call_GetCopyDBSnapshot_601124;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## getCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_601140 = newJObject()
  add(query_601140, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_601140, "Action", newJString(Action))
  add(query_601140, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_601140, "Version", newJString(Version))
  result = call_601139.call(nil, query_601140, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_601124(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_601125,
    base: "/", url: url_GetCopyDBSnapshot_601126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_601198 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBInstance_601200(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_601199(path: JsonNode; query: JsonNode;
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
  var valid_601201 = query.getOrDefault("Action")
  valid_601201 = validateParameter(valid_601201, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_601201 != nil:
    section.add "Action", valid_601201
  var valid_601202 = query.getOrDefault("Version")
  valid_601202 = validateParameter(valid_601202, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601202 != nil:
    section.add "Version", valid_601202
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
  var valid_601203 = header.getOrDefault("X-Amz-Date")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Date", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Security-Token")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Security-Token", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Content-Sha256", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Algorithm")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Algorithm", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Signature")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Signature", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-SignedHeaders", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Credential")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Credential", valid_601209
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
  var valid_601210 = formData.getOrDefault("DBSecurityGroups")
  valid_601210 = validateParameter(valid_601210, JArray, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "DBSecurityGroups", valid_601210
  var valid_601211 = formData.getOrDefault("Port")
  valid_601211 = validateParameter(valid_601211, JInt, required = false, default = nil)
  if valid_601211 != nil:
    section.add "Port", valid_601211
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_601212 = formData.getOrDefault("Engine")
  valid_601212 = validateParameter(valid_601212, JString, required = true,
                                 default = nil)
  if valid_601212 != nil:
    section.add "Engine", valid_601212
  var valid_601213 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_601213 = validateParameter(valid_601213, JArray, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "VpcSecurityGroupIds", valid_601213
  var valid_601214 = formData.getOrDefault("Iops")
  valid_601214 = validateParameter(valid_601214, JInt, required = false, default = nil)
  if valid_601214 != nil:
    section.add "Iops", valid_601214
  var valid_601215 = formData.getOrDefault("DBName")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "DBName", valid_601215
  var valid_601216 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601216 = validateParameter(valid_601216, JString, required = true,
                                 default = nil)
  if valid_601216 != nil:
    section.add "DBInstanceIdentifier", valid_601216
  var valid_601217 = formData.getOrDefault("BackupRetentionPeriod")
  valid_601217 = validateParameter(valid_601217, JInt, required = false, default = nil)
  if valid_601217 != nil:
    section.add "BackupRetentionPeriod", valid_601217
  var valid_601218 = formData.getOrDefault("DBParameterGroupName")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "DBParameterGroupName", valid_601218
  var valid_601219 = formData.getOrDefault("OptionGroupName")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "OptionGroupName", valid_601219
  var valid_601220 = formData.getOrDefault("MasterUserPassword")
  valid_601220 = validateParameter(valid_601220, JString, required = true,
                                 default = nil)
  if valid_601220 != nil:
    section.add "MasterUserPassword", valid_601220
  var valid_601221 = formData.getOrDefault("DBSubnetGroupName")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "DBSubnetGroupName", valid_601221
  var valid_601222 = formData.getOrDefault("AvailabilityZone")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "AvailabilityZone", valid_601222
  var valid_601223 = formData.getOrDefault("MultiAZ")
  valid_601223 = validateParameter(valid_601223, JBool, required = false, default = nil)
  if valid_601223 != nil:
    section.add "MultiAZ", valid_601223
  var valid_601224 = formData.getOrDefault("AllocatedStorage")
  valid_601224 = validateParameter(valid_601224, JInt, required = true, default = nil)
  if valid_601224 != nil:
    section.add "AllocatedStorage", valid_601224
  var valid_601225 = formData.getOrDefault("PubliclyAccessible")
  valid_601225 = validateParameter(valid_601225, JBool, required = false, default = nil)
  if valid_601225 != nil:
    section.add "PubliclyAccessible", valid_601225
  var valid_601226 = formData.getOrDefault("MasterUsername")
  valid_601226 = validateParameter(valid_601226, JString, required = true,
                                 default = nil)
  if valid_601226 != nil:
    section.add "MasterUsername", valid_601226
  var valid_601227 = formData.getOrDefault("DBInstanceClass")
  valid_601227 = validateParameter(valid_601227, JString, required = true,
                                 default = nil)
  if valid_601227 != nil:
    section.add "DBInstanceClass", valid_601227
  var valid_601228 = formData.getOrDefault("CharacterSetName")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "CharacterSetName", valid_601228
  var valid_601229 = formData.getOrDefault("PreferredBackupWindow")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "PreferredBackupWindow", valid_601229
  var valid_601230 = formData.getOrDefault("LicenseModel")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "LicenseModel", valid_601230
  var valid_601231 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601231 = validateParameter(valid_601231, JBool, required = false, default = nil)
  if valid_601231 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601231
  var valid_601232 = formData.getOrDefault("EngineVersion")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "EngineVersion", valid_601232
  var valid_601233 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "PreferredMaintenanceWindow", valid_601233
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601234: Call_PostCreateDBInstance_601198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601234.validator(path, query, header, formData, body)
  let scheme = call_601234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601234.url(scheme.get, call_601234.host, call_601234.base,
                         call_601234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601234, url, valid)

proc call*(call_601235: Call_PostCreateDBInstance_601198; Engine: string;
          DBInstanceIdentifier: string; MasterUserPassword: string;
          AllocatedStorage: int; MasterUsername: string; DBInstanceClass: string;
          DBSecurityGroups: JsonNode = nil; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; Iops: int = 0; DBName: string = "";
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          OptionGroupName: string = ""; DBSubnetGroupName: string = "";
          AvailabilityZone: string = ""; MultiAZ: bool = false;
          Action: string = "CreateDBInstance"; PubliclyAccessible: bool = false;
          CharacterSetName: string = ""; PreferredBackupWindow: string = "";
          LicenseModel: string = ""; AutoMinorVersionUpgrade: bool = false;
          EngineVersion: string = ""; Version: string = "2013-02-12";
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
  var query_601236 = newJObject()
  var formData_601237 = newJObject()
  if DBSecurityGroups != nil:
    formData_601237.add "DBSecurityGroups", DBSecurityGroups
  add(formData_601237, "Port", newJInt(Port))
  add(formData_601237, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_601237.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_601237, "Iops", newJInt(Iops))
  add(formData_601237, "DBName", newJString(DBName))
  add(formData_601237, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601237, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_601237, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601237, "OptionGroupName", newJString(OptionGroupName))
  add(formData_601237, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_601237, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601237, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_601237, "MultiAZ", newJBool(MultiAZ))
  add(query_601236, "Action", newJString(Action))
  add(formData_601237, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_601237, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601237, "MasterUsername", newJString(MasterUsername))
  add(formData_601237, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601237, "CharacterSetName", newJString(CharacterSetName))
  add(formData_601237, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_601237, "LicenseModel", newJString(LicenseModel))
  add(formData_601237, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_601237, "EngineVersion", newJString(EngineVersion))
  add(query_601236, "Version", newJString(Version))
  add(formData_601237, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_601235.call(nil, query_601236, nil, formData_601237, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_601198(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_601199, base: "/",
    url: url_PostCreateDBInstance_601200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_601159 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBInstance_601161(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_601160(path: JsonNode; query: JsonNode;
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
  var valid_601162 = query.getOrDefault("Engine")
  valid_601162 = validateParameter(valid_601162, JString, required = true,
                                 default = nil)
  if valid_601162 != nil:
    section.add "Engine", valid_601162
  var valid_601163 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "PreferredMaintenanceWindow", valid_601163
  var valid_601164 = query.getOrDefault("AllocatedStorage")
  valid_601164 = validateParameter(valid_601164, JInt, required = true, default = nil)
  if valid_601164 != nil:
    section.add "AllocatedStorage", valid_601164
  var valid_601165 = query.getOrDefault("OptionGroupName")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "OptionGroupName", valid_601165
  var valid_601166 = query.getOrDefault("DBSecurityGroups")
  valid_601166 = validateParameter(valid_601166, JArray, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "DBSecurityGroups", valid_601166
  var valid_601167 = query.getOrDefault("MasterUserPassword")
  valid_601167 = validateParameter(valid_601167, JString, required = true,
                                 default = nil)
  if valid_601167 != nil:
    section.add "MasterUserPassword", valid_601167
  var valid_601168 = query.getOrDefault("AvailabilityZone")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "AvailabilityZone", valid_601168
  var valid_601169 = query.getOrDefault("Iops")
  valid_601169 = validateParameter(valid_601169, JInt, required = false, default = nil)
  if valid_601169 != nil:
    section.add "Iops", valid_601169
  var valid_601170 = query.getOrDefault("VpcSecurityGroupIds")
  valid_601170 = validateParameter(valid_601170, JArray, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "VpcSecurityGroupIds", valid_601170
  var valid_601171 = query.getOrDefault("MultiAZ")
  valid_601171 = validateParameter(valid_601171, JBool, required = false, default = nil)
  if valid_601171 != nil:
    section.add "MultiAZ", valid_601171
  var valid_601172 = query.getOrDefault("LicenseModel")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "LicenseModel", valid_601172
  var valid_601173 = query.getOrDefault("BackupRetentionPeriod")
  valid_601173 = validateParameter(valid_601173, JInt, required = false, default = nil)
  if valid_601173 != nil:
    section.add "BackupRetentionPeriod", valid_601173
  var valid_601174 = query.getOrDefault("DBName")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "DBName", valid_601174
  var valid_601175 = query.getOrDefault("DBParameterGroupName")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "DBParameterGroupName", valid_601175
  var valid_601176 = query.getOrDefault("DBInstanceClass")
  valid_601176 = validateParameter(valid_601176, JString, required = true,
                                 default = nil)
  if valid_601176 != nil:
    section.add "DBInstanceClass", valid_601176
  var valid_601177 = query.getOrDefault("Action")
  valid_601177 = validateParameter(valid_601177, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_601177 != nil:
    section.add "Action", valid_601177
  var valid_601178 = query.getOrDefault("DBSubnetGroupName")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "DBSubnetGroupName", valid_601178
  var valid_601179 = query.getOrDefault("CharacterSetName")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "CharacterSetName", valid_601179
  var valid_601180 = query.getOrDefault("PubliclyAccessible")
  valid_601180 = validateParameter(valid_601180, JBool, required = false, default = nil)
  if valid_601180 != nil:
    section.add "PubliclyAccessible", valid_601180
  var valid_601181 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601181 = validateParameter(valid_601181, JBool, required = false, default = nil)
  if valid_601181 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601181
  var valid_601182 = query.getOrDefault("EngineVersion")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "EngineVersion", valid_601182
  var valid_601183 = query.getOrDefault("Port")
  valid_601183 = validateParameter(valid_601183, JInt, required = false, default = nil)
  if valid_601183 != nil:
    section.add "Port", valid_601183
  var valid_601184 = query.getOrDefault("PreferredBackupWindow")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "PreferredBackupWindow", valid_601184
  var valid_601185 = query.getOrDefault("Version")
  valid_601185 = validateParameter(valid_601185, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601185 != nil:
    section.add "Version", valid_601185
  var valid_601186 = query.getOrDefault("DBInstanceIdentifier")
  valid_601186 = validateParameter(valid_601186, JString, required = true,
                                 default = nil)
  if valid_601186 != nil:
    section.add "DBInstanceIdentifier", valid_601186
  var valid_601187 = query.getOrDefault("MasterUsername")
  valid_601187 = validateParameter(valid_601187, JString, required = true,
                                 default = nil)
  if valid_601187 != nil:
    section.add "MasterUsername", valid_601187
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
  var valid_601188 = header.getOrDefault("X-Amz-Date")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Date", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Security-Token")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Security-Token", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Content-Sha256", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Algorithm")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Algorithm", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-Signature")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-Signature", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-SignedHeaders", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Credential")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Credential", valid_601194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601195: Call_GetCreateDBInstance_601159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601195.validator(path, query, header, formData, body)
  let scheme = call_601195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601195.url(scheme.get, call_601195.host, call_601195.base,
                         call_601195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601195, url, valid)

proc call*(call_601196: Call_GetCreateDBInstance_601159; Engine: string;
          AllocatedStorage: int; MasterUserPassword: string;
          DBInstanceClass: string; DBInstanceIdentifier: string;
          MasterUsername: string; PreferredMaintenanceWindow: string = "";
          OptionGroupName: string = ""; DBSecurityGroups: JsonNode = nil;
          AvailabilityZone: string = ""; Iops: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; MultiAZ: bool = false;
          LicenseModel: string = ""; BackupRetentionPeriod: int = 0;
          DBName: string = ""; DBParameterGroupName: string = "";
          Action: string = "CreateDBInstance"; DBSubnetGroupName: string = "";
          CharacterSetName: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          Port: int = 0; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
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
  var query_601197 = newJObject()
  add(query_601197, "Engine", newJString(Engine))
  add(query_601197, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_601197, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_601197, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_601197.add "DBSecurityGroups", DBSecurityGroups
  add(query_601197, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_601197, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601197, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_601197.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_601197, "MultiAZ", newJBool(MultiAZ))
  add(query_601197, "LicenseModel", newJString(LicenseModel))
  add(query_601197, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601197, "DBName", newJString(DBName))
  add(query_601197, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601197, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601197, "Action", newJString(Action))
  add(query_601197, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601197, "CharacterSetName", newJString(CharacterSetName))
  add(query_601197, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601197, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601197, "EngineVersion", newJString(EngineVersion))
  add(query_601197, "Port", newJInt(Port))
  add(query_601197, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601197, "Version", newJString(Version))
  add(query_601197, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601197, "MasterUsername", newJString(MasterUsername))
  result = call_601196.call(nil, query_601197, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_601159(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_601160, base: "/",
    url: url_GetCreateDBInstance_601161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_601262 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBInstanceReadReplica_601264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_601263(path: JsonNode;
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
  var valid_601265 = query.getOrDefault("Action")
  valid_601265 = validateParameter(valid_601265, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_601265 != nil:
    section.add "Action", valid_601265
  var valid_601266 = query.getOrDefault("Version")
  valid_601266 = validateParameter(valid_601266, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601266 != nil:
    section.add "Version", valid_601266
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
  var valid_601267 = header.getOrDefault("X-Amz-Date")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Date", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Security-Token")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Security-Token", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Content-Sha256", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Algorithm")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Algorithm", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Signature")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Signature", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-SignedHeaders", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Credential")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Credential", valid_601273
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   Iops: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   OptionGroupName: JString
  ##   AvailabilityZone: JString
  ##   PubliclyAccessible: JBool
  ##   DBInstanceClass: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_601274 = formData.getOrDefault("Port")
  valid_601274 = validateParameter(valid_601274, JInt, required = false, default = nil)
  if valid_601274 != nil:
    section.add "Port", valid_601274
  var valid_601275 = formData.getOrDefault("Iops")
  valid_601275 = validateParameter(valid_601275, JInt, required = false, default = nil)
  if valid_601275 != nil:
    section.add "Iops", valid_601275
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601276 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601276 = validateParameter(valid_601276, JString, required = true,
                                 default = nil)
  if valid_601276 != nil:
    section.add "DBInstanceIdentifier", valid_601276
  var valid_601277 = formData.getOrDefault("OptionGroupName")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "OptionGroupName", valid_601277
  var valid_601278 = formData.getOrDefault("AvailabilityZone")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "AvailabilityZone", valid_601278
  var valid_601279 = formData.getOrDefault("PubliclyAccessible")
  valid_601279 = validateParameter(valid_601279, JBool, required = false, default = nil)
  if valid_601279 != nil:
    section.add "PubliclyAccessible", valid_601279
  var valid_601280 = formData.getOrDefault("DBInstanceClass")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "DBInstanceClass", valid_601280
  var valid_601281 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_601281 = validateParameter(valid_601281, JString, required = true,
                                 default = nil)
  if valid_601281 != nil:
    section.add "SourceDBInstanceIdentifier", valid_601281
  var valid_601282 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601282 = validateParameter(valid_601282, JBool, required = false, default = nil)
  if valid_601282 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601283: Call_PostCreateDBInstanceReadReplica_601262;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601283.validator(path, query, header, formData, body)
  let scheme = call_601283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601283.url(scheme.get, call_601283.host, call_601283.base,
                         call_601283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601283, url, valid)

proc call*(call_601284: Call_PostCreateDBInstanceReadReplica_601262;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Port: int = 0; Iops: int = 0; OptionGroupName: string = "";
          AvailabilityZone: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          PubliclyAccessible: bool = false; DBInstanceClass: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBInstanceReadReplica
  ##   Port: int
  ##   Iops: int
  ##   DBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
  ##   AvailabilityZone: string
  ##   Action: string (required)
  ##   PubliclyAccessible: bool
  ##   DBInstanceClass: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   Version: string (required)
  var query_601285 = newJObject()
  var formData_601286 = newJObject()
  add(formData_601286, "Port", newJInt(Port))
  add(formData_601286, "Iops", newJInt(Iops))
  add(formData_601286, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601286, "OptionGroupName", newJString(OptionGroupName))
  add(formData_601286, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601285, "Action", newJString(Action))
  add(formData_601286, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601286, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601286, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_601286, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_601285, "Version", newJString(Version))
  result = call_601284.call(nil, query_601285, nil, formData_601286, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_601262(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_601263, base: "/",
    url: url_PostCreateDBInstanceReadReplica_601264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_601238 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBInstanceReadReplica_601240(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_601239(path: JsonNode;
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
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_601241 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_601241 = validateParameter(valid_601241, JString, required = true,
                                 default = nil)
  if valid_601241 != nil:
    section.add "SourceDBInstanceIdentifier", valid_601241
  var valid_601242 = query.getOrDefault("OptionGroupName")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "OptionGroupName", valid_601242
  var valid_601243 = query.getOrDefault("AvailabilityZone")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "AvailabilityZone", valid_601243
  var valid_601244 = query.getOrDefault("Iops")
  valid_601244 = validateParameter(valid_601244, JInt, required = false, default = nil)
  if valid_601244 != nil:
    section.add "Iops", valid_601244
  var valid_601245 = query.getOrDefault("DBInstanceClass")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "DBInstanceClass", valid_601245
  var valid_601246 = query.getOrDefault("Action")
  valid_601246 = validateParameter(valid_601246, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_601246 != nil:
    section.add "Action", valid_601246
  var valid_601247 = query.getOrDefault("PubliclyAccessible")
  valid_601247 = validateParameter(valid_601247, JBool, required = false, default = nil)
  if valid_601247 != nil:
    section.add "PubliclyAccessible", valid_601247
  var valid_601248 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601248 = validateParameter(valid_601248, JBool, required = false, default = nil)
  if valid_601248 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601248
  var valid_601249 = query.getOrDefault("Port")
  valid_601249 = validateParameter(valid_601249, JInt, required = false, default = nil)
  if valid_601249 != nil:
    section.add "Port", valid_601249
  var valid_601250 = query.getOrDefault("Version")
  valid_601250 = validateParameter(valid_601250, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601250 != nil:
    section.add "Version", valid_601250
  var valid_601251 = query.getOrDefault("DBInstanceIdentifier")
  valid_601251 = validateParameter(valid_601251, JString, required = true,
                                 default = nil)
  if valid_601251 != nil:
    section.add "DBInstanceIdentifier", valid_601251
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
  var valid_601252 = header.getOrDefault("X-Amz-Date")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Date", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Security-Token")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Security-Token", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Content-Sha256", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Algorithm")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Algorithm", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Signature")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Signature", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-SignedHeaders", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Credential")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Credential", valid_601258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601259: Call_GetCreateDBInstanceReadReplica_601238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601259.validator(path, query, header, formData, body)
  let scheme = call_601259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601259.url(scheme.get, call_601259.host, call_601259.base,
                         call_601259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601259, url, valid)

proc call*(call_601260: Call_GetCreateDBInstanceReadReplica_601238;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          OptionGroupName: string = ""; AvailabilityZone: string = ""; Iops: int = 0;
          DBInstanceClass: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Port: int = 0; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   SourceDBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601261 = newJObject()
  add(query_601261, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_601261, "OptionGroupName", newJString(OptionGroupName))
  add(query_601261, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601261, "Iops", newJInt(Iops))
  add(query_601261, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601261, "Action", newJString(Action))
  add(query_601261, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601261, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601261, "Port", newJInt(Port))
  add(query_601261, "Version", newJString(Version))
  add(query_601261, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601260.call(nil, query_601261, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_601238(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_601239, base: "/",
    url: url_GetCreateDBInstanceReadReplica_601240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_601305 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBParameterGroup_601307(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBParameterGroup_601306(path: JsonNode; query: JsonNode;
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
  var valid_601308 = query.getOrDefault("Action")
  valid_601308 = validateParameter(valid_601308, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_601308 != nil:
    section.add "Action", valid_601308
  var valid_601309 = query.getOrDefault("Version")
  valid_601309 = validateParameter(valid_601309, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601309 != nil:
    section.add "Version", valid_601309
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
  var valid_601310 = header.getOrDefault("X-Amz-Date")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Date", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Security-Token")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Security-Token", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Content-Sha256", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Algorithm")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Algorithm", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Signature")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Signature", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-SignedHeaders", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Credential")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Credential", valid_601316
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601317 = formData.getOrDefault("DBParameterGroupName")
  valid_601317 = validateParameter(valid_601317, JString, required = true,
                                 default = nil)
  if valid_601317 != nil:
    section.add "DBParameterGroupName", valid_601317
  var valid_601318 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601318 = validateParameter(valid_601318, JString, required = true,
                                 default = nil)
  if valid_601318 != nil:
    section.add "DBParameterGroupFamily", valid_601318
  var valid_601319 = formData.getOrDefault("Description")
  valid_601319 = validateParameter(valid_601319, JString, required = true,
                                 default = nil)
  if valid_601319 != nil:
    section.add "Description", valid_601319
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601320: Call_PostCreateDBParameterGroup_601305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601320.validator(path, query, header, formData, body)
  let scheme = call_601320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601320.url(scheme.get, call_601320.host, call_601320.base,
                         call_601320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601320, url, valid)

proc call*(call_601321: Call_PostCreateDBParameterGroup_601305;
          DBParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Description: string (required)
  var query_601322 = newJObject()
  var formData_601323 = newJObject()
  add(formData_601323, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601322, "Action", newJString(Action))
  add(formData_601323, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_601322, "Version", newJString(Version))
  add(formData_601323, "Description", newJString(Description))
  result = call_601321.call(nil, query_601322, nil, formData_601323, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_601305(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_601306, base: "/",
    url: url_PostCreateDBParameterGroup_601307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_601287 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBParameterGroup_601289(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBParameterGroup_601288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Description: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Description` field"
  var valid_601290 = query.getOrDefault("Description")
  valid_601290 = validateParameter(valid_601290, JString, required = true,
                                 default = nil)
  if valid_601290 != nil:
    section.add "Description", valid_601290
  var valid_601291 = query.getOrDefault("DBParameterGroupFamily")
  valid_601291 = validateParameter(valid_601291, JString, required = true,
                                 default = nil)
  if valid_601291 != nil:
    section.add "DBParameterGroupFamily", valid_601291
  var valid_601292 = query.getOrDefault("DBParameterGroupName")
  valid_601292 = validateParameter(valid_601292, JString, required = true,
                                 default = nil)
  if valid_601292 != nil:
    section.add "DBParameterGroupName", valid_601292
  var valid_601293 = query.getOrDefault("Action")
  valid_601293 = validateParameter(valid_601293, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_601293 != nil:
    section.add "Action", valid_601293
  var valid_601294 = query.getOrDefault("Version")
  valid_601294 = validateParameter(valid_601294, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601294 != nil:
    section.add "Version", valid_601294
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
  var valid_601295 = header.getOrDefault("X-Amz-Date")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Date", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Security-Token")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Security-Token", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Content-Sha256", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Algorithm")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Algorithm", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Signature")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Signature", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-SignedHeaders", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-Credential")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Credential", valid_601301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601302: Call_GetCreateDBParameterGroup_601287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601302.validator(path, query, header, formData, body)
  let scheme = call_601302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601302.url(scheme.get, call_601302.host, call_601302.base,
                         call_601302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601302, url, valid)

proc call*(call_601303: Call_GetCreateDBParameterGroup_601287; Description: string;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601304 = newJObject()
  add(query_601304, "Description", newJString(Description))
  add(query_601304, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_601304, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601304, "Action", newJString(Action))
  add(query_601304, "Version", newJString(Version))
  result = call_601303.call(nil, query_601304, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_601287(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_601288, base: "/",
    url: url_GetCreateDBParameterGroup_601289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_601341 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBSecurityGroup_601343(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSecurityGroup_601342(path: JsonNode; query: JsonNode;
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
  var valid_601344 = query.getOrDefault("Action")
  valid_601344 = validateParameter(valid_601344, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_601344 != nil:
    section.add "Action", valid_601344
  var valid_601345 = query.getOrDefault("Version")
  valid_601345 = validateParameter(valid_601345, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601345 != nil:
    section.add "Version", valid_601345
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
  var valid_601346 = header.getOrDefault("X-Amz-Date")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Date", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Security-Token")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Security-Token", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Content-Sha256", valid_601348
  var valid_601349 = header.getOrDefault("X-Amz-Algorithm")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Algorithm", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Signature")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Signature", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-SignedHeaders", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Credential")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Credential", valid_601352
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601353 = formData.getOrDefault("DBSecurityGroupName")
  valid_601353 = validateParameter(valid_601353, JString, required = true,
                                 default = nil)
  if valid_601353 != nil:
    section.add "DBSecurityGroupName", valid_601353
  var valid_601354 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_601354 = validateParameter(valid_601354, JString, required = true,
                                 default = nil)
  if valid_601354 != nil:
    section.add "DBSecurityGroupDescription", valid_601354
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601355: Call_PostCreateDBSecurityGroup_601341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601355.validator(path, query, header, formData, body)
  let scheme = call_601355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601355.url(scheme.get, call_601355.host, call_601355.base,
                         call_601355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601355, url, valid)

proc call*(call_601356: Call_PostCreateDBSecurityGroup_601341;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_601357 = newJObject()
  var formData_601358 = newJObject()
  add(formData_601358, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601357, "Action", newJString(Action))
  add(formData_601358, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_601357, "Version", newJString(Version))
  result = call_601356.call(nil, query_601357, nil, formData_601358, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_601341(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_601342, base: "/",
    url: url_PostCreateDBSecurityGroup_601343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_601324 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBSecurityGroup_601326(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSecurityGroup_601325(path: JsonNode; query: JsonNode;
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
  var valid_601327 = query.getOrDefault("DBSecurityGroupName")
  valid_601327 = validateParameter(valid_601327, JString, required = true,
                                 default = nil)
  if valid_601327 != nil:
    section.add "DBSecurityGroupName", valid_601327
  var valid_601328 = query.getOrDefault("DBSecurityGroupDescription")
  valid_601328 = validateParameter(valid_601328, JString, required = true,
                                 default = nil)
  if valid_601328 != nil:
    section.add "DBSecurityGroupDescription", valid_601328
  var valid_601329 = query.getOrDefault("Action")
  valid_601329 = validateParameter(valid_601329, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_601329 != nil:
    section.add "Action", valid_601329
  var valid_601330 = query.getOrDefault("Version")
  valid_601330 = validateParameter(valid_601330, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601330 != nil:
    section.add "Version", valid_601330
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
  var valid_601331 = header.getOrDefault("X-Amz-Date")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Date", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Security-Token")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Security-Token", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Content-Sha256", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-Algorithm")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Algorithm", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Signature")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Signature", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-SignedHeaders", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Credential")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Credential", valid_601337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601338: Call_GetCreateDBSecurityGroup_601324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601338.validator(path, query, header, formData, body)
  let scheme = call_601338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601338.url(scheme.get, call_601338.host, call_601338.base,
                         call_601338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601338, url, valid)

proc call*(call_601339: Call_GetCreateDBSecurityGroup_601324;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601340 = newJObject()
  add(query_601340, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601340, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_601340, "Action", newJString(Action))
  add(query_601340, "Version", newJString(Version))
  result = call_601339.call(nil, query_601340, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_601324(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_601325, base: "/",
    url: url_GetCreateDBSecurityGroup_601326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_601376 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBSnapshot_601378(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSnapshot_601377(path: JsonNode; query: JsonNode;
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
  var valid_601379 = query.getOrDefault("Action")
  valid_601379 = validateParameter(valid_601379, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_601379 != nil:
    section.add "Action", valid_601379
  var valid_601380 = query.getOrDefault("Version")
  valid_601380 = validateParameter(valid_601380, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601380 != nil:
    section.add "Version", valid_601380
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
  var valid_601381 = header.getOrDefault("X-Amz-Date")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Date", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-Security-Token")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Security-Token", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Content-Sha256", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-Algorithm")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-Algorithm", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Signature")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Signature", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-SignedHeaders", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Credential")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Credential", valid_601387
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601388 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601388 = validateParameter(valid_601388, JString, required = true,
                                 default = nil)
  if valid_601388 != nil:
    section.add "DBInstanceIdentifier", valid_601388
  var valid_601389 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601389 = validateParameter(valid_601389, JString, required = true,
                                 default = nil)
  if valid_601389 != nil:
    section.add "DBSnapshotIdentifier", valid_601389
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601390: Call_PostCreateDBSnapshot_601376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601390.validator(path, query, header, formData, body)
  let scheme = call_601390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601390.url(scheme.get, call_601390.host, call_601390.base,
                         call_601390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601390, url, valid)

proc call*(call_601391: Call_PostCreateDBSnapshot_601376;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601392 = newJObject()
  var formData_601393 = newJObject()
  add(formData_601393, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601393, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601392, "Action", newJString(Action))
  add(query_601392, "Version", newJString(Version))
  result = call_601391.call(nil, query_601392, nil, formData_601393, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_601376(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_601377, base: "/",
    url: url_PostCreateDBSnapshot_601378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_601359 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBSnapshot_601361(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSnapshot_601360(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601362 = query.getOrDefault("Action")
  valid_601362 = validateParameter(valid_601362, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_601362 != nil:
    section.add "Action", valid_601362
  var valid_601363 = query.getOrDefault("Version")
  valid_601363 = validateParameter(valid_601363, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601363 != nil:
    section.add "Version", valid_601363
  var valid_601364 = query.getOrDefault("DBInstanceIdentifier")
  valid_601364 = validateParameter(valid_601364, JString, required = true,
                                 default = nil)
  if valid_601364 != nil:
    section.add "DBInstanceIdentifier", valid_601364
  var valid_601365 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601365 = validateParameter(valid_601365, JString, required = true,
                                 default = nil)
  if valid_601365 != nil:
    section.add "DBSnapshotIdentifier", valid_601365
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
  var valid_601366 = header.getOrDefault("X-Amz-Date")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Date", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-Security-Token")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-Security-Token", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Content-Sha256", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Algorithm")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Algorithm", valid_601369
  var valid_601370 = header.getOrDefault("X-Amz-Signature")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Signature", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-SignedHeaders", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Credential")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Credential", valid_601372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601373: Call_GetCreateDBSnapshot_601359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601373.validator(path, query, header, formData, body)
  let scheme = call_601373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601373.url(scheme.get, call_601373.host, call_601373.base,
                         call_601373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601373, url, valid)

proc call*(call_601374: Call_GetCreateDBSnapshot_601359;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_601375 = newJObject()
  add(query_601375, "Action", newJString(Action))
  add(query_601375, "Version", newJString(Version))
  add(query_601375, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601375, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601374.call(nil, query_601375, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_601359(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_601360, base: "/",
    url: url_GetCreateDBSnapshot_601361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_601412 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBSubnetGroup_601414(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_601413(path: JsonNode; query: JsonNode;
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
  var valid_601415 = query.getOrDefault("Action")
  valid_601415 = validateParameter(valid_601415, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_601415 != nil:
    section.add "Action", valid_601415
  var valid_601416 = query.getOrDefault("Version")
  valid_601416 = validateParameter(valid_601416, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601416 != nil:
    section.add "Version", valid_601416
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
  var valid_601417 = header.getOrDefault("X-Amz-Date")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Date", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Security-Token")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Security-Token", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Content-Sha256", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-Algorithm")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Algorithm", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Signature")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Signature", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-SignedHeaders", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Credential")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Credential", valid_601423
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601424 = formData.getOrDefault("DBSubnetGroupName")
  valid_601424 = validateParameter(valid_601424, JString, required = true,
                                 default = nil)
  if valid_601424 != nil:
    section.add "DBSubnetGroupName", valid_601424
  var valid_601425 = formData.getOrDefault("SubnetIds")
  valid_601425 = validateParameter(valid_601425, JArray, required = true, default = nil)
  if valid_601425 != nil:
    section.add "SubnetIds", valid_601425
  var valid_601426 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_601426 = validateParameter(valid_601426, JString, required = true,
                                 default = nil)
  if valid_601426 != nil:
    section.add "DBSubnetGroupDescription", valid_601426
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601427: Call_PostCreateDBSubnetGroup_601412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601427.validator(path, query, header, formData, body)
  let scheme = call_601427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601427.url(scheme.get, call_601427.host, call_601427.base,
                         call_601427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601427, url, valid)

proc call*(call_601428: Call_PostCreateDBSubnetGroup_601412;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_601429 = newJObject()
  var formData_601430 = newJObject()
  add(formData_601430, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_601430.add "SubnetIds", SubnetIds
  add(query_601429, "Action", newJString(Action))
  add(formData_601430, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601429, "Version", newJString(Version))
  result = call_601428.call(nil, query_601429, nil, formData_601430, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_601412(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_601413, base: "/",
    url: url_PostCreateDBSubnetGroup_601414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_601394 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBSubnetGroup_601396(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_601395(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601397 = query.getOrDefault("Action")
  valid_601397 = validateParameter(valid_601397, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_601397 != nil:
    section.add "Action", valid_601397
  var valid_601398 = query.getOrDefault("DBSubnetGroupName")
  valid_601398 = validateParameter(valid_601398, JString, required = true,
                                 default = nil)
  if valid_601398 != nil:
    section.add "DBSubnetGroupName", valid_601398
  var valid_601399 = query.getOrDefault("SubnetIds")
  valid_601399 = validateParameter(valid_601399, JArray, required = true, default = nil)
  if valid_601399 != nil:
    section.add "SubnetIds", valid_601399
  var valid_601400 = query.getOrDefault("DBSubnetGroupDescription")
  valid_601400 = validateParameter(valid_601400, JString, required = true,
                                 default = nil)
  if valid_601400 != nil:
    section.add "DBSubnetGroupDescription", valid_601400
  var valid_601401 = query.getOrDefault("Version")
  valid_601401 = validateParameter(valid_601401, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601401 != nil:
    section.add "Version", valid_601401
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
  var valid_601402 = header.getOrDefault("X-Amz-Date")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Date", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Security-Token")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Security-Token", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Content-Sha256", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Algorithm")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Algorithm", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-Signature")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Signature", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-SignedHeaders", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-Credential")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Credential", valid_601408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601409: Call_GetCreateDBSubnetGroup_601394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601409.validator(path, query, header, formData, body)
  let scheme = call_601409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601409.url(scheme.get, call_601409.host, call_601409.base,
                         call_601409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601409, url, valid)

proc call*(call_601410: Call_GetCreateDBSubnetGroup_601394;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_601411 = newJObject()
  add(query_601411, "Action", newJString(Action))
  add(query_601411, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_601411.add "SubnetIds", SubnetIds
  add(query_601411, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601411, "Version", newJString(Version))
  result = call_601410.call(nil, query_601411, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_601394(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_601395, base: "/",
    url: url_GetCreateDBSubnetGroup_601396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_601452 = ref object of OpenApiRestCall_600421
proc url_PostCreateEventSubscription_601454(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEventSubscription_601453(path: JsonNode; query: JsonNode;
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
  var valid_601455 = query.getOrDefault("Action")
  valid_601455 = validateParameter(valid_601455, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_601455 != nil:
    section.add "Action", valid_601455
  var valid_601456 = query.getOrDefault("Version")
  valid_601456 = validateParameter(valid_601456, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601456 != nil:
    section.add "Version", valid_601456
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
  var valid_601457 = header.getOrDefault("X-Amz-Date")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Date", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-Security-Token")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-Security-Token", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Content-Sha256", valid_601459
  var valid_601460 = header.getOrDefault("X-Amz-Algorithm")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-Algorithm", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-Signature")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Signature", valid_601461
  var valid_601462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601462 = validateParameter(valid_601462, JString, required = false,
                                 default = nil)
  if valid_601462 != nil:
    section.add "X-Amz-SignedHeaders", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-Credential")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Credential", valid_601463
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString (required)
  ##   SourceIds: JArray
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_601464 = formData.getOrDefault("Enabled")
  valid_601464 = validateParameter(valid_601464, JBool, required = false, default = nil)
  if valid_601464 != nil:
    section.add "Enabled", valid_601464
  var valid_601465 = formData.getOrDefault("EventCategories")
  valid_601465 = validateParameter(valid_601465, JArray, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "EventCategories", valid_601465
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_601466 = formData.getOrDefault("SnsTopicArn")
  valid_601466 = validateParameter(valid_601466, JString, required = true,
                                 default = nil)
  if valid_601466 != nil:
    section.add "SnsTopicArn", valid_601466
  var valid_601467 = formData.getOrDefault("SourceIds")
  valid_601467 = validateParameter(valid_601467, JArray, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "SourceIds", valid_601467
  var valid_601468 = formData.getOrDefault("SubscriptionName")
  valid_601468 = validateParameter(valid_601468, JString, required = true,
                                 default = nil)
  if valid_601468 != nil:
    section.add "SubscriptionName", valid_601468
  var valid_601469 = formData.getOrDefault("SourceType")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "SourceType", valid_601469
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601470: Call_PostCreateEventSubscription_601452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601470.validator(path, query, header, formData, body)
  let scheme = call_601470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601470.url(scheme.get, call_601470.host, call_601470.base,
                         call_601470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601470, url, valid)

proc call*(call_601471: Call_PostCreateEventSubscription_601452;
          SnsTopicArn: string; SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SourceIds: JsonNode = nil;
          Action: string = "CreateEventSubscription";
          Version: string = "2013-02-12"; SourceType: string = ""): Recallable =
  ## postCreateEventSubscription
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   SnsTopicArn: string (required)
  ##   SourceIds: JArray
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_601472 = newJObject()
  var formData_601473 = newJObject()
  add(formData_601473, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_601473.add "EventCategories", EventCategories
  add(formData_601473, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_601473.add "SourceIds", SourceIds
  add(formData_601473, "SubscriptionName", newJString(SubscriptionName))
  add(query_601472, "Action", newJString(Action))
  add(query_601472, "Version", newJString(Version))
  add(formData_601473, "SourceType", newJString(SourceType))
  result = call_601471.call(nil, query_601472, nil, formData_601473, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_601452(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_601453, base: "/",
    url: url_PostCreateEventSubscription_601454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_601431 = ref object of OpenApiRestCall_600421
proc url_GetCreateEventSubscription_601433(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEventSubscription_601432(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   SourceIds: JArray
  ##   Enabled: JBool
  ##   Action: JString (required)
  ##   SnsTopicArn: JString (required)
  ##   EventCategories: JArray
  ##   SubscriptionName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_601434 = query.getOrDefault("SourceType")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "SourceType", valid_601434
  var valid_601435 = query.getOrDefault("SourceIds")
  valid_601435 = validateParameter(valid_601435, JArray, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "SourceIds", valid_601435
  var valid_601436 = query.getOrDefault("Enabled")
  valid_601436 = validateParameter(valid_601436, JBool, required = false, default = nil)
  if valid_601436 != nil:
    section.add "Enabled", valid_601436
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601437 = query.getOrDefault("Action")
  valid_601437 = validateParameter(valid_601437, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_601437 != nil:
    section.add "Action", valid_601437
  var valid_601438 = query.getOrDefault("SnsTopicArn")
  valid_601438 = validateParameter(valid_601438, JString, required = true,
                                 default = nil)
  if valid_601438 != nil:
    section.add "SnsTopicArn", valid_601438
  var valid_601439 = query.getOrDefault("EventCategories")
  valid_601439 = validateParameter(valid_601439, JArray, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "EventCategories", valid_601439
  var valid_601440 = query.getOrDefault("SubscriptionName")
  valid_601440 = validateParameter(valid_601440, JString, required = true,
                                 default = nil)
  if valid_601440 != nil:
    section.add "SubscriptionName", valid_601440
  var valid_601441 = query.getOrDefault("Version")
  valid_601441 = validateParameter(valid_601441, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601441 != nil:
    section.add "Version", valid_601441
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
  var valid_601442 = header.getOrDefault("X-Amz-Date")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Date", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-Security-Token")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Security-Token", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Content-Sha256", valid_601444
  var valid_601445 = header.getOrDefault("X-Amz-Algorithm")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-Algorithm", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-Signature")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-Signature", valid_601446
  var valid_601447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "X-Amz-SignedHeaders", valid_601447
  var valid_601448 = header.getOrDefault("X-Amz-Credential")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-Credential", valid_601448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601449: Call_GetCreateEventSubscription_601431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601449.validator(path, query, header, formData, body)
  let scheme = call_601449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601449.url(scheme.get, call_601449.host, call_601449.base,
                         call_601449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601449, url, valid)

proc call*(call_601450: Call_GetCreateEventSubscription_601431;
          SnsTopicArn: string; SubscriptionName: string; SourceType: string = "";
          SourceIds: JsonNode = nil; Enabled: bool = false;
          Action: string = "CreateEventSubscription";
          EventCategories: JsonNode = nil; Version: string = "2013-02-12"): Recallable =
  ## getCreateEventSubscription
  ##   SourceType: string
  ##   SourceIds: JArray
  ##   Enabled: bool
  ##   Action: string (required)
  ##   SnsTopicArn: string (required)
  ##   EventCategories: JArray
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_601451 = newJObject()
  add(query_601451, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_601451.add "SourceIds", SourceIds
  add(query_601451, "Enabled", newJBool(Enabled))
  add(query_601451, "Action", newJString(Action))
  add(query_601451, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_601451.add "EventCategories", EventCategories
  add(query_601451, "SubscriptionName", newJString(SubscriptionName))
  add(query_601451, "Version", newJString(Version))
  result = call_601450.call(nil, query_601451, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_601431(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_601432, base: "/",
    url: url_GetCreateEventSubscription_601433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_601493 = ref object of OpenApiRestCall_600421
proc url_PostCreateOptionGroup_601495(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateOptionGroup_601494(path: JsonNode; query: JsonNode;
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
  var valid_601496 = query.getOrDefault("Action")
  valid_601496 = validateParameter(valid_601496, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_601496 != nil:
    section.add "Action", valid_601496
  var valid_601497 = query.getOrDefault("Version")
  valid_601497 = validateParameter(valid_601497, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601497 != nil:
    section.add "Version", valid_601497
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
  var valid_601498 = header.getOrDefault("X-Amz-Date")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Date", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-Security-Token")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Security-Token", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Content-Sha256", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Algorithm")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Algorithm", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Signature")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Signature", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-SignedHeaders", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Credential")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Credential", valid_601504
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_601505 = formData.getOrDefault("MajorEngineVersion")
  valid_601505 = validateParameter(valid_601505, JString, required = true,
                                 default = nil)
  if valid_601505 != nil:
    section.add "MajorEngineVersion", valid_601505
  var valid_601506 = formData.getOrDefault("OptionGroupName")
  valid_601506 = validateParameter(valid_601506, JString, required = true,
                                 default = nil)
  if valid_601506 != nil:
    section.add "OptionGroupName", valid_601506
  var valid_601507 = formData.getOrDefault("EngineName")
  valid_601507 = validateParameter(valid_601507, JString, required = true,
                                 default = nil)
  if valid_601507 != nil:
    section.add "EngineName", valid_601507
  var valid_601508 = formData.getOrDefault("OptionGroupDescription")
  valid_601508 = validateParameter(valid_601508, JString, required = true,
                                 default = nil)
  if valid_601508 != nil:
    section.add "OptionGroupDescription", valid_601508
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601509: Call_PostCreateOptionGroup_601493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601509.validator(path, query, header, formData, body)
  let scheme = call_601509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601509.url(scheme.get, call_601509.host, call_601509.base,
                         call_601509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601509, url, valid)

proc call*(call_601510: Call_PostCreateOptionGroup_601493;
          MajorEngineVersion: string; OptionGroupName: string; EngineName: string;
          OptionGroupDescription: string; Action: string = "CreateOptionGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postCreateOptionGroup
  ##   MajorEngineVersion: string (required)
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Version: string (required)
  var query_601511 = newJObject()
  var formData_601512 = newJObject()
  add(formData_601512, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_601512, "OptionGroupName", newJString(OptionGroupName))
  add(query_601511, "Action", newJString(Action))
  add(formData_601512, "EngineName", newJString(EngineName))
  add(formData_601512, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_601511, "Version", newJString(Version))
  result = call_601510.call(nil, query_601511, nil, formData_601512, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_601493(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_601494, base: "/",
    url: url_PostCreateOptionGroup_601495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_601474 = ref object of OpenApiRestCall_600421
proc url_GetCreateOptionGroup_601476(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateOptionGroup_601475(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OptionGroupName: JString (required)
  ##   OptionGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `OptionGroupName` field"
  var valid_601477 = query.getOrDefault("OptionGroupName")
  valid_601477 = validateParameter(valid_601477, JString, required = true,
                                 default = nil)
  if valid_601477 != nil:
    section.add "OptionGroupName", valid_601477
  var valid_601478 = query.getOrDefault("OptionGroupDescription")
  valid_601478 = validateParameter(valid_601478, JString, required = true,
                                 default = nil)
  if valid_601478 != nil:
    section.add "OptionGroupDescription", valid_601478
  var valid_601479 = query.getOrDefault("Action")
  valid_601479 = validateParameter(valid_601479, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_601479 != nil:
    section.add "Action", valid_601479
  var valid_601480 = query.getOrDefault("Version")
  valid_601480 = validateParameter(valid_601480, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601480 != nil:
    section.add "Version", valid_601480
  var valid_601481 = query.getOrDefault("EngineName")
  valid_601481 = validateParameter(valid_601481, JString, required = true,
                                 default = nil)
  if valid_601481 != nil:
    section.add "EngineName", valid_601481
  var valid_601482 = query.getOrDefault("MajorEngineVersion")
  valid_601482 = validateParameter(valid_601482, JString, required = true,
                                 default = nil)
  if valid_601482 != nil:
    section.add "MajorEngineVersion", valid_601482
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
  var valid_601483 = header.getOrDefault("X-Amz-Date")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Date", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-Security-Token")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Security-Token", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Content-Sha256", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Algorithm")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Algorithm", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Signature")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Signature", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-SignedHeaders", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Credential")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Credential", valid_601489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601490: Call_GetCreateOptionGroup_601474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601490.validator(path, query, header, formData, body)
  let scheme = call_601490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601490.url(scheme.get, call_601490.host, call_601490.base,
                         call_601490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601490, url, valid)

proc call*(call_601491: Call_GetCreateOptionGroup_601474; OptionGroupName: string;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; Action: string = "CreateOptionGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getCreateOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  var query_601492 = newJObject()
  add(query_601492, "OptionGroupName", newJString(OptionGroupName))
  add(query_601492, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_601492, "Action", newJString(Action))
  add(query_601492, "Version", newJString(Version))
  add(query_601492, "EngineName", newJString(EngineName))
  add(query_601492, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_601491.call(nil, query_601492, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_601474(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_601475, base: "/",
    url: url_GetCreateOptionGroup_601476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_601531 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBInstance_601533(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_601532(path: JsonNode; query: JsonNode;
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
  var valid_601534 = query.getOrDefault("Action")
  valid_601534 = validateParameter(valid_601534, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_601534 != nil:
    section.add "Action", valid_601534
  var valid_601535 = query.getOrDefault("Version")
  valid_601535 = validateParameter(valid_601535, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601535 != nil:
    section.add "Version", valid_601535
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
  var valid_601536 = header.getOrDefault("X-Amz-Date")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Date", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Security-Token")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Security-Token", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Content-Sha256", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-Algorithm")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Algorithm", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Signature")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Signature", valid_601540
  var valid_601541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-SignedHeaders", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-Credential")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Credential", valid_601542
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601543 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601543 = validateParameter(valid_601543, JString, required = true,
                                 default = nil)
  if valid_601543 != nil:
    section.add "DBInstanceIdentifier", valid_601543
  var valid_601544 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_601544
  var valid_601545 = formData.getOrDefault("SkipFinalSnapshot")
  valid_601545 = validateParameter(valid_601545, JBool, required = false, default = nil)
  if valid_601545 != nil:
    section.add "SkipFinalSnapshot", valid_601545
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601546: Call_PostDeleteDBInstance_601531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601546.validator(path, query, header, formData, body)
  let scheme = call_601546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601546.url(scheme.get, call_601546.host, call_601546.base,
                         call_601546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601546, url, valid)

proc call*(call_601547: Call_PostDeleteDBInstance_601531;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-02-12";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_601548 = newJObject()
  var formData_601549 = newJObject()
  add(formData_601549, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601549, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_601548, "Action", newJString(Action))
  add(query_601548, "Version", newJString(Version))
  add(formData_601549, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_601547.call(nil, query_601548, nil, formData_601549, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_601531(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_601532, base: "/",
    url: url_PostDeleteDBInstance_601533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_601513 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBInstance_601515(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_601514(path: JsonNode; query: JsonNode;
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
  var valid_601516 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_601516
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601517 = query.getOrDefault("Action")
  valid_601517 = validateParameter(valid_601517, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_601517 != nil:
    section.add "Action", valid_601517
  var valid_601518 = query.getOrDefault("SkipFinalSnapshot")
  valid_601518 = validateParameter(valid_601518, JBool, required = false, default = nil)
  if valid_601518 != nil:
    section.add "SkipFinalSnapshot", valid_601518
  var valid_601519 = query.getOrDefault("Version")
  valid_601519 = validateParameter(valid_601519, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601519 != nil:
    section.add "Version", valid_601519
  var valid_601520 = query.getOrDefault("DBInstanceIdentifier")
  valid_601520 = validateParameter(valid_601520, JString, required = true,
                                 default = nil)
  if valid_601520 != nil:
    section.add "DBInstanceIdentifier", valid_601520
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
  var valid_601521 = header.getOrDefault("X-Amz-Date")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Date", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Security-Token")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Security-Token", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Content-Sha256", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-Algorithm")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-Algorithm", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-Signature")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Signature", valid_601525
  var valid_601526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "X-Amz-SignedHeaders", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Credential")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Credential", valid_601527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601528: Call_GetDeleteDBInstance_601513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601528.validator(path, query, header, formData, body)
  let scheme = call_601528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601528.url(scheme.get, call_601528.host, call_601528.base,
                         call_601528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601528, url, valid)

proc call*(call_601529: Call_GetDeleteDBInstance_601513;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601530 = newJObject()
  add(query_601530, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_601530, "Action", newJString(Action))
  add(query_601530, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_601530, "Version", newJString(Version))
  add(query_601530, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601529.call(nil, query_601530, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_601513(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_601514, base: "/",
    url: url_GetDeleteDBInstance_601515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_601566 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBParameterGroup_601568(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBParameterGroup_601567(path: JsonNode; query: JsonNode;
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
  var valid_601569 = query.getOrDefault("Action")
  valid_601569 = validateParameter(valid_601569, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_601569 != nil:
    section.add "Action", valid_601569
  var valid_601570 = query.getOrDefault("Version")
  valid_601570 = validateParameter(valid_601570, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601570 != nil:
    section.add "Version", valid_601570
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
  var valid_601571 = header.getOrDefault("X-Amz-Date")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "X-Amz-Date", valid_601571
  var valid_601572 = header.getOrDefault("X-Amz-Security-Token")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Security-Token", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Content-Sha256", valid_601573
  var valid_601574 = header.getOrDefault("X-Amz-Algorithm")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Algorithm", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-Signature")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-Signature", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-SignedHeaders", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-Credential")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-Credential", valid_601577
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601578 = formData.getOrDefault("DBParameterGroupName")
  valid_601578 = validateParameter(valid_601578, JString, required = true,
                                 default = nil)
  if valid_601578 != nil:
    section.add "DBParameterGroupName", valid_601578
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601579: Call_PostDeleteDBParameterGroup_601566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601579.validator(path, query, header, formData, body)
  let scheme = call_601579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601579.url(scheme.get, call_601579.host, call_601579.base,
                         call_601579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601579, url, valid)

proc call*(call_601580: Call_PostDeleteDBParameterGroup_601566;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601581 = newJObject()
  var formData_601582 = newJObject()
  add(formData_601582, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601581, "Action", newJString(Action))
  add(query_601581, "Version", newJString(Version))
  result = call_601580.call(nil, query_601581, nil, formData_601582, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_601566(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_601567, base: "/",
    url: url_PostDeleteDBParameterGroup_601568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_601550 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBParameterGroup_601552(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBParameterGroup_601551(path: JsonNode; query: JsonNode;
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
  var valid_601553 = query.getOrDefault("DBParameterGroupName")
  valid_601553 = validateParameter(valid_601553, JString, required = true,
                                 default = nil)
  if valid_601553 != nil:
    section.add "DBParameterGroupName", valid_601553
  var valid_601554 = query.getOrDefault("Action")
  valid_601554 = validateParameter(valid_601554, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_601554 != nil:
    section.add "Action", valid_601554
  var valid_601555 = query.getOrDefault("Version")
  valid_601555 = validateParameter(valid_601555, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601555 != nil:
    section.add "Version", valid_601555
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
  var valid_601556 = header.getOrDefault("X-Amz-Date")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Date", valid_601556
  var valid_601557 = header.getOrDefault("X-Amz-Security-Token")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Security-Token", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Content-Sha256", valid_601558
  var valid_601559 = header.getOrDefault("X-Amz-Algorithm")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-Algorithm", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Signature")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Signature", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-SignedHeaders", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Credential")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Credential", valid_601562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601563: Call_GetDeleteDBParameterGroup_601550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601563.validator(path, query, header, formData, body)
  let scheme = call_601563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601563.url(scheme.get, call_601563.host, call_601563.base,
                         call_601563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601563, url, valid)

proc call*(call_601564: Call_GetDeleteDBParameterGroup_601550;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601565 = newJObject()
  add(query_601565, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601565, "Action", newJString(Action))
  add(query_601565, "Version", newJString(Version))
  result = call_601564.call(nil, query_601565, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_601550(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_601551, base: "/",
    url: url_GetDeleteDBParameterGroup_601552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_601599 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBSecurityGroup_601601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSecurityGroup_601600(path: JsonNode; query: JsonNode;
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
  var valid_601602 = query.getOrDefault("Action")
  valid_601602 = validateParameter(valid_601602, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_601602 != nil:
    section.add "Action", valid_601602
  var valid_601603 = query.getOrDefault("Version")
  valid_601603 = validateParameter(valid_601603, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601603 != nil:
    section.add "Version", valid_601603
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
  var valid_601604 = header.getOrDefault("X-Amz-Date")
  valid_601604 = validateParameter(valid_601604, JString, required = false,
                                 default = nil)
  if valid_601604 != nil:
    section.add "X-Amz-Date", valid_601604
  var valid_601605 = header.getOrDefault("X-Amz-Security-Token")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Security-Token", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Content-Sha256", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Algorithm")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Algorithm", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-Signature")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-Signature", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-SignedHeaders", valid_601609
  var valid_601610 = header.getOrDefault("X-Amz-Credential")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "X-Amz-Credential", valid_601610
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601611 = formData.getOrDefault("DBSecurityGroupName")
  valid_601611 = validateParameter(valid_601611, JString, required = true,
                                 default = nil)
  if valid_601611 != nil:
    section.add "DBSecurityGroupName", valid_601611
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601612: Call_PostDeleteDBSecurityGroup_601599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601612.validator(path, query, header, formData, body)
  let scheme = call_601612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601612.url(scheme.get, call_601612.host, call_601612.base,
                         call_601612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601612, url, valid)

proc call*(call_601613: Call_PostDeleteDBSecurityGroup_601599;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601614 = newJObject()
  var formData_601615 = newJObject()
  add(formData_601615, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601614, "Action", newJString(Action))
  add(query_601614, "Version", newJString(Version))
  result = call_601613.call(nil, query_601614, nil, formData_601615, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_601599(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_601600, base: "/",
    url: url_PostDeleteDBSecurityGroup_601601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_601583 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBSecurityGroup_601585(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSecurityGroup_601584(path: JsonNode; query: JsonNode;
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
  var valid_601586 = query.getOrDefault("DBSecurityGroupName")
  valid_601586 = validateParameter(valid_601586, JString, required = true,
                                 default = nil)
  if valid_601586 != nil:
    section.add "DBSecurityGroupName", valid_601586
  var valid_601587 = query.getOrDefault("Action")
  valid_601587 = validateParameter(valid_601587, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_601587 != nil:
    section.add "Action", valid_601587
  var valid_601588 = query.getOrDefault("Version")
  valid_601588 = validateParameter(valid_601588, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601588 != nil:
    section.add "Version", valid_601588
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
  var valid_601589 = header.getOrDefault("X-Amz-Date")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "X-Amz-Date", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-Security-Token")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Security-Token", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Content-Sha256", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-Algorithm")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-Algorithm", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-Signature")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Signature", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-SignedHeaders", valid_601594
  var valid_601595 = header.getOrDefault("X-Amz-Credential")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "X-Amz-Credential", valid_601595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601596: Call_GetDeleteDBSecurityGroup_601583; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601596.validator(path, query, header, formData, body)
  let scheme = call_601596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601596.url(scheme.get, call_601596.host, call_601596.base,
                         call_601596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601596, url, valid)

proc call*(call_601597: Call_GetDeleteDBSecurityGroup_601583;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601598 = newJObject()
  add(query_601598, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601598, "Action", newJString(Action))
  add(query_601598, "Version", newJString(Version))
  result = call_601597.call(nil, query_601598, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_601583(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_601584, base: "/",
    url: url_GetDeleteDBSecurityGroup_601585, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_601632 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBSnapshot_601634(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSnapshot_601633(path: JsonNode; query: JsonNode;
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
  var valid_601635 = query.getOrDefault("Action")
  valid_601635 = validateParameter(valid_601635, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_601635 != nil:
    section.add "Action", valid_601635
  var valid_601636 = query.getOrDefault("Version")
  valid_601636 = validateParameter(valid_601636, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601636 != nil:
    section.add "Version", valid_601636
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
  var valid_601637 = header.getOrDefault("X-Amz-Date")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-Date", valid_601637
  var valid_601638 = header.getOrDefault("X-Amz-Security-Token")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-Security-Token", valid_601638
  var valid_601639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "X-Amz-Content-Sha256", valid_601639
  var valid_601640 = header.getOrDefault("X-Amz-Algorithm")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "X-Amz-Algorithm", valid_601640
  var valid_601641 = header.getOrDefault("X-Amz-Signature")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "X-Amz-Signature", valid_601641
  var valid_601642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "X-Amz-SignedHeaders", valid_601642
  var valid_601643 = header.getOrDefault("X-Amz-Credential")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "X-Amz-Credential", valid_601643
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_601644 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601644 = validateParameter(valid_601644, JString, required = true,
                                 default = nil)
  if valid_601644 != nil:
    section.add "DBSnapshotIdentifier", valid_601644
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601645: Call_PostDeleteDBSnapshot_601632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601645.validator(path, query, header, formData, body)
  let scheme = call_601645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601645.url(scheme.get, call_601645.host, call_601645.base,
                         call_601645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601645, url, valid)

proc call*(call_601646: Call_PostDeleteDBSnapshot_601632;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601647 = newJObject()
  var formData_601648 = newJObject()
  add(formData_601648, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601647, "Action", newJString(Action))
  add(query_601647, "Version", newJString(Version))
  result = call_601646.call(nil, query_601647, nil, formData_601648, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_601632(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_601633, base: "/",
    url: url_PostDeleteDBSnapshot_601634, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_601616 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBSnapshot_601618(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSnapshot_601617(path: JsonNode; query: JsonNode;
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
  var valid_601619 = query.getOrDefault("Action")
  valid_601619 = validateParameter(valid_601619, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_601619 != nil:
    section.add "Action", valid_601619
  var valid_601620 = query.getOrDefault("Version")
  valid_601620 = validateParameter(valid_601620, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601620 != nil:
    section.add "Version", valid_601620
  var valid_601621 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601621 = validateParameter(valid_601621, JString, required = true,
                                 default = nil)
  if valid_601621 != nil:
    section.add "DBSnapshotIdentifier", valid_601621
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
  var valid_601622 = header.getOrDefault("X-Amz-Date")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Date", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-Security-Token")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Security-Token", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Content-Sha256", valid_601624
  var valid_601625 = header.getOrDefault("X-Amz-Algorithm")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "X-Amz-Algorithm", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-Signature")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Signature", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-SignedHeaders", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Credential")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Credential", valid_601628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601629: Call_GetDeleteDBSnapshot_601616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601629.validator(path, query, header, formData, body)
  let scheme = call_601629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601629.url(scheme.get, call_601629.host, call_601629.base,
                         call_601629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601629, url, valid)

proc call*(call_601630: Call_GetDeleteDBSnapshot_601616;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_601631 = newJObject()
  add(query_601631, "Action", newJString(Action))
  add(query_601631, "Version", newJString(Version))
  add(query_601631, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601630.call(nil, query_601631, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_601616(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_601617, base: "/",
    url: url_GetDeleteDBSnapshot_601618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_601665 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBSubnetGroup_601667(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_601666(path: JsonNode; query: JsonNode;
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
  var valid_601668 = query.getOrDefault("Action")
  valid_601668 = validateParameter(valid_601668, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_601668 != nil:
    section.add "Action", valid_601668
  var valid_601669 = query.getOrDefault("Version")
  valid_601669 = validateParameter(valid_601669, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601669 != nil:
    section.add "Version", valid_601669
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
  var valid_601670 = header.getOrDefault("X-Amz-Date")
  valid_601670 = validateParameter(valid_601670, JString, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "X-Amz-Date", valid_601670
  var valid_601671 = header.getOrDefault("X-Amz-Security-Token")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "X-Amz-Security-Token", valid_601671
  var valid_601672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601672 = validateParameter(valid_601672, JString, required = false,
                                 default = nil)
  if valid_601672 != nil:
    section.add "X-Amz-Content-Sha256", valid_601672
  var valid_601673 = header.getOrDefault("X-Amz-Algorithm")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "X-Amz-Algorithm", valid_601673
  var valid_601674 = header.getOrDefault("X-Amz-Signature")
  valid_601674 = validateParameter(valid_601674, JString, required = false,
                                 default = nil)
  if valid_601674 != nil:
    section.add "X-Amz-Signature", valid_601674
  var valid_601675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601675 = validateParameter(valid_601675, JString, required = false,
                                 default = nil)
  if valid_601675 != nil:
    section.add "X-Amz-SignedHeaders", valid_601675
  var valid_601676 = header.getOrDefault("X-Amz-Credential")
  valid_601676 = validateParameter(valid_601676, JString, required = false,
                                 default = nil)
  if valid_601676 != nil:
    section.add "X-Amz-Credential", valid_601676
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601677 = formData.getOrDefault("DBSubnetGroupName")
  valid_601677 = validateParameter(valid_601677, JString, required = true,
                                 default = nil)
  if valid_601677 != nil:
    section.add "DBSubnetGroupName", valid_601677
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601678: Call_PostDeleteDBSubnetGroup_601665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601678.validator(path, query, header, formData, body)
  let scheme = call_601678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601678.url(scheme.get, call_601678.host, call_601678.base,
                         call_601678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601678, url, valid)

proc call*(call_601679: Call_PostDeleteDBSubnetGroup_601665;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601680 = newJObject()
  var formData_601681 = newJObject()
  add(formData_601681, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601680, "Action", newJString(Action))
  add(query_601680, "Version", newJString(Version))
  result = call_601679.call(nil, query_601680, nil, formData_601681, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_601665(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_601666, base: "/",
    url: url_PostDeleteDBSubnetGroup_601667, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_601649 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBSubnetGroup_601651(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_601650(path: JsonNode; query: JsonNode;
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
  var valid_601652 = query.getOrDefault("Action")
  valid_601652 = validateParameter(valid_601652, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_601652 != nil:
    section.add "Action", valid_601652
  var valid_601653 = query.getOrDefault("DBSubnetGroupName")
  valid_601653 = validateParameter(valid_601653, JString, required = true,
                                 default = nil)
  if valid_601653 != nil:
    section.add "DBSubnetGroupName", valid_601653
  var valid_601654 = query.getOrDefault("Version")
  valid_601654 = validateParameter(valid_601654, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601654 != nil:
    section.add "Version", valid_601654
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
  var valid_601655 = header.getOrDefault("X-Amz-Date")
  valid_601655 = validateParameter(valid_601655, JString, required = false,
                                 default = nil)
  if valid_601655 != nil:
    section.add "X-Amz-Date", valid_601655
  var valid_601656 = header.getOrDefault("X-Amz-Security-Token")
  valid_601656 = validateParameter(valid_601656, JString, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "X-Amz-Security-Token", valid_601656
  var valid_601657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601657 = validateParameter(valid_601657, JString, required = false,
                                 default = nil)
  if valid_601657 != nil:
    section.add "X-Amz-Content-Sha256", valid_601657
  var valid_601658 = header.getOrDefault("X-Amz-Algorithm")
  valid_601658 = validateParameter(valid_601658, JString, required = false,
                                 default = nil)
  if valid_601658 != nil:
    section.add "X-Amz-Algorithm", valid_601658
  var valid_601659 = header.getOrDefault("X-Amz-Signature")
  valid_601659 = validateParameter(valid_601659, JString, required = false,
                                 default = nil)
  if valid_601659 != nil:
    section.add "X-Amz-Signature", valid_601659
  var valid_601660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601660 = validateParameter(valid_601660, JString, required = false,
                                 default = nil)
  if valid_601660 != nil:
    section.add "X-Amz-SignedHeaders", valid_601660
  var valid_601661 = header.getOrDefault("X-Amz-Credential")
  valid_601661 = validateParameter(valid_601661, JString, required = false,
                                 default = nil)
  if valid_601661 != nil:
    section.add "X-Amz-Credential", valid_601661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601662: Call_GetDeleteDBSubnetGroup_601649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601662.validator(path, query, header, formData, body)
  let scheme = call_601662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601662.url(scheme.get, call_601662.host, call_601662.base,
                         call_601662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601662, url, valid)

proc call*(call_601663: Call_GetDeleteDBSubnetGroup_601649;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_601664 = newJObject()
  add(query_601664, "Action", newJString(Action))
  add(query_601664, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601664, "Version", newJString(Version))
  result = call_601663.call(nil, query_601664, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_601649(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_601650, base: "/",
    url: url_GetDeleteDBSubnetGroup_601651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_601698 = ref object of OpenApiRestCall_600421
proc url_PostDeleteEventSubscription_601700(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEventSubscription_601699(path: JsonNode; query: JsonNode;
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
  var valid_601701 = query.getOrDefault("Action")
  valid_601701 = validateParameter(valid_601701, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_601701 != nil:
    section.add "Action", valid_601701
  var valid_601702 = query.getOrDefault("Version")
  valid_601702 = validateParameter(valid_601702, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601702 != nil:
    section.add "Version", valid_601702
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
  var valid_601703 = header.getOrDefault("X-Amz-Date")
  valid_601703 = validateParameter(valid_601703, JString, required = false,
                                 default = nil)
  if valid_601703 != nil:
    section.add "X-Amz-Date", valid_601703
  var valid_601704 = header.getOrDefault("X-Amz-Security-Token")
  valid_601704 = validateParameter(valid_601704, JString, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "X-Amz-Security-Token", valid_601704
  var valid_601705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601705 = validateParameter(valid_601705, JString, required = false,
                                 default = nil)
  if valid_601705 != nil:
    section.add "X-Amz-Content-Sha256", valid_601705
  var valid_601706 = header.getOrDefault("X-Amz-Algorithm")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "X-Amz-Algorithm", valid_601706
  var valid_601707 = header.getOrDefault("X-Amz-Signature")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-Signature", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-SignedHeaders", valid_601708
  var valid_601709 = header.getOrDefault("X-Amz-Credential")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "X-Amz-Credential", valid_601709
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_601710 = formData.getOrDefault("SubscriptionName")
  valid_601710 = validateParameter(valid_601710, JString, required = true,
                                 default = nil)
  if valid_601710 != nil:
    section.add "SubscriptionName", valid_601710
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601711: Call_PostDeleteEventSubscription_601698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601711.validator(path, query, header, formData, body)
  let scheme = call_601711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601711.url(scheme.get, call_601711.host, call_601711.base,
                         call_601711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601711, url, valid)

proc call*(call_601712: Call_PostDeleteEventSubscription_601698;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601713 = newJObject()
  var formData_601714 = newJObject()
  add(formData_601714, "SubscriptionName", newJString(SubscriptionName))
  add(query_601713, "Action", newJString(Action))
  add(query_601713, "Version", newJString(Version))
  result = call_601712.call(nil, query_601713, nil, formData_601714, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_601698(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_601699, base: "/",
    url: url_PostDeleteEventSubscription_601700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_601682 = ref object of OpenApiRestCall_600421
proc url_GetDeleteEventSubscription_601684(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEventSubscription_601683(path: JsonNode; query: JsonNode;
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
  var valid_601685 = query.getOrDefault("Action")
  valid_601685 = validateParameter(valid_601685, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_601685 != nil:
    section.add "Action", valid_601685
  var valid_601686 = query.getOrDefault("SubscriptionName")
  valid_601686 = validateParameter(valid_601686, JString, required = true,
                                 default = nil)
  if valid_601686 != nil:
    section.add "SubscriptionName", valid_601686
  var valid_601687 = query.getOrDefault("Version")
  valid_601687 = validateParameter(valid_601687, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601687 != nil:
    section.add "Version", valid_601687
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
  var valid_601688 = header.getOrDefault("X-Amz-Date")
  valid_601688 = validateParameter(valid_601688, JString, required = false,
                                 default = nil)
  if valid_601688 != nil:
    section.add "X-Amz-Date", valid_601688
  var valid_601689 = header.getOrDefault("X-Amz-Security-Token")
  valid_601689 = validateParameter(valid_601689, JString, required = false,
                                 default = nil)
  if valid_601689 != nil:
    section.add "X-Amz-Security-Token", valid_601689
  var valid_601690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601690 = validateParameter(valid_601690, JString, required = false,
                                 default = nil)
  if valid_601690 != nil:
    section.add "X-Amz-Content-Sha256", valid_601690
  var valid_601691 = header.getOrDefault("X-Amz-Algorithm")
  valid_601691 = validateParameter(valid_601691, JString, required = false,
                                 default = nil)
  if valid_601691 != nil:
    section.add "X-Amz-Algorithm", valid_601691
  var valid_601692 = header.getOrDefault("X-Amz-Signature")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-Signature", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-SignedHeaders", valid_601693
  var valid_601694 = header.getOrDefault("X-Amz-Credential")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "X-Amz-Credential", valid_601694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601695: Call_GetDeleteEventSubscription_601682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601695.validator(path, query, header, formData, body)
  let scheme = call_601695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601695.url(scheme.get, call_601695.host, call_601695.base,
                         call_601695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601695, url, valid)

proc call*(call_601696: Call_GetDeleteEventSubscription_601682;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_601697 = newJObject()
  add(query_601697, "Action", newJString(Action))
  add(query_601697, "SubscriptionName", newJString(SubscriptionName))
  add(query_601697, "Version", newJString(Version))
  result = call_601696.call(nil, query_601697, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_601682(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_601683, base: "/",
    url: url_GetDeleteEventSubscription_601684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_601731 = ref object of OpenApiRestCall_600421
proc url_PostDeleteOptionGroup_601733(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteOptionGroup_601732(path: JsonNode; query: JsonNode;
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
  var valid_601734 = query.getOrDefault("Action")
  valid_601734 = validateParameter(valid_601734, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_601734 != nil:
    section.add "Action", valid_601734
  var valid_601735 = query.getOrDefault("Version")
  valid_601735 = validateParameter(valid_601735, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601735 != nil:
    section.add "Version", valid_601735
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
  var valid_601736 = header.getOrDefault("X-Amz-Date")
  valid_601736 = validateParameter(valid_601736, JString, required = false,
                                 default = nil)
  if valid_601736 != nil:
    section.add "X-Amz-Date", valid_601736
  var valid_601737 = header.getOrDefault("X-Amz-Security-Token")
  valid_601737 = validateParameter(valid_601737, JString, required = false,
                                 default = nil)
  if valid_601737 != nil:
    section.add "X-Amz-Security-Token", valid_601737
  var valid_601738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601738 = validateParameter(valid_601738, JString, required = false,
                                 default = nil)
  if valid_601738 != nil:
    section.add "X-Amz-Content-Sha256", valid_601738
  var valid_601739 = header.getOrDefault("X-Amz-Algorithm")
  valid_601739 = validateParameter(valid_601739, JString, required = false,
                                 default = nil)
  if valid_601739 != nil:
    section.add "X-Amz-Algorithm", valid_601739
  var valid_601740 = header.getOrDefault("X-Amz-Signature")
  valid_601740 = validateParameter(valid_601740, JString, required = false,
                                 default = nil)
  if valid_601740 != nil:
    section.add "X-Amz-Signature", valid_601740
  var valid_601741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "X-Amz-SignedHeaders", valid_601741
  var valid_601742 = header.getOrDefault("X-Amz-Credential")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "X-Amz-Credential", valid_601742
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_601743 = formData.getOrDefault("OptionGroupName")
  valid_601743 = validateParameter(valid_601743, JString, required = true,
                                 default = nil)
  if valid_601743 != nil:
    section.add "OptionGroupName", valid_601743
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601744: Call_PostDeleteOptionGroup_601731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601744.validator(path, query, header, formData, body)
  let scheme = call_601744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601744.url(scheme.get, call_601744.host, call_601744.base,
                         call_601744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601744, url, valid)

proc call*(call_601745: Call_PostDeleteOptionGroup_601731; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601746 = newJObject()
  var formData_601747 = newJObject()
  add(formData_601747, "OptionGroupName", newJString(OptionGroupName))
  add(query_601746, "Action", newJString(Action))
  add(query_601746, "Version", newJString(Version))
  result = call_601745.call(nil, query_601746, nil, formData_601747, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_601731(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_601732, base: "/",
    url: url_PostDeleteOptionGroup_601733, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_601715 = ref object of OpenApiRestCall_600421
proc url_GetDeleteOptionGroup_601717(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteOptionGroup_601716(path: JsonNode; query: JsonNode;
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
  var valid_601718 = query.getOrDefault("OptionGroupName")
  valid_601718 = validateParameter(valid_601718, JString, required = true,
                                 default = nil)
  if valid_601718 != nil:
    section.add "OptionGroupName", valid_601718
  var valid_601719 = query.getOrDefault("Action")
  valid_601719 = validateParameter(valid_601719, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_601719 != nil:
    section.add "Action", valid_601719
  var valid_601720 = query.getOrDefault("Version")
  valid_601720 = validateParameter(valid_601720, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601720 != nil:
    section.add "Version", valid_601720
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
  var valid_601721 = header.getOrDefault("X-Amz-Date")
  valid_601721 = validateParameter(valid_601721, JString, required = false,
                                 default = nil)
  if valid_601721 != nil:
    section.add "X-Amz-Date", valid_601721
  var valid_601722 = header.getOrDefault("X-Amz-Security-Token")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-Security-Token", valid_601722
  var valid_601723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "X-Amz-Content-Sha256", valid_601723
  var valid_601724 = header.getOrDefault("X-Amz-Algorithm")
  valid_601724 = validateParameter(valid_601724, JString, required = false,
                                 default = nil)
  if valid_601724 != nil:
    section.add "X-Amz-Algorithm", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-Signature")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Signature", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-SignedHeaders", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-Credential")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-Credential", valid_601727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601728: Call_GetDeleteOptionGroup_601715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601728.validator(path, query, header, formData, body)
  let scheme = call_601728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601728.url(scheme.get, call_601728.host, call_601728.base,
                         call_601728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601728, url, valid)

proc call*(call_601729: Call_GetDeleteOptionGroup_601715; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601730 = newJObject()
  add(query_601730, "OptionGroupName", newJString(OptionGroupName))
  add(query_601730, "Action", newJString(Action))
  add(query_601730, "Version", newJString(Version))
  result = call_601729.call(nil, query_601730, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_601715(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_601716, base: "/",
    url: url_GetDeleteOptionGroup_601717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_601770 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBEngineVersions_601772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_601771(path: JsonNode; query: JsonNode;
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
  var valid_601773 = query.getOrDefault("Action")
  valid_601773 = validateParameter(valid_601773, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_601773 != nil:
    section.add "Action", valid_601773
  var valid_601774 = query.getOrDefault("Version")
  valid_601774 = validateParameter(valid_601774, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601774 != nil:
    section.add "Version", valid_601774
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
  var valid_601775 = header.getOrDefault("X-Amz-Date")
  valid_601775 = validateParameter(valid_601775, JString, required = false,
                                 default = nil)
  if valid_601775 != nil:
    section.add "X-Amz-Date", valid_601775
  var valid_601776 = header.getOrDefault("X-Amz-Security-Token")
  valid_601776 = validateParameter(valid_601776, JString, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "X-Amz-Security-Token", valid_601776
  var valid_601777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "X-Amz-Content-Sha256", valid_601777
  var valid_601778 = header.getOrDefault("X-Amz-Algorithm")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "X-Amz-Algorithm", valid_601778
  var valid_601779 = header.getOrDefault("X-Amz-Signature")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "X-Amz-Signature", valid_601779
  var valid_601780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-SignedHeaders", valid_601780
  var valid_601781 = header.getOrDefault("X-Amz-Credential")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "X-Amz-Credential", valid_601781
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListSupportedCharacterSets: JBool
  ##   Engine: JString
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   DefaultOnly: JBool
  section = newJObject()
  var valid_601782 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_601782 = validateParameter(valid_601782, JBool, required = false, default = nil)
  if valid_601782 != nil:
    section.add "ListSupportedCharacterSets", valid_601782
  var valid_601783 = formData.getOrDefault("Engine")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "Engine", valid_601783
  var valid_601784 = formData.getOrDefault("Marker")
  valid_601784 = validateParameter(valid_601784, JString, required = false,
                                 default = nil)
  if valid_601784 != nil:
    section.add "Marker", valid_601784
  var valid_601785 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601785 = validateParameter(valid_601785, JString, required = false,
                                 default = nil)
  if valid_601785 != nil:
    section.add "DBParameterGroupFamily", valid_601785
  var valid_601786 = formData.getOrDefault("MaxRecords")
  valid_601786 = validateParameter(valid_601786, JInt, required = false, default = nil)
  if valid_601786 != nil:
    section.add "MaxRecords", valid_601786
  var valid_601787 = formData.getOrDefault("EngineVersion")
  valid_601787 = validateParameter(valid_601787, JString, required = false,
                                 default = nil)
  if valid_601787 != nil:
    section.add "EngineVersion", valid_601787
  var valid_601788 = formData.getOrDefault("DefaultOnly")
  valid_601788 = validateParameter(valid_601788, JBool, required = false, default = nil)
  if valid_601788 != nil:
    section.add "DefaultOnly", valid_601788
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601789: Call_PostDescribeDBEngineVersions_601770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601789.validator(path, query, header, formData, body)
  let scheme = call_601789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601789.url(scheme.get, call_601789.host, call_601789.base,
                         call_601789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601789, url, valid)

proc call*(call_601790: Call_PostDescribeDBEngineVersions_601770;
          ListSupportedCharacterSets: bool = false; Engine: string = "";
          Marker: string = ""; Action: string = "DescribeDBEngineVersions";
          DBParameterGroupFamily: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Version: string = "2013-02-12";
          DefaultOnly: bool = false): Recallable =
  ## postDescribeDBEngineVersions
  ##   ListSupportedCharacterSets: bool
  ##   Engine: string
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Version: string (required)
  ##   DefaultOnly: bool
  var query_601791 = newJObject()
  var formData_601792 = newJObject()
  add(formData_601792, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_601792, "Engine", newJString(Engine))
  add(formData_601792, "Marker", newJString(Marker))
  add(query_601791, "Action", newJString(Action))
  add(formData_601792, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_601792, "MaxRecords", newJInt(MaxRecords))
  add(formData_601792, "EngineVersion", newJString(EngineVersion))
  add(query_601791, "Version", newJString(Version))
  add(formData_601792, "DefaultOnly", newJBool(DefaultOnly))
  result = call_601790.call(nil, query_601791, nil, formData_601792, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_601770(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_601771, base: "/",
    url: url_PostDescribeDBEngineVersions_601772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_601748 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBEngineVersions_601750(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_601749(path: JsonNode; query: JsonNode;
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
  ##   Action: JString (required)
  ##   Marker: JString
  ##   EngineVersion: JString
  ##   DefaultOnly: JBool
  ##   Version: JString (required)
  section = newJObject()
  var valid_601751 = query.getOrDefault("Engine")
  valid_601751 = validateParameter(valid_601751, JString, required = false,
                                 default = nil)
  if valid_601751 != nil:
    section.add "Engine", valid_601751
  var valid_601752 = query.getOrDefault("ListSupportedCharacterSets")
  valid_601752 = validateParameter(valid_601752, JBool, required = false, default = nil)
  if valid_601752 != nil:
    section.add "ListSupportedCharacterSets", valid_601752
  var valid_601753 = query.getOrDefault("MaxRecords")
  valid_601753 = validateParameter(valid_601753, JInt, required = false, default = nil)
  if valid_601753 != nil:
    section.add "MaxRecords", valid_601753
  var valid_601754 = query.getOrDefault("DBParameterGroupFamily")
  valid_601754 = validateParameter(valid_601754, JString, required = false,
                                 default = nil)
  if valid_601754 != nil:
    section.add "DBParameterGroupFamily", valid_601754
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601755 = query.getOrDefault("Action")
  valid_601755 = validateParameter(valid_601755, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_601755 != nil:
    section.add "Action", valid_601755
  var valid_601756 = query.getOrDefault("Marker")
  valid_601756 = validateParameter(valid_601756, JString, required = false,
                                 default = nil)
  if valid_601756 != nil:
    section.add "Marker", valid_601756
  var valid_601757 = query.getOrDefault("EngineVersion")
  valid_601757 = validateParameter(valid_601757, JString, required = false,
                                 default = nil)
  if valid_601757 != nil:
    section.add "EngineVersion", valid_601757
  var valid_601758 = query.getOrDefault("DefaultOnly")
  valid_601758 = validateParameter(valid_601758, JBool, required = false, default = nil)
  if valid_601758 != nil:
    section.add "DefaultOnly", valid_601758
  var valid_601759 = query.getOrDefault("Version")
  valid_601759 = validateParameter(valid_601759, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601759 != nil:
    section.add "Version", valid_601759
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
  var valid_601760 = header.getOrDefault("X-Amz-Date")
  valid_601760 = validateParameter(valid_601760, JString, required = false,
                                 default = nil)
  if valid_601760 != nil:
    section.add "X-Amz-Date", valid_601760
  var valid_601761 = header.getOrDefault("X-Amz-Security-Token")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-Security-Token", valid_601761
  var valid_601762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-Content-Sha256", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Algorithm")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Algorithm", valid_601763
  var valid_601764 = header.getOrDefault("X-Amz-Signature")
  valid_601764 = validateParameter(valid_601764, JString, required = false,
                                 default = nil)
  if valid_601764 != nil:
    section.add "X-Amz-Signature", valid_601764
  var valid_601765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "X-Amz-SignedHeaders", valid_601765
  var valid_601766 = header.getOrDefault("X-Amz-Credential")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-Credential", valid_601766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601767: Call_GetDescribeDBEngineVersions_601748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601767.validator(path, query, header, formData, body)
  let scheme = call_601767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601767.url(scheme.get, call_601767.host, call_601767.base,
                         call_601767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601767, url, valid)

proc call*(call_601768: Call_GetDescribeDBEngineVersions_601748;
          Engine: string = ""; ListSupportedCharacterSets: bool = false;
          MaxRecords: int = 0; DBParameterGroupFamily: string = "";
          Action: string = "DescribeDBEngineVersions"; Marker: string = "";
          EngineVersion: string = ""; DefaultOnly: bool = false;
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBEngineVersions
  ##   Engine: string
  ##   ListSupportedCharacterSets: bool
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string
  ##   Action: string (required)
  ##   Marker: string
  ##   EngineVersion: string
  ##   DefaultOnly: bool
  ##   Version: string (required)
  var query_601769 = newJObject()
  add(query_601769, "Engine", newJString(Engine))
  add(query_601769, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_601769, "MaxRecords", newJInt(MaxRecords))
  add(query_601769, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_601769, "Action", newJString(Action))
  add(query_601769, "Marker", newJString(Marker))
  add(query_601769, "EngineVersion", newJString(EngineVersion))
  add(query_601769, "DefaultOnly", newJBool(DefaultOnly))
  add(query_601769, "Version", newJString(Version))
  result = call_601768.call(nil, query_601769, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_601748(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_601749, base: "/",
    url: url_GetDescribeDBEngineVersions_601750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_601811 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBInstances_601813(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_601812(path: JsonNode; query: JsonNode;
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
  var valid_601814 = query.getOrDefault("Action")
  valid_601814 = validateParameter(valid_601814, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_601814 != nil:
    section.add "Action", valid_601814
  var valid_601815 = query.getOrDefault("Version")
  valid_601815 = validateParameter(valid_601815, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601815 != nil:
    section.add "Version", valid_601815
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
  var valid_601816 = header.getOrDefault("X-Amz-Date")
  valid_601816 = validateParameter(valid_601816, JString, required = false,
                                 default = nil)
  if valid_601816 != nil:
    section.add "X-Amz-Date", valid_601816
  var valid_601817 = header.getOrDefault("X-Amz-Security-Token")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "X-Amz-Security-Token", valid_601817
  var valid_601818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601818 = validateParameter(valid_601818, JString, required = false,
                                 default = nil)
  if valid_601818 != nil:
    section.add "X-Amz-Content-Sha256", valid_601818
  var valid_601819 = header.getOrDefault("X-Amz-Algorithm")
  valid_601819 = validateParameter(valid_601819, JString, required = false,
                                 default = nil)
  if valid_601819 != nil:
    section.add "X-Amz-Algorithm", valid_601819
  var valid_601820 = header.getOrDefault("X-Amz-Signature")
  valid_601820 = validateParameter(valid_601820, JString, required = false,
                                 default = nil)
  if valid_601820 != nil:
    section.add "X-Amz-Signature", valid_601820
  var valid_601821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "X-Amz-SignedHeaders", valid_601821
  var valid_601822 = header.getOrDefault("X-Amz-Credential")
  valid_601822 = validateParameter(valid_601822, JString, required = false,
                                 default = nil)
  if valid_601822 != nil:
    section.add "X-Amz-Credential", valid_601822
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601823 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "DBInstanceIdentifier", valid_601823
  var valid_601824 = formData.getOrDefault("Marker")
  valid_601824 = validateParameter(valid_601824, JString, required = false,
                                 default = nil)
  if valid_601824 != nil:
    section.add "Marker", valid_601824
  var valid_601825 = formData.getOrDefault("MaxRecords")
  valid_601825 = validateParameter(valid_601825, JInt, required = false, default = nil)
  if valid_601825 != nil:
    section.add "MaxRecords", valid_601825
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601826: Call_PostDescribeDBInstances_601811; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601826.validator(path, query, header, formData, body)
  let scheme = call_601826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601826.url(scheme.get, call_601826.host, call_601826.base,
                         call_601826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601826, url, valid)

proc call*(call_601827: Call_PostDescribeDBInstances_601811;
          DBInstanceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeDBInstances"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBInstances
  ##   DBInstanceIdentifier: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_601828 = newJObject()
  var formData_601829 = newJObject()
  add(formData_601829, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601829, "Marker", newJString(Marker))
  add(query_601828, "Action", newJString(Action))
  add(formData_601829, "MaxRecords", newJInt(MaxRecords))
  add(query_601828, "Version", newJString(Version))
  result = call_601827.call(nil, query_601828, nil, formData_601829, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_601811(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_601812, base: "/",
    url: url_PostDescribeDBInstances_601813, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_601793 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBInstances_601795(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_601794(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString
  section = newJObject()
  var valid_601796 = query.getOrDefault("MaxRecords")
  valid_601796 = validateParameter(valid_601796, JInt, required = false, default = nil)
  if valid_601796 != nil:
    section.add "MaxRecords", valid_601796
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601797 = query.getOrDefault("Action")
  valid_601797 = validateParameter(valid_601797, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_601797 != nil:
    section.add "Action", valid_601797
  var valid_601798 = query.getOrDefault("Marker")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "Marker", valid_601798
  var valid_601799 = query.getOrDefault("Version")
  valid_601799 = validateParameter(valid_601799, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601799 != nil:
    section.add "Version", valid_601799
  var valid_601800 = query.getOrDefault("DBInstanceIdentifier")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "DBInstanceIdentifier", valid_601800
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
  var valid_601801 = header.getOrDefault("X-Amz-Date")
  valid_601801 = validateParameter(valid_601801, JString, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "X-Amz-Date", valid_601801
  var valid_601802 = header.getOrDefault("X-Amz-Security-Token")
  valid_601802 = validateParameter(valid_601802, JString, required = false,
                                 default = nil)
  if valid_601802 != nil:
    section.add "X-Amz-Security-Token", valid_601802
  var valid_601803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601803 = validateParameter(valid_601803, JString, required = false,
                                 default = nil)
  if valid_601803 != nil:
    section.add "X-Amz-Content-Sha256", valid_601803
  var valid_601804 = header.getOrDefault("X-Amz-Algorithm")
  valid_601804 = validateParameter(valid_601804, JString, required = false,
                                 default = nil)
  if valid_601804 != nil:
    section.add "X-Amz-Algorithm", valid_601804
  var valid_601805 = header.getOrDefault("X-Amz-Signature")
  valid_601805 = validateParameter(valid_601805, JString, required = false,
                                 default = nil)
  if valid_601805 != nil:
    section.add "X-Amz-Signature", valid_601805
  var valid_601806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601806 = validateParameter(valid_601806, JString, required = false,
                                 default = nil)
  if valid_601806 != nil:
    section.add "X-Amz-SignedHeaders", valid_601806
  var valid_601807 = header.getOrDefault("X-Amz-Credential")
  valid_601807 = validateParameter(valid_601807, JString, required = false,
                                 default = nil)
  if valid_601807 != nil:
    section.add "X-Amz-Credential", valid_601807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601808: Call_GetDescribeDBInstances_601793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601808.validator(path, query, header, formData, body)
  let scheme = call_601808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601808.url(scheme.get, call_601808.host, call_601808.base,
                         call_601808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601808, url, valid)

proc call*(call_601809: Call_GetDescribeDBInstances_601793; MaxRecords: int = 0;
          Action: string = "DescribeDBInstances"; Marker: string = "";
          Version: string = "2013-02-12"; DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  var query_601810 = newJObject()
  add(query_601810, "MaxRecords", newJInt(MaxRecords))
  add(query_601810, "Action", newJString(Action))
  add(query_601810, "Marker", newJString(Marker))
  add(query_601810, "Version", newJString(Version))
  add(query_601810, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601809.call(nil, query_601810, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_601793(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_601794, base: "/",
    url: url_GetDescribeDBInstances_601795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_601851 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBLogFiles_601853(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBLogFiles_601852(path: JsonNode; query: JsonNode;
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
  var valid_601854 = query.getOrDefault("Action")
  valid_601854 = validateParameter(valid_601854, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_601854 != nil:
    section.add "Action", valid_601854
  var valid_601855 = query.getOrDefault("Version")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601855 != nil:
    section.add "Version", valid_601855
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
  var valid_601856 = header.getOrDefault("X-Amz-Date")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Date", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Security-Token")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Security-Token", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Content-Sha256", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Algorithm")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Algorithm", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Signature")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Signature", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Credential")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Credential", valid_601862
  result.add "header", section
  ## parameters in `formData` object:
  ##   FilenameContains: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FileSize: JInt
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_601863 = formData.getOrDefault("FilenameContains")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "FilenameContains", valid_601863
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601864 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601864 = validateParameter(valid_601864, JString, required = true,
                                 default = nil)
  if valid_601864 != nil:
    section.add "DBInstanceIdentifier", valid_601864
  var valid_601865 = formData.getOrDefault("FileSize")
  valid_601865 = validateParameter(valid_601865, JInt, required = false, default = nil)
  if valid_601865 != nil:
    section.add "FileSize", valid_601865
  var valid_601866 = formData.getOrDefault("Marker")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "Marker", valid_601866
  var valid_601867 = formData.getOrDefault("MaxRecords")
  valid_601867 = validateParameter(valid_601867, JInt, required = false, default = nil)
  if valid_601867 != nil:
    section.add "MaxRecords", valid_601867
  var valid_601868 = formData.getOrDefault("FileLastWritten")
  valid_601868 = validateParameter(valid_601868, JInt, required = false, default = nil)
  if valid_601868 != nil:
    section.add "FileLastWritten", valid_601868
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601869: Call_PostDescribeDBLogFiles_601851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601869.validator(path, query, header, formData, body)
  let scheme = call_601869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601869.url(scheme.get, call_601869.host, call_601869.base,
                         call_601869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601869, url, valid)

proc call*(call_601870: Call_PostDescribeDBLogFiles_601851;
          DBInstanceIdentifier: string; FilenameContains: string = "";
          FileSize: int = 0; Marker: string = ""; Action: string = "DescribeDBLogFiles";
          MaxRecords: int = 0; FileLastWritten: int = 0; Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBLogFiles
  ##   FilenameContains: string
  ##   DBInstanceIdentifier: string (required)
  ##   FileSize: int
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   FileLastWritten: int
  ##   Version: string (required)
  var query_601871 = newJObject()
  var formData_601872 = newJObject()
  add(formData_601872, "FilenameContains", newJString(FilenameContains))
  add(formData_601872, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601872, "FileSize", newJInt(FileSize))
  add(formData_601872, "Marker", newJString(Marker))
  add(query_601871, "Action", newJString(Action))
  add(formData_601872, "MaxRecords", newJInt(MaxRecords))
  add(formData_601872, "FileLastWritten", newJInt(FileLastWritten))
  add(query_601871, "Version", newJString(Version))
  result = call_601870.call(nil, query_601871, nil, formData_601872, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_601851(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_601852, base: "/",
    url: url_PostDescribeDBLogFiles_601853, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_601830 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBLogFiles_601832(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBLogFiles_601831(path: JsonNode; query: JsonNode;
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
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_601833 = query.getOrDefault("FileLastWritten")
  valid_601833 = validateParameter(valid_601833, JInt, required = false, default = nil)
  if valid_601833 != nil:
    section.add "FileLastWritten", valid_601833
  var valid_601834 = query.getOrDefault("MaxRecords")
  valid_601834 = validateParameter(valid_601834, JInt, required = false, default = nil)
  if valid_601834 != nil:
    section.add "MaxRecords", valid_601834
  var valid_601835 = query.getOrDefault("FilenameContains")
  valid_601835 = validateParameter(valid_601835, JString, required = false,
                                 default = nil)
  if valid_601835 != nil:
    section.add "FilenameContains", valid_601835
  var valid_601836 = query.getOrDefault("FileSize")
  valid_601836 = validateParameter(valid_601836, JInt, required = false, default = nil)
  if valid_601836 != nil:
    section.add "FileSize", valid_601836
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601837 = query.getOrDefault("Action")
  valid_601837 = validateParameter(valid_601837, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_601837 != nil:
    section.add "Action", valid_601837
  var valid_601838 = query.getOrDefault("Marker")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "Marker", valid_601838
  var valid_601839 = query.getOrDefault("Version")
  valid_601839 = validateParameter(valid_601839, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601839 != nil:
    section.add "Version", valid_601839
  var valid_601840 = query.getOrDefault("DBInstanceIdentifier")
  valid_601840 = validateParameter(valid_601840, JString, required = true,
                                 default = nil)
  if valid_601840 != nil:
    section.add "DBInstanceIdentifier", valid_601840
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
  var valid_601841 = header.getOrDefault("X-Amz-Date")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Date", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Security-Token")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Security-Token", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Content-Sha256", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Algorithm")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Algorithm", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Signature")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Signature", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-SignedHeaders", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Credential")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Credential", valid_601847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601848: Call_GetDescribeDBLogFiles_601830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601848.validator(path, query, header, formData, body)
  let scheme = call_601848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601848.url(scheme.get, call_601848.host, call_601848.base,
                         call_601848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601848, url, valid)

proc call*(call_601849: Call_GetDescribeDBLogFiles_601830;
          DBInstanceIdentifier: string; FileLastWritten: int = 0; MaxRecords: int = 0;
          FilenameContains: string = ""; FileSize: int = 0;
          Action: string = "DescribeDBLogFiles"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBLogFiles
  ##   FileLastWritten: int
  ##   MaxRecords: int
  ##   FilenameContains: string
  ##   FileSize: int
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601850 = newJObject()
  add(query_601850, "FileLastWritten", newJInt(FileLastWritten))
  add(query_601850, "MaxRecords", newJInt(MaxRecords))
  add(query_601850, "FilenameContains", newJString(FilenameContains))
  add(query_601850, "FileSize", newJInt(FileSize))
  add(query_601850, "Action", newJString(Action))
  add(query_601850, "Marker", newJString(Marker))
  add(query_601850, "Version", newJString(Version))
  add(query_601850, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601849.call(nil, query_601850, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_601830(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_601831, base: "/",
    url: url_GetDescribeDBLogFiles_601832, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_601891 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBParameterGroups_601893(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_601892(path: JsonNode; query: JsonNode;
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
  var valid_601894 = query.getOrDefault("Action")
  valid_601894 = validateParameter(valid_601894, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_601894 != nil:
    section.add "Action", valid_601894
  var valid_601895 = query.getOrDefault("Version")
  valid_601895 = validateParameter(valid_601895, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601895 != nil:
    section.add "Version", valid_601895
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
  var valid_601896 = header.getOrDefault("X-Amz-Date")
  valid_601896 = validateParameter(valid_601896, JString, required = false,
                                 default = nil)
  if valid_601896 != nil:
    section.add "X-Amz-Date", valid_601896
  var valid_601897 = header.getOrDefault("X-Amz-Security-Token")
  valid_601897 = validateParameter(valid_601897, JString, required = false,
                                 default = nil)
  if valid_601897 != nil:
    section.add "X-Amz-Security-Token", valid_601897
  var valid_601898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601898 = validateParameter(valid_601898, JString, required = false,
                                 default = nil)
  if valid_601898 != nil:
    section.add "X-Amz-Content-Sha256", valid_601898
  var valid_601899 = header.getOrDefault("X-Amz-Algorithm")
  valid_601899 = validateParameter(valid_601899, JString, required = false,
                                 default = nil)
  if valid_601899 != nil:
    section.add "X-Amz-Algorithm", valid_601899
  var valid_601900 = header.getOrDefault("X-Amz-Signature")
  valid_601900 = validateParameter(valid_601900, JString, required = false,
                                 default = nil)
  if valid_601900 != nil:
    section.add "X-Amz-Signature", valid_601900
  var valid_601901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "X-Amz-SignedHeaders", valid_601901
  var valid_601902 = header.getOrDefault("X-Amz-Credential")
  valid_601902 = validateParameter(valid_601902, JString, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "X-Amz-Credential", valid_601902
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601903 = formData.getOrDefault("DBParameterGroupName")
  valid_601903 = validateParameter(valid_601903, JString, required = false,
                                 default = nil)
  if valid_601903 != nil:
    section.add "DBParameterGroupName", valid_601903
  var valid_601904 = formData.getOrDefault("Marker")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "Marker", valid_601904
  var valid_601905 = formData.getOrDefault("MaxRecords")
  valid_601905 = validateParameter(valid_601905, JInt, required = false, default = nil)
  if valid_601905 != nil:
    section.add "MaxRecords", valid_601905
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601906: Call_PostDescribeDBParameterGroups_601891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601906.validator(path, query, header, formData, body)
  let scheme = call_601906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601906.url(scheme.get, call_601906.host, call_601906.base,
                         call_601906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601906, url, valid)

proc call*(call_601907: Call_PostDescribeDBParameterGroups_601891;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_601908 = newJObject()
  var formData_601909 = newJObject()
  add(formData_601909, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601909, "Marker", newJString(Marker))
  add(query_601908, "Action", newJString(Action))
  add(formData_601909, "MaxRecords", newJInt(MaxRecords))
  add(query_601908, "Version", newJString(Version))
  result = call_601907.call(nil, query_601908, nil, formData_601909, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_601891(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_601892, base: "/",
    url: url_PostDescribeDBParameterGroups_601893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_601873 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBParameterGroups_601875(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_601874(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_601876 = query.getOrDefault("MaxRecords")
  valid_601876 = validateParameter(valid_601876, JInt, required = false, default = nil)
  if valid_601876 != nil:
    section.add "MaxRecords", valid_601876
  var valid_601877 = query.getOrDefault("DBParameterGroupName")
  valid_601877 = validateParameter(valid_601877, JString, required = false,
                                 default = nil)
  if valid_601877 != nil:
    section.add "DBParameterGroupName", valid_601877
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601878 = query.getOrDefault("Action")
  valid_601878 = validateParameter(valid_601878, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_601878 != nil:
    section.add "Action", valid_601878
  var valid_601879 = query.getOrDefault("Marker")
  valid_601879 = validateParameter(valid_601879, JString, required = false,
                                 default = nil)
  if valid_601879 != nil:
    section.add "Marker", valid_601879
  var valid_601880 = query.getOrDefault("Version")
  valid_601880 = validateParameter(valid_601880, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601880 != nil:
    section.add "Version", valid_601880
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
  var valid_601881 = header.getOrDefault("X-Amz-Date")
  valid_601881 = validateParameter(valid_601881, JString, required = false,
                                 default = nil)
  if valid_601881 != nil:
    section.add "X-Amz-Date", valid_601881
  var valid_601882 = header.getOrDefault("X-Amz-Security-Token")
  valid_601882 = validateParameter(valid_601882, JString, required = false,
                                 default = nil)
  if valid_601882 != nil:
    section.add "X-Amz-Security-Token", valid_601882
  var valid_601883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601883 = validateParameter(valid_601883, JString, required = false,
                                 default = nil)
  if valid_601883 != nil:
    section.add "X-Amz-Content-Sha256", valid_601883
  var valid_601884 = header.getOrDefault("X-Amz-Algorithm")
  valid_601884 = validateParameter(valid_601884, JString, required = false,
                                 default = nil)
  if valid_601884 != nil:
    section.add "X-Amz-Algorithm", valid_601884
  var valid_601885 = header.getOrDefault("X-Amz-Signature")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "X-Amz-Signature", valid_601885
  var valid_601886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "X-Amz-SignedHeaders", valid_601886
  var valid_601887 = header.getOrDefault("X-Amz-Credential")
  valid_601887 = validateParameter(valid_601887, JString, required = false,
                                 default = nil)
  if valid_601887 != nil:
    section.add "X-Amz-Credential", valid_601887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601888: Call_GetDescribeDBParameterGroups_601873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601888.validator(path, query, header, formData, body)
  let scheme = call_601888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601888.url(scheme.get, call_601888.host, call_601888.base,
                         call_601888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601888, url, valid)

proc call*(call_601889: Call_GetDescribeDBParameterGroups_601873;
          MaxRecords: int = 0; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_601890 = newJObject()
  add(query_601890, "MaxRecords", newJInt(MaxRecords))
  add(query_601890, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601890, "Action", newJString(Action))
  add(query_601890, "Marker", newJString(Marker))
  add(query_601890, "Version", newJString(Version))
  result = call_601889.call(nil, query_601890, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_601873(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_601874, base: "/",
    url: url_GetDescribeDBParameterGroups_601875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_601929 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBParameters_601931(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_601930(path: JsonNode; query: JsonNode;
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
  var valid_601932 = query.getOrDefault("Action")
  valid_601932 = validateParameter(valid_601932, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_601932 != nil:
    section.add "Action", valid_601932
  var valid_601933 = query.getOrDefault("Version")
  valid_601933 = validateParameter(valid_601933, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601933 != nil:
    section.add "Version", valid_601933
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
  var valid_601934 = header.getOrDefault("X-Amz-Date")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "X-Amz-Date", valid_601934
  var valid_601935 = header.getOrDefault("X-Amz-Security-Token")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "X-Amz-Security-Token", valid_601935
  var valid_601936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "X-Amz-Content-Sha256", valid_601936
  var valid_601937 = header.getOrDefault("X-Amz-Algorithm")
  valid_601937 = validateParameter(valid_601937, JString, required = false,
                                 default = nil)
  if valid_601937 != nil:
    section.add "X-Amz-Algorithm", valid_601937
  var valid_601938 = header.getOrDefault("X-Amz-Signature")
  valid_601938 = validateParameter(valid_601938, JString, required = false,
                                 default = nil)
  if valid_601938 != nil:
    section.add "X-Amz-Signature", valid_601938
  var valid_601939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601939 = validateParameter(valid_601939, JString, required = false,
                                 default = nil)
  if valid_601939 != nil:
    section.add "X-Amz-SignedHeaders", valid_601939
  var valid_601940 = header.getOrDefault("X-Amz-Credential")
  valid_601940 = validateParameter(valid_601940, JString, required = false,
                                 default = nil)
  if valid_601940 != nil:
    section.add "X-Amz-Credential", valid_601940
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601941 = formData.getOrDefault("DBParameterGroupName")
  valid_601941 = validateParameter(valid_601941, JString, required = true,
                                 default = nil)
  if valid_601941 != nil:
    section.add "DBParameterGroupName", valid_601941
  var valid_601942 = formData.getOrDefault("Marker")
  valid_601942 = validateParameter(valid_601942, JString, required = false,
                                 default = nil)
  if valid_601942 != nil:
    section.add "Marker", valid_601942
  var valid_601943 = formData.getOrDefault("MaxRecords")
  valid_601943 = validateParameter(valid_601943, JInt, required = false, default = nil)
  if valid_601943 != nil:
    section.add "MaxRecords", valid_601943
  var valid_601944 = formData.getOrDefault("Source")
  valid_601944 = validateParameter(valid_601944, JString, required = false,
                                 default = nil)
  if valid_601944 != nil:
    section.add "Source", valid_601944
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601945: Call_PostDescribeDBParameters_601929; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601945.validator(path, query, header, formData, body)
  let scheme = call_601945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601945.url(scheme.get, call_601945.host, call_601945.base,
                         call_601945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601945, url, valid)

proc call*(call_601946: Call_PostDescribeDBParameters_601929;
          DBParameterGroupName: string; Marker: string = "";
          Action: string = "DescribeDBParameters"; MaxRecords: int = 0;
          Version: string = "2013-02-12"; Source: string = ""): Recallable =
  ## postDescribeDBParameters
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  ##   Source: string
  var query_601947 = newJObject()
  var formData_601948 = newJObject()
  add(formData_601948, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601948, "Marker", newJString(Marker))
  add(query_601947, "Action", newJString(Action))
  add(formData_601948, "MaxRecords", newJInt(MaxRecords))
  add(query_601947, "Version", newJString(Version))
  add(formData_601948, "Source", newJString(Source))
  result = call_601946.call(nil, query_601947, nil, formData_601948, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_601929(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_601930, base: "/",
    url: url_PostDescribeDBParameters_601931, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_601910 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBParameters_601912(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_601911(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Source: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_601913 = query.getOrDefault("MaxRecords")
  valid_601913 = validateParameter(valid_601913, JInt, required = false, default = nil)
  if valid_601913 != nil:
    section.add "MaxRecords", valid_601913
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_601914 = query.getOrDefault("DBParameterGroupName")
  valid_601914 = validateParameter(valid_601914, JString, required = true,
                                 default = nil)
  if valid_601914 != nil:
    section.add "DBParameterGroupName", valid_601914
  var valid_601915 = query.getOrDefault("Action")
  valid_601915 = validateParameter(valid_601915, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_601915 != nil:
    section.add "Action", valid_601915
  var valid_601916 = query.getOrDefault("Marker")
  valid_601916 = validateParameter(valid_601916, JString, required = false,
                                 default = nil)
  if valid_601916 != nil:
    section.add "Marker", valid_601916
  var valid_601917 = query.getOrDefault("Source")
  valid_601917 = validateParameter(valid_601917, JString, required = false,
                                 default = nil)
  if valid_601917 != nil:
    section.add "Source", valid_601917
  var valid_601918 = query.getOrDefault("Version")
  valid_601918 = validateParameter(valid_601918, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601918 != nil:
    section.add "Version", valid_601918
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
  var valid_601919 = header.getOrDefault("X-Amz-Date")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "X-Amz-Date", valid_601919
  var valid_601920 = header.getOrDefault("X-Amz-Security-Token")
  valid_601920 = validateParameter(valid_601920, JString, required = false,
                                 default = nil)
  if valid_601920 != nil:
    section.add "X-Amz-Security-Token", valid_601920
  var valid_601921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601921 = validateParameter(valid_601921, JString, required = false,
                                 default = nil)
  if valid_601921 != nil:
    section.add "X-Amz-Content-Sha256", valid_601921
  var valid_601922 = header.getOrDefault("X-Amz-Algorithm")
  valid_601922 = validateParameter(valid_601922, JString, required = false,
                                 default = nil)
  if valid_601922 != nil:
    section.add "X-Amz-Algorithm", valid_601922
  var valid_601923 = header.getOrDefault("X-Amz-Signature")
  valid_601923 = validateParameter(valid_601923, JString, required = false,
                                 default = nil)
  if valid_601923 != nil:
    section.add "X-Amz-Signature", valid_601923
  var valid_601924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601924 = validateParameter(valid_601924, JString, required = false,
                                 default = nil)
  if valid_601924 != nil:
    section.add "X-Amz-SignedHeaders", valid_601924
  var valid_601925 = header.getOrDefault("X-Amz-Credential")
  valid_601925 = validateParameter(valid_601925, JString, required = false,
                                 default = nil)
  if valid_601925 != nil:
    section.add "X-Amz-Credential", valid_601925
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601926: Call_GetDescribeDBParameters_601910; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601926.validator(path, query, header, formData, body)
  let scheme = call_601926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601926.url(scheme.get, call_601926.host, call_601926.base,
                         call_601926.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601926, url, valid)

proc call*(call_601927: Call_GetDescribeDBParameters_601910;
          DBParameterGroupName: string; MaxRecords: int = 0;
          Action: string = "DescribeDBParameters"; Marker: string = "";
          Source: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBParameters
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Source: string
  ##   Version: string (required)
  var query_601928 = newJObject()
  add(query_601928, "MaxRecords", newJInt(MaxRecords))
  add(query_601928, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601928, "Action", newJString(Action))
  add(query_601928, "Marker", newJString(Marker))
  add(query_601928, "Source", newJString(Source))
  add(query_601928, "Version", newJString(Version))
  result = call_601927.call(nil, query_601928, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_601910(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_601911, base: "/",
    url: url_GetDescribeDBParameters_601912, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_601967 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBSecurityGroups_601969(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_601968(path: JsonNode; query: JsonNode;
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
  var valid_601970 = query.getOrDefault("Action")
  valid_601970 = validateParameter(valid_601970, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_601970 != nil:
    section.add "Action", valid_601970
  var valid_601971 = query.getOrDefault("Version")
  valid_601971 = validateParameter(valid_601971, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601971 != nil:
    section.add "Version", valid_601971
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
  var valid_601972 = header.getOrDefault("X-Amz-Date")
  valid_601972 = validateParameter(valid_601972, JString, required = false,
                                 default = nil)
  if valid_601972 != nil:
    section.add "X-Amz-Date", valid_601972
  var valid_601973 = header.getOrDefault("X-Amz-Security-Token")
  valid_601973 = validateParameter(valid_601973, JString, required = false,
                                 default = nil)
  if valid_601973 != nil:
    section.add "X-Amz-Security-Token", valid_601973
  var valid_601974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601974 = validateParameter(valid_601974, JString, required = false,
                                 default = nil)
  if valid_601974 != nil:
    section.add "X-Amz-Content-Sha256", valid_601974
  var valid_601975 = header.getOrDefault("X-Amz-Algorithm")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = nil)
  if valid_601975 != nil:
    section.add "X-Amz-Algorithm", valid_601975
  var valid_601976 = header.getOrDefault("X-Amz-Signature")
  valid_601976 = validateParameter(valid_601976, JString, required = false,
                                 default = nil)
  if valid_601976 != nil:
    section.add "X-Amz-Signature", valid_601976
  var valid_601977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "X-Amz-SignedHeaders", valid_601977
  var valid_601978 = header.getOrDefault("X-Amz-Credential")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "X-Amz-Credential", valid_601978
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601979 = formData.getOrDefault("DBSecurityGroupName")
  valid_601979 = validateParameter(valid_601979, JString, required = false,
                                 default = nil)
  if valid_601979 != nil:
    section.add "DBSecurityGroupName", valid_601979
  var valid_601980 = formData.getOrDefault("Marker")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "Marker", valid_601980
  var valid_601981 = formData.getOrDefault("MaxRecords")
  valid_601981 = validateParameter(valid_601981, JInt, required = false, default = nil)
  if valid_601981 != nil:
    section.add "MaxRecords", valid_601981
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601982: Call_PostDescribeDBSecurityGroups_601967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601982.validator(path, query, header, formData, body)
  let scheme = call_601982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601982.url(scheme.get, call_601982.host, call_601982.base,
                         call_601982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601982, url, valid)

proc call*(call_601983: Call_PostDescribeDBSecurityGroups_601967;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_601984 = newJObject()
  var formData_601985 = newJObject()
  add(formData_601985, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_601985, "Marker", newJString(Marker))
  add(query_601984, "Action", newJString(Action))
  add(formData_601985, "MaxRecords", newJInt(MaxRecords))
  add(query_601984, "Version", newJString(Version))
  result = call_601983.call(nil, query_601984, nil, formData_601985, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_601967(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_601968, base: "/",
    url: url_PostDescribeDBSecurityGroups_601969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_601949 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBSecurityGroups_601951(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_601950(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   DBSecurityGroupName: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_601952 = query.getOrDefault("MaxRecords")
  valid_601952 = validateParameter(valid_601952, JInt, required = false, default = nil)
  if valid_601952 != nil:
    section.add "MaxRecords", valid_601952
  var valid_601953 = query.getOrDefault("DBSecurityGroupName")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "DBSecurityGroupName", valid_601953
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601954 = query.getOrDefault("Action")
  valid_601954 = validateParameter(valid_601954, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_601954 != nil:
    section.add "Action", valid_601954
  var valid_601955 = query.getOrDefault("Marker")
  valid_601955 = validateParameter(valid_601955, JString, required = false,
                                 default = nil)
  if valid_601955 != nil:
    section.add "Marker", valid_601955
  var valid_601956 = query.getOrDefault("Version")
  valid_601956 = validateParameter(valid_601956, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601956 != nil:
    section.add "Version", valid_601956
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
  var valid_601957 = header.getOrDefault("X-Amz-Date")
  valid_601957 = validateParameter(valid_601957, JString, required = false,
                                 default = nil)
  if valid_601957 != nil:
    section.add "X-Amz-Date", valid_601957
  var valid_601958 = header.getOrDefault("X-Amz-Security-Token")
  valid_601958 = validateParameter(valid_601958, JString, required = false,
                                 default = nil)
  if valid_601958 != nil:
    section.add "X-Amz-Security-Token", valid_601958
  var valid_601959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601959 = validateParameter(valid_601959, JString, required = false,
                                 default = nil)
  if valid_601959 != nil:
    section.add "X-Amz-Content-Sha256", valid_601959
  var valid_601960 = header.getOrDefault("X-Amz-Algorithm")
  valid_601960 = validateParameter(valid_601960, JString, required = false,
                                 default = nil)
  if valid_601960 != nil:
    section.add "X-Amz-Algorithm", valid_601960
  var valid_601961 = header.getOrDefault("X-Amz-Signature")
  valid_601961 = validateParameter(valid_601961, JString, required = false,
                                 default = nil)
  if valid_601961 != nil:
    section.add "X-Amz-Signature", valid_601961
  var valid_601962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601962 = validateParameter(valid_601962, JString, required = false,
                                 default = nil)
  if valid_601962 != nil:
    section.add "X-Amz-SignedHeaders", valid_601962
  var valid_601963 = header.getOrDefault("X-Amz-Credential")
  valid_601963 = validateParameter(valid_601963, JString, required = false,
                                 default = nil)
  if valid_601963 != nil:
    section.add "X-Amz-Credential", valid_601963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601964: Call_GetDescribeDBSecurityGroups_601949; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601964.validator(path, query, header, formData, body)
  let scheme = call_601964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601964.url(scheme.get, call_601964.host, call_601964.base,
                         call_601964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601964, url, valid)

proc call*(call_601965: Call_GetDescribeDBSecurityGroups_601949;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_601966 = newJObject()
  add(query_601966, "MaxRecords", newJInt(MaxRecords))
  add(query_601966, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601966, "Action", newJString(Action))
  add(query_601966, "Marker", newJString(Marker))
  add(query_601966, "Version", newJString(Version))
  result = call_601965.call(nil, query_601966, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_601949(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_601950, base: "/",
    url: url_GetDescribeDBSecurityGroups_601951,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_602006 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBSnapshots_602008(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSnapshots_602007(path: JsonNode; query: JsonNode;
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
  var valid_602009 = query.getOrDefault("Action")
  valid_602009 = validateParameter(valid_602009, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602009 != nil:
    section.add "Action", valid_602009
  var valid_602010 = query.getOrDefault("Version")
  valid_602010 = validateParameter(valid_602010, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602010 != nil:
    section.add "Version", valid_602010
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
  var valid_602011 = header.getOrDefault("X-Amz-Date")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Date", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Security-Token")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Security-Token", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Content-Sha256", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-Algorithm")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-Algorithm", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-SignedHeaders", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Credential")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Credential", valid_602017
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602018 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "DBInstanceIdentifier", valid_602018
  var valid_602019 = formData.getOrDefault("SnapshotType")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "SnapshotType", valid_602019
  var valid_602020 = formData.getOrDefault("Marker")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "Marker", valid_602020
  var valid_602021 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "DBSnapshotIdentifier", valid_602021
  var valid_602022 = formData.getOrDefault("MaxRecords")
  valid_602022 = validateParameter(valid_602022, JInt, required = false, default = nil)
  if valid_602022 != nil:
    section.add "MaxRecords", valid_602022
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_PostDescribeDBSnapshots_602006; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602023, url, valid)

proc call*(call_602024: Call_PostDescribeDBSnapshots_602006;
          DBInstanceIdentifier: string = ""; SnapshotType: string = "";
          Marker: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSnapshots
  ##   DBInstanceIdentifier: string
  ##   SnapshotType: string
  ##   Marker: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_602025 = newJObject()
  var formData_602026 = newJObject()
  add(formData_602026, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602026, "SnapshotType", newJString(SnapshotType))
  add(formData_602026, "Marker", newJString(Marker))
  add(formData_602026, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602025, "Action", newJString(Action))
  add(formData_602026, "MaxRecords", newJInt(MaxRecords))
  add(query_602025, "Version", newJString(Version))
  result = call_602024.call(nil, query_602025, nil, formData_602026, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_602006(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_602007, base: "/",
    url: url_PostDescribeDBSnapshots_602008, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_601986 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBSnapshots_601988(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_601987(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Action: JString (required)
  ##   Marker: JString
  ##   SnapshotType: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  section = newJObject()
  var valid_601989 = query.getOrDefault("MaxRecords")
  valid_601989 = validateParameter(valid_601989, JInt, required = false, default = nil)
  if valid_601989 != nil:
    section.add "MaxRecords", valid_601989
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601990 = query.getOrDefault("Action")
  valid_601990 = validateParameter(valid_601990, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_601990 != nil:
    section.add "Action", valid_601990
  var valid_601991 = query.getOrDefault("Marker")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "Marker", valid_601991
  var valid_601992 = query.getOrDefault("SnapshotType")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "SnapshotType", valid_601992
  var valid_601993 = query.getOrDefault("Version")
  valid_601993 = validateParameter(valid_601993, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601993 != nil:
    section.add "Version", valid_601993
  var valid_601994 = query.getOrDefault("DBInstanceIdentifier")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "DBInstanceIdentifier", valid_601994
  var valid_601995 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "DBSnapshotIdentifier", valid_601995
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
  var valid_601996 = header.getOrDefault("X-Amz-Date")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Date", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-Security-Token")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-Security-Token", valid_601997
  var valid_601998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-Content-Sha256", valid_601998
  var valid_601999 = header.getOrDefault("X-Amz-Algorithm")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-Algorithm", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-SignedHeaders", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Credential")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Credential", valid_602002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602003: Call_GetDescribeDBSnapshots_601986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602003.validator(path, query, header, formData, body)
  let scheme = call_602003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602003.url(scheme.get, call_602003.host, call_602003.base,
                         call_602003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602003, url, valid)

proc call*(call_602004: Call_GetDescribeDBSnapshots_601986; MaxRecords: int = 0;
          Action: string = "DescribeDBSnapshots"; Marker: string = "";
          SnapshotType: string = ""; Version: string = "2013-02-12";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = ""): Recallable =
  ## getDescribeDBSnapshots
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SnapshotType: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  var query_602005 = newJObject()
  add(query_602005, "MaxRecords", newJInt(MaxRecords))
  add(query_602005, "Action", newJString(Action))
  add(query_602005, "Marker", newJString(Marker))
  add(query_602005, "SnapshotType", newJString(SnapshotType))
  add(query_602005, "Version", newJString(Version))
  add(query_602005, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602005, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_602004.call(nil, query_602005, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_601986(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_601987, base: "/",
    url: url_GetDescribeDBSnapshots_601988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_602045 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBSubnetGroups_602047(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_602046(path: JsonNode; query: JsonNode;
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
  var valid_602048 = query.getOrDefault("Action")
  valid_602048 = validateParameter(valid_602048, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602048 != nil:
    section.add "Action", valid_602048
  var valid_602049 = query.getOrDefault("Version")
  valid_602049 = validateParameter(valid_602049, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602049 != nil:
    section.add "Version", valid_602049
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
  var valid_602050 = header.getOrDefault("X-Amz-Date")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Date", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Security-Token")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Security-Token", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Content-Sha256", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Algorithm")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Algorithm", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Signature")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Signature", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-SignedHeaders", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Credential")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Credential", valid_602056
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602057 = formData.getOrDefault("DBSubnetGroupName")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "DBSubnetGroupName", valid_602057
  var valid_602058 = formData.getOrDefault("Marker")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "Marker", valid_602058
  var valid_602059 = formData.getOrDefault("MaxRecords")
  valid_602059 = validateParameter(valid_602059, JInt, required = false, default = nil)
  if valid_602059 != nil:
    section.add "MaxRecords", valid_602059
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602060: Call_PostDescribeDBSubnetGroups_602045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602060.validator(path, query, header, formData, body)
  let scheme = call_602060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602060.url(scheme.get, call_602060.host, call_602060.base,
                         call_602060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602060, url, valid)

proc call*(call_602061: Call_PostDescribeDBSubnetGroups_602045;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_602062 = newJObject()
  var formData_602063 = newJObject()
  add(formData_602063, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602063, "Marker", newJString(Marker))
  add(query_602062, "Action", newJString(Action))
  add(formData_602063, "MaxRecords", newJInt(MaxRecords))
  add(query_602062, "Version", newJString(Version))
  result = call_602061.call(nil, query_602062, nil, formData_602063, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_602045(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_602046, base: "/",
    url: url_PostDescribeDBSubnetGroups_602047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_602027 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBSubnetGroups_602029(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_602028(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Action: JString (required)
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_602030 = query.getOrDefault("MaxRecords")
  valid_602030 = validateParameter(valid_602030, JInt, required = false, default = nil)
  if valid_602030 != nil:
    section.add "MaxRecords", valid_602030
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602031 = query.getOrDefault("Action")
  valid_602031 = validateParameter(valid_602031, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602031 != nil:
    section.add "Action", valid_602031
  var valid_602032 = query.getOrDefault("Marker")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "Marker", valid_602032
  var valid_602033 = query.getOrDefault("DBSubnetGroupName")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "DBSubnetGroupName", valid_602033
  var valid_602034 = query.getOrDefault("Version")
  valid_602034 = validateParameter(valid_602034, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602034 != nil:
    section.add "Version", valid_602034
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
  var valid_602035 = header.getOrDefault("X-Amz-Date")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Date", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Security-Token")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Security-Token", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Content-Sha256", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Algorithm")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Algorithm", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Signature")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Signature", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-SignedHeaders", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Credential")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Credential", valid_602041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602042: Call_GetDescribeDBSubnetGroups_602027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602042.validator(path, query, header, formData, body)
  let scheme = call_602042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602042.url(scheme.get, call_602042.host, call_602042.base,
                         call_602042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602042, url, valid)

proc call*(call_602043: Call_GetDescribeDBSubnetGroups_602027; MaxRecords: int = 0;
          Action: string = "DescribeDBSubnetGroups"; Marker: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_602044 = newJObject()
  add(query_602044, "MaxRecords", newJInt(MaxRecords))
  add(query_602044, "Action", newJString(Action))
  add(query_602044, "Marker", newJString(Marker))
  add(query_602044, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602044, "Version", newJString(Version))
  result = call_602043.call(nil, query_602044, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_602027(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_602028, base: "/",
    url: url_GetDescribeDBSubnetGroups_602029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_602082 = ref object of OpenApiRestCall_600421
proc url_PostDescribeEngineDefaultParameters_602084(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_602083(path: JsonNode;
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
  var valid_602085 = query.getOrDefault("Action")
  valid_602085 = validateParameter(valid_602085, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602085 != nil:
    section.add "Action", valid_602085
  var valid_602086 = query.getOrDefault("Version")
  valid_602086 = validateParameter(valid_602086, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602086 != nil:
    section.add "Version", valid_602086
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
  var valid_602087 = header.getOrDefault("X-Amz-Date")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Date", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Security-Token")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Security-Token", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Content-Sha256", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Algorithm")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Algorithm", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Signature")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Signature", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-SignedHeaders", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602094 = formData.getOrDefault("Marker")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "Marker", valid_602094
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602095 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602095 = validateParameter(valid_602095, JString, required = true,
                                 default = nil)
  if valid_602095 != nil:
    section.add "DBParameterGroupFamily", valid_602095
  var valid_602096 = formData.getOrDefault("MaxRecords")
  valid_602096 = validateParameter(valid_602096, JInt, required = false, default = nil)
  if valid_602096 != nil:
    section.add "MaxRecords", valid_602096
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602097: Call_PostDescribeEngineDefaultParameters_602082;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602097.validator(path, query, header, formData, body)
  let scheme = call_602097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602097.url(scheme.get, call_602097.host, call_602097.base,
                         call_602097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602097, url, valid)

proc call*(call_602098: Call_PostDescribeEngineDefaultParameters_602082;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_602099 = newJObject()
  var formData_602100 = newJObject()
  add(formData_602100, "Marker", newJString(Marker))
  add(query_602099, "Action", newJString(Action))
  add(formData_602100, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_602100, "MaxRecords", newJInt(MaxRecords))
  add(query_602099, "Version", newJString(Version))
  result = call_602098.call(nil, query_602099, nil, formData_602100, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_602082(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_602083, base: "/",
    url: url_PostDescribeEngineDefaultParameters_602084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_602064 = ref object of OpenApiRestCall_600421
proc url_GetDescribeEngineDefaultParameters_602066(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_602065(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupFamily: JString (required)
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_602067 = query.getOrDefault("MaxRecords")
  valid_602067 = validateParameter(valid_602067, JInt, required = false, default = nil)
  if valid_602067 != nil:
    section.add "MaxRecords", valid_602067
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602068 = query.getOrDefault("DBParameterGroupFamily")
  valid_602068 = validateParameter(valid_602068, JString, required = true,
                                 default = nil)
  if valid_602068 != nil:
    section.add "DBParameterGroupFamily", valid_602068
  var valid_602069 = query.getOrDefault("Action")
  valid_602069 = validateParameter(valid_602069, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602069 != nil:
    section.add "Action", valid_602069
  var valid_602070 = query.getOrDefault("Marker")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "Marker", valid_602070
  var valid_602071 = query.getOrDefault("Version")
  valid_602071 = validateParameter(valid_602071, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602071 != nil:
    section.add "Version", valid_602071
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
  var valid_602072 = header.getOrDefault("X-Amz-Date")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Date", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Security-Token")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Security-Token", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Content-Sha256", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Algorithm")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Algorithm", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Signature")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Signature", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-SignedHeaders", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602079: Call_GetDescribeEngineDefaultParameters_602064;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602079.validator(path, query, header, formData, body)
  let scheme = call_602079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602079.url(scheme.get, call_602079.host, call_602079.base,
                         call_602079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602079, url, valid)

proc call*(call_602080: Call_GetDescribeEngineDefaultParameters_602064;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_602081 = newJObject()
  add(query_602081, "MaxRecords", newJInt(MaxRecords))
  add(query_602081, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_602081, "Action", newJString(Action))
  add(query_602081, "Marker", newJString(Marker))
  add(query_602081, "Version", newJString(Version))
  result = call_602080.call(nil, query_602081, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_602064(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_602065, base: "/",
    url: url_GetDescribeEngineDefaultParameters_602066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_602117 = ref object of OpenApiRestCall_600421
proc url_PostDescribeEventCategories_602119(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_602118(path: JsonNode; query: JsonNode;
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
  var valid_602120 = query.getOrDefault("Action")
  valid_602120 = validateParameter(valid_602120, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602120 != nil:
    section.add "Action", valid_602120
  var valid_602121 = query.getOrDefault("Version")
  valid_602121 = validateParameter(valid_602121, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602121 != nil:
    section.add "Version", valid_602121
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
  var valid_602122 = header.getOrDefault("X-Amz-Date")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Date", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Security-Token")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Security-Token", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Content-Sha256", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Algorithm")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Algorithm", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Signature")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Signature", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-SignedHeaders", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Credential")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Credential", valid_602128
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_602129 = formData.getOrDefault("SourceType")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "SourceType", valid_602129
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602130: Call_PostDescribeEventCategories_602117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602130.validator(path, query, header, formData, body)
  let scheme = call_602130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602130.url(scheme.get, call_602130.host, call_602130.base,
                         call_602130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602130, url, valid)

proc call*(call_602131: Call_PostDescribeEventCategories_602117;
          Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_602132 = newJObject()
  var formData_602133 = newJObject()
  add(query_602132, "Action", newJString(Action))
  add(query_602132, "Version", newJString(Version))
  add(formData_602133, "SourceType", newJString(SourceType))
  result = call_602131.call(nil, query_602132, nil, formData_602133, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_602117(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_602118, base: "/",
    url: url_PostDescribeEventCategories_602119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_602101 = ref object of OpenApiRestCall_600421
proc url_GetDescribeEventCategories_602103(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_602102(path: JsonNode; query: JsonNode;
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
  var valid_602104 = query.getOrDefault("SourceType")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "SourceType", valid_602104
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602105 = query.getOrDefault("Action")
  valid_602105 = validateParameter(valid_602105, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602105 != nil:
    section.add "Action", valid_602105
  var valid_602106 = query.getOrDefault("Version")
  valid_602106 = validateParameter(valid_602106, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602106 != nil:
    section.add "Version", valid_602106
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
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Security-Token")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Security-Token", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Content-Sha256", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Signature")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Signature", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-SignedHeaders", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Credential")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Credential", valid_602113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602114: Call_GetDescribeEventCategories_602101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602114.validator(path, query, header, formData, body)
  let scheme = call_602114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602114.url(scheme.get, call_602114.host, call_602114.base,
                         call_602114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602114, url, valid)

proc call*(call_602115: Call_GetDescribeEventCategories_602101;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602116 = newJObject()
  add(query_602116, "SourceType", newJString(SourceType))
  add(query_602116, "Action", newJString(Action))
  add(query_602116, "Version", newJString(Version))
  result = call_602115.call(nil, query_602116, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_602101(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_602102, base: "/",
    url: url_GetDescribeEventCategories_602103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_602152 = ref object of OpenApiRestCall_600421
proc url_PostDescribeEventSubscriptions_602154(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_602153(path: JsonNode;
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
  var valid_602155 = query.getOrDefault("Action")
  valid_602155 = validateParameter(valid_602155, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_602155 != nil:
    section.add "Action", valid_602155
  var valid_602156 = query.getOrDefault("Version")
  valid_602156 = validateParameter(valid_602156, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602156 != nil:
    section.add "Version", valid_602156
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
  var valid_602157 = header.getOrDefault("X-Amz-Date")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Date", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Security-Token")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Security-Token", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Content-Sha256", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Algorithm")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Algorithm", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Signature")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Signature", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-SignedHeaders", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Credential")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Credential", valid_602163
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602164 = formData.getOrDefault("Marker")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "Marker", valid_602164
  var valid_602165 = formData.getOrDefault("SubscriptionName")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "SubscriptionName", valid_602165
  var valid_602166 = formData.getOrDefault("MaxRecords")
  valid_602166 = validateParameter(valid_602166, JInt, required = false, default = nil)
  if valid_602166 != nil:
    section.add "MaxRecords", valid_602166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602167: Call_PostDescribeEventSubscriptions_602152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602167.validator(path, query, header, formData, body)
  let scheme = call_602167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602167.url(scheme.get, call_602167.host, call_602167.base,
                         call_602167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602167, url, valid)

proc call*(call_602168: Call_PostDescribeEventSubscriptions_602152;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_602169 = newJObject()
  var formData_602170 = newJObject()
  add(formData_602170, "Marker", newJString(Marker))
  add(formData_602170, "SubscriptionName", newJString(SubscriptionName))
  add(query_602169, "Action", newJString(Action))
  add(formData_602170, "MaxRecords", newJInt(MaxRecords))
  add(query_602169, "Version", newJString(Version))
  result = call_602168.call(nil, query_602169, nil, formData_602170, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_602152(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_602153, base: "/",
    url: url_PostDescribeEventSubscriptions_602154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_602134 = ref object of OpenApiRestCall_600421
proc url_GetDescribeEventSubscriptions_602136(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_602135(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Action: JString (required)
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_602137 = query.getOrDefault("MaxRecords")
  valid_602137 = validateParameter(valid_602137, JInt, required = false, default = nil)
  if valid_602137 != nil:
    section.add "MaxRecords", valid_602137
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602138 = query.getOrDefault("Action")
  valid_602138 = validateParameter(valid_602138, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_602138 != nil:
    section.add "Action", valid_602138
  var valid_602139 = query.getOrDefault("Marker")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "Marker", valid_602139
  var valid_602140 = query.getOrDefault("SubscriptionName")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "SubscriptionName", valid_602140
  var valid_602141 = query.getOrDefault("Version")
  valid_602141 = validateParameter(valid_602141, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602141 != nil:
    section.add "Version", valid_602141
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
  var valid_602142 = header.getOrDefault("X-Amz-Date")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Date", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Security-Token")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Security-Token", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Content-Sha256", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Algorithm")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Algorithm", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Signature")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Signature", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-SignedHeaders", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Credential")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Credential", valid_602148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602149: Call_GetDescribeEventSubscriptions_602134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602149.validator(path, query, header, formData, body)
  let scheme = call_602149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602149.url(scheme.get, call_602149.host, call_602149.base,
                         call_602149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602149, url, valid)

proc call*(call_602150: Call_GetDescribeEventSubscriptions_602134;
          MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
          Marker: string = ""; SubscriptionName: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_602151 = newJObject()
  add(query_602151, "MaxRecords", newJInt(MaxRecords))
  add(query_602151, "Action", newJString(Action))
  add(query_602151, "Marker", newJString(Marker))
  add(query_602151, "SubscriptionName", newJString(SubscriptionName))
  add(query_602151, "Version", newJString(Version))
  result = call_602150.call(nil, query_602151, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_602134(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_602135, base: "/",
    url: url_GetDescribeEventSubscriptions_602136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_602194 = ref object of OpenApiRestCall_600421
proc url_PostDescribeEvents_602196(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_602195(path: JsonNode; query: JsonNode;
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
  var valid_602197 = query.getOrDefault("Action")
  valid_602197 = validateParameter(valid_602197, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602197 != nil:
    section.add "Action", valid_602197
  var valid_602198 = query.getOrDefault("Version")
  valid_602198 = validateParameter(valid_602198, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602198 != nil:
    section.add "Version", valid_602198
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
  var valid_602199 = header.getOrDefault("X-Amz-Date")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Date", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Security-Token")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Security-Token", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Content-Sha256", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Algorithm")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Algorithm", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-Signature")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Signature", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-SignedHeaders", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Credential")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Credential", valid_602205
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString
  ##   EventCategories: JArray
  ##   Marker: JString
  ##   StartTime: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   MaxRecords: JInt
  ##   SourceType: JString
  section = newJObject()
  var valid_602206 = formData.getOrDefault("SourceIdentifier")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "SourceIdentifier", valid_602206
  var valid_602207 = formData.getOrDefault("EventCategories")
  valid_602207 = validateParameter(valid_602207, JArray, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "EventCategories", valid_602207
  var valid_602208 = formData.getOrDefault("Marker")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "Marker", valid_602208
  var valid_602209 = formData.getOrDefault("StartTime")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "StartTime", valid_602209
  var valid_602210 = formData.getOrDefault("Duration")
  valid_602210 = validateParameter(valid_602210, JInt, required = false, default = nil)
  if valid_602210 != nil:
    section.add "Duration", valid_602210
  var valid_602211 = formData.getOrDefault("EndTime")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "EndTime", valid_602211
  var valid_602212 = formData.getOrDefault("MaxRecords")
  valid_602212 = validateParameter(valid_602212, JInt, required = false, default = nil)
  if valid_602212 != nil:
    section.add "MaxRecords", valid_602212
  var valid_602213 = formData.getOrDefault("SourceType")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602213 != nil:
    section.add "SourceType", valid_602213
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602214: Call_PostDescribeEvents_602194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602214.validator(path, query, header, formData, body)
  let scheme = call_602214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602214.url(scheme.get, call_602214.host, call_602214.base,
                         call_602214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602214, url, valid)

proc call*(call_602215: Call_PostDescribeEvents_602194;
          SourceIdentifier: string = ""; EventCategories: JsonNode = nil;
          Marker: string = ""; StartTime: string = "";
          Action: string = "DescribeEvents"; Duration: int = 0; EndTime: string = "";
          MaxRecords: int = 0; Version: string = "2013-02-12";
          SourceType: string = "db-instance"): Recallable =
  ## postDescribeEvents
  ##   SourceIdentifier: string
  ##   EventCategories: JArray
  ##   Marker: string
  ##   StartTime: string
  ##   Action: string (required)
  ##   Duration: int
  ##   EndTime: string
  ##   MaxRecords: int
  ##   Version: string (required)
  ##   SourceType: string
  var query_602216 = newJObject()
  var formData_602217 = newJObject()
  add(formData_602217, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_602217.add "EventCategories", EventCategories
  add(formData_602217, "Marker", newJString(Marker))
  add(formData_602217, "StartTime", newJString(StartTime))
  add(query_602216, "Action", newJString(Action))
  add(formData_602217, "Duration", newJInt(Duration))
  add(formData_602217, "EndTime", newJString(EndTime))
  add(formData_602217, "MaxRecords", newJInt(MaxRecords))
  add(query_602216, "Version", newJString(Version))
  add(formData_602217, "SourceType", newJString(SourceType))
  result = call_602215.call(nil, query_602216, nil, formData_602217, nil)

var postDescribeEvents* = Call_PostDescribeEvents_602194(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_602195, base: "/",
    url: url_PostDescribeEvents_602196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_602171 = ref object of OpenApiRestCall_600421
proc url_GetDescribeEvents_602173(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_602172(path: JsonNode; query: JsonNode;
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
  ##   Action: JString (required)
  ##   SourceIdentifier: JString
  ##   Marker: JString
  ##   EventCategories: JArray
  ##   Duration: JInt
  ##   EndTime: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_602174 = query.getOrDefault("SourceType")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602174 != nil:
    section.add "SourceType", valid_602174
  var valid_602175 = query.getOrDefault("MaxRecords")
  valid_602175 = validateParameter(valid_602175, JInt, required = false, default = nil)
  if valid_602175 != nil:
    section.add "MaxRecords", valid_602175
  var valid_602176 = query.getOrDefault("StartTime")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "StartTime", valid_602176
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602177 = query.getOrDefault("Action")
  valid_602177 = validateParameter(valid_602177, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602177 != nil:
    section.add "Action", valid_602177
  var valid_602178 = query.getOrDefault("SourceIdentifier")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "SourceIdentifier", valid_602178
  var valid_602179 = query.getOrDefault("Marker")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "Marker", valid_602179
  var valid_602180 = query.getOrDefault("EventCategories")
  valid_602180 = validateParameter(valid_602180, JArray, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "EventCategories", valid_602180
  var valid_602181 = query.getOrDefault("Duration")
  valid_602181 = validateParameter(valid_602181, JInt, required = false, default = nil)
  if valid_602181 != nil:
    section.add "Duration", valid_602181
  var valid_602182 = query.getOrDefault("EndTime")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "EndTime", valid_602182
  var valid_602183 = query.getOrDefault("Version")
  valid_602183 = validateParameter(valid_602183, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602183 != nil:
    section.add "Version", valid_602183
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
  var valid_602184 = header.getOrDefault("X-Amz-Date")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Date", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Security-Token")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Security-Token", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Content-Sha256", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Algorithm")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Algorithm", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Signature")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Signature", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-SignedHeaders", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Credential")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Credential", valid_602190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602191: Call_GetDescribeEvents_602171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602191.validator(path, query, header, formData, body)
  let scheme = call_602191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602191.url(scheme.get, call_602191.host, call_602191.base,
                         call_602191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602191, url, valid)

proc call*(call_602192: Call_GetDescribeEvents_602171;
          SourceType: string = "db-instance"; MaxRecords: int = 0;
          StartTime: string = ""; Action: string = "DescribeEvents";
          SourceIdentifier: string = ""; Marker: string = "";
          EventCategories: JsonNode = nil; Duration: int = 0; EndTime: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEvents
  ##   SourceType: string
  ##   MaxRecords: int
  ##   StartTime: string
  ##   Action: string (required)
  ##   SourceIdentifier: string
  ##   Marker: string
  ##   EventCategories: JArray
  ##   Duration: int
  ##   EndTime: string
  ##   Version: string (required)
  var query_602193 = newJObject()
  add(query_602193, "SourceType", newJString(SourceType))
  add(query_602193, "MaxRecords", newJInt(MaxRecords))
  add(query_602193, "StartTime", newJString(StartTime))
  add(query_602193, "Action", newJString(Action))
  add(query_602193, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_602193, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_602193.add "EventCategories", EventCategories
  add(query_602193, "Duration", newJInt(Duration))
  add(query_602193, "EndTime", newJString(EndTime))
  add(query_602193, "Version", newJString(Version))
  result = call_602192.call(nil, query_602193, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_602171(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_602172,
    base: "/", url: url_GetDescribeEvents_602173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_602237 = ref object of OpenApiRestCall_600421
proc url_PostDescribeOptionGroupOptions_602239(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_602238(path: JsonNode;
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
  var valid_602240 = query.getOrDefault("Action")
  valid_602240 = validateParameter(valid_602240, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_602240 != nil:
    section.add "Action", valid_602240
  var valid_602241 = query.getOrDefault("Version")
  valid_602241 = validateParameter(valid_602241, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602241 != nil:
    section.add "Version", valid_602241
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
  var valid_602242 = header.getOrDefault("X-Amz-Date")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Date", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Security-Token")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Security-Token", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Content-Sha256", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Algorithm")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Algorithm", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Signature")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Signature", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-SignedHeaders", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Credential")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Credential", valid_602248
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602249 = formData.getOrDefault("MajorEngineVersion")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "MajorEngineVersion", valid_602249
  var valid_602250 = formData.getOrDefault("Marker")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "Marker", valid_602250
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_602251 = formData.getOrDefault("EngineName")
  valid_602251 = validateParameter(valid_602251, JString, required = true,
                                 default = nil)
  if valid_602251 != nil:
    section.add "EngineName", valid_602251
  var valid_602252 = formData.getOrDefault("MaxRecords")
  valid_602252 = validateParameter(valid_602252, JInt, required = false, default = nil)
  if valid_602252 != nil:
    section.add "MaxRecords", valid_602252
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602253: Call_PostDescribeOptionGroupOptions_602237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602253.validator(path, query, header, formData, body)
  let scheme = call_602253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602253.url(scheme.get, call_602253.host, call_602253.base,
                         call_602253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602253, url, valid)

proc call*(call_602254: Call_PostDescribeOptionGroupOptions_602237;
          EngineName: string; MajorEngineVersion: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MajorEngineVersion: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_602255 = newJObject()
  var formData_602256 = newJObject()
  add(formData_602256, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_602256, "Marker", newJString(Marker))
  add(query_602255, "Action", newJString(Action))
  add(formData_602256, "EngineName", newJString(EngineName))
  add(formData_602256, "MaxRecords", newJInt(MaxRecords))
  add(query_602255, "Version", newJString(Version))
  result = call_602254.call(nil, query_602255, nil, formData_602256, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_602237(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_602238, base: "/",
    url: url_PostDescribeOptionGroupOptions_602239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_602218 = ref object of OpenApiRestCall_600421
proc url_GetDescribeOptionGroupOptions_602220(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_602219(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_602221 = query.getOrDefault("MaxRecords")
  valid_602221 = validateParameter(valid_602221, JInt, required = false, default = nil)
  if valid_602221 != nil:
    section.add "MaxRecords", valid_602221
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602222 = query.getOrDefault("Action")
  valid_602222 = validateParameter(valid_602222, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_602222 != nil:
    section.add "Action", valid_602222
  var valid_602223 = query.getOrDefault("Marker")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "Marker", valid_602223
  var valid_602224 = query.getOrDefault("Version")
  valid_602224 = validateParameter(valid_602224, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602224 != nil:
    section.add "Version", valid_602224
  var valid_602225 = query.getOrDefault("EngineName")
  valid_602225 = validateParameter(valid_602225, JString, required = true,
                                 default = nil)
  if valid_602225 != nil:
    section.add "EngineName", valid_602225
  var valid_602226 = query.getOrDefault("MajorEngineVersion")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "MajorEngineVersion", valid_602226
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
  var valid_602227 = header.getOrDefault("X-Amz-Date")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Date", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Security-Token")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Security-Token", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Content-Sha256", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Algorithm")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Algorithm", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Signature")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Signature", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-SignedHeaders", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Credential")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Credential", valid_602233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602234: Call_GetDescribeOptionGroupOptions_602218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602234.validator(path, query, header, formData, body)
  let scheme = call_602234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602234.url(scheme.get, call_602234.host, call_602234.base,
                         call_602234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602234, url, valid)

proc call*(call_602235: Call_GetDescribeOptionGroupOptions_602218;
          EngineName: string; MaxRecords: int = 0;
          Action: string = "DescribeOptionGroupOptions"; Marker: string = "";
          Version: string = "2013-02-12"; MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  var query_602236 = newJObject()
  add(query_602236, "MaxRecords", newJInt(MaxRecords))
  add(query_602236, "Action", newJString(Action))
  add(query_602236, "Marker", newJString(Marker))
  add(query_602236, "Version", newJString(Version))
  add(query_602236, "EngineName", newJString(EngineName))
  add(query_602236, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602235.call(nil, query_602236, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_602218(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_602219, base: "/",
    url: url_GetDescribeOptionGroupOptions_602220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_602277 = ref object of OpenApiRestCall_600421
proc url_PostDescribeOptionGroups_602279(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_602278(path: JsonNode; query: JsonNode;
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
  var valid_602280 = query.getOrDefault("Action")
  valid_602280 = validateParameter(valid_602280, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_602280 != nil:
    section.add "Action", valid_602280
  var valid_602281 = query.getOrDefault("Version")
  valid_602281 = validateParameter(valid_602281, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602281 != nil:
    section.add "Version", valid_602281
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
  var valid_602282 = header.getOrDefault("X-Amz-Date")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Date", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Security-Token")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Security-Token", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Content-Sha256", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Algorithm")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Algorithm", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Signature")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Signature", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-SignedHeaders", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Credential")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Credential", valid_602288
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602289 = formData.getOrDefault("MajorEngineVersion")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "MajorEngineVersion", valid_602289
  var valid_602290 = formData.getOrDefault("OptionGroupName")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "OptionGroupName", valid_602290
  var valid_602291 = formData.getOrDefault("Marker")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "Marker", valid_602291
  var valid_602292 = formData.getOrDefault("EngineName")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "EngineName", valid_602292
  var valid_602293 = formData.getOrDefault("MaxRecords")
  valid_602293 = validateParameter(valid_602293, JInt, required = false, default = nil)
  if valid_602293 != nil:
    section.add "MaxRecords", valid_602293
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602294: Call_PostDescribeOptionGroups_602277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602294.validator(path, query, header, formData, body)
  let scheme = call_602294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602294.url(scheme.get, call_602294.host, call_602294.base,
                         call_602294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602294, url, valid)

proc call*(call_602295: Call_PostDescribeOptionGroups_602277;
          MajorEngineVersion: string = ""; OptionGroupName: string = "";
          Marker: string = ""; Action: string = "DescribeOptionGroups";
          EngineName: string = ""; MaxRecords: int = 0; Version: string = "2013-02-12"): Recallable =
  ## postDescribeOptionGroups
  ##   MajorEngineVersion: string
  ##   OptionGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_602296 = newJObject()
  var formData_602297 = newJObject()
  add(formData_602297, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_602297, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602297, "Marker", newJString(Marker))
  add(query_602296, "Action", newJString(Action))
  add(formData_602297, "EngineName", newJString(EngineName))
  add(formData_602297, "MaxRecords", newJInt(MaxRecords))
  add(query_602296, "Version", newJString(Version))
  result = call_602295.call(nil, query_602296, nil, formData_602297, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_602277(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_602278, base: "/",
    url: url_PostDescribeOptionGroups_602279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_602257 = ref object of OpenApiRestCall_600421
proc url_GetDescribeOptionGroups_602259(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_602258(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   OptionGroupName: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_602260 = query.getOrDefault("MaxRecords")
  valid_602260 = validateParameter(valid_602260, JInt, required = false, default = nil)
  if valid_602260 != nil:
    section.add "MaxRecords", valid_602260
  var valid_602261 = query.getOrDefault("OptionGroupName")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "OptionGroupName", valid_602261
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602262 = query.getOrDefault("Action")
  valid_602262 = validateParameter(valid_602262, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_602262 != nil:
    section.add "Action", valid_602262
  var valid_602263 = query.getOrDefault("Marker")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "Marker", valid_602263
  var valid_602264 = query.getOrDefault("Version")
  valid_602264 = validateParameter(valid_602264, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602264 != nil:
    section.add "Version", valid_602264
  var valid_602265 = query.getOrDefault("EngineName")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "EngineName", valid_602265
  var valid_602266 = query.getOrDefault("MajorEngineVersion")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "MajorEngineVersion", valid_602266
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
  var valid_602267 = header.getOrDefault("X-Amz-Date")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Date", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Security-Token")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Security-Token", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Content-Sha256", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Algorithm")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Algorithm", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Signature")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Signature", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-SignedHeaders", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Credential")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Credential", valid_602273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602274: Call_GetDescribeOptionGroups_602257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602274.validator(path, query, header, formData, body)
  let scheme = call_602274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602274.url(scheme.get, call_602274.host, call_602274.base,
                         call_602274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602274, url, valid)

proc call*(call_602275: Call_GetDescribeOptionGroups_602257; MaxRecords: int = 0;
          OptionGroupName: string = ""; Action: string = "DescribeOptionGroups";
          Marker: string = ""; Version: string = "2013-02-12"; EngineName: string = "";
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   MaxRecords: int
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string
  ##   MajorEngineVersion: string
  var query_602276 = newJObject()
  add(query_602276, "MaxRecords", newJInt(MaxRecords))
  add(query_602276, "OptionGroupName", newJString(OptionGroupName))
  add(query_602276, "Action", newJString(Action))
  add(query_602276, "Marker", newJString(Marker))
  add(query_602276, "Version", newJString(Version))
  add(query_602276, "EngineName", newJString(EngineName))
  add(query_602276, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602275.call(nil, query_602276, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_602257(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_602258, base: "/",
    url: url_GetDescribeOptionGroups_602259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_602320 = ref object of OpenApiRestCall_600421
proc url_PostDescribeOrderableDBInstanceOptions_602322(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_602321(path: JsonNode;
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
  var valid_602323 = query.getOrDefault("Action")
  valid_602323 = validateParameter(valid_602323, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602323 != nil:
    section.add "Action", valid_602323
  var valid_602324 = query.getOrDefault("Version")
  valid_602324 = validateParameter(valid_602324, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602324 != nil:
    section.add "Version", valid_602324
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
  var valid_602325 = header.getOrDefault("X-Amz-Date")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Date", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Security-Token")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Security-Token", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Content-Sha256", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-Algorithm")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Algorithm", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Signature")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Signature", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-SignedHeaders", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Credential")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Credential", valid_602331
  result.add "header", section
  ## parameters in `formData` object:
  ##   Engine: JString (required)
  ##   Marker: JString
  ##   Vpc: JBool
  ##   DBInstanceClass: JString
  ##   LicenseModel: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_602332 = formData.getOrDefault("Engine")
  valid_602332 = validateParameter(valid_602332, JString, required = true,
                                 default = nil)
  if valid_602332 != nil:
    section.add "Engine", valid_602332
  var valid_602333 = formData.getOrDefault("Marker")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "Marker", valid_602333
  var valid_602334 = formData.getOrDefault("Vpc")
  valid_602334 = validateParameter(valid_602334, JBool, required = false, default = nil)
  if valid_602334 != nil:
    section.add "Vpc", valid_602334
  var valid_602335 = formData.getOrDefault("DBInstanceClass")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "DBInstanceClass", valid_602335
  var valid_602336 = formData.getOrDefault("LicenseModel")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "LicenseModel", valid_602336
  var valid_602337 = formData.getOrDefault("MaxRecords")
  valid_602337 = validateParameter(valid_602337, JInt, required = false, default = nil)
  if valid_602337 != nil:
    section.add "MaxRecords", valid_602337
  var valid_602338 = formData.getOrDefault("EngineVersion")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "EngineVersion", valid_602338
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602339: Call_PostDescribeOrderableDBInstanceOptions_602320;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602339.validator(path, query, header, formData, body)
  let scheme = call_602339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602339.url(scheme.get, call_602339.host, call_602339.base,
                         call_602339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602339, url, valid)

proc call*(call_602340: Call_PostDescribeOrderableDBInstanceOptions_602320;
          Engine: string; Marker: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions"; Vpc: bool = false;
          DBInstanceClass: string = ""; LicenseModel: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Version: string = "2013-02-12"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ##   Engine: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Vpc: bool
  ##   DBInstanceClass: string
  ##   LicenseModel: string
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Version: string (required)
  var query_602341 = newJObject()
  var formData_602342 = newJObject()
  add(formData_602342, "Engine", newJString(Engine))
  add(formData_602342, "Marker", newJString(Marker))
  add(query_602341, "Action", newJString(Action))
  add(formData_602342, "Vpc", newJBool(Vpc))
  add(formData_602342, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602342, "LicenseModel", newJString(LicenseModel))
  add(formData_602342, "MaxRecords", newJInt(MaxRecords))
  add(formData_602342, "EngineVersion", newJString(EngineVersion))
  add(query_602341, "Version", newJString(Version))
  result = call_602340.call(nil, query_602341, nil, formData_602342, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_602320(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_602321, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_602322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_602298 = ref object of OpenApiRestCall_600421
proc url_GetDescribeOrderableDBInstanceOptions_602300(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_602299(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##   MaxRecords: JInt
  ##   LicenseModel: JString
  ##   Vpc: JBool
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   EngineVersion: JString
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_602301 = query.getOrDefault("Engine")
  valid_602301 = validateParameter(valid_602301, JString, required = true,
                                 default = nil)
  if valid_602301 != nil:
    section.add "Engine", valid_602301
  var valid_602302 = query.getOrDefault("MaxRecords")
  valid_602302 = validateParameter(valid_602302, JInt, required = false, default = nil)
  if valid_602302 != nil:
    section.add "MaxRecords", valid_602302
  var valid_602303 = query.getOrDefault("LicenseModel")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "LicenseModel", valid_602303
  var valid_602304 = query.getOrDefault("Vpc")
  valid_602304 = validateParameter(valid_602304, JBool, required = false, default = nil)
  if valid_602304 != nil:
    section.add "Vpc", valid_602304
  var valid_602305 = query.getOrDefault("DBInstanceClass")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "DBInstanceClass", valid_602305
  var valid_602306 = query.getOrDefault("Action")
  valid_602306 = validateParameter(valid_602306, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602306 != nil:
    section.add "Action", valid_602306
  var valid_602307 = query.getOrDefault("Marker")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "Marker", valid_602307
  var valid_602308 = query.getOrDefault("EngineVersion")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "EngineVersion", valid_602308
  var valid_602309 = query.getOrDefault("Version")
  valid_602309 = validateParameter(valid_602309, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602309 != nil:
    section.add "Version", valid_602309
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
  var valid_602310 = header.getOrDefault("X-Amz-Date")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Date", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Security-Token")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Security-Token", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Content-Sha256", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Algorithm")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Algorithm", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Signature")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Signature", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-SignedHeaders", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Credential")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Credential", valid_602316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602317: Call_GetDescribeOrderableDBInstanceOptions_602298;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602317.validator(path, query, header, formData, body)
  let scheme = call_602317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602317.url(scheme.get, call_602317.host, call_602317.base,
                         call_602317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602317, url, valid)

proc call*(call_602318: Call_GetDescribeOrderableDBInstanceOptions_602298;
          Engine: string; MaxRecords: int = 0; LicenseModel: string = "";
          Vpc: bool = false; DBInstanceClass: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Marker: string = ""; EngineVersion: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ##   Engine: string (required)
  ##   MaxRecords: int
  ##   LicenseModel: string
  ##   Vpc: bool
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   Marker: string
  ##   EngineVersion: string
  ##   Version: string (required)
  var query_602319 = newJObject()
  add(query_602319, "Engine", newJString(Engine))
  add(query_602319, "MaxRecords", newJInt(MaxRecords))
  add(query_602319, "LicenseModel", newJString(LicenseModel))
  add(query_602319, "Vpc", newJBool(Vpc))
  add(query_602319, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602319, "Action", newJString(Action))
  add(query_602319, "Marker", newJString(Marker))
  add(query_602319, "EngineVersion", newJString(EngineVersion))
  add(query_602319, "Version", newJString(Version))
  result = call_602318.call(nil, query_602319, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_602298(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_602299, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_602300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_602367 = ref object of OpenApiRestCall_600421
proc url_PostDescribeReservedDBInstances_602369(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_602368(path: JsonNode;
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
  var valid_602370 = query.getOrDefault("Action")
  valid_602370 = validateParameter(valid_602370, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_602370 != nil:
    section.add "Action", valid_602370
  var valid_602371 = query.getOrDefault("Version")
  valid_602371 = validateParameter(valid_602371, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602371 != nil:
    section.add "Version", valid_602371
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
  var valid_602372 = header.getOrDefault("X-Amz-Date")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Date", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Security-Token")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Security-Token", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Content-Sha256", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Algorithm")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Algorithm", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Signature")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Signature", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-SignedHeaders", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-Credential")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Credential", valid_602378
  result.add "header", section
  ## parameters in `formData` object:
  ##   OfferingType: JString
  ##   ReservedDBInstanceId: JString
  ##   Marker: JString
  ##   MultiAZ: JBool
  ##   Duration: JString
  ##   DBInstanceClass: JString
  ##   ProductDescription: JString
  ##   MaxRecords: JInt
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_602379 = formData.getOrDefault("OfferingType")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "OfferingType", valid_602379
  var valid_602380 = formData.getOrDefault("ReservedDBInstanceId")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "ReservedDBInstanceId", valid_602380
  var valid_602381 = formData.getOrDefault("Marker")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "Marker", valid_602381
  var valid_602382 = formData.getOrDefault("MultiAZ")
  valid_602382 = validateParameter(valid_602382, JBool, required = false, default = nil)
  if valid_602382 != nil:
    section.add "MultiAZ", valid_602382
  var valid_602383 = formData.getOrDefault("Duration")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "Duration", valid_602383
  var valid_602384 = formData.getOrDefault("DBInstanceClass")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "DBInstanceClass", valid_602384
  var valid_602385 = formData.getOrDefault("ProductDescription")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "ProductDescription", valid_602385
  var valid_602386 = formData.getOrDefault("MaxRecords")
  valid_602386 = validateParameter(valid_602386, JInt, required = false, default = nil)
  if valid_602386 != nil:
    section.add "MaxRecords", valid_602386
  var valid_602387 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602387
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602388: Call_PostDescribeReservedDBInstances_602367;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602388.validator(path, query, header, formData, body)
  let scheme = call_602388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602388.url(scheme.get, call_602388.host, call_602388.base,
                         call_602388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602388, url, valid)

proc call*(call_602389: Call_PostDescribeReservedDBInstances_602367;
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstances"; Duration: string = "";
          DBInstanceClass: string = ""; ProductDescription: string = "";
          MaxRecords: int = 0; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeReservedDBInstances
  ##   OfferingType: string
  ##   ReservedDBInstanceId: string
  ##   Marker: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   Duration: string
  ##   DBInstanceClass: string
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_602390 = newJObject()
  var formData_602391 = newJObject()
  add(formData_602391, "OfferingType", newJString(OfferingType))
  add(formData_602391, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_602391, "Marker", newJString(Marker))
  add(formData_602391, "MultiAZ", newJBool(MultiAZ))
  add(query_602390, "Action", newJString(Action))
  add(formData_602391, "Duration", newJString(Duration))
  add(formData_602391, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602391, "ProductDescription", newJString(ProductDescription))
  add(formData_602391, "MaxRecords", newJInt(MaxRecords))
  add(formData_602391, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602390, "Version", newJString(Version))
  result = call_602389.call(nil, query_602390, nil, formData_602391, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_602367(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_602368, base: "/",
    url: url_PostDescribeReservedDBInstances_602369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_602343 = ref object of OpenApiRestCall_600421
proc url_GetDescribeReservedDBInstances_602345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_602344(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ProductDescription: JString
  ##   MaxRecords: JInt
  ##   OfferingType: JString
  ##   MultiAZ: JBool
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Duration: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_602346 = query.getOrDefault("ProductDescription")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "ProductDescription", valid_602346
  var valid_602347 = query.getOrDefault("MaxRecords")
  valid_602347 = validateParameter(valid_602347, JInt, required = false, default = nil)
  if valid_602347 != nil:
    section.add "MaxRecords", valid_602347
  var valid_602348 = query.getOrDefault("OfferingType")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "OfferingType", valid_602348
  var valid_602349 = query.getOrDefault("MultiAZ")
  valid_602349 = validateParameter(valid_602349, JBool, required = false, default = nil)
  if valid_602349 != nil:
    section.add "MultiAZ", valid_602349
  var valid_602350 = query.getOrDefault("ReservedDBInstanceId")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "ReservedDBInstanceId", valid_602350
  var valid_602351 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602351
  var valid_602352 = query.getOrDefault("DBInstanceClass")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "DBInstanceClass", valid_602352
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602353 = query.getOrDefault("Action")
  valid_602353 = validateParameter(valid_602353, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_602353 != nil:
    section.add "Action", valid_602353
  var valid_602354 = query.getOrDefault("Marker")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "Marker", valid_602354
  var valid_602355 = query.getOrDefault("Duration")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "Duration", valid_602355
  var valid_602356 = query.getOrDefault("Version")
  valid_602356 = validateParameter(valid_602356, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602356 != nil:
    section.add "Version", valid_602356
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
  var valid_602357 = header.getOrDefault("X-Amz-Date")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Date", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Security-Token")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Security-Token", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Content-Sha256", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Algorithm")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Algorithm", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Signature")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Signature", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-SignedHeaders", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Credential")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Credential", valid_602363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602364: Call_GetDescribeReservedDBInstances_602343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602364.validator(path, query, header, formData, body)
  let scheme = call_602364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602364.url(scheme.get, call_602364.host, call_602364.base,
                         call_602364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602364, url, valid)

proc call*(call_602365: Call_GetDescribeReservedDBInstances_602343;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; MultiAZ: bool = false;
          ReservedDBInstanceId: string = "";
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstances"; Marker: string = "";
          Duration: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getDescribeReservedDBInstances
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   OfferingType: string
  ##   MultiAZ: bool
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Duration: string
  ##   Version: string (required)
  var query_602366 = newJObject()
  add(query_602366, "ProductDescription", newJString(ProductDescription))
  add(query_602366, "MaxRecords", newJInt(MaxRecords))
  add(query_602366, "OfferingType", newJString(OfferingType))
  add(query_602366, "MultiAZ", newJBool(MultiAZ))
  add(query_602366, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_602366, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602366, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602366, "Action", newJString(Action))
  add(query_602366, "Marker", newJString(Marker))
  add(query_602366, "Duration", newJString(Duration))
  add(query_602366, "Version", newJString(Version))
  result = call_602365.call(nil, query_602366, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_602343(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_602344, base: "/",
    url: url_GetDescribeReservedDBInstances_602345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_602415 = ref object of OpenApiRestCall_600421
proc url_PostDescribeReservedDBInstancesOfferings_602417(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_602416(path: JsonNode;
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
  var valid_602418 = query.getOrDefault("Action")
  valid_602418 = validateParameter(valid_602418, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_602418 != nil:
    section.add "Action", valid_602418
  var valid_602419 = query.getOrDefault("Version")
  valid_602419 = validateParameter(valid_602419, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602419 != nil:
    section.add "Version", valid_602419
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
  var valid_602420 = header.getOrDefault("X-Amz-Date")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Date", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Security-Token")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Security-Token", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-Content-Sha256", valid_602422
  var valid_602423 = header.getOrDefault("X-Amz-Algorithm")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Algorithm", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Signature")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Signature", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-SignedHeaders", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-Credential")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-Credential", valid_602426
  result.add "header", section
  ## parameters in `formData` object:
  ##   OfferingType: JString
  ##   Marker: JString
  ##   MultiAZ: JBool
  ##   Duration: JString
  ##   DBInstanceClass: JString
  ##   ProductDescription: JString
  ##   MaxRecords: JInt
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_602427 = formData.getOrDefault("OfferingType")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "OfferingType", valid_602427
  var valid_602428 = formData.getOrDefault("Marker")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "Marker", valid_602428
  var valid_602429 = formData.getOrDefault("MultiAZ")
  valid_602429 = validateParameter(valid_602429, JBool, required = false, default = nil)
  if valid_602429 != nil:
    section.add "MultiAZ", valid_602429
  var valid_602430 = formData.getOrDefault("Duration")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "Duration", valid_602430
  var valid_602431 = formData.getOrDefault("DBInstanceClass")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "DBInstanceClass", valid_602431
  var valid_602432 = formData.getOrDefault("ProductDescription")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "ProductDescription", valid_602432
  var valid_602433 = formData.getOrDefault("MaxRecords")
  valid_602433 = validateParameter(valid_602433, JInt, required = false, default = nil)
  if valid_602433 != nil:
    section.add "MaxRecords", valid_602433
  var valid_602434 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602434
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602435: Call_PostDescribeReservedDBInstancesOfferings_602415;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602435.validator(path, query, header, formData, body)
  let scheme = call_602435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602435.url(scheme.get, call_602435.host, call_602435.base,
                         call_602435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602435, url, valid)

proc call*(call_602436: Call_PostDescribeReservedDBInstancesOfferings_602415;
          OfferingType: string = ""; Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstancesOfferings";
          Duration: string = ""; DBInstanceClass: string = "";
          ProductDescription: string = ""; MaxRecords: int = 0;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-02-12"): Recallable =
  ## postDescribeReservedDBInstancesOfferings
  ##   OfferingType: string
  ##   Marker: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   Duration: string
  ##   DBInstanceClass: string
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_602437 = newJObject()
  var formData_602438 = newJObject()
  add(formData_602438, "OfferingType", newJString(OfferingType))
  add(formData_602438, "Marker", newJString(Marker))
  add(formData_602438, "MultiAZ", newJBool(MultiAZ))
  add(query_602437, "Action", newJString(Action))
  add(formData_602438, "Duration", newJString(Duration))
  add(formData_602438, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602438, "ProductDescription", newJString(ProductDescription))
  add(formData_602438, "MaxRecords", newJInt(MaxRecords))
  add(formData_602438, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602437, "Version", newJString(Version))
  result = call_602436.call(nil, query_602437, nil, formData_602438, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_602415(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_602416,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_602417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_602392 = ref object of OpenApiRestCall_600421
proc url_GetDescribeReservedDBInstancesOfferings_602394(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_602393(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ProductDescription: JString
  ##   MaxRecords: JInt
  ##   OfferingType: JString
  ##   MultiAZ: JBool
  ##   ReservedDBInstancesOfferingId: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Duration: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_602395 = query.getOrDefault("ProductDescription")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "ProductDescription", valid_602395
  var valid_602396 = query.getOrDefault("MaxRecords")
  valid_602396 = validateParameter(valid_602396, JInt, required = false, default = nil)
  if valid_602396 != nil:
    section.add "MaxRecords", valid_602396
  var valid_602397 = query.getOrDefault("OfferingType")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "OfferingType", valid_602397
  var valid_602398 = query.getOrDefault("MultiAZ")
  valid_602398 = validateParameter(valid_602398, JBool, required = false, default = nil)
  if valid_602398 != nil:
    section.add "MultiAZ", valid_602398
  var valid_602399 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602399
  var valid_602400 = query.getOrDefault("DBInstanceClass")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "DBInstanceClass", valid_602400
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602401 = query.getOrDefault("Action")
  valid_602401 = validateParameter(valid_602401, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_602401 != nil:
    section.add "Action", valid_602401
  var valid_602402 = query.getOrDefault("Marker")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "Marker", valid_602402
  var valid_602403 = query.getOrDefault("Duration")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "Duration", valid_602403
  var valid_602404 = query.getOrDefault("Version")
  valid_602404 = validateParameter(valid_602404, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602404 != nil:
    section.add "Version", valid_602404
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
  var valid_602405 = header.getOrDefault("X-Amz-Date")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Date", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Security-Token")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Security-Token", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Content-Sha256", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-Algorithm")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Algorithm", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Signature")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Signature", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-SignedHeaders", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Credential")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Credential", valid_602411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602412: Call_GetDescribeReservedDBInstancesOfferings_602392;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602412.validator(path, query, header, formData, body)
  let scheme = call_602412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602412.url(scheme.get, call_602412.host, call_602412.base,
                         call_602412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602412, url, valid)

proc call*(call_602413: Call_GetDescribeReservedDBInstancesOfferings_602392;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; MultiAZ: bool = false;
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          Marker: string = ""; Duration: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getDescribeReservedDBInstancesOfferings
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   OfferingType: string
  ##   MultiAZ: bool
  ##   ReservedDBInstancesOfferingId: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Duration: string
  ##   Version: string (required)
  var query_602414 = newJObject()
  add(query_602414, "ProductDescription", newJString(ProductDescription))
  add(query_602414, "MaxRecords", newJInt(MaxRecords))
  add(query_602414, "OfferingType", newJString(OfferingType))
  add(query_602414, "MultiAZ", newJBool(MultiAZ))
  add(query_602414, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602414, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602414, "Action", newJString(Action))
  add(query_602414, "Marker", newJString(Marker))
  add(query_602414, "Duration", newJString(Duration))
  add(query_602414, "Version", newJString(Version))
  result = call_602413.call(nil, query_602414, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_602392(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_602393, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_602394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_602458 = ref object of OpenApiRestCall_600421
proc url_PostDownloadDBLogFilePortion_602460(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDownloadDBLogFilePortion_602459(path: JsonNode; query: JsonNode;
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
  var valid_602461 = query.getOrDefault("Action")
  valid_602461 = validateParameter(valid_602461, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_602461 != nil:
    section.add "Action", valid_602461
  var valid_602462 = query.getOrDefault("Version")
  valid_602462 = validateParameter(valid_602462, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602462 != nil:
    section.add "Version", valid_602462
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
  var valid_602463 = header.getOrDefault("X-Amz-Date")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Date", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Security-Token")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Security-Token", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Content-Sha256", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Algorithm")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Algorithm", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Signature")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Signature", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-SignedHeaders", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Credential")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Credential", valid_602469
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_602470 = formData.getOrDefault("NumberOfLines")
  valid_602470 = validateParameter(valid_602470, JInt, required = false, default = nil)
  if valid_602470 != nil:
    section.add "NumberOfLines", valid_602470
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602471 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602471 = validateParameter(valid_602471, JString, required = true,
                                 default = nil)
  if valid_602471 != nil:
    section.add "DBInstanceIdentifier", valid_602471
  var valid_602472 = formData.getOrDefault("Marker")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "Marker", valid_602472
  var valid_602473 = formData.getOrDefault("LogFileName")
  valid_602473 = validateParameter(valid_602473, JString, required = true,
                                 default = nil)
  if valid_602473 != nil:
    section.add "LogFileName", valid_602473
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602474: Call_PostDownloadDBLogFilePortion_602458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602474.validator(path, query, header, formData, body)
  let scheme = call_602474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602474.url(scheme.get, call_602474.host, call_602474.base,
                         call_602474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602474, url, valid)

proc call*(call_602475: Call_PostDownloadDBLogFilePortion_602458;
          DBInstanceIdentifier: string; LogFileName: string; NumberOfLines: int = 0;
          Marker: string = ""; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2013-02-12"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   DBInstanceIdentifier: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   LogFileName: string (required)
  ##   Version: string (required)
  var query_602476 = newJObject()
  var formData_602477 = newJObject()
  add(formData_602477, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_602477, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602477, "Marker", newJString(Marker))
  add(query_602476, "Action", newJString(Action))
  add(formData_602477, "LogFileName", newJString(LogFileName))
  add(query_602476, "Version", newJString(Version))
  result = call_602475.call(nil, query_602476, nil, formData_602477, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_602458(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_602459, base: "/",
    url: url_PostDownloadDBLogFilePortion_602460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_602439 = ref object of OpenApiRestCall_600421
proc url_GetDownloadDBLogFilePortion_602441(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDownloadDBLogFilePortion_602440(path: JsonNode; query: JsonNode;
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
  var valid_602442 = query.getOrDefault("NumberOfLines")
  valid_602442 = validateParameter(valid_602442, JInt, required = false, default = nil)
  if valid_602442 != nil:
    section.add "NumberOfLines", valid_602442
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_602443 = query.getOrDefault("LogFileName")
  valid_602443 = validateParameter(valid_602443, JString, required = true,
                                 default = nil)
  if valid_602443 != nil:
    section.add "LogFileName", valid_602443
  var valid_602444 = query.getOrDefault("Action")
  valid_602444 = validateParameter(valid_602444, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_602444 != nil:
    section.add "Action", valid_602444
  var valid_602445 = query.getOrDefault("Marker")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "Marker", valid_602445
  var valid_602446 = query.getOrDefault("Version")
  valid_602446 = validateParameter(valid_602446, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602446 != nil:
    section.add "Version", valid_602446
  var valid_602447 = query.getOrDefault("DBInstanceIdentifier")
  valid_602447 = validateParameter(valid_602447, JString, required = true,
                                 default = nil)
  if valid_602447 != nil:
    section.add "DBInstanceIdentifier", valid_602447
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
  var valid_602448 = header.getOrDefault("X-Amz-Date")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Date", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-Security-Token")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Security-Token", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Content-Sha256", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Algorithm")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Algorithm", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Signature")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Signature", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-SignedHeaders", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Credential")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Credential", valid_602454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602455: Call_GetDownloadDBLogFilePortion_602439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602455.validator(path, query, header, formData, body)
  let scheme = call_602455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602455.url(scheme.get, call_602455.host, call_602455.base,
                         call_602455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602455, url, valid)

proc call*(call_602456: Call_GetDownloadDBLogFilePortion_602439;
          LogFileName: string; DBInstanceIdentifier: string; NumberOfLines: int = 0;
          Action: string = "DownloadDBLogFilePortion"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   LogFileName: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602457 = newJObject()
  add(query_602457, "NumberOfLines", newJInt(NumberOfLines))
  add(query_602457, "LogFileName", newJString(LogFileName))
  add(query_602457, "Action", newJString(Action))
  add(query_602457, "Marker", newJString(Marker))
  add(query_602457, "Version", newJString(Version))
  add(query_602457, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602456.call(nil, query_602457, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_602439(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_602440, base: "/",
    url: url_GetDownloadDBLogFilePortion_602441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_602494 = ref object of OpenApiRestCall_600421
proc url_PostListTagsForResource_602496(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_602495(path: JsonNode; query: JsonNode;
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
  var valid_602497 = query.getOrDefault("Action")
  valid_602497 = validateParameter(valid_602497, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602497 != nil:
    section.add "Action", valid_602497
  var valid_602498 = query.getOrDefault("Version")
  valid_602498 = validateParameter(valid_602498, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602498 != nil:
    section.add "Version", valid_602498
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
  var valid_602499 = header.getOrDefault("X-Amz-Date")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Date", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-Security-Token")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Security-Token", valid_602500
  var valid_602501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-Content-Sha256", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-Algorithm")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-Algorithm", valid_602502
  var valid_602503 = header.getOrDefault("X-Amz-Signature")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Signature", valid_602503
  var valid_602504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-SignedHeaders", valid_602504
  var valid_602505 = header.getOrDefault("X-Amz-Credential")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Credential", valid_602505
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_602506 = formData.getOrDefault("ResourceName")
  valid_602506 = validateParameter(valid_602506, JString, required = true,
                                 default = nil)
  if valid_602506 != nil:
    section.add "ResourceName", valid_602506
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602507: Call_PostListTagsForResource_602494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602507.validator(path, query, header, formData, body)
  let scheme = call_602507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602507.url(scheme.get, call_602507.host, call_602507.base,
                         call_602507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602507, url, valid)

proc call*(call_602508: Call_PostListTagsForResource_602494; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_602509 = newJObject()
  var formData_602510 = newJObject()
  add(query_602509, "Action", newJString(Action))
  add(formData_602510, "ResourceName", newJString(ResourceName))
  add(query_602509, "Version", newJString(Version))
  result = call_602508.call(nil, query_602509, nil, formData_602510, nil)

var postListTagsForResource* = Call_PostListTagsForResource_602494(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_602495, base: "/",
    url: url_PostListTagsForResource_602496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_602478 = ref object of OpenApiRestCall_600421
proc url_GetListTagsForResource_602480(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_602479(path: JsonNode; query: JsonNode;
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
  var valid_602481 = query.getOrDefault("ResourceName")
  valid_602481 = validateParameter(valid_602481, JString, required = true,
                                 default = nil)
  if valid_602481 != nil:
    section.add "ResourceName", valid_602481
  var valid_602482 = query.getOrDefault("Action")
  valid_602482 = validateParameter(valid_602482, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602482 != nil:
    section.add "Action", valid_602482
  var valid_602483 = query.getOrDefault("Version")
  valid_602483 = validateParameter(valid_602483, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602483 != nil:
    section.add "Version", valid_602483
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
  var valid_602484 = header.getOrDefault("X-Amz-Date")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Date", valid_602484
  var valid_602485 = header.getOrDefault("X-Amz-Security-Token")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "X-Amz-Security-Token", valid_602485
  var valid_602486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-Content-Sha256", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-Algorithm")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Algorithm", valid_602487
  var valid_602488 = header.getOrDefault("X-Amz-Signature")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-Signature", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-SignedHeaders", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-Credential")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-Credential", valid_602490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602491: Call_GetListTagsForResource_602478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602491.validator(path, query, header, formData, body)
  let scheme = call_602491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602491.url(scheme.get, call_602491.host, call_602491.base,
                         call_602491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602491, url, valid)

proc call*(call_602492: Call_GetListTagsForResource_602478; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602493 = newJObject()
  add(query_602493, "ResourceName", newJString(ResourceName))
  add(query_602493, "Action", newJString(Action))
  add(query_602493, "Version", newJString(Version))
  result = call_602492.call(nil, query_602493, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_602478(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_602479, base: "/",
    url: url_GetListTagsForResource_602480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_602544 = ref object of OpenApiRestCall_600421
proc url_PostModifyDBInstance_602546(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_602545(path: JsonNode; query: JsonNode;
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
  var valid_602547 = query.getOrDefault("Action")
  valid_602547 = validateParameter(valid_602547, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602547 != nil:
    section.add "Action", valid_602547
  var valid_602548 = query.getOrDefault("Version")
  valid_602548 = validateParameter(valid_602548, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602548 != nil:
    section.add "Version", valid_602548
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
  var valid_602549 = header.getOrDefault("X-Amz-Date")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-Date", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-Security-Token")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-Security-Token", valid_602550
  var valid_602551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602551 = validateParameter(valid_602551, JString, required = false,
                                 default = nil)
  if valid_602551 != nil:
    section.add "X-Amz-Content-Sha256", valid_602551
  var valid_602552 = header.getOrDefault("X-Amz-Algorithm")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "X-Amz-Algorithm", valid_602552
  var valid_602553 = header.getOrDefault("X-Amz-Signature")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-Signature", valid_602553
  var valid_602554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-SignedHeaders", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-Credential")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Credential", valid_602555
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
  var valid_602556 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "PreferredMaintenanceWindow", valid_602556
  var valid_602557 = formData.getOrDefault("DBSecurityGroups")
  valid_602557 = validateParameter(valid_602557, JArray, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "DBSecurityGroups", valid_602557
  var valid_602558 = formData.getOrDefault("ApplyImmediately")
  valid_602558 = validateParameter(valid_602558, JBool, required = false, default = nil)
  if valid_602558 != nil:
    section.add "ApplyImmediately", valid_602558
  var valid_602559 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_602559 = validateParameter(valid_602559, JArray, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "VpcSecurityGroupIds", valid_602559
  var valid_602560 = formData.getOrDefault("Iops")
  valid_602560 = validateParameter(valid_602560, JInt, required = false, default = nil)
  if valid_602560 != nil:
    section.add "Iops", valid_602560
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602561 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602561 = validateParameter(valid_602561, JString, required = true,
                                 default = nil)
  if valid_602561 != nil:
    section.add "DBInstanceIdentifier", valid_602561
  var valid_602562 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602562 = validateParameter(valid_602562, JInt, required = false, default = nil)
  if valid_602562 != nil:
    section.add "BackupRetentionPeriod", valid_602562
  var valid_602563 = formData.getOrDefault("DBParameterGroupName")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "DBParameterGroupName", valid_602563
  var valid_602564 = formData.getOrDefault("OptionGroupName")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "OptionGroupName", valid_602564
  var valid_602565 = formData.getOrDefault("MasterUserPassword")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "MasterUserPassword", valid_602565
  var valid_602566 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "NewDBInstanceIdentifier", valid_602566
  var valid_602567 = formData.getOrDefault("MultiAZ")
  valid_602567 = validateParameter(valid_602567, JBool, required = false, default = nil)
  if valid_602567 != nil:
    section.add "MultiAZ", valid_602567
  var valid_602568 = formData.getOrDefault("AllocatedStorage")
  valid_602568 = validateParameter(valid_602568, JInt, required = false, default = nil)
  if valid_602568 != nil:
    section.add "AllocatedStorage", valid_602568
  var valid_602569 = formData.getOrDefault("DBInstanceClass")
  valid_602569 = validateParameter(valid_602569, JString, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "DBInstanceClass", valid_602569
  var valid_602570 = formData.getOrDefault("PreferredBackupWindow")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "PreferredBackupWindow", valid_602570
  var valid_602571 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602571 = validateParameter(valid_602571, JBool, required = false, default = nil)
  if valid_602571 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602571
  var valid_602572 = formData.getOrDefault("EngineVersion")
  valid_602572 = validateParameter(valid_602572, JString, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "EngineVersion", valid_602572
  var valid_602573 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_602573 = validateParameter(valid_602573, JBool, required = false, default = nil)
  if valid_602573 != nil:
    section.add "AllowMajorVersionUpgrade", valid_602573
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602574: Call_PostModifyDBInstance_602544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602574.validator(path, query, header, formData, body)
  let scheme = call_602574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602574.url(scheme.get, call_602574.host, call_602574.base,
                         call_602574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602574, url, valid)

proc call*(call_602575: Call_PostModifyDBInstance_602544;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBSecurityGroups: JsonNode = nil; ApplyImmediately: bool = false;
          VpcSecurityGroupIds: JsonNode = nil; Iops: int = 0;
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          OptionGroupName: string = ""; MasterUserPassword: string = "";
          NewDBInstanceIdentifier: string = ""; MultiAZ: bool = false;
          Action: string = "ModifyDBInstance"; AllocatedStorage: int = 0;
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          Version: string = "2013-02-12"; AllowMajorVersionUpgrade: bool = false): Recallable =
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
  var query_602576 = newJObject()
  var formData_602577 = newJObject()
  add(formData_602577, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_602577.add "DBSecurityGroups", DBSecurityGroups
  add(formData_602577, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_602577.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_602577, "Iops", newJInt(Iops))
  add(formData_602577, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602577, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_602577, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602577, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602577, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_602577, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_602577, "MultiAZ", newJBool(MultiAZ))
  add(query_602576, "Action", newJString(Action))
  add(formData_602577, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_602577, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602577, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_602577, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_602577, "EngineVersion", newJString(EngineVersion))
  add(query_602576, "Version", newJString(Version))
  add(formData_602577, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_602575.call(nil, query_602576, nil, formData_602577, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_602544(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_602545, base: "/",
    url: url_PostModifyDBInstance_602546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_602511 = ref object of OpenApiRestCall_600421
proc url_GetModifyDBInstance_602513(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_602512(path: JsonNode; query: JsonNode;
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
  var valid_602514 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "PreferredMaintenanceWindow", valid_602514
  var valid_602515 = query.getOrDefault("AllocatedStorage")
  valid_602515 = validateParameter(valid_602515, JInt, required = false, default = nil)
  if valid_602515 != nil:
    section.add "AllocatedStorage", valid_602515
  var valid_602516 = query.getOrDefault("OptionGroupName")
  valid_602516 = validateParameter(valid_602516, JString, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "OptionGroupName", valid_602516
  var valid_602517 = query.getOrDefault("DBSecurityGroups")
  valid_602517 = validateParameter(valid_602517, JArray, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "DBSecurityGroups", valid_602517
  var valid_602518 = query.getOrDefault("MasterUserPassword")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "MasterUserPassword", valid_602518
  var valid_602519 = query.getOrDefault("Iops")
  valid_602519 = validateParameter(valid_602519, JInt, required = false, default = nil)
  if valid_602519 != nil:
    section.add "Iops", valid_602519
  var valid_602520 = query.getOrDefault("VpcSecurityGroupIds")
  valid_602520 = validateParameter(valid_602520, JArray, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "VpcSecurityGroupIds", valid_602520
  var valid_602521 = query.getOrDefault("MultiAZ")
  valid_602521 = validateParameter(valid_602521, JBool, required = false, default = nil)
  if valid_602521 != nil:
    section.add "MultiAZ", valid_602521
  var valid_602522 = query.getOrDefault("BackupRetentionPeriod")
  valid_602522 = validateParameter(valid_602522, JInt, required = false, default = nil)
  if valid_602522 != nil:
    section.add "BackupRetentionPeriod", valid_602522
  var valid_602523 = query.getOrDefault("DBParameterGroupName")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "DBParameterGroupName", valid_602523
  var valid_602524 = query.getOrDefault("DBInstanceClass")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "DBInstanceClass", valid_602524
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602525 = query.getOrDefault("Action")
  valid_602525 = validateParameter(valid_602525, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602525 != nil:
    section.add "Action", valid_602525
  var valid_602526 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_602526 = validateParameter(valid_602526, JBool, required = false, default = nil)
  if valid_602526 != nil:
    section.add "AllowMajorVersionUpgrade", valid_602526
  var valid_602527 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "NewDBInstanceIdentifier", valid_602527
  var valid_602528 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602528 = validateParameter(valid_602528, JBool, required = false, default = nil)
  if valid_602528 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602528
  var valid_602529 = query.getOrDefault("EngineVersion")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "EngineVersion", valid_602529
  var valid_602530 = query.getOrDefault("PreferredBackupWindow")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "PreferredBackupWindow", valid_602530
  var valid_602531 = query.getOrDefault("Version")
  valid_602531 = validateParameter(valid_602531, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602531 != nil:
    section.add "Version", valid_602531
  var valid_602532 = query.getOrDefault("DBInstanceIdentifier")
  valid_602532 = validateParameter(valid_602532, JString, required = true,
                                 default = nil)
  if valid_602532 != nil:
    section.add "DBInstanceIdentifier", valid_602532
  var valid_602533 = query.getOrDefault("ApplyImmediately")
  valid_602533 = validateParameter(valid_602533, JBool, required = false, default = nil)
  if valid_602533 != nil:
    section.add "ApplyImmediately", valid_602533
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
  var valid_602534 = header.getOrDefault("X-Amz-Date")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Date", valid_602534
  var valid_602535 = header.getOrDefault("X-Amz-Security-Token")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-Security-Token", valid_602535
  var valid_602536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "X-Amz-Content-Sha256", valid_602536
  var valid_602537 = header.getOrDefault("X-Amz-Algorithm")
  valid_602537 = validateParameter(valid_602537, JString, required = false,
                                 default = nil)
  if valid_602537 != nil:
    section.add "X-Amz-Algorithm", valid_602537
  var valid_602538 = header.getOrDefault("X-Amz-Signature")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-Signature", valid_602538
  var valid_602539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-SignedHeaders", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Credential")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Credential", valid_602540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602541: Call_GetModifyDBInstance_602511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602541.validator(path, query, header, formData, body)
  let scheme = call_602541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602541.url(scheme.get, call_602541.host, call_602541.base,
                         call_602541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602541, url, valid)

proc call*(call_602542: Call_GetModifyDBInstance_602511;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          AllocatedStorage: int = 0; OptionGroupName: string = "";
          DBSecurityGroups: JsonNode = nil; MasterUserPassword: string = "";
          Iops: int = 0; VpcSecurityGroupIds: JsonNode = nil; MultiAZ: bool = false;
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          DBInstanceClass: string = ""; Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false;
          NewDBInstanceIdentifier: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          PreferredBackupWindow: string = ""; Version: string = "2013-02-12";
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
  var query_602543 = newJObject()
  add(query_602543, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_602543, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_602543, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_602543.add "DBSecurityGroups", DBSecurityGroups
  add(query_602543, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_602543, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_602543.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_602543, "MultiAZ", newJBool(MultiAZ))
  add(query_602543, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602543, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602543, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602543, "Action", newJString(Action))
  add(query_602543, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_602543, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_602543, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602543, "EngineVersion", newJString(EngineVersion))
  add(query_602543, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602543, "Version", newJString(Version))
  add(query_602543, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602543, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_602542.call(nil, query_602543, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_602511(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_602512, base: "/",
    url: url_GetModifyDBInstance_602513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_602595 = ref object of OpenApiRestCall_600421
proc url_PostModifyDBParameterGroup_602597(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_602596(path: JsonNode; query: JsonNode;
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
  var valid_602598 = query.getOrDefault("Action")
  valid_602598 = validateParameter(valid_602598, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_602598 != nil:
    section.add "Action", valid_602598
  var valid_602599 = query.getOrDefault("Version")
  valid_602599 = validateParameter(valid_602599, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602599 != nil:
    section.add "Version", valid_602599
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
  var valid_602600 = header.getOrDefault("X-Amz-Date")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Date", valid_602600
  var valid_602601 = header.getOrDefault("X-Amz-Security-Token")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "X-Amz-Security-Token", valid_602601
  var valid_602602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "X-Amz-Content-Sha256", valid_602602
  var valid_602603 = header.getOrDefault("X-Amz-Algorithm")
  valid_602603 = validateParameter(valid_602603, JString, required = false,
                                 default = nil)
  if valid_602603 != nil:
    section.add "X-Amz-Algorithm", valid_602603
  var valid_602604 = header.getOrDefault("X-Amz-Signature")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "X-Amz-Signature", valid_602604
  var valid_602605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-SignedHeaders", valid_602605
  var valid_602606 = header.getOrDefault("X-Amz-Credential")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-Credential", valid_602606
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602607 = formData.getOrDefault("DBParameterGroupName")
  valid_602607 = validateParameter(valid_602607, JString, required = true,
                                 default = nil)
  if valid_602607 != nil:
    section.add "DBParameterGroupName", valid_602607
  var valid_602608 = formData.getOrDefault("Parameters")
  valid_602608 = validateParameter(valid_602608, JArray, required = true, default = nil)
  if valid_602608 != nil:
    section.add "Parameters", valid_602608
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602609: Call_PostModifyDBParameterGroup_602595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602609.validator(path, query, header, formData, body)
  let scheme = call_602609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602609.url(scheme.get, call_602609.host, call_602609.base,
                         call_602609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602609, url, valid)

proc call*(call_602610: Call_PostModifyDBParameterGroup_602595;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602611 = newJObject()
  var formData_602612 = newJObject()
  add(formData_602612, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_602612.add "Parameters", Parameters
  add(query_602611, "Action", newJString(Action))
  add(query_602611, "Version", newJString(Version))
  result = call_602610.call(nil, query_602611, nil, formData_602612, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_602595(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_602596, base: "/",
    url: url_PostModifyDBParameterGroup_602597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_602578 = ref object of OpenApiRestCall_600421
proc url_GetModifyDBParameterGroup_602580(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_602579(path: JsonNode; query: JsonNode;
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
  var valid_602581 = query.getOrDefault("DBParameterGroupName")
  valid_602581 = validateParameter(valid_602581, JString, required = true,
                                 default = nil)
  if valid_602581 != nil:
    section.add "DBParameterGroupName", valid_602581
  var valid_602582 = query.getOrDefault("Parameters")
  valid_602582 = validateParameter(valid_602582, JArray, required = true, default = nil)
  if valid_602582 != nil:
    section.add "Parameters", valid_602582
  var valid_602583 = query.getOrDefault("Action")
  valid_602583 = validateParameter(valid_602583, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_602583 != nil:
    section.add "Action", valid_602583
  var valid_602584 = query.getOrDefault("Version")
  valid_602584 = validateParameter(valid_602584, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602584 != nil:
    section.add "Version", valid_602584
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
  var valid_602585 = header.getOrDefault("X-Amz-Date")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-Date", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-Security-Token")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Security-Token", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-Content-Sha256", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-Algorithm")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-Algorithm", valid_602588
  var valid_602589 = header.getOrDefault("X-Amz-Signature")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-Signature", valid_602589
  var valid_602590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-SignedHeaders", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-Credential")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-Credential", valid_602591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602592: Call_GetModifyDBParameterGroup_602578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602592.validator(path, query, header, formData, body)
  let scheme = call_602592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602592.url(scheme.get, call_602592.host, call_602592.base,
                         call_602592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602592, url, valid)

proc call*(call_602593: Call_GetModifyDBParameterGroup_602578;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602594 = newJObject()
  add(query_602594, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_602594.add "Parameters", Parameters
  add(query_602594, "Action", newJString(Action))
  add(query_602594, "Version", newJString(Version))
  result = call_602593.call(nil, query_602594, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_602578(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_602579, base: "/",
    url: url_GetModifyDBParameterGroup_602580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_602631 = ref object of OpenApiRestCall_600421
proc url_PostModifyDBSubnetGroup_602633(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_602632(path: JsonNode; query: JsonNode;
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
  var valid_602634 = query.getOrDefault("Action")
  valid_602634 = validateParameter(valid_602634, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602634 != nil:
    section.add "Action", valid_602634
  var valid_602635 = query.getOrDefault("Version")
  valid_602635 = validateParameter(valid_602635, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602635 != nil:
    section.add "Version", valid_602635
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
  var valid_602636 = header.getOrDefault("X-Amz-Date")
  valid_602636 = validateParameter(valid_602636, JString, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "X-Amz-Date", valid_602636
  var valid_602637 = header.getOrDefault("X-Amz-Security-Token")
  valid_602637 = validateParameter(valid_602637, JString, required = false,
                                 default = nil)
  if valid_602637 != nil:
    section.add "X-Amz-Security-Token", valid_602637
  var valid_602638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602638 = validateParameter(valid_602638, JString, required = false,
                                 default = nil)
  if valid_602638 != nil:
    section.add "X-Amz-Content-Sha256", valid_602638
  var valid_602639 = header.getOrDefault("X-Amz-Algorithm")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-Algorithm", valid_602639
  var valid_602640 = header.getOrDefault("X-Amz-Signature")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-Signature", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-SignedHeaders", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Credential")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Credential", valid_602642
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_602643 = formData.getOrDefault("DBSubnetGroupName")
  valid_602643 = validateParameter(valid_602643, JString, required = true,
                                 default = nil)
  if valid_602643 != nil:
    section.add "DBSubnetGroupName", valid_602643
  var valid_602644 = formData.getOrDefault("SubnetIds")
  valid_602644 = validateParameter(valid_602644, JArray, required = true, default = nil)
  if valid_602644 != nil:
    section.add "SubnetIds", valid_602644
  var valid_602645 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "DBSubnetGroupDescription", valid_602645
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602646: Call_PostModifyDBSubnetGroup_602631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602646.validator(path, query, header, formData, body)
  let scheme = call_602646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602646.url(scheme.get, call_602646.host, call_602646.base,
                         call_602646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602646, url, valid)

proc call*(call_602647: Call_PostModifyDBSubnetGroup_602631;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_602648 = newJObject()
  var formData_602649 = newJObject()
  add(formData_602649, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_602649.add "SubnetIds", SubnetIds
  add(query_602648, "Action", newJString(Action))
  add(formData_602649, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602648, "Version", newJString(Version))
  result = call_602647.call(nil, query_602648, nil, formData_602649, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_602631(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_602632, base: "/",
    url: url_PostModifyDBSubnetGroup_602633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_602613 = ref object of OpenApiRestCall_600421
proc url_GetModifyDBSubnetGroup_602615(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_602614(path: JsonNode; query: JsonNode;
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
  var valid_602616 = query.getOrDefault("Action")
  valid_602616 = validateParameter(valid_602616, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602616 != nil:
    section.add "Action", valid_602616
  var valid_602617 = query.getOrDefault("DBSubnetGroupName")
  valid_602617 = validateParameter(valid_602617, JString, required = true,
                                 default = nil)
  if valid_602617 != nil:
    section.add "DBSubnetGroupName", valid_602617
  var valid_602618 = query.getOrDefault("SubnetIds")
  valid_602618 = validateParameter(valid_602618, JArray, required = true, default = nil)
  if valid_602618 != nil:
    section.add "SubnetIds", valid_602618
  var valid_602619 = query.getOrDefault("DBSubnetGroupDescription")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "DBSubnetGroupDescription", valid_602619
  var valid_602620 = query.getOrDefault("Version")
  valid_602620 = validateParameter(valid_602620, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602620 != nil:
    section.add "Version", valid_602620
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
  var valid_602621 = header.getOrDefault("X-Amz-Date")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "X-Amz-Date", valid_602621
  var valid_602622 = header.getOrDefault("X-Amz-Security-Token")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "X-Amz-Security-Token", valid_602622
  var valid_602623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Content-Sha256", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-Algorithm")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Algorithm", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Signature")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Signature", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-SignedHeaders", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-Credential")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Credential", valid_602627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602628: Call_GetModifyDBSubnetGroup_602613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602628.validator(path, query, header, formData, body)
  let scheme = call_602628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602628.url(scheme.get, call_602628.host, call_602628.base,
                         call_602628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602628, url, valid)

proc call*(call_602629: Call_GetModifyDBSubnetGroup_602613;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_602630 = newJObject()
  add(query_602630, "Action", newJString(Action))
  add(query_602630, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_602630.add "SubnetIds", SubnetIds
  add(query_602630, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602630, "Version", newJString(Version))
  result = call_602629.call(nil, query_602630, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_602613(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_602614, base: "/",
    url: url_GetModifyDBSubnetGroup_602615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_602670 = ref object of OpenApiRestCall_600421
proc url_PostModifyEventSubscription_602672(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_602671(path: JsonNode; query: JsonNode;
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
  var valid_602673 = query.getOrDefault("Action")
  valid_602673 = validateParameter(valid_602673, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_602673 != nil:
    section.add "Action", valid_602673
  var valid_602674 = query.getOrDefault("Version")
  valid_602674 = validateParameter(valid_602674, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602674 != nil:
    section.add "Version", valid_602674
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
  var valid_602675 = header.getOrDefault("X-Amz-Date")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Date", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Security-Token")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Security-Token", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Content-Sha256", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-Algorithm")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-Algorithm", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-Signature")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Signature", valid_602679
  var valid_602680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-SignedHeaders", valid_602680
  var valid_602681 = header.getOrDefault("X-Amz-Credential")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-Credential", valid_602681
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_602682 = formData.getOrDefault("Enabled")
  valid_602682 = validateParameter(valid_602682, JBool, required = false, default = nil)
  if valid_602682 != nil:
    section.add "Enabled", valid_602682
  var valid_602683 = formData.getOrDefault("EventCategories")
  valid_602683 = validateParameter(valid_602683, JArray, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "EventCategories", valid_602683
  var valid_602684 = formData.getOrDefault("SnsTopicArn")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "SnsTopicArn", valid_602684
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_602685 = formData.getOrDefault("SubscriptionName")
  valid_602685 = validateParameter(valid_602685, JString, required = true,
                                 default = nil)
  if valid_602685 != nil:
    section.add "SubscriptionName", valid_602685
  var valid_602686 = formData.getOrDefault("SourceType")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "SourceType", valid_602686
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602687: Call_PostModifyEventSubscription_602670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602687.validator(path, query, header, formData, body)
  let scheme = call_602687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602687.url(scheme.get, call_602687.host, call_602687.base,
                         call_602687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602687, url, valid)

proc call*(call_602688: Call_PostModifyEventSubscription_602670;
          SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SnsTopicArn: string = "";
          Action: string = "ModifyEventSubscription";
          Version: string = "2013-02-12"; SourceType: string = ""): Recallable =
  ## postModifyEventSubscription
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   SnsTopicArn: string
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_602689 = newJObject()
  var formData_602690 = newJObject()
  add(formData_602690, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_602690.add "EventCategories", EventCategories
  add(formData_602690, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_602690, "SubscriptionName", newJString(SubscriptionName))
  add(query_602689, "Action", newJString(Action))
  add(query_602689, "Version", newJString(Version))
  add(formData_602690, "SourceType", newJString(SourceType))
  result = call_602688.call(nil, query_602689, nil, formData_602690, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_602670(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_602671, base: "/",
    url: url_PostModifyEventSubscription_602672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_602650 = ref object of OpenApiRestCall_600421
proc url_GetModifyEventSubscription_602652(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_602651(path: JsonNode; query: JsonNode;
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
  var valid_602653 = query.getOrDefault("SourceType")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "SourceType", valid_602653
  var valid_602654 = query.getOrDefault("Enabled")
  valid_602654 = validateParameter(valid_602654, JBool, required = false, default = nil)
  if valid_602654 != nil:
    section.add "Enabled", valid_602654
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602655 = query.getOrDefault("Action")
  valid_602655 = validateParameter(valid_602655, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_602655 != nil:
    section.add "Action", valid_602655
  var valid_602656 = query.getOrDefault("SnsTopicArn")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "SnsTopicArn", valid_602656
  var valid_602657 = query.getOrDefault("EventCategories")
  valid_602657 = validateParameter(valid_602657, JArray, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "EventCategories", valid_602657
  var valid_602658 = query.getOrDefault("SubscriptionName")
  valid_602658 = validateParameter(valid_602658, JString, required = true,
                                 default = nil)
  if valid_602658 != nil:
    section.add "SubscriptionName", valid_602658
  var valid_602659 = query.getOrDefault("Version")
  valid_602659 = validateParameter(valid_602659, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602659 != nil:
    section.add "Version", valid_602659
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
  var valid_602660 = header.getOrDefault("X-Amz-Date")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Date", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-Security-Token")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-Security-Token", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-Content-Sha256", valid_602662
  var valid_602663 = header.getOrDefault("X-Amz-Algorithm")
  valid_602663 = validateParameter(valid_602663, JString, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "X-Amz-Algorithm", valid_602663
  var valid_602664 = header.getOrDefault("X-Amz-Signature")
  valid_602664 = validateParameter(valid_602664, JString, required = false,
                                 default = nil)
  if valid_602664 != nil:
    section.add "X-Amz-Signature", valid_602664
  var valid_602665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "X-Amz-SignedHeaders", valid_602665
  var valid_602666 = header.getOrDefault("X-Amz-Credential")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-Credential", valid_602666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602667: Call_GetModifyEventSubscription_602650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602667.validator(path, query, header, formData, body)
  let scheme = call_602667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602667.url(scheme.get, call_602667.host, call_602667.base,
                         call_602667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602667, url, valid)

proc call*(call_602668: Call_GetModifyEventSubscription_602650;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          EventCategories: JsonNode = nil; Version: string = "2013-02-12"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   EventCategories: JArray
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_602669 = newJObject()
  add(query_602669, "SourceType", newJString(SourceType))
  add(query_602669, "Enabled", newJBool(Enabled))
  add(query_602669, "Action", newJString(Action))
  add(query_602669, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_602669.add "EventCategories", EventCategories
  add(query_602669, "SubscriptionName", newJString(SubscriptionName))
  add(query_602669, "Version", newJString(Version))
  result = call_602668.call(nil, query_602669, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_602650(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_602651, base: "/",
    url: url_GetModifyEventSubscription_602652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_602710 = ref object of OpenApiRestCall_600421
proc url_PostModifyOptionGroup_602712(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_602711(path: JsonNode; query: JsonNode;
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
  var valid_602713 = query.getOrDefault("Action")
  valid_602713 = validateParameter(valid_602713, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_602713 != nil:
    section.add "Action", valid_602713
  var valid_602714 = query.getOrDefault("Version")
  valid_602714 = validateParameter(valid_602714, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602714 != nil:
    section.add "Version", valid_602714
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
  var valid_602715 = header.getOrDefault("X-Amz-Date")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-Date", valid_602715
  var valid_602716 = header.getOrDefault("X-Amz-Security-Token")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "X-Amz-Security-Token", valid_602716
  var valid_602717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602717 = validateParameter(valid_602717, JString, required = false,
                                 default = nil)
  if valid_602717 != nil:
    section.add "X-Amz-Content-Sha256", valid_602717
  var valid_602718 = header.getOrDefault("X-Amz-Algorithm")
  valid_602718 = validateParameter(valid_602718, JString, required = false,
                                 default = nil)
  if valid_602718 != nil:
    section.add "X-Amz-Algorithm", valid_602718
  var valid_602719 = header.getOrDefault("X-Amz-Signature")
  valid_602719 = validateParameter(valid_602719, JString, required = false,
                                 default = nil)
  if valid_602719 != nil:
    section.add "X-Amz-Signature", valid_602719
  var valid_602720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602720 = validateParameter(valid_602720, JString, required = false,
                                 default = nil)
  if valid_602720 != nil:
    section.add "X-Amz-SignedHeaders", valid_602720
  var valid_602721 = header.getOrDefault("X-Amz-Credential")
  valid_602721 = validateParameter(valid_602721, JString, required = false,
                                 default = nil)
  if valid_602721 != nil:
    section.add "X-Amz-Credential", valid_602721
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_602722 = formData.getOrDefault("OptionsToRemove")
  valid_602722 = validateParameter(valid_602722, JArray, required = false,
                                 default = nil)
  if valid_602722 != nil:
    section.add "OptionsToRemove", valid_602722
  var valid_602723 = formData.getOrDefault("ApplyImmediately")
  valid_602723 = validateParameter(valid_602723, JBool, required = false, default = nil)
  if valid_602723 != nil:
    section.add "ApplyImmediately", valid_602723
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_602724 = formData.getOrDefault("OptionGroupName")
  valid_602724 = validateParameter(valid_602724, JString, required = true,
                                 default = nil)
  if valid_602724 != nil:
    section.add "OptionGroupName", valid_602724
  var valid_602725 = formData.getOrDefault("OptionsToInclude")
  valid_602725 = validateParameter(valid_602725, JArray, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "OptionsToInclude", valid_602725
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602726: Call_PostModifyOptionGroup_602710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602726.validator(path, query, header, formData, body)
  let scheme = call_602726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602726.url(scheme.get, call_602726.host, call_602726.base,
                         call_602726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602726, url, valid)

proc call*(call_602727: Call_PostModifyOptionGroup_602710; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionGroupName: string (required)
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602728 = newJObject()
  var formData_602729 = newJObject()
  if OptionsToRemove != nil:
    formData_602729.add "OptionsToRemove", OptionsToRemove
  add(formData_602729, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_602729, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_602729.add "OptionsToInclude", OptionsToInclude
  add(query_602728, "Action", newJString(Action))
  add(query_602728, "Version", newJString(Version))
  result = call_602727.call(nil, query_602728, nil, formData_602729, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_602710(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_602711, base: "/",
    url: url_PostModifyOptionGroup_602712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_602691 = ref object of OpenApiRestCall_600421
proc url_GetModifyOptionGroup_602693(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_602692(path: JsonNode; query: JsonNode;
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
  var valid_602694 = query.getOrDefault("OptionGroupName")
  valid_602694 = validateParameter(valid_602694, JString, required = true,
                                 default = nil)
  if valid_602694 != nil:
    section.add "OptionGroupName", valid_602694
  var valid_602695 = query.getOrDefault("OptionsToRemove")
  valid_602695 = validateParameter(valid_602695, JArray, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "OptionsToRemove", valid_602695
  var valid_602696 = query.getOrDefault("Action")
  valid_602696 = validateParameter(valid_602696, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_602696 != nil:
    section.add "Action", valid_602696
  var valid_602697 = query.getOrDefault("Version")
  valid_602697 = validateParameter(valid_602697, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602697 != nil:
    section.add "Version", valid_602697
  var valid_602698 = query.getOrDefault("ApplyImmediately")
  valid_602698 = validateParameter(valid_602698, JBool, required = false, default = nil)
  if valid_602698 != nil:
    section.add "ApplyImmediately", valid_602698
  var valid_602699 = query.getOrDefault("OptionsToInclude")
  valid_602699 = validateParameter(valid_602699, JArray, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "OptionsToInclude", valid_602699
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
  var valid_602700 = header.getOrDefault("X-Amz-Date")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Date", valid_602700
  var valid_602701 = header.getOrDefault("X-Amz-Security-Token")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "X-Amz-Security-Token", valid_602701
  var valid_602702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "X-Amz-Content-Sha256", valid_602702
  var valid_602703 = header.getOrDefault("X-Amz-Algorithm")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "X-Amz-Algorithm", valid_602703
  var valid_602704 = header.getOrDefault("X-Amz-Signature")
  valid_602704 = validateParameter(valid_602704, JString, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "X-Amz-Signature", valid_602704
  var valid_602705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602705 = validateParameter(valid_602705, JString, required = false,
                                 default = nil)
  if valid_602705 != nil:
    section.add "X-Amz-SignedHeaders", valid_602705
  var valid_602706 = header.getOrDefault("X-Amz-Credential")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "X-Amz-Credential", valid_602706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602707: Call_GetModifyOptionGroup_602691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602707.validator(path, query, header, formData, body)
  let scheme = call_602707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602707.url(scheme.get, call_602707.host, call_602707.base,
                         call_602707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602707, url, valid)

proc call*(call_602708: Call_GetModifyOptionGroup_602691; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-02-12"; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil): Recallable =
  ## getModifyOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionsToRemove: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  var query_602709 = newJObject()
  add(query_602709, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_602709.add "OptionsToRemove", OptionsToRemove
  add(query_602709, "Action", newJString(Action))
  add(query_602709, "Version", newJString(Version))
  add(query_602709, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_602709.add "OptionsToInclude", OptionsToInclude
  result = call_602708.call(nil, query_602709, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_602691(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_602692, base: "/",
    url: url_GetModifyOptionGroup_602693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_602748 = ref object of OpenApiRestCall_600421
proc url_PostPromoteReadReplica_602750(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_602749(path: JsonNode; query: JsonNode;
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
  var valid_602751 = query.getOrDefault("Action")
  valid_602751 = validateParameter(valid_602751, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_602751 != nil:
    section.add "Action", valid_602751
  var valid_602752 = query.getOrDefault("Version")
  valid_602752 = validateParameter(valid_602752, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602752 != nil:
    section.add "Version", valid_602752
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
  var valid_602753 = header.getOrDefault("X-Amz-Date")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "X-Amz-Date", valid_602753
  var valid_602754 = header.getOrDefault("X-Amz-Security-Token")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Security-Token", valid_602754
  var valid_602755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602755 = validateParameter(valid_602755, JString, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "X-Amz-Content-Sha256", valid_602755
  var valid_602756 = header.getOrDefault("X-Amz-Algorithm")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-Algorithm", valid_602756
  var valid_602757 = header.getOrDefault("X-Amz-Signature")
  valid_602757 = validateParameter(valid_602757, JString, required = false,
                                 default = nil)
  if valid_602757 != nil:
    section.add "X-Amz-Signature", valid_602757
  var valid_602758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602758 = validateParameter(valid_602758, JString, required = false,
                                 default = nil)
  if valid_602758 != nil:
    section.add "X-Amz-SignedHeaders", valid_602758
  var valid_602759 = header.getOrDefault("X-Amz-Credential")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-Credential", valid_602759
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602760 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602760 = validateParameter(valid_602760, JString, required = true,
                                 default = nil)
  if valid_602760 != nil:
    section.add "DBInstanceIdentifier", valid_602760
  var valid_602761 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602761 = validateParameter(valid_602761, JInt, required = false, default = nil)
  if valid_602761 != nil:
    section.add "BackupRetentionPeriod", valid_602761
  var valid_602762 = formData.getOrDefault("PreferredBackupWindow")
  valid_602762 = validateParameter(valid_602762, JString, required = false,
                                 default = nil)
  if valid_602762 != nil:
    section.add "PreferredBackupWindow", valid_602762
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602763: Call_PostPromoteReadReplica_602748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602763.validator(path, query, header, formData, body)
  let scheme = call_602763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602763.url(scheme.get, call_602763.host, call_602763.base,
                         call_602763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602763, url, valid)

proc call*(call_602764: Call_PostPromoteReadReplica_602748;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_602765 = newJObject()
  var formData_602766 = newJObject()
  add(formData_602766, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602766, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602765, "Action", newJString(Action))
  add(formData_602766, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602765, "Version", newJString(Version))
  result = call_602764.call(nil, query_602765, nil, formData_602766, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_602748(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_602749, base: "/",
    url: url_PostPromoteReadReplica_602750, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_602730 = ref object of OpenApiRestCall_600421
proc url_GetPromoteReadReplica_602732(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_602731(path: JsonNode; query: JsonNode;
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
  var valid_602733 = query.getOrDefault("BackupRetentionPeriod")
  valid_602733 = validateParameter(valid_602733, JInt, required = false, default = nil)
  if valid_602733 != nil:
    section.add "BackupRetentionPeriod", valid_602733
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602734 = query.getOrDefault("Action")
  valid_602734 = validateParameter(valid_602734, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_602734 != nil:
    section.add "Action", valid_602734
  var valid_602735 = query.getOrDefault("PreferredBackupWindow")
  valid_602735 = validateParameter(valid_602735, JString, required = false,
                                 default = nil)
  if valid_602735 != nil:
    section.add "PreferredBackupWindow", valid_602735
  var valid_602736 = query.getOrDefault("Version")
  valid_602736 = validateParameter(valid_602736, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602736 != nil:
    section.add "Version", valid_602736
  var valid_602737 = query.getOrDefault("DBInstanceIdentifier")
  valid_602737 = validateParameter(valid_602737, JString, required = true,
                                 default = nil)
  if valid_602737 != nil:
    section.add "DBInstanceIdentifier", valid_602737
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
  var valid_602738 = header.getOrDefault("X-Amz-Date")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-Date", valid_602738
  var valid_602739 = header.getOrDefault("X-Amz-Security-Token")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "X-Amz-Security-Token", valid_602739
  var valid_602740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "X-Amz-Content-Sha256", valid_602740
  var valid_602741 = header.getOrDefault("X-Amz-Algorithm")
  valid_602741 = validateParameter(valid_602741, JString, required = false,
                                 default = nil)
  if valid_602741 != nil:
    section.add "X-Amz-Algorithm", valid_602741
  var valid_602742 = header.getOrDefault("X-Amz-Signature")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "X-Amz-Signature", valid_602742
  var valid_602743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602743 = validateParameter(valid_602743, JString, required = false,
                                 default = nil)
  if valid_602743 != nil:
    section.add "X-Amz-SignedHeaders", valid_602743
  var valid_602744 = header.getOrDefault("X-Amz-Credential")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-Credential", valid_602744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602745: Call_GetPromoteReadReplica_602730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602745.validator(path, query, header, formData, body)
  let scheme = call_602745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602745.url(scheme.get, call_602745.host, call_602745.base,
                         call_602745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602745, url, valid)

proc call*(call_602746: Call_GetPromoteReadReplica_602730;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602747 = newJObject()
  add(query_602747, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602747, "Action", newJString(Action))
  add(query_602747, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602747, "Version", newJString(Version))
  add(query_602747, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602746.call(nil, query_602747, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_602730(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_602731, base: "/",
    url: url_GetPromoteReadReplica_602732, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_602785 = ref object of OpenApiRestCall_600421
proc url_PostPurchaseReservedDBInstancesOffering_602787(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_602786(path: JsonNode;
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
  var valid_602788 = query.getOrDefault("Action")
  valid_602788 = validateParameter(valid_602788, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_602788 != nil:
    section.add "Action", valid_602788
  var valid_602789 = query.getOrDefault("Version")
  valid_602789 = validateParameter(valid_602789, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602789 != nil:
    section.add "Version", valid_602789
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
  var valid_602790 = header.getOrDefault("X-Amz-Date")
  valid_602790 = validateParameter(valid_602790, JString, required = false,
                                 default = nil)
  if valid_602790 != nil:
    section.add "X-Amz-Date", valid_602790
  var valid_602791 = header.getOrDefault("X-Amz-Security-Token")
  valid_602791 = validateParameter(valid_602791, JString, required = false,
                                 default = nil)
  if valid_602791 != nil:
    section.add "X-Amz-Security-Token", valid_602791
  var valid_602792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602792 = validateParameter(valid_602792, JString, required = false,
                                 default = nil)
  if valid_602792 != nil:
    section.add "X-Amz-Content-Sha256", valid_602792
  var valid_602793 = header.getOrDefault("X-Amz-Algorithm")
  valid_602793 = validateParameter(valid_602793, JString, required = false,
                                 default = nil)
  if valid_602793 != nil:
    section.add "X-Amz-Algorithm", valid_602793
  var valid_602794 = header.getOrDefault("X-Amz-Signature")
  valid_602794 = validateParameter(valid_602794, JString, required = false,
                                 default = nil)
  if valid_602794 != nil:
    section.add "X-Amz-Signature", valid_602794
  var valid_602795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602795 = validateParameter(valid_602795, JString, required = false,
                                 default = nil)
  if valid_602795 != nil:
    section.add "X-Amz-SignedHeaders", valid_602795
  var valid_602796 = header.getOrDefault("X-Amz-Credential")
  valid_602796 = validateParameter(valid_602796, JString, required = false,
                                 default = nil)
  if valid_602796 != nil:
    section.add "X-Amz-Credential", valid_602796
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_602797 = formData.getOrDefault("ReservedDBInstanceId")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "ReservedDBInstanceId", valid_602797
  var valid_602798 = formData.getOrDefault("DBInstanceCount")
  valid_602798 = validateParameter(valid_602798, JInt, required = false, default = nil)
  if valid_602798 != nil:
    section.add "DBInstanceCount", valid_602798
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_602799 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602799 = validateParameter(valid_602799, JString, required = true,
                                 default = nil)
  if valid_602799 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602799
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602800: Call_PostPurchaseReservedDBInstancesOffering_602785;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602800.validator(path, query, header, formData, body)
  let scheme = call_602800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602800.url(scheme.get, call_602800.host, call_602800.base,
                         call_602800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602800, url, valid)

proc call*(call_602801: Call_PostPurchaseReservedDBInstancesOffering_602785;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = ""; DBInstanceCount: int = 0;
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-02-12"): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   DBInstanceCount: int
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_602802 = newJObject()
  var formData_602803 = newJObject()
  add(formData_602803, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_602803, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_602802, "Action", newJString(Action))
  add(formData_602803, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602802, "Version", newJString(Version))
  result = call_602801.call(nil, query_602802, nil, formData_602803, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_602785(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_602786, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_602787,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_602767 = ref object of OpenApiRestCall_600421
proc url_GetPurchaseReservedDBInstancesOffering_602769(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_602768(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_602770 = query.getOrDefault("DBInstanceCount")
  valid_602770 = validateParameter(valid_602770, JInt, required = false, default = nil)
  if valid_602770 != nil:
    section.add "DBInstanceCount", valid_602770
  var valid_602771 = query.getOrDefault("ReservedDBInstanceId")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "ReservedDBInstanceId", valid_602771
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_602772 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602772 = validateParameter(valid_602772, JString, required = true,
                                 default = nil)
  if valid_602772 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602772
  var valid_602773 = query.getOrDefault("Action")
  valid_602773 = validateParameter(valid_602773, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_602773 != nil:
    section.add "Action", valid_602773
  var valid_602774 = query.getOrDefault("Version")
  valid_602774 = validateParameter(valid_602774, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602774 != nil:
    section.add "Version", valid_602774
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
  var valid_602775 = header.getOrDefault("X-Amz-Date")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-Date", valid_602775
  var valid_602776 = header.getOrDefault("X-Amz-Security-Token")
  valid_602776 = validateParameter(valid_602776, JString, required = false,
                                 default = nil)
  if valid_602776 != nil:
    section.add "X-Amz-Security-Token", valid_602776
  var valid_602777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602777 = validateParameter(valid_602777, JString, required = false,
                                 default = nil)
  if valid_602777 != nil:
    section.add "X-Amz-Content-Sha256", valid_602777
  var valid_602778 = header.getOrDefault("X-Amz-Algorithm")
  valid_602778 = validateParameter(valid_602778, JString, required = false,
                                 default = nil)
  if valid_602778 != nil:
    section.add "X-Amz-Algorithm", valid_602778
  var valid_602779 = header.getOrDefault("X-Amz-Signature")
  valid_602779 = validateParameter(valid_602779, JString, required = false,
                                 default = nil)
  if valid_602779 != nil:
    section.add "X-Amz-Signature", valid_602779
  var valid_602780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602780 = validateParameter(valid_602780, JString, required = false,
                                 default = nil)
  if valid_602780 != nil:
    section.add "X-Amz-SignedHeaders", valid_602780
  var valid_602781 = header.getOrDefault("X-Amz-Credential")
  valid_602781 = validateParameter(valid_602781, JString, required = false,
                                 default = nil)
  if valid_602781 != nil:
    section.add "X-Amz-Credential", valid_602781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602782: Call_GetPurchaseReservedDBInstancesOffering_602767;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602782.validator(path, query, header, formData, body)
  let scheme = call_602782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602782.url(scheme.get, call_602782.host, call_602782.base,
                         call_602782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602782, url, valid)

proc call*(call_602783: Call_GetPurchaseReservedDBInstancesOffering_602767;
          ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-02-12"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602784 = newJObject()
  add(query_602784, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_602784, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_602784, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602784, "Action", newJString(Action))
  add(query_602784, "Version", newJString(Version))
  result = call_602783.call(nil, query_602784, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_602767(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_602768, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_602769,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_602821 = ref object of OpenApiRestCall_600421
proc url_PostRebootDBInstance_602823(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_602822(path: JsonNode; query: JsonNode;
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
  var valid_602824 = query.getOrDefault("Action")
  valid_602824 = validateParameter(valid_602824, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602824 != nil:
    section.add "Action", valid_602824
  var valid_602825 = query.getOrDefault("Version")
  valid_602825 = validateParameter(valid_602825, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602825 != nil:
    section.add "Version", valid_602825
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
  var valid_602826 = header.getOrDefault("X-Amz-Date")
  valid_602826 = validateParameter(valid_602826, JString, required = false,
                                 default = nil)
  if valid_602826 != nil:
    section.add "X-Amz-Date", valid_602826
  var valid_602827 = header.getOrDefault("X-Amz-Security-Token")
  valid_602827 = validateParameter(valid_602827, JString, required = false,
                                 default = nil)
  if valid_602827 != nil:
    section.add "X-Amz-Security-Token", valid_602827
  var valid_602828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602828 = validateParameter(valid_602828, JString, required = false,
                                 default = nil)
  if valid_602828 != nil:
    section.add "X-Amz-Content-Sha256", valid_602828
  var valid_602829 = header.getOrDefault("X-Amz-Algorithm")
  valid_602829 = validateParameter(valid_602829, JString, required = false,
                                 default = nil)
  if valid_602829 != nil:
    section.add "X-Amz-Algorithm", valid_602829
  var valid_602830 = header.getOrDefault("X-Amz-Signature")
  valid_602830 = validateParameter(valid_602830, JString, required = false,
                                 default = nil)
  if valid_602830 != nil:
    section.add "X-Amz-Signature", valid_602830
  var valid_602831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602831 = validateParameter(valid_602831, JString, required = false,
                                 default = nil)
  if valid_602831 != nil:
    section.add "X-Amz-SignedHeaders", valid_602831
  var valid_602832 = header.getOrDefault("X-Amz-Credential")
  valid_602832 = validateParameter(valid_602832, JString, required = false,
                                 default = nil)
  if valid_602832 != nil:
    section.add "X-Amz-Credential", valid_602832
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602833 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602833 = validateParameter(valid_602833, JString, required = true,
                                 default = nil)
  if valid_602833 != nil:
    section.add "DBInstanceIdentifier", valid_602833
  var valid_602834 = formData.getOrDefault("ForceFailover")
  valid_602834 = validateParameter(valid_602834, JBool, required = false, default = nil)
  if valid_602834 != nil:
    section.add "ForceFailover", valid_602834
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602835: Call_PostRebootDBInstance_602821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602835.validator(path, query, header, formData, body)
  let scheme = call_602835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602835.url(scheme.get, call_602835.host, call_602835.base,
                         call_602835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602835, url, valid)

proc call*(call_602836: Call_PostRebootDBInstance_602821;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_602837 = newJObject()
  var formData_602838 = newJObject()
  add(formData_602838, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602837, "Action", newJString(Action))
  add(formData_602838, "ForceFailover", newJBool(ForceFailover))
  add(query_602837, "Version", newJString(Version))
  result = call_602836.call(nil, query_602837, nil, formData_602838, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_602821(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_602822, base: "/",
    url: url_PostRebootDBInstance_602823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_602804 = ref object of OpenApiRestCall_600421
proc url_GetRebootDBInstance_602806(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_602805(path: JsonNode; query: JsonNode;
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
  var valid_602807 = query.getOrDefault("Action")
  valid_602807 = validateParameter(valid_602807, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602807 != nil:
    section.add "Action", valid_602807
  var valid_602808 = query.getOrDefault("ForceFailover")
  valid_602808 = validateParameter(valid_602808, JBool, required = false, default = nil)
  if valid_602808 != nil:
    section.add "ForceFailover", valid_602808
  var valid_602809 = query.getOrDefault("Version")
  valid_602809 = validateParameter(valid_602809, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602809 != nil:
    section.add "Version", valid_602809
  var valid_602810 = query.getOrDefault("DBInstanceIdentifier")
  valid_602810 = validateParameter(valid_602810, JString, required = true,
                                 default = nil)
  if valid_602810 != nil:
    section.add "DBInstanceIdentifier", valid_602810
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
  var valid_602811 = header.getOrDefault("X-Amz-Date")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "X-Amz-Date", valid_602811
  var valid_602812 = header.getOrDefault("X-Amz-Security-Token")
  valid_602812 = validateParameter(valid_602812, JString, required = false,
                                 default = nil)
  if valid_602812 != nil:
    section.add "X-Amz-Security-Token", valid_602812
  var valid_602813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602813 = validateParameter(valid_602813, JString, required = false,
                                 default = nil)
  if valid_602813 != nil:
    section.add "X-Amz-Content-Sha256", valid_602813
  var valid_602814 = header.getOrDefault("X-Amz-Algorithm")
  valid_602814 = validateParameter(valid_602814, JString, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "X-Amz-Algorithm", valid_602814
  var valid_602815 = header.getOrDefault("X-Amz-Signature")
  valid_602815 = validateParameter(valid_602815, JString, required = false,
                                 default = nil)
  if valid_602815 != nil:
    section.add "X-Amz-Signature", valid_602815
  var valid_602816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602816 = validateParameter(valid_602816, JString, required = false,
                                 default = nil)
  if valid_602816 != nil:
    section.add "X-Amz-SignedHeaders", valid_602816
  var valid_602817 = header.getOrDefault("X-Amz-Credential")
  valid_602817 = validateParameter(valid_602817, JString, required = false,
                                 default = nil)
  if valid_602817 != nil:
    section.add "X-Amz-Credential", valid_602817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602818: Call_GetRebootDBInstance_602804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602818.validator(path, query, header, formData, body)
  let scheme = call_602818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602818.url(scheme.get, call_602818.host, call_602818.base,
                         call_602818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602818, url, valid)

proc call*(call_602819: Call_GetRebootDBInstance_602804;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-02-12"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602820 = newJObject()
  add(query_602820, "Action", newJString(Action))
  add(query_602820, "ForceFailover", newJBool(ForceFailover))
  add(query_602820, "Version", newJString(Version))
  add(query_602820, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602819.call(nil, query_602820, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_602804(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_602805, base: "/",
    url: url_GetRebootDBInstance_602806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_602856 = ref object of OpenApiRestCall_600421
proc url_PostRemoveSourceIdentifierFromSubscription_602858(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_602857(path: JsonNode;
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
  var valid_602859 = query.getOrDefault("Action")
  valid_602859 = validateParameter(valid_602859, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_602859 != nil:
    section.add "Action", valid_602859
  var valid_602860 = query.getOrDefault("Version")
  valid_602860 = validateParameter(valid_602860, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602860 != nil:
    section.add "Version", valid_602860
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
  var valid_602861 = header.getOrDefault("X-Amz-Date")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "X-Amz-Date", valid_602861
  var valid_602862 = header.getOrDefault("X-Amz-Security-Token")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "X-Amz-Security-Token", valid_602862
  var valid_602863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-Content-Sha256", valid_602863
  var valid_602864 = header.getOrDefault("X-Amz-Algorithm")
  valid_602864 = validateParameter(valid_602864, JString, required = false,
                                 default = nil)
  if valid_602864 != nil:
    section.add "X-Amz-Algorithm", valid_602864
  var valid_602865 = header.getOrDefault("X-Amz-Signature")
  valid_602865 = validateParameter(valid_602865, JString, required = false,
                                 default = nil)
  if valid_602865 != nil:
    section.add "X-Amz-Signature", valid_602865
  var valid_602866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602866 = validateParameter(valid_602866, JString, required = false,
                                 default = nil)
  if valid_602866 != nil:
    section.add "X-Amz-SignedHeaders", valid_602866
  var valid_602867 = header.getOrDefault("X-Amz-Credential")
  valid_602867 = validateParameter(valid_602867, JString, required = false,
                                 default = nil)
  if valid_602867 != nil:
    section.add "X-Amz-Credential", valid_602867
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_602868 = formData.getOrDefault("SourceIdentifier")
  valid_602868 = validateParameter(valid_602868, JString, required = true,
                                 default = nil)
  if valid_602868 != nil:
    section.add "SourceIdentifier", valid_602868
  var valid_602869 = formData.getOrDefault("SubscriptionName")
  valid_602869 = validateParameter(valid_602869, JString, required = true,
                                 default = nil)
  if valid_602869 != nil:
    section.add "SubscriptionName", valid_602869
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602870: Call_PostRemoveSourceIdentifierFromSubscription_602856;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602870.validator(path, query, header, formData, body)
  let scheme = call_602870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602870.url(scheme.get, call_602870.host, call_602870.base,
                         call_602870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602870, url, valid)

proc call*(call_602871: Call_PostRemoveSourceIdentifierFromSubscription_602856;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602872 = newJObject()
  var formData_602873 = newJObject()
  add(formData_602873, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_602873, "SubscriptionName", newJString(SubscriptionName))
  add(query_602872, "Action", newJString(Action))
  add(query_602872, "Version", newJString(Version))
  result = call_602871.call(nil, query_602872, nil, formData_602873, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_602856(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_602857,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_602858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_602839 = ref object of OpenApiRestCall_600421
proc url_GetRemoveSourceIdentifierFromSubscription_602841(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_602840(path: JsonNode;
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
  var valid_602842 = query.getOrDefault("Action")
  valid_602842 = validateParameter(valid_602842, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_602842 != nil:
    section.add "Action", valid_602842
  var valid_602843 = query.getOrDefault("SourceIdentifier")
  valid_602843 = validateParameter(valid_602843, JString, required = true,
                                 default = nil)
  if valid_602843 != nil:
    section.add "SourceIdentifier", valid_602843
  var valid_602844 = query.getOrDefault("SubscriptionName")
  valid_602844 = validateParameter(valid_602844, JString, required = true,
                                 default = nil)
  if valid_602844 != nil:
    section.add "SubscriptionName", valid_602844
  var valid_602845 = query.getOrDefault("Version")
  valid_602845 = validateParameter(valid_602845, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602845 != nil:
    section.add "Version", valid_602845
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
  var valid_602846 = header.getOrDefault("X-Amz-Date")
  valid_602846 = validateParameter(valid_602846, JString, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "X-Amz-Date", valid_602846
  var valid_602847 = header.getOrDefault("X-Amz-Security-Token")
  valid_602847 = validateParameter(valid_602847, JString, required = false,
                                 default = nil)
  if valid_602847 != nil:
    section.add "X-Amz-Security-Token", valid_602847
  var valid_602848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602848 = validateParameter(valid_602848, JString, required = false,
                                 default = nil)
  if valid_602848 != nil:
    section.add "X-Amz-Content-Sha256", valid_602848
  var valid_602849 = header.getOrDefault("X-Amz-Algorithm")
  valid_602849 = validateParameter(valid_602849, JString, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "X-Amz-Algorithm", valid_602849
  var valid_602850 = header.getOrDefault("X-Amz-Signature")
  valid_602850 = validateParameter(valid_602850, JString, required = false,
                                 default = nil)
  if valid_602850 != nil:
    section.add "X-Amz-Signature", valid_602850
  var valid_602851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602851 = validateParameter(valid_602851, JString, required = false,
                                 default = nil)
  if valid_602851 != nil:
    section.add "X-Amz-SignedHeaders", valid_602851
  var valid_602852 = header.getOrDefault("X-Amz-Credential")
  valid_602852 = validateParameter(valid_602852, JString, required = false,
                                 default = nil)
  if valid_602852 != nil:
    section.add "X-Amz-Credential", valid_602852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602853: Call_GetRemoveSourceIdentifierFromSubscription_602839;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602853.validator(path, query, header, formData, body)
  let scheme = call_602853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602853.url(scheme.get, call_602853.host, call_602853.base,
                         call_602853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602853, url, valid)

proc call*(call_602854: Call_GetRemoveSourceIdentifierFromSubscription_602839;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_602855 = newJObject()
  add(query_602855, "Action", newJString(Action))
  add(query_602855, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_602855, "SubscriptionName", newJString(SubscriptionName))
  add(query_602855, "Version", newJString(Version))
  result = call_602854.call(nil, query_602855, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_602839(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_602840,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_602841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_602891 = ref object of OpenApiRestCall_600421
proc url_PostRemoveTagsFromResource_602893(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_602892(path: JsonNode; query: JsonNode;
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
  var valid_602894 = query.getOrDefault("Action")
  valid_602894 = validateParameter(valid_602894, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_602894 != nil:
    section.add "Action", valid_602894
  var valid_602895 = query.getOrDefault("Version")
  valid_602895 = validateParameter(valid_602895, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602895 != nil:
    section.add "Version", valid_602895
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
  var valid_602896 = header.getOrDefault("X-Amz-Date")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "X-Amz-Date", valid_602896
  var valid_602897 = header.getOrDefault("X-Amz-Security-Token")
  valid_602897 = validateParameter(valid_602897, JString, required = false,
                                 default = nil)
  if valid_602897 != nil:
    section.add "X-Amz-Security-Token", valid_602897
  var valid_602898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602898 = validateParameter(valid_602898, JString, required = false,
                                 default = nil)
  if valid_602898 != nil:
    section.add "X-Amz-Content-Sha256", valid_602898
  var valid_602899 = header.getOrDefault("X-Amz-Algorithm")
  valid_602899 = validateParameter(valid_602899, JString, required = false,
                                 default = nil)
  if valid_602899 != nil:
    section.add "X-Amz-Algorithm", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-Signature")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-Signature", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-SignedHeaders", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Credential")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Credential", valid_602902
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_602903 = formData.getOrDefault("TagKeys")
  valid_602903 = validateParameter(valid_602903, JArray, required = true, default = nil)
  if valid_602903 != nil:
    section.add "TagKeys", valid_602903
  var valid_602904 = formData.getOrDefault("ResourceName")
  valid_602904 = validateParameter(valid_602904, JString, required = true,
                                 default = nil)
  if valid_602904 != nil:
    section.add "ResourceName", valid_602904
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602905: Call_PostRemoveTagsFromResource_602891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602905.validator(path, query, header, formData, body)
  let scheme = call_602905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602905.url(scheme.get, call_602905.host, call_602905.base,
                         call_602905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602905, url, valid)

proc call*(call_602906: Call_PostRemoveTagsFromResource_602891; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_602907 = newJObject()
  var formData_602908 = newJObject()
  add(query_602907, "Action", newJString(Action))
  if TagKeys != nil:
    formData_602908.add "TagKeys", TagKeys
  add(formData_602908, "ResourceName", newJString(ResourceName))
  add(query_602907, "Version", newJString(Version))
  result = call_602906.call(nil, query_602907, nil, formData_602908, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_602891(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_602892, base: "/",
    url: url_PostRemoveTagsFromResource_602893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_602874 = ref object of OpenApiRestCall_600421
proc url_GetRemoveTagsFromResource_602876(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_602875(path: JsonNode; query: JsonNode;
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
  var valid_602877 = query.getOrDefault("ResourceName")
  valid_602877 = validateParameter(valid_602877, JString, required = true,
                                 default = nil)
  if valid_602877 != nil:
    section.add "ResourceName", valid_602877
  var valid_602878 = query.getOrDefault("Action")
  valid_602878 = validateParameter(valid_602878, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_602878 != nil:
    section.add "Action", valid_602878
  var valid_602879 = query.getOrDefault("TagKeys")
  valid_602879 = validateParameter(valid_602879, JArray, required = true, default = nil)
  if valid_602879 != nil:
    section.add "TagKeys", valid_602879
  var valid_602880 = query.getOrDefault("Version")
  valid_602880 = validateParameter(valid_602880, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602880 != nil:
    section.add "Version", valid_602880
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
  var valid_602881 = header.getOrDefault("X-Amz-Date")
  valid_602881 = validateParameter(valid_602881, JString, required = false,
                                 default = nil)
  if valid_602881 != nil:
    section.add "X-Amz-Date", valid_602881
  var valid_602882 = header.getOrDefault("X-Amz-Security-Token")
  valid_602882 = validateParameter(valid_602882, JString, required = false,
                                 default = nil)
  if valid_602882 != nil:
    section.add "X-Amz-Security-Token", valid_602882
  var valid_602883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602883 = validateParameter(valid_602883, JString, required = false,
                                 default = nil)
  if valid_602883 != nil:
    section.add "X-Amz-Content-Sha256", valid_602883
  var valid_602884 = header.getOrDefault("X-Amz-Algorithm")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Algorithm", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Signature")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Signature", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-SignedHeaders", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Credential")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Credential", valid_602887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602888: Call_GetRemoveTagsFromResource_602874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602888.validator(path, query, header, formData, body)
  let scheme = call_602888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602888.url(scheme.get, call_602888.host, call_602888.base,
                         call_602888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602888, url, valid)

proc call*(call_602889: Call_GetRemoveTagsFromResource_602874;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-02-12"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_602890 = newJObject()
  add(query_602890, "ResourceName", newJString(ResourceName))
  add(query_602890, "Action", newJString(Action))
  if TagKeys != nil:
    query_602890.add "TagKeys", TagKeys
  add(query_602890, "Version", newJString(Version))
  result = call_602889.call(nil, query_602890, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_602874(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_602875, base: "/",
    url: url_GetRemoveTagsFromResource_602876,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_602927 = ref object of OpenApiRestCall_600421
proc url_PostResetDBParameterGroup_602929(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_602928(path: JsonNode; query: JsonNode;
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
  var valid_602930 = query.getOrDefault("Action")
  valid_602930 = validateParameter(valid_602930, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_602930 != nil:
    section.add "Action", valid_602930
  var valid_602931 = query.getOrDefault("Version")
  valid_602931 = validateParameter(valid_602931, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602931 != nil:
    section.add "Version", valid_602931
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
  var valid_602932 = header.getOrDefault("X-Amz-Date")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "X-Amz-Date", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Security-Token")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Security-Token", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Content-Sha256", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Algorithm")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Algorithm", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Signature")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Signature", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-SignedHeaders", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Credential")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Credential", valid_602938
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602939 = formData.getOrDefault("DBParameterGroupName")
  valid_602939 = validateParameter(valid_602939, JString, required = true,
                                 default = nil)
  if valid_602939 != nil:
    section.add "DBParameterGroupName", valid_602939
  var valid_602940 = formData.getOrDefault("Parameters")
  valid_602940 = validateParameter(valid_602940, JArray, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "Parameters", valid_602940
  var valid_602941 = formData.getOrDefault("ResetAllParameters")
  valid_602941 = validateParameter(valid_602941, JBool, required = false, default = nil)
  if valid_602941 != nil:
    section.add "ResetAllParameters", valid_602941
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602942: Call_PostResetDBParameterGroup_602927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602942.validator(path, query, header, formData, body)
  let scheme = call_602942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602942.url(scheme.get, call_602942.host, call_602942.base,
                         call_602942.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602942, url, valid)

proc call*(call_602943: Call_PostResetDBParameterGroup_602927;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_602944 = newJObject()
  var formData_602945 = newJObject()
  add(formData_602945, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_602945.add "Parameters", Parameters
  add(query_602944, "Action", newJString(Action))
  add(formData_602945, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_602944, "Version", newJString(Version))
  result = call_602943.call(nil, query_602944, nil, formData_602945, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_602927(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_602928, base: "/",
    url: url_PostResetDBParameterGroup_602929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_602909 = ref object of OpenApiRestCall_600421
proc url_GetResetDBParameterGroup_602911(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_602910(path: JsonNode; query: JsonNode;
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
  var valid_602912 = query.getOrDefault("DBParameterGroupName")
  valid_602912 = validateParameter(valid_602912, JString, required = true,
                                 default = nil)
  if valid_602912 != nil:
    section.add "DBParameterGroupName", valid_602912
  var valid_602913 = query.getOrDefault("Parameters")
  valid_602913 = validateParameter(valid_602913, JArray, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "Parameters", valid_602913
  var valid_602914 = query.getOrDefault("Action")
  valid_602914 = validateParameter(valid_602914, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_602914 != nil:
    section.add "Action", valid_602914
  var valid_602915 = query.getOrDefault("ResetAllParameters")
  valid_602915 = validateParameter(valid_602915, JBool, required = false, default = nil)
  if valid_602915 != nil:
    section.add "ResetAllParameters", valid_602915
  var valid_602916 = query.getOrDefault("Version")
  valid_602916 = validateParameter(valid_602916, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602916 != nil:
    section.add "Version", valid_602916
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
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Content-Sha256", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-Algorithm")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Algorithm", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-Signature")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Signature", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-SignedHeaders", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-Credential")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Credential", valid_602923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602924: Call_GetResetDBParameterGroup_602909; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602924.validator(path, query, header, formData, body)
  let scheme = call_602924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602924.url(scheme.get, call_602924.host, call_602924.base,
                         call_602924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602924, url, valid)

proc call*(call_602925: Call_GetResetDBParameterGroup_602909;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-02-12"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_602926 = newJObject()
  add(query_602926, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_602926.add "Parameters", Parameters
  add(query_602926, "Action", newJString(Action))
  add(query_602926, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_602926, "Version", newJString(Version))
  result = call_602925.call(nil, query_602926, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_602909(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_602910, base: "/",
    url: url_GetResetDBParameterGroup_602911, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_602975 = ref object of OpenApiRestCall_600421
proc url_PostRestoreDBInstanceFromDBSnapshot_602977(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_602976(path: JsonNode;
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
  var valid_602978 = query.getOrDefault("Action")
  valid_602978 = validateParameter(valid_602978, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_602978 != nil:
    section.add "Action", valid_602978
  var valid_602979 = query.getOrDefault("Version")
  valid_602979 = validateParameter(valid_602979, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602979 != nil:
    section.add "Version", valid_602979
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
  var valid_602980 = header.getOrDefault("X-Amz-Date")
  valid_602980 = validateParameter(valid_602980, JString, required = false,
                                 default = nil)
  if valid_602980 != nil:
    section.add "X-Amz-Date", valid_602980
  var valid_602981 = header.getOrDefault("X-Amz-Security-Token")
  valid_602981 = validateParameter(valid_602981, JString, required = false,
                                 default = nil)
  if valid_602981 != nil:
    section.add "X-Amz-Security-Token", valid_602981
  var valid_602982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602982 = validateParameter(valid_602982, JString, required = false,
                                 default = nil)
  if valid_602982 != nil:
    section.add "X-Amz-Content-Sha256", valid_602982
  var valid_602983 = header.getOrDefault("X-Amz-Algorithm")
  valid_602983 = validateParameter(valid_602983, JString, required = false,
                                 default = nil)
  if valid_602983 != nil:
    section.add "X-Amz-Algorithm", valid_602983
  var valid_602984 = header.getOrDefault("X-Amz-Signature")
  valid_602984 = validateParameter(valid_602984, JString, required = false,
                                 default = nil)
  if valid_602984 != nil:
    section.add "X-Amz-Signature", valid_602984
  var valid_602985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602985 = validateParameter(valid_602985, JString, required = false,
                                 default = nil)
  if valid_602985 != nil:
    section.add "X-Amz-SignedHeaders", valid_602985
  var valid_602986 = header.getOrDefault("X-Amz-Credential")
  valid_602986 = validateParameter(valid_602986, JString, required = false,
                                 default = nil)
  if valid_602986 != nil:
    section.add "X-Amz-Credential", valid_602986
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   Engine: JString
  ##   Iops: JInt
  ##   DBName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   OptionGroupName: JString
  ##   DBSubnetGroupName: JString
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   DBSnapshotIdentifier: JString (required)
  ##   PubliclyAccessible: JBool
  ##   DBInstanceClass: JString
  ##   LicenseModel: JString
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_602987 = formData.getOrDefault("Port")
  valid_602987 = validateParameter(valid_602987, JInt, required = false, default = nil)
  if valid_602987 != nil:
    section.add "Port", valid_602987
  var valid_602988 = formData.getOrDefault("Engine")
  valid_602988 = validateParameter(valid_602988, JString, required = false,
                                 default = nil)
  if valid_602988 != nil:
    section.add "Engine", valid_602988
  var valid_602989 = formData.getOrDefault("Iops")
  valid_602989 = validateParameter(valid_602989, JInt, required = false, default = nil)
  if valid_602989 != nil:
    section.add "Iops", valid_602989
  var valid_602990 = formData.getOrDefault("DBName")
  valid_602990 = validateParameter(valid_602990, JString, required = false,
                                 default = nil)
  if valid_602990 != nil:
    section.add "DBName", valid_602990
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602991 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602991 = validateParameter(valid_602991, JString, required = true,
                                 default = nil)
  if valid_602991 != nil:
    section.add "DBInstanceIdentifier", valid_602991
  var valid_602992 = formData.getOrDefault("OptionGroupName")
  valid_602992 = validateParameter(valid_602992, JString, required = false,
                                 default = nil)
  if valid_602992 != nil:
    section.add "OptionGroupName", valid_602992
  var valid_602993 = formData.getOrDefault("DBSubnetGroupName")
  valid_602993 = validateParameter(valid_602993, JString, required = false,
                                 default = nil)
  if valid_602993 != nil:
    section.add "DBSubnetGroupName", valid_602993
  var valid_602994 = formData.getOrDefault("AvailabilityZone")
  valid_602994 = validateParameter(valid_602994, JString, required = false,
                                 default = nil)
  if valid_602994 != nil:
    section.add "AvailabilityZone", valid_602994
  var valid_602995 = formData.getOrDefault("MultiAZ")
  valid_602995 = validateParameter(valid_602995, JBool, required = false, default = nil)
  if valid_602995 != nil:
    section.add "MultiAZ", valid_602995
  var valid_602996 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602996 = validateParameter(valid_602996, JString, required = true,
                                 default = nil)
  if valid_602996 != nil:
    section.add "DBSnapshotIdentifier", valid_602996
  var valid_602997 = formData.getOrDefault("PubliclyAccessible")
  valid_602997 = validateParameter(valid_602997, JBool, required = false, default = nil)
  if valid_602997 != nil:
    section.add "PubliclyAccessible", valid_602997
  var valid_602998 = formData.getOrDefault("DBInstanceClass")
  valid_602998 = validateParameter(valid_602998, JString, required = false,
                                 default = nil)
  if valid_602998 != nil:
    section.add "DBInstanceClass", valid_602998
  var valid_602999 = formData.getOrDefault("LicenseModel")
  valid_602999 = validateParameter(valid_602999, JString, required = false,
                                 default = nil)
  if valid_602999 != nil:
    section.add "LicenseModel", valid_602999
  var valid_603000 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603000 = validateParameter(valid_603000, JBool, required = false, default = nil)
  if valid_603000 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603000
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603001: Call_PostRestoreDBInstanceFromDBSnapshot_602975;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603001.validator(path, query, header, formData, body)
  let scheme = call_603001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603001.url(scheme.get, call_603001.host, call_603001.base,
                         call_603001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603001, url, valid)

proc call*(call_603002: Call_PostRestoreDBInstanceFromDBSnapshot_602975;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          Engine: string = ""; Iops: int = 0; DBName: string = "";
          OptionGroupName: string = ""; DBSubnetGroupName: string = "";
          AvailabilityZone: string = ""; MultiAZ: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          PubliclyAccessible: bool = false; DBInstanceClass: string = "";
          LicenseModel: string = ""; AutoMinorVersionUpgrade: bool = false;
          Version: string = "2013-02-12"): Recallable =
  ## postRestoreDBInstanceFromDBSnapshot
  ##   Port: int
  ##   Engine: string
  ##   Iops: int
  ##   DBName: string
  ##   DBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
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
  var query_603003 = newJObject()
  var formData_603004 = newJObject()
  add(formData_603004, "Port", newJInt(Port))
  add(formData_603004, "Engine", newJString(Engine))
  add(formData_603004, "Iops", newJInt(Iops))
  add(formData_603004, "DBName", newJString(DBName))
  add(formData_603004, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603004, "OptionGroupName", newJString(OptionGroupName))
  add(formData_603004, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603004, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603004, "MultiAZ", newJBool(MultiAZ))
  add(formData_603004, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603003, "Action", newJString(Action))
  add(formData_603004, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603004, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603004, "LicenseModel", newJString(LicenseModel))
  add(formData_603004, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603003, "Version", newJString(Version))
  result = call_603002.call(nil, query_603003, nil, formData_603004, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_602975(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_602976, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_602977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_602946 = ref object of OpenApiRestCall_600421
proc url_GetRestoreDBInstanceFromDBSnapshot_602948(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_602947(path: JsonNode;
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
  var valid_602949 = query.getOrDefault("Engine")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "Engine", valid_602949
  var valid_602950 = query.getOrDefault("OptionGroupName")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "OptionGroupName", valid_602950
  var valid_602951 = query.getOrDefault("AvailabilityZone")
  valid_602951 = validateParameter(valid_602951, JString, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "AvailabilityZone", valid_602951
  var valid_602952 = query.getOrDefault("Iops")
  valid_602952 = validateParameter(valid_602952, JInt, required = false, default = nil)
  if valid_602952 != nil:
    section.add "Iops", valid_602952
  var valid_602953 = query.getOrDefault("MultiAZ")
  valid_602953 = validateParameter(valid_602953, JBool, required = false, default = nil)
  if valid_602953 != nil:
    section.add "MultiAZ", valid_602953
  var valid_602954 = query.getOrDefault("LicenseModel")
  valid_602954 = validateParameter(valid_602954, JString, required = false,
                                 default = nil)
  if valid_602954 != nil:
    section.add "LicenseModel", valid_602954
  var valid_602955 = query.getOrDefault("DBName")
  valid_602955 = validateParameter(valid_602955, JString, required = false,
                                 default = nil)
  if valid_602955 != nil:
    section.add "DBName", valid_602955
  var valid_602956 = query.getOrDefault("DBInstanceClass")
  valid_602956 = validateParameter(valid_602956, JString, required = false,
                                 default = nil)
  if valid_602956 != nil:
    section.add "DBInstanceClass", valid_602956
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602957 = query.getOrDefault("Action")
  valid_602957 = validateParameter(valid_602957, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_602957 != nil:
    section.add "Action", valid_602957
  var valid_602958 = query.getOrDefault("DBSubnetGroupName")
  valid_602958 = validateParameter(valid_602958, JString, required = false,
                                 default = nil)
  if valid_602958 != nil:
    section.add "DBSubnetGroupName", valid_602958
  var valid_602959 = query.getOrDefault("PubliclyAccessible")
  valid_602959 = validateParameter(valid_602959, JBool, required = false, default = nil)
  if valid_602959 != nil:
    section.add "PubliclyAccessible", valid_602959
  var valid_602960 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602960 = validateParameter(valid_602960, JBool, required = false, default = nil)
  if valid_602960 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602960
  var valid_602961 = query.getOrDefault("Port")
  valid_602961 = validateParameter(valid_602961, JInt, required = false, default = nil)
  if valid_602961 != nil:
    section.add "Port", valid_602961
  var valid_602962 = query.getOrDefault("Version")
  valid_602962 = validateParameter(valid_602962, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602962 != nil:
    section.add "Version", valid_602962
  var valid_602963 = query.getOrDefault("DBInstanceIdentifier")
  valid_602963 = validateParameter(valid_602963, JString, required = true,
                                 default = nil)
  if valid_602963 != nil:
    section.add "DBInstanceIdentifier", valid_602963
  var valid_602964 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602964 = validateParameter(valid_602964, JString, required = true,
                                 default = nil)
  if valid_602964 != nil:
    section.add "DBSnapshotIdentifier", valid_602964
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
  var valid_602965 = header.getOrDefault("X-Amz-Date")
  valid_602965 = validateParameter(valid_602965, JString, required = false,
                                 default = nil)
  if valid_602965 != nil:
    section.add "X-Amz-Date", valid_602965
  var valid_602966 = header.getOrDefault("X-Amz-Security-Token")
  valid_602966 = validateParameter(valid_602966, JString, required = false,
                                 default = nil)
  if valid_602966 != nil:
    section.add "X-Amz-Security-Token", valid_602966
  var valid_602967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602967 = validateParameter(valid_602967, JString, required = false,
                                 default = nil)
  if valid_602967 != nil:
    section.add "X-Amz-Content-Sha256", valid_602967
  var valid_602968 = header.getOrDefault("X-Amz-Algorithm")
  valid_602968 = validateParameter(valid_602968, JString, required = false,
                                 default = nil)
  if valid_602968 != nil:
    section.add "X-Amz-Algorithm", valid_602968
  var valid_602969 = header.getOrDefault("X-Amz-Signature")
  valid_602969 = validateParameter(valid_602969, JString, required = false,
                                 default = nil)
  if valid_602969 != nil:
    section.add "X-Amz-Signature", valid_602969
  var valid_602970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602970 = validateParameter(valid_602970, JString, required = false,
                                 default = nil)
  if valid_602970 != nil:
    section.add "X-Amz-SignedHeaders", valid_602970
  var valid_602971 = header.getOrDefault("X-Amz-Credential")
  valid_602971 = validateParameter(valid_602971, JString, required = false,
                                 default = nil)
  if valid_602971 != nil:
    section.add "X-Amz-Credential", valid_602971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602972: Call_GetRestoreDBInstanceFromDBSnapshot_602946;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602972.validator(path, query, header, formData, body)
  let scheme = call_602972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602972.url(scheme.get, call_602972.host, call_602972.base,
                         call_602972.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602972, url, valid)

proc call*(call_602973: Call_GetRestoreDBInstanceFromDBSnapshot_602946;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Engine: string = ""; OptionGroupName: string = "";
          AvailabilityZone: string = ""; Iops: int = 0; MultiAZ: bool = false;
          LicenseModel: string = ""; DBName: string = ""; DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Port: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   Engine: string
  ##   OptionGroupName: string
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   MultiAZ: bool
  ##   LicenseModel: string
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
  var query_602974 = newJObject()
  add(query_602974, "Engine", newJString(Engine))
  add(query_602974, "OptionGroupName", newJString(OptionGroupName))
  add(query_602974, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_602974, "Iops", newJInt(Iops))
  add(query_602974, "MultiAZ", newJBool(MultiAZ))
  add(query_602974, "LicenseModel", newJString(LicenseModel))
  add(query_602974, "DBName", newJString(DBName))
  add(query_602974, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602974, "Action", newJString(Action))
  add(query_602974, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602974, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602974, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602974, "Port", newJInt(Port))
  add(query_602974, "Version", newJString(Version))
  add(query_602974, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602974, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_602973.call(nil, query_602974, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_602946(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_602947, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_602948,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_603036 = ref object of OpenApiRestCall_600421
proc url_PostRestoreDBInstanceToPointInTime_603038(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_603037(path: JsonNode;
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
  var valid_603039 = query.getOrDefault("Action")
  valid_603039 = validateParameter(valid_603039, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603039 != nil:
    section.add "Action", valid_603039
  var valid_603040 = query.getOrDefault("Version")
  valid_603040 = validateParameter(valid_603040, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603040 != nil:
    section.add "Version", valid_603040
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
  var valid_603041 = header.getOrDefault("X-Amz-Date")
  valid_603041 = validateParameter(valid_603041, JString, required = false,
                                 default = nil)
  if valid_603041 != nil:
    section.add "X-Amz-Date", valid_603041
  var valid_603042 = header.getOrDefault("X-Amz-Security-Token")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Security-Token", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Content-Sha256", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-Algorithm")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-Algorithm", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Signature")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Signature", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-SignedHeaders", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Credential")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Credential", valid_603047
  result.add "header", section
  ## parameters in `formData` object:
  ##   UseLatestRestorableTime: JBool
  ##   Port: JInt
  ##   Engine: JString
  ##   Iops: JInt
  ##   DBName: JString
  ##   OptionGroupName: JString
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
  var valid_603048 = formData.getOrDefault("UseLatestRestorableTime")
  valid_603048 = validateParameter(valid_603048, JBool, required = false, default = nil)
  if valid_603048 != nil:
    section.add "UseLatestRestorableTime", valid_603048
  var valid_603049 = formData.getOrDefault("Port")
  valid_603049 = validateParameter(valid_603049, JInt, required = false, default = nil)
  if valid_603049 != nil:
    section.add "Port", valid_603049
  var valid_603050 = formData.getOrDefault("Engine")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "Engine", valid_603050
  var valid_603051 = formData.getOrDefault("Iops")
  valid_603051 = validateParameter(valid_603051, JInt, required = false, default = nil)
  if valid_603051 != nil:
    section.add "Iops", valid_603051
  var valid_603052 = formData.getOrDefault("DBName")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "DBName", valid_603052
  var valid_603053 = formData.getOrDefault("OptionGroupName")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "OptionGroupName", valid_603053
  var valid_603054 = formData.getOrDefault("DBSubnetGroupName")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "DBSubnetGroupName", valid_603054
  var valid_603055 = formData.getOrDefault("AvailabilityZone")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "AvailabilityZone", valid_603055
  var valid_603056 = formData.getOrDefault("MultiAZ")
  valid_603056 = validateParameter(valid_603056, JBool, required = false, default = nil)
  if valid_603056 != nil:
    section.add "MultiAZ", valid_603056
  var valid_603057 = formData.getOrDefault("RestoreTime")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "RestoreTime", valid_603057
  var valid_603058 = formData.getOrDefault("PubliclyAccessible")
  valid_603058 = validateParameter(valid_603058, JBool, required = false, default = nil)
  if valid_603058 != nil:
    section.add "PubliclyAccessible", valid_603058
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_603059 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_603059 = validateParameter(valid_603059, JString, required = true,
                                 default = nil)
  if valid_603059 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603059
  var valid_603060 = formData.getOrDefault("DBInstanceClass")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "DBInstanceClass", valid_603060
  var valid_603061 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_603061 = validateParameter(valid_603061, JString, required = true,
                                 default = nil)
  if valid_603061 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603061
  var valid_603062 = formData.getOrDefault("LicenseModel")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "LicenseModel", valid_603062
  var valid_603063 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603063 = validateParameter(valid_603063, JBool, required = false, default = nil)
  if valid_603063 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603063
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603064: Call_PostRestoreDBInstanceToPointInTime_603036;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603064.validator(path, query, header, formData, body)
  let scheme = call_603064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603064.url(scheme.get, call_603064.host, call_603064.base,
                         call_603064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603064, url, valid)

proc call*(call_603065: Call_PostRestoreDBInstanceToPointInTime_603036;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          UseLatestRestorableTime: bool = false; Port: int = 0; Engine: string = "";
          Iops: int = 0; DBName: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; AvailabilityZone: string = "";
          MultiAZ: bool = false; Action: string = "RestoreDBInstanceToPointInTime";
          RestoreTime: string = ""; PubliclyAccessible: bool = false;
          DBInstanceClass: string = ""; LicenseModel: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postRestoreDBInstanceToPointInTime
  ##   UseLatestRestorableTime: bool
  ##   Port: int
  ##   Engine: string
  ##   Iops: int
  ##   DBName: string
  ##   OptionGroupName: string
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
  var query_603066 = newJObject()
  var formData_603067 = newJObject()
  add(formData_603067, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_603067, "Port", newJInt(Port))
  add(formData_603067, "Engine", newJString(Engine))
  add(formData_603067, "Iops", newJInt(Iops))
  add(formData_603067, "DBName", newJString(DBName))
  add(formData_603067, "OptionGroupName", newJString(OptionGroupName))
  add(formData_603067, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603067, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603067, "MultiAZ", newJBool(MultiAZ))
  add(query_603066, "Action", newJString(Action))
  add(formData_603067, "RestoreTime", newJString(RestoreTime))
  add(formData_603067, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603067, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_603067, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603067, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_603067, "LicenseModel", newJString(LicenseModel))
  add(formData_603067, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603066, "Version", newJString(Version))
  result = call_603065.call(nil, query_603066, nil, formData_603067, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_603036(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_603037, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_603038,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_603005 = ref object of OpenApiRestCall_600421
proc url_GetRestoreDBInstanceToPointInTime_603007(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_603006(path: JsonNode;
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
  var valid_603008 = query.getOrDefault("Engine")
  valid_603008 = validateParameter(valid_603008, JString, required = false,
                                 default = nil)
  if valid_603008 != nil:
    section.add "Engine", valid_603008
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_603009 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_603009 = validateParameter(valid_603009, JString, required = true,
                                 default = nil)
  if valid_603009 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603009
  var valid_603010 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_603010 = validateParameter(valid_603010, JString, required = true,
                                 default = nil)
  if valid_603010 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603010
  var valid_603011 = query.getOrDefault("AvailabilityZone")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "AvailabilityZone", valid_603011
  var valid_603012 = query.getOrDefault("Iops")
  valid_603012 = validateParameter(valid_603012, JInt, required = false, default = nil)
  if valid_603012 != nil:
    section.add "Iops", valid_603012
  var valid_603013 = query.getOrDefault("OptionGroupName")
  valid_603013 = validateParameter(valid_603013, JString, required = false,
                                 default = nil)
  if valid_603013 != nil:
    section.add "OptionGroupName", valid_603013
  var valid_603014 = query.getOrDefault("RestoreTime")
  valid_603014 = validateParameter(valid_603014, JString, required = false,
                                 default = nil)
  if valid_603014 != nil:
    section.add "RestoreTime", valid_603014
  var valid_603015 = query.getOrDefault("MultiAZ")
  valid_603015 = validateParameter(valid_603015, JBool, required = false, default = nil)
  if valid_603015 != nil:
    section.add "MultiAZ", valid_603015
  var valid_603016 = query.getOrDefault("LicenseModel")
  valid_603016 = validateParameter(valid_603016, JString, required = false,
                                 default = nil)
  if valid_603016 != nil:
    section.add "LicenseModel", valid_603016
  var valid_603017 = query.getOrDefault("DBName")
  valid_603017 = validateParameter(valid_603017, JString, required = false,
                                 default = nil)
  if valid_603017 != nil:
    section.add "DBName", valid_603017
  var valid_603018 = query.getOrDefault("DBInstanceClass")
  valid_603018 = validateParameter(valid_603018, JString, required = false,
                                 default = nil)
  if valid_603018 != nil:
    section.add "DBInstanceClass", valid_603018
  var valid_603019 = query.getOrDefault("Action")
  valid_603019 = validateParameter(valid_603019, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603019 != nil:
    section.add "Action", valid_603019
  var valid_603020 = query.getOrDefault("UseLatestRestorableTime")
  valid_603020 = validateParameter(valid_603020, JBool, required = false, default = nil)
  if valid_603020 != nil:
    section.add "UseLatestRestorableTime", valid_603020
  var valid_603021 = query.getOrDefault("DBSubnetGroupName")
  valid_603021 = validateParameter(valid_603021, JString, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "DBSubnetGroupName", valid_603021
  var valid_603022 = query.getOrDefault("PubliclyAccessible")
  valid_603022 = validateParameter(valid_603022, JBool, required = false, default = nil)
  if valid_603022 != nil:
    section.add "PubliclyAccessible", valid_603022
  var valid_603023 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603023 = validateParameter(valid_603023, JBool, required = false, default = nil)
  if valid_603023 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603023
  var valid_603024 = query.getOrDefault("Port")
  valid_603024 = validateParameter(valid_603024, JInt, required = false, default = nil)
  if valid_603024 != nil:
    section.add "Port", valid_603024
  var valid_603025 = query.getOrDefault("Version")
  valid_603025 = validateParameter(valid_603025, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603025 != nil:
    section.add "Version", valid_603025
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
  var valid_603026 = header.getOrDefault("X-Amz-Date")
  valid_603026 = validateParameter(valid_603026, JString, required = false,
                                 default = nil)
  if valid_603026 != nil:
    section.add "X-Amz-Date", valid_603026
  var valid_603027 = header.getOrDefault("X-Amz-Security-Token")
  valid_603027 = validateParameter(valid_603027, JString, required = false,
                                 default = nil)
  if valid_603027 != nil:
    section.add "X-Amz-Security-Token", valid_603027
  var valid_603028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603028 = validateParameter(valid_603028, JString, required = false,
                                 default = nil)
  if valid_603028 != nil:
    section.add "X-Amz-Content-Sha256", valid_603028
  var valid_603029 = header.getOrDefault("X-Amz-Algorithm")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "X-Amz-Algorithm", valid_603029
  var valid_603030 = header.getOrDefault("X-Amz-Signature")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "X-Amz-Signature", valid_603030
  var valid_603031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-SignedHeaders", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Credential")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Credential", valid_603032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603033: Call_GetRestoreDBInstanceToPointInTime_603005;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603033.validator(path, query, header, formData, body)
  let scheme = call_603033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603033.url(scheme.get, call_603033.host, call_603033.base,
                         call_603033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603033, url, valid)

proc call*(call_603034: Call_GetRestoreDBInstanceToPointInTime_603005;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Engine: string = ""; AvailabilityZone: string = ""; Iops: int = 0;
          OptionGroupName: string = ""; RestoreTime: string = ""; MultiAZ: bool = false;
          LicenseModel: string = ""; DBName: string = ""; DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceToPointInTime";
          UseLatestRestorableTime: bool = false; DBSubnetGroupName: string = "";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Port: int = 0; Version: string = "2013-02-12"): Recallable =
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
  ##   DBName: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   UseLatestRestorableTime: bool
  ##   DBSubnetGroupName: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Version: string (required)
  var query_603035 = newJObject()
  add(query_603035, "Engine", newJString(Engine))
  add(query_603035, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_603035, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_603035, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603035, "Iops", newJInt(Iops))
  add(query_603035, "OptionGroupName", newJString(OptionGroupName))
  add(query_603035, "RestoreTime", newJString(RestoreTime))
  add(query_603035, "MultiAZ", newJBool(MultiAZ))
  add(query_603035, "LicenseModel", newJString(LicenseModel))
  add(query_603035, "DBName", newJString(DBName))
  add(query_603035, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603035, "Action", newJString(Action))
  add(query_603035, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_603035, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603035, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603035, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603035, "Port", newJInt(Port))
  add(query_603035, "Version", newJString(Version))
  result = call_603034.call(nil, query_603035, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_603005(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_603006, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_603007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_603088 = ref object of OpenApiRestCall_600421
proc url_PostRevokeDBSecurityGroupIngress_603090(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_603089(path: JsonNode;
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
  var valid_603091 = query.getOrDefault("Action")
  valid_603091 = validateParameter(valid_603091, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603091 != nil:
    section.add "Action", valid_603091
  var valid_603092 = query.getOrDefault("Version")
  valid_603092 = validateParameter(valid_603092, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603092 != nil:
    section.add "Version", valid_603092
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
  var valid_603093 = header.getOrDefault("X-Amz-Date")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Date", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Security-Token")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Security-Token", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Content-Sha256", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Algorithm")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Algorithm", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Signature")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Signature", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-SignedHeaders", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Credential")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Credential", valid_603099
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603100 = formData.getOrDefault("DBSecurityGroupName")
  valid_603100 = validateParameter(valid_603100, JString, required = true,
                                 default = nil)
  if valid_603100 != nil:
    section.add "DBSecurityGroupName", valid_603100
  var valid_603101 = formData.getOrDefault("EC2SecurityGroupName")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "EC2SecurityGroupName", valid_603101
  var valid_603102 = formData.getOrDefault("EC2SecurityGroupId")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "EC2SecurityGroupId", valid_603102
  var valid_603103 = formData.getOrDefault("CIDRIP")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "CIDRIP", valid_603103
  var valid_603104 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603104
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603105: Call_PostRevokeDBSecurityGroupIngress_603088;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603105.validator(path, query, header, formData, body)
  let scheme = call_603105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603105.url(scheme.get, call_603105.host, call_603105.base,
                         call_603105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603105, url, valid)

proc call*(call_603106: Call_PostRevokeDBSecurityGroupIngress_603088;
          DBSecurityGroupName: string;
          Action: string = "RevokeDBSecurityGroupIngress";
          EC2SecurityGroupName: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Version: string = "2013-02-12";
          EC2SecurityGroupOwnerId: string = ""): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Version: string (required)
  ##   EC2SecurityGroupOwnerId: string
  var query_603107 = newJObject()
  var formData_603108 = newJObject()
  add(formData_603108, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603107, "Action", newJString(Action))
  add(formData_603108, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_603108, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_603108, "CIDRIP", newJString(CIDRIP))
  add(query_603107, "Version", newJString(Version))
  add(formData_603108, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_603106.call(nil, query_603107, nil, formData_603108, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_603088(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_603089, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_603090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_603068 = ref object of OpenApiRestCall_600421
proc url_GetRevokeDBSecurityGroupIngress_603070(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_603069(path: JsonNode;
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
  var valid_603071 = query.getOrDefault("EC2SecurityGroupId")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "EC2SecurityGroupId", valid_603071
  var valid_603072 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603072
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603073 = query.getOrDefault("DBSecurityGroupName")
  valid_603073 = validateParameter(valid_603073, JString, required = true,
                                 default = nil)
  if valid_603073 != nil:
    section.add "DBSecurityGroupName", valid_603073
  var valid_603074 = query.getOrDefault("Action")
  valid_603074 = validateParameter(valid_603074, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603074 != nil:
    section.add "Action", valid_603074
  var valid_603075 = query.getOrDefault("CIDRIP")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "CIDRIP", valid_603075
  var valid_603076 = query.getOrDefault("EC2SecurityGroupName")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "EC2SecurityGroupName", valid_603076
  var valid_603077 = query.getOrDefault("Version")
  valid_603077 = validateParameter(valid_603077, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603077 != nil:
    section.add "Version", valid_603077
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
  var valid_603078 = header.getOrDefault("X-Amz-Date")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Date", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Security-Token")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Security-Token", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Content-Sha256", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Algorithm")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Algorithm", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Signature")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Signature", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-SignedHeaders", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Credential")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Credential", valid_603084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603085: Call_GetRevokeDBSecurityGroupIngress_603068;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603085.validator(path, query, header, formData, body)
  let scheme = call_603085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603085.url(scheme.get, call_603085.host, call_603085.base,
                         call_603085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603085, url, valid)

proc call*(call_603086: Call_GetRevokeDBSecurityGroupIngress_603068;
          DBSecurityGroupName: string; EC2SecurityGroupId: string = "";
          EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress"; CIDRIP: string = "";
          EC2SecurityGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   CIDRIP: string
  ##   EC2SecurityGroupName: string
  ##   Version: string (required)
  var query_603087 = newJObject()
  add(query_603087, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_603087, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_603087, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603087, "Action", newJString(Action))
  add(query_603087, "CIDRIP", newJString(CIDRIP))
  add(query_603087, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_603087, "Version", newJString(Version))
  result = call_603086.call(nil, query_603087, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_603068(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_603069, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_603070,
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
