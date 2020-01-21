
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
  var valid_606186 = query.getOrDefault("Action")
  valid_606186 = validateParameter(valid_606186, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_606186 != nil:
    section.add "Action", valid_606186
  var valid_606187 = query.getOrDefault("Version")
  valid_606187 = validateParameter(valid_606187, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
  var valid_606221 = query.getOrDefault("Action")
  valid_606221 = validateParameter(valid_606221, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_606221 != nil:
    section.add "Action", valid_606221
  var valid_606222 = query.getOrDefault("Version")
  valid_606222 = validateParameter(valid_606222, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
  var valid_606259 = query.getOrDefault("Action")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_606259 != nil:
    section.add "Action", valid_606259
  var valid_606260 = query.getOrDefault("Version")
  valid_606260 = validateParameter(valid_606260, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"; CIDRIP: string = ""): Recallable =
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
  var valid_606297 = query.getOrDefault("Action")
  valid_606297 = validateParameter(valid_606297, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_606297 != nil:
    section.add "Action", valid_606297
  var valid_606298 = query.getOrDefault("Version")
  valid_606298 = validateParameter(valid_606298, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
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
  var valid_606354 = query.getOrDefault("Action")
  valid_606354 = validateParameter(valid_606354, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_606354 != nil:
    section.add "Action", valid_606354
  var valid_606355 = query.getOrDefault("Version")
  valid_606355 = validateParameter(valid_606355, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  var valid_606315 = query.getOrDefault("Version")
  valid_606315 = validateParameter(valid_606315, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  var valid_606418 = query.getOrDefault("Action")
  valid_606418 = validateParameter(valid_606418, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_606418 != nil:
    section.add "Action", valid_606418
  var valid_606419 = query.getOrDefault("Version")
  valid_606419 = validateParameter(valid_606419, JString, required = true,
                                 default = newJString("2013-01-10"))
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
                                 default = newJString("2013-01-10"))
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
  var valid_606461 = query.getOrDefault("Action")
  valid_606461 = validateParameter(valid_606461, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_606461 != nil:
    section.add "Action", valid_606461
  var valid_606462 = query.getOrDefault("Version")
  valid_606462 = validateParameter(valid_606462, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
  var valid_606497 = query.getOrDefault("Action")
  valid_606497 = validateParameter(valid_606497, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_606497 != nil:
    section.add "Action", valid_606497
  var valid_606498 = query.getOrDefault("Version")
  valid_606498 = validateParameter(valid_606498, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
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
  var valid_606532 = query.getOrDefault("Action")
  valid_606532 = validateParameter(valid_606532, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_606532 != nil:
    section.add "Action", valid_606532
  var valid_606533 = query.getOrDefault("Version")
  valid_606533 = validateParameter(valid_606533, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
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
  var valid_606568 = query.getOrDefault("Action")
  valid_606568 = validateParameter(valid_606568, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_606568 != nil:
    section.add "Action", valid_606568
  var valid_606569 = query.getOrDefault("Version")
  valid_606569 = validateParameter(valid_606569, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
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
  var valid_606608 = query.getOrDefault("Action")
  valid_606608 = validateParameter(valid_606608, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_606608 != nil:
    section.add "Action", valid_606608
  var valid_606609 = query.getOrDefault("Version")
  valid_606609 = validateParameter(valid_606609, JString, required = true,
                                 default = newJString("2013-01-10"))
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
                                 default = newJString("2013-01-10"))
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
  var valid_606649 = query.getOrDefault("Action")
  valid_606649 = validateParameter(valid_606649, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_606649 != nil:
    section.add "Action", valid_606649
  var valid_606650 = query.getOrDefault("Version")
  valid_606650 = validateParameter(valid_606650, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Action: string = "CreateOptionGroup"; Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
  var valid_606687 = query.getOrDefault("Action")
  valid_606687 = validateParameter(valid_606687, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_606687 != nil:
    section.add "Action", valid_606687
  var valid_606688 = query.getOrDefault("Version")
  valid_606688 = validateParameter(valid_606688, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Action: string = "DeleteDBInstance"; Version: string = "2013-01-10";
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
  var valid_606722 = query.getOrDefault("Action")
  valid_606722 = validateParameter(valid_606722, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_606722 != nil:
    section.add "Action", valid_606722
  var valid_606723 = query.getOrDefault("Version")
  valid_606723 = validateParameter(valid_606723, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
  var valid_606755 = query.getOrDefault("Action")
  valid_606755 = validateParameter(valid_606755, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_606755 != nil:
    section.add "Action", valid_606755
  var valid_606756 = query.getOrDefault("Version")
  valid_606756 = validateParameter(valid_606756, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
  var valid_606788 = query.getOrDefault("Action")
  valid_606788 = validateParameter(valid_606788, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_606788 != nil:
    section.add "Action", valid_606788
  var valid_606789 = query.getOrDefault("Version")
  valid_606789 = validateParameter(valid_606789, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
  var valid_606821 = query.getOrDefault("Action")
  valid_606821 = validateParameter(valid_606821, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_606821 != nil:
    section.add "Action", valid_606821
  var valid_606822 = query.getOrDefault("Version")
  valid_606822 = validateParameter(valid_606822, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
  var valid_606854 = query.getOrDefault("Action")
  valid_606854 = validateParameter(valid_606854, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_606854 != nil:
    section.add "Action", valid_606854
  var valid_606855 = query.getOrDefault("Version")
  valid_606855 = validateParameter(valid_606855, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
  var valid_606887 = query.getOrDefault("Action")
  valid_606887 = validateParameter(valid_606887, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_606887 != nil:
    section.add "Action", valid_606887
  var valid_606888 = query.getOrDefault("Version")
  valid_606888 = validateParameter(valid_606888, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
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
  var valid_606926 = query.getOrDefault("Action")
  valid_606926 = validateParameter(valid_606926, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_606926 != nil:
    section.add "Action", valid_606926
  var valid_606927 = query.getOrDefault("Version")
  valid_606927 = validateParameter(valid_606927, JString, required = true,
                                 default = newJString("2013-01-10"))
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
                                 default = newJString("2013-01-10"))
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
  var valid_606967 = query.getOrDefault("Action")
  valid_606967 = validateParameter(valid_606967, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_606967 != nil:
    section.add "Action", valid_606967
  var valid_606968 = query.getOrDefault("Version")
  valid_606968 = validateParameter(valid_606968, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Action: string = "DescribeDBInstances"; Version: string = "2013-01-10"): Recallable =
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
  var valid_606951 = query.getOrDefault("Action")
  valid_606951 = validateParameter(valid_606951, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_606951 != nil:
    section.add "Action", valid_606951
  var valid_606952 = query.getOrDefault("Version")
  valid_606952 = validateParameter(valid_606952, JString, required = true,
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
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
  Call_PostDescribeDBParameterGroups_607001 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBParameterGroups_607003(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameterGroups_607002(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607004 = query.getOrDefault("Action")
  valid_607004 = validateParameter(valid_607004, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_607004 != nil:
    section.add "Action", valid_607004
  var valid_607005 = query.getOrDefault("Version")
  valid_607005 = validateParameter(valid_607005, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607005 != nil:
    section.add "Version", valid_607005
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607006 = header.getOrDefault("X-Amz-Signature")
  valid_607006 = validateParameter(valid_607006, JString, required = false,
                                 default = nil)
  if valid_607006 != nil:
    section.add "X-Amz-Signature", valid_607006
  var valid_607007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607007 = validateParameter(valid_607007, JString, required = false,
                                 default = nil)
  if valid_607007 != nil:
    section.add "X-Amz-Content-Sha256", valid_607007
  var valid_607008 = header.getOrDefault("X-Amz-Date")
  valid_607008 = validateParameter(valid_607008, JString, required = false,
                                 default = nil)
  if valid_607008 != nil:
    section.add "X-Amz-Date", valid_607008
  var valid_607009 = header.getOrDefault("X-Amz-Credential")
  valid_607009 = validateParameter(valid_607009, JString, required = false,
                                 default = nil)
  if valid_607009 != nil:
    section.add "X-Amz-Credential", valid_607009
  var valid_607010 = header.getOrDefault("X-Amz-Security-Token")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "X-Amz-Security-Token", valid_607010
  var valid_607011 = header.getOrDefault("X-Amz-Algorithm")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "X-Amz-Algorithm", valid_607011
  var valid_607012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607012 = validateParameter(valid_607012, JString, required = false,
                                 default = nil)
  if valid_607012 != nil:
    section.add "X-Amz-SignedHeaders", valid_607012
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  section = newJObject()
  var valid_607013 = formData.getOrDefault("MaxRecords")
  valid_607013 = validateParameter(valid_607013, JInt, required = false, default = nil)
  if valid_607013 != nil:
    section.add "MaxRecords", valid_607013
  var valid_607014 = formData.getOrDefault("DBParameterGroupName")
  valid_607014 = validateParameter(valid_607014, JString, required = false,
                                 default = nil)
  if valid_607014 != nil:
    section.add "DBParameterGroupName", valid_607014
  var valid_607015 = formData.getOrDefault("Marker")
  valid_607015 = validateParameter(valid_607015, JString, required = false,
                                 default = nil)
  if valid_607015 != nil:
    section.add "Marker", valid_607015
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607016: Call_PostDescribeDBParameterGroups_607001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607016.validator(path, query, header, formData, body)
  let scheme = call_607016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607016.url(scheme.get, call_607016.host, call_607016.base,
                         call_607016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607016, url, valid)

proc call*(call_607017: Call_PostDescribeDBParameterGroups_607001;
          MaxRecords: int = 0; DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607018 = newJObject()
  var formData_607019 = newJObject()
  add(formData_607019, "MaxRecords", newJInt(MaxRecords))
  add(formData_607019, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_607019, "Marker", newJString(Marker))
  add(query_607018, "Action", newJString(Action))
  add(query_607018, "Version", newJString(Version))
  result = call_607017.call(nil, query_607018, nil, formData_607019, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_607001(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_607002, base: "/",
    url: url_PostDescribeDBParameterGroups_607003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_606983 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBParameterGroups_606985(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBParameterGroups_606984(path: JsonNode; query: JsonNode;
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
  var valid_606986 = query.getOrDefault("Marker")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "Marker", valid_606986
  var valid_606987 = query.getOrDefault("DBParameterGroupName")
  valid_606987 = validateParameter(valid_606987, JString, required = false,
                                 default = nil)
  if valid_606987 != nil:
    section.add "DBParameterGroupName", valid_606987
  var valid_606988 = query.getOrDefault("Action")
  valid_606988 = validateParameter(valid_606988, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_606988 != nil:
    section.add "Action", valid_606988
  var valid_606989 = query.getOrDefault("Version")
  valid_606989 = validateParameter(valid_606989, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_606989 != nil:
    section.add "Version", valid_606989
  var valid_606990 = query.getOrDefault("MaxRecords")
  valid_606990 = validateParameter(valid_606990, JInt, required = false, default = nil)
  if valid_606990 != nil:
    section.add "MaxRecords", valid_606990
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606991 = header.getOrDefault("X-Amz-Signature")
  valid_606991 = validateParameter(valid_606991, JString, required = false,
                                 default = nil)
  if valid_606991 != nil:
    section.add "X-Amz-Signature", valid_606991
  var valid_606992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606992 = validateParameter(valid_606992, JString, required = false,
                                 default = nil)
  if valid_606992 != nil:
    section.add "X-Amz-Content-Sha256", valid_606992
  var valid_606993 = header.getOrDefault("X-Amz-Date")
  valid_606993 = validateParameter(valid_606993, JString, required = false,
                                 default = nil)
  if valid_606993 != nil:
    section.add "X-Amz-Date", valid_606993
  var valid_606994 = header.getOrDefault("X-Amz-Credential")
  valid_606994 = validateParameter(valid_606994, JString, required = false,
                                 default = nil)
  if valid_606994 != nil:
    section.add "X-Amz-Credential", valid_606994
  var valid_606995 = header.getOrDefault("X-Amz-Security-Token")
  valid_606995 = validateParameter(valid_606995, JString, required = false,
                                 default = nil)
  if valid_606995 != nil:
    section.add "X-Amz-Security-Token", valid_606995
  var valid_606996 = header.getOrDefault("X-Amz-Algorithm")
  valid_606996 = validateParameter(valid_606996, JString, required = false,
                                 default = nil)
  if valid_606996 != nil:
    section.add "X-Amz-Algorithm", valid_606996
  var valid_606997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "X-Amz-SignedHeaders", valid_606997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606998: Call_GetDescribeDBParameterGroups_606983; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606998.validator(path, query, header, formData, body)
  let scheme = call_606998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606998.url(scheme.get, call_606998.host, call_606998.base,
                         call_606998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606998, url, valid)

proc call*(call_606999: Call_GetDescribeDBParameterGroups_606983;
          Marker: string = ""; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameterGroups
  ##   Marker: string
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_607000 = newJObject()
  add(query_607000, "Marker", newJString(Marker))
  add(query_607000, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607000, "Action", newJString(Action))
  add(query_607000, "Version", newJString(Version))
  add(query_607000, "MaxRecords", newJInt(MaxRecords))
  result = call_606999.call(nil, query_607000, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_606983(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_606984, base: "/",
    url: url_GetDescribeDBParameterGroups_606985,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_607039 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBParameters_607041(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameters_607040(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607042 = query.getOrDefault("Action")
  valid_607042 = validateParameter(valid_607042, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_607042 != nil:
    section.add "Action", valid_607042
  var valid_607043 = query.getOrDefault("Version")
  valid_607043 = validateParameter(valid_607043, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607043 != nil:
    section.add "Version", valid_607043
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607044 = header.getOrDefault("X-Amz-Signature")
  valid_607044 = validateParameter(valid_607044, JString, required = false,
                                 default = nil)
  if valid_607044 != nil:
    section.add "X-Amz-Signature", valid_607044
  var valid_607045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607045 = validateParameter(valid_607045, JString, required = false,
                                 default = nil)
  if valid_607045 != nil:
    section.add "X-Amz-Content-Sha256", valid_607045
  var valid_607046 = header.getOrDefault("X-Amz-Date")
  valid_607046 = validateParameter(valid_607046, JString, required = false,
                                 default = nil)
  if valid_607046 != nil:
    section.add "X-Amz-Date", valid_607046
  var valid_607047 = header.getOrDefault("X-Amz-Credential")
  valid_607047 = validateParameter(valid_607047, JString, required = false,
                                 default = nil)
  if valid_607047 != nil:
    section.add "X-Amz-Credential", valid_607047
  var valid_607048 = header.getOrDefault("X-Amz-Security-Token")
  valid_607048 = validateParameter(valid_607048, JString, required = false,
                                 default = nil)
  if valid_607048 != nil:
    section.add "X-Amz-Security-Token", valid_607048
  var valid_607049 = header.getOrDefault("X-Amz-Algorithm")
  valid_607049 = validateParameter(valid_607049, JString, required = false,
                                 default = nil)
  if valid_607049 != nil:
    section.add "X-Amz-Algorithm", valid_607049
  var valid_607050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607050 = validateParameter(valid_607050, JString, required = false,
                                 default = nil)
  if valid_607050 != nil:
    section.add "X-Amz-SignedHeaders", valid_607050
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  section = newJObject()
  var valid_607051 = formData.getOrDefault("Source")
  valid_607051 = validateParameter(valid_607051, JString, required = false,
                                 default = nil)
  if valid_607051 != nil:
    section.add "Source", valid_607051
  var valid_607052 = formData.getOrDefault("MaxRecords")
  valid_607052 = validateParameter(valid_607052, JInt, required = false, default = nil)
  if valid_607052 != nil:
    section.add "MaxRecords", valid_607052
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_607053 = formData.getOrDefault("DBParameterGroupName")
  valid_607053 = validateParameter(valid_607053, JString, required = true,
                                 default = nil)
  if valid_607053 != nil:
    section.add "DBParameterGroupName", valid_607053
  var valid_607054 = formData.getOrDefault("Marker")
  valid_607054 = validateParameter(valid_607054, JString, required = false,
                                 default = nil)
  if valid_607054 != nil:
    section.add "Marker", valid_607054
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607055: Call_PostDescribeDBParameters_607039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607055.validator(path, query, header, formData, body)
  let scheme = call_607055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607055.url(scheme.get, call_607055.host, call_607055.base,
                         call_607055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607055, url, valid)

proc call*(call_607056: Call_PostDescribeDBParameters_607039;
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
  var query_607057 = newJObject()
  var formData_607058 = newJObject()
  add(formData_607058, "Source", newJString(Source))
  add(formData_607058, "MaxRecords", newJInt(MaxRecords))
  add(formData_607058, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_607058, "Marker", newJString(Marker))
  add(query_607057, "Action", newJString(Action))
  add(query_607057, "Version", newJString(Version))
  result = call_607056.call(nil, query_607057, nil, formData_607058, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_607039(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_607040, base: "/",
    url: url_PostDescribeDBParameters_607041, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_607020 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBParameters_607022(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBParameters_607021(path: JsonNode; query: JsonNode;
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
  var valid_607023 = query.getOrDefault("Marker")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "Marker", valid_607023
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_607024 = query.getOrDefault("DBParameterGroupName")
  valid_607024 = validateParameter(valid_607024, JString, required = true,
                                 default = nil)
  if valid_607024 != nil:
    section.add "DBParameterGroupName", valid_607024
  var valid_607025 = query.getOrDefault("Source")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "Source", valid_607025
  var valid_607026 = query.getOrDefault("Action")
  valid_607026 = validateParameter(valid_607026, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_607026 != nil:
    section.add "Action", valid_607026
  var valid_607027 = query.getOrDefault("Version")
  valid_607027 = validateParameter(valid_607027, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607027 != nil:
    section.add "Version", valid_607027
  var valid_607028 = query.getOrDefault("MaxRecords")
  valid_607028 = validateParameter(valid_607028, JInt, required = false, default = nil)
  if valid_607028 != nil:
    section.add "MaxRecords", valid_607028
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607029 = header.getOrDefault("X-Amz-Signature")
  valid_607029 = validateParameter(valid_607029, JString, required = false,
                                 default = nil)
  if valid_607029 != nil:
    section.add "X-Amz-Signature", valid_607029
  var valid_607030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607030 = validateParameter(valid_607030, JString, required = false,
                                 default = nil)
  if valid_607030 != nil:
    section.add "X-Amz-Content-Sha256", valid_607030
  var valid_607031 = header.getOrDefault("X-Amz-Date")
  valid_607031 = validateParameter(valid_607031, JString, required = false,
                                 default = nil)
  if valid_607031 != nil:
    section.add "X-Amz-Date", valid_607031
  var valid_607032 = header.getOrDefault("X-Amz-Credential")
  valid_607032 = validateParameter(valid_607032, JString, required = false,
                                 default = nil)
  if valid_607032 != nil:
    section.add "X-Amz-Credential", valid_607032
  var valid_607033 = header.getOrDefault("X-Amz-Security-Token")
  valid_607033 = validateParameter(valid_607033, JString, required = false,
                                 default = nil)
  if valid_607033 != nil:
    section.add "X-Amz-Security-Token", valid_607033
  var valid_607034 = header.getOrDefault("X-Amz-Algorithm")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-Algorithm", valid_607034
  var valid_607035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607035 = validateParameter(valid_607035, JString, required = false,
                                 default = nil)
  if valid_607035 != nil:
    section.add "X-Amz-SignedHeaders", valid_607035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607036: Call_GetDescribeDBParameters_607020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607036.validator(path, query, header, formData, body)
  let scheme = call_607036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607036.url(scheme.get, call_607036.host, call_607036.base,
                         call_607036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607036, url, valid)

proc call*(call_607037: Call_GetDescribeDBParameters_607020;
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
  var query_607038 = newJObject()
  add(query_607038, "Marker", newJString(Marker))
  add(query_607038, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607038, "Source", newJString(Source))
  add(query_607038, "Action", newJString(Action))
  add(query_607038, "Version", newJString(Version))
  add(query_607038, "MaxRecords", newJInt(MaxRecords))
  result = call_607037.call(nil, query_607038, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_607020(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_607021, base: "/",
    url: url_GetDescribeDBParameters_607022, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_607077 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBSecurityGroups_607079(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSecurityGroups_607078(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607080 = query.getOrDefault("Action")
  valid_607080 = validateParameter(valid_607080, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_607080 != nil:
    section.add "Action", valid_607080
  var valid_607081 = query.getOrDefault("Version")
  valid_607081 = validateParameter(valid_607081, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607081 != nil:
    section.add "Version", valid_607081
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607082 = header.getOrDefault("X-Amz-Signature")
  valid_607082 = validateParameter(valid_607082, JString, required = false,
                                 default = nil)
  if valid_607082 != nil:
    section.add "X-Amz-Signature", valid_607082
  var valid_607083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607083 = validateParameter(valid_607083, JString, required = false,
                                 default = nil)
  if valid_607083 != nil:
    section.add "X-Amz-Content-Sha256", valid_607083
  var valid_607084 = header.getOrDefault("X-Amz-Date")
  valid_607084 = validateParameter(valid_607084, JString, required = false,
                                 default = nil)
  if valid_607084 != nil:
    section.add "X-Amz-Date", valid_607084
  var valid_607085 = header.getOrDefault("X-Amz-Credential")
  valid_607085 = validateParameter(valid_607085, JString, required = false,
                                 default = nil)
  if valid_607085 != nil:
    section.add "X-Amz-Credential", valid_607085
  var valid_607086 = header.getOrDefault("X-Amz-Security-Token")
  valid_607086 = validateParameter(valid_607086, JString, required = false,
                                 default = nil)
  if valid_607086 != nil:
    section.add "X-Amz-Security-Token", valid_607086
  var valid_607087 = header.getOrDefault("X-Amz-Algorithm")
  valid_607087 = validateParameter(valid_607087, JString, required = false,
                                 default = nil)
  if valid_607087 != nil:
    section.add "X-Amz-Algorithm", valid_607087
  var valid_607088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607088 = validateParameter(valid_607088, JString, required = false,
                                 default = nil)
  if valid_607088 != nil:
    section.add "X-Amz-SignedHeaders", valid_607088
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  section = newJObject()
  var valid_607089 = formData.getOrDefault("DBSecurityGroupName")
  valid_607089 = validateParameter(valid_607089, JString, required = false,
                                 default = nil)
  if valid_607089 != nil:
    section.add "DBSecurityGroupName", valid_607089
  var valid_607090 = formData.getOrDefault("MaxRecords")
  valid_607090 = validateParameter(valid_607090, JInt, required = false, default = nil)
  if valid_607090 != nil:
    section.add "MaxRecords", valid_607090
  var valid_607091 = formData.getOrDefault("Marker")
  valid_607091 = validateParameter(valid_607091, JString, required = false,
                                 default = nil)
  if valid_607091 != nil:
    section.add "Marker", valid_607091
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607092: Call_PostDescribeDBSecurityGroups_607077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607092.validator(path, query, header, formData, body)
  let scheme = call_607092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607092.url(scheme.get, call_607092.host, call_607092.base,
                         call_607092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607092, url, valid)

proc call*(call_607093: Call_PostDescribeDBSecurityGroups_607077;
          DBSecurityGroupName: string = ""; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607094 = newJObject()
  var formData_607095 = newJObject()
  add(formData_607095, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_607095, "MaxRecords", newJInt(MaxRecords))
  add(formData_607095, "Marker", newJString(Marker))
  add(query_607094, "Action", newJString(Action))
  add(query_607094, "Version", newJString(Version))
  result = call_607093.call(nil, query_607094, nil, formData_607095, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_607077(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_607078, base: "/",
    url: url_PostDescribeDBSecurityGroups_607079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_607059 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBSecurityGroups_607061(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSecurityGroups_607060(path: JsonNode; query: JsonNode;
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
  var valid_607062 = query.getOrDefault("Marker")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "Marker", valid_607062
  var valid_607063 = query.getOrDefault("DBSecurityGroupName")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "DBSecurityGroupName", valid_607063
  var valid_607064 = query.getOrDefault("Action")
  valid_607064 = validateParameter(valid_607064, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_607064 != nil:
    section.add "Action", valid_607064
  var valid_607065 = query.getOrDefault("Version")
  valid_607065 = validateParameter(valid_607065, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607065 != nil:
    section.add "Version", valid_607065
  var valid_607066 = query.getOrDefault("MaxRecords")
  valid_607066 = validateParameter(valid_607066, JInt, required = false, default = nil)
  if valid_607066 != nil:
    section.add "MaxRecords", valid_607066
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607067 = header.getOrDefault("X-Amz-Signature")
  valid_607067 = validateParameter(valid_607067, JString, required = false,
                                 default = nil)
  if valid_607067 != nil:
    section.add "X-Amz-Signature", valid_607067
  var valid_607068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607068 = validateParameter(valid_607068, JString, required = false,
                                 default = nil)
  if valid_607068 != nil:
    section.add "X-Amz-Content-Sha256", valid_607068
  var valid_607069 = header.getOrDefault("X-Amz-Date")
  valid_607069 = validateParameter(valid_607069, JString, required = false,
                                 default = nil)
  if valid_607069 != nil:
    section.add "X-Amz-Date", valid_607069
  var valid_607070 = header.getOrDefault("X-Amz-Credential")
  valid_607070 = validateParameter(valid_607070, JString, required = false,
                                 default = nil)
  if valid_607070 != nil:
    section.add "X-Amz-Credential", valid_607070
  var valid_607071 = header.getOrDefault("X-Amz-Security-Token")
  valid_607071 = validateParameter(valid_607071, JString, required = false,
                                 default = nil)
  if valid_607071 != nil:
    section.add "X-Amz-Security-Token", valid_607071
  var valid_607072 = header.getOrDefault("X-Amz-Algorithm")
  valid_607072 = validateParameter(valid_607072, JString, required = false,
                                 default = nil)
  if valid_607072 != nil:
    section.add "X-Amz-Algorithm", valid_607072
  var valid_607073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607073 = validateParameter(valid_607073, JString, required = false,
                                 default = nil)
  if valid_607073 != nil:
    section.add "X-Amz-SignedHeaders", valid_607073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607074: Call_GetDescribeDBSecurityGroups_607059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607074.validator(path, query, header, formData, body)
  let scheme = call_607074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607074.url(scheme.get, call_607074.host, call_607074.base,
                         call_607074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607074, url, valid)

proc call*(call_607075: Call_GetDescribeDBSecurityGroups_607059;
          Marker: string = ""; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Marker: string
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_607076 = newJObject()
  add(query_607076, "Marker", newJString(Marker))
  add(query_607076, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_607076, "Action", newJString(Action))
  add(query_607076, "Version", newJString(Version))
  add(query_607076, "MaxRecords", newJInt(MaxRecords))
  result = call_607075.call(nil, query_607076, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_607059(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_607060, base: "/",
    url: url_GetDescribeDBSecurityGroups_607061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_607116 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBSnapshots_607118(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBSnapshots_607117(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607119 = query.getOrDefault("Action")
  valid_607119 = validateParameter(valid_607119, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_607119 != nil:
    section.add "Action", valid_607119
  var valid_607120 = query.getOrDefault("Version")
  valid_607120 = validateParameter(valid_607120, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607120 != nil:
    section.add "Version", valid_607120
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607121 = header.getOrDefault("X-Amz-Signature")
  valid_607121 = validateParameter(valid_607121, JString, required = false,
                                 default = nil)
  if valid_607121 != nil:
    section.add "X-Amz-Signature", valid_607121
  var valid_607122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607122 = validateParameter(valid_607122, JString, required = false,
                                 default = nil)
  if valid_607122 != nil:
    section.add "X-Amz-Content-Sha256", valid_607122
  var valid_607123 = header.getOrDefault("X-Amz-Date")
  valid_607123 = validateParameter(valid_607123, JString, required = false,
                                 default = nil)
  if valid_607123 != nil:
    section.add "X-Amz-Date", valid_607123
  var valid_607124 = header.getOrDefault("X-Amz-Credential")
  valid_607124 = validateParameter(valid_607124, JString, required = false,
                                 default = nil)
  if valid_607124 != nil:
    section.add "X-Amz-Credential", valid_607124
  var valid_607125 = header.getOrDefault("X-Amz-Security-Token")
  valid_607125 = validateParameter(valid_607125, JString, required = false,
                                 default = nil)
  if valid_607125 != nil:
    section.add "X-Amz-Security-Token", valid_607125
  var valid_607126 = header.getOrDefault("X-Amz-Algorithm")
  valid_607126 = validateParameter(valid_607126, JString, required = false,
                                 default = nil)
  if valid_607126 != nil:
    section.add "X-Amz-Algorithm", valid_607126
  var valid_607127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607127 = validateParameter(valid_607127, JString, required = false,
                                 default = nil)
  if valid_607127 != nil:
    section.add "X-Amz-SignedHeaders", valid_607127
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  section = newJObject()
  var valid_607128 = formData.getOrDefault("SnapshotType")
  valid_607128 = validateParameter(valid_607128, JString, required = false,
                                 default = nil)
  if valid_607128 != nil:
    section.add "SnapshotType", valid_607128
  var valid_607129 = formData.getOrDefault("MaxRecords")
  valid_607129 = validateParameter(valid_607129, JInt, required = false, default = nil)
  if valid_607129 != nil:
    section.add "MaxRecords", valid_607129
  var valid_607130 = formData.getOrDefault("Marker")
  valid_607130 = validateParameter(valid_607130, JString, required = false,
                                 default = nil)
  if valid_607130 != nil:
    section.add "Marker", valid_607130
  var valid_607131 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "DBInstanceIdentifier", valid_607131
  var valid_607132 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_607132 = validateParameter(valid_607132, JString, required = false,
                                 default = nil)
  if valid_607132 != nil:
    section.add "DBSnapshotIdentifier", valid_607132
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607133: Call_PostDescribeDBSnapshots_607116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607133.validator(path, query, header, formData, body)
  let scheme = call_607133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607133.url(scheme.get, call_607133.host, call_607133.base,
                         call_607133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607133, url, valid)

proc call*(call_607134: Call_PostDescribeDBSnapshots_607116;
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
  var query_607135 = newJObject()
  var formData_607136 = newJObject()
  add(formData_607136, "SnapshotType", newJString(SnapshotType))
  add(formData_607136, "MaxRecords", newJInt(MaxRecords))
  add(formData_607136, "Marker", newJString(Marker))
  add(formData_607136, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_607136, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_607135, "Action", newJString(Action))
  add(query_607135, "Version", newJString(Version))
  result = call_607134.call(nil, query_607135, nil, formData_607136, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_607116(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_607117, base: "/",
    url: url_PostDescribeDBSnapshots_607118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_607096 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBSnapshots_607098(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBSnapshots_607097(path: JsonNode; query: JsonNode;
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
  var valid_607099 = query.getOrDefault("Marker")
  valid_607099 = validateParameter(valid_607099, JString, required = false,
                                 default = nil)
  if valid_607099 != nil:
    section.add "Marker", valid_607099
  var valid_607100 = query.getOrDefault("DBInstanceIdentifier")
  valid_607100 = validateParameter(valid_607100, JString, required = false,
                                 default = nil)
  if valid_607100 != nil:
    section.add "DBInstanceIdentifier", valid_607100
  var valid_607101 = query.getOrDefault("DBSnapshotIdentifier")
  valid_607101 = validateParameter(valid_607101, JString, required = false,
                                 default = nil)
  if valid_607101 != nil:
    section.add "DBSnapshotIdentifier", valid_607101
  var valid_607102 = query.getOrDefault("SnapshotType")
  valid_607102 = validateParameter(valid_607102, JString, required = false,
                                 default = nil)
  if valid_607102 != nil:
    section.add "SnapshotType", valid_607102
  var valid_607103 = query.getOrDefault("Action")
  valid_607103 = validateParameter(valid_607103, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_607103 != nil:
    section.add "Action", valid_607103
  var valid_607104 = query.getOrDefault("Version")
  valid_607104 = validateParameter(valid_607104, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607104 != nil:
    section.add "Version", valid_607104
  var valid_607105 = query.getOrDefault("MaxRecords")
  valid_607105 = validateParameter(valid_607105, JInt, required = false, default = nil)
  if valid_607105 != nil:
    section.add "MaxRecords", valid_607105
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607106 = header.getOrDefault("X-Amz-Signature")
  valid_607106 = validateParameter(valid_607106, JString, required = false,
                                 default = nil)
  if valid_607106 != nil:
    section.add "X-Amz-Signature", valid_607106
  var valid_607107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607107 = validateParameter(valid_607107, JString, required = false,
                                 default = nil)
  if valid_607107 != nil:
    section.add "X-Amz-Content-Sha256", valid_607107
  var valid_607108 = header.getOrDefault("X-Amz-Date")
  valid_607108 = validateParameter(valid_607108, JString, required = false,
                                 default = nil)
  if valid_607108 != nil:
    section.add "X-Amz-Date", valid_607108
  var valid_607109 = header.getOrDefault("X-Amz-Credential")
  valid_607109 = validateParameter(valid_607109, JString, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "X-Amz-Credential", valid_607109
  var valid_607110 = header.getOrDefault("X-Amz-Security-Token")
  valid_607110 = validateParameter(valid_607110, JString, required = false,
                                 default = nil)
  if valid_607110 != nil:
    section.add "X-Amz-Security-Token", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-Algorithm")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-Algorithm", valid_607111
  var valid_607112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "X-Amz-SignedHeaders", valid_607112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607113: Call_GetDescribeDBSnapshots_607096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607113.validator(path, query, header, formData, body)
  let scheme = call_607113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607113.url(scheme.get, call_607113.host, call_607113.base,
                         call_607113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607113, url, valid)

proc call*(call_607114: Call_GetDescribeDBSnapshots_607096; Marker: string = "";
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
  var query_607115 = newJObject()
  add(query_607115, "Marker", newJString(Marker))
  add(query_607115, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607115, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_607115, "SnapshotType", newJString(SnapshotType))
  add(query_607115, "Action", newJString(Action))
  add(query_607115, "Version", newJString(Version))
  add(query_607115, "MaxRecords", newJInt(MaxRecords))
  result = call_607114.call(nil, query_607115, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_607096(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_607097, base: "/",
    url: url_GetDescribeDBSnapshots_607098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_607155 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBSubnetGroups_607157(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSubnetGroups_607156(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607158 = query.getOrDefault("Action")
  valid_607158 = validateParameter(valid_607158, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_607158 != nil:
    section.add "Action", valid_607158
  var valid_607159 = query.getOrDefault("Version")
  valid_607159 = validateParameter(valid_607159, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607159 != nil:
    section.add "Version", valid_607159
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607160 = header.getOrDefault("X-Amz-Signature")
  valid_607160 = validateParameter(valid_607160, JString, required = false,
                                 default = nil)
  if valid_607160 != nil:
    section.add "X-Amz-Signature", valid_607160
  var valid_607161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607161 = validateParameter(valid_607161, JString, required = false,
                                 default = nil)
  if valid_607161 != nil:
    section.add "X-Amz-Content-Sha256", valid_607161
  var valid_607162 = header.getOrDefault("X-Amz-Date")
  valid_607162 = validateParameter(valid_607162, JString, required = false,
                                 default = nil)
  if valid_607162 != nil:
    section.add "X-Amz-Date", valid_607162
  var valid_607163 = header.getOrDefault("X-Amz-Credential")
  valid_607163 = validateParameter(valid_607163, JString, required = false,
                                 default = nil)
  if valid_607163 != nil:
    section.add "X-Amz-Credential", valid_607163
  var valid_607164 = header.getOrDefault("X-Amz-Security-Token")
  valid_607164 = validateParameter(valid_607164, JString, required = false,
                                 default = nil)
  if valid_607164 != nil:
    section.add "X-Amz-Security-Token", valid_607164
  var valid_607165 = header.getOrDefault("X-Amz-Algorithm")
  valid_607165 = validateParameter(valid_607165, JString, required = false,
                                 default = nil)
  if valid_607165 != nil:
    section.add "X-Amz-Algorithm", valid_607165
  var valid_607166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607166 = validateParameter(valid_607166, JString, required = false,
                                 default = nil)
  if valid_607166 != nil:
    section.add "X-Amz-SignedHeaders", valid_607166
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  section = newJObject()
  var valid_607167 = formData.getOrDefault("MaxRecords")
  valid_607167 = validateParameter(valid_607167, JInt, required = false, default = nil)
  if valid_607167 != nil:
    section.add "MaxRecords", valid_607167
  var valid_607168 = formData.getOrDefault("Marker")
  valid_607168 = validateParameter(valid_607168, JString, required = false,
                                 default = nil)
  if valid_607168 != nil:
    section.add "Marker", valid_607168
  var valid_607169 = formData.getOrDefault("DBSubnetGroupName")
  valid_607169 = validateParameter(valid_607169, JString, required = false,
                                 default = nil)
  if valid_607169 != nil:
    section.add "DBSubnetGroupName", valid_607169
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607170: Call_PostDescribeDBSubnetGroups_607155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607170.validator(path, query, header, formData, body)
  let scheme = call_607170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607170.url(scheme.get, call_607170.host, call_607170.base,
                         call_607170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607170, url, valid)

proc call*(call_607171: Call_PostDescribeDBSubnetGroups_607155;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_607172 = newJObject()
  var formData_607173 = newJObject()
  add(formData_607173, "MaxRecords", newJInt(MaxRecords))
  add(formData_607173, "Marker", newJString(Marker))
  add(query_607172, "Action", newJString(Action))
  add(formData_607173, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607172, "Version", newJString(Version))
  result = call_607171.call(nil, query_607172, nil, formData_607173, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_607155(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_607156, base: "/",
    url: url_PostDescribeDBSubnetGroups_607157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_607137 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBSubnetGroups_607139(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSubnetGroups_607138(path: JsonNode; query: JsonNode;
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
  var valid_607140 = query.getOrDefault("Marker")
  valid_607140 = validateParameter(valid_607140, JString, required = false,
                                 default = nil)
  if valid_607140 != nil:
    section.add "Marker", valid_607140
  var valid_607141 = query.getOrDefault("Action")
  valid_607141 = validateParameter(valid_607141, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_607141 != nil:
    section.add "Action", valid_607141
  var valid_607142 = query.getOrDefault("DBSubnetGroupName")
  valid_607142 = validateParameter(valid_607142, JString, required = false,
                                 default = nil)
  if valid_607142 != nil:
    section.add "DBSubnetGroupName", valid_607142
  var valid_607143 = query.getOrDefault("Version")
  valid_607143 = validateParameter(valid_607143, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607143 != nil:
    section.add "Version", valid_607143
  var valid_607144 = query.getOrDefault("MaxRecords")
  valid_607144 = validateParameter(valid_607144, JInt, required = false, default = nil)
  if valid_607144 != nil:
    section.add "MaxRecords", valid_607144
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607145 = header.getOrDefault("X-Amz-Signature")
  valid_607145 = validateParameter(valid_607145, JString, required = false,
                                 default = nil)
  if valid_607145 != nil:
    section.add "X-Amz-Signature", valid_607145
  var valid_607146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607146 = validateParameter(valid_607146, JString, required = false,
                                 default = nil)
  if valid_607146 != nil:
    section.add "X-Amz-Content-Sha256", valid_607146
  var valid_607147 = header.getOrDefault("X-Amz-Date")
  valid_607147 = validateParameter(valid_607147, JString, required = false,
                                 default = nil)
  if valid_607147 != nil:
    section.add "X-Amz-Date", valid_607147
  var valid_607148 = header.getOrDefault("X-Amz-Credential")
  valid_607148 = validateParameter(valid_607148, JString, required = false,
                                 default = nil)
  if valid_607148 != nil:
    section.add "X-Amz-Credential", valid_607148
  var valid_607149 = header.getOrDefault("X-Amz-Security-Token")
  valid_607149 = validateParameter(valid_607149, JString, required = false,
                                 default = nil)
  if valid_607149 != nil:
    section.add "X-Amz-Security-Token", valid_607149
  var valid_607150 = header.getOrDefault("X-Amz-Algorithm")
  valid_607150 = validateParameter(valid_607150, JString, required = false,
                                 default = nil)
  if valid_607150 != nil:
    section.add "X-Amz-Algorithm", valid_607150
  var valid_607151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607151 = validateParameter(valid_607151, JString, required = false,
                                 default = nil)
  if valid_607151 != nil:
    section.add "X-Amz-SignedHeaders", valid_607151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607152: Call_GetDescribeDBSubnetGroups_607137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607152.validator(path, query, header, formData, body)
  let scheme = call_607152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607152.url(scheme.get, call_607152.host, call_607152.base,
                         call_607152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607152, url, valid)

proc call*(call_607153: Call_GetDescribeDBSubnetGroups_607137; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_607154 = newJObject()
  add(query_607154, "Marker", newJString(Marker))
  add(query_607154, "Action", newJString(Action))
  add(query_607154, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607154, "Version", newJString(Version))
  add(query_607154, "MaxRecords", newJInt(MaxRecords))
  result = call_607153.call(nil, query_607154, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_607137(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_607138, base: "/",
    url: url_GetDescribeDBSubnetGroups_607139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_607192 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEngineDefaultParameters_607194(protocol: Scheme; host: string;
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

proc validate_PostDescribeEngineDefaultParameters_607193(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607195 = query.getOrDefault("Action")
  valid_607195 = validateParameter(valid_607195, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_607195 != nil:
    section.add "Action", valid_607195
  var valid_607196 = query.getOrDefault("Version")
  valid_607196 = validateParameter(valid_607196, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607196 != nil:
    section.add "Version", valid_607196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607197 = header.getOrDefault("X-Amz-Signature")
  valid_607197 = validateParameter(valid_607197, JString, required = false,
                                 default = nil)
  if valid_607197 != nil:
    section.add "X-Amz-Signature", valid_607197
  var valid_607198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607198 = validateParameter(valid_607198, JString, required = false,
                                 default = nil)
  if valid_607198 != nil:
    section.add "X-Amz-Content-Sha256", valid_607198
  var valid_607199 = header.getOrDefault("X-Amz-Date")
  valid_607199 = validateParameter(valid_607199, JString, required = false,
                                 default = nil)
  if valid_607199 != nil:
    section.add "X-Amz-Date", valid_607199
  var valid_607200 = header.getOrDefault("X-Amz-Credential")
  valid_607200 = validateParameter(valid_607200, JString, required = false,
                                 default = nil)
  if valid_607200 != nil:
    section.add "X-Amz-Credential", valid_607200
  var valid_607201 = header.getOrDefault("X-Amz-Security-Token")
  valid_607201 = validateParameter(valid_607201, JString, required = false,
                                 default = nil)
  if valid_607201 != nil:
    section.add "X-Amz-Security-Token", valid_607201
  var valid_607202 = header.getOrDefault("X-Amz-Algorithm")
  valid_607202 = validateParameter(valid_607202, JString, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "X-Amz-Algorithm", valid_607202
  var valid_607203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-SignedHeaders", valid_607203
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_607204 = formData.getOrDefault("MaxRecords")
  valid_607204 = validateParameter(valid_607204, JInt, required = false, default = nil)
  if valid_607204 != nil:
    section.add "MaxRecords", valid_607204
  var valid_607205 = formData.getOrDefault("Marker")
  valid_607205 = validateParameter(valid_607205, JString, required = false,
                                 default = nil)
  if valid_607205 != nil:
    section.add "Marker", valid_607205
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_607206 = formData.getOrDefault("DBParameterGroupFamily")
  valid_607206 = validateParameter(valid_607206, JString, required = true,
                                 default = nil)
  if valid_607206 != nil:
    section.add "DBParameterGroupFamily", valid_607206
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607207: Call_PostDescribeEngineDefaultParameters_607192;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607207.validator(path, query, header, formData, body)
  let scheme = call_607207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607207.url(scheme.get, call_607207.host, call_607207.base,
                         call_607207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607207, url, valid)

proc call*(call_607208: Call_PostDescribeEngineDefaultParameters_607192;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_607209 = newJObject()
  var formData_607210 = newJObject()
  add(formData_607210, "MaxRecords", newJInt(MaxRecords))
  add(formData_607210, "Marker", newJString(Marker))
  add(query_607209, "Action", newJString(Action))
  add(query_607209, "Version", newJString(Version))
  add(formData_607210, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_607208.call(nil, query_607209, nil, formData_607210, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_607192(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_607193, base: "/",
    url: url_PostDescribeEngineDefaultParameters_607194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_607174 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEngineDefaultParameters_607176(protocol: Scheme; host: string;
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

proc validate_GetDescribeEngineDefaultParameters_607175(path: JsonNode;
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
  var valid_607177 = query.getOrDefault("Marker")
  valid_607177 = validateParameter(valid_607177, JString, required = false,
                                 default = nil)
  if valid_607177 != nil:
    section.add "Marker", valid_607177
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_607178 = query.getOrDefault("DBParameterGroupFamily")
  valid_607178 = validateParameter(valid_607178, JString, required = true,
                                 default = nil)
  if valid_607178 != nil:
    section.add "DBParameterGroupFamily", valid_607178
  var valid_607179 = query.getOrDefault("Action")
  valid_607179 = validateParameter(valid_607179, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_607179 != nil:
    section.add "Action", valid_607179
  var valid_607180 = query.getOrDefault("Version")
  valid_607180 = validateParameter(valid_607180, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607180 != nil:
    section.add "Version", valid_607180
  var valid_607181 = query.getOrDefault("MaxRecords")
  valid_607181 = validateParameter(valid_607181, JInt, required = false, default = nil)
  if valid_607181 != nil:
    section.add "MaxRecords", valid_607181
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607182 = header.getOrDefault("X-Amz-Signature")
  valid_607182 = validateParameter(valid_607182, JString, required = false,
                                 default = nil)
  if valid_607182 != nil:
    section.add "X-Amz-Signature", valid_607182
  var valid_607183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607183 = validateParameter(valid_607183, JString, required = false,
                                 default = nil)
  if valid_607183 != nil:
    section.add "X-Amz-Content-Sha256", valid_607183
  var valid_607184 = header.getOrDefault("X-Amz-Date")
  valid_607184 = validateParameter(valid_607184, JString, required = false,
                                 default = nil)
  if valid_607184 != nil:
    section.add "X-Amz-Date", valid_607184
  var valid_607185 = header.getOrDefault("X-Amz-Credential")
  valid_607185 = validateParameter(valid_607185, JString, required = false,
                                 default = nil)
  if valid_607185 != nil:
    section.add "X-Amz-Credential", valid_607185
  var valid_607186 = header.getOrDefault("X-Amz-Security-Token")
  valid_607186 = validateParameter(valid_607186, JString, required = false,
                                 default = nil)
  if valid_607186 != nil:
    section.add "X-Amz-Security-Token", valid_607186
  var valid_607187 = header.getOrDefault("X-Amz-Algorithm")
  valid_607187 = validateParameter(valid_607187, JString, required = false,
                                 default = nil)
  if valid_607187 != nil:
    section.add "X-Amz-Algorithm", valid_607187
  var valid_607188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607188 = validateParameter(valid_607188, JString, required = false,
                                 default = nil)
  if valid_607188 != nil:
    section.add "X-Amz-SignedHeaders", valid_607188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607189: Call_GetDescribeEngineDefaultParameters_607174;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607189.validator(path, query, header, formData, body)
  let scheme = call_607189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607189.url(scheme.get, call_607189.host, call_607189.base,
                         call_607189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607189, url, valid)

proc call*(call_607190: Call_GetDescribeEngineDefaultParameters_607174;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_607191 = newJObject()
  add(query_607191, "Marker", newJString(Marker))
  add(query_607191, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_607191, "Action", newJString(Action))
  add(query_607191, "Version", newJString(Version))
  add(query_607191, "MaxRecords", newJInt(MaxRecords))
  result = call_607190.call(nil, query_607191, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_607174(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_607175, base: "/",
    url: url_GetDescribeEngineDefaultParameters_607176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_607227 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEventCategories_607229(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventCategories_607228(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607230 = query.getOrDefault("Action")
  valid_607230 = validateParameter(valid_607230, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_607230 != nil:
    section.add "Action", valid_607230
  var valid_607231 = query.getOrDefault("Version")
  valid_607231 = validateParameter(valid_607231, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607231 != nil:
    section.add "Version", valid_607231
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607232 = header.getOrDefault("X-Amz-Signature")
  valid_607232 = validateParameter(valid_607232, JString, required = false,
                                 default = nil)
  if valid_607232 != nil:
    section.add "X-Amz-Signature", valid_607232
  var valid_607233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607233 = validateParameter(valid_607233, JString, required = false,
                                 default = nil)
  if valid_607233 != nil:
    section.add "X-Amz-Content-Sha256", valid_607233
  var valid_607234 = header.getOrDefault("X-Amz-Date")
  valid_607234 = validateParameter(valid_607234, JString, required = false,
                                 default = nil)
  if valid_607234 != nil:
    section.add "X-Amz-Date", valid_607234
  var valid_607235 = header.getOrDefault("X-Amz-Credential")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "X-Amz-Credential", valid_607235
  var valid_607236 = header.getOrDefault("X-Amz-Security-Token")
  valid_607236 = validateParameter(valid_607236, JString, required = false,
                                 default = nil)
  if valid_607236 != nil:
    section.add "X-Amz-Security-Token", valid_607236
  var valid_607237 = header.getOrDefault("X-Amz-Algorithm")
  valid_607237 = validateParameter(valid_607237, JString, required = false,
                                 default = nil)
  if valid_607237 != nil:
    section.add "X-Amz-Algorithm", valid_607237
  var valid_607238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607238 = validateParameter(valid_607238, JString, required = false,
                                 default = nil)
  if valid_607238 != nil:
    section.add "X-Amz-SignedHeaders", valid_607238
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_607239 = formData.getOrDefault("SourceType")
  valid_607239 = validateParameter(valid_607239, JString, required = false,
                                 default = nil)
  if valid_607239 != nil:
    section.add "SourceType", valid_607239
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607240: Call_PostDescribeEventCategories_607227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607240.validator(path, query, header, formData, body)
  let scheme = call_607240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607240.url(scheme.get, call_607240.host, call_607240.base,
                         call_607240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607240, url, valid)

proc call*(call_607241: Call_PostDescribeEventCategories_607227;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607242 = newJObject()
  var formData_607243 = newJObject()
  add(formData_607243, "SourceType", newJString(SourceType))
  add(query_607242, "Action", newJString(Action))
  add(query_607242, "Version", newJString(Version))
  result = call_607241.call(nil, query_607242, nil, formData_607243, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_607227(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_607228, base: "/",
    url: url_PostDescribeEventCategories_607229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_607211 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEventCategories_607213(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventCategories_607212(path: JsonNode; query: JsonNode;
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
  var valid_607214 = query.getOrDefault("SourceType")
  valid_607214 = validateParameter(valid_607214, JString, required = false,
                                 default = nil)
  if valid_607214 != nil:
    section.add "SourceType", valid_607214
  var valid_607215 = query.getOrDefault("Action")
  valid_607215 = validateParameter(valid_607215, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_607215 != nil:
    section.add "Action", valid_607215
  var valid_607216 = query.getOrDefault("Version")
  valid_607216 = validateParameter(valid_607216, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607216 != nil:
    section.add "Version", valid_607216
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607217 = header.getOrDefault("X-Amz-Signature")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "X-Amz-Signature", valid_607217
  var valid_607218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "X-Amz-Content-Sha256", valid_607218
  var valid_607219 = header.getOrDefault("X-Amz-Date")
  valid_607219 = validateParameter(valid_607219, JString, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "X-Amz-Date", valid_607219
  var valid_607220 = header.getOrDefault("X-Amz-Credential")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "X-Amz-Credential", valid_607220
  var valid_607221 = header.getOrDefault("X-Amz-Security-Token")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "X-Amz-Security-Token", valid_607221
  var valid_607222 = header.getOrDefault("X-Amz-Algorithm")
  valid_607222 = validateParameter(valid_607222, JString, required = false,
                                 default = nil)
  if valid_607222 != nil:
    section.add "X-Amz-Algorithm", valid_607222
  var valid_607223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607223 = validateParameter(valid_607223, JString, required = false,
                                 default = nil)
  if valid_607223 != nil:
    section.add "X-Amz-SignedHeaders", valid_607223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607224: Call_GetDescribeEventCategories_607211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607224.validator(path, query, header, formData, body)
  let scheme = call_607224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607224.url(scheme.get, call_607224.host, call_607224.base,
                         call_607224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607224, url, valid)

proc call*(call_607225: Call_GetDescribeEventCategories_607211;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607226 = newJObject()
  add(query_607226, "SourceType", newJString(SourceType))
  add(query_607226, "Action", newJString(Action))
  add(query_607226, "Version", newJString(Version))
  result = call_607225.call(nil, query_607226, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_607211(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_607212, base: "/",
    url: url_GetDescribeEventCategories_607213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_607262 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEventSubscriptions_607264(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventSubscriptions_607263(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607265 = query.getOrDefault("Action")
  valid_607265 = validateParameter(valid_607265, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_607265 != nil:
    section.add "Action", valid_607265
  var valid_607266 = query.getOrDefault("Version")
  valid_607266 = validateParameter(valid_607266, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607266 != nil:
    section.add "Version", valid_607266
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607267 = header.getOrDefault("X-Amz-Signature")
  valid_607267 = validateParameter(valid_607267, JString, required = false,
                                 default = nil)
  if valid_607267 != nil:
    section.add "X-Amz-Signature", valid_607267
  var valid_607268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607268 = validateParameter(valid_607268, JString, required = false,
                                 default = nil)
  if valid_607268 != nil:
    section.add "X-Amz-Content-Sha256", valid_607268
  var valid_607269 = header.getOrDefault("X-Amz-Date")
  valid_607269 = validateParameter(valid_607269, JString, required = false,
                                 default = nil)
  if valid_607269 != nil:
    section.add "X-Amz-Date", valid_607269
  var valid_607270 = header.getOrDefault("X-Amz-Credential")
  valid_607270 = validateParameter(valid_607270, JString, required = false,
                                 default = nil)
  if valid_607270 != nil:
    section.add "X-Amz-Credential", valid_607270
  var valid_607271 = header.getOrDefault("X-Amz-Security-Token")
  valid_607271 = validateParameter(valid_607271, JString, required = false,
                                 default = nil)
  if valid_607271 != nil:
    section.add "X-Amz-Security-Token", valid_607271
  var valid_607272 = header.getOrDefault("X-Amz-Algorithm")
  valid_607272 = validateParameter(valid_607272, JString, required = false,
                                 default = nil)
  if valid_607272 != nil:
    section.add "X-Amz-Algorithm", valid_607272
  var valid_607273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607273 = validateParameter(valid_607273, JString, required = false,
                                 default = nil)
  if valid_607273 != nil:
    section.add "X-Amz-SignedHeaders", valid_607273
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  section = newJObject()
  var valid_607274 = formData.getOrDefault("MaxRecords")
  valid_607274 = validateParameter(valid_607274, JInt, required = false, default = nil)
  if valid_607274 != nil:
    section.add "MaxRecords", valid_607274
  var valid_607275 = formData.getOrDefault("Marker")
  valid_607275 = validateParameter(valid_607275, JString, required = false,
                                 default = nil)
  if valid_607275 != nil:
    section.add "Marker", valid_607275
  var valid_607276 = formData.getOrDefault("SubscriptionName")
  valid_607276 = validateParameter(valid_607276, JString, required = false,
                                 default = nil)
  if valid_607276 != nil:
    section.add "SubscriptionName", valid_607276
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607277: Call_PostDescribeEventSubscriptions_607262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607277.validator(path, query, header, formData, body)
  let scheme = call_607277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607277.url(scheme.get, call_607277.host, call_607277.base,
                         call_607277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607277, url, valid)

proc call*(call_607278: Call_PostDescribeEventSubscriptions_607262;
          MaxRecords: int = 0; Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607279 = newJObject()
  var formData_607280 = newJObject()
  add(formData_607280, "MaxRecords", newJInt(MaxRecords))
  add(formData_607280, "Marker", newJString(Marker))
  add(formData_607280, "SubscriptionName", newJString(SubscriptionName))
  add(query_607279, "Action", newJString(Action))
  add(query_607279, "Version", newJString(Version))
  result = call_607278.call(nil, query_607279, nil, formData_607280, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_607262(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_607263, base: "/",
    url: url_PostDescribeEventSubscriptions_607264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_607244 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEventSubscriptions_607246(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventSubscriptions_607245(path: JsonNode; query: JsonNode;
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
  var valid_607247 = query.getOrDefault("Marker")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "Marker", valid_607247
  var valid_607248 = query.getOrDefault("SubscriptionName")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "SubscriptionName", valid_607248
  var valid_607249 = query.getOrDefault("Action")
  valid_607249 = validateParameter(valid_607249, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_607249 != nil:
    section.add "Action", valid_607249
  var valid_607250 = query.getOrDefault("Version")
  valid_607250 = validateParameter(valid_607250, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607250 != nil:
    section.add "Version", valid_607250
  var valid_607251 = query.getOrDefault("MaxRecords")
  valid_607251 = validateParameter(valid_607251, JInt, required = false, default = nil)
  if valid_607251 != nil:
    section.add "MaxRecords", valid_607251
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607252 = header.getOrDefault("X-Amz-Signature")
  valid_607252 = validateParameter(valid_607252, JString, required = false,
                                 default = nil)
  if valid_607252 != nil:
    section.add "X-Amz-Signature", valid_607252
  var valid_607253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607253 = validateParameter(valid_607253, JString, required = false,
                                 default = nil)
  if valid_607253 != nil:
    section.add "X-Amz-Content-Sha256", valid_607253
  var valid_607254 = header.getOrDefault("X-Amz-Date")
  valid_607254 = validateParameter(valid_607254, JString, required = false,
                                 default = nil)
  if valid_607254 != nil:
    section.add "X-Amz-Date", valid_607254
  var valid_607255 = header.getOrDefault("X-Amz-Credential")
  valid_607255 = validateParameter(valid_607255, JString, required = false,
                                 default = nil)
  if valid_607255 != nil:
    section.add "X-Amz-Credential", valid_607255
  var valid_607256 = header.getOrDefault("X-Amz-Security-Token")
  valid_607256 = validateParameter(valid_607256, JString, required = false,
                                 default = nil)
  if valid_607256 != nil:
    section.add "X-Amz-Security-Token", valid_607256
  var valid_607257 = header.getOrDefault("X-Amz-Algorithm")
  valid_607257 = validateParameter(valid_607257, JString, required = false,
                                 default = nil)
  if valid_607257 != nil:
    section.add "X-Amz-Algorithm", valid_607257
  var valid_607258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607258 = validateParameter(valid_607258, JString, required = false,
                                 default = nil)
  if valid_607258 != nil:
    section.add "X-Amz-SignedHeaders", valid_607258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607259: Call_GetDescribeEventSubscriptions_607244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607259.validator(path, query, header, formData, body)
  let scheme = call_607259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607259.url(scheme.get, call_607259.host, call_607259.base,
                         call_607259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607259, url, valid)

proc call*(call_607260: Call_GetDescribeEventSubscriptions_607244;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_607261 = newJObject()
  add(query_607261, "Marker", newJString(Marker))
  add(query_607261, "SubscriptionName", newJString(SubscriptionName))
  add(query_607261, "Action", newJString(Action))
  add(query_607261, "Version", newJString(Version))
  add(query_607261, "MaxRecords", newJInt(MaxRecords))
  result = call_607260.call(nil, query_607261, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_607244(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_607245, base: "/",
    url: url_GetDescribeEventSubscriptions_607246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_607304 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEvents_607306(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_607305(path: JsonNode; query: JsonNode;
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
  var valid_607307 = query.getOrDefault("Action")
  valid_607307 = validateParameter(valid_607307, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_607307 != nil:
    section.add "Action", valid_607307
  var valid_607308 = query.getOrDefault("Version")
  valid_607308 = validateParameter(valid_607308, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607308 != nil:
    section.add "Version", valid_607308
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607309 = header.getOrDefault("X-Amz-Signature")
  valid_607309 = validateParameter(valid_607309, JString, required = false,
                                 default = nil)
  if valid_607309 != nil:
    section.add "X-Amz-Signature", valid_607309
  var valid_607310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607310 = validateParameter(valid_607310, JString, required = false,
                                 default = nil)
  if valid_607310 != nil:
    section.add "X-Amz-Content-Sha256", valid_607310
  var valid_607311 = header.getOrDefault("X-Amz-Date")
  valid_607311 = validateParameter(valid_607311, JString, required = false,
                                 default = nil)
  if valid_607311 != nil:
    section.add "X-Amz-Date", valid_607311
  var valid_607312 = header.getOrDefault("X-Amz-Credential")
  valid_607312 = validateParameter(valid_607312, JString, required = false,
                                 default = nil)
  if valid_607312 != nil:
    section.add "X-Amz-Credential", valid_607312
  var valid_607313 = header.getOrDefault("X-Amz-Security-Token")
  valid_607313 = validateParameter(valid_607313, JString, required = false,
                                 default = nil)
  if valid_607313 != nil:
    section.add "X-Amz-Security-Token", valid_607313
  var valid_607314 = header.getOrDefault("X-Amz-Algorithm")
  valid_607314 = validateParameter(valid_607314, JString, required = false,
                                 default = nil)
  if valid_607314 != nil:
    section.add "X-Amz-Algorithm", valid_607314
  var valid_607315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607315 = validateParameter(valid_607315, JString, required = false,
                                 default = nil)
  if valid_607315 != nil:
    section.add "X-Amz-SignedHeaders", valid_607315
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
  var valid_607316 = formData.getOrDefault("MaxRecords")
  valid_607316 = validateParameter(valid_607316, JInt, required = false, default = nil)
  if valid_607316 != nil:
    section.add "MaxRecords", valid_607316
  var valid_607317 = formData.getOrDefault("Marker")
  valid_607317 = validateParameter(valid_607317, JString, required = false,
                                 default = nil)
  if valid_607317 != nil:
    section.add "Marker", valid_607317
  var valid_607318 = formData.getOrDefault("SourceIdentifier")
  valid_607318 = validateParameter(valid_607318, JString, required = false,
                                 default = nil)
  if valid_607318 != nil:
    section.add "SourceIdentifier", valid_607318
  var valid_607319 = formData.getOrDefault("SourceType")
  valid_607319 = validateParameter(valid_607319, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_607319 != nil:
    section.add "SourceType", valid_607319
  var valid_607320 = formData.getOrDefault("Duration")
  valid_607320 = validateParameter(valid_607320, JInt, required = false, default = nil)
  if valid_607320 != nil:
    section.add "Duration", valid_607320
  var valid_607321 = formData.getOrDefault("EndTime")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "EndTime", valid_607321
  var valid_607322 = formData.getOrDefault("StartTime")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "StartTime", valid_607322
  var valid_607323 = formData.getOrDefault("EventCategories")
  valid_607323 = validateParameter(valid_607323, JArray, required = false,
                                 default = nil)
  if valid_607323 != nil:
    section.add "EventCategories", valid_607323
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607324: Call_PostDescribeEvents_607304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607324.validator(path, query, header, formData, body)
  let scheme = call_607324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607324.url(scheme.get, call_607324.host, call_607324.base,
                         call_607324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607324, url, valid)

proc call*(call_607325: Call_PostDescribeEvents_607304; MaxRecords: int = 0;
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
  var query_607326 = newJObject()
  var formData_607327 = newJObject()
  add(formData_607327, "MaxRecords", newJInt(MaxRecords))
  add(formData_607327, "Marker", newJString(Marker))
  add(formData_607327, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_607327, "SourceType", newJString(SourceType))
  add(formData_607327, "Duration", newJInt(Duration))
  add(formData_607327, "EndTime", newJString(EndTime))
  add(formData_607327, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_607327.add "EventCategories", EventCategories
  add(query_607326, "Action", newJString(Action))
  add(query_607326, "Version", newJString(Version))
  result = call_607325.call(nil, query_607326, nil, formData_607327, nil)

var postDescribeEvents* = Call_PostDescribeEvents_607304(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_607305, base: "/",
    url: url_PostDescribeEvents_607306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_607281 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEvents_607283(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_607282(path: JsonNode; query: JsonNode;
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
  var valid_607284 = query.getOrDefault("Marker")
  valid_607284 = validateParameter(valid_607284, JString, required = false,
                                 default = nil)
  if valid_607284 != nil:
    section.add "Marker", valid_607284
  var valid_607285 = query.getOrDefault("SourceType")
  valid_607285 = validateParameter(valid_607285, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_607285 != nil:
    section.add "SourceType", valid_607285
  var valid_607286 = query.getOrDefault("SourceIdentifier")
  valid_607286 = validateParameter(valid_607286, JString, required = false,
                                 default = nil)
  if valid_607286 != nil:
    section.add "SourceIdentifier", valid_607286
  var valid_607287 = query.getOrDefault("EventCategories")
  valid_607287 = validateParameter(valid_607287, JArray, required = false,
                                 default = nil)
  if valid_607287 != nil:
    section.add "EventCategories", valid_607287
  var valid_607288 = query.getOrDefault("Action")
  valid_607288 = validateParameter(valid_607288, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_607288 != nil:
    section.add "Action", valid_607288
  var valid_607289 = query.getOrDefault("StartTime")
  valid_607289 = validateParameter(valid_607289, JString, required = false,
                                 default = nil)
  if valid_607289 != nil:
    section.add "StartTime", valid_607289
  var valid_607290 = query.getOrDefault("Duration")
  valid_607290 = validateParameter(valid_607290, JInt, required = false, default = nil)
  if valid_607290 != nil:
    section.add "Duration", valid_607290
  var valid_607291 = query.getOrDefault("EndTime")
  valid_607291 = validateParameter(valid_607291, JString, required = false,
                                 default = nil)
  if valid_607291 != nil:
    section.add "EndTime", valid_607291
  var valid_607292 = query.getOrDefault("Version")
  valid_607292 = validateParameter(valid_607292, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607292 != nil:
    section.add "Version", valid_607292
  var valid_607293 = query.getOrDefault("MaxRecords")
  valid_607293 = validateParameter(valid_607293, JInt, required = false, default = nil)
  if valid_607293 != nil:
    section.add "MaxRecords", valid_607293
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607294 = header.getOrDefault("X-Amz-Signature")
  valid_607294 = validateParameter(valid_607294, JString, required = false,
                                 default = nil)
  if valid_607294 != nil:
    section.add "X-Amz-Signature", valid_607294
  var valid_607295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "X-Amz-Content-Sha256", valid_607295
  var valid_607296 = header.getOrDefault("X-Amz-Date")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "X-Amz-Date", valid_607296
  var valid_607297 = header.getOrDefault("X-Amz-Credential")
  valid_607297 = validateParameter(valid_607297, JString, required = false,
                                 default = nil)
  if valid_607297 != nil:
    section.add "X-Amz-Credential", valid_607297
  var valid_607298 = header.getOrDefault("X-Amz-Security-Token")
  valid_607298 = validateParameter(valid_607298, JString, required = false,
                                 default = nil)
  if valid_607298 != nil:
    section.add "X-Amz-Security-Token", valid_607298
  var valid_607299 = header.getOrDefault("X-Amz-Algorithm")
  valid_607299 = validateParameter(valid_607299, JString, required = false,
                                 default = nil)
  if valid_607299 != nil:
    section.add "X-Amz-Algorithm", valid_607299
  var valid_607300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607300 = validateParameter(valid_607300, JString, required = false,
                                 default = nil)
  if valid_607300 != nil:
    section.add "X-Amz-SignedHeaders", valid_607300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607301: Call_GetDescribeEvents_607281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607301.validator(path, query, header, formData, body)
  let scheme = call_607301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607301.url(scheme.get, call_607301.host, call_607301.base,
                         call_607301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607301, url, valid)

proc call*(call_607302: Call_GetDescribeEvents_607281; Marker: string = "";
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
  var query_607303 = newJObject()
  add(query_607303, "Marker", newJString(Marker))
  add(query_607303, "SourceType", newJString(SourceType))
  add(query_607303, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_607303.add "EventCategories", EventCategories
  add(query_607303, "Action", newJString(Action))
  add(query_607303, "StartTime", newJString(StartTime))
  add(query_607303, "Duration", newJInt(Duration))
  add(query_607303, "EndTime", newJString(EndTime))
  add(query_607303, "Version", newJString(Version))
  add(query_607303, "MaxRecords", newJInt(MaxRecords))
  result = call_607302.call(nil, query_607303, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_607281(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_607282,
    base: "/", url: url_GetDescribeEvents_607283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_607347 = ref object of OpenApiRestCall_605573
proc url_PostDescribeOptionGroupOptions_607349(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroupOptions_607348(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607350 = query.getOrDefault("Action")
  valid_607350 = validateParameter(valid_607350, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_607350 != nil:
    section.add "Action", valid_607350
  var valid_607351 = query.getOrDefault("Version")
  valid_607351 = validateParameter(valid_607351, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
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
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_607361 = formData.getOrDefault("EngineName")
  valid_607361 = validateParameter(valid_607361, JString, required = true,
                                 default = nil)
  if valid_607361 != nil:
    section.add "EngineName", valid_607361
  var valid_607362 = formData.getOrDefault("MajorEngineVersion")
  valid_607362 = validateParameter(valid_607362, JString, required = false,
                                 default = nil)
  if valid_607362 != nil:
    section.add "MajorEngineVersion", valid_607362
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607363: Call_PostDescribeOptionGroupOptions_607347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607363.validator(path, query, header, formData, body)
  let scheme = call_607363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607363.url(scheme.get, call_607363.host, call_607363.base,
                         call_607363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607363, url, valid)

proc call*(call_607364: Call_PostDescribeOptionGroupOptions_607347;
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
  var query_607365 = newJObject()
  var formData_607366 = newJObject()
  add(formData_607366, "MaxRecords", newJInt(MaxRecords))
  add(formData_607366, "Marker", newJString(Marker))
  add(formData_607366, "EngineName", newJString(EngineName))
  add(formData_607366, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_607365, "Action", newJString(Action))
  add(query_607365, "Version", newJString(Version))
  result = call_607364.call(nil, query_607365, nil, formData_607366, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_607347(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_607348, base: "/",
    url: url_PostDescribeOptionGroupOptions_607349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_607328 = ref object of OpenApiRestCall_605573
proc url_GetDescribeOptionGroupOptions_607330(protocol: Scheme; host: string;
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

proc validate_GetDescribeOptionGroupOptions_607329(path: JsonNode; query: JsonNode;
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
  var valid_607331 = query.getOrDefault("EngineName")
  valid_607331 = validateParameter(valid_607331, JString, required = true,
                                 default = nil)
  if valid_607331 != nil:
    section.add "EngineName", valid_607331
  var valid_607332 = query.getOrDefault("Marker")
  valid_607332 = validateParameter(valid_607332, JString, required = false,
                                 default = nil)
  if valid_607332 != nil:
    section.add "Marker", valid_607332
  var valid_607333 = query.getOrDefault("Action")
  valid_607333 = validateParameter(valid_607333, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_607333 != nil:
    section.add "Action", valid_607333
  var valid_607334 = query.getOrDefault("Version")
  valid_607334 = validateParameter(valid_607334, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607334 != nil:
    section.add "Version", valid_607334
  var valid_607335 = query.getOrDefault("MaxRecords")
  valid_607335 = validateParameter(valid_607335, JInt, required = false, default = nil)
  if valid_607335 != nil:
    section.add "MaxRecords", valid_607335
  var valid_607336 = query.getOrDefault("MajorEngineVersion")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "MajorEngineVersion", valid_607336
  result.add "query", section
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

proc call*(call_607344: Call_GetDescribeOptionGroupOptions_607328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607344.validator(path, query, header, formData, body)
  let scheme = call_607344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607344.url(scheme.get, call_607344.host, call_607344.base,
                         call_607344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607344, url, valid)

proc call*(call_607345: Call_GetDescribeOptionGroupOptions_607328;
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
  var query_607346 = newJObject()
  add(query_607346, "EngineName", newJString(EngineName))
  add(query_607346, "Marker", newJString(Marker))
  add(query_607346, "Action", newJString(Action))
  add(query_607346, "Version", newJString(Version))
  add(query_607346, "MaxRecords", newJInt(MaxRecords))
  add(query_607346, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_607345.call(nil, query_607346, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_607328(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_607329, base: "/",
    url: url_GetDescribeOptionGroupOptions_607330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_607387 = ref object of OpenApiRestCall_605573
proc url_PostDescribeOptionGroups_607389(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroups_607388(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607390 = query.getOrDefault("Action")
  valid_607390 = validateParameter(valid_607390, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_607390 != nil:
    section.add "Action", valid_607390
  var valid_607391 = query.getOrDefault("Version")
  valid_607391 = validateParameter(valid_607391, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607391 != nil:
    section.add "Version", valid_607391
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607392 = header.getOrDefault("X-Amz-Signature")
  valid_607392 = validateParameter(valid_607392, JString, required = false,
                                 default = nil)
  if valid_607392 != nil:
    section.add "X-Amz-Signature", valid_607392
  var valid_607393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607393 = validateParameter(valid_607393, JString, required = false,
                                 default = nil)
  if valid_607393 != nil:
    section.add "X-Amz-Content-Sha256", valid_607393
  var valid_607394 = header.getOrDefault("X-Amz-Date")
  valid_607394 = validateParameter(valid_607394, JString, required = false,
                                 default = nil)
  if valid_607394 != nil:
    section.add "X-Amz-Date", valid_607394
  var valid_607395 = header.getOrDefault("X-Amz-Credential")
  valid_607395 = validateParameter(valid_607395, JString, required = false,
                                 default = nil)
  if valid_607395 != nil:
    section.add "X-Amz-Credential", valid_607395
  var valid_607396 = header.getOrDefault("X-Amz-Security-Token")
  valid_607396 = validateParameter(valid_607396, JString, required = false,
                                 default = nil)
  if valid_607396 != nil:
    section.add "X-Amz-Security-Token", valid_607396
  var valid_607397 = header.getOrDefault("X-Amz-Algorithm")
  valid_607397 = validateParameter(valid_607397, JString, required = false,
                                 default = nil)
  if valid_607397 != nil:
    section.add "X-Amz-Algorithm", valid_607397
  var valid_607398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "X-Amz-SignedHeaders", valid_607398
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_607399 = formData.getOrDefault("MaxRecords")
  valid_607399 = validateParameter(valid_607399, JInt, required = false, default = nil)
  if valid_607399 != nil:
    section.add "MaxRecords", valid_607399
  var valid_607400 = formData.getOrDefault("Marker")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "Marker", valid_607400
  var valid_607401 = formData.getOrDefault("EngineName")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "EngineName", valid_607401
  var valid_607402 = formData.getOrDefault("MajorEngineVersion")
  valid_607402 = validateParameter(valid_607402, JString, required = false,
                                 default = nil)
  if valid_607402 != nil:
    section.add "MajorEngineVersion", valid_607402
  var valid_607403 = formData.getOrDefault("OptionGroupName")
  valid_607403 = validateParameter(valid_607403, JString, required = false,
                                 default = nil)
  if valid_607403 != nil:
    section.add "OptionGroupName", valid_607403
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607404: Call_PostDescribeOptionGroups_607387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607404.validator(path, query, header, formData, body)
  let scheme = call_607404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607404.url(scheme.get, call_607404.host, call_607404.base,
                         call_607404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607404, url, valid)

proc call*(call_607405: Call_PostDescribeOptionGroups_607387; MaxRecords: int = 0;
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
  var query_607406 = newJObject()
  var formData_607407 = newJObject()
  add(formData_607407, "MaxRecords", newJInt(MaxRecords))
  add(formData_607407, "Marker", newJString(Marker))
  add(formData_607407, "EngineName", newJString(EngineName))
  add(formData_607407, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_607406, "Action", newJString(Action))
  add(formData_607407, "OptionGroupName", newJString(OptionGroupName))
  add(query_607406, "Version", newJString(Version))
  result = call_607405.call(nil, query_607406, nil, formData_607407, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_607387(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_607388, base: "/",
    url: url_PostDescribeOptionGroups_607389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_607367 = ref object of OpenApiRestCall_605573
proc url_GetDescribeOptionGroups_607369(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeOptionGroups_607368(path: JsonNode; query: JsonNode;
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
  var valid_607370 = query.getOrDefault("EngineName")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "EngineName", valid_607370
  var valid_607371 = query.getOrDefault("Marker")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "Marker", valid_607371
  var valid_607372 = query.getOrDefault("Action")
  valid_607372 = validateParameter(valid_607372, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_607372 != nil:
    section.add "Action", valid_607372
  var valid_607373 = query.getOrDefault("OptionGroupName")
  valid_607373 = validateParameter(valid_607373, JString, required = false,
                                 default = nil)
  if valid_607373 != nil:
    section.add "OptionGroupName", valid_607373
  var valid_607374 = query.getOrDefault("Version")
  valid_607374 = validateParameter(valid_607374, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607374 != nil:
    section.add "Version", valid_607374
  var valid_607375 = query.getOrDefault("MaxRecords")
  valid_607375 = validateParameter(valid_607375, JInt, required = false, default = nil)
  if valid_607375 != nil:
    section.add "MaxRecords", valid_607375
  var valid_607376 = query.getOrDefault("MajorEngineVersion")
  valid_607376 = validateParameter(valid_607376, JString, required = false,
                                 default = nil)
  if valid_607376 != nil:
    section.add "MajorEngineVersion", valid_607376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607377 = header.getOrDefault("X-Amz-Signature")
  valid_607377 = validateParameter(valid_607377, JString, required = false,
                                 default = nil)
  if valid_607377 != nil:
    section.add "X-Amz-Signature", valid_607377
  var valid_607378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607378 = validateParameter(valid_607378, JString, required = false,
                                 default = nil)
  if valid_607378 != nil:
    section.add "X-Amz-Content-Sha256", valid_607378
  var valid_607379 = header.getOrDefault("X-Amz-Date")
  valid_607379 = validateParameter(valid_607379, JString, required = false,
                                 default = nil)
  if valid_607379 != nil:
    section.add "X-Amz-Date", valid_607379
  var valid_607380 = header.getOrDefault("X-Amz-Credential")
  valid_607380 = validateParameter(valid_607380, JString, required = false,
                                 default = nil)
  if valid_607380 != nil:
    section.add "X-Amz-Credential", valid_607380
  var valid_607381 = header.getOrDefault("X-Amz-Security-Token")
  valid_607381 = validateParameter(valid_607381, JString, required = false,
                                 default = nil)
  if valid_607381 != nil:
    section.add "X-Amz-Security-Token", valid_607381
  var valid_607382 = header.getOrDefault("X-Amz-Algorithm")
  valid_607382 = validateParameter(valid_607382, JString, required = false,
                                 default = nil)
  if valid_607382 != nil:
    section.add "X-Amz-Algorithm", valid_607382
  var valid_607383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-SignedHeaders", valid_607383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607384: Call_GetDescribeOptionGroups_607367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607384.validator(path, query, header, formData, body)
  let scheme = call_607384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607384.url(scheme.get, call_607384.host, call_607384.base,
                         call_607384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607384, url, valid)

proc call*(call_607385: Call_GetDescribeOptionGroups_607367;
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
  var query_607386 = newJObject()
  add(query_607386, "EngineName", newJString(EngineName))
  add(query_607386, "Marker", newJString(Marker))
  add(query_607386, "Action", newJString(Action))
  add(query_607386, "OptionGroupName", newJString(OptionGroupName))
  add(query_607386, "Version", newJString(Version))
  add(query_607386, "MaxRecords", newJInt(MaxRecords))
  add(query_607386, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_607385.call(nil, query_607386, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_607367(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_607368, base: "/",
    url: url_GetDescribeOptionGroups_607369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_607430 = ref object of OpenApiRestCall_605573
proc url_PostDescribeOrderableDBInstanceOptions_607432(protocol: Scheme;
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

proc validate_PostDescribeOrderableDBInstanceOptions_607431(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607433 = query.getOrDefault("Action")
  valid_607433 = validateParameter(valid_607433, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_607433 != nil:
    section.add "Action", valid_607433
  var valid_607434 = query.getOrDefault("Version")
  valid_607434 = validateParameter(valid_607434, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ##   DBInstanceClass: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   Marker: JString
  ##   Engine: JString (required)
  ##   Vpc: JBool
  ##   LicenseModel: JString
  section = newJObject()
  var valid_607442 = formData.getOrDefault("DBInstanceClass")
  valid_607442 = validateParameter(valid_607442, JString, required = false,
                                 default = nil)
  if valid_607442 != nil:
    section.add "DBInstanceClass", valid_607442
  var valid_607443 = formData.getOrDefault("MaxRecords")
  valid_607443 = validateParameter(valid_607443, JInt, required = false, default = nil)
  if valid_607443 != nil:
    section.add "MaxRecords", valid_607443
  var valid_607444 = formData.getOrDefault("EngineVersion")
  valid_607444 = validateParameter(valid_607444, JString, required = false,
                                 default = nil)
  if valid_607444 != nil:
    section.add "EngineVersion", valid_607444
  var valid_607445 = formData.getOrDefault("Marker")
  valid_607445 = validateParameter(valid_607445, JString, required = false,
                                 default = nil)
  if valid_607445 != nil:
    section.add "Marker", valid_607445
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_607446 = formData.getOrDefault("Engine")
  valid_607446 = validateParameter(valid_607446, JString, required = true,
                                 default = nil)
  if valid_607446 != nil:
    section.add "Engine", valid_607446
  var valid_607447 = formData.getOrDefault("Vpc")
  valid_607447 = validateParameter(valid_607447, JBool, required = false, default = nil)
  if valid_607447 != nil:
    section.add "Vpc", valid_607447
  var valid_607448 = formData.getOrDefault("LicenseModel")
  valid_607448 = validateParameter(valid_607448, JString, required = false,
                                 default = nil)
  if valid_607448 != nil:
    section.add "LicenseModel", valid_607448
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607449: Call_PostDescribeOrderableDBInstanceOptions_607430;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607449.validator(path, query, header, formData, body)
  let scheme = call_607449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607449.url(scheme.get, call_607449.host, call_607449.base,
                         call_607449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607449, url, valid)

proc call*(call_607450: Call_PostDescribeOrderableDBInstanceOptions_607430;
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
  var query_607451 = newJObject()
  var formData_607452 = newJObject()
  add(formData_607452, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607452, "MaxRecords", newJInt(MaxRecords))
  add(formData_607452, "EngineVersion", newJString(EngineVersion))
  add(formData_607452, "Marker", newJString(Marker))
  add(formData_607452, "Engine", newJString(Engine))
  add(formData_607452, "Vpc", newJBool(Vpc))
  add(query_607451, "Action", newJString(Action))
  add(formData_607452, "LicenseModel", newJString(LicenseModel))
  add(query_607451, "Version", newJString(Version))
  result = call_607450.call(nil, query_607451, nil, formData_607452, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_607430(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_607431, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_607432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_607408 = ref object of OpenApiRestCall_605573
proc url_GetDescribeOrderableDBInstanceOptions_607410(protocol: Scheme;
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

proc validate_GetDescribeOrderableDBInstanceOptions_607409(path: JsonNode;
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
  var valid_607411 = query.getOrDefault("Marker")
  valid_607411 = validateParameter(valid_607411, JString, required = false,
                                 default = nil)
  if valid_607411 != nil:
    section.add "Marker", valid_607411
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_607412 = query.getOrDefault("Engine")
  valid_607412 = validateParameter(valid_607412, JString, required = true,
                                 default = nil)
  if valid_607412 != nil:
    section.add "Engine", valid_607412
  var valid_607413 = query.getOrDefault("LicenseModel")
  valid_607413 = validateParameter(valid_607413, JString, required = false,
                                 default = nil)
  if valid_607413 != nil:
    section.add "LicenseModel", valid_607413
  var valid_607414 = query.getOrDefault("Vpc")
  valid_607414 = validateParameter(valid_607414, JBool, required = false, default = nil)
  if valid_607414 != nil:
    section.add "Vpc", valid_607414
  var valid_607415 = query.getOrDefault("EngineVersion")
  valid_607415 = validateParameter(valid_607415, JString, required = false,
                                 default = nil)
  if valid_607415 != nil:
    section.add "EngineVersion", valid_607415
  var valid_607416 = query.getOrDefault("Action")
  valid_607416 = validateParameter(valid_607416, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_607416 != nil:
    section.add "Action", valid_607416
  var valid_607417 = query.getOrDefault("Version")
  valid_607417 = validateParameter(valid_607417, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607417 != nil:
    section.add "Version", valid_607417
  var valid_607418 = query.getOrDefault("DBInstanceClass")
  valid_607418 = validateParameter(valid_607418, JString, required = false,
                                 default = nil)
  if valid_607418 != nil:
    section.add "DBInstanceClass", valid_607418
  var valid_607419 = query.getOrDefault("MaxRecords")
  valid_607419 = validateParameter(valid_607419, JInt, required = false, default = nil)
  if valid_607419 != nil:
    section.add "MaxRecords", valid_607419
  result.add "query", section
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

proc call*(call_607427: Call_GetDescribeOrderableDBInstanceOptions_607408;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607427.validator(path, query, header, formData, body)
  let scheme = call_607427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607427.url(scheme.get, call_607427.host, call_607427.base,
                         call_607427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607427, url, valid)

proc call*(call_607428: Call_GetDescribeOrderableDBInstanceOptions_607408;
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
  var query_607429 = newJObject()
  add(query_607429, "Marker", newJString(Marker))
  add(query_607429, "Engine", newJString(Engine))
  add(query_607429, "LicenseModel", newJString(LicenseModel))
  add(query_607429, "Vpc", newJBool(Vpc))
  add(query_607429, "EngineVersion", newJString(EngineVersion))
  add(query_607429, "Action", newJString(Action))
  add(query_607429, "Version", newJString(Version))
  add(query_607429, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_607429, "MaxRecords", newJInt(MaxRecords))
  result = call_607428.call(nil, query_607429, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_607408(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_607409, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_607410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_607477 = ref object of OpenApiRestCall_605573
proc url_PostDescribeReservedDBInstances_607479(protocol: Scheme; host: string;
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

proc validate_PostDescribeReservedDBInstances_607478(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607480 = query.getOrDefault("Action")
  valid_607480 = validateParameter(valid_607480, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_607480 != nil:
    section.add "Action", valid_607480
  var valid_607481 = query.getOrDefault("Version")
  valid_607481 = validateParameter(valid_607481, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607481 != nil:
    section.add "Version", valid_607481
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607482 = header.getOrDefault("X-Amz-Signature")
  valid_607482 = validateParameter(valid_607482, JString, required = false,
                                 default = nil)
  if valid_607482 != nil:
    section.add "X-Amz-Signature", valid_607482
  var valid_607483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607483 = validateParameter(valid_607483, JString, required = false,
                                 default = nil)
  if valid_607483 != nil:
    section.add "X-Amz-Content-Sha256", valid_607483
  var valid_607484 = header.getOrDefault("X-Amz-Date")
  valid_607484 = validateParameter(valid_607484, JString, required = false,
                                 default = nil)
  if valid_607484 != nil:
    section.add "X-Amz-Date", valid_607484
  var valid_607485 = header.getOrDefault("X-Amz-Credential")
  valid_607485 = validateParameter(valid_607485, JString, required = false,
                                 default = nil)
  if valid_607485 != nil:
    section.add "X-Amz-Credential", valid_607485
  var valid_607486 = header.getOrDefault("X-Amz-Security-Token")
  valid_607486 = validateParameter(valid_607486, JString, required = false,
                                 default = nil)
  if valid_607486 != nil:
    section.add "X-Amz-Security-Token", valid_607486
  var valid_607487 = header.getOrDefault("X-Amz-Algorithm")
  valid_607487 = validateParameter(valid_607487, JString, required = false,
                                 default = nil)
  if valid_607487 != nil:
    section.add "X-Amz-Algorithm", valid_607487
  var valid_607488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607488 = validateParameter(valid_607488, JString, required = false,
                                 default = nil)
  if valid_607488 != nil:
    section.add "X-Amz-SignedHeaders", valid_607488
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
  var valid_607489 = formData.getOrDefault("DBInstanceClass")
  valid_607489 = validateParameter(valid_607489, JString, required = false,
                                 default = nil)
  if valid_607489 != nil:
    section.add "DBInstanceClass", valid_607489
  var valid_607490 = formData.getOrDefault("MultiAZ")
  valid_607490 = validateParameter(valid_607490, JBool, required = false, default = nil)
  if valid_607490 != nil:
    section.add "MultiAZ", valid_607490
  var valid_607491 = formData.getOrDefault("MaxRecords")
  valid_607491 = validateParameter(valid_607491, JInt, required = false, default = nil)
  if valid_607491 != nil:
    section.add "MaxRecords", valid_607491
  var valid_607492 = formData.getOrDefault("ReservedDBInstanceId")
  valid_607492 = validateParameter(valid_607492, JString, required = false,
                                 default = nil)
  if valid_607492 != nil:
    section.add "ReservedDBInstanceId", valid_607492
  var valid_607493 = formData.getOrDefault("Marker")
  valid_607493 = validateParameter(valid_607493, JString, required = false,
                                 default = nil)
  if valid_607493 != nil:
    section.add "Marker", valid_607493
  var valid_607494 = formData.getOrDefault("Duration")
  valid_607494 = validateParameter(valid_607494, JString, required = false,
                                 default = nil)
  if valid_607494 != nil:
    section.add "Duration", valid_607494
  var valid_607495 = formData.getOrDefault("OfferingType")
  valid_607495 = validateParameter(valid_607495, JString, required = false,
                                 default = nil)
  if valid_607495 != nil:
    section.add "OfferingType", valid_607495
  var valid_607496 = formData.getOrDefault("ProductDescription")
  valid_607496 = validateParameter(valid_607496, JString, required = false,
                                 default = nil)
  if valid_607496 != nil:
    section.add "ProductDescription", valid_607496
  var valid_607497 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607497 = validateParameter(valid_607497, JString, required = false,
                                 default = nil)
  if valid_607497 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607497
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607498: Call_PostDescribeReservedDBInstances_607477;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607498.validator(path, query, header, formData, body)
  let scheme = call_607498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607498.url(scheme.get, call_607498.host, call_607498.base,
                         call_607498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607498, url, valid)

proc call*(call_607499: Call_PostDescribeReservedDBInstances_607477;
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
  var query_607500 = newJObject()
  var formData_607501 = newJObject()
  add(formData_607501, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607501, "MultiAZ", newJBool(MultiAZ))
  add(formData_607501, "MaxRecords", newJInt(MaxRecords))
  add(formData_607501, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_607501, "Marker", newJString(Marker))
  add(formData_607501, "Duration", newJString(Duration))
  add(formData_607501, "OfferingType", newJString(OfferingType))
  add(formData_607501, "ProductDescription", newJString(ProductDescription))
  add(query_607500, "Action", newJString(Action))
  add(formData_607501, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607500, "Version", newJString(Version))
  result = call_607499.call(nil, query_607500, nil, formData_607501, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_607477(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_607478, base: "/",
    url: url_PostDescribeReservedDBInstances_607479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_607453 = ref object of OpenApiRestCall_605573
proc url_GetDescribeReservedDBInstances_607455(protocol: Scheme; host: string;
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

proc validate_GetDescribeReservedDBInstances_607454(path: JsonNode;
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
  var valid_607456 = query.getOrDefault("Marker")
  valid_607456 = validateParameter(valid_607456, JString, required = false,
                                 default = nil)
  if valid_607456 != nil:
    section.add "Marker", valid_607456
  var valid_607457 = query.getOrDefault("ProductDescription")
  valid_607457 = validateParameter(valid_607457, JString, required = false,
                                 default = nil)
  if valid_607457 != nil:
    section.add "ProductDescription", valid_607457
  var valid_607458 = query.getOrDefault("OfferingType")
  valid_607458 = validateParameter(valid_607458, JString, required = false,
                                 default = nil)
  if valid_607458 != nil:
    section.add "OfferingType", valid_607458
  var valid_607459 = query.getOrDefault("ReservedDBInstanceId")
  valid_607459 = validateParameter(valid_607459, JString, required = false,
                                 default = nil)
  if valid_607459 != nil:
    section.add "ReservedDBInstanceId", valid_607459
  var valid_607460 = query.getOrDefault("Action")
  valid_607460 = validateParameter(valid_607460, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_607460 != nil:
    section.add "Action", valid_607460
  var valid_607461 = query.getOrDefault("MultiAZ")
  valid_607461 = validateParameter(valid_607461, JBool, required = false, default = nil)
  if valid_607461 != nil:
    section.add "MultiAZ", valid_607461
  var valid_607462 = query.getOrDefault("Duration")
  valid_607462 = validateParameter(valid_607462, JString, required = false,
                                 default = nil)
  if valid_607462 != nil:
    section.add "Duration", valid_607462
  var valid_607463 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607463 = validateParameter(valid_607463, JString, required = false,
                                 default = nil)
  if valid_607463 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607463
  var valid_607464 = query.getOrDefault("Version")
  valid_607464 = validateParameter(valid_607464, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607464 != nil:
    section.add "Version", valid_607464
  var valid_607465 = query.getOrDefault("DBInstanceClass")
  valid_607465 = validateParameter(valid_607465, JString, required = false,
                                 default = nil)
  if valid_607465 != nil:
    section.add "DBInstanceClass", valid_607465
  var valid_607466 = query.getOrDefault("MaxRecords")
  valid_607466 = validateParameter(valid_607466, JInt, required = false, default = nil)
  if valid_607466 != nil:
    section.add "MaxRecords", valid_607466
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607467 = header.getOrDefault("X-Amz-Signature")
  valid_607467 = validateParameter(valid_607467, JString, required = false,
                                 default = nil)
  if valid_607467 != nil:
    section.add "X-Amz-Signature", valid_607467
  var valid_607468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607468 = validateParameter(valid_607468, JString, required = false,
                                 default = nil)
  if valid_607468 != nil:
    section.add "X-Amz-Content-Sha256", valid_607468
  var valid_607469 = header.getOrDefault("X-Amz-Date")
  valid_607469 = validateParameter(valid_607469, JString, required = false,
                                 default = nil)
  if valid_607469 != nil:
    section.add "X-Amz-Date", valid_607469
  var valid_607470 = header.getOrDefault("X-Amz-Credential")
  valid_607470 = validateParameter(valid_607470, JString, required = false,
                                 default = nil)
  if valid_607470 != nil:
    section.add "X-Amz-Credential", valid_607470
  var valid_607471 = header.getOrDefault("X-Amz-Security-Token")
  valid_607471 = validateParameter(valid_607471, JString, required = false,
                                 default = nil)
  if valid_607471 != nil:
    section.add "X-Amz-Security-Token", valid_607471
  var valid_607472 = header.getOrDefault("X-Amz-Algorithm")
  valid_607472 = validateParameter(valid_607472, JString, required = false,
                                 default = nil)
  if valid_607472 != nil:
    section.add "X-Amz-Algorithm", valid_607472
  var valid_607473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607473 = validateParameter(valid_607473, JString, required = false,
                                 default = nil)
  if valid_607473 != nil:
    section.add "X-Amz-SignedHeaders", valid_607473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607474: Call_GetDescribeReservedDBInstances_607453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607474.validator(path, query, header, formData, body)
  let scheme = call_607474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607474.url(scheme.get, call_607474.host, call_607474.base,
                         call_607474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607474, url, valid)

proc call*(call_607475: Call_GetDescribeReservedDBInstances_607453;
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
  var query_607476 = newJObject()
  add(query_607476, "Marker", newJString(Marker))
  add(query_607476, "ProductDescription", newJString(ProductDescription))
  add(query_607476, "OfferingType", newJString(OfferingType))
  add(query_607476, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_607476, "Action", newJString(Action))
  add(query_607476, "MultiAZ", newJBool(MultiAZ))
  add(query_607476, "Duration", newJString(Duration))
  add(query_607476, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607476, "Version", newJString(Version))
  add(query_607476, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_607476, "MaxRecords", newJInt(MaxRecords))
  result = call_607475.call(nil, query_607476, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_607453(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_607454, base: "/",
    url: url_GetDescribeReservedDBInstances_607455,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_607525 = ref object of OpenApiRestCall_605573
proc url_PostDescribeReservedDBInstancesOfferings_607527(protocol: Scheme;
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

proc validate_PostDescribeReservedDBInstancesOfferings_607526(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607528 = query.getOrDefault("Action")
  valid_607528 = validateParameter(valid_607528, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_607528 != nil:
    section.add "Action", valid_607528
  var valid_607529 = query.getOrDefault("Version")
  valid_607529 = validateParameter(valid_607529, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607529 != nil:
    section.add "Version", valid_607529
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607530 = header.getOrDefault("X-Amz-Signature")
  valid_607530 = validateParameter(valid_607530, JString, required = false,
                                 default = nil)
  if valid_607530 != nil:
    section.add "X-Amz-Signature", valid_607530
  var valid_607531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607531 = validateParameter(valid_607531, JString, required = false,
                                 default = nil)
  if valid_607531 != nil:
    section.add "X-Amz-Content-Sha256", valid_607531
  var valid_607532 = header.getOrDefault("X-Amz-Date")
  valid_607532 = validateParameter(valid_607532, JString, required = false,
                                 default = nil)
  if valid_607532 != nil:
    section.add "X-Amz-Date", valid_607532
  var valid_607533 = header.getOrDefault("X-Amz-Credential")
  valid_607533 = validateParameter(valid_607533, JString, required = false,
                                 default = nil)
  if valid_607533 != nil:
    section.add "X-Amz-Credential", valid_607533
  var valid_607534 = header.getOrDefault("X-Amz-Security-Token")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "X-Amz-Security-Token", valid_607534
  var valid_607535 = header.getOrDefault("X-Amz-Algorithm")
  valid_607535 = validateParameter(valid_607535, JString, required = false,
                                 default = nil)
  if valid_607535 != nil:
    section.add "X-Amz-Algorithm", valid_607535
  var valid_607536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607536 = validateParameter(valid_607536, JString, required = false,
                                 default = nil)
  if valid_607536 != nil:
    section.add "X-Amz-SignedHeaders", valid_607536
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
  var valid_607537 = formData.getOrDefault("DBInstanceClass")
  valid_607537 = validateParameter(valid_607537, JString, required = false,
                                 default = nil)
  if valid_607537 != nil:
    section.add "DBInstanceClass", valid_607537
  var valid_607538 = formData.getOrDefault("MultiAZ")
  valid_607538 = validateParameter(valid_607538, JBool, required = false, default = nil)
  if valid_607538 != nil:
    section.add "MultiAZ", valid_607538
  var valid_607539 = formData.getOrDefault("MaxRecords")
  valid_607539 = validateParameter(valid_607539, JInt, required = false, default = nil)
  if valid_607539 != nil:
    section.add "MaxRecords", valid_607539
  var valid_607540 = formData.getOrDefault("Marker")
  valid_607540 = validateParameter(valid_607540, JString, required = false,
                                 default = nil)
  if valid_607540 != nil:
    section.add "Marker", valid_607540
  var valid_607541 = formData.getOrDefault("Duration")
  valid_607541 = validateParameter(valid_607541, JString, required = false,
                                 default = nil)
  if valid_607541 != nil:
    section.add "Duration", valid_607541
  var valid_607542 = formData.getOrDefault("OfferingType")
  valid_607542 = validateParameter(valid_607542, JString, required = false,
                                 default = nil)
  if valid_607542 != nil:
    section.add "OfferingType", valid_607542
  var valid_607543 = formData.getOrDefault("ProductDescription")
  valid_607543 = validateParameter(valid_607543, JString, required = false,
                                 default = nil)
  if valid_607543 != nil:
    section.add "ProductDescription", valid_607543
  var valid_607544 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607544 = validateParameter(valid_607544, JString, required = false,
                                 default = nil)
  if valid_607544 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607544
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607545: Call_PostDescribeReservedDBInstancesOfferings_607525;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607545.validator(path, query, header, formData, body)
  let scheme = call_607545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607545.url(scheme.get, call_607545.host, call_607545.base,
                         call_607545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607545, url, valid)

proc call*(call_607546: Call_PostDescribeReservedDBInstancesOfferings_607525;
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
  var query_607547 = newJObject()
  var formData_607548 = newJObject()
  add(formData_607548, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607548, "MultiAZ", newJBool(MultiAZ))
  add(formData_607548, "MaxRecords", newJInt(MaxRecords))
  add(formData_607548, "Marker", newJString(Marker))
  add(formData_607548, "Duration", newJString(Duration))
  add(formData_607548, "OfferingType", newJString(OfferingType))
  add(formData_607548, "ProductDescription", newJString(ProductDescription))
  add(query_607547, "Action", newJString(Action))
  add(formData_607548, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607547, "Version", newJString(Version))
  result = call_607546.call(nil, query_607547, nil, formData_607548, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_607525(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_607526,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_607527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_607502 = ref object of OpenApiRestCall_605573
proc url_GetDescribeReservedDBInstancesOfferings_607504(protocol: Scheme;
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

proc validate_GetDescribeReservedDBInstancesOfferings_607503(path: JsonNode;
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
  var valid_607505 = query.getOrDefault("Marker")
  valid_607505 = validateParameter(valid_607505, JString, required = false,
                                 default = nil)
  if valid_607505 != nil:
    section.add "Marker", valid_607505
  var valid_607506 = query.getOrDefault("ProductDescription")
  valid_607506 = validateParameter(valid_607506, JString, required = false,
                                 default = nil)
  if valid_607506 != nil:
    section.add "ProductDescription", valid_607506
  var valid_607507 = query.getOrDefault("OfferingType")
  valid_607507 = validateParameter(valid_607507, JString, required = false,
                                 default = nil)
  if valid_607507 != nil:
    section.add "OfferingType", valid_607507
  var valid_607508 = query.getOrDefault("Action")
  valid_607508 = validateParameter(valid_607508, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_607508 != nil:
    section.add "Action", valid_607508
  var valid_607509 = query.getOrDefault("MultiAZ")
  valid_607509 = validateParameter(valid_607509, JBool, required = false, default = nil)
  if valid_607509 != nil:
    section.add "MultiAZ", valid_607509
  var valid_607510 = query.getOrDefault("Duration")
  valid_607510 = validateParameter(valid_607510, JString, required = false,
                                 default = nil)
  if valid_607510 != nil:
    section.add "Duration", valid_607510
  var valid_607511 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607511 = validateParameter(valid_607511, JString, required = false,
                                 default = nil)
  if valid_607511 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607511
  var valid_607512 = query.getOrDefault("Version")
  valid_607512 = validateParameter(valid_607512, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607512 != nil:
    section.add "Version", valid_607512
  var valid_607513 = query.getOrDefault("DBInstanceClass")
  valid_607513 = validateParameter(valid_607513, JString, required = false,
                                 default = nil)
  if valid_607513 != nil:
    section.add "DBInstanceClass", valid_607513
  var valid_607514 = query.getOrDefault("MaxRecords")
  valid_607514 = validateParameter(valid_607514, JInt, required = false, default = nil)
  if valid_607514 != nil:
    section.add "MaxRecords", valid_607514
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607515 = header.getOrDefault("X-Amz-Signature")
  valid_607515 = validateParameter(valid_607515, JString, required = false,
                                 default = nil)
  if valid_607515 != nil:
    section.add "X-Amz-Signature", valid_607515
  var valid_607516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607516 = validateParameter(valid_607516, JString, required = false,
                                 default = nil)
  if valid_607516 != nil:
    section.add "X-Amz-Content-Sha256", valid_607516
  var valid_607517 = header.getOrDefault("X-Amz-Date")
  valid_607517 = validateParameter(valid_607517, JString, required = false,
                                 default = nil)
  if valid_607517 != nil:
    section.add "X-Amz-Date", valid_607517
  var valid_607518 = header.getOrDefault("X-Amz-Credential")
  valid_607518 = validateParameter(valid_607518, JString, required = false,
                                 default = nil)
  if valid_607518 != nil:
    section.add "X-Amz-Credential", valid_607518
  var valid_607519 = header.getOrDefault("X-Amz-Security-Token")
  valid_607519 = validateParameter(valid_607519, JString, required = false,
                                 default = nil)
  if valid_607519 != nil:
    section.add "X-Amz-Security-Token", valid_607519
  var valid_607520 = header.getOrDefault("X-Amz-Algorithm")
  valid_607520 = validateParameter(valid_607520, JString, required = false,
                                 default = nil)
  if valid_607520 != nil:
    section.add "X-Amz-Algorithm", valid_607520
  var valid_607521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607521 = validateParameter(valid_607521, JString, required = false,
                                 default = nil)
  if valid_607521 != nil:
    section.add "X-Amz-SignedHeaders", valid_607521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607522: Call_GetDescribeReservedDBInstancesOfferings_607502;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607522.validator(path, query, header, formData, body)
  let scheme = call_607522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607522.url(scheme.get, call_607522.host, call_607522.base,
                         call_607522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607522, url, valid)

proc call*(call_607523: Call_GetDescribeReservedDBInstancesOfferings_607502;
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
  var query_607524 = newJObject()
  add(query_607524, "Marker", newJString(Marker))
  add(query_607524, "ProductDescription", newJString(ProductDescription))
  add(query_607524, "OfferingType", newJString(OfferingType))
  add(query_607524, "Action", newJString(Action))
  add(query_607524, "MultiAZ", newJBool(MultiAZ))
  add(query_607524, "Duration", newJString(Duration))
  add(query_607524, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607524, "Version", newJString(Version))
  add(query_607524, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_607524, "MaxRecords", newJInt(MaxRecords))
  result = call_607523.call(nil, query_607524, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_607502(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_607503, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_607504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_607565 = ref object of OpenApiRestCall_605573
proc url_PostListTagsForResource_607567(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_607566(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607568 = query.getOrDefault("Action")
  valid_607568 = validateParameter(valid_607568, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_607568 != nil:
    section.add "Action", valid_607568
  var valid_607569 = query.getOrDefault("Version")
  valid_607569 = validateParameter(valid_607569, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607569 != nil:
    section.add "Version", valid_607569
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607570 = header.getOrDefault("X-Amz-Signature")
  valid_607570 = validateParameter(valid_607570, JString, required = false,
                                 default = nil)
  if valid_607570 != nil:
    section.add "X-Amz-Signature", valid_607570
  var valid_607571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607571 = validateParameter(valid_607571, JString, required = false,
                                 default = nil)
  if valid_607571 != nil:
    section.add "X-Amz-Content-Sha256", valid_607571
  var valid_607572 = header.getOrDefault("X-Amz-Date")
  valid_607572 = validateParameter(valid_607572, JString, required = false,
                                 default = nil)
  if valid_607572 != nil:
    section.add "X-Amz-Date", valid_607572
  var valid_607573 = header.getOrDefault("X-Amz-Credential")
  valid_607573 = validateParameter(valid_607573, JString, required = false,
                                 default = nil)
  if valid_607573 != nil:
    section.add "X-Amz-Credential", valid_607573
  var valid_607574 = header.getOrDefault("X-Amz-Security-Token")
  valid_607574 = validateParameter(valid_607574, JString, required = false,
                                 default = nil)
  if valid_607574 != nil:
    section.add "X-Amz-Security-Token", valid_607574
  var valid_607575 = header.getOrDefault("X-Amz-Algorithm")
  valid_607575 = validateParameter(valid_607575, JString, required = false,
                                 default = nil)
  if valid_607575 != nil:
    section.add "X-Amz-Algorithm", valid_607575
  var valid_607576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607576 = validateParameter(valid_607576, JString, required = false,
                                 default = nil)
  if valid_607576 != nil:
    section.add "X-Amz-SignedHeaders", valid_607576
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_607577 = formData.getOrDefault("ResourceName")
  valid_607577 = validateParameter(valid_607577, JString, required = true,
                                 default = nil)
  if valid_607577 != nil:
    section.add "ResourceName", valid_607577
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607578: Call_PostListTagsForResource_607565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607578.validator(path, query, header, formData, body)
  let scheme = call_607578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607578.url(scheme.get, call_607578.host, call_607578.base,
                         call_607578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607578, url, valid)

proc call*(call_607579: Call_PostListTagsForResource_607565; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_607580 = newJObject()
  var formData_607581 = newJObject()
  add(query_607580, "Action", newJString(Action))
  add(query_607580, "Version", newJString(Version))
  add(formData_607581, "ResourceName", newJString(ResourceName))
  result = call_607579.call(nil, query_607580, nil, formData_607581, nil)

var postListTagsForResource* = Call_PostListTagsForResource_607565(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_607566, base: "/",
    url: url_PostListTagsForResource_607567, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_607549 = ref object of OpenApiRestCall_605573
proc url_GetListTagsForResource_607551(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_607550(path: JsonNode; query: JsonNode;
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
  var valid_607552 = query.getOrDefault("ResourceName")
  valid_607552 = validateParameter(valid_607552, JString, required = true,
                                 default = nil)
  if valid_607552 != nil:
    section.add "ResourceName", valid_607552
  var valid_607553 = query.getOrDefault("Action")
  valid_607553 = validateParameter(valid_607553, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_607553 != nil:
    section.add "Action", valid_607553
  var valid_607554 = query.getOrDefault("Version")
  valid_607554 = validateParameter(valid_607554, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607554 != nil:
    section.add "Version", valid_607554
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607555 = header.getOrDefault("X-Amz-Signature")
  valid_607555 = validateParameter(valid_607555, JString, required = false,
                                 default = nil)
  if valid_607555 != nil:
    section.add "X-Amz-Signature", valid_607555
  var valid_607556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607556 = validateParameter(valid_607556, JString, required = false,
                                 default = nil)
  if valid_607556 != nil:
    section.add "X-Amz-Content-Sha256", valid_607556
  var valid_607557 = header.getOrDefault("X-Amz-Date")
  valid_607557 = validateParameter(valid_607557, JString, required = false,
                                 default = nil)
  if valid_607557 != nil:
    section.add "X-Amz-Date", valid_607557
  var valid_607558 = header.getOrDefault("X-Amz-Credential")
  valid_607558 = validateParameter(valid_607558, JString, required = false,
                                 default = nil)
  if valid_607558 != nil:
    section.add "X-Amz-Credential", valid_607558
  var valid_607559 = header.getOrDefault("X-Amz-Security-Token")
  valid_607559 = validateParameter(valid_607559, JString, required = false,
                                 default = nil)
  if valid_607559 != nil:
    section.add "X-Amz-Security-Token", valid_607559
  var valid_607560 = header.getOrDefault("X-Amz-Algorithm")
  valid_607560 = validateParameter(valid_607560, JString, required = false,
                                 default = nil)
  if valid_607560 != nil:
    section.add "X-Amz-Algorithm", valid_607560
  var valid_607561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607561 = validateParameter(valid_607561, JString, required = false,
                                 default = nil)
  if valid_607561 != nil:
    section.add "X-Amz-SignedHeaders", valid_607561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607562: Call_GetListTagsForResource_607549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607562.validator(path, query, header, formData, body)
  let scheme = call_607562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607562.url(scheme.get, call_607562.host, call_607562.base,
                         call_607562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607562, url, valid)

proc call*(call_607563: Call_GetListTagsForResource_607549; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607564 = newJObject()
  add(query_607564, "ResourceName", newJString(ResourceName))
  add(query_607564, "Action", newJString(Action))
  add(query_607564, "Version", newJString(Version))
  result = call_607563.call(nil, query_607564, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_607549(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_607550, base: "/",
    url: url_GetListTagsForResource_607551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_607615 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBInstance_607617(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBInstance_607616(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607618 = query.getOrDefault("Action")
  valid_607618 = validateParameter(valid_607618, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_607618 != nil:
    section.add "Action", valid_607618
  var valid_607619 = query.getOrDefault("Version")
  valid_607619 = validateParameter(valid_607619, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607619 != nil:
    section.add "Version", valid_607619
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607620 = header.getOrDefault("X-Amz-Signature")
  valid_607620 = validateParameter(valid_607620, JString, required = false,
                                 default = nil)
  if valid_607620 != nil:
    section.add "X-Amz-Signature", valid_607620
  var valid_607621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607621 = validateParameter(valid_607621, JString, required = false,
                                 default = nil)
  if valid_607621 != nil:
    section.add "X-Amz-Content-Sha256", valid_607621
  var valid_607622 = header.getOrDefault("X-Amz-Date")
  valid_607622 = validateParameter(valid_607622, JString, required = false,
                                 default = nil)
  if valid_607622 != nil:
    section.add "X-Amz-Date", valid_607622
  var valid_607623 = header.getOrDefault("X-Amz-Credential")
  valid_607623 = validateParameter(valid_607623, JString, required = false,
                                 default = nil)
  if valid_607623 != nil:
    section.add "X-Amz-Credential", valid_607623
  var valid_607624 = header.getOrDefault("X-Amz-Security-Token")
  valid_607624 = validateParameter(valid_607624, JString, required = false,
                                 default = nil)
  if valid_607624 != nil:
    section.add "X-Amz-Security-Token", valid_607624
  var valid_607625 = header.getOrDefault("X-Amz-Algorithm")
  valid_607625 = validateParameter(valid_607625, JString, required = false,
                                 default = nil)
  if valid_607625 != nil:
    section.add "X-Amz-Algorithm", valid_607625
  var valid_607626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607626 = validateParameter(valid_607626, JString, required = false,
                                 default = nil)
  if valid_607626 != nil:
    section.add "X-Amz-SignedHeaders", valid_607626
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
  var valid_607627 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_607627 = validateParameter(valid_607627, JString, required = false,
                                 default = nil)
  if valid_607627 != nil:
    section.add "PreferredMaintenanceWindow", valid_607627
  var valid_607628 = formData.getOrDefault("DBInstanceClass")
  valid_607628 = validateParameter(valid_607628, JString, required = false,
                                 default = nil)
  if valid_607628 != nil:
    section.add "DBInstanceClass", valid_607628
  var valid_607629 = formData.getOrDefault("PreferredBackupWindow")
  valid_607629 = validateParameter(valid_607629, JString, required = false,
                                 default = nil)
  if valid_607629 != nil:
    section.add "PreferredBackupWindow", valid_607629
  var valid_607630 = formData.getOrDefault("MasterUserPassword")
  valid_607630 = validateParameter(valid_607630, JString, required = false,
                                 default = nil)
  if valid_607630 != nil:
    section.add "MasterUserPassword", valid_607630
  var valid_607631 = formData.getOrDefault("MultiAZ")
  valid_607631 = validateParameter(valid_607631, JBool, required = false, default = nil)
  if valid_607631 != nil:
    section.add "MultiAZ", valid_607631
  var valid_607632 = formData.getOrDefault("DBParameterGroupName")
  valid_607632 = validateParameter(valid_607632, JString, required = false,
                                 default = nil)
  if valid_607632 != nil:
    section.add "DBParameterGroupName", valid_607632
  var valid_607633 = formData.getOrDefault("EngineVersion")
  valid_607633 = validateParameter(valid_607633, JString, required = false,
                                 default = nil)
  if valid_607633 != nil:
    section.add "EngineVersion", valid_607633
  var valid_607634 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_607634 = validateParameter(valid_607634, JArray, required = false,
                                 default = nil)
  if valid_607634 != nil:
    section.add "VpcSecurityGroupIds", valid_607634
  var valid_607635 = formData.getOrDefault("BackupRetentionPeriod")
  valid_607635 = validateParameter(valid_607635, JInt, required = false, default = nil)
  if valid_607635 != nil:
    section.add "BackupRetentionPeriod", valid_607635
  var valid_607636 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_607636 = validateParameter(valid_607636, JBool, required = false, default = nil)
  if valid_607636 != nil:
    section.add "AutoMinorVersionUpgrade", valid_607636
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607637 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607637 = validateParameter(valid_607637, JString, required = true,
                                 default = nil)
  if valid_607637 != nil:
    section.add "DBInstanceIdentifier", valid_607637
  var valid_607638 = formData.getOrDefault("ApplyImmediately")
  valid_607638 = validateParameter(valid_607638, JBool, required = false, default = nil)
  if valid_607638 != nil:
    section.add "ApplyImmediately", valid_607638
  var valid_607639 = formData.getOrDefault("Iops")
  valid_607639 = validateParameter(valid_607639, JInt, required = false, default = nil)
  if valid_607639 != nil:
    section.add "Iops", valid_607639
  var valid_607640 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_607640 = validateParameter(valid_607640, JBool, required = false, default = nil)
  if valid_607640 != nil:
    section.add "AllowMajorVersionUpgrade", valid_607640
  var valid_607641 = formData.getOrDefault("OptionGroupName")
  valid_607641 = validateParameter(valid_607641, JString, required = false,
                                 default = nil)
  if valid_607641 != nil:
    section.add "OptionGroupName", valid_607641
  var valid_607642 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_607642 = validateParameter(valid_607642, JString, required = false,
                                 default = nil)
  if valid_607642 != nil:
    section.add "NewDBInstanceIdentifier", valid_607642
  var valid_607643 = formData.getOrDefault("DBSecurityGroups")
  valid_607643 = validateParameter(valid_607643, JArray, required = false,
                                 default = nil)
  if valid_607643 != nil:
    section.add "DBSecurityGroups", valid_607643
  var valid_607644 = formData.getOrDefault("AllocatedStorage")
  valid_607644 = validateParameter(valid_607644, JInt, required = false, default = nil)
  if valid_607644 != nil:
    section.add "AllocatedStorage", valid_607644
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607645: Call_PostModifyDBInstance_607615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607645.validator(path, query, header, formData, body)
  let scheme = call_607645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607645.url(scheme.get, call_607645.host, call_607645.base,
                         call_607645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607645, url, valid)

proc call*(call_607646: Call_PostModifyDBInstance_607615;
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
  var query_607647 = newJObject()
  var formData_607648 = newJObject()
  add(formData_607648, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_607648, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607648, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_607648, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_607648, "MultiAZ", newJBool(MultiAZ))
  add(formData_607648, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_607648, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_607648.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_607648, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_607648, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_607648, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_607648, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_607648, "Iops", newJInt(Iops))
  add(query_607647, "Action", newJString(Action))
  add(formData_607648, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_607648, "OptionGroupName", newJString(OptionGroupName))
  add(formData_607648, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_607647, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_607648.add "DBSecurityGroups", DBSecurityGroups
  add(formData_607648, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_607646.call(nil, query_607647, nil, formData_607648, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_607615(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_607616, base: "/",
    url: url_PostModifyDBInstance_607617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_607582 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBInstance_607584(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBInstance_607583(path: JsonNode; query: JsonNode;
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
  var valid_607585 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_607585 = validateParameter(valid_607585, JString, required = false,
                                 default = nil)
  if valid_607585 != nil:
    section.add "NewDBInstanceIdentifier", valid_607585
  var valid_607586 = query.getOrDefault("DBParameterGroupName")
  valid_607586 = validateParameter(valid_607586, JString, required = false,
                                 default = nil)
  if valid_607586 != nil:
    section.add "DBParameterGroupName", valid_607586
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607587 = query.getOrDefault("DBInstanceIdentifier")
  valid_607587 = validateParameter(valid_607587, JString, required = true,
                                 default = nil)
  if valid_607587 != nil:
    section.add "DBInstanceIdentifier", valid_607587
  var valid_607588 = query.getOrDefault("BackupRetentionPeriod")
  valid_607588 = validateParameter(valid_607588, JInt, required = false, default = nil)
  if valid_607588 != nil:
    section.add "BackupRetentionPeriod", valid_607588
  var valid_607589 = query.getOrDefault("EngineVersion")
  valid_607589 = validateParameter(valid_607589, JString, required = false,
                                 default = nil)
  if valid_607589 != nil:
    section.add "EngineVersion", valid_607589
  var valid_607590 = query.getOrDefault("Action")
  valid_607590 = validateParameter(valid_607590, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_607590 != nil:
    section.add "Action", valid_607590
  var valid_607591 = query.getOrDefault("MultiAZ")
  valid_607591 = validateParameter(valid_607591, JBool, required = false, default = nil)
  if valid_607591 != nil:
    section.add "MultiAZ", valid_607591
  var valid_607592 = query.getOrDefault("DBSecurityGroups")
  valid_607592 = validateParameter(valid_607592, JArray, required = false,
                                 default = nil)
  if valid_607592 != nil:
    section.add "DBSecurityGroups", valid_607592
  var valid_607593 = query.getOrDefault("ApplyImmediately")
  valid_607593 = validateParameter(valid_607593, JBool, required = false, default = nil)
  if valid_607593 != nil:
    section.add "ApplyImmediately", valid_607593
  var valid_607594 = query.getOrDefault("VpcSecurityGroupIds")
  valid_607594 = validateParameter(valid_607594, JArray, required = false,
                                 default = nil)
  if valid_607594 != nil:
    section.add "VpcSecurityGroupIds", valid_607594
  var valid_607595 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_607595 = validateParameter(valid_607595, JBool, required = false, default = nil)
  if valid_607595 != nil:
    section.add "AllowMajorVersionUpgrade", valid_607595
  var valid_607596 = query.getOrDefault("MasterUserPassword")
  valid_607596 = validateParameter(valid_607596, JString, required = false,
                                 default = nil)
  if valid_607596 != nil:
    section.add "MasterUserPassword", valid_607596
  var valid_607597 = query.getOrDefault("OptionGroupName")
  valid_607597 = validateParameter(valid_607597, JString, required = false,
                                 default = nil)
  if valid_607597 != nil:
    section.add "OptionGroupName", valid_607597
  var valid_607598 = query.getOrDefault("Version")
  valid_607598 = validateParameter(valid_607598, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607598 != nil:
    section.add "Version", valid_607598
  var valid_607599 = query.getOrDefault("AllocatedStorage")
  valid_607599 = validateParameter(valid_607599, JInt, required = false, default = nil)
  if valid_607599 != nil:
    section.add "AllocatedStorage", valid_607599
  var valid_607600 = query.getOrDefault("DBInstanceClass")
  valid_607600 = validateParameter(valid_607600, JString, required = false,
                                 default = nil)
  if valid_607600 != nil:
    section.add "DBInstanceClass", valid_607600
  var valid_607601 = query.getOrDefault("PreferredBackupWindow")
  valid_607601 = validateParameter(valid_607601, JString, required = false,
                                 default = nil)
  if valid_607601 != nil:
    section.add "PreferredBackupWindow", valid_607601
  var valid_607602 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_607602 = validateParameter(valid_607602, JString, required = false,
                                 default = nil)
  if valid_607602 != nil:
    section.add "PreferredMaintenanceWindow", valid_607602
  var valid_607603 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_607603 = validateParameter(valid_607603, JBool, required = false, default = nil)
  if valid_607603 != nil:
    section.add "AutoMinorVersionUpgrade", valid_607603
  var valid_607604 = query.getOrDefault("Iops")
  valid_607604 = validateParameter(valid_607604, JInt, required = false, default = nil)
  if valid_607604 != nil:
    section.add "Iops", valid_607604
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607605 = header.getOrDefault("X-Amz-Signature")
  valid_607605 = validateParameter(valid_607605, JString, required = false,
                                 default = nil)
  if valid_607605 != nil:
    section.add "X-Amz-Signature", valid_607605
  var valid_607606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607606 = validateParameter(valid_607606, JString, required = false,
                                 default = nil)
  if valid_607606 != nil:
    section.add "X-Amz-Content-Sha256", valid_607606
  var valid_607607 = header.getOrDefault("X-Amz-Date")
  valid_607607 = validateParameter(valid_607607, JString, required = false,
                                 default = nil)
  if valid_607607 != nil:
    section.add "X-Amz-Date", valid_607607
  var valid_607608 = header.getOrDefault("X-Amz-Credential")
  valid_607608 = validateParameter(valid_607608, JString, required = false,
                                 default = nil)
  if valid_607608 != nil:
    section.add "X-Amz-Credential", valid_607608
  var valid_607609 = header.getOrDefault("X-Amz-Security-Token")
  valid_607609 = validateParameter(valid_607609, JString, required = false,
                                 default = nil)
  if valid_607609 != nil:
    section.add "X-Amz-Security-Token", valid_607609
  var valid_607610 = header.getOrDefault("X-Amz-Algorithm")
  valid_607610 = validateParameter(valid_607610, JString, required = false,
                                 default = nil)
  if valid_607610 != nil:
    section.add "X-Amz-Algorithm", valid_607610
  var valid_607611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607611 = validateParameter(valid_607611, JString, required = false,
                                 default = nil)
  if valid_607611 != nil:
    section.add "X-Amz-SignedHeaders", valid_607611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607612: Call_GetModifyDBInstance_607582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607612.validator(path, query, header, formData, body)
  let scheme = call_607612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607612.url(scheme.get, call_607612.host, call_607612.base,
                         call_607612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607612, url, valid)

proc call*(call_607613: Call_GetModifyDBInstance_607582;
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
  var query_607614 = newJObject()
  add(query_607614, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_607614, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607614, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607614, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_607614, "EngineVersion", newJString(EngineVersion))
  add(query_607614, "Action", newJString(Action))
  add(query_607614, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_607614.add "DBSecurityGroups", DBSecurityGroups
  add(query_607614, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_607614.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_607614, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_607614, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_607614, "OptionGroupName", newJString(OptionGroupName))
  add(query_607614, "Version", newJString(Version))
  add(query_607614, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_607614, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_607614, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_607614, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_607614, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_607614, "Iops", newJInt(Iops))
  result = call_607613.call(nil, query_607614, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_607582(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_607583, base: "/",
    url: url_GetModifyDBInstance_607584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_607666 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBParameterGroup_607668(protocol: Scheme; host: string;
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

proc validate_PostModifyDBParameterGroup_607667(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607669 = query.getOrDefault("Action")
  valid_607669 = validateParameter(valid_607669, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_607669 != nil:
    section.add "Action", valid_607669
  var valid_607670 = query.getOrDefault("Version")
  valid_607670 = validateParameter(valid_607670, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607670 != nil:
    section.add "Version", valid_607670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607671 = header.getOrDefault("X-Amz-Signature")
  valid_607671 = validateParameter(valid_607671, JString, required = false,
                                 default = nil)
  if valid_607671 != nil:
    section.add "X-Amz-Signature", valid_607671
  var valid_607672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607672 = validateParameter(valid_607672, JString, required = false,
                                 default = nil)
  if valid_607672 != nil:
    section.add "X-Amz-Content-Sha256", valid_607672
  var valid_607673 = header.getOrDefault("X-Amz-Date")
  valid_607673 = validateParameter(valid_607673, JString, required = false,
                                 default = nil)
  if valid_607673 != nil:
    section.add "X-Amz-Date", valid_607673
  var valid_607674 = header.getOrDefault("X-Amz-Credential")
  valid_607674 = validateParameter(valid_607674, JString, required = false,
                                 default = nil)
  if valid_607674 != nil:
    section.add "X-Amz-Credential", valid_607674
  var valid_607675 = header.getOrDefault("X-Amz-Security-Token")
  valid_607675 = validateParameter(valid_607675, JString, required = false,
                                 default = nil)
  if valid_607675 != nil:
    section.add "X-Amz-Security-Token", valid_607675
  var valid_607676 = header.getOrDefault("X-Amz-Algorithm")
  valid_607676 = validateParameter(valid_607676, JString, required = false,
                                 default = nil)
  if valid_607676 != nil:
    section.add "X-Amz-Algorithm", valid_607676
  var valid_607677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607677 = validateParameter(valid_607677, JString, required = false,
                                 default = nil)
  if valid_607677 != nil:
    section.add "X-Amz-SignedHeaders", valid_607677
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_607678 = formData.getOrDefault("DBParameterGroupName")
  valid_607678 = validateParameter(valid_607678, JString, required = true,
                                 default = nil)
  if valid_607678 != nil:
    section.add "DBParameterGroupName", valid_607678
  var valid_607679 = formData.getOrDefault("Parameters")
  valid_607679 = validateParameter(valid_607679, JArray, required = true, default = nil)
  if valid_607679 != nil:
    section.add "Parameters", valid_607679
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607680: Call_PostModifyDBParameterGroup_607666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607680.validator(path, query, header, formData, body)
  let scheme = call_607680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607680.url(scheme.get, call_607680.host, call_607680.base,
                         call_607680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607680, url, valid)

proc call*(call_607681: Call_PostModifyDBParameterGroup_607666;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_607682 = newJObject()
  var formData_607683 = newJObject()
  add(formData_607683, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607682, "Action", newJString(Action))
  if Parameters != nil:
    formData_607683.add "Parameters", Parameters
  add(query_607682, "Version", newJString(Version))
  result = call_607681.call(nil, query_607682, nil, formData_607683, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_607666(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_607667, base: "/",
    url: url_PostModifyDBParameterGroup_607668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_607649 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBParameterGroup_607651(protocol: Scheme; host: string;
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

proc validate_GetModifyDBParameterGroup_607650(path: JsonNode; query: JsonNode;
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
  var valid_607652 = query.getOrDefault("DBParameterGroupName")
  valid_607652 = validateParameter(valid_607652, JString, required = true,
                                 default = nil)
  if valid_607652 != nil:
    section.add "DBParameterGroupName", valid_607652
  var valid_607653 = query.getOrDefault("Parameters")
  valid_607653 = validateParameter(valid_607653, JArray, required = true, default = nil)
  if valid_607653 != nil:
    section.add "Parameters", valid_607653
  var valid_607654 = query.getOrDefault("Action")
  valid_607654 = validateParameter(valid_607654, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_607654 != nil:
    section.add "Action", valid_607654
  var valid_607655 = query.getOrDefault("Version")
  valid_607655 = validateParameter(valid_607655, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607655 != nil:
    section.add "Version", valid_607655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607656 = header.getOrDefault("X-Amz-Signature")
  valid_607656 = validateParameter(valid_607656, JString, required = false,
                                 default = nil)
  if valid_607656 != nil:
    section.add "X-Amz-Signature", valid_607656
  var valid_607657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607657 = validateParameter(valid_607657, JString, required = false,
                                 default = nil)
  if valid_607657 != nil:
    section.add "X-Amz-Content-Sha256", valid_607657
  var valid_607658 = header.getOrDefault("X-Amz-Date")
  valid_607658 = validateParameter(valid_607658, JString, required = false,
                                 default = nil)
  if valid_607658 != nil:
    section.add "X-Amz-Date", valid_607658
  var valid_607659 = header.getOrDefault("X-Amz-Credential")
  valid_607659 = validateParameter(valid_607659, JString, required = false,
                                 default = nil)
  if valid_607659 != nil:
    section.add "X-Amz-Credential", valid_607659
  var valid_607660 = header.getOrDefault("X-Amz-Security-Token")
  valid_607660 = validateParameter(valid_607660, JString, required = false,
                                 default = nil)
  if valid_607660 != nil:
    section.add "X-Amz-Security-Token", valid_607660
  var valid_607661 = header.getOrDefault("X-Amz-Algorithm")
  valid_607661 = validateParameter(valid_607661, JString, required = false,
                                 default = nil)
  if valid_607661 != nil:
    section.add "X-Amz-Algorithm", valid_607661
  var valid_607662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607662 = validateParameter(valid_607662, JString, required = false,
                                 default = nil)
  if valid_607662 != nil:
    section.add "X-Amz-SignedHeaders", valid_607662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607663: Call_GetModifyDBParameterGroup_607649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607663.validator(path, query, header, formData, body)
  let scheme = call_607663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607663.url(scheme.get, call_607663.host, call_607663.base,
                         call_607663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607663, url, valid)

proc call*(call_607664: Call_GetModifyDBParameterGroup_607649;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607665 = newJObject()
  add(query_607665, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_607665.add "Parameters", Parameters
  add(query_607665, "Action", newJString(Action))
  add(query_607665, "Version", newJString(Version))
  result = call_607664.call(nil, query_607665, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_607649(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_607650, base: "/",
    url: url_GetModifyDBParameterGroup_607651,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_607702 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBSubnetGroup_607704(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBSubnetGroup_607703(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607705 = query.getOrDefault("Action")
  valid_607705 = validateParameter(valid_607705, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_607705 != nil:
    section.add "Action", valid_607705
  var valid_607706 = query.getOrDefault("Version")
  valid_607706 = validateParameter(valid_607706, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607706 != nil:
    section.add "Version", valid_607706
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607707 = header.getOrDefault("X-Amz-Signature")
  valid_607707 = validateParameter(valid_607707, JString, required = false,
                                 default = nil)
  if valid_607707 != nil:
    section.add "X-Amz-Signature", valid_607707
  var valid_607708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607708 = validateParameter(valid_607708, JString, required = false,
                                 default = nil)
  if valid_607708 != nil:
    section.add "X-Amz-Content-Sha256", valid_607708
  var valid_607709 = header.getOrDefault("X-Amz-Date")
  valid_607709 = validateParameter(valid_607709, JString, required = false,
                                 default = nil)
  if valid_607709 != nil:
    section.add "X-Amz-Date", valid_607709
  var valid_607710 = header.getOrDefault("X-Amz-Credential")
  valid_607710 = validateParameter(valid_607710, JString, required = false,
                                 default = nil)
  if valid_607710 != nil:
    section.add "X-Amz-Credential", valid_607710
  var valid_607711 = header.getOrDefault("X-Amz-Security-Token")
  valid_607711 = validateParameter(valid_607711, JString, required = false,
                                 default = nil)
  if valid_607711 != nil:
    section.add "X-Amz-Security-Token", valid_607711
  var valid_607712 = header.getOrDefault("X-Amz-Algorithm")
  valid_607712 = validateParameter(valid_607712, JString, required = false,
                                 default = nil)
  if valid_607712 != nil:
    section.add "X-Amz-Algorithm", valid_607712
  var valid_607713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607713 = validateParameter(valid_607713, JString, required = false,
                                 default = nil)
  if valid_607713 != nil:
    section.add "X-Amz-SignedHeaders", valid_607713
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_607714 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_607714 = validateParameter(valid_607714, JString, required = false,
                                 default = nil)
  if valid_607714 != nil:
    section.add "DBSubnetGroupDescription", valid_607714
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_607715 = formData.getOrDefault("DBSubnetGroupName")
  valid_607715 = validateParameter(valid_607715, JString, required = true,
                                 default = nil)
  if valid_607715 != nil:
    section.add "DBSubnetGroupName", valid_607715
  var valid_607716 = formData.getOrDefault("SubnetIds")
  valid_607716 = validateParameter(valid_607716, JArray, required = true, default = nil)
  if valid_607716 != nil:
    section.add "SubnetIds", valid_607716
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607717: Call_PostModifyDBSubnetGroup_607702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607717.validator(path, query, header, formData, body)
  let scheme = call_607717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607717.url(scheme.get, call_607717.host, call_607717.base,
                         call_607717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607717, url, valid)

proc call*(call_607718: Call_PostModifyDBSubnetGroup_607702;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_607719 = newJObject()
  var formData_607720 = newJObject()
  add(formData_607720, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_607719, "Action", newJString(Action))
  add(formData_607720, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607719, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_607720.add "SubnetIds", SubnetIds
  result = call_607718.call(nil, query_607719, nil, formData_607720, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_607702(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_607703, base: "/",
    url: url_PostModifyDBSubnetGroup_607704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_607684 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBSubnetGroup_607686(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBSubnetGroup_607685(path: JsonNode; query: JsonNode;
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
  var valid_607687 = query.getOrDefault("SubnetIds")
  valid_607687 = validateParameter(valid_607687, JArray, required = true, default = nil)
  if valid_607687 != nil:
    section.add "SubnetIds", valid_607687
  var valid_607688 = query.getOrDefault("Action")
  valid_607688 = validateParameter(valid_607688, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_607688 != nil:
    section.add "Action", valid_607688
  var valid_607689 = query.getOrDefault("DBSubnetGroupDescription")
  valid_607689 = validateParameter(valid_607689, JString, required = false,
                                 default = nil)
  if valid_607689 != nil:
    section.add "DBSubnetGroupDescription", valid_607689
  var valid_607690 = query.getOrDefault("DBSubnetGroupName")
  valid_607690 = validateParameter(valid_607690, JString, required = true,
                                 default = nil)
  if valid_607690 != nil:
    section.add "DBSubnetGroupName", valid_607690
  var valid_607691 = query.getOrDefault("Version")
  valid_607691 = validateParameter(valid_607691, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607691 != nil:
    section.add "Version", valid_607691
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607692 = header.getOrDefault("X-Amz-Signature")
  valid_607692 = validateParameter(valid_607692, JString, required = false,
                                 default = nil)
  if valid_607692 != nil:
    section.add "X-Amz-Signature", valid_607692
  var valid_607693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607693 = validateParameter(valid_607693, JString, required = false,
                                 default = nil)
  if valid_607693 != nil:
    section.add "X-Amz-Content-Sha256", valid_607693
  var valid_607694 = header.getOrDefault("X-Amz-Date")
  valid_607694 = validateParameter(valid_607694, JString, required = false,
                                 default = nil)
  if valid_607694 != nil:
    section.add "X-Amz-Date", valid_607694
  var valid_607695 = header.getOrDefault("X-Amz-Credential")
  valid_607695 = validateParameter(valid_607695, JString, required = false,
                                 default = nil)
  if valid_607695 != nil:
    section.add "X-Amz-Credential", valid_607695
  var valid_607696 = header.getOrDefault("X-Amz-Security-Token")
  valid_607696 = validateParameter(valid_607696, JString, required = false,
                                 default = nil)
  if valid_607696 != nil:
    section.add "X-Amz-Security-Token", valid_607696
  var valid_607697 = header.getOrDefault("X-Amz-Algorithm")
  valid_607697 = validateParameter(valid_607697, JString, required = false,
                                 default = nil)
  if valid_607697 != nil:
    section.add "X-Amz-Algorithm", valid_607697
  var valid_607698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607698 = validateParameter(valid_607698, JString, required = false,
                                 default = nil)
  if valid_607698 != nil:
    section.add "X-Amz-SignedHeaders", valid_607698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607699: Call_GetModifyDBSubnetGroup_607684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607699.validator(path, query, header, formData, body)
  let scheme = call_607699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607699.url(scheme.get, call_607699.host, call_607699.base,
                         call_607699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607699, url, valid)

proc call*(call_607700: Call_GetModifyDBSubnetGroup_607684; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_607701 = newJObject()
  if SubnetIds != nil:
    query_607701.add "SubnetIds", SubnetIds
  add(query_607701, "Action", newJString(Action))
  add(query_607701, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_607701, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607701, "Version", newJString(Version))
  result = call_607700.call(nil, query_607701, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_607684(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_607685, base: "/",
    url: url_GetModifyDBSubnetGroup_607686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_607741 = ref object of OpenApiRestCall_605573
proc url_PostModifyEventSubscription_607743(protocol: Scheme; host: string;
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

proc validate_PostModifyEventSubscription_607742(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607744 = query.getOrDefault("Action")
  valid_607744 = validateParameter(valid_607744, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_607744 != nil:
    section.add "Action", valid_607744
  var valid_607745 = query.getOrDefault("Version")
  valid_607745 = validateParameter(valid_607745, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607745 != nil:
    section.add "Version", valid_607745
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607746 = header.getOrDefault("X-Amz-Signature")
  valid_607746 = validateParameter(valid_607746, JString, required = false,
                                 default = nil)
  if valid_607746 != nil:
    section.add "X-Amz-Signature", valid_607746
  var valid_607747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607747 = validateParameter(valid_607747, JString, required = false,
                                 default = nil)
  if valid_607747 != nil:
    section.add "X-Amz-Content-Sha256", valid_607747
  var valid_607748 = header.getOrDefault("X-Amz-Date")
  valid_607748 = validateParameter(valid_607748, JString, required = false,
                                 default = nil)
  if valid_607748 != nil:
    section.add "X-Amz-Date", valid_607748
  var valid_607749 = header.getOrDefault("X-Amz-Credential")
  valid_607749 = validateParameter(valid_607749, JString, required = false,
                                 default = nil)
  if valid_607749 != nil:
    section.add "X-Amz-Credential", valid_607749
  var valid_607750 = header.getOrDefault("X-Amz-Security-Token")
  valid_607750 = validateParameter(valid_607750, JString, required = false,
                                 default = nil)
  if valid_607750 != nil:
    section.add "X-Amz-Security-Token", valid_607750
  var valid_607751 = header.getOrDefault("X-Amz-Algorithm")
  valid_607751 = validateParameter(valid_607751, JString, required = false,
                                 default = nil)
  if valid_607751 != nil:
    section.add "X-Amz-Algorithm", valid_607751
  var valid_607752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607752 = validateParameter(valid_607752, JString, required = false,
                                 default = nil)
  if valid_607752 != nil:
    section.add "X-Amz-SignedHeaders", valid_607752
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_607753 = formData.getOrDefault("SnsTopicArn")
  valid_607753 = validateParameter(valid_607753, JString, required = false,
                                 default = nil)
  if valid_607753 != nil:
    section.add "SnsTopicArn", valid_607753
  var valid_607754 = formData.getOrDefault("Enabled")
  valid_607754 = validateParameter(valid_607754, JBool, required = false, default = nil)
  if valid_607754 != nil:
    section.add "Enabled", valid_607754
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_607755 = formData.getOrDefault("SubscriptionName")
  valid_607755 = validateParameter(valid_607755, JString, required = true,
                                 default = nil)
  if valid_607755 != nil:
    section.add "SubscriptionName", valid_607755
  var valid_607756 = formData.getOrDefault("SourceType")
  valid_607756 = validateParameter(valid_607756, JString, required = false,
                                 default = nil)
  if valid_607756 != nil:
    section.add "SourceType", valid_607756
  var valid_607757 = formData.getOrDefault("EventCategories")
  valid_607757 = validateParameter(valid_607757, JArray, required = false,
                                 default = nil)
  if valid_607757 != nil:
    section.add "EventCategories", valid_607757
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607758: Call_PostModifyEventSubscription_607741; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607758.validator(path, query, header, formData, body)
  let scheme = call_607758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607758.url(scheme.get, call_607758.host, call_607758.base,
                         call_607758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607758, url, valid)

proc call*(call_607759: Call_PostModifyEventSubscription_607741;
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
  var query_607760 = newJObject()
  var formData_607761 = newJObject()
  add(formData_607761, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_607761, "Enabled", newJBool(Enabled))
  add(formData_607761, "SubscriptionName", newJString(SubscriptionName))
  add(formData_607761, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_607761.add "EventCategories", EventCategories
  add(query_607760, "Action", newJString(Action))
  add(query_607760, "Version", newJString(Version))
  result = call_607759.call(nil, query_607760, nil, formData_607761, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_607741(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_607742, base: "/",
    url: url_PostModifyEventSubscription_607743,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_607721 = ref object of OpenApiRestCall_605573
proc url_GetModifyEventSubscription_607723(protocol: Scheme; host: string;
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

proc validate_GetModifyEventSubscription_607722(path: JsonNode; query: JsonNode;
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
  var valid_607724 = query.getOrDefault("SourceType")
  valid_607724 = validateParameter(valid_607724, JString, required = false,
                                 default = nil)
  if valid_607724 != nil:
    section.add "SourceType", valid_607724
  var valid_607725 = query.getOrDefault("Enabled")
  valid_607725 = validateParameter(valid_607725, JBool, required = false, default = nil)
  if valid_607725 != nil:
    section.add "Enabled", valid_607725
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_607726 = query.getOrDefault("SubscriptionName")
  valid_607726 = validateParameter(valid_607726, JString, required = true,
                                 default = nil)
  if valid_607726 != nil:
    section.add "SubscriptionName", valid_607726
  var valid_607727 = query.getOrDefault("EventCategories")
  valid_607727 = validateParameter(valid_607727, JArray, required = false,
                                 default = nil)
  if valid_607727 != nil:
    section.add "EventCategories", valid_607727
  var valid_607728 = query.getOrDefault("Action")
  valid_607728 = validateParameter(valid_607728, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_607728 != nil:
    section.add "Action", valid_607728
  var valid_607729 = query.getOrDefault("SnsTopicArn")
  valid_607729 = validateParameter(valid_607729, JString, required = false,
                                 default = nil)
  if valid_607729 != nil:
    section.add "SnsTopicArn", valid_607729
  var valid_607730 = query.getOrDefault("Version")
  valid_607730 = validateParameter(valid_607730, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607730 != nil:
    section.add "Version", valid_607730
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607731 = header.getOrDefault("X-Amz-Signature")
  valid_607731 = validateParameter(valid_607731, JString, required = false,
                                 default = nil)
  if valid_607731 != nil:
    section.add "X-Amz-Signature", valid_607731
  var valid_607732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607732 = validateParameter(valid_607732, JString, required = false,
                                 default = nil)
  if valid_607732 != nil:
    section.add "X-Amz-Content-Sha256", valid_607732
  var valid_607733 = header.getOrDefault("X-Amz-Date")
  valid_607733 = validateParameter(valid_607733, JString, required = false,
                                 default = nil)
  if valid_607733 != nil:
    section.add "X-Amz-Date", valid_607733
  var valid_607734 = header.getOrDefault("X-Amz-Credential")
  valid_607734 = validateParameter(valid_607734, JString, required = false,
                                 default = nil)
  if valid_607734 != nil:
    section.add "X-Amz-Credential", valid_607734
  var valid_607735 = header.getOrDefault("X-Amz-Security-Token")
  valid_607735 = validateParameter(valid_607735, JString, required = false,
                                 default = nil)
  if valid_607735 != nil:
    section.add "X-Amz-Security-Token", valid_607735
  var valid_607736 = header.getOrDefault("X-Amz-Algorithm")
  valid_607736 = validateParameter(valid_607736, JString, required = false,
                                 default = nil)
  if valid_607736 != nil:
    section.add "X-Amz-Algorithm", valid_607736
  var valid_607737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607737 = validateParameter(valid_607737, JString, required = false,
                                 default = nil)
  if valid_607737 != nil:
    section.add "X-Amz-SignedHeaders", valid_607737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607738: Call_GetModifyEventSubscription_607721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607738.validator(path, query, header, formData, body)
  let scheme = call_607738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607738.url(scheme.get, call_607738.host, call_607738.base,
                         call_607738.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607738, url, valid)

proc call*(call_607739: Call_GetModifyEventSubscription_607721;
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
  var query_607740 = newJObject()
  add(query_607740, "SourceType", newJString(SourceType))
  add(query_607740, "Enabled", newJBool(Enabled))
  add(query_607740, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_607740.add "EventCategories", EventCategories
  add(query_607740, "Action", newJString(Action))
  add(query_607740, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_607740, "Version", newJString(Version))
  result = call_607739.call(nil, query_607740, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_607721(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_607722, base: "/",
    url: url_GetModifyEventSubscription_607723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_607781 = ref object of OpenApiRestCall_605573
proc url_PostModifyOptionGroup_607783(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyOptionGroup_607782(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607784 = query.getOrDefault("Action")
  valid_607784 = validateParameter(valid_607784, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_607784 != nil:
    section.add "Action", valid_607784
  var valid_607785 = query.getOrDefault("Version")
  valid_607785 = validateParameter(valid_607785, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607785 != nil:
    section.add "Version", valid_607785
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607786 = header.getOrDefault("X-Amz-Signature")
  valid_607786 = validateParameter(valid_607786, JString, required = false,
                                 default = nil)
  if valid_607786 != nil:
    section.add "X-Amz-Signature", valid_607786
  var valid_607787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607787 = validateParameter(valid_607787, JString, required = false,
                                 default = nil)
  if valid_607787 != nil:
    section.add "X-Amz-Content-Sha256", valid_607787
  var valid_607788 = header.getOrDefault("X-Amz-Date")
  valid_607788 = validateParameter(valid_607788, JString, required = false,
                                 default = nil)
  if valid_607788 != nil:
    section.add "X-Amz-Date", valid_607788
  var valid_607789 = header.getOrDefault("X-Amz-Credential")
  valid_607789 = validateParameter(valid_607789, JString, required = false,
                                 default = nil)
  if valid_607789 != nil:
    section.add "X-Amz-Credential", valid_607789
  var valid_607790 = header.getOrDefault("X-Amz-Security-Token")
  valid_607790 = validateParameter(valid_607790, JString, required = false,
                                 default = nil)
  if valid_607790 != nil:
    section.add "X-Amz-Security-Token", valid_607790
  var valid_607791 = header.getOrDefault("X-Amz-Algorithm")
  valid_607791 = validateParameter(valid_607791, JString, required = false,
                                 default = nil)
  if valid_607791 != nil:
    section.add "X-Amz-Algorithm", valid_607791
  var valid_607792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607792 = validateParameter(valid_607792, JString, required = false,
                                 default = nil)
  if valid_607792 != nil:
    section.add "X-Amz-SignedHeaders", valid_607792
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_607793 = formData.getOrDefault("OptionsToRemove")
  valid_607793 = validateParameter(valid_607793, JArray, required = false,
                                 default = nil)
  if valid_607793 != nil:
    section.add "OptionsToRemove", valid_607793
  var valid_607794 = formData.getOrDefault("ApplyImmediately")
  valid_607794 = validateParameter(valid_607794, JBool, required = false, default = nil)
  if valid_607794 != nil:
    section.add "ApplyImmediately", valid_607794
  var valid_607795 = formData.getOrDefault("OptionsToInclude")
  valid_607795 = validateParameter(valid_607795, JArray, required = false,
                                 default = nil)
  if valid_607795 != nil:
    section.add "OptionsToInclude", valid_607795
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_607796 = formData.getOrDefault("OptionGroupName")
  valid_607796 = validateParameter(valid_607796, JString, required = true,
                                 default = nil)
  if valid_607796 != nil:
    section.add "OptionGroupName", valid_607796
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607797: Call_PostModifyOptionGroup_607781; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607797.validator(path, query, header, formData, body)
  let scheme = call_607797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607797.url(scheme.get, call_607797.host, call_607797.base,
                         call_607797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607797, url, valid)

proc call*(call_607798: Call_PostModifyOptionGroup_607781; OptionGroupName: string;
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
  var query_607799 = newJObject()
  var formData_607800 = newJObject()
  if OptionsToRemove != nil:
    formData_607800.add "OptionsToRemove", OptionsToRemove
  add(formData_607800, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_607800.add "OptionsToInclude", OptionsToInclude
  add(query_607799, "Action", newJString(Action))
  add(formData_607800, "OptionGroupName", newJString(OptionGroupName))
  add(query_607799, "Version", newJString(Version))
  result = call_607798.call(nil, query_607799, nil, formData_607800, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_607781(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_607782, base: "/",
    url: url_PostModifyOptionGroup_607783, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_607762 = ref object of OpenApiRestCall_605573
proc url_GetModifyOptionGroup_607764(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyOptionGroup_607763(path: JsonNode; query: JsonNode;
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
  var valid_607765 = query.getOrDefault("Action")
  valid_607765 = validateParameter(valid_607765, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_607765 != nil:
    section.add "Action", valid_607765
  var valid_607766 = query.getOrDefault("ApplyImmediately")
  valid_607766 = validateParameter(valid_607766, JBool, required = false, default = nil)
  if valid_607766 != nil:
    section.add "ApplyImmediately", valid_607766
  var valid_607767 = query.getOrDefault("OptionsToRemove")
  valid_607767 = validateParameter(valid_607767, JArray, required = false,
                                 default = nil)
  if valid_607767 != nil:
    section.add "OptionsToRemove", valid_607767
  var valid_607768 = query.getOrDefault("OptionsToInclude")
  valid_607768 = validateParameter(valid_607768, JArray, required = false,
                                 default = nil)
  if valid_607768 != nil:
    section.add "OptionsToInclude", valid_607768
  var valid_607769 = query.getOrDefault("OptionGroupName")
  valid_607769 = validateParameter(valid_607769, JString, required = true,
                                 default = nil)
  if valid_607769 != nil:
    section.add "OptionGroupName", valid_607769
  var valid_607770 = query.getOrDefault("Version")
  valid_607770 = validateParameter(valid_607770, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607770 != nil:
    section.add "Version", valid_607770
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607771 = header.getOrDefault("X-Amz-Signature")
  valid_607771 = validateParameter(valid_607771, JString, required = false,
                                 default = nil)
  if valid_607771 != nil:
    section.add "X-Amz-Signature", valid_607771
  var valid_607772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607772 = validateParameter(valid_607772, JString, required = false,
                                 default = nil)
  if valid_607772 != nil:
    section.add "X-Amz-Content-Sha256", valid_607772
  var valid_607773 = header.getOrDefault("X-Amz-Date")
  valid_607773 = validateParameter(valid_607773, JString, required = false,
                                 default = nil)
  if valid_607773 != nil:
    section.add "X-Amz-Date", valid_607773
  var valid_607774 = header.getOrDefault("X-Amz-Credential")
  valid_607774 = validateParameter(valid_607774, JString, required = false,
                                 default = nil)
  if valid_607774 != nil:
    section.add "X-Amz-Credential", valid_607774
  var valid_607775 = header.getOrDefault("X-Amz-Security-Token")
  valid_607775 = validateParameter(valid_607775, JString, required = false,
                                 default = nil)
  if valid_607775 != nil:
    section.add "X-Amz-Security-Token", valid_607775
  var valid_607776 = header.getOrDefault("X-Amz-Algorithm")
  valid_607776 = validateParameter(valid_607776, JString, required = false,
                                 default = nil)
  if valid_607776 != nil:
    section.add "X-Amz-Algorithm", valid_607776
  var valid_607777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607777 = validateParameter(valid_607777, JString, required = false,
                                 default = nil)
  if valid_607777 != nil:
    section.add "X-Amz-SignedHeaders", valid_607777
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607778: Call_GetModifyOptionGroup_607762; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607778.validator(path, query, header, formData, body)
  let scheme = call_607778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607778.url(scheme.get, call_607778.host, call_607778.base,
                         call_607778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607778, url, valid)

proc call*(call_607779: Call_GetModifyOptionGroup_607762; OptionGroupName: string;
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
  var query_607780 = newJObject()
  add(query_607780, "Action", newJString(Action))
  add(query_607780, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_607780.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_607780.add "OptionsToInclude", OptionsToInclude
  add(query_607780, "OptionGroupName", newJString(OptionGroupName))
  add(query_607780, "Version", newJString(Version))
  result = call_607779.call(nil, query_607780, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_607762(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_607763, base: "/",
    url: url_GetModifyOptionGroup_607764, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_607819 = ref object of OpenApiRestCall_605573
proc url_PostPromoteReadReplica_607821(protocol: Scheme; host: string; base: string;
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

proc validate_PostPromoteReadReplica_607820(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607822 = query.getOrDefault("Action")
  valid_607822 = validateParameter(valid_607822, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_607822 != nil:
    section.add "Action", valid_607822
  var valid_607823 = query.getOrDefault("Version")
  valid_607823 = validateParameter(valid_607823, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607823 != nil:
    section.add "Version", valid_607823
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607824 = header.getOrDefault("X-Amz-Signature")
  valid_607824 = validateParameter(valid_607824, JString, required = false,
                                 default = nil)
  if valid_607824 != nil:
    section.add "X-Amz-Signature", valid_607824
  var valid_607825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607825 = validateParameter(valid_607825, JString, required = false,
                                 default = nil)
  if valid_607825 != nil:
    section.add "X-Amz-Content-Sha256", valid_607825
  var valid_607826 = header.getOrDefault("X-Amz-Date")
  valid_607826 = validateParameter(valid_607826, JString, required = false,
                                 default = nil)
  if valid_607826 != nil:
    section.add "X-Amz-Date", valid_607826
  var valid_607827 = header.getOrDefault("X-Amz-Credential")
  valid_607827 = validateParameter(valid_607827, JString, required = false,
                                 default = nil)
  if valid_607827 != nil:
    section.add "X-Amz-Credential", valid_607827
  var valid_607828 = header.getOrDefault("X-Amz-Security-Token")
  valid_607828 = validateParameter(valid_607828, JString, required = false,
                                 default = nil)
  if valid_607828 != nil:
    section.add "X-Amz-Security-Token", valid_607828
  var valid_607829 = header.getOrDefault("X-Amz-Algorithm")
  valid_607829 = validateParameter(valid_607829, JString, required = false,
                                 default = nil)
  if valid_607829 != nil:
    section.add "X-Amz-Algorithm", valid_607829
  var valid_607830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607830 = validateParameter(valid_607830, JString, required = false,
                                 default = nil)
  if valid_607830 != nil:
    section.add "X-Amz-SignedHeaders", valid_607830
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_607831 = formData.getOrDefault("PreferredBackupWindow")
  valid_607831 = validateParameter(valid_607831, JString, required = false,
                                 default = nil)
  if valid_607831 != nil:
    section.add "PreferredBackupWindow", valid_607831
  var valid_607832 = formData.getOrDefault("BackupRetentionPeriod")
  valid_607832 = validateParameter(valid_607832, JInt, required = false, default = nil)
  if valid_607832 != nil:
    section.add "BackupRetentionPeriod", valid_607832
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607833 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607833 = validateParameter(valid_607833, JString, required = true,
                                 default = nil)
  if valid_607833 != nil:
    section.add "DBInstanceIdentifier", valid_607833
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607834: Call_PostPromoteReadReplica_607819; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607834.validator(path, query, header, formData, body)
  let scheme = call_607834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607834.url(scheme.get, call_607834.host, call_607834.base,
                         call_607834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607834, url, valid)

proc call*(call_607835: Call_PostPromoteReadReplica_607819;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2013-01-10"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607836 = newJObject()
  var formData_607837 = newJObject()
  add(formData_607837, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_607837, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_607837, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607836, "Action", newJString(Action))
  add(query_607836, "Version", newJString(Version))
  result = call_607835.call(nil, query_607836, nil, formData_607837, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_607819(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_607820, base: "/",
    url: url_PostPromoteReadReplica_607821, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_607801 = ref object of OpenApiRestCall_605573
proc url_GetPromoteReadReplica_607803(protocol: Scheme; host: string; base: string;
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

proc validate_GetPromoteReadReplica_607802(path: JsonNode; query: JsonNode;
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
  var valid_607804 = query.getOrDefault("DBInstanceIdentifier")
  valid_607804 = validateParameter(valid_607804, JString, required = true,
                                 default = nil)
  if valid_607804 != nil:
    section.add "DBInstanceIdentifier", valid_607804
  var valid_607805 = query.getOrDefault("BackupRetentionPeriod")
  valid_607805 = validateParameter(valid_607805, JInt, required = false, default = nil)
  if valid_607805 != nil:
    section.add "BackupRetentionPeriod", valid_607805
  var valid_607806 = query.getOrDefault("Action")
  valid_607806 = validateParameter(valid_607806, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_607806 != nil:
    section.add "Action", valid_607806
  var valid_607807 = query.getOrDefault("Version")
  valid_607807 = validateParameter(valid_607807, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607807 != nil:
    section.add "Version", valid_607807
  var valid_607808 = query.getOrDefault("PreferredBackupWindow")
  valid_607808 = validateParameter(valid_607808, JString, required = false,
                                 default = nil)
  if valid_607808 != nil:
    section.add "PreferredBackupWindow", valid_607808
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607809 = header.getOrDefault("X-Amz-Signature")
  valid_607809 = validateParameter(valid_607809, JString, required = false,
                                 default = nil)
  if valid_607809 != nil:
    section.add "X-Amz-Signature", valid_607809
  var valid_607810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607810 = validateParameter(valid_607810, JString, required = false,
                                 default = nil)
  if valid_607810 != nil:
    section.add "X-Amz-Content-Sha256", valid_607810
  var valid_607811 = header.getOrDefault("X-Amz-Date")
  valid_607811 = validateParameter(valid_607811, JString, required = false,
                                 default = nil)
  if valid_607811 != nil:
    section.add "X-Amz-Date", valid_607811
  var valid_607812 = header.getOrDefault("X-Amz-Credential")
  valid_607812 = validateParameter(valid_607812, JString, required = false,
                                 default = nil)
  if valid_607812 != nil:
    section.add "X-Amz-Credential", valid_607812
  var valid_607813 = header.getOrDefault("X-Amz-Security-Token")
  valid_607813 = validateParameter(valid_607813, JString, required = false,
                                 default = nil)
  if valid_607813 != nil:
    section.add "X-Amz-Security-Token", valid_607813
  var valid_607814 = header.getOrDefault("X-Amz-Algorithm")
  valid_607814 = validateParameter(valid_607814, JString, required = false,
                                 default = nil)
  if valid_607814 != nil:
    section.add "X-Amz-Algorithm", valid_607814
  var valid_607815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607815 = validateParameter(valid_607815, JString, required = false,
                                 default = nil)
  if valid_607815 != nil:
    section.add "X-Amz-SignedHeaders", valid_607815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607816: Call_GetPromoteReadReplica_607801; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607816.validator(path, query, header, formData, body)
  let scheme = call_607816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607816.url(scheme.get, call_607816.host, call_607816.base,
                         call_607816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607816, url, valid)

proc call*(call_607817: Call_GetPromoteReadReplica_607801;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2013-01-10";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_607818 = newJObject()
  add(query_607818, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607818, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_607818, "Action", newJString(Action))
  add(query_607818, "Version", newJString(Version))
  add(query_607818, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_607817.call(nil, query_607818, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_607801(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_607802, base: "/",
    url: url_GetPromoteReadReplica_607803, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_607856 = ref object of OpenApiRestCall_605573
proc url_PostPurchaseReservedDBInstancesOffering_607858(protocol: Scheme;
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

proc validate_PostPurchaseReservedDBInstancesOffering_607857(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607859 = query.getOrDefault("Action")
  valid_607859 = validateParameter(valid_607859, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_607859 != nil:
    section.add "Action", valid_607859
  var valid_607860 = query.getOrDefault("Version")
  valid_607860 = validateParameter(valid_607860, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607860 != nil:
    section.add "Version", valid_607860
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607861 = header.getOrDefault("X-Amz-Signature")
  valid_607861 = validateParameter(valid_607861, JString, required = false,
                                 default = nil)
  if valid_607861 != nil:
    section.add "X-Amz-Signature", valid_607861
  var valid_607862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607862 = validateParameter(valid_607862, JString, required = false,
                                 default = nil)
  if valid_607862 != nil:
    section.add "X-Amz-Content-Sha256", valid_607862
  var valid_607863 = header.getOrDefault("X-Amz-Date")
  valid_607863 = validateParameter(valid_607863, JString, required = false,
                                 default = nil)
  if valid_607863 != nil:
    section.add "X-Amz-Date", valid_607863
  var valid_607864 = header.getOrDefault("X-Amz-Credential")
  valid_607864 = validateParameter(valid_607864, JString, required = false,
                                 default = nil)
  if valid_607864 != nil:
    section.add "X-Amz-Credential", valid_607864
  var valid_607865 = header.getOrDefault("X-Amz-Security-Token")
  valid_607865 = validateParameter(valid_607865, JString, required = false,
                                 default = nil)
  if valid_607865 != nil:
    section.add "X-Amz-Security-Token", valid_607865
  var valid_607866 = header.getOrDefault("X-Amz-Algorithm")
  valid_607866 = validateParameter(valid_607866, JString, required = false,
                                 default = nil)
  if valid_607866 != nil:
    section.add "X-Amz-Algorithm", valid_607866
  var valid_607867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607867 = validateParameter(valid_607867, JString, required = false,
                                 default = nil)
  if valid_607867 != nil:
    section.add "X-Amz-SignedHeaders", valid_607867
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_607868 = formData.getOrDefault("ReservedDBInstanceId")
  valid_607868 = validateParameter(valid_607868, JString, required = false,
                                 default = nil)
  if valid_607868 != nil:
    section.add "ReservedDBInstanceId", valid_607868
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_607869 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607869 = validateParameter(valid_607869, JString, required = true,
                                 default = nil)
  if valid_607869 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607869
  var valid_607870 = formData.getOrDefault("DBInstanceCount")
  valid_607870 = validateParameter(valid_607870, JInt, required = false, default = nil)
  if valid_607870 != nil:
    section.add "DBInstanceCount", valid_607870
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607871: Call_PostPurchaseReservedDBInstancesOffering_607856;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607871.validator(path, query, header, formData, body)
  let scheme = call_607871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607871.url(scheme.get, call_607871.host, call_607871.base,
                         call_607871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607871, url, valid)

proc call*(call_607872: Call_PostPurchaseReservedDBInstancesOffering_607856;
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
  var query_607873 = newJObject()
  var formData_607874 = newJObject()
  add(formData_607874, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_607873, "Action", newJString(Action))
  add(formData_607874, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607873, "Version", newJString(Version))
  add(formData_607874, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_607872.call(nil, query_607873, nil, formData_607874, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_607856(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_607857, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_607858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_607838 = ref object of OpenApiRestCall_605573
proc url_GetPurchaseReservedDBInstancesOffering_607840(protocol: Scheme;
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

proc validate_GetPurchaseReservedDBInstancesOffering_607839(path: JsonNode;
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
  var valid_607841 = query.getOrDefault("DBInstanceCount")
  valid_607841 = validateParameter(valid_607841, JInt, required = false, default = nil)
  if valid_607841 != nil:
    section.add "DBInstanceCount", valid_607841
  var valid_607842 = query.getOrDefault("ReservedDBInstanceId")
  valid_607842 = validateParameter(valid_607842, JString, required = false,
                                 default = nil)
  if valid_607842 != nil:
    section.add "ReservedDBInstanceId", valid_607842
  var valid_607843 = query.getOrDefault("Action")
  valid_607843 = validateParameter(valid_607843, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_607843 != nil:
    section.add "Action", valid_607843
  var valid_607844 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607844 = validateParameter(valid_607844, JString, required = true,
                                 default = nil)
  if valid_607844 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607844
  var valid_607845 = query.getOrDefault("Version")
  valid_607845 = validateParameter(valid_607845, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607845 != nil:
    section.add "Version", valid_607845
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607846 = header.getOrDefault("X-Amz-Signature")
  valid_607846 = validateParameter(valid_607846, JString, required = false,
                                 default = nil)
  if valid_607846 != nil:
    section.add "X-Amz-Signature", valid_607846
  var valid_607847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607847 = validateParameter(valid_607847, JString, required = false,
                                 default = nil)
  if valid_607847 != nil:
    section.add "X-Amz-Content-Sha256", valid_607847
  var valid_607848 = header.getOrDefault("X-Amz-Date")
  valid_607848 = validateParameter(valid_607848, JString, required = false,
                                 default = nil)
  if valid_607848 != nil:
    section.add "X-Amz-Date", valid_607848
  var valid_607849 = header.getOrDefault("X-Amz-Credential")
  valid_607849 = validateParameter(valid_607849, JString, required = false,
                                 default = nil)
  if valid_607849 != nil:
    section.add "X-Amz-Credential", valid_607849
  var valid_607850 = header.getOrDefault("X-Amz-Security-Token")
  valid_607850 = validateParameter(valid_607850, JString, required = false,
                                 default = nil)
  if valid_607850 != nil:
    section.add "X-Amz-Security-Token", valid_607850
  var valid_607851 = header.getOrDefault("X-Amz-Algorithm")
  valid_607851 = validateParameter(valid_607851, JString, required = false,
                                 default = nil)
  if valid_607851 != nil:
    section.add "X-Amz-Algorithm", valid_607851
  var valid_607852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607852 = validateParameter(valid_607852, JString, required = false,
                                 default = nil)
  if valid_607852 != nil:
    section.add "X-Amz-SignedHeaders", valid_607852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607853: Call_GetPurchaseReservedDBInstancesOffering_607838;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607853.validator(path, query, header, formData, body)
  let scheme = call_607853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607853.url(scheme.get, call_607853.host, call_607853.base,
                         call_607853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607853, url, valid)

proc call*(call_607854: Call_GetPurchaseReservedDBInstancesOffering_607838;
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
  var query_607855 = newJObject()
  add(query_607855, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_607855, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_607855, "Action", newJString(Action))
  add(query_607855, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607855, "Version", newJString(Version))
  result = call_607854.call(nil, query_607855, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_607838(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_607839, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_607840,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_607892 = ref object of OpenApiRestCall_605573
proc url_PostRebootDBInstance_607894(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebootDBInstance_607893(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607895 = query.getOrDefault("Action")
  valid_607895 = validateParameter(valid_607895, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_607895 != nil:
    section.add "Action", valid_607895
  var valid_607896 = query.getOrDefault("Version")
  valid_607896 = validateParameter(valid_607896, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607896 != nil:
    section.add "Version", valid_607896
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607897 = header.getOrDefault("X-Amz-Signature")
  valid_607897 = validateParameter(valid_607897, JString, required = false,
                                 default = nil)
  if valid_607897 != nil:
    section.add "X-Amz-Signature", valid_607897
  var valid_607898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607898 = validateParameter(valid_607898, JString, required = false,
                                 default = nil)
  if valid_607898 != nil:
    section.add "X-Amz-Content-Sha256", valid_607898
  var valid_607899 = header.getOrDefault("X-Amz-Date")
  valid_607899 = validateParameter(valid_607899, JString, required = false,
                                 default = nil)
  if valid_607899 != nil:
    section.add "X-Amz-Date", valid_607899
  var valid_607900 = header.getOrDefault("X-Amz-Credential")
  valid_607900 = validateParameter(valid_607900, JString, required = false,
                                 default = nil)
  if valid_607900 != nil:
    section.add "X-Amz-Credential", valid_607900
  var valid_607901 = header.getOrDefault("X-Amz-Security-Token")
  valid_607901 = validateParameter(valid_607901, JString, required = false,
                                 default = nil)
  if valid_607901 != nil:
    section.add "X-Amz-Security-Token", valid_607901
  var valid_607902 = header.getOrDefault("X-Amz-Algorithm")
  valid_607902 = validateParameter(valid_607902, JString, required = false,
                                 default = nil)
  if valid_607902 != nil:
    section.add "X-Amz-Algorithm", valid_607902
  var valid_607903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607903 = validateParameter(valid_607903, JString, required = false,
                                 default = nil)
  if valid_607903 != nil:
    section.add "X-Amz-SignedHeaders", valid_607903
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_607904 = formData.getOrDefault("ForceFailover")
  valid_607904 = validateParameter(valid_607904, JBool, required = false, default = nil)
  if valid_607904 != nil:
    section.add "ForceFailover", valid_607904
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607905 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607905 = validateParameter(valid_607905, JString, required = true,
                                 default = nil)
  if valid_607905 != nil:
    section.add "DBInstanceIdentifier", valid_607905
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607906: Call_PostRebootDBInstance_607892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607906.validator(path, query, header, formData, body)
  let scheme = call_607906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607906.url(scheme.get, call_607906.host, call_607906.base,
                         call_607906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607906, url, valid)

proc call*(call_607907: Call_PostRebootDBInstance_607892;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-01-10"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607908 = newJObject()
  var formData_607909 = newJObject()
  add(formData_607909, "ForceFailover", newJBool(ForceFailover))
  add(formData_607909, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607908, "Action", newJString(Action))
  add(query_607908, "Version", newJString(Version))
  result = call_607907.call(nil, query_607908, nil, formData_607909, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_607892(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_607893, base: "/",
    url: url_PostRebootDBInstance_607894, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_607875 = ref object of OpenApiRestCall_605573
proc url_GetRebootDBInstance_607877(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebootDBInstance_607876(path: JsonNode; query: JsonNode;
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
  var valid_607878 = query.getOrDefault("ForceFailover")
  valid_607878 = validateParameter(valid_607878, JBool, required = false, default = nil)
  if valid_607878 != nil:
    section.add "ForceFailover", valid_607878
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607879 = query.getOrDefault("DBInstanceIdentifier")
  valid_607879 = validateParameter(valid_607879, JString, required = true,
                                 default = nil)
  if valid_607879 != nil:
    section.add "DBInstanceIdentifier", valid_607879
  var valid_607880 = query.getOrDefault("Action")
  valid_607880 = validateParameter(valid_607880, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_607880 != nil:
    section.add "Action", valid_607880
  var valid_607881 = query.getOrDefault("Version")
  valid_607881 = validateParameter(valid_607881, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607881 != nil:
    section.add "Version", valid_607881
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607882 = header.getOrDefault("X-Amz-Signature")
  valid_607882 = validateParameter(valid_607882, JString, required = false,
                                 default = nil)
  if valid_607882 != nil:
    section.add "X-Amz-Signature", valid_607882
  var valid_607883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607883 = validateParameter(valid_607883, JString, required = false,
                                 default = nil)
  if valid_607883 != nil:
    section.add "X-Amz-Content-Sha256", valid_607883
  var valid_607884 = header.getOrDefault("X-Amz-Date")
  valid_607884 = validateParameter(valid_607884, JString, required = false,
                                 default = nil)
  if valid_607884 != nil:
    section.add "X-Amz-Date", valid_607884
  var valid_607885 = header.getOrDefault("X-Amz-Credential")
  valid_607885 = validateParameter(valid_607885, JString, required = false,
                                 default = nil)
  if valid_607885 != nil:
    section.add "X-Amz-Credential", valid_607885
  var valid_607886 = header.getOrDefault("X-Amz-Security-Token")
  valid_607886 = validateParameter(valid_607886, JString, required = false,
                                 default = nil)
  if valid_607886 != nil:
    section.add "X-Amz-Security-Token", valid_607886
  var valid_607887 = header.getOrDefault("X-Amz-Algorithm")
  valid_607887 = validateParameter(valid_607887, JString, required = false,
                                 default = nil)
  if valid_607887 != nil:
    section.add "X-Amz-Algorithm", valid_607887
  var valid_607888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607888 = validateParameter(valid_607888, JString, required = false,
                                 default = nil)
  if valid_607888 != nil:
    section.add "X-Amz-SignedHeaders", valid_607888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607889: Call_GetRebootDBInstance_607875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607889.validator(path, query, header, formData, body)
  let scheme = call_607889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607889.url(scheme.get, call_607889.host, call_607889.base,
                         call_607889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607889, url, valid)

proc call*(call_607890: Call_GetRebootDBInstance_607875;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-01-10"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607891 = newJObject()
  add(query_607891, "ForceFailover", newJBool(ForceFailover))
  add(query_607891, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607891, "Action", newJString(Action))
  add(query_607891, "Version", newJString(Version))
  result = call_607890.call(nil, query_607891, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_607875(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_607876, base: "/",
    url: url_GetRebootDBInstance_607877, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_607927 = ref object of OpenApiRestCall_605573
proc url_PostRemoveSourceIdentifierFromSubscription_607929(protocol: Scheme;
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

proc validate_PostRemoveSourceIdentifierFromSubscription_607928(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607930 = query.getOrDefault("Action")
  valid_607930 = validateParameter(valid_607930, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_607930 != nil:
    section.add "Action", valid_607930
  var valid_607931 = query.getOrDefault("Version")
  valid_607931 = validateParameter(valid_607931, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607931 != nil:
    section.add "Version", valid_607931
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607932 = header.getOrDefault("X-Amz-Signature")
  valid_607932 = validateParameter(valid_607932, JString, required = false,
                                 default = nil)
  if valid_607932 != nil:
    section.add "X-Amz-Signature", valid_607932
  var valid_607933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607933 = validateParameter(valid_607933, JString, required = false,
                                 default = nil)
  if valid_607933 != nil:
    section.add "X-Amz-Content-Sha256", valid_607933
  var valid_607934 = header.getOrDefault("X-Amz-Date")
  valid_607934 = validateParameter(valid_607934, JString, required = false,
                                 default = nil)
  if valid_607934 != nil:
    section.add "X-Amz-Date", valid_607934
  var valid_607935 = header.getOrDefault("X-Amz-Credential")
  valid_607935 = validateParameter(valid_607935, JString, required = false,
                                 default = nil)
  if valid_607935 != nil:
    section.add "X-Amz-Credential", valid_607935
  var valid_607936 = header.getOrDefault("X-Amz-Security-Token")
  valid_607936 = validateParameter(valid_607936, JString, required = false,
                                 default = nil)
  if valid_607936 != nil:
    section.add "X-Amz-Security-Token", valid_607936
  var valid_607937 = header.getOrDefault("X-Amz-Algorithm")
  valid_607937 = validateParameter(valid_607937, JString, required = false,
                                 default = nil)
  if valid_607937 != nil:
    section.add "X-Amz-Algorithm", valid_607937
  var valid_607938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607938 = validateParameter(valid_607938, JString, required = false,
                                 default = nil)
  if valid_607938 != nil:
    section.add "X-Amz-SignedHeaders", valid_607938
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_607939 = formData.getOrDefault("SubscriptionName")
  valid_607939 = validateParameter(valid_607939, JString, required = true,
                                 default = nil)
  if valid_607939 != nil:
    section.add "SubscriptionName", valid_607939
  var valid_607940 = formData.getOrDefault("SourceIdentifier")
  valid_607940 = validateParameter(valid_607940, JString, required = true,
                                 default = nil)
  if valid_607940 != nil:
    section.add "SourceIdentifier", valid_607940
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607941: Call_PostRemoveSourceIdentifierFromSubscription_607927;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607941.validator(path, query, header, formData, body)
  let scheme = call_607941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607941.url(scheme.get, call_607941.host, call_607941.base,
                         call_607941.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607941, url, valid)

proc call*(call_607942: Call_PostRemoveSourceIdentifierFromSubscription_607927;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607943 = newJObject()
  var formData_607944 = newJObject()
  add(formData_607944, "SubscriptionName", newJString(SubscriptionName))
  add(formData_607944, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_607943, "Action", newJString(Action))
  add(query_607943, "Version", newJString(Version))
  result = call_607942.call(nil, query_607943, nil, formData_607944, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_607927(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_607928,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_607929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_607910 = ref object of OpenApiRestCall_605573
proc url_GetRemoveSourceIdentifierFromSubscription_607912(protocol: Scheme;
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

proc validate_GetRemoveSourceIdentifierFromSubscription_607911(path: JsonNode;
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
  var valid_607913 = query.getOrDefault("SourceIdentifier")
  valid_607913 = validateParameter(valid_607913, JString, required = true,
                                 default = nil)
  if valid_607913 != nil:
    section.add "SourceIdentifier", valid_607913
  var valid_607914 = query.getOrDefault("SubscriptionName")
  valid_607914 = validateParameter(valid_607914, JString, required = true,
                                 default = nil)
  if valid_607914 != nil:
    section.add "SubscriptionName", valid_607914
  var valid_607915 = query.getOrDefault("Action")
  valid_607915 = validateParameter(valid_607915, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_607915 != nil:
    section.add "Action", valid_607915
  var valid_607916 = query.getOrDefault("Version")
  valid_607916 = validateParameter(valid_607916, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607916 != nil:
    section.add "Version", valid_607916
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607917 = header.getOrDefault("X-Amz-Signature")
  valid_607917 = validateParameter(valid_607917, JString, required = false,
                                 default = nil)
  if valid_607917 != nil:
    section.add "X-Amz-Signature", valid_607917
  var valid_607918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607918 = validateParameter(valid_607918, JString, required = false,
                                 default = nil)
  if valid_607918 != nil:
    section.add "X-Amz-Content-Sha256", valid_607918
  var valid_607919 = header.getOrDefault("X-Amz-Date")
  valid_607919 = validateParameter(valid_607919, JString, required = false,
                                 default = nil)
  if valid_607919 != nil:
    section.add "X-Amz-Date", valid_607919
  var valid_607920 = header.getOrDefault("X-Amz-Credential")
  valid_607920 = validateParameter(valid_607920, JString, required = false,
                                 default = nil)
  if valid_607920 != nil:
    section.add "X-Amz-Credential", valid_607920
  var valid_607921 = header.getOrDefault("X-Amz-Security-Token")
  valid_607921 = validateParameter(valid_607921, JString, required = false,
                                 default = nil)
  if valid_607921 != nil:
    section.add "X-Amz-Security-Token", valid_607921
  var valid_607922 = header.getOrDefault("X-Amz-Algorithm")
  valid_607922 = validateParameter(valid_607922, JString, required = false,
                                 default = nil)
  if valid_607922 != nil:
    section.add "X-Amz-Algorithm", valid_607922
  var valid_607923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607923 = validateParameter(valid_607923, JString, required = false,
                                 default = nil)
  if valid_607923 != nil:
    section.add "X-Amz-SignedHeaders", valid_607923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607924: Call_GetRemoveSourceIdentifierFromSubscription_607910;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607924.validator(path, query, header, formData, body)
  let scheme = call_607924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607924.url(scheme.get, call_607924.host, call_607924.base,
                         call_607924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607924, url, valid)

proc call*(call_607925: Call_GetRemoveSourceIdentifierFromSubscription_607910;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607926 = newJObject()
  add(query_607926, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_607926, "SubscriptionName", newJString(SubscriptionName))
  add(query_607926, "Action", newJString(Action))
  add(query_607926, "Version", newJString(Version))
  result = call_607925.call(nil, query_607926, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_607910(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_607911,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_607912,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_607962 = ref object of OpenApiRestCall_605573
proc url_PostRemoveTagsFromResource_607964(protocol: Scheme; host: string;
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

proc validate_PostRemoveTagsFromResource_607963(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607965 = query.getOrDefault("Action")
  valid_607965 = validateParameter(valid_607965, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_607965 != nil:
    section.add "Action", valid_607965
  var valid_607966 = query.getOrDefault("Version")
  valid_607966 = validateParameter(valid_607966, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607966 != nil:
    section.add "Version", valid_607966
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607967 = header.getOrDefault("X-Amz-Signature")
  valid_607967 = validateParameter(valid_607967, JString, required = false,
                                 default = nil)
  if valid_607967 != nil:
    section.add "X-Amz-Signature", valid_607967
  var valid_607968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607968 = validateParameter(valid_607968, JString, required = false,
                                 default = nil)
  if valid_607968 != nil:
    section.add "X-Amz-Content-Sha256", valid_607968
  var valid_607969 = header.getOrDefault("X-Amz-Date")
  valid_607969 = validateParameter(valid_607969, JString, required = false,
                                 default = nil)
  if valid_607969 != nil:
    section.add "X-Amz-Date", valid_607969
  var valid_607970 = header.getOrDefault("X-Amz-Credential")
  valid_607970 = validateParameter(valid_607970, JString, required = false,
                                 default = nil)
  if valid_607970 != nil:
    section.add "X-Amz-Credential", valid_607970
  var valid_607971 = header.getOrDefault("X-Amz-Security-Token")
  valid_607971 = validateParameter(valid_607971, JString, required = false,
                                 default = nil)
  if valid_607971 != nil:
    section.add "X-Amz-Security-Token", valid_607971
  var valid_607972 = header.getOrDefault("X-Amz-Algorithm")
  valid_607972 = validateParameter(valid_607972, JString, required = false,
                                 default = nil)
  if valid_607972 != nil:
    section.add "X-Amz-Algorithm", valid_607972
  var valid_607973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607973 = validateParameter(valid_607973, JString, required = false,
                                 default = nil)
  if valid_607973 != nil:
    section.add "X-Amz-SignedHeaders", valid_607973
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_607974 = formData.getOrDefault("TagKeys")
  valid_607974 = validateParameter(valid_607974, JArray, required = true, default = nil)
  if valid_607974 != nil:
    section.add "TagKeys", valid_607974
  var valid_607975 = formData.getOrDefault("ResourceName")
  valid_607975 = validateParameter(valid_607975, JString, required = true,
                                 default = nil)
  if valid_607975 != nil:
    section.add "ResourceName", valid_607975
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607976: Call_PostRemoveTagsFromResource_607962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607976.validator(path, query, header, formData, body)
  let scheme = call_607976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607976.url(scheme.get, call_607976.host, call_607976.base,
                         call_607976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607976, url, valid)

proc call*(call_607977: Call_PostRemoveTagsFromResource_607962; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_607978 = newJObject()
  var formData_607979 = newJObject()
  if TagKeys != nil:
    formData_607979.add "TagKeys", TagKeys
  add(query_607978, "Action", newJString(Action))
  add(query_607978, "Version", newJString(Version))
  add(formData_607979, "ResourceName", newJString(ResourceName))
  result = call_607977.call(nil, query_607978, nil, formData_607979, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_607962(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_607963, base: "/",
    url: url_PostRemoveTagsFromResource_607964,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_607945 = ref object of OpenApiRestCall_605573
proc url_GetRemoveTagsFromResource_607947(protocol: Scheme; host: string;
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

proc validate_GetRemoveTagsFromResource_607946(path: JsonNode; query: JsonNode;
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
  var valid_607948 = query.getOrDefault("ResourceName")
  valid_607948 = validateParameter(valid_607948, JString, required = true,
                                 default = nil)
  if valid_607948 != nil:
    section.add "ResourceName", valid_607948
  var valid_607949 = query.getOrDefault("TagKeys")
  valid_607949 = validateParameter(valid_607949, JArray, required = true, default = nil)
  if valid_607949 != nil:
    section.add "TagKeys", valid_607949
  var valid_607950 = query.getOrDefault("Action")
  valid_607950 = validateParameter(valid_607950, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_607950 != nil:
    section.add "Action", valid_607950
  var valid_607951 = query.getOrDefault("Version")
  valid_607951 = validateParameter(valid_607951, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607951 != nil:
    section.add "Version", valid_607951
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607952 = header.getOrDefault("X-Amz-Signature")
  valid_607952 = validateParameter(valid_607952, JString, required = false,
                                 default = nil)
  if valid_607952 != nil:
    section.add "X-Amz-Signature", valid_607952
  var valid_607953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607953 = validateParameter(valid_607953, JString, required = false,
                                 default = nil)
  if valid_607953 != nil:
    section.add "X-Amz-Content-Sha256", valid_607953
  var valid_607954 = header.getOrDefault("X-Amz-Date")
  valid_607954 = validateParameter(valid_607954, JString, required = false,
                                 default = nil)
  if valid_607954 != nil:
    section.add "X-Amz-Date", valid_607954
  var valid_607955 = header.getOrDefault("X-Amz-Credential")
  valid_607955 = validateParameter(valid_607955, JString, required = false,
                                 default = nil)
  if valid_607955 != nil:
    section.add "X-Amz-Credential", valid_607955
  var valid_607956 = header.getOrDefault("X-Amz-Security-Token")
  valid_607956 = validateParameter(valid_607956, JString, required = false,
                                 default = nil)
  if valid_607956 != nil:
    section.add "X-Amz-Security-Token", valid_607956
  var valid_607957 = header.getOrDefault("X-Amz-Algorithm")
  valid_607957 = validateParameter(valid_607957, JString, required = false,
                                 default = nil)
  if valid_607957 != nil:
    section.add "X-Amz-Algorithm", valid_607957
  var valid_607958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607958 = validateParameter(valid_607958, JString, required = false,
                                 default = nil)
  if valid_607958 != nil:
    section.add "X-Amz-SignedHeaders", valid_607958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607959: Call_GetRemoveTagsFromResource_607945; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607959.validator(path, query, header, formData, body)
  let scheme = call_607959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607959.url(scheme.get, call_607959.host, call_607959.base,
                         call_607959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607959, url, valid)

proc call*(call_607960: Call_GetRemoveTagsFromResource_607945;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-01-10"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607961 = newJObject()
  add(query_607961, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_607961.add "TagKeys", TagKeys
  add(query_607961, "Action", newJString(Action))
  add(query_607961, "Version", newJString(Version))
  result = call_607960.call(nil, query_607961, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_607945(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_607946, base: "/",
    url: url_GetRemoveTagsFromResource_607947,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_607998 = ref object of OpenApiRestCall_605573
proc url_PostResetDBParameterGroup_608000(protocol: Scheme; host: string;
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

proc validate_PostResetDBParameterGroup_607999(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608001 = query.getOrDefault("Action")
  valid_608001 = validateParameter(valid_608001, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_608001 != nil:
    section.add "Action", valid_608001
  var valid_608002 = query.getOrDefault("Version")
  valid_608002 = validateParameter(valid_608002, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_608002 != nil:
    section.add "Version", valid_608002
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608003 = header.getOrDefault("X-Amz-Signature")
  valid_608003 = validateParameter(valid_608003, JString, required = false,
                                 default = nil)
  if valid_608003 != nil:
    section.add "X-Amz-Signature", valid_608003
  var valid_608004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608004 = validateParameter(valid_608004, JString, required = false,
                                 default = nil)
  if valid_608004 != nil:
    section.add "X-Amz-Content-Sha256", valid_608004
  var valid_608005 = header.getOrDefault("X-Amz-Date")
  valid_608005 = validateParameter(valid_608005, JString, required = false,
                                 default = nil)
  if valid_608005 != nil:
    section.add "X-Amz-Date", valid_608005
  var valid_608006 = header.getOrDefault("X-Amz-Credential")
  valid_608006 = validateParameter(valid_608006, JString, required = false,
                                 default = nil)
  if valid_608006 != nil:
    section.add "X-Amz-Credential", valid_608006
  var valid_608007 = header.getOrDefault("X-Amz-Security-Token")
  valid_608007 = validateParameter(valid_608007, JString, required = false,
                                 default = nil)
  if valid_608007 != nil:
    section.add "X-Amz-Security-Token", valid_608007
  var valid_608008 = header.getOrDefault("X-Amz-Algorithm")
  valid_608008 = validateParameter(valid_608008, JString, required = false,
                                 default = nil)
  if valid_608008 != nil:
    section.add "X-Amz-Algorithm", valid_608008
  var valid_608009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608009 = validateParameter(valid_608009, JString, required = false,
                                 default = nil)
  if valid_608009 != nil:
    section.add "X-Amz-SignedHeaders", valid_608009
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_608010 = formData.getOrDefault("ResetAllParameters")
  valid_608010 = validateParameter(valid_608010, JBool, required = false, default = nil)
  if valid_608010 != nil:
    section.add "ResetAllParameters", valid_608010
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_608011 = formData.getOrDefault("DBParameterGroupName")
  valid_608011 = validateParameter(valid_608011, JString, required = true,
                                 default = nil)
  if valid_608011 != nil:
    section.add "DBParameterGroupName", valid_608011
  var valid_608012 = formData.getOrDefault("Parameters")
  valid_608012 = validateParameter(valid_608012, JArray, required = false,
                                 default = nil)
  if valid_608012 != nil:
    section.add "Parameters", valid_608012
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608013: Call_PostResetDBParameterGroup_607998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608013.validator(path, query, header, formData, body)
  let scheme = call_608013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608013.url(scheme.get, call_608013.host, call_608013.base,
                         call_608013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608013, url, valid)

proc call*(call_608014: Call_PostResetDBParameterGroup_607998;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2013-01-10"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_608015 = newJObject()
  var formData_608016 = newJObject()
  add(formData_608016, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_608016, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_608015, "Action", newJString(Action))
  if Parameters != nil:
    formData_608016.add "Parameters", Parameters
  add(query_608015, "Version", newJString(Version))
  result = call_608014.call(nil, query_608015, nil, formData_608016, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_607998(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_607999, base: "/",
    url: url_PostResetDBParameterGroup_608000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_607980 = ref object of OpenApiRestCall_605573
proc url_GetResetDBParameterGroup_607982(protocol: Scheme; host: string;
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

proc validate_GetResetDBParameterGroup_607981(path: JsonNode; query: JsonNode;
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
  var valid_607983 = query.getOrDefault("DBParameterGroupName")
  valid_607983 = validateParameter(valid_607983, JString, required = true,
                                 default = nil)
  if valid_607983 != nil:
    section.add "DBParameterGroupName", valid_607983
  var valid_607984 = query.getOrDefault("Parameters")
  valid_607984 = validateParameter(valid_607984, JArray, required = false,
                                 default = nil)
  if valid_607984 != nil:
    section.add "Parameters", valid_607984
  var valid_607985 = query.getOrDefault("ResetAllParameters")
  valid_607985 = validateParameter(valid_607985, JBool, required = false, default = nil)
  if valid_607985 != nil:
    section.add "ResetAllParameters", valid_607985
  var valid_607986 = query.getOrDefault("Action")
  valid_607986 = validateParameter(valid_607986, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_607986 != nil:
    section.add "Action", valid_607986
  var valid_607987 = query.getOrDefault("Version")
  valid_607987 = validateParameter(valid_607987, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_607987 != nil:
    section.add "Version", valid_607987
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607988 = header.getOrDefault("X-Amz-Signature")
  valid_607988 = validateParameter(valid_607988, JString, required = false,
                                 default = nil)
  if valid_607988 != nil:
    section.add "X-Amz-Signature", valid_607988
  var valid_607989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607989 = validateParameter(valid_607989, JString, required = false,
                                 default = nil)
  if valid_607989 != nil:
    section.add "X-Amz-Content-Sha256", valid_607989
  var valid_607990 = header.getOrDefault("X-Amz-Date")
  valid_607990 = validateParameter(valid_607990, JString, required = false,
                                 default = nil)
  if valid_607990 != nil:
    section.add "X-Amz-Date", valid_607990
  var valid_607991 = header.getOrDefault("X-Amz-Credential")
  valid_607991 = validateParameter(valid_607991, JString, required = false,
                                 default = nil)
  if valid_607991 != nil:
    section.add "X-Amz-Credential", valid_607991
  var valid_607992 = header.getOrDefault("X-Amz-Security-Token")
  valid_607992 = validateParameter(valid_607992, JString, required = false,
                                 default = nil)
  if valid_607992 != nil:
    section.add "X-Amz-Security-Token", valid_607992
  var valid_607993 = header.getOrDefault("X-Amz-Algorithm")
  valid_607993 = validateParameter(valid_607993, JString, required = false,
                                 default = nil)
  if valid_607993 != nil:
    section.add "X-Amz-Algorithm", valid_607993
  var valid_607994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607994 = validateParameter(valid_607994, JString, required = false,
                                 default = nil)
  if valid_607994 != nil:
    section.add "X-Amz-SignedHeaders", valid_607994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607995: Call_GetResetDBParameterGroup_607980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607995.validator(path, query, header, formData, body)
  let scheme = call_607995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607995.url(scheme.get, call_607995.host, call_607995.base,
                         call_607995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607995, url, valid)

proc call*(call_607996: Call_GetResetDBParameterGroup_607980;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607997 = newJObject()
  add(query_607997, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_607997.add "Parameters", Parameters
  add(query_607997, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_607997, "Action", newJString(Action))
  add(query_607997, "Version", newJString(Version))
  result = call_607996.call(nil, query_607997, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_607980(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_607981, base: "/",
    url: url_GetResetDBParameterGroup_607982, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_608046 = ref object of OpenApiRestCall_605573
proc url_PostRestoreDBInstanceFromDBSnapshot_608048(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceFromDBSnapshot_608047(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608049 = query.getOrDefault("Action")
  valid_608049 = validateParameter(valid_608049, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_608049 != nil:
    section.add "Action", valid_608049
  var valid_608050 = query.getOrDefault("Version")
  valid_608050 = validateParameter(valid_608050, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_608050 != nil:
    section.add "Version", valid_608050
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608051 = header.getOrDefault("X-Amz-Signature")
  valid_608051 = validateParameter(valid_608051, JString, required = false,
                                 default = nil)
  if valid_608051 != nil:
    section.add "X-Amz-Signature", valid_608051
  var valid_608052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608052 = validateParameter(valid_608052, JString, required = false,
                                 default = nil)
  if valid_608052 != nil:
    section.add "X-Amz-Content-Sha256", valid_608052
  var valid_608053 = header.getOrDefault("X-Amz-Date")
  valid_608053 = validateParameter(valid_608053, JString, required = false,
                                 default = nil)
  if valid_608053 != nil:
    section.add "X-Amz-Date", valid_608053
  var valid_608054 = header.getOrDefault("X-Amz-Credential")
  valid_608054 = validateParameter(valid_608054, JString, required = false,
                                 default = nil)
  if valid_608054 != nil:
    section.add "X-Amz-Credential", valid_608054
  var valid_608055 = header.getOrDefault("X-Amz-Security-Token")
  valid_608055 = validateParameter(valid_608055, JString, required = false,
                                 default = nil)
  if valid_608055 != nil:
    section.add "X-Amz-Security-Token", valid_608055
  var valid_608056 = header.getOrDefault("X-Amz-Algorithm")
  valid_608056 = validateParameter(valid_608056, JString, required = false,
                                 default = nil)
  if valid_608056 != nil:
    section.add "X-Amz-Algorithm", valid_608056
  var valid_608057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608057 = validateParameter(valid_608057, JString, required = false,
                                 default = nil)
  if valid_608057 != nil:
    section.add "X-Amz-SignedHeaders", valid_608057
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
  var valid_608058 = formData.getOrDefault("Port")
  valid_608058 = validateParameter(valid_608058, JInt, required = false, default = nil)
  if valid_608058 != nil:
    section.add "Port", valid_608058
  var valid_608059 = formData.getOrDefault("DBInstanceClass")
  valid_608059 = validateParameter(valid_608059, JString, required = false,
                                 default = nil)
  if valid_608059 != nil:
    section.add "DBInstanceClass", valid_608059
  var valid_608060 = formData.getOrDefault("MultiAZ")
  valid_608060 = validateParameter(valid_608060, JBool, required = false, default = nil)
  if valid_608060 != nil:
    section.add "MultiAZ", valid_608060
  var valid_608061 = formData.getOrDefault("AvailabilityZone")
  valid_608061 = validateParameter(valid_608061, JString, required = false,
                                 default = nil)
  if valid_608061 != nil:
    section.add "AvailabilityZone", valid_608061
  var valid_608062 = formData.getOrDefault("Engine")
  valid_608062 = validateParameter(valid_608062, JString, required = false,
                                 default = nil)
  if valid_608062 != nil:
    section.add "Engine", valid_608062
  var valid_608063 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_608063 = validateParameter(valid_608063, JBool, required = false, default = nil)
  if valid_608063 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608063
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_608064 = formData.getOrDefault("DBInstanceIdentifier")
  valid_608064 = validateParameter(valid_608064, JString, required = true,
                                 default = nil)
  if valid_608064 != nil:
    section.add "DBInstanceIdentifier", valid_608064
  var valid_608065 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_608065 = validateParameter(valid_608065, JString, required = true,
                                 default = nil)
  if valid_608065 != nil:
    section.add "DBSnapshotIdentifier", valid_608065
  var valid_608066 = formData.getOrDefault("DBName")
  valid_608066 = validateParameter(valid_608066, JString, required = false,
                                 default = nil)
  if valid_608066 != nil:
    section.add "DBName", valid_608066
  var valid_608067 = formData.getOrDefault("Iops")
  valid_608067 = validateParameter(valid_608067, JInt, required = false, default = nil)
  if valid_608067 != nil:
    section.add "Iops", valid_608067
  var valid_608068 = formData.getOrDefault("PubliclyAccessible")
  valid_608068 = validateParameter(valid_608068, JBool, required = false, default = nil)
  if valid_608068 != nil:
    section.add "PubliclyAccessible", valid_608068
  var valid_608069 = formData.getOrDefault("LicenseModel")
  valid_608069 = validateParameter(valid_608069, JString, required = false,
                                 default = nil)
  if valid_608069 != nil:
    section.add "LicenseModel", valid_608069
  var valid_608070 = formData.getOrDefault("DBSubnetGroupName")
  valid_608070 = validateParameter(valid_608070, JString, required = false,
                                 default = nil)
  if valid_608070 != nil:
    section.add "DBSubnetGroupName", valid_608070
  var valid_608071 = formData.getOrDefault("OptionGroupName")
  valid_608071 = validateParameter(valid_608071, JString, required = false,
                                 default = nil)
  if valid_608071 != nil:
    section.add "OptionGroupName", valid_608071
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608072: Call_PostRestoreDBInstanceFromDBSnapshot_608046;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608072.validator(path, query, header, formData, body)
  let scheme = call_608072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608072.url(scheme.get, call_608072.host, call_608072.base,
                         call_608072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608072, url, valid)

proc call*(call_608073: Call_PostRestoreDBInstanceFromDBSnapshot_608046;
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
  var query_608074 = newJObject()
  var formData_608075 = newJObject()
  add(formData_608075, "Port", newJInt(Port))
  add(formData_608075, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_608075, "MultiAZ", newJBool(MultiAZ))
  add(formData_608075, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_608075, "Engine", newJString(Engine))
  add(formData_608075, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_608075, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_608075, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_608075, "DBName", newJString(DBName))
  add(formData_608075, "Iops", newJInt(Iops))
  add(formData_608075, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608074, "Action", newJString(Action))
  add(formData_608075, "LicenseModel", newJString(LicenseModel))
  add(formData_608075, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_608075, "OptionGroupName", newJString(OptionGroupName))
  add(query_608074, "Version", newJString(Version))
  result = call_608073.call(nil, query_608074, nil, formData_608075, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_608046(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_608047, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_608048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_608017 = ref object of OpenApiRestCall_605573
proc url_GetRestoreDBInstanceFromDBSnapshot_608019(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceFromDBSnapshot_608018(path: JsonNode;
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
  var valid_608020 = query.getOrDefault("DBName")
  valid_608020 = validateParameter(valid_608020, JString, required = false,
                                 default = nil)
  if valid_608020 != nil:
    section.add "DBName", valid_608020
  var valid_608021 = query.getOrDefault("Engine")
  valid_608021 = validateParameter(valid_608021, JString, required = false,
                                 default = nil)
  if valid_608021 != nil:
    section.add "Engine", valid_608021
  var valid_608022 = query.getOrDefault("LicenseModel")
  valid_608022 = validateParameter(valid_608022, JString, required = false,
                                 default = nil)
  if valid_608022 != nil:
    section.add "LicenseModel", valid_608022
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_608023 = query.getOrDefault("DBInstanceIdentifier")
  valid_608023 = validateParameter(valid_608023, JString, required = true,
                                 default = nil)
  if valid_608023 != nil:
    section.add "DBInstanceIdentifier", valid_608023
  var valid_608024 = query.getOrDefault("DBSnapshotIdentifier")
  valid_608024 = validateParameter(valid_608024, JString, required = true,
                                 default = nil)
  if valid_608024 != nil:
    section.add "DBSnapshotIdentifier", valid_608024
  var valid_608025 = query.getOrDefault("Action")
  valid_608025 = validateParameter(valid_608025, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_608025 != nil:
    section.add "Action", valid_608025
  var valid_608026 = query.getOrDefault("MultiAZ")
  valid_608026 = validateParameter(valid_608026, JBool, required = false, default = nil)
  if valid_608026 != nil:
    section.add "MultiAZ", valid_608026
  var valid_608027 = query.getOrDefault("Port")
  valid_608027 = validateParameter(valid_608027, JInt, required = false, default = nil)
  if valid_608027 != nil:
    section.add "Port", valid_608027
  var valid_608028 = query.getOrDefault("AvailabilityZone")
  valid_608028 = validateParameter(valid_608028, JString, required = false,
                                 default = nil)
  if valid_608028 != nil:
    section.add "AvailabilityZone", valid_608028
  var valid_608029 = query.getOrDefault("OptionGroupName")
  valid_608029 = validateParameter(valid_608029, JString, required = false,
                                 default = nil)
  if valid_608029 != nil:
    section.add "OptionGroupName", valid_608029
  var valid_608030 = query.getOrDefault("DBSubnetGroupName")
  valid_608030 = validateParameter(valid_608030, JString, required = false,
                                 default = nil)
  if valid_608030 != nil:
    section.add "DBSubnetGroupName", valid_608030
  var valid_608031 = query.getOrDefault("Version")
  valid_608031 = validateParameter(valid_608031, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_608031 != nil:
    section.add "Version", valid_608031
  var valid_608032 = query.getOrDefault("DBInstanceClass")
  valid_608032 = validateParameter(valid_608032, JString, required = false,
                                 default = nil)
  if valid_608032 != nil:
    section.add "DBInstanceClass", valid_608032
  var valid_608033 = query.getOrDefault("PubliclyAccessible")
  valid_608033 = validateParameter(valid_608033, JBool, required = false, default = nil)
  if valid_608033 != nil:
    section.add "PubliclyAccessible", valid_608033
  var valid_608034 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_608034 = validateParameter(valid_608034, JBool, required = false, default = nil)
  if valid_608034 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608034
  var valid_608035 = query.getOrDefault("Iops")
  valid_608035 = validateParameter(valid_608035, JInt, required = false, default = nil)
  if valid_608035 != nil:
    section.add "Iops", valid_608035
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608036 = header.getOrDefault("X-Amz-Signature")
  valid_608036 = validateParameter(valid_608036, JString, required = false,
                                 default = nil)
  if valid_608036 != nil:
    section.add "X-Amz-Signature", valid_608036
  var valid_608037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608037 = validateParameter(valid_608037, JString, required = false,
                                 default = nil)
  if valid_608037 != nil:
    section.add "X-Amz-Content-Sha256", valid_608037
  var valid_608038 = header.getOrDefault("X-Amz-Date")
  valid_608038 = validateParameter(valid_608038, JString, required = false,
                                 default = nil)
  if valid_608038 != nil:
    section.add "X-Amz-Date", valid_608038
  var valid_608039 = header.getOrDefault("X-Amz-Credential")
  valid_608039 = validateParameter(valid_608039, JString, required = false,
                                 default = nil)
  if valid_608039 != nil:
    section.add "X-Amz-Credential", valid_608039
  var valid_608040 = header.getOrDefault("X-Amz-Security-Token")
  valid_608040 = validateParameter(valid_608040, JString, required = false,
                                 default = nil)
  if valid_608040 != nil:
    section.add "X-Amz-Security-Token", valid_608040
  var valid_608041 = header.getOrDefault("X-Amz-Algorithm")
  valid_608041 = validateParameter(valid_608041, JString, required = false,
                                 default = nil)
  if valid_608041 != nil:
    section.add "X-Amz-Algorithm", valid_608041
  var valid_608042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608042 = validateParameter(valid_608042, JString, required = false,
                                 default = nil)
  if valid_608042 != nil:
    section.add "X-Amz-SignedHeaders", valid_608042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608043: Call_GetRestoreDBInstanceFromDBSnapshot_608017;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608043.validator(path, query, header, formData, body)
  let scheme = call_608043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608043.url(scheme.get, call_608043.host, call_608043.base,
                         call_608043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608043, url, valid)

proc call*(call_608044: Call_GetRestoreDBInstanceFromDBSnapshot_608017;
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
  var query_608045 = newJObject()
  add(query_608045, "DBName", newJString(DBName))
  add(query_608045, "Engine", newJString(Engine))
  add(query_608045, "LicenseModel", newJString(LicenseModel))
  add(query_608045, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_608045, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_608045, "Action", newJString(Action))
  add(query_608045, "MultiAZ", newJBool(MultiAZ))
  add(query_608045, "Port", newJInt(Port))
  add(query_608045, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_608045, "OptionGroupName", newJString(OptionGroupName))
  add(query_608045, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_608045, "Version", newJString(Version))
  add(query_608045, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_608045, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608045, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_608045, "Iops", newJInt(Iops))
  result = call_608044.call(nil, query_608045, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_608017(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_608018, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_608019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_608107 = ref object of OpenApiRestCall_605573
proc url_PostRestoreDBInstanceToPointInTime_608109(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceToPointInTime_608108(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608110 = query.getOrDefault("Action")
  valid_608110 = validateParameter(valid_608110, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_608110 != nil:
    section.add "Action", valid_608110
  var valid_608111 = query.getOrDefault("Version")
  valid_608111 = validateParameter(valid_608111, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_608111 != nil:
    section.add "Version", valid_608111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608112 = header.getOrDefault("X-Amz-Signature")
  valid_608112 = validateParameter(valid_608112, JString, required = false,
                                 default = nil)
  if valid_608112 != nil:
    section.add "X-Amz-Signature", valid_608112
  var valid_608113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608113 = validateParameter(valid_608113, JString, required = false,
                                 default = nil)
  if valid_608113 != nil:
    section.add "X-Amz-Content-Sha256", valid_608113
  var valid_608114 = header.getOrDefault("X-Amz-Date")
  valid_608114 = validateParameter(valid_608114, JString, required = false,
                                 default = nil)
  if valid_608114 != nil:
    section.add "X-Amz-Date", valid_608114
  var valid_608115 = header.getOrDefault("X-Amz-Credential")
  valid_608115 = validateParameter(valid_608115, JString, required = false,
                                 default = nil)
  if valid_608115 != nil:
    section.add "X-Amz-Credential", valid_608115
  var valid_608116 = header.getOrDefault("X-Amz-Security-Token")
  valid_608116 = validateParameter(valid_608116, JString, required = false,
                                 default = nil)
  if valid_608116 != nil:
    section.add "X-Amz-Security-Token", valid_608116
  var valid_608117 = header.getOrDefault("X-Amz-Algorithm")
  valid_608117 = validateParameter(valid_608117, JString, required = false,
                                 default = nil)
  if valid_608117 != nil:
    section.add "X-Amz-Algorithm", valid_608117
  var valid_608118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608118 = validateParameter(valid_608118, JString, required = false,
                                 default = nil)
  if valid_608118 != nil:
    section.add "X-Amz-SignedHeaders", valid_608118
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
  var valid_608119 = formData.getOrDefault("Port")
  valid_608119 = validateParameter(valid_608119, JInt, required = false, default = nil)
  if valid_608119 != nil:
    section.add "Port", valid_608119
  var valid_608120 = formData.getOrDefault("DBInstanceClass")
  valid_608120 = validateParameter(valid_608120, JString, required = false,
                                 default = nil)
  if valid_608120 != nil:
    section.add "DBInstanceClass", valid_608120
  var valid_608121 = formData.getOrDefault("MultiAZ")
  valid_608121 = validateParameter(valid_608121, JBool, required = false, default = nil)
  if valid_608121 != nil:
    section.add "MultiAZ", valid_608121
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_608122 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_608122 = validateParameter(valid_608122, JString, required = true,
                                 default = nil)
  if valid_608122 != nil:
    section.add "SourceDBInstanceIdentifier", valid_608122
  var valid_608123 = formData.getOrDefault("AvailabilityZone")
  valid_608123 = validateParameter(valid_608123, JString, required = false,
                                 default = nil)
  if valid_608123 != nil:
    section.add "AvailabilityZone", valid_608123
  var valid_608124 = formData.getOrDefault("Engine")
  valid_608124 = validateParameter(valid_608124, JString, required = false,
                                 default = nil)
  if valid_608124 != nil:
    section.add "Engine", valid_608124
  var valid_608125 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_608125 = validateParameter(valid_608125, JBool, required = false, default = nil)
  if valid_608125 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608125
  var valid_608126 = formData.getOrDefault("UseLatestRestorableTime")
  valid_608126 = validateParameter(valid_608126, JBool, required = false, default = nil)
  if valid_608126 != nil:
    section.add "UseLatestRestorableTime", valid_608126
  var valid_608127 = formData.getOrDefault("DBName")
  valid_608127 = validateParameter(valid_608127, JString, required = false,
                                 default = nil)
  if valid_608127 != nil:
    section.add "DBName", valid_608127
  var valid_608128 = formData.getOrDefault("Iops")
  valid_608128 = validateParameter(valid_608128, JInt, required = false, default = nil)
  if valid_608128 != nil:
    section.add "Iops", valid_608128
  var valid_608129 = formData.getOrDefault("PubliclyAccessible")
  valid_608129 = validateParameter(valid_608129, JBool, required = false, default = nil)
  if valid_608129 != nil:
    section.add "PubliclyAccessible", valid_608129
  var valid_608130 = formData.getOrDefault("LicenseModel")
  valid_608130 = validateParameter(valid_608130, JString, required = false,
                                 default = nil)
  if valid_608130 != nil:
    section.add "LicenseModel", valid_608130
  var valid_608131 = formData.getOrDefault("DBSubnetGroupName")
  valid_608131 = validateParameter(valid_608131, JString, required = false,
                                 default = nil)
  if valid_608131 != nil:
    section.add "DBSubnetGroupName", valid_608131
  var valid_608132 = formData.getOrDefault("OptionGroupName")
  valid_608132 = validateParameter(valid_608132, JString, required = false,
                                 default = nil)
  if valid_608132 != nil:
    section.add "OptionGroupName", valid_608132
  var valid_608133 = formData.getOrDefault("RestoreTime")
  valid_608133 = validateParameter(valid_608133, JString, required = false,
                                 default = nil)
  if valid_608133 != nil:
    section.add "RestoreTime", valid_608133
  var valid_608134 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_608134 = validateParameter(valid_608134, JString, required = true,
                                 default = nil)
  if valid_608134 != nil:
    section.add "TargetDBInstanceIdentifier", valid_608134
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608135: Call_PostRestoreDBInstanceToPointInTime_608107;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608135.validator(path, query, header, formData, body)
  let scheme = call_608135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608135.url(scheme.get, call_608135.host, call_608135.base,
                         call_608135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608135, url, valid)

proc call*(call_608136: Call_PostRestoreDBInstanceToPointInTime_608107;
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
  var query_608137 = newJObject()
  var formData_608138 = newJObject()
  add(formData_608138, "Port", newJInt(Port))
  add(formData_608138, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_608138, "MultiAZ", newJBool(MultiAZ))
  add(formData_608138, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_608138, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_608138, "Engine", newJString(Engine))
  add(formData_608138, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_608138, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_608138, "DBName", newJString(DBName))
  add(formData_608138, "Iops", newJInt(Iops))
  add(formData_608138, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608137, "Action", newJString(Action))
  add(formData_608138, "LicenseModel", newJString(LicenseModel))
  add(formData_608138, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_608138, "OptionGroupName", newJString(OptionGroupName))
  add(formData_608138, "RestoreTime", newJString(RestoreTime))
  add(formData_608138, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_608137, "Version", newJString(Version))
  result = call_608136.call(nil, query_608137, nil, formData_608138, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_608107(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_608108, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_608109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_608076 = ref object of OpenApiRestCall_605573
proc url_GetRestoreDBInstanceToPointInTime_608078(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceToPointInTime_608077(path: JsonNode;
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
  var valid_608079 = query.getOrDefault("DBName")
  valid_608079 = validateParameter(valid_608079, JString, required = false,
                                 default = nil)
  if valid_608079 != nil:
    section.add "DBName", valid_608079
  var valid_608080 = query.getOrDefault("Engine")
  valid_608080 = validateParameter(valid_608080, JString, required = false,
                                 default = nil)
  if valid_608080 != nil:
    section.add "Engine", valid_608080
  var valid_608081 = query.getOrDefault("UseLatestRestorableTime")
  valid_608081 = validateParameter(valid_608081, JBool, required = false, default = nil)
  if valid_608081 != nil:
    section.add "UseLatestRestorableTime", valid_608081
  var valid_608082 = query.getOrDefault("LicenseModel")
  valid_608082 = validateParameter(valid_608082, JString, required = false,
                                 default = nil)
  if valid_608082 != nil:
    section.add "LicenseModel", valid_608082
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_608083 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_608083 = validateParameter(valid_608083, JString, required = true,
                                 default = nil)
  if valid_608083 != nil:
    section.add "TargetDBInstanceIdentifier", valid_608083
  var valid_608084 = query.getOrDefault("Action")
  valid_608084 = validateParameter(valid_608084, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_608084 != nil:
    section.add "Action", valid_608084
  var valid_608085 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_608085 = validateParameter(valid_608085, JString, required = true,
                                 default = nil)
  if valid_608085 != nil:
    section.add "SourceDBInstanceIdentifier", valid_608085
  var valid_608086 = query.getOrDefault("MultiAZ")
  valid_608086 = validateParameter(valid_608086, JBool, required = false, default = nil)
  if valid_608086 != nil:
    section.add "MultiAZ", valid_608086
  var valid_608087 = query.getOrDefault("Port")
  valid_608087 = validateParameter(valid_608087, JInt, required = false, default = nil)
  if valid_608087 != nil:
    section.add "Port", valid_608087
  var valid_608088 = query.getOrDefault("AvailabilityZone")
  valid_608088 = validateParameter(valid_608088, JString, required = false,
                                 default = nil)
  if valid_608088 != nil:
    section.add "AvailabilityZone", valid_608088
  var valid_608089 = query.getOrDefault("OptionGroupName")
  valid_608089 = validateParameter(valid_608089, JString, required = false,
                                 default = nil)
  if valid_608089 != nil:
    section.add "OptionGroupName", valid_608089
  var valid_608090 = query.getOrDefault("DBSubnetGroupName")
  valid_608090 = validateParameter(valid_608090, JString, required = false,
                                 default = nil)
  if valid_608090 != nil:
    section.add "DBSubnetGroupName", valid_608090
  var valid_608091 = query.getOrDefault("RestoreTime")
  valid_608091 = validateParameter(valid_608091, JString, required = false,
                                 default = nil)
  if valid_608091 != nil:
    section.add "RestoreTime", valid_608091
  var valid_608092 = query.getOrDefault("DBInstanceClass")
  valid_608092 = validateParameter(valid_608092, JString, required = false,
                                 default = nil)
  if valid_608092 != nil:
    section.add "DBInstanceClass", valid_608092
  var valid_608093 = query.getOrDefault("PubliclyAccessible")
  valid_608093 = validateParameter(valid_608093, JBool, required = false, default = nil)
  if valid_608093 != nil:
    section.add "PubliclyAccessible", valid_608093
  var valid_608094 = query.getOrDefault("Version")
  valid_608094 = validateParameter(valid_608094, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_608094 != nil:
    section.add "Version", valid_608094
  var valid_608095 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_608095 = validateParameter(valid_608095, JBool, required = false, default = nil)
  if valid_608095 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608095
  var valid_608096 = query.getOrDefault("Iops")
  valid_608096 = validateParameter(valid_608096, JInt, required = false, default = nil)
  if valid_608096 != nil:
    section.add "Iops", valid_608096
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608097 = header.getOrDefault("X-Amz-Signature")
  valid_608097 = validateParameter(valid_608097, JString, required = false,
                                 default = nil)
  if valid_608097 != nil:
    section.add "X-Amz-Signature", valid_608097
  var valid_608098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608098 = validateParameter(valid_608098, JString, required = false,
                                 default = nil)
  if valid_608098 != nil:
    section.add "X-Amz-Content-Sha256", valid_608098
  var valid_608099 = header.getOrDefault("X-Amz-Date")
  valid_608099 = validateParameter(valid_608099, JString, required = false,
                                 default = nil)
  if valid_608099 != nil:
    section.add "X-Amz-Date", valid_608099
  var valid_608100 = header.getOrDefault("X-Amz-Credential")
  valid_608100 = validateParameter(valid_608100, JString, required = false,
                                 default = nil)
  if valid_608100 != nil:
    section.add "X-Amz-Credential", valid_608100
  var valid_608101 = header.getOrDefault("X-Amz-Security-Token")
  valid_608101 = validateParameter(valid_608101, JString, required = false,
                                 default = nil)
  if valid_608101 != nil:
    section.add "X-Amz-Security-Token", valid_608101
  var valid_608102 = header.getOrDefault("X-Amz-Algorithm")
  valid_608102 = validateParameter(valid_608102, JString, required = false,
                                 default = nil)
  if valid_608102 != nil:
    section.add "X-Amz-Algorithm", valid_608102
  var valid_608103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608103 = validateParameter(valid_608103, JString, required = false,
                                 default = nil)
  if valid_608103 != nil:
    section.add "X-Amz-SignedHeaders", valid_608103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608104: Call_GetRestoreDBInstanceToPointInTime_608076;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608104.validator(path, query, header, formData, body)
  let scheme = call_608104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608104.url(scheme.get, call_608104.host, call_608104.base,
                         call_608104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608104, url, valid)

proc call*(call_608105: Call_GetRestoreDBInstanceToPointInTime_608076;
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
  var query_608106 = newJObject()
  add(query_608106, "DBName", newJString(DBName))
  add(query_608106, "Engine", newJString(Engine))
  add(query_608106, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_608106, "LicenseModel", newJString(LicenseModel))
  add(query_608106, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_608106, "Action", newJString(Action))
  add(query_608106, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_608106, "MultiAZ", newJBool(MultiAZ))
  add(query_608106, "Port", newJInt(Port))
  add(query_608106, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_608106, "OptionGroupName", newJString(OptionGroupName))
  add(query_608106, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_608106, "RestoreTime", newJString(RestoreTime))
  add(query_608106, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_608106, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608106, "Version", newJString(Version))
  add(query_608106, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_608106, "Iops", newJInt(Iops))
  result = call_608105.call(nil, query_608106, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_608076(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_608077, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_608078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_608159 = ref object of OpenApiRestCall_605573
proc url_PostRevokeDBSecurityGroupIngress_608161(protocol: Scheme; host: string;
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

proc validate_PostRevokeDBSecurityGroupIngress_608160(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608162 = query.getOrDefault("Action")
  valid_608162 = validateParameter(valid_608162, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_608162 != nil:
    section.add "Action", valid_608162
  var valid_608163 = query.getOrDefault("Version")
  valid_608163 = validateParameter(valid_608163, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_608163 != nil:
    section.add "Version", valid_608163
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608164 = header.getOrDefault("X-Amz-Signature")
  valid_608164 = validateParameter(valid_608164, JString, required = false,
                                 default = nil)
  if valid_608164 != nil:
    section.add "X-Amz-Signature", valid_608164
  var valid_608165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608165 = validateParameter(valid_608165, JString, required = false,
                                 default = nil)
  if valid_608165 != nil:
    section.add "X-Amz-Content-Sha256", valid_608165
  var valid_608166 = header.getOrDefault("X-Amz-Date")
  valid_608166 = validateParameter(valid_608166, JString, required = false,
                                 default = nil)
  if valid_608166 != nil:
    section.add "X-Amz-Date", valid_608166
  var valid_608167 = header.getOrDefault("X-Amz-Credential")
  valid_608167 = validateParameter(valid_608167, JString, required = false,
                                 default = nil)
  if valid_608167 != nil:
    section.add "X-Amz-Credential", valid_608167
  var valid_608168 = header.getOrDefault("X-Amz-Security-Token")
  valid_608168 = validateParameter(valid_608168, JString, required = false,
                                 default = nil)
  if valid_608168 != nil:
    section.add "X-Amz-Security-Token", valid_608168
  var valid_608169 = header.getOrDefault("X-Amz-Algorithm")
  valid_608169 = validateParameter(valid_608169, JString, required = false,
                                 default = nil)
  if valid_608169 != nil:
    section.add "X-Amz-Algorithm", valid_608169
  var valid_608170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608170 = validateParameter(valid_608170, JString, required = false,
                                 default = nil)
  if valid_608170 != nil:
    section.add "X-Amz-SignedHeaders", valid_608170
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_608171 = formData.getOrDefault("DBSecurityGroupName")
  valid_608171 = validateParameter(valid_608171, JString, required = true,
                                 default = nil)
  if valid_608171 != nil:
    section.add "DBSecurityGroupName", valid_608171
  var valid_608172 = formData.getOrDefault("EC2SecurityGroupName")
  valid_608172 = validateParameter(valid_608172, JString, required = false,
                                 default = nil)
  if valid_608172 != nil:
    section.add "EC2SecurityGroupName", valid_608172
  var valid_608173 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_608173 = validateParameter(valid_608173, JString, required = false,
                                 default = nil)
  if valid_608173 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_608173
  var valid_608174 = formData.getOrDefault("EC2SecurityGroupId")
  valid_608174 = validateParameter(valid_608174, JString, required = false,
                                 default = nil)
  if valid_608174 != nil:
    section.add "EC2SecurityGroupId", valid_608174
  var valid_608175 = formData.getOrDefault("CIDRIP")
  valid_608175 = validateParameter(valid_608175, JString, required = false,
                                 default = nil)
  if valid_608175 != nil:
    section.add "CIDRIP", valid_608175
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608176: Call_PostRevokeDBSecurityGroupIngress_608159;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608176.validator(path, query, header, formData, body)
  let scheme = call_608176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608176.url(scheme.get, call_608176.host, call_608176.base,
                         call_608176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608176, url, valid)

proc call*(call_608177: Call_PostRevokeDBSecurityGroupIngress_608159;
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
  var query_608178 = newJObject()
  var formData_608179 = newJObject()
  add(formData_608179, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_608179, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_608179, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_608179, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_608179, "CIDRIP", newJString(CIDRIP))
  add(query_608178, "Action", newJString(Action))
  add(query_608178, "Version", newJString(Version))
  result = call_608177.call(nil, query_608178, nil, formData_608179, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_608159(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_608160, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_608161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_608139 = ref object of OpenApiRestCall_605573
proc url_GetRevokeDBSecurityGroupIngress_608141(protocol: Scheme; host: string;
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

proc validate_GetRevokeDBSecurityGroupIngress_608140(path: JsonNode;
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
  var valid_608142 = query.getOrDefault("EC2SecurityGroupName")
  valid_608142 = validateParameter(valid_608142, JString, required = false,
                                 default = nil)
  if valid_608142 != nil:
    section.add "EC2SecurityGroupName", valid_608142
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_608143 = query.getOrDefault("DBSecurityGroupName")
  valid_608143 = validateParameter(valid_608143, JString, required = true,
                                 default = nil)
  if valid_608143 != nil:
    section.add "DBSecurityGroupName", valid_608143
  var valid_608144 = query.getOrDefault("EC2SecurityGroupId")
  valid_608144 = validateParameter(valid_608144, JString, required = false,
                                 default = nil)
  if valid_608144 != nil:
    section.add "EC2SecurityGroupId", valid_608144
  var valid_608145 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_608145 = validateParameter(valid_608145, JString, required = false,
                                 default = nil)
  if valid_608145 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_608145
  var valid_608146 = query.getOrDefault("Action")
  valid_608146 = validateParameter(valid_608146, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_608146 != nil:
    section.add "Action", valid_608146
  var valid_608147 = query.getOrDefault("Version")
  valid_608147 = validateParameter(valid_608147, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_608147 != nil:
    section.add "Version", valid_608147
  var valid_608148 = query.getOrDefault("CIDRIP")
  valid_608148 = validateParameter(valid_608148, JString, required = false,
                                 default = nil)
  if valid_608148 != nil:
    section.add "CIDRIP", valid_608148
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608149 = header.getOrDefault("X-Amz-Signature")
  valid_608149 = validateParameter(valid_608149, JString, required = false,
                                 default = nil)
  if valid_608149 != nil:
    section.add "X-Amz-Signature", valid_608149
  var valid_608150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608150 = validateParameter(valid_608150, JString, required = false,
                                 default = nil)
  if valid_608150 != nil:
    section.add "X-Amz-Content-Sha256", valid_608150
  var valid_608151 = header.getOrDefault("X-Amz-Date")
  valid_608151 = validateParameter(valid_608151, JString, required = false,
                                 default = nil)
  if valid_608151 != nil:
    section.add "X-Amz-Date", valid_608151
  var valid_608152 = header.getOrDefault("X-Amz-Credential")
  valid_608152 = validateParameter(valid_608152, JString, required = false,
                                 default = nil)
  if valid_608152 != nil:
    section.add "X-Amz-Credential", valid_608152
  var valid_608153 = header.getOrDefault("X-Amz-Security-Token")
  valid_608153 = validateParameter(valid_608153, JString, required = false,
                                 default = nil)
  if valid_608153 != nil:
    section.add "X-Amz-Security-Token", valid_608153
  var valid_608154 = header.getOrDefault("X-Amz-Algorithm")
  valid_608154 = validateParameter(valid_608154, JString, required = false,
                                 default = nil)
  if valid_608154 != nil:
    section.add "X-Amz-Algorithm", valid_608154
  var valid_608155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608155 = validateParameter(valid_608155, JString, required = false,
                                 default = nil)
  if valid_608155 != nil:
    section.add "X-Amz-SignedHeaders", valid_608155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608156: Call_GetRevokeDBSecurityGroupIngress_608139;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608156.validator(path, query, header, formData, body)
  let scheme = call_608156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608156.url(scheme.get, call_608156.host, call_608156.base,
                         call_608156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608156, url, valid)

proc call*(call_608157: Call_GetRevokeDBSecurityGroupIngress_608139;
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
  var query_608158 = newJObject()
  add(query_608158, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_608158, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_608158, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_608158, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_608158, "Action", newJString(Action))
  add(query_608158, "Version", newJString(Version))
  add(query_608158, "CIDRIP", newJString(CIDRIP))
  result = call_608157.call(nil, query_608158, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_608139(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_608140, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_608141,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
