
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

  OpenApiRestCall_605573 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605573](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605573): Option[Scheme] {.used.} =
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
  Call_PostAddSourceIdentifierToSubscription_606183 = ref object of OpenApiRestCall_605573
proc url_PostAddSourceIdentifierToSubscription_606185(protocol: Scheme;
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

proc validate_PostAddSourceIdentifierToSubscription_606184(path: JsonNode;
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
  var valid_606186 = query.getOrDefault("Action")
  valid_606186 = validateParameter(valid_606186, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_606186 != nil:
    section.add "Action", valid_606186
  var valid_606187 = query.getOrDefault("Version")
  valid_606187 = validateParameter(valid_606187, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606187 != nil:
    section.add "Version", valid_606187
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606188 = header.getOrDefault("X-Amz-Signature")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Signature", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Content-Sha256", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Date")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Date", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-Credential")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Credential", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Security-Token")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Security-Token", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Algorithm")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Algorithm", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-SignedHeaders", valid_606194
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_606195 = formData.getOrDefault("SubscriptionName")
  valid_606195 = validateParameter(valid_606195, JString, required = true,
                                 default = nil)
  if valid_606195 != nil:
    section.add "SubscriptionName", valid_606195
  var valid_606196 = formData.getOrDefault("SourceIdentifier")
  valid_606196 = validateParameter(valid_606196, JString, required = true,
                                 default = nil)
  if valid_606196 != nil:
    section.add "SourceIdentifier", valid_606196
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606197: Call_PostAddSourceIdentifierToSubscription_606183;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_606197.validator(path, query, header, formData, body)
  let scheme = call_606197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606197.url(scheme.get, call_606197.host, call_606197.base,
                         call_606197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606197, url, valid)

proc call*(call_606198: Call_PostAddSourceIdentifierToSubscription_606183;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606199 = newJObject()
  var formData_606200 = newJObject()
  add(formData_606200, "SubscriptionName", newJString(SubscriptionName))
  add(formData_606200, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_606199, "Action", newJString(Action))
  add(query_606199, "Version", newJString(Version))
  result = call_606198.call(nil, query_606199, nil, formData_606200, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_606183(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_606184, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_606185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_605911 = ref object of OpenApiRestCall_605573
proc url_GetAddSourceIdentifierToSubscription_605913(protocol: Scheme;
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

proc validate_GetAddSourceIdentifierToSubscription_605912(path: JsonNode;
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
  var valid_606025 = query.getOrDefault("SourceIdentifier")
  valid_606025 = validateParameter(valid_606025, JString, required = true,
                                 default = nil)
  if valid_606025 != nil:
    section.add "SourceIdentifier", valid_606025
  var valid_606026 = query.getOrDefault("SubscriptionName")
  valid_606026 = validateParameter(valid_606026, JString, required = true,
                                 default = nil)
  if valid_606026 != nil:
    section.add "SubscriptionName", valid_606026
  var valid_606040 = query.getOrDefault("Action")
  valid_606040 = validateParameter(valid_606040, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_606040 != nil:
    section.add "Action", valid_606040
  var valid_606041 = query.getOrDefault("Version")
  valid_606041 = validateParameter(valid_606041, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606041 != nil:
    section.add "Version", valid_606041
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606042 = header.getOrDefault("X-Amz-Signature")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "X-Amz-Signature", valid_606042
  var valid_606043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Content-Sha256", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Date")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Date", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Credential")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Credential", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Security-Token")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Security-Token", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Algorithm")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Algorithm", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-SignedHeaders", valid_606048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606071: Call_GetAddSourceIdentifierToSubscription_605911;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_606071.validator(path, query, header, formData, body)
  let scheme = call_606071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606071.url(scheme.get, call_606071.host, call_606071.base,
                         call_606071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606071, url, valid)

proc call*(call_606142: Call_GetAddSourceIdentifierToSubscription_605911;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606143 = newJObject()
  add(query_606143, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_606143, "SubscriptionName", newJString(SubscriptionName))
  add(query_606143, "Action", newJString(Action))
  add(query_606143, "Version", newJString(Version))
  result = call_606142.call(nil, query_606143, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_605911(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_605912, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_605913,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_606218 = ref object of OpenApiRestCall_605573
proc url_PostAddTagsToResource_606220(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddTagsToResource_606219(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606221 = query.getOrDefault("Action")
  valid_606221 = validateParameter(valid_606221, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_606221 != nil:
    section.add "Action", valid_606221
  var valid_606222 = query.getOrDefault("Version")
  valid_606222 = validateParameter(valid_606222, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606222 != nil:
    section.add "Version", valid_606222
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606223 = header.getOrDefault("X-Amz-Signature")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Signature", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Content-Sha256", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Date")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Date", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Credential")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Credential", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Security-Token")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Security-Token", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Algorithm")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Algorithm", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-SignedHeaders", valid_606229
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_606230 = formData.getOrDefault("Tags")
  valid_606230 = validateParameter(valid_606230, JArray, required = true, default = nil)
  if valid_606230 != nil:
    section.add "Tags", valid_606230
  var valid_606231 = formData.getOrDefault("ResourceName")
  valid_606231 = validateParameter(valid_606231, JString, required = true,
                                 default = nil)
  if valid_606231 != nil:
    section.add "ResourceName", valid_606231
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606232: Call_PostAddTagsToResource_606218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606232.validator(path, query, header, formData, body)
  let scheme = call_606232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606232.url(scheme.get, call_606232.host, call_606232.base,
                         call_606232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606232, url, valid)

proc call*(call_606233: Call_PostAddTagsToResource_606218; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-02-12"): Recallable =
  ## postAddTagsToResource
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_606234 = newJObject()
  var formData_606235 = newJObject()
  add(query_606234, "Action", newJString(Action))
  if Tags != nil:
    formData_606235.add "Tags", Tags
  add(query_606234, "Version", newJString(Version))
  add(formData_606235, "ResourceName", newJString(ResourceName))
  result = call_606233.call(nil, query_606234, nil, formData_606235, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_606218(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_606219, base: "/",
    url: url_PostAddTagsToResource_606220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_606201 = ref object of OpenApiRestCall_605573
proc url_GetAddTagsToResource_606203(protocol: Scheme; host: string; base: string;
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

proc validate_GetAddTagsToResource_606202(path: JsonNode; query: JsonNode;
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
  var valid_606204 = query.getOrDefault("Tags")
  valid_606204 = validateParameter(valid_606204, JArray, required = true, default = nil)
  if valid_606204 != nil:
    section.add "Tags", valid_606204
  var valid_606205 = query.getOrDefault("ResourceName")
  valid_606205 = validateParameter(valid_606205, JString, required = true,
                                 default = nil)
  if valid_606205 != nil:
    section.add "ResourceName", valid_606205
  var valid_606206 = query.getOrDefault("Action")
  valid_606206 = validateParameter(valid_606206, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_606206 != nil:
    section.add "Action", valid_606206
  var valid_606207 = query.getOrDefault("Version")
  valid_606207 = validateParameter(valid_606207, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606207 != nil:
    section.add "Version", valid_606207
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606208 = header.getOrDefault("X-Amz-Signature")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Signature", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Content-Sha256", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Date")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Date", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Credential")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Credential", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-Security-Token")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-Security-Token", valid_606212
  var valid_606213 = header.getOrDefault("X-Amz-Algorithm")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Algorithm", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-SignedHeaders", valid_606214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606215: Call_GetAddTagsToResource_606201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606215.validator(path, query, header, formData, body)
  let scheme = call_606215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606215.url(scheme.get, call_606215.host, call_606215.base,
                         call_606215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606215, url, valid)

proc call*(call_606216: Call_GetAddTagsToResource_606201; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-02-12"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606217 = newJObject()
  if Tags != nil:
    query_606217.add "Tags", Tags
  add(query_606217, "ResourceName", newJString(ResourceName))
  add(query_606217, "Action", newJString(Action))
  add(query_606217, "Version", newJString(Version))
  result = call_606216.call(nil, query_606217, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_606201(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_606202, base: "/",
    url: url_GetAddTagsToResource_606203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_606256 = ref object of OpenApiRestCall_605573
proc url_PostAuthorizeDBSecurityGroupIngress_606258(protocol: Scheme; host: string;
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

proc validate_PostAuthorizeDBSecurityGroupIngress_606257(path: JsonNode;
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
  var valid_606259 = query.getOrDefault("Action")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_606259 != nil:
    section.add "Action", valid_606259
  var valid_606260 = query.getOrDefault("Version")
  valid_606260 = validateParameter(valid_606260, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606260 != nil:
    section.add "Version", valid_606260
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606261 = header.getOrDefault("X-Amz-Signature")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Signature", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Content-Sha256", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Date")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Date", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Credential")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Credential", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Security-Token")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Security-Token", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Algorithm")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Algorithm", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-SignedHeaders", valid_606267
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_606268 = formData.getOrDefault("DBSecurityGroupName")
  valid_606268 = validateParameter(valid_606268, JString, required = true,
                                 default = nil)
  if valid_606268 != nil:
    section.add "DBSecurityGroupName", valid_606268
  var valid_606269 = formData.getOrDefault("EC2SecurityGroupName")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "EC2SecurityGroupName", valid_606269
  var valid_606270 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_606270
  var valid_606271 = formData.getOrDefault("EC2SecurityGroupId")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "EC2SecurityGroupId", valid_606271
  var valid_606272 = formData.getOrDefault("CIDRIP")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "CIDRIP", valid_606272
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606273: Call_PostAuthorizeDBSecurityGroupIngress_606256;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_606273.validator(path, query, header, formData, body)
  let scheme = call_606273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606273.url(scheme.get, call_606273.host, call_606273.base,
                         call_606273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606273, url, valid)

proc call*(call_606274: Call_PostAuthorizeDBSecurityGroupIngress_606256;
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
  var query_606275 = newJObject()
  var formData_606276 = newJObject()
  add(formData_606276, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_606276, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_606276, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_606276, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_606276, "CIDRIP", newJString(CIDRIP))
  add(query_606275, "Action", newJString(Action))
  add(query_606275, "Version", newJString(Version))
  result = call_606274.call(nil, query_606275, nil, formData_606276, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_606256(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_606257, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_606258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_606236 = ref object of OpenApiRestCall_605573
proc url_GetAuthorizeDBSecurityGroupIngress_606238(protocol: Scheme; host: string;
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

proc validate_GetAuthorizeDBSecurityGroupIngress_606237(path: JsonNode;
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
  var valid_606239 = query.getOrDefault("EC2SecurityGroupName")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "EC2SecurityGroupName", valid_606239
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_606240 = query.getOrDefault("DBSecurityGroupName")
  valid_606240 = validateParameter(valid_606240, JString, required = true,
                                 default = nil)
  if valid_606240 != nil:
    section.add "DBSecurityGroupName", valid_606240
  var valid_606241 = query.getOrDefault("EC2SecurityGroupId")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "EC2SecurityGroupId", valid_606241
  var valid_606242 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_606242
  var valid_606243 = query.getOrDefault("Action")
  valid_606243 = validateParameter(valid_606243, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_606243 != nil:
    section.add "Action", valid_606243
  var valid_606244 = query.getOrDefault("Version")
  valid_606244 = validateParameter(valid_606244, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606244 != nil:
    section.add "Version", valid_606244
  var valid_606245 = query.getOrDefault("CIDRIP")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "CIDRIP", valid_606245
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606246 = header.getOrDefault("X-Amz-Signature")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Signature", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Content-Sha256", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Date")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Date", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Credential")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Credential", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Security-Token")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Security-Token", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Algorithm")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Algorithm", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-SignedHeaders", valid_606252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_GetAuthorizeDBSecurityGroupIngress_606236;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_GetAuthorizeDBSecurityGroupIngress_606236;
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
  var query_606255 = newJObject()
  add(query_606255, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_606255, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_606255, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_606255, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_606255, "Action", newJString(Action))
  add(query_606255, "Version", newJString(Version))
  add(query_606255, "CIDRIP", newJString(CIDRIP))
  result = call_606254.call(nil, query_606255, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_606236(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_606237, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_606238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_606294 = ref object of OpenApiRestCall_605573
proc url_PostCopyDBSnapshot_606296(protocol: Scheme; host: string; base: string;
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

proc validate_PostCopyDBSnapshot_606295(path: JsonNode; query: JsonNode;
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
  var valid_606297 = query.getOrDefault("Action")
  valid_606297 = validateParameter(valid_606297, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_606297 != nil:
    section.add "Action", valid_606297
  var valid_606298 = query.getOrDefault("Version")
  valid_606298 = validateParameter(valid_606298, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606298 != nil:
    section.add "Version", valid_606298
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606299 = header.getOrDefault("X-Amz-Signature")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Signature", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Content-Sha256", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Date")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Date", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Credential")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Credential", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Security-Token")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Security-Token", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Algorithm")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Algorithm", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-SignedHeaders", valid_606305
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_606306 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_606306 = validateParameter(valid_606306, JString, required = true,
                                 default = nil)
  if valid_606306 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_606306
  var valid_606307 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_606307 = validateParameter(valid_606307, JString, required = true,
                                 default = nil)
  if valid_606307 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_606307
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606308: Call_PostCopyDBSnapshot_606294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606308.validator(path, query, header, formData, body)
  let scheme = call_606308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606308.url(scheme.get, call_606308.host, call_606308.base,
                         call_606308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606308, url, valid)

proc call*(call_606309: Call_PostCopyDBSnapshot_606294;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_606310 = newJObject()
  var formData_606311 = newJObject()
  add(formData_606311, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_606310, "Action", newJString(Action))
  add(formData_606311, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_606310, "Version", newJString(Version))
  result = call_606309.call(nil, query_606310, nil, formData_606311, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_606294(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_606295, base: "/",
    url: url_PostCopyDBSnapshot_606296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_606277 = ref object of OpenApiRestCall_605573
proc url_GetCopyDBSnapshot_606279(protocol: Scheme; host: string; base: string;
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

proc validate_GetCopyDBSnapshot_606278(path: JsonNode; query: JsonNode;
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
  var valid_606280 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_606280 = validateParameter(valid_606280, JString, required = true,
                                 default = nil)
  if valid_606280 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_606280
  var valid_606281 = query.getOrDefault("Action")
  valid_606281 = validateParameter(valid_606281, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_606281 != nil:
    section.add "Action", valid_606281
  var valid_606282 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_606282 = validateParameter(valid_606282, JString, required = true,
                                 default = nil)
  if valid_606282 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_606282
  var valid_606283 = query.getOrDefault("Version")
  valid_606283 = validateParameter(valid_606283, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606283 != nil:
    section.add "Version", valid_606283
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606284 = header.getOrDefault("X-Amz-Signature")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Signature", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Content-Sha256", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Date")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Date", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Credential")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Credential", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Security-Token")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Security-Token", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Algorithm")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Algorithm", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-SignedHeaders", valid_606290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606291: Call_GetCopyDBSnapshot_606277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606291.validator(path, query, header, formData, body)
  let scheme = call_606291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606291.url(scheme.get, call_606291.host, call_606291.base,
                         call_606291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606291, url, valid)

proc call*(call_606292: Call_GetCopyDBSnapshot_606277;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_606293 = newJObject()
  add(query_606293, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_606293, "Action", newJString(Action))
  add(query_606293, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_606293, "Version", newJString(Version))
  result = call_606292.call(nil, query_606293, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_606277(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_606278,
    base: "/", url: url_GetCopyDBSnapshot_606279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_606351 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBInstance_606353(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBInstance_606352(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606354 = query.getOrDefault("Action")
  valid_606354 = validateParameter(valid_606354, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_606354 != nil:
    section.add "Action", valid_606354
  var valid_606355 = query.getOrDefault("Version")
  valid_606355 = validateParameter(valid_606355, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606355 != nil:
    section.add "Version", valid_606355
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606356 = header.getOrDefault("X-Amz-Signature")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Signature", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Content-Sha256", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-Date")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Date", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Credential")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Credential", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Security-Token")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Security-Token", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Algorithm")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Algorithm", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-SignedHeaders", valid_606362
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
  var valid_606363 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "PreferredMaintenanceWindow", valid_606363
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_606364 = formData.getOrDefault("DBInstanceClass")
  valid_606364 = validateParameter(valid_606364, JString, required = true,
                                 default = nil)
  if valid_606364 != nil:
    section.add "DBInstanceClass", valid_606364
  var valid_606365 = formData.getOrDefault("Port")
  valid_606365 = validateParameter(valid_606365, JInt, required = false, default = nil)
  if valid_606365 != nil:
    section.add "Port", valid_606365
  var valid_606366 = formData.getOrDefault("PreferredBackupWindow")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "PreferredBackupWindow", valid_606366
  var valid_606367 = formData.getOrDefault("MasterUserPassword")
  valid_606367 = validateParameter(valid_606367, JString, required = true,
                                 default = nil)
  if valid_606367 != nil:
    section.add "MasterUserPassword", valid_606367
  var valid_606368 = formData.getOrDefault("MultiAZ")
  valid_606368 = validateParameter(valid_606368, JBool, required = false, default = nil)
  if valid_606368 != nil:
    section.add "MultiAZ", valid_606368
  var valid_606369 = formData.getOrDefault("MasterUsername")
  valid_606369 = validateParameter(valid_606369, JString, required = true,
                                 default = nil)
  if valid_606369 != nil:
    section.add "MasterUsername", valid_606369
  var valid_606370 = formData.getOrDefault("DBParameterGroupName")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "DBParameterGroupName", valid_606370
  var valid_606371 = formData.getOrDefault("EngineVersion")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "EngineVersion", valid_606371
  var valid_606372 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_606372 = validateParameter(valid_606372, JArray, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "VpcSecurityGroupIds", valid_606372
  var valid_606373 = formData.getOrDefault("AvailabilityZone")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "AvailabilityZone", valid_606373
  var valid_606374 = formData.getOrDefault("BackupRetentionPeriod")
  valid_606374 = validateParameter(valid_606374, JInt, required = false, default = nil)
  if valid_606374 != nil:
    section.add "BackupRetentionPeriod", valid_606374
  var valid_606375 = formData.getOrDefault("Engine")
  valid_606375 = validateParameter(valid_606375, JString, required = true,
                                 default = nil)
  if valid_606375 != nil:
    section.add "Engine", valid_606375
  var valid_606376 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_606376 = validateParameter(valid_606376, JBool, required = false, default = nil)
  if valid_606376 != nil:
    section.add "AutoMinorVersionUpgrade", valid_606376
  var valid_606377 = formData.getOrDefault("DBName")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "DBName", valid_606377
  var valid_606378 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606378 = validateParameter(valid_606378, JString, required = true,
                                 default = nil)
  if valid_606378 != nil:
    section.add "DBInstanceIdentifier", valid_606378
  var valid_606379 = formData.getOrDefault("Iops")
  valid_606379 = validateParameter(valid_606379, JInt, required = false, default = nil)
  if valid_606379 != nil:
    section.add "Iops", valid_606379
  var valid_606380 = formData.getOrDefault("PubliclyAccessible")
  valid_606380 = validateParameter(valid_606380, JBool, required = false, default = nil)
  if valid_606380 != nil:
    section.add "PubliclyAccessible", valid_606380
  var valid_606381 = formData.getOrDefault("LicenseModel")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "LicenseModel", valid_606381
  var valid_606382 = formData.getOrDefault("DBSubnetGroupName")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "DBSubnetGroupName", valid_606382
  var valid_606383 = formData.getOrDefault("OptionGroupName")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "OptionGroupName", valid_606383
  var valid_606384 = formData.getOrDefault("CharacterSetName")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "CharacterSetName", valid_606384
  var valid_606385 = formData.getOrDefault("DBSecurityGroups")
  valid_606385 = validateParameter(valid_606385, JArray, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "DBSecurityGroups", valid_606385
  var valid_606386 = formData.getOrDefault("AllocatedStorage")
  valid_606386 = validateParameter(valid_606386, JInt, required = true, default = nil)
  if valid_606386 != nil:
    section.add "AllocatedStorage", valid_606386
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606387: Call_PostCreateDBInstance_606351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606387.validator(path, query, header, formData, body)
  let scheme = call_606387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606387.url(scheme.get, call_606387.host, call_606387.base,
                         call_606387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606387, url, valid)

proc call*(call_606388: Call_PostCreateDBInstance_606351; DBInstanceClass: string;
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
  var query_606389 = newJObject()
  var formData_606390 = newJObject()
  add(formData_606390, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_606390, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_606390, "Port", newJInt(Port))
  add(formData_606390, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_606390, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_606390, "MultiAZ", newJBool(MultiAZ))
  add(formData_606390, "MasterUsername", newJString(MasterUsername))
  add(formData_606390, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_606390, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_606390.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_606390, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_606390, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_606390, "Engine", newJString(Engine))
  add(formData_606390, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_606390, "DBName", newJString(DBName))
  add(formData_606390, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_606390, "Iops", newJInt(Iops))
  add(formData_606390, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_606389, "Action", newJString(Action))
  add(formData_606390, "LicenseModel", newJString(LicenseModel))
  add(formData_606390, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_606390, "OptionGroupName", newJString(OptionGroupName))
  add(formData_606390, "CharacterSetName", newJString(CharacterSetName))
  add(query_606389, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_606390.add "DBSecurityGroups", DBSecurityGroups
  add(formData_606390, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_606388.call(nil, query_606389, nil, formData_606390, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_606351(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_606352, base: "/",
    url: url_PostCreateDBInstance_606353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_606312 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBInstance_606314(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBInstance_606313(path: JsonNode; query: JsonNode;
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
  var valid_606315 = query.getOrDefault("Version")
  valid_606315 = validateParameter(valid_606315, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606315 != nil:
    section.add "Version", valid_606315
  var valid_606316 = query.getOrDefault("DBName")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "DBName", valid_606316
  var valid_606317 = query.getOrDefault("Engine")
  valid_606317 = validateParameter(valid_606317, JString, required = true,
                                 default = nil)
  if valid_606317 != nil:
    section.add "Engine", valid_606317
  var valid_606318 = query.getOrDefault("DBParameterGroupName")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "DBParameterGroupName", valid_606318
  var valid_606319 = query.getOrDefault("CharacterSetName")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "CharacterSetName", valid_606319
  var valid_606320 = query.getOrDefault("LicenseModel")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "LicenseModel", valid_606320
  var valid_606321 = query.getOrDefault("DBInstanceIdentifier")
  valid_606321 = validateParameter(valid_606321, JString, required = true,
                                 default = nil)
  if valid_606321 != nil:
    section.add "DBInstanceIdentifier", valid_606321
  var valid_606322 = query.getOrDefault("MasterUsername")
  valid_606322 = validateParameter(valid_606322, JString, required = true,
                                 default = nil)
  if valid_606322 != nil:
    section.add "MasterUsername", valid_606322
  var valid_606323 = query.getOrDefault("BackupRetentionPeriod")
  valid_606323 = validateParameter(valid_606323, JInt, required = false, default = nil)
  if valid_606323 != nil:
    section.add "BackupRetentionPeriod", valid_606323
  var valid_606324 = query.getOrDefault("EngineVersion")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "EngineVersion", valid_606324
  var valid_606325 = query.getOrDefault("Action")
  valid_606325 = validateParameter(valid_606325, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_606325 != nil:
    section.add "Action", valid_606325
  var valid_606326 = query.getOrDefault("MultiAZ")
  valid_606326 = validateParameter(valid_606326, JBool, required = false, default = nil)
  if valid_606326 != nil:
    section.add "MultiAZ", valid_606326
  var valid_606327 = query.getOrDefault("DBSecurityGroups")
  valid_606327 = validateParameter(valid_606327, JArray, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "DBSecurityGroups", valid_606327
  var valid_606328 = query.getOrDefault("Port")
  valid_606328 = validateParameter(valid_606328, JInt, required = false, default = nil)
  if valid_606328 != nil:
    section.add "Port", valid_606328
  var valid_606329 = query.getOrDefault("VpcSecurityGroupIds")
  valid_606329 = validateParameter(valid_606329, JArray, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "VpcSecurityGroupIds", valid_606329
  var valid_606330 = query.getOrDefault("MasterUserPassword")
  valid_606330 = validateParameter(valid_606330, JString, required = true,
                                 default = nil)
  if valid_606330 != nil:
    section.add "MasterUserPassword", valid_606330
  var valid_606331 = query.getOrDefault("AvailabilityZone")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "AvailabilityZone", valid_606331
  var valid_606332 = query.getOrDefault("OptionGroupName")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "OptionGroupName", valid_606332
  var valid_606333 = query.getOrDefault("DBSubnetGroupName")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "DBSubnetGroupName", valid_606333
  var valid_606334 = query.getOrDefault("AllocatedStorage")
  valid_606334 = validateParameter(valid_606334, JInt, required = true, default = nil)
  if valid_606334 != nil:
    section.add "AllocatedStorage", valid_606334
  var valid_606335 = query.getOrDefault("DBInstanceClass")
  valid_606335 = validateParameter(valid_606335, JString, required = true,
                                 default = nil)
  if valid_606335 != nil:
    section.add "DBInstanceClass", valid_606335
  var valid_606336 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "PreferredMaintenanceWindow", valid_606336
  var valid_606337 = query.getOrDefault("PreferredBackupWindow")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "PreferredBackupWindow", valid_606337
  var valid_606338 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_606338 = validateParameter(valid_606338, JBool, required = false, default = nil)
  if valid_606338 != nil:
    section.add "AutoMinorVersionUpgrade", valid_606338
  var valid_606339 = query.getOrDefault("Iops")
  valid_606339 = validateParameter(valid_606339, JInt, required = false, default = nil)
  if valid_606339 != nil:
    section.add "Iops", valid_606339
  var valid_606340 = query.getOrDefault("PubliclyAccessible")
  valid_606340 = validateParameter(valid_606340, JBool, required = false, default = nil)
  if valid_606340 != nil:
    section.add "PubliclyAccessible", valid_606340
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606341 = header.getOrDefault("X-Amz-Signature")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Signature", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Content-Sha256", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Date")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Date", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Credential")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Credential", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Security-Token")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Security-Token", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Algorithm")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Algorithm", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-SignedHeaders", valid_606347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606348: Call_GetCreateDBInstance_606312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606348.validator(path, query, header, formData, body)
  let scheme = call_606348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606348.url(scheme.get, call_606348.host, call_606348.base,
                         call_606348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606348, url, valid)

proc call*(call_606349: Call_GetCreateDBInstance_606312; Engine: string;
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
  var query_606350 = newJObject()
  add(query_606350, "Version", newJString(Version))
  add(query_606350, "DBName", newJString(DBName))
  add(query_606350, "Engine", newJString(Engine))
  add(query_606350, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_606350, "CharacterSetName", newJString(CharacterSetName))
  add(query_606350, "LicenseModel", newJString(LicenseModel))
  add(query_606350, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606350, "MasterUsername", newJString(MasterUsername))
  add(query_606350, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_606350, "EngineVersion", newJString(EngineVersion))
  add(query_606350, "Action", newJString(Action))
  add(query_606350, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_606350.add "DBSecurityGroups", DBSecurityGroups
  add(query_606350, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_606350.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_606350, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_606350, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_606350, "OptionGroupName", newJString(OptionGroupName))
  add(query_606350, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606350, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_606350, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_606350, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_606350, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_606350, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_606350, "Iops", newJInt(Iops))
  add(query_606350, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_606349.call(nil, query_606350, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_606312(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_606313, base: "/",
    url: url_GetCreateDBInstance_606314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_606415 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBInstanceReadReplica_606417(protocol: Scheme; host: string;
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

proc validate_PostCreateDBInstanceReadReplica_606416(path: JsonNode;
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
  var valid_606418 = query.getOrDefault("Action")
  valid_606418 = validateParameter(valid_606418, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_606418 != nil:
    section.add "Action", valid_606418
  var valid_606419 = query.getOrDefault("Version")
  valid_606419 = validateParameter(valid_606419, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606419 != nil:
    section.add "Version", valid_606419
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606420 = header.getOrDefault("X-Amz-Signature")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Signature", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Content-Sha256", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Date")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Date", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Credential")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Credential", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Security-Token")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Security-Token", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Algorithm")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Algorithm", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-SignedHeaders", valid_606426
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
  var valid_606427 = formData.getOrDefault("Port")
  valid_606427 = validateParameter(valid_606427, JInt, required = false, default = nil)
  if valid_606427 != nil:
    section.add "Port", valid_606427
  var valid_606428 = formData.getOrDefault("DBInstanceClass")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "DBInstanceClass", valid_606428
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_606429 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_606429 = validateParameter(valid_606429, JString, required = true,
                                 default = nil)
  if valid_606429 != nil:
    section.add "SourceDBInstanceIdentifier", valid_606429
  var valid_606430 = formData.getOrDefault("AvailabilityZone")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "AvailabilityZone", valid_606430
  var valid_606431 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_606431 = validateParameter(valid_606431, JBool, required = false, default = nil)
  if valid_606431 != nil:
    section.add "AutoMinorVersionUpgrade", valid_606431
  var valid_606432 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606432 = validateParameter(valid_606432, JString, required = true,
                                 default = nil)
  if valid_606432 != nil:
    section.add "DBInstanceIdentifier", valid_606432
  var valid_606433 = formData.getOrDefault("Iops")
  valid_606433 = validateParameter(valid_606433, JInt, required = false, default = nil)
  if valid_606433 != nil:
    section.add "Iops", valid_606433
  var valid_606434 = formData.getOrDefault("PubliclyAccessible")
  valid_606434 = validateParameter(valid_606434, JBool, required = false, default = nil)
  if valid_606434 != nil:
    section.add "PubliclyAccessible", valid_606434
  var valid_606435 = formData.getOrDefault("OptionGroupName")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "OptionGroupName", valid_606435
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606436: Call_PostCreateDBInstanceReadReplica_606415;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_606436.validator(path, query, header, formData, body)
  let scheme = call_606436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606436.url(scheme.get, call_606436.host, call_606436.base,
                         call_606436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606436, url, valid)

proc call*(call_606437: Call_PostCreateDBInstanceReadReplica_606415;
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
  var query_606438 = newJObject()
  var formData_606439 = newJObject()
  add(formData_606439, "Port", newJInt(Port))
  add(formData_606439, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_606439, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_606439, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_606439, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_606439, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_606439, "Iops", newJInt(Iops))
  add(formData_606439, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_606438, "Action", newJString(Action))
  add(formData_606439, "OptionGroupName", newJString(OptionGroupName))
  add(query_606438, "Version", newJString(Version))
  result = call_606437.call(nil, query_606438, nil, formData_606439, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_606415(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_606416, base: "/",
    url: url_PostCreateDBInstanceReadReplica_606417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_606391 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBInstanceReadReplica_606393(protocol: Scheme; host: string;
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

proc validate_GetCreateDBInstanceReadReplica_606392(path: JsonNode;
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
  var valid_606394 = query.getOrDefault("DBInstanceIdentifier")
  valid_606394 = validateParameter(valid_606394, JString, required = true,
                                 default = nil)
  if valid_606394 != nil:
    section.add "DBInstanceIdentifier", valid_606394
  var valid_606395 = query.getOrDefault("Action")
  valid_606395 = validateParameter(valid_606395, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_606395 != nil:
    section.add "Action", valid_606395
  var valid_606396 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_606396 = validateParameter(valid_606396, JString, required = true,
                                 default = nil)
  if valid_606396 != nil:
    section.add "SourceDBInstanceIdentifier", valid_606396
  var valid_606397 = query.getOrDefault("Port")
  valid_606397 = validateParameter(valid_606397, JInt, required = false, default = nil)
  if valid_606397 != nil:
    section.add "Port", valid_606397
  var valid_606398 = query.getOrDefault("AvailabilityZone")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "AvailabilityZone", valid_606398
  var valid_606399 = query.getOrDefault("OptionGroupName")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "OptionGroupName", valid_606399
  var valid_606400 = query.getOrDefault("Version")
  valid_606400 = validateParameter(valid_606400, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606400 != nil:
    section.add "Version", valid_606400
  var valid_606401 = query.getOrDefault("DBInstanceClass")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "DBInstanceClass", valid_606401
  var valid_606402 = query.getOrDefault("PubliclyAccessible")
  valid_606402 = validateParameter(valid_606402, JBool, required = false, default = nil)
  if valid_606402 != nil:
    section.add "PubliclyAccessible", valid_606402
  var valid_606403 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_606403 = validateParameter(valid_606403, JBool, required = false, default = nil)
  if valid_606403 != nil:
    section.add "AutoMinorVersionUpgrade", valid_606403
  var valid_606404 = query.getOrDefault("Iops")
  valid_606404 = validateParameter(valid_606404, JInt, required = false, default = nil)
  if valid_606404 != nil:
    section.add "Iops", valid_606404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606405 = header.getOrDefault("X-Amz-Signature")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Signature", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Content-Sha256", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Date")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Date", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Credential")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Credential", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Security-Token")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Security-Token", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Algorithm")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Algorithm", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-SignedHeaders", valid_606411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606412: Call_GetCreateDBInstanceReadReplica_606391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606412.validator(path, query, header, formData, body)
  let scheme = call_606412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606412.url(scheme.get, call_606412.host, call_606412.base,
                         call_606412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606412, url, valid)

proc call*(call_606413: Call_GetCreateDBInstanceReadReplica_606391;
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
  var query_606414 = newJObject()
  add(query_606414, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606414, "Action", newJString(Action))
  add(query_606414, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_606414, "Port", newJInt(Port))
  add(query_606414, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_606414, "OptionGroupName", newJString(OptionGroupName))
  add(query_606414, "Version", newJString(Version))
  add(query_606414, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_606414, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_606414, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_606414, "Iops", newJInt(Iops))
  result = call_606413.call(nil, query_606414, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_606391(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_606392, base: "/",
    url: url_GetCreateDBInstanceReadReplica_606393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_606458 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBParameterGroup_606460(protocol: Scheme; host: string;
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

proc validate_PostCreateDBParameterGroup_606459(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606461 = query.getOrDefault("Action")
  valid_606461 = validateParameter(valid_606461, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_606461 != nil:
    section.add "Action", valid_606461
  var valid_606462 = query.getOrDefault("Version")
  valid_606462 = validateParameter(valid_606462, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606462 != nil:
    section.add "Version", valid_606462
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606463 = header.getOrDefault("X-Amz-Signature")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Signature", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Content-Sha256", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Date")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Date", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Credential")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Credential", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Security-Token")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Security-Token", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Algorithm")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Algorithm", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-SignedHeaders", valid_606469
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_606470 = formData.getOrDefault("Description")
  valid_606470 = validateParameter(valid_606470, JString, required = true,
                                 default = nil)
  if valid_606470 != nil:
    section.add "Description", valid_606470
  var valid_606471 = formData.getOrDefault("DBParameterGroupName")
  valid_606471 = validateParameter(valid_606471, JString, required = true,
                                 default = nil)
  if valid_606471 != nil:
    section.add "DBParameterGroupName", valid_606471
  var valid_606472 = formData.getOrDefault("DBParameterGroupFamily")
  valid_606472 = validateParameter(valid_606472, JString, required = true,
                                 default = nil)
  if valid_606472 != nil:
    section.add "DBParameterGroupFamily", valid_606472
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606473: Call_PostCreateDBParameterGroup_606458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606473.validator(path, query, header, formData, body)
  let scheme = call_606473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606473.url(scheme.get, call_606473.host, call_606473.base,
                         call_606473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606473, url, valid)

proc call*(call_606474: Call_PostCreateDBParameterGroup_606458;
          Description: string; DBParameterGroupName: string;
          DBParameterGroupFamily: string;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_606475 = newJObject()
  var formData_606476 = newJObject()
  add(formData_606476, "Description", newJString(Description))
  add(formData_606476, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_606475, "Action", newJString(Action))
  add(query_606475, "Version", newJString(Version))
  add(formData_606476, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_606474.call(nil, query_606475, nil, formData_606476, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_606458(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_606459, base: "/",
    url: url_PostCreateDBParameterGroup_606460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_606440 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBParameterGroup_606442(protocol: Scheme; host: string;
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

proc validate_GetCreateDBParameterGroup_606441(path: JsonNode; query: JsonNode;
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
  var valid_606443 = query.getOrDefault("DBParameterGroupFamily")
  valid_606443 = validateParameter(valid_606443, JString, required = true,
                                 default = nil)
  if valid_606443 != nil:
    section.add "DBParameterGroupFamily", valid_606443
  var valid_606444 = query.getOrDefault("DBParameterGroupName")
  valid_606444 = validateParameter(valid_606444, JString, required = true,
                                 default = nil)
  if valid_606444 != nil:
    section.add "DBParameterGroupName", valid_606444
  var valid_606445 = query.getOrDefault("Action")
  valid_606445 = validateParameter(valid_606445, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_606445 != nil:
    section.add "Action", valid_606445
  var valid_606446 = query.getOrDefault("Description")
  valid_606446 = validateParameter(valid_606446, JString, required = true,
                                 default = nil)
  if valid_606446 != nil:
    section.add "Description", valid_606446
  var valid_606447 = query.getOrDefault("Version")
  valid_606447 = validateParameter(valid_606447, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606447 != nil:
    section.add "Version", valid_606447
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606448 = header.getOrDefault("X-Amz-Signature")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Signature", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Content-Sha256", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Date")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Date", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Credential")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Credential", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Security-Token")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Security-Token", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-Algorithm")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Algorithm", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-SignedHeaders", valid_606454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606455: Call_GetCreateDBParameterGroup_606440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606455.validator(path, query, header, formData, body)
  let scheme = call_606455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606455.url(scheme.get, call_606455.host, call_606455.base,
                         call_606455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606455, url, valid)

proc call*(call_606456: Call_GetCreateDBParameterGroup_606440;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Description: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Description: string (required)
  ##   Version: string (required)
  var query_606457 = newJObject()
  add(query_606457, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_606457, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_606457, "Action", newJString(Action))
  add(query_606457, "Description", newJString(Description))
  add(query_606457, "Version", newJString(Version))
  result = call_606456.call(nil, query_606457, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_606440(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_606441, base: "/",
    url: url_GetCreateDBParameterGroup_606442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_606494 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBSecurityGroup_606496(protocol: Scheme; host: string;
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

proc validate_PostCreateDBSecurityGroup_606495(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606497 = query.getOrDefault("Action")
  valid_606497 = validateParameter(valid_606497, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_606497 != nil:
    section.add "Action", valid_606497
  var valid_606498 = query.getOrDefault("Version")
  valid_606498 = validateParameter(valid_606498, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606498 != nil:
    section.add "Version", valid_606498
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606499 = header.getOrDefault("X-Amz-Signature")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Signature", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Content-Sha256", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Date")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Date", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Credential")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Credential", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Security-Token")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Security-Token", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Algorithm")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Algorithm", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-SignedHeaders", valid_606505
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_606506 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_606506 = validateParameter(valid_606506, JString, required = true,
                                 default = nil)
  if valid_606506 != nil:
    section.add "DBSecurityGroupDescription", valid_606506
  var valid_606507 = formData.getOrDefault("DBSecurityGroupName")
  valid_606507 = validateParameter(valid_606507, JString, required = true,
                                 default = nil)
  if valid_606507 != nil:
    section.add "DBSecurityGroupName", valid_606507
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606508: Call_PostCreateDBSecurityGroup_606494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606508.validator(path, query, header, formData, body)
  let scheme = call_606508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606508.url(scheme.get, call_606508.host, call_606508.base,
                         call_606508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606508, url, valid)

proc call*(call_606509: Call_PostCreateDBSecurityGroup_606494;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606510 = newJObject()
  var formData_606511 = newJObject()
  add(formData_606511, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_606511, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_606510, "Action", newJString(Action))
  add(query_606510, "Version", newJString(Version))
  result = call_606509.call(nil, query_606510, nil, formData_606511, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_606494(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_606495, base: "/",
    url: url_PostCreateDBSecurityGroup_606496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_606477 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBSecurityGroup_606479(protocol: Scheme; host: string;
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

proc validate_GetCreateDBSecurityGroup_606478(path: JsonNode; query: JsonNode;
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
  var valid_606480 = query.getOrDefault("DBSecurityGroupName")
  valid_606480 = validateParameter(valid_606480, JString, required = true,
                                 default = nil)
  if valid_606480 != nil:
    section.add "DBSecurityGroupName", valid_606480
  var valid_606481 = query.getOrDefault("DBSecurityGroupDescription")
  valid_606481 = validateParameter(valid_606481, JString, required = true,
                                 default = nil)
  if valid_606481 != nil:
    section.add "DBSecurityGroupDescription", valid_606481
  var valid_606482 = query.getOrDefault("Action")
  valid_606482 = validateParameter(valid_606482, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_606482 != nil:
    section.add "Action", valid_606482
  var valid_606483 = query.getOrDefault("Version")
  valid_606483 = validateParameter(valid_606483, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606483 != nil:
    section.add "Version", valid_606483
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606484 = header.getOrDefault("X-Amz-Signature")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Signature", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Content-Sha256", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Date")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Date", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Credential")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Credential", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Security-Token")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Security-Token", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Algorithm")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Algorithm", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-SignedHeaders", valid_606490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606491: Call_GetCreateDBSecurityGroup_606477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606491.validator(path, query, header, formData, body)
  let scheme = call_606491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606491.url(scheme.get, call_606491.host, call_606491.base,
                         call_606491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606491, url, valid)

proc call*(call_606492: Call_GetCreateDBSecurityGroup_606477;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606493 = newJObject()
  add(query_606493, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_606493, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_606493, "Action", newJString(Action))
  add(query_606493, "Version", newJString(Version))
  result = call_606492.call(nil, query_606493, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_606477(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_606478, base: "/",
    url: url_GetCreateDBSecurityGroup_606479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_606529 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBSnapshot_606531(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSnapshot_606530(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606532 = query.getOrDefault("Action")
  valid_606532 = validateParameter(valid_606532, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_606532 != nil:
    section.add "Action", valid_606532
  var valid_606533 = query.getOrDefault("Version")
  valid_606533 = validateParameter(valid_606533, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606533 != nil:
    section.add "Version", valid_606533
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606534 = header.getOrDefault("X-Amz-Signature")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Signature", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Content-Sha256", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Date")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Date", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Credential")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Credential", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-Security-Token")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Security-Token", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-Algorithm")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Algorithm", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-SignedHeaders", valid_606540
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_606541 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606541 = validateParameter(valid_606541, JString, required = true,
                                 default = nil)
  if valid_606541 != nil:
    section.add "DBInstanceIdentifier", valid_606541
  var valid_606542 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_606542 = validateParameter(valid_606542, JString, required = true,
                                 default = nil)
  if valid_606542 != nil:
    section.add "DBSnapshotIdentifier", valid_606542
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606543: Call_PostCreateDBSnapshot_606529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606543.validator(path, query, header, formData, body)
  let scheme = call_606543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606543.url(scheme.get, call_606543.host, call_606543.base,
                         call_606543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606543, url, valid)

proc call*(call_606544: Call_PostCreateDBSnapshot_606529;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606545 = newJObject()
  var formData_606546 = newJObject()
  add(formData_606546, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_606546, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_606545, "Action", newJString(Action))
  add(query_606545, "Version", newJString(Version))
  result = call_606544.call(nil, query_606545, nil, formData_606546, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_606529(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_606530, base: "/",
    url: url_PostCreateDBSnapshot_606531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_606512 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBSnapshot_606514(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSnapshot_606513(path: JsonNode; query: JsonNode;
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
  var valid_606515 = query.getOrDefault("DBInstanceIdentifier")
  valid_606515 = validateParameter(valid_606515, JString, required = true,
                                 default = nil)
  if valid_606515 != nil:
    section.add "DBInstanceIdentifier", valid_606515
  var valid_606516 = query.getOrDefault("DBSnapshotIdentifier")
  valid_606516 = validateParameter(valid_606516, JString, required = true,
                                 default = nil)
  if valid_606516 != nil:
    section.add "DBSnapshotIdentifier", valid_606516
  var valid_606517 = query.getOrDefault("Action")
  valid_606517 = validateParameter(valid_606517, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_606517 != nil:
    section.add "Action", valid_606517
  var valid_606518 = query.getOrDefault("Version")
  valid_606518 = validateParameter(valid_606518, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606518 != nil:
    section.add "Version", valid_606518
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606519 = header.getOrDefault("X-Amz-Signature")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Signature", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Content-Sha256", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-Date")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Date", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Credential")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Credential", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Security-Token")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Security-Token", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Algorithm")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Algorithm", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-SignedHeaders", valid_606525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606526: Call_GetCreateDBSnapshot_606512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606526.validator(path, query, header, formData, body)
  let scheme = call_606526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606526.url(scheme.get, call_606526.host, call_606526.base,
                         call_606526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606526, url, valid)

proc call*(call_606527: Call_GetCreateDBSnapshot_606512;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606528 = newJObject()
  add(query_606528, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606528, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_606528, "Action", newJString(Action))
  add(query_606528, "Version", newJString(Version))
  result = call_606527.call(nil, query_606528, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_606512(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_606513, base: "/",
    url: url_GetCreateDBSnapshot_606514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_606565 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBSubnetGroup_606567(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSubnetGroup_606566(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606568 = query.getOrDefault("Action")
  valid_606568 = validateParameter(valid_606568, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_606568 != nil:
    section.add "Action", valid_606568
  var valid_606569 = query.getOrDefault("Version")
  valid_606569 = validateParameter(valid_606569, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606569 != nil:
    section.add "Version", valid_606569
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606570 = header.getOrDefault("X-Amz-Signature")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-Signature", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Content-Sha256", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-Date")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Date", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-Credential")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Credential", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-Security-Token")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Security-Token", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Algorithm")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Algorithm", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-SignedHeaders", valid_606576
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_606577 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_606577 = validateParameter(valid_606577, JString, required = true,
                                 default = nil)
  if valid_606577 != nil:
    section.add "DBSubnetGroupDescription", valid_606577
  var valid_606578 = formData.getOrDefault("DBSubnetGroupName")
  valid_606578 = validateParameter(valid_606578, JString, required = true,
                                 default = nil)
  if valid_606578 != nil:
    section.add "DBSubnetGroupName", valid_606578
  var valid_606579 = formData.getOrDefault("SubnetIds")
  valid_606579 = validateParameter(valid_606579, JArray, required = true, default = nil)
  if valid_606579 != nil:
    section.add "SubnetIds", valid_606579
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606580: Call_PostCreateDBSubnetGroup_606565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606580.validator(path, query, header, formData, body)
  let scheme = call_606580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606580.url(scheme.get, call_606580.host, call_606580.base,
                         call_606580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606580, url, valid)

proc call*(call_606581: Call_PostCreateDBSubnetGroup_606565;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          SubnetIds: JsonNode; Action: string = "CreateDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_606582 = newJObject()
  var formData_606583 = newJObject()
  add(formData_606583, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_606582, "Action", newJString(Action))
  add(formData_606583, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606582, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_606583.add "SubnetIds", SubnetIds
  result = call_606581.call(nil, query_606582, nil, formData_606583, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_606565(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_606566, base: "/",
    url: url_PostCreateDBSubnetGroup_606567, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_606547 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBSubnetGroup_606549(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSubnetGroup_606548(path: JsonNode; query: JsonNode;
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
  var valid_606550 = query.getOrDefault("SubnetIds")
  valid_606550 = validateParameter(valid_606550, JArray, required = true, default = nil)
  if valid_606550 != nil:
    section.add "SubnetIds", valid_606550
  var valid_606551 = query.getOrDefault("Action")
  valid_606551 = validateParameter(valid_606551, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_606551 != nil:
    section.add "Action", valid_606551
  var valid_606552 = query.getOrDefault("DBSubnetGroupDescription")
  valid_606552 = validateParameter(valid_606552, JString, required = true,
                                 default = nil)
  if valid_606552 != nil:
    section.add "DBSubnetGroupDescription", valid_606552
  var valid_606553 = query.getOrDefault("DBSubnetGroupName")
  valid_606553 = validateParameter(valid_606553, JString, required = true,
                                 default = nil)
  if valid_606553 != nil:
    section.add "DBSubnetGroupName", valid_606553
  var valid_606554 = query.getOrDefault("Version")
  valid_606554 = validateParameter(valid_606554, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606554 != nil:
    section.add "Version", valid_606554
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606555 = header.getOrDefault("X-Amz-Signature")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Signature", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Content-Sha256", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-Date")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Date", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Credential")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Credential", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Security-Token")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Security-Token", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Algorithm")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Algorithm", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-SignedHeaders", valid_606561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606562: Call_GetCreateDBSubnetGroup_606547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606562.validator(path, query, header, formData, body)
  let scheme = call_606562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606562.url(scheme.get, call_606562.host, call_606562.base,
                         call_606562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606562, url, valid)

proc call*(call_606563: Call_GetCreateDBSubnetGroup_606547; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_606564 = newJObject()
  if SubnetIds != nil:
    query_606564.add "SubnetIds", SubnetIds
  add(query_606564, "Action", newJString(Action))
  add(query_606564, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_606564, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606564, "Version", newJString(Version))
  result = call_606563.call(nil, query_606564, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_606547(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_606548, base: "/",
    url: url_GetCreateDBSubnetGroup_606549, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_606605 = ref object of OpenApiRestCall_605573
proc url_PostCreateEventSubscription_606607(protocol: Scheme; host: string;
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

proc validate_PostCreateEventSubscription_606606(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606608 = query.getOrDefault("Action")
  valid_606608 = validateParameter(valid_606608, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_606608 != nil:
    section.add "Action", valid_606608
  var valid_606609 = query.getOrDefault("Version")
  valid_606609 = validateParameter(valid_606609, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606609 != nil:
    section.add "Version", valid_606609
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606610 = header.getOrDefault("X-Amz-Signature")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Signature", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Content-Sha256", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Date")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Date", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Credential")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Credential", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Security-Token")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Security-Token", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-Algorithm")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-Algorithm", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-SignedHeaders", valid_606616
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIds: JArray
  ##   SnsTopicArn: JString (required)
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_606617 = formData.getOrDefault("SourceIds")
  valid_606617 = validateParameter(valid_606617, JArray, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "SourceIds", valid_606617
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_606618 = formData.getOrDefault("SnsTopicArn")
  valid_606618 = validateParameter(valid_606618, JString, required = true,
                                 default = nil)
  if valid_606618 != nil:
    section.add "SnsTopicArn", valid_606618
  var valid_606619 = formData.getOrDefault("Enabled")
  valid_606619 = validateParameter(valid_606619, JBool, required = false, default = nil)
  if valid_606619 != nil:
    section.add "Enabled", valid_606619
  var valid_606620 = formData.getOrDefault("SubscriptionName")
  valid_606620 = validateParameter(valid_606620, JString, required = true,
                                 default = nil)
  if valid_606620 != nil:
    section.add "SubscriptionName", valid_606620
  var valid_606621 = formData.getOrDefault("SourceType")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "SourceType", valid_606621
  var valid_606622 = formData.getOrDefault("EventCategories")
  valid_606622 = validateParameter(valid_606622, JArray, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "EventCategories", valid_606622
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606623: Call_PostCreateEventSubscription_606605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606623.validator(path, query, header, formData, body)
  let scheme = call_606623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606623.url(scheme.get, call_606623.host, call_606623.base,
                         call_606623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606623, url, valid)

proc call*(call_606624: Call_PostCreateEventSubscription_606605;
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
  var query_606625 = newJObject()
  var formData_606626 = newJObject()
  if SourceIds != nil:
    formData_606626.add "SourceIds", SourceIds
  add(formData_606626, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_606626, "Enabled", newJBool(Enabled))
  add(formData_606626, "SubscriptionName", newJString(SubscriptionName))
  add(formData_606626, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_606626.add "EventCategories", EventCategories
  add(query_606625, "Action", newJString(Action))
  add(query_606625, "Version", newJString(Version))
  result = call_606624.call(nil, query_606625, nil, formData_606626, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_606605(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_606606, base: "/",
    url: url_PostCreateEventSubscription_606607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_606584 = ref object of OpenApiRestCall_605573
proc url_GetCreateEventSubscription_606586(protocol: Scheme; host: string;
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

proc validate_GetCreateEventSubscription_606585(path: JsonNode; query: JsonNode;
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
  var valid_606587 = query.getOrDefault("SourceType")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "SourceType", valid_606587
  var valid_606588 = query.getOrDefault("Enabled")
  valid_606588 = validateParameter(valid_606588, JBool, required = false, default = nil)
  if valid_606588 != nil:
    section.add "Enabled", valid_606588
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_606589 = query.getOrDefault("SubscriptionName")
  valid_606589 = validateParameter(valid_606589, JString, required = true,
                                 default = nil)
  if valid_606589 != nil:
    section.add "SubscriptionName", valid_606589
  var valid_606590 = query.getOrDefault("EventCategories")
  valid_606590 = validateParameter(valid_606590, JArray, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "EventCategories", valid_606590
  var valid_606591 = query.getOrDefault("SourceIds")
  valid_606591 = validateParameter(valid_606591, JArray, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "SourceIds", valid_606591
  var valid_606592 = query.getOrDefault("Action")
  valid_606592 = validateParameter(valid_606592, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_606592 != nil:
    section.add "Action", valid_606592
  var valid_606593 = query.getOrDefault("SnsTopicArn")
  valid_606593 = validateParameter(valid_606593, JString, required = true,
                                 default = nil)
  if valid_606593 != nil:
    section.add "SnsTopicArn", valid_606593
  var valid_606594 = query.getOrDefault("Version")
  valid_606594 = validateParameter(valid_606594, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606594 != nil:
    section.add "Version", valid_606594
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606595 = header.getOrDefault("X-Amz-Signature")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Signature", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Content-Sha256", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Date")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Date", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Credential")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Credential", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Security-Token")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Security-Token", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Algorithm")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Algorithm", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-SignedHeaders", valid_606601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606602: Call_GetCreateEventSubscription_606584; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606602.validator(path, query, header, formData, body)
  let scheme = call_606602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606602.url(scheme.get, call_606602.host, call_606602.base,
                         call_606602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606602, url, valid)

proc call*(call_606603: Call_GetCreateEventSubscription_606584;
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
  var query_606604 = newJObject()
  add(query_606604, "SourceType", newJString(SourceType))
  add(query_606604, "Enabled", newJBool(Enabled))
  add(query_606604, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_606604.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_606604.add "SourceIds", SourceIds
  add(query_606604, "Action", newJString(Action))
  add(query_606604, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_606604, "Version", newJString(Version))
  result = call_606603.call(nil, query_606604, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_606584(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_606585, base: "/",
    url: url_GetCreateEventSubscription_606586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_606646 = ref object of OpenApiRestCall_605573
proc url_PostCreateOptionGroup_606648(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateOptionGroup_606647(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606649 = query.getOrDefault("Action")
  valid_606649 = validateParameter(valid_606649, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_606649 != nil:
    section.add "Action", valid_606649
  var valid_606650 = query.getOrDefault("Version")
  valid_606650 = validateParameter(valid_606650, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606650 != nil:
    section.add "Version", valid_606650
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606651 = header.getOrDefault("X-Amz-Signature")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Signature", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Content-Sha256", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Date")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Date", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-Credential")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Credential", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Security-Token")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Security-Token", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Algorithm")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Algorithm", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-SignedHeaders", valid_606657
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_606658 = formData.getOrDefault("OptionGroupDescription")
  valid_606658 = validateParameter(valid_606658, JString, required = true,
                                 default = nil)
  if valid_606658 != nil:
    section.add "OptionGroupDescription", valid_606658
  var valid_606659 = formData.getOrDefault("EngineName")
  valid_606659 = validateParameter(valid_606659, JString, required = true,
                                 default = nil)
  if valid_606659 != nil:
    section.add "EngineName", valid_606659
  var valid_606660 = formData.getOrDefault("MajorEngineVersion")
  valid_606660 = validateParameter(valid_606660, JString, required = true,
                                 default = nil)
  if valid_606660 != nil:
    section.add "MajorEngineVersion", valid_606660
  var valid_606661 = formData.getOrDefault("OptionGroupName")
  valid_606661 = validateParameter(valid_606661, JString, required = true,
                                 default = nil)
  if valid_606661 != nil:
    section.add "OptionGroupName", valid_606661
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606662: Call_PostCreateOptionGroup_606646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606662.validator(path, query, header, formData, body)
  let scheme = call_606662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606662.url(scheme.get, call_606662.host, call_606662.base,
                         call_606662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606662, url, valid)

proc call*(call_606663: Call_PostCreateOptionGroup_606646;
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
  var query_606664 = newJObject()
  var formData_606665 = newJObject()
  add(formData_606665, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_606665, "EngineName", newJString(EngineName))
  add(formData_606665, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_606664, "Action", newJString(Action))
  add(formData_606665, "OptionGroupName", newJString(OptionGroupName))
  add(query_606664, "Version", newJString(Version))
  result = call_606663.call(nil, query_606664, nil, formData_606665, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_606646(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_606647, base: "/",
    url: url_PostCreateOptionGroup_606648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_606627 = ref object of OpenApiRestCall_605573
proc url_GetCreateOptionGroup_606629(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateOptionGroup_606628(path: JsonNode; query: JsonNode;
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
  var valid_606630 = query.getOrDefault("EngineName")
  valid_606630 = validateParameter(valid_606630, JString, required = true,
                                 default = nil)
  if valid_606630 != nil:
    section.add "EngineName", valid_606630
  var valid_606631 = query.getOrDefault("OptionGroupDescription")
  valid_606631 = validateParameter(valid_606631, JString, required = true,
                                 default = nil)
  if valid_606631 != nil:
    section.add "OptionGroupDescription", valid_606631
  var valid_606632 = query.getOrDefault("Action")
  valid_606632 = validateParameter(valid_606632, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_606632 != nil:
    section.add "Action", valid_606632
  var valid_606633 = query.getOrDefault("OptionGroupName")
  valid_606633 = validateParameter(valid_606633, JString, required = true,
                                 default = nil)
  if valid_606633 != nil:
    section.add "OptionGroupName", valid_606633
  var valid_606634 = query.getOrDefault("Version")
  valid_606634 = validateParameter(valid_606634, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606634 != nil:
    section.add "Version", valid_606634
  var valid_606635 = query.getOrDefault("MajorEngineVersion")
  valid_606635 = validateParameter(valid_606635, JString, required = true,
                                 default = nil)
  if valid_606635 != nil:
    section.add "MajorEngineVersion", valid_606635
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606636 = header.getOrDefault("X-Amz-Signature")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Signature", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Content-Sha256", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Date")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Date", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Credential")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Credential", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Security-Token")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Security-Token", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Algorithm")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Algorithm", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-SignedHeaders", valid_606642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606643: Call_GetCreateOptionGroup_606627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606643.validator(path, query, header, formData, body)
  let scheme = call_606643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606643.url(scheme.get, call_606643.host, call_606643.base,
                         call_606643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606643, url, valid)

proc call*(call_606644: Call_GetCreateOptionGroup_606627; EngineName: string;
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
  var query_606645 = newJObject()
  add(query_606645, "EngineName", newJString(EngineName))
  add(query_606645, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_606645, "Action", newJString(Action))
  add(query_606645, "OptionGroupName", newJString(OptionGroupName))
  add(query_606645, "Version", newJString(Version))
  add(query_606645, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_606644.call(nil, query_606645, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_606627(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_606628, base: "/",
    url: url_GetCreateOptionGroup_606629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_606684 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBInstance_606686(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBInstance_606685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606687 = query.getOrDefault("Action")
  valid_606687 = validateParameter(valid_606687, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_606687 != nil:
    section.add "Action", valid_606687
  var valid_606688 = query.getOrDefault("Version")
  valid_606688 = validateParameter(valid_606688, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606688 != nil:
    section.add "Version", valid_606688
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606689 = header.getOrDefault("X-Amz-Signature")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Signature", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Content-Sha256", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-Date")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Date", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-Credential")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-Credential", valid_606692
  var valid_606693 = header.getOrDefault("X-Amz-Security-Token")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-Security-Token", valid_606693
  var valid_606694 = header.getOrDefault("X-Amz-Algorithm")
  valid_606694 = validateParameter(valid_606694, JString, required = false,
                                 default = nil)
  if valid_606694 != nil:
    section.add "X-Amz-Algorithm", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-SignedHeaders", valid_606695
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_606696 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606696 = validateParameter(valid_606696, JString, required = true,
                                 default = nil)
  if valid_606696 != nil:
    section.add "DBInstanceIdentifier", valid_606696
  var valid_606697 = formData.getOrDefault("SkipFinalSnapshot")
  valid_606697 = validateParameter(valid_606697, JBool, required = false, default = nil)
  if valid_606697 != nil:
    section.add "SkipFinalSnapshot", valid_606697
  var valid_606698 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_606698
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606699: Call_PostDeleteDBInstance_606684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606699.validator(path, query, header, formData, body)
  let scheme = call_606699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606699.url(scheme.get, call_606699.host, call_606699.base,
                         call_606699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606699, url, valid)

proc call*(call_606700: Call_PostDeleteDBInstance_606684;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_606701 = newJObject()
  var formData_606702 = newJObject()
  add(formData_606702, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606701, "Action", newJString(Action))
  add(formData_606702, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_606702, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_606701, "Version", newJString(Version))
  result = call_606700.call(nil, query_606701, nil, formData_606702, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_606684(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_606685, base: "/",
    url: url_PostDeleteDBInstance_606686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_606666 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBInstance_606668(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBInstance_606667(path: JsonNode; query: JsonNode;
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
  var valid_606669 = query.getOrDefault("DBInstanceIdentifier")
  valid_606669 = validateParameter(valid_606669, JString, required = true,
                                 default = nil)
  if valid_606669 != nil:
    section.add "DBInstanceIdentifier", valid_606669
  var valid_606670 = query.getOrDefault("SkipFinalSnapshot")
  valid_606670 = validateParameter(valid_606670, JBool, required = false, default = nil)
  if valid_606670 != nil:
    section.add "SkipFinalSnapshot", valid_606670
  var valid_606671 = query.getOrDefault("Action")
  valid_606671 = validateParameter(valid_606671, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_606671 != nil:
    section.add "Action", valid_606671
  var valid_606672 = query.getOrDefault("Version")
  valid_606672 = validateParameter(valid_606672, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606672 != nil:
    section.add "Version", valid_606672
  var valid_606673 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_606673
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606674 = header.getOrDefault("X-Amz-Signature")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Signature", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Content-Sha256", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Date")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Date", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-Credential")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-Credential", valid_606677
  var valid_606678 = header.getOrDefault("X-Amz-Security-Token")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-Security-Token", valid_606678
  var valid_606679 = header.getOrDefault("X-Amz-Algorithm")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-Algorithm", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-SignedHeaders", valid_606680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606681: Call_GetDeleteDBInstance_606666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606681.validator(path, query, header, formData, body)
  let scheme = call_606681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606681.url(scheme.get, call_606681.host, call_606681.base,
                         call_606681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606681, url, valid)

proc call*(call_606682: Call_GetDeleteDBInstance_606666;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2013-02-12";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_606683 = newJObject()
  add(query_606683, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606683, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_606683, "Action", newJString(Action))
  add(query_606683, "Version", newJString(Version))
  add(query_606683, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_606682.call(nil, query_606683, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_606666(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_606667, base: "/",
    url: url_GetDeleteDBInstance_606668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_606719 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBParameterGroup_606721(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBParameterGroup_606720(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606722 = query.getOrDefault("Action")
  valid_606722 = validateParameter(valid_606722, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_606722 != nil:
    section.add "Action", valid_606722
  var valid_606723 = query.getOrDefault("Version")
  valid_606723 = validateParameter(valid_606723, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606723 != nil:
    section.add "Version", valid_606723
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606724 = header.getOrDefault("X-Amz-Signature")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Signature", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Content-Sha256", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Date")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Date", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Credential")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Credential", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Security-Token")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Security-Token", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-Algorithm")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-Algorithm", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-SignedHeaders", valid_606730
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_606731 = formData.getOrDefault("DBParameterGroupName")
  valid_606731 = validateParameter(valid_606731, JString, required = true,
                                 default = nil)
  if valid_606731 != nil:
    section.add "DBParameterGroupName", valid_606731
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606732: Call_PostDeleteDBParameterGroup_606719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606732.validator(path, query, header, formData, body)
  let scheme = call_606732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606732.url(scheme.get, call_606732.host, call_606732.base,
                         call_606732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606732, url, valid)

proc call*(call_606733: Call_PostDeleteDBParameterGroup_606719;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606734 = newJObject()
  var formData_606735 = newJObject()
  add(formData_606735, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_606734, "Action", newJString(Action))
  add(query_606734, "Version", newJString(Version))
  result = call_606733.call(nil, query_606734, nil, formData_606735, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_606719(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_606720, base: "/",
    url: url_PostDeleteDBParameterGroup_606721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_606703 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBParameterGroup_606705(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBParameterGroup_606704(path: JsonNode; query: JsonNode;
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
  var valid_606706 = query.getOrDefault("DBParameterGroupName")
  valid_606706 = validateParameter(valid_606706, JString, required = true,
                                 default = nil)
  if valid_606706 != nil:
    section.add "DBParameterGroupName", valid_606706
  var valid_606707 = query.getOrDefault("Action")
  valid_606707 = validateParameter(valid_606707, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_606707 != nil:
    section.add "Action", valid_606707
  var valid_606708 = query.getOrDefault("Version")
  valid_606708 = validateParameter(valid_606708, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606708 != nil:
    section.add "Version", valid_606708
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606709 = header.getOrDefault("X-Amz-Signature")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Signature", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Content-Sha256", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Date")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Date", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Credential")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Credential", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Security-Token")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Security-Token", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-Algorithm")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Algorithm", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-SignedHeaders", valid_606715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606716: Call_GetDeleteDBParameterGroup_606703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606716.validator(path, query, header, formData, body)
  let scheme = call_606716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606716.url(scheme.get, call_606716.host, call_606716.base,
                         call_606716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606716, url, valid)

proc call*(call_606717: Call_GetDeleteDBParameterGroup_606703;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606718 = newJObject()
  add(query_606718, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_606718, "Action", newJString(Action))
  add(query_606718, "Version", newJString(Version))
  result = call_606717.call(nil, query_606718, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_606703(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_606704, base: "/",
    url: url_GetDeleteDBParameterGroup_606705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_606752 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBSecurityGroup_606754(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBSecurityGroup_606753(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606755 = query.getOrDefault("Action")
  valid_606755 = validateParameter(valid_606755, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_606755 != nil:
    section.add "Action", valid_606755
  var valid_606756 = query.getOrDefault("Version")
  valid_606756 = validateParameter(valid_606756, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606756 != nil:
    section.add "Version", valid_606756
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606757 = header.getOrDefault("X-Amz-Signature")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Signature", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-Content-Sha256", valid_606758
  var valid_606759 = header.getOrDefault("X-Amz-Date")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Date", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-Credential")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Credential", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-Security-Token")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-Security-Token", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-Algorithm")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-Algorithm", valid_606762
  var valid_606763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-SignedHeaders", valid_606763
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_606764 = formData.getOrDefault("DBSecurityGroupName")
  valid_606764 = validateParameter(valid_606764, JString, required = true,
                                 default = nil)
  if valid_606764 != nil:
    section.add "DBSecurityGroupName", valid_606764
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606765: Call_PostDeleteDBSecurityGroup_606752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606765.validator(path, query, header, formData, body)
  let scheme = call_606765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606765.url(scheme.get, call_606765.host, call_606765.base,
                         call_606765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606765, url, valid)

proc call*(call_606766: Call_PostDeleteDBSecurityGroup_606752;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606767 = newJObject()
  var formData_606768 = newJObject()
  add(formData_606768, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_606767, "Action", newJString(Action))
  add(query_606767, "Version", newJString(Version))
  result = call_606766.call(nil, query_606767, nil, formData_606768, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_606752(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_606753, base: "/",
    url: url_PostDeleteDBSecurityGroup_606754,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_606736 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBSecurityGroup_606738(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBSecurityGroup_606737(path: JsonNode; query: JsonNode;
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
  var valid_606739 = query.getOrDefault("DBSecurityGroupName")
  valid_606739 = validateParameter(valid_606739, JString, required = true,
                                 default = nil)
  if valid_606739 != nil:
    section.add "DBSecurityGroupName", valid_606739
  var valid_606740 = query.getOrDefault("Action")
  valid_606740 = validateParameter(valid_606740, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_606740 != nil:
    section.add "Action", valid_606740
  var valid_606741 = query.getOrDefault("Version")
  valid_606741 = validateParameter(valid_606741, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606741 != nil:
    section.add "Version", valid_606741
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606742 = header.getOrDefault("X-Amz-Signature")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Signature", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Content-Sha256", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-Date")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Date", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Credential")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Credential", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-Security-Token")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Security-Token", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-Algorithm")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Algorithm", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-SignedHeaders", valid_606748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606749: Call_GetDeleteDBSecurityGroup_606736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606749.validator(path, query, header, formData, body)
  let scheme = call_606749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606749.url(scheme.get, call_606749.host, call_606749.base,
                         call_606749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606749, url, valid)

proc call*(call_606750: Call_GetDeleteDBSecurityGroup_606736;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606751 = newJObject()
  add(query_606751, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_606751, "Action", newJString(Action))
  add(query_606751, "Version", newJString(Version))
  result = call_606750.call(nil, query_606751, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_606736(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_606737, base: "/",
    url: url_GetDeleteDBSecurityGroup_606738, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_606785 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBSnapshot_606787(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSnapshot_606786(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606788 = query.getOrDefault("Action")
  valid_606788 = validateParameter(valid_606788, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_606788 != nil:
    section.add "Action", valid_606788
  var valid_606789 = query.getOrDefault("Version")
  valid_606789 = validateParameter(valid_606789, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606789 != nil:
    section.add "Version", valid_606789
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606790 = header.getOrDefault("X-Amz-Signature")
  valid_606790 = validateParameter(valid_606790, JString, required = false,
                                 default = nil)
  if valid_606790 != nil:
    section.add "X-Amz-Signature", valid_606790
  var valid_606791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-Content-Sha256", valid_606791
  var valid_606792 = header.getOrDefault("X-Amz-Date")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "X-Amz-Date", valid_606792
  var valid_606793 = header.getOrDefault("X-Amz-Credential")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "X-Amz-Credential", valid_606793
  var valid_606794 = header.getOrDefault("X-Amz-Security-Token")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "X-Amz-Security-Token", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Algorithm")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Algorithm", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-SignedHeaders", valid_606796
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_606797 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_606797 = validateParameter(valid_606797, JString, required = true,
                                 default = nil)
  if valid_606797 != nil:
    section.add "DBSnapshotIdentifier", valid_606797
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606798: Call_PostDeleteDBSnapshot_606785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606798.validator(path, query, header, formData, body)
  let scheme = call_606798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606798.url(scheme.get, call_606798.host, call_606798.base,
                         call_606798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606798, url, valid)

proc call*(call_606799: Call_PostDeleteDBSnapshot_606785;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606800 = newJObject()
  var formData_606801 = newJObject()
  add(formData_606801, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_606800, "Action", newJString(Action))
  add(query_606800, "Version", newJString(Version))
  result = call_606799.call(nil, query_606800, nil, formData_606801, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_606785(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_606786, base: "/",
    url: url_PostDeleteDBSnapshot_606787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_606769 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBSnapshot_606771(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSnapshot_606770(path: JsonNode; query: JsonNode;
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
  var valid_606772 = query.getOrDefault("DBSnapshotIdentifier")
  valid_606772 = validateParameter(valid_606772, JString, required = true,
                                 default = nil)
  if valid_606772 != nil:
    section.add "DBSnapshotIdentifier", valid_606772
  var valid_606773 = query.getOrDefault("Action")
  valid_606773 = validateParameter(valid_606773, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_606773 != nil:
    section.add "Action", valid_606773
  var valid_606774 = query.getOrDefault("Version")
  valid_606774 = validateParameter(valid_606774, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606774 != nil:
    section.add "Version", valid_606774
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606775 = header.getOrDefault("X-Amz-Signature")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Signature", valid_606775
  var valid_606776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-Content-Sha256", valid_606776
  var valid_606777 = header.getOrDefault("X-Amz-Date")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-Date", valid_606777
  var valid_606778 = header.getOrDefault("X-Amz-Credential")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Credential", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Security-Token")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Security-Token", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Algorithm")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Algorithm", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-SignedHeaders", valid_606781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606782: Call_GetDeleteDBSnapshot_606769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606782.validator(path, query, header, formData, body)
  let scheme = call_606782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606782.url(scheme.get, call_606782.host, call_606782.base,
                         call_606782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606782, url, valid)

proc call*(call_606783: Call_GetDeleteDBSnapshot_606769;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606784 = newJObject()
  add(query_606784, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_606784, "Action", newJString(Action))
  add(query_606784, "Version", newJString(Version))
  result = call_606783.call(nil, query_606784, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_606769(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_606770, base: "/",
    url: url_GetDeleteDBSnapshot_606771, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_606818 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBSubnetGroup_606820(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSubnetGroup_606819(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606821 = query.getOrDefault("Action")
  valid_606821 = validateParameter(valid_606821, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_606821 != nil:
    section.add "Action", valid_606821
  var valid_606822 = query.getOrDefault("Version")
  valid_606822 = validateParameter(valid_606822, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606822 != nil:
    section.add "Version", valid_606822
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606823 = header.getOrDefault("X-Amz-Signature")
  valid_606823 = validateParameter(valid_606823, JString, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "X-Amz-Signature", valid_606823
  var valid_606824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "X-Amz-Content-Sha256", valid_606824
  var valid_606825 = header.getOrDefault("X-Amz-Date")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "X-Amz-Date", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-Credential")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Credential", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Security-Token")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Security-Token", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-Algorithm")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Algorithm", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-SignedHeaders", valid_606829
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_606830 = formData.getOrDefault("DBSubnetGroupName")
  valid_606830 = validateParameter(valid_606830, JString, required = true,
                                 default = nil)
  if valid_606830 != nil:
    section.add "DBSubnetGroupName", valid_606830
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606831: Call_PostDeleteDBSubnetGroup_606818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606831.validator(path, query, header, formData, body)
  let scheme = call_606831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606831.url(scheme.get, call_606831.host, call_606831.base,
                         call_606831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606831, url, valid)

proc call*(call_606832: Call_PostDeleteDBSubnetGroup_606818;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_606833 = newJObject()
  var formData_606834 = newJObject()
  add(query_606833, "Action", newJString(Action))
  add(formData_606834, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606833, "Version", newJString(Version))
  result = call_606832.call(nil, query_606833, nil, formData_606834, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_606818(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_606819, base: "/",
    url: url_PostDeleteDBSubnetGroup_606820, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_606802 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBSubnetGroup_606804(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSubnetGroup_606803(path: JsonNode; query: JsonNode;
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
  var valid_606805 = query.getOrDefault("Action")
  valid_606805 = validateParameter(valid_606805, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_606805 != nil:
    section.add "Action", valid_606805
  var valid_606806 = query.getOrDefault("DBSubnetGroupName")
  valid_606806 = validateParameter(valid_606806, JString, required = true,
                                 default = nil)
  if valid_606806 != nil:
    section.add "DBSubnetGroupName", valid_606806
  var valid_606807 = query.getOrDefault("Version")
  valid_606807 = validateParameter(valid_606807, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606807 != nil:
    section.add "Version", valid_606807
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606808 = header.getOrDefault("X-Amz-Signature")
  valid_606808 = validateParameter(valid_606808, JString, required = false,
                                 default = nil)
  if valid_606808 != nil:
    section.add "X-Amz-Signature", valid_606808
  var valid_606809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Content-Sha256", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Date")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Date", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Credential")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Credential", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Security-Token")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Security-Token", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Algorithm")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Algorithm", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-SignedHeaders", valid_606814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606815: Call_GetDeleteDBSubnetGroup_606802; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606815.validator(path, query, header, formData, body)
  let scheme = call_606815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606815.url(scheme.get, call_606815.host, call_606815.base,
                         call_606815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606815, url, valid)

proc call*(call_606816: Call_GetDeleteDBSubnetGroup_606802;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_606817 = newJObject()
  add(query_606817, "Action", newJString(Action))
  add(query_606817, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606817, "Version", newJString(Version))
  result = call_606816.call(nil, query_606817, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_606802(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_606803, base: "/",
    url: url_GetDeleteDBSubnetGroup_606804, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_606851 = ref object of OpenApiRestCall_605573
proc url_PostDeleteEventSubscription_606853(protocol: Scheme; host: string;
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

proc validate_PostDeleteEventSubscription_606852(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606854 = query.getOrDefault("Action")
  valid_606854 = validateParameter(valid_606854, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_606854 != nil:
    section.add "Action", valid_606854
  var valid_606855 = query.getOrDefault("Version")
  valid_606855 = validateParameter(valid_606855, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606855 != nil:
    section.add "Version", valid_606855
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606856 = header.getOrDefault("X-Amz-Signature")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Signature", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Content-Sha256", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Date")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Date", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Credential")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Credential", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-Security-Token")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Security-Token", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-Algorithm")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Algorithm", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-SignedHeaders", valid_606862
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_606863 = formData.getOrDefault("SubscriptionName")
  valid_606863 = validateParameter(valid_606863, JString, required = true,
                                 default = nil)
  if valid_606863 != nil:
    section.add "SubscriptionName", valid_606863
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606864: Call_PostDeleteEventSubscription_606851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606864.validator(path, query, header, formData, body)
  let scheme = call_606864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606864.url(scheme.get, call_606864.host, call_606864.base,
                         call_606864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606864, url, valid)

proc call*(call_606865: Call_PostDeleteEventSubscription_606851;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606866 = newJObject()
  var formData_606867 = newJObject()
  add(formData_606867, "SubscriptionName", newJString(SubscriptionName))
  add(query_606866, "Action", newJString(Action))
  add(query_606866, "Version", newJString(Version))
  result = call_606865.call(nil, query_606866, nil, formData_606867, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_606851(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_606852, base: "/",
    url: url_PostDeleteEventSubscription_606853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_606835 = ref object of OpenApiRestCall_605573
proc url_GetDeleteEventSubscription_606837(protocol: Scheme; host: string;
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

proc validate_GetDeleteEventSubscription_606836(path: JsonNode; query: JsonNode;
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
  var valid_606838 = query.getOrDefault("SubscriptionName")
  valid_606838 = validateParameter(valid_606838, JString, required = true,
                                 default = nil)
  if valid_606838 != nil:
    section.add "SubscriptionName", valid_606838
  var valid_606839 = query.getOrDefault("Action")
  valid_606839 = validateParameter(valid_606839, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_606839 != nil:
    section.add "Action", valid_606839
  var valid_606840 = query.getOrDefault("Version")
  valid_606840 = validateParameter(valid_606840, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606840 != nil:
    section.add "Version", valid_606840
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606841 = header.getOrDefault("X-Amz-Signature")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Signature", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Content-Sha256", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Date")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Date", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Credential")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Credential", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Security-Token")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Security-Token", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-Algorithm")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Algorithm", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-SignedHeaders", valid_606847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606848: Call_GetDeleteEventSubscription_606835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606848.validator(path, query, header, formData, body)
  let scheme = call_606848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606848.url(scheme.get, call_606848.host, call_606848.base,
                         call_606848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606848, url, valid)

proc call*(call_606849: Call_GetDeleteEventSubscription_606835;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606850 = newJObject()
  add(query_606850, "SubscriptionName", newJString(SubscriptionName))
  add(query_606850, "Action", newJString(Action))
  add(query_606850, "Version", newJString(Version))
  result = call_606849.call(nil, query_606850, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_606835(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_606836, base: "/",
    url: url_GetDeleteEventSubscription_606837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_606884 = ref object of OpenApiRestCall_605573
proc url_PostDeleteOptionGroup_606886(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteOptionGroup_606885(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606887 = query.getOrDefault("Action")
  valid_606887 = validateParameter(valid_606887, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_606887 != nil:
    section.add "Action", valid_606887
  var valid_606888 = query.getOrDefault("Version")
  valid_606888 = validateParameter(valid_606888, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606888 != nil:
    section.add "Version", valid_606888
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606889 = header.getOrDefault("X-Amz-Signature")
  valid_606889 = validateParameter(valid_606889, JString, required = false,
                                 default = nil)
  if valid_606889 != nil:
    section.add "X-Amz-Signature", valid_606889
  var valid_606890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Content-Sha256", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-Date")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-Date", valid_606891
  var valid_606892 = header.getOrDefault("X-Amz-Credential")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-Credential", valid_606892
  var valid_606893 = header.getOrDefault("X-Amz-Security-Token")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "X-Amz-Security-Token", valid_606893
  var valid_606894 = header.getOrDefault("X-Amz-Algorithm")
  valid_606894 = validateParameter(valid_606894, JString, required = false,
                                 default = nil)
  if valid_606894 != nil:
    section.add "X-Amz-Algorithm", valid_606894
  var valid_606895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606895 = validateParameter(valid_606895, JString, required = false,
                                 default = nil)
  if valid_606895 != nil:
    section.add "X-Amz-SignedHeaders", valid_606895
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_606896 = formData.getOrDefault("OptionGroupName")
  valid_606896 = validateParameter(valid_606896, JString, required = true,
                                 default = nil)
  if valid_606896 != nil:
    section.add "OptionGroupName", valid_606896
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606897: Call_PostDeleteOptionGroup_606884; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606897.validator(path, query, header, formData, body)
  let scheme = call_606897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606897.url(scheme.get, call_606897.host, call_606897.base,
                         call_606897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606897, url, valid)

proc call*(call_606898: Call_PostDeleteOptionGroup_606884; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_606899 = newJObject()
  var formData_606900 = newJObject()
  add(query_606899, "Action", newJString(Action))
  add(formData_606900, "OptionGroupName", newJString(OptionGroupName))
  add(query_606899, "Version", newJString(Version))
  result = call_606898.call(nil, query_606899, nil, formData_606900, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_606884(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_606885, base: "/",
    url: url_PostDeleteOptionGroup_606886, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_606868 = ref object of OpenApiRestCall_605573
proc url_GetDeleteOptionGroup_606870(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteOptionGroup_606869(path: JsonNode; query: JsonNode;
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
  var valid_606871 = query.getOrDefault("Action")
  valid_606871 = validateParameter(valid_606871, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_606871 != nil:
    section.add "Action", valid_606871
  var valid_606872 = query.getOrDefault("OptionGroupName")
  valid_606872 = validateParameter(valid_606872, JString, required = true,
                                 default = nil)
  if valid_606872 != nil:
    section.add "OptionGroupName", valid_606872
  var valid_606873 = query.getOrDefault("Version")
  valid_606873 = validateParameter(valid_606873, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606873 != nil:
    section.add "Version", valid_606873
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606874 = header.getOrDefault("X-Amz-Signature")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Signature", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Content-Sha256", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Date")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Date", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Credential")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Credential", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-Security-Token")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-Security-Token", valid_606878
  var valid_606879 = header.getOrDefault("X-Amz-Algorithm")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "X-Amz-Algorithm", valid_606879
  var valid_606880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606880 = validateParameter(valid_606880, JString, required = false,
                                 default = nil)
  if valid_606880 != nil:
    section.add "X-Amz-SignedHeaders", valid_606880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606881: Call_GetDeleteOptionGroup_606868; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606881.validator(path, query, header, formData, body)
  let scheme = call_606881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606881.url(scheme.get, call_606881.host, call_606881.base,
                         call_606881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606881, url, valid)

proc call*(call_606882: Call_GetDeleteOptionGroup_606868; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_606883 = newJObject()
  add(query_606883, "Action", newJString(Action))
  add(query_606883, "OptionGroupName", newJString(OptionGroupName))
  add(query_606883, "Version", newJString(Version))
  result = call_606882.call(nil, query_606883, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_606868(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_606869, base: "/",
    url: url_GetDeleteOptionGroup_606870, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_606923 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBEngineVersions_606925(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBEngineVersions_606924(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606926 = query.getOrDefault("Action")
  valid_606926 = validateParameter(valid_606926, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_606926 != nil:
    section.add "Action", valid_606926
  var valid_606927 = query.getOrDefault("Version")
  valid_606927 = validateParameter(valid_606927, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606927 != nil:
    section.add "Version", valid_606927
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606928 = header.getOrDefault("X-Amz-Signature")
  valid_606928 = validateParameter(valid_606928, JString, required = false,
                                 default = nil)
  if valid_606928 != nil:
    section.add "X-Amz-Signature", valid_606928
  var valid_606929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606929 = validateParameter(valid_606929, JString, required = false,
                                 default = nil)
  if valid_606929 != nil:
    section.add "X-Amz-Content-Sha256", valid_606929
  var valid_606930 = header.getOrDefault("X-Amz-Date")
  valid_606930 = validateParameter(valid_606930, JString, required = false,
                                 default = nil)
  if valid_606930 != nil:
    section.add "X-Amz-Date", valid_606930
  var valid_606931 = header.getOrDefault("X-Amz-Credential")
  valid_606931 = validateParameter(valid_606931, JString, required = false,
                                 default = nil)
  if valid_606931 != nil:
    section.add "X-Amz-Credential", valid_606931
  var valid_606932 = header.getOrDefault("X-Amz-Security-Token")
  valid_606932 = validateParameter(valid_606932, JString, required = false,
                                 default = nil)
  if valid_606932 != nil:
    section.add "X-Amz-Security-Token", valid_606932
  var valid_606933 = header.getOrDefault("X-Amz-Algorithm")
  valid_606933 = validateParameter(valid_606933, JString, required = false,
                                 default = nil)
  if valid_606933 != nil:
    section.add "X-Amz-Algorithm", valid_606933
  var valid_606934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606934 = validateParameter(valid_606934, JString, required = false,
                                 default = nil)
  if valid_606934 != nil:
    section.add "X-Amz-SignedHeaders", valid_606934
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
  var valid_606935 = formData.getOrDefault("DefaultOnly")
  valid_606935 = validateParameter(valid_606935, JBool, required = false, default = nil)
  if valid_606935 != nil:
    section.add "DefaultOnly", valid_606935
  var valid_606936 = formData.getOrDefault("MaxRecords")
  valid_606936 = validateParameter(valid_606936, JInt, required = false, default = nil)
  if valid_606936 != nil:
    section.add "MaxRecords", valid_606936
  var valid_606937 = formData.getOrDefault("EngineVersion")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "EngineVersion", valid_606937
  var valid_606938 = formData.getOrDefault("Marker")
  valid_606938 = validateParameter(valid_606938, JString, required = false,
                                 default = nil)
  if valid_606938 != nil:
    section.add "Marker", valid_606938
  var valid_606939 = formData.getOrDefault("Engine")
  valid_606939 = validateParameter(valid_606939, JString, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "Engine", valid_606939
  var valid_606940 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_606940 = validateParameter(valid_606940, JBool, required = false, default = nil)
  if valid_606940 != nil:
    section.add "ListSupportedCharacterSets", valid_606940
  var valid_606941 = formData.getOrDefault("DBParameterGroupFamily")
  valid_606941 = validateParameter(valid_606941, JString, required = false,
                                 default = nil)
  if valid_606941 != nil:
    section.add "DBParameterGroupFamily", valid_606941
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606942: Call_PostDescribeDBEngineVersions_606923; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606942.validator(path, query, header, formData, body)
  let scheme = call_606942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606942.url(scheme.get, call_606942.host, call_606942.base,
                         call_606942.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606942, url, valid)

proc call*(call_606943: Call_PostDescribeDBEngineVersions_606923;
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
  var query_606944 = newJObject()
  var formData_606945 = newJObject()
  add(formData_606945, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_606945, "MaxRecords", newJInt(MaxRecords))
  add(formData_606945, "EngineVersion", newJString(EngineVersion))
  add(formData_606945, "Marker", newJString(Marker))
  add(formData_606945, "Engine", newJString(Engine))
  add(formData_606945, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_606944, "Action", newJString(Action))
  add(query_606944, "Version", newJString(Version))
  add(formData_606945, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_606943.call(nil, query_606944, nil, formData_606945, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_606923(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_606924, base: "/",
    url: url_PostDescribeDBEngineVersions_606925,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_606901 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBEngineVersions_606903(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBEngineVersions_606902(path: JsonNode; query: JsonNode;
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
  var valid_606904 = query.getOrDefault("Marker")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "Marker", valid_606904
  var valid_606905 = query.getOrDefault("DBParameterGroupFamily")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "DBParameterGroupFamily", valid_606905
  var valid_606906 = query.getOrDefault("Engine")
  valid_606906 = validateParameter(valid_606906, JString, required = false,
                                 default = nil)
  if valid_606906 != nil:
    section.add "Engine", valid_606906
  var valid_606907 = query.getOrDefault("EngineVersion")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "EngineVersion", valid_606907
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606908 = query.getOrDefault("Action")
  valid_606908 = validateParameter(valid_606908, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_606908 != nil:
    section.add "Action", valid_606908
  var valid_606909 = query.getOrDefault("ListSupportedCharacterSets")
  valid_606909 = validateParameter(valid_606909, JBool, required = false, default = nil)
  if valid_606909 != nil:
    section.add "ListSupportedCharacterSets", valid_606909
  var valid_606910 = query.getOrDefault("Version")
  valid_606910 = validateParameter(valid_606910, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606910 != nil:
    section.add "Version", valid_606910
  var valid_606911 = query.getOrDefault("MaxRecords")
  valid_606911 = validateParameter(valid_606911, JInt, required = false, default = nil)
  if valid_606911 != nil:
    section.add "MaxRecords", valid_606911
  var valid_606912 = query.getOrDefault("DefaultOnly")
  valid_606912 = validateParameter(valid_606912, JBool, required = false, default = nil)
  if valid_606912 != nil:
    section.add "DefaultOnly", valid_606912
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606913 = header.getOrDefault("X-Amz-Signature")
  valid_606913 = validateParameter(valid_606913, JString, required = false,
                                 default = nil)
  if valid_606913 != nil:
    section.add "X-Amz-Signature", valid_606913
  var valid_606914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606914 = validateParameter(valid_606914, JString, required = false,
                                 default = nil)
  if valid_606914 != nil:
    section.add "X-Amz-Content-Sha256", valid_606914
  var valid_606915 = header.getOrDefault("X-Amz-Date")
  valid_606915 = validateParameter(valid_606915, JString, required = false,
                                 default = nil)
  if valid_606915 != nil:
    section.add "X-Amz-Date", valid_606915
  var valid_606916 = header.getOrDefault("X-Amz-Credential")
  valid_606916 = validateParameter(valid_606916, JString, required = false,
                                 default = nil)
  if valid_606916 != nil:
    section.add "X-Amz-Credential", valid_606916
  var valid_606917 = header.getOrDefault("X-Amz-Security-Token")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "X-Amz-Security-Token", valid_606917
  var valid_606918 = header.getOrDefault("X-Amz-Algorithm")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "X-Amz-Algorithm", valid_606918
  var valid_606919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606919 = validateParameter(valid_606919, JString, required = false,
                                 default = nil)
  if valid_606919 != nil:
    section.add "X-Amz-SignedHeaders", valid_606919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606920: Call_GetDescribeDBEngineVersions_606901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606920.validator(path, query, header, formData, body)
  let scheme = call_606920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606920.url(scheme.get, call_606920.host, call_606920.base,
                         call_606920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606920, url, valid)

proc call*(call_606921: Call_GetDescribeDBEngineVersions_606901;
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
  var query_606922 = newJObject()
  add(query_606922, "Marker", newJString(Marker))
  add(query_606922, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_606922, "Engine", newJString(Engine))
  add(query_606922, "EngineVersion", newJString(EngineVersion))
  add(query_606922, "Action", newJString(Action))
  add(query_606922, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_606922, "Version", newJString(Version))
  add(query_606922, "MaxRecords", newJInt(MaxRecords))
  add(query_606922, "DefaultOnly", newJBool(DefaultOnly))
  result = call_606921.call(nil, query_606922, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_606901(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_606902, base: "/",
    url: url_GetDescribeDBEngineVersions_606903,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_606964 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBInstances_606966(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBInstances_606965(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606967 = query.getOrDefault("Action")
  valid_606967 = validateParameter(valid_606967, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_606967 != nil:
    section.add "Action", valid_606967
  var valid_606968 = query.getOrDefault("Version")
  valid_606968 = validateParameter(valid_606968, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606968 != nil:
    section.add "Version", valid_606968
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606969 = header.getOrDefault("X-Amz-Signature")
  valid_606969 = validateParameter(valid_606969, JString, required = false,
                                 default = nil)
  if valid_606969 != nil:
    section.add "X-Amz-Signature", valid_606969
  var valid_606970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606970 = validateParameter(valid_606970, JString, required = false,
                                 default = nil)
  if valid_606970 != nil:
    section.add "X-Amz-Content-Sha256", valid_606970
  var valid_606971 = header.getOrDefault("X-Amz-Date")
  valid_606971 = validateParameter(valid_606971, JString, required = false,
                                 default = nil)
  if valid_606971 != nil:
    section.add "X-Amz-Date", valid_606971
  var valid_606972 = header.getOrDefault("X-Amz-Credential")
  valid_606972 = validateParameter(valid_606972, JString, required = false,
                                 default = nil)
  if valid_606972 != nil:
    section.add "X-Amz-Credential", valid_606972
  var valid_606973 = header.getOrDefault("X-Amz-Security-Token")
  valid_606973 = validateParameter(valid_606973, JString, required = false,
                                 default = nil)
  if valid_606973 != nil:
    section.add "X-Amz-Security-Token", valid_606973
  var valid_606974 = header.getOrDefault("X-Amz-Algorithm")
  valid_606974 = validateParameter(valid_606974, JString, required = false,
                                 default = nil)
  if valid_606974 != nil:
    section.add "X-Amz-Algorithm", valid_606974
  var valid_606975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "X-Amz-SignedHeaders", valid_606975
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  section = newJObject()
  var valid_606976 = formData.getOrDefault("MaxRecords")
  valid_606976 = validateParameter(valid_606976, JInt, required = false, default = nil)
  if valid_606976 != nil:
    section.add "MaxRecords", valid_606976
  var valid_606977 = formData.getOrDefault("Marker")
  valid_606977 = validateParameter(valid_606977, JString, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "Marker", valid_606977
  var valid_606978 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606978 = validateParameter(valid_606978, JString, required = false,
                                 default = nil)
  if valid_606978 != nil:
    section.add "DBInstanceIdentifier", valid_606978
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606979: Call_PostDescribeDBInstances_606964; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606979.validator(path, query, header, formData, body)
  let scheme = call_606979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606979.url(scheme.get, call_606979.host, call_606979.base,
                         call_606979.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606979, url, valid)

proc call*(call_606980: Call_PostDescribeDBInstances_606964; MaxRecords: int = 0;
          Marker: string = ""; DBInstanceIdentifier: string = "";
          Action: string = "DescribeDBInstances"; Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBInstances
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606981 = newJObject()
  var formData_606982 = newJObject()
  add(formData_606982, "MaxRecords", newJInt(MaxRecords))
  add(formData_606982, "Marker", newJString(Marker))
  add(formData_606982, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606981, "Action", newJString(Action))
  add(query_606981, "Version", newJString(Version))
  result = call_606980.call(nil, query_606981, nil, formData_606982, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_606964(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_606965, base: "/",
    url: url_PostDescribeDBInstances_606966, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_606946 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBInstances_606948(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBInstances_606947(path: JsonNode; query: JsonNode;
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
  var valid_606949 = query.getOrDefault("Marker")
  valid_606949 = validateParameter(valid_606949, JString, required = false,
                                 default = nil)
  if valid_606949 != nil:
    section.add "Marker", valid_606949
  var valid_606950 = query.getOrDefault("DBInstanceIdentifier")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = nil)
  if valid_606950 != nil:
    section.add "DBInstanceIdentifier", valid_606950
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606951 = query.getOrDefault("Action")
  valid_606951 = validateParameter(valid_606951, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_606951 != nil:
    section.add "Action", valid_606951
  var valid_606952 = query.getOrDefault("Version")
  valid_606952 = validateParameter(valid_606952, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606952 != nil:
    section.add "Version", valid_606952
  var valid_606953 = query.getOrDefault("MaxRecords")
  valid_606953 = validateParameter(valid_606953, JInt, required = false, default = nil)
  if valid_606953 != nil:
    section.add "MaxRecords", valid_606953
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606954 = header.getOrDefault("X-Amz-Signature")
  valid_606954 = validateParameter(valid_606954, JString, required = false,
                                 default = nil)
  if valid_606954 != nil:
    section.add "X-Amz-Signature", valid_606954
  var valid_606955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606955 = validateParameter(valid_606955, JString, required = false,
                                 default = nil)
  if valid_606955 != nil:
    section.add "X-Amz-Content-Sha256", valid_606955
  var valid_606956 = header.getOrDefault("X-Amz-Date")
  valid_606956 = validateParameter(valid_606956, JString, required = false,
                                 default = nil)
  if valid_606956 != nil:
    section.add "X-Amz-Date", valid_606956
  var valid_606957 = header.getOrDefault("X-Amz-Credential")
  valid_606957 = validateParameter(valid_606957, JString, required = false,
                                 default = nil)
  if valid_606957 != nil:
    section.add "X-Amz-Credential", valid_606957
  var valid_606958 = header.getOrDefault("X-Amz-Security-Token")
  valid_606958 = validateParameter(valid_606958, JString, required = false,
                                 default = nil)
  if valid_606958 != nil:
    section.add "X-Amz-Security-Token", valid_606958
  var valid_606959 = header.getOrDefault("X-Amz-Algorithm")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-Algorithm", valid_606959
  var valid_606960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "X-Amz-SignedHeaders", valid_606960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606961: Call_GetDescribeDBInstances_606946; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606961.validator(path, query, header, formData, body)
  let scheme = call_606961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606961.url(scheme.get, call_606961.host, call_606961.base,
                         call_606961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606961, url, valid)

proc call*(call_606962: Call_GetDescribeDBInstances_606946; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_606963 = newJObject()
  add(query_606963, "Marker", newJString(Marker))
  add(query_606963, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606963, "Action", newJString(Action))
  add(query_606963, "Version", newJString(Version))
  add(query_606963, "MaxRecords", newJInt(MaxRecords))
  result = call_606962.call(nil, query_606963, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_606946(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_606947, base: "/",
    url: url_GetDescribeDBInstances_606948, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_607004 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBLogFiles_607006(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBLogFiles_607005(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607007 = query.getOrDefault("Action")
  valid_607007 = validateParameter(valid_607007, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_607007 != nil:
    section.add "Action", valid_607007
  var valid_607008 = query.getOrDefault("Version")
  valid_607008 = validateParameter(valid_607008, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607008 != nil:
    section.add "Version", valid_607008
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607009 = header.getOrDefault("X-Amz-Signature")
  valid_607009 = validateParameter(valid_607009, JString, required = false,
                                 default = nil)
  if valid_607009 != nil:
    section.add "X-Amz-Signature", valid_607009
  var valid_607010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "X-Amz-Content-Sha256", valid_607010
  var valid_607011 = header.getOrDefault("X-Amz-Date")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "X-Amz-Date", valid_607011
  var valid_607012 = header.getOrDefault("X-Amz-Credential")
  valid_607012 = validateParameter(valid_607012, JString, required = false,
                                 default = nil)
  if valid_607012 != nil:
    section.add "X-Amz-Credential", valid_607012
  var valid_607013 = header.getOrDefault("X-Amz-Security-Token")
  valid_607013 = validateParameter(valid_607013, JString, required = false,
                                 default = nil)
  if valid_607013 != nil:
    section.add "X-Amz-Security-Token", valid_607013
  var valid_607014 = header.getOrDefault("X-Amz-Algorithm")
  valid_607014 = validateParameter(valid_607014, JString, required = false,
                                 default = nil)
  if valid_607014 != nil:
    section.add "X-Amz-Algorithm", valid_607014
  var valid_607015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607015 = validateParameter(valid_607015, JString, required = false,
                                 default = nil)
  if valid_607015 != nil:
    section.add "X-Amz-SignedHeaders", valid_607015
  result.add "header", section
  ## parameters in `formData` object:
  ##   FileSize: JInt
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FilenameContains: JString
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_607016 = formData.getOrDefault("FileSize")
  valid_607016 = validateParameter(valid_607016, JInt, required = false, default = nil)
  if valid_607016 != nil:
    section.add "FileSize", valid_607016
  var valid_607017 = formData.getOrDefault("MaxRecords")
  valid_607017 = validateParameter(valid_607017, JInt, required = false, default = nil)
  if valid_607017 != nil:
    section.add "MaxRecords", valid_607017
  var valid_607018 = formData.getOrDefault("Marker")
  valid_607018 = validateParameter(valid_607018, JString, required = false,
                                 default = nil)
  if valid_607018 != nil:
    section.add "Marker", valid_607018
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607019 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607019 = validateParameter(valid_607019, JString, required = true,
                                 default = nil)
  if valid_607019 != nil:
    section.add "DBInstanceIdentifier", valid_607019
  var valid_607020 = formData.getOrDefault("FilenameContains")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "FilenameContains", valid_607020
  var valid_607021 = formData.getOrDefault("FileLastWritten")
  valid_607021 = validateParameter(valid_607021, JInt, required = false, default = nil)
  if valid_607021 != nil:
    section.add "FileLastWritten", valid_607021
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607022: Call_PostDescribeDBLogFiles_607004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607022.validator(path, query, header, formData, body)
  let scheme = call_607022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607022.url(scheme.get, call_607022.host, call_607022.base,
                         call_607022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607022, url, valid)

proc call*(call_607023: Call_PostDescribeDBLogFiles_607004;
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
  var query_607024 = newJObject()
  var formData_607025 = newJObject()
  add(formData_607025, "FileSize", newJInt(FileSize))
  add(formData_607025, "MaxRecords", newJInt(MaxRecords))
  add(formData_607025, "Marker", newJString(Marker))
  add(formData_607025, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_607025, "FilenameContains", newJString(FilenameContains))
  add(query_607024, "Action", newJString(Action))
  add(query_607024, "Version", newJString(Version))
  add(formData_607025, "FileLastWritten", newJInt(FileLastWritten))
  result = call_607023.call(nil, query_607024, nil, formData_607025, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_607004(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_607005, base: "/",
    url: url_PostDescribeDBLogFiles_607006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_606983 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBLogFiles_606985(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBLogFiles_606984(path: JsonNode; query: JsonNode;
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
  var valid_606986 = query.getOrDefault("Marker")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "Marker", valid_606986
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_606987 = query.getOrDefault("DBInstanceIdentifier")
  valid_606987 = validateParameter(valid_606987, JString, required = true,
                                 default = nil)
  if valid_606987 != nil:
    section.add "DBInstanceIdentifier", valid_606987
  var valid_606988 = query.getOrDefault("FileLastWritten")
  valid_606988 = validateParameter(valid_606988, JInt, required = false, default = nil)
  if valid_606988 != nil:
    section.add "FileLastWritten", valid_606988
  var valid_606989 = query.getOrDefault("Action")
  valid_606989 = validateParameter(valid_606989, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_606989 != nil:
    section.add "Action", valid_606989
  var valid_606990 = query.getOrDefault("FilenameContains")
  valid_606990 = validateParameter(valid_606990, JString, required = false,
                                 default = nil)
  if valid_606990 != nil:
    section.add "FilenameContains", valid_606990
  var valid_606991 = query.getOrDefault("Version")
  valid_606991 = validateParameter(valid_606991, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_606991 != nil:
    section.add "Version", valid_606991
  var valid_606992 = query.getOrDefault("MaxRecords")
  valid_606992 = validateParameter(valid_606992, JInt, required = false, default = nil)
  if valid_606992 != nil:
    section.add "MaxRecords", valid_606992
  var valid_606993 = query.getOrDefault("FileSize")
  valid_606993 = validateParameter(valid_606993, JInt, required = false, default = nil)
  if valid_606993 != nil:
    section.add "FileSize", valid_606993
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606994 = header.getOrDefault("X-Amz-Signature")
  valid_606994 = validateParameter(valid_606994, JString, required = false,
                                 default = nil)
  if valid_606994 != nil:
    section.add "X-Amz-Signature", valid_606994
  var valid_606995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606995 = validateParameter(valid_606995, JString, required = false,
                                 default = nil)
  if valid_606995 != nil:
    section.add "X-Amz-Content-Sha256", valid_606995
  var valid_606996 = header.getOrDefault("X-Amz-Date")
  valid_606996 = validateParameter(valid_606996, JString, required = false,
                                 default = nil)
  if valid_606996 != nil:
    section.add "X-Amz-Date", valid_606996
  var valid_606997 = header.getOrDefault("X-Amz-Credential")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "X-Amz-Credential", valid_606997
  var valid_606998 = header.getOrDefault("X-Amz-Security-Token")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "X-Amz-Security-Token", valid_606998
  var valid_606999 = header.getOrDefault("X-Amz-Algorithm")
  valid_606999 = validateParameter(valid_606999, JString, required = false,
                                 default = nil)
  if valid_606999 != nil:
    section.add "X-Amz-Algorithm", valid_606999
  var valid_607000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607000 = validateParameter(valid_607000, JString, required = false,
                                 default = nil)
  if valid_607000 != nil:
    section.add "X-Amz-SignedHeaders", valid_607000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607001: Call_GetDescribeDBLogFiles_606983; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607001.validator(path, query, header, formData, body)
  let scheme = call_607001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607001.url(scheme.get, call_607001.host, call_607001.base,
                         call_607001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607001, url, valid)

proc call*(call_607002: Call_GetDescribeDBLogFiles_606983;
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
  var query_607003 = newJObject()
  add(query_607003, "Marker", newJString(Marker))
  add(query_607003, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607003, "FileLastWritten", newJInt(FileLastWritten))
  add(query_607003, "Action", newJString(Action))
  add(query_607003, "FilenameContains", newJString(FilenameContains))
  add(query_607003, "Version", newJString(Version))
  add(query_607003, "MaxRecords", newJInt(MaxRecords))
  add(query_607003, "FileSize", newJInt(FileSize))
  result = call_607002.call(nil, query_607003, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_606983(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_606984, base: "/",
    url: url_GetDescribeDBLogFiles_606985, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_607044 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBParameterGroups_607046(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameterGroups_607045(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607047 = query.getOrDefault("Action")
  valid_607047 = validateParameter(valid_607047, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_607047 != nil:
    section.add "Action", valid_607047
  var valid_607048 = query.getOrDefault("Version")
  valid_607048 = validateParameter(valid_607048, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607048 != nil:
    section.add "Version", valid_607048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607049 = header.getOrDefault("X-Amz-Signature")
  valid_607049 = validateParameter(valid_607049, JString, required = false,
                                 default = nil)
  if valid_607049 != nil:
    section.add "X-Amz-Signature", valid_607049
  var valid_607050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607050 = validateParameter(valid_607050, JString, required = false,
                                 default = nil)
  if valid_607050 != nil:
    section.add "X-Amz-Content-Sha256", valid_607050
  var valid_607051 = header.getOrDefault("X-Amz-Date")
  valid_607051 = validateParameter(valid_607051, JString, required = false,
                                 default = nil)
  if valid_607051 != nil:
    section.add "X-Amz-Date", valid_607051
  var valid_607052 = header.getOrDefault("X-Amz-Credential")
  valid_607052 = validateParameter(valid_607052, JString, required = false,
                                 default = nil)
  if valid_607052 != nil:
    section.add "X-Amz-Credential", valid_607052
  var valid_607053 = header.getOrDefault("X-Amz-Security-Token")
  valid_607053 = validateParameter(valid_607053, JString, required = false,
                                 default = nil)
  if valid_607053 != nil:
    section.add "X-Amz-Security-Token", valid_607053
  var valid_607054 = header.getOrDefault("X-Amz-Algorithm")
  valid_607054 = validateParameter(valid_607054, JString, required = false,
                                 default = nil)
  if valid_607054 != nil:
    section.add "X-Amz-Algorithm", valid_607054
  var valid_607055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607055 = validateParameter(valid_607055, JString, required = false,
                                 default = nil)
  if valid_607055 != nil:
    section.add "X-Amz-SignedHeaders", valid_607055
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  section = newJObject()
  var valid_607056 = formData.getOrDefault("MaxRecords")
  valid_607056 = validateParameter(valid_607056, JInt, required = false, default = nil)
  if valid_607056 != nil:
    section.add "MaxRecords", valid_607056
  var valid_607057 = formData.getOrDefault("DBParameterGroupName")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "DBParameterGroupName", valid_607057
  var valid_607058 = formData.getOrDefault("Marker")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "Marker", valid_607058
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607059: Call_PostDescribeDBParameterGroups_607044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607059.validator(path, query, header, formData, body)
  let scheme = call_607059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607059.url(scheme.get, call_607059.host, call_607059.base,
                         call_607059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607059, url, valid)

proc call*(call_607060: Call_PostDescribeDBParameterGroups_607044;
          MaxRecords: int = 0; DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607061 = newJObject()
  var formData_607062 = newJObject()
  add(formData_607062, "MaxRecords", newJInt(MaxRecords))
  add(formData_607062, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_607062, "Marker", newJString(Marker))
  add(query_607061, "Action", newJString(Action))
  add(query_607061, "Version", newJString(Version))
  result = call_607060.call(nil, query_607061, nil, formData_607062, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_607044(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_607045, base: "/",
    url: url_PostDescribeDBParameterGroups_607046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_607026 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBParameterGroups_607028(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBParameterGroups_607027(path: JsonNode; query: JsonNode;
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
  var valid_607029 = query.getOrDefault("Marker")
  valid_607029 = validateParameter(valid_607029, JString, required = false,
                                 default = nil)
  if valid_607029 != nil:
    section.add "Marker", valid_607029
  var valid_607030 = query.getOrDefault("DBParameterGroupName")
  valid_607030 = validateParameter(valid_607030, JString, required = false,
                                 default = nil)
  if valid_607030 != nil:
    section.add "DBParameterGroupName", valid_607030
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607031 = query.getOrDefault("Action")
  valid_607031 = validateParameter(valid_607031, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_607031 != nil:
    section.add "Action", valid_607031
  var valid_607032 = query.getOrDefault("Version")
  valid_607032 = validateParameter(valid_607032, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607032 != nil:
    section.add "Version", valid_607032
  var valid_607033 = query.getOrDefault("MaxRecords")
  valid_607033 = validateParameter(valid_607033, JInt, required = false, default = nil)
  if valid_607033 != nil:
    section.add "MaxRecords", valid_607033
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607034 = header.getOrDefault("X-Amz-Signature")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-Signature", valid_607034
  var valid_607035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607035 = validateParameter(valid_607035, JString, required = false,
                                 default = nil)
  if valid_607035 != nil:
    section.add "X-Amz-Content-Sha256", valid_607035
  var valid_607036 = header.getOrDefault("X-Amz-Date")
  valid_607036 = validateParameter(valid_607036, JString, required = false,
                                 default = nil)
  if valid_607036 != nil:
    section.add "X-Amz-Date", valid_607036
  var valid_607037 = header.getOrDefault("X-Amz-Credential")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "X-Amz-Credential", valid_607037
  var valid_607038 = header.getOrDefault("X-Amz-Security-Token")
  valid_607038 = validateParameter(valid_607038, JString, required = false,
                                 default = nil)
  if valid_607038 != nil:
    section.add "X-Amz-Security-Token", valid_607038
  var valid_607039 = header.getOrDefault("X-Amz-Algorithm")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "X-Amz-Algorithm", valid_607039
  var valid_607040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "X-Amz-SignedHeaders", valid_607040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607041: Call_GetDescribeDBParameterGroups_607026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607041.validator(path, query, header, formData, body)
  let scheme = call_607041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607041.url(scheme.get, call_607041.host, call_607041.base,
                         call_607041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607041, url, valid)

proc call*(call_607042: Call_GetDescribeDBParameterGroups_607026;
          Marker: string = ""; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameterGroups
  ##   Marker: string
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_607043 = newJObject()
  add(query_607043, "Marker", newJString(Marker))
  add(query_607043, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607043, "Action", newJString(Action))
  add(query_607043, "Version", newJString(Version))
  add(query_607043, "MaxRecords", newJInt(MaxRecords))
  result = call_607042.call(nil, query_607043, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_607026(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_607027, base: "/",
    url: url_GetDescribeDBParameterGroups_607028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_607082 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBParameters_607084(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameters_607083(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607085 = query.getOrDefault("Action")
  valid_607085 = validateParameter(valid_607085, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_607085 != nil:
    section.add "Action", valid_607085
  var valid_607086 = query.getOrDefault("Version")
  valid_607086 = validateParameter(valid_607086, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607086 != nil:
    section.add "Version", valid_607086
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607087 = header.getOrDefault("X-Amz-Signature")
  valid_607087 = validateParameter(valid_607087, JString, required = false,
                                 default = nil)
  if valid_607087 != nil:
    section.add "X-Amz-Signature", valid_607087
  var valid_607088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607088 = validateParameter(valid_607088, JString, required = false,
                                 default = nil)
  if valid_607088 != nil:
    section.add "X-Amz-Content-Sha256", valid_607088
  var valid_607089 = header.getOrDefault("X-Amz-Date")
  valid_607089 = validateParameter(valid_607089, JString, required = false,
                                 default = nil)
  if valid_607089 != nil:
    section.add "X-Amz-Date", valid_607089
  var valid_607090 = header.getOrDefault("X-Amz-Credential")
  valid_607090 = validateParameter(valid_607090, JString, required = false,
                                 default = nil)
  if valid_607090 != nil:
    section.add "X-Amz-Credential", valid_607090
  var valid_607091 = header.getOrDefault("X-Amz-Security-Token")
  valid_607091 = validateParameter(valid_607091, JString, required = false,
                                 default = nil)
  if valid_607091 != nil:
    section.add "X-Amz-Security-Token", valid_607091
  var valid_607092 = header.getOrDefault("X-Amz-Algorithm")
  valid_607092 = validateParameter(valid_607092, JString, required = false,
                                 default = nil)
  if valid_607092 != nil:
    section.add "X-Amz-Algorithm", valid_607092
  var valid_607093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607093 = validateParameter(valid_607093, JString, required = false,
                                 default = nil)
  if valid_607093 != nil:
    section.add "X-Amz-SignedHeaders", valid_607093
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  section = newJObject()
  var valid_607094 = formData.getOrDefault("Source")
  valid_607094 = validateParameter(valid_607094, JString, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "Source", valid_607094
  var valid_607095 = formData.getOrDefault("MaxRecords")
  valid_607095 = validateParameter(valid_607095, JInt, required = false, default = nil)
  if valid_607095 != nil:
    section.add "MaxRecords", valid_607095
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_607096 = formData.getOrDefault("DBParameterGroupName")
  valid_607096 = validateParameter(valid_607096, JString, required = true,
                                 default = nil)
  if valid_607096 != nil:
    section.add "DBParameterGroupName", valid_607096
  var valid_607097 = formData.getOrDefault("Marker")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "Marker", valid_607097
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607098: Call_PostDescribeDBParameters_607082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607098.validator(path, query, header, formData, body)
  let scheme = call_607098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607098.url(scheme.get, call_607098.host, call_607098.base,
                         call_607098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607098, url, valid)

proc call*(call_607099: Call_PostDescribeDBParameters_607082;
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
  var query_607100 = newJObject()
  var formData_607101 = newJObject()
  add(formData_607101, "Source", newJString(Source))
  add(formData_607101, "MaxRecords", newJInt(MaxRecords))
  add(formData_607101, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_607101, "Marker", newJString(Marker))
  add(query_607100, "Action", newJString(Action))
  add(query_607100, "Version", newJString(Version))
  result = call_607099.call(nil, query_607100, nil, formData_607101, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_607082(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_607083, base: "/",
    url: url_PostDescribeDBParameters_607084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_607063 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBParameters_607065(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBParameters_607064(path: JsonNode; query: JsonNode;
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
  var valid_607066 = query.getOrDefault("Marker")
  valid_607066 = validateParameter(valid_607066, JString, required = false,
                                 default = nil)
  if valid_607066 != nil:
    section.add "Marker", valid_607066
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_607067 = query.getOrDefault("DBParameterGroupName")
  valid_607067 = validateParameter(valid_607067, JString, required = true,
                                 default = nil)
  if valid_607067 != nil:
    section.add "DBParameterGroupName", valid_607067
  var valid_607068 = query.getOrDefault("Source")
  valid_607068 = validateParameter(valid_607068, JString, required = false,
                                 default = nil)
  if valid_607068 != nil:
    section.add "Source", valid_607068
  var valid_607069 = query.getOrDefault("Action")
  valid_607069 = validateParameter(valid_607069, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_607069 != nil:
    section.add "Action", valid_607069
  var valid_607070 = query.getOrDefault("Version")
  valid_607070 = validateParameter(valid_607070, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607070 != nil:
    section.add "Version", valid_607070
  var valid_607071 = query.getOrDefault("MaxRecords")
  valid_607071 = validateParameter(valid_607071, JInt, required = false, default = nil)
  if valid_607071 != nil:
    section.add "MaxRecords", valid_607071
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607072 = header.getOrDefault("X-Amz-Signature")
  valid_607072 = validateParameter(valid_607072, JString, required = false,
                                 default = nil)
  if valid_607072 != nil:
    section.add "X-Amz-Signature", valid_607072
  var valid_607073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607073 = validateParameter(valid_607073, JString, required = false,
                                 default = nil)
  if valid_607073 != nil:
    section.add "X-Amz-Content-Sha256", valid_607073
  var valid_607074 = header.getOrDefault("X-Amz-Date")
  valid_607074 = validateParameter(valid_607074, JString, required = false,
                                 default = nil)
  if valid_607074 != nil:
    section.add "X-Amz-Date", valid_607074
  var valid_607075 = header.getOrDefault("X-Amz-Credential")
  valid_607075 = validateParameter(valid_607075, JString, required = false,
                                 default = nil)
  if valid_607075 != nil:
    section.add "X-Amz-Credential", valid_607075
  var valid_607076 = header.getOrDefault("X-Amz-Security-Token")
  valid_607076 = validateParameter(valid_607076, JString, required = false,
                                 default = nil)
  if valid_607076 != nil:
    section.add "X-Amz-Security-Token", valid_607076
  var valid_607077 = header.getOrDefault("X-Amz-Algorithm")
  valid_607077 = validateParameter(valid_607077, JString, required = false,
                                 default = nil)
  if valid_607077 != nil:
    section.add "X-Amz-Algorithm", valid_607077
  var valid_607078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "X-Amz-SignedHeaders", valid_607078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607079: Call_GetDescribeDBParameters_607063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607079.validator(path, query, header, formData, body)
  let scheme = call_607079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607079.url(scheme.get, call_607079.host, call_607079.base,
                         call_607079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607079, url, valid)

proc call*(call_607080: Call_GetDescribeDBParameters_607063;
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
  var query_607081 = newJObject()
  add(query_607081, "Marker", newJString(Marker))
  add(query_607081, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607081, "Source", newJString(Source))
  add(query_607081, "Action", newJString(Action))
  add(query_607081, "Version", newJString(Version))
  add(query_607081, "MaxRecords", newJInt(MaxRecords))
  result = call_607080.call(nil, query_607081, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_607063(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_607064, base: "/",
    url: url_GetDescribeDBParameters_607065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_607120 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBSecurityGroups_607122(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSecurityGroups_607121(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607123 = query.getOrDefault("Action")
  valid_607123 = validateParameter(valid_607123, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_607123 != nil:
    section.add "Action", valid_607123
  var valid_607124 = query.getOrDefault("Version")
  valid_607124 = validateParameter(valid_607124, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607124 != nil:
    section.add "Version", valid_607124
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607125 = header.getOrDefault("X-Amz-Signature")
  valid_607125 = validateParameter(valid_607125, JString, required = false,
                                 default = nil)
  if valid_607125 != nil:
    section.add "X-Amz-Signature", valid_607125
  var valid_607126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607126 = validateParameter(valid_607126, JString, required = false,
                                 default = nil)
  if valid_607126 != nil:
    section.add "X-Amz-Content-Sha256", valid_607126
  var valid_607127 = header.getOrDefault("X-Amz-Date")
  valid_607127 = validateParameter(valid_607127, JString, required = false,
                                 default = nil)
  if valid_607127 != nil:
    section.add "X-Amz-Date", valid_607127
  var valid_607128 = header.getOrDefault("X-Amz-Credential")
  valid_607128 = validateParameter(valid_607128, JString, required = false,
                                 default = nil)
  if valid_607128 != nil:
    section.add "X-Amz-Credential", valid_607128
  var valid_607129 = header.getOrDefault("X-Amz-Security-Token")
  valid_607129 = validateParameter(valid_607129, JString, required = false,
                                 default = nil)
  if valid_607129 != nil:
    section.add "X-Amz-Security-Token", valid_607129
  var valid_607130 = header.getOrDefault("X-Amz-Algorithm")
  valid_607130 = validateParameter(valid_607130, JString, required = false,
                                 default = nil)
  if valid_607130 != nil:
    section.add "X-Amz-Algorithm", valid_607130
  var valid_607131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "X-Amz-SignedHeaders", valid_607131
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  section = newJObject()
  var valid_607132 = formData.getOrDefault("DBSecurityGroupName")
  valid_607132 = validateParameter(valid_607132, JString, required = false,
                                 default = nil)
  if valid_607132 != nil:
    section.add "DBSecurityGroupName", valid_607132
  var valid_607133 = formData.getOrDefault("MaxRecords")
  valid_607133 = validateParameter(valid_607133, JInt, required = false, default = nil)
  if valid_607133 != nil:
    section.add "MaxRecords", valid_607133
  var valid_607134 = formData.getOrDefault("Marker")
  valid_607134 = validateParameter(valid_607134, JString, required = false,
                                 default = nil)
  if valid_607134 != nil:
    section.add "Marker", valid_607134
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607135: Call_PostDescribeDBSecurityGroups_607120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607135.validator(path, query, header, formData, body)
  let scheme = call_607135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607135.url(scheme.get, call_607135.host, call_607135.base,
                         call_607135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607135, url, valid)

proc call*(call_607136: Call_PostDescribeDBSecurityGroups_607120;
          DBSecurityGroupName: string = ""; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607137 = newJObject()
  var formData_607138 = newJObject()
  add(formData_607138, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_607138, "MaxRecords", newJInt(MaxRecords))
  add(formData_607138, "Marker", newJString(Marker))
  add(query_607137, "Action", newJString(Action))
  add(query_607137, "Version", newJString(Version))
  result = call_607136.call(nil, query_607137, nil, formData_607138, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_607120(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_607121, base: "/",
    url: url_PostDescribeDBSecurityGroups_607122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_607102 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBSecurityGroups_607104(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSecurityGroups_607103(path: JsonNode; query: JsonNode;
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
  var valid_607105 = query.getOrDefault("Marker")
  valid_607105 = validateParameter(valid_607105, JString, required = false,
                                 default = nil)
  if valid_607105 != nil:
    section.add "Marker", valid_607105
  var valid_607106 = query.getOrDefault("DBSecurityGroupName")
  valid_607106 = validateParameter(valid_607106, JString, required = false,
                                 default = nil)
  if valid_607106 != nil:
    section.add "DBSecurityGroupName", valid_607106
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607107 = query.getOrDefault("Action")
  valid_607107 = validateParameter(valid_607107, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_607107 != nil:
    section.add "Action", valid_607107
  var valid_607108 = query.getOrDefault("Version")
  valid_607108 = validateParameter(valid_607108, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607108 != nil:
    section.add "Version", valid_607108
  var valid_607109 = query.getOrDefault("MaxRecords")
  valid_607109 = validateParameter(valid_607109, JInt, required = false, default = nil)
  if valid_607109 != nil:
    section.add "MaxRecords", valid_607109
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607110 = header.getOrDefault("X-Amz-Signature")
  valid_607110 = validateParameter(valid_607110, JString, required = false,
                                 default = nil)
  if valid_607110 != nil:
    section.add "X-Amz-Signature", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-Content-Sha256", valid_607111
  var valid_607112 = header.getOrDefault("X-Amz-Date")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "X-Amz-Date", valid_607112
  var valid_607113 = header.getOrDefault("X-Amz-Credential")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-Credential", valid_607113
  var valid_607114 = header.getOrDefault("X-Amz-Security-Token")
  valid_607114 = validateParameter(valid_607114, JString, required = false,
                                 default = nil)
  if valid_607114 != nil:
    section.add "X-Amz-Security-Token", valid_607114
  var valid_607115 = header.getOrDefault("X-Amz-Algorithm")
  valid_607115 = validateParameter(valid_607115, JString, required = false,
                                 default = nil)
  if valid_607115 != nil:
    section.add "X-Amz-Algorithm", valid_607115
  var valid_607116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607116 = validateParameter(valid_607116, JString, required = false,
                                 default = nil)
  if valid_607116 != nil:
    section.add "X-Amz-SignedHeaders", valid_607116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607117: Call_GetDescribeDBSecurityGroups_607102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607117.validator(path, query, header, formData, body)
  let scheme = call_607117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607117.url(scheme.get, call_607117.host, call_607117.base,
                         call_607117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607117, url, valid)

proc call*(call_607118: Call_GetDescribeDBSecurityGroups_607102;
          Marker: string = ""; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Marker: string
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_607119 = newJObject()
  add(query_607119, "Marker", newJString(Marker))
  add(query_607119, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_607119, "Action", newJString(Action))
  add(query_607119, "Version", newJString(Version))
  add(query_607119, "MaxRecords", newJInt(MaxRecords))
  result = call_607118.call(nil, query_607119, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_607102(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_607103, base: "/",
    url: url_GetDescribeDBSecurityGroups_607104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_607159 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBSnapshots_607161(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBSnapshots_607160(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607162 = query.getOrDefault("Action")
  valid_607162 = validateParameter(valid_607162, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_607162 != nil:
    section.add "Action", valid_607162
  var valid_607163 = query.getOrDefault("Version")
  valid_607163 = validateParameter(valid_607163, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607163 != nil:
    section.add "Version", valid_607163
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607164 = header.getOrDefault("X-Amz-Signature")
  valid_607164 = validateParameter(valid_607164, JString, required = false,
                                 default = nil)
  if valid_607164 != nil:
    section.add "X-Amz-Signature", valid_607164
  var valid_607165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607165 = validateParameter(valid_607165, JString, required = false,
                                 default = nil)
  if valid_607165 != nil:
    section.add "X-Amz-Content-Sha256", valid_607165
  var valid_607166 = header.getOrDefault("X-Amz-Date")
  valid_607166 = validateParameter(valid_607166, JString, required = false,
                                 default = nil)
  if valid_607166 != nil:
    section.add "X-Amz-Date", valid_607166
  var valid_607167 = header.getOrDefault("X-Amz-Credential")
  valid_607167 = validateParameter(valid_607167, JString, required = false,
                                 default = nil)
  if valid_607167 != nil:
    section.add "X-Amz-Credential", valid_607167
  var valid_607168 = header.getOrDefault("X-Amz-Security-Token")
  valid_607168 = validateParameter(valid_607168, JString, required = false,
                                 default = nil)
  if valid_607168 != nil:
    section.add "X-Amz-Security-Token", valid_607168
  var valid_607169 = header.getOrDefault("X-Amz-Algorithm")
  valid_607169 = validateParameter(valid_607169, JString, required = false,
                                 default = nil)
  if valid_607169 != nil:
    section.add "X-Amz-Algorithm", valid_607169
  var valid_607170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607170 = validateParameter(valid_607170, JString, required = false,
                                 default = nil)
  if valid_607170 != nil:
    section.add "X-Amz-SignedHeaders", valid_607170
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  section = newJObject()
  var valid_607171 = formData.getOrDefault("SnapshotType")
  valid_607171 = validateParameter(valid_607171, JString, required = false,
                                 default = nil)
  if valid_607171 != nil:
    section.add "SnapshotType", valid_607171
  var valid_607172 = formData.getOrDefault("MaxRecords")
  valid_607172 = validateParameter(valid_607172, JInt, required = false, default = nil)
  if valid_607172 != nil:
    section.add "MaxRecords", valid_607172
  var valid_607173 = formData.getOrDefault("Marker")
  valid_607173 = validateParameter(valid_607173, JString, required = false,
                                 default = nil)
  if valid_607173 != nil:
    section.add "Marker", valid_607173
  var valid_607174 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607174 = validateParameter(valid_607174, JString, required = false,
                                 default = nil)
  if valid_607174 != nil:
    section.add "DBInstanceIdentifier", valid_607174
  var valid_607175 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_607175 = validateParameter(valid_607175, JString, required = false,
                                 default = nil)
  if valid_607175 != nil:
    section.add "DBSnapshotIdentifier", valid_607175
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607176: Call_PostDescribeDBSnapshots_607159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607176.validator(path, query, header, formData, body)
  let scheme = call_607176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607176.url(scheme.get, call_607176.host, call_607176.base,
                         call_607176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607176, url, valid)

proc call*(call_607177: Call_PostDescribeDBSnapshots_607159;
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
  var query_607178 = newJObject()
  var formData_607179 = newJObject()
  add(formData_607179, "SnapshotType", newJString(SnapshotType))
  add(formData_607179, "MaxRecords", newJInt(MaxRecords))
  add(formData_607179, "Marker", newJString(Marker))
  add(formData_607179, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_607179, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_607178, "Action", newJString(Action))
  add(query_607178, "Version", newJString(Version))
  result = call_607177.call(nil, query_607178, nil, formData_607179, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_607159(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_607160, base: "/",
    url: url_PostDescribeDBSnapshots_607161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_607139 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBSnapshots_607141(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBSnapshots_607140(path: JsonNode; query: JsonNode;
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
  var valid_607142 = query.getOrDefault("Marker")
  valid_607142 = validateParameter(valid_607142, JString, required = false,
                                 default = nil)
  if valid_607142 != nil:
    section.add "Marker", valid_607142
  var valid_607143 = query.getOrDefault("DBInstanceIdentifier")
  valid_607143 = validateParameter(valid_607143, JString, required = false,
                                 default = nil)
  if valid_607143 != nil:
    section.add "DBInstanceIdentifier", valid_607143
  var valid_607144 = query.getOrDefault("DBSnapshotIdentifier")
  valid_607144 = validateParameter(valid_607144, JString, required = false,
                                 default = nil)
  if valid_607144 != nil:
    section.add "DBSnapshotIdentifier", valid_607144
  var valid_607145 = query.getOrDefault("SnapshotType")
  valid_607145 = validateParameter(valid_607145, JString, required = false,
                                 default = nil)
  if valid_607145 != nil:
    section.add "SnapshotType", valid_607145
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607146 = query.getOrDefault("Action")
  valid_607146 = validateParameter(valid_607146, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_607146 != nil:
    section.add "Action", valid_607146
  var valid_607147 = query.getOrDefault("Version")
  valid_607147 = validateParameter(valid_607147, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607147 != nil:
    section.add "Version", valid_607147
  var valid_607148 = query.getOrDefault("MaxRecords")
  valid_607148 = validateParameter(valid_607148, JInt, required = false, default = nil)
  if valid_607148 != nil:
    section.add "MaxRecords", valid_607148
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607149 = header.getOrDefault("X-Amz-Signature")
  valid_607149 = validateParameter(valid_607149, JString, required = false,
                                 default = nil)
  if valid_607149 != nil:
    section.add "X-Amz-Signature", valid_607149
  var valid_607150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607150 = validateParameter(valid_607150, JString, required = false,
                                 default = nil)
  if valid_607150 != nil:
    section.add "X-Amz-Content-Sha256", valid_607150
  var valid_607151 = header.getOrDefault("X-Amz-Date")
  valid_607151 = validateParameter(valid_607151, JString, required = false,
                                 default = nil)
  if valid_607151 != nil:
    section.add "X-Amz-Date", valid_607151
  var valid_607152 = header.getOrDefault("X-Amz-Credential")
  valid_607152 = validateParameter(valid_607152, JString, required = false,
                                 default = nil)
  if valid_607152 != nil:
    section.add "X-Amz-Credential", valid_607152
  var valid_607153 = header.getOrDefault("X-Amz-Security-Token")
  valid_607153 = validateParameter(valid_607153, JString, required = false,
                                 default = nil)
  if valid_607153 != nil:
    section.add "X-Amz-Security-Token", valid_607153
  var valid_607154 = header.getOrDefault("X-Amz-Algorithm")
  valid_607154 = validateParameter(valid_607154, JString, required = false,
                                 default = nil)
  if valid_607154 != nil:
    section.add "X-Amz-Algorithm", valid_607154
  var valid_607155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607155 = validateParameter(valid_607155, JString, required = false,
                                 default = nil)
  if valid_607155 != nil:
    section.add "X-Amz-SignedHeaders", valid_607155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607156: Call_GetDescribeDBSnapshots_607139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607156.validator(path, query, header, formData, body)
  let scheme = call_607156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607156.url(scheme.get, call_607156.host, call_607156.base,
                         call_607156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607156, url, valid)

proc call*(call_607157: Call_GetDescribeDBSnapshots_607139; Marker: string = "";
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
  var query_607158 = newJObject()
  add(query_607158, "Marker", newJString(Marker))
  add(query_607158, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607158, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_607158, "SnapshotType", newJString(SnapshotType))
  add(query_607158, "Action", newJString(Action))
  add(query_607158, "Version", newJString(Version))
  add(query_607158, "MaxRecords", newJInt(MaxRecords))
  result = call_607157.call(nil, query_607158, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_607139(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_607140, base: "/",
    url: url_GetDescribeDBSnapshots_607141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_607198 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBSubnetGroups_607200(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSubnetGroups_607199(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607201 = query.getOrDefault("Action")
  valid_607201 = validateParameter(valid_607201, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_607201 != nil:
    section.add "Action", valid_607201
  var valid_607202 = query.getOrDefault("Version")
  valid_607202 = validateParameter(valid_607202, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607202 != nil:
    section.add "Version", valid_607202
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607203 = header.getOrDefault("X-Amz-Signature")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-Signature", valid_607203
  var valid_607204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607204 = validateParameter(valid_607204, JString, required = false,
                                 default = nil)
  if valid_607204 != nil:
    section.add "X-Amz-Content-Sha256", valid_607204
  var valid_607205 = header.getOrDefault("X-Amz-Date")
  valid_607205 = validateParameter(valid_607205, JString, required = false,
                                 default = nil)
  if valid_607205 != nil:
    section.add "X-Amz-Date", valid_607205
  var valid_607206 = header.getOrDefault("X-Amz-Credential")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "X-Amz-Credential", valid_607206
  var valid_607207 = header.getOrDefault("X-Amz-Security-Token")
  valid_607207 = validateParameter(valid_607207, JString, required = false,
                                 default = nil)
  if valid_607207 != nil:
    section.add "X-Amz-Security-Token", valid_607207
  var valid_607208 = header.getOrDefault("X-Amz-Algorithm")
  valid_607208 = validateParameter(valid_607208, JString, required = false,
                                 default = nil)
  if valid_607208 != nil:
    section.add "X-Amz-Algorithm", valid_607208
  var valid_607209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607209 = validateParameter(valid_607209, JString, required = false,
                                 default = nil)
  if valid_607209 != nil:
    section.add "X-Amz-SignedHeaders", valid_607209
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  section = newJObject()
  var valid_607210 = formData.getOrDefault("MaxRecords")
  valid_607210 = validateParameter(valid_607210, JInt, required = false, default = nil)
  if valid_607210 != nil:
    section.add "MaxRecords", valid_607210
  var valid_607211 = formData.getOrDefault("Marker")
  valid_607211 = validateParameter(valid_607211, JString, required = false,
                                 default = nil)
  if valid_607211 != nil:
    section.add "Marker", valid_607211
  var valid_607212 = formData.getOrDefault("DBSubnetGroupName")
  valid_607212 = validateParameter(valid_607212, JString, required = false,
                                 default = nil)
  if valid_607212 != nil:
    section.add "DBSubnetGroupName", valid_607212
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607213: Call_PostDescribeDBSubnetGroups_607198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607213.validator(path, query, header, formData, body)
  let scheme = call_607213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607213.url(scheme.get, call_607213.host, call_607213.base,
                         call_607213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607213, url, valid)

proc call*(call_607214: Call_PostDescribeDBSubnetGroups_607198;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_607215 = newJObject()
  var formData_607216 = newJObject()
  add(formData_607216, "MaxRecords", newJInt(MaxRecords))
  add(formData_607216, "Marker", newJString(Marker))
  add(query_607215, "Action", newJString(Action))
  add(formData_607216, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607215, "Version", newJString(Version))
  result = call_607214.call(nil, query_607215, nil, formData_607216, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_607198(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_607199, base: "/",
    url: url_PostDescribeDBSubnetGroups_607200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_607180 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBSubnetGroups_607182(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSubnetGroups_607181(path: JsonNode; query: JsonNode;
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
  var valid_607183 = query.getOrDefault("Marker")
  valid_607183 = validateParameter(valid_607183, JString, required = false,
                                 default = nil)
  if valid_607183 != nil:
    section.add "Marker", valid_607183
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607184 = query.getOrDefault("Action")
  valid_607184 = validateParameter(valid_607184, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_607184 != nil:
    section.add "Action", valid_607184
  var valid_607185 = query.getOrDefault("DBSubnetGroupName")
  valid_607185 = validateParameter(valid_607185, JString, required = false,
                                 default = nil)
  if valid_607185 != nil:
    section.add "DBSubnetGroupName", valid_607185
  var valid_607186 = query.getOrDefault("Version")
  valid_607186 = validateParameter(valid_607186, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607186 != nil:
    section.add "Version", valid_607186
  var valid_607187 = query.getOrDefault("MaxRecords")
  valid_607187 = validateParameter(valid_607187, JInt, required = false, default = nil)
  if valid_607187 != nil:
    section.add "MaxRecords", valid_607187
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607188 = header.getOrDefault("X-Amz-Signature")
  valid_607188 = validateParameter(valid_607188, JString, required = false,
                                 default = nil)
  if valid_607188 != nil:
    section.add "X-Amz-Signature", valid_607188
  var valid_607189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607189 = validateParameter(valid_607189, JString, required = false,
                                 default = nil)
  if valid_607189 != nil:
    section.add "X-Amz-Content-Sha256", valid_607189
  var valid_607190 = header.getOrDefault("X-Amz-Date")
  valid_607190 = validateParameter(valid_607190, JString, required = false,
                                 default = nil)
  if valid_607190 != nil:
    section.add "X-Amz-Date", valid_607190
  var valid_607191 = header.getOrDefault("X-Amz-Credential")
  valid_607191 = validateParameter(valid_607191, JString, required = false,
                                 default = nil)
  if valid_607191 != nil:
    section.add "X-Amz-Credential", valid_607191
  var valid_607192 = header.getOrDefault("X-Amz-Security-Token")
  valid_607192 = validateParameter(valid_607192, JString, required = false,
                                 default = nil)
  if valid_607192 != nil:
    section.add "X-Amz-Security-Token", valid_607192
  var valid_607193 = header.getOrDefault("X-Amz-Algorithm")
  valid_607193 = validateParameter(valid_607193, JString, required = false,
                                 default = nil)
  if valid_607193 != nil:
    section.add "X-Amz-Algorithm", valid_607193
  var valid_607194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607194 = validateParameter(valid_607194, JString, required = false,
                                 default = nil)
  if valid_607194 != nil:
    section.add "X-Amz-SignedHeaders", valid_607194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607195: Call_GetDescribeDBSubnetGroups_607180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607195.validator(path, query, header, formData, body)
  let scheme = call_607195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607195.url(scheme.get, call_607195.host, call_607195.base,
                         call_607195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607195, url, valid)

proc call*(call_607196: Call_GetDescribeDBSubnetGroups_607180; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_607197 = newJObject()
  add(query_607197, "Marker", newJString(Marker))
  add(query_607197, "Action", newJString(Action))
  add(query_607197, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607197, "Version", newJString(Version))
  add(query_607197, "MaxRecords", newJInt(MaxRecords))
  result = call_607196.call(nil, query_607197, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_607180(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_607181, base: "/",
    url: url_GetDescribeDBSubnetGroups_607182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_607235 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEngineDefaultParameters_607237(protocol: Scheme; host: string;
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

proc validate_PostDescribeEngineDefaultParameters_607236(path: JsonNode;
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
  var valid_607238 = query.getOrDefault("Action")
  valid_607238 = validateParameter(valid_607238, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_607238 != nil:
    section.add "Action", valid_607238
  var valid_607239 = query.getOrDefault("Version")
  valid_607239 = validateParameter(valid_607239, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607239 != nil:
    section.add "Version", valid_607239
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607240 = header.getOrDefault("X-Amz-Signature")
  valid_607240 = validateParameter(valid_607240, JString, required = false,
                                 default = nil)
  if valid_607240 != nil:
    section.add "X-Amz-Signature", valid_607240
  var valid_607241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607241 = validateParameter(valid_607241, JString, required = false,
                                 default = nil)
  if valid_607241 != nil:
    section.add "X-Amz-Content-Sha256", valid_607241
  var valid_607242 = header.getOrDefault("X-Amz-Date")
  valid_607242 = validateParameter(valid_607242, JString, required = false,
                                 default = nil)
  if valid_607242 != nil:
    section.add "X-Amz-Date", valid_607242
  var valid_607243 = header.getOrDefault("X-Amz-Credential")
  valid_607243 = validateParameter(valid_607243, JString, required = false,
                                 default = nil)
  if valid_607243 != nil:
    section.add "X-Amz-Credential", valid_607243
  var valid_607244 = header.getOrDefault("X-Amz-Security-Token")
  valid_607244 = validateParameter(valid_607244, JString, required = false,
                                 default = nil)
  if valid_607244 != nil:
    section.add "X-Amz-Security-Token", valid_607244
  var valid_607245 = header.getOrDefault("X-Amz-Algorithm")
  valid_607245 = validateParameter(valid_607245, JString, required = false,
                                 default = nil)
  if valid_607245 != nil:
    section.add "X-Amz-Algorithm", valid_607245
  var valid_607246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607246 = validateParameter(valid_607246, JString, required = false,
                                 default = nil)
  if valid_607246 != nil:
    section.add "X-Amz-SignedHeaders", valid_607246
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_607247 = formData.getOrDefault("MaxRecords")
  valid_607247 = validateParameter(valid_607247, JInt, required = false, default = nil)
  if valid_607247 != nil:
    section.add "MaxRecords", valid_607247
  var valid_607248 = formData.getOrDefault("Marker")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "Marker", valid_607248
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_607249 = formData.getOrDefault("DBParameterGroupFamily")
  valid_607249 = validateParameter(valid_607249, JString, required = true,
                                 default = nil)
  if valid_607249 != nil:
    section.add "DBParameterGroupFamily", valid_607249
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607250: Call_PostDescribeEngineDefaultParameters_607235;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607250.validator(path, query, header, formData, body)
  let scheme = call_607250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607250.url(scheme.get, call_607250.host, call_607250.base,
                         call_607250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607250, url, valid)

proc call*(call_607251: Call_PostDescribeEngineDefaultParameters_607235;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_607252 = newJObject()
  var formData_607253 = newJObject()
  add(formData_607253, "MaxRecords", newJInt(MaxRecords))
  add(formData_607253, "Marker", newJString(Marker))
  add(query_607252, "Action", newJString(Action))
  add(query_607252, "Version", newJString(Version))
  add(formData_607253, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_607251.call(nil, query_607252, nil, formData_607253, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_607235(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_607236, base: "/",
    url: url_PostDescribeEngineDefaultParameters_607237,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_607217 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEngineDefaultParameters_607219(protocol: Scheme; host: string;
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

proc validate_GetDescribeEngineDefaultParameters_607218(path: JsonNode;
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
  var valid_607220 = query.getOrDefault("Marker")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "Marker", valid_607220
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_607221 = query.getOrDefault("DBParameterGroupFamily")
  valid_607221 = validateParameter(valid_607221, JString, required = true,
                                 default = nil)
  if valid_607221 != nil:
    section.add "DBParameterGroupFamily", valid_607221
  var valid_607222 = query.getOrDefault("Action")
  valid_607222 = validateParameter(valid_607222, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_607222 != nil:
    section.add "Action", valid_607222
  var valid_607223 = query.getOrDefault("Version")
  valid_607223 = validateParameter(valid_607223, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607223 != nil:
    section.add "Version", valid_607223
  var valid_607224 = query.getOrDefault("MaxRecords")
  valid_607224 = validateParameter(valid_607224, JInt, required = false, default = nil)
  if valid_607224 != nil:
    section.add "MaxRecords", valid_607224
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607225 = header.getOrDefault("X-Amz-Signature")
  valid_607225 = validateParameter(valid_607225, JString, required = false,
                                 default = nil)
  if valid_607225 != nil:
    section.add "X-Amz-Signature", valid_607225
  var valid_607226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607226 = validateParameter(valid_607226, JString, required = false,
                                 default = nil)
  if valid_607226 != nil:
    section.add "X-Amz-Content-Sha256", valid_607226
  var valid_607227 = header.getOrDefault("X-Amz-Date")
  valid_607227 = validateParameter(valid_607227, JString, required = false,
                                 default = nil)
  if valid_607227 != nil:
    section.add "X-Amz-Date", valid_607227
  var valid_607228 = header.getOrDefault("X-Amz-Credential")
  valid_607228 = validateParameter(valid_607228, JString, required = false,
                                 default = nil)
  if valid_607228 != nil:
    section.add "X-Amz-Credential", valid_607228
  var valid_607229 = header.getOrDefault("X-Amz-Security-Token")
  valid_607229 = validateParameter(valid_607229, JString, required = false,
                                 default = nil)
  if valid_607229 != nil:
    section.add "X-Amz-Security-Token", valid_607229
  var valid_607230 = header.getOrDefault("X-Amz-Algorithm")
  valid_607230 = validateParameter(valid_607230, JString, required = false,
                                 default = nil)
  if valid_607230 != nil:
    section.add "X-Amz-Algorithm", valid_607230
  var valid_607231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607231 = validateParameter(valid_607231, JString, required = false,
                                 default = nil)
  if valid_607231 != nil:
    section.add "X-Amz-SignedHeaders", valid_607231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607232: Call_GetDescribeEngineDefaultParameters_607217;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607232.validator(path, query, header, formData, body)
  let scheme = call_607232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607232.url(scheme.get, call_607232.host, call_607232.base,
                         call_607232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607232, url, valid)

proc call*(call_607233: Call_GetDescribeEngineDefaultParameters_607217;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_607234 = newJObject()
  add(query_607234, "Marker", newJString(Marker))
  add(query_607234, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_607234, "Action", newJString(Action))
  add(query_607234, "Version", newJString(Version))
  add(query_607234, "MaxRecords", newJInt(MaxRecords))
  result = call_607233.call(nil, query_607234, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_607217(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_607218, base: "/",
    url: url_GetDescribeEngineDefaultParameters_607219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_607270 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEventCategories_607272(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventCategories_607271(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607273 = query.getOrDefault("Action")
  valid_607273 = validateParameter(valid_607273, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_607273 != nil:
    section.add "Action", valid_607273
  var valid_607274 = query.getOrDefault("Version")
  valid_607274 = validateParameter(valid_607274, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607274 != nil:
    section.add "Version", valid_607274
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607275 = header.getOrDefault("X-Amz-Signature")
  valid_607275 = validateParameter(valid_607275, JString, required = false,
                                 default = nil)
  if valid_607275 != nil:
    section.add "X-Amz-Signature", valid_607275
  var valid_607276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607276 = validateParameter(valid_607276, JString, required = false,
                                 default = nil)
  if valid_607276 != nil:
    section.add "X-Amz-Content-Sha256", valid_607276
  var valid_607277 = header.getOrDefault("X-Amz-Date")
  valid_607277 = validateParameter(valid_607277, JString, required = false,
                                 default = nil)
  if valid_607277 != nil:
    section.add "X-Amz-Date", valid_607277
  var valid_607278 = header.getOrDefault("X-Amz-Credential")
  valid_607278 = validateParameter(valid_607278, JString, required = false,
                                 default = nil)
  if valid_607278 != nil:
    section.add "X-Amz-Credential", valid_607278
  var valid_607279 = header.getOrDefault("X-Amz-Security-Token")
  valid_607279 = validateParameter(valid_607279, JString, required = false,
                                 default = nil)
  if valid_607279 != nil:
    section.add "X-Amz-Security-Token", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-Algorithm")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Algorithm", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-SignedHeaders", valid_607281
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_607282 = formData.getOrDefault("SourceType")
  valid_607282 = validateParameter(valid_607282, JString, required = false,
                                 default = nil)
  if valid_607282 != nil:
    section.add "SourceType", valid_607282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607283: Call_PostDescribeEventCategories_607270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607283.validator(path, query, header, formData, body)
  let scheme = call_607283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607283.url(scheme.get, call_607283.host, call_607283.base,
                         call_607283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607283, url, valid)

proc call*(call_607284: Call_PostDescribeEventCategories_607270;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607285 = newJObject()
  var formData_607286 = newJObject()
  add(formData_607286, "SourceType", newJString(SourceType))
  add(query_607285, "Action", newJString(Action))
  add(query_607285, "Version", newJString(Version))
  result = call_607284.call(nil, query_607285, nil, formData_607286, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_607270(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_607271, base: "/",
    url: url_PostDescribeEventCategories_607272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_607254 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEventCategories_607256(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventCategories_607255(path: JsonNode; query: JsonNode;
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
  var valid_607257 = query.getOrDefault("SourceType")
  valid_607257 = validateParameter(valid_607257, JString, required = false,
                                 default = nil)
  if valid_607257 != nil:
    section.add "SourceType", valid_607257
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607258 = query.getOrDefault("Action")
  valid_607258 = validateParameter(valid_607258, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_607258 != nil:
    section.add "Action", valid_607258
  var valid_607259 = query.getOrDefault("Version")
  valid_607259 = validateParameter(valid_607259, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607259 != nil:
    section.add "Version", valid_607259
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607260 = header.getOrDefault("X-Amz-Signature")
  valid_607260 = validateParameter(valid_607260, JString, required = false,
                                 default = nil)
  if valid_607260 != nil:
    section.add "X-Amz-Signature", valid_607260
  var valid_607261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607261 = validateParameter(valid_607261, JString, required = false,
                                 default = nil)
  if valid_607261 != nil:
    section.add "X-Amz-Content-Sha256", valid_607261
  var valid_607262 = header.getOrDefault("X-Amz-Date")
  valid_607262 = validateParameter(valid_607262, JString, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "X-Amz-Date", valid_607262
  var valid_607263 = header.getOrDefault("X-Amz-Credential")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "X-Amz-Credential", valid_607263
  var valid_607264 = header.getOrDefault("X-Amz-Security-Token")
  valid_607264 = validateParameter(valid_607264, JString, required = false,
                                 default = nil)
  if valid_607264 != nil:
    section.add "X-Amz-Security-Token", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-Algorithm")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-Algorithm", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-SignedHeaders", valid_607266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607267: Call_GetDescribeEventCategories_607254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607267.validator(path, query, header, formData, body)
  let scheme = call_607267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607267.url(scheme.get, call_607267.host, call_607267.base,
                         call_607267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607267, url, valid)

proc call*(call_607268: Call_GetDescribeEventCategories_607254;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607269 = newJObject()
  add(query_607269, "SourceType", newJString(SourceType))
  add(query_607269, "Action", newJString(Action))
  add(query_607269, "Version", newJString(Version))
  result = call_607268.call(nil, query_607269, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_607254(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_607255, base: "/",
    url: url_GetDescribeEventCategories_607256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_607305 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEventSubscriptions_607307(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventSubscriptions_607306(path: JsonNode;
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
  var valid_607308 = query.getOrDefault("Action")
  valid_607308 = validateParameter(valid_607308, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_607308 != nil:
    section.add "Action", valid_607308
  var valid_607309 = query.getOrDefault("Version")
  valid_607309 = validateParameter(valid_607309, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607309 != nil:
    section.add "Version", valid_607309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607310 = header.getOrDefault("X-Amz-Signature")
  valid_607310 = validateParameter(valid_607310, JString, required = false,
                                 default = nil)
  if valid_607310 != nil:
    section.add "X-Amz-Signature", valid_607310
  var valid_607311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607311 = validateParameter(valid_607311, JString, required = false,
                                 default = nil)
  if valid_607311 != nil:
    section.add "X-Amz-Content-Sha256", valid_607311
  var valid_607312 = header.getOrDefault("X-Amz-Date")
  valid_607312 = validateParameter(valid_607312, JString, required = false,
                                 default = nil)
  if valid_607312 != nil:
    section.add "X-Amz-Date", valid_607312
  var valid_607313 = header.getOrDefault("X-Amz-Credential")
  valid_607313 = validateParameter(valid_607313, JString, required = false,
                                 default = nil)
  if valid_607313 != nil:
    section.add "X-Amz-Credential", valid_607313
  var valid_607314 = header.getOrDefault("X-Amz-Security-Token")
  valid_607314 = validateParameter(valid_607314, JString, required = false,
                                 default = nil)
  if valid_607314 != nil:
    section.add "X-Amz-Security-Token", valid_607314
  var valid_607315 = header.getOrDefault("X-Amz-Algorithm")
  valid_607315 = validateParameter(valid_607315, JString, required = false,
                                 default = nil)
  if valid_607315 != nil:
    section.add "X-Amz-Algorithm", valid_607315
  var valid_607316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607316 = validateParameter(valid_607316, JString, required = false,
                                 default = nil)
  if valid_607316 != nil:
    section.add "X-Amz-SignedHeaders", valid_607316
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  section = newJObject()
  var valid_607317 = formData.getOrDefault("MaxRecords")
  valid_607317 = validateParameter(valid_607317, JInt, required = false, default = nil)
  if valid_607317 != nil:
    section.add "MaxRecords", valid_607317
  var valid_607318 = formData.getOrDefault("Marker")
  valid_607318 = validateParameter(valid_607318, JString, required = false,
                                 default = nil)
  if valid_607318 != nil:
    section.add "Marker", valid_607318
  var valid_607319 = formData.getOrDefault("SubscriptionName")
  valid_607319 = validateParameter(valid_607319, JString, required = false,
                                 default = nil)
  if valid_607319 != nil:
    section.add "SubscriptionName", valid_607319
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607320: Call_PostDescribeEventSubscriptions_607305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607320.validator(path, query, header, formData, body)
  let scheme = call_607320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607320.url(scheme.get, call_607320.host, call_607320.base,
                         call_607320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607320, url, valid)

proc call*(call_607321: Call_PostDescribeEventSubscriptions_607305;
          MaxRecords: int = 0; Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607322 = newJObject()
  var formData_607323 = newJObject()
  add(formData_607323, "MaxRecords", newJInt(MaxRecords))
  add(formData_607323, "Marker", newJString(Marker))
  add(formData_607323, "SubscriptionName", newJString(SubscriptionName))
  add(query_607322, "Action", newJString(Action))
  add(query_607322, "Version", newJString(Version))
  result = call_607321.call(nil, query_607322, nil, formData_607323, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_607305(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_607306, base: "/",
    url: url_PostDescribeEventSubscriptions_607307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_607287 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEventSubscriptions_607289(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventSubscriptions_607288(path: JsonNode; query: JsonNode;
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
  var valid_607290 = query.getOrDefault("Marker")
  valid_607290 = validateParameter(valid_607290, JString, required = false,
                                 default = nil)
  if valid_607290 != nil:
    section.add "Marker", valid_607290
  var valid_607291 = query.getOrDefault("SubscriptionName")
  valid_607291 = validateParameter(valid_607291, JString, required = false,
                                 default = nil)
  if valid_607291 != nil:
    section.add "SubscriptionName", valid_607291
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607292 = query.getOrDefault("Action")
  valid_607292 = validateParameter(valid_607292, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_607292 != nil:
    section.add "Action", valid_607292
  var valid_607293 = query.getOrDefault("Version")
  valid_607293 = validateParameter(valid_607293, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607293 != nil:
    section.add "Version", valid_607293
  var valid_607294 = query.getOrDefault("MaxRecords")
  valid_607294 = validateParameter(valid_607294, JInt, required = false, default = nil)
  if valid_607294 != nil:
    section.add "MaxRecords", valid_607294
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607295 = header.getOrDefault("X-Amz-Signature")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "X-Amz-Signature", valid_607295
  var valid_607296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "X-Amz-Content-Sha256", valid_607296
  var valid_607297 = header.getOrDefault("X-Amz-Date")
  valid_607297 = validateParameter(valid_607297, JString, required = false,
                                 default = nil)
  if valid_607297 != nil:
    section.add "X-Amz-Date", valid_607297
  var valid_607298 = header.getOrDefault("X-Amz-Credential")
  valid_607298 = validateParameter(valid_607298, JString, required = false,
                                 default = nil)
  if valid_607298 != nil:
    section.add "X-Amz-Credential", valid_607298
  var valid_607299 = header.getOrDefault("X-Amz-Security-Token")
  valid_607299 = validateParameter(valid_607299, JString, required = false,
                                 default = nil)
  if valid_607299 != nil:
    section.add "X-Amz-Security-Token", valid_607299
  var valid_607300 = header.getOrDefault("X-Amz-Algorithm")
  valid_607300 = validateParameter(valid_607300, JString, required = false,
                                 default = nil)
  if valid_607300 != nil:
    section.add "X-Amz-Algorithm", valid_607300
  var valid_607301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607301 = validateParameter(valid_607301, JString, required = false,
                                 default = nil)
  if valid_607301 != nil:
    section.add "X-Amz-SignedHeaders", valid_607301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607302: Call_GetDescribeEventSubscriptions_607287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607302.validator(path, query, header, formData, body)
  let scheme = call_607302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607302.url(scheme.get, call_607302.host, call_607302.base,
                         call_607302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607302, url, valid)

proc call*(call_607303: Call_GetDescribeEventSubscriptions_607287;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_607304 = newJObject()
  add(query_607304, "Marker", newJString(Marker))
  add(query_607304, "SubscriptionName", newJString(SubscriptionName))
  add(query_607304, "Action", newJString(Action))
  add(query_607304, "Version", newJString(Version))
  add(query_607304, "MaxRecords", newJInt(MaxRecords))
  result = call_607303.call(nil, query_607304, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_607287(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_607288, base: "/",
    url: url_GetDescribeEventSubscriptions_607289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_607347 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEvents_607349(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_607348(path: JsonNode; query: JsonNode;
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
  var valid_607350 = query.getOrDefault("Action")
  valid_607350 = validateParameter(valid_607350, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_607350 != nil:
    section.add "Action", valid_607350
  var valid_607351 = query.getOrDefault("Version")
  valid_607351 = validateParameter(valid_607351, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607351 != nil:
    section.add "Version", valid_607351
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607352 = header.getOrDefault("X-Amz-Signature")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Signature", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Content-Sha256", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-Date")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-Date", valid_607354
  var valid_607355 = header.getOrDefault("X-Amz-Credential")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-Credential", valid_607355
  var valid_607356 = header.getOrDefault("X-Amz-Security-Token")
  valid_607356 = validateParameter(valid_607356, JString, required = false,
                                 default = nil)
  if valid_607356 != nil:
    section.add "X-Amz-Security-Token", valid_607356
  var valid_607357 = header.getOrDefault("X-Amz-Algorithm")
  valid_607357 = validateParameter(valid_607357, JString, required = false,
                                 default = nil)
  if valid_607357 != nil:
    section.add "X-Amz-Algorithm", valid_607357
  var valid_607358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607358 = validateParameter(valid_607358, JString, required = false,
                                 default = nil)
  if valid_607358 != nil:
    section.add "X-Amz-SignedHeaders", valid_607358
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
  var valid_607359 = formData.getOrDefault("MaxRecords")
  valid_607359 = validateParameter(valid_607359, JInt, required = false, default = nil)
  if valid_607359 != nil:
    section.add "MaxRecords", valid_607359
  var valid_607360 = formData.getOrDefault("Marker")
  valid_607360 = validateParameter(valid_607360, JString, required = false,
                                 default = nil)
  if valid_607360 != nil:
    section.add "Marker", valid_607360
  var valid_607361 = formData.getOrDefault("SourceIdentifier")
  valid_607361 = validateParameter(valid_607361, JString, required = false,
                                 default = nil)
  if valid_607361 != nil:
    section.add "SourceIdentifier", valid_607361
  var valid_607362 = formData.getOrDefault("SourceType")
  valid_607362 = validateParameter(valid_607362, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_607362 != nil:
    section.add "SourceType", valid_607362
  var valid_607363 = formData.getOrDefault("Duration")
  valid_607363 = validateParameter(valid_607363, JInt, required = false, default = nil)
  if valid_607363 != nil:
    section.add "Duration", valid_607363
  var valid_607364 = formData.getOrDefault("EndTime")
  valid_607364 = validateParameter(valid_607364, JString, required = false,
                                 default = nil)
  if valid_607364 != nil:
    section.add "EndTime", valid_607364
  var valid_607365 = formData.getOrDefault("StartTime")
  valid_607365 = validateParameter(valid_607365, JString, required = false,
                                 default = nil)
  if valid_607365 != nil:
    section.add "StartTime", valid_607365
  var valid_607366 = formData.getOrDefault("EventCategories")
  valid_607366 = validateParameter(valid_607366, JArray, required = false,
                                 default = nil)
  if valid_607366 != nil:
    section.add "EventCategories", valid_607366
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607367: Call_PostDescribeEvents_607347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607367.validator(path, query, header, formData, body)
  let scheme = call_607367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607367.url(scheme.get, call_607367.host, call_607367.base,
                         call_607367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607367, url, valid)

proc call*(call_607368: Call_PostDescribeEvents_607347; MaxRecords: int = 0;
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
  var query_607369 = newJObject()
  var formData_607370 = newJObject()
  add(formData_607370, "MaxRecords", newJInt(MaxRecords))
  add(formData_607370, "Marker", newJString(Marker))
  add(formData_607370, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_607370, "SourceType", newJString(SourceType))
  add(formData_607370, "Duration", newJInt(Duration))
  add(formData_607370, "EndTime", newJString(EndTime))
  add(formData_607370, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_607370.add "EventCategories", EventCategories
  add(query_607369, "Action", newJString(Action))
  add(query_607369, "Version", newJString(Version))
  result = call_607368.call(nil, query_607369, nil, formData_607370, nil)

var postDescribeEvents* = Call_PostDescribeEvents_607347(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_607348, base: "/",
    url: url_PostDescribeEvents_607349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_607324 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEvents_607326(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_607325(path: JsonNode; query: JsonNode;
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
  var valid_607327 = query.getOrDefault("Marker")
  valid_607327 = validateParameter(valid_607327, JString, required = false,
                                 default = nil)
  if valid_607327 != nil:
    section.add "Marker", valid_607327
  var valid_607328 = query.getOrDefault("SourceType")
  valid_607328 = validateParameter(valid_607328, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_607328 != nil:
    section.add "SourceType", valid_607328
  var valid_607329 = query.getOrDefault("SourceIdentifier")
  valid_607329 = validateParameter(valid_607329, JString, required = false,
                                 default = nil)
  if valid_607329 != nil:
    section.add "SourceIdentifier", valid_607329
  var valid_607330 = query.getOrDefault("EventCategories")
  valid_607330 = validateParameter(valid_607330, JArray, required = false,
                                 default = nil)
  if valid_607330 != nil:
    section.add "EventCategories", valid_607330
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607331 = query.getOrDefault("Action")
  valid_607331 = validateParameter(valid_607331, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_607331 != nil:
    section.add "Action", valid_607331
  var valid_607332 = query.getOrDefault("StartTime")
  valid_607332 = validateParameter(valid_607332, JString, required = false,
                                 default = nil)
  if valid_607332 != nil:
    section.add "StartTime", valid_607332
  var valid_607333 = query.getOrDefault("Duration")
  valid_607333 = validateParameter(valid_607333, JInt, required = false, default = nil)
  if valid_607333 != nil:
    section.add "Duration", valid_607333
  var valid_607334 = query.getOrDefault("EndTime")
  valid_607334 = validateParameter(valid_607334, JString, required = false,
                                 default = nil)
  if valid_607334 != nil:
    section.add "EndTime", valid_607334
  var valid_607335 = query.getOrDefault("Version")
  valid_607335 = validateParameter(valid_607335, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607335 != nil:
    section.add "Version", valid_607335
  var valid_607336 = query.getOrDefault("MaxRecords")
  valid_607336 = validateParameter(valid_607336, JInt, required = false, default = nil)
  if valid_607336 != nil:
    section.add "MaxRecords", valid_607336
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607337 = header.getOrDefault("X-Amz-Signature")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Signature", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Content-Sha256", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-Date")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-Date", valid_607339
  var valid_607340 = header.getOrDefault("X-Amz-Credential")
  valid_607340 = validateParameter(valid_607340, JString, required = false,
                                 default = nil)
  if valid_607340 != nil:
    section.add "X-Amz-Credential", valid_607340
  var valid_607341 = header.getOrDefault("X-Amz-Security-Token")
  valid_607341 = validateParameter(valid_607341, JString, required = false,
                                 default = nil)
  if valid_607341 != nil:
    section.add "X-Amz-Security-Token", valid_607341
  var valid_607342 = header.getOrDefault("X-Amz-Algorithm")
  valid_607342 = validateParameter(valid_607342, JString, required = false,
                                 default = nil)
  if valid_607342 != nil:
    section.add "X-Amz-Algorithm", valid_607342
  var valid_607343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607343 = validateParameter(valid_607343, JString, required = false,
                                 default = nil)
  if valid_607343 != nil:
    section.add "X-Amz-SignedHeaders", valid_607343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607344: Call_GetDescribeEvents_607324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607344.validator(path, query, header, formData, body)
  let scheme = call_607344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607344.url(scheme.get, call_607344.host, call_607344.base,
                         call_607344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607344, url, valid)

proc call*(call_607345: Call_GetDescribeEvents_607324; Marker: string = "";
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
  var query_607346 = newJObject()
  add(query_607346, "Marker", newJString(Marker))
  add(query_607346, "SourceType", newJString(SourceType))
  add(query_607346, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_607346.add "EventCategories", EventCategories
  add(query_607346, "Action", newJString(Action))
  add(query_607346, "StartTime", newJString(StartTime))
  add(query_607346, "Duration", newJInt(Duration))
  add(query_607346, "EndTime", newJString(EndTime))
  add(query_607346, "Version", newJString(Version))
  add(query_607346, "MaxRecords", newJInt(MaxRecords))
  result = call_607345.call(nil, query_607346, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_607324(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_607325,
    base: "/", url: url_GetDescribeEvents_607326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_607390 = ref object of OpenApiRestCall_605573
proc url_PostDescribeOptionGroupOptions_607392(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroupOptions_607391(path: JsonNode;
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
  var valid_607393 = query.getOrDefault("Action")
  valid_607393 = validateParameter(valid_607393, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_607393 != nil:
    section.add "Action", valid_607393
  var valid_607394 = query.getOrDefault("Version")
  valid_607394 = validateParameter(valid_607394, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607394 != nil:
    section.add "Version", valid_607394
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607395 = header.getOrDefault("X-Amz-Signature")
  valid_607395 = validateParameter(valid_607395, JString, required = false,
                                 default = nil)
  if valid_607395 != nil:
    section.add "X-Amz-Signature", valid_607395
  var valid_607396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607396 = validateParameter(valid_607396, JString, required = false,
                                 default = nil)
  if valid_607396 != nil:
    section.add "X-Amz-Content-Sha256", valid_607396
  var valid_607397 = header.getOrDefault("X-Amz-Date")
  valid_607397 = validateParameter(valid_607397, JString, required = false,
                                 default = nil)
  if valid_607397 != nil:
    section.add "X-Amz-Date", valid_607397
  var valid_607398 = header.getOrDefault("X-Amz-Credential")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "X-Amz-Credential", valid_607398
  var valid_607399 = header.getOrDefault("X-Amz-Security-Token")
  valid_607399 = validateParameter(valid_607399, JString, required = false,
                                 default = nil)
  if valid_607399 != nil:
    section.add "X-Amz-Security-Token", valid_607399
  var valid_607400 = header.getOrDefault("X-Amz-Algorithm")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "X-Amz-Algorithm", valid_607400
  var valid_607401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "X-Amz-SignedHeaders", valid_607401
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_607402 = formData.getOrDefault("MaxRecords")
  valid_607402 = validateParameter(valid_607402, JInt, required = false, default = nil)
  if valid_607402 != nil:
    section.add "MaxRecords", valid_607402
  var valid_607403 = formData.getOrDefault("Marker")
  valid_607403 = validateParameter(valid_607403, JString, required = false,
                                 default = nil)
  if valid_607403 != nil:
    section.add "Marker", valid_607403
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_607404 = formData.getOrDefault("EngineName")
  valid_607404 = validateParameter(valid_607404, JString, required = true,
                                 default = nil)
  if valid_607404 != nil:
    section.add "EngineName", valid_607404
  var valid_607405 = formData.getOrDefault("MajorEngineVersion")
  valid_607405 = validateParameter(valid_607405, JString, required = false,
                                 default = nil)
  if valid_607405 != nil:
    section.add "MajorEngineVersion", valid_607405
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607406: Call_PostDescribeOptionGroupOptions_607390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607406.validator(path, query, header, formData, body)
  let scheme = call_607406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607406.url(scheme.get, call_607406.host, call_607406.base,
                         call_607406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607406, url, valid)

proc call*(call_607407: Call_PostDescribeOptionGroupOptions_607390;
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
  var query_607408 = newJObject()
  var formData_607409 = newJObject()
  add(formData_607409, "MaxRecords", newJInt(MaxRecords))
  add(formData_607409, "Marker", newJString(Marker))
  add(formData_607409, "EngineName", newJString(EngineName))
  add(formData_607409, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_607408, "Action", newJString(Action))
  add(query_607408, "Version", newJString(Version))
  result = call_607407.call(nil, query_607408, nil, formData_607409, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_607390(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_607391, base: "/",
    url: url_PostDescribeOptionGroupOptions_607392,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_607371 = ref object of OpenApiRestCall_605573
proc url_GetDescribeOptionGroupOptions_607373(protocol: Scheme; host: string;
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

proc validate_GetDescribeOptionGroupOptions_607372(path: JsonNode; query: JsonNode;
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
  var valid_607374 = query.getOrDefault("EngineName")
  valid_607374 = validateParameter(valid_607374, JString, required = true,
                                 default = nil)
  if valid_607374 != nil:
    section.add "EngineName", valid_607374
  var valid_607375 = query.getOrDefault("Marker")
  valid_607375 = validateParameter(valid_607375, JString, required = false,
                                 default = nil)
  if valid_607375 != nil:
    section.add "Marker", valid_607375
  var valid_607376 = query.getOrDefault("Action")
  valid_607376 = validateParameter(valid_607376, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_607376 != nil:
    section.add "Action", valid_607376
  var valid_607377 = query.getOrDefault("Version")
  valid_607377 = validateParameter(valid_607377, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607377 != nil:
    section.add "Version", valid_607377
  var valid_607378 = query.getOrDefault("MaxRecords")
  valid_607378 = validateParameter(valid_607378, JInt, required = false, default = nil)
  if valid_607378 != nil:
    section.add "MaxRecords", valid_607378
  var valid_607379 = query.getOrDefault("MajorEngineVersion")
  valid_607379 = validateParameter(valid_607379, JString, required = false,
                                 default = nil)
  if valid_607379 != nil:
    section.add "MajorEngineVersion", valid_607379
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607380 = header.getOrDefault("X-Amz-Signature")
  valid_607380 = validateParameter(valid_607380, JString, required = false,
                                 default = nil)
  if valid_607380 != nil:
    section.add "X-Amz-Signature", valid_607380
  var valid_607381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607381 = validateParameter(valid_607381, JString, required = false,
                                 default = nil)
  if valid_607381 != nil:
    section.add "X-Amz-Content-Sha256", valid_607381
  var valid_607382 = header.getOrDefault("X-Amz-Date")
  valid_607382 = validateParameter(valid_607382, JString, required = false,
                                 default = nil)
  if valid_607382 != nil:
    section.add "X-Amz-Date", valid_607382
  var valid_607383 = header.getOrDefault("X-Amz-Credential")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-Credential", valid_607383
  var valid_607384 = header.getOrDefault("X-Amz-Security-Token")
  valid_607384 = validateParameter(valid_607384, JString, required = false,
                                 default = nil)
  if valid_607384 != nil:
    section.add "X-Amz-Security-Token", valid_607384
  var valid_607385 = header.getOrDefault("X-Amz-Algorithm")
  valid_607385 = validateParameter(valid_607385, JString, required = false,
                                 default = nil)
  if valid_607385 != nil:
    section.add "X-Amz-Algorithm", valid_607385
  var valid_607386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607386 = validateParameter(valid_607386, JString, required = false,
                                 default = nil)
  if valid_607386 != nil:
    section.add "X-Amz-SignedHeaders", valid_607386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607387: Call_GetDescribeOptionGroupOptions_607371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607387.validator(path, query, header, formData, body)
  let scheme = call_607387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607387.url(scheme.get, call_607387.host, call_607387.base,
                         call_607387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607387, url, valid)

proc call*(call_607388: Call_GetDescribeOptionGroupOptions_607371;
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
  var query_607389 = newJObject()
  add(query_607389, "EngineName", newJString(EngineName))
  add(query_607389, "Marker", newJString(Marker))
  add(query_607389, "Action", newJString(Action))
  add(query_607389, "Version", newJString(Version))
  add(query_607389, "MaxRecords", newJInt(MaxRecords))
  add(query_607389, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_607388.call(nil, query_607389, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_607371(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_607372, base: "/",
    url: url_GetDescribeOptionGroupOptions_607373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_607430 = ref object of OpenApiRestCall_605573
proc url_PostDescribeOptionGroups_607432(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroups_607431(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607433 = query.getOrDefault("Action")
  valid_607433 = validateParameter(valid_607433, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_607433 != nil:
    section.add "Action", valid_607433
  var valid_607434 = query.getOrDefault("Version")
  valid_607434 = validateParameter(valid_607434, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607434 != nil:
    section.add "Version", valid_607434
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607435 = header.getOrDefault("X-Amz-Signature")
  valid_607435 = validateParameter(valid_607435, JString, required = false,
                                 default = nil)
  if valid_607435 != nil:
    section.add "X-Amz-Signature", valid_607435
  var valid_607436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607436 = validateParameter(valid_607436, JString, required = false,
                                 default = nil)
  if valid_607436 != nil:
    section.add "X-Amz-Content-Sha256", valid_607436
  var valid_607437 = header.getOrDefault("X-Amz-Date")
  valid_607437 = validateParameter(valid_607437, JString, required = false,
                                 default = nil)
  if valid_607437 != nil:
    section.add "X-Amz-Date", valid_607437
  var valid_607438 = header.getOrDefault("X-Amz-Credential")
  valid_607438 = validateParameter(valid_607438, JString, required = false,
                                 default = nil)
  if valid_607438 != nil:
    section.add "X-Amz-Credential", valid_607438
  var valid_607439 = header.getOrDefault("X-Amz-Security-Token")
  valid_607439 = validateParameter(valid_607439, JString, required = false,
                                 default = nil)
  if valid_607439 != nil:
    section.add "X-Amz-Security-Token", valid_607439
  var valid_607440 = header.getOrDefault("X-Amz-Algorithm")
  valid_607440 = validateParameter(valid_607440, JString, required = false,
                                 default = nil)
  if valid_607440 != nil:
    section.add "X-Amz-Algorithm", valid_607440
  var valid_607441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607441 = validateParameter(valid_607441, JString, required = false,
                                 default = nil)
  if valid_607441 != nil:
    section.add "X-Amz-SignedHeaders", valid_607441
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_607442 = formData.getOrDefault("MaxRecords")
  valid_607442 = validateParameter(valid_607442, JInt, required = false, default = nil)
  if valid_607442 != nil:
    section.add "MaxRecords", valid_607442
  var valid_607443 = formData.getOrDefault("Marker")
  valid_607443 = validateParameter(valid_607443, JString, required = false,
                                 default = nil)
  if valid_607443 != nil:
    section.add "Marker", valid_607443
  var valid_607444 = formData.getOrDefault("EngineName")
  valid_607444 = validateParameter(valid_607444, JString, required = false,
                                 default = nil)
  if valid_607444 != nil:
    section.add "EngineName", valid_607444
  var valid_607445 = formData.getOrDefault("MajorEngineVersion")
  valid_607445 = validateParameter(valid_607445, JString, required = false,
                                 default = nil)
  if valid_607445 != nil:
    section.add "MajorEngineVersion", valid_607445
  var valid_607446 = formData.getOrDefault("OptionGroupName")
  valid_607446 = validateParameter(valid_607446, JString, required = false,
                                 default = nil)
  if valid_607446 != nil:
    section.add "OptionGroupName", valid_607446
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607447: Call_PostDescribeOptionGroups_607430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607447.validator(path, query, header, formData, body)
  let scheme = call_607447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607447.url(scheme.get, call_607447.host, call_607447.base,
                         call_607447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607447, url, valid)

proc call*(call_607448: Call_PostDescribeOptionGroups_607430; MaxRecords: int = 0;
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
  var query_607449 = newJObject()
  var formData_607450 = newJObject()
  add(formData_607450, "MaxRecords", newJInt(MaxRecords))
  add(formData_607450, "Marker", newJString(Marker))
  add(formData_607450, "EngineName", newJString(EngineName))
  add(formData_607450, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_607449, "Action", newJString(Action))
  add(formData_607450, "OptionGroupName", newJString(OptionGroupName))
  add(query_607449, "Version", newJString(Version))
  result = call_607448.call(nil, query_607449, nil, formData_607450, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_607430(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_607431, base: "/",
    url: url_PostDescribeOptionGroups_607432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_607410 = ref object of OpenApiRestCall_605573
proc url_GetDescribeOptionGroups_607412(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeOptionGroups_607411(path: JsonNode; query: JsonNode;
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
  var valid_607413 = query.getOrDefault("EngineName")
  valid_607413 = validateParameter(valid_607413, JString, required = false,
                                 default = nil)
  if valid_607413 != nil:
    section.add "EngineName", valid_607413
  var valid_607414 = query.getOrDefault("Marker")
  valid_607414 = validateParameter(valid_607414, JString, required = false,
                                 default = nil)
  if valid_607414 != nil:
    section.add "Marker", valid_607414
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607415 = query.getOrDefault("Action")
  valid_607415 = validateParameter(valid_607415, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_607415 != nil:
    section.add "Action", valid_607415
  var valid_607416 = query.getOrDefault("OptionGroupName")
  valid_607416 = validateParameter(valid_607416, JString, required = false,
                                 default = nil)
  if valid_607416 != nil:
    section.add "OptionGroupName", valid_607416
  var valid_607417 = query.getOrDefault("Version")
  valid_607417 = validateParameter(valid_607417, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607417 != nil:
    section.add "Version", valid_607417
  var valid_607418 = query.getOrDefault("MaxRecords")
  valid_607418 = validateParameter(valid_607418, JInt, required = false, default = nil)
  if valid_607418 != nil:
    section.add "MaxRecords", valid_607418
  var valid_607419 = query.getOrDefault("MajorEngineVersion")
  valid_607419 = validateParameter(valid_607419, JString, required = false,
                                 default = nil)
  if valid_607419 != nil:
    section.add "MajorEngineVersion", valid_607419
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607420 = header.getOrDefault("X-Amz-Signature")
  valid_607420 = validateParameter(valid_607420, JString, required = false,
                                 default = nil)
  if valid_607420 != nil:
    section.add "X-Amz-Signature", valid_607420
  var valid_607421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607421 = validateParameter(valid_607421, JString, required = false,
                                 default = nil)
  if valid_607421 != nil:
    section.add "X-Amz-Content-Sha256", valid_607421
  var valid_607422 = header.getOrDefault("X-Amz-Date")
  valid_607422 = validateParameter(valid_607422, JString, required = false,
                                 default = nil)
  if valid_607422 != nil:
    section.add "X-Amz-Date", valid_607422
  var valid_607423 = header.getOrDefault("X-Amz-Credential")
  valid_607423 = validateParameter(valid_607423, JString, required = false,
                                 default = nil)
  if valid_607423 != nil:
    section.add "X-Amz-Credential", valid_607423
  var valid_607424 = header.getOrDefault("X-Amz-Security-Token")
  valid_607424 = validateParameter(valid_607424, JString, required = false,
                                 default = nil)
  if valid_607424 != nil:
    section.add "X-Amz-Security-Token", valid_607424
  var valid_607425 = header.getOrDefault("X-Amz-Algorithm")
  valid_607425 = validateParameter(valid_607425, JString, required = false,
                                 default = nil)
  if valid_607425 != nil:
    section.add "X-Amz-Algorithm", valid_607425
  var valid_607426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607426 = validateParameter(valid_607426, JString, required = false,
                                 default = nil)
  if valid_607426 != nil:
    section.add "X-Amz-SignedHeaders", valid_607426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607427: Call_GetDescribeOptionGroups_607410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607427.validator(path, query, header, formData, body)
  let scheme = call_607427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607427.url(scheme.get, call_607427.host, call_607427.base,
                         call_607427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607427, url, valid)

proc call*(call_607428: Call_GetDescribeOptionGroups_607410;
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
  var query_607429 = newJObject()
  add(query_607429, "EngineName", newJString(EngineName))
  add(query_607429, "Marker", newJString(Marker))
  add(query_607429, "Action", newJString(Action))
  add(query_607429, "OptionGroupName", newJString(OptionGroupName))
  add(query_607429, "Version", newJString(Version))
  add(query_607429, "MaxRecords", newJInt(MaxRecords))
  add(query_607429, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_607428.call(nil, query_607429, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_607410(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_607411, base: "/",
    url: url_GetDescribeOptionGroups_607412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_607473 = ref object of OpenApiRestCall_605573
proc url_PostDescribeOrderableDBInstanceOptions_607475(protocol: Scheme;
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

proc validate_PostDescribeOrderableDBInstanceOptions_607474(path: JsonNode;
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
  var valid_607476 = query.getOrDefault("Action")
  valid_607476 = validateParameter(valid_607476, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_607476 != nil:
    section.add "Action", valid_607476
  var valid_607477 = query.getOrDefault("Version")
  valid_607477 = validateParameter(valid_607477, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607477 != nil:
    section.add "Version", valid_607477
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607478 = header.getOrDefault("X-Amz-Signature")
  valid_607478 = validateParameter(valid_607478, JString, required = false,
                                 default = nil)
  if valid_607478 != nil:
    section.add "X-Amz-Signature", valid_607478
  var valid_607479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607479 = validateParameter(valid_607479, JString, required = false,
                                 default = nil)
  if valid_607479 != nil:
    section.add "X-Amz-Content-Sha256", valid_607479
  var valid_607480 = header.getOrDefault("X-Amz-Date")
  valid_607480 = validateParameter(valid_607480, JString, required = false,
                                 default = nil)
  if valid_607480 != nil:
    section.add "X-Amz-Date", valid_607480
  var valid_607481 = header.getOrDefault("X-Amz-Credential")
  valid_607481 = validateParameter(valid_607481, JString, required = false,
                                 default = nil)
  if valid_607481 != nil:
    section.add "X-Amz-Credential", valid_607481
  var valid_607482 = header.getOrDefault("X-Amz-Security-Token")
  valid_607482 = validateParameter(valid_607482, JString, required = false,
                                 default = nil)
  if valid_607482 != nil:
    section.add "X-Amz-Security-Token", valid_607482
  var valid_607483 = header.getOrDefault("X-Amz-Algorithm")
  valid_607483 = validateParameter(valid_607483, JString, required = false,
                                 default = nil)
  if valid_607483 != nil:
    section.add "X-Amz-Algorithm", valid_607483
  var valid_607484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607484 = validateParameter(valid_607484, JString, required = false,
                                 default = nil)
  if valid_607484 != nil:
    section.add "X-Amz-SignedHeaders", valid_607484
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
  var valid_607485 = formData.getOrDefault("DBInstanceClass")
  valid_607485 = validateParameter(valid_607485, JString, required = false,
                                 default = nil)
  if valid_607485 != nil:
    section.add "DBInstanceClass", valid_607485
  var valid_607486 = formData.getOrDefault("MaxRecords")
  valid_607486 = validateParameter(valid_607486, JInt, required = false, default = nil)
  if valid_607486 != nil:
    section.add "MaxRecords", valid_607486
  var valid_607487 = formData.getOrDefault("EngineVersion")
  valid_607487 = validateParameter(valid_607487, JString, required = false,
                                 default = nil)
  if valid_607487 != nil:
    section.add "EngineVersion", valid_607487
  var valid_607488 = formData.getOrDefault("Marker")
  valid_607488 = validateParameter(valid_607488, JString, required = false,
                                 default = nil)
  if valid_607488 != nil:
    section.add "Marker", valid_607488
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_607489 = formData.getOrDefault("Engine")
  valid_607489 = validateParameter(valid_607489, JString, required = true,
                                 default = nil)
  if valid_607489 != nil:
    section.add "Engine", valid_607489
  var valid_607490 = formData.getOrDefault("Vpc")
  valid_607490 = validateParameter(valid_607490, JBool, required = false, default = nil)
  if valid_607490 != nil:
    section.add "Vpc", valid_607490
  var valid_607491 = formData.getOrDefault("LicenseModel")
  valid_607491 = validateParameter(valid_607491, JString, required = false,
                                 default = nil)
  if valid_607491 != nil:
    section.add "LicenseModel", valid_607491
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607492: Call_PostDescribeOrderableDBInstanceOptions_607473;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607492.validator(path, query, header, formData, body)
  let scheme = call_607492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607492.url(scheme.get, call_607492.host, call_607492.base,
                         call_607492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607492, url, valid)

proc call*(call_607493: Call_PostDescribeOrderableDBInstanceOptions_607473;
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
  var query_607494 = newJObject()
  var formData_607495 = newJObject()
  add(formData_607495, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607495, "MaxRecords", newJInt(MaxRecords))
  add(formData_607495, "EngineVersion", newJString(EngineVersion))
  add(formData_607495, "Marker", newJString(Marker))
  add(formData_607495, "Engine", newJString(Engine))
  add(formData_607495, "Vpc", newJBool(Vpc))
  add(query_607494, "Action", newJString(Action))
  add(formData_607495, "LicenseModel", newJString(LicenseModel))
  add(query_607494, "Version", newJString(Version))
  result = call_607493.call(nil, query_607494, nil, formData_607495, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_607473(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_607474, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_607475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_607451 = ref object of OpenApiRestCall_605573
proc url_GetDescribeOrderableDBInstanceOptions_607453(protocol: Scheme;
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

proc validate_GetDescribeOrderableDBInstanceOptions_607452(path: JsonNode;
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
  var valid_607454 = query.getOrDefault("Marker")
  valid_607454 = validateParameter(valid_607454, JString, required = false,
                                 default = nil)
  if valid_607454 != nil:
    section.add "Marker", valid_607454
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_607455 = query.getOrDefault("Engine")
  valid_607455 = validateParameter(valid_607455, JString, required = true,
                                 default = nil)
  if valid_607455 != nil:
    section.add "Engine", valid_607455
  var valid_607456 = query.getOrDefault("LicenseModel")
  valid_607456 = validateParameter(valid_607456, JString, required = false,
                                 default = nil)
  if valid_607456 != nil:
    section.add "LicenseModel", valid_607456
  var valid_607457 = query.getOrDefault("Vpc")
  valid_607457 = validateParameter(valid_607457, JBool, required = false, default = nil)
  if valid_607457 != nil:
    section.add "Vpc", valid_607457
  var valid_607458 = query.getOrDefault("EngineVersion")
  valid_607458 = validateParameter(valid_607458, JString, required = false,
                                 default = nil)
  if valid_607458 != nil:
    section.add "EngineVersion", valid_607458
  var valid_607459 = query.getOrDefault("Action")
  valid_607459 = validateParameter(valid_607459, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_607459 != nil:
    section.add "Action", valid_607459
  var valid_607460 = query.getOrDefault("Version")
  valid_607460 = validateParameter(valid_607460, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607460 != nil:
    section.add "Version", valid_607460
  var valid_607461 = query.getOrDefault("DBInstanceClass")
  valid_607461 = validateParameter(valid_607461, JString, required = false,
                                 default = nil)
  if valid_607461 != nil:
    section.add "DBInstanceClass", valid_607461
  var valid_607462 = query.getOrDefault("MaxRecords")
  valid_607462 = validateParameter(valid_607462, JInt, required = false, default = nil)
  if valid_607462 != nil:
    section.add "MaxRecords", valid_607462
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607463 = header.getOrDefault("X-Amz-Signature")
  valid_607463 = validateParameter(valid_607463, JString, required = false,
                                 default = nil)
  if valid_607463 != nil:
    section.add "X-Amz-Signature", valid_607463
  var valid_607464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607464 = validateParameter(valid_607464, JString, required = false,
                                 default = nil)
  if valid_607464 != nil:
    section.add "X-Amz-Content-Sha256", valid_607464
  var valid_607465 = header.getOrDefault("X-Amz-Date")
  valid_607465 = validateParameter(valid_607465, JString, required = false,
                                 default = nil)
  if valid_607465 != nil:
    section.add "X-Amz-Date", valid_607465
  var valid_607466 = header.getOrDefault("X-Amz-Credential")
  valid_607466 = validateParameter(valid_607466, JString, required = false,
                                 default = nil)
  if valid_607466 != nil:
    section.add "X-Amz-Credential", valid_607466
  var valid_607467 = header.getOrDefault("X-Amz-Security-Token")
  valid_607467 = validateParameter(valid_607467, JString, required = false,
                                 default = nil)
  if valid_607467 != nil:
    section.add "X-Amz-Security-Token", valid_607467
  var valid_607468 = header.getOrDefault("X-Amz-Algorithm")
  valid_607468 = validateParameter(valid_607468, JString, required = false,
                                 default = nil)
  if valid_607468 != nil:
    section.add "X-Amz-Algorithm", valid_607468
  var valid_607469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607469 = validateParameter(valid_607469, JString, required = false,
                                 default = nil)
  if valid_607469 != nil:
    section.add "X-Amz-SignedHeaders", valid_607469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607470: Call_GetDescribeOrderableDBInstanceOptions_607451;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607470.validator(path, query, header, formData, body)
  let scheme = call_607470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607470.url(scheme.get, call_607470.host, call_607470.base,
                         call_607470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607470, url, valid)

proc call*(call_607471: Call_GetDescribeOrderableDBInstanceOptions_607451;
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
  var query_607472 = newJObject()
  add(query_607472, "Marker", newJString(Marker))
  add(query_607472, "Engine", newJString(Engine))
  add(query_607472, "LicenseModel", newJString(LicenseModel))
  add(query_607472, "Vpc", newJBool(Vpc))
  add(query_607472, "EngineVersion", newJString(EngineVersion))
  add(query_607472, "Action", newJString(Action))
  add(query_607472, "Version", newJString(Version))
  add(query_607472, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_607472, "MaxRecords", newJInt(MaxRecords))
  result = call_607471.call(nil, query_607472, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_607451(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_607452, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_607453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_607520 = ref object of OpenApiRestCall_605573
proc url_PostDescribeReservedDBInstances_607522(protocol: Scheme; host: string;
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

proc validate_PostDescribeReservedDBInstances_607521(path: JsonNode;
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
  var valid_607523 = query.getOrDefault("Action")
  valid_607523 = validateParameter(valid_607523, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_607523 != nil:
    section.add "Action", valid_607523
  var valid_607524 = query.getOrDefault("Version")
  valid_607524 = validateParameter(valid_607524, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607524 != nil:
    section.add "Version", valid_607524
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607525 = header.getOrDefault("X-Amz-Signature")
  valid_607525 = validateParameter(valid_607525, JString, required = false,
                                 default = nil)
  if valid_607525 != nil:
    section.add "X-Amz-Signature", valid_607525
  var valid_607526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607526 = validateParameter(valid_607526, JString, required = false,
                                 default = nil)
  if valid_607526 != nil:
    section.add "X-Amz-Content-Sha256", valid_607526
  var valid_607527 = header.getOrDefault("X-Amz-Date")
  valid_607527 = validateParameter(valid_607527, JString, required = false,
                                 default = nil)
  if valid_607527 != nil:
    section.add "X-Amz-Date", valid_607527
  var valid_607528 = header.getOrDefault("X-Amz-Credential")
  valid_607528 = validateParameter(valid_607528, JString, required = false,
                                 default = nil)
  if valid_607528 != nil:
    section.add "X-Amz-Credential", valid_607528
  var valid_607529 = header.getOrDefault("X-Amz-Security-Token")
  valid_607529 = validateParameter(valid_607529, JString, required = false,
                                 default = nil)
  if valid_607529 != nil:
    section.add "X-Amz-Security-Token", valid_607529
  var valid_607530 = header.getOrDefault("X-Amz-Algorithm")
  valid_607530 = validateParameter(valid_607530, JString, required = false,
                                 default = nil)
  if valid_607530 != nil:
    section.add "X-Amz-Algorithm", valid_607530
  var valid_607531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607531 = validateParameter(valid_607531, JString, required = false,
                                 default = nil)
  if valid_607531 != nil:
    section.add "X-Amz-SignedHeaders", valid_607531
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
  var valid_607532 = formData.getOrDefault("DBInstanceClass")
  valid_607532 = validateParameter(valid_607532, JString, required = false,
                                 default = nil)
  if valid_607532 != nil:
    section.add "DBInstanceClass", valid_607532
  var valid_607533 = formData.getOrDefault("MultiAZ")
  valid_607533 = validateParameter(valid_607533, JBool, required = false, default = nil)
  if valid_607533 != nil:
    section.add "MultiAZ", valid_607533
  var valid_607534 = formData.getOrDefault("MaxRecords")
  valid_607534 = validateParameter(valid_607534, JInt, required = false, default = nil)
  if valid_607534 != nil:
    section.add "MaxRecords", valid_607534
  var valid_607535 = formData.getOrDefault("ReservedDBInstanceId")
  valid_607535 = validateParameter(valid_607535, JString, required = false,
                                 default = nil)
  if valid_607535 != nil:
    section.add "ReservedDBInstanceId", valid_607535
  var valid_607536 = formData.getOrDefault("Marker")
  valid_607536 = validateParameter(valid_607536, JString, required = false,
                                 default = nil)
  if valid_607536 != nil:
    section.add "Marker", valid_607536
  var valid_607537 = formData.getOrDefault("Duration")
  valid_607537 = validateParameter(valid_607537, JString, required = false,
                                 default = nil)
  if valid_607537 != nil:
    section.add "Duration", valid_607537
  var valid_607538 = formData.getOrDefault("OfferingType")
  valid_607538 = validateParameter(valid_607538, JString, required = false,
                                 default = nil)
  if valid_607538 != nil:
    section.add "OfferingType", valid_607538
  var valid_607539 = formData.getOrDefault("ProductDescription")
  valid_607539 = validateParameter(valid_607539, JString, required = false,
                                 default = nil)
  if valid_607539 != nil:
    section.add "ProductDescription", valid_607539
  var valid_607540 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607540 = validateParameter(valid_607540, JString, required = false,
                                 default = nil)
  if valid_607540 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607540
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607541: Call_PostDescribeReservedDBInstances_607520;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607541.validator(path, query, header, formData, body)
  let scheme = call_607541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607541.url(scheme.get, call_607541.host, call_607541.base,
                         call_607541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607541, url, valid)

proc call*(call_607542: Call_PostDescribeReservedDBInstances_607520;
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
  var query_607543 = newJObject()
  var formData_607544 = newJObject()
  add(formData_607544, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607544, "MultiAZ", newJBool(MultiAZ))
  add(formData_607544, "MaxRecords", newJInt(MaxRecords))
  add(formData_607544, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_607544, "Marker", newJString(Marker))
  add(formData_607544, "Duration", newJString(Duration))
  add(formData_607544, "OfferingType", newJString(OfferingType))
  add(formData_607544, "ProductDescription", newJString(ProductDescription))
  add(query_607543, "Action", newJString(Action))
  add(formData_607544, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607543, "Version", newJString(Version))
  result = call_607542.call(nil, query_607543, nil, formData_607544, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_607520(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_607521, base: "/",
    url: url_PostDescribeReservedDBInstances_607522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_607496 = ref object of OpenApiRestCall_605573
proc url_GetDescribeReservedDBInstances_607498(protocol: Scheme; host: string;
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

proc validate_GetDescribeReservedDBInstances_607497(path: JsonNode;
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
  var valid_607499 = query.getOrDefault("Marker")
  valid_607499 = validateParameter(valid_607499, JString, required = false,
                                 default = nil)
  if valid_607499 != nil:
    section.add "Marker", valid_607499
  var valid_607500 = query.getOrDefault("ProductDescription")
  valid_607500 = validateParameter(valid_607500, JString, required = false,
                                 default = nil)
  if valid_607500 != nil:
    section.add "ProductDescription", valid_607500
  var valid_607501 = query.getOrDefault("OfferingType")
  valid_607501 = validateParameter(valid_607501, JString, required = false,
                                 default = nil)
  if valid_607501 != nil:
    section.add "OfferingType", valid_607501
  var valid_607502 = query.getOrDefault("ReservedDBInstanceId")
  valid_607502 = validateParameter(valid_607502, JString, required = false,
                                 default = nil)
  if valid_607502 != nil:
    section.add "ReservedDBInstanceId", valid_607502
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607503 = query.getOrDefault("Action")
  valid_607503 = validateParameter(valid_607503, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_607503 != nil:
    section.add "Action", valid_607503
  var valid_607504 = query.getOrDefault("MultiAZ")
  valid_607504 = validateParameter(valid_607504, JBool, required = false, default = nil)
  if valid_607504 != nil:
    section.add "MultiAZ", valid_607504
  var valid_607505 = query.getOrDefault("Duration")
  valid_607505 = validateParameter(valid_607505, JString, required = false,
                                 default = nil)
  if valid_607505 != nil:
    section.add "Duration", valid_607505
  var valid_607506 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607506 = validateParameter(valid_607506, JString, required = false,
                                 default = nil)
  if valid_607506 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607506
  var valid_607507 = query.getOrDefault("Version")
  valid_607507 = validateParameter(valid_607507, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607507 != nil:
    section.add "Version", valid_607507
  var valid_607508 = query.getOrDefault("DBInstanceClass")
  valid_607508 = validateParameter(valid_607508, JString, required = false,
                                 default = nil)
  if valid_607508 != nil:
    section.add "DBInstanceClass", valid_607508
  var valid_607509 = query.getOrDefault("MaxRecords")
  valid_607509 = validateParameter(valid_607509, JInt, required = false, default = nil)
  if valid_607509 != nil:
    section.add "MaxRecords", valid_607509
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607510 = header.getOrDefault("X-Amz-Signature")
  valid_607510 = validateParameter(valid_607510, JString, required = false,
                                 default = nil)
  if valid_607510 != nil:
    section.add "X-Amz-Signature", valid_607510
  var valid_607511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607511 = validateParameter(valid_607511, JString, required = false,
                                 default = nil)
  if valid_607511 != nil:
    section.add "X-Amz-Content-Sha256", valid_607511
  var valid_607512 = header.getOrDefault("X-Amz-Date")
  valid_607512 = validateParameter(valid_607512, JString, required = false,
                                 default = nil)
  if valid_607512 != nil:
    section.add "X-Amz-Date", valid_607512
  var valid_607513 = header.getOrDefault("X-Amz-Credential")
  valid_607513 = validateParameter(valid_607513, JString, required = false,
                                 default = nil)
  if valid_607513 != nil:
    section.add "X-Amz-Credential", valid_607513
  var valid_607514 = header.getOrDefault("X-Amz-Security-Token")
  valid_607514 = validateParameter(valid_607514, JString, required = false,
                                 default = nil)
  if valid_607514 != nil:
    section.add "X-Amz-Security-Token", valid_607514
  var valid_607515 = header.getOrDefault("X-Amz-Algorithm")
  valid_607515 = validateParameter(valid_607515, JString, required = false,
                                 default = nil)
  if valid_607515 != nil:
    section.add "X-Amz-Algorithm", valid_607515
  var valid_607516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607516 = validateParameter(valid_607516, JString, required = false,
                                 default = nil)
  if valid_607516 != nil:
    section.add "X-Amz-SignedHeaders", valid_607516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607517: Call_GetDescribeReservedDBInstances_607496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607517.validator(path, query, header, formData, body)
  let scheme = call_607517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607517.url(scheme.get, call_607517.host, call_607517.base,
                         call_607517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607517, url, valid)

proc call*(call_607518: Call_GetDescribeReservedDBInstances_607496;
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
  var query_607519 = newJObject()
  add(query_607519, "Marker", newJString(Marker))
  add(query_607519, "ProductDescription", newJString(ProductDescription))
  add(query_607519, "OfferingType", newJString(OfferingType))
  add(query_607519, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_607519, "Action", newJString(Action))
  add(query_607519, "MultiAZ", newJBool(MultiAZ))
  add(query_607519, "Duration", newJString(Duration))
  add(query_607519, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607519, "Version", newJString(Version))
  add(query_607519, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_607519, "MaxRecords", newJInt(MaxRecords))
  result = call_607518.call(nil, query_607519, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_607496(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_607497, base: "/",
    url: url_GetDescribeReservedDBInstances_607498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_607568 = ref object of OpenApiRestCall_605573
proc url_PostDescribeReservedDBInstancesOfferings_607570(protocol: Scheme;
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

proc validate_PostDescribeReservedDBInstancesOfferings_607569(path: JsonNode;
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
  var valid_607571 = query.getOrDefault("Action")
  valid_607571 = validateParameter(valid_607571, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_607571 != nil:
    section.add "Action", valid_607571
  var valid_607572 = query.getOrDefault("Version")
  valid_607572 = validateParameter(valid_607572, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607572 != nil:
    section.add "Version", valid_607572
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607573 = header.getOrDefault("X-Amz-Signature")
  valid_607573 = validateParameter(valid_607573, JString, required = false,
                                 default = nil)
  if valid_607573 != nil:
    section.add "X-Amz-Signature", valid_607573
  var valid_607574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607574 = validateParameter(valid_607574, JString, required = false,
                                 default = nil)
  if valid_607574 != nil:
    section.add "X-Amz-Content-Sha256", valid_607574
  var valid_607575 = header.getOrDefault("X-Amz-Date")
  valid_607575 = validateParameter(valid_607575, JString, required = false,
                                 default = nil)
  if valid_607575 != nil:
    section.add "X-Amz-Date", valid_607575
  var valid_607576 = header.getOrDefault("X-Amz-Credential")
  valid_607576 = validateParameter(valid_607576, JString, required = false,
                                 default = nil)
  if valid_607576 != nil:
    section.add "X-Amz-Credential", valid_607576
  var valid_607577 = header.getOrDefault("X-Amz-Security-Token")
  valid_607577 = validateParameter(valid_607577, JString, required = false,
                                 default = nil)
  if valid_607577 != nil:
    section.add "X-Amz-Security-Token", valid_607577
  var valid_607578 = header.getOrDefault("X-Amz-Algorithm")
  valid_607578 = validateParameter(valid_607578, JString, required = false,
                                 default = nil)
  if valid_607578 != nil:
    section.add "X-Amz-Algorithm", valid_607578
  var valid_607579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607579 = validateParameter(valid_607579, JString, required = false,
                                 default = nil)
  if valid_607579 != nil:
    section.add "X-Amz-SignedHeaders", valid_607579
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
  var valid_607580 = formData.getOrDefault("DBInstanceClass")
  valid_607580 = validateParameter(valid_607580, JString, required = false,
                                 default = nil)
  if valid_607580 != nil:
    section.add "DBInstanceClass", valid_607580
  var valid_607581 = formData.getOrDefault("MultiAZ")
  valid_607581 = validateParameter(valid_607581, JBool, required = false, default = nil)
  if valid_607581 != nil:
    section.add "MultiAZ", valid_607581
  var valid_607582 = formData.getOrDefault("MaxRecords")
  valid_607582 = validateParameter(valid_607582, JInt, required = false, default = nil)
  if valid_607582 != nil:
    section.add "MaxRecords", valid_607582
  var valid_607583 = formData.getOrDefault("Marker")
  valid_607583 = validateParameter(valid_607583, JString, required = false,
                                 default = nil)
  if valid_607583 != nil:
    section.add "Marker", valid_607583
  var valid_607584 = formData.getOrDefault("Duration")
  valid_607584 = validateParameter(valid_607584, JString, required = false,
                                 default = nil)
  if valid_607584 != nil:
    section.add "Duration", valid_607584
  var valid_607585 = formData.getOrDefault("OfferingType")
  valid_607585 = validateParameter(valid_607585, JString, required = false,
                                 default = nil)
  if valid_607585 != nil:
    section.add "OfferingType", valid_607585
  var valid_607586 = formData.getOrDefault("ProductDescription")
  valid_607586 = validateParameter(valid_607586, JString, required = false,
                                 default = nil)
  if valid_607586 != nil:
    section.add "ProductDescription", valid_607586
  var valid_607587 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607587 = validateParameter(valid_607587, JString, required = false,
                                 default = nil)
  if valid_607587 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607587
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607588: Call_PostDescribeReservedDBInstancesOfferings_607568;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607588.validator(path, query, header, formData, body)
  let scheme = call_607588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607588.url(scheme.get, call_607588.host, call_607588.base,
                         call_607588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607588, url, valid)

proc call*(call_607589: Call_PostDescribeReservedDBInstancesOfferings_607568;
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
  var query_607590 = newJObject()
  var formData_607591 = newJObject()
  add(formData_607591, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607591, "MultiAZ", newJBool(MultiAZ))
  add(formData_607591, "MaxRecords", newJInt(MaxRecords))
  add(formData_607591, "Marker", newJString(Marker))
  add(formData_607591, "Duration", newJString(Duration))
  add(formData_607591, "OfferingType", newJString(OfferingType))
  add(formData_607591, "ProductDescription", newJString(ProductDescription))
  add(query_607590, "Action", newJString(Action))
  add(formData_607591, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607590, "Version", newJString(Version))
  result = call_607589.call(nil, query_607590, nil, formData_607591, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_607568(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_607569,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_607570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_607545 = ref object of OpenApiRestCall_605573
proc url_GetDescribeReservedDBInstancesOfferings_607547(protocol: Scheme;
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

proc validate_GetDescribeReservedDBInstancesOfferings_607546(path: JsonNode;
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
  var valid_607548 = query.getOrDefault("Marker")
  valid_607548 = validateParameter(valid_607548, JString, required = false,
                                 default = nil)
  if valid_607548 != nil:
    section.add "Marker", valid_607548
  var valid_607549 = query.getOrDefault("ProductDescription")
  valid_607549 = validateParameter(valid_607549, JString, required = false,
                                 default = nil)
  if valid_607549 != nil:
    section.add "ProductDescription", valid_607549
  var valid_607550 = query.getOrDefault("OfferingType")
  valid_607550 = validateParameter(valid_607550, JString, required = false,
                                 default = nil)
  if valid_607550 != nil:
    section.add "OfferingType", valid_607550
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607551 = query.getOrDefault("Action")
  valid_607551 = validateParameter(valid_607551, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_607551 != nil:
    section.add "Action", valid_607551
  var valid_607552 = query.getOrDefault("MultiAZ")
  valid_607552 = validateParameter(valid_607552, JBool, required = false, default = nil)
  if valid_607552 != nil:
    section.add "MultiAZ", valid_607552
  var valid_607553 = query.getOrDefault("Duration")
  valid_607553 = validateParameter(valid_607553, JString, required = false,
                                 default = nil)
  if valid_607553 != nil:
    section.add "Duration", valid_607553
  var valid_607554 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607554 = validateParameter(valid_607554, JString, required = false,
                                 default = nil)
  if valid_607554 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607554
  var valid_607555 = query.getOrDefault("Version")
  valid_607555 = validateParameter(valid_607555, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607555 != nil:
    section.add "Version", valid_607555
  var valid_607556 = query.getOrDefault("DBInstanceClass")
  valid_607556 = validateParameter(valid_607556, JString, required = false,
                                 default = nil)
  if valid_607556 != nil:
    section.add "DBInstanceClass", valid_607556
  var valid_607557 = query.getOrDefault("MaxRecords")
  valid_607557 = validateParameter(valid_607557, JInt, required = false, default = nil)
  if valid_607557 != nil:
    section.add "MaxRecords", valid_607557
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607558 = header.getOrDefault("X-Amz-Signature")
  valid_607558 = validateParameter(valid_607558, JString, required = false,
                                 default = nil)
  if valid_607558 != nil:
    section.add "X-Amz-Signature", valid_607558
  var valid_607559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607559 = validateParameter(valid_607559, JString, required = false,
                                 default = nil)
  if valid_607559 != nil:
    section.add "X-Amz-Content-Sha256", valid_607559
  var valid_607560 = header.getOrDefault("X-Amz-Date")
  valid_607560 = validateParameter(valid_607560, JString, required = false,
                                 default = nil)
  if valid_607560 != nil:
    section.add "X-Amz-Date", valid_607560
  var valid_607561 = header.getOrDefault("X-Amz-Credential")
  valid_607561 = validateParameter(valid_607561, JString, required = false,
                                 default = nil)
  if valid_607561 != nil:
    section.add "X-Amz-Credential", valid_607561
  var valid_607562 = header.getOrDefault("X-Amz-Security-Token")
  valid_607562 = validateParameter(valid_607562, JString, required = false,
                                 default = nil)
  if valid_607562 != nil:
    section.add "X-Amz-Security-Token", valid_607562
  var valid_607563 = header.getOrDefault("X-Amz-Algorithm")
  valid_607563 = validateParameter(valid_607563, JString, required = false,
                                 default = nil)
  if valid_607563 != nil:
    section.add "X-Amz-Algorithm", valid_607563
  var valid_607564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607564 = validateParameter(valid_607564, JString, required = false,
                                 default = nil)
  if valid_607564 != nil:
    section.add "X-Amz-SignedHeaders", valid_607564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607565: Call_GetDescribeReservedDBInstancesOfferings_607545;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607565.validator(path, query, header, formData, body)
  let scheme = call_607565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607565.url(scheme.get, call_607565.host, call_607565.base,
                         call_607565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607565, url, valid)

proc call*(call_607566: Call_GetDescribeReservedDBInstancesOfferings_607545;
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
  var query_607567 = newJObject()
  add(query_607567, "Marker", newJString(Marker))
  add(query_607567, "ProductDescription", newJString(ProductDescription))
  add(query_607567, "OfferingType", newJString(OfferingType))
  add(query_607567, "Action", newJString(Action))
  add(query_607567, "MultiAZ", newJBool(MultiAZ))
  add(query_607567, "Duration", newJString(Duration))
  add(query_607567, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607567, "Version", newJString(Version))
  add(query_607567, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_607567, "MaxRecords", newJInt(MaxRecords))
  result = call_607566.call(nil, query_607567, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_607545(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_607546, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_607547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_607611 = ref object of OpenApiRestCall_605573
proc url_PostDownloadDBLogFilePortion_607613(protocol: Scheme; host: string;
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

proc validate_PostDownloadDBLogFilePortion_607612(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607614 = query.getOrDefault("Action")
  valid_607614 = validateParameter(valid_607614, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_607614 != nil:
    section.add "Action", valid_607614
  var valid_607615 = query.getOrDefault("Version")
  valid_607615 = validateParameter(valid_607615, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607615 != nil:
    section.add "Version", valid_607615
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607616 = header.getOrDefault("X-Amz-Signature")
  valid_607616 = validateParameter(valid_607616, JString, required = false,
                                 default = nil)
  if valid_607616 != nil:
    section.add "X-Amz-Signature", valid_607616
  var valid_607617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607617 = validateParameter(valid_607617, JString, required = false,
                                 default = nil)
  if valid_607617 != nil:
    section.add "X-Amz-Content-Sha256", valid_607617
  var valid_607618 = header.getOrDefault("X-Amz-Date")
  valid_607618 = validateParameter(valid_607618, JString, required = false,
                                 default = nil)
  if valid_607618 != nil:
    section.add "X-Amz-Date", valid_607618
  var valid_607619 = header.getOrDefault("X-Amz-Credential")
  valid_607619 = validateParameter(valid_607619, JString, required = false,
                                 default = nil)
  if valid_607619 != nil:
    section.add "X-Amz-Credential", valid_607619
  var valid_607620 = header.getOrDefault("X-Amz-Security-Token")
  valid_607620 = validateParameter(valid_607620, JString, required = false,
                                 default = nil)
  if valid_607620 != nil:
    section.add "X-Amz-Security-Token", valid_607620
  var valid_607621 = header.getOrDefault("X-Amz-Algorithm")
  valid_607621 = validateParameter(valid_607621, JString, required = false,
                                 default = nil)
  if valid_607621 != nil:
    section.add "X-Amz-Algorithm", valid_607621
  var valid_607622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607622 = validateParameter(valid_607622, JString, required = false,
                                 default = nil)
  if valid_607622 != nil:
    section.add "X-Amz-SignedHeaders", valid_607622
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_607623 = formData.getOrDefault("NumberOfLines")
  valid_607623 = validateParameter(valid_607623, JInt, required = false, default = nil)
  if valid_607623 != nil:
    section.add "NumberOfLines", valid_607623
  var valid_607624 = formData.getOrDefault("Marker")
  valid_607624 = validateParameter(valid_607624, JString, required = false,
                                 default = nil)
  if valid_607624 != nil:
    section.add "Marker", valid_607624
  assert formData != nil,
        "formData argument is necessary due to required `LogFileName` field"
  var valid_607625 = formData.getOrDefault("LogFileName")
  valid_607625 = validateParameter(valid_607625, JString, required = true,
                                 default = nil)
  if valid_607625 != nil:
    section.add "LogFileName", valid_607625
  var valid_607626 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607626 = validateParameter(valid_607626, JString, required = true,
                                 default = nil)
  if valid_607626 != nil:
    section.add "DBInstanceIdentifier", valid_607626
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607627: Call_PostDownloadDBLogFilePortion_607611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607627.validator(path, query, header, formData, body)
  let scheme = call_607627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607627.url(scheme.get, call_607627.host, call_607627.base,
                         call_607627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607627, url, valid)

proc call*(call_607628: Call_PostDownloadDBLogFilePortion_607611;
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
  var query_607629 = newJObject()
  var formData_607630 = newJObject()
  add(formData_607630, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_607630, "Marker", newJString(Marker))
  add(formData_607630, "LogFileName", newJString(LogFileName))
  add(formData_607630, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607629, "Action", newJString(Action))
  add(query_607629, "Version", newJString(Version))
  result = call_607628.call(nil, query_607629, nil, formData_607630, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_607611(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_607612, base: "/",
    url: url_PostDownloadDBLogFilePortion_607613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_607592 = ref object of OpenApiRestCall_605573
proc url_GetDownloadDBLogFilePortion_607594(protocol: Scheme; host: string;
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

proc validate_GetDownloadDBLogFilePortion_607593(path: JsonNode; query: JsonNode;
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
  var valid_607595 = query.getOrDefault("Marker")
  valid_607595 = validateParameter(valid_607595, JString, required = false,
                                 default = nil)
  if valid_607595 != nil:
    section.add "Marker", valid_607595
  var valid_607596 = query.getOrDefault("NumberOfLines")
  valid_607596 = validateParameter(valid_607596, JInt, required = false, default = nil)
  if valid_607596 != nil:
    section.add "NumberOfLines", valid_607596
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607597 = query.getOrDefault("DBInstanceIdentifier")
  valid_607597 = validateParameter(valid_607597, JString, required = true,
                                 default = nil)
  if valid_607597 != nil:
    section.add "DBInstanceIdentifier", valid_607597
  var valid_607598 = query.getOrDefault("Action")
  valid_607598 = validateParameter(valid_607598, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_607598 != nil:
    section.add "Action", valid_607598
  var valid_607599 = query.getOrDefault("LogFileName")
  valid_607599 = validateParameter(valid_607599, JString, required = true,
                                 default = nil)
  if valid_607599 != nil:
    section.add "LogFileName", valid_607599
  var valid_607600 = query.getOrDefault("Version")
  valid_607600 = validateParameter(valid_607600, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607600 != nil:
    section.add "Version", valid_607600
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607601 = header.getOrDefault("X-Amz-Signature")
  valid_607601 = validateParameter(valid_607601, JString, required = false,
                                 default = nil)
  if valid_607601 != nil:
    section.add "X-Amz-Signature", valid_607601
  var valid_607602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607602 = validateParameter(valid_607602, JString, required = false,
                                 default = nil)
  if valid_607602 != nil:
    section.add "X-Amz-Content-Sha256", valid_607602
  var valid_607603 = header.getOrDefault("X-Amz-Date")
  valid_607603 = validateParameter(valid_607603, JString, required = false,
                                 default = nil)
  if valid_607603 != nil:
    section.add "X-Amz-Date", valid_607603
  var valid_607604 = header.getOrDefault("X-Amz-Credential")
  valid_607604 = validateParameter(valid_607604, JString, required = false,
                                 default = nil)
  if valid_607604 != nil:
    section.add "X-Amz-Credential", valid_607604
  var valid_607605 = header.getOrDefault("X-Amz-Security-Token")
  valid_607605 = validateParameter(valid_607605, JString, required = false,
                                 default = nil)
  if valid_607605 != nil:
    section.add "X-Amz-Security-Token", valid_607605
  var valid_607606 = header.getOrDefault("X-Amz-Algorithm")
  valid_607606 = validateParameter(valid_607606, JString, required = false,
                                 default = nil)
  if valid_607606 != nil:
    section.add "X-Amz-Algorithm", valid_607606
  var valid_607607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607607 = validateParameter(valid_607607, JString, required = false,
                                 default = nil)
  if valid_607607 != nil:
    section.add "X-Amz-SignedHeaders", valid_607607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607608: Call_GetDownloadDBLogFilePortion_607592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607608.validator(path, query, header, formData, body)
  let scheme = call_607608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607608.url(scheme.get, call_607608.host, call_607608.base,
                         call_607608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607608, url, valid)

proc call*(call_607609: Call_GetDownloadDBLogFilePortion_607592;
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
  var query_607610 = newJObject()
  add(query_607610, "Marker", newJString(Marker))
  add(query_607610, "NumberOfLines", newJInt(NumberOfLines))
  add(query_607610, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607610, "Action", newJString(Action))
  add(query_607610, "LogFileName", newJString(LogFileName))
  add(query_607610, "Version", newJString(Version))
  result = call_607609.call(nil, query_607610, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_607592(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_607593, base: "/",
    url: url_GetDownloadDBLogFilePortion_607594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_607647 = ref object of OpenApiRestCall_605573
proc url_PostListTagsForResource_607649(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_607648(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607650 = query.getOrDefault("Action")
  valid_607650 = validateParameter(valid_607650, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_607650 != nil:
    section.add "Action", valid_607650
  var valid_607651 = query.getOrDefault("Version")
  valid_607651 = validateParameter(valid_607651, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607651 != nil:
    section.add "Version", valid_607651
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607652 = header.getOrDefault("X-Amz-Signature")
  valid_607652 = validateParameter(valid_607652, JString, required = false,
                                 default = nil)
  if valid_607652 != nil:
    section.add "X-Amz-Signature", valid_607652
  var valid_607653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607653 = validateParameter(valid_607653, JString, required = false,
                                 default = nil)
  if valid_607653 != nil:
    section.add "X-Amz-Content-Sha256", valid_607653
  var valid_607654 = header.getOrDefault("X-Amz-Date")
  valid_607654 = validateParameter(valid_607654, JString, required = false,
                                 default = nil)
  if valid_607654 != nil:
    section.add "X-Amz-Date", valid_607654
  var valid_607655 = header.getOrDefault("X-Amz-Credential")
  valid_607655 = validateParameter(valid_607655, JString, required = false,
                                 default = nil)
  if valid_607655 != nil:
    section.add "X-Amz-Credential", valid_607655
  var valid_607656 = header.getOrDefault("X-Amz-Security-Token")
  valid_607656 = validateParameter(valid_607656, JString, required = false,
                                 default = nil)
  if valid_607656 != nil:
    section.add "X-Amz-Security-Token", valid_607656
  var valid_607657 = header.getOrDefault("X-Amz-Algorithm")
  valid_607657 = validateParameter(valid_607657, JString, required = false,
                                 default = nil)
  if valid_607657 != nil:
    section.add "X-Amz-Algorithm", valid_607657
  var valid_607658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607658 = validateParameter(valid_607658, JString, required = false,
                                 default = nil)
  if valid_607658 != nil:
    section.add "X-Amz-SignedHeaders", valid_607658
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_607659 = formData.getOrDefault("ResourceName")
  valid_607659 = validateParameter(valid_607659, JString, required = true,
                                 default = nil)
  if valid_607659 != nil:
    section.add "ResourceName", valid_607659
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607660: Call_PostListTagsForResource_607647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607660.validator(path, query, header, formData, body)
  let scheme = call_607660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607660.url(scheme.get, call_607660.host, call_607660.base,
                         call_607660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607660, url, valid)

proc call*(call_607661: Call_PostListTagsForResource_607647; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_607662 = newJObject()
  var formData_607663 = newJObject()
  add(query_607662, "Action", newJString(Action))
  add(query_607662, "Version", newJString(Version))
  add(formData_607663, "ResourceName", newJString(ResourceName))
  result = call_607661.call(nil, query_607662, nil, formData_607663, nil)

var postListTagsForResource* = Call_PostListTagsForResource_607647(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_607648, base: "/",
    url: url_PostListTagsForResource_607649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_607631 = ref object of OpenApiRestCall_605573
proc url_GetListTagsForResource_607633(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_607632(path: JsonNode; query: JsonNode;
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
  var valid_607634 = query.getOrDefault("ResourceName")
  valid_607634 = validateParameter(valid_607634, JString, required = true,
                                 default = nil)
  if valid_607634 != nil:
    section.add "ResourceName", valid_607634
  var valid_607635 = query.getOrDefault("Action")
  valid_607635 = validateParameter(valid_607635, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_607635 != nil:
    section.add "Action", valid_607635
  var valid_607636 = query.getOrDefault("Version")
  valid_607636 = validateParameter(valid_607636, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607636 != nil:
    section.add "Version", valid_607636
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607637 = header.getOrDefault("X-Amz-Signature")
  valid_607637 = validateParameter(valid_607637, JString, required = false,
                                 default = nil)
  if valid_607637 != nil:
    section.add "X-Amz-Signature", valid_607637
  var valid_607638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607638 = validateParameter(valid_607638, JString, required = false,
                                 default = nil)
  if valid_607638 != nil:
    section.add "X-Amz-Content-Sha256", valid_607638
  var valid_607639 = header.getOrDefault("X-Amz-Date")
  valid_607639 = validateParameter(valid_607639, JString, required = false,
                                 default = nil)
  if valid_607639 != nil:
    section.add "X-Amz-Date", valid_607639
  var valid_607640 = header.getOrDefault("X-Amz-Credential")
  valid_607640 = validateParameter(valid_607640, JString, required = false,
                                 default = nil)
  if valid_607640 != nil:
    section.add "X-Amz-Credential", valid_607640
  var valid_607641 = header.getOrDefault("X-Amz-Security-Token")
  valid_607641 = validateParameter(valid_607641, JString, required = false,
                                 default = nil)
  if valid_607641 != nil:
    section.add "X-Amz-Security-Token", valid_607641
  var valid_607642 = header.getOrDefault("X-Amz-Algorithm")
  valid_607642 = validateParameter(valid_607642, JString, required = false,
                                 default = nil)
  if valid_607642 != nil:
    section.add "X-Amz-Algorithm", valid_607642
  var valid_607643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607643 = validateParameter(valid_607643, JString, required = false,
                                 default = nil)
  if valid_607643 != nil:
    section.add "X-Amz-SignedHeaders", valid_607643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607644: Call_GetListTagsForResource_607631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607644.validator(path, query, header, formData, body)
  let scheme = call_607644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607644.url(scheme.get, call_607644.host, call_607644.base,
                         call_607644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607644, url, valid)

proc call*(call_607645: Call_GetListTagsForResource_607631; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607646 = newJObject()
  add(query_607646, "ResourceName", newJString(ResourceName))
  add(query_607646, "Action", newJString(Action))
  add(query_607646, "Version", newJString(Version))
  result = call_607645.call(nil, query_607646, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_607631(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_607632, base: "/",
    url: url_GetListTagsForResource_607633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_607697 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBInstance_607699(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBInstance_607698(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607700 = query.getOrDefault("Action")
  valid_607700 = validateParameter(valid_607700, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_607700 != nil:
    section.add "Action", valid_607700
  var valid_607701 = query.getOrDefault("Version")
  valid_607701 = validateParameter(valid_607701, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607701 != nil:
    section.add "Version", valid_607701
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607702 = header.getOrDefault("X-Amz-Signature")
  valid_607702 = validateParameter(valid_607702, JString, required = false,
                                 default = nil)
  if valid_607702 != nil:
    section.add "X-Amz-Signature", valid_607702
  var valid_607703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607703 = validateParameter(valid_607703, JString, required = false,
                                 default = nil)
  if valid_607703 != nil:
    section.add "X-Amz-Content-Sha256", valid_607703
  var valid_607704 = header.getOrDefault("X-Amz-Date")
  valid_607704 = validateParameter(valid_607704, JString, required = false,
                                 default = nil)
  if valid_607704 != nil:
    section.add "X-Amz-Date", valid_607704
  var valid_607705 = header.getOrDefault("X-Amz-Credential")
  valid_607705 = validateParameter(valid_607705, JString, required = false,
                                 default = nil)
  if valid_607705 != nil:
    section.add "X-Amz-Credential", valid_607705
  var valid_607706 = header.getOrDefault("X-Amz-Security-Token")
  valid_607706 = validateParameter(valid_607706, JString, required = false,
                                 default = nil)
  if valid_607706 != nil:
    section.add "X-Amz-Security-Token", valid_607706
  var valid_607707 = header.getOrDefault("X-Amz-Algorithm")
  valid_607707 = validateParameter(valid_607707, JString, required = false,
                                 default = nil)
  if valid_607707 != nil:
    section.add "X-Amz-Algorithm", valid_607707
  var valid_607708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607708 = validateParameter(valid_607708, JString, required = false,
                                 default = nil)
  if valid_607708 != nil:
    section.add "X-Amz-SignedHeaders", valid_607708
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
  var valid_607709 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_607709 = validateParameter(valid_607709, JString, required = false,
                                 default = nil)
  if valid_607709 != nil:
    section.add "PreferredMaintenanceWindow", valid_607709
  var valid_607710 = formData.getOrDefault("DBInstanceClass")
  valid_607710 = validateParameter(valid_607710, JString, required = false,
                                 default = nil)
  if valid_607710 != nil:
    section.add "DBInstanceClass", valid_607710
  var valid_607711 = formData.getOrDefault("PreferredBackupWindow")
  valid_607711 = validateParameter(valid_607711, JString, required = false,
                                 default = nil)
  if valid_607711 != nil:
    section.add "PreferredBackupWindow", valid_607711
  var valid_607712 = formData.getOrDefault("MasterUserPassword")
  valid_607712 = validateParameter(valid_607712, JString, required = false,
                                 default = nil)
  if valid_607712 != nil:
    section.add "MasterUserPassword", valid_607712
  var valid_607713 = formData.getOrDefault("MultiAZ")
  valid_607713 = validateParameter(valid_607713, JBool, required = false, default = nil)
  if valid_607713 != nil:
    section.add "MultiAZ", valid_607713
  var valid_607714 = formData.getOrDefault("DBParameterGroupName")
  valid_607714 = validateParameter(valid_607714, JString, required = false,
                                 default = nil)
  if valid_607714 != nil:
    section.add "DBParameterGroupName", valid_607714
  var valid_607715 = formData.getOrDefault("EngineVersion")
  valid_607715 = validateParameter(valid_607715, JString, required = false,
                                 default = nil)
  if valid_607715 != nil:
    section.add "EngineVersion", valid_607715
  var valid_607716 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_607716 = validateParameter(valid_607716, JArray, required = false,
                                 default = nil)
  if valid_607716 != nil:
    section.add "VpcSecurityGroupIds", valid_607716
  var valid_607717 = formData.getOrDefault("BackupRetentionPeriod")
  valid_607717 = validateParameter(valid_607717, JInt, required = false, default = nil)
  if valid_607717 != nil:
    section.add "BackupRetentionPeriod", valid_607717
  var valid_607718 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_607718 = validateParameter(valid_607718, JBool, required = false, default = nil)
  if valid_607718 != nil:
    section.add "AutoMinorVersionUpgrade", valid_607718
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607719 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607719 = validateParameter(valid_607719, JString, required = true,
                                 default = nil)
  if valid_607719 != nil:
    section.add "DBInstanceIdentifier", valid_607719
  var valid_607720 = formData.getOrDefault("ApplyImmediately")
  valid_607720 = validateParameter(valid_607720, JBool, required = false, default = nil)
  if valid_607720 != nil:
    section.add "ApplyImmediately", valid_607720
  var valid_607721 = formData.getOrDefault("Iops")
  valid_607721 = validateParameter(valid_607721, JInt, required = false, default = nil)
  if valid_607721 != nil:
    section.add "Iops", valid_607721
  var valid_607722 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_607722 = validateParameter(valid_607722, JBool, required = false, default = nil)
  if valid_607722 != nil:
    section.add "AllowMajorVersionUpgrade", valid_607722
  var valid_607723 = formData.getOrDefault("OptionGroupName")
  valid_607723 = validateParameter(valid_607723, JString, required = false,
                                 default = nil)
  if valid_607723 != nil:
    section.add "OptionGroupName", valid_607723
  var valid_607724 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_607724 = validateParameter(valid_607724, JString, required = false,
                                 default = nil)
  if valid_607724 != nil:
    section.add "NewDBInstanceIdentifier", valid_607724
  var valid_607725 = formData.getOrDefault("DBSecurityGroups")
  valid_607725 = validateParameter(valid_607725, JArray, required = false,
                                 default = nil)
  if valid_607725 != nil:
    section.add "DBSecurityGroups", valid_607725
  var valid_607726 = formData.getOrDefault("AllocatedStorage")
  valid_607726 = validateParameter(valid_607726, JInt, required = false, default = nil)
  if valid_607726 != nil:
    section.add "AllocatedStorage", valid_607726
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607727: Call_PostModifyDBInstance_607697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607727.validator(path, query, header, formData, body)
  let scheme = call_607727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607727.url(scheme.get, call_607727.host, call_607727.base,
                         call_607727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607727, url, valid)

proc call*(call_607728: Call_PostModifyDBInstance_607697;
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
  var query_607729 = newJObject()
  var formData_607730 = newJObject()
  add(formData_607730, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_607730, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607730, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_607730, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_607730, "MultiAZ", newJBool(MultiAZ))
  add(formData_607730, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_607730, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_607730.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_607730, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_607730, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_607730, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_607730, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_607730, "Iops", newJInt(Iops))
  add(query_607729, "Action", newJString(Action))
  add(formData_607730, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_607730, "OptionGroupName", newJString(OptionGroupName))
  add(formData_607730, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_607729, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_607730.add "DBSecurityGroups", DBSecurityGroups
  add(formData_607730, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_607728.call(nil, query_607729, nil, formData_607730, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_607697(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_607698, base: "/",
    url: url_PostModifyDBInstance_607699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_607664 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBInstance_607666(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBInstance_607665(path: JsonNode; query: JsonNode;
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
  var valid_607667 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_607667 = validateParameter(valid_607667, JString, required = false,
                                 default = nil)
  if valid_607667 != nil:
    section.add "NewDBInstanceIdentifier", valid_607667
  var valid_607668 = query.getOrDefault("DBParameterGroupName")
  valid_607668 = validateParameter(valid_607668, JString, required = false,
                                 default = nil)
  if valid_607668 != nil:
    section.add "DBParameterGroupName", valid_607668
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607669 = query.getOrDefault("DBInstanceIdentifier")
  valid_607669 = validateParameter(valid_607669, JString, required = true,
                                 default = nil)
  if valid_607669 != nil:
    section.add "DBInstanceIdentifier", valid_607669
  var valid_607670 = query.getOrDefault("BackupRetentionPeriod")
  valid_607670 = validateParameter(valid_607670, JInt, required = false, default = nil)
  if valid_607670 != nil:
    section.add "BackupRetentionPeriod", valid_607670
  var valid_607671 = query.getOrDefault("EngineVersion")
  valid_607671 = validateParameter(valid_607671, JString, required = false,
                                 default = nil)
  if valid_607671 != nil:
    section.add "EngineVersion", valid_607671
  var valid_607672 = query.getOrDefault("Action")
  valid_607672 = validateParameter(valid_607672, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_607672 != nil:
    section.add "Action", valid_607672
  var valid_607673 = query.getOrDefault("MultiAZ")
  valid_607673 = validateParameter(valid_607673, JBool, required = false, default = nil)
  if valid_607673 != nil:
    section.add "MultiAZ", valid_607673
  var valid_607674 = query.getOrDefault("DBSecurityGroups")
  valid_607674 = validateParameter(valid_607674, JArray, required = false,
                                 default = nil)
  if valid_607674 != nil:
    section.add "DBSecurityGroups", valid_607674
  var valid_607675 = query.getOrDefault("ApplyImmediately")
  valid_607675 = validateParameter(valid_607675, JBool, required = false, default = nil)
  if valid_607675 != nil:
    section.add "ApplyImmediately", valid_607675
  var valid_607676 = query.getOrDefault("VpcSecurityGroupIds")
  valid_607676 = validateParameter(valid_607676, JArray, required = false,
                                 default = nil)
  if valid_607676 != nil:
    section.add "VpcSecurityGroupIds", valid_607676
  var valid_607677 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_607677 = validateParameter(valid_607677, JBool, required = false, default = nil)
  if valid_607677 != nil:
    section.add "AllowMajorVersionUpgrade", valid_607677
  var valid_607678 = query.getOrDefault("MasterUserPassword")
  valid_607678 = validateParameter(valid_607678, JString, required = false,
                                 default = nil)
  if valid_607678 != nil:
    section.add "MasterUserPassword", valid_607678
  var valid_607679 = query.getOrDefault("OptionGroupName")
  valid_607679 = validateParameter(valid_607679, JString, required = false,
                                 default = nil)
  if valid_607679 != nil:
    section.add "OptionGroupName", valid_607679
  var valid_607680 = query.getOrDefault("Version")
  valid_607680 = validateParameter(valid_607680, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607680 != nil:
    section.add "Version", valid_607680
  var valid_607681 = query.getOrDefault("AllocatedStorage")
  valid_607681 = validateParameter(valid_607681, JInt, required = false, default = nil)
  if valid_607681 != nil:
    section.add "AllocatedStorage", valid_607681
  var valid_607682 = query.getOrDefault("DBInstanceClass")
  valid_607682 = validateParameter(valid_607682, JString, required = false,
                                 default = nil)
  if valid_607682 != nil:
    section.add "DBInstanceClass", valid_607682
  var valid_607683 = query.getOrDefault("PreferredBackupWindow")
  valid_607683 = validateParameter(valid_607683, JString, required = false,
                                 default = nil)
  if valid_607683 != nil:
    section.add "PreferredBackupWindow", valid_607683
  var valid_607684 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_607684 = validateParameter(valid_607684, JString, required = false,
                                 default = nil)
  if valid_607684 != nil:
    section.add "PreferredMaintenanceWindow", valid_607684
  var valid_607685 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_607685 = validateParameter(valid_607685, JBool, required = false, default = nil)
  if valid_607685 != nil:
    section.add "AutoMinorVersionUpgrade", valid_607685
  var valid_607686 = query.getOrDefault("Iops")
  valid_607686 = validateParameter(valid_607686, JInt, required = false, default = nil)
  if valid_607686 != nil:
    section.add "Iops", valid_607686
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607687 = header.getOrDefault("X-Amz-Signature")
  valid_607687 = validateParameter(valid_607687, JString, required = false,
                                 default = nil)
  if valid_607687 != nil:
    section.add "X-Amz-Signature", valid_607687
  var valid_607688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607688 = validateParameter(valid_607688, JString, required = false,
                                 default = nil)
  if valid_607688 != nil:
    section.add "X-Amz-Content-Sha256", valid_607688
  var valid_607689 = header.getOrDefault("X-Amz-Date")
  valid_607689 = validateParameter(valid_607689, JString, required = false,
                                 default = nil)
  if valid_607689 != nil:
    section.add "X-Amz-Date", valid_607689
  var valid_607690 = header.getOrDefault("X-Amz-Credential")
  valid_607690 = validateParameter(valid_607690, JString, required = false,
                                 default = nil)
  if valid_607690 != nil:
    section.add "X-Amz-Credential", valid_607690
  var valid_607691 = header.getOrDefault("X-Amz-Security-Token")
  valid_607691 = validateParameter(valid_607691, JString, required = false,
                                 default = nil)
  if valid_607691 != nil:
    section.add "X-Amz-Security-Token", valid_607691
  var valid_607692 = header.getOrDefault("X-Amz-Algorithm")
  valid_607692 = validateParameter(valid_607692, JString, required = false,
                                 default = nil)
  if valid_607692 != nil:
    section.add "X-Amz-Algorithm", valid_607692
  var valid_607693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607693 = validateParameter(valid_607693, JString, required = false,
                                 default = nil)
  if valid_607693 != nil:
    section.add "X-Amz-SignedHeaders", valid_607693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607694: Call_GetModifyDBInstance_607664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607694.validator(path, query, header, formData, body)
  let scheme = call_607694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607694.url(scheme.get, call_607694.host, call_607694.base,
                         call_607694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607694, url, valid)

proc call*(call_607695: Call_GetModifyDBInstance_607664;
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
  var query_607696 = newJObject()
  add(query_607696, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_607696, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607696, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607696, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_607696, "EngineVersion", newJString(EngineVersion))
  add(query_607696, "Action", newJString(Action))
  add(query_607696, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_607696.add "DBSecurityGroups", DBSecurityGroups
  add(query_607696, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_607696.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_607696, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_607696, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_607696, "OptionGroupName", newJString(OptionGroupName))
  add(query_607696, "Version", newJString(Version))
  add(query_607696, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_607696, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_607696, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_607696, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_607696, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_607696, "Iops", newJInt(Iops))
  result = call_607695.call(nil, query_607696, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_607664(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_607665, base: "/",
    url: url_GetModifyDBInstance_607666, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_607748 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBParameterGroup_607750(protocol: Scheme; host: string;
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

proc validate_PostModifyDBParameterGroup_607749(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607751 = query.getOrDefault("Action")
  valid_607751 = validateParameter(valid_607751, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_607751 != nil:
    section.add "Action", valid_607751
  var valid_607752 = query.getOrDefault("Version")
  valid_607752 = validateParameter(valid_607752, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607752 != nil:
    section.add "Version", valid_607752
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607753 = header.getOrDefault("X-Amz-Signature")
  valid_607753 = validateParameter(valid_607753, JString, required = false,
                                 default = nil)
  if valid_607753 != nil:
    section.add "X-Amz-Signature", valid_607753
  var valid_607754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607754 = validateParameter(valid_607754, JString, required = false,
                                 default = nil)
  if valid_607754 != nil:
    section.add "X-Amz-Content-Sha256", valid_607754
  var valid_607755 = header.getOrDefault("X-Amz-Date")
  valid_607755 = validateParameter(valid_607755, JString, required = false,
                                 default = nil)
  if valid_607755 != nil:
    section.add "X-Amz-Date", valid_607755
  var valid_607756 = header.getOrDefault("X-Amz-Credential")
  valid_607756 = validateParameter(valid_607756, JString, required = false,
                                 default = nil)
  if valid_607756 != nil:
    section.add "X-Amz-Credential", valid_607756
  var valid_607757 = header.getOrDefault("X-Amz-Security-Token")
  valid_607757 = validateParameter(valid_607757, JString, required = false,
                                 default = nil)
  if valid_607757 != nil:
    section.add "X-Amz-Security-Token", valid_607757
  var valid_607758 = header.getOrDefault("X-Amz-Algorithm")
  valid_607758 = validateParameter(valid_607758, JString, required = false,
                                 default = nil)
  if valid_607758 != nil:
    section.add "X-Amz-Algorithm", valid_607758
  var valid_607759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607759 = validateParameter(valid_607759, JString, required = false,
                                 default = nil)
  if valid_607759 != nil:
    section.add "X-Amz-SignedHeaders", valid_607759
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_607760 = formData.getOrDefault("DBParameterGroupName")
  valid_607760 = validateParameter(valid_607760, JString, required = true,
                                 default = nil)
  if valid_607760 != nil:
    section.add "DBParameterGroupName", valid_607760
  var valid_607761 = formData.getOrDefault("Parameters")
  valid_607761 = validateParameter(valid_607761, JArray, required = true, default = nil)
  if valid_607761 != nil:
    section.add "Parameters", valid_607761
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607762: Call_PostModifyDBParameterGroup_607748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607762.validator(path, query, header, formData, body)
  let scheme = call_607762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607762.url(scheme.get, call_607762.host, call_607762.base,
                         call_607762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607762, url, valid)

proc call*(call_607763: Call_PostModifyDBParameterGroup_607748;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_607764 = newJObject()
  var formData_607765 = newJObject()
  add(formData_607765, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607764, "Action", newJString(Action))
  if Parameters != nil:
    formData_607765.add "Parameters", Parameters
  add(query_607764, "Version", newJString(Version))
  result = call_607763.call(nil, query_607764, nil, formData_607765, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_607748(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_607749, base: "/",
    url: url_PostModifyDBParameterGroup_607750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_607731 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBParameterGroup_607733(protocol: Scheme; host: string;
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

proc validate_GetModifyDBParameterGroup_607732(path: JsonNode; query: JsonNode;
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
  var valid_607734 = query.getOrDefault("DBParameterGroupName")
  valid_607734 = validateParameter(valid_607734, JString, required = true,
                                 default = nil)
  if valid_607734 != nil:
    section.add "DBParameterGroupName", valid_607734
  var valid_607735 = query.getOrDefault("Parameters")
  valid_607735 = validateParameter(valid_607735, JArray, required = true, default = nil)
  if valid_607735 != nil:
    section.add "Parameters", valid_607735
  var valid_607736 = query.getOrDefault("Action")
  valid_607736 = validateParameter(valid_607736, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_607736 != nil:
    section.add "Action", valid_607736
  var valid_607737 = query.getOrDefault("Version")
  valid_607737 = validateParameter(valid_607737, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607737 != nil:
    section.add "Version", valid_607737
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607738 = header.getOrDefault("X-Amz-Signature")
  valid_607738 = validateParameter(valid_607738, JString, required = false,
                                 default = nil)
  if valid_607738 != nil:
    section.add "X-Amz-Signature", valid_607738
  var valid_607739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607739 = validateParameter(valid_607739, JString, required = false,
                                 default = nil)
  if valid_607739 != nil:
    section.add "X-Amz-Content-Sha256", valid_607739
  var valid_607740 = header.getOrDefault("X-Amz-Date")
  valid_607740 = validateParameter(valid_607740, JString, required = false,
                                 default = nil)
  if valid_607740 != nil:
    section.add "X-Amz-Date", valid_607740
  var valid_607741 = header.getOrDefault("X-Amz-Credential")
  valid_607741 = validateParameter(valid_607741, JString, required = false,
                                 default = nil)
  if valid_607741 != nil:
    section.add "X-Amz-Credential", valid_607741
  var valid_607742 = header.getOrDefault("X-Amz-Security-Token")
  valid_607742 = validateParameter(valid_607742, JString, required = false,
                                 default = nil)
  if valid_607742 != nil:
    section.add "X-Amz-Security-Token", valid_607742
  var valid_607743 = header.getOrDefault("X-Amz-Algorithm")
  valid_607743 = validateParameter(valid_607743, JString, required = false,
                                 default = nil)
  if valid_607743 != nil:
    section.add "X-Amz-Algorithm", valid_607743
  var valid_607744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607744 = validateParameter(valid_607744, JString, required = false,
                                 default = nil)
  if valid_607744 != nil:
    section.add "X-Amz-SignedHeaders", valid_607744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607745: Call_GetModifyDBParameterGroup_607731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607745.validator(path, query, header, formData, body)
  let scheme = call_607745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607745.url(scheme.get, call_607745.host, call_607745.base,
                         call_607745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607745, url, valid)

proc call*(call_607746: Call_GetModifyDBParameterGroup_607731;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607747 = newJObject()
  add(query_607747, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_607747.add "Parameters", Parameters
  add(query_607747, "Action", newJString(Action))
  add(query_607747, "Version", newJString(Version))
  result = call_607746.call(nil, query_607747, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_607731(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_607732, base: "/",
    url: url_GetModifyDBParameterGroup_607733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_607784 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBSubnetGroup_607786(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBSubnetGroup_607785(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607787 = query.getOrDefault("Action")
  valid_607787 = validateParameter(valid_607787, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_607787 != nil:
    section.add "Action", valid_607787
  var valid_607788 = query.getOrDefault("Version")
  valid_607788 = validateParameter(valid_607788, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607788 != nil:
    section.add "Version", valid_607788
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607789 = header.getOrDefault("X-Amz-Signature")
  valid_607789 = validateParameter(valid_607789, JString, required = false,
                                 default = nil)
  if valid_607789 != nil:
    section.add "X-Amz-Signature", valid_607789
  var valid_607790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607790 = validateParameter(valid_607790, JString, required = false,
                                 default = nil)
  if valid_607790 != nil:
    section.add "X-Amz-Content-Sha256", valid_607790
  var valid_607791 = header.getOrDefault("X-Amz-Date")
  valid_607791 = validateParameter(valid_607791, JString, required = false,
                                 default = nil)
  if valid_607791 != nil:
    section.add "X-Amz-Date", valid_607791
  var valid_607792 = header.getOrDefault("X-Amz-Credential")
  valid_607792 = validateParameter(valid_607792, JString, required = false,
                                 default = nil)
  if valid_607792 != nil:
    section.add "X-Amz-Credential", valid_607792
  var valid_607793 = header.getOrDefault("X-Amz-Security-Token")
  valid_607793 = validateParameter(valid_607793, JString, required = false,
                                 default = nil)
  if valid_607793 != nil:
    section.add "X-Amz-Security-Token", valid_607793
  var valid_607794 = header.getOrDefault("X-Amz-Algorithm")
  valid_607794 = validateParameter(valid_607794, JString, required = false,
                                 default = nil)
  if valid_607794 != nil:
    section.add "X-Amz-Algorithm", valid_607794
  var valid_607795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607795 = validateParameter(valid_607795, JString, required = false,
                                 default = nil)
  if valid_607795 != nil:
    section.add "X-Amz-SignedHeaders", valid_607795
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_607796 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_607796 = validateParameter(valid_607796, JString, required = false,
                                 default = nil)
  if valid_607796 != nil:
    section.add "DBSubnetGroupDescription", valid_607796
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_607797 = formData.getOrDefault("DBSubnetGroupName")
  valid_607797 = validateParameter(valid_607797, JString, required = true,
                                 default = nil)
  if valid_607797 != nil:
    section.add "DBSubnetGroupName", valid_607797
  var valid_607798 = formData.getOrDefault("SubnetIds")
  valid_607798 = validateParameter(valid_607798, JArray, required = true, default = nil)
  if valid_607798 != nil:
    section.add "SubnetIds", valid_607798
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607799: Call_PostModifyDBSubnetGroup_607784; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607799.validator(path, query, header, formData, body)
  let scheme = call_607799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607799.url(scheme.get, call_607799.host, call_607799.base,
                         call_607799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607799, url, valid)

proc call*(call_607800: Call_PostModifyDBSubnetGroup_607784;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_607801 = newJObject()
  var formData_607802 = newJObject()
  add(formData_607802, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_607801, "Action", newJString(Action))
  add(formData_607802, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607801, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_607802.add "SubnetIds", SubnetIds
  result = call_607800.call(nil, query_607801, nil, formData_607802, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_607784(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_607785, base: "/",
    url: url_PostModifyDBSubnetGroup_607786, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_607766 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBSubnetGroup_607768(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBSubnetGroup_607767(path: JsonNode; query: JsonNode;
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
  var valid_607769 = query.getOrDefault("SubnetIds")
  valid_607769 = validateParameter(valid_607769, JArray, required = true, default = nil)
  if valid_607769 != nil:
    section.add "SubnetIds", valid_607769
  var valid_607770 = query.getOrDefault("Action")
  valid_607770 = validateParameter(valid_607770, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_607770 != nil:
    section.add "Action", valid_607770
  var valid_607771 = query.getOrDefault("DBSubnetGroupDescription")
  valid_607771 = validateParameter(valid_607771, JString, required = false,
                                 default = nil)
  if valid_607771 != nil:
    section.add "DBSubnetGroupDescription", valid_607771
  var valid_607772 = query.getOrDefault("DBSubnetGroupName")
  valid_607772 = validateParameter(valid_607772, JString, required = true,
                                 default = nil)
  if valid_607772 != nil:
    section.add "DBSubnetGroupName", valid_607772
  var valid_607773 = query.getOrDefault("Version")
  valid_607773 = validateParameter(valid_607773, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607773 != nil:
    section.add "Version", valid_607773
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607774 = header.getOrDefault("X-Amz-Signature")
  valid_607774 = validateParameter(valid_607774, JString, required = false,
                                 default = nil)
  if valid_607774 != nil:
    section.add "X-Amz-Signature", valid_607774
  var valid_607775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607775 = validateParameter(valid_607775, JString, required = false,
                                 default = nil)
  if valid_607775 != nil:
    section.add "X-Amz-Content-Sha256", valid_607775
  var valid_607776 = header.getOrDefault("X-Amz-Date")
  valid_607776 = validateParameter(valid_607776, JString, required = false,
                                 default = nil)
  if valid_607776 != nil:
    section.add "X-Amz-Date", valid_607776
  var valid_607777 = header.getOrDefault("X-Amz-Credential")
  valid_607777 = validateParameter(valid_607777, JString, required = false,
                                 default = nil)
  if valid_607777 != nil:
    section.add "X-Amz-Credential", valid_607777
  var valid_607778 = header.getOrDefault("X-Amz-Security-Token")
  valid_607778 = validateParameter(valid_607778, JString, required = false,
                                 default = nil)
  if valid_607778 != nil:
    section.add "X-Amz-Security-Token", valid_607778
  var valid_607779 = header.getOrDefault("X-Amz-Algorithm")
  valid_607779 = validateParameter(valid_607779, JString, required = false,
                                 default = nil)
  if valid_607779 != nil:
    section.add "X-Amz-Algorithm", valid_607779
  var valid_607780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607780 = validateParameter(valid_607780, JString, required = false,
                                 default = nil)
  if valid_607780 != nil:
    section.add "X-Amz-SignedHeaders", valid_607780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607781: Call_GetModifyDBSubnetGroup_607766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607781.validator(path, query, header, formData, body)
  let scheme = call_607781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607781.url(scheme.get, call_607781.host, call_607781.base,
                         call_607781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607781, url, valid)

proc call*(call_607782: Call_GetModifyDBSubnetGroup_607766; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_607783 = newJObject()
  if SubnetIds != nil:
    query_607783.add "SubnetIds", SubnetIds
  add(query_607783, "Action", newJString(Action))
  add(query_607783, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_607783, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607783, "Version", newJString(Version))
  result = call_607782.call(nil, query_607783, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_607766(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_607767, base: "/",
    url: url_GetModifyDBSubnetGroup_607768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_607823 = ref object of OpenApiRestCall_605573
proc url_PostModifyEventSubscription_607825(protocol: Scheme; host: string;
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

proc validate_PostModifyEventSubscription_607824(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607826 = query.getOrDefault("Action")
  valid_607826 = validateParameter(valid_607826, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_607826 != nil:
    section.add "Action", valid_607826
  var valid_607827 = query.getOrDefault("Version")
  valid_607827 = validateParameter(valid_607827, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607827 != nil:
    section.add "Version", valid_607827
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607828 = header.getOrDefault("X-Amz-Signature")
  valid_607828 = validateParameter(valid_607828, JString, required = false,
                                 default = nil)
  if valid_607828 != nil:
    section.add "X-Amz-Signature", valid_607828
  var valid_607829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607829 = validateParameter(valid_607829, JString, required = false,
                                 default = nil)
  if valid_607829 != nil:
    section.add "X-Amz-Content-Sha256", valid_607829
  var valid_607830 = header.getOrDefault("X-Amz-Date")
  valid_607830 = validateParameter(valid_607830, JString, required = false,
                                 default = nil)
  if valid_607830 != nil:
    section.add "X-Amz-Date", valid_607830
  var valid_607831 = header.getOrDefault("X-Amz-Credential")
  valid_607831 = validateParameter(valid_607831, JString, required = false,
                                 default = nil)
  if valid_607831 != nil:
    section.add "X-Amz-Credential", valid_607831
  var valid_607832 = header.getOrDefault("X-Amz-Security-Token")
  valid_607832 = validateParameter(valid_607832, JString, required = false,
                                 default = nil)
  if valid_607832 != nil:
    section.add "X-Amz-Security-Token", valid_607832
  var valid_607833 = header.getOrDefault("X-Amz-Algorithm")
  valid_607833 = validateParameter(valid_607833, JString, required = false,
                                 default = nil)
  if valid_607833 != nil:
    section.add "X-Amz-Algorithm", valid_607833
  var valid_607834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607834 = validateParameter(valid_607834, JString, required = false,
                                 default = nil)
  if valid_607834 != nil:
    section.add "X-Amz-SignedHeaders", valid_607834
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_607835 = formData.getOrDefault("SnsTopicArn")
  valid_607835 = validateParameter(valid_607835, JString, required = false,
                                 default = nil)
  if valid_607835 != nil:
    section.add "SnsTopicArn", valid_607835
  var valid_607836 = formData.getOrDefault("Enabled")
  valid_607836 = validateParameter(valid_607836, JBool, required = false, default = nil)
  if valid_607836 != nil:
    section.add "Enabled", valid_607836
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_607837 = formData.getOrDefault("SubscriptionName")
  valid_607837 = validateParameter(valid_607837, JString, required = true,
                                 default = nil)
  if valid_607837 != nil:
    section.add "SubscriptionName", valid_607837
  var valid_607838 = formData.getOrDefault("SourceType")
  valid_607838 = validateParameter(valid_607838, JString, required = false,
                                 default = nil)
  if valid_607838 != nil:
    section.add "SourceType", valid_607838
  var valid_607839 = formData.getOrDefault("EventCategories")
  valid_607839 = validateParameter(valid_607839, JArray, required = false,
                                 default = nil)
  if valid_607839 != nil:
    section.add "EventCategories", valid_607839
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607840: Call_PostModifyEventSubscription_607823; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607840.validator(path, query, header, formData, body)
  let scheme = call_607840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607840.url(scheme.get, call_607840.host, call_607840.base,
                         call_607840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607840, url, valid)

proc call*(call_607841: Call_PostModifyEventSubscription_607823;
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
  var query_607842 = newJObject()
  var formData_607843 = newJObject()
  add(formData_607843, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_607843, "Enabled", newJBool(Enabled))
  add(formData_607843, "SubscriptionName", newJString(SubscriptionName))
  add(formData_607843, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_607843.add "EventCategories", EventCategories
  add(query_607842, "Action", newJString(Action))
  add(query_607842, "Version", newJString(Version))
  result = call_607841.call(nil, query_607842, nil, formData_607843, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_607823(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_607824, base: "/",
    url: url_PostModifyEventSubscription_607825,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_607803 = ref object of OpenApiRestCall_605573
proc url_GetModifyEventSubscription_607805(protocol: Scheme; host: string;
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

proc validate_GetModifyEventSubscription_607804(path: JsonNode; query: JsonNode;
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
  var valid_607806 = query.getOrDefault("SourceType")
  valid_607806 = validateParameter(valid_607806, JString, required = false,
                                 default = nil)
  if valid_607806 != nil:
    section.add "SourceType", valid_607806
  var valid_607807 = query.getOrDefault("Enabled")
  valid_607807 = validateParameter(valid_607807, JBool, required = false, default = nil)
  if valid_607807 != nil:
    section.add "Enabled", valid_607807
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_607808 = query.getOrDefault("SubscriptionName")
  valid_607808 = validateParameter(valid_607808, JString, required = true,
                                 default = nil)
  if valid_607808 != nil:
    section.add "SubscriptionName", valid_607808
  var valid_607809 = query.getOrDefault("EventCategories")
  valid_607809 = validateParameter(valid_607809, JArray, required = false,
                                 default = nil)
  if valid_607809 != nil:
    section.add "EventCategories", valid_607809
  var valid_607810 = query.getOrDefault("Action")
  valid_607810 = validateParameter(valid_607810, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_607810 != nil:
    section.add "Action", valid_607810
  var valid_607811 = query.getOrDefault("SnsTopicArn")
  valid_607811 = validateParameter(valid_607811, JString, required = false,
                                 default = nil)
  if valid_607811 != nil:
    section.add "SnsTopicArn", valid_607811
  var valid_607812 = query.getOrDefault("Version")
  valid_607812 = validateParameter(valid_607812, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607812 != nil:
    section.add "Version", valid_607812
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607813 = header.getOrDefault("X-Amz-Signature")
  valid_607813 = validateParameter(valid_607813, JString, required = false,
                                 default = nil)
  if valid_607813 != nil:
    section.add "X-Amz-Signature", valid_607813
  var valid_607814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607814 = validateParameter(valid_607814, JString, required = false,
                                 default = nil)
  if valid_607814 != nil:
    section.add "X-Amz-Content-Sha256", valid_607814
  var valid_607815 = header.getOrDefault("X-Amz-Date")
  valid_607815 = validateParameter(valid_607815, JString, required = false,
                                 default = nil)
  if valid_607815 != nil:
    section.add "X-Amz-Date", valid_607815
  var valid_607816 = header.getOrDefault("X-Amz-Credential")
  valid_607816 = validateParameter(valid_607816, JString, required = false,
                                 default = nil)
  if valid_607816 != nil:
    section.add "X-Amz-Credential", valid_607816
  var valid_607817 = header.getOrDefault("X-Amz-Security-Token")
  valid_607817 = validateParameter(valid_607817, JString, required = false,
                                 default = nil)
  if valid_607817 != nil:
    section.add "X-Amz-Security-Token", valid_607817
  var valid_607818 = header.getOrDefault("X-Amz-Algorithm")
  valid_607818 = validateParameter(valid_607818, JString, required = false,
                                 default = nil)
  if valid_607818 != nil:
    section.add "X-Amz-Algorithm", valid_607818
  var valid_607819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607819 = validateParameter(valid_607819, JString, required = false,
                                 default = nil)
  if valid_607819 != nil:
    section.add "X-Amz-SignedHeaders", valid_607819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607820: Call_GetModifyEventSubscription_607803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607820.validator(path, query, header, formData, body)
  let scheme = call_607820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607820.url(scheme.get, call_607820.host, call_607820.base,
                         call_607820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607820, url, valid)

proc call*(call_607821: Call_GetModifyEventSubscription_607803;
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
  var query_607822 = newJObject()
  add(query_607822, "SourceType", newJString(SourceType))
  add(query_607822, "Enabled", newJBool(Enabled))
  add(query_607822, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_607822.add "EventCategories", EventCategories
  add(query_607822, "Action", newJString(Action))
  add(query_607822, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_607822, "Version", newJString(Version))
  result = call_607821.call(nil, query_607822, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_607803(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_607804, base: "/",
    url: url_GetModifyEventSubscription_607805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_607863 = ref object of OpenApiRestCall_605573
proc url_PostModifyOptionGroup_607865(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyOptionGroup_607864(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607866 = query.getOrDefault("Action")
  valid_607866 = validateParameter(valid_607866, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_607866 != nil:
    section.add "Action", valid_607866
  var valid_607867 = query.getOrDefault("Version")
  valid_607867 = validateParameter(valid_607867, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607867 != nil:
    section.add "Version", valid_607867
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607868 = header.getOrDefault("X-Amz-Signature")
  valid_607868 = validateParameter(valid_607868, JString, required = false,
                                 default = nil)
  if valid_607868 != nil:
    section.add "X-Amz-Signature", valid_607868
  var valid_607869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607869 = validateParameter(valid_607869, JString, required = false,
                                 default = nil)
  if valid_607869 != nil:
    section.add "X-Amz-Content-Sha256", valid_607869
  var valid_607870 = header.getOrDefault("X-Amz-Date")
  valid_607870 = validateParameter(valid_607870, JString, required = false,
                                 default = nil)
  if valid_607870 != nil:
    section.add "X-Amz-Date", valid_607870
  var valid_607871 = header.getOrDefault("X-Amz-Credential")
  valid_607871 = validateParameter(valid_607871, JString, required = false,
                                 default = nil)
  if valid_607871 != nil:
    section.add "X-Amz-Credential", valid_607871
  var valid_607872 = header.getOrDefault("X-Amz-Security-Token")
  valid_607872 = validateParameter(valid_607872, JString, required = false,
                                 default = nil)
  if valid_607872 != nil:
    section.add "X-Amz-Security-Token", valid_607872
  var valid_607873 = header.getOrDefault("X-Amz-Algorithm")
  valid_607873 = validateParameter(valid_607873, JString, required = false,
                                 default = nil)
  if valid_607873 != nil:
    section.add "X-Amz-Algorithm", valid_607873
  var valid_607874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607874 = validateParameter(valid_607874, JString, required = false,
                                 default = nil)
  if valid_607874 != nil:
    section.add "X-Amz-SignedHeaders", valid_607874
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_607875 = formData.getOrDefault("OptionsToRemove")
  valid_607875 = validateParameter(valid_607875, JArray, required = false,
                                 default = nil)
  if valid_607875 != nil:
    section.add "OptionsToRemove", valid_607875
  var valid_607876 = formData.getOrDefault("ApplyImmediately")
  valid_607876 = validateParameter(valid_607876, JBool, required = false, default = nil)
  if valid_607876 != nil:
    section.add "ApplyImmediately", valid_607876
  var valid_607877 = formData.getOrDefault("OptionsToInclude")
  valid_607877 = validateParameter(valid_607877, JArray, required = false,
                                 default = nil)
  if valid_607877 != nil:
    section.add "OptionsToInclude", valid_607877
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_607878 = formData.getOrDefault("OptionGroupName")
  valid_607878 = validateParameter(valid_607878, JString, required = true,
                                 default = nil)
  if valid_607878 != nil:
    section.add "OptionGroupName", valid_607878
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607879: Call_PostModifyOptionGroup_607863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607879.validator(path, query, header, formData, body)
  let scheme = call_607879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607879.url(scheme.get, call_607879.host, call_607879.base,
                         call_607879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607879, url, valid)

proc call*(call_607880: Call_PostModifyOptionGroup_607863; OptionGroupName: string;
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
  var query_607881 = newJObject()
  var formData_607882 = newJObject()
  if OptionsToRemove != nil:
    formData_607882.add "OptionsToRemove", OptionsToRemove
  add(formData_607882, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_607882.add "OptionsToInclude", OptionsToInclude
  add(query_607881, "Action", newJString(Action))
  add(formData_607882, "OptionGroupName", newJString(OptionGroupName))
  add(query_607881, "Version", newJString(Version))
  result = call_607880.call(nil, query_607881, nil, formData_607882, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_607863(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_607864, base: "/",
    url: url_PostModifyOptionGroup_607865, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_607844 = ref object of OpenApiRestCall_605573
proc url_GetModifyOptionGroup_607846(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyOptionGroup_607845(path: JsonNode; query: JsonNode;
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
  var valid_607847 = query.getOrDefault("Action")
  valid_607847 = validateParameter(valid_607847, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_607847 != nil:
    section.add "Action", valid_607847
  var valid_607848 = query.getOrDefault("ApplyImmediately")
  valid_607848 = validateParameter(valid_607848, JBool, required = false, default = nil)
  if valid_607848 != nil:
    section.add "ApplyImmediately", valid_607848
  var valid_607849 = query.getOrDefault("OptionsToRemove")
  valid_607849 = validateParameter(valid_607849, JArray, required = false,
                                 default = nil)
  if valid_607849 != nil:
    section.add "OptionsToRemove", valid_607849
  var valid_607850 = query.getOrDefault("OptionsToInclude")
  valid_607850 = validateParameter(valid_607850, JArray, required = false,
                                 default = nil)
  if valid_607850 != nil:
    section.add "OptionsToInclude", valid_607850
  var valid_607851 = query.getOrDefault("OptionGroupName")
  valid_607851 = validateParameter(valid_607851, JString, required = true,
                                 default = nil)
  if valid_607851 != nil:
    section.add "OptionGroupName", valid_607851
  var valid_607852 = query.getOrDefault("Version")
  valid_607852 = validateParameter(valid_607852, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607852 != nil:
    section.add "Version", valid_607852
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607853 = header.getOrDefault("X-Amz-Signature")
  valid_607853 = validateParameter(valid_607853, JString, required = false,
                                 default = nil)
  if valid_607853 != nil:
    section.add "X-Amz-Signature", valid_607853
  var valid_607854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607854 = validateParameter(valid_607854, JString, required = false,
                                 default = nil)
  if valid_607854 != nil:
    section.add "X-Amz-Content-Sha256", valid_607854
  var valid_607855 = header.getOrDefault("X-Amz-Date")
  valid_607855 = validateParameter(valid_607855, JString, required = false,
                                 default = nil)
  if valid_607855 != nil:
    section.add "X-Amz-Date", valid_607855
  var valid_607856 = header.getOrDefault("X-Amz-Credential")
  valid_607856 = validateParameter(valid_607856, JString, required = false,
                                 default = nil)
  if valid_607856 != nil:
    section.add "X-Amz-Credential", valid_607856
  var valid_607857 = header.getOrDefault("X-Amz-Security-Token")
  valid_607857 = validateParameter(valid_607857, JString, required = false,
                                 default = nil)
  if valid_607857 != nil:
    section.add "X-Amz-Security-Token", valid_607857
  var valid_607858 = header.getOrDefault("X-Amz-Algorithm")
  valid_607858 = validateParameter(valid_607858, JString, required = false,
                                 default = nil)
  if valid_607858 != nil:
    section.add "X-Amz-Algorithm", valid_607858
  var valid_607859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607859 = validateParameter(valid_607859, JString, required = false,
                                 default = nil)
  if valid_607859 != nil:
    section.add "X-Amz-SignedHeaders", valid_607859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607860: Call_GetModifyOptionGroup_607844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607860.validator(path, query, header, formData, body)
  let scheme = call_607860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607860.url(scheme.get, call_607860.host, call_607860.base,
                         call_607860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607860, url, valid)

proc call*(call_607861: Call_GetModifyOptionGroup_607844; OptionGroupName: string;
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
  var query_607862 = newJObject()
  add(query_607862, "Action", newJString(Action))
  add(query_607862, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_607862.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_607862.add "OptionsToInclude", OptionsToInclude
  add(query_607862, "OptionGroupName", newJString(OptionGroupName))
  add(query_607862, "Version", newJString(Version))
  result = call_607861.call(nil, query_607862, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_607844(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_607845, base: "/",
    url: url_GetModifyOptionGroup_607846, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_607901 = ref object of OpenApiRestCall_605573
proc url_PostPromoteReadReplica_607903(protocol: Scheme; host: string; base: string;
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

proc validate_PostPromoteReadReplica_607902(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607904 = query.getOrDefault("Action")
  valid_607904 = validateParameter(valid_607904, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_607904 != nil:
    section.add "Action", valid_607904
  var valid_607905 = query.getOrDefault("Version")
  valid_607905 = validateParameter(valid_607905, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607905 != nil:
    section.add "Version", valid_607905
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607906 = header.getOrDefault("X-Amz-Signature")
  valid_607906 = validateParameter(valid_607906, JString, required = false,
                                 default = nil)
  if valid_607906 != nil:
    section.add "X-Amz-Signature", valid_607906
  var valid_607907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607907 = validateParameter(valid_607907, JString, required = false,
                                 default = nil)
  if valid_607907 != nil:
    section.add "X-Amz-Content-Sha256", valid_607907
  var valid_607908 = header.getOrDefault("X-Amz-Date")
  valid_607908 = validateParameter(valid_607908, JString, required = false,
                                 default = nil)
  if valid_607908 != nil:
    section.add "X-Amz-Date", valid_607908
  var valid_607909 = header.getOrDefault("X-Amz-Credential")
  valid_607909 = validateParameter(valid_607909, JString, required = false,
                                 default = nil)
  if valid_607909 != nil:
    section.add "X-Amz-Credential", valid_607909
  var valid_607910 = header.getOrDefault("X-Amz-Security-Token")
  valid_607910 = validateParameter(valid_607910, JString, required = false,
                                 default = nil)
  if valid_607910 != nil:
    section.add "X-Amz-Security-Token", valid_607910
  var valid_607911 = header.getOrDefault("X-Amz-Algorithm")
  valid_607911 = validateParameter(valid_607911, JString, required = false,
                                 default = nil)
  if valid_607911 != nil:
    section.add "X-Amz-Algorithm", valid_607911
  var valid_607912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607912 = validateParameter(valid_607912, JString, required = false,
                                 default = nil)
  if valid_607912 != nil:
    section.add "X-Amz-SignedHeaders", valid_607912
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_607913 = formData.getOrDefault("PreferredBackupWindow")
  valid_607913 = validateParameter(valid_607913, JString, required = false,
                                 default = nil)
  if valid_607913 != nil:
    section.add "PreferredBackupWindow", valid_607913
  var valid_607914 = formData.getOrDefault("BackupRetentionPeriod")
  valid_607914 = validateParameter(valid_607914, JInt, required = false, default = nil)
  if valid_607914 != nil:
    section.add "BackupRetentionPeriod", valid_607914
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607915 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607915 = validateParameter(valid_607915, JString, required = true,
                                 default = nil)
  if valid_607915 != nil:
    section.add "DBInstanceIdentifier", valid_607915
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607916: Call_PostPromoteReadReplica_607901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607916.validator(path, query, header, formData, body)
  let scheme = call_607916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607916.url(scheme.get, call_607916.host, call_607916.base,
                         call_607916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607916, url, valid)

proc call*(call_607917: Call_PostPromoteReadReplica_607901;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2013-02-12"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607918 = newJObject()
  var formData_607919 = newJObject()
  add(formData_607919, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_607919, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_607919, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607918, "Action", newJString(Action))
  add(query_607918, "Version", newJString(Version))
  result = call_607917.call(nil, query_607918, nil, formData_607919, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_607901(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_607902, base: "/",
    url: url_PostPromoteReadReplica_607903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_607883 = ref object of OpenApiRestCall_605573
proc url_GetPromoteReadReplica_607885(protocol: Scheme; host: string; base: string;
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

proc validate_GetPromoteReadReplica_607884(path: JsonNode; query: JsonNode;
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
  var valid_607886 = query.getOrDefault("DBInstanceIdentifier")
  valid_607886 = validateParameter(valid_607886, JString, required = true,
                                 default = nil)
  if valid_607886 != nil:
    section.add "DBInstanceIdentifier", valid_607886
  var valid_607887 = query.getOrDefault("BackupRetentionPeriod")
  valid_607887 = validateParameter(valid_607887, JInt, required = false, default = nil)
  if valid_607887 != nil:
    section.add "BackupRetentionPeriod", valid_607887
  var valid_607888 = query.getOrDefault("Action")
  valid_607888 = validateParameter(valid_607888, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_607888 != nil:
    section.add "Action", valid_607888
  var valid_607889 = query.getOrDefault("Version")
  valid_607889 = validateParameter(valid_607889, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607889 != nil:
    section.add "Version", valid_607889
  var valid_607890 = query.getOrDefault("PreferredBackupWindow")
  valid_607890 = validateParameter(valid_607890, JString, required = false,
                                 default = nil)
  if valid_607890 != nil:
    section.add "PreferredBackupWindow", valid_607890
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607891 = header.getOrDefault("X-Amz-Signature")
  valid_607891 = validateParameter(valid_607891, JString, required = false,
                                 default = nil)
  if valid_607891 != nil:
    section.add "X-Amz-Signature", valid_607891
  var valid_607892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607892 = validateParameter(valid_607892, JString, required = false,
                                 default = nil)
  if valid_607892 != nil:
    section.add "X-Amz-Content-Sha256", valid_607892
  var valid_607893 = header.getOrDefault("X-Amz-Date")
  valid_607893 = validateParameter(valid_607893, JString, required = false,
                                 default = nil)
  if valid_607893 != nil:
    section.add "X-Amz-Date", valid_607893
  var valid_607894 = header.getOrDefault("X-Amz-Credential")
  valid_607894 = validateParameter(valid_607894, JString, required = false,
                                 default = nil)
  if valid_607894 != nil:
    section.add "X-Amz-Credential", valid_607894
  var valid_607895 = header.getOrDefault("X-Amz-Security-Token")
  valid_607895 = validateParameter(valid_607895, JString, required = false,
                                 default = nil)
  if valid_607895 != nil:
    section.add "X-Amz-Security-Token", valid_607895
  var valid_607896 = header.getOrDefault("X-Amz-Algorithm")
  valid_607896 = validateParameter(valid_607896, JString, required = false,
                                 default = nil)
  if valid_607896 != nil:
    section.add "X-Amz-Algorithm", valid_607896
  var valid_607897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607897 = validateParameter(valid_607897, JString, required = false,
                                 default = nil)
  if valid_607897 != nil:
    section.add "X-Amz-SignedHeaders", valid_607897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607898: Call_GetPromoteReadReplica_607883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607898.validator(path, query, header, formData, body)
  let scheme = call_607898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607898.url(scheme.get, call_607898.host, call_607898.base,
                         call_607898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607898, url, valid)

proc call*(call_607899: Call_GetPromoteReadReplica_607883;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2013-02-12";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_607900 = newJObject()
  add(query_607900, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607900, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_607900, "Action", newJString(Action))
  add(query_607900, "Version", newJString(Version))
  add(query_607900, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_607899.call(nil, query_607900, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_607883(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_607884, base: "/",
    url: url_GetPromoteReadReplica_607885, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_607938 = ref object of OpenApiRestCall_605573
proc url_PostPurchaseReservedDBInstancesOffering_607940(protocol: Scheme;
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

proc validate_PostPurchaseReservedDBInstancesOffering_607939(path: JsonNode;
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
  var valid_607941 = query.getOrDefault("Action")
  valid_607941 = validateParameter(valid_607941, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_607941 != nil:
    section.add "Action", valid_607941
  var valid_607942 = query.getOrDefault("Version")
  valid_607942 = validateParameter(valid_607942, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607942 != nil:
    section.add "Version", valid_607942
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607943 = header.getOrDefault("X-Amz-Signature")
  valid_607943 = validateParameter(valid_607943, JString, required = false,
                                 default = nil)
  if valid_607943 != nil:
    section.add "X-Amz-Signature", valid_607943
  var valid_607944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607944 = validateParameter(valid_607944, JString, required = false,
                                 default = nil)
  if valid_607944 != nil:
    section.add "X-Amz-Content-Sha256", valid_607944
  var valid_607945 = header.getOrDefault("X-Amz-Date")
  valid_607945 = validateParameter(valid_607945, JString, required = false,
                                 default = nil)
  if valid_607945 != nil:
    section.add "X-Amz-Date", valid_607945
  var valid_607946 = header.getOrDefault("X-Amz-Credential")
  valid_607946 = validateParameter(valid_607946, JString, required = false,
                                 default = nil)
  if valid_607946 != nil:
    section.add "X-Amz-Credential", valid_607946
  var valid_607947 = header.getOrDefault("X-Amz-Security-Token")
  valid_607947 = validateParameter(valid_607947, JString, required = false,
                                 default = nil)
  if valid_607947 != nil:
    section.add "X-Amz-Security-Token", valid_607947
  var valid_607948 = header.getOrDefault("X-Amz-Algorithm")
  valid_607948 = validateParameter(valid_607948, JString, required = false,
                                 default = nil)
  if valid_607948 != nil:
    section.add "X-Amz-Algorithm", valid_607948
  var valid_607949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607949 = validateParameter(valid_607949, JString, required = false,
                                 default = nil)
  if valid_607949 != nil:
    section.add "X-Amz-SignedHeaders", valid_607949
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_607950 = formData.getOrDefault("ReservedDBInstanceId")
  valid_607950 = validateParameter(valid_607950, JString, required = false,
                                 default = nil)
  if valid_607950 != nil:
    section.add "ReservedDBInstanceId", valid_607950
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_607951 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607951 = validateParameter(valid_607951, JString, required = true,
                                 default = nil)
  if valid_607951 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607951
  var valid_607952 = formData.getOrDefault("DBInstanceCount")
  valid_607952 = validateParameter(valid_607952, JInt, required = false, default = nil)
  if valid_607952 != nil:
    section.add "DBInstanceCount", valid_607952
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607953: Call_PostPurchaseReservedDBInstancesOffering_607938;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607953.validator(path, query, header, formData, body)
  let scheme = call_607953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607953.url(scheme.get, call_607953.host, call_607953.base,
                         call_607953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607953, url, valid)

proc call*(call_607954: Call_PostPurchaseReservedDBInstancesOffering_607938;
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
  var query_607955 = newJObject()
  var formData_607956 = newJObject()
  add(formData_607956, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_607955, "Action", newJString(Action))
  add(formData_607956, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607955, "Version", newJString(Version))
  add(formData_607956, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_607954.call(nil, query_607955, nil, formData_607956, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_607938(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_607939, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_607940,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_607920 = ref object of OpenApiRestCall_605573
proc url_GetPurchaseReservedDBInstancesOffering_607922(protocol: Scheme;
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

proc validate_GetPurchaseReservedDBInstancesOffering_607921(path: JsonNode;
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
  var valid_607923 = query.getOrDefault("DBInstanceCount")
  valid_607923 = validateParameter(valid_607923, JInt, required = false, default = nil)
  if valid_607923 != nil:
    section.add "DBInstanceCount", valid_607923
  var valid_607924 = query.getOrDefault("ReservedDBInstanceId")
  valid_607924 = validateParameter(valid_607924, JString, required = false,
                                 default = nil)
  if valid_607924 != nil:
    section.add "ReservedDBInstanceId", valid_607924
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607925 = query.getOrDefault("Action")
  valid_607925 = validateParameter(valid_607925, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_607925 != nil:
    section.add "Action", valid_607925
  var valid_607926 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607926 = validateParameter(valid_607926, JString, required = true,
                                 default = nil)
  if valid_607926 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607926
  var valid_607927 = query.getOrDefault("Version")
  valid_607927 = validateParameter(valid_607927, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607927 != nil:
    section.add "Version", valid_607927
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607928 = header.getOrDefault("X-Amz-Signature")
  valid_607928 = validateParameter(valid_607928, JString, required = false,
                                 default = nil)
  if valid_607928 != nil:
    section.add "X-Amz-Signature", valid_607928
  var valid_607929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607929 = validateParameter(valid_607929, JString, required = false,
                                 default = nil)
  if valid_607929 != nil:
    section.add "X-Amz-Content-Sha256", valid_607929
  var valid_607930 = header.getOrDefault("X-Amz-Date")
  valid_607930 = validateParameter(valid_607930, JString, required = false,
                                 default = nil)
  if valid_607930 != nil:
    section.add "X-Amz-Date", valid_607930
  var valid_607931 = header.getOrDefault("X-Amz-Credential")
  valid_607931 = validateParameter(valid_607931, JString, required = false,
                                 default = nil)
  if valid_607931 != nil:
    section.add "X-Amz-Credential", valid_607931
  var valid_607932 = header.getOrDefault("X-Amz-Security-Token")
  valid_607932 = validateParameter(valid_607932, JString, required = false,
                                 default = nil)
  if valid_607932 != nil:
    section.add "X-Amz-Security-Token", valid_607932
  var valid_607933 = header.getOrDefault("X-Amz-Algorithm")
  valid_607933 = validateParameter(valid_607933, JString, required = false,
                                 default = nil)
  if valid_607933 != nil:
    section.add "X-Amz-Algorithm", valid_607933
  var valid_607934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607934 = validateParameter(valid_607934, JString, required = false,
                                 default = nil)
  if valid_607934 != nil:
    section.add "X-Amz-SignedHeaders", valid_607934
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607935: Call_GetPurchaseReservedDBInstancesOffering_607920;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607935.validator(path, query, header, formData, body)
  let scheme = call_607935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607935.url(scheme.get, call_607935.host, call_607935.base,
                         call_607935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607935, url, valid)

proc call*(call_607936: Call_GetPurchaseReservedDBInstancesOffering_607920;
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
  var query_607937 = newJObject()
  add(query_607937, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_607937, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_607937, "Action", newJString(Action))
  add(query_607937, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607937, "Version", newJString(Version))
  result = call_607936.call(nil, query_607937, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_607920(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_607921, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_607922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_607974 = ref object of OpenApiRestCall_605573
proc url_PostRebootDBInstance_607976(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebootDBInstance_607975(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607977 = query.getOrDefault("Action")
  valid_607977 = validateParameter(valid_607977, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_607977 != nil:
    section.add "Action", valid_607977
  var valid_607978 = query.getOrDefault("Version")
  valid_607978 = validateParameter(valid_607978, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607978 != nil:
    section.add "Version", valid_607978
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607979 = header.getOrDefault("X-Amz-Signature")
  valid_607979 = validateParameter(valid_607979, JString, required = false,
                                 default = nil)
  if valid_607979 != nil:
    section.add "X-Amz-Signature", valid_607979
  var valid_607980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607980 = validateParameter(valid_607980, JString, required = false,
                                 default = nil)
  if valid_607980 != nil:
    section.add "X-Amz-Content-Sha256", valid_607980
  var valid_607981 = header.getOrDefault("X-Amz-Date")
  valid_607981 = validateParameter(valid_607981, JString, required = false,
                                 default = nil)
  if valid_607981 != nil:
    section.add "X-Amz-Date", valid_607981
  var valid_607982 = header.getOrDefault("X-Amz-Credential")
  valid_607982 = validateParameter(valid_607982, JString, required = false,
                                 default = nil)
  if valid_607982 != nil:
    section.add "X-Amz-Credential", valid_607982
  var valid_607983 = header.getOrDefault("X-Amz-Security-Token")
  valid_607983 = validateParameter(valid_607983, JString, required = false,
                                 default = nil)
  if valid_607983 != nil:
    section.add "X-Amz-Security-Token", valid_607983
  var valid_607984 = header.getOrDefault("X-Amz-Algorithm")
  valid_607984 = validateParameter(valid_607984, JString, required = false,
                                 default = nil)
  if valid_607984 != nil:
    section.add "X-Amz-Algorithm", valid_607984
  var valid_607985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607985 = validateParameter(valid_607985, JString, required = false,
                                 default = nil)
  if valid_607985 != nil:
    section.add "X-Amz-SignedHeaders", valid_607985
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_607986 = formData.getOrDefault("ForceFailover")
  valid_607986 = validateParameter(valid_607986, JBool, required = false, default = nil)
  if valid_607986 != nil:
    section.add "ForceFailover", valid_607986
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607987 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607987 = validateParameter(valid_607987, JString, required = true,
                                 default = nil)
  if valid_607987 != nil:
    section.add "DBInstanceIdentifier", valid_607987
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607988: Call_PostRebootDBInstance_607974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607988.validator(path, query, header, formData, body)
  let scheme = call_607988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607988.url(scheme.get, call_607988.host, call_607988.base,
                         call_607988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607988, url, valid)

proc call*(call_607989: Call_PostRebootDBInstance_607974;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-02-12"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607990 = newJObject()
  var formData_607991 = newJObject()
  add(formData_607991, "ForceFailover", newJBool(ForceFailover))
  add(formData_607991, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607990, "Action", newJString(Action))
  add(query_607990, "Version", newJString(Version))
  result = call_607989.call(nil, query_607990, nil, formData_607991, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_607974(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_607975, base: "/",
    url: url_PostRebootDBInstance_607976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_607957 = ref object of OpenApiRestCall_605573
proc url_GetRebootDBInstance_607959(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebootDBInstance_607958(path: JsonNode; query: JsonNode;
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
  var valid_607960 = query.getOrDefault("ForceFailover")
  valid_607960 = validateParameter(valid_607960, JBool, required = false, default = nil)
  if valid_607960 != nil:
    section.add "ForceFailover", valid_607960
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607961 = query.getOrDefault("DBInstanceIdentifier")
  valid_607961 = validateParameter(valid_607961, JString, required = true,
                                 default = nil)
  if valid_607961 != nil:
    section.add "DBInstanceIdentifier", valid_607961
  var valid_607962 = query.getOrDefault("Action")
  valid_607962 = validateParameter(valid_607962, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_607962 != nil:
    section.add "Action", valid_607962
  var valid_607963 = query.getOrDefault("Version")
  valid_607963 = validateParameter(valid_607963, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607963 != nil:
    section.add "Version", valid_607963
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607964 = header.getOrDefault("X-Amz-Signature")
  valid_607964 = validateParameter(valid_607964, JString, required = false,
                                 default = nil)
  if valid_607964 != nil:
    section.add "X-Amz-Signature", valid_607964
  var valid_607965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607965 = validateParameter(valid_607965, JString, required = false,
                                 default = nil)
  if valid_607965 != nil:
    section.add "X-Amz-Content-Sha256", valid_607965
  var valid_607966 = header.getOrDefault("X-Amz-Date")
  valid_607966 = validateParameter(valid_607966, JString, required = false,
                                 default = nil)
  if valid_607966 != nil:
    section.add "X-Amz-Date", valid_607966
  var valid_607967 = header.getOrDefault("X-Amz-Credential")
  valid_607967 = validateParameter(valid_607967, JString, required = false,
                                 default = nil)
  if valid_607967 != nil:
    section.add "X-Amz-Credential", valid_607967
  var valid_607968 = header.getOrDefault("X-Amz-Security-Token")
  valid_607968 = validateParameter(valid_607968, JString, required = false,
                                 default = nil)
  if valid_607968 != nil:
    section.add "X-Amz-Security-Token", valid_607968
  var valid_607969 = header.getOrDefault("X-Amz-Algorithm")
  valid_607969 = validateParameter(valid_607969, JString, required = false,
                                 default = nil)
  if valid_607969 != nil:
    section.add "X-Amz-Algorithm", valid_607969
  var valid_607970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607970 = validateParameter(valid_607970, JString, required = false,
                                 default = nil)
  if valid_607970 != nil:
    section.add "X-Amz-SignedHeaders", valid_607970
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607971: Call_GetRebootDBInstance_607957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607971.validator(path, query, header, formData, body)
  let scheme = call_607971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607971.url(scheme.get, call_607971.host, call_607971.base,
                         call_607971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607971, url, valid)

proc call*(call_607972: Call_GetRebootDBInstance_607957;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-02-12"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607973 = newJObject()
  add(query_607973, "ForceFailover", newJBool(ForceFailover))
  add(query_607973, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607973, "Action", newJString(Action))
  add(query_607973, "Version", newJString(Version))
  result = call_607972.call(nil, query_607973, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_607957(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_607958, base: "/",
    url: url_GetRebootDBInstance_607959, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_608009 = ref object of OpenApiRestCall_605573
proc url_PostRemoveSourceIdentifierFromSubscription_608011(protocol: Scheme;
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

proc validate_PostRemoveSourceIdentifierFromSubscription_608010(path: JsonNode;
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
  var valid_608012 = query.getOrDefault("Action")
  valid_608012 = validateParameter(valid_608012, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_608012 != nil:
    section.add "Action", valid_608012
  var valid_608013 = query.getOrDefault("Version")
  valid_608013 = validateParameter(valid_608013, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_608013 != nil:
    section.add "Version", valid_608013
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608014 = header.getOrDefault("X-Amz-Signature")
  valid_608014 = validateParameter(valid_608014, JString, required = false,
                                 default = nil)
  if valid_608014 != nil:
    section.add "X-Amz-Signature", valid_608014
  var valid_608015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608015 = validateParameter(valid_608015, JString, required = false,
                                 default = nil)
  if valid_608015 != nil:
    section.add "X-Amz-Content-Sha256", valid_608015
  var valid_608016 = header.getOrDefault("X-Amz-Date")
  valid_608016 = validateParameter(valid_608016, JString, required = false,
                                 default = nil)
  if valid_608016 != nil:
    section.add "X-Amz-Date", valid_608016
  var valid_608017 = header.getOrDefault("X-Amz-Credential")
  valid_608017 = validateParameter(valid_608017, JString, required = false,
                                 default = nil)
  if valid_608017 != nil:
    section.add "X-Amz-Credential", valid_608017
  var valid_608018 = header.getOrDefault("X-Amz-Security-Token")
  valid_608018 = validateParameter(valid_608018, JString, required = false,
                                 default = nil)
  if valid_608018 != nil:
    section.add "X-Amz-Security-Token", valid_608018
  var valid_608019 = header.getOrDefault("X-Amz-Algorithm")
  valid_608019 = validateParameter(valid_608019, JString, required = false,
                                 default = nil)
  if valid_608019 != nil:
    section.add "X-Amz-Algorithm", valid_608019
  var valid_608020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608020 = validateParameter(valid_608020, JString, required = false,
                                 default = nil)
  if valid_608020 != nil:
    section.add "X-Amz-SignedHeaders", valid_608020
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_608021 = formData.getOrDefault("SubscriptionName")
  valid_608021 = validateParameter(valid_608021, JString, required = true,
                                 default = nil)
  if valid_608021 != nil:
    section.add "SubscriptionName", valid_608021
  var valid_608022 = formData.getOrDefault("SourceIdentifier")
  valid_608022 = validateParameter(valid_608022, JString, required = true,
                                 default = nil)
  if valid_608022 != nil:
    section.add "SourceIdentifier", valid_608022
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608023: Call_PostRemoveSourceIdentifierFromSubscription_608009;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608023.validator(path, query, header, formData, body)
  let scheme = call_608023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608023.url(scheme.get, call_608023.host, call_608023.base,
                         call_608023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608023, url, valid)

proc call*(call_608024: Call_PostRemoveSourceIdentifierFromSubscription_608009;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608025 = newJObject()
  var formData_608026 = newJObject()
  add(formData_608026, "SubscriptionName", newJString(SubscriptionName))
  add(formData_608026, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_608025, "Action", newJString(Action))
  add(query_608025, "Version", newJString(Version))
  result = call_608024.call(nil, query_608025, nil, formData_608026, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_608009(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_608010,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_608011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_607992 = ref object of OpenApiRestCall_605573
proc url_GetRemoveSourceIdentifierFromSubscription_607994(protocol: Scheme;
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

proc validate_GetRemoveSourceIdentifierFromSubscription_607993(path: JsonNode;
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
  var valid_607995 = query.getOrDefault("SourceIdentifier")
  valid_607995 = validateParameter(valid_607995, JString, required = true,
                                 default = nil)
  if valid_607995 != nil:
    section.add "SourceIdentifier", valid_607995
  var valid_607996 = query.getOrDefault("SubscriptionName")
  valid_607996 = validateParameter(valid_607996, JString, required = true,
                                 default = nil)
  if valid_607996 != nil:
    section.add "SubscriptionName", valid_607996
  var valid_607997 = query.getOrDefault("Action")
  valid_607997 = validateParameter(valid_607997, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_607997 != nil:
    section.add "Action", valid_607997
  var valid_607998 = query.getOrDefault("Version")
  valid_607998 = validateParameter(valid_607998, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_607998 != nil:
    section.add "Version", valid_607998
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607999 = header.getOrDefault("X-Amz-Signature")
  valid_607999 = validateParameter(valid_607999, JString, required = false,
                                 default = nil)
  if valid_607999 != nil:
    section.add "X-Amz-Signature", valid_607999
  var valid_608000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608000 = validateParameter(valid_608000, JString, required = false,
                                 default = nil)
  if valid_608000 != nil:
    section.add "X-Amz-Content-Sha256", valid_608000
  var valid_608001 = header.getOrDefault("X-Amz-Date")
  valid_608001 = validateParameter(valid_608001, JString, required = false,
                                 default = nil)
  if valid_608001 != nil:
    section.add "X-Amz-Date", valid_608001
  var valid_608002 = header.getOrDefault("X-Amz-Credential")
  valid_608002 = validateParameter(valid_608002, JString, required = false,
                                 default = nil)
  if valid_608002 != nil:
    section.add "X-Amz-Credential", valid_608002
  var valid_608003 = header.getOrDefault("X-Amz-Security-Token")
  valid_608003 = validateParameter(valid_608003, JString, required = false,
                                 default = nil)
  if valid_608003 != nil:
    section.add "X-Amz-Security-Token", valid_608003
  var valid_608004 = header.getOrDefault("X-Amz-Algorithm")
  valid_608004 = validateParameter(valid_608004, JString, required = false,
                                 default = nil)
  if valid_608004 != nil:
    section.add "X-Amz-Algorithm", valid_608004
  var valid_608005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608005 = validateParameter(valid_608005, JString, required = false,
                                 default = nil)
  if valid_608005 != nil:
    section.add "X-Amz-SignedHeaders", valid_608005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608006: Call_GetRemoveSourceIdentifierFromSubscription_607992;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608006.validator(path, query, header, formData, body)
  let scheme = call_608006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608006.url(scheme.get, call_608006.host, call_608006.base,
                         call_608006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608006, url, valid)

proc call*(call_608007: Call_GetRemoveSourceIdentifierFromSubscription_607992;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608008 = newJObject()
  add(query_608008, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_608008, "SubscriptionName", newJString(SubscriptionName))
  add(query_608008, "Action", newJString(Action))
  add(query_608008, "Version", newJString(Version))
  result = call_608007.call(nil, query_608008, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_607992(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_607993,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_607994,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_608044 = ref object of OpenApiRestCall_605573
proc url_PostRemoveTagsFromResource_608046(protocol: Scheme; host: string;
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

proc validate_PostRemoveTagsFromResource_608045(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_608047 = query.getOrDefault("Action")
  valid_608047 = validateParameter(valid_608047, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_608047 != nil:
    section.add "Action", valid_608047
  var valid_608048 = query.getOrDefault("Version")
  valid_608048 = validateParameter(valid_608048, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_608048 != nil:
    section.add "Version", valid_608048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608049 = header.getOrDefault("X-Amz-Signature")
  valid_608049 = validateParameter(valid_608049, JString, required = false,
                                 default = nil)
  if valid_608049 != nil:
    section.add "X-Amz-Signature", valid_608049
  var valid_608050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608050 = validateParameter(valid_608050, JString, required = false,
                                 default = nil)
  if valid_608050 != nil:
    section.add "X-Amz-Content-Sha256", valid_608050
  var valid_608051 = header.getOrDefault("X-Amz-Date")
  valid_608051 = validateParameter(valid_608051, JString, required = false,
                                 default = nil)
  if valid_608051 != nil:
    section.add "X-Amz-Date", valid_608051
  var valid_608052 = header.getOrDefault("X-Amz-Credential")
  valid_608052 = validateParameter(valid_608052, JString, required = false,
                                 default = nil)
  if valid_608052 != nil:
    section.add "X-Amz-Credential", valid_608052
  var valid_608053 = header.getOrDefault("X-Amz-Security-Token")
  valid_608053 = validateParameter(valid_608053, JString, required = false,
                                 default = nil)
  if valid_608053 != nil:
    section.add "X-Amz-Security-Token", valid_608053
  var valid_608054 = header.getOrDefault("X-Amz-Algorithm")
  valid_608054 = validateParameter(valid_608054, JString, required = false,
                                 default = nil)
  if valid_608054 != nil:
    section.add "X-Amz-Algorithm", valid_608054
  var valid_608055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608055 = validateParameter(valid_608055, JString, required = false,
                                 default = nil)
  if valid_608055 != nil:
    section.add "X-Amz-SignedHeaders", valid_608055
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_608056 = formData.getOrDefault("TagKeys")
  valid_608056 = validateParameter(valid_608056, JArray, required = true, default = nil)
  if valid_608056 != nil:
    section.add "TagKeys", valid_608056
  var valid_608057 = formData.getOrDefault("ResourceName")
  valid_608057 = validateParameter(valid_608057, JString, required = true,
                                 default = nil)
  if valid_608057 != nil:
    section.add "ResourceName", valid_608057
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608058: Call_PostRemoveTagsFromResource_608044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608058.validator(path, query, header, formData, body)
  let scheme = call_608058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608058.url(scheme.get, call_608058.host, call_608058.base,
                         call_608058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608058, url, valid)

proc call*(call_608059: Call_PostRemoveTagsFromResource_608044; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_608060 = newJObject()
  var formData_608061 = newJObject()
  if TagKeys != nil:
    formData_608061.add "TagKeys", TagKeys
  add(query_608060, "Action", newJString(Action))
  add(query_608060, "Version", newJString(Version))
  add(formData_608061, "ResourceName", newJString(ResourceName))
  result = call_608059.call(nil, query_608060, nil, formData_608061, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_608044(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_608045, base: "/",
    url: url_PostRemoveTagsFromResource_608046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_608027 = ref object of OpenApiRestCall_605573
proc url_GetRemoveTagsFromResource_608029(protocol: Scheme; host: string;
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

proc validate_GetRemoveTagsFromResource_608028(path: JsonNode; query: JsonNode;
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
  var valid_608030 = query.getOrDefault("ResourceName")
  valid_608030 = validateParameter(valid_608030, JString, required = true,
                                 default = nil)
  if valid_608030 != nil:
    section.add "ResourceName", valid_608030
  var valid_608031 = query.getOrDefault("TagKeys")
  valid_608031 = validateParameter(valid_608031, JArray, required = true, default = nil)
  if valid_608031 != nil:
    section.add "TagKeys", valid_608031
  var valid_608032 = query.getOrDefault("Action")
  valid_608032 = validateParameter(valid_608032, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_608032 != nil:
    section.add "Action", valid_608032
  var valid_608033 = query.getOrDefault("Version")
  valid_608033 = validateParameter(valid_608033, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_608033 != nil:
    section.add "Version", valid_608033
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608034 = header.getOrDefault("X-Amz-Signature")
  valid_608034 = validateParameter(valid_608034, JString, required = false,
                                 default = nil)
  if valid_608034 != nil:
    section.add "X-Amz-Signature", valid_608034
  var valid_608035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608035 = validateParameter(valid_608035, JString, required = false,
                                 default = nil)
  if valid_608035 != nil:
    section.add "X-Amz-Content-Sha256", valid_608035
  var valid_608036 = header.getOrDefault("X-Amz-Date")
  valid_608036 = validateParameter(valid_608036, JString, required = false,
                                 default = nil)
  if valid_608036 != nil:
    section.add "X-Amz-Date", valid_608036
  var valid_608037 = header.getOrDefault("X-Amz-Credential")
  valid_608037 = validateParameter(valid_608037, JString, required = false,
                                 default = nil)
  if valid_608037 != nil:
    section.add "X-Amz-Credential", valid_608037
  var valid_608038 = header.getOrDefault("X-Amz-Security-Token")
  valid_608038 = validateParameter(valid_608038, JString, required = false,
                                 default = nil)
  if valid_608038 != nil:
    section.add "X-Amz-Security-Token", valid_608038
  var valid_608039 = header.getOrDefault("X-Amz-Algorithm")
  valid_608039 = validateParameter(valid_608039, JString, required = false,
                                 default = nil)
  if valid_608039 != nil:
    section.add "X-Amz-Algorithm", valid_608039
  var valid_608040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608040 = validateParameter(valid_608040, JString, required = false,
                                 default = nil)
  if valid_608040 != nil:
    section.add "X-Amz-SignedHeaders", valid_608040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608041: Call_GetRemoveTagsFromResource_608027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608041.validator(path, query, header, formData, body)
  let scheme = call_608041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608041.url(scheme.get, call_608041.host, call_608041.base,
                         call_608041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608041, url, valid)

proc call*(call_608042: Call_GetRemoveTagsFromResource_608027;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-02-12"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608043 = newJObject()
  add(query_608043, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_608043.add "TagKeys", TagKeys
  add(query_608043, "Action", newJString(Action))
  add(query_608043, "Version", newJString(Version))
  result = call_608042.call(nil, query_608043, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_608027(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_608028, base: "/",
    url: url_GetRemoveTagsFromResource_608029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_608080 = ref object of OpenApiRestCall_605573
proc url_PostResetDBParameterGroup_608082(protocol: Scheme; host: string;
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

proc validate_PostResetDBParameterGroup_608081(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_608083 = query.getOrDefault("Action")
  valid_608083 = validateParameter(valid_608083, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_608083 != nil:
    section.add "Action", valid_608083
  var valid_608084 = query.getOrDefault("Version")
  valid_608084 = validateParameter(valid_608084, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_608084 != nil:
    section.add "Version", valid_608084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608085 = header.getOrDefault("X-Amz-Signature")
  valid_608085 = validateParameter(valid_608085, JString, required = false,
                                 default = nil)
  if valid_608085 != nil:
    section.add "X-Amz-Signature", valid_608085
  var valid_608086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608086 = validateParameter(valid_608086, JString, required = false,
                                 default = nil)
  if valid_608086 != nil:
    section.add "X-Amz-Content-Sha256", valid_608086
  var valid_608087 = header.getOrDefault("X-Amz-Date")
  valid_608087 = validateParameter(valid_608087, JString, required = false,
                                 default = nil)
  if valid_608087 != nil:
    section.add "X-Amz-Date", valid_608087
  var valid_608088 = header.getOrDefault("X-Amz-Credential")
  valid_608088 = validateParameter(valid_608088, JString, required = false,
                                 default = nil)
  if valid_608088 != nil:
    section.add "X-Amz-Credential", valid_608088
  var valid_608089 = header.getOrDefault("X-Amz-Security-Token")
  valid_608089 = validateParameter(valid_608089, JString, required = false,
                                 default = nil)
  if valid_608089 != nil:
    section.add "X-Amz-Security-Token", valid_608089
  var valid_608090 = header.getOrDefault("X-Amz-Algorithm")
  valid_608090 = validateParameter(valid_608090, JString, required = false,
                                 default = nil)
  if valid_608090 != nil:
    section.add "X-Amz-Algorithm", valid_608090
  var valid_608091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608091 = validateParameter(valid_608091, JString, required = false,
                                 default = nil)
  if valid_608091 != nil:
    section.add "X-Amz-SignedHeaders", valid_608091
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_608092 = formData.getOrDefault("ResetAllParameters")
  valid_608092 = validateParameter(valid_608092, JBool, required = false, default = nil)
  if valid_608092 != nil:
    section.add "ResetAllParameters", valid_608092
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_608093 = formData.getOrDefault("DBParameterGroupName")
  valid_608093 = validateParameter(valid_608093, JString, required = true,
                                 default = nil)
  if valid_608093 != nil:
    section.add "DBParameterGroupName", valid_608093
  var valid_608094 = formData.getOrDefault("Parameters")
  valid_608094 = validateParameter(valid_608094, JArray, required = false,
                                 default = nil)
  if valid_608094 != nil:
    section.add "Parameters", valid_608094
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608095: Call_PostResetDBParameterGroup_608080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608095.validator(path, query, header, formData, body)
  let scheme = call_608095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608095.url(scheme.get, call_608095.host, call_608095.base,
                         call_608095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608095, url, valid)

proc call*(call_608096: Call_PostResetDBParameterGroup_608080;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2013-02-12"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_608097 = newJObject()
  var formData_608098 = newJObject()
  add(formData_608098, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_608098, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_608097, "Action", newJString(Action))
  if Parameters != nil:
    formData_608098.add "Parameters", Parameters
  add(query_608097, "Version", newJString(Version))
  result = call_608096.call(nil, query_608097, nil, formData_608098, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_608080(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_608081, base: "/",
    url: url_PostResetDBParameterGroup_608082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_608062 = ref object of OpenApiRestCall_605573
proc url_GetResetDBParameterGroup_608064(protocol: Scheme; host: string;
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

proc validate_GetResetDBParameterGroup_608063(path: JsonNode; query: JsonNode;
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
  var valid_608065 = query.getOrDefault("DBParameterGroupName")
  valid_608065 = validateParameter(valid_608065, JString, required = true,
                                 default = nil)
  if valid_608065 != nil:
    section.add "DBParameterGroupName", valid_608065
  var valid_608066 = query.getOrDefault("Parameters")
  valid_608066 = validateParameter(valid_608066, JArray, required = false,
                                 default = nil)
  if valid_608066 != nil:
    section.add "Parameters", valid_608066
  var valid_608067 = query.getOrDefault("ResetAllParameters")
  valid_608067 = validateParameter(valid_608067, JBool, required = false, default = nil)
  if valid_608067 != nil:
    section.add "ResetAllParameters", valid_608067
  var valid_608068 = query.getOrDefault("Action")
  valid_608068 = validateParameter(valid_608068, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_608068 != nil:
    section.add "Action", valid_608068
  var valid_608069 = query.getOrDefault("Version")
  valid_608069 = validateParameter(valid_608069, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_608069 != nil:
    section.add "Version", valid_608069
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608070 = header.getOrDefault("X-Amz-Signature")
  valid_608070 = validateParameter(valid_608070, JString, required = false,
                                 default = nil)
  if valid_608070 != nil:
    section.add "X-Amz-Signature", valid_608070
  var valid_608071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608071 = validateParameter(valid_608071, JString, required = false,
                                 default = nil)
  if valid_608071 != nil:
    section.add "X-Amz-Content-Sha256", valid_608071
  var valid_608072 = header.getOrDefault("X-Amz-Date")
  valid_608072 = validateParameter(valid_608072, JString, required = false,
                                 default = nil)
  if valid_608072 != nil:
    section.add "X-Amz-Date", valid_608072
  var valid_608073 = header.getOrDefault("X-Amz-Credential")
  valid_608073 = validateParameter(valid_608073, JString, required = false,
                                 default = nil)
  if valid_608073 != nil:
    section.add "X-Amz-Credential", valid_608073
  var valid_608074 = header.getOrDefault("X-Amz-Security-Token")
  valid_608074 = validateParameter(valid_608074, JString, required = false,
                                 default = nil)
  if valid_608074 != nil:
    section.add "X-Amz-Security-Token", valid_608074
  var valid_608075 = header.getOrDefault("X-Amz-Algorithm")
  valid_608075 = validateParameter(valid_608075, JString, required = false,
                                 default = nil)
  if valid_608075 != nil:
    section.add "X-Amz-Algorithm", valid_608075
  var valid_608076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608076 = validateParameter(valid_608076, JString, required = false,
                                 default = nil)
  if valid_608076 != nil:
    section.add "X-Amz-SignedHeaders", valid_608076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608077: Call_GetResetDBParameterGroup_608062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608077.validator(path, query, header, formData, body)
  let scheme = call_608077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608077.url(scheme.get, call_608077.host, call_608077.base,
                         call_608077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608077, url, valid)

proc call*(call_608078: Call_GetResetDBParameterGroup_608062;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608079 = newJObject()
  add(query_608079, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_608079.add "Parameters", Parameters
  add(query_608079, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_608079, "Action", newJString(Action))
  add(query_608079, "Version", newJString(Version))
  result = call_608078.call(nil, query_608079, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_608062(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_608063, base: "/",
    url: url_GetResetDBParameterGroup_608064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_608128 = ref object of OpenApiRestCall_605573
proc url_PostRestoreDBInstanceFromDBSnapshot_608130(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceFromDBSnapshot_608129(path: JsonNode;
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
  var valid_608131 = query.getOrDefault("Action")
  valid_608131 = validateParameter(valid_608131, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_608131 != nil:
    section.add "Action", valid_608131
  var valid_608132 = query.getOrDefault("Version")
  valid_608132 = validateParameter(valid_608132, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_608132 != nil:
    section.add "Version", valid_608132
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608133 = header.getOrDefault("X-Amz-Signature")
  valid_608133 = validateParameter(valid_608133, JString, required = false,
                                 default = nil)
  if valid_608133 != nil:
    section.add "X-Amz-Signature", valid_608133
  var valid_608134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608134 = validateParameter(valid_608134, JString, required = false,
                                 default = nil)
  if valid_608134 != nil:
    section.add "X-Amz-Content-Sha256", valid_608134
  var valid_608135 = header.getOrDefault("X-Amz-Date")
  valid_608135 = validateParameter(valid_608135, JString, required = false,
                                 default = nil)
  if valid_608135 != nil:
    section.add "X-Amz-Date", valid_608135
  var valid_608136 = header.getOrDefault("X-Amz-Credential")
  valid_608136 = validateParameter(valid_608136, JString, required = false,
                                 default = nil)
  if valid_608136 != nil:
    section.add "X-Amz-Credential", valid_608136
  var valid_608137 = header.getOrDefault("X-Amz-Security-Token")
  valid_608137 = validateParameter(valid_608137, JString, required = false,
                                 default = nil)
  if valid_608137 != nil:
    section.add "X-Amz-Security-Token", valid_608137
  var valid_608138 = header.getOrDefault("X-Amz-Algorithm")
  valid_608138 = validateParameter(valid_608138, JString, required = false,
                                 default = nil)
  if valid_608138 != nil:
    section.add "X-Amz-Algorithm", valid_608138
  var valid_608139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608139 = validateParameter(valid_608139, JString, required = false,
                                 default = nil)
  if valid_608139 != nil:
    section.add "X-Amz-SignedHeaders", valid_608139
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
  var valid_608140 = formData.getOrDefault("Port")
  valid_608140 = validateParameter(valid_608140, JInt, required = false, default = nil)
  if valid_608140 != nil:
    section.add "Port", valid_608140
  var valid_608141 = formData.getOrDefault("DBInstanceClass")
  valid_608141 = validateParameter(valid_608141, JString, required = false,
                                 default = nil)
  if valid_608141 != nil:
    section.add "DBInstanceClass", valid_608141
  var valid_608142 = formData.getOrDefault("MultiAZ")
  valid_608142 = validateParameter(valid_608142, JBool, required = false, default = nil)
  if valid_608142 != nil:
    section.add "MultiAZ", valid_608142
  var valid_608143 = formData.getOrDefault("AvailabilityZone")
  valid_608143 = validateParameter(valid_608143, JString, required = false,
                                 default = nil)
  if valid_608143 != nil:
    section.add "AvailabilityZone", valid_608143
  var valid_608144 = formData.getOrDefault("Engine")
  valid_608144 = validateParameter(valid_608144, JString, required = false,
                                 default = nil)
  if valid_608144 != nil:
    section.add "Engine", valid_608144
  var valid_608145 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_608145 = validateParameter(valid_608145, JBool, required = false, default = nil)
  if valid_608145 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608145
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_608146 = formData.getOrDefault("DBInstanceIdentifier")
  valid_608146 = validateParameter(valid_608146, JString, required = true,
                                 default = nil)
  if valid_608146 != nil:
    section.add "DBInstanceIdentifier", valid_608146
  var valid_608147 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_608147 = validateParameter(valid_608147, JString, required = true,
                                 default = nil)
  if valid_608147 != nil:
    section.add "DBSnapshotIdentifier", valid_608147
  var valid_608148 = formData.getOrDefault("DBName")
  valid_608148 = validateParameter(valid_608148, JString, required = false,
                                 default = nil)
  if valid_608148 != nil:
    section.add "DBName", valid_608148
  var valid_608149 = formData.getOrDefault("Iops")
  valid_608149 = validateParameter(valid_608149, JInt, required = false, default = nil)
  if valid_608149 != nil:
    section.add "Iops", valid_608149
  var valid_608150 = formData.getOrDefault("PubliclyAccessible")
  valid_608150 = validateParameter(valid_608150, JBool, required = false, default = nil)
  if valid_608150 != nil:
    section.add "PubliclyAccessible", valid_608150
  var valid_608151 = formData.getOrDefault("LicenseModel")
  valid_608151 = validateParameter(valid_608151, JString, required = false,
                                 default = nil)
  if valid_608151 != nil:
    section.add "LicenseModel", valid_608151
  var valid_608152 = formData.getOrDefault("DBSubnetGroupName")
  valid_608152 = validateParameter(valid_608152, JString, required = false,
                                 default = nil)
  if valid_608152 != nil:
    section.add "DBSubnetGroupName", valid_608152
  var valid_608153 = formData.getOrDefault("OptionGroupName")
  valid_608153 = validateParameter(valid_608153, JString, required = false,
                                 default = nil)
  if valid_608153 != nil:
    section.add "OptionGroupName", valid_608153
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608154: Call_PostRestoreDBInstanceFromDBSnapshot_608128;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608154.validator(path, query, header, formData, body)
  let scheme = call_608154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608154.url(scheme.get, call_608154.host, call_608154.base,
                         call_608154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608154, url, valid)

proc call*(call_608155: Call_PostRestoreDBInstanceFromDBSnapshot_608128;
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
  var query_608156 = newJObject()
  var formData_608157 = newJObject()
  add(formData_608157, "Port", newJInt(Port))
  add(formData_608157, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_608157, "MultiAZ", newJBool(MultiAZ))
  add(formData_608157, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_608157, "Engine", newJString(Engine))
  add(formData_608157, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_608157, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_608157, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_608157, "DBName", newJString(DBName))
  add(formData_608157, "Iops", newJInt(Iops))
  add(formData_608157, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608156, "Action", newJString(Action))
  add(formData_608157, "LicenseModel", newJString(LicenseModel))
  add(formData_608157, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_608157, "OptionGroupName", newJString(OptionGroupName))
  add(query_608156, "Version", newJString(Version))
  result = call_608155.call(nil, query_608156, nil, formData_608157, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_608128(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_608129, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_608130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_608099 = ref object of OpenApiRestCall_605573
proc url_GetRestoreDBInstanceFromDBSnapshot_608101(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceFromDBSnapshot_608100(path: JsonNode;
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
  var valid_608102 = query.getOrDefault("DBName")
  valid_608102 = validateParameter(valid_608102, JString, required = false,
                                 default = nil)
  if valid_608102 != nil:
    section.add "DBName", valid_608102
  var valid_608103 = query.getOrDefault("Engine")
  valid_608103 = validateParameter(valid_608103, JString, required = false,
                                 default = nil)
  if valid_608103 != nil:
    section.add "Engine", valid_608103
  var valid_608104 = query.getOrDefault("LicenseModel")
  valid_608104 = validateParameter(valid_608104, JString, required = false,
                                 default = nil)
  if valid_608104 != nil:
    section.add "LicenseModel", valid_608104
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_608105 = query.getOrDefault("DBInstanceIdentifier")
  valid_608105 = validateParameter(valid_608105, JString, required = true,
                                 default = nil)
  if valid_608105 != nil:
    section.add "DBInstanceIdentifier", valid_608105
  var valid_608106 = query.getOrDefault("DBSnapshotIdentifier")
  valid_608106 = validateParameter(valid_608106, JString, required = true,
                                 default = nil)
  if valid_608106 != nil:
    section.add "DBSnapshotIdentifier", valid_608106
  var valid_608107 = query.getOrDefault("Action")
  valid_608107 = validateParameter(valid_608107, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_608107 != nil:
    section.add "Action", valid_608107
  var valid_608108 = query.getOrDefault("MultiAZ")
  valid_608108 = validateParameter(valid_608108, JBool, required = false, default = nil)
  if valid_608108 != nil:
    section.add "MultiAZ", valid_608108
  var valid_608109 = query.getOrDefault("Port")
  valid_608109 = validateParameter(valid_608109, JInt, required = false, default = nil)
  if valid_608109 != nil:
    section.add "Port", valid_608109
  var valid_608110 = query.getOrDefault("AvailabilityZone")
  valid_608110 = validateParameter(valid_608110, JString, required = false,
                                 default = nil)
  if valid_608110 != nil:
    section.add "AvailabilityZone", valid_608110
  var valid_608111 = query.getOrDefault("OptionGroupName")
  valid_608111 = validateParameter(valid_608111, JString, required = false,
                                 default = nil)
  if valid_608111 != nil:
    section.add "OptionGroupName", valid_608111
  var valid_608112 = query.getOrDefault("DBSubnetGroupName")
  valid_608112 = validateParameter(valid_608112, JString, required = false,
                                 default = nil)
  if valid_608112 != nil:
    section.add "DBSubnetGroupName", valid_608112
  var valid_608113 = query.getOrDefault("Version")
  valid_608113 = validateParameter(valid_608113, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_608113 != nil:
    section.add "Version", valid_608113
  var valid_608114 = query.getOrDefault("DBInstanceClass")
  valid_608114 = validateParameter(valid_608114, JString, required = false,
                                 default = nil)
  if valid_608114 != nil:
    section.add "DBInstanceClass", valid_608114
  var valid_608115 = query.getOrDefault("PubliclyAccessible")
  valid_608115 = validateParameter(valid_608115, JBool, required = false, default = nil)
  if valid_608115 != nil:
    section.add "PubliclyAccessible", valid_608115
  var valid_608116 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_608116 = validateParameter(valid_608116, JBool, required = false, default = nil)
  if valid_608116 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608116
  var valid_608117 = query.getOrDefault("Iops")
  valid_608117 = validateParameter(valid_608117, JInt, required = false, default = nil)
  if valid_608117 != nil:
    section.add "Iops", valid_608117
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608118 = header.getOrDefault("X-Amz-Signature")
  valid_608118 = validateParameter(valid_608118, JString, required = false,
                                 default = nil)
  if valid_608118 != nil:
    section.add "X-Amz-Signature", valid_608118
  var valid_608119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608119 = validateParameter(valid_608119, JString, required = false,
                                 default = nil)
  if valid_608119 != nil:
    section.add "X-Amz-Content-Sha256", valid_608119
  var valid_608120 = header.getOrDefault("X-Amz-Date")
  valid_608120 = validateParameter(valid_608120, JString, required = false,
                                 default = nil)
  if valid_608120 != nil:
    section.add "X-Amz-Date", valid_608120
  var valid_608121 = header.getOrDefault("X-Amz-Credential")
  valid_608121 = validateParameter(valid_608121, JString, required = false,
                                 default = nil)
  if valid_608121 != nil:
    section.add "X-Amz-Credential", valid_608121
  var valid_608122 = header.getOrDefault("X-Amz-Security-Token")
  valid_608122 = validateParameter(valid_608122, JString, required = false,
                                 default = nil)
  if valid_608122 != nil:
    section.add "X-Amz-Security-Token", valid_608122
  var valid_608123 = header.getOrDefault("X-Amz-Algorithm")
  valid_608123 = validateParameter(valid_608123, JString, required = false,
                                 default = nil)
  if valid_608123 != nil:
    section.add "X-Amz-Algorithm", valid_608123
  var valid_608124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608124 = validateParameter(valid_608124, JString, required = false,
                                 default = nil)
  if valid_608124 != nil:
    section.add "X-Amz-SignedHeaders", valid_608124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608125: Call_GetRestoreDBInstanceFromDBSnapshot_608099;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608125.validator(path, query, header, formData, body)
  let scheme = call_608125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608125.url(scheme.get, call_608125.host, call_608125.base,
                         call_608125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608125, url, valid)

proc call*(call_608126: Call_GetRestoreDBInstanceFromDBSnapshot_608099;
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
  var query_608127 = newJObject()
  add(query_608127, "DBName", newJString(DBName))
  add(query_608127, "Engine", newJString(Engine))
  add(query_608127, "LicenseModel", newJString(LicenseModel))
  add(query_608127, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_608127, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_608127, "Action", newJString(Action))
  add(query_608127, "MultiAZ", newJBool(MultiAZ))
  add(query_608127, "Port", newJInt(Port))
  add(query_608127, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_608127, "OptionGroupName", newJString(OptionGroupName))
  add(query_608127, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_608127, "Version", newJString(Version))
  add(query_608127, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_608127, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608127, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_608127, "Iops", newJInt(Iops))
  result = call_608126.call(nil, query_608127, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_608099(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_608100, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_608101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_608189 = ref object of OpenApiRestCall_605573
proc url_PostRestoreDBInstanceToPointInTime_608191(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceToPointInTime_608190(path: JsonNode;
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
  var valid_608192 = query.getOrDefault("Action")
  valid_608192 = validateParameter(valid_608192, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_608192 != nil:
    section.add "Action", valid_608192
  var valid_608193 = query.getOrDefault("Version")
  valid_608193 = validateParameter(valid_608193, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_608193 != nil:
    section.add "Version", valid_608193
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608194 = header.getOrDefault("X-Amz-Signature")
  valid_608194 = validateParameter(valid_608194, JString, required = false,
                                 default = nil)
  if valid_608194 != nil:
    section.add "X-Amz-Signature", valid_608194
  var valid_608195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608195 = validateParameter(valid_608195, JString, required = false,
                                 default = nil)
  if valid_608195 != nil:
    section.add "X-Amz-Content-Sha256", valid_608195
  var valid_608196 = header.getOrDefault("X-Amz-Date")
  valid_608196 = validateParameter(valid_608196, JString, required = false,
                                 default = nil)
  if valid_608196 != nil:
    section.add "X-Amz-Date", valid_608196
  var valid_608197 = header.getOrDefault("X-Amz-Credential")
  valid_608197 = validateParameter(valid_608197, JString, required = false,
                                 default = nil)
  if valid_608197 != nil:
    section.add "X-Amz-Credential", valid_608197
  var valid_608198 = header.getOrDefault("X-Amz-Security-Token")
  valid_608198 = validateParameter(valid_608198, JString, required = false,
                                 default = nil)
  if valid_608198 != nil:
    section.add "X-Amz-Security-Token", valid_608198
  var valid_608199 = header.getOrDefault("X-Amz-Algorithm")
  valid_608199 = validateParameter(valid_608199, JString, required = false,
                                 default = nil)
  if valid_608199 != nil:
    section.add "X-Amz-Algorithm", valid_608199
  var valid_608200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608200 = validateParameter(valid_608200, JString, required = false,
                                 default = nil)
  if valid_608200 != nil:
    section.add "X-Amz-SignedHeaders", valid_608200
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
  var valid_608201 = formData.getOrDefault("Port")
  valid_608201 = validateParameter(valid_608201, JInt, required = false, default = nil)
  if valid_608201 != nil:
    section.add "Port", valid_608201
  var valid_608202 = formData.getOrDefault("DBInstanceClass")
  valid_608202 = validateParameter(valid_608202, JString, required = false,
                                 default = nil)
  if valid_608202 != nil:
    section.add "DBInstanceClass", valid_608202
  var valid_608203 = formData.getOrDefault("MultiAZ")
  valid_608203 = validateParameter(valid_608203, JBool, required = false, default = nil)
  if valid_608203 != nil:
    section.add "MultiAZ", valid_608203
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_608204 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_608204 = validateParameter(valid_608204, JString, required = true,
                                 default = nil)
  if valid_608204 != nil:
    section.add "SourceDBInstanceIdentifier", valid_608204
  var valid_608205 = formData.getOrDefault("AvailabilityZone")
  valid_608205 = validateParameter(valid_608205, JString, required = false,
                                 default = nil)
  if valid_608205 != nil:
    section.add "AvailabilityZone", valid_608205
  var valid_608206 = formData.getOrDefault("Engine")
  valid_608206 = validateParameter(valid_608206, JString, required = false,
                                 default = nil)
  if valid_608206 != nil:
    section.add "Engine", valid_608206
  var valid_608207 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_608207 = validateParameter(valid_608207, JBool, required = false, default = nil)
  if valid_608207 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608207
  var valid_608208 = formData.getOrDefault("UseLatestRestorableTime")
  valid_608208 = validateParameter(valid_608208, JBool, required = false, default = nil)
  if valid_608208 != nil:
    section.add "UseLatestRestorableTime", valid_608208
  var valid_608209 = formData.getOrDefault("DBName")
  valid_608209 = validateParameter(valid_608209, JString, required = false,
                                 default = nil)
  if valid_608209 != nil:
    section.add "DBName", valid_608209
  var valid_608210 = formData.getOrDefault("Iops")
  valid_608210 = validateParameter(valid_608210, JInt, required = false, default = nil)
  if valid_608210 != nil:
    section.add "Iops", valid_608210
  var valid_608211 = formData.getOrDefault("PubliclyAccessible")
  valid_608211 = validateParameter(valid_608211, JBool, required = false, default = nil)
  if valid_608211 != nil:
    section.add "PubliclyAccessible", valid_608211
  var valid_608212 = formData.getOrDefault("LicenseModel")
  valid_608212 = validateParameter(valid_608212, JString, required = false,
                                 default = nil)
  if valid_608212 != nil:
    section.add "LicenseModel", valid_608212
  var valid_608213 = formData.getOrDefault("DBSubnetGroupName")
  valid_608213 = validateParameter(valid_608213, JString, required = false,
                                 default = nil)
  if valid_608213 != nil:
    section.add "DBSubnetGroupName", valid_608213
  var valid_608214 = formData.getOrDefault("OptionGroupName")
  valid_608214 = validateParameter(valid_608214, JString, required = false,
                                 default = nil)
  if valid_608214 != nil:
    section.add "OptionGroupName", valid_608214
  var valid_608215 = formData.getOrDefault("RestoreTime")
  valid_608215 = validateParameter(valid_608215, JString, required = false,
                                 default = nil)
  if valid_608215 != nil:
    section.add "RestoreTime", valid_608215
  var valid_608216 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_608216 = validateParameter(valid_608216, JString, required = true,
                                 default = nil)
  if valid_608216 != nil:
    section.add "TargetDBInstanceIdentifier", valid_608216
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608217: Call_PostRestoreDBInstanceToPointInTime_608189;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608217.validator(path, query, header, formData, body)
  let scheme = call_608217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608217.url(scheme.get, call_608217.host, call_608217.base,
                         call_608217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608217, url, valid)

proc call*(call_608218: Call_PostRestoreDBInstanceToPointInTime_608189;
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
  var query_608219 = newJObject()
  var formData_608220 = newJObject()
  add(formData_608220, "Port", newJInt(Port))
  add(formData_608220, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_608220, "MultiAZ", newJBool(MultiAZ))
  add(formData_608220, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_608220, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_608220, "Engine", newJString(Engine))
  add(formData_608220, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_608220, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_608220, "DBName", newJString(DBName))
  add(formData_608220, "Iops", newJInt(Iops))
  add(formData_608220, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608219, "Action", newJString(Action))
  add(formData_608220, "LicenseModel", newJString(LicenseModel))
  add(formData_608220, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_608220, "OptionGroupName", newJString(OptionGroupName))
  add(formData_608220, "RestoreTime", newJString(RestoreTime))
  add(formData_608220, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_608219, "Version", newJString(Version))
  result = call_608218.call(nil, query_608219, nil, formData_608220, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_608189(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_608190, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_608191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_608158 = ref object of OpenApiRestCall_605573
proc url_GetRestoreDBInstanceToPointInTime_608160(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceToPointInTime_608159(path: JsonNode;
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
  var valid_608161 = query.getOrDefault("DBName")
  valid_608161 = validateParameter(valid_608161, JString, required = false,
                                 default = nil)
  if valid_608161 != nil:
    section.add "DBName", valid_608161
  var valid_608162 = query.getOrDefault("Engine")
  valid_608162 = validateParameter(valid_608162, JString, required = false,
                                 default = nil)
  if valid_608162 != nil:
    section.add "Engine", valid_608162
  var valid_608163 = query.getOrDefault("UseLatestRestorableTime")
  valid_608163 = validateParameter(valid_608163, JBool, required = false, default = nil)
  if valid_608163 != nil:
    section.add "UseLatestRestorableTime", valid_608163
  var valid_608164 = query.getOrDefault("LicenseModel")
  valid_608164 = validateParameter(valid_608164, JString, required = false,
                                 default = nil)
  if valid_608164 != nil:
    section.add "LicenseModel", valid_608164
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_608165 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_608165 = validateParameter(valid_608165, JString, required = true,
                                 default = nil)
  if valid_608165 != nil:
    section.add "TargetDBInstanceIdentifier", valid_608165
  var valid_608166 = query.getOrDefault("Action")
  valid_608166 = validateParameter(valid_608166, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_608166 != nil:
    section.add "Action", valid_608166
  var valid_608167 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_608167 = validateParameter(valid_608167, JString, required = true,
                                 default = nil)
  if valid_608167 != nil:
    section.add "SourceDBInstanceIdentifier", valid_608167
  var valid_608168 = query.getOrDefault("MultiAZ")
  valid_608168 = validateParameter(valid_608168, JBool, required = false, default = nil)
  if valid_608168 != nil:
    section.add "MultiAZ", valid_608168
  var valid_608169 = query.getOrDefault("Port")
  valid_608169 = validateParameter(valid_608169, JInt, required = false, default = nil)
  if valid_608169 != nil:
    section.add "Port", valid_608169
  var valid_608170 = query.getOrDefault("AvailabilityZone")
  valid_608170 = validateParameter(valid_608170, JString, required = false,
                                 default = nil)
  if valid_608170 != nil:
    section.add "AvailabilityZone", valid_608170
  var valid_608171 = query.getOrDefault("OptionGroupName")
  valid_608171 = validateParameter(valid_608171, JString, required = false,
                                 default = nil)
  if valid_608171 != nil:
    section.add "OptionGroupName", valid_608171
  var valid_608172 = query.getOrDefault("DBSubnetGroupName")
  valid_608172 = validateParameter(valid_608172, JString, required = false,
                                 default = nil)
  if valid_608172 != nil:
    section.add "DBSubnetGroupName", valid_608172
  var valid_608173 = query.getOrDefault("RestoreTime")
  valid_608173 = validateParameter(valid_608173, JString, required = false,
                                 default = nil)
  if valid_608173 != nil:
    section.add "RestoreTime", valid_608173
  var valid_608174 = query.getOrDefault("DBInstanceClass")
  valid_608174 = validateParameter(valid_608174, JString, required = false,
                                 default = nil)
  if valid_608174 != nil:
    section.add "DBInstanceClass", valid_608174
  var valid_608175 = query.getOrDefault("PubliclyAccessible")
  valid_608175 = validateParameter(valid_608175, JBool, required = false, default = nil)
  if valid_608175 != nil:
    section.add "PubliclyAccessible", valid_608175
  var valid_608176 = query.getOrDefault("Version")
  valid_608176 = validateParameter(valid_608176, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_608176 != nil:
    section.add "Version", valid_608176
  var valid_608177 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_608177 = validateParameter(valid_608177, JBool, required = false, default = nil)
  if valid_608177 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608177
  var valid_608178 = query.getOrDefault("Iops")
  valid_608178 = validateParameter(valid_608178, JInt, required = false, default = nil)
  if valid_608178 != nil:
    section.add "Iops", valid_608178
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608179 = header.getOrDefault("X-Amz-Signature")
  valid_608179 = validateParameter(valid_608179, JString, required = false,
                                 default = nil)
  if valid_608179 != nil:
    section.add "X-Amz-Signature", valid_608179
  var valid_608180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608180 = validateParameter(valid_608180, JString, required = false,
                                 default = nil)
  if valid_608180 != nil:
    section.add "X-Amz-Content-Sha256", valid_608180
  var valid_608181 = header.getOrDefault("X-Amz-Date")
  valid_608181 = validateParameter(valid_608181, JString, required = false,
                                 default = nil)
  if valid_608181 != nil:
    section.add "X-Amz-Date", valid_608181
  var valid_608182 = header.getOrDefault("X-Amz-Credential")
  valid_608182 = validateParameter(valid_608182, JString, required = false,
                                 default = nil)
  if valid_608182 != nil:
    section.add "X-Amz-Credential", valid_608182
  var valid_608183 = header.getOrDefault("X-Amz-Security-Token")
  valid_608183 = validateParameter(valid_608183, JString, required = false,
                                 default = nil)
  if valid_608183 != nil:
    section.add "X-Amz-Security-Token", valid_608183
  var valid_608184 = header.getOrDefault("X-Amz-Algorithm")
  valid_608184 = validateParameter(valid_608184, JString, required = false,
                                 default = nil)
  if valid_608184 != nil:
    section.add "X-Amz-Algorithm", valid_608184
  var valid_608185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608185 = validateParameter(valid_608185, JString, required = false,
                                 default = nil)
  if valid_608185 != nil:
    section.add "X-Amz-SignedHeaders", valid_608185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608186: Call_GetRestoreDBInstanceToPointInTime_608158;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608186.validator(path, query, header, formData, body)
  let scheme = call_608186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608186.url(scheme.get, call_608186.host, call_608186.base,
                         call_608186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608186, url, valid)

proc call*(call_608187: Call_GetRestoreDBInstanceToPointInTime_608158;
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
  var query_608188 = newJObject()
  add(query_608188, "DBName", newJString(DBName))
  add(query_608188, "Engine", newJString(Engine))
  add(query_608188, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_608188, "LicenseModel", newJString(LicenseModel))
  add(query_608188, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_608188, "Action", newJString(Action))
  add(query_608188, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_608188, "MultiAZ", newJBool(MultiAZ))
  add(query_608188, "Port", newJInt(Port))
  add(query_608188, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_608188, "OptionGroupName", newJString(OptionGroupName))
  add(query_608188, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_608188, "RestoreTime", newJString(RestoreTime))
  add(query_608188, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_608188, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608188, "Version", newJString(Version))
  add(query_608188, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_608188, "Iops", newJInt(Iops))
  result = call_608187.call(nil, query_608188, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_608158(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_608159, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_608160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_608241 = ref object of OpenApiRestCall_605573
proc url_PostRevokeDBSecurityGroupIngress_608243(protocol: Scheme; host: string;
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

proc validate_PostRevokeDBSecurityGroupIngress_608242(path: JsonNode;
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
  var valid_608244 = query.getOrDefault("Action")
  valid_608244 = validateParameter(valid_608244, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_608244 != nil:
    section.add "Action", valid_608244
  var valid_608245 = query.getOrDefault("Version")
  valid_608245 = validateParameter(valid_608245, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_608245 != nil:
    section.add "Version", valid_608245
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608246 = header.getOrDefault("X-Amz-Signature")
  valid_608246 = validateParameter(valid_608246, JString, required = false,
                                 default = nil)
  if valid_608246 != nil:
    section.add "X-Amz-Signature", valid_608246
  var valid_608247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608247 = validateParameter(valid_608247, JString, required = false,
                                 default = nil)
  if valid_608247 != nil:
    section.add "X-Amz-Content-Sha256", valid_608247
  var valid_608248 = header.getOrDefault("X-Amz-Date")
  valid_608248 = validateParameter(valid_608248, JString, required = false,
                                 default = nil)
  if valid_608248 != nil:
    section.add "X-Amz-Date", valid_608248
  var valid_608249 = header.getOrDefault("X-Amz-Credential")
  valid_608249 = validateParameter(valid_608249, JString, required = false,
                                 default = nil)
  if valid_608249 != nil:
    section.add "X-Amz-Credential", valid_608249
  var valid_608250 = header.getOrDefault("X-Amz-Security-Token")
  valid_608250 = validateParameter(valid_608250, JString, required = false,
                                 default = nil)
  if valid_608250 != nil:
    section.add "X-Amz-Security-Token", valid_608250
  var valid_608251 = header.getOrDefault("X-Amz-Algorithm")
  valid_608251 = validateParameter(valid_608251, JString, required = false,
                                 default = nil)
  if valid_608251 != nil:
    section.add "X-Amz-Algorithm", valid_608251
  var valid_608252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608252 = validateParameter(valid_608252, JString, required = false,
                                 default = nil)
  if valid_608252 != nil:
    section.add "X-Amz-SignedHeaders", valid_608252
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_608253 = formData.getOrDefault("DBSecurityGroupName")
  valid_608253 = validateParameter(valid_608253, JString, required = true,
                                 default = nil)
  if valid_608253 != nil:
    section.add "DBSecurityGroupName", valid_608253
  var valid_608254 = formData.getOrDefault("EC2SecurityGroupName")
  valid_608254 = validateParameter(valid_608254, JString, required = false,
                                 default = nil)
  if valid_608254 != nil:
    section.add "EC2SecurityGroupName", valid_608254
  var valid_608255 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_608255 = validateParameter(valid_608255, JString, required = false,
                                 default = nil)
  if valid_608255 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_608255
  var valid_608256 = formData.getOrDefault("EC2SecurityGroupId")
  valid_608256 = validateParameter(valid_608256, JString, required = false,
                                 default = nil)
  if valid_608256 != nil:
    section.add "EC2SecurityGroupId", valid_608256
  var valid_608257 = formData.getOrDefault("CIDRIP")
  valid_608257 = validateParameter(valid_608257, JString, required = false,
                                 default = nil)
  if valid_608257 != nil:
    section.add "CIDRIP", valid_608257
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608258: Call_PostRevokeDBSecurityGroupIngress_608241;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608258.validator(path, query, header, formData, body)
  let scheme = call_608258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608258.url(scheme.get, call_608258.host, call_608258.base,
                         call_608258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608258, url, valid)

proc call*(call_608259: Call_PostRevokeDBSecurityGroupIngress_608241;
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
  var query_608260 = newJObject()
  var formData_608261 = newJObject()
  add(formData_608261, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_608261, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_608261, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_608261, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_608261, "CIDRIP", newJString(CIDRIP))
  add(query_608260, "Action", newJString(Action))
  add(query_608260, "Version", newJString(Version))
  result = call_608259.call(nil, query_608260, nil, formData_608261, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_608241(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_608242, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_608243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_608221 = ref object of OpenApiRestCall_605573
proc url_GetRevokeDBSecurityGroupIngress_608223(protocol: Scheme; host: string;
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

proc validate_GetRevokeDBSecurityGroupIngress_608222(path: JsonNode;
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
  var valid_608224 = query.getOrDefault("EC2SecurityGroupName")
  valid_608224 = validateParameter(valid_608224, JString, required = false,
                                 default = nil)
  if valid_608224 != nil:
    section.add "EC2SecurityGroupName", valid_608224
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_608225 = query.getOrDefault("DBSecurityGroupName")
  valid_608225 = validateParameter(valid_608225, JString, required = true,
                                 default = nil)
  if valid_608225 != nil:
    section.add "DBSecurityGroupName", valid_608225
  var valid_608226 = query.getOrDefault("EC2SecurityGroupId")
  valid_608226 = validateParameter(valid_608226, JString, required = false,
                                 default = nil)
  if valid_608226 != nil:
    section.add "EC2SecurityGroupId", valid_608226
  var valid_608227 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_608227 = validateParameter(valid_608227, JString, required = false,
                                 default = nil)
  if valid_608227 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_608227
  var valid_608228 = query.getOrDefault("Action")
  valid_608228 = validateParameter(valid_608228, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_608228 != nil:
    section.add "Action", valid_608228
  var valid_608229 = query.getOrDefault("Version")
  valid_608229 = validateParameter(valid_608229, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_608229 != nil:
    section.add "Version", valid_608229
  var valid_608230 = query.getOrDefault("CIDRIP")
  valid_608230 = validateParameter(valid_608230, JString, required = false,
                                 default = nil)
  if valid_608230 != nil:
    section.add "CIDRIP", valid_608230
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608231 = header.getOrDefault("X-Amz-Signature")
  valid_608231 = validateParameter(valid_608231, JString, required = false,
                                 default = nil)
  if valid_608231 != nil:
    section.add "X-Amz-Signature", valid_608231
  var valid_608232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608232 = validateParameter(valid_608232, JString, required = false,
                                 default = nil)
  if valid_608232 != nil:
    section.add "X-Amz-Content-Sha256", valid_608232
  var valid_608233 = header.getOrDefault("X-Amz-Date")
  valid_608233 = validateParameter(valid_608233, JString, required = false,
                                 default = nil)
  if valid_608233 != nil:
    section.add "X-Amz-Date", valid_608233
  var valid_608234 = header.getOrDefault("X-Amz-Credential")
  valid_608234 = validateParameter(valid_608234, JString, required = false,
                                 default = nil)
  if valid_608234 != nil:
    section.add "X-Amz-Credential", valid_608234
  var valid_608235 = header.getOrDefault("X-Amz-Security-Token")
  valid_608235 = validateParameter(valid_608235, JString, required = false,
                                 default = nil)
  if valid_608235 != nil:
    section.add "X-Amz-Security-Token", valid_608235
  var valid_608236 = header.getOrDefault("X-Amz-Algorithm")
  valid_608236 = validateParameter(valid_608236, JString, required = false,
                                 default = nil)
  if valid_608236 != nil:
    section.add "X-Amz-Algorithm", valid_608236
  var valid_608237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608237 = validateParameter(valid_608237, JString, required = false,
                                 default = nil)
  if valid_608237 != nil:
    section.add "X-Amz-SignedHeaders", valid_608237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608238: Call_GetRevokeDBSecurityGroupIngress_608221;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608238.validator(path, query, header, formData, body)
  let scheme = call_608238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608238.url(scheme.get, call_608238.host, call_608238.base,
                         call_608238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608238, url, valid)

proc call*(call_608239: Call_GetRevokeDBSecurityGroupIngress_608221;
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
  var query_608240 = newJObject()
  add(query_608240, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_608240, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_608240, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_608240, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_608240, "Action", newJString(Action))
  add(query_608240, "Version", newJString(Version))
  add(query_608240, "CIDRIP", newJString(CIDRIP))
  result = call_608239.call(nil, query_608240, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_608221(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_608222, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_608223,
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
