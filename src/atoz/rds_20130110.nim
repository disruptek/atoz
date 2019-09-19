
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772581 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772581](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772581): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostAddSourceIdentifierToSubscription_773189 = ref object of OpenApiRestCall_772581
proc url_PostAddSourceIdentifierToSubscription_773191(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddSourceIdentifierToSubscription_773190(path: JsonNode;
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
  var valid_773192 = query.getOrDefault("Action")
  valid_773192 = validateParameter(valid_773192, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_773192 != nil:
    section.add "Action", valid_773192
  var valid_773193 = query.getOrDefault("Version")
  valid_773193 = validateParameter(valid_773193, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773193 != nil:
    section.add "Version", valid_773193
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773194 = header.getOrDefault("X-Amz-Date")
  valid_773194 = validateParameter(valid_773194, JString, required = false,
                                 default = nil)
  if valid_773194 != nil:
    section.add "X-Amz-Date", valid_773194
  var valid_773195 = header.getOrDefault("X-Amz-Security-Token")
  valid_773195 = validateParameter(valid_773195, JString, required = false,
                                 default = nil)
  if valid_773195 != nil:
    section.add "X-Amz-Security-Token", valid_773195
  var valid_773196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-Content-Sha256", valid_773196
  var valid_773197 = header.getOrDefault("X-Amz-Algorithm")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-Algorithm", valid_773197
  var valid_773198 = header.getOrDefault("X-Amz-Signature")
  valid_773198 = validateParameter(valid_773198, JString, required = false,
                                 default = nil)
  if valid_773198 != nil:
    section.add "X-Amz-Signature", valid_773198
  var valid_773199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773199 = validateParameter(valid_773199, JString, required = false,
                                 default = nil)
  if valid_773199 != nil:
    section.add "X-Amz-SignedHeaders", valid_773199
  var valid_773200 = header.getOrDefault("X-Amz-Credential")
  valid_773200 = validateParameter(valid_773200, JString, required = false,
                                 default = nil)
  if valid_773200 != nil:
    section.add "X-Amz-Credential", valid_773200
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_773201 = formData.getOrDefault("SourceIdentifier")
  valid_773201 = validateParameter(valid_773201, JString, required = true,
                                 default = nil)
  if valid_773201 != nil:
    section.add "SourceIdentifier", valid_773201
  var valid_773202 = formData.getOrDefault("SubscriptionName")
  valid_773202 = validateParameter(valid_773202, JString, required = true,
                                 default = nil)
  if valid_773202 != nil:
    section.add "SubscriptionName", valid_773202
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773203: Call_PostAddSourceIdentifierToSubscription_773189;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_773203.validator(path, query, header, formData, body)
  let scheme = call_773203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773203.url(scheme.get, call_773203.host, call_773203.base,
                         call_773203.route, valid.getOrDefault("path"))
  result = hook(call_773203, url, valid)

proc call*(call_773204: Call_PostAddSourceIdentifierToSubscription_773189;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773205 = newJObject()
  var formData_773206 = newJObject()
  add(formData_773206, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_773206, "SubscriptionName", newJString(SubscriptionName))
  add(query_773205, "Action", newJString(Action))
  add(query_773205, "Version", newJString(Version))
  result = call_773204.call(nil, query_773205, nil, formData_773206, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_773189(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_773190, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_773191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_772917 = ref object of OpenApiRestCall_772581
proc url_GetAddSourceIdentifierToSubscription_772919(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddSourceIdentifierToSubscription_772918(path: JsonNode;
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
  var valid_773044 = query.getOrDefault("Action")
  valid_773044 = validateParameter(valid_773044, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_773044 != nil:
    section.add "Action", valid_773044
  var valid_773045 = query.getOrDefault("SourceIdentifier")
  valid_773045 = validateParameter(valid_773045, JString, required = true,
                                 default = nil)
  if valid_773045 != nil:
    section.add "SourceIdentifier", valid_773045
  var valid_773046 = query.getOrDefault("SubscriptionName")
  valid_773046 = validateParameter(valid_773046, JString, required = true,
                                 default = nil)
  if valid_773046 != nil:
    section.add "SubscriptionName", valid_773046
  var valid_773047 = query.getOrDefault("Version")
  valid_773047 = validateParameter(valid_773047, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773047 != nil:
    section.add "Version", valid_773047
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773048 = header.getOrDefault("X-Amz-Date")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Date", valid_773048
  var valid_773049 = header.getOrDefault("X-Amz-Security-Token")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Security-Token", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-Content-Sha256", valid_773050
  var valid_773051 = header.getOrDefault("X-Amz-Algorithm")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Algorithm", valid_773051
  var valid_773052 = header.getOrDefault("X-Amz-Signature")
  valid_773052 = validateParameter(valid_773052, JString, required = false,
                                 default = nil)
  if valid_773052 != nil:
    section.add "X-Amz-Signature", valid_773052
  var valid_773053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773053 = validateParameter(valid_773053, JString, required = false,
                                 default = nil)
  if valid_773053 != nil:
    section.add "X-Amz-SignedHeaders", valid_773053
  var valid_773054 = header.getOrDefault("X-Amz-Credential")
  valid_773054 = validateParameter(valid_773054, JString, required = false,
                                 default = nil)
  if valid_773054 != nil:
    section.add "X-Amz-Credential", valid_773054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773077: Call_GetAddSourceIdentifierToSubscription_772917;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_773077.validator(path, query, header, formData, body)
  let scheme = call_773077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773077.url(scheme.get, call_773077.host, call_773077.base,
                         call_773077.route, valid.getOrDefault("path"))
  result = hook(call_773077, url, valid)

proc call*(call_773148: Call_GetAddSourceIdentifierToSubscription_772917;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_773149 = newJObject()
  add(query_773149, "Action", newJString(Action))
  add(query_773149, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_773149, "SubscriptionName", newJString(SubscriptionName))
  add(query_773149, "Version", newJString(Version))
  result = call_773148.call(nil, query_773149, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_772917(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_772918, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_772919,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_773224 = ref object of OpenApiRestCall_772581
proc url_PostAddTagsToResource_773226(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddTagsToResource_773225(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773227 = query.getOrDefault("Action")
  valid_773227 = validateParameter(valid_773227, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_773227 != nil:
    section.add "Action", valid_773227
  var valid_773228 = query.getOrDefault("Version")
  valid_773228 = validateParameter(valid_773228, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773228 != nil:
    section.add "Version", valid_773228
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773229 = header.getOrDefault("X-Amz-Date")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Date", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-Security-Token")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Security-Token", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Content-Sha256", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-Algorithm")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-Algorithm", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Signature")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Signature", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-SignedHeaders", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-Credential")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Credential", valid_773235
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_773236 = formData.getOrDefault("Tags")
  valid_773236 = validateParameter(valid_773236, JArray, required = true, default = nil)
  if valid_773236 != nil:
    section.add "Tags", valid_773236
  var valid_773237 = formData.getOrDefault("ResourceName")
  valid_773237 = validateParameter(valid_773237, JString, required = true,
                                 default = nil)
  if valid_773237 != nil:
    section.add "ResourceName", valid_773237
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773238: Call_PostAddTagsToResource_773224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773238.validator(path, query, header, formData, body)
  let scheme = call_773238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773238.url(scheme.get, call_773238.host, call_773238.base,
                         call_773238.route, valid.getOrDefault("path"))
  result = hook(call_773238, url, valid)

proc call*(call_773239: Call_PostAddTagsToResource_773224; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-01-10"): Recallable =
  ## postAddTagsToResource
  ##   Tags: JArray (required)
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_773240 = newJObject()
  var formData_773241 = newJObject()
  if Tags != nil:
    formData_773241.add "Tags", Tags
  add(query_773240, "Action", newJString(Action))
  add(formData_773241, "ResourceName", newJString(ResourceName))
  add(query_773240, "Version", newJString(Version))
  result = call_773239.call(nil, query_773240, nil, formData_773241, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_773224(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_773225, base: "/",
    url: url_PostAddTagsToResource_773226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_773207 = ref object of OpenApiRestCall_772581
proc url_GetAddTagsToResource_773209(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddTagsToResource_773208(path: JsonNode; query: JsonNode;
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
  var valid_773210 = query.getOrDefault("Tags")
  valid_773210 = validateParameter(valid_773210, JArray, required = true, default = nil)
  if valid_773210 != nil:
    section.add "Tags", valid_773210
  var valid_773211 = query.getOrDefault("ResourceName")
  valid_773211 = validateParameter(valid_773211, JString, required = true,
                                 default = nil)
  if valid_773211 != nil:
    section.add "ResourceName", valid_773211
  var valid_773212 = query.getOrDefault("Action")
  valid_773212 = validateParameter(valid_773212, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_773212 != nil:
    section.add "Action", valid_773212
  var valid_773213 = query.getOrDefault("Version")
  valid_773213 = validateParameter(valid_773213, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773213 != nil:
    section.add "Version", valid_773213
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773214 = header.getOrDefault("X-Amz-Date")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Date", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Security-Token")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Security-Token", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-Content-Sha256", valid_773216
  var valid_773217 = header.getOrDefault("X-Amz-Algorithm")
  valid_773217 = validateParameter(valid_773217, JString, required = false,
                                 default = nil)
  if valid_773217 != nil:
    section.add "X-Amz-Algorithm", valid_773217
  var valid_773218 = header.getOrDefault("X-Amz-Signature")
  valid_773218 = validateParameter(valid_773218, JString, required = false,
                                 default = nil)
  if valid_773218 != nil:
    section.add "X-Amz-Signature", valid_773218
  var valid_773219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773219 = validateParameter(valid_773219, JString, required = false,
                                 default = nil)
  if valid_773219 != nil:
    section.add "X-Amz-SignedHeaders", valid_773219
  var valid_773220 = header.getOrDefault("X-Amz-Credential")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Credential", valid_773220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773221: Call_GetAddTagsToResource_773207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773221.validator(path, query, header, formData, body)
  let scheme = call_773221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773221.url(scheme.get, call_773221.host, call_773221.base,
                         call_773221.route, valid.getOrDefault("path"))
  result = hook(call_773221, url, valid)

proc call*(call_773222: Call_GetAddTagsToResource_773207; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-01-10"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773223 = newJObject()
  if Tags != nil:
    query_773223.add "Tags", Tags
  add(query_773223, "ResourceName", newJString(ResourceName))
  add(query_773223, "Action", newJString(Action))
  add(query_773223, "Version", newJString(Version))
  result = call_773222.call(nil, query_773223, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_773207(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_773208, base: "/",
    url: url_GetAddTagsToResource_773209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_773262 = ref object of OpenApiRestCall_772581
proc url_PostAuthorizeDBSecurityGroupIngress_773264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_773263(path: JsonNode;
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
  var valid_773265 = query.getOrDefault("Action")
  valid_773265 = validateParameter(valid_773265, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_773265 != nil:
    section.add "Action", valid_773265
  var valid_773266 = query.getOrDefault("Version")
  valid_773266 = validateParameter(valid_773266, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773266 != nil:
    section.add "Version", valid_773266
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773267 = header.getOrDefault("X-Amz-Date")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Date", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Security-Token")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Security-Token", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Content-Sha256", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Algorithm")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Algorithm", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Signature")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Signature", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-SignedHeaders", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-Credential")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-Credential", valid_773273
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_773274 = formData.getOrDefault("DBSecurityGroupName")
  valid_773274 = validateParameter(valid_773274, JString, required = true,
                                 default = nil)
  if valid_773274 != nil:
    section.add "DBSecurityGroupName", valid_773274
  var valid_773275 = formData.getOrDefault("EC2SecurityGroupName")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "EC2SecurityGroupName", valid_773275
  var valid_773276 = formData.getOrDefault("EC2SecurityGroupId")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "EC2SecurityGroupId", valid_773276
  var valid_773277 = formData.getOrDefault("CIDRIP")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "CIDRIP", valid_773277
  var valid_773278 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_773278
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773279: Call_PostAuthorizeDBSecurityGroupIngress_773262;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_773279.validator(path, query, header, formData, body)
  let scheme = call_773279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773279.url(scheme.get, call_773279.host, call_773279.base,
                         call_773279.route, valid.getOrDefault("path"))
  result = hook(call_773279, url, valid)

proc call*(call_773280: Call_PostAuthorizeDBSecurityGroupIngress_773262;
          DBSecurityGroupName: string;
          Action: string = "AuthorizeDBSecurityGroupIngress";
          EC2SecurityGroupName: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Version: string = "2013-01-10";
          EC2SecurityGroupOwnerId: string = ""): Recallable =
  ## postAuthorizeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Version: string (required)
  ##   EC2SecurityGroupOwnerId: string
  var query_773281 = newJObject()
  var formData_773282 = newJObject()
  add(formData_773282, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_773281, "Action", newJString(Action))
  add(formData_773282, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_773282, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_773282, "CIDRIP", newJString(CIDRIP))
  add(query_773281, "Version", newJString(Version))
  add(formData_773282, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_773280.call(nil, query_773281, nil, formData_773282, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_773262(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_773263, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_773264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_773242 = ref object of OpenApiRestCall_772581
proc url_GetAuthorizeDBSecurityGroupIngress_773244(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_773243(path: JsonNode;
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
  var valid_773245 = query.getOrDefault("EC2SecurityGroupId")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "EC2SecurityGroupId", valid_773245
  var valid_773246 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_773246
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_773247 = query.getOrDefault("DBSecurityGroupName")
  valid_773247 = validateParameter(valid_773247, JString, required = true,
                                 default = nil)
  if valid_773247 != nil:
    section.add "DBSecurityGroupName", valid_773247
  var valid_773248 = query.getOrDefault("Action")
  valid_773248 = validateParameter(valid_773248, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_773248 != nil:
    section.add "Action", valid_773248
  var valid_773249 = query.getOrDefault("CIDRIP")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "CIDRIP", valid_773249
  var valid_773250 = query.getOrDefault("EC2SecurityGroupName")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "EC2SecurityGroupName", valid_773250
  var valid_773251 = query.getOrDefault("Version")
  valid_773251 = validateParameter(valid_773251, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773251 != nil:
    section.add "Version", valid_773251
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773252 = header.getOrDefault("X-Amz-Date")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Date", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Security-Token")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Security-Token", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Content-Sha256", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Algorithm")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Algorithm", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Signature")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Signature", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-SignedHeaders", valid_773257
  var valid_773258 = header.getOrDefault("X-Amz-Credential")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-Credential", valid_773258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773259: Call_GetAuthorizeDBSecurityGroupIngress_773242;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_GetAuthorizeDBSecurityGroupIngress_773242;
          DBSecurityGroupName: string; EC2SecurityGroupId: string = "";
          EC2SecurityGroupOwnerId: string = "";
          Action: string = "AuthorizeDBSecurityGroupIngress"; CIDRIP: string = "";
          EC2SecurityGroupName: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getAuthorizeDBSecurityGroupIngress
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   CIDRIP: string
  ##   EC2SecurityGroupName: string
  ##   Version: string (required)
  var query_773261 = newJObject()
  add(query_773261, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_773261, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_773261, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_773261, "Action", newJString(Action))
  add(query_773261, "CIDRIP", newJString(CIDRIP))
  add(query_773261, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_773261, "Version", newJString(Version))
  result = call_773260.call(nil, query_773261, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_773242(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_773243, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_773244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_773300 = ref object of OpenApiRestCall_772581
proc url_PostCopyDBSnapshot_773302(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBSnapshot_773301(path: JsonNode; query: JsonNode;
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
  var valid_773303 = query.getOrDefault("Action")
  valid_773303 = validateParameter(valid_773303, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_773303 != nil:
    section.add "Action", valid_773303
  var valid_773304 = query.getOrDefault("Version")
  valid_773304 = validateParameter(valid_773304, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773304 != nil:
    section.add "Version", valid_773304
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773305 = header.getOrDefault("X-Amz-Date")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-Date", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-Security-Token")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Security-Token", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Content-Sha256", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-Algorithm")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-Algorithm", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-Signature")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Signature", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-SignedHeaders", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Credential")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Credential", valid_773311
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_773312 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_773312 = validateParameter(valid_773312, JString, required = true,
                                 default = nil)
  if valid_773312 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_773312
  var valid_773313 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_773313 = validateParameter(valid_773313, JString, required = true,
                                 default = nil)
  if valid_773313 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_773313
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773314: Call_PostCopyDBSnapshot_773300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773314.validator(path, query, header, formData, body)
  let scheme = call_773314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773314.url(scheme.get, call_773314.host, call_773314.base,
                         call_773314.route, valid.getOrDefault("path"))
  result = hook(call_773314, url, valid)

proc call*(call_773315: Call_PostCopyDBSnapshot_773300;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_773316 = newJObject()
  var formData_773317 = newJObject()
  add(formData_773317, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_773316, "Action", newJString(Action))
  add(formData_773317, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_773316, "Version", newJString(Version))
  result = call_773315.call(nil, query_773316, nil, formData_773317, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_773300(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_773301, base: "/",
    url: url_PostCopyDBSnapshot_773302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_773283 = ref object of OpenApiRestCall_772581
proc url_GetCopyDBSnapshot_773285(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBSnapshot_773284(path: JsonNode; query: JsonNode;
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
  var valid_773286 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_773286 = validateParameter(valid_773286, JString, required = true,
                                 default = nil)
  if valid_773286 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_773286
  var valid_773287 = query.getOrDefault("Action")
  valid_773287 = validateParameter(valid_773287, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_773287 != nil:
    section.add "Action", valid_773287
  var valid_773288 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_773288 = validateParameter(valid_773288, JString, required = true,
                                 default = nil)
  if valid_773288 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_773288
  var valid_773289 = query.getOrDefault("Version")
  valid_773289 = validateParameter(valid_773289, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773289 != nil:
    section.add "Version", valid_773289
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773290 = header.getOrDefault("X-Amz-Date")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Date", valid_773290
  var valid_773291 = header.getOrDefault("X-Amz-Security-Token")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-Security-Token", valid_773291
  var valid_773292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Content-Sha256", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Algorithm")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Algorithm", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-Signature")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-Signature", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-SignedHeaders", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Credential")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Credential", valid_773296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773297: Call_GetCopyDBSnapshot_773283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773297.validator(path, query, header, formData, body)
  let scheme = call_773297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773297.url(scheme.get, call_773297.host, call_773297.base,
                         call_773297.route, valid.getOrDefault("path"))
  result = hook(call_773297, url, valid)

proc call*(call_773298: Call_GetCopyDBSnapshot_773283;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_773299 = newJObject()
  add(query_773299, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_773299, "Action", newJString(Action))
  add(query_773299, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_773299, "Version", newJString(Version))
  result = call_773298.call(nil, query_773299, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_773283(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_773284,
    base: "/", url: url_GetCopyDBSnapshot_773285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_773357 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBInstance_773359(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstance_773358(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773360 = query.getOrDefault("Action")
  valid_773360 = validateParameter(valid_773360, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_773360 != nil:
    section.add "Action", valid_773360
  var valid_773361 = query.getOrDefault("Version")
  valid_773361 = validateParameter(valid_773361, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773361 != nil:
    section.add "Version", valid_773361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773362 = header.getOrDefault("X-Amz-Date")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Date", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-Security-Token")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-Security-Token", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-Content-Sha256", valid_773364
  var valid_773365 = header.getOrDefault("X-Amz-Algorithm")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-Algorithm", valid_773365
  var valid_773366 = header.getOrDefault("X-Amz-Signature")
  valid_773366 = validateParameter(valid_773366, JString, required = false,
                                 default = nil)
  if valid_773366 != nil:
    section.add "X-Amz-Signature", valid_773366
  var valid_773367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "X-Amz-SignedHeaders", valid_773367
  var valid_773368 = header.getOrDefault("X-Amz-Credential")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Credential", valid_773368
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
  var valid_773369 = formData.getOrDefault("DBSecurityGroups")
  valid_773369 = validateParameter(valid_773369, JArray, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "DBSecurityGroups", valid_773369
  var valid_773370 = formData.getOrDefault("Port")
  valid_773370 = validateParameter(valid_773370, JInt, required = false, default = nil)
  if valid_773370 != nil:
    section.add "Port", valid_773370
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_773371 = formData.getOrDefault("Engine")
  valid_773371 = validateParameter(valid_773371, JString, required = true,
                                 default = nil)
  if valid_773371 != nil:
    section.add "Engine", valid_773371
  var valid_773372 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_773372 = validateParameter(valid_773372, JArray, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "VpcSecurityGroupIds", valid_773372
  var valid_773373 = formData.getOrDefault("Iops")
  valid_773373 = validateParameter(valid_773373, JInt, required = false, default = nil)
  if valid_773373 != nil:
    section.add "Iops", valid_773373
  var valid_773374 = formData.getOrDefault("DBName")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "DBName", valid_773374
  var valid_773375 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773375 = validateParameter(valid_773375, JString, required = true,
                                 default = nil)
  if valid_773375 != nil:
    section.add "DBInstanceIdentifier", valid_773375
  var valid_773376 = formData.getOrDefault("BackupRetentionPeriod")
  valid_773376 = validateParameter(valid_773376, JInt, required = false, default = nil)
  if valid_773376 != nil:
    section.add "BackupRetentionPeriod", valid_773376
  var valid_773377 = formData.getOrDefault("DBParameterGroupName")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "DBParameterGroupName", valid_773377
  var valid_773378 = formData.getOrDefault("OptionGroupName")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "OptionGroupName", valid_773378
  var valid_773379 = formData.getOrDefault("MasterUserPassword")
  valid_773379 = validateParameter(valid_773379, JString, required = true,
                                 default = nil)
  if valid_773379 != nil:
    section.add "MasterUserPassword", valid_773379
  var valid_773380 = formData.getOrDefault("DBSubnetGroupName")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "DBSubnetGroupName", valid_773380
  var valid_773381 = formData.getOrDefault("AvailabilityZone")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "AvailabilityZone", valid_773381
  var valid_773382 = formData.getOrDefault("MultiAZ")
  valid_773382 = validateParameter(valid_773382, JBool, required = false, default = nil)
  if valid_773382 != nil:
    section.add "MultiAZ", valid_773382
  var valid_773383 = formData.getOrDefault("AllocatedStorage")
  valid_773383 = validateParameter(valid_773383, JInt, required = true, default = nil)
  if valid_773383 != nil:
    section.add "AllocatedStorage", valid_773383
  var valid_773384 = formData.getOrDefault("PubliclyAccessible")
  valid_773384 = validateParameter(valid_773384, JBool, required = false, default = nil)
  if valid_773384 != nil:
    section.add "PubliclyAccessible", valid_773384
  var valid_773385 = formData.getOrDefault("MasterUsername")
  valid_773385 = validateParameter(valid_773385, JString, required = true,
                                 default = nil)
  if valid_773385 != nil:
    section.add "MasterUsername", valid_773385
  var valid_773386 = formData.getOrDefault("DBInstanceClass")
  valid_773386 = validateParameter(valid_773386, JString, required = true,
                                 default = nil)
  if valid_773386 != nil:
    section.add "DBInstanceClass", valid_773386
  var valid_773387 = formData.getOrDefault("CharacterSetName")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "CharacterSetName", valid_773387
  var valid_773388 = formData.getOrDefault("PreferredBackupWindow")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "PreferredBackupWindow", valid_773388
  var valid_773389 = formData.getOrDefault("LicenseModel")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "LicenseModel", valid_773389
  var valid_773390 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_773390 = validateParameter(valid_773390, JBool, required = false, default = nil)
  if valid_773390 != nil:
    section.add "AutoMinorVersionUpgrade", valid_773390
  var valid_773391 = formData.getOrDefault("EngineVersion")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "EngineVersion", valid_773391
  var valid_773392 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "PreferredMaintenanceWindow", valid_773392
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773393: Call_PostCreateDBInstance_773357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773393.validator(path, query, header, formData, body)
  let scheme = call_773393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773393.url(scheme.get, call_773393.host, call_773393.base,
                         call_773393.route, valid.getOrDefault("path"))
  result = hook(call_773393, url, valid)

proc call*(call_773394: Call_PostCreateDBInstance_773357; Engine: string;
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
          EngineVersion: string = ""; Version: string = "2013-01-10";
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
  var query_773395 = newJObject()
  var formData_773396 = newJObject()
  if DBSecurityGroups != nil:
    formData_773396.add "DBSecurityGroups", DBSecurityGroups
  add(formData_773396, "Port", newJInt(Port))
  add(formData_773396, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_773396.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_773396, "Iops", newJInt(Iops))
  add(formData_773396, "DBName", newJString(DBName))
  add(formData_773396, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_773396, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_773396, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_773396, "OptionGroupName", newJString(OptionGroupName))
  add(formData_773396, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_773396, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_773396, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_773396, "MultiAZ", newJBool(MultiAZ))
  add(query_773395, "Action", newJString(Action))
  add(formData_773396, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_773396, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_773396, "MasterUsername", newJString(MasterUsername))
  add(formData_773396, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_773396, "CharacterSetName", newJString(CharacterSetName))
  add(formData_773396, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_773396, "LicenseModel", newJString(LicenseModel))
  add(formData_773396, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_773396, "EngineVersion", newJString(EngineVersion))
  add(query_773395, "Version", newJString(Version))
  add(formData_773396, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_773394.call(nil, query_773395, nil, formData_773396, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_773357(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_773358, base: "/",
    url: url_PostCreateDBInstance_773359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_773318 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBInstance_773320(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstance_773319(path: JsonNode; query: JsonNode;
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
  var valid_773321 = query.getOrDefault("Engine")
  valid_773321 = validateParameter(valid_773321, JString, required = true,
                                 default = nil)
  if valid_773321 != nil:
    section.add "Engine", valid_773321
  var valid_773322 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "PreferredMaintenanceWindow", valid_773322
  var valid_773323 = query.getOrDefault("AllocatedStorage")
  valid_773323 = validateParameter(valid_773323, JInt, required = true, default = nil)
  if valid_773323 != nil:
    section.add "AllocatedStorage", valid_773323
  var valid_773324 = query.getOrDefault("OptionGroupName")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "OptionGroupName", valid_773324
  var valid_773325 = query.getOrDefault("DBSecurityGroups")
  valid_773325 = validateParameter(valid_773325, JArray, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "DBSecurityGroups", valid_773325
  var valid_773326 = query.getOrDefault("MasterUserPassword")
  valid_773326 = validateParameter(valid_773326, JString, required = true,
                                 default = nil)
  if valid_773326 != nil:
    section.add "MasterUserPassword", valid_773326
  var valid_773327 = query.getOrDefault("AvailabilityZone")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "AvailabilityZone", valid_773327
  var valid_773328 = query.getOrDefault("Iops")
  valid_773328 = validateParameter(valid_773328, JInt, required = false, default = nil)
  if valid_773328 != nil:
    section.add "Iops", valid_773328
  var valid_773329 = query.getOrDefault("VpcSecurityGroupIds")
  valid_773329 = validateParameter(valid_773329, JArray, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "VpcSecurityGroupIds", valid_773329
  var valid_773330 = query.getOrDefault("MultiAZ")
  valid_773330 = validateParameter(valid_773330, JBool, required = false, default = nil)
  if valid_773330 != nil:
    section.add "MultiAZ", valid_773330
  var valid_773331 = query.getOrDefault("LicenseModel")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "LicenseModel", valid_773331
  var valid_773332 = query.getOrDefault("BackupRetentionPeriod")
  valid_773332 = validateParameter(valid_773332, JInt, required = false, default = nil)
  if valid_773332 != nil:
    section.add "BackupRetentionPeriod", valid_773332
  var valid_773333 = query.getOrDefault("DBName")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "DBName", valid_773333
  var valid_773334 = query.getOrDefault("DBParameterGroupName")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "DBParameterGroupName", valid_773334
  var valid_773335 = query.getOrDefault("DBInstanceClass")
  valid_773335 = validateParameter(valid_773335, JString, required = true,
                                 default = nil)
  if valid_773335 != nil:
    section.add "DBInstanceClass", valid_773335
  var valid_773336 = query.getOrDefault("Action")
  valid_773336 = validateParameter(valid_773336, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_773336 != nil:
    section.add "Action", valid_773336
  var valid_773337 = query.getOrDefault("DBSubnetGroupName")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "DBSubnetGroupName", valid_773337
  var valid_773338 = query.getOrDefault("CharacterSetName")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "CharacterSetName", valid_773338
  var valid_773339 = query.getOrDefault("PubliclyAccessible")
  valid_773339 = validateParameter(valid_773339, JBool, required = false, default = nil)
  if valid_773339 != nil:
    section.add "PubliclyAccessible", valid_773339
  var valid_773340 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_773340 = validateParameter(valid_773340, JBool, required = false, default = nil)
  if valid_773340 != nil:
    section.add "AutoMinorVersionUpgrade", valid_773340
  var valid_773341 = query.getOrDefault("EngineVersion")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "EngineVersion", valid_773341
  var valid_773342 = query.getOrDefault("Port")
  valid_773342 = validateParameter(valid_773342, JInt, required = false, default = nil)
  if valid_773342 != nil:
    section.add "Port", valid_773342
  var valid_773343 = query.getOrDefault("PreferredBackupWindow")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "PreferredBackupWindow", valid_773343
  var valid_773344 = query.getOrDefault("Version")
  valid_773344 = validateParameter(valid_773344, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773344 != nil:
    section.add "Version", valid_773344
  var valid_773345 = query.getOrDefault("DBInstanceIdentifier")
  valid_773345 = validateParameter(valid_773345, JString, required = true,
                                 default = nil)
  if valid_773345 != nil:
    section.add "DBInstanceIdentifier", valid_773345
  var valid_773346 = query.getOrDefault("MasterUsername")
  valid_773346 = validateParameter(valid_773346, JString, required = true,
                                 default = nil)
  if valid_773346 != nil:
    section.add "MasterUsername", valid_773346
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773347 = header.getOrDefault("X-Amz-Date")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Date", valid_773347
  var valid_773348 = header.getOrDefault("X-Amz-Security-Token")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-Security-Token", valid_773348
  var valid_773349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-Content-Sha256", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-Algorithm")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Algorithm", valid_773350
  var valid_773351 = header.getOrDefault("X-Amz-Signature")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-Signature", valid_773351
  var valid_773352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-SignedHeaders", valid_773352
  var valid_773353 = header.getOrDefault("X-Amz-Credential")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-Credential", valid_773353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773354: Call_GetCreateDBInstance_773318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773354.validator(path, query, header, formData, body)
  let scheme = call_773354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773354.url(scheme.get, call_773354.host, call_773354.base,
                         call_773354.route, valid.getOrDefault("path"))
  result = hook(call_773354, url, valid)

proc call*(call_773355: Call_GetCreateDBInstance_773318; Engine: string;
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
          Version: string = "2013-01-10"): Recallable =
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
  var query_773356 = newJObject()
  add(query_773356, "Engine", newJString(Engine))
  add(query_773356, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_773356, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_773356, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_773356.add "DBSecurityGroups", DBSecurityGroups
  add(query_773356, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_773356, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_773356, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_773356.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_773356, "MultiAZ", newJBool(MultiAZ))
  add(query_773356, "LicenseModel", newJString(LicenseModel))
  add(query_773356, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_773356, "DBName", newJString(DBName))
  add(query_773356, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_773356, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_773356, "Action", newJString(Action))
  add(query_773356, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773356, "CharacterSetName", newJString(CharacterSetName))
  add(query_773356, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_773356, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_773356, "EngineVersion", newJString(EngineVersion))
  add(query_773356, "Port", newJInt(Port))
  add(query_773356, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_773356, "Version", newJString(Version))
  add(query_773356, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_773356, "MasterUsername", newJString(MasterUsername))
  result = call_773355.call(nil, query_773356, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_773318(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_773319, base: "/",
    url: url_GetCreateDBInstance_773320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_773421 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBInstanceReadReplica_773423(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstanceReadReplica_773422(path: JsonNode;
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
  var valid_773424 = query.getOrDefault("Action")
  valid_773424 = validateParameter(valid_773424, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_773424 != nil:
    section.add "Action", valid_773424
  var valid_773425 = query.getOrDefault("Version")
  valid_773425 = validateParameter(valid_773425, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773425 != nil:
    section.add "Version", valid_773425
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773426 = header.getOrDefault("X-Amz-Date")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Date", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-Security-Token")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-Security-Token", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Content-Sha256", valid_773428
  var valid_773429 = header.getOrDefault("X-Amz-Algorithm")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "X-Amz-Algorithm", valid_773429
  var valid_773430 = header.getOrDefault("X-Amz-Signature")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Signature", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-SignedHeaders", valid_773431
  var valid_773432 = header.getOrDefault("X-Amz-Credential")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-Credential", valid_773432
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
  var valid_773433 = formData.getOrDefault("Port")
  valid_773433 = validateParameter(valid_773433, JInt, required = false, default = nil)
  if valid_773433 != nil:
    section.add "Port", valid_773433
  var valid_773434 = formData.getOrDefault("Iops")
  valid_773434 = validateParameter(valid_773434, JInt, required = false, default = nil)
  if valid_773434 != nil:
    section.add "Iops", valid_773434
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_773435 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773435 = validateParameter(valid_773435, JString, required = true,
                                 default = nil)
  if valid_773435 != nil:
    section.add "DBInstanceIdentifier", valid_773435
  var valid_773436 = formData.getOrDefault("OptionGroupName")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "OptionGroupName", valid_773436
  var valid_773437 = formData.getOrDefault("AvailabilityZone")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "AvailabilityZone", valid_773437
  var valid_773438 = formData.getOrDefault("PubliclyAccessible")
  valid_773438 = validateParameter(valid_773438, JBool, required = false, default = nil)
  if valid_773438 != nil:
    section.add "PubliclyAccessible", valid_773438
  var valid_773439 = formData.getOrDefault("DBInstanceClass")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "DBInstanceClass", valid_773439
  var valid_773440 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_773440 = validateParameter(valid_773440, JString, required = true,
                                 default = nil)
  if valid_773440 != nil:
    section.add "SourceDBInstanceIdentifier", valid_773440
  var valid_773441 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_773441 = validateParameter(valid_773441, JBool, required = false, default = nil)
  if valid_773441 != nil:
    section.add "AutoMinorVersionUpgrade", valid_773441
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773442: Call_PostCreateDBInstanceReadReplica_773421;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_773442.validator(path, query, header, formData, body)
  let scheme = call_773442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773442.url(scheme.get, call_773442.host, call_773442.base,
                         call_773442.route, valid.getOrDefault("path"))
  result = hook(call_773442, url, valid)

proc call*(call_773443: Call_PostCreateDBInstanceReadReplica_773421;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Port: int = 0; Iops: int = 0; OptionGroupName: string = "";
          AvailabilityZone: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          PubliclyAccessible: bool = false; DBInstanceClass: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2013-01-10"): Recallable =
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
  var query_773444 = newJObject()
  var formData_773445 = newJObject()
  add(formData_773445, "Port", newJInt(Port))
  add(formData_773445, "Iops", newJInt(Iops))
  add(formData_773445, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_773445, "OptionGroupName", newJString(OptionGroupName))
  add(formData_773445, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_773444, "Action", newJString(Action))
  add(formData_773445, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_773445, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_773445, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_773445, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_773444, "Version", newJString(Version))
  result = call_773443.call(nil, query_773444, nil, formData_773445, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_773421(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_773422, base: "/",
    url: url_PostCreateDBInstanceReadReplica_773423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_773397 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBInstanceReadReplica_773399(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstanceReadReplica_773398(path: JsonNode;
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
  var valid_773400 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_773400 = validateParameter(valid_773400, JString, required = true,
                                 default = nil)
  if valid_773400 != nil:
    section.add "SourceDBInstanceIdentifier", valid_773400
  var valid_773401 = query.getOrDefault("OptionGroupName")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "OptionGroupName", valid_773401
  var valid_773402 = query.getOrDefault("AvailabilityZone")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "AvailabilityZone", valid_773402
  var valid_773403 = query.getOrDefault("Iops")
  valid_773403 = validateParameter(valid_773403, JInt, required = false, default = nil)
  if valid_773403 != nil:
    section.add "Iops", valid_773403
  var valid_773404 = query.getOrDefault("DBInstanceClass")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "DBInstanceClass", valid_773404
  var valid_773405 = query.getOrDefault("Action")
  valid_773405 = validateParameter(valid_773405, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_773405 != nil:
    section.add "Action", valid_773405
  var valid_773406 = query.getOrDefault("PubliclyAccessible")
  valid_773406 = validateParameter(valid_773406, JBool, required = false, default = nil)
  if valid_773406 != nil:
    section.add "PubliclyAccessible", valid_773406
  var valid_773407 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_773407 = validateParameter(valid_773407, JBool, required = false, default = nil)
  if valid_773407 != nil:
    section.add "AutoMinorVersionUpgrade", valid_773407
  var valid_773408 = query.getOrDefault("Port")
  valid_773408 = validateParameter(valid_773408, JInt, required = false, default = nil)
  if valid_773408 != nil:
    section.add "Port", valid_773408
  var valid_773409 = query.getOrDefault("Version")
  valid_773409 = validateParameter(valid_773409, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773409 != nil:
    section.add "Version", valid_773409
  var valid_773410 = query.getOrDefault("DBInstanceIdentifier")
  valid_773410 = validateParameter(valid_773410, JString, required = true,
                                 default = nil)
  if valid_773410 != nil:
    section.add "DBInstanceIdentifier", valid_773410
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773411 = header.getOrDefault("X-Amz-Date")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-Date", valid_773411
  var valid_773412 = header.getOrDefault("X-Amz-Security-Token")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Security-Token", valid_773412
  var valid_773413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Content-Sha256", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-Algorithm")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-Algorithm", valid_773414
  var valid_773415 = header.getOrDefault("X-Amz-Signature")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Signature", valid_773415
  var valid_773416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-SignedHeaders", valid_773416
  var valid_773417 = header.getOrDefault("X-Amz-Credential")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Credential", valid_773417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773418: Call_GetCreateDBInstanceReadReplica_773397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773418.validator(path, query, header, formData, body)
  let scheme = call_773418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773418.url(scheme.get, call_773418.host, call_773418.base,
                         call_773418.route, valid.getOrDefault("path"))
  result = hook(call_773418, url, valid)

proc call*(call_773419: Call_GetCreateDBInstanceReadReplica_773397;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          OptionGroupName: string = ""; AvailabilityZone: string = ""; Iops: int = 0;
          DBInstanceClass: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Port: int = 0; Version: string = "2013-01-10"): Recallable =
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
  var query_773420 = newJObject()
  add(query_773420, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_773420, "OptionGroupName", newJString(OptionGroupName))
  add(query_773420, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_773420, "Iops", newJInt(Iops))
  add(query_773420, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_773420, "Action", newJString(Action))
  add(query_773420, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_773420, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_773420, "Port", newJInt(Port))
  add(query_773420, "Version", newJString(Version))
  add(query_773420, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_773419.call(nil, query_773420, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_773397(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_773398, base: "/",
    url: url_GetCreateDBInstanceReadReplica_773399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_773464 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBParameterGroup_773466(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBParameterGroup_773465(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773467 = query.getOrDefault("Action")
  valid_773467 = validateParameter(valid_773467, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_773467 != nil:
    section.add "Action", valid_773467
  var valid_773468 = query.getOrDefault("Version")
  valid_773468 = validateParameter(valid_773468, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773468 != nil:
    section.add "Version", valid_773468
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773469 = header.getOrDefault("X-Amz-Date")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Date", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-Security-Token")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-Security-Token", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Content-Sha256", valid_773471
  var valid_773472 = header.getOrDefault("X-Amz-Algorithm")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-Algorithm", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-Signature")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-Signature", valid_773473
  var valid_773474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773474 = validateParameter(valid_773474, JString, required = false,
                                 default = nil)
  if valid_773474 != nil:
    section.add "X-Amz-SignedHeaders", valid_773474
  var valid_773475 = header.getOrDefault("X-Amz-Credential")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-Credential", valid_773475
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_773476 = formData.getOrDefault("DBParameterGroupName")
  valid_773476 = validateParameter(valid_773476, JString, required = true,
                                 default = nil)
  if valid_773476 != nil:
    section.add "DBParameterGroupName", valid_773476
  var valid_773477 = formData.getOrDefault("DBParameterGroupFamily")
  valid_773477 = validateParameter(valid_773477, JString, required = true,
                                 default = nil)
  if valid_773477 != nil:
    section.add "DBParameterGroupFamily", valid_773477
  var valid_773478 = formData.getOrDefault("Description")
  valid_773478 = validateParameter(valid_773478, JString, required = true,
                                 default = nil)
  if valid_773478 != nil:
    section.add "Description", valid_773478
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773479: Call_PostCreateDBParameterGroup_773464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773479.validator(path, query, header, formData, body)
  let scheme = call_773479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773479.url(scheme.get, call_773479.host, call_773479.base,
                         call_773479.route, valid.getOrDefault("path"))
  result = hook(call_773479, url, valid)

proc call*(call_773480: Call_PostCreateDBParameterGroup_773464;
          DBParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Description: string (required)
  var query_773481 = newJObject()
  var formData_773482 = newJObject()
  add(formData_773482, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_773481, "Action", newJString(Action))
  add(formData_773482, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_773481, "Version", newJString(Version))
  add(formData_773482, "Description", newJString(Description))
  result = call_773480.call(nil, query_773481, nil, formData_773482, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_773464(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_773465, base: "/",
    url: url_PostCreateDBParameterGroup_773466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_773446 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBParameterGroup_773448(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBParameterGroup_773447(path: JsonNode; query: JsonNode;
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
  var valid_773449 = query.getOrDefault("Description")
  valid_773449 = validateParameter(valid_773449, JString, required = true,
                                 default = nil)
  if valid_773449 != nil:
    section.add "Description", valid_773449
  var valid_773450 = query.getOrDefault("DBParameterGroupFamily")
  valid_773450 = validateParameter(valid_773450, JString, required = true,
                                 default = nil)
  if valid_773450 != nil:
    section.add "DBParameterGroupFamily", valid_773450
  var valid_773451 = query.getOrDefault("DBParameterGroupName")
  valid_773451 = validateParameter(valid_773451, JString, required = true,
                                 default = nil)
  if valid_773451 != nil:
    section.add "DBParameterGroupName", valid_773451
  var valid_773452 = query.getOrDefault("Action")
  valid_773452 = validateParameter(valid_773452, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_773452 != nil:
    section.add "Action", valid_773452
  var valid_773453 = query.getOrDefault("Version")
  valid_773453 = validateParameter(valid_773453, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773453 != nil:
    section.add "Version", valid_773453
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773454 = header.getOrDefault("X-Amz-Date")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-Date", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-Security-Token")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Security-Token", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Content-Sha256", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-Algorithm")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Algorithm", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-Signature")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-Signature", valid_773458
  var valid_773459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "X-Amz-SignedHeaders", valid_773459
  var valid_773460 = header.getOrDefault("X-Amz-Credential")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-Credential", valid_773460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773461: Call_GetCreateDBParameterGroup_773446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773461.validator(path, query, header, formData, body)
  let scheme = call_773461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773461.url(scheme.get, call_773461.host, call_773461.base,
                         call_773461.route, valid.getOrDefault("path"))
  result = hook(call_773461, url, valid)

proc call*(call_773462: Call_GetCreateDBParameterGroup_773446; Description: string;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773463 = newJObject()
  add(query_773463, "Description", newJString(Description))
  add(query_773463, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_773463, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_773463, "Action", newJString(Action))
  add(query_773463, "Version", newJString(Version))
  result = call_773462.call(nil, query_773463, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_773446(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_773447, base: "/",
    url: url_GetCreateDBParameterGroup_773448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_773500 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBSecurityGroup_773502(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSecurityGroup_773501(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773503 = query.getOrDefault("Action")
  valid_773503 = validateParameter(valid_773503, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_773503 != nil:
    section.add "Action", valid_773503
  var valid_773504 = query.getOrDefault("Version")
  valid_773504 = validateParameter(valid_773504, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773504 != nil:
    section.add "Version", valid_773504
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773505 = header.getOrDefault("X-Amz-Date")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Date", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-Security-Token")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Security-Token", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Content-Sha256", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-Algorithm")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-Algorithm", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Signature")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Signature", valid_773509
  var valid_773510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773510 = validateParameter(valid_773510, JString, required = false,
                                 default = nil)
  if valid_773510 != nil:
    section.add "X-Amz-SignedHeaders", valid_773510
  var valid_773511 = header.getOrDefault("X-Amz-Credential")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-Credential", valid_773511
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_773512 = formData.getOrDefault("DBSecurityGroupName")
  valid_773512 = validateParameter(valid_773512, JString, required = true,
                                 default = nil)
  if valid_773512 != nil:
    section.add "DBSecurityGroupName", valid_773512
  var valid_773513 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_773513 = validateParameter(valid_773513, JString, required = true,
                                 default = nil)
  if valid_773513 != nil:
    section.add "DBSecurityGroupDescription", valid_773513
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773514: Call_PostCreateDBSecurityGroup_773500; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773514.validator(path, query, header, formData, body)
  let scheme = call_773514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773514.url(scheme.get, call_773514.host, call_773514.base,
                         call_773514.route, valid.getOrDefault("path"))
  result = hook(call_773514, url, valid)

proc call*(call_773515: Call_PostCreateDBSecurityGroup_773500;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_773516 = newJObject()
  var formData_773517 = newJObject()
  add(formData_773517, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_773516, "Action", newJString(Action))
  add(formData_773517, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_773516, "Version", newJString(Version))
  result = call_773515.call(nil, query_773516, nil, formData_773517, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_773500(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_773501, base: "/",
    url: url_PostCreateDBSecurityGroup_773502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_773483 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBSecurityGroup_773485(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSecurityGroup_773484(path: JsonNode; query: JsonNode;
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
  var valid_773486 = query.getOrDefault("DBSecurityGroupName")
  valid_773486 = validateParameter(valid_773486, JString, required = true,
                                 default = nil)
  if valid_773486 != nil:
    section.add "DBSecurityGroupName", valid_773486
  var valid_773487 = query.getOrDefault("DBSecurityGroupDescription")
  valid_773487 = validateParameter(valid_773487, JString, required = true,
                                 default = nil)
  if valid_773487 != nil:
    section.add "DBSecurityGroupDescription", valid_773487
  var valid_773488 = query.getOrDefault("Action")
  valid_773488 = validateParameter(valid_773488, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_773488 != nil:
    section.add "Action", valid_773488
  var valid_773489 = query.getOrDefault("Version")
  valid_773489 = validateParameter(valid_773489, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773489 != nil:
    section.add "Version", valid_773489
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773490 = header.getOrDefault("X-Amz-Date")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Date", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Security-Token")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Security-Token", valid_773491
  var valid_773492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773492 = validateParameter(valid_773492, JString, required = false,
                                 default = nil)
  if valid_773492 != nil:
    section.add "X-Amz-Content-Sha256", valid_773492
  var valid_773493 = header.getOrDefault("X-Amz-Algorithm")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Algorithm", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-Signature")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Signature", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-SignedHeaders", valid_773495
  var valid_773496 = header.getOrDefault("X-Amz-Credential")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-Credential", valid_773496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773497: Call_GetCreateDBSecurityGroup_773483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773497.validator(path, query, header, formData, body)
  let scheme = call_773497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773497.url(scheme.get, call_773497.host, call_773497.base,
                         call_773497.route, valid.getOrDefault("path"))
  result = hook(call_773497, url, valid)

proc call*(call_773498: Call_GetCreateDBSecurityGroup_773483;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773499 = newJObject()
  add(query_773499, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_773499, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_773499, "Action", newJString(Action))
  add(query_773499, "Version", newJString(Version))
  result = call_773498.call(nil, query_773499, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_773483(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_773484, base: "/",
    url: url_GetCreateDBSecurityGroup_773485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_773535 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBSnapshot_773537(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSnapshot_773536(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773538 = query.getOrDefault("Action")
  valid_773538 = validateParameter(valid_773538, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_773538 != nil:
    section.add "Action", valid_773538
  var valid_773539 = query.getOrDefault("Version")
  valid_773539 = validateParameter(valid_773539, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773539 != nil:
    section.add "Version", valid_773539
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773540 = header.getOrDefault("X-Amz-Date")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Date", valid_773540
  var valid_773541 = header.getOrDefault("X-Amz-Security-Token")
  valid_773541 = validateParameter(valid_773541, JString, required = false,
                                 default = nil)
  if valid_773541 != nil:
    section.add "X-Amz-Security-Token", valid_773541
  var valid_773542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Content-Sha256", valid_773542
  var valid_773543 = header.getOrDefault("X-Amz-Algorithm")
  valid_773543 = validateParameter(valid_773543, JString, required = false,
                                 default = nil)
  if valid_773543 != nil:
    section.add "X-Amz-Algorithm", valid_773543
  var valid_773544 = header.getOrDefault("X-Amz-Signature")
  valid_773544 = validateParameter(valid_773544, JString, required = false,
                                 default = nil)
  if valid_773544 != nil:
    section.add "X-Amz-Signature", valid_773544
  var valid_773545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773545 = validateParameter(valid_773545, JString, required = false,
                                 default = nil)
  if valid_773545 != nil:
    section.add "X-Amz-SignedHeaders", valid_773545
  var valid_773546 = header.getOrDefault("X-Amz-Credential")
  valid_773546 = validateParameter(valid_773546, JString, required = false,
                                 default = nil)
  if valid_773546 != nil:
    section.add "X-Amz-Credential", valid_773546
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_773547 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773547 = validateParameter(valid_773547, JString, required = true,
                                 default = nil)
  if valid_773547 != nil:
    section.add "DBInstanceIdentifier", valid_773547
  var valid_773548 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_773548 = validateParameter(valid_773548, JString, required = true,
                                 default = nil)
  if valid_773548 != nil:
    section.add "DBSnapshotIdentifier", valid_773548
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773549: Call_PostCreateDBSnapshot_773535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773549.validator(path, query, header, formData, body)
  let scheme = call_773549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773549.url(scheme.get, call_773549.host, call_773549.base,
                         call_773549.route, valid.getOrDefault("path"))
  result = hook(call_773549, url, valid)

proc call*(call_773550: Call_PostCreateDBSnapshot_773535;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773551 = newJObject()
  var formData_773552 = newJObject()
  add(formData_773552, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_773552, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_773551, "Action", newJString(Action))
  add(query_773551, "Version", newJString(Version))
  result = call_773550.call(nil, query_773551, nil, formData_773552, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_773535(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_773536, base: "/",
    url: url_PostCreateDBSnapshot_773537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_773518 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBSnapshot_773520(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSnapshot_773519(path: JsonNode; query: JsonNode;
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
  var valid_773521 = query.getOrDefault("Action")
  valid_773521 = validateParameter(valid_773521, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_773521 != nil:
    section.add "Action", valid_773521
  var valid_773522 = query.getOrDefault("Version")
  valid_773522 = validateParameter(valid_773522, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773522 != nil:
    section.add "Version", valid_773522
  var valid_773523 = query.getOrDefault("DBInstanceIdentifier")
  valid_773523 = validateParameter(valid_773523, JString, required = true,
                                 default = nil)
  if valid_773523 != nil:
    section.add "DBInstanceIdentifier", valid_773523
  var valid_773524 = query.getOrDefault("DBSnapshotIdentifier")
  valid_773524 = validateParameter(valid_773524, JString, required = true,
                                 default = nil)
  if valid_773524 != nil:
    section.add "DBSnapshotIdentifier", valid_773524
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773525 = header.getOrDefault("X-Amz-Date")
  valid_773525 = validateParameter(valid_773525, JString, required = false,
                                 default = nil)
  if valid_773525 != nil:
    section.add "X-Amz-Date", valid_773525
  var valid_773526 = header.getOrDefault("X-Amz-Security-Token")
  valid_773526 = validateParameter(valid_773526, JString, required = false,
                                 default = nil)
  if valid_773526 != nil:
    section.add "X-Amz-Security-Token", valid_773526
  var valid_773527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Content-Sha256", valid_773527
  var valid_773528 = header.getOrDefault("X-Amz-Algorithm")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "X-Amz-Algorithm", valid_773528
  var valid_773529 = header.getOrDefault("X-Amz-Signature")
  valid_773529 = validateParameter(valid_773529, JString, required = false,
                                 default = nil)
  if valid_773529 != nil:
    section.add "X-Amz-Signature", valid_773529
  var valid_773530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773530 = validateParameter(valid_773530, JString, required = false,
                                 default = nil)
  if valid_773530 != nil:
    section.add "X-Amz-SignedHeaders", valid_773530
  var valid_773531 = header.getOrDefault("X-Amz-Credential")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "X-Amz-Credential", valid_773531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773532: Call_GetCreateDBSnapshot_773518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773532.validator(path, query, header, formData, body)
  let scheme = call_773532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773532.url(scheme.get, call_773532.host, call_773532.base,
                         call_773532.route, valid.getOrDefault("path"))
  result = hook(call_773532, url, valid)

proc call*(call_773533: Call_GetCreateDBSnapshot_773518;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_773534 = newJObject()
  add(query_773534, "Action", newJString(Action))
  add(query_773534, "Version", newJString(Version))
  add(query_773534, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_773534, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_773533.call(nil, query_773534, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_773518(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_773519, base: "/",
    url: url_GetCreateDBSnapshot_773520, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_773571 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBSubnetGroup_773573(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSubnetGroup_773572(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773574 = query.getOrDefault("Action")
  valid_773574 = validateParameter(valid_773574, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_773574 != nil:
    section.add "Action", valid_773574
  var valid_773575 = query.getOrDefault("Version")
  valid_773575 = validateParameter(valid_773575, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773575 != nil:
    section.add "Version", valid_773575
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773576 = header.getOrDefault("X-Amz-Date")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "X-Amz-Date", valid_773576
  var valid_773577 = header.getOrDefault("X-Amz-Security-Token")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-Security-Token", valid_773577
  var valid_773578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773578 = validateParameter(valid_773578, JString, required = false,
                                 default = nil)
  if valid_773578 != nil:
    section.add "X-Amz-Content-Sha256", valid_773578
  var valid_773579 = header.getOrDefault("X-Amz-Algorithm")
  valid_773579 = validateParameter(valid_773579, JString, required = false,
                                 default = nil)
  if valid_773579 != nil:
    section.add "X-Amz-Algorithm", valid_773579
  var valid_773580 = header.getOrDefault("X-Amz-Signature")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Signature", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-SignedHeaders", valid_773581
  var valid_773582 = header.getOrDefault("X-Amz-Credential")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "X-Amz-Credential", valid_773582
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_773583 = formData.getOrDefault("DBSubnetGroupName")
  valid_773583 = validateParameter(valid_773583, JString, required = true,
                                 default = nil)
  if valid_773583 != nil:
    section.add "DBSubnetGroupName", valid_773583
  var valid_773584 = formData.getOrDefault("SubnetIds")
  valid_773584 = validateParameter(valid_773584, JArray, required = true, default = nil)
  if valid_773584 != nil:
    section.add "SubnetIds", valid_773584
  var valid_773585 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_773585 = validateParameter(valid_773585, JString, required = true,
                                 default = nil)
  if valid_773585 != nil:
    section.add "DBSubnetGroupDescription", valid_773585
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773586: Call_PostCreateDBSubnetGroup_773571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773586.validator(path, query, header, formData, body)
  let scheme = call_773586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773586.url(scheme.get, call_773586.host, call_773586.base,
                         call_773586.route, valid.getOrDefault("path"))
  result = hook(call_773586, url, valid)

proc call*(call_773587: Call_PostCreateDBSubnetGroup_773571;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_773588 = newJObject()
  var formData_773589 = newJObject()
  add(formData_773589, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_773589.add "SubnetIds", SubnetIds
  add(query_773588, "Action", newJString(Action))
  add(formData_773589, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_773588, "Version", newJString(Version))
  result = call_773587.call(nil, query_773588, nil, formData_773589, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_773571(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_773572, base: "/",
    url: url_PostCreateDBSubnetGroup_773573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_773553 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBSubnetGroup_773555(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSubnetGroup_773554(path: JsonNode; query: JsonNode;
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
  var valid_773556 = query.getOrDefault("Action")
  valid_773556 = validateParameter(valid_773556, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_773556 != nil:
    section.add "Action", valid_773556
  var valid_773557 = query.getOrDefault("DBSubnetGroupName")
  valid_773557 = validateParameter(valid_773557, JString, required = true,
                                 default = nil)
  if valid_773557 != nil:
    section.add "DBSubnetGroupName", valid_773557
  var valid_773558 = query.getOrDefault("SubnetIds")
  valid_773558 = validateParameter(valid_773558, JArray, required = true, default = nil)
  if valid_773558 != nil:
    section.add "SubnetIds", valid_773558
  var valid_773559 = query.getOrDefault("DBSubnetGroupDescription")
  valid_773559 = validateParameter(valid_773559, JString, required = true,
                                 default = nil)
  if valid_773559 != nil:
    section.add "DBSubnetGroupDescription", valid_773559
  var valid_773560 = query.getOrDefault("Version")
  valid_773560 = validateParameter(valid_773560, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773560 != nil:
    section.add "Version", valid_773560
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773561 = header.getOrDefault("X-Amz-Date")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-Date", valid_773561
  var valid_773562 = header.getOrDefault("X-Amz-Security-Token")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-Security-Token", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Content-Sha256", valid_773563
  var valid_773564 = header.getOrDefault("X-Amz-Algorithm")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-Algorithm", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-Signature")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-Signature", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-SignedHeaders", valid_773566
  var valid_773567 = header.getOrDefault("X-Amz-Credential")
  valid_773567 = validateParameter(valid_773567, JString, required = false,
                                 default = nil)
  if valid_773567 != nil:
    section.add "X-Amz-Credential", valid_773567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773568: Call_GetCreateDBSubnetGroup_773553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773568.validator(path, query, header, formData, body)
  let scheme = call_773568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773568.url(scheme.get, call_773568.host, call_773568.base,
                         call_773568.route, valid.getOrDefault("path"))
  result = hook(call_773568, url, valid)

proc call*(call_773569: Call_GetCreateDBSubnetGroup_773553;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_773570 = newJObject()
  add(query_773570, "Action", newJString(Action))
  add(query_773570, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_773570.add "SubnetIds", SubnetIds
  add(query_773570, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_773570, "Version", newJString(Version))
  result = call_773569.call(nil, query_773570, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_773553(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_773554, base: "/",
    url: url_GetCreateDBSubnetGroup_773555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_773611 = ref object of OpenApiRestCall_772581
proc url_PostCreateEventSubscription_773613(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateEventSubscription_773612(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773614 = query.getOrDefault("Action")
  valid_773614 = validateParameter(valid_773614, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_773614 != nil:
    section.add "Action", valid_773614
  var valid_773615 = query.getOrDefault("Version")
  valid_773615 = validateParameter(valid_773615, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773615 != nil:
    section.add "Version", valid_773615
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773616 = header.getOrDefault("X-Amz-Date")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-Date", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-Security-Token")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Security-Token", valid_773617
  var valid_773618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-Content-Sha256", valid_773618
  var valid_773619 = header.getOrDefault("X-Amz-Algorithm")
  valid_773619 = validateParameter(valid_773619, JString, required = false,
                                 default = nil)
  if valid_773619 != nil:
    section.add "X-Amz-Algorithm", valid_773619
  var valid_773620 = header.getOrDefault("X-Amz-Signature")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "X-Amz-Signature", valid_773620
  var valid_773621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773621 = validateParameter(valid_773621, JString, required = false,
                                 default = nil)
  if valid_773621 != nil:
    section.add "X-Amz-SignedHeaders", valid_773621
  var valid_773622 = header.getOrDefault("X-Amz-Credential")
  valid_773622 = validateParameter(valid_773622, JString, required = false,
                                 default = nil)
  if valid_773622 != nil:
    section.add "X-Amz-Credential", valid_773622
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString (required)
  ##   SourceIds: JArray
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_773623 = formData.getOrDefault("Enabled")
  valid_773623 = validateParameter(valid_773623, JBool, required = false, default = nil)
  if valid_773623 != nil:
    section.add "Enabled", valid_773623
  var valid_773624 = formData.getOrDefault("EventCategories")
  valid_773624 = validateParameter(valid_773624, JArray, required = false,
                                 default = nil)
  if valid_773624 != nil:
    section.add "EventCategories", valid_773624
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_773625 = formData.getOrDefault("SnsTopicArn")
  valid_773625 = validateParameter(valid_773625, JString, required = true,
                                 default = nil)
  if valid_773625 != nil:
    section.add "SnsTopicArn", valid_773625
  var valid_773626 = formData.getOrDefault("SourceIds")
  valid_773626 = validateParameter(valid_773626, JArray, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "SourceIds", valid_773626
  var valid_773627 = formData.getOrDefault("SubscriptionName")
  valid_773627 = validateParameter(valid_773627, JString, required = true,
                                 default = nil)
  if valid_773627 != nil:
    section.add "SubscriptionName", valid_773627
  var valid_773628 = formData.getOrDefault("SourceType")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "SourceType", valid_773628
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773629: Call_PostCreateEventSubscription_773611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773629.validator(path, query, header, formData, body)
  let scheme = call_773629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773629.url(scheme.get, call_773629.host, call_773629.base,
                         call_773629.route, valid.getOrDefault("path"))
  result = hook(call_773629, url, valid)

proc call*(call_773630: Call_PostCreateEventSubscription_773611;
          SnsTopicArn: string; SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SourceIds: JsonNode = nil;
          Action: string = "CreateEventSubscription";
          Version: string = "2013-01-10"; SourceType: string = ""): Recallable =
  ## postCreateEventSubscription
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   SnsTopicArn: string (required)
  ##   SourceIds: JArray
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_773631 = newJObject()
  var formData_773632 = newJObject()
  add(formData_773632, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_773632.add "EventCategories", EventCategories
  add(formData_773632, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_773632.add "SourceIds", SourceIds
  add(formData_773632, "SubscriptionName", newJString(SubscriptionName))
  add(query_773631, "Action", newJString(Action))
  add(query_773631, "Version", newJString(Version))
  add(formData_773632, "SourceType", newJString(SourceType))
  result = call_773630.call(nil, query_773631, nil, formData_773632, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_773611(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_773612, base: "/",
    url: url_PostCreateEventSubscription_773613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_773590 = ref object of OpenApiRestCall_772581
proc url_GetCreateEventSubscription_773592(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateEventSubscription_773591(path: JsonNode; query: JsonNode;
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
  var valid_773593 = query.getOrDefault("SourceType")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "SourceType", valid_773593
  var valid_773594 = query.getOrDefault("SourceIds")
  valid_773594 = validateParameter(valid_773594, JArray, required = false,
                                 default = nil)
  if valid_773594 != nil:
    section.add "SourceIds", valid_773594
  var valid_773595 = query.getOrDefault("Enabled")
  valid_773595 = validateParameter(valid_773595, JBool, required = false, default = nil)
  if valid_773595 != nil:
    section.add "Enabled", valid_773595
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773596 = query.getOrDefault("Action")
  valid_773596 = validateParameter(valid_773596, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_773596 != nil:
    section.add "Action", valid_773596
  var valid_773597 = query.getOrDefault("SnsTopicArn")
  valid_773597 = validateParameter(valid_773597, JString, required = true,
                                 default = nil)
  if valid_773597 != nil:
    section.add "SnsTopicArn", valid_773597
  var valid_773598 = query.getOrDefault("EventCategories")
  valid_773598 = validateParameter(valid_773598, JArray, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "EventCategories", valid_773598
  var valid_773599 = query.getOrDefault("SubscriptionName")
  valid_773599 = validateParameter(valid_773599, JString, required = true,
                                 default = nil)
  if valid_773599 != nil:
    section.add "SubscriptionName", valid_773599
  var valid_773600 = query.getOrDefault("Version")
  valid_773600 = validateParameter(valid_773600, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773600 != nil:
    section.add "Version", valid_773600
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773601 = header.getOrDefault("X-Amz-Date")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-Date", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Security-Token")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Security-Token", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-Content-Sha256", valid_773603
  var valid_773604 = header.getOrDefault("X-Amz-Algorithm")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "X-Amz-Algorithm", valid_773604
  var valid_773605 = header.getOrDefault("X-Amz-Signature")
  valid_773605 = validateParameter(valid_773605, JString, required = false,
                                 default = nil)
  if valid_773605 != nil:
    section.add "X-Amz-Signature", valid_773605
  var valid_773606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773606 = validateParameter(valid_773606, JString, required = false,
                                 default = nil)
  if valid_773606 != nil:
    section.add "X-Amz-SignedHeaders", valid_773606
  var valid_773607 = header.getOrDefault("X-Amz-Credential")
  valid_773607 = validateParameter(valid_773607, JString, required = false,
                                 default = nil)
  if valid_773607 != nil:
    section.add "X-Amz-Credential", valid_773607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773608: Call_GetCreateEventSubscription_773590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773608.validator(path, query, header, formData, body)
  let scheme = call_773608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773608.url(scheme.get, call_773608.host, call_773608.base,
                         call_773608.route, valid.getOrDefault("path"))
  result = hook(call_773608, url, valid)

proc call*(call_773609: Call_GetCreateEventSubscription_773590;
          SnsTopicArn: string; SubscriptionName: string; SourceType: string = "";
          SourceIds: JsonNode = nil; Enabled: bool = false;
          Action: string = "CreateEventSubscription";
          EventCategories: JsonNode = nil; Version: string = "2013-01-10"): Recallable =
  ## getCreateEventSubscription
  ##   SourceType: string
  ##   SourceIds: JArray
  ##   Enabled: bool
  ##   Action: string (required)
  ##   SnsTopicArn: string (required)
  ##   EventCategories: JArray
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_773610 = newJObject()
  add(query_773610, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_773610.add "SourceIds", SourceIds
  add(query_773610, "Enabled", newJBool(Enabled))
  add(query_773610, "Action", newJString(Action))
  add(query_773610, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_773610.add "EventCategories", EventCategories
  add(query_773610, "SubscriptionName", newJString(SubscriptionName))
  add(query_773610, "Version", newJString(Version))
  result = call_773609.call(nil, query_773610, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_773590(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_773591, base: "/",
    url: url_GetCreateEventSubscription_773592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_773652 = ref object of OpenApiRestCall_772581
proc url_PostCreateOptionGroup_773654(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateOptionGroup_773653(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773655 = query.getOrDefault("Action")
  valid_773655 = validateParameter(valid_773655, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_773655 != nil:
    section.add "Action", valid_773655
  var valid_773656 = query.getOrDefault("Version")
  valid_773656 = validateParameter(valid_773656, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773656 != nil:
    section.add "Version", valid_773656
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773657 = header.getOrDefault("X-Amz-Date")
  valid_773657 = validateParameter(valid_773657, JString, required = false,
                                 default = nil)
  if valid_773657 != nil:
    section.add "X-Amz-Date", valid_773657
  var valid_773658 = header.getOrDefault("X-Amz-Security-Token")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-Security-Token", valid_773658
  var valid_773659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Content-Sha256", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-Algorithm")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-Algorithm", valid_773660
  var valid_773661 = header.getOrDefault("X-Amz-Signature")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-Signature", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-SignedHeaders", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-Credential")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Credential", valid_773663
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_773664 = formData.getOrDefault("MajorEngineVersion")
  valid_773664 = validateParameter(valid_773664, JString, required = true,
                                 default = nil)
  if valid_773664 != nil:
    section.add "MajorEngineVersion", valid_773664
  var valid_773665 = formData.getOrDefault("OptionGroupName")
  valid_773665 = validateParameter(valid_773665, JString, required = true,
                                 default = nil)
  if valid_773665 != nil:
    section.add "OptionGroupName", valid_773665
  var valid_773666 = formData.getOrDefault("EngineName")
  valid_773666 = validateParameter(valid_773666, JString, required = true,
                                 default = nil)
  if valid_773666 != nil:
    section.add "EngineName", valid_773666
  var valid_773667 = formData.getOrDefault("OptionGroupDescription")
  valid_773667 = validateParameter(valid_773667, JString, required = true,
                                 default = nil)
  if valid_773667 != nil:
    section.add "OptionGroupDescription", valid_773667
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773668: Call_PostCreateOptionGroup_773652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773668.validator(path, query, header, formData, body)
  let scheme = call_773668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773668.url(scheme.get, call_773668.host, call_773668.base,
                         call_773668.route, valid.getOrDefault("path"))
  result = hook(call_773668, url, valid)

proc call*(call_773669: Call_PostCreateOptionGroup_773652;
          MajorEngineVersion: string; OptionGroupName: string; EngineName: string;
          OptionGroupDescription: string; Action: string = "CreateOptionGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postCreateOptionGroup
  ##   MajorEngineVersion: string (required)
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Version: string (required)
  var query_773670 = newJObject()
  var formData_773671 = newJObject()
  add(formData_773671, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_773671, "OptionGroupName", newJString(OptionGroupName))
  add(query_773670, "Action", newJString(Action))
  add(formData_773671, "EngineName", newJString(EngineName))
  add(formData_773671, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_773670, "Version", newJString(Version))
  result = call_773669.call(nil, query_773670, nil, formData_773671, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_773652(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_773653, base: "/",
    url: url_PostCreateOptionGroup_773654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_773633 = ref object of OpenApiRestCall_772581
proc url_GetCreateOptionGroup_773635(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateOptionGroup_773634(path: JsonNode; query: JsonNode;
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
  var valid_773636 = query.getOrDefault("OptionGroupName")
  valid_773636 = validateParameter(valid_773636, JString, required = true,
                                 default = nil)
  if valid_773636 != nil:
    section.add "OptionGroupName", valid_773636
  var valid_773637 = query.getOrDefault("OptionGroupDescription")
  valid_773637 = validateParameter(valid_773637, JString, required = true,
                                 default = nil)
  if valid_773637 != nil:
    section.add "OptionGroupDescription", valid_773637
  var valid_773638 = query.getOrDefault("Action")
  valid_773638 = validateParameter(valid_773638, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_773638 != nil:
    section.add "Action", valid_773638
  var valid_773639 = query.getOrDefault("Version")
  valid_773639 = validateParameter(valid_773639, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773639 != nil:
    section.add "Version", valid_773639
  var valid_773640 = query.getOrDefault("EngineName")
  valid_773640 = validateParameter(valid_773640, JString, required = true,
                                 default = nil)
  if valid_773640 != nil:
    section.add "EngineName", valid_773640
  var valid_773641 = query.getOrDefault("MajorEngineVersion")
  valid_773641 = validateParameter(valid_773641, JString, required = true,
                                 default = nil)
  if valid_773641 != nil:
    section.add "MajorEngineVersion", valid_773641
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773642 = header.getOrDefault("X-Amz-Date")
  valid_773642 = validateParameter(valid_773642, JString, required = false,
                                 default = nil)
  if valid_773642 != nil:
    section.add "X-Amz-Date", valid_773642
  var valid_773643 = header.getOrDefault("X-Amz-Security-Token")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-Security-Token", valid_773643
  var valid_773644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Content-Sha256", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Algorithm")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Algorithm", valid_773645
  var valid_773646 = header.getOrDefault("X-Amz-Signature")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "X-Amz-Signature", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-SignedHeaders", valid_773647
  var valid_773648 = header.getOrDefault("X-Amz-Credential")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-Credential", valid_773648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773649: Call_GetCreateOptionGroup_773633; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773649.validator(path, query, header, formData, body)
  let scheme = call_773649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773649.url(scheme.get, call_773649.host, call_773649.base,
                         call_773649.route, valid.getOrDefault("path"))
  result = hook(call_773649, url, valid)

proc call*(call_773650: Call_GetCreateOptionGroup_773633; OptionGroupName: string;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; Action: string = "CreateOptionGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getCreateOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  var query_773651 = newJObject()
  add(query_773651, "OptionGroupName", newJString(OptionGroupName))
  add(query_773651, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_773651, "Action", newJString(Action))
  add(query_773651, "Version", newJString(Version))
  add(query_773651, "EngineName", newJString(EngineName))
  add(query_773651, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_773650.call(nil, query_773651, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_773633(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_773634, base: "/",
    url: url_GetCreateOptionGroup_773635, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_773690 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBInstance_773692(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBInstance_773691(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773693 = query.getOrDefault("Action")
  valid_773693 = validateParameter(valid_773693, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_773693 != nil:
    section.add "Action", valid_773693
  var valid_773694 = query.getOrDefault("Version")
  valid_773694 = validateParameter(valid_773694, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773694 != nil:
    section.add "Version", valid_773694
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773695 = header.getOrDefault("X-Amz-Date")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Date", valid_773695
  var valid_773696 = header.getOrDefault("X-Amz-Security-Token")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "X-Amz-Security-Token", valid_773696
  var valid_773697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773697 = validateParameter(valid_773697, JString, required = false,
                                 default = nil)
  if valid_773697 != nil:
    section.add "X-Amz-Content-Sha256", valid_773697
  var valid_773698 = header.getOrDefault("X-Amz-Algorithm")
  valid_773698 = validateParameter(valid_773698, JString, required = false,
                                 default = nil)
  if valid_773698 != nil:
    section.add "X-Amz-Algorithm", valid_773698
  var valid_773699 = header.getOrDefault("X-Amz-Signature")
  valid_773699 = validateParameter(valid_773699, JString, required = false,
                                 default = nil)
  if valid_773699 != nil:
    section.add "X-Amz-Signature", valid_773699
  var valid_773700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773700 = validateParameter(valid_773700, JString, required = false,
                                 default = nil)
  if valid_773700 != nil:
    section.add "X-Amz-SignedHeaders", valid_773700
  var valid_773701 = header.getOrDefault("X-Amz-Credential")
  valid_773701 = validateParameter(valid_773701, JString, required = false,
                                 default = nil)
  if valid_773701 != nil:
    section.add "X-Amz-Credential", valid_773701
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_773702 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773702 = validateParameter(valid_773702, JString, required = true,
                                 default = nil)
  if valid_773702 != nil:
    section.add "DBInstanceIdentifier", valid_773702
  var valid_773703 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_773703 = validateParameter(valid_773703, JString, required = false,
                                 default = nil)
  if valid_773703 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_773703
  var valid_773704 = formData.getOrDefault("SkipFinalSnapshot")
  valid_773704 = validateParameter(valid_773704, JBool, required = false, default = nil)
  if valid_773704 != nil:
    section.add "SkipFinalSnapshot", valid_773704
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773705: Call_PostDeleteDBInstance_773690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773705.validator(path, query, header, formData, body)
  let scheme = call_773705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773705.url(scheme.get, call_773705.host, call_773705.base,
                         call_773705.route, valid.getOrDefault("path"))
  result = hook(call_773705, url, valid)

proc call*(call_773706: Call_PostDeleteDBInstance_773690;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-01-10";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_773707 = newJObject()
  var formData_773708 = newJObject()
  add(formData_773708, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_773708, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_773707, "Action", newJString(Action))
  add(query_773707, "Version", newJString(Version))
  add(formData_773708, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_773706.call(nil, query_773707, nil, formData_773708, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_773690(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_773691, base: "/",
    url: url_PostDeleteDBInstance_773692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_773672 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBInstance_773674(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBInstance_773673(path: JsonNode; query: JsonNode;
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
  var valid_773675 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_773675 = validateParameter(valid_773675, JString, required = false,
                                 default = nil)
  if valid_773675 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_773675
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773676 = query.getOrDefault("Action")
  valid_773676 = validateParameter(valid_773676, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_773676 != nil:
    section.add "Action", valid_773676
  var valid_773677 = query.getOrDefault("SkipFinalSnapshot")
  valid_773677 = validateParameter(valid_773677, JBool, required = false, default = nil)
  if valid_773677 != nil:
    section.add "SkipFinalSnapshot", valid_773677
  var valid_773678 = query.getOrDefault("Version")
  valid_773678 = validateParameter(valid_773678, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773678 != nil:
    section.add "Version", valid_773678
  var valid_773679 = query.getOrDefault("DBInstanceIdentifier")
  valid_773679 = validateParameter(valid_773679, JString, required = true,
                                 default = nil)
  if valid_773679 != nil:
    section.add "DBInstanceIdentifier", valid_773679
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773680 = header.getOrDefault("X-Amz-Date")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Date", valid_773680
  var valid_773681 = header.getOrDefault("X-Amz-Security-Token")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-Security-Token", valid_773681
  var valid_773682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-Content-Sha256", valid_773682
  var valid_773683 = header.getOrDefault("X-Amz-Algorithm")
  valid_773683 = validateParameter(valid_773683, JString, required = false,
                                 default = nil)
  if valid_773683 != nil:
    section.add "X-Amz-Algorithm", valid_773683
  var valid_773684 = header.getOrDefault("X-Amz-Signature")
  valid_773684 = validateParameter(valid_773684, JString, required = false,
                                 default = nil)
  if valid_773684 != nil:
    section.add "X-Amz-Signature", valid_773684
  var valid_773685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773685 = validateParameter(valid_773685, JString, required = false,
                                 default = nil)
  if valid_773685 != nil:
    section.add "X-Amz-SignedHeaders", valid_773685
  var valid_773686 = header.getOrDefault("X-Amz-Credential")
  valid_773686 = validateParameter(valid_773686, JString, required = false,
                                 default = nil)
  if valid_773686 != nil:
    section.add "X-Amz-Credential", valid_773686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773687: Call_GetDeleteDBInstance_773672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773687.validator(path, query, header, formData, body)
  let scheme = call_773687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773687.url(scheme.get, call_773687.host, call_773687.base,
                         call_773687.route, valid.getOrDefault("path"))
  result = hook(call_773687, url, valid)

proc call*(call_773688: Call_GetDeleteDBInstance_773672;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_773689 = newJObject()
  add(query_773689, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_773689, "Action", newJString(Action))
  add(query_773689, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_773689, "Version", newJString(Version))
  add(query_773689, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_773688.call(nil, query_773689, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_773672(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_773673, base: "/",
    url: url_GetDeleteDBInstance_773674, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_773725 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBParameterGroup_773727(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBParameterGroup_773726(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773728 = query.getOrDefault("Action")
  valid_773728 = validateParameter(valid_773728, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_773728 != nil:
    section.add "Action", valid_773728
  var valid_773729 = query.getOrDefault("Version")
  valid_773729 = validateParameter(valid_773729, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773729 != nil:
    section.add "Version", valid_773729
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773730 = header.getOrDefault("X-Amz-Date")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-Date", valid_773730
  var valid_773731 = header.getOrDefault("X-Amz-Security-Token")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "X-Amz-Security-Token", valid_773731
  var valid_773732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773732 = validateParameter(valid_773732, JString, required = false,
                                 default = nil)
  if valid_773732 != nil:
    section.add "X-Amz-Content-Sha256", valid_773732
  var valid_773733 = header.getOrDefault("X-Amz-Algorithm")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = nil)
  if valid_773733 != nil:
    section.add "X-Amz-Algorithm", valid_773733
  var valid_773734 = header.getOrDefault("X-Amz-Signature")
  valid_773734 = validateParameter(valid_773734, JString, required = false,
                                 default = nil)
  if valid_773734 != nil:
    section.add "X-Amz-Signature", valid_773734
  var valid_773735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773735 = validateParameter(valid_773735, JString, required = false,
                                 default = nil)
  if valid_773735 != nil:
    section.add "X-Amz-SignedHeaders", valid_773735
  var valid_773736 = header.getOrDefault("X-Amz-Credential")
  valid_773736 = validateParameter(valid_773736, JString, required = false,
                                 default = nil)
  if valid_773736 != nil:
    section.add "X-Amz-Credential", valid_773736
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_773737 = formData.getOrDefault("DBParameterGroupName")
  valid_773737 = validateParameter(valid_773737, JString, required = true,
                                 default = nil)
  if valid_773737 != nil:
    section.add "DBParameterGroupName", valid_773737
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773738: Call_PostDeleteDBParameterGroup_773725; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773738.validator(path, query, header, formData, body)
  let scheme = call_773738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773738.url(scheme.get, call_773738.host, call_773738.base,
                         call_773738.route, valid.getOrDefault("path"))
  result = hook(call_773738, url, valid)

proc call*(call_773739: Call_PostDeleteDBParameterGroup_773725;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773740 = newJObject()
  var formData_773741 = newJObject()
  add(formData_773741, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_773740, "Action", newJString(Action))
  add(query_773740, "Version", newJString(Version))
  result = call_773739.call(nil, query_773740, nil, formData_773741, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_773725(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_773726, base: "/",
    url: url_PostDeleteDBParameterGroup_773727,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_773709 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBParameterGroup_773711(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBParameterGroup_773710(path: JsonNode; query: JsonNode;
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
  var valid_773712 = query.getOrDefault("DBParameterGroupName")
  valid_773712 = validateParameter(valid_773712, JString, required = true,
                                 default = nil)
  if valid_773712 != nil:
    section.add "DBParameterGroupName", valid_773712
  var valid_773713 = query.getOrDefault("Action")
  valid_773713 = validateParameter(valid_773713, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_773713 != nil:
    section.add "Action", valid_773713
  var valid_773714 = query.getOrDefault("Version")
  valid_773714 = validateParameter(valid_773714, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773714 != nil:
    section.add "Version", valid_773714
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773715 = header.getOrDefault("X-Amz-Date")
  valid_773715 = validateParameter(valid_773715, JString, required = false,
                                 default = nil)
  if valid_773715 != nil:
    section.add "X-Amz-Date", valid_773715
  var valid_773716 = header.getOrDefault("X-Amz-Security-Token")
  valid_773716 = validateParameter(valid_773716, JString, required = false,
                                 default = nil)
  if valid_773716 != nil:
    section.add "X-Amz-Security-Token", valid_773716
  var valid_773717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773717 = validateParameter(valid_773717, JString, required = false,
                                 default = nil)
  if valid_773717 != nil:
    section.add "X-Amz-Content-Sha256", valid_773717
  var valid_773718 = header.getOrDefault("X-Amz-Algorithm")
  valid_773718 = validateParameter(valid_773718, JString, required = false,
                                 default = nil)
  if valid_773718 != nil:
    section.add "X-Amz-Algorithm", valid_773718
  var valid_773719 = header.getOrDefault("X-Amz-Signature")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "X-Amz-Signature", valid_773719
  var valid_773720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "X-Amz-SignedHeaders", valid_773720
  var valid_773721 = header.getOrDefault("X-Amz-Credential")
  valid_773721 = validateParameter(valid_773721, JString, required = false,
                                 default = nil)
  if valid_773721 != nil:
    section.add "X-Amz-Credential", valid_773721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773722: Call_GetDeleteDBParameterGroup_773709; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773722.validator(path, query, header, formData, body)
  let scheme = call_773722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773722.url(scheme.get, call_773722.host, call_773722.base,
                         call_773722.route, valid.getOrDefault("path"))
  result = hook(call_773722, url, valid)

proc call*(call_773723: Call_GetDeleteDBParameterGroup_773709;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773724 = newJObject()
  add(query_773724, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_773724, "Action", newJString(Action))
  add(query_773724, "Version", newJString(Version))
  result = call_773723.call(nil, query_773724, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_773709(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_773710, base: "/",
    url: url_GetDeleteDBParameterGroup_773711,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_773758 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBSecurityGroup_773760(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSecurityGroup_773759(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773761 = query.getOrDefault("Action")
  valid_773761 = validateParameter(valid_773761, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_773761 != nil:
    section.add "Action", valid_773761
  var valid_773762 = query.getOrDefault("Version")
  valid_773762 = validateParameter(valid_773762, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773762 != nil:
    section.add "Version", valid_773762
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773763 = header.getOrDefault("X-Amz-Date")
  valid_773763 = validateParameter(valid_773763, JString, required = false,
                                 default = nil)
  if valid_773763 != nil:
    section.add "X-Amz-Date", valid_773763
  var valid_773764 = header.getOrDefault("X-Amz-Security-Token")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "X-Amz-Security-Token", valid_773764
  var valid_773765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "X-Amz-Content-Sha256", valid_773765
  var valid_773766 = header.getOrDefault("X-Amz-Algorithm")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "X-Amz-Algorithm", valid_773766
  var valid_773767 = header.getOrDefault("X-Amz-Signature")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "X-Amz-Signature", valid_773767
  var valid_773768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773768 = validateParameter(valid_773768, JString, required = false,
                                 default = nil)
  if valid_773768 != nil:
    section.add "X-Amz-SignedHeaders", valid_773768
  var valid_773769 = header.getOrDefault("X-Amz-Credential")
  valid_773769 = validateParameter(valid_773769, JString, required = false,
                                 default = nil)
  if valid_773769 != nil:
    section.add "X-Amz-Credential", valid_773769
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_773770 = formData.getOrDefault("DBSecurityGroupName")
  valid_773770 = validateParameter(valid_773770, JString, required = true,
                                 default = nil)
  if valid_773770 != nil:
    section.add "DBSecurityGroupName", valid_773770
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773771: Call_PostDeleteDBSecurityGroup_773758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773771.validator(path, query, header, formData, body)
  let scheme = call_773771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773771.url(scheme.get, call_773771.host, call_773771.base,
                         call_773771.route, valid.getOrDefault("path"))
  result = hook(call_773771, url, valid)

proc call*(call_773772: Call_PostDeleteDBSecurityGroup_773758;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773773 = newJObject()
  var formData_773774 = newJObject()
  add(formData_773774, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_773773, "Action", newJString(Action))
  add(query_773773, "Version", newJString(Version))
  result = call_773772.call(nil, query_773773, nil, formData_773774, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_773758(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_773759, base: "/",
    url: url_PostDeleteDBSecurityGroup_773760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_773742 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBSecurityGroup_773744(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSecurityGroup_773743(path: JsonNode; query: JsonNode;
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
  var valid_773745 = query.getOrDefault("DBSecurityGroupName")
  valid_773745 = validateParameter(valid_773745, JString, required = true,
                                 default = nil)
  if valid_773745 != nil:
    section.add "DBSecurityGroupName", valid_773745
  var valid_773746 = query.getOrDefault("Action")
  valid_773746 = validateParameter(valid_773746, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_773746 != nil:
    section.add "Action", valid_773746
  var valid_773747 = query.getOrDefault("Version")
  valid_773747 = validateParameter(valid_773747, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773747 != nil:
    section.add "Version", valid_773747
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773748 = header.getOrDefault("X-Amz-Date")
  valid_773748 = validateParameter(valid_773748, JString, required = false,
                                 default = nil)
  if valid_773748 != nil:
    section.add "X-Amz-Date", valid_773748
  var valid_773749 = header.getOrDefault("X-Amz-Security-Token")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "X-Amz-Security-Token", valid_773749
  var valid_773750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "X-Amz-Content-Sha256", valid_773750
  var valid_773751 = header.getOrDefault("X-Amz-Algorithm")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-Algorithm", valid_773751
  var valid_773752 = header.getOrDefault("X-Amz-Signature")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-Signature", valid_773752
  var valid_773753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773753 = validateParameter(valid_773753, JString, required = false,
                                 default = nil)
  if valid_773753 != nil:
    section.add "X-Amz-SignedHeaders", valid_773753
  var valid_773754 = header.getOrDefault("X-Amz-Credential")
  valid_773754 = validateParameter(valid_773754, JString, required = false,
                                 default = nil)
  if valid_773754 != nil:
    section.add "X-Amz-Credential", valid_773754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773755: Call_GetDeleteDBSecurityGroup_773742; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773755.validator(path, query, header, formData, body)
  let scheme = call_773755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773755.url(scheme.get, call_773755.host, call_773755.base,
                         call_773755.route, valid.getOrDefault("path"))
  result = hook(call_773755, url, valid)

proc call*(call_773756: Call_GetDeleteDBSecurityGroup_773742;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773757 = newJObject()
  add(query_773757, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_773757, "Action", newJString(Action))
  add(query_773757, "Version", newJString(Version))
  result = call_773756.call(nil, query_773757, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_773742(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_773743, base: "/",
    url: url_GetDeleteDBSecurityGroup_773744, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_773791 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBSnapshot_773793(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSnapshot_773792(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773794 = query.getOrDefault("Action")
  valid_773794 = validateParameter(valid_773794, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_773794 != nil:
    section.add "Action", valid_773794
  var valid_773795 = query.getOrDefault("Version")
  valid_773795 = validateParameter(valid_773795, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773795 != nil:
    section.add "Version", valid_773795
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773796 = header.getOrDefault("X-Amz-Date")
  valid_773796 = validateParameter(valid_773796, JString, required = false,
                                 default = nil)
  if valid_773796 != nil:
    section.add "X-Amz-Date", valid_773796
  var valid_773797 = header.getOrDefault("X-Amz-Security-Token")
  valid_773797 = validateParameter(valid_773797, JString, required = false,
                                 default = nil)
  if valid_773797 != nil:
    section.add "X-Amz-Security-Token", valid_773797
  var valid_773798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773798 = validateParameter(valid_773798, JString, required = false,
                                 default = nil)
  if valid_773798 != nil:
    section.add "X-Amz-Content-Sha256", valid_773798
  var valid_773799 = header.getOrDefault("X-Amz-Algorithm")
  valid_773799 = validateParameter(valid_773799, JString, required = false,
                                 default = nil)
  if valid_773799 != nil:
    section.add "X-Amz-Algorithm", valid_773799
  var valid_773800 = header.getOrDefault("X-Amz-Signature")
  valid_773800 = validateParameter(valid_773800, JString, required = false,
                                 default = nil)
  if valid_773800 != nil:
    section.add "X-Amz-Signature", valid_773800
  var valid_773801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773801 = validateParameter(valid_773801, JString, required = false,
                                 default = nil)
  if valid_773801 != nil:
    section.add "X-Amz-SignedHeaders", valid_773801
  var valid_773802 = header.getOrDefault("X-Amz-Credential")
  valid_773802 = validateParameter(valid_773802, JString, required = false,
                                 default = nil)
  if valid_773802 != nil:
    section.add "X-Amz-Credential", valid_773802
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_773803 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_773803 = validateParameter(valid_773803, JString, required = true,
                                 default = nil)
  if valid_773803 != nil:
    section.add "DBSnapshotIdentifier", valid_773803
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773804: Call_PostDeleteDBSnapshot_773791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773804.validator(path, query, header, formData, body)
  let scheme = call_773804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773804.url(scheme.get, call_773804.host, call_773804.base,
                         call_773804.route, valid.getOrDefault("path"))
  result = hook(call_773804, url, valid)

proc call*(call_773805: Call_PostDeleteDBSnapshot_773791;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773806 = newJObject()
  var formData_773807 = newJObject()
  add(formData_773807, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_773806, "Action", newJString(Action))
  add(query_773806, "Version", newJString(Version))
  result = call_773805.call(nil, query_773806, nil, formData_773807, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_773791(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_773792, base: "/",
    url: url_PostDeleteDBSnapshot_773793, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_773775 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBSnapshot_773777(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSnapshot_773776(path: JsonNode; query: JsonNode;
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
  var valid_773778 = query.getOrDefault("Action")
  valid_773778 = validateParameter(valid_773778, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_773778 != nil:
    section.add "Action", valid_773778
  var valid_773779 = query.getOrDefault("Version")
  valid_773779 = validateParameter(valid_773779, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773779 != nil:
    section.add "Version", valid_773779
  var valid_773780 = query.getOrDefault("DBSnapshotIdentifier")
  valid_773780 = validateParameter(valid_773780, JString, required = true,
                                 default = nil)
  if valid_773780 != nil:
    section.add "DBSnapshotIdentifier", valid_773780
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773781 = header.getOrDefault("X-Amz-Date")
  valid_773781 = validateParameter(valid_773781, JString, required = false,
                                 default = nil)
  if valid_773781 != nil:
    section.add "X-Amz-Date", valid_773781
  var valid_773782 = header.getOrDefault("X-Amz-Security-Token")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-Security-Token", valid_773782
  var valid_773783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773783 = validateParameter(valid_773783, JString, required = false,
                                 default = nil)
  if valid_773783 != nil:
    section.add "X-Amz-Content-Sha256", valid_773783
  var valid_773784 = header.getOrDefault("X-Amz-Algorithm")
  valid_773784 = validateParameter(valid_773784, JString, required = false,
                                 default = nil)
  if valid_773784 != nil:
    section.add "X-Amz-Algorithm", valid_773784
  var valid_773785 = header.getOrDefault("X-Amz-Signature")
  valid_773785 = validateParameter(valid_773785, JString, required = false,
                                 default = nil)
  if valid_773785 != nil:
    section.add "X-Amz-Signature", valid_773785
  var valid_773786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773786 = validateParameter(valid_773786, JString, required = false,
                                 default = nil)
  if valid_773786 != nil:
    section.add "X-Amz-SignedHeaders", valid_773786
  var valid_773787 = header.getOrDefault("X-Amz-Credential")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-Credential", valid_773787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773788: Call_GetDeleteDBSnapshot_773775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773788.validator(path, query, header, formData, body)
  let scheme = call_773788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773788.url(scheme.get, call_773788.host, call_773788.base,
                         call_773788.route, valid.getOrDefault("path"))
  result = hook(call_773788, url, valid)

proc call*(call_773789: Call_GetDeleteDBSnapshot_773775;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_773790 = newJObject()
  add(query_773790, "Action", newJString(Action))
  add(query_773790, "Version", newJString(Version))
  add(query_773790, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_773789.call(nil, query_773790, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_773775(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_773776, base: "/",
    url: url_GetDeleteDBSnapshot_773777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_773824 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBSubnetGroup_773826(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSubnetGroup_773825(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773827 = query.getOrDefault("Action")
  valid_773827 = validateParameter(valid_773827, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_773827 != nil:
    section.add "Action", valid_773827
  var valid_773828 = query.getOrDefault("Version")
  valid_773828 = validateParameter(valid_773828, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773828 != nil:
    section.add "Version", valid_773828
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773829 = header.getOrDefault("X-Amz-Date")
  valid_773829 = validateParameter(valid_773829, JString, required = false,
                                 default = nil)
  if valid_773829 != nil:
    section.add "X-Amz-Date", valid_773829
  var valid_773830 = header.getOrDefault("X-Amz-Security-Token")
  valid_773830 = validateParameter(valid_773830, JString, required = false,
                                 default = nil)
  if valid_773830 != nil:
    section.add "X-Amz-Security-Token", valid_773830
  var valid_773831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773831 = validateParameter(valid_773831, JString, required = false,
                                 default = nil)
  if valid_773831 != nil:
    section.add "X-Amz-Content-Sha256", valid_773831
  var valid_773832 = header.getOrDefault("X-Amz-Algorithm")
  valid_773832 = validateParameter(valid_773832, JString, required = false,
                                 default = nil)
  if valid_773832 != nil:
    section.add "X-Amz-Algorithm", valid_773832
  var valid_773833 = header.getOrDefault("X-Amz-Signature")
  valid_773833 = validateParameter(valid_773833, JString, required = false,
                                 default = nil)
  if valid_773833 != nil:
    section.add "X-Amz-Signature", valid_773833
  var valid_773834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773834 = validateParameter(valid_773834, JString, required = false,
                                 default = nil)
  if valid_773834 != nil:
    section.add "X-Amz-SignedHeaders", valid_773834
  var valid_773835 = header.getOrDefault("X-Amz-Credential")
  valid_773835 = validateParameter(valid_773835, JString, required = false,
                                 default = nil)
  if valid_773835 != nil:
    section.add "X-Amz-Credential", valid_773835
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_773836 = formData.getOrDefault("DBSubnetGroupName")
  valid_773836 = validateParameter(valid_773836, JString, required = true,
                                 default = nil)
  if valid_773836 != nil:
    section.add "DBSubnetGroupName", valid_773836
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773837: Call_PostDeleteDBSubnetGroup_773824; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773837.validator(path, query, header, formData, body)
  let scheme = call_773837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773837.url(scheme.get, call_773837.host, call_773837.base,
                         call_773837.route, valid.getOrDefault("path"))
  result = hook(call_773837, url, valid)

proc call*(call_773838: Call_PostDeleteDBSubnetGroup_773824;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773839 = newJObject()
  var formData_773840 = newJObject()
  add(formData_773840, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773839, "Action", newJString(Action))
  add(query_773839, "Version", newJString(Version))
  result = call_773838.call(nil, query_773839, nil, formData_773840, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_773824(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_773825, base: "/",
    url: url_PostDeleteDBSubnetGroup_773826, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_773808 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBSubnetGroup_773810(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSubnetGroup_773809(path: JsonNode; query: JsonNode;
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
  var valid_773811 = query.getOrDefault("Action")
  valid_773811 = validateParameter(valid_773811, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_773811 != nil:
    section.add "Action", valid_773811
  var valid_773812 = query.getOrDefault("DBSubnetGroupName")
  valid_773812 = validateParameter(valid_773812, JString, required = true,
                                 default = nil)
  if valid_773812 != nil:
    section.add "DBSubnetGroupName", valid_773812
  var valid_773813 = query.getOrDefault("Version")
  valid_773813 = validateParameter(valid_773813, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773813 != nil:
    section.add "Version", valid_773813
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773814 = header.getOrDefault("X-Amz-Date")
  valid_773814 = validateParameter(valid_773814, JString, required = false,
                                 default = nil)
  if valid_773814 != nil:
    section.add "X-Amz-Date", valid_773814
  var valid_773815 = header.getOrDefault("X-Amz-Security-Token")
  valid_773815 = validateParameter(valid_773815, JString, required = false,
                                 default = nil)
  if valid_773815 != nil:
    section.add "X-Amz-Security-Token", valid_773815
  var valid_773816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773816 = validateParameter(valid_773816, JString, required = false,
                                 default = nil)
  if valid_773816 != nil:
    section.add "X-Amz-Content-Sha256", valid_773816
  var valid_773817 = header.getOrDefault("X-Amz-Algorithm")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-Algorithm", valid_773817
  var valid_773818 = header.getOrDefault("X-Amz-Signature")
  valid_773818 = validateParameter(valid_773818, JString, required = false,
                                 default = nil)
  if valid_773818 != nil:
    section.add "X-Amz-Signature", valid_773818
  var valid_773819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773819 = validateParameter(valid_773819, JString, required = false,
                                 default = nil)
  if valid_773819 != nil:
    section.add "X-Amz-SignedHeaders", valid_773819
  var valid_773820 = header.getOrDefault("X-Amz-Credential")
  valid_773820 = validateParameter(valid_773820, JString, required = false,
                                 default = nil)
  if valid_773820 != nil:
    section.add "X-Amz-Credential", valid_773820
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773821: Call_GetDeleteDBSubnetGroup_773808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773821.validator(path, query, header, formData, body)
  let scheme = call_773821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773821.url(scheme.get, call_773821.host, call_773821.base,
                         call_773821.route, valid.getOrDefault("path"))
  result = hook(call_773821, url, valid)

proc call*(call_773822: Call_GetDeleteDBSubnetGroup_773808;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_773823 = newJObject()
  add(query_773823, "Action", newJString(Action))
  add(query_773823, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773823, "Version", newJString(Version))
  result = call_773822.call(nil, query_773823, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_773808(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_773809, base: "/",
    url: url_GetDeleteDBSubnetGroup_773810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_773857 = ref object of OpenApiRestCall_772581
proc url_PostDeleteEventSubscription_773859(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEventSubscription_773858(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773860 = query.getOrDefault("Action")
  valid_773860 = validateParameter(valid_773860, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_773860 != nil:
    section.add "Action", valid_773860
  var valid_773861 = query.getOrDefault("Version")
  valid_773861 = validateParameter(valid_773861, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773861 != nil:
    section.add "Version", valid_773861
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773862 = header.getOrDefault("X-Amz-Date")
  valid_773862 = validateParameter(valid_773862, JString, required = false,
                                 default = nil)
  if valid_773862 != nil:
    section.add "X-Amz-Date", valid_773862
  var valid_773863 = header.getOrDefault("X-Amz-Security-Token")
  valid_773863 = validateParameter(valid_773863, JString, required = false,
                                 default = nil)
  if valid_773863 != nil:
    section.add "X-Amz-Security-Token", valid_773863
  var valid_773864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773864 = validateParameter(valid_773864, JString, required = false,
                                 default = nil)
  if valid_773864 != nil:
    section.add "X-Amz-Content-Sha256", valid_773864
  var valid_773865 = header.getOrDefault("X-Amz-Algorithm")
  valid_773865 = validateParameter(valid_773865, JString, required = false,
                                 default = nil)
  if valid_773865 != nil:
    section.add "X-Amz-Algorithm", valid_773865
  var valid_773866 = header.getOrDefault("X-Amz-Signature")
  valid_773866 = validateParameter(valid_773866, JString, required = false,
                                 default = nil)
  if valid_773866 != nil:
    section.add "X-Amz-Signature", valid_773866
  var valid_773867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773867 = validateParameter(valid_773867, JString, required = false,
                                 default = nil)
  if valid_773867 != nil:
    section.add "X-Amz-SignedHeaders", valid_773867
  var valid_773868 = header.getOrDefault("X-Amz-Credential")
  valid_773868 = validateParameter(valid_773868, JString, required = false,
                                 default = nil)
  if valid_773868 != nil:
    section.add "X-Amz-Credential", valid_773868
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_773869 = formData.getOrDefault("SubscriptionName")
  valid_773869 = validateParameter(valid_773869, JString, required = true,
                                 default = nil)
  if valid_773869 != nil:
    section.add "SubscriptionName", valid_773869
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773870: Call_PostDeleteEventSubscription_773857; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773870.validator(path, query, header, formData, body)
  let scheme = call_773870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773870.url(scheme.get, call_773870.host, call_773870.base,
                         call_773870.route, valid.getOrDefault("path"))
  result = hook(call_773870, url, valid)

proc call*(call_773871: Call_PostDeleteEventSubscription_773857;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773872 = newJObject()
  var formData_773873 = newJObject()
  add(formData_773873, "SubscriptionName", newJString(SubscriptionName))
  add(query_773872, "Action", newJString(Action))
  add(query_773872, "Version", newJString(Version))
  result = call_773871.call(nil, query_773872, nil, formData_773873, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_773857(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_773858, base: "/",
    url: url_PostDeleteEventSubscription_773859,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_773841 = ref object of OpenApiRestCall_772581
proc url_GetDeleteEventSubscription_773843(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEventSubscription_773842(path: JsonNode; query: JsonNode;
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
  var valid_773844 = query.getOrDefault("Action")
  valid_773844 = validateParameter(valid_773844, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_773844 != nil:
    section.add "Action", valid_773844
  var valid_773845 = query.getOrDefault("SubscriptionName")
  valid_773845 = validateParameter(valid_773845, JString, required = true,
                                 default = nil)
  if valid_773845 != nil:
    section.add "SubscriptionName", valid_773845
  var valid_773846 = query.getOrDefault("Version")
  valid_773846 = validateParameter(valid_773846, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773846 != nil:
    section.add "Version", valid_773846
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773847 = header.getOrDefault("X-Amz-Date")
  valid_773847 = validateParameter(valid_773847, JString, required = false,
                                 default = nil)
  if valid_773847 != nil:
    section.add "X-Amz-Date", valid_773847
  var valid_773848 = header.getOrDefault("X-Amz-Security-Token")
  valid_773848 = validateParameter(valid_773848, JString, required = false,
                                 default = nil)
  if valid_773848 != nil:
    section.add "X-Amz-Security-Token", valid_773848
  var valid_773849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773849 = validateParameter(valid_773849, JString, required = false,
                                 default = nil)
  if valid_773849 != nil:
    section.add "X-Amz-Content-Sha256", valid_773849
  var valid_773850 = header.getOrDefault("X-Amz-Algorithm")
  valid_773850 = validateParameter(valid_773850, JString, required = false,
                                 default = nil)
  if valid_773850 != nil:
    section.add "X-Amz-Algorithm", valid_773850
  var valid_773851 = header.getOrDefault("X-Amz-Signature")
  valid_773851 = validateParameter(valid_773851, JString, required = false,
                                 default = nil)
  if valid_773851 != nil:
    section.add "X-Amz-Signature", valid_773851
  var valid_773852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773852 = validateParameter(valid_773852, JString, required = false,
                                 default = nil)
  if valid_773852 != nil:
    section.add "X-Amz-SignedHeaders", valid_773852
  var valid_773853 = header.getOrDefault("X-Amz-Credential")
  valid_773853 = validateParameter(valid_773853, JString, required = false,
                                 default = nil)
  if valid_773853 != nil:
    section.add "X-Amz-Credential", valid_773853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773854: Call_GetDeleteEventSubscription_773841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773854.validator(path, query, header, formData, body)
  let scheme = call_773854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773854.url(scheme.get, call_773854.host, call_773854.base,
                         call_773854.route, valid.getOrDefault("path"))
  result = hook(call_773854, url, valid)

proc call*(call_773855: Call_GetDeleteEventSubscription_773841;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_773856 = newJObject()
  add(query_773856, "Action", newJString(Action))
  add(query_773856, "SubscriptionName", newJString(SubscriptionName))
  add(query_773856, "Version", newJString(Version))
  result = call_773855.call(nil, query_773856, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_773841(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_773842, base: "/",
    url: url_GetDeleteEventSubscription_773843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_773890 = ref object of OpenApiRestCall_772581
proc url_PostDeleteOptionGroup_773892(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteOptionGroup_773891(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773893 = query.getOrDefault("Action")
  valid_773893 = validateParameter(valid_773893, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_773893 != nil:
    section.add "Action", valid_773893
  var valid_773894 = query.getOrDefault("Version")
  valid_773894 = validateParameter(valid_773894, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773894 != nil:
    section.add "Version", valid_773894
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773895 = header.getOrDefault("X-Amz-Date")
  valid_773895 = validateParameter(valid_773895, JString, required = false,
                                 default = nil)
  if valid_773895 != nil:
    section.add "X-Amz-Date", valid_773895
  var valid_773896 = header.getOrDefault("X-Amz-Security-Token")
  valid_773896 = validateParameter(valid_773896, JString, required = false,
                                 default = nil)
  if valid_773896 != nil:
    section.add "X-Amz-Security-Token", valid_773896
  var valid_773897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773897 = validateParameter(valid_773897, JString, required = false,
                                 default = nil)
  if valid_773897 != nil:
    section.add "X-Amz-Content-Sha256", valid_773897
  var valid_773898 = header.getOrDefault("X-Amz-Algorithm")
  valid_773898 = validateParameter(valid_773898, JString, required = false,
                                 default = nil)
  if valid_773898 != nil:
    section.add "X-Amz-Algorithm", valid_773898
  var valid_773899 = header.getOrDefault("X-Amz-Signature")
  valid_773899 = validateParameter(valid_773899, JString, required = false,
                                 default = nil)
  if valid_773899 != nil:
    section.add "X-Amz-Signature", valid_773899
  var valid_773900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773900 = validateParameter(valid_773900, JString, required = false,
                                 default = nil)
  if valid_773900 != nil:
    section.add "X-Amz-SignedHeaders", valid_773900
  var valid_773901 = header.getOrDefault("X-Amz-Credential")
  valid_773901 = validateParameter(valid_773901, JString, required = false,
                                 default = nil)
  if valid_773901 != nil:
    section.add "X-Amz-Credential", valid_773901
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_773902 = formData.getOrDefault("OptionGroupName")
  valid_773902 = validateParameter(valid_773902, JString, required = true,
                                 default = nil)
  if valid_773902 != nil:
    section.add "OptionGroupName", valid_773902
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773903: Call_PostDeleteOptionGroup_773890; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773903.validator(path, query, header, formData, body)
  let scheme = call_773903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773903.url(scheme.get, call_773903.host, call_773903.base,
                         call_773903.route, valid.getOrDefault("path"))
  result = hook(call_773903, url, valid)

proc call*(call_773904: Call_PostDeleteOptionGroup_773890; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773905 = newJObject()
  var formData_773906 = newJObject()
  add(formData_773906, "OptionGroupName", newJString(OptionGroupName))
  add(query_773905, "Action", newJString(Action))
  add(query_773905, "Version", newJString(Version))
  result = call_773904.call(nil, query_773905, nil, formData_773906, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_773890(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_773891, base: "/",
    url: url_PostDeleteOptionGroup_773892, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_773874 = ref object of OpenApiRestCall_772581
proc url_GetDeleteOptionGroup_773876(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteOptionGroup_773875(path: JsonNode; query: JsonNode;
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
  var valid_773877 = query.getOrDefault("OptionGroupName")
  valid_773877 = validateParameter(valid_773877, JString, required = true,
                                 default = nil)
  if valid_773877 != nil:
    section.add "OptionGroupName", valid_773877
  var valid_773878 = query.getOrDefault("Action")
  valid_773878 = validateParameter(valid_773878, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_773878 != nil:
    section.add "Action", valid_773878
  var valid_773879 = query.getOrDefault("Version")
  valid_773879 = validateParameter(valid_773879, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773879 != nil:
    section.add "Version", valid_773879
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773880 = header.getOrDefault("X-Amz-Date")
  valid_773880 = validateParameter(valid_773880, JString, required = false,
                                 default = nil)
  if valid_773880 != nil:
    section.add "X-Amz-Date", valid_773880
  var valid_773881 = header.getOrDefault("X-Amz-Security-Token")
  valid_773881 = validateParameter(valid_773881, JString, required = false,
                                 default = nil)
  if valid_773881 != nil:
    section.add "X-Amz-Security-Token", valid_773881
  var valid_773882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773882 = validateParameter(valid_773882, JString, required = false,
                                 default = nil)
  if valid_773882 != nil:
    section.add "X-Amz-Content-Sha256", valid_773882
  var valid_773883 = header.getOrDefault("X-Amz-Algorithm")
  valid_773883 = validateParameter(valid_773883, JString, required = false,
                                 default = nil)
  if valid_773883 != nil:
    section.add "X-Amz-Algorithm", valid_773883
  var valid_773884 = header.getOrDefault("X-Amz-Signature")
  valid_773884 = validateParameter(valid_773884, JString, required = false,
                                 default = nil)
  if valid_773884 != nil:
    section.add "X-Amz-Signature", valid_773884
  var valid_773885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773885 = validateParameter(valid_773885, JString, required = false,
                                 default = nil)
  if valid_773885 != nil:
    section.add "X-Amz-SignedHeaders", valid_773885
  var valid_773886 = header.getOrDefault("X-Amz-Credential")
  valid_773886 = validateParameter(valid_773886, JString, required = false,
                                 default = nil)
  if valid_773886 != nil:
    section.add "X-Amz-Credential", valid_773886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773887: Call_GetDeleteOptionGroup_773874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773887.validator(path, query, header, formData, body)
  let scheme = call_773887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773887.url(scheme.get, call_773887.host, call_773887.base,
                         call_773887.route, valid.getOrDefault("path"))
  result = hook(call_773887, url, valid)

proc call*(call_773888: Call_GetDeleteOptionGroup_773874; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773889 = newJObject()
  add(query_773889, "OptionGroupName", newJString(OptionGroupName))
  add(query_773889, "Action", newJString(Action))
  add(query_773889, "Version", newJString(Version))
  result = call_773888.call(nil, query_773889, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_773874(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_773875, base: "/",
    url: url_GetDeleteOptionGroup_773876, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_773929 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBEngineVersions_773931(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBEngineVersions_773930(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773932 = query.getOrDefault("Action")
  valid_773932 = validateParameter(valid_773932, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_773932 != nil:
    section.add "Action", valid_773932
  var valid_773933 = query.getOrDefault("Version")
  valid_773933 = validateParameter(valid_773933, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773933 != nil:
    section.add "Version", valid_773933
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773934 = header.getOrDefault("X-Amz-Date")
  valid_773934 = validateParameter(valid_773934, JString, required = false,
                                 default = nil)
  if valid_773934 != nil:
    section.add "X-Amz-Date", valid_773934
  var valid_773935 = header.getOrDefault("X-Amz-Security-Token")
  valid_773935 = validateParameter(valid_773935, JString, required = false,
                                 default = nil)
  if valid_773935 != nil:
    section.add "X-Amz-Security-Token", valid_773935
  var valid_773936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773936 = validateParameter(valid_773936, JString, required = false,
                                 default = nil)
  if valid_773936 != nil:
    section.add "X-Amz-Content-Sha256", valid_773936
  var valid_773937 = header.getOrDefault("X-Amz-Algorithm")
  valid_773937 = validateParameter(valid_773937, JString, required = false,
                                 default = nil)
  if valid_773937 != nil:
    section.add "X-Amz-Algorithm", valid_773937
  var valid_773938 = header.getOrDefault("X-Amz-Signature")
  valid_773938 = validateParameter(valid_773938, JString, required = false,
                                 default = nil)
  if valid_773938 != nil:
    section.add "X-Amz-Signature", valid_773938
  var valid_773939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773939 = validateParameter(valid_773939, JString, required = false,
                                 default = nil)
  if valid_773939 != nil:
    section.add "X-Amz-SignedHeaders", valid_773939
  var valid_773940 = header.getOrDefault("X-Amz-Credential")
  valid_773940 = validateParameter(valid_773940, JString, required = false,
                                 default = nil)
  if valid_773940 != nil:
    section.add "X-Amz-Credential", valid_773940
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
  var valid_773941 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_773941 = validateParameter(valid_773941, JBool, required = false, default = nil)
  if valid_773941 != nil:
    section.add "ListSupportedCharacterSets", valid_773941
  var valid_773942 = formData.getOrDefault("Engine")
  valid_773942 = validateParameter(valid_773942, JString, required = false,
                                 default = nil)
  if valid_773942 != nil:
    section.add "Engine", valid_773942
  var valid_773943 = formData.getOrDefault("Marker")
  valid_773943 = validateParameter(valid_773943, JString, required = false,
                                 default = nil)
  if valid_773943 != nil:
    section.add "Marker", valid_773943
  var valid_773944 = formData.getOrDefault("DBParameterGroupFamily")
  valid_773944 = validateParameter(valid_773944, JString, required = false,
                                 default = nil)
  if valid_773944 != nil:
    section.add "DBParameterGroupFamily", valid_773944
  var valid_773945 = formData.getOrDefault("MaxRecords")
  valid_773945 = validateParameter(valid_773945, JInt, required = false, default = nil)
  if valid_773945 != nil:
    section.add "MaxRecords", valid_773945
  var valid_773946 = formData.getOrDefault("EngineVersion")
  valid_773946 = validateParameter(valid_773946, JString, required = false,
                                 default = nil)
  if valid_773946 != nil:
    section.add "EngineVersion", valid_773946
  var valid_773947 = formData.getOrDefault("DefaultOnly")
  valid_773947 = validateParameter(valid_773947, JBool, required = false, default = nil)
  if valid_773947 != nil:
    section.add "DefaultOnly", valid_773947
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773948: Call_PostDescribeDBEngineVersions_773929; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773948.validator(path, query, header, formData, body)
  let scheme = call_773948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773948.url(scheme.get, call_773948.host, call_773948.base,
                         call_773948.route, valid.getOrDefault("path"))
  result = hook(call_773948, url, valid)

proc call*(call_773949: Call_PostDescribeDBEngineVersions_773929;
          ListSupportedCharacterSets: bool = false; Engine: string = "";
          Marker: string = ""; Action: string = "DescribeDBEngineVersions";
          DBParameterGroupFamily: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Version: string = "2013-01-10";
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
  var query_773950 = newJObject()
  var formData_773951 = newJObject()
  add(formData_773951, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_773951, "Engine", newJString(Engine))
  add(formData_773951, "Marker", newJString(Marker))
  add(query_773950, "Action", newJString(Action))
  add(formData_773951, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_773951, "MaxRecords", newJInt(MaxRecords))
  add(formData_773951, "EngineVersion", newJString(EngineVersion))
  add(query_773950, "Version", newJString(Version))
  add(formData_773951, "DefaultOnly", newJBool(DefaultOnly))
  result = call_773949.call(nil, query_773950, nil, formData_773951, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_773929(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_773930, base: "/",
    url: url_PostDescribeDBEngineVersions_773931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_773907 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBEngineVersions_773909(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBEngineVersions_773908(path: JsonNode; query: JsonNode;
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
  var valid_773910 = query.getOrDefault("Engine")
  valid_773910 = validateParameter(valid_773910, JString, required = false,
                                 default = nil)
  if valid_773910 != nil:
    section.add "Engine", valid_773910
  var valid_773911 = query.getOrDefault("ListSupportedCharacterSets")
  valid_773911 = validateParameter(valid_773911, JBool, required = false, default = nil)
  if valid_773911 != nil:
    section.add "ListSupportedCharacterSets", valid_773911
  var valid_773912 = query.getOrDefault("MaxRecords")
  valid_773912 = validateParameter(valid_773912, JInt, required = false, default = nil)
  if valid_773912 != nil:
    section.add "MaxRecords", valid_773912
  var valid_773913 = query.getOrDefault("DBParameterGroupFamily")
  valid_773913 = validateParameter(valid_773913, JString, required = false,
                                 default = nil)
  if valid_773913 != nil:
    section.add "DBParameterGroupFamily", valid_773913
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773914 = query.getOrDefault("Action")
  valid_773914 = validateParameter(valid_773914, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_773914 != nil:
    section.add "Action", valid_773914
  var valid_773915 = query.getOrDefault("Marker")
  valid_773915 = validateParameter(valid_773915, JString, required = false,
                                 default = nil)
  if valid_773915 != nil:
    section.add "Marker", valid_773915
  var valid_773916 = query.getOrDefault("EngineVersion")
  valid_773916 = validateParameter(valid_773916, JString, required = false,
                                 default = nil)
  if valid_773916 != nil:
    section.add "EngineVersion", valid_773916
  var valid_773917 = query.getOrDefault("DefaultOnly")
  valid_773917 = validateParameter(valid_773917, JBool, required = false, default = nil)
  if valid_773917 != nil:
    section.add "DefaultOnly", valid_773917
  var valid_773918 = query.getOrDefault("Version")
  valid_773918 = validateParameter(valid_773918, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773918 != nil:
    section.add "Version", valid_773918
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773919 = header.getOrDefault("X-Amz-Date")
  valid_773919 = validateParameter(valid_773919, JString, required = false,
                                 default = nil)
  if valid_773919 != nil:
    section.add "X-Amz-Date", valid_773919
  var valid_773920 = header.getOrDefault("X-Amz-Security-Token")
  valid_773920 = validateParameter(valid_773920, JString, required = false,
                                 default = nil)
  if valid_773920 != nil:
    section.add "X-Amz-Security-Token", valid_773920
  var valid_773921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773921 = validateParameter(valid_773921, JString, required = false,
                                 default = nil)
  if valid_773921 != nil:
    section.add "X-Amz-Content-Sha256", valid_773921
  var valid_773922 = header.getOrDefault("X-Amz-Algorithm")
  valid_773922 = validateParameter(valid_773922, JString, required = false,
                                 default = nil)
  if valid_773922 != nil:
    section.add "X-Amz-Algorithm", valid_773922
  var valid_773923 = header.getOrDefault("X-Amz-Signature")
  valid_773923 = validateParameter(valid_773923, JString, required = false,
                                 default = nil)
  if valid_773923 != nil:
    section.add "X-Amz-Signature", valid_773923
  var valid_773924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773924 = validateParameter(valid_773924, JString, required = false,
                                 default = nil)
  if valid_773924 != nil:
    section.add "X-Amz-SignedHeaders", valid_773924
  var valid_773925 = header.getOrDefault("X-Amz-Credential")
  valid_773925 = validateParameter(valid_773925, JString, required = false,
                                 default = nil)
  if valid_773925 != nil:
    section.add "X-Amz-Credential", valid_773925
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773926: Call_GetDescribeDBEngineVersions_773907; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773926.validator(path, query, header, formData, body)
  let scheme = call_773926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773926.url(scheme.get, call_773926.host, call_773926.base,
                         call_773926.route, valid.getOrDefault("path"))
  result = hook(call_773926, url, valid)

proc call*(call_773927: Call_GetDescribeDBEngineVersions_773907;
          Engine: string = ""; ListSupportedCharacterSets: bool = false;
          MaxRecords: int = 0; DBParameterGroupFamily: string = "";
          Action: string = "DescribeDBEngineVersions"; Marker: string = "";
          EngineVersion: string = ""; DefaultOnly: bool = false;
          Version: string = "2013-01-10"): Recallable =
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
  var query_773928 = newJObject()
  add(query_773928, "Engine", newJString(Engine))
  add(query_773928, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_773928, "MaxRecords", newJInt(MaxRecords))
  add(query_773928, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_773928, "Action", newJString(Action))
  add(query_773928, "Marker", newJString(Marker))
  add(query_773928, "EngineVersion", newJString(EngineVersion))
  add(query_773928, "DefaultOnly", newJBool(DefaultOnly))
  add(query_773928, "Version", newJString(Version))
  result = call_773927.call(nil, query_773928, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_773907(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_773908, base: "/",
    url: url_GetDescribeDBEngineVersions_773909,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_773970 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBInstances_773972(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBInstances_773971(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773973 = query.getOrDefault("Action")
  valid_773973 = validateParameter(valid_773973, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_773973 != nil:
    section.add "Action", valid_773973
  var valid_773974 = query.getOrDefault("Version")
  valid_773974 = validateParameter(valid_773974, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773974 != nil:
    section.add "Version", valid_773974
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773975 = header.getOrDefault("X-Amz-Date")
  valid_773975 = validateParameter(valid_773975, JString, required = false,
                                 default = nil)
  if valid_773975 != nil:
    section.add "X-Amz-Date", valid_773975
  var valid_773976 = header.getOrDefault("X-Amz-Security-Token")
  valid_773976 = validateParameter(valid_773976, JString, required = false,
                                 default = nil)
  if valid_773976 != nil:
    section.add "X-Amz-Security-Token", valid_773976
  var valid_773977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773977 = validateParameter(valid_773977, JString, required = false,
                                 default = nil)
  if valid_773977 != nil:
    section.add "X-Amz-Content-Sha256", valid_773977
  var valid_773978 = header.getOrDefault("X-Amz-Algorithm")
  valid_773978 = validateParameter(valid_773978, JString, required = false,
                                 default = nil)
  if valid_773978 != nil:
    section.add "X-Amz-Algorithm", valid_773978
  var valid_773979 = header.getOrDefault("X-Amz-Signature")
  valid_773979 = validateParameter(valid_773979, JString, required = false,
                                 default = nil)
  if valid_773979 != nil:
    section.add "X-Amz-Signature", valid_773979
  var valid_773980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773980 = validateParameter(valid_773980, JString, required = false,
                                 default = nil)
  if valid_773980 != nil:
    section.add "X-Amz-SignedHeaders", valid_773980
  var valid_773981 = header.getOrDefault("X-Amz-Credential")
  valid_773981 = validateParameter(valid_773981, JString, required = false,
                                 default = nil)
  if valid_773981 != nil:
    section.add "X-Amz-Credential", valid_773981
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_773982 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773982 = validateParameter(valid_773982, JString, required = false,
                                 default = nil)
  if valid_773982 != nil:
    section.add "DBInstanceIdentifier", valid_773982
  var valid_773983 = formData.getOrDefault("Marker")
  valid_773983 = validateParameter(valid_773983, JString, required = false,
                                 default = nil)
  if valid_773983 != nil:
    section.add "Marker", valid_773983
  var valid_773984 = formData.getOrDefault("MaxRecords")
  valid_773984 = validateParameter(valid_773984, JInt, required = false, default = nil)
  if valid_773984 != nil:
    section.add "MaxRecords", valid_773984
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773985: Call_PostDescribeDBInstances_773970; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773985.validator(path, query, header, formData, body)
  let scheme = call_773985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773985.url(scheme.get, call_773985.host, call_773985.base,
                         call_773985.route, valid.getOrDefault("path"))
  result = hook(call_773985, url, valid)

proc call*(call_773986: Call_PostDescribeDBInstances_773970;
          DBInstanceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeDBInstances"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBInstances
  ##   DBInstanceIdentifier: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_773987 = newJObject()
  var formData_773988 = newJObject()
  add(formData_773988, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_773988, "Marker", newJString(Marker))
  add(query_773987, "Action", newJString(Action))
  add(formData_773988, "MaxRecords", newJInt(MaxRecords))
  add(query_773987, "Version", newJString(Version))
  result = call_773986.call(nil, query_773987, nil, formData_773988, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_773970(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_773971, base: "/",
    url: url_PostDescribeDBInstances_773972, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_773952 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBInstances_773954(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBInstances_773953(path: JsonNode; query: JsonNode;
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
  var valid_773955 = query.getOrDefault("MaxRecords")
  valid_773955 = validateParameter(valid_773955, JInt, required = false, default = nil)
  if valid_773955 != nil:
    section.add "MaxRecords", valid_773955
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773956 = query.getOrDefault("Action")
  valid_773956 = validateParameter(valid_773956, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_773956 != nil:
    section.add "Action", valid_773956
  var valid_773957 = query.getOrDefault("Marker")
  valid_773957 = validateParameter(valid_773957, JString, required = false,
                                 default = nil)
  if valid_773957 != nil:
    section.add "Marker", valid_773957
  var valid_773958 = query.getOrDefault("Version")
  valid_773958 = validateParameter(valid_773958, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773958 != nil:
    section.add "Version", valid_773958
  var valid_773959 = query.getOrDefault("DBInstanceIdentifier")
  valid_773959 = validateParameter(valid_773959, JString, required = false,
                                 default = nil)
  if valid_773959 != nil:
    section.add "DBInstanceIdentifier", valid_773959
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773960 = header.getOrDefault("X-Amz-Date")
  valid_773960 = validateParameter(valid_773960, JString, required = false,
                                 default = nil)
  if valid_773960 != nil:
    section.add "X-Amz-Date", valid_773960
  var valid_773961 = header.getOrDefault("X-Amz-Security-Token")
  valid_773961 = validateParameter(valid_773961, JString, required = false,
                                 default = nil)
  if valid_773961 != nil:
    section.add "X-Amz-Security-Token", valid_773961
  var valid_773962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773962 = validateParameter(valid_773962, JString, required = false,
                                 default = nil)
  if valid_773962 != nil:
    section.add "X-Amz-Content-Sha256", valid_773962
  var valid_773963 = header.getOrDefault("X-Amz-Algorithm")
  valid_773963 = validateParameter(valid_773963, JString, required = false,
                                 default = nil)
  if valid_773963 != nil:
    section.add "X-Amz-Algorithm", valid_773963
  var valid_773964 = header.getOrDefault("X-Amz-Signature")
  valid_773964 = validateParameter(valid_773964, JString, required = false,
                                 default = nil)
  if valid_773964 != nil:
    section.add "X-Amz-Signature", valid_773964
  var valid_773965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773965 = validateParameter(valid_773965, JString, required = false,
                                 default = nil)
  if valid_773965 != nil:
    section.add "X-Amz-SignedHeaders", valid_773965
  var valid_773966 = header.getOrDefault("X-Amz-Credential")
  valid_773966 = validateParameter(valid_773966, JString, required = false,
                                 default = nil)
  if valid_773966 != nil:
    section.add "X-Amz-Credential", valid_773966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773967: Call_GetDescribeDBInstances_773952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773967.validator(path, query, header, formData, body)
  let scheme = call_773967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773967.url(scheme.get, call_773967.host, call_773967.base,
                         call_773967.route, valid.getOrDefault("path"))
  result = hook(call_773967, url, valid)

proc call*(call_773968: Call_GetDescribeDBInstances_773952; MaxRecords: int = 0;
          Action: string = "DescribeDBInstances"; Marker: string = "";
          Version: string = "2013-01-10"; DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  var query_773969 = newJObject()
  add(query_773969, "MaxRecords", newJInt(MaxRecords))
  add(query_773969, "Action", newJString(Action))
  add(query_773969, "Marker", newJString(Marker))
  add(query_773969, "Version", newJString(Version))
  add(query_773969, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_773968.call(nil, query_773969, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_773952(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_773953, base: "/",
    url: url_GetDescribeDBInstances_773954, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_774007 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBParameterGroups_774009(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameterGroups_774008(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774010 = query.getOrDefault("Action")
  valid_774010 = validateParameter(valid_774010, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_774010 != nil:
    section.add "Action", valid_774010
  var valid_774011 = query.getOrDefault("Version")
  valid_774011 = validateParameter(valid_774011, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774011 != nil:
    section.add "Version", valid_774011
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774012 = header.getOrDefault("X-Amz-Date")
  valid_774012 = validateParameter(valid_774012, JString, required = false,
                                 default = nil)
  if valid_774012 != nil:
    section.add "X-Amz-Date", valid_774012
  var valid_774013 = header.getOrDefault("X-Amz-Security-Token")
  valid_774013 = validateParameter(valid_774013, JString, required = false,
                                 default = nil)
  if valid_774013 != nil:
    section.add "X-Amz-Security-Token", valid_774013
  var valid_774014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774014 = validateParameter(valid_774014, JString, required = false,
                                 default = nil)
  if valid_774014 != nil:
    section.add "X-Amz-Content-Sha256", valid_774014
  var valid_774015 = header.getOrDefault("X-Amz-Algorithm")
  valid_774015 = validateParameter(valid_774015, JString, required = false,
                                 default = nil)
  if valid_774015 != nil:
    section.add "X-Amz-Algorithm", valid_774015
  var valid_774016 = header.getOrDefault("X-Amz-Signature")
  valid_774016 = validateParameter(valid_774016, JString, required = false,
                                 default = nil)
  if valid_774016 != nil:
    section.add "X-Amz-Signature", valid_774016
  var valid_774017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774017 = validateParameter(valid_774017, JString, required = false,
                                 default = nil)
  if valid_774017 != nil:
    section.add "X-Amz-SignedHeaders", valid_774017
  var valid_774018 = header.getOrDefault("X-Amz-Credential")
  valid_774018 = validateParameter(valid_774018, JString, required = false,
                                 default = nil)
  if valid_774018 != nil:
    section.add "X-Amz-Credential", valid_774018
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774019 = formData.getOrDefault("DBParameterGroupName")
  valid_774019 = validateParameter(valid_774019, JString, required = false,
                                 default = nil)
  if valid_774019 != nil:
    section.add "DBParameterGroupName", valid_774019
  var valid_774020 = formData.getOrDefault("Marker")
  valid_774020 = validateParameter(valid_774020, JString, required = false,
                                 default = nil)
  if valid_774020 != nil:
    section.add "Marker", valid_774020
  var valid_774021 = formData.getOrDefault("MaxRecords")
  valid_774021 = validateParameter(valid_774021, JInt, required = false, default = nil)
  if valid_774021 != nil:
    section.add "MaxRecords", valid_774021
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774022: Call_PostDescribeDBParameterGroups_774007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774022.validator(path, query, header, formData, body)
  let scheme = call_774022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774022.url(scheme.get, call_774022.host, call_774022.base,
                         call_774022.route, valid.getOrDefault("path"))
  result = hook(call_774022, url, valid)

proc call*(call_774023: Call_PostDescribeDBParameterGroups_774007;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_774024 = newJObject()
  var formData_774025 = newJObject()
  add(formData_774025, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_774025, "Marker", newJString(Marker))
  add(query_774024, "Action", newJString(Action))
  add(formData_774025, "MaxRecords", newJInt(MaxRecords))
  add(query_774024, "Version", newJString(Version))
  result = call_774023.call(nil, query_774024, nil, formData_774025, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_774007(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_774008, base: "/",
    url: url_PostDescribeDBParameterGroups_774009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_773989 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBParameterGroups_773991(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameterGroups_773990(path: JsonNode; query: JsonNode;
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
  var valid_773992 = query.getOrDefault("MaxRecords")
  valid_773992 = validateParameter(valid_773992, JInt, required = false, default = nil)
  if valid_773992 != nil:
    section.add "MaxRecords", valid_773992
  var valid_773993 = query.getOrDefault("DBParameterGroupName")
  valid_773993 = validateParameter(valid_773993, JString, required = false,
                                 default = nil)
  if valid_773993 != nil:
    section.add "DBParameterGroupName", valid_773993
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773994 = query.getOrDefault("Action")
  valid_773994 = validateParameter(valid_773994, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_773994 != nil:
    section.add "Action", valid_773994
  var valid_773995 = query.getOrDefault("Marker")
  valid_773995 = validateParameter(valid_773995, JString, required = false,
                                 default = nil)
  if valid_773995 != nil:
    section.add "Marker", valid_773995
  var valid_773996 = query.getOrDefault("Version")
  valid_773996 = validateParameter(valid_773996, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_773996 != nil:
    section.add "Version", valid_773996
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773997 = header.getOrDefault("X-Amz-Date")
  valid_773997 = validateParameter(valid_773997, JString, required = false,
                                 default = nil)
  if valid_773997 != nil:
    section.add "X-Amz-Date", valid_773997
  var valid_773998 = header.getOrDefault("X-Amz-Security-Token")
  valid_773998 = validateParameter(valid_773998, JString, required = false,
                                 default = nil)
  if valid_773998 != nil:
    section.add "X-Amz-Security-Token", valid_773998
  var valid_773999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773999 = validateParameter(valid_773999, JString, required = false,
                                 default = nil)
  if valid_773999 != nil:
    section.add "X-Amz-Content-Sha256", valid_773999
  var valid_774000 = header.getOrDefault("X-Amz-Algorithm")
  valid_774000 = validateParameter(valid_774000, JString, required = false,
                                 default = nil)
  if valid_774000 != nil:
    section.add "X-Amz-Algorithm", valid_774000
  var valid_774001 = header.getOrDefault("X-Amz-Signature")
  valid_774001 = validateParameter(valid_774001, JString, required = false,
                                 default = nil)
  if valid_774001 != nil:
    section.add "X-Amz-Signature", valid_774001
  var valid_774002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774002 = validateParameter(valid_774002, JString, required = false,
                                 default = nil)
  if valid_774002 != nil:
    section.add "X-Amz-SignedHeaders", valid_774002
  var valid_774003 = header.getOrDefault("X-Amz-Credential")
  valid_774003 = validateParameter(valid_774003, JString, required = false,
                                 default = nil)
  if valid_774003 != nil:
    section.add "X-Amz-Credential", valid_774003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774004: Call_GetDescribeDBParameterGroups_773989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774004.validator(path, query, header, formData, body)
  let scheme = call_774004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774004.url(scheme.get, call_774004.host, call_774004.base,
                         call_774004.route, valid.getOrDefault("path"))
  result = hook(call_774004, url, valid)

proc call*(call_774005: Call_GetDescribeDBParameterGroups_773989;
          MaxRecords: int = 0; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_774006 = newJObject()
  add(query_774006, "MaxRecords", newJInt(MaxRecords))
  add(query_774006, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_774006, "Action", newJString(Action))
  add(query_774006, "Marker", newJString(Marker))
  add(query_774006, "Version", newJString(Version))
  result = call_774005.call(nil, query_774006, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_773989(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_773990, base: "/",
    url: url_GetDescribeDBParameterGroups_773991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_774045 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBParameters_774047(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameters_774046(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774048 = query.getOrDefault("Action")
  valid_774048 = validateParameter(valid_774048, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_774048 != nil:
    section.add "Action", valid_774048
  var valid_774049 = query.getOrDefault("Version")
  valid_774049 = validateParameter(valid_774049, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774049 != nil:
    section.add "Version", valid_774049
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774050 = header.getOrDefault("X-Amz-Date")
  valid_774050 = validateParameter(valid_774050, JString, required = false,
                                 default = nil)
  if valid_774050 != nil:
    section.add "X-Amz-Date", valid_774050
  var valid_774051 = header.getOrDefault("X-Amz-Security-Token")
  valid_774051 = validateParameter(valid_774051, JString, required = false,
                                 default = nil)
  if valid_774051 != nil:
    section.add "X-Amz-Security-Token", valid_774051
  var valid_774052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774052 = validateParameter(valid_774052, JString, required = false,
                                 default = nil)
  if valid_774052 != nil:
    section.add "X-Amz-Content-Sha256", valid_774052
  var valid_774053 = header.getOrDefault("X-Amz-Algorithm")
  valid_774053 = validateParameter(valid_774053, JString, required = false,
                                 default = nil)
  if valid_774053 != nil:
    section.add "X-Amz-Algorithm", valid_774053
  var valid_774054 = header.getOrDefault("X-Amz-Signature")
  valid_774054 = validateParameter(valid_774054, JString, required = false,
                                 default = nil)
  if valid_774054 != nil:
    section.add "X-Amz-Signature", valid_774054
  var valid_774055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774055 = validateParameter(valid_774055, JString, required = false,
                                 default = nil)
  if valid_774055 != nil:
    section.add "X-Amz-SignedHeaders", valid_774055
  var valid_774056 = header.getOrDefault("X-Amz-Credential")
  valid_774056 = validateParameter(valid_774056, JString, required = false,
                                 default = nil)
  if valid_774056 != nil:
    section.add "X-Amz-Credential", valid_774056
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_774057 = formData.getOrDefault("DBParameterGroupName")
  valid_774057 = validateParameter(valid_774057, JString, required = true,
                                 default = nil)
  if valid_774057 != nil:
    section.add "DBParameterGroupName", valid_774057
  var valid_774058 = formData.getOrDefault("Marker")
  valid_774058 = validateParameter(valid_774058, JString, required = false,
                                 default = nil)
  if valid_774058 != nil:
    section.add "Marker", valid_774058
  var valid_774059 = formData.getOrDefault("MaxRecords")
  valid_774059 = validateParameter(valid_774059, JInt, required = false, default = nil)
  if valid_774059 != nil:
    section.add "MaxRecords", valid_774059
  var valid_774060 = formData.getOrDefault("Source")
  valid_774060 = validateParameter(valid_774060, JString, required = false,
                                 default = nil)
  if valid_774060 != nil:
    section.add "Source", valid_774060
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774061: Call_PostDescribeDBParameters_774045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774061.validator(path, query, header, formData, body)
  let scheme = call_774061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774061.url(scheme.get, call_774061.host, call_774061.base,
                         call_774061.route, valid.getOrDefault("path"))
  result = hook(call_774061, url, valid)

proc call*(call_774062: Call_PostDescribeDBParameters_774045;
          DBParameterGroupName: string; Marker: string = "";
          Action: string = "DescribeDBParameters"; MaxRecords: int = 0;
          Version: string = "2013-01-10"; Source: string = ""): Recallable =
  ## postDescribeDBParameters
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  ##   Source: string
  var query_774063 = newJObject()
  var formData_774064 = newJObject()
  add(formData_774064, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_774064, "Marker", newJString(Marker))
  add(query_774063, "Action", newJString(Action))
  add(formData_774064, "MaxRecords", newJInt(MaxRecords))
  add(query_774063, "Version", newJString(Version))
  add(formData_774064, "Source", newJString(Source))
  result = call_774062.call(nil, query_774063, nil, formData_774064, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_774045(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_774046, base: "/",
    url: url_PostDescribeDBParameters_774047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_774026 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBParameters_774028(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameters_774027(path: JsonNode; query: JsonNode;
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
  var valid_774029 = query.getOrDefault("MaxRecords")
  valid_774029 = validateParameter(valid_774029, JInt, required = false, default = nil)
  if valid_774029 != nil:
    section.add "MaxRecords", valid_774029
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_774030 = query.getOrDefault("DBParameterGroupName")
  valid_774030 = validateParameter(valid_774030, JString, required = true,
                                 default = nil)
  if valid_774030 != nil:
    section.add "DBParameterGroupName", valid_774030
  var valid_774031 = query.getOrDefault("Action")
  valid_774031 = validateParameter(valid_774031, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_774031 != nil:
    section.add "Action", valid_774031
  var valid_774032 = query.getOrDefault("Marker")
  valid_774032 = validateParameter(valid_774032, JString, required = false,
                                 default = nil)
  if valid_774032 != nil:
    section.add "Marker", valid_774032
  var valid_774033 = query.getOrDefault("Source")
  valid_774033 = validateParameter(valid_774033, JString, required = false,
                                 default = nil)
  if valid_774033 != nil:
    section.add "Source", valid_774033
  var valid_774034 = query.getOrDefault("Version")
  valid_774034 = validateParameter(valid_774034, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774034 != nil:
    section.add "Version", valid_774034
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774035 = header.getOrDefault("X-Amz-Date")
  valid_774035 = validateParameter(valid_774035, JString, required = false,
                                 default = nil)
  if valid_774035 != nil:
    section.add "X-Amz-Date", valid_774035
  var valid_774036 = header.getOrDefault("X-Amz-Security-Token")
  valid_774036 = validateParameter(valid_774036, JString, required = false,
                                 default = nil)
  if valid_774036 != nil:
    section.add "X-Amz-Security-Token", valid_774036
  var valid_774037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774037 = validateParameter(valid_774037, JString, required = false,
                                 default = nil)
  if valid_774037 != nil:
    section.add "X-Amz-Content-Sha256", valid_774037
  var valid_774038 = header.getOrDefault("X-Amz-Algorithm")
  valid_774038 = validateParameter(valid_774038, JString, required = false,
                                 default = nil)
  if valid_774038 != nil:
    section.add "X-Amz-Algorithm", valid_774038
  var valid_774039 = header.getOrDefault("X-Amz-Signature")
  valid_774039 = validateParameter(valid_774039, JString, required = false,
                                 default = nil)
  if valid_774039 != nil:
    section.add "X-Amz-Signature", valid_774039
  var valid_774040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774040 = validateParameter(valid_774040, JString, required = false,
                                 default = nil)
  if valid_774040 != nil:
    section.add "X-Amz-SignedHeaders", valid_774040
  var valid_774041 = header.getOrDefault("X-Amz-Credential")
  valid_774041 = validateParameter(valid_774041, JString, required = false,
                                 default = nil)
  if valid_774041 != nil:
    section.add "X-Amz-Credential", valid_774041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774042: Call_GetDescribeDBParameters_774026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774042.validator(path, query, header, formData, body)
  let scheme = call_774042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774042.url(scheme.get, call_774042.host, call_774042.base,
                         call_774042.route, valid.getOrDefault("path"))
  result = hook(call_774042, url, valid)

proc call*(call_774043: Call_GetDescribeDBParameters_774026;
          DBParameterGroupName: string; MaxRecords: int = 0;
          Action: string = "DescribeDBParameters"; Marker: string = "";
          Source: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBParameters
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Source: string
  ##   Version: string (required)
  var query_774044 = newJObject()
  add(query_774044, "MaxRecords", newJInt(MaxRecords))
  add(query_774044, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_774044, "Action", newJString(Action))
  add(query_774044, "Marker", newJString(Marker))
  add(query_774044, "Source", newJString(Source))
  add(query_774044, "Version", newJString(Version))
  result = call_774043.call(nil, query_774044, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_774026(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_774027, base: "/",
    url: url_GetDescribeDBParameters_774028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_774083 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBSecurityGroups_774085(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSecurityGroups_774084(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774086 = query.getOrDefault("Action")
  valid_774086 = validateParameter(valid_774086, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_774086 != nil:
    section.add "Action", valid_774086
  var valid_774087 = query.getOrDefault("Version")
  valid_774087 = validateParameter(valid_774087, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774087 != nil:
    section.add "Version", valid_774087
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774088 = header.getOrDefault("X-Amz-Date")
  valid_774088 = validateParameter(valid_774088, JString, required = false,
                                 default = nil)
  if valid_774088 != nil:
    section.add "X-Amz-Date", valid_774088
  var valid_774089 = header.getOrDefault("X-Amz-Security-Token")
  valid_774089 = validateParameter(valid_774089, JString, required = false,
                                 default = nil)
  if valid_774089 != nil:
    section.add "X-Amz-Security-Token", valid_774089
  var valid_774090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774090 = validateParameter(valid_774090, JString, required = false,
                                 default = nil)
  if valid_774090 != nil:
    section.add "X-Amz-Content-Sha256", valid_774090
  var valid_774091 = header.getOrDefault("X-Amz-Algorithm")
  valid_774091 = validateParameter(valid_774091, JString, required = false,
                                 default = nil)
  if valid_774091 != nil:
    section.add "X-Amz-Algorithm", valid_774091
  var valid_774092 = header.getOrDefault("X-Amz-Signature")
  valid_774092 = validateParameter(valid_774092, JString, required = false,
                                 default = nil)
  if valid_774092 != nil:
    section.add "X-Amz-Signature", valid_774092
  var valid_774093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774093 = validateParameter(valid_774093, JString, required = false,
                                 default = nil)
  if valid_774093 != nil:
    section.add "X-Amz-SignedHeaders", valid_774093
  var valid_774094 = header.getOrDefault("X-Amz-Credential")
  valid_774094 = validateParameter(valid_774094, JString, required = false,
                                 default = nil)
  if valid_774094 != nil:
    section.add "X-Amz-Credential", valid_774094
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774095 = formData.getOrDefault("DBSecurityGroupName")
  valid_774095 = validateParameter(valid_774095, JString, required = false,
                                 default = nil)
  if valid_774095 != nil:
    section.add "DBSecurityGroupName", valid_774095
  var valid_774096 = formData.getOrDefault("Marker")
  valid_774096 = validateParameter(valid_774096, JString, required = false,
                                 default = nil)
  if valid_774096 != nil:
    section.add "Marker", valid_774096
  var valid_774097 = formData.getOrDefault("MaxRecords")
  valid_774097 = validateParameter(valid_774097, JInt, required = false, default = nil)
  if valid_774097 != nil:
    section.add "MaxRecords", valid_774097
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774098: Call_PostDescribeDBSecurityGroups_774083; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774098.validator(path, query, header, formData, body)
  let scheme = call_774098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774098.url(scheme.get, call_774098.host, call_774098.base,
                         call_774098.route, valid.getOrDefault("path"))
  result = hook(call_774098, url, valid)

proc call*(call_774099: Call_PostDescribeDBSecurityGroups_774083;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_774100 = newJObject()
  var formData_774101 = newJObject()
  add(formData_774101, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_774101, "Marker", newJString(Marker))
  add(query_774100, "Action", newJString(Action))
  add(formData_774101, "MaxRecords", newJInt(MaxRecords))
  add(query_774100, "Version", newJString(Version))
  result = call_774099.call(nil, query_774100, nil, formData_774101, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_774083(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_774084, base: "/",
    url: url_PostDescribeDBSecurityGroups_774085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_774065 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBSecurityGroups_774067(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSecurityGroups_774066(path: JsonNode; query: JsonNode;
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
  var valid_774068 = query.getOrDefault("MaxRecords")
  valid_774068 = validateParameter(valid_774068, JInt, required = false, default = nil)
  if valid_774068 != nil:
    section.add "MaxRecords", valid_774068
  var valid_774069 = query.getOrDefault("DBSecurityGroupName")
  valid_774069 = validateParameter(valid_774069, JString, required = false,
                                 default = nil)
  if valid_774069 != nil:
    section.add "DBSecurityGroupName", valid_774069
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774070 = query.getOrDefault("Action")
  valid_774070 = validateParameter(valid_774070, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_774070 != nil:
    section.add "Action", valid_774070
  var valid_774071 = query.getOrDefault("Marker")
  valid_774071 = validateParameter(valid_774071, JString, required = false,
                                 default = nil)
  if valid_774071 != nil:
    section.add "Marker", valid_774071
  var valid_774072 = query.getOrDefault("Version")
  valid_774072 = validateParameter(valid_774072, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774072 != nil:
    section.add "Version", valid_774072
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774073 = header.getOrDefault("X-Amz-Date")
  valid_774073 = validateParameter(valid_774073, JString, required = false,
                                 default = nil)
  if valid_774073 != nil:
    section.add "X-Amz-Date", valid_774073
  var valid_774074 = header.getOrDefault("X-Amz-Security-Token")
  valid_774074 = validateParameter(valid_774074, JString, required = false,
                                 default = nil)
  if valid_774074 != nil:
    section.add "X-Amz-Security-Token", valid_774074
  var valid_774075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774075 = validateParameter(valid_774075, JString, required = false,
                                 default = nil)
  if valid_774075 != nil:
    section.add "X-Amz-Content-Sha256", valid_774075
  var valid_774076 = header.getOrDefault("X-Amz-Algorithm")
  valid_774076 = validateParameter(valid_774076, JString, required = false,
                                 default = nil)
  if valid_774076 != nil:
    section.add "X-Amz-Algorithm", valid_774076
  var valid_774077 = header.getOrDefault("X-Amz-Signature")
  valid_774077 = validateParameter(valid_774077, JString, required = false,
                                 default = nil)
  if valid_774077 != nil:
    section.add "X-Amz-Signature", valid_774077
  var valid_774078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774078 = validateParameter(valid_774078, JString, required = false,
                                 default = nil)
  if valid_774078 != nil:
    section.add "X-Amz-SignedHeaders", valid_774078
  var valid_774079 = header.getOrDefault("X-Amz-Credential")
  valid_774079 = validateParameter(valid_774079, JString, required = false,
                                 default = nil)
  if valid_774079 != nil:
    section.add "X-Amz-Credential", valid_774079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774080: Call_GetDescribeDBSecurityGroups_774065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774080.validator(path, query, header, formData, body)
  let scheme = call_774080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774080.url(scheme.get, call_774080.host, call_774080.base,
                         call_774080.route, valid.getOrDefault("path"))
  result = hook(call_774080, url, valid)

proc call*(call_774081: Call_GetDescribeDBSecurityGroups_774065;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_774082 = newJObject()
  add(query_774082, "MaxRecords", newJInt(MaxRecords))
  add(query_774082, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_774082, "Action", newJString(Action))
  add(query_774082, "Marker", newJString(Marker))
  add(query_774082, "Version", newJString(Version))
  result = call_774081.call(nil, query_774082, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_774065(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_774066, base: "/",
    url: url_GetDescribeDBSecurityGroups_774067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_774122 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBSnapshots_774124(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSnapshots_774123(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774125 = query.getOrDefault("Action")
  valid_774125 = validateParameter(valid_774125, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_774125 != nil:
    section.add "Action", valid_774125
  var valid_774126 = query.getOrDefault("Version")
  valid_774126 = validateParameter(valid_774126, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774126 != nil:
    section.add "Version", valid_774126
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774127 = header.getOrDefault("X-Amz-Date")
  valid_774127 = validateParameter(valid_774127, JString, required = false,
                                 default = nil)
  if valid_774127 != nil:
    section.add "X-Amz-Date", valid_774127
  var valid_774128 = header.getOrDefault("X-Amz-Security-Token")
  valid_774128 = validateParameter(valid_774128, JString, required = false,
                                 default = nil)
  if valid_774128 != nil:
    section.add "X-Amz-Security-Token", valid_774128
  var valid_774129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774129 = validateParameter(valid_774129, JString, required = false,
                                 default = nil)
  if valid_774129 != nil:
    section.add "X-Amz-Content-Sha256", valid_774129
  var valid_774130 = header.getOrDefault("X-Amz-Algorithm")
  valid_774130 = validateParameter(valid_774130, JString, required = false,
                                 default = nil)
  if valid_774130 != nil:
    section.add "X-Amz-Algorithm", valid_774130
  var valid_774131 = header.getOrDefault("X-Amz-Signature")
  valid_774131 = validateParameter(valid_774131, JString, required = false,
                                 default = nil)
  if valid_774131 != nil:
    section.add "X-Amz-Signature", valid_774131
  var valid_774132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774132 = validateParameter(valid_774132, JString, required = false,
                                 default = nil)
  if valid_774132 != nil:
    section.add "X-Amz-SignedHeaders", valid_774132
  var valid_774133 = header.getOrDefault("X-Amz-Credential")
  valid_774133 = validateParameter(valid_774133, JString, required = false,
                                 default = nil)
  if valid_774133 != nil:
    section.add "X-Amz-Credential", valid_774133
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774134 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774134 = validateParameter(valid_774134, JString, required = false,
                                 default = nil)
  if valid_774134 != nil:
    section.add "DBInstanceIdentifier", valid_774134
  var valid_774135 = formData.getOrDefault("SnapshotType")
  valid_774135 = validateParameter(valid_774135, JString, required = false,
                                 default = nil)
  if valid_774135 != nil:
    section.add "SnapshotType", valid_774135
  var valid_774136 = formData.getOrDefault("Marker")
  valid_774136 = validateParameter(valid_774136, JString, required = false,
                                 default = nil)
  if valid_774136 != nil:
    section.add "Marker", valid_774136
  var valid_774137 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_774137 = validateParameter(valid_774137, JString, required = false,
                                 default = nil)
  if valid_774137 != nil:
    section.add "DBSnapshotIdentifier", valid_774137
  var valid_774138 = formData.getOrDefault("MaxRecords")
  valid_774138 = validateParameter(valid_774138, JInt, required = false, default = nil)
  if valid_774138 != nil:
    section.add "MaxRecords", valid_774138
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774139: Call_PostDescribeDBSnapshots_774122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774139.validator(path, query, header, formData, body)
  let scheme = call_774139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774139.url(scheme.get, call_774139.host, call_774139.base,
                         call_774139.route, valid.getOrDefault("path"))
  result = hook(call_774139, url, valid)

proc call*(call_774140: Call_PostDescribeDBSnapshots_774122;
          DBInstanceIdentifier: string = ""; SnapshotType: string = "";
          Marker: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSnapshots
  ##   DBInstanceIdentifier: string
  ##   SnapshotType: string
  ##   Marker: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_774141 = newJObject()
  var formData_774142 = newJObject()
  add(formData_774142, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774142, "SnapshotType", newJString(SnapshotType))
  add(formData_774142, "Marker", newJString(Marker))
  add(formData_774142, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_774141, "Action", newJString(Action))
  add(formData_774142, "MaxRecords", newJInt(MaxRecords))
  add(query_774141, "Version", newJString(Version))
  result = call_774140.call(nil, query_774141, nil, formData_774142, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_774122(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_774123, base: "/",
    url: url_PostDescribeDBSnapshots_774124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_774102 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBSnapshots_774104(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSnapshots_774103(path: JsonNode; query: JsonNode;
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
  var valid_774105 = query.getOrDefault("MaxRecords")
  valid_774105 = validateParameter(valid_774105, JInt, required = false, default = nil)
  if valid_774105 != nil:
    section.add "MaxRecords", valid_774105
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774106 = query.getOrDefault("Action")
  valid_774106 = validateParameter(valid_774106, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_774106 != nil:
    section.add "Action", valid_774106
  var valid_774107 = query.getOrDefault("Marker")
  valid_774107 = validateParameter(valid_774107, JString, required = false,
                                 default = nil)
  if valid_774107 != nil:
    section.add "Marker", valid_774107
  var valid_774108 = query.getOrDefault("SnapshotType")
  valid_774108 = validateParameter(valid_774108, JString, required = false,
                                 default = nil)
  if valid_774108 != nil:
    section.add "SnapshotType", valid_774108
  var valid_774109 = query.getOrDefault("Version")
  valid_774109 = validateParameter(valid_774109, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774109 != nil:
    section.add "Version", valid_774109
  var valid_774110 = query.getOrDefault("DBInstanceIdentifier")
  valid_774110 = validateParameter(valid_774110, JString, required = false,
                                 default = nil)
  if valid_774110 != nil:
    section.add "DBInstanceIdentifier", valid_774110
  var valid_774111 = query.getOrDefault("DBSnapshotIdentifier")
  valid_774111 = validateParameter(valid_774111, JString, required = false,
                                 default = nil)
  if valid_774111 != nil:
    section.add "DBSnapshotIdentifier", valid_774111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774112 = header.getOrDefault("X-Amz-Date")
  valid_774112 = validateParameter(valid_774112, JString, required = false,
                                 default = nil)
  if valid_774112 != nil:
    section.add "X-Amz-Date", valid_774112
  var valid_774113 = header.getOrDefault("X-Amz-Security-Token")
  valid_774113 = validateParameter(valid_774113, JString, required = false,
                                 default = nil)
  if valid_774113 != nil:
    section.add "X-Amz-Security-Token", valid_774113
  var valid_774114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774114 = validateParameter(valid_774114, JString, required = false,
                                 default = nil)
  if valid_774114 != nil:
    section.add "X-Amz-Content-Sha256", valid_774114
  var valid_774115 = header.getOrDefault("X-Amz-Algorithm")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "X-Amz-Algorithm", valid_774115
  var valid_774116 = header.getOrDefault("X-Amz-Signature")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "X-Amz-Signature", valid_774116
  var valid_774117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774117 = validateParameter(valid_774117, JString, required = false,
                                 default = nil)
  if valid_774117 != nil:
    section.add "X-Amz-SignedHeaders", valid_774117
  var valid_774118 = header.getOrDefault("X-Amz-Credential")
  valid_774118 = validateParameter(valid_774118, JString, required = false,
                                 default = nil)
  if valid_774118 != nil:
    section.add "X-Amz-Credential", valid_774118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774119: Call_GetDescribeDBSnapshots_774102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774119.validator(path, query, header, formData, body)
  let scheme = call_774119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774119.url(scheme.get, call_774119.host, call_774119.base,
                         call_774119.route, valid.getOrDefault("path"))
  result = hook(call_774119, url, valid)

proc call*(call_774120: Call_GetDescribeDBSnapshots_774102; MaxRecords: int = 0;
          Action: string = "DescribeDBSnapshots"; Marker: string = "";
          SnapshotType: string = ""; Version: string = "2013-01-10";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = ""): Recallable =
  ## getDescribeDBSnapshots
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SnapshotType: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  var query_774121 = newJObject()
  add(query_774121, "MaxRecords", newJInt(MaxRecords))
  add(query_774121, "Action", newJString(Action))
  add(query_774121, "Marker", newJString(Marker))
  add(query_774121, "SnapshotType", newJString(SnapshotType))
  add(query_774121, "Version", newJString(Version))
  add(query_774121, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_774121, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_774120.call(nil, query_774121, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_774102(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_774103, base: "/",
    url: url_GetDescribeDBSnapshots_774104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_774161 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBSubnetGroups_774163(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSubnetGroups_774162(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774164 = query.getOrDefault("Action")
  valid_774164 = validateParameter(valid_774164, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_774164 != nil:
    section.add "Action", valid_774164
  var valid_774165 = query.getOrDefault("Version")
  valid_774165 = validateParameter(valid_774165, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774165 != nil:
    section.add "Version", valid_774165
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774166 = header.getOrDefault("X-Amz-Date")
  valid_774166 = validateParameter(valid_774166, JString, required = false,
                                 default = nil)
  if valid_774166 != nil:
    section.add "X-Amz-Date", valid_774166
  var valid_774167 = header.getOrDefault("X-Amz-Security-Token")
  valid_774167 = validateParameter(valid_774167, JString, required = false,
                                 default = nil)
  if valid_774167 != nil:
    section.add "X-Amz-Security-Token", valid_774167
  var valid_774168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774168 = validateParameter(valid_774168, JString, required = false,
                                 default = nil)
  if valid_774168 != nil:
    section.add "X-Amz-Content-Sha256", valid_774168
  var valid_774169 = header.getOrDefault("X-Amz-Algorithm")
  valid_774169 = validateParameter(valid_774169, JString, required = false,
                                 default = nil)
  if valid_774169 != nil:
    section.add "X-Amz-Algorithm", valid_774169
  var valid_774170 = header.getOrDefault("X-Amz-Signature")
  valid_774170 = validateParameter(valid_774170, JString, required = false,
                                 default = nil)
  if valid_774170 != nil:
    section.add "X-Amz-Signature", valid_774170
  var valid_774171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774171 = validateParameter(valid_774171, JString, required = false,
                                 default = nil)
  if valid_774171 != nil:
    section.add "X-Amz-SignedHeaders", valid_774171
  var valid_774172 = header.getOrDefault("X-Amz-Credential")
  valid_774172 = validateParameter(valid_774172, JString, required = false,
                                 default = nil)
  if valid_774172 != nil:
    section.add "X-Amz-Credential", valid_774172
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774173 = formData.getOrDefault("DBSubnetGroupName")
  valid_774173 = validateParameter(valid_774173, JString, required = false,
                                 default = nil)
  if valid_774173 != nil:
    section.add "DBSubnetGroupName", valid_774173
  var valid_774174 = formData.getOrDefault("Marker")
  valid_774174 = validateParameter(valid_774174, JString, required = false,
                                 default = nil)
  if valid_774174 != nil:
    section.add "Marker", valid_774174
  var valid_774175 = formData.getOrDefault("MaxRecords")
  valid_774175 = validateParameter(valid_774175, JInt, required = false, default = nil)
  if valid_774175 != nil:
    section.add "MaxRecords", valid_774175
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774176: Call_PostDescribeDBSubnetGroups_774161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774176.validator(path, query, header, formData, body)
  let scheme = call_774176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774176.url(scheme.get, call_774176.host, call_774176.base,
                         call_774176.route, valid.getOrDefault("path"))
  result = hook(call_774176, url, valid)

proc call*(call_774177: Call_PostDescribeDBSubnetGroups_774161;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_774178 = newJObject()
  var formData_774179 = newJObject()
  add(formData_774179, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_774179, "Marker", newJString(Marker))
  add(query_774178, "Action", newJString(Action))
  add(formData_774179, "MaxRecords", newJInt(MaxRecords))
  add(query_774178, "Version", newJString(Version))
  result = call_774177.call(nil, query_774178, nil, formData_774179, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_774161(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_774162, base: "/",
    url: url_PostDescribeDBSubnetGroups_774163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_774143 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBSubnetGroups_774145(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSubnetGroups_774144(path: JsonNode; query: JsonNode;
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
  var valid_774146 = query.getOrDefault("MaxRecords")
  valid_774146 = validateParameter(valid_774146, JInt, required = false, default = nil)
  if valid_774146 != nil:
    section.add "MaxRecords", valid_774146
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774147 = query.getOrDefault("Action")
  valid_774147 = validateParameter(valid_774147, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_774147 != nil:
    section.add "Action", valid_774147
  var valid_774148 = query.getOrDefault("Marker")
  valid_774148 = validateParameter(valid_774148, JString, required = false,
                                 default = nil)
  if valid_774148 != nil:
    section.add "Marker", valid_774148
  var valid_774149 = query.getOrDefault("DBSubnetGroupName")
  valid_774149 = validateParameter(valid_774149, JString, required = false,
                                 default = nil)
  if valid_774149 != nil:
    section.add "DBSubnetGroupName", valid_774149
  var valid_774150 = query.getOrDefault("Version")
  valid_774150 = validateParameter(valid_774150, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774150 != nil:
    section.add "Version", valid_774150
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774151 = header.getOrDefault("X-Amz-Date")
  valid_774151 = validateParameter(valid_774151, JString, required = false,
                                 default = nil)
  if valid_774151 != nil:
    section.add "X-Amz-Date", valid_774151
  var valid_774152 = header.getOrDefault("X-Amz-Security-Token")
  valid_774152 = validateParameter(valid_774152, JString, required = false,
                                 default = nil)
  if valid_774152 != nil:
    section.add "X-Amz-Security-Token", valid_774152
  var valid_774153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774153 = validateParameter(valid_774153, JString, required = false,
                                 default = nil)
  if valid_774153 != nil:
    section.add "X-Amz-Content-Sha256", valid_774153
  var valid_774154 = header.getOrDefault("X-Amz-Algorithm")
  valid_774154 = validateParameter(valid_774154, JString, required = false,
                                 default = nil)
  if valid_774154 != nil:
    section.add "X-Amz-Algorithm", valid_774154
  var valid_774155 = header.getOrDefault("X-Amz-Signature")
  valid_774155 = validateParameter(valid_774155, JString, required = false,
                                 default = nil)
  if valid_774155 != nil:
    section.add "X-Amz-Signature", valid_774155
  var valid_774156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774156 = validateParameter(valid_774156, JString, required = false,
                                 default = nil)
  if valid_774156 != nil:
    section.add "X-Amz-SignedHeaders", valid_774156
  var valid_774157 = header.getOrDefault("X-Amz-Credential")
  valid_774157 = validateParameter(valid_774157, JString, required = false,
                                 default = nil)
  if valid_774157 != nil:
    section.add "X-Amz-Credential", valid_774157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774158: Call_GetDescribeDBSubnetGroups_774143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774158.validator(path, query, header, formData, body)
  let scheme = call_774158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774158.url(scheme.get, call_774158.host, call_774158.base,
                         call_774158.route, valid.getOrDefault("path"))
  result = hook(call_774158, url, valid)

proc call*(call_774159: Call_GetDescribeDBSubnetGroups_774143; MaxRecords: int = 0;
          Action: string = "DescribeDBSubnetGroups"; Marker: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_774160 = newJObject()
  add(query_774160, "MaxRecords", newJInt(MaxRecords))
  add(query_774160, "Action", newJString(Action))
  add(query_774160, "Marker", newJString(Marker))
  add(query_774160, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_774160, "Version", newJString(Version))
  result = call_774159.call(nil, query_774160, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_774143(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_774144, base: "/",
    url: url_GetDescribeDBSubnetGroups_774145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_774198 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEngineDefaultParameters_774200(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEngineDefaultParameters_774199(path: JsonNode;
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
  var valid_774201 = query.getOrDefault("Action")
  valid_774201 = validateParameter(valid_774201, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_774201 != nil:
    section.add "Action", valid_774201
  var valid_774202 = query.getOrDefault("Version")
  valid_774202 = validateParameter(valid_774202, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774202 != nil:
    section.add "Version", valid_774202
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774203 = header.getOrDefault("X-Amz-Date")
  valid_774203 = validateParameter(valid_774203, JString, required = false,
                                 default = nil)
  if valid_774203 != nil:
    section.add "X-Amz-Date", valid_774203
  var valid_774204 = header.getOrDefault("X-Amz-Security-Token")
  valid_774204 = validateParameter(valid_774204, JString, required = false,
                                 default = nil)
  if valid_774204 != nil:
    section.add "X-Amz-Security-Token", valid_774204
  var valid_774205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774205 = validateParameter(valid_774205, JString, required = false,
                                 default = nil)
  if valid_774205 != nil:
    section.add "X-Amz-Content-Sha256", valid_774205
  var valid_774206 = header.getOrDefault("X-Amz-Algorithm")
  valid_774206 = validateParameter(valid_774206, JString, required = false,
                                 default = nil)
  if valid_774206 != nil:
    section.add "X-Amz-Algorithm", valid_774206
  var valid_774207 = header.getOrDefault("X-Amz-Signature")
  valid_774207 = validateParameter(valid_774207, JString, required = false,
                                 default = nil)
  if valid_774207 != nil:
    section.add "X-Amz-Signature", valid_774207
  var valid_774208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774208 = validateParameter(valid_774208, JString, required = false,
                                 default = nil)
  if valid_774208 != nil:
    section.add "X-Amz-SignedHeaders", valid_774208
  var valid_774209 = header.getOrDefault("X-Amz-Credential")
  valid_774209 = validateParameter(valid_774209, JString, required = false,
                                 default = nil)
  if valid_774209 != nil:
    section.add "X-Amz-Credential", valid_774209
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774210 = formData.getOrDefault("Marker")
  valid_774210 = validateParameter(valid_774210, JString, required = false,
                                 default = nil)
  if valid_774210 != nil:
    section.add "Marker", valid_774210
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_774211 = formData.getOrDefault("DBParameterGroupFamily")
  valid_774211 = validateParameter(valid_774211, JString, required = true,
                                 default = nil)
  if valid_774211 != nil:
    section.add "DBParameterGroupFamily", valid_774211
  var valid_774212 = formData.getOrDefault("MaxRecords")
  valid_774212 = validateParameter(valid_774212, JInt, required = false, default = nil)
  if valid_774212 != nil:
    section.add "MaxRecords", valid_774212
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774213: Call_PostDescribeEngineDefaultParameters_774198;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774213.validator(path, query, header, formData, body)
  let scheme = call_774213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774213.url(scheme.get, call_774213.host, call_774213.base,
                         call_774213.route, valid.getOrDefault("path"))
  result = hook(call_774213, url, valid)

proc call*(call_774214: Call_PostDescribeEngineDefaultParameters_774198;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_774215 = newJObject()
  var formData_774216 = newJObject()
  add(formData_774216, "Marker", newJString(Marker))
  add(query_774215, "Action", newJString(Action))
  add(formData_774216, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_774216, "MaxRecords", newJInt(MaxRecords))
  add(query_774215, "Version", newJString(Version))
  result = call_774214.call(nil, query_774215, nil, formData_774216, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_774198(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_774199, base: "/",
    url: url_PostDescribeEngineDefaultParameters_774200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_774180 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEngineDefaultParameters_774182(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEngineDefaultParameters_774181(path: JsonNode;
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
  var valid_774183 = query.getOrDefault("MaxRecords")
  valid_774183 = validateParameter(valid_774183, JInt, required = false, default = nil)
  if valid_774183 != nil:
    section.add "MaxRecords", valid_774183
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_774184 = query.getOrDefault("DBParameterGroupFamily")
  valid_774184 = validateParameter(valid_774184, JString, required = true,
                                 default = nil)
  if valid_774184 != nil:
    section.add "DBParameterGroupFamily", valid_774184
  var valid_774185 = query.getOrDefault("Action")
  valid_774185 = validateParameter(valid_774185, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_774185 != nil:
    section.add "Action", valid_774185
  var valid_774186 = query.getOrDefault("Marker")
  valid_774186 = validateParameter(valid_774186, JString, required = false,
                                 default = nil)
  if valid_774186 != nil:
    section.add "Marker", valid_774186
  var valid_774187 = query.getOrDefault("Version")
  valid_774187 = validateParameter(valid_774187, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774187 != nil:
    section.add "Version", valid_774187
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774188 = header.getOrDefault("X-Amz-Date")
  valid_774188 = validateParameter(valid_774188, JString, required = false,
                                 default = nil)
  if valid_774188 != nil:
    section.add "X-Amz-Date", valid_774188
  var valid_774189 = header.getOrDefault("X-Amz-Security-Token")
  valid_774189 = validateParameter(valid_774189, JString, required = false,
                                 default = nil)
  if valid_774189 != nil:
    section.add "X-Amz-Security-Token", valid_774189
  var valid_774190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774190 = validateParameter(valid_774190, JString, required = false,
                                 default = nil)
  if valid_774190 != nil:
    section.add "X-Amz-Content-Sha256", valid_774190
  var valid_774191 = header.getOrDefault("X-Amz-Algorithm")
  valid_774191 = validateParameter(valid_774191, JString, required = false,
                                 default = nil)
  if valid_774191 != nil:
    section.add "X-Amz-Algorithm", valid_774191
  var valid_774192 = header.getOrDefault("X-Amz-Signature")
  valid_774192 = validateParameter(valid_774192, JString, required = false,
                                 default = nil)
  if valid_774192 != nil:
    section.add "X-Amz-Signature", valid_774192
  var valid_774193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774193 = validateParameter(valid_774193, JString, required = false,
                                 default = nil)
  if valid_774193 != nil:
    section.add "X-Amz-SignedHeaders", valid_774193
  var valid_774194 = header.getOrDefault("X-Amz-Credential")
  valid_774194 = validateParameter(valid_774194, JString, required = false,
                                 default = nil)
  if valid_774194 != nil:
    section.add "X-Amz-Credential", valid_774194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774195: Call_GetDescribeEngineDefaultParameters_774180;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774195.validator(path, query, header, formData, body)
  let scheme = call_774195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774195.url(scheme.get, call_774195.host, call_774195.base,
                         call_774195.route, valid.getOrDefault("path"))
  result = hook(call_774195, url, valid)

proc call*(call_774196: Call_GetDescribeEngineDefaultParameters_774180;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_774197 = newJObject()
  add(query_774197, "MaxRecords", newJInt(MaxRecords))
  add(query_774197, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_774197, "Action", newJString(Action))
  add(query_774197, "Marker", newJString(Marker))
  add(query_774197, "Version", newJString(Version))
  result = call_774196.call(nil, query_774197, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_774180(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_774181, base: "/",
    url: url_GetDescribeEngineDefaultParameters_774182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_774233 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEventCategories_774235(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventCategories_774234(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774236 = query.getOrDefault("Action")
  valid_774236 = validateParameter(valid_774236, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_774236 != nil:
    section.add "Action", valid_774236
  var valid_774237 = query.getOrDefault("Version")
  valid_774237 = validateParameter(valid_774237, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774237 != nil:
    section.add "Version", valid_774237
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774238 = header.getOrDefault("X-Amz-Date")
  valid_774238 = validateParameter(valid_774238, JString, required = false,
                                 default = nil)
  if valid_774238 != nil:
    section.add "X-Amz-Date", valid_774238
  var valid_774239 = header.getOrDefault("X-Amz-Security-Token")
  valid_774239 = validateParameter(valid_774239, JString, required = false,
                                 default = nil)
  if valid_774239 != nil:
    section.add "X-Amz-Security-Token", valid_774239
  var valid_774240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774240 = validateParameter(valid_774240, JString, required = false,
                                 default = nil)
  if valid_774240 != nil:
    section.add "X-Amz-Content-Sha256", valid_774240
  var valid_774241 = header.getOrDefault("X-Amz-Algorithm")
  valid_774241 = validateParameter(valid_774241, JString, required = false,
                                 default = nil)
  if valid_774241 != nil:
    section.add "X-Amz-Algorithm", valid_774241
  var valid_774242 = header.getOrDefault("X-Amz-Signature")
  valid_774242 = validateParameter(valid_774242, JString, required = false,
                                 default = nil)
  if valid_774242 != nil:
    section.add "X-Amz-Signature", valid_774242
  var valid_774243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774243 = validateParameter(valid_774243, JString, required = false,
                                 default = nil)
  if valid_774243 != nil:
    section.add "X-Amz-SignedHeaders", valid_774243
  var valid_774244 = header.getOrDefault("X-Amz-Credential")
  valid_774244 = validateParameter(valid_774244, JString, required = false,
                                 default = nil)
  if valid_774244 != nil:
    section.add "X-Amz-Credential", valid_774244
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_774245 = formData.getOrDefault("SourceType")
  valid_774245 = validateParameter(valid_774245, JString, required = false,
                                 default = nil)
  if valid_774245 != nil:
    section.add "SourceType", valid_774245
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774246: Call_PostDescribeEventCategories_774233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774246.validator(path, query, header, formData, body)
  let scheme = call_774246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774246.url(scheme.get, call_774246.host, call_774246.base,
                         call_774246.route, valid.getOrDefault("path"))
  result = hook(call_774246, url, valid)

proc call*(call_774247: Call_PostDescribeEventCategories_774233;
          Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_774248 = newJObject()
  var formData_774249 = newJObject()
  add(query_774248, "Action", newJString(Action))
  add(query_774248, "Version", newJString(Version))
  add(formData_774249, "SourceType", newJString(SourceType))
  result = call_774247.call(nil, query_774248, nil, formData_774249, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_774233(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_774234, base: "/",
    url: url_PostDescribeEventCategories_774235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_774217 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEventCategories_774219(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventCategories_774218(path: JsonNode; query: JsonNode;
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
  var valid_774220 = query.getOrDefault("SourceType")
  valid_774220 = validateParameter(valid_774220, JString, required = false,
                                 default = nil)
  if valid_774220 != nil:
    section.add "SourceType", valid_774220
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774221 = query.getOrDefault("Action")
  valid_774221 = validateParameter(valid_774221, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_774221 != nil:
    section.add "Action", valid_774221
  var valid_774222 = query.getOrDefault("Version")
  valid_774222 = validateParameter(valid_774222, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774222 != nil:
    section.add "Version", valid_774222
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774223 = header.getOrDefault("X-Amz-Date")
  valid_774223 = validateParameter(valid_774223, JString, required = false,
                                 default = nil)
  if valid_774223 != nil:
    section.add "X-Amz-Date", valid_774223
  var valid_774224 = header.getOrDefault("X-Amz-Security-Token")
  valid_774224 = validateParameter(valid_774224, JString, required = false,
                                 default = nil)
  if valid_774224 != nil:
    section.add "X-Amz-Security-Token", valid_774224
  var valid_774225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774225 = validateParameter(valid_774225, JString, required = false,
                                 default = nil)
  if valid_774225 != nil:
    section.add "X-Amz-Content-Sha256", valid_774225
  var valid_774226 = header.getOrDefault("X-Amz-Algorithm")
  valid_774226 = validateParameter(valid_774226, JString, required = false,
                                 default = nil)
  if valid_774226 != nil:
    section.add "X-Amz-Algorithm", valid_774226
  var valid_774227 = header.getOrDefault("X-Amz-Signature")
  valid_774227 = validateParameter(valid_774227, JString, required = false,
                                 default = nil)
  if valid_774227 != nil:
    section.add "X-Amz-Signature", valid_774227
  var valid_774228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774228 = validateParameter(valid_774228, JString, required = false,
                                 default = nil)
  if valid_774228 != nil:
    section.add "X-Amz-SignedHeaders", valid_774228
  var valid_774229 = header.getOrDefault("X-Amz-Credential")
  valid_774229 = validateParameter(valid_774229, JString, required = false,
                                 default = nil)
  if valid_774229 != nil:
    section.add "X-Amz-Credential", valid_774229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774230: Call_GetDescribeEventCategories_774217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774230.validator(path, query, header, formData, body)
  let scheme = call_774230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774230.url(scheme.get, call_774230.host, call_774230.base,
                         call_774230.route, valid.getOrDefault("path"))
  result = hook(call_774230, url, valid)

proc call*(call_774231: Call_GetDescribeEventCategories_774217;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774232 = newJObject()
  add(query_774232, "SourceType", newJString(SourceType))
  add(query_774232, "Action", newJString(Action))
  add(query_774232, "Version", newJString(Version))
  result = call_774231.call(nil, query_774232, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_774217(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_774218, base: "/",
    url: url_GetDescribeEventCategories_774219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_774268 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEventSubscriptions_774270(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventSubscriptions_774269(path: JsonNode;
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
  var valid_774271 = query.getOrDefault("Action")
  valid_774271 = validateParameter(valid_774271, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_774271 != nil:
    section.add "Action", valid_774271
  var valid_774272 = query.getOrDefault("Version")
  valid_774272 = validateParameter(valid_774272, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774272 != nil:
    section.add "Version", valid_774272
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774273 = header.getOrDefault("X-Amz-Date")
  valid_774273 = validateParameter(valid_774273, JString, required = false,
                                 default = nil)
  if valid_774273 != nil:
    section.add "X-Amz-Date", valid_774273
  var valid_774274 = header.getOrDefault("X-Amz-Security-Token")
  valid_774274 = validateParameter(valid_774274, JString, required = false,
                                 default = nil)
  if valid_774274 != nil:
    section.add "X-Amz-Security-Token", valid_774274
  var valid_774275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774275 = validateParameter(valid_774275, JString, required = false,
                                 default = nil)
  if valid_774275 != nil:
    section.add "X-Amz-Content-Sha256", valid_774275
  var valid_774276 = header.getOrDefault("X-Amz-Algorithm")
  valid_774276 = validateParameter(valid_774276, JString, required = false,
                                 default = nil)
  if valid_774276 != nil:
    section.add "X-Amz-Algorithm", valid_774276
  var valid_774277 = header.getOrDefault("X-Amz-Signature")
  valid_774277 = validateParameter(valid_774277, JString, required = false,
                                 default = nil)
  if valid_774277 != nil:
    section.add "X-Amz-Signature", valid_774277
  var valid_774278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774278 = validateParameter(valid_774278, JString, required = false,
                                 default = nil)
  if valid_774278 != nil:
    section.add "X-Amz-SignedHeaders", valid_774278
  var valid_774279 = header.getOrDefault("X-Amz-Credential")
  valid_774279 = validateParameter(valid_774279, JString, required = false,
                                 default = nil)
  if valid_774279 != nil:
    section.add "X-Amz-Credential", valid_774279
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774280 = formData.getOrDefault("Marker")
  valid_774280 = validateParameter(valid_774280, JString, required = false,
                                 default = nil)
  if valid_774280 != nil:
    section.add "Marker", valid_774280
  var valid_774281 = formData.getOrDefault("SubscriptionName")
  valid_774281 = validateParameter(valid_774281, JString, required = false,
                                 default = nil)
  if valid_774281 != nil:
    section.add "SubscriptionName", valid_774281
  var valid_774282 = formData.getOrDefault("MaxRecords")
  valid_774282 = validateParameter(valid_774282, JInt, required = false, default = nil)
  if valid_774282 != nil:
    section.add "MaxRecords", valid_774282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774283: Call_PostDescribeEventSubscriptions_774268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774283.validator(path, query, header, formData, body)
  let scheme = call_774283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774283.url(scheme.get, call_774283.host, call_774283.base,
                         call_774283.route, valid.getOrDefault("path"))
  result = hook(call_774283, url, valid)

proc call*(call_774284: Call_PostDescribeEventSubscriptions_774268;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_774285 = newJObject()
  var formData_774286 = newJObject()
  add(formData_774286, "Marker", newJString(Marker))
  add(formData_774286, "SubscriptionName", newJString(SubscriptionName))
  add(query_774285, "Action", newJString(Action))
  add(formData_774286, "MaxRecords", newJInt(MaxRecords))
  add(query_774285, "Version", newJString(Version))
  result = call_774284.call(nil, query_774285, nil, formData_774286, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_774268(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_774269, base: "/",
    url: url_PostDescribeEventSubscriptions_774270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_774250 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEventSubscriptions_774252(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventSubscriptions_774251(path: JsonNode; query: JsonNode;
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
  var valid_774253 = query.getOrDefault("MaxRecords")
  valid_774253 = validateParameter(valid_774253, JInt, required = false, default = nil)
  if valid_774253 != nil:
    section.add "MaxRecords", valid_774253
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774254 = query.getOrDefault("Action")
  valid_774254 = validateParameter(valid_774254, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_774254 != nil:
    section.add "Action", valid_774254
  var valid_774255 = query.getOrDefault("Marker")
  valid_774255 = validateParameter(valid_774255, JString, required = false,
                                 default = nil)
  if valid_774255 != nil:
    section.add "Marker", valid_774255
  var valid_774256 = query.getOrDefault("SubscriptionName")
  valid_774256 = validateParameter(valid_774256, JString, required = false,
                                 default = nil)
  if valid_774256 != nil:
    section.add "SubscriptionName", valid_774256
  var valid_774257 = query.getOrDefault("Version")
  valid_774257 = validateParameter(valid_774257, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774257 != nil:
    section.add "Version", valid_774257
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774258 = header.getOrDefault("X-Amz-Date")
  valid_774258 = validateParameter(valid_774258, JString, required = false,
                                 default = nil)
  if valid_774258 != nil:
    section.add "X-Amz-Date", valid_774258
  var valid_774259 = header.getOrDefault("X-Amz-Security-Token")
  valid_774259 = validateParameter(valid_774259, JString, required = false,
                                 default = nil)
  if valid_774259 != nil:
    section.add "X-Amz-Security-Token", valid_774259
  var valid_774260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774260 = validateParameter(valid_774260, JString, required = false,
                                 default = nil)
  if valid_774260 != nil:
    section.add "X-Amz-Content-Sha256", valid_774260
  var valid_774261 = header.getOrDefault("X-Amz-Algorithm")
  valid_774261 = validateParameter(valid_774261, JString, required = false,
                                 default = nil)
  if valid_774261 != nil:
    section.add "X-Amz-Algorithm", valid_774261
  var valid_774262 = header.getOrDefault("X-Amz-Signature")
  valid_774262 = validateParameter(valid_774262, JString, required = false,
                                 default = nil)
  if valid_774262 != nil:
    section.add "X-Amz-Signature", valid_774262
  var valid_774263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774263 = validateParameter(valid_774263, JString, required = false,
                                 default = nil)
  if valid_774263 != nil:
    section.add "X-Amz-SignedHeaders", valid_774263
  var valid_774264 = header.getOrDefault("X-Amz-Credential")
  valid_774264 = validateParameter(valid_774264, JString, required = false,
                                 default = nil)
  if valid_774264 != nil:
    section.add "X-Amz-Credential", valid_774264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774265: Call_GetDescribeEventSubscriptions_774250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774265.validator(path, query, header, formData, body)
  let scheme = call_774265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774265.url(scheme.get, call_774265.host, call_774265.base,
                         call_774265.route, valid.getOrDefault("path"))
  result = hook(call_774265, url, valid)

proc call*(call_774266: Call_GetDescribeEventSubscriptions_774250;
          MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
          Marker: string = ""; SubscriptionName: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_774267 = newJObject()
  add(query_774267, "MaxRecords", newJInt(MaxRecords))
  add(query_774267, "Action", newJString(Action))
  add(query_774267, "Marker", newJString(Marker))
  add(query_774267, "SubscriptionName", newJString(SubscriptionName))
  add(query_774267, "Version", newJString(Version))
  result = call_774266.call(nil, query_774267, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_774250(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_774251, base: "/",
    url: url_GetDescribeEventSubscriptions_774252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_774310 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEvents_774312(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_774311(path: JsonNode; query: JsonNode;
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
  var valid_774313 = query.getOrDefault("Action")
  valid_774313 = validateParameter(valid_774313, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_774313 != nil:
    section.add "Action", valid_774313
  var valid_774314 = query.getOrDefault("Version")
  valid_774314 = validateParameter(valid_774314, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774314 != nil:
    section.add "Version", valid_774314
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774315 = header.getOrDefault("X-Amz-Date")
  valid_774315 = validateParameter(valid_774315, JString, required = false,
                                 default = nil)
  if valid_774315 != nil:
    section.add "X-Amz-Date", valid_774315
  var valid_774316 = header.getOrDefault("X-Amz-Security-Token")
  valid_774316 = validateParameter(valid_774316, JString, required = false,
                                 default = nil)
  if valid_774316 != nil:
    section.add "X-Amz-Security-Token", valid_774316
  var valid_774317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774317 = validateParameter(valid_774317, JString, required = false,
                                 default = nil)
  if valid_774317 != nil:
    section.add "X-Amz-Content-Sha256", valid_774317
  var valid_774318 = header.getOrDefault("X-Amz-Algorithm")
  valid_774318 = validateParameter(valid_774318, JString, required = false,
                                 default = nil)
  if valid_774318 != nil:
    section.add "X-Amz-Algorithm", valid_774318
  var valid_774319 = header.getOrDefault("X-Amz-Signature")
  valid_774319 = validateParameter(valid_774319, JString, required = false,
                                 default = nil)
  if valid_774319 != nil:
    section.add "X-Amz-Signature", valid_774319
  var valid_774320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774320 = validateParameter(valid_774320, JString, required = false,
                                 default = nil)
  if valid_774320 != nil:
    section.add "X-Amz-SignedHeaders", valid_774320
  var valid_774321 = header.getOrDefault("X-Amz-Credential")
  valid_774321 = validateParameter(valid_774321, JString, required = false,
                                 default = nil)
  if valid_774321 != nil:
    section.add "X-Amz-Credential", valid_774321
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
  var valid_774322 = formData.getOrDefault("SourceIdentifier")
  valid_774322 = validateParameter(valid_774322, JString, required = false,
                                 default = nil)
  if valid_774322 != nil:
    section.add "SourceIdentifier", valid_774322
  var valid_774323 = formData.getOrDefault("EventCategories")
  valid_774323 = validateParameter(valid_774323, JArray, required = false,
                                 default = nil)
  if valid_774323 != nil:
    section.add "EventCategories", valid_774323
  var valid_774324 = formData.getOrDefault("Marker")
  valid_774324 = validateParameter(valid_774324, JString, required = false,
                                 default = nil)
  if valid_774324 != nil:
    section.add "Marker", valid_774324
  var valid_774325 = formData.getOrDefault("StartTime")
  valid_774325 = validateParameter(valid_774325, JString, required = false,
                                 default = nil)
  if valid_774325 != nil:
    section.add "StartTime", valid_774325
  var valid_774326 = formData.getOrDefault("Duration")
  valid_774326 = validateParameter(valid_774326, JInt, required = false, default = nil)
  if valid_774326 != nil:
    section.add "Duration", valid_774326
  var valid_774327 = formData.getOrDefault("EndTime")
  valid_774327 = validateParameter(valid_774327, JString, required = false,
                                 default = nil)
  if valid_774327 != nil:
    section.add "EndTime", valid_774327
  var valid_774328 = formData.getOrDefault("MaxRecords")
  valid_774328 = validateParameter(valid_774328, JInt, required = false, default = nil)
  if valid_774328 != nil:
    section.add "MaxRecords", valid_774328
  var valid_774329 = formData.getOrDefault("SourceType")
  valid_774329 = validateParameter(valid_774329, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_774329 != nil:
    section.add "SourceType", valid_774329
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774330: Call_PostDescribeEvents_774310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774330.validator(path, query, header, formData, body)
  let scheme = call_774330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774330.url(scheme.get, call_774330.host, call_774330.base,
                         call_774330.route, valid.getOrDefault("path"))
  result = hook(call_774330, url, valid)

proc call*(call_774331: Call_PostDescribeEvents_774310;
          SourceIdentifier: string = ""; EventCategories: JsonNode = nil;
          Marker: string = ""; StartTime: string = "";
          Action: string = "DescribeEvents"; Duration: int = 0; EndTime: string = "";
          MaxRecords: int = 0; Version: string = "2013-01-10";
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
  var query_774332 = newJObject()
  var formData_774333 = newJObject()
  add(formData_774333, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_774333.add "EventCategories", EventCategories
  add(formData_774333, "Marker", newJString(Marker))
  add(formData_774333, "StartTime", newJString(StartTime))
  add(query_774332, "Action", newJString(Action))
  add(formData_774333, "Duration", newJInt(Duration))
  add(formData_774333, "EndTime", newJString(EndTime))
  add(formData_774333, "MaxRecords", newJInt(MaxRecords))
  add(query_774332, "Version", newJString(Version))
  add(formData_774333, "SourceType", newJString(SourceType))
  result = call_774331.call(nil, query_774332, nil, formData_774333, nil)

var postDescribeEvents* = Call_PostDescribeEvents_774310(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_774311, base: "/",
    url: url_PostDescribeEvents_774312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_774287 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEvents_774289(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_774288(path: JsonNode; query: JsonNode;
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
  var valid_774290 = query.getOrDefault("SourceType")
  valid_774290 = validateParameter(valid_774290, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_774290 != nil:
    section.add "SourceType", valid_774290
  var valid_774291 = query.getOrDefault("MaxRecords")
  valid_774291 = validateParameter(valid_774291, JInt, required = false, default = nil)
  if valid_774291 != nil:
    section.add "MaxRecords", valid_774291
  var valid_774292 = query.getOrDefault("StartTime")
  valid_774292 = validateParameter(valid_774292, JString, required = false,
                                 default = nil)
  if valid_774292 != nil:
    section.add "StartTime", valid_774292
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774293 = query.getOrDefault("Action")
  valid_774293 = validateParameter(valid_774293, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_774293 != nil:
    section.add "Action", valid_774293
  var valid_774294 = query.getOrDefault("SourceIdentifier")
  valid_774294 = validateParameter(valid_774294, JString, required = false,
                                 default = nil)
  if valid_774294 != nil:
    section.add "SourceIdentifier", valid_774294
  var valid_774295 = query.getOrDefault("Marker")
  valid_774295 = validateParameter(valid_774295, JString, required = false,
                                 default = nil)
  if valid_774295 != nil:
    section.add "Marker", valid_774295
  var valid_774296 = query.getOrDefault("EventCategories")
  valid_774296 = validateParameter(valid_774296, JArray, required = false,
                                 default = nil)
  if valid_774296 != nil:
    section.add "EventCategories", valid_774296
  var valid_774297 = query.getOrDefault("Duration")
  valid_774297 = validateParameter(valid_774297, JInt, required = false, default = nil)
  if valid_774297 != nil:
    section.add "Duration", valid_774297
  var valid_774298 = query.getOrDefault("EndTime")
  valid_774298 = validateParameter(valid_774298, JString, required = false,
                                 default = nil)
  if valid_774298 != nil:
    section.add "EndTime", valid_774298
  var valid_774299 = query.getOrDefault("Version")
  valid_774299 = validateParameter(valid_774299, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774299 != nil:
    section.add "Version", valid_774299
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774300 = header.getOrDefault("X-Amz-Date")
  valid_774300 = validateParameter(valid_774300, JString, required = false,
                                 default = nil)
  if valid_774300 != nil:
    section.add "X-Amz-Date", valid_774300
  var valid_774301 = header.getOrDefault("X-Amz-Security-Token")
  valid_774301 = validateParameter(valid_774301, JString, required = false,
                                 default = nil)
  if valid_774301 != nil:
    section.add "X-Amz-Security-Token", valid_774301
  var valid_774302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774302 = validateParameter(valid_774302, JString, required = false,
                                 default = nil)
  if valid_774302 != nil:
    section.add "X-Amz-Content-Sha256", valid_774302
  var valid_774303 = header.getOrDefault("X-Amz-Algorithm")
  valid_774303 = validateParameter(valid_774303, JString, required = false,
                                 default = nil)
  if valid_774303 != nil:
    section.add "X-Amz-Algorithm", valid_774303
  var valid_774304 = header.getOrDefault("X-Amz-Signature")
  valid_774304 = validateParameter(valid_774304, JString, required = false,
                                 default = nil)
  if valid_774304 != nil:
    section.add "X-Amz-Signature", valid_774304
  var valid_774305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774305 = validateParameter(valid_774305, JString, required = false,
                                 default = nil)
  if valid_774305 != nil:
    section.add "X-Amz-SignedHeaders", valid_774305
  var valid_774306 = header.getOrDefault("X-Amz-Credential")
  valid_774306 = validateParameter(valid_774306, JString, required = false,
                                 default = nil)
  if valid_774306 != nil:
    section.add "X-Amz-Credential", valid_774306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774307: Call_GetDescribeEvents_774287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774307.validator(path, query, header, formData, body)
  let scheme = call_774307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774307.url(scheme.get, call_774307.host, call_774307.base,
                         call_774307.route, valid.getOrDefault("path"))
  result = hook(call_774307, url, valid)

proc call*(call_774308: Call_GetDescribeEvents_774287;
          SourceType: string = "db-instance"; MaxRecords: int = 0;
          StartTime: string = ""; Action: string = "DescribeEvents";
          SourceIdentifier: string = ""; Marker: string = "";
          EventCategories: JsonNode = nil; Duration: int = 0; EndTime: string = "";
          Version: string = "2013-01-10"): Recallable =
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
  var query_774309 = newJObject()
  add(query_774309, "SourceType", newJString(SourceType))
  add(query_774309, "MaxRecords", newJInt(MaxRecords))
  add(query_774309, "StartTime", newJString(StartTime))
  add(query_774309, "Action", newJString(Action))
  add(query_774309, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_774309, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_774309.add "EventCategories", EventCategories
  add(query_774309, "Duration", newJInt(Duration))
  add(query_774309, "EndTime", newJString(EndTime))
  add(query_774309, "Version", newJString(Version))
  result = call_774308.call(nil, query_774309, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_774287(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_774288,
    base: "/", url: url_GetDescribeEvents_774289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_774353 = ref object of OpenApiRestCall_772581
proc url_PostDescribeOptionGroupOptions_774355(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroupOptions_774354(path: JsonNode;
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
  var valid_774356 = query.getOrDefault("Action")
  valid_774356 = validateParameter(valid_774356, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_774356 != nil:
    section.add "Action", valid_774356
  var valid_774357 = query.getOrDefault("Version")
  valid_774357 = validateParameter(valid_774357, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774357 != nil:
    section.add "Version", valid_774357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774358 = header.getOrDefault("X-Amz-Date")
  valid_774358 = validateParameter(valid_774358, JString, required = false,
                                 default = nil)
  if valid_774358 != nil:
    section.add "X-Amz-Date", valid_774358
  var valid_774359 = header.getOrDefault("X-Amz-Security-Token")
  valid_774359 = validateParameter(valid_774359, JString, required = false,
                                 default = nil)
  if valid_774359 != nil:
    section.add "X-Amz-Security-Token", valid_774359
  var valid_774360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774360 = validateParameter(valid_774360, JString, required = false,
                                 default = nil)
  if valid_774360 != nil:
    section.add "X-Amz-Content-Sha256", valid_774360
  var valid_774361 = header.getOrDefault("X-Amz-Algorithm")
  valid_774361 = validateParameter(valid_774361, JString, required = false,
                                 default = nil)
  if valid_774361 != nil:
    section.add "X-Amz-Algorithm", valid_774361
  var valid_774362 = header.getOrDefault("X-Amz-Signature")
  valid_774362 = validateParameter(valid_774362, JString, required = false,
                                 default = nil)
  if valid_774362 != nil:
    section.add "X-Amz-Signature", valid_774362
  var valid_774363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774363 = validateParameter(valid_774363, JString, required = false,
                                 default = nil)
  if valid_774363 != nil:
    section.add "X-Amz-SignedHeaders", valid_774363
  var valid_774364 = header.getOrDefault("X-Amz-Credential")
  valid_774364 = validateParameter(valid_774364, JString, required = false,
                                 default = nil)
  if valid_774364 != nil:
    section.add "X-Amz-Credential", valid_774364
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774365 = formData.getOrDefault("MajorEngineVersion")
  valid_774365 = validateParameter(valid_774365, JString, required = false,
                                 default = nil)
  if valid_774365 != nil:
    section.add "MajorEngineVersion", valid_774365
  var valid_774366 = formData.getOrDefault("Marker")
  valid_774366 = validateParameter(valid_774366, JString, required = false,
                                 default = nil)
  if valid_774366 != nil:
    section.add "Marker", valid_774366
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_774367 = formData.getOrDefault("EngineName")
  valid_774367 = validateParameter(valid_774367, JString, required = true,
                                 default = nil)
  if valid_774367 != nil:
    section.add "EngineName", valid_774367
  var valid_774368 = formData.getOrDefault("MaxRecords")
  valid_774368 = validateParameter(valid_774368, JInt, required = false, default = nil)
  if valid_774368 != nil:
    section.add "MaxRecords", valid_774368
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774369: Call_PostDescribeOptionGroupOptions_774353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774369.validator(path, query, header, formData, body)
  let scheme = call_774369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774369.url(scheme.get, call_774369.host, call_774369.base,
                         call_774369.route, valid.getOrDefault("path"))
  result = hook(call_774369, url, valid)

proc call*(call_774370: Call_PostDescribeOptionGroupOptions_774353;
          EngineName: string; MajorEngineVersion: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MajorEngineVersion: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_774371 = newJObject()
  var formData_774372 = newJObject()
  add(formData_774372, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_774372, "Marker", newJString(Marker))
  add(query_774371, "Action", newJString(Action))
  add(formData_774372, "EngineName", newJString(EngineName))
  add(formData_774372, "MaxRecords", newJInt(MaxRecords))
  add(query_774371, "Version", newJString(Version))
  result = call_774370.call(nil, query_774371, nil, formData_774372, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_774353(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_774354, base: "/",
    url: url_PostDescribeOptionGroupOptions_774355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_774334 = ref object of OpenApiRestCall_772581
proc url_GetDescribeOptionGroupOptions_774336(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroupOptions_774335(path: JsonNode; query: JsonNode;
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
  var valid_774337 = query.getOrDefault("MaxRecords")
  valid_774337 = validateParameter(valid_774337, JInt, required = false, default = nil)
  if valid_774337 != nil:
    section.add "MaxRecords", valid_774337
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774338 = query.getOrDefault("Action")
  valid_774338 = validateParameter(valid_774338, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_774338 != nil:
    section.add "Action", valid_774338
  var valid_774339 = query.getOrDefault("Marker")
  valid_774339 = validateParameter(valid_774339, JString, required = false,
                                 default = nil)
  if valid_774339 != nil:
    section.add "Marker", valid_774339
  var valid_774340 = query.getOrDefault("Version")
  valid_774340 = validateParameter(valid_774340, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774340 != nil:
    section.add "Version", valid_774340
  var valid_774341 = query.getOrDefault("EngineName")
  valid_774341 = validateParameter(valid_774341, JString, required = true,
                                 default = nil)
  if valid_774341 != nil:
    section.add "EngineName", valid_774341
  var valid_774342 = query.getOrDefault("MajorEngineVersion")
  valid_774342 = validateParameter(valid_774342, JString, required = false,
                                 default = nil)
  if valid_774342 != nil:
    section.add "MajorEngineVersion", valid_774342
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774343 = header.getOrDefault("X-Amz-Date")
  valid_774343 = validateParameter(valid_774343, JString, required = false,
                                 default = nil)
  if valid_774343 != nil:
    section.add "X-Amz-Date", valid_774343
  var valid_774344 = header.getOrDefault("X-Amz-Security-Token")
  valid_774344 = validateParameter(valid_774344, JString, required = false,
                                 default = nil)
  if valid_774344 != nil:
    section.add "X-Amz-Security-Token", valid_774344
  var valid_774345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774345 = validateParameter(valid_774345, JString, required = false,
                                 default = nil)
  if valid_774345 != nil:
    section.add "X-Amz-Content-Sha256", valid_774345
  var valid_774346 = header.getOrDefault("X-Amz-Algorithm")
  valid_774346 = validateParameter(valid_774346, JString, required = false,
                                 default = nil)
  if valid_774346 != nil:
    section.add "X-Amz-Algorithm", valid_774346
  var valid_774347 = header.getOrDefault("X-Amz-Signature")
  valid_774347 = validateParameter(valid_774347, JString, required = false,
                                 default = nil)
  if valid_774347 != nil:
    section.add "X-Amz-Signature", valid_774347
  var valid_774348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774348 = validateParameter(valid_774348, JString, required = false,
                                 default = nil)
  if valid_774348 != nil:
    section.add "X-Amz-SignedHeaders", valid_774348
  var valid_774349 = header.getOrDefault("X-Amz-Credential")
  valid_774349 = validateParameter(valid_774349, JString, required = false,
                                 default = nil)
  if valid_774349 != nil:
    section.add "X-Amz-Credential", valid_774349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774350: Call_GetDescribeOptionGroupOptions_774334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774350.validator(path, query, header, formData, body)
  let scheme = call_774350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774350.url(scheme.get, call_774350.host, call_774350.base,
                         call_774350.route, valid.getOrDefault("path"))
  result = hook(call_774350, url, valid)

proc call*(call_774351: Call_GetDescribeOptionGroupOptions_774334;
          EngineName: string; MaxRecords: int = 0;
          Action: string = "DescribeOptionGroupOptions"; Marker: string = "";
          Version: string = "2013-01-10"; MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  var query_774352 = newJObject()
  add(query_774352, "MaxRecords", newJInt(MaxRecords))
  add(query_774352, "Action", newJString(Action))
  add(query_774352, "Marker", newJString(Marker))
  add(query_774352, "Version", newJString(Version))
  add(query_774352, "EngineName", newJString(EngineName))
  add(query_774352, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_774351.call(nil, query_774352, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_774334(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_774335, base: "/",
    url: url_GetDescribeOptionGroupOptions_774336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_774393 = ref object of OpenApiRestCall_772581
proc url_PostDescribeOptionGroups_774395(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroups_774394(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774396 = query.getOrDefault("Action")
  valid_774396 = validateParameter(valid_774396, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_774396 != nil:
    section.add "Action", valid_774396
  var valid_774397 = query.getOrDefault("Version")
  valid_774397 = validateParameter(valid_774397, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774397 != nil:
    section.add "Version", valid_774397
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774398 = header.getOrDefault("X-Amz-Date")
  valid_774398 = validateParameter(valid_774398, JString, required = false,
                                 default = nil)
  if valid_774398 != nil:
    section.add "X-Amz-Date", valid_774398
  var valid_774399 = header.getOrDefault("X-Amz-Security-Token")
  valid_774399 = validateParameter(valid_774399, JString, required = false,
                                 default = nil)
  if valid_774399 != nil:
    section.add "X-Amz-Security-Token", valid_774399
  var valid_774400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774400 = validateParameter(valid_774400, JString, required = false,
                                 default = nil)
  if valid_774400 != nil:
    section.add "X-Amz-Content-Sha256", valid_774400
  var valid_774401 = header.getOrDefault("X-Amz-Algorithm")
  valid_774401 = validateParameter(valid_774401, JString, required = false,
                                 default = nil)
  if valid_774401 != nil:
    section.add "X-Amz-Algorithm", valid_774401
  var valid_774402 = header.getOrDefault("X-Amz-Signature")
  valid_774402 = validateParameter(valid_774402, JString, required = false,
                                 default = nil)
  if valid_774402 != nil:
    section.add "X-Amz-Signature", valid_774402
  var valid_774403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774403 = validateParameter(valid_774403, JString, required = false,
                                 default = nil)
  if valid_774403 != nil:
    section.add "X-Amz-SignedHeaders", valid_774403
  var valid_774404 = header.getOrDefault("X-Amz-Credential")
  valid_774404 = validateParameter(valid_774404, JString, required = false,
                                 default = nil)
  if valid_774404 != nil:
    section.add "X-Amz-Credential", valid_774404
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774405 = formData.getOrDefault("MajorEngineVersion")
  valid_774405 = validateParameter(valid_774405, JString, required = false,
                                 default = nil)
  if valid_774405 != nil:
    section.add "MajorEngineVersion", valid_774405
  var valid_774406 = formData.getOrDefault("OptionGroupName")
  valid_774406 = validateParameter(valid_774406, JString, required = false,
                                 default = nil)
  if valid_774406 != nil:
    section.add "OptionGroupName", valid_774406
  var valid_774407 = formData.getOrDefault("Marker")
  valid_774407 = validateParameter(valid_774407, JString, required = false,
                                 default = nil)
  if valid_774407 != nil:
    section.add "Marker", valid_774407
  var valid_774408 = formData.getOrDefault("EngineName")
  valid_774408 = validateParameter(valid_774408, JString, required = false,
                                 default = nil)
  if valid_774408 != nil:
    section.add "EngineName", valid_774408
  var valid_774409 = formData.getOrDefault("MaxRecords")
  valid_774409 = validateParameter(valid_774409, JInt, required = false, default = nil)
  if valid_774409 != nil:
    section.add "MaxRecords", valid_774409
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774410: Call_PostDescribeOptionGroups_774393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774410.validator(path, query, header, formData, body)
  let scheme = call_774410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774410.url(scheme.get, call_774410.host, call_774410.base,
                         call_774410.route, valid.getOrDefault("path"))
  result = hook(call_774410, url, valid)

proc call*(call_774411: Call_PostDescribeOptionGroups_774393;
          MajorEngineVersion: string = ""; OptionGroupName: string = "";
          Marker: string = ""; Action: string = "DescribeOptionGroups";
          EngineName: string = ""; MaxRecords: int = 0; Version: string = "2013-01-10"): Recallable =
  ## postDescribeOptionGroups
  ##   MajorEngineVersion: string
  ##   OptionGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_774412 = newJObject()
  var formData_774413 = newJObject()
  add(formData_774413, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_774413, "OptionGroupName", newJString(OptionGroupName))
  add(formData_774413, "Marker", newJString(Marker))
  add(query_774412, "Action", newJString(Action))
  add(formData_774413, "EngineName", newJString(EngineName))
  add(formData_774413, "MaxRecords", newJInt(MaxRecords))
  add(query_774412, "Version", newJString(Version))
  result = call_774411.call(nil, query_774412, nil, formData_774413, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_774393(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_774394, base: "/",
    url: url_PostDescribeOptionGroups_774395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_774373 = ref object of OpenApiRestCall_772581
proc url_GetDescribeOptionGroups_774375(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroups_774374(path: JsonNode; query: JsonNode;
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
  var valid_774376 = query.getOrDefault("MaxRecords")
  valid_774376 = validateParameter(valid_774376, JInt, required = false, default = nil)
  if valid_774376 != nil:
    section.add "MaxRecords", valid_774376
  var valid_774377 = query.getOrDefault("OptionGroupName")
  valid_774377 = validateParameter(valid_774377, JString, required = false,
                                 default = nil)
  if valid_774377 != nil:
    section.add "OptionGroupName", valid_774377
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774378 = query.getOrDefault("Action")
  valid_774378 = validateParameter(valid_774378, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_774378 != nil:
    section.add "Action", valid_774378
  var valid_774379 = query.getOrDefault("Marker")
  valid_774379 = validateParameter(valid_774379, JString, required = false,
                                 default = nil)
  if valid_774379 != nil:
    section.add "Marker", valid_774379
  var valid_774380 = query.getOrDefault("Version")
  valid_774380 = validateParameter(valid_774380, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774380 != nil:
    section.add "Version", valid_774380
  var valid_774381 = query.getOrDefault("EngineName")
  valid_774381 = validateParameter(valid_774381, JString, required = false,
                                 default = nil)
  if valid_774381 != nil:
    section.add "EngineName", valid_774381
  var valid_774382 = query.getOrDefault("MajorEngineVersion")
  valid_774382 = validateParameter(valid_774382, JString, required = false,
                                 default = nil)
  if valid_774382 != nil:
    section.add "MajorEngineVersion", valid_774382
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774383 = header.getOrDefault("X-Amz-Date")
  valid_774383 = validateParameter(valid_774383, JString, required = false,
                                 default = nil)
  if valid_774383 != nil:
    section.add "X-Amz-Date", valid_774383
  var valid_774384 = header.getOrDefault("X-Amz-Security-Token")
  valid_774384 = validateParameter(valid_774384, JString, required = false,
                                 default = nil)
  if valid_774384 != nil:
    section.add "X-Amz-Security-Token", valid_774384
  var valid_774385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774385 = validateParameter(valid_774385, JString, required = false,
                                 default = nil)
  if valid_774385 != nil:
    section.add "X-Amz-Content-Sha256", valid_774385
  var valid_774386 = header.getOrDefault("X-Amz-Algorithm")
  valid_774386 = validateParameter(valid_774386, JString, required = false,
                                 default = nil)
  if valid_774386 != nil:
    section.add "X-Amz-Algorithm", valid_774386
  var valid_774387 = header.getOrDefault("X-Amz-Signature")
  valid_774387 = validateParameter(valid_774387, JString, required = false,
                                 default = nil)
  if valid_774387 != nil:
    section.add "X-Amz-Signature", valid_774387
  var valid_774388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774388 = validateParameter(valid_774388, JString, required = false,
                                 default = nil)
  if valid_774388 != nil:
    section.add "X-Amz-SignedHeaders", valid_774388
  var valid_774389 = header.getOrDefault("X-Amz-Credential")
  valid_774389 = validateParameter(valid_774389, JString, required = false,
                                 default = nil)
  if valid_774389 != nil:
    section.add "X-Amz-Credential", valid_774389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774390: Call_GetDescribeOptionGroups_774373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774390.validator(path, query, header, formData, body)
  let scheme = call_774390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774390.url(scheme.get, call_774390.host, call_774390.base,
                         call_774390.route, valid.getOrDefault("path"))
  result = hook(call_774390, url, valid)

proc call*(call_774391: Call_GetDescribeOptionGroups_774373; MaxRecords: int = 0;
          OptionGroupName: string = ""; Action: string = "DescribeOptionGroups";
          Marker: string = ""; Version: string = "2013-01-10"; EngineName: string = "";
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   MaxRecords: int
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string
  ##   MajorEngineVersion: string
  var query_774392 = newJObject()
  add(query_774392, "MaxRecords", newJInt(MaxRecords))
  add(query_774392, "OptionGroupName", newJString(OptionGroupName))
  add(query_774392, "Action", newJString(Action))
  add(query_774392, "Marker", newJString(Marker))
  add(query_774392, "Version", newJString(Version))
  add(query_774392, "EngineName", newJString(EngineName))
  add(query_774392, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_774391.call(nil, query_774392, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_774373(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_774374, base: "/",
    url: url_GetDescribeOptionGroups_774375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_774436 = ref object of OpenApiRestCall_772581
proc url_PostDescribeOrderableDBInstanceOptions_774438(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOrderableDBInstanceOptions_774437(path: JsonNode;
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
  var valid_774439 = query.getOrDefault("Action")
  valid_774439 = validateParameter(valid_774439, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_774439 != nil:
    section.add "Action", valid_774439
  var valid_774440 = query.getOrDefault("Version")
  valid_774440 = validateParameter(valid_774440, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774440 != nil:
    section.add "Version", valid_774440
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774441 = header.getOrDefault("X-Amz-Date")
  valid_774441 = validateParameter(valid_774441, JString, required = false,
                                 default = nil)
  if valid_774441 != nil:
    section.add "X-Amz-Date", valid_774441
  var valid_774442 = header.getOrDefault("X-Amz-Security-Token")
  valid_774442 = validateParameter(valid_774442, JString, required = false,
                                 default = nil)
  if valid_774442 != nil:
    section.add "X-Amz-Security-Token", valid_774442
  var valid_774443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774443 = validateParameter(valid_774443, JString, required = false,
                                 default = nil)
  if valid_774443 != nil:
    section.add "X-Amz-Content-Sha256", valid_774443
  var valid_774444 = header.getOrDefault("X-Amz-Algorithm")
  valid_774444 = validateParameter(valid_774444, JString, required = false,
                                 default = nil)
  if valid_774444 != nil:
    section.add "X-Amz-Algorithm", valid_774444
  var valid_774445 = header.getOrDefault("X-Amz-Signature")
  valid_774445 = validateParameter(valid_774445, JString, required = false,
                                 default = nil)
  if valid_774445 != nil:
    section.add "X-Amz-Signature", valid_774445
  var valid_774446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774446 = validateParameter(valid_774446, JString, required = false,
                                 default = nil)
  if valid_774446 != nil:
    section.add "X-Amz-SignedHeaders", valid_774446
  var valid_774447 = header.getOrDefault("X-Amz-Credential")
  valid_774447 = validateParameter(valid_774447, JString, required = false,
                                 default = nil)
  if valid_774447 != nil:
    section.add "X-Amz-Credential", valid_774447
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
  var valid_774448 = formData.getOrDefault("Engine")
  valid_774448 = validateParameter(valid_774448, JString, required = true,
                                 default = nil)
  if valid_774448 != nil:
    section.add "Engine", valid_774448
  var valid_774449 = formData.getOrDefault("Marker")
  valid_774449 = validateParameter(valid_774449, JString, required = false,
                                 default = nil)
  if valid_774449 != nil:
    section.add "Marker", valid_774449
  var valid_774450 = formData.getOrDefault("Vpc")
  valid_774450 = validateParameter(valid_774450, JBool, required = false, default = nil)
  if valid_774450 != nil:
    section.add "Vpc", valid_774450
  var valid_774451 = formData.getOrDefault("DBInstanceClass")
  valid_774451 = validateParameter(valid_774451, JString, required = false,
                                 default = nil)
  if valid_774451 != nil:
    section.add "DBInstanceClass", valid_774451
  var valid_774452 = formData.getOrDefault("LicenseModel")
  valid_774452 = validateParameter(valid_774452, JString, required = false,
                                 default = nil)
  if valid_774452 != nil:
    section.add "LicenseModel", valid_774452
  var valid_774453 = formData.getOrDefault("MaxRecords")
  valid_774453 = validateParameter(valid_774453, JInt, required = false, default = nil)
  if valid_774453 != nil:
    section.add "MaxRecords", valid_774453
  var valid_774454 = formData.getOrDefault("EngineVersion")
  valid_774454 = validateParameter(valid_774454, JString, required = false,
                                 default = nil)
  if valid_774454 != nil:
    section.add "EngineVersion", valid_774454
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774455: Call_PostDescribeOrderableDBInstanceOptions_774436;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774455.validator(path, query, header, formData, body)
  let scheme = call_774455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774455.url(scheme.get, call_774455.host, call_774455.base,
                         call_774455.route, valid.getOrDefault("path"))
  result = hook(call_774455, url, valid)

proc call*(call_774456: Call_PostDescribeOrderableDBInstanceOptions_774436;
          Engine: string; Marker: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions"; Vpc: bool = false;
          DBInstanceClass: string = ""; LicenseModel: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Version: string = "2013-01-10"): Recallable =
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
  var query_774457 = newJObject()
  var formData_774458 = newJObject()
  add(formData_774458, "Engine", newJString(Engine))
  add(formData_774458, "Marker", newJString(Marker))
  add(query_774457, "Action", newJString(Action))
  add(formData_774458, "Vpc", newJBool(Vpc))
  add(formData_774458, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_774458, "LicenseModel", newJString(LicenseModel))
  add(formData_774458, "MaxRecords", newJInt(MaxRecords))
  add(formData_774458, "EngineVersion", newJString(EngineVersion))
  add(query_774457, "Version", newJString(Version))
  result = call_774456.call(nil, query_774457, nil, formData_774458, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_774436(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_774437, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_774438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_774414 = ref object of OpenApiRestCall_772581
proc url_GetDescribeOrderableDBInstanceOptions_774416(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOrderableDBInstanceOptions_774415(path: JsonNode;
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
  var valid_774417 = query.getOrDefault("Engine")
  valid_774417 = validateParameter(valid_774417, JString, required = true,
                                 default = nil)
  if valid_774417 != nil:
    section.add "Engine", valid_774417
  var valid_774418 = query.getOrDefault("MaxRecords")
  valid_774418 = validateParameter(valid_774418, JInt, required = false, default = nil)
  if valid_774418 != nil:
    section.add "MaxRecords", valid_774418
  var valid_774419 = query.getOrDefault("LicenseModel")
  valid_774419 = validateParameter(valid_774419, JString, required = false,
                                 default = nil)
  if valid_774419 != nil:
    section.add "LicenseModel", valid_774419
  var valid_774420 = query.getOrDefault("Vpc")
  valid_774420 = validateParameter(valid_774420, JBool, required = false, default = nil)
  if valid_774420 != nil:
    section.add "Vpc", valid_774420
  var valid_774421 = query.getOrDefault("DBInstanceClass")
  valid_774421 = validateParameter(valid_774421, JString, required = false,
                                 default = nil)
  if valid_774421 != nil:
    section.add "DBInstanceClass", valid_774421
  var valid_774422 = query.getOrDefault("Action")
  valid_774422 = validateParameter(valid_774422, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_774422 != nil:
    section.add "Action", valid_774422
  var valid_774423 = query.getOrDefault("Marker")
  valid_774423 = validateParameter(valid_774423, JString, required = false,
                                 default = nil)
  if valid_774423 != nil:
    section.add "Marker", valid_774423
  var valid_774424 = query.getOrDefault("EngineVersion")
  valid_774424 = validateParameter(valid_774424, JString, required = false,
                                 default = nil)
  if valid_774424 != nil:
    section.add "EngineVersion", valid_774424
  var valid_774425 = query.getOrDefault("Version")
  valid_774425 = validateParameter(valid_774425, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774425 != nil:
    section.add "Version", valid_774425
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774426 = header.getOrDefault("X-Amz-Date")
  valid_774426 = validateParameter(valid_774426, JString, required = false,
                                 default = nil)
  if valid_774426 != nil:
    section.add "X-Amz-Date", valid_774426
  var valid_774427 = header.getOrDefault("X-Amz-Security-Token")
  valid_774427 = validateParameter(valid_774427, JString, required = false,
                                 default = nil)
  if valid_774427 != nil:
    section.add "X-Amz-Security-Token", valid_774427
  var valid_774428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774428 = validateParameter(valid_774428, JString, required = false,
                                 default = nil)
  if valid_774428 != nil:
    section.add "X-Amz-Content-Sha256", valid_774428
  var valid_774429 = header.getOrDefault("X-Amz-Algorithm")
  valid_774429 = validateParameter(valid_774429, JString, required = false,
                                 default = nil)
  if valid_774429 != nil:
    section.add "X-Amz-Algorithm", valid_774429
  var valid_774430 = header.getOrDefault("X-Amz-Signature")
  valid_774430 = validateParameter(valid_774430, JString, required = false,
                                 default = nil)
  if valid_774430 != nil:
    section.add "X-Amz-Signature", valid_774430
  var valid_774431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774431 = validateParameter(valid_774431, JString, required = false,
                                 default = nil)
  if valid_774431 != nil:
    section.add "X-Amz-SignedHeaders", valid_774431
  var valid_774432 = header.getOrDefault("X-Amz-Credential")
  valid_774432 = validateParameter(valid_774432, JString, required = false,
                                 default = nil)
  if valid_774432 != nil:
    section.add "X-Amz-Credential", valid_774432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774433: Call_GetDescribeOrderableDBInstanceOptions_774414;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774433.validator(path, query, header, formData, body)
  let scheme = call_774433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774433.url(scheme.get, call_774433.host, call_774433.base,
                         call_774433.route, valid.getOrDefault("path"))
  result = hook(call_774433, url, valid)

proc call*(call_774434: Call_GetDescribeOrderableDBInstanceOptions_774414;
          Engine: string; MaxRecords: int = 0; LicenseModel: string = "";
          Vpc: bool = false; DBInstanceClass: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Marker: string = ""; EngineVersion: string = "";
          Version: string = "2013-01-10"): Recallable =
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
  var query_774435 = newJObject()
  add(query_774435, "Engine", newJString(Engine))
  add(query_774435, "MaxRecords", newJInt(MaxRecords))
  add(query_774435, "LicenseModel", newJString(LicenseModel))
  add(query_774435, "Vpc", newJBool(Vpc))
  add(query_774435, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774435, "Action", newJString(Action))
  add(query_774435, "Marker", newJString(Marker))
  add(query_774435, "EngineVersion", newJString(EngineVersion))
  add(query_774435, "Version", newJString(Version))
  result = call_774434.call(nil, query_774435, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_774414(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_774415, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_774416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_774483 = ref object of OpenApiRestCall_772581
proc url_PostDescribeReservedDBInstances_774485(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstances_774484(path: JsonNode;
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
  var valid_774486 = query.getOrDefault("Action")
  valid_774486 = validateParameter(valid_774486, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_774486 != nil:
    section.add "Action", valid_774486
  var valid_774487 = query.getOrDefault("Version")
  valid_774487 = validateParameter(valid_774487, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774487 != nil:
    section.add "Version", valid_774487
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774488 = header.getOrDefault("X-Amz-Date")
  valid_774488 = validateParameter(valid_774488, JString, required = false,
                                 default = nil)
  if valid_774488 != nil:
    section.add "X-Amz-Date", valid_774488
  var valid_774489 = header.getOrDefault("X-Amz-Security-Token")
  valid_774489 = validateParameter(valid_774489, JString, required = false,
                                 default = nil)
  if valid_774489 != nil:
    section.add "X-Amz-Security-Token", valid_774489
  var valid_774490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774490 = validateParameter(valid_774490, JString, required = false,
                                 default = nil)
  if valid_774490 != nil:
    section.add "X-Amz-Content-Sha256", valid_774490
  var valid_774491 = header.getOrDefault("X-Amz-Algorithm")
  valid_774491 = validateParameter(valid_774491, JString, required = false,
                                 default = nil)
  if valid_774491 != nil:
    section.add "X-Amz-Algorithm", valid_774491
  var valid_774492 = header.getOrDefault("X-Amz-Signature")
  valid_774492 = validateParameter(valid_774492, JString, required = false,
                                 default = nil)
  if valid_774492 != nil:
    section.add "X-Amz-Signature", valid_774492
  var valid_774493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774493 = validateParameter(valid_774493, JString, required = false,
                                 default = nil)
  if valid_774493 != nil:
    section.add "X-Amz-SignedHeaders", valid_774493
  var valid_774494 = header.getOrDefault("X-Amz-Credential")
  valid_774494 = validateParameter(valid_774494, JString, required = false,
                                 default = nil)
  if valid_774494 != nil:
    section.add "X-Amz-Credential", valid_774494
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
  var valid_774495 = formData.getOrDefault("OfferingType")
  valid_774495 = validateParameter(valid_774495, JString, required = false,
                                 default = nil)
  if valid_774495 != nil:
    section.add "OfferingType", valid_774495
  var valid_774496 = formData.getOrDefault("ReservedDBInstanceId")
  valid_774496 = validateParameter(valid_774496, JString, required = false,
                                 default = nil)
  if valid_774496 != nil:
    section.add "ReservedDBInstanceId", valid_774496
  var valid_774497 = formData.getOrDefault("Marker")
  valid_774497 = validateParameter(valid_774497, JString, required = false,
                                 default = nil)
  if valid_774497 != nil:
    section.add "Marker", valid_774497
  var valid_774498 = formData.getOrDefault("MultiAZ")
  valid_774498 = validateParameter(valid_774498, JBool, required = false, default = nil)
  if valid_774498 != nil:
    section.add "MultiAZ", valid_774498
  var valid_774499 = formData.getOrDefault("Duration")
  valid_774499 = validateParameter(valid_774499, JString, required = false,
                                 default = nil)
  if valid_774499 != nil:
    section.add "Duration", valid_774499
  var valid_774500 = formData.getOrDefault("DBInstanceClass")
  valid_774500 = validateParameter(valid_774500, JString, required = false,
                                 default = nil)
  if valid_774500 != nil:
    section.add "DBInstanceClass", valid_774500
  var valid_774501 = formData.getOrDefault("ProductDescription")
  valid_774501 = validateParameter(valid_774501, JString, required = false,
                                 default = nil)
  if valid_774501 != nil:
    section.add "ProductDescription", valid_774501
  var valid_774502 = formData.getOrDefault("MaxRecords")
  valid_774502 = validateParameter(valid_774502, JInt, required = false, default = nil)
  if valid_774502 != nil:
    section.add "MaxRecords", valid_774502
  var valid_774503 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774503 = validateParameter(valid_774503, JString, required = false,
                                 default = nil)
  if valid_774503 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774503
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774504: Call_PostDescribeReservedDBInstances_774483;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774504.validator(path, query, header, formData, body)
  let scheme = call_774504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774504.url(scheme.get, call_774504.host, call_774504.base,
                         call_774504.route, valid.getOrDefault("path"))
  result = hook(call_774504, url, valid)

proc call*(call_774505: Call_PostDescribeReservedDBInstances_774483;
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstances"; Duration: string = "";
          DBInstanceClass: string = ""; ProductDescription: string = "";
          MaxRecords: int = 0; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-01-10"): Recallable =
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
  var query_774506 = newJObject()
  var formData_774507 = newJObject()
  add(formData_774507, "OfferingType", newJString(OfferingType))
  add(formData_774507, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_774507, "Marker", newJString(Marker))
  add(formData_774507, "MultiAZ", newJBool(MultiAZ))
  add(query_774506, "Action", newJString(Action))
  add(formData_774507, "Duration", newJString(Duration))
  add(formData_774507, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_774507, "ProductDescription", newJString(ProductDescription))
  add(formData_774507, "MaxRecords", newJInt(MaxRecords))
  add(formData_774507, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774506, "Version", newJString(Version))
  result = call_774505.call(nil, query_774506, nil, formData_774507, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_774483(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_774484, base: "/",
    url: url_PostDescribeReservedDBInstances_774485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_774459 = ref object of OpenApiRestCall_772581
proc url_GetDescribeReservedDBInstances_774461(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstances_774460(path: JsonNode;
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
  var valid_774462 = query.getOrDefault("ProductDescription")
  valid_774462 = validateParameter(valid_774462, JString, required = false,
                                 default = nil)
  if valid_774462 != nil:
    section.add "ProductDescription", valid_774462
  var valid_774463 = query.getOrDefault("MaxRecords")
  valid_774463 = validateParameter(valid_774463, JInt, required = false, default = nil)
  if valid_774463 != nil:
    section.add "MaxRecords", valid_774463
  var valid_774464 = query.getOrDefault("OfferingType")
  valid_774464 = validateParameter(valid_774464, JString, required = false,
                                 default = nil)
  if valid_774464 != nil:
    section.add "OfferingType", valid_774464
  var valid_774465 = query.getOrDefault("MultiAZ")
  valid_774465 = validateParameter(valid_774465, JBool, required = false, default = nil)
  if valid_774465 != nil:
    section.add "MultiAZ", valid_774465
  var valid_774466 = query.getOrDefault("ReservedDBInstanceId")
  valid_774466 = validateParameter(valid_774466, JString, required = false,
                                 default = nil)
  if valid_774466 != nil:
    section.add "ReservedDBInstanceId", valid_774466
  var valid_774467 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774467 = validateParameter(valid_774467, JString, required = false,
                                 default = nil)
  if valid_774467 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774467
  var valid_774468 = query.getOrDefault("DBInstanceClass")
  valid_774468 = validateParameter(valid_774468, JString, required = false,
                                 default = nil)
  if valid_774468 != nil:
    section.add "DBInstanceClass", valid_774468
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774469 = query.getOrDefault("Action")
  valid_774469 = validateParameter(valid_774469, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_774469 != nil:
    section.add "Action", valid_774469
  var valid_774470 = query.getOrDefault("Marker")
  valid_774470 = validateParameter(valid_774470, JString, required = false,
                                 default = nil)
  if valid_774470 != nil:
    section.add "Marker", valid_774470
  var valid_774471 = query.getOrDefault("Duration")
  valid_774471 = validateParameter(valid_774471, JString, required = false,
                                 default = nil)
  if valid_774471 != nil:
    section.add "Duration", valid_774471
  var valid_774472 = query.getOrDefault("Version")
  valid_774472 = validateParameter(valid_774472, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774472 != nil:
    section.add "Version", valid_774472
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774473 = header.getOrDefault("X-Amz-Date")
  valid_774473 = validateParameter(valid_774473, JString, required = false,
                                 default = nil)
  if valid_774473 != nil:
    section.add "X-Amz-Date", valid_774473
  var valid_774474 = header.getOrDefault("X-Amz-Security-Token")
  valid_774474 = validateParameter(valid_774474, JString, required = false,
                                 default = nil)
  if valid_774474 != nil:
    section.add "X-Amz-Security-Token", valid_774474
  var valid_774475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774475 = validateParameter(valid_774475, JString, required = false,
                                 default = nil)
  if valid_774475 != nil:
    section.add "X-Amz-Content-Sha256", valid_774475
  var valid_774476 = header.getOrDefault("X-Amz-Algorithm")
  valid_774476 = validateParameter(valid_774476, JString, required = false,
                                 default = nil)
  if valid_774476 != nil:
    section.add "X-Amz-Algorithm", valid_774476
  var valid_774477 = header.getOrDefault("X-Amz-Signature")
  valid_774477 = validateParameter(valid_774477, JString, required = false,
                                 default = nil)
  if valid_774477 != nil:
    section.add "X-Amz-Signature", valid_774477
  var valid_774478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774478 = validateParameter(valid_774478, JString, required = false,
                                 default = nil)
  if valid_774478 != nil:
    section.add "X-Amz-SignedHeaders", valid_774478
  var valid_774479 = header.getOrDefault("X-Amz-Credential")
  valid_774479 = validateParameter(valid_774479, JString, required = false,
                                 default = nil)
  if valid_774479 != nil:
    section.add "X-Amz-Credential", valid_774479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774480: Call_GetDescribeReservedDBInstances_774459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774480.validator(path, query, header, formData, body)
  let scheme = call_774480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774480.url(scheme.get, call_774480.host, call_774480.base,
                         call_774480.route, valid.getOrDefault("path"))
  result = hook(call_774480, url, valid)

proc call*(call_774481: Call_GetDescribeReservedDBInstances_774459;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; MultiAZ: bool = false;
          ReservedDBInstanceId: string = "";
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstances"; Marker: string = "";
          Duration: string = ""; Version: string = "2013-01-10"): Recallable =
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
  var query_774482 = newJObject()
  add(query_774482, "ProductDescription", newJString(ProductDescription))
  add(query_774482, "MaxRecords", newJInt(MaxRecords))
  add(query_774482, "OfferingType", newJString(OfferingType))
  add(query_774482, "MultiAZ", newJBool(MultiAZ))
  add(query_774482, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_774482, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774482, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774482, "Action", newJString(Action))
  add(query_774482, "Marker", newJString(Marker))
  add(query_774482, "Duration", newJString(Duration))
  add(query_774482, "Version", newJString(Version))
  result = call_774481.call(nil, query_774482, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_774459(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_774460, base: "/",
    url: url_GetDescribeReservedDBInstances_774461,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_774531 = ref object of OpenApiRestCall_772581
proc url_PostDescribeReservedDBInstancesOfferings_774533(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstancesOfferings_774532(path: JsonNode;
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
  var valid_774534 = query.getOrDefault("Action")
  valid_774534 = validateParameter(valid_774534, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_774534 != nil:
    section.add "Action", valid_774534
  var valid_774535 = query.getOrDefault("Version")
  valid_774535 = validateParameter(valid_774535, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774535 != nil:
    section.add "Version", valid_774535
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774536 = header.getOrDefault("X-Amz-Date")
  valid_774536 = validateParameter(valid_774536, JString, required = false,
                                 default = nil)
  if valid_774536 != nil:
    section.add "X-Amz-Date", valid_774536
  var valid_774537 = header.getOrDefault("X-Amz-Security-Token")
  valid_774537 = validateParameter(valid_774537, JString, required = false,
                                 default = nil)
  if valid_774537 != nil:
    section.add "X-Amz-Security-Token", valid_774537
  var valid_774538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774538 = validateParameter(valid_774538, JString, required = false,
                                 default = nil)
  if valid_774538 != nil:
    section.add "X-Amz-Content-Sha256", valid_774538
  var valid_774539 = header.getOrDefault("X-Amz-Algorithm")
  valid_774539 = validateParameter(valid_774539, JString, required = false,
                                 default = nil)
  if valid_774539 != nil:
    section.add "X-Amz-Algorithm", valid_774539
  var valid_774540 = header.getOrDefault("X-Amz-Signature")
  valid_774540 = validateParameter(valid_774540, JString, required = false,
                                 default = nil)
  if valid_774540 != nil:
    section.add "X-Amz-Signature", valid_774540
  var valid_774541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774541 = validateParameter(valid_774541, JString, required = false,
                                 default = nil)
  if valid_774541 != nil:
    section.add "X-Amz-SignedHeaders", valid_774541
  var valid_774542 = header.getOrDefault("X-Amz-Credential")
  valid_774542 = validateParameter(valid_774542, JString, required = false,
                                 default = nil)
  if valid_774542 != nil:
    section.add "X-Amz-Credential", valid_774542
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
  var valid_774543 = formData.getOrDefault("OfferingType")
  valid_774543 = validateParameter(valid_774543, JString, required = false,
                                 default = nil)
  if valid_774543 != nil:
    section.add "OfferingType", valid_774543
  var valid_774544 = formData.getOrDefault("Marker")
  valid_774544 = validateParameter(valid_774544, JString, required = false,
                                 default = nil)
  if valid_774544 != nil:
    section.add "Marker", valid_774544
  var valid_774545 = formData.getOrDefault("MultiAZ")
  valid_774545 = validateParameter(valid_774545, JBool, required = false, default = nil)
  if valid_774545 != nil:
    section.add "MultiAZ", valid_774545
  var valid_774546 = formData.getOrDefault("Duration")
  valid_774546 = validateParameter(valid_774546, JString, required = false,
                                 default = nil)
  if valid_774546 != nil:
    section.add "Duration", valid_774546
  var valid_774547 = formData.getOrDefault("DBInstanceClass")
  valid_774547 = validateParameter(valid_774547, JString, required = false,
                                 default = nil)
  if valid_774547 != nil:
    section.add "DBInstanceClass", valid_774547
  var valid_774548 = formData.getOrDefault("ProductDescription")
  valid_774548 = validateParameter(valid_774548, JString, required = false,
                                 default = nil)
  if valid_774548 != nil:
    section.add "ProductDescription", valid_774548
  var valid_774549 = formData.getOrDefault("MaxRecords")
  valid_774549 = validateParameter(valid_774549, JInt, required = false, default = nil)
  if valid_774549 != nil:
    section.add "MaxRecords", valid_774549
  var valid_774550 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774550 = validateParameter(valid_774550, JString, required = false,
                                 default = nil)
  if valid_774550 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774550
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774551: Call_PostDescribeReservedDBInstancesOfferings_774531;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774551.validator(path, query, header, formData, body)
  let scheme = call_774551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774551.url(scheme.get, call_774551.host, call_774551.base,
                         call_774551.route, valid.getOrDefault("path"))
  result = hook(call_774551, url, valid)

proc call*(call_774552: Call_PostDescribeReservedDBInstancesOfferings_774531;
          OfferingType: string = ""; Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstancesOfferings";
          Duration: string = ""; DBInstanceClass: string = "";
          ProductDescription: string = ""; MaxRecords: int = 0;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-01-10"): Recallable =
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
  var query_774553 = newJObject()
  var formData_774554 = newJObject()
  add(formData_774554, "OfferingType", newJString(OfferingType))
  add(formData_774554, "Marker", newJString(Marker))
  add(formData_774554, "MultiAZ", newJBool(MultiAZ))
  add(query_774553, "Action", newJString(Action))
  add(formData_774554, "Duration", newJString(Duration))
  add(formData_774554, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_774554, "ProductDescription", newJString(ProductDescription))
  add(formData_774554, "MaxRecords", newJInt(MaxRecords))
  add(formData_774554, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774553, "Version", newJString(Version))
  result = call_774552.call(nil, query_774553, nil, formData_774554, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_774531(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_774532,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_774533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_774508 = ref object of OpenApiRestCall_772581
proc url_GetDescribeReservedDBInstancesOfferings_774510(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstancesOfferings_774509(path: JsonNode;
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
  var valid_774511 = query.getOrDefault("ProductDescription")
  valid_774511 = validateParameter(valid_774511, JString, required = false,
                                 default = nil)
  if valid_774511 != nil:
    section.add "ProductDescription", valid_774511
  var valid_774512 = query.getOrDefault("MaxRecords")
  valid_774512 = validateParameter(valid_774512, JInt, required = false, default = nil)
  if valid_774512 != nil:
    section.add "MaxRecords", valid_774512
  var valid_774513 = query.getOrDefault("OfferingType")
  valid_774513 = validateParameter(valid_774513, JString, required = false,
                                 default = nil)
  if valid_774513 != nil:
    section.add "OfferingType", valid_774513
  var valid_774514 = query.getOrDefault("MultiAZ")
  valid_774514 = validateParameter(valid_774514, JBool, required = false, default = nil)
  if valid_774514 != nil:
    section.add "MultiAZ", valid_774514
  var valid_774515 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774515 = validateParameter(valid_774515, JString, required = false,
                                 default = nil)
  if valid_774515 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774515
  var valid_774516 = query.getOrDefault("DBInstanceClass")
  valid_774516 = validateParameter(valid_774516, JString, required = false,
                                 default = nil)
  if valid_774516 != nil:
    section.add "DBInstanceClass", valid_774516
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774517 = query.getOrDefault("Action")
  valid_774517 = validateParameter(valid_774517, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_774517 != nil:
    section.add "Action", valid_774517
  var valid_774518 = query.getOrDefault("Marker")
  valid_774518 = validateParameter(valid_774518, JString, required = false,
                                 default = nil)
  if valid_774518 != nil:
    section.add "Marker", valid_774518
  var valid_774519 = query.getOrDefault("Duration")
  valid_774519 = validateParameter(valid_774519, JString, required = false,
                                 default = nil)
  if valid_774519 != nil:
    section.add "Duration", valid_774519
  var valid_774520 = query.getOrDefault("Version")
  valid_774520 = validateParameter(valid_774520, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774520 != nil:
    section.add "Version", valid_774520
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774521 = header.getOrDefault("X-Amz-Date")
  valid_774521 = validateParameter(valid_774521, JString, required = false,
                                 default = nil)
  if valid_774521 != nil:
    section.add "X-Amz-Date", valid_774521
  var valid_774522 = header.getOrDefault("X-Amz-Security-Token")
  valid_774522 = validateParameter(valid_774522, JString, required = false,
                                 default = nil)
  if valid_774522 != nil:
    section.add "X-Amz-Security-Token", valid_774522
  var valid_774523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774523 = validateParameter(valid_774523, JString, required = false,
                                 default = nil)
  if valid_774523 != nil:
    section.add "X-Amz-Content-Sha256", valid_774523
  var valid_774524 = header.getOrDefault("X-Amz-Algorithm")
  valid_774524 = validateParameter(valid_774524, JString, required = false,
                                 default = nil)
  if valid_774524 != nil:
    section.add "X-Amz-Algorithm", valid_774524
  var valid_774525 = header.getOrDefault("X-Amz-Signature")
  valid_774525 = validateParameter(valid_774525, JString, required = false,
                                 default = nil)
  if valid_774525 != nil:
    section.add "X-Amz-Signature", valid_774525
  var valid_774526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774526 = validateParameter(valid_774526, JString, required = false,
                                 default = nil)
  if valid_774526 != nil:
    section.add "X-Amz-SignedHeaders", valid_774526
  var valid_774527 = header.getOrDefault("X-Amz-Credential")
  valid_774527 = validateParameter(valid_774527, JString, required = false,
                                 default = nil)
  if valid_774527 != nil:
    section.add "X-Amz-Credential", valid_774527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774528: Call_GetDescribeReservedDBInstancesOfferings_774508;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774528.validator(path, query, header, formData, body)
  let scheme = call_774528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774528.url(scheme.get, call_774528.host, call_774528.base,
                         call_774528.route, valid.getOrDefault("path"))
  result = hook(call_774528, url, valid)

proc call*(call_774529: Call_GetDescribeReservedDBInstancesOfferings_774508;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; MultiAZ: bool = false;
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          Marker: string = ""; Duration: string = ""; Version: string = "2013-01-10"): Recallable =
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
  var query_774530 = newJObject()
  add(query_774530, "ProductDescription", newJString(ProductDescription))
  add(query_774530, "MaxRecords", newJInt(MaxRecords))
  add(query_774530, "OfferingType", newJString(OfferingType))
  add(query_774530, "MultiAZ", newJBool(MultiAZ))
  add(query_774530, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774530, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774530, "Action", newJString(Action))
  add(query_774530, "Marker", newJString(Marker))
  add(query_774530, "Duration", newJString(Duration))
  add(query_774530, "Version", newJString(Version))
  result = call_774529.call(nil, query_774530, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_774508(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_774509, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_774510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_774571 = ref object of OpenApiRestCall_772581
proc url_PostListTagsForResource_774573(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_774572(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774574 = query.getOrDefault("Action")
  valid_774574 = validateParameter(valid_774574, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_774574 != nil:
    section.add "Action", valid_774574
  var valid_774575 = query.getOrDefault("Version")
  valid_774575 = validateParameter(valid_774575, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774575 != nil:
    section.add "Version", valid_774575
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774576 = header.getOrDefault("X-Amz-Date")
  valid_774576 = validateParameter(valid_774576, JString, required = false,
                                 default = nil)
  if valid_774576 != nil:
    section.add "X-Amz-Date", valid_774576
  var valid_774577 = header.getOrDefault("X-Amz-Security-Token")
  valid_774577 = validateParameter(valid_774577, JString, required = false,
                                 default = nil)
  if valid_774577 != nil:
    section.add "X-Amz-Security-Token", valid_774577
  var valid_774578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774578 = validateParameter(valid_774578, JString, required = false,
                                 default = nil)
  if valid_774578 != nil:
    section.add "X-Amz-Content-Sha256", valid_774578
  var valid_774579 = header.getOrDefault("X-Amz-Algorithm")
  valid_774579 = validateParameter(valid_774579, JString, required = false,
                                 default = nil)
  if valid_774579 != nil:
    section.add "X-Amz-Algorithm", valid_774579
  var valid_774580 = header.getOrDefault("X-Amz-Signature")
  valid_774580 = validateParameter(valid_774580, JString, required = false,
                                 default = nil)
  if valid_774580 != nil:
    section.add "X-Amz-Signature", valid_774580
  var valid_774581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774581 = validateParameter(valid_774581, JString, required = false,
                                 default = nil)
  if valid_774581 != nil:
    section.add "X-Amz-SignedHeaders", valid_774581
  var valid_774582 = header.getOrDefault("X-Amz-Credential")
  valid_774582 = validateParameter(valid_774582, JString, required = false,
                                 default = nil)
  if valid_774582 != nil:
    section.add "X-Amz-Credential", valid_774582
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_774583 = formData.getOrDefault("ResourceName")
  valid_774583 = validateParameter(valid_774583, JString, required = true,
                                 default = nil)
  if valid_774583 != nil:
    section.add "ResourceName", valid_774583
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774584: Call_PostListTagsForResource_774571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774584.validator(path, query, header, formData, body)
  let scheme = call_774584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774584.url(scheme.get, call_774584.host, call_774584.base,
                         call_774584.route, valid.getOrDefault("path"))
  result = hook(call_774584, url, valid)

proc call*(call_774585: Call_PostListTagsForResource_774571; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_774586 = newJObject()
  var formData_774587 = newJObject()
  add(query_774586, "Action", newJString(Action))
  add(formData_774587, "ResourceName", newJString(ResourceName))
  add(query_774586, "Version", newJString(Version))
  result = call_774585.call(nil, query_774586, nil, formData_774587, nil)

var postListTagsForResource* = Call_PostListTagsForResource_774571(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_774572, base: "/",
    url: url_PostListTagsForResource_774573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_774555 = ref object of OpenApiRestCall_772581
proc url_GetListTagsForResource_774557(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_774556(path: JsonNode; query: JsonNode;
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
  var valid_774558 = query.getOrDefault("ResourceName")
  valid_774558 = validateParameter(valid_774558, JString, required = true,
                                 default = nil)
  if valid_774558 != nil:
    section.add "ResourceName", valid_774558
  var valid_774559 = query.getOrDefault("Action")
  valid_774559 = validateParameter(valid_774559, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_774559 != nil:
    section.add "Action", valid_774559
  var valid_774560 = query.getOrDefault("Version")
  valid_774560 = validateParameter(valid_774560, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774560 != nil:
    section.add "Version", valid_774560
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774561 = header.getOrDefault("X-Amz-Date")
  valid_774561 = validateParameter(valid_774561, JString, required = false,
                                 default = nil)
  if valid_774561 != nil:
    section.add "X-Amz-Date", valid_774561
  var valid_774562 = header.getOrDefault("X-Amz-Security-Token")
  valid_774562 = validateParameter(valid_774562, JString, required = false,
                                 default = nil)
  if valid_774562 != nil:
    section.add "X-Amz-Security-Token", valid_774562
  var valid_774563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774563 = validateParameter(valid_774563, JString, required = false,
                                 default = nil)
  if valid_774563 != nil:
    section.add "X-Amz-Content-Sha256", valid_774563
  var valid_774564 = header.getOrDefault("X-Amz-Algorithm")
  valid_774564 = validateParameter(valid_774564, JString, required = false,
                                 default = nil)
  if valid_774564 != nil:
    section.add "X-Amz-Algorithm", valid_774564
  var valid_774565 = header.getOrDefault("X-Amz-Signature")
  valid_774565 = validateParameter(valid_774565, JString, required = false,
                                 default = nil)
  if valid_774565 != nil:
    section.add "X-Amz-Signature", valid_774565
  var valid_774566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774566 = validateParameter(valid_774566, JString, required = false,
                                 default = nil)
  if valid_774566 != nil:
    section.add "X-Amz-SignedHeaders", valid_774566
  var valid_774567 = header.getOrDefault("X-Amz-Credential")
  valid_774567 = validateParameter(valid_774567, JString, required = false,
                                 default = nil)
  if valid_774567 != nil:
    section.add "X-Amz-Credential", valid_774567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774568: Call_GetListTagsForResource_774555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774568.validator(path, query, header, formData, body)
  let scheme = call_774568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774568.url(scheme.get, call_774568.host, call_774568.base,
                         call_774568.route, valid.getOrDefault("path"))
  result = hook(call_774568, url, valid)

proc call*(call_774569: Call_GetListTagsForResource_774555; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774570 = newJObject()
  add(query_774570, "ResourceName", newJString(ResourceName))
  add(query_774570, "Action", newJString(Action))
  add(query_774570, "Version", newJString(Version))
  result = call_774569.call(nil, query_774570, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_774555(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_774556, base: "/",
    url: url_GetListTagsForResource_774557, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_774621 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBInstance_774623(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBInstance_774622(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774624 = query.getOrDefault("Action")
  valid_774624 = validateParameter(valid_774624, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_774624 != nil:
    section.add "Action", valid_774624
  var valid_774625 = query.getOrDefault("Version")
  valid_774625 = validateParameter(valid_774625, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774625 != nil:
    section.add "Version", valid_774625
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774626 = header.getOrDefault("X-Amz-Date")
  valid_774626 = validateParameter(valid_774626, JString, required = false,
                                 default = nil)
  if valid_774626 != nil:
    section.add "X-Amz-Date", valid_774626
  var valid_774627 = header.getOrDefault("X-Amz-Security-Token")
  valid_774627 = validateParameter(valid_774627, JString, required = false,
                                 default = nil)
  if valid_774627 != nil:
    section.add "X-Amz-Security-Token", valid_774627
  var valid_774628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774628 = validateParameter(valid_774628, JString, required = false,
                                 default = nil)
  if valid_774628 != nil:
    section.add "X-Amz-Content-Sha256", valid_774628
  var valid_774629 = header.getOrDefault("X-Amz-Algorithm")
  valid_774629 = validateParameter(valid_774629, JString, required = false,
                                 default = nil)
  if valid_774629 != nil:
    section.add "X-Amz-Algorithm", valid_774629
  var valid_774630 = header.getOrDefault("X-Amz-Signature")
  valid_774630 = validateParameter(valid_774630, JString, required = false,
                                 default = nil)
  if valid_774630 != nil:
    section.add "X-Amz-Signature", valid_774630
  var valid_774631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774631 = validateParameter(valid_774631, JString, required = false,
                                 default = nil)
  if valid_774631 != nil:
    section.add "X-Amz-SignedHeaders", valid_774631
  var valid_774632 = header.getOrDefault("X-Amz-Credential")
  valid_774632 = validateParameter(valid_774632, JString, required = false,
                                 default = nil)
  if valid_774632 != nil:
    section.add "X-Amz-Credential", valid_774632
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
  var valid_774633 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_774633 = validateParameter(valid_774633, JString, required = false,
                                 default = nil)
  if valid_774633 != nil:
    section.add "PreferredMaintenanceWindow", valid_774633
  var valid_774634 = formData.getOrDefault("DBSecurityGroups")
  valid_774634 = validateParameter(valid_774634, JArray, required = false,
                                 default = nil)
  if valid_774634 != nil:
    section.add "DBSecurityGroups", valid_774634
  var valid_774635 = formData.getOrDefault("ApplyImmediately")
  valid_774635 = validateParameter(valid_774635, JBool, required = false, default = nil)
  if valid_774635 != nil:
    section.add "ApplyImmediately", valid_774635
  var valid_774636 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_774636 = validateParameter(valid_774636, JArray, required = false,
                                 default = nil)
  if valid_774636 != nil:
    section.add "VpcSecurityGroupIds", valid_774636
  var valid_774637 = formData.getOrDefault("Iops")
  valid_774637 = validateParameter(valid_774637, JInt, required = false, default = nil)
  if valid_774637 != nil:
    section.add "Iops", valid_774637
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774638 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774638 = validateParameter(valid_774638, JString, required = true,
                                 default = nil)
  if valid_774638 != nil:
    section.add "DBInstanceIdentifier", valid_774638
  var valid_774639 = formData.getOrDefault("BackupRetentionPeriod")
  valid_774639 = validateParameter(valid_774639, JInt, required = false, default = nil)
  if valid_774639 != nil:
    section.add "BackupRetentionPeriod", valid_774639
  var valid_774640 = formData.getOrDefault("DBParameterGroupName")
  valid_774640 = validateParameter(valid_774640, JString, required = false,
                                 default = nil)
  if valid_774640 != nil:
    section.add "DBParameterGroupName", valid_774640
  var valid_774641 = formData.getOrDefault("OptionGroupName")
  valid_774641 = validateParameter(valid_774641, JString, required = false,
                                 default = nil)
  if valid_774641 != nil:
    section.add "OptionGroupName", valid_774641
  var valid_774642 = formData.getOrDefault("MasterUserPassword")
  valid_774642 = validateParameter(valid_774642, JString, required = false,
                                 default = nil)
  if valid_774642 != nil:
    section.add "MasterUserPassword", valid_774642
  var valid_774643 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_774643 = validateParameter(valid_774643, JString, required = false,
                                 default = nil)
  if valid_774643 != nil:
    section.add "NewDBInstanceIdentifier", valid_774643
  var valid_774644 = formData.getOrDefault("MultiAZ")
  valid_774644 = validateParameter(valid_774644, JBool, required = false, default = nil)
  if valid_774644 != nil:
    section.add "MultiAZ", valid_774644
  var valid_774645 = formData.getOrDefault("AllocatedStorage")
  valid_774645 = validateParameter(valid_774645, JInt, required = false, default = nil)
  if valid_774645 != nil:
    section.add "AllocatedStorage", valid_774645
  var valid_774646 = formData.getOrDefault("DBInstanceClass")
  valid_774646 = validateParameter(valid_774646, JString, required = false,
                                 default = nil)
  if valid_774646 != nil:
    section.add "DBInstanceClass", valid_774646
  var valid_774647 = formData.getOrDefault("PreferredBackupWindow")
  valid_774647 = validateParameter(valid_774647, JString, required = false,
                                 default = nil)
  if valid_774647 != nil:
    section.add "PreferredBackupWindow", valid_774647
  var valid_774648 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_774648 = validateParameter(valid_774648, JBool, required = false, default = nil)
  if valid_774648 != nil:
    section.add "AutoMinorVersionUpgrade", valid_774648
  var valid_774649 = formData.getOrDefault("EngineVersion")
  valid_774649 = validateParameter(valid_774649, JString, required = false,
                                 default = nil)
  if valid_774649 != nil:
    section.add "EngineVersion", valid_774649
  var valid_774650 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_774650 = validateParameter(valid_774650, JBool, required = false, default = nil)
  if valid_774650 != nil:
    section.add "AllowMajorVersionUpgrade", valid_774650
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774651: Call_PostModifyDBInstance_774621; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774651.validator(path, query, header, formData, body)
  let scheme = call_774651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774651.url(scheme.get, call_774651.host, call_774651.base,
                         call_774651.route, valid.getOrDefault("path"))
  result = hook(call_774651, url, valid)

proc call*(call_774652: Call_PostModifyDBInstance_774621;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBSecurityGroups: JsonNode = nil; ApplyImmediately: bool = false;
          VpcSecurityGroupIds: JsonNode = nil; Iops: int = 0;
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          OptionGroupName: string = ""; MasterUserPassword: string = "";
          NewDBInstanceIdentifier: string = ""; MultiAZ: bool = false;
          Action: string = "ModifyDBInstance"; AllocatedStorage: int = 0;
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          Version: string = "2013-01-10"; AllowMajorVersionUpgrade: bool = false): Recallable =
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
  var query_774653 = newJObject()
  var formData_774654 = newJObject()
  add(formData_774654, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_774654.add "DBSecurityGroups", DBSecurityGroups
  add(formData_774654, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_774654.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_774654, "Iops", newJInt(Iops))
  add(formData_774654, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774654, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_774654, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_774654, "OptionGroupName", newJString(OptionGroupName))
  add(formData_774654, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_774654, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_774654, "MultiAZ", newJBool(MultiAZ))
  add(query_774653, "Action", newJString(Action))
  add(formData_774654, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_774654, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_774654, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_774654, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_774654, "EngineVersion", newJString(EngineVersion))
  add(query_774653, "Version", newJString(Version))
  add(formData_774654, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_774652.call(nil, query_774653, nil, formData_774654, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_774621(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_774622, base: "/",
    url: url_PostModifyDBInstance_774623, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_774588 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBInstance_774590(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBInstance_774589(path: JsonNode; query: JsonNode;
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
  var valid_774591 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_774591 = validateParameter(valid_774591, JString, required = false,
                                 default = nil)
  if valid_774591 != nil:
    section.add "PreferredMaintenanceWindow", valid_774591
  var valid_774592 = query.getOrDefault("AllocatedStorage")
  valid_774592 = validateParameter(valid_774592, JInt, required = false, default = nil)
  if valid_774592 != nil:
    section.add "AllocatedStorage", valid_774592
  var valid_774593 = query.getOrDefault("OptionGroupName")
  valid_774593 = validateParameter(valid_774593, JString, required = false,
                                 default = nil)
  if valid_774593 != nil:
    section.add "OptionGroupName", valid_774593
  var valid_774594 = query.getOrDefault("DBSecurityGroups")
  valid_774594 = validateParameter(valid_774594, JArray, required = false,
                                 default = nil)
  if valid_774594 != nil:
    section.add "DBSecurityGroups", valid_774594
  var valid_774595 = query.getOrDefault("MasterUserPassword")
  valid_774595 = validateParameter(valid_774595, JString, required = false,
                                 default = nil)
  if valid_774595 != nil:
    section.add "MasterUserPassword", valid_774595
  var valid_774596 = query.getOrDefault("Iops")
  valid_774596 = validateParameter(valid_774596, JInt, required = false, default = nil)
  if valid_774596 != nil:
    section.add "Iops", valid_774596
  var valid_774597 = query.getOrDefault("VpcSecurityGroupIds")
  valid_774597 = validateParameter(valid_774597, JArray, required = false,
                                 default = nil)
  if valid_774597 != nil:
    section.add "VpcSecurityGroupIds", valid_774597
  var valid_774598 = query.getOrDefault("MultiAZ")
  valid_774598 = validateParameter(valid_774598, JBool, required = false, default = nil)
  if valid_774598 != nil:
    section.add "MultiAZ", valid_774598
  var valid_774599 = query.getOrDefault("BackupRetentionPeriod")
  valid_774599 = validateParameter(valid_774599, JInt, required = false, default = nil)
  if valid_774599 != nil:
    section.add "BackupRetentionPeriod", valid_774599
  var valid_774600 = query.getOrDefault("DBParameterGroupName")
  valid_774600 = validateParameter(valid_774600, JString, required = false,
                                 default = nil)
  if valid_774600 != nil:
    section.add "DBParameterGroupName", valid_774600
  var valid_774601 = query.getOrDefault("DBInstanceClass")
  valid_774601 = validateParameter(valid_774601, JString, required = false,
                                 default = nil)
  if valid_774601 != nil:
    section.add "DBInstanceClass", valid_774601
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774602 = query.getOrDefault("Action")
  valid_774602 = validateParameter(valid_774602, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_774602 != nil:
    section.add "Action", valid_774602
  var valid_774603 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_774603 = validateParameter(valid_774603, JBool, required = false, default = nil)
  if valid_774603 != nil:
    section.add "AllowMajorVersionUpgrade", valid_774603
  var valid_774604 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_774604 = validateParameter(valid_774604, JString, required = false,
                                 default = nil)
  if valid_774604 != nil:
    section.add "NewDBInstanceIdentifier", valid_774604
  var valid_774605 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_774605 = validateParameter(valid_774605, JBool, required = false, default = nil)
  if valid_774605 != nil:
    section.add "AutoMinorVersionUpgrade", valid_774605
  var valid_774606 = query.getOrDefault("EngineVersion")
  valid_774606 = validateParameter(valid_774606, JString, required = false,
                                 default = nil)
  if valid_774606 != nil:
    section.add "EngineVersion", valid_774606
  var valid_774607 = query.getOrDefault("PreferredBackupWindow")
  valid_774607 = validateParameter(valid_774607, JString, required = false,
                                 default = nil)
  if valid_774607 != nil:
    section.add "PreferredBackupWindow", valid_774607
  var valid_774608 = query.getOrDefault("Version")
  valid_774608 = validateParameter(valid_774608, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774608 != nil:
    section.add "Version", valid_774608
  var valid_774609 = query.getOrDefault("DBInstanceIdentifier")
  valid_774609 = validateParameter(valid_774609, JString, required = true,
                                 default = nil)
  if valid_774609 != nil:
    section.add "DBInstanceIdentifier", valid_774609
  var valid_774610 = query.getOrDefault("ApplyImmediately")
  valid_774610 = validateParameter(valid_774610, JBool, required = false, default = nil)
  if valid_774610 != nil:
    section.add "ApplyImmediately", valid_774610
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774611 = header.getOrDefault("X-Amz-Date")
  valid_774611 = validateParameter(valid_774611, JString, required = false,
                                 default = nil)
  if valid_774611 != nil:
    section.add "X-Amz-Date", valid_774611
  var valid_774612 = header.getOrDefault("X-Amz-Security-Token")
  valid_774612 = validateParameter(valid_774612, JString, required = false,
                                 default = nil)
  if valid_774612 != nil:
    section.add "X-Amz-Security-Token", valid_774612
  var valid_774613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774613 = validateParameter(valid_774613, JString, required = false,
                                 default = nil)
  if valid_774613 != nil:
    section.add "X-Amz-Content-Sha256", valid_774613
  var valid_774614 = header.getOrDefault("X-Amz-Algorithm")
  valid_774614 = validateParameter(valid_774614, JString, required = false,
                                 default = nil)
  if valid_774614 != nil:
    section.add "X-Amz-Algorithm", valid_774614
  var valid_774615 = header.getOrDefault("X-Amz-Signature")
  valid_774615 = validateParameter(valid_774615, JString, required = false,
                                 default = nil)
  if valid_774615 != nil:
    section.add "X-Amz-Signature", valid_774615
  var valid_774616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774616 = validateParameter(valid_774616, JString, required = false,
                                 default = nil)
  if valid_774616 != nil:
    section.add "X-Amz-SignedHeaders", valid_774616
  var valid_774617 = header.getOrDefault("X-Amz-Credential")
  valid_774617 = validateParameter(valid_774617, JString, required = false,
                                 default = nil)
  if valid_774617 != nil:
    section.add "X-Amz-Credential", valid_774617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774618: Call_GetModifyDBInstance_774588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774618.validator(path, query, header, formData, body)
  let scheme = call_774618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774618.url(scheme.get, call_774618.host, call_774618.base,
                         call_774618.route, valid.getOrDefault("path"))
  result = hook(call_774618, url, valid)

proc call*(call_774619: Call_GetModifyDBInstance_774588;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          AllocatedStorage: int = 0; OptionGroupName: string = "";
          DBSecurityGroups: JsonNode = nil; MasterUserPassword: string = "";
          Iops: int = 0; VpcSecurityGroupIds: JsonNode = nil; MultiAZ: bool = false;
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          DBInstanceClass: string = ""; Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false;
          NewDBInstanceIdentifier: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          PreferredBackupWindow: string = ""; Version: string = "2013-01-10";
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
  var query_774620 = newJObject()
  add(query_774620, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_774620, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_774620, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_774620.add "DBSecurityGroups", DBSecurityGroups
  add(query_774620, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_774620, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_774620.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_774620, "MultiAZ", newJBool(MultiAZ))
  add(query_774620, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_774620, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_774620, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774620, "Action", newJString(Action))
  add(query_774620, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_774620, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_774620, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_774620, "EngineVersion", newJString(EngineVersion))
  add(query_774620, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_774620, "Version", newJString(Version))
  add(query_774620, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_774620, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_774619.call(nil, query_774620, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_774588(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_774589, base: "/",
    url: url_GetModifyDBInstance_774590, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_774672 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBParameterGroup_774674(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBParameterGroup_774673(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774675 = query.getOrDefault("Action")
  valid_774675 = validateParameter(valid_774675, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_774675 != nil:
    section.add "Action", valid_774675
  var valid_774676 = query.getOrDefault("Version")
  valid_774676 = validateParameter(valid_774676, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774676 != nil:
    section.add "Version", valid_774676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774677 = header.getOrDefault("X-Amz-Date")
  valid_774677 = validateParameter(valid_774677, JString, required = false,
                                 default = nil)
  if valid_774677 != nil:
    section.add "X-Amz-Date", valid_774677
  var valid_774678 = header.getOrDefault("X-Amz-Security-Token")
  valid_774678 = validateParameter(valid_774678, JString, required = false,
                                 default = nil)
  if valid_774678 != nil:
    section.add "X-Amz-Security-Token", valid_774678
  var valid_774679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774679 = validateParameter(valid_774679, JString, required = false,
                                 default = nil)
  if valid_774679 != nil:
    section.add "X-Amz-Content-Sha256", valid_774679
  var valid_774680 = header.getOrDefault("X-Amz-Algorithm")
  valid_774680 = validateParameter(valid_774680, JString, required = false,
                                 default = nil)
  if valid_774680 != nil:
    section.add "X-Amz-Algorithm", valid_774680
  var valid_774681 = header.getOrDefault("X-Amz-Signature")
  valid_774681 = validateParameter(valid_774681, JString, required = false,
                                 default = nil)
  if valid_774681 != nil:
    section.add "X-Amz-Signature", valid_774681
  var valid_774682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774682 = validateParameter(valid_774682, JString, required = false,
                                 default = nil)
  if valid_774682 != nil:
    section.add "X-Amz-SignedHeaders", valid_774682
  var valid_774683 = header.getOrDefault("X-Amz-Credential")
  valid_774683 = validateParameter(valid_774683, JString, required = false,
                                 default = nil)
  if valid_774683 != nil:
    section.add "X-Amz-Credential", valid_774683
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_774684 = formData.getOrDefault("DBParameterGroupName")
  valid_774684 = validateParameter(valid_774684, JString, required = true,
                                 default = nil)
  if valid_774684 != nil:
    section.add "DBParameterGroupName", valid_774684
  var valid_774685 = formData.getOrDefault("Parameters")
  valid_774685 = validateParameter(valid_774685, JArray, required = true, default = nil)
  if valid_774685 != nil:
    section.add "Parameters", valid_774685
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774686: Call_PostModifyDBParameterGroup_774672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774686.validator(path, query, header, formData, body)
  let scheme = call_774686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774686.url(scheme.get, call_774686.host, call_774686.base,
                         call_774686.route, valid.getOrDefault("path"))
  result = hook(call_774686, url, valid)

proc call*(call_774687: Call_PostModifyDBParameterGroup_774672;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774688 = newJObject()
  var formData_774689 = newJObject()
  add(formData_774689, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_774689.add "Parameters", Parameters
  add(query_774688, "Action", newJString(Action))
  add(query_774688, "Version", newJString(Version))
  result = call_774687.call(nil, query_774688, nil, formData_774689, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_774672(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_774673, base: "/",
    url: url_PostModifyDBParameterGroup_774674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_774655 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBParameterGroup_774657(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBParameterGroup_774656(path: JsonNode; query: JsonNode;
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
  var valid_774658 = query.getOrDefault("DBParameterGroupName")
  valid_774658 = validateParameter(valid_774658, JString, required = true,
                                 default = nil)
  if valid_774658 != nil:
    section.add "DBParameterGroupName", valid_774658
  var valid_774659 = query.getOrDefault("Parameters")
  valid_774659 = validateParameter(valid_774659, JArray, required = true, default = nil)
  if valid_774659 != nil:
    section.add "Parameters", valid_774659
  var valid_774660 = query.getOrDefault("Action")
  valid_774660 = validateParameter(valid_774660, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_774660 != nil:
    section.add "Action", valid_774660
  var valid_774661 = query.getOrDefault("Version")
  valid_774661 = validateParameter(valid_774661, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774661 != nil:
    section.add "Version", valid_774661
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774662 = header.getOrDefault("X-Amz-Date")
  valid_774662 = validateParameter(valid_774662, JString, required = false,
                                 default = nil)
  if valid_774662 != nil:
    section.add "X-Amz-Date", valid_774662
  var valid_774663 = header.getOrDefault("X-Amz-Security-Token")
  valid_774663 = validateParameter(valid_774663, JString, required = false,
                                 default = nil)
  if valid_774663 != nil:
    section.add "X-Amz-Security-Token", valid_774663
  var valid_774664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774664 = validateParameter(valid_774664, JString, required = false,
                                 default = nil)
  if valid_774664 != nil:
    section.add "X-Amz-Content-Sha256", valid_774664
  var valid_774665 = header.getOrDefault("X-Amz-Algorithm")
  valid_774665 = validateParameter(valid_774665, JString, required = false,
                                 default = nil)
  if valid_774665 != nil:
    section.add "X-Amz-Algorithm", valid_774665
  var valid_774666 = header.getOrDefault("X-Amz-Signature")
  valid_774666 = validateParameter(valid_774666, JString, required = false,
                                 default = nil)
  if valid_774666 != nil:
    section.add "X-Amz-Signature", valid_774666
  var valid_774667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774667 = validateParameter(valid_774667, JString, required = false,
                                 default = nil)
  if valid_774667 != nil:
    section.add "X-Amz-SignedHeaders", valid_774667
  var valid_774668 = header.getOrDefault("X-Amz-Credential")
  valid_774668 = validateParameter(valid_774668, JString, required = false,
                                 default = nil)
  if valid_774668 != nil:
    section.add "X-Amz-Credential", valid_774668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774669: Call_GetModifyDBParameterGroup_774655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774669.validator(path, query, header, formData, body)
  let scheme = call_774669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774669.url(scheme.get, call_774669.host, call_774669.base,
                         call_774669.route, valid.getOrDefault("path"))
  result = hook(call_774669, url, valid)

proc call*(call_774670: Call_GetModifyDBParameterGroup_774655;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774671 = newJObject()
  add(query_774671, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_774671.add "Parameters", Parameters
  add(query_774671, "Action", newJString(Action))
  add(query_774671, "Version", newJString(Version))
  result = call_774670.call(nil, query_774671, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_774655(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_774656, base: "/",
    url: url_GetModifyDBParameterGroup_774657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_774708 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBSubnetGroup_774710(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBSubnetGroup_774709(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774711 = query.getOrDefault("Action")
  valid_774711 = validateParameter(valid_774711, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_774711 != nil:
    section.add "Action", valid_774711
  var valid_774712 = query.getOrDefault("Version")
  valid_774712 = validateParameter(valid_774712, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774712 != nil:
    section.add "Version", valid_774712
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774713 = header.getOrDefault("X-Amz-Date")
  valid_774713 = validateParameter(valid_774713, JString, required = false,
                                 default = nil)
  if valid_774713 != nil:
    section.add "X-Amz-Date", valid_774713
  var valid_774714 = header.getOrDefault("X-Amz-Security-Token")
  valid_774714 = validateParameter(valid_774714, JString, required = false,
                                 default = nil)
  if valid_774714 != nil:
    section.add "X-Amz-Security-Token", valid_774714
  var valid_774715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774715 = validateParameter(valid_774715, JString, required = false,
                                 default = nil)
  if valid_774715 != nil:
    section.add "X-Amz-Content-Sha256", valid_774715
  var valid_774716 = header.getOrDefault("X-Amz-Algorithm")
  valid_774716 = validateParameter(valid_774716, JString, required = false,
                                 default = nil)
  if valid_774716 != nil:
    section.add "X-Amz-Algorithm", valid_774716
  var valid_774717 = header.getOrDefault("X-Amz-Signature")
  valid_774717 = validateParameter(valid_774717, JString, required = false,
                                 default = nil)
  if valid_774717 != nil:
    section.add "X-Amz-Signature", valid_774717
  var valid_774718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774718 = validateParameter(valid_774718, JString, required = false,
                                 default = nil)
  if valid_774718 != nil:
    section.add "X-Amz-SignedHeaders", valid_774718
  var valid_774719 = header.getOrDefault("X-Amz-Credential")
  valid_774719 = validateParameter(valid_774719, JString, required = false,
                                 default = nil)
  if valid_774719 != nil:
    section.add "X-Amz-Credential", valid_774719
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_774720 = formData.getOrDefault("DBSubnetGroupName")
  valid_774720 = validateParameter(valid_774720, JString, required = true,
                                 default = nil)
  if valid_774720 != nil:
    section.add "DBSubnetGroupName", valid_774720
  var valid_774721 = formData.getOrDefault("SubnetIds")
  valid_774721 = validateParameter(valid_774721, JArray, required = true, default = nil)
  if valid_774721 != nil:
    section.add "SubnetIds", valid_774721
  var valid_774722 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_774722 = validateParameter(valid_774722, JString, required = false,
                                 default = nil)
  if valid_774722 != nil:
    section.add "DBSubnetGroupDescription", valid_774722
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774723: Call_PostModifyDBSubnetGroup_774708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774723.validator(path, query, header, formData, body)
  let scheme = call_774723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774723.url(scheme.get, call_774723.host, call_774723.base,
                         call_774723.route, valid.getOrDefault("path"))
  result = hook(call_774723, url, valid)

proc call*(call_774724: Call_PostModifyDBSubnetGroup_774708;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_774725 = newJObject()
  var formData_774726 = newJObject()
  add(formData_774726, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_774726.add "SubnetIds", SubnetIds
  add(query_774725, "Action", newJString(Action))
  add(formData_774726, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_774725, "Version", newJString(Version))
  result = call_774724.call(nil, query_774725, nil, formData_774726, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_774708(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_774709, base: "/",
    url: url_PostModifyDBSubnetGroup_774710, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_774690 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBSubnetGroup_774692(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBSubnetGroup_774691(path: JsonNode; query: JsonNode;
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
  var valid_774693 = query.getOrDefault("Action")
  valid_774693 = validateParameter(valid_774693, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_774693 != nil:
    section.add "Action", valid_774693
  var valid_774694 = query.getOrDefault("DBSubnetGroupName")
  valid_774694 = validateParameter(valid_774694, JString, required = true,
                                 default = nil)
  if valid_774694 != nil:
    section.add "DBSubnetGroupName", valid_774694
  var valid_774695 = query.getOrDefault("SubnetIds")
  valid_774695 = validateParameter(valid_774695, JArray, required = true, default = nil)
  if valid_774695 != nil:
    section.add "SubnetIds", valid_774695
  var valid_774696 = query.getOrDefault("DBSubnetGroupDescription")
  valid_774696 = validateParameter(valid_774696, JString, required = false,
                                 default = nil)
  if valid_774696 != nil:
    section.add "DBSubnetGroupDescription", valid_774696
  var valid_774697 = query.getOrDefault("Version")
  valid_774697 = validateParameter(valid_774697, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774697 != nil:
    section.add "Version", valid_774697
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774698 = header.getOrDefault("X-Amz-Date")
  valid_774698 = validateParameter(valid_774698, JString, required = false,
                                 default = nil)
  if valid_774698 != nil:
    section.add "X-Amz-Date", valid_774698
  var valid_774699 = header.getOrDefault("X-Amz-Security-Token")
  valid_774699 = validateParameter(valid_774699, JString, required = false,
                                 default = nil)
  if valid_774699 != nil:
    section.add "X-Amz-Security-Token", valid_774699
  var valid_774700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774700 = validateParameter(valid_774700, JString, required = false,
                                 default = nil)
  if valid_774700 != nil:
    section.add "X-Amz-Content-Sha256", valid_774700
  var valid_774701 = header.getOrDefault("X-Amz-Algorithm")
  valid_774701 = validateParameter(valid_774701, JString, required = false,
                                 default = nil)
  if valid_774701 != nil:
    section.add "X-Amz-Algorithm", valid_774701
  var valid_774702 = header.getOrDefault("X-Amz-Signature")
  valid_774702 = validateParameter(valid_774702, JString, required = false,
                                 default = nil)
  if valid_774702 != nil:
    section.add "X-Amz-Signature", valid_774702
  var valid_774703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774703 = validateParameter(valid_774703, JString, required = false,
                                 default = nil)
  if valid_774703 != nil:
    section.add "X-Amz-SignedHeaders", valid_774703
  var valid_774704 = header.getOrDefault("X-Amz-Credential")
  valid_774704 = validateParameter(valid_774704, JString, required = false,
                                 default = nil)
  if valid_774704 != nil:
    section.add "X-Amz-Credential", valid_774704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774705: Call_GetModifyDBSubnetGroup_774690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774705.validator(path, query, header, formData, body)
  let scheme = call_774705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774705.url(scheme.get, call_774705.host, call_774705.base,
                         call_774705.route, valid.getOrDefault("path"))
  result = hook(call_774705, url, valid)

proc call*(call_774706: Call_GetModifyDBSubnetGroup_774690;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_774707 = newJObject()
  add(query_774707, "Action", newJString(Action))
  add(query_774707, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_774707.add "SubnetIds", SubnetIds
  add(query_774707, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_774707, "Version", newJString(Version))
  result = call_774706.call(nil, query_774707, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_774690(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_774691, base: "/",
    url: url_GetModifyDBSubnetGroup_774692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_774747 = ref object of OpenApiRestCall_772581
proc url_PostModifyEventSubscription_774749(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyEventSubscription_774748(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774750 = query.getOrDefault("Action")
  valid_774750 = validateParameter(valid_774750, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_774750 != nil:
    section.add "Action", valid_774750
  var valid_774751 = query.getOrDefault("Version")
  valid_774751 = validateParameter(valid_774751, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774751 != nil:
    section.add "Version", valid_774751
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774752 = header.getOrDefault("X-Amz-Date")
  valid_774752 = validateParameter(valid_774752, JString, required = false,
                                 default = nil)
  if valid_774752 != nil:
    section.add "X-Amz-Date", valid_774752
  var valid_774753 = header.getOrDefault("X-Amz-Security-Token")
  valid_774753 = validateParameter(valid_774753, JString, required = false,
                                 default = nil)
  if valid_774753 != nil:
    section.add "X-Amz-Security-Token", valid_774753
  var valid_774754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774754 = validateParameter(valid_774754, JString, required = false,
                                 default = nil)
  if valid_774754 != nil:
    section.add "X-Amz-Content-Sha256", valid_774754
  var valid_774755 = header.getOrDefault("X-Amz-Algorithm")
  valid_774755 = validateParameter(valid_774755, JString, required = false,
                                 default = nil)
  if valid_774755 != nil:
    section.add "X-Amz-Algorithm", valid_774755
  var valid_774756 = header.getOrDefault("X-Amz-Signature")
  valid_774756 = validateParameter(valid_774756, JString, required = false,
                                 default = nil)
  if valid_774756 != nil:
    section.add "X-Amz-Signature", valid_774756
  var valid_774757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774757 = validateParameter(valid_774757, JString, required = false,
                                 default = nil)
  if valid_774757 != nil:
    section.add "X-Amz-SignedHeaders", valid_774757
  var valid_774758 = header.getOrDefault("X-Amz-Credential")
  valid_774758 = validateParameter(valid_774758, JString, required = false,
                                 default = nil)
  if valid_774758 != nil:
    section.add "X-Amz-Credential", valid_774758
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_774759 = formData.getOrDefault("Enabled")
  valid_774759 = validateParameter(valid_774759, JBool, required = false, default = nil)
  if valid_774759 != nil:
    section.add "Enabled", valid_774759
  var valid_774760 = formData.getOrDefault("EventCategories")
  valid_774760 = validateParameter(valid_774760, JArray, required = false,
                                 default = nil)
  if valid_774760 != nil:
    section.add "EventCategories", valid_774760
  var valid_774761 = formData.getOrDefault("SnsTopicArn")
  valid_774761 = validateParameter(valid_774761, JString, required = false,
                                 default = nil)
  if valid_774761 != nil:
    section.add "SnsTopicArn", valid_774761
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_774762 = formData.getOrDefault("SubscriptionName")
  valid_774762 = validateParameter(valid_774762, JString, required = true,
                                 default = nil)
  if valid_774762 != nil:
    section.add "SubscriptionName", valid_774762
  var valid_774763 = formData.getOrDefault("SourceType")
  valid_774763 = validateParameter(valid_774763, JString, required = false,
                                 default = nil)
  if valid_774763 != nil:
    section.add "SourceType", valid_774763
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774764: Call_PostModifyEventSubscription_774747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774764.validator(path, query, header, formData, body)
  let scheme = call_774764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774764.url(scheme.get, call_774764.host, call_774764.base,
                         call_774764.route, valid.getOrDefault("path"))
  result = hook(call_774764, url, valid)

proc call*(call_774765: Call_PostModifyEventSubscription_774747;
          SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SnsTopicArn: string = "";
          Action: string = "ModifyEventSubscription";
          Version: string = "2013-01-10"; SourceType: string = ""): Recallable =
  ## postModifyEventSubscription
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   SnsTopicArn: string
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_774766 = newJObject()
  var formData_774767 = newJObject()
  add(formData_774767, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_774767.add "EventCategories", EventCategories
  add(formData_774767, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_774767, "SubscriptionName", newJString(SubscriptionName))
  add(query_774766, "Action", newJString(Action))
  add(query_774766, "Version", newJString(Version))
  add(formData_774767, "SourceType", newJString(SourceType))
  result = call_774765.call(nil, query_774766, nil, formData_774767, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_774747(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_774748, base: "/",
    url: url_PostModifyEventSubscription_774749,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_774727 = ref object of OpenApiRestCall_772581
proc url_GetModifyEventSubscription_774729(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyEventSubscription_774728(path: JsonNode; query: JsonNode;
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
  var valid_774730 = query.getOrDefault("SourceType")
  valid_774730 = validateParameter(valid_774730, JString, required = false,
                                 default = nil)
  if valid_774730 != nil:
    section.add "SourceType", valid_774730
  var valid_774731 = query.getOrDefault("Enabled")
  valid_774731 = validateParameter(valid_774731, JBool, required = false, default = nil)
  if valid_774731 != nil:
    section.add "Enabled", valid_774731
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774732 = query.getOrDefault("Action")
  valid_774732 = validateParameter(valid_774732, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_774732 != nil:
    section.add "Action", valid_774732
  var valid_774733 = query.getOrDefault("SnsTopicArn")
  valid_774733 = validateParameter(valid_774733, JString, required = false,
                                 default = nil)
  if valid_774733 != nil:
    section.add "SnsTopicArn", valid_774733
  var valid_774734 = query.getOrDefault("EventCategories")
  valid_774734 = validateParameter(valid_774734, JArray, required = false,
                                 default = nil)
  if valid_774734 != nil:
    section.add "EventCategories", valid_774734
  var valid_774735 = query.getOrDefault("SubscriptionName")
  valid_774735 = validateParameter(valid_774735, JString, required = true,
                                 default = nil)
  if valid_774735 != nil:
    section.add "SubscriptionName", valid_774735
  var valid_774736 = query.getOrDefault("Version")
  valid_774736 = validateParameter(valid_774736, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774736 != nil:
    section.add "Version", valid_774736
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774737 = header.getOrDefault("X-Amz-Date")
  valid_774737 = validateParameter(valid_774737, JString, required = false,
                                 default = nil)
  if valid_774737 != nil:
    section.add "X-Amz-Date", valid_774737
  var valid_774738 = header.getOrDefault("X-Amz-Security-Token")
  valid_774738 = validateParameter(valid_774738, JString, required = false,
                                 default = nil)
  if valid_774738 != nil:
    section.add "X-Amz-Security-Token", valid_774738
  var valid_774739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774739 = validateParameter(valid_774739, JString, required = false,
                                 default = nil)
  if valid_774739 != nil:
    section.add "X-Amz-Content-Sha256", valid_774739
  var valid_774740 = header.getOrDefault("X-Amz-Algorithm")
  valid_774740 = validateParameter(valid_774740, JString, required = false,
                                 default = nil)
  if valid_774740 != nil:
    section.add "X-Amz-Algorithm", valid_774740
  var valid_774741 = header.getOrDefault("X-Amz-Signature")
  valid_774741 = validateParameter(valid_774741, JString, required = false,
                                 default = nil)
  if valid_774741 != nil:
    section.add "X-Amz-Signature", valid_774741
  var valid_774742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774742 = validateParameter(valid_774742, JString, required = false,
                                 default = nil)
  if valid_774742 != nil:
    section.add "X-Amz-SignedHeaders", valid_774742
  var valid_774743 = header.getOrDefault("X-Amz-Credential")
  valid_774743 = validateParameter(valid_774743, JString, required = false,
                                 default = nil)
  if valid_774743 != nil:
    section.add "X-Amz-Credential", valid_774743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774744: Call_GetModifyEventSubscription_774727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774744.validator(path, query, header, formData, body)
  let scheme = call_774744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774744.url(scheme.get, call_774744.host, call_774744.base,
                         call_774744.route, valid.getOrDefault("path"))
  result = hook(call_774744, url, valid)

proc call*(call_774745: Call_GetModifyEventSubscription_774727;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          EventCategories: JsonNode = nil; Version: string = "2013-01-10"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   EventCategories: JArray
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_774746 = newJObject()
  add(query_774746, "SourceType", newJString(SourceType))
  add(query_774746, "Enabled", newJBool(Enabled))
  add(query_774746, "Action", newJString(Action))
  add(query_774746, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_774746.add "EventCategories", EventCategories
  add(query_774746, "SubscriptionName", newJString(SubscriptionName))
  add(query_774746, "Version", newJString(Version))
  result = call_774745.call(nil, query_774746, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_774727(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_774728, base: "/",
    url: url_GetModifyEventSubscription_774729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_774787 = ref object of OpenApiRestCall_772581
proc url_PostModifyOptionGroup_774789(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyOptionGroup_774788(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774790 = query.getOrDefault("Action")
  valid_774790 = validateParameter(valid_774790, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_774790 != nil:
    section.add "Action", valid_774790
  var valid_774791 = query.getOrDefault("Version")
  valid_774791 = validateParameter(valid_774791, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774791 != nil:
    section.add "Version", valid_774791
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774792 = header.getOrDefault("X-Amz-Date")
  valid_774792 = validateParameter(valid_774792, JString, required = false,
                                 default = nil)
  if valid_774792 != nil:
    section.add "X-Amz-Date", valid_774792
  var valid_774793 = header.getOrDefault("X-Amz-Security-Token")
  valid_774793 = validateParameter(valid_774793, JString, required = false,
                                 default = nil)
  if valid_774793 != nil:
    section.add "X-Amz-Security-Token", valid_774793
  var valid_774794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774794 = validateParameter(valid_774794, JString, required = false,
                                 default = nil)
  if valid_774794 != nil:
    section.add "X-Amz-Content-Sha256", valid_774794
  var valid_774795 = header.getOrDefault("X-Amz-Algorithm")
  valid_774795 = validateParameter(valid_774795, JString, required = false,
                                 default = nil)
  if valid_774795 != nil:
    section.add "X-Amz-Algorithm", valid_774795
  var valid_774796 = header.getOrDefault("X-Amz-Signature")
  valid_774796 = validateParameter(valid_774796, JString, required = false,
                                 default = nil)
  if valid_774796 != nil:
    section.add "X-Amz-Signature", valid_774796
  var valid_774797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774797 = validateParameter(valid_774797, JString, required = false,
                                 default = nil)
  if valid_774797 != nil:
    section.add "X-Amz-SignedHeaders", valid_774797
  var valid_774798 = header.getOrDefault("X-Amz-Credential")
  valid_774798 = validateParameter(valid_774798, JString, required = false,
                                 default = nil)
  if valid_774798 != nil:
    section.add "X-Amz-Credential", valid_774798
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_774799 = formData.getOrDefault("OptionsToRemove")
  valid_774799 = validateParameter(valid_774799, JArray, required = false,
                                 default = nil)
  if valid_774799 != nil:
    section.add "OptionsToRemove", valid_774799
  var valid_774800 = formData.getOrDefault("ApplyImmediately")
  valid_774800 = validateParameter(valid_774800, JBool, required = false, default = nil)
  if valid_774800 != nil:
    section.add "ApplyImmediately", valid_774800
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_774801 = formData.getOrDefault("OptionGroupName")
  valid_774801 = validateParameter(valid_774801, JString, required = true,
                                 default = nil)
  if valid_774801 != nil:
    section.add "OptionGroupName", valid_774801
  var valid_774802 = formData.getOrDefault("OptionsToInclude")
  valid_774802 = validateParameter(valid_774802, JArray, required = false,
                                 default = nil)
  if valid_774802 != nil:
    section.add "OptionsToInclude", valid_774802
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774803: Call_PostModifyOptionGroup_774787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774803.validator(path, query, header, formData, body)
  let scheme = call_774803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774803.url(scheme.get, call_774803.host, call_774803.base,
                         call_774803.route, valid.getOrDefault("path"))
  result = hook(call_774803, url, valid)

proc call*(call_774804: Call_PostModifyOptionGroup_774787; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionGroupName: string (required)
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774805 = newJObject()
  var formData_774806 = newJObject()
  if OptionsToRemove != nil:
    formData_774806.add "OptionsToRemove", OptionsToRemove
  add(formData_774806, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_774806, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_774806.add "OptionsToInclude", OptionsToInclude
  add(query_774805, "Action", newJString(Action))
  add(query_774805, "Version", newJString(Version))
  result = call_774804.call(nil, query_774805, nil, formData_774806, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_774787(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_774788, base: "/",
    url: url_PostModifyOptionGroup_774789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_774768 = ref object of OpenApiRestCall_772581
proc url_GetModifyOptionGroup_774770(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyOptionGroup_774769(path: JsonNode; query: JsonNode;
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
  var valid_774771 = query.getOrDefault("OptionGroupName")
  valid_774771 = validateParameter(valid_774771, JString, required = true,
                                 default = nil)
  if valid_774771 != nil:
    section.add "OptionGroupName", valid_774771
  var valid_774772 = query.getOrDefault("OptionsToRemove")
  valid_774772 = validateParameter(valid_774772, JArray, required = false,
                                 default = nil)
  if valid_774772 != nil:
    section.add "OptionsToRemove", valid_774772
  var valid_774773 = query.getOrDefault("Action")
  valid_774773 = validateParameter(valid_774773, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_774773 != nil:
    section.add "Action", valid_774773
  var valid_774774 = query.getOrDefault("Version")
  valid_774774 = validateParameter(valid_774774, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774774 != nil:
    section.add "Version", valid_774774
  var valid_774775 = query.getOrDefault("ApplyImmediately")
  valid_774775 = validateParameter(valid_774775, JBool, required = false, default = nil)
  if valid_774775 != nil:
    section.add "ApplyImmediately", valid_774775
  var valid_774776 = query.getOrDefault("OptionsToInclude")
  valid_774776 = validateParameter(valid_774776, JArray, required = false,
                                 default = nil)
  if valid_774776 != nil:
    section.add "OptionsToInclude", valid_774776
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774777 = header.getOrDefault("X-Amz-Date")
  valid_774777 = validateParameter(valid_774777, JString, required = false,
                                 default = nil)
  if valid_774777 != nil:
    section.add "X-Amz-Date", valid_774777
  var valid_774778 = header.getOrDefault("X-Amz-Security-Token")
  valid_774778 = validateParameter(valid_774778, JString, required = false,
                                 default = nil)
  if valid_774778 != nil:
    section.add "X-Amz-Security-Token", valid_774778
  var valid_774779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774779 = validateParameter(valid_774779, JString, required = false,
                                 default = nil)
  if valid_774779 != nil:
    section.add "X-Amz-Content-Sha256", valid_774779
  var valid_774780 = header.getOrDefault("X-Amz-Algorithm")
  valid_774780 = validateParameter(valid_774780, JString, required = false,
                                 default = nil)
  if valid_774780 != nil:
    section.add "X-Amz-Algorithm", valid_774780
  var valid_774781 = header.getOrDefault("X-Amz-Signature")
  valid_774781 = validateParameter(valid_774781, JString, required = false,
                                 default = nil)
  if valid_774781 != nil:
    section.add "X-Amz-Signature", valid_774781
  var valid_774782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774782 = validateParameter(valid_774782, JString, required = false,
                                 default = nil)
  if valid_774782 != nil:
    section.add "X-Amz-SignedHeaders", valid_774782
  var valid_774783 = header.getOrDefault("X-Amz-Credential")
  valid_774783 = validateParameter(valid_774783, JString, required = false,
                                 default = nil)
  if valid_774783 != nil:
    section.add "X-Amz-Credential", valid_774783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774784: Call_GetModifyOptionGroup_774768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774784.validator(path, query, header, formData, body)
  let scheme = call_774784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774784.url(scheme.get, call_774784.host, call_774784.base,
                         call_774784.route, valid.getOrDefault("path"))
  result = hook(call_774784, url, valid)

proc call*(call_774785: Call_GetModifyOptionGroup_774768; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-01-10"; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil): Recallable =
  ## getModifyOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionsToRemove: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  var query_774786 = newJObject()
  add(query_774786, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_774786.add "OptionsToRemove", OptionsToRemove
  add(query_774786, "Action", newJString(Action))
  add(query_774786, "Version", newJString(Version))
  add(query_774786, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_774786.add "OptionsToInclude", OptionsToInclude
  result = call_774785.call(nil, query_774786, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_774768(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_774769, base: "/",
    url: url_GetModifyOptionGroup_774770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_774825 = ref object of OpenApiRestCall_772581
proc url_PostPromoteReadReplica_774827(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPromoteReadReplica_774826(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774828 = query.getOrDefault("Action")
  valid_774828 = validateParameter(valid_774828, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_774828 != nil:
    section.add "Action", valid_774828
  var valid_774829 = query.getOrDefault("Version")
  valid_774829 = validateParameter(valid_774829, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774829 != nil:
    section.add "Version", valid_774829
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774830 = header.getOrDefault("X-Amz-Date")
  valid_774830 = validateParameter(valid_774830, JString, required = false,
                                 default = nil)
  if valid_774830 != nil:
    section.add "X-Amz-Date", valid_774830
  var valid_774831 = header.getOrDefault("X-Amz-Security-Token")
  valid_774831 = validateParameter(valid_774831, JString, required = false,
                                 default = nil)
  if valid_774831 != nil:
    section.add "X-Amz-Security-Token", valid_774831
  var valid_774832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774832 = validateParameter(valid_774832, JString, required = false,
                                 default = nil)
  if valid_774832 != nil:
    section.add "X-Amz-Content-Sha256", valid_774832
  var valid_774833 = header.getOrDefault("X-Amz-Algorithm")
  valid_774833 = validateParameter(valid_774833, JString, required = false,
                                 default = nil)
  if valid_774833 != nil:
    section.add "X-Amz-Algorithm", valid_774833
  var valid_774834 = header.getOrDefault("X-Amz-Signature")
  valid_774834 = validateParameter(valid_774834, JString, required = false,
                                 default = nil)
  if valid_774834 != nil:
    section.add "X-Amz-Signature", valid_774834
  var valid_774835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774835 = validateParameter(valid_774835, JString, required = false,
                                 default = nil)
  if valid_774835 != nil:
    section.add "X-Amz-SignedHeaders", valid_774835
  var valid_774836 = header.getOrDefault("X-Amz-Credential")
  valid_774836 = validateParameter(valid_774836, JString, required = false,
                                 default = nil)
  if valid_774836 != nil:
    section.add "X-Amz-Credential", valid_774836
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774837 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774837 = validateParameter(valid_774837, JString, required = true,
                                 default = nil)
  if valid_774837 != nil:
    section.add "DBInstanceIdentifier", valid_774837
  var valid_774838 = formData.getOrDefault("BackupRetentionPeriod")
  valid_774838 = validateParameter(valid_774838, JInt, required = false, default = nil)
  if valid_774838 != nil:
    section.add "BackupRetentionPeriod", valid_774838
  var valid_774839 = formData.getOrDefault("PreferredBackupWindow")
  valid_774839 = validateParameter(valid_774839, JString, required = false,
                                 default = nil)
  if valid_774839 != nil:
    section.add "PreferredBackupWindow", valid_774839
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774840: Call_PostPromoteReadReplica_774825; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774840.validator(path, query, header, formData, body)
  let scheme = call_774840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774840.url(scheme.get, call_774840.host, call_774840.base,
                         call_774840.route, valid.getOrDefault("path"))
  result = hook(call_774840, url, valid)

proc call*(call_774841: Call_PostPromoteReadReplica_774825;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_774842 = newJObject()
  var formData_774843 = newJObject()
  add(formData_774843, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774843, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_774842, "Action", newJString(Action))
  add(formData_774843, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_774842, "Version", newJString(Version))
  result = call_774841.call(nil, query_774842, nil, formData_774843, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_774825(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_774826, base: "/",
    url: url_PostPromoteReadReplica_774827, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_774807 = ref object of OpenApiRestCall_772581
proc url_GetPromoteReadReplica_774809(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPromoteReadReplica_774808(path: JsonNode; query: JsonNode;
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
  var valid_774810 = query.getOrDefault("BackupRetentionPeriod")
  valid_774810 = validateParameter(valid_774810, JInt, required = false, default = nil)
  if valid_774810 != nil:
    section.add "BackupRetentionPeriod", valid_774810
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774811 = query.getOrDefault("Action")
  valid_774811 = validateParameter(valid_774811, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_774811 != nil:
    section.add "Action", valid_774811
  var valid_774812 = query.getOrDefault("PreferredBackupWindow")
  valid_774812 = validateParameter(valid_774812, JString, required = false,
                                 default = nil)
  if valid_774812 != nil:
    section.add "PreferredBackupWindow", valid_774812
  var valid_774813 = query.getOrDefault("Version")
  valid_774813 = validateParameter(valid_774813, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774813 != nil:
    section.add "Version", valid_774813
  var valid_774814 = query.getOrDefault("DBInstanceIdentifier")
  valid_774814 = validateParameter(valid_774814, JString, required = true,
                                 default = nil)
  if valid_774814 != nil:
    section.add "DBInstanceIdentifier", valid_774814
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774815 = header.getOrDefault("X-Amz-Date")
  valid_774815 = validateParameter(valid_774815, JString, required = false,
                                 default = nil)
  if valid_774815 != nil:
    section.add "X-Amz-Date", valid_774815
  var valid_774816 = header.getOrDefault("X-Amz-Security-Token")
  valid_774816 = validateParameter(valid_774816, JString, required = false,
                                 default = nil)
  if valid_774816 != nil:
    section.add "X-Amz-Security-Token", valid_774816
  var valid_774817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774817 = validateParameter(valid_774817, JString, required = false,
                                 default = nil)
  if valid_774817 != nil:
    section.add "X-Amz-Content-Sha256", valid_774817
  var valid_774818 = header.getOrDefault("X-Amz-Algorithm")
  valid_774818 = validateParameter(valid_774818, JString, required = false,
                                 default = nil)
  if valid_774818 != nil:
    section.add "X-Amz-Algorithm", valid_774818
  var valid_774819 = header.getOrDefault("X-Amz-Signature")
  valid_774819 = validateParameter(valid_774819, JString, required = false,
                                 default = nil)
  if valid_774819 != nil:
    section.add "X-Amz-Signature", valid_774819
  var valid_774820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774820 = validateParameter(valid_774820, JString, required = false,
                                 default = nil)
  if valid_774820 != nil:
    section.add "X-Amz-SignedHeaders", valid_774820
  var valid_774821 = header.getOrDefault("X-Amz-Credential")
  valid_774821 = validateParameter(valid_774821, JString, required = false,
                                 default = nil)
  if valid_774821 != nil:
    section.add "X-Amz-Credential", valid_774821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774822: Call_GetPromoteReadReplica_774807; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774822.validator(path, query, header, formData, body)
  let scheme = call_774822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774822.url(scheme.get, call_774822.host, call_774822.base,
                         call_774822.route, valid.getOrDefault("path"))
  result = hook(call_774822, url, valid)

proc call*(call_774823: Call_GetPromoteReadReplica_774807;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_774824 = newJObject()
  add(query_774824, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_774824, "Action", newJString(Action))
  add(query_774824, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_774824, "Version", newJString(Version))
  add(query_774824, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_774823.call(nil, query_774824, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_774807(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_774808, base: "/",
    url: url_GetPromoteReadReplica_774809, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_774862 = ref object of OpenApiRestCall_772581
proc url_PostPurchaseReservedDBInstancesOffering_774864(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPurchaseReservedDBInstancesOffering_774863(path: JsonNode;
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
  var valid_774865 = query.getOrDefault("Action")
  valid_774865 = validateParameter(valid_774865, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_774865 != nil:
    section.add "Action", valid_774865
  var valid_774866 = query.getOrDefault("Version")
  valid_774866 = validateParameter(valid_774866, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774866 != nil:
    section.add "Version", valid_774866
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774867 = header.getOrDefault("X-Amz-Date")
  valid_774867 = validateParameter(valid_774867, JString, required = false,
                                 default = nil)
  if valid_774867 != nil:
    section.add "X-Amz-Date", valid_774867
  var valid_774868 = header.getOrDefault("X-Amz-Security-Token")
  valid_774868 = validateParameter(valid_774868, JString, required = false,
                                 default = nil)
  if valid_774868 != nil:
    section.add "X-Amz-Security-Token", valid_774868
  var valid_774869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774869 = validateParameter(valid_774869, JString, required = false,
                                 default = nil)
  if valid_774869 != nil:
    section.add "X-Amz-Content-Sha256", valid_774869
  var valid_774870 = header.getOrDefault("X-Amz-Algorithm")
  valid_774870 = validateParameter(valid_774870, JString, required = false,
                                 default = nil)
  if valid_774870 != nil:
    section.add "X-Amz-Algorithm", valid_774870
  var valid_774871 = header.getOrDefault("X-Amz-Signature")
  valid_774871 = validateParameter(valid_774871, JString, required = false,
                                 default = nil)
  if valid_774871 != nil:
    section.add "X-Amz-Signature", valid_774871
  var valid_774872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774872 = validateParameter(valid_774872, JString, required = false,
                                 default = nil)
  if valid_774872 != nil:
    section.add "X-Amz-SignedHeaders", valid_774872
  var valid_774873 = header.getOrDefault("X-Amz-Credential")
  valid_774873 = validateParameter(valid_774873, JString, required = false,
                                 default = nil)
  if valid_774873 != nil:
    section.add "X-Amz-Credential", valid_774873
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_774874 = formData.getOrDefault("ReservedDBInstanceId")
  valid_774874 = validateParameter(valid_774874, JString, required = false,
                                 default = nil)
  if valid_774874 != nil:
    section.add "ReservedDBInstanceId", valid_774874
  var valid_774875 = formData.getOrDefault("DBInstanceCount")
  valid_774875 = validateParameter(valid_774875, JInt, required = false, default = nil)
  if valid_774875 != nil:
    section.add "DBInstanceCount", valid_774875
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_774876 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774876 = validateParameter(valid_774876, JString, required = true,
                                 default = nil)
  if valid_774876 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774876
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774877: Call_PostPurchaseReservedDBInstancesOffering_774862;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774877.validator(path, query, header, formData, body)
  let scheme = call_774877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774877.url(scheme.get, call_774877.host, call_774877.base,
                         call_774877.route, valid.getOrDefault("path"))
  result = hook(call_774877, url, valid)

proc call*(call_774878: Call_PostPurchaseReservedDBInstancesOffering_774862;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = ""; DBInstanceCount: int = 0;
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-01-10"): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   DBInstanceCount: int
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_774879 = newJObject()
  var formData_774880 = newJObject()
  add(formData_774880, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_774880, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_774879, "Action", newJString(Action))
  add(formData_774880, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774879, "Version", newJString(Version))
  result = call_774878.call(nil, query_774879, nil, formData_774880, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_774862(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_774863, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_774864,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_774844 = ref object of OpenApiRestCall_772581
proc url_GetPurchaseReservedDBInstancesOffering_774846(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPurchaseReservedDBInstancesOffering_774845(path: JsonNode;
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
  var valid_774847 = query.getOrDefault("DBInstanceCount")
  valid_774847 = validateParameter(valid_774847, JInt, required = false, default = nil)
  if valid_774847 != nil:
    section.add "DBInstanceCount", valid_774847
  var valid_774848 = query.getOrDefault("ReservedDBInstanceId")
  valid_774848 = validateParameter(valid_774848, JString, required = false,
                                 default = nil)
  if valid_774848 != nil:
    section.add "ReservedDBInstanceId", valid_774848
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_774849 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774849 = validateParameter(valid_774849, JString, required = true,
                                 default = nil)
  if valid_774849 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774849
  var valid_774850 = query.getOrDefault("Action")
  valid_774850 = validateParameter(valid_774850, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_774850 != nil:
    section.add "Action", valid_774850
  var valid_774851 = query.getOrDefault("Version")
  valid_774851 = validateParameter(valid_774851, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774851 != nil:
    section.add "Version", valid_774851
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774852 = header.getOrDefault("X-Amz-Date")
  valid_774852 = validateParameter(valid_774852, JString, required = false,
                                 default = nil)
  if valid_774852 != nil:
    section.add "X-Amz-Date", valid_774852
  var valid_774853 = header.getOrDefault("X-Amz-Security-Token")
  valid_774853 = validateParameter(valid_774853, JString, required = false,
                                 default = nil)
  if valid_774853 != nil:
    section.add "X-Amz-Security-Token", valid_774853
  var valid_774854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774854 = validateParameter(valid_774854, JString, required = false,
                                 default = nil)
  if valid_774854 != nil:
    section.add "X-Amz-Content-Sha256", valid_774854
  var valid_774855 = header.getOrDefault("X-Amz-Algorithm")
  valid_774855 = validateParameter(valid_774855, JString, required = false,
                                 default = nil)
  if valid_774855 != nil:
    section.add "X-Amz-Algorithm", valid_774855
  var valid_774856 = header.getOrDefault("X-Amz-Signature")
  valid_774856 = validateParameter(valid_774856, JString, required = false,
                                 default = nil)
  if valid_774856 != nil:
    section.add "X-Amz-Signature", valid_774856
  var valid_774857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774857 = validateParameter(valid_774857, JString, required = false,
                                 default = nil)
  if valid_774857 != nil:
    section.add "X-Amz-SignedHeaders", valid_774857
  var valid_774858 = header.getOrDefault("X-Amz-Credential")
  valid_774858 = validateParameter(valid_774858, JString, required = false,
                                 default = nil)
  if valid_774858 != nil:
    section.add "X-Amz-Credential", valid_774858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774859: Call_GetPurchaseReservedDBInstancesOffering_774844;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774859.validator(path, query, header, formData, body)
  let scheme = call_774859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774859.url(scheme.get, call_774859.host, call_774859.base,
                         call_774859.route, valid.getOrDefault("path"))
  result = hook(call_774859, url, valid)

proc call*(call_774860: Call_GetPurchaseReservedDBInstancesOffering_774844;
          ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-01-10"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774861 = newJObject()
  add(query_774861, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_774861, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_774861, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774861, "Action", newJString(Action))
  add(query_774861, "Version", newJString(Version))
  result = call_774860.call(nil, query_774861, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_774844(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_774845, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_774846,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_774898 = ref object of OpenApiRestCall_772581
proc url_PostRebootDBInstance_774900(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebootDBInstance_774899(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774901 = query.getOrDefault("Action")
  valid_774901 = validateParameter(valid_774901, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_774901 != nil:
    section.add "Action", valid_774901
  var valid_774902 = query.getOrDefault("Version")
  valid_774902 = validateParameter(valid_774902, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774902 != nil:
    section.add "Version", valid_774902
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774903 = header.getOrDefault("X-Amz-Date")
  valid_774903 = validateParameter(valid_774903, JString, required = false,
                                 default = nil)
  if valid_774903 != nil:
    section.add "X-Amz-Date", valid_774903
  var valid_774904 = header.getOrDefault("X-Amz-Security-Token")
  valid_774904 = validateParameter(valid_774904, JString, required = false,
                                 default = nil)
  if valid_774904 != nil:
    section.add "X-Amz-Security-Token", valid_774904
  var valid_774905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774905 = validateParameter(valid_774905, JString, required = false,
                                 default = nil)
  if valid_774905 != nil:
    section.add "X-Amz-Content-Sha256", valid_774905
  var valid_774906 = header.getOrDefault("X-Amz-Algorithm")
  valid_774906 = validateParameter(valid_774906, JString, required = false,
                                 default = nil)
  if valid_774906 != nil:
    section.add "X-Amz-Algorithm", valid_774906
  var valid_774907 = header.getOrDefault("X-Amz-Signature")
  valid_774907 = validateParameter(valid_774907, JString, required = false,
                                 default = nil)
  if valid_774907 != nil:
    section.add "X-Amz-Signature", valid_774907
  var valid_774908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774908 = validateParameter(valid_774908, JString, required = false,
                                 default = nil)
  if valid_774908 != nil:
    section.add "X-Amz-SignedHeaders", valid_774908
  var valid_774909 = header.getOrDefault("X-Amz-Credential")
  valid_774909 = validateParameter(valid_774909, JString, required = false,
                                 default = nil)
  if valid_774909 != nil:
    section.add "X-Amz-Credential", valid_774909
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774910 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774910 = validateParameter(valid_774910, JString, required = true,
                                 default = nil)
  if valid_774910 != nil:
    section.add "DBInstanceIdentifier", valid_774910
  var valid_774911 = formData.getOrDefault("ForceFailover")
  valid_774911 = validateParameter(valid_774911, JBool, required = false, default = nil)
  if valid_774911 != nil:
    section.add "ForceFailover", valid_774911
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774912: Call_PostRebootDBInstance_774898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774912.validator(path, query, header, formData, body)
  let scheme = call_774912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774912.url(scheme.get, call_774912.host, call_774912.base,
                         call_774912.route, valid.getOrDefault("path"))
  result = hook(call_774912, url, valid)

proc call*(call_774913: Call_PostRebootDBInstance_774898;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-01-10"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_774914 = newJObject()
  var formData_774915 = newJObject()
  add(formData_774915, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_774914, "Action", newJString(Action))
  add(formData_774915, "ForceFailover", newJBool(ForceFailover))
  add(query_774914, "Version", newJString(Version))
  result = call_774913.call(nil, query_774914, nil, formData_774915, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_774898(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_774899, base: "/",
    url: url_PostRebootDBInstance_774900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_774881 = ref object of OpenApiRestCall_772581
proc url_GetRebootDBInstance_774883(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebootDBInstance_774882(path: JsonNode; query: JsonNode;
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
  var valid_774884 = query.getOrDefault("Action")
  valid_774884 = validateParameter(valid_774884, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_774884 != nil:
    section.add "Action", valid_774884
  var valid_774885 = query.getOrDefault("ForceFailover")
  valid_774885 = validateParameter(valid_774885, JBool, required = false, default = nil)
  if valid_774885 != nil:
    section.add "ForceFailover", valid_774885
  var valid_774886 = query.getOrDefault("Version")
  valid_774886 = validateParameter(valid_774886, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774886 != nil:
    section.add "Version", valid_774886
  var valid_774887 = query.getOrDefault("DBInstanceIdentifier")
  valid_774887 = validateParameter(valid_774887, JString, required = true,
                                 default = nil)
  if valid_774887 != nil:
    section.add "DBInstanceIdentifier", valid_774887
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774888 = header.getOrDefault("X-Amz-Date")
  valid_774888 = validateParameter(valid_774888, JString, required = false,
                                 default = nil)
  if valid_774888 != nil:
    section.add "X-Amz-Date", valid_774888
  var valid_774889 = header.getOrDefault("X-Amz-Security-Token")
  valid_774889 = validateParameter(valid_774889, JString, required = false,
                                 default = nil)
  if valid_774889 != nil:
    section.add "X-Amz-Security-Token", valid_774889
  var valid_774890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774890 = validateParameter(valid_774890, JString, required = false,
                                 default = nil)
  if valid_774890 != nil:
    section.add "X-Amz-Content-Sha256", valid_774890
  var valid_774891 = header.getOrDefault("X-Amz-Algorithm")
  valid_774891 = validateParameter(valid_774891, JString, required = false,
                                 default = nil)
  if valid_774891 != nil:
    section.add "X-Amz-Algorithm", valid_774891
  var valid_774892 = header.getOrDefault("X-Amz-Signature")
  valid_774892 = validateParameter(valid_774892, JString, required = false,
                                 default = nil)
  if valid_774892 != nil:
    section.add "X-Amz-Signature", valid_774892
  var valid_774893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774893 = validateParameter(valid_774893, JString, required = false,
                                 default = nil)
  if valid_774893 != nil:
    section.add "X-Amz-SignedHeaders", valid_774893
  var valid_774894 = header.getOrDefault("X-Amz-Credential")
  valid_774894 = validateParameter(valid_774894, JString, required = false,
                                 default = nil)
  if valid_774894 != nil:
    section.add "X-Amz-Credential", valid_774894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774895: Call_GetRebootDBInstance_774881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774895.validator(path, query, header, formData, body)
  let scheme = call_774895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774895.url(scheme.get, call_774895.host, call_774895.base,
                         call_774895.route, valid.getOrDefault("path"))
  result = hook(call_774895, url, valid)

proc call*(call_774896: Call_GetRebootDBInstance_774881;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-01-10"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_774897 = newJObject()
  add(query_774897, "Action", newJString(Action))
  add(query_774897, "ForceFailover", newJBool(ForceFailover))
  add(query_774897, "Version", newJString(Version))
  add(query_774897, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_774896.call(nil, query_774897, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_774881(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_774882, base: "/",
    url: url_GetRebootDBInstance_774883, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_774933 = ref object of OpenApiRestCall_772581
proc url_PostRemoveSourceIdentifierFromSubscription_774935(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_774934(path: JsonNode;
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
  var valid_774936 = query.getOrDefault("Action")
  valid_774936 = validateParameter(valid_774936, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_774936 != nil:
    section.add "Action", valid_774936
  var valid_774937 = query.getOrDefault("Version")
  valid_774937 = validateParameter(valid_774937, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774937 != nil:
    section.add "Version", valid_774937
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774938 = header.getOrDefault("X-Amz-Date")
  valid_774938 = validateParameter(valid_774938, JString, required = false,
                                 default = nil)
  if valid_774938 != nil:
    section.add "X-Amz-Date", valid_774938
  var valid_774939 = header.getOrDefault("X-Amz-Security-Token")
  valid_774939 = validateParameter(valid_774939, JString, required = false,
                                 default = nil)
  if valid_774939 != nil:
    section.add "X-Amz-Security-Token", valid_774939
  var valid_774940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774940 = validateParameter(valid_774940, JString, required = false,
                                 default = nil)
  if valid_774940 != nil:
    section.add "X-Amz-Content-Sha256", valid_774940
  var valid_774941 = header.getOrDefault("X-Amz-Algorithm")
  valid_774941 = validateParameter(valid_774941, JString, required = false,
                                 default = nil)
  if valid_774941 != nil:
    section.add "X-Amz-Algorithm", valid_774941
  var valid_774942 = header.getOrDefault("X-Amz-Signature")
  valid_774942 = validateParameter(valid_774942, JString, required = false,
                                 default = nil)
  if valid_774942 != nil:
    section.add "X-Amz-Signature", valid_774942
  var valid_774943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774943 = validateParameter(valid_774943, JString, required = false,
                                 default = nil)
  if valid_774943 != nil:
    section.add "X-Amz-SignedHeaders", valid_774943
  var valid_774944 = header.getOrDefault("X-Amz-Credential")
  valid_774944 = validateParameter(valid_774944, JString, required = false,
                                 default = nil)
  if valid_774944 != nil:
    section.add "X-Amz-Credential", valid_774944
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_774945 = formData.getOrDefault("SourceIdentifier")
  valid_774945 = validateParameter(valid_774945, JString, required = true,
                                 default = nil)
  if valid_774945 != nil:
    section.add "SourceIdentifier", valid_774945
  var valid_774946 = formData.getOrDefault("SubscriptionName")
  valid_774946 = validateParameter(valid_774946, JString, required = true,
                                 default = nil)
  if valid_774946 != nil:
    section.add "SubscriptionName", valid_774946
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774947: Call_PostRemoveSourceIdentifierFromSubscription_774933;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774947.validator(path, query, header, formData, body)
  let scheme = call_774947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774947.url(scheme.get, call_774947.host, call_774947.base,
                         call_774947.route, valid.getOrDefault("path"))
  result = hook(call_774947, url, valid)

proc call*(call_774948: Call_PostRemoveSourceIdentifierFromSubscription_774933;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774949 = newJObject()
  var formData_774950 = newJObject()
  add(formData_774950, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_774950, "SubscriptionName", newJString(SubscriptionName))
  add(query_774949, "Action", newJString(Action))
  add(query_774949, "Version", newJString(Version))
  result = call_774948.call(nil, query_774949, nil, formData_774950, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_774933(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_774934,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_774935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_774916 = ref object of OpenApiRestCall_772581
proc url_GetRemoveSourceIdentifierFromSubscription_774918(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_774917(path: JsonNode;
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
  var valid_774919 = query.getOrDefault("Action")
  valid_774919 = validateParameter(valid_774919, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_774919 != nil:
    section.add "Action", valid_774919
  var valid_774920 = query.getOrDefault("SourceIdentifier")
  valid_774920 = validateParameter(valid_774920, JString, required = true,
                                 default = nil)
  if valid_774920 != nil:
    section.add "SourceIdentifier", valid_774920
  var valid_774921 = query.getOrDefault("SubscriptionName")
  valid_774921 = validateParameter(valid_774921, JString, required = true,
                                 default = nil)
  if valid_774921 != nil:
    section.add "SubscriptionName", valid_774921
  var valid_774922 = query.getOrDefault("Version")
  valid_774922 = validateParameter(valid_774922, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774922 != nil:
    section.add "Version", valid_774922
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774923 = header.getOrDefault("X-Amz-Date")
  valid_774923 = validateParameter(valid_774923, JString, required = false,
                                 default = nil)
  if valid_774923 != nil:
    section.add "X-Amz-Date", valid_774923
  var valid_774924 = header.getOrDefault("X-Amz-Security-Token")
  valid_774924 = validateParameter(valid_774924, JString, required = false,
                                 default = nil)
  if valid_774924 != nil:
    section.add "X-Amz-Security-Token", valid_774924
  var valid_774925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774925 = validateParameter(valid_774925, JString, required = false,
                                 default = nil)
  if valid_774925 != nil:
    section.add "X-Amz-Content-Sha256", valid_774925
  var valid_774926 = header.getOrDefault("X-Amz-Algorithm")
  valid_774926 = validateParameter(valid_774926, JString, required = false,
                                 default = nil)
  if valid_774926 != nil:
    section.add "X-Amz-Algorithm", valid_774926
  var valid_774927 = header.getOrDefault("X-Amz-Signature")
  valid_774927 = validateParameter(valid_774927, JString, required = false,
                                 default = nil)
  if valid_774927 != nil:
    section.add "X-Amz-Signature", valid_774927
  var valid_774928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774928 = validateParameter(valid_774928, JString, required = false,
                                 default = nil)
  if valid_774928 != nil:
    section.add "X-Amz-SignedHeaders", valid_774928
  var valid_774929 = header.getOrDefault("X-Amz-Credential")
  valid_774929 = validateParameter(valid_774929, JString, required = false,
                                 default = nil)
  if valid_774929 != nil:
    section.add "X-Amz-Credential", valid_774929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774930: Call_GetRemoveSourceIdentifierFromSubscription_774916;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774930.validator(path, query, header, formData, body)
  let scheme = call_774930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774930.url(scheme.get, call_774930.host, call_774930.base,
                         call_774930.route, valid.getOrDefault("path"))
  result = hook(call_774930, url, valid)

proc call*(call_774931: Call_GetRemoveSourceIdentifierFromSubscription_774916;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_774932 = newJObject()
  add(query_774932, "Action", newJString(Action))
  add(query_774932, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_774932, "SubscriptionName", newJString(SubscriptionName))
  add(query_774932, "Version", newJString(Version))
  result = call_774931.call(nil, query_774932, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_774916(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_774917,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_774918,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_774968 = ref object of OpenApiRestCall_772581
proc url_PostRemoveTagsFromResource_774970(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTagsFromResource_774969(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774971 = query.getOrDefault("Action")
  valid_774971 = validateParameter(valid_774971, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_774971 != nil:
    section.add "Action", valid_774971
  var valid_774972 = query.getOrDefault("Version")
  valid_774972 = validateParameter(valid_774972, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774972 != nil:
    section.add "Version", valid_774972
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774973 = header.getOrDefault("X-Amz-Date")
  valid_774973 = validateParameter(valid_774973, JString, required = false,
                                 default = nil)
  if valid_774973 != nil:
    section.add "X-Amz-Date", valid_774973
  var valid_774974 = header.getOrDefault("X-Amz-Security-Token")
  valid_774974 = validateParameter(valid_774974, JString, required = false,
                                 default = nil)
  if valid_774974 != nil:
    section.add "X-Amz-Security-Token", valid_774974
  var valid_774975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774975 = validateParameter(valid_774975, JString, required = false,
                                 default = nil)
  if valid_774975 != nil:
    section.add "X-Amz-Content-Sha256", valid_774975
  var valid_774976 = header.getOrDefault("X-Amz-Algorithm")
  valid_774976 = validateParameter(valid_774976, JString, required = false,
                                 default = nil)
  if valid_774976 != nil:
    section.add "X-Amz-Algorithm", valid_774976
  var valid_774977 = header.getOrDefault("X-Amz-Signature")
  valid_774977 = validateParameter(valid_774977, JString, required = false,
                                 default = nil)
  if valid_774977 != nil:
    section.add "X-Amz-Signature", valid_774977
  var valid_774978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774978 = validateParameter(valid_774978, JString, required = false,
                                 default = nil)
  if valid_774978 != nil:
    section.add "X-Amz-SignedHeaders", valid_774978
  var valid_774979 = header.getOrDefault("X-Amz-Credential")
  valid_774979 = validateParameter(valid_774979, JString, required = false,
                                 default = nil)
  if valid_774979 != nil:
    section.add "X-Amz-Credential", valid_774979
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_774980 = formData.getOrDefault("TagKeys")
  valid_774980 = validateParameter(valid_774980, JArray, required = true, default = nil)
  if valid_774980 != nil:
    section.add "TagKeys", valid_774980
  var valid_774981 = formData.getOrDefault("ResourceName")
  valid_774981 = validateParameter(valid_774981, JString, required = true,
                                 default = nil)
  if valid_774981 != nil:
    section.add "ResourceName", valid_774981
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774982: Call_PostRemoveTagsFromResource_774968; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774982.validator(path, query, header, formData, body)
  let scheme = call_774982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774982.url(scheme.get, call_774982.host, call_774982.base,
                         call_774982.route, valid.getOrDefault("path"))
  result = hook(call_774982, url, valid)

proc call*(call_774983: Call_PostRemoveTagsFromResource_774968; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_774984 = newJObject()
  var formData_774985 = newJObject()
  add(query_774984, "Action", newJString(Action))
  if TagKeys != nil:
    formData_774985.add "TagKeys", TagKeys
  add(formData_774985, "ResourceName", newJString(ResourceName))
  add(query_774984, "Version", newJString(Version))
  result = call_774983.call(nil, query_774984, nil, formData_774985, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_774968(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_774969, base: "/",
    url: url_PostRemoveTagsFromResource_774970,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_774951 = ref object of OpenApiRestCall_772581
proc url_GetRemoveTagsFromResource_774953(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTagsFromResource_774952(path: JsonNode; query: JsonNode;
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
  var valid_774954 = query.getOrDefault("ResourceName")
  valid_774954 = validateParameter(valid_774954, JString, required = true,
                                 default = nil)
  if valid_774954 != nil:
    section.add "ResourceName", valid_774954
  var valid_774955 = query.getOrDefault("Action")
  valid_774955 = validateParameter(valid_774955, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_774955 != nil:
    section.add "Action", valid_774955
  var valid_774956 = query.getOrDefault("TagKeys")
  valid_774956 = validateParameter(valid_774956, JArray, required = true, default = nil)
  if valid_774956 != nil:
    section.add "TagKeys", valid_774956
  var valid_774957 = query.getOrDefault("Version")
  valid_774957 = validateParameter(valid_774957, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774957 != nil:
    section.add "Version", valid_774957
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774958 = header.getOrDefault("X-Amz-Date")
  valid_774958 = validateParameter(valid_774958, JString, required = false,
                                 default = nil)
  if valid_774958 != nil:
    section.add "X-Amz-Date", valid_774958
  var valid_774959 = header.getOrDefault("X-Amz-Security-Token")
  valid_774959 = validateParameter(valid_774959, JString, required = false,
                                 default = nil)
  if valid_774959 != nil:
    section.add "X-Amz-Security-Token", valid_774959
  var valid_774960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774960 = validateParameter(valid_774960, JString, required = false,
                                 default = nil)
  if valid_774960 != nil:
    section.add "X-Amz-Content-Sha256", valid_774960
  var valid_774961 = header.getOrDefault("X-Amz-Algorithm")
  valid_774961 = validateParameter(valid_774961, JString, required = false,
                                 default = nil)
  if valid_774961 != nil:
    section.add "X-Amz-Algorithm", valid_774961
  var valid_774962 = header.getOrDefault("X-Amz-Signature")
  valid_774962 = validateParameter(valid_774962, JString, required = false,
                                 default = nil)
  if valid_774962 != nil:
    section.add "X-Amz-Signature", valid_774962
  var valid_774963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774963 = validateParameter(valid_774963, JString, required = false,
                                 default = nil)
  if valid_774963 != nil:
    section.add "X-Amz-SignedHeaders", valid_774963
  var valid_774964 = header.getOrDefault("X-Amz-Credential")
  valid_774964 = validateParameter(valid_774964, JString, required = false,
                                 default = nil)
  if valid_774964 != nil:
    section.add "X-Amz-Credential", valid_774964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774965: Call_GetRemoveTagsFromResource_774951; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774965.validator(path, query, header, formData, body)
  let scheme = call_774965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774965.url(scheme.get, call_774965.host, call_774965.base,
                         call_774965.route, valid.getOrDefault("path"))
  result = hook(call_774965, url, valid)

proc call*(call_774966: Call_GetRemoveTagsFromResource_774951;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-01-10"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_774967 = newJObject()
  add(query_774967, "ResourceName", newJString(ResourceName))
  add(query_774967, "Action", newJString(Action))
  if TagKeys != nil:
    query_774967.add "TagKeys", TagKeys
  add(query_774967, "Version", newJString(Version))
  result = call_774966.call(nil, query_774967, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_774951(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_774952, base: "/",
    url: url_GetRemoveTagsFromResource_774953,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_775004 = ref object of OpenApiRestCall_772581
proc url_PostResetDBParameterGroup_775006(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostResetDBParameterGroup_775005(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775007 = query.getOrDefault("Action")
  valid_775007 = validateParameter(valid_775007, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_775007 != nil:
    section.add "Action", valid_775007
  var valid_775008 = query.getOrDefault("Version")
  valid_775008 = validateParameter(valid_775008, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_775008 != nil:
    section.add "Version", valid_775008
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775009 = header.getOrDefault("X-Amz-Date")
  valid_775009 = validateParameter(valid_775009, JString, required = false,
                                 default = nil)
  if valid_775009 != nil:
    section.add "X-Amz-Date", valid_775009
  var valid_775010 = header.getOrDefault("X-Amz-Security-Token")
  valid_775010 = validateParameter(valid_775010, JString, required = false,
                                 default = nil)
  if valid_775010 != nil:
    section.add "X-Amz-Security-Token", valid_775010
  var valid_775011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775011 = validateParameter(valid_775011, JString, required = false,
                                 default = nil)
  if valid_775011 != nil:
    section.add "X-Amz-Content-Sha256", valid_775011
  var valid_775012 = header.getOrDefault("X-Amz-Algorithm")
  valid_775012 = validateParameter(valid_775012, JString, required = false,
                                 default = nil)
  if valid_775012 != nil:
    section.add "X-Amz-Algorithm", valid_775012
  var valid_775013 = header.getOrDefault("X-Amz-Signature")
  valid_775013 = validateParameter(valid_775013, JString, required = false,
                                 default = nil)
  if valid_775013 != nil:
    section.add "X-Amz-Signature", valid_775013
  var valid_775014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775014 = validateParameter(valid_775014, JString, required = false,
                                 default = nil)
  if valid_775014 != nil:
    section.add "X-Amz-SignedHeaders", valid_775014
  var valid_775015 = header.getOrDefault("X-Amz-Credential")
  valid_775015 = validateParameter(valid_775015, JString, required = false,
                                 default = nil)
  if valid_775015 != nil:
    section.add "X-Amz-Credential", valid_775015
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_775016 = formData.getOrDefault("DBParameterGroupName")
  valid_775016 = validateParameter(valid_775016, JString, required = true,
                                 default = nil)
  if valid_775016 != nil:
    section.add "DBParameterGroupName", valid_775016
  var valid_775017 = formData.getOrDefault("Parameters")
  valid_775017 = validateParameter(valid_775017, JArray, required = false,
                                 default = nil)
  if valid_775017 != nil:
    section.add "Parameters", valid_775017
  var valid_775018 = formData.getOrDefault("ResetAllParameters")
  valid_775018 = validateParameter(valid_775018, JBool, required = false, default = nil)
  if valid_775018 != nil:
    section.add "ResetAllParameters", valid_775018
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775019: Call_PostResetDBParameterGroup_775004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775019.validator(path, query, header, formData, body)
  let scheme = call_775019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775019.url(scheme.get, call_775019.host, call_775019.base,
                         call_775019.route, valid.getOrDefault("path"))
  result = hook(call_775019, url, valid)

proc call*(call_775020: Call_PostResetDBParameterGroup_775004;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-01-10"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_775021 = newJObject()
  var formData_775022 = newJObject()
  add(formData_775022, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_775022.add "Parameters", Parameters
  add(query_775021, "Action", newJString(Action))
  add(formData_775022, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_775021, "Version", newJString(Version))
  result = call_775020.call(nil, query_775021, nil, formData_775022, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_775004(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_775005, base: "/",
    url: url_PostResetDBParameterGroup_775006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_774986 = ref object of OpenApiRestCall_772581
proc url_GetResetDBParameterGroup_774988(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResetDBParameterGroup_774987(path: JsonNode; query: JsonNode;
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
  var valid_774989 = query.getOrDefault("DBParameterGroupName")
  valid_774989 = validateParameter(valid_774989, JString, required = true,
                                 default = nil)
  if valid_774989 != nil:
    section.add "DBParameterGroupName", valid_774989
  var valid_774990 = query.getOrDefault("Parameters")
  valid_774990 = validateParameter(valid_774990, JArray, required = false,
                                 default = nil)
  if valid_774990 != nil:
    section.add "Parameters", valid_774990
  var valid_774991 = query.getOrDefault("Action")
  valid_774991 = validateParameter(valid_774991, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_774991 != nil:
    section.add "Action", valid_774991
  var valid_774992 = query.getOrDefault("ResetAllParameters")
  valid_774992 = validateParameter(valid_774992, JBool, required = false, default = nil)
  if valid_774992 != nil:
    section.add "ResetAllParameters", valid_774992
  var valid_774993 = query.getOrDefault("Version")
  valid_774993 = validateParameter(valid_774993, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_774993 != nil:
    section.add "Version", valid_774993
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774994 = header.getOrDefault("X-Amz-Date")
  valid_774994 = validateParameter(valid_774994, JString, required = false,
                                 default = nil)
  if valid_774994 != nil:
    section.add "X-Amz-Date", valid_774994
  var valid_774995 = header.getOrDefault("X-Amz-Security-Token")
  valid_774995 = validateParameter(valid_774995, JString, required = false,
                                 default = nil)
  if valid_774995 != nil:
    section.add "X-Amz-Security-Token", valid_774995
  var valid_774996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774996 = validateParameter(valid_774996, JString, required = false,
                                 default = nil)
  if valid_774996 != nil:
    section.add "X-Amz-Content-Sha256", valid_774996
  var valid_774997 = header.getOrDefault("X-Amz-Algorithm")
  valid_774997 = validateParameter(valid_774997, JString, required = false,
                                 default = nil)
  if valid_774997 != nil:
    section.add "X-Amz-Algorithm", valid_774997
  var valid_774998 = header.getOrDefault("X-Amz-Signature")
  valid_774998 = validateParameter(valid_774998, JString, required = false,
                                 default = nil)
  if valid_774998 != nil:
    section.add "X-Amz-Signature", valid_774998
  var valid_774999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774999 = validateParameter(valid_774999, JString, required = false,
                                 default = nil)
  if valid_774999 != nil:
    section.add "X-Amz-SignedHeaders", valid_774999
  var valid_775000 = header.getOrDefault("X-Amz-Credential")
  valid_775000 = validateParameter(valid_775000, JString, required = false,
                                 default = nil)
  if valid_775000 != nil:
    section.add "X-Amz-Credential", valid_775000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775001: Call_GetResetDBParameterGroup_774986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775001.validator(path, query, header, formData, body)
  let scheme = call_775001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775001.url(scheme.get, call_775001.host, call_775001.base,
                         call_775001.route, valid.getOrDefault("path"))
  result = hook(call_775001, url, valid)

proc call*(call_775002: Call_GetResetDBParameterGroup_774986;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-01-10"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_775003 = newJObject()
  add(query_775003, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_775003.add "Parameters", Parameters
  add(query_775003, "Action", newJString(Action))
  add(query_775003, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_775003, "Version", newJString(Version))
  result = call_775002.call(nil, query_775003, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_774986(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_774987, base: "/",
    url: url_GetResetDBParameterGroup_774988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_775052 = ref object of OpenApiRestCall_772581
proc url_PostRestoreDBInstanceFromDBSnapshot_775054(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_775053(path: JsonNode;
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
  var valid_775055 = query.getOrDefault("Action")
  valid_775055 = validateParameter(valid_775055, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_775055 != nil:
    section.add "Action", valid_775055
  var valid_775056 = query.getOrDefault("Version")
  valid_775056 = validateParameter(valid_775056, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_775056 != nil:
    section.add "Version", valid_775056
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775057 = header.getOrDefault("X-Amz-Date")
  valid_775057 = validateParameter(valid_775057, JString, required = false,
                                 default = nil)
  if valid_775057 != nil:
    section.add "X-Amz-Date", valid_775057
  var valid_775058 = header.getOrDefault("X-Amz-Security-Token")
  valid_775058 = validateParameter(valid_775058, JString, required = false,
                                 default = nil)
  if valid_775058 != nil:
    section.add "X-Amz-Security-Token", valid_775058
  var valid_775059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775059 = validateParameter(valid_775059, JString, required = false,
                                 default = nil)
  if valid_775059 != nil:
    section.add "X-Amz-Content-Sha256", valid_775059
  var valid_775060 = header.getOrDefault("X-Amz-Algorithm")
  valid_775060 = validateParameter(valid_775060, JString, required = false,
                                 default = nil)
  if valid_775060 != nil:
    section.add "X-Amz-Algorithm", valid_775060
  var valid_775061 = header.getOrDefault("X-Amz-Signature")
  valid_775061 = validateParameter(valid_775061, JString, required = false,
                                 default = nil)
  if valid_775061 != nil:
    section.add "X-Amz-Signature", valid_775061
  var valid_775062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775062 = validateParameter(valid_775062, JString, required = false,
                                 default = nil)
  if valid_775062 != nil:
    section.add "X-Amz-SignedHeaders", valid_775062
  var valid_775063 = header.getOrDefault("X-Amz-Credential")
  valid_775063 = validateParameter(valid_775063, JString, required = false,
                                 default = nil)
  if valid_775063 != nil:
    section.add "X-Amz-Credential", valid_775063
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
  var valid_775064 = formData.getOrDefault("Port")
  valid_775064 = validateParameter(valid_775064, JInt, required = false, default = nil)
  if valid_775064 != nil:
    section.add "Port", valid_775064
  var valid_775065 = formData.getOrDefault("Engine")
  valid_775065 = validateParameter(valid_775065, JString, required = false,
                                 default = nil)
  if valid_775065 != nil:
    section.add "Engine", valid_775065
  var valid_775066 = formData.getOrDefault("Iops")
  valid_775066 = validateParameter(valid_775066, JInt, required = false, default = nil)
  if valid_775066 != nil:
    section.add "Iops", valid_775066
  var valid_775067 = formData.getOrDefault("DBName")
  valid_775067 = validateParameter(valid_775067, JString, required = false,
                                 default = nil)
  if valid_775067 != nil:
    section.add "DBName", valid_775067
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_775068 = formData.getOrDefault("DBInstanceIdentifier")
  valid_775068 = validateParameter(valid_775068, JString, required = true,
                                 default = nil)
  if valid_775068 != nil:
    section.add "DBInstanceIdentifier", valid_775068
  var valid_775069 = formData.getOrDefault("OptionGroupName")
  valid_775069 = validateParameter(valid_775069, JString, required = false,
                                 default = nil)
  if valid_775069 != nil:
    section.add "OptionGroupName", valid_775069
  var valid_775070 = formData.getOrDefault("DBSubnetGroupName")
  valid_775070 = validateParameter(valid_775070, JString, required = false,
                                 default = nil)
  if valid_775070 != nil:
    section.add "DBSubnetGroupName", valid_775070
  var valid_775071 = formData.getOrDefault("AvailabilityZone")
  valid_775071 = validateParameter(valid_775071, JString, required = false,
                                 default = nil)
  if valid_775071 != nil:
    section.add "AvailabilityZone", valid_775071
  var valid_775072 = formData.getOrDefault("MultiAZ")
  valid_775072 = validateParameter(valid_775072, JBool, required = false, default = nil)
  if valid_775072 != nil:
    section.add "MultiAZ", valid_775072
  var valid_775073 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_775073 = validateParameter(valid_775073, JString, required = true,
                                 default = nil)
  if valid_775073 != nil:
    section.add "DBSnapshotIdentifier", valid_775073
  var valid_775074 = formData.getOrDefault("PubliclyAccessible")
  valid_775074 = validateParameter(valid_775074, JBool, required = false, default = nil)
  if valid_775074 != nil:
    section.add "PubliclyAccessible", valid_775074
  var valid_775075 = formData.getOrDefault("DBInstanceClass")
  valid_775075 = validateParameter(valid_775075, JString, required = false,
                                 default = nil)
  if valid_775075 != nil:
    section.add "DBInstanceClass", valid_775075
  var valid_775076 = formData.getOrDefault("LicenseModel")
  valid_775076 = validateParameter(valid_775076, JString, required = false,
                                 default = nil)
  if valid_775076 != nil:
    section.add "LicenseModel", valid_775076
  var valid_775077 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_775077 = validateParameter(valid_775077, JBool, required = false, default = nil)
  if valid_775077 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775077
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775078: Call_PostRestoreDBInstanceFromDBSnapshot_775052;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775078.validator(path, query, header, formData, body)
  let scheme = call_775078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775078.url(scheme.get, call_775078.host, call_775078.base,
                         call_775078.route, valid.getOrDefault("path"))
  result = hook(call_775078, url, valid)

proc call*(call_775079: Call_PostRestoreDBInstanceFromDBSnapshot_775052;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          Engine: string = ""; Iops: int = 0; DBName: string = "";
          OptionGroupName: string = ""; DBSubnetGroupName: string = "";
          AvailabilityZone: string = ""; MultiAZ: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          PubliclyAccessible: bool = false; DBInstanceClass: string = "";
          LicenseModel: string = ""; AutoMinorVersionUpgrade: bool = false;
          Version: string = "2013-01-10"): Recallable =
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
  var query_775080 = newJObject()
  var formData_775081 = newJObject()
  add(formData_775081, "Port", newJInt(Port))
  add(formData_775081, "Engine", newJString(Engine))
  add(formData_775081, "Iops", newJInt(Iops))
  add(formData_775081, "DBName", newJString(DBName))
  add(formData_775081, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_775081, "OptionGroupName", newJString(OptionGroupName))
  add(formData_775081, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_775081, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_775081, "MultiAZ", newJBool(MultiAZ))
  add(formData_775081, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_775080, "Action", newJString(Action))
  add(formData_775081, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_775081, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_775081, "LicenseModel", newJString(LicenseModel))
  add(formData_775081, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_775080, "Version", newJString(Version))
  result = call_775079.call(nil, query_775080, nil, formData_775081, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_775052(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_775053, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_775054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_775023 = ref object of OpenApiRestCall_772581
proc url_GetRestoreDBInstanceFromDBSnapshot_775025(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_775024(path: JsonNode;
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
  var valid_775026 = query.getOrDefault("Engine")
  valid_775026 = validateParameter(valid_775026, JString, required = false,
                                 default = nil)
  if valid_775026 != nil:
    section.add "Engine", valid_775026
  var valid_775027 = query.getOrDefault("OptionGroupName")
  valid_775027 = validateParameter(valid_775027, JString, required = false,
                                 default = nil)
  if valid_775027 != nil:
    section.add "OptionGroupName", valid_775027
  var valid_775028 = query.getOrDefault("AvailabilityZone")
  valid_775028 = validateParameter(valid_775028, JString, required = false,
                                 default = nil)
  if valid_775028 != nil:
    section.add "AvailabilityZone", valid_775028
  var valid_775029 = query.getOrDefault("Iops")
  valid_775029 = validateParameter(valid_775029, JInt, required = false, default = nil)
  if valid_775029 != nil:
    section.add "Iops", valid_775029
  var valid_775030 = query.getOrDefault("MultiAZ")
  valid_775030 = validateParameter(valid_775030, JBool, required = false, default = nil)
  if valid_775030 != nil:
    section.add "MultiAZ", valid_775030
  var valid_775031 = query.getOrDefault("LicenseModel")
  valid_775031 = validateParameter(valid_775031, JString, required = false,
                                 default = nil)
  if valid_775031 != nil:
    section.add "LicenseModel", valid_775031
  var valid_775032 = query.getOrDefault("DBName")
  valid_775032 = validateParameter(valid_775032, JString, required = false,
                                 default = nil)
  if valid_775032 != nil:
    section.add "DBName", valid_775032
  var valid_775033 = query.getOrDefault("DBInstanceClass")
  valid_775033 = validateParameter(valid_775033, JString, required = false,
                                 default = nil)
  if valid_775033 != nil:
    section.add "DBInstanceClass", valid_775033
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775034 = query.getOrDefault("Action")
  valid_775034 = validateParameter(valid_775034, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_775034 != nil:
    section.add "Action", valid_775034
  var valid_775035 = query.getOrDefault("DBSubnetGroupName")
  valid_775035 = validateParameter(valid_775035, JString, required = false,
                                 default = nil)
  if valid_775035 != nil:
    section.add "DBSubnetGroupName", valid_775035
  var valid_775036 = query.getOrDefault("PubliclyAccessible")
  valid_775036 = validateParameter(valid_775036, JBool, required = false, default = nil)
  if valid_775036 != nil:
    section.add "PubliclyAccessible", valid_775036
  var valid_775037 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_775037 = validateParameter(valid_775037, JBool, required = false, default = nil)
  if valid_775037 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775037
  var valid_775038 = query.getOrDefault("Port")
  valid_775038 = validateParameter(valid_775038, JInt, required = false, default = nil)
  if valid_775038 != nil:
    section.add "Port", valid_775038
  var valid_775039 = query.getOrDefault("Version")
  valid_775039 = validateParameter(valid_775039, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_775039 != nil:
    section.add "Version", valid_775039
  var valid_775040 = query.getOrDefault("DBInstanceIdentifier")
  valid_775040 = validateParameter(valid_775040, JString, required = true,
                                 default = nil)
  if valid_775040 != nil:
    section.add "DBInstanceIdentifier", valid_775040
  var valid_775041 = query.getOrDefault("DBSnapshotIdentifier")
  valid_775041 = validateParameter(valid_775041, JString, required = true,
                                 default = nil)
  if valid_775041 != nil:
    section.add "DBSnapshotIdentifier", valid_775041
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775042 = header.getOrDefault("X-Amz-Date")
  valid_775042 = validateParameter(valid_775042, JString, required = false,
                                 default = nil)
  if valid_775042 != nil:
    section.add "X-Amz-Date", valid_775042
  var valid_775043 = header.getOrDefault("X-Amz-Security-Token")
  valid_775043 = validateParameter(valid_775043, JString, required = false,
                                 default = nil)
  if valid_775043 != nil:
    section.add "X-Amz-Security-Token", valid_775043
  var valid_775044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775044 = validateParameter(valid_775044, JString, required = false,
                                 default = nil)
  if valid_775044 != nil:
    section.add "X-Amz-Content-Sha256", valid_775044
  var valid_775045 = header.getOrDefault("X-Amz-Algorithm")
  valid_775045 = validateParameter(valid_775045, JString, required = false,
                                 default = nil)
  if valid_775045 != nil:
    section.add "X-Amz-Algorithm", valid_775045
  var valid_775046 = header.getOrDefault("X-Amz-Signature")
  valid_775046 = validateParameter(valid_775046, JString, required = false,
                                 default = nil)
  if valid_775046 != nil:
    section.add "X-Amz-Signature", valid_775046
  var valid_775047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775047 = validateParameter(valid_775047, JString, required = false,
                                 default = nil)
  if valid_775047 != nil:
    section.add "X-Amz-SignedHeaders", valid_775047
  var valid_775048 = header.getOrDefault("X-Amz-Credential")
  valid_775048 = validateParameter(valid_775048, JString, required = false,
                                 default = nil)
  if valid_775048 != nil:
    section.add "X-Amz-Credential", valid_775048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775049: Call_GetRestoreDBInstanceFromDBSnapshot_775023;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775049.validator(path, query, header, formData, body)
  let scheme = call_775049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775049.url(scheme.get, call_775049.host, call_775049.base,
                         call_775049.route, valid.getOrDefault("path"))
  result = hook(call_775049, url, valid)

proc call*(call_775050: Call_GetRestoreDBInstanceFromDBSnapshot_775023;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Engine: string = ""; OptionGroupName: string = "";
          AvailabilityZone: string = ""; Iops: int = 0; MultiAZ: bool = false;
          LicenseModel: string = ""; DBName: string = ""; DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Port: int = 0;
          Version: string = "2013-01-10"): Recallable =
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
  var query_775051 = newJObject()
  add(query_775051, "Engine", newJString(Engine))
  add(query_775051, "OptionGroupName", newJString(OptionGroupName))
  add(query_775051, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_775051, "Iops", newJInt(Iops))
  add(query_775051, "MultiAZ", newJBool(MultiAZ))
  add(query_775051, "LicenseModel", newJString(LicenseModel))
  add(query_775051, "DBName", newJString(DBName))
  add(query_775051, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_775051, "Action", newJString(Action))
  add(query_775051, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_775051, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_775051, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_775051, "Port", newJInt(Port))
  add(query_775051, "Version", newJString(Version))
  add(query_775051, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_775051, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_775050.call(nil, query_775051, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_775023(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_775024, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_775025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_775113 = ref object of OpenApiRestCall_772581
proc url_PostRestoreDBInstanceToPointInTime_775115(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceToPointInTime_775114(path: JsonNode;
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
  var valid_775116 = query.getOrDefault("Action")
  valid_775116 = validateParameter(valid_775116, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_775116 != nil:
    section.add "Action", valid_775116
  var valid_775117 = query.getOrDefault("Version")
  valid_775117 = validateParameter(valid_775117, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_775117 != nil:
    section.add "Version", valid_775117
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775118 = header.getOrDefault("X-Amz-Date")
  valid_775118 = validateParameter(valid_775118, JString, required = false,
                                 default = nil)
  if valid_775118 != nil:
    section.add "X-Amz-Date", valid_775118
  var valid_775119 = header.getOrDefault("X-Amz-Security-Token")
  valid_775119 = validateParameter(valid_775119, JString, required = false,
                                 default = nil)
  if valid_775119 != nil:
    section.add "X-Amz-Security-Token", valid_775119
  var valid_775120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775120 = validateParameter(valid_775120, JString, required = false,
                                 default = nil)
  if valid_775120 != nil:
    section.add "X-Amz-Content-Sha256", valid_775120
  var valid_775121 = header.getOrDefault("X-Amz-Algorithm")
  valid_775121 = validateParameter(valid_775121, JString, required = false,
                                 default = nil)
  if valid_775121 != nil:
    section.add "X-Amz-Algorithm", valid_775121
  var valid_775122 = header.getOrDefault("X-Amz-Signature")
  valid_775122 = validateParameter(valid_775122, JString, required = false,
                                 default = nil)
  if valid_775122 != nil:
    section.add "X-Amz-Signature", valid_775122
  var valid_775123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775123 = validateParameter(valid_775123, JString, required = false,
                                 default = nil)
  if valid_775123 != nil:
    section.add "X-Amz-SignedHeaders", valid_775123
  var valid_775124 = header.getOrDefault("X-Amz-Credential")
  valid_775124 = validateParameter(valid_775124, JString, required = false,
                                 default = nil)
  if valid_775124 != nil:
    section.add "X-Amz-Credential", valid_775124
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
  var valid_775125 = formData.getOrDefault("UseLatestRestorableTime")
  valid_775125 = validateParameter(valid_775125, JBool, required = false, default = nil)
  if valid_775125 != nil:
    section.add "UseLatestRestorableTime", valid_775125
  var valid_775126 = formData.getOrDefault("Port")
  valid_775126 = validateParameter(valid_775126, JInt, required = false, default = nil)
  if valid_775126 != nil:
    section.add "Port", valid_775126
  var valid_775127 = formData.getOrDefault("Engine")
  valid_775127 = validateParameter(valid_775127, JString, required = false,
                                 default = nil)
  if valid_775127 != nil:
    section.add "Engine", valid_775127
  var valid_775128 = formData.getOrDefault("Iops")
  valid_775128 = validateParameter(valid_775128, JInt, required = false, default = nil)
  if valid_775128 != nil:
    section.add "Iops", valid_775128
  var valid_775129 = formData.getOrDefault("DBName")
  valid_775129 = validateParameter(valid_775129, JString, required = false,
                                 default = nil)
  if valid_775129 != nil:
    section.add "DBName", valid_775129
  var valid_775130 = formData.getOrDefault("OptionGroupName")
  valid_775130 = validateParameter(valid_775130, JString, required = false,
                                 default = nil)
  if valid_775130 != nil:
    section.add "OptionGroupName", valid_775130
  var valid_775131 = formData.getOrDefault("DBSubnetGroupName")
  valid_775131 = validateParameter(valid_775131, JString, required = false,
                                 default = nil)
  if valid_775131 != nil:
    section.add "DBSubnetGroupName", valid_775131
  var valid_775132 = formData.getOrDefault("AvailabilityZone")
  valid_775132 = validateParameter(valid_775132, JString, required = false,
                                 default = nil)
  if valid_775132 != nil:
    section.add "AvailabilityZone", valid_775132
  var valid_775133 = formData.getOrDefault("MultiAZ")
  valid_775133 = validateParameter(valid_775133, JBool, required = false, default = nil)
  if valid_775133 != nil:
    section.add "MultiAZ", valid_775133
  var valid_775134 = formData.getOrDefault("RestoreTime")
  valid_775134 = validateParameter(valid_775134, JString, required = false,
                                 default = nil)
  if valid_775134 != nil:
    section.add "RestoreTime", valid_775134
  var valid_775135 = formData.getOrDefault("PubliclyAccessible")
  valid_775135 = validateParameter(valid_775135, JBool, required = false, default = nil)
  if valid_775135 != nil:
    section.add "PubliclyAccessible", valid_775135
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_775136 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_775136 = validateParameter(valid_775136, JString, required = true,
                                 default = nil)
  if valid_775136 != nil:
    section.add "TargetDBInstanceIdentifier", valid_775136
  var valid_775137 = formData.getOrDefault("DBInstanceClass")
  valid_775137 = validateParameter(valid_775137, JString, required = false,
                                 default = nil)
  if valid_775137 != nil:
    section.add "DBInstanceClass", valid_775137
  var valid_775138 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_775138 = validateParameter(valid_775138, JString, required = true,
                                 default = nil)
  if valid_775138 != nil:
    section.add "SourceDBInstanceIdentifier", valid_775138
  var valid_775139 = formData.getOrDefault("LicenseModel")
  valid_775139 = validateParameter(valid_775139, JString, required = false,
                                 default = nil)
  if valid_775139 != nil:
    section.add "LicenseModel", valid_775139
  var valid_775140 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_775140 = validateParameter(valid_775140, JBool, required = false, default = nil)
  if valid_775140 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775140
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775141: Call_PostRestoreDBInstanceToPointInTime_775113;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775141.validator(path, query, header, formData, body)
  let scheme = call_775141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775141.url(scheme.get, call_775141.host, call_775141.base,
                         call_775141.route, valid.getOrDefault("path"))
  result = hook(call_775141, url, valid)

proc call*(call_775142: Call_PostRestoreDBInstanceToPointInTime_775113;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          UseLatestRestorableTime: bool = false; Port: int = 0; Engine: string = "";
          Iops: int = 0; DBName: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; AvailabilityZone: string = "";
          MultiAZ: bool = false; Action: string = "RestoreDBInstanceToPointInTime";
          RestoreTime: string = ""; PubliclyAccessible: bool = false;
          DBInstanceClass: string = ""; LicenseModel: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2013-01-10"): Recallable =
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
  var query_775143 = newJObject()
  var formData_775144 = newJObject()
  add(formData_775144, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_775144, "Port", newJInt(Port))
  add(formData_775144, "Engine", newJString(Engine))
  add(formData_775144, "Iops", newJInt(Iops))
  add(formData_775144, "DBName", newJString(DBName))
  add(formData_775144, "OptionGroupName", newJString(OptionGroupName))
  add(formData_775144, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_775144, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_775144, "MultiAZ", newJBool(MultiAZ))
  add(query_775143, "Action", newJString(Action))
  add(formData_775144, "RestoreTime", newJString(RestoreTime))
  add(formData_775144, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_775144, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_775144, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_775144, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_775144, "LicenseModel", newJString(LicenseModel))
  add(formData_775144, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_775143, "Version", newJString(Version))
  result = call_775142.call(nil, query_775143, nil, formData_775144, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_775113(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_775114, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_775115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_775082 = ref object of OpenApiRestCall_772581
proc url_GetRestoreDBInstanceToPointInTime_775084(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceToPointInTime_775083(path: JsonNode;
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
  var valid_775085 = query.getOrDefault("Engine")
  valid_775085 = validateParameter(valid_775085, JString, required = false,
                                 default = nil)
  if valid_775085 != nil:
    section.add "Engine", valid_775085
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_775086 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_775086 = validateParameter(valid_775086, JString, required = true,
                                 default = nil)
  if valid_775086 != nil:
    section.add "SourceDBInstanceIdentifier", valid_775086
  var valid_775087 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_775087 = validateParameter(valid_775087, JString, required = true,
                                 default = nil)
  if valid_775087 != nil:
    section.add "TargetDBInstanceIdentifier", valid_775087
  var valid_775088 = query.getOrDefault("AvailabilityZone")
  valid_775088 = validateParameter(valid_775088, JString, required = false,
                                 default = nil)
  if valid_775088 != nil:
    section.add "AvailabilityZone", valid_775088
  var valid_775089 = query.getOrDefault("Iops")
  valid_775089 = validateParameter(valid_775089, JInt, required = false, default = nil)
  if valid_775089 != nil:
    section.add "Iops", valid_775089
  var valid_775090 = query.getOrDefault("OptionGroupName")
  valid_775090 = validateParameter(valid_775090, JString, required = false,
                                 default = nil)
  if valid_775090 != nil:
    section.add "OptionGroupName", valid_775090
  var valid_775091 = query.getOrDefault("RestoreTime")
  valid_775091 = validateParameter(valid_775091, JString, required = false,
                                 default = nil)
  if valid_775091 != nil:
    section.add "RestoreTime", valid_775091
  var valid_775092 = query.getOrDefault("MultiAZ")
  valid_775092 = validateParameter(valid_775092, JBool, required = false, default = nil)
  if valid_775092 != nil:
    section.add "MultiAZ", valid_775092
  var valid_775093 = query.getOrDefault("LicenseModel")
  valid_775093 = validateParameter(valid_775093, JString, required = false,
                                 default = nil)
  if valid_775093 != nil:
    section.add "LicenseModel", valid_775093
  var valid_775094 = query.getOrDefault("DBName")
  valid_775094 = validateParameter(valid_775094, JString, required = false,
                                 default = nil)
  if valid_775094 != nil:
    section.add "DBName", valid_775094
  var valid_775095 = query.getOrDefault("DBInstanceClass")
  valid_775095 = validateParameter(valid_775095, JString, required = false,
                                 default = nil)
  if valid_775095 != nil:
    section.add "DBInstanceClass", valid_775095
  var valid_775096 = query.getOrDefault("Action")
  valid_775096 = validateParameter(valid_775096, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_775096 != nil:
    section.add "Action", valid_775096
  var valid_775097 = query.getOrDefault("UseLatestRestorableTime")
  valid_775097 = validateParameter(valid_775097, JBool, required = false, default = nil)
  if valid_775097 != nil:
    section.add "UseLatestRestorableTime", valid_775097
  var valid_775098 = query.getOrDefault("DBSubnetGroupName")
  valid_775098 = validateParameter(valid_775098, JString, required = false,
                                 default = nil)
  if valid_775098 != nil:
    section.add "DBSubnetGroupName", valid_775098
  var valid_775099 = query.getOrDefault("PubliclyAccessible")
  valid_775099 = validateParameter(valid_775099, JBool, required = false, default = nil)
  if valid_775099 != nil:
    section.add "PubliclyAccessible", valid_775099
  var valid_775100 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_775100 = validateParameter(valid_775100, JBool, required = false, default = nil)
  if valid_775100 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775100
  var valid_775101 = query.getOrDefault("Port")
  valid_775101 = validateParameter(valid_775101, JInt, required = false, default = nil)
  if valid_775101 != nil:
    section.add "Port", valid_775101
  var valid_775102 = query.getOrDefault("Version")
  valid_775102 = validateParameter(valid_775102, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_775102 != nil:
    section.add "Version", valid_775102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775103 = header.getOrDefault("X-Amz-Date")
  valid_775103 = validateParameter(valid_775103, JString, required = false,
                                 default = nil)
  if valid_775103 != nil:
    section.add "X-Amz-Date", valid_775103
  var valid_775104 = header.getOrDefault("X-Amz-Security-Token")
  valid_775104 = validateParameter(valid_775104, JString, required = false,
                                 default = nil)
  if valid_775104 != nil:
    section.add "X-Amz-Security-Token", valid_775104
  var valid_775105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775105 = validateParameter(valid_775105, JString, required = false,
                                 default = nil)
  if valid_775105 != nil:
    section.add "X-Amz-Content-Sha256", valid_775105
  var valid_775106 = header.getOrDefault("X-Amz-Algorithm")
  valid_775106 = validateParameter(valid_775106, JString, required = false,
                                 default = nil)
  if valid_775106 != nil:
    section.add "X-Amz-Algorithm", valid_775106
  var valid_775107 = header.getOrDefault("X-Amz-Signature")
  valid_775107 = validateParameter(valid_775107, JString, required = false,
                                 default = nil)
  if valid_775107 != nil:
    section.add "X-Amz-Signature", valid_775107
  var valid_775108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775108 = validateParameter(valid_775108, JString, required = false,
                                 default = nil)
  if valid_775108 != nil:
    section.add "X-Amz-SignedHeaders", valid_775108
  var valid_775109 = header.getOrDefault("X-Amz-Credential")
  valid_775109 = validateParameter(valid_775109, JString, required = false,
                                 default = nil)
  if valid_775109 != nil:
    section.add "X-Amz-Credential", valid_775109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775110: Call_GetRestoreDBInstanceToPointInTime_775082;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775110.validator(path, query, header, formData, body)
  let scheme = call_775110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775110.url(scheme.get, call_775110.host, call_775110.base,
                         call_775110.route, valid.getOrDefault("path"))
  result = hook(call_775110, url, valid)

proc call*(call_775111: Call_GetRestoreDBInstanceToPointInTime_775082;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Engine: string = ""; AvailabilityZone: string = ""; Iops: int = 0;
          OptionGroupName: string = ""; RestoreTime: string = ""; MultiAZ: bool = false;
          LicenseModel: string = ""; DBName: string = ""; DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceToPointInTime";
          UseLatestRestorableTime: bool = false; DBSubnetGroupName: string = "";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Port: int = 0; Version: string = "2013-01-10"): Recallable =
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
  var query_775112 = newJObject()
  add(query_775112, "Engine", newJString(Engine))
  add(query_775112, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_775112, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_775112, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_775112, "Iops", newJInt(Iops))
  add(query_775112, "OptionGroupName", newJString(OptionGroupName))
  add(query_775112, "RestoreTime", newJString(RestoreTime))
  add(query_775112, "MultiAZ", newJBool(MultiAZ))
  add(query_775112, "LicenseModel", newJString(LicenseModel))
  add(query_775112, "DBName", newJString(DBName))
  add(query_775112, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_775112, "Action", newJString(Action))
  add(query_775112, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_775112, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_775112, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_775112, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_775112, "Port", newJInt(Port))
  add(query_775112, "Version", newJString(Version))
  result = call_775111.call(nil, query_775112, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_775082(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_775083, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_775084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_775165 = ref object of OpenApiRestCall_772581
proc url_PostRevokeDBSecurityGroupIngress_775167(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRevokeDBSecurityGroupIngress_775166(path: JsonNode;
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
  var valid_775168 = query.getOrDefault("Action")
  valid_775168 = validateParameter(valid_775168, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_775168 != nil:
    section.add "Action", valid_775168
  var valid_775169 = query.getOrDefault("Version")
  valid_775169 = validateParameter(valid_775169, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_775169 != nil:
    section.add "Version", valid_775169
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775170 = header.getOrDefault("X-Amz-Date")
  valid_775170 = validateParameter(valid_775170, JString, required = false,
                                 default = nil)
  if valid_775170 != nil:
    section.add "X-Amz-Date", valid_775170
  var valid_775171 = header.getOrDefault("X-Amz-Security-Token")
  valid_775171 = validateParameter(valid_775171, JString, required = false,
                                 default = nil)
  if valid_775171 != nil:
    section.add "X-Amz-Security-Token", valid_775171
  var valid_775172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775172 = validateParameter(valid_775172, JString, required = false,
                                 default = nil)
  if valid_775172 != nil:
    section.add "X-Amz-Content-Sha256", valid_775172
  var valid_775173 = header.getOrDefault("X-Amz-Algorithm")
  valid_775173 = validateParameter(valid_775173, JString, required = false,
                                 default = nil)
  if valid_775173 != nil:
    section.add "X-Amz-Algorithm", valid_775173
  var valid_775174 = header.getOrDefault("X-Amz-Signature")
  valid_775174 = validateParameter(valid_775174, JString, required = false,
                                 default = nil)
  if valid_775174 != nil:
    section.add "X-Amz-Signature", valid_775174
  var valid_775175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775175 = validateParameter(valid_775175, JString, required = false,
                                 default = nil)
  if valid_775175 != nil:
    section.add "X-Amz-SignedHeaders", valid_775175
  var valid_775176 = header.getOrDefault("X-Amz-Credential")
  valid_775176 = validateParameter(valid_775176, JString, required = false,
                                 default = nil)
  if valid_775176 != nil:
    section.add "X-Amz-Credential", valid_775176
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_775177 = formData.getOrDefault("DBSecurityGroupName")
  valid_775177 = validateParameter(valid_775177, JString, required = true,
                                 default = nil)
  if valid_775177 != nil:
    section.add "DBSecurityGroupName", valid_775177
  var valid_775178 = formData.getOrDefault("EC2SecurityGroupName")
  valid_775178 = validateParameter(valid_775178, JString, required = false,
                                 default = nil)
  if valid_775178 != nil:
    section.add "EC2SecurityGroupName", valid_775178
  var valid_775179 = formData.getOrDefault("EC2SecurityGroupId")
  valid_775179 = validateParameter(valid_775179, JString, required = false,
                                 default = nil)
  if valid_775179 != nil:
    section.add "EC2SecurityGroupId", valid_775179
  var valid_775180 = formData.getOrDefault("CIDRIP")
  valid_775180 = validateParameter(valid_775180, JString, required = false,
                                 default = nil)
  if valid_775180 != nil:
    section.add "CIDRIP", valid_775180
  var valid_775181 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_775181 = validateParameter(valid_775181, JString, required = false,
                                 default = nil)
  if valid_775181 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_775181
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775182: Call_PostRevokeDBSecurityGroupIngress_775165;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775182.validator(path, query, header, formData, body)
  let scheme = call_775182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775182.url(scheme.get, call_775182.host, call_775182.base,
                         call_775182.route, valid.getOrDefault("path"))
  result = hook(call_775182, url, valid)

proc call*(call_775183: Call_PostRevokeDBSecurityGroupIngress_775165;
          DBSecurityGroupName: string;
          Action: string = "RevokeDBSecurityGroupIngress";
          EC2SecurityGroupName: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Version: string = "2013-01-10";
          EC2SecurityGroupOwnerId: string = ""): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Version: string (required)
  ##   EC2SecurityGroupOwnerId: string
  var query_775184 = newJObject()
  var formData_775185 = newJObject()
  add(formData_775185, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_775184, "Action", newJString(Action))
  add(formData_775185, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_775185, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_775185, "CIDRIP", newJString(CIDRIP))
  add(query_775184, "Version", newJString(Version))
  add(formData_775185, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_775183.call(nil, query_775184, nil, formData_775185, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_775165(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_775166, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_775167,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_775145 = ref object of OpenApiRestCall_772581
proc url_GetRevokeDBSecurityGroupIngress_775147(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRevokeDBSecurityGroupIngress_775146(path: JsonNode;
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
  var valid_775148 = query.getOrDefault("EC2SecurityGroupId")
  valid_775148 = validateParameter(valid_775148, JString, required = false,
                                 default = nil)
  if valid_775148 != nil:
    section.add "EC2SecurityGroupId", valid_775148
  var valid_775149 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_775149 = validateParameter(valid_775149, JString, required = false,
                                 default = nil)
  if valid_775149 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_775149
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_775150 = query.getOrDefault("DBSecurityGroupName")
  valid_775150 = validateParameter(valid_775150, JString, required = true,
                                 default = nil)
  if valid_775150 != nil:
    section.add "DBSecurityGroupName", valid_775150
  var valid_775151 = query.getOrDefault("Action")
  valid_775151 = validateParameter(valid_775151, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_775151 != nil:
    section.add "Action", valid_775151
  var valid_775152 = query.getOrDefault("CIDRIP")
  valid_775152 = validateParameter(valid_775152, JString, required = false,
                                 default = nil)
  if valid_775152 != nil:
    section.add "CIDRIP", valid_775152
  var valid_775153 = query.getOrDefault("EC2SecurityGroupName")
  valid_775153 = validateParameter(valid_775153, JString, required = false,
                                 default = nil)
  if valid_775153 != nil:
    section.add "EC2SecurityGroupName", valid_775153
  var valid_775154 = query.getOrDefault("Version")
  valid_775154 = validateParameter(valid_775154, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_775154 != nil:
    section.add "Version", valid_775154
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775155 = header.getOrDefault("X-Amz-Date")
  valid_775155 = validateParameter(valid_775155, JString, required = false,
                                 default = nil)
  if valid_775155 != nil:
    section.add "X-Amz-Date", valid_775155
  var valid_775156 = header.getOrDefault("X-Amz-Security-Token")
  valid_775156 = validateParameter(valid_775156, JString, required = false,
                                 default = nil)
  if valid_775156 != nil:
    section.add "X-Amz-Security-Token", valid_775156
  var valid_775157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775157 = validateParameter(valid_775157, JString, required = false,
                                 default = nil)
  if valid_775157 != nil:
    section.add "X-Amz-Content-Sha256", valid_775157
  var valid_775158 = header.getOrDefault("X-Amz-Algorithm")
  valid_775158 = validateParameter(valid_775158, JString, required = false,
                                 default = nil)
  if valid_775158 != nil:
    section.add "X-Amz-Algorithm", valid_775158
  var valid_775159 = header.getOrDefault("X-Amz-Signature")
  valid_775159 = validateParameter(valid_775159, JString, required = false,
                                 default = nil)
  if valid_775159 != nil:
    section.add "X-Amz-Signature", valid_775159
  var valid_775160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775160 = validateParameter(valid_775160, JString, required = false,
                                 default = nil)
  if valid_775160 != nil:
    section.add "X-Amz-SignedHeaders", valid_775160
  var valid_775161 = header.getOrDefault("X-Amz-Credential")
  valid_775161 = validateParameter(valid_775161, JString, required = false,
                                 default = nil)
  if valid_775161 != nil:
    section.add "X-Amz-Credential", valid_775161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775162: Call_GetRevokeDBSecurityGroupIngress_775145;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775162.validator(path, query, header, formData, body)
  let scheme = call_775162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775162.url(scheme.get, call_775162.host, call_775162.base,
                         call_775162.route, valid.getOrDefault("path"))
  result = hook(call_775162, url, valid)

proc call*(call_775163: Call_GetRevokeDBSecurityGroupIngress_775145;
          DBSecurityGroupName: string; EC2SecurityGroupId: string = "";
          EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress"; CIDRIP: string = "";
          EC2SecurityGroupName: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   CIDRIP: string
  ##   EC2SecurityGroupName: string
  ##   Version: string (required)
  var query_775164 = newJObject()
  add(query_775164, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_775164, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_775164, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_775164, "Action", newJString(Action))
  add(query_775164, "CIDRIP", newJString(CIDRIP))
  add(query_775164, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_775164, "Version", newJString(Version))
  result = call_775163.call(nil, query_775164, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_775145(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_775146, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_775147,
    schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
