
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteDBInstance"; Version: string = "2013-02-12";
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"; DBInstanceIdentifier: string = ""): Recallable =
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
  Call_PostDescribeDBLogFiles_774010 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBLogFiles_774012(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBLogFiles_774011(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774013 = query.getOrDefault("Action")
  valid_774013 = validateParameter(valid_774013, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_774013 != nil:
    section.add "Action", valid_774013
  var valid_774014 = query.getOrDefault("Version")
  valid_774014 = validateParameter(valid_774014, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774014 != nil:
    section.add "Version", valid_774014
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774015 = header.getOrDefault("X-Amz-Date")
  valid_774015 = validateParameter(valid_774015, JString, required = false,
                                 default = nil)
  if valid_774015 != nil:
    section.add "X-Amz-Date", valid_774015
  var valid_774016 = header.getOrDefault("X-Amz-Security-Token")
  valid_774016 = validateParameter(valid_774016, JString, required = false,
                                 default = nil)
  if valid_774016 != nil:
    section.add "X-Amz-Security-Token", valid_774016
  var valid_774017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774017 = validateParameter(valid_774017, JString, required = false,
                                 default = nil)
  if valid_774017 != nil:
    section.add "X-Amz-Content-Sha256", valid_774017
  var valid_774018 = header.getOrDefault("X-Amz-Algorithm")
  valid_774018 = validateParameter(valid_774018, JString, required = false,
                                 default = nil)
  if valid_774018 != nil:
    section.add "X-Amz-Algorithm", valid_774018
  var valid_774019 = header.getOrDefault("X-Amz-Signature")
  valid_774019 = validateParameter(valid_774019, JString, required = false,
                                 default = nil)
  if valid_774019 != nil:
    section.add "X-Amz-Signature", valid_774019
  var valid_774020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774020 = validateParameter(valid_774020, JString, required = false,
                                 default = nil)
  if valid_774020 != nil:
    section.add "X-Amz-SignedHeaders", valid_774020
  var valid_774021 = header.getOrDefault("X-Amz-Credential")
  valid_774021 = validateParameter(valid_774021, JString, required = false,
                                 default = nil)
  if valid_774021 != nil:
    section.add "X-Amz-Credential", valid_774021
  result.add "header", section
  ## parameters in `formData` object:
  ##   FilenameContains: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FileSize: JInt
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_774022 = formData.getOrDefault("FilenameContains")
  valid_774022 = validateParameter(valid_774022, JString, required = false,
                                 default = nil)
  if valid_774022 != nil:
    section.add "FilenameContains", valid_774022
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774023 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774023 = validateParameter(valid_774023, JString, required = true,
                                 default = nil)
  if valid_774023 != nil:
    section.add "DBInstanceIdentifier", valid_774023
  var valid_774024 = formData.getOrDefault("FileSize")
  valid_774024 = validateParameter(valid_774024, JInt, required = false, default = nil)
  if valid_774024 != nil:
    section.add "FileSize", valid_774024
  var valid_774025 = formData.getOrDefault("Marker")
  valid_774025 = validateParameter(valid_774025, JString, required = false,
                                 default = nil)
  if valid_774025 != nil:
    section.add "Marker", valid_774025
  var valid_774026 = formData.getOrDefault("MaxRecords")
  valid_774026 = validateParameter(valid_774026, JInt, required = false, default = nil)
  if valid_774026 != nil:
    section.add "MaxRecords", valid_774026
  var valid_774027 = formData.getOrDefault("FileLastWritten")
  valid_774027 = validateParameter(valid_774027, JInt, required = false, default = nil)
  if valid_774027 != nil:
    section.add "FileLastWritten", valid_774027
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774028: Call_PostDescribeDBLogFiles_774010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774028.validator(path, query, header, formData, body)
  let scheme = call_774028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774028.url(scheme.get, call_774028.host, call_774028.base,
                         call_774028.route, valid.getOrDefault("path"))
  result = hook(call_774028, url, valid)

proc call*(call_774029: Call_PostDescribeDBLogFiles_774010;
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
  var query_774030 = newJObject()
  var formData_774031 = newJObject()
  add(formData_774031, "FilenameContains", newJString(FilenameContains))
  add(formData_774031, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774031, "FileSize", newJInt(FileSize))
  add(formData_774031, "Marker", newJString(Marker))
  add(query_774030, "Action", newJString(Action))
  add(formData_774031, "MaxRecords", newJInt(MaxRecords))
  add(formData_774031, "FileLastWritten", newJInt(FileLastWritten))
  add(query_774030, "Version", newJString(Version))
  result = call_774029.call(nil, query_774030, nil, formData_774031, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_774010(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_774011, base: "/",
    url: url_PostDescribeDBLogFiles_774012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_773989 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBLogFiles_773991(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBLogFiles_773990(path: JsonNode; query: JsonNode;
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
  var valid_773992 = query.getOrDefault("FileLastWritten")
  valid_773992 = validateParameter(valid_773992, JInt, required = false, default = nil)
  if valid_773992 != nil:
    section.add "FileLastWritten", valid_773992
  var valid_773993 = query.getOrDefault("MaxRecords")
  valid_773993 = validateParameter(valid_773993, JInt, required = false, default = nil)
  if valid_773993 != nil:
    section.add "MaxRecords", valid_773993
  var valid_773994 = query.getOrDefault("FilenameContains")
  valid_773994 = validateParameter(valid_773994, JString, required = false,
                                 default = nil)
  if valid_773994 != nil:
    section.add "FilenameContains", valid_773994
  var valid_773995 = query.getOrDefault("FileSize")
  valid_773995 = validateParameter(valid_773995, JInt, required = false, default = nil)
  if valid_773995 != nil:
    section.add "FileSize", valid_773995
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773996 = query.getOrDefault("Action")
  valid_773996 = validateParameter(valid_773996, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_773996 != nil:
    section.add "Action", valid_773996
  var valid_773997 = query.getOrDefault("Marker")
  valid_773997 = validateParameter(valid_773997, JString, required = false,
                                 default = nil)
  if valid_773997 != nil:
    section.add "Marker", valid_773997
  var valid_773998 = query.getOrDefault("Version")
  valid_773998 = validateParameter(valid_773998, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_773998 != nil:
    section.add "Version", valid_773998
  var valid_773999 = query.getOrDefault("DBInstanceIdentifier")
  valid_773999 = validateParameter(valid_773999, JString, required = true,
                                 default = nil)
  if valid_773999 != nil:
    section.add "DBInstanceIdentifier", valid_773999
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774000 = header.getOrDefault("X-Amz-Date")
  valid_774000 = validateParameter(valid_774000, JString, required = false,
                                 default = nil)
  if valid_774000 != nil:
    section.add "X-Amz-Date", valid_774000
  var valid_774001 = header.getOrDefault("X-Amz-Security-Token")
  valid_774001 = validateParameter(valid_774001, JString, required = false,
                                 default = nil)
  if valid_774001 != nil:
    section.add "X-Amz-Security-Token", valid_774001
  var valid_774002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774002 = validateParameter(valid_774002, JString, required = false,
                                 default = nil)
  if valid_774002 != nil:
    section.add "X-Amz-Content-Sha256", valid_774002
  var valid_774003 = header.getOrDefault("X-Amz-Algorithm")
  valid_774003 = validateParameter(valid_774003, JString, required = false,
                                 default = nil)
  if valid_774003 != nil:
    section.add "X-Amz-Algorithm", valid_774003
  var valid_774004 = header.getOrDefault("X-Amz-Signature")
  valid_774004 = validateParameter(valid_774004, JString, required = false,
                                 default = nil)
  if valid_774004 != nil:
    section.add "X-Amz-Signature", valid_774004
  var valid_774005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774005 = validateParameter(valid_774005, JString, required = false,
                                 default = nil)
  if valid_774005 != nil:
    section.add "X-Amz-SignedHeaders", valid_774005
  var valid_774006 = header.getOrDefault("X-Amz-Credential")
  valid_774006 = validateParameter(valid_774006, JString, required = false,
                                 default = nil)
  if valid_774006 != nil:
    section.add "X-Amz-Credential", valid_774006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774007: Call_GetDescribeDBLogFiles_773989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774007.validator(path, query, header, formData, body)
  let scheme = call_774007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774007.url(scheme.get, call_774007.host, call_774007.base,
                         call_774007.route, valid.getOrDefault("path"))
  result = hook(call_774007, url, valid)

proc call*(call_774008: Call_GetDescribeDBLogFiles_773989;
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
  var query_774009 = newJObject()
  add(query_774009, "FileLastWritten", newJInt(FileLastWritten))
  add(query_774009, "MaxRecords", newJInt(MaxRecords))
  add(query_774009, "FilenameContains", newJString(FilenameContains))
  add(query_774009, "FileSize", newJInt(FileSize))
  add(query_774009, "Action", newJString(Action))
  add(query_774009, "Marker", newJString(Marker))
  add(query_774009, "Version", newJString(Version))
  add(query_774009, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_774008.call(nil, query_774009, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_773989(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_773990, base: "/",
    url: url_GetDescribeDBLogFiles_773991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_774050 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBParameterGroups_774052(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameterGroups_774051(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774053 = query.getOrDefault("Action")
  valid_774053 = validateParameter(valid_774053, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_774053 != nil:
    section.add "Action", valid_774053
  var valid_774054 = query.getOrDefault("Version")
  valid_774054 = validateParameter(valid_774054, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774054 != nil:
    section.add "Version", valid_774054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774055 = header.getOrDefault("X-Amz-Date")
  valid_774055 = validateParameter(valid_774055, JString, required = false,
                                 default = nil)
  if valid_774055 != nil:
    section.add "X-Amz-Date", valid_774055
  var valid_774056 = header.getOrDefault("X-Amz-Security-Token")
  valid_774056 = validateParameter(valid_774056, JString, required = false,
                                 default = nil)
  if valid_774056 != nil:
    section.add "X-Amz-Security-Token", valid_774056
  var valid_774057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774057 = validateParameter(valid_774057, JString, required = false,
                                 default = nil)
  if valid_774057 != nil:
    section.add "X-Amz-Content-Sha256", valid_774057
  var valid_774058 = header.getOrDefault("X-Amz-Algorithm")
  valid_774058 = validateParameter(valid_774058, JString, required = false,
                                 default = nil)
  if valid_774058 != nil:
    section.add "X-Amz-Algorithm", valid_774058
  var valid_774059 = header.getOrDefault("X-Amz-Signature")
  valid_774059 = validateParameter(valid_774059, JString, required = false,
                                 default = nil)
  if valid_774059 != nil:
    section.add "X-Amz-Signature", valid_774059
  var valid_774060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774060 = validateParameter(valid_774060, JString, required = false,
                                 default = nil)
  if valid_774060 != nil:
    section.add "X-Amz-SignedHeaders", valid_774060
  var valid_774061 = header.getOrDefault("X-Amz-Credential")
  valid_774061 = validateParameter(valid_774061, JString, required = false,
                                 default = nil)
  if valid_774061 != nil:
    section.add "X-Amz-Credential", valid_774061
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774062 = formData.getOrDefault("DBParameterGroupName")
  valid_774062 = validateParameter(valid_774062, JString, required = false,
                                 default = nil)
  if valid_774062 != nil:
    section.add "DBParameterGroupName", valid_774062
  var valid_774063 = formData.getOrDefault("Marker")
  valid_774063 = validateParameter(valid_774063, JString, required = false,
                                 default = nil)
  if valid_774063 != nil:
    section.add "Marker", valid_774063
  var valid_774064 = formData.getOrDefault("MaxRecords")
  valid_774064 = validateParameter(valid_774064, JInt, required = false, default = nil)
  if valid_774064 != nil:
    section.add "MaxRecords", valid_774064
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774065: Call_PostDescribeDBParameterGroups_774050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774065.validator(path, query, header, formData, body)
  let scheme = call_774065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774065.url(scheme.get, call_774065.host, call_774065.base,
                         call_774065.route, valid.getOrDefault("path"))
  result = hook(call_774065, url, valid)

proc call*(call_774066: Call_PostDescribeDBParameterGroups_774050;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_774067 = newJObject()
  var formData_774068 = newJObject()
  add(formData_774068, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_774068, "Marker", newJString(Marker))
  add(query_774067, "Action", newJString(Action))
  add(formData_774068, "MaxRecords", newJInt(MaxRecords))
  add(query_774067, "Version", newJString(Version))
  result = call_774066.call(nil, query_774067, nil, formData_774068, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_774050(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_774051, base: "/",
    url: url_PostDescribeDBParameterGroups_774052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_774032 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBParameterGroups_774034(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameterGroups_774033(path: JsonNode; query: JsonNode;
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
  var valid_774035 = query.getOrDefault("MaxRecords")
  valid_774035 = validateParameter(valid_774035, JInt, required = false, default = nil)
  if valid_774035 != nil:
    section.add "MaxRecords", valid_774035
  var valid_774036 = query.getOrDefault("DBParameterGroupName")
  valid_774036 = validateParameter(valid_774036, JString, required = false,
                                 default = nil)
  if valid_774036 != nil:
    section.add "DBParameterGroupName", valid_774036
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774037 = query.getOrDefault("Action")
  valid_774037 = validateParameter(valid_774037, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_774037 != nil:
    section.add "Action", valid_774037
  var valid_774038 = query.getOrDefault("Marker")
  valid_774038 = validateParameter(valid_774038, JString, required = false,
                                 default = nil)
  if valid_774038 != nil:
    section.add "Marker", valid_774038
  var valid_774039 = query.getOrDefault("Version")
  valid_774039 = validateParameter(valid_774039, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774039 != nil:
    section.add "Version", valid_774039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774040 = header.getOrDefault("X-Amz-Date")
  valid_774040 = validateParameter(valid_774040, JString, required = false,
                                 default = nil)
  if valid_774040 != nil:
    section.add "X-Amz-Date", valid_774040
  var valid_774041 = header.getOrDefault("X-Amz-Security-Token")
  valid_774041 = validateParameter(valid_774041, JString, required = false,
                                 default = nil)
  if valid_774041 != nil:
    section.add "X-Amz-Security-Token", valid_774041
  var valid_774042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774042 = validateParameter(valid_774042, JString, required = false,
                                 default = nil)
  if valid_774042 != nil:
    section.add "X-Amz-Content-Sha256", valid_774042
  var valid_774043 = header.getOrDefault("X-Amz-Algorithm")
  valid_774043 = validateParameter(valid_774043, JString, required = false,
                                 default = nil)
  if valid_774043 != nil:
    section.add "X-Amz-Algorithm", valid_774043
  var valid_774044 = header.getOrDefault("X-Amz-Signature")
  valid_774044 = validateParameter(valid_774044, JString, required = false,
                                 default = nil)
  if valid_774044 != nil:
    section.add "X-Amz-Signature", valid_774044
  var valid_774045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774045 = validateParameter(valid_774045, JString, required = false,
                                 default = nil)
  if valid_774045 != nil:
    section.add "X-Amz-SignedHeaders", valid_774045
  var valid_774046 = header.getOrDefault("X-Amz-Credential")
  valid_774046 = validateParameter(valid_774046, JString, required = false,
                                 default = nil)
  if valid_774046 != nil:
    section.add "X-Amz-Credential", valid_774046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774047: Call_GetDescribeDBParameterGroups_774032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774047.validator(path, query, header, formData, body)
  let scheme = call_774047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774047.url(scheme.get, call_774047.host, call_774047.base,
                         call_774047.route, valid.getOrDefault("path"))
  result = hook(call_774047, url, valid)

proc call*(call_774048: Call_GetDescribeDBParameterGroups_774032;
          MaxRecords: int = 0; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_774049 = newJObject()
  add(query_774049, "MaxRecords", newJInt(MaxRecords))
  add(query_774049, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_774049, "Action", newJString(Action))
  add(query_774049, "Marker", newJString(Marker))
  add(query_774049, "Version", newJString(Version))
  result = call_774048.call(nil, query_774049, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_774032(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_774033, base: "/",
    url: url_GetDescribeDBParameterGroups_774034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_774088 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBParameters_774090(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameters_774089(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774091 = query.getOrDefault("Action")
  valid_774091 = validateParameter(valid_774091, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_774091 != nil:
    section.add "Action", valid_774091
  var valid_774092 = query.getOrDefault("Version")
  valid_774092 = validateParameter(valid_774092, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774092 != nil:
    section.add "Version", valid_774092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774093 = header.getOrDefault("X-Amz-Date")
  valid_774093 = validateParameter(valid_774093, JString, required = false,
                                 default = nil)
  if valid_774093 != nil:
    section.add "X-Amz-Date", valid_774093
  var valid_774094 = header.getOrDefault("X-Amz-Security-Token")
  valid_774094 = validateParameter(valid_774094, JString, required = false,
                                 default = nil)
  if valid_774094 != nil:
    section.add "X-Amz-Security-Token", valid_774094
  var valid_774095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774095 = validateParameter(valid_774095, JString, required = false,
                                 default = nil)
  if valid_774095 != nil:
    section.add "X-Amz-Content-Sha256", valid_774095
  var valid_774096 = header.getOrDefault("X-Amz-Algorithm")
  valid_774096 = validateParameter(valid_774096, JString, required = false,
                                 default = nil)
  if valid_774096 != nil:
    section.add "X-Amz-Algorithm", valid_774096
  var valid_774097 = header.getOrDefault("X-Amz-Signature")
  valid_774097 = validateParameter(valid_774097, JString, required = false,
                                 default = nil)
  if valid_774097 != nil:
    section.add "X-Amz-Signature", valid_774097
  var valid_774098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774098 = validateParameter(valid_774098, JString, required = false,
                                 default = nil)
  if valid_774098 != nil:
    section.add "X-Amz-SignedHeaders", valid_774098
  var valid_774099 = header.getOrDefault("X-Amz-Credential")
  valid_774099 = validateParameter(valid_774099, JString, required = false,
                                 default = nil)
  if valid_774099 != nil:
    section.add "X-Amz-Credential", valid_774099
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_774100 = formData.getOrDefault("DBParameterGroupName")
  valid_774100 = validateParameter(valid_774100, JString, required = true,
                                 default = nil)
  if valid_774100 != nil:
    section.add "DBParameterGroupName", valid_774100
  var valid_774101 = formData.getOrDefault("Marker")
  valid_774101 = validateParameter(valid_774101, JString, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "Marker", valid_774101
  var valid_774102 = formData.getOrDefault("MaxRecords")
  valid_774102 = validateParameter(valid_774102, JInt, required = false, default = nil)
  if valid_774102 != nil:
    section.add "MaxRecords", valid_774102
  var valid_774103 = formData.getOrDefault("Source")
  valid_774103 = validateParameter(valid_774103, JString, required = false,
                                 default = nil)
  if valid_774103 != nil:
    section.add "Source", valid_774103
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774104: Call_PostDescribeDBParameters_774088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774104.validator(path, query, header, formData, body)
  let scheme = call_774104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774104.url(scheme.get, call_774104.host, call_774104.base,
                         call_774104.route, valid.getOrDefault("path"))
  result = hook(call_774104, url, valid)

proc call*(call_774105: Call_PostDescribeDBParameters_774088;
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
  var query_774106 = newJObject()
  var formData_774107 = newJObject()
  add(formData_774107, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_774107, "Marker", newJString(Marker))
  add(query_774106, "Action", newJString(Action))
  add(formData_774107, "MaxRecords", newJInt(MaxRecords))
  add(query_774106, "Version", newJString(Version))
  add(formData_774107, "Source", newJString(Source))
  result = call_774105.call(nil, query_774106, nil, formData_774107, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_774088(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_774089, base: "/",
    url: url_PostDescribeDBParameters_774090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_774069 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBParameters_774071(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameters_774070(path: JsonNode; query: JsonNode;
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
  var valid_774072 = query.getOrDefault("MaxRecords")
  valid_774072 = validateParameter(valid_774072, JInt, required = false, default = nil)
  if valid_774072 != nil:
    section.add "MaxRecords", valid_774072
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_774073 = query.getOrDefault("DBParameterGroupName")
  valid_774073 = validateParameter(valid_774073, JString, required = true,
                                 default = nil)
  if valid_774073 != nil:
    section.add "DBParameterGroupName", valid_774073
  var valid_774074 = query.getOrDefault("Action")
  valid_774074 = validateParameter(valid_774074, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_774074 != nil:
    section.add "Action", valid_774074
  var valid_774075 = query.getOrDefault("Marker")
  valid_774075 = validateParameter(valid_774075, JString, required = false,
                                 default = nil)
  if valid_774075 != nil:
    section.add "Marker", valid_774075
  var valid_774076 = query.getOrDefault("Source")
  valid_774076 = validateParameter(valid_774076, JString, required = false,
                                 default = nil)
  if valid_774076 != nil:
    section.add "Source", valid_774076
  var valid_774077 = query.getOrDefault("Version")
  valid_774077 = validateParameter(valid_774077, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774077 != nil:
    section.add "Version", valid_774077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774078 = header.getOrDefault("X-Amz-Date")
  valid_774078 = validateParameter(valid_774078, JString, required = false,
                                 default = nil)
  if valid_774078 != nil:
    section.add "X-Amz-Date", valid_774078
  var valid_774079 = header.getOrDefault("X-Amz-Security-Token")
  valid_774079 = validateParameter(valid_774079, JString, required = false,
                                 default = nil)
  if valid_774079 != nil:
    section.add "X-Amz-Security-Token", valid_774079
  var valid_774080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774080 = validateParameter(valid_774080, JString, required = false,
                                 default = nil)
  if valid_774080 != nil:
    section.add "X-Amz-Content-Sha256", valid_774080
  var valid_774081 = header.getOrDefault("X-Amz-Algorithm")
  valid_774081 = validateParameter(valid_774081, JString, required = false,
                                 default = nil)
  if valid_774081 != nil:
    section.add "X-Amz-Algorithm", valid_774081
  var valid_774082 = header.getOrDefault("X-Amz-Signature")
  valid_774082 = validateParameter(valid_774082, JString, required = false,
                                 default = nil)
  if valid_774082 != nil:
    section.add "X-Amz-Signature", valid_774082
  var valid_774083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774083 = validateParameter(valid_774083, JString, required = false,
                                 default = nil)
  if valid_774083 != nil:
    section.add "X-Amz-SignedHeaders", valid_774083
  var valid_774084 = header.getOrDefault("X-Amz-Credential")
  valid_774084 = validateParameter(valid_774084, JString, required = false,
                                 default = nil)
  if valid_774084 != nil:
    section.add "X-Amz-Credential", valid_774084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774085: Call_GetDescribeDBParameters_774069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774085.validator(path, query, header, formData, body)
  let scheme = call_774085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774085.url(scheme.get, call_774085.host, call_774085.base,
                         call_774085.route, valid.getOrDefault("path"))
  result = hook(call_774085, url, valid)

proc call*(call_774086: Call_GetDescribeDBParameters_774069;
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
  var query_774087 = newJObject()
  add(query_774087, "MaxRecords", newJInt(MaxRecords))
  add(query_774087, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_774087, "Action", newJString(Action))
  add(query_774087, "Marker", newJString(Marker))
  add(query_774087, "Source", newJString(Source))
  add(query_774087, "Version", newJString(Version))
  result = call_774086.call(nil, query_774087, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_774069(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_774070, base: "/",
    url: url_GetDescribeDBParameters_774071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_774126 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBSecurityGroups_774128(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSecurityGroups_774127(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774129 = query.getOrDefault("Action")
  valid_774129 = validateParameter(valid_774129, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_774129 != nil:
    section.add "Action", valid_774129
  var valid_774130 = query.getOrDefault("Version")
  valid_774130 = validateParameter(valid_774130, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774130 != nil:
    section.add "Version", valid_774130
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774131 = header.getOrDefault("X-Amz-Date")
  valid_774131 = validateParameter(valid_774131, JString, required = false,
                                 default = nil)
  if valid_774131 != nil:
    section.add "X-Amz-Date", valid_774131
  var valid_774132 = header.getOrDefault("X-Amz-Security-Token")
  valid_774132 = validateParameter(valid_774132, JString, required = false,
                                 default = nil)
  if valid_774132 != nil:
    section.add "X-Amz-Security-Token", valid_774132
  var valid_774133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774133 = validateParameter(valid_774133, JString, required = false,
                                 default = nil)
  if valid_774133 != nil:
    section.add "X-Amz-Content-Sha256", valid_774133
  var valid_774134 = header.getOrDefault("X-Amz-Algorithm")
  valid_774134 = validateParameter(valid_774134, JString, required = false,
                                 default = nil)
  if valid_774134 != nil:
    section.add "X-Amz-Algorithm", valid_774134
  var valid_774135 = header.getOrDefault("X-Amz-Signature")
  valid_774135 = validateParameter(valid_774135, JString, required = false,
                                 default = nil)
  if valid_774135 != nil:
    section.add "X-Amz-Signature", valid_774135
  var valid_774136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774136 = validateParameter(valid_774136, JString, required = false,
                                 default = nil)
  if valid_774136 != nil:
    section.add "X-Amz-SignedHeaders", valid_774136
  var valid_774137 = header.getOrDefault("X-Amz-Credential")
  valid_774137 = validateParameter(valid_774137, JString, required = false,
                                 default = nil)
  if valid_774137 != nil:
    section.add "X-Amz-Credential", valid_774137
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774138 = formData.getOrDefault("DBSecurityGroupName")
  valid_774138 = validateParameter(valid_774138, JString, required = false,
                                 default = nil)
  if valid_774138 != nil:
    section.add "DBSecurityGroupName", valid_774138
  var valid_774139 = formData.getOrDefault("Marker")
  valid_774139 = validateParameter(valid_774139, JString, required = false,
                                 default = nil)
  if valid_774139 != nil:
    section.add "Marker", valid_774139
  var valid_774140 = formData.getOrDefault("MaxRecords")
  valid_774140 = validateParameter(valid_774140, JInt, required = false, default = nil)
  if valid_774140 != nil:
    section.add "MaxRecords", valid_774140
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774141: Call_PostDescribeDBSecurityGroups_774126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774141.validator(path, query, header, formData, body)
  let scheme = call_774141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774141.url(scheme.get, call_774141.host, call_774141.base,
                         call_774141.route, valid.getOrDefault("path"))
  result = hook(call_774141, url, valid)

proc call*(call_774142: Call_PostDescribeDBSecurityGroups_774126;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_774143 = newJObject()
  var formData_774144 = newJObject()
  add(formData_774144, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_774144, "Marker", newJString(Marker))
  add(query_774143, "Action", newJString(Action))
  add(formData_774144, "MaxRecords", newJInt(MaxRecords))
  add(query_774143, "Version", newJString(Version))
  result = call_774142.call(nil, query_774143, nil, formData_774144, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_774126(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_774127, base: "/",
    url: url_PostDescribeDBSecurityGroups_774128,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_774108 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBSecurityGroups_774110(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSecurityGroups_774109(path: JsonNode; query: JsonNode;
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
  var valid_774111 = query.getOrDefault("MaxRecords")
  valid_774111 = validateParameter(valid_774111, JInt, required = false, default = nil)
  if valid_774111 != nil:
    section.add "MaxRecords", valid_774111
  var valid_774112 = query.getOrDefault("DBSecurityGroupName")
  valid_774112 = validateParameter(valid_774112, JString, required = false,
                                 default = nil)
  if valid_774112 != nil:
    section.add "DBSecurityGroupName", valid_774112
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774113 = query.getOrDefault("Action")
  valid_774113 = validateParameter(valid_774113, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_774113 != nil:
    section.add "Action", valid_774113
  var valid_774114 = query.getOrDefault("Marker")
  valid_774114 = validateParameter(valid_774114, JString, required = false,
                                 default = nil)
  if valid_774114 != nil:
    section.add "Marker", valid_774114
  var valid_774115 = query.getOrDefault("Version")
  valid_774115 = validateParameter(valid_774115, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774115 != nil:
    section.add "Version", valid_774115
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774116 = header.getOrDefault("X-Amz-Date")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "X-Amz-Date", valid_774116
  var valid_774117 = header.getOrDefault("X-Amz-Security-Token")
  valid_774117 = validateParameter(valid_774117, JString, required = false,
                                 default = nil)
  if valid_774117 != nil:
    section.add "X-Amz-Security-Token", valid_774117
  var valid_774118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774118 = validateParameter(valid_774118, JString, required = false,
                                 default = nil)
  if valid_774118 != nil:
    section.add "X-Amz-Content-Sha256", valid_774118
  var valid_774119 = header.getOrDefault("X-Amz-Algorithm")
  valid_774119 = validateParameter(valid_774119, JString, required = false,
                                 default = nil)
  if valid_774119 != nil:
    section.add "X-Amz-Algorithm", valid_774119
  var valid_774120 = header.getOrDefault("X-Amz-Signature")
  valid_774120 = validateParameter(valid_774120, JString, required = false,
                                 default = nil)
  if valid_774120 != nil:
    section.add "X-Amz-Signature", valid_774120
  var valid_774121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774121 = validateParameter(valid_774121, JString, required = false,
                                 default = nil)
  if valid_774121 != nil:
    section.add "X-Amz-SignedHeaders", valid_774121
  var valid_774122 = header.getOrDefault("X-Amz-Credential")
  valid_774122 = validateParameter(valid_774122, JString, required = false,
                                 default = nil)
  if valid_774122 != nil:
    section.add "X-Amz-Credential", valid_774122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774123: Call_GetDescribeDBSecurityGroups_774108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774123.validator(path, query, header, formData, body)
  let scheme = call_774123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774123.url(scheme.get, call_774123.host, call_774123.base,
                         call_774123.route, valid.getOrDefault("path"))
  result = hook(call_774123, url, valid)

proc call*(call_774124: Call_GetDescribeDBSecurityGroups_774108;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_774125 = newJObject()
  add(query_774125, "MaxRecords", newJInt(MaxRecords))
  add(query_774125, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_774125, "Action", newJString(Action))
  add(query_774125, "Marker", newJString(Marker))
  add(query_774125, "Version", newJString(Version))
  result = call_774124.call(nil, query_774125, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_774108(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_774109, base: "/",
    url: url_GetDescribeDBSecurityGroups_774110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_774165 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBSnapshots_774167(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSnapshots_774166(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774168 = query.getOrDefault("Action")
  valid_774168 = validateParameter(valid_774168, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_774168 != nil:
    section.add "Action", valid_774168
  var valid_774169 = query.getOrDefault("Version")
  valid_774169 = validateParameter(valid_774169, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774169 != nil:
    section.add "Version", valid_774169
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774170 = header.getOrDefault("X-Amz-Date")
  valid_774170 = validateParameter(valid_774170, JString, required = false,
                                 default = nil)
  if valid_774170 != nil:
    section.add "X-Amz-Date", valid_774170
  var valid_774171 = header.getOrDefault("X-Amz-Security-Token")
  valid_774171 = validateParameter(valid_774171, JString, required = false,
                                 default = nil)
  if valid_774171 != nil:
    section.add "X-Amz-Security-Token", valid_774171
  var valid_774172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774172 = validateParameter(valid_774172, JString, required = false,
                                 default = nil)
  if valid_774172 != nil:
    section.add "X-Amz-Content-Sha256", valid_774172
  var valid_774173 = header.getOrDefault("X-Amz-Algorithm")
  valid_774173 = validateParameter(valid_774173, JString, required = false,
                                 default = nil)
  if valid_774173 != nil:
    section.add "X-Amz-Algorithm", valid_774173
  var valid_774174 = header.getOrDefault("X-Amz-Signature")
  valid_774174 = validateParameter(valid_774174, JString, required = false,
                                 default = nil)
  if valid_774174 != nil:
    section.add "X-Amz-Signature", valid_774174
  var valid_774175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774175 = validateParameter(valid_774175, JString, required = false,
                                 default = nil)
  if valid_774175 != nil:
    section.add "X-Amz-SignedHeaders", valid_774175
  var valid_774176 = header.getOrDefault("X-Amz-Credential")
  valid_774176 = validateParameter(valid_774176, JString, required = false,
                                 default = nil)
  if valid_774176 != nil:
    section.add "X-Amz-Credential", valid_774176
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774177 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774177 = validateParameter(valid_774177, JString, required = false,
                                 default = nil)
  if valid_774177 != nil:
    section.add "DBInstanceIdentifier", valid_774177
  var valid_774178 = formData.getOrDefault("SnapshotType")
  valid_774178 = validateParameter(valid_774178, JString, required = false,
                                 default = nil)
  if valid_774178 != nil:
    section.add "SnapshotType", valid_774178
  var valid_774179 = formData.getOrDefault("Marker")
  valid_774179 = validateParameter(valid_774179, JString, required = false,
                                 default = nil)
  if valid_774179 != nil:
    section.add "Marker", valid_774179
  var valid_774180 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_774180 = validateParameter(valid_774180, JString, required = false,
                                 default = nil)
  if valid_774180 != nil:
    section.add "DBSnapshotIdentifier", valid_774180
  var valid_774181 = formData.getOrDefault("MaxRecords")
  valid_774181 = validateParameter(valid_774181, JInt, required = false, default = nil)
  if valid_774181 != nil:
    section.add "MaxRecords", valid_774181
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774182: Call_PostDescribeDBSnapshots_774165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774182.validator(path, query, header, formData, body)
  let scheme = call_774182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774182.url(scheme.get, call_774182.host, call_774182.base,
                         call_774182.route, valid.getOrDefault("path"))
  result = hook(call_774182, url, valid)

proc call*(call_774183: Call_PostDescribeDBSnapshots_774165;
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
  var query_774184 = newJObject()
  var formData_774185 = newJObject()
  add(formData_774185, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774185, "SnapshotType", newJString(SnapshotType))
  add(formData_774185, "Marker", newJString(Marker))
  add(formData_774185, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_774184, "Action", newJString(Action))
  add(formData_774185, "MaxRecords", newJInt(MaxRecords))
  add(query_774184, "Version", newJString(Version))
  result = call_774183.call(nil, query_774184, nil, formData_774185, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_774165(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_774166, base: "/",
    url: url_PostDescribeDBSnapshots_774167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_774145 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBSnapshots_774147(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSnapshots_774146(path: JsonNode; query: JsonNode;
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
  var valid_774148 = query.getOrDefault("MaxRecords")
  valid_774148 = validateParameter(valid_774148, JInt, required = false, default = nil)
  if valid_774148 != nil:
    section.add "MaxRecords", valid_774148
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774149 = query.getOrDefault("Action")
  valid_774149 = validateParameter(valid_774149, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_774149 != nil:
    section.add "Action", valid_774149
  var valid_774150 = query.getOrDefault("Marker")
  valid_774150 = validateParameter(valid_774150, JString, required = false,
                                 default = nil)
  if valid_774150 != nil:
    section.add "Marker", valid_774150
  var valid_774151 = query.getOrDefault("SnapshotType")
  valid_774151 = validateParameter(valid_774151, JString, required = false,
                                 default = nil)
  if valid_774151 != nil:
    section.add "SnapshotType", valid_774151
  var valid_774152 = query.getOrDefault("Version")
  valid_774152 = validateParameter(valid_774152, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774152 != nil:
    section.add "Version", valid_774152
  var valid_774153 = query.getOrDefault("DBInstanceIdentifier")
  valid_774153 = validateParameter(valid_774153, JString, required = false,
                                 default = nil)
  if valid_774153 != nil:
    section.add "DBInstanceIdentifier", valid_774153
  var valid_774154 = query.getOrDefault("DBSnapshotIdentifier")
  valid_774154 = validateParameter(valid_774154, JString, required = false,
                                 default = nil)
  if valid_774154 != nil:
    section.add "DBSnapshotIdentifier", valid_774154
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774155 = header.getOrDefault("X-Amz-Date")
  valid_774155 = validateParameter(valid_774155, JString, required = false,
                                 default = nil)
  if valid_774155 != nil:
    section.add "X-Amz-Date", valid_774155
  var valid_774156 = header.getOrDefault("X-Amz-Security-Token")
  valid_774156 = validateParameter(valid_774156, JString, required = false,
                                 default = nil)
  if valid_774156 != nil:
    section.add "X-Amz-Security-Token", valid_774156
  var valid_774157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774157 = validateParameter(valid_774157, JString, required = false,
                                 default = nil)
  if valid_774157 != nil:
    section.add "X-Amz-Content-Sha256", valid_774157
  var valid_774158 = header.getOrDefault("X-Amz-Algorithm")
  valid_774158 = validateParameter(valid_774158, JString, required = false,
                                 default = nil)
  if valid_774158 != nil:
    section.add "X-Amz-Algorithm", valid_774158
  var valid_774159 = header.getOrDefault("X-Amz-Signature")
  valid_774159 = validateParameter(valid_774159, JString, required = false,
                                 default = nil)
  if valid_774159 != nil:
    section.add "X-Amz-Signature", valid_774159
  var valid_774160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774160 = validateParameter(valid_774160, JString, required = false,
                                 default = nil)
  if valid_774160 != nil:
    section.add "X-Amz-SignedHeaders", valid_774160
  var valid_774161 = header.getOrDefault("X-Amz-Credential")
  valid_774161 = validateParameter(valid_774161, JString, required = false,
                                 default = nil)
  if valid_774161 != nil:
    section.add "X-Amz-Credential", valid_774161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774162: Call_GetDescribeDBSnapshots_774145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774162.validator(path, query, header, formData, body)
  let scheme = call_774162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774162.url(scheme.get, call_774162.host, call_774162.base,
                         call_774162.route, valid.getOrDefault("path"))
  result = hook(call_774162, url, valid)

proc call*(call_774163: Call_GetDescribeDBSnapshots_774145; MaxRecords: int = 0;
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
  var query_774164 = newJObject()
  add(query_774164, "MaxRecords", newJInt(MaxRecords))
  add(query_774164, "Action", newJString(Action))
  add(query_774164, "Marker", newJString(Marker))
  add(query_774164, "SnapshotType", newJString(SnapshotType))
  add(query_774164, "Version", newJString(Version))
  add(query_774164, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_774164, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_774163.call(nil, query_774164, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_774145(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_774146, base: "/",
    url: url_GetDescribeDBSnapshots_774147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_774204 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBSubnetGroups_774206(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSubnetGroups_774205(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774207 = query.getOrDefault("Action")
  valid_774207 = validateParameter(valid_774207, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_774207 != nil:
    section.add "Action", valid_774207
  var valid_774208 = query.getOrDefault("Version")
  valid_774208 = validateParameter(valid_774208, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774208 != nil:
    section.add "Version", valid_774208
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774209 = header.getOrDefault("X-Amz-Date")
  valid_774209 = validateParameter(valid_774209, JString, required = false,
                                 default = nil)
  if valid_774209 != nil:
    section.add "X-Amz-Date", valid_774209
  var valid_774210 = header.getOrDefault("X-Amz-Security-Token")
  valid_774210 = validateParameter(valid_774210, JString, required = false,
                                 default = nil)
  if valid_774210 != nil:
    section.add "X-Amz-Security-Token", valid_774210
  var valid_774211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774211 = validateParameter(valid_774211, JString, required = false,
                                 default = nil)
  if valid_774211 != nil:
    section.add "X-Amz-Content-Sha256", valid_774211
  var valid_774212 = header.getOrDefault("X-Amz-Algorithm")
  valid_774212 = validateParameter(valid_774212, JString, required = false,
                                 default = nil)
  if valid_774212 != nil:
    section.add "X-Amz-Algorithm", valid_774212
  var valid_774213 = header.getOrDefault("X-Amz-Signature")
  valid_774213 = validateParameter(valid_774213, JString, required = false,
                                 default = nil)
  if valid_774213 != nil:
    section.add "X-Amz-Signature", valid_774213
  var valid_774214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774214 = validateParameter(valid_774214, JString, required = false,
                                 default = nil)
  if valid_774214 != nil:
    section.add "X-Amz-SignedHeaders", valid_774214
  var valid_774215 = header.getOrDefault("X-Amz-Credential")
  valid_774215 = validateParameter(valid_774215, JString, required = false,
                                 default = nil)
  if valid_774215 != nil:
    section.add "X-Amz-Credential", valid_774215
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774216 = formData.getOrDefault("DBSubnetGroupName")
  valid_774216 = validateParameter(valid_774216, JString, required = false,
                                 default = nil)
  if valid_774216 != nil:
    section.add "DBSubnetGroupName", valid_774216
  var valid_774217 = formData.getOrDefault("Marker")
  valid_774217 = validateParameter(valid_774217, JString, required = false,
                                 default = nil)
  if valid_774217 != nil:
    section.add "Marker", valid_774217
  var valid_774218 = formData.getOrDefault("MaxRecords")
  valid_774218 = validateParameter(valid_774218, JInt, required = false, default = nil)
  if valid_774218 != nil:
    section.add "MaxRecords", valid_774218
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774219: Call_PostDescribeDBSubnetGroups_774204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774219.validator(path, query, header, formData, body)
  let scheme = call_774219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774219.url(scheme.get, call_774219.host, call_774219.base,
                         call_774219.route, valid.getOrDefault("path"))
  result = hook(call_774219, url, valid)

proc call*(call_774220: Call_PostDescribeDBSubnetGroups_774204;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_774221 = newJObject()
  var formData_774222 = newJObject()
  add(formData_774222, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_774222, "Marker", newJString(Marker))
  add(query_774221, "Action", newJString(Action))
  add(formData_774222, "MaxRecords", newJInt(MaxRecords))
  add(query_774221, "Version", newJString(Version))
  result = call_774220.call(nil, query_774221, nil, formData_774222, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_774204(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_774205, base: "/",
    url: url_PostDescribeDBSubnetGroups_774206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_774186 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBSubnetGroups_774188(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSubnetGroups_774187(path: JsonNode; query: JsonNode;
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
  var valid_774189 = query.getOrDefault("MaxRecords")
  valid_774189 = validateParameter(valid_774189, JInt, required = false, default = nil)
  if valid_774189 != nil:
    section.add "MaxRecords", valid_774189
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774190 = query.getOrDefault("Action")
  valid_774190 = validateParameter(valid_774190, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_774190 != nil:
    section.add "Action", valid_774190
  var valid_774191 = query.getOrDefault("Marker")
  valid_774191 = validateParameter(valid_774191, JString, required = false,
                                 default = nil)
  if valid_774191 != nil:
    section.add "Marker", valid_774191
  var valid_774192 = query.getOrDefault("DBSubnetGroupName")
  valid_774192 = validateParameter(valid_774192, JString, required = false,
                                 default = nil)
  if valid_774192 != nil:
    section.add "DBSubnetGroupName", valid_774192
  var valid_774193 = query.getOrDefault("Version")
  valid_774193 = validateParameter(valid_774193, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774193 != nil:
    section.add "Version", valid_774193
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774194 = header.getOrDefault("X-Amz-Date")
  valid_774194 = validateParameter(valid_774194, JString, required = false,
                                 default = nil)
  if valid_774194 != nil:
    section.add "X-Amz-Date", valid_774194
  var valid_774195 = header.getOrDefault("X-Amz-Security-Token")
  valid_774195 = validateParameter(valid_774195, JString, required = false,
                                 default = nil)
  if valid_774195 != nil:
    section.add "X-Amz-Security-Token", valid_774195
  var valid_774196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774196 = validateParameter(valid_774196, JString, required = false,
                                 default = nil)
  if valid_774196 != nil:
    section.add "X-Amz-Content-Sha256", valid_774196
  var valid_774197 = header.getOrDefault("X-Amz-Algorithm")
  valid_774197 = validateParameter(valid_774197, JString, required = false,
                                 default = nil)
  if valid_774197 != nil:
    section.add "X-Amz-Algorithm", valid_774197
  var valid_774198 = header.getOrDefault("X-Amz-Signature")
  valid_774198 = validateParameter(valid_774198, JString, required = false,
                                 default = nil)
  if valid_774198 != nil:
    section.add "X-Amz-Signature", valid_774198
  var valid_774199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774199 = validateParameter(valid_774199, JString, required = false,
                                 default = nil)
  if valid_774199 != nil:
    section.add "X-Amz-SignedHeaders", valid_774199
  var valid_774200 = header.getOrDefault("X-Amz-Credential")
  valid_774200 = validateParameter(valid_774200, JString, required = false,
                                 default = nil)
  if valid_774200 != nil:
    section.add "X-Amz-Credential", valid_774200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774201: Call_GetDescribeDBSubnetGroups_774186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774201.validator(path, query, header, formData, body)
  let scheme = call_774201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774201.url(scheme.get, call_774201.host, call_774201.base,
                         call_774201.route, valid.getOrDefault("path"))
  result = hook(call_774201, url, valid)

proc call*(call_774202: Call_GetDescribeDBSubnetGroups_774186; MaxRecords: int = 0;
          Action: string = "DescribeDBSubnetGroups"; Marker: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_774203 = newJObject()
  add(query_774203, "MaxRecords", newJInt(MaxRecords))
  add(query_774203, "Action", newJString(Action))
  add(query_774203, "Marker", newJString(Marker))
  add(query_774203, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_774203, "Version", newJString(Version))
  result = call_774202.call(nil, query_774203, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_774186(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_774187, base: "/",
    url: url_GetDescribeDBSubnetGroups_774188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_774241 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEngineDefaultParameters_774243(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEngineDefaultParameters_774242(path: JsonNode;
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
  var valid_774244 = query.getOrDefault("Action")
  valid_774244 = validateParameter(valid_774244, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_774244 != nil:
    section.add "Action", valid_774244
  var valid_774245 = query.getOrDefault("Version")
  valid_774245 = validateParameter(valid_774245, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774245 != nil:
    section.add "Version", valid_774245
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774246 = header.getOrDefault("X-Amz-Date")
  valid_774246 = validateParameter(valid_774246, JString, required = false,
                                 default = nil)
  if valid_774246 != nil:
    section.add "X-Amz-Date", valid_774246
  var valid_774247 = header.getOrDefault("X-Amz-Security-Token")
  valid_774247 = validateParameter(valid_774247, JString, required = false,
                                 default = nil)
  if valid_774247 != nil:
    section.add "X-Amz-Security-Token", valid_774247
  var valid_774248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774248 = validateParameter(valid_774248, JString, required = false,
                                 default = nil)
  if valid_774248 != nil:
    section.add "X-Amz-Content-Sha256", valid_774248
  var valid_774249 = header.getOrDefault("X-Amz-Algorithm")
  valid_774249 = validateParameter(valid_774249, JString, required = false,
                                 default = nil)
  if valid_774249 != nil:
    section.add "X-Amz-Algorithm", valid_774249
  var valid_774250 = header.getOrDefault("X-Amz-Signature")
  valid_774250 = validateParameter(valid_774250, JString, required = false,
                                 default = nil)
  if valid_774250 != nil:
    section.add "X-Amz-Signature", valid_774250
  var valid_774251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774251 = validateParameter(valid_774251, JString, required = false,
                                 default = nil)
  if valid_774251 != nil:
    section.add "X-Amz-SignedHeaders", valid_774251
  var valid_774252 = header.getOrDefault("X-Amz-Credential")
  valid_774252 = validateParameter(valid_774252, JString, required = false,
                                 default = nil)
  if valid_774252 != nil:
    section.add "X-Amz-Credential", valid_774252
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774253 = formData.getOrDefault("Marker")
  valid_774253 = validateParameter(valid_774253, JString, required = false,
                                 default = nil)
  if valid_774253 != nil:
    section.add "Marker", valid_774253
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_774254 = formData.getOrDefault("DBParameterGroupFamily")
  valid_774254 = validateParameter(valid_774254, JString, required = true,
                                 default = nil)
  if valid_774254 != nil:
    section.add "DBParameterGroupFamily", valid_774254
  var valid_774255 = formData.getOrDefault("MaxRecords")
  valid_774255 = validateParameter(valid_774255, JInt, required = false, default = nil)
  if valid_774255 != nil:
    section.add "MaxRecords", valid_774255
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774256: Call_PostDescribeEngineDefaultParameters_774241;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774256.validator(path, query, header, formData, body)
  let scheme = call_774256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774256.url(scheme.get, call_774256.host, call_774256.base,
                         call_774256.route, valid.getOrDefault("path"))
  result = hook(call_774256, url, valid)

proc call*(call_774257: Call_PostDescribeEngineDefaultParameters_774241;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_774258 = newJObject()
  var formData_774259 = newJObject()
  add(formData_774259, "Marker", newJString(Marker))
  add(query_774258, "Action", newJString(Action))
  add(formData_774259, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_774259, "MaxRecords", newJInt(MaxRecords))
  add(query_774258, "Version", newJString(Version))
  result = call_774257.call(nil, query_774258, nil, formData_774259, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_774241(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_774242, base: "/",
    url: url_PostDescribeEngineDefaultParameters_774243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_774223 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEngineDefaultParameters_774225(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEngineDefaultParameters_774224(path: JsonNode;
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
  var valid_774226 = query.getOrDefault("MaxRecords")
  valid_774226 = validateParameter(valid_774226, JInt, required = false, default = nil)
  if valid_774226 != nil:
    section.add "MaxRecords", valid_774226
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_774227 = query.getOrDefault("DBParameterGroupFamily")
  valid_774227 = validateParameter(valid_774227, JString, required = true,
                                 default = nil)
  if valid_774227 != nil:
    section.add "DBParameterGroupFamily", valid_774227
  var valid_774228 = query.getOrDefault("Action")
  valid_774228 = validateParameter(valid_774228, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_774228 != nil:
    section.add "Action", valid_774228
  var valid_774229 = query.getOrDefault("Marker")
  valid_774229 = validateParameter(valid_774229, JString, required = false,
                                 default = nil)
  if valid_774229 != nil:
    section.add "Marker", valid_774229
  var valid_774230 = query.getOrDefault("Version")
  valid_774230 = validateParameter(valid_774230, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774230 != nil:
    section.add "Version", valid_774230
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774231 = header.getOrDefault("X-Amz-Date")
  valid_774231 = validateParameter(valid_774231, JString, required = false,
                                 default = nil)
  if valid_774231 != nil:
    section.add "X-Amz-Date", valid_774231
  var valid_774232 = header.getOrDefault("X-Amz-Security-Token")
  valid_774232 = validateParameter(valid_774232, JString, required = false,
                                 default = nil)
  if valid_774232 != nil:
    section.add "X-Amz-Security-Token", valid_774232
  var valid_774233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774233 = validateParameter(valid_774233, JString, required = false,
                                 default = nil)
  if valid_774233 != nil:
    section.add "X-Amz-Content-Sha256", valid_774233
  var valid_774234 = header.getOrDefault("X-Amz-Algorithm")
  valid_774234 = validateParameter(valid_774234, JString, required = false,
                                 default = nil)
  if valid_774234 != nil:
    section.add "X-Amz-Algorithm", valid_774234
  var valid_774235 = header.getOrDefault("X-Amz-Signature")
  valid_774235 = validateParameter(valid_774235, JString, required = false,
                                 default = nil)
  if valid_774235 != nil:
    section.add "X-Amz-Signature", valid_774235
  var valid_774236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774236 = validateParameter(valid_774236, JString, required = false,
                                 default = nil)
  if valid_774236 != nil:
    section.add "X-Amz-SignedHeaders", valid_774236
  var valid_774237 = header.getOrDefault("X-Amz-Credential")
  valid_774237 = validateParameter(valid_774237, JString, required = false,
                                 default = nil)
  if valid_774237 != nil:
    section.add "X-Amz-Credential", valid_774237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774238: Call_GetDescribeEngineDefaultParameters_774223;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774238.validator(path, query, header, formData, body)
  let scheme = call_774238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774238.url(scheme.get, call_774238.host, call_774238.base,
                         call_774238.route, valid.getOrDefault("path"))
  result = hook(call_774238, url, valid)

proc call*(call_774239: Call_GetDescribeEngineDefaultParameters_774223;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_774240 = newJObject()
  add(query_774240, "MaxRecords", newJInt(MaxRecords))
  add(query_774240, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_774240, "Action", newJString(Action))
  add(query_774240, "Marker", newJString(Marker))
  add(query_774240, "Version", newJString(Version))
  result = call_774239.call(nil, query_774240, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_774223(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_774224, base: "/",
    url: url_GetDescribeEngineDefaultParameters_774225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_774276 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEventCategories_774278(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventCategories_774277(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774279 = query.getOrDefault("Action")
  valid_774279 = validateParameter(valid_774279, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_774279 != nil:
    section.add "Action", valid_774279
  var valid_774280 = query.getOrDefault("Version")
  valid_774280 = validateParameter(valid_774280, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774280 != nil:
    section.add "Version", valid_774280
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774281 = header.getOrDefault("X-Amz-Date")
  valid_774281 = validateParameter(valid_774281, JString, required = false,
                                 default = nil)
  if valid_774281 != nil:
    section.add "X-Amz-Date", valid_774281
  var valid_774282 = header.getOrDefault("X-Amz-Security-Token")
  valid_774282 = validateParameter(valid_774282, JString, required = false,
                                 default = nil)
  if valid_774282 != nil:
    section.add "X-Amz-Security-Token", valid_774282
  var valid_774283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774283 = validateParameter(valid_774283, JString, required = false,
                                 default = nil)
  if valid_774283 != nil:
    section.add "X-Amz-Content-Sha256", valid_774283
  var valid_774284 = header.getOrDefault("X-Amz-Algorithm")
  valid_774284 = validateParameter(valid_774284, JString, required = false,
                                 default = nil)
  if valid_774284 != nil:
    section.add "X-Amz-Algorithm", valid_774284
  var valid_774285 = header.getOrDefault("X-Amz-Signature")
  valid_774285 = validateParameter(valid_774285, JString, required = false,
                                 default = nil)
  if valid_774285 != nil:
    section.add "X-Amz-Signature", valid_774285
  var valid_774286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774286 = validateParameter(valid_774286, JString, required = false,
                                 default = nil)
  if valid_774286 != nil:
    section.add "X-Amz-SignedHeaders", valid_774286
  var valid_774287 = header.getOrDefault("X-Amz-Credential")
  valid_774287 = validateParameter(valid_774287, JString, required = false,
                                 default = nil)
  if valid_774287 != nil:
    section.add "X-Amz-Credential", valid_774287
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_774288 = formData.getOrDefault("SourceType")
  valid_774288 = validateParameter(valid_774288, JString, required = false,
                                 default = nil)
  if valid_774288 != nil:
    section.add "SourceType", valid_774288
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774289: Call_PostDescribeEventCategories_774276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774289.validator(path, query, header, formData, body)
  let scheme = call_774289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774289.url(scheme.get, call_774289.host, call_774289.base,
                         call_774289.route, valid.getOrDefault("path"))
  result = hook(call_774289, url, valid)

proc call*(call_774290: Call_PostDescribeEventCategories_774276;
          Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_774291 = newJObject()
  var formData_774292 = newJObject()
  add(query_774291, "Action", newJString(Action))
  add(query_774291, "Version", newJString(Version))
  add(formData_774292, "SourceType", newJString(SourceType))
  result = call_774290.call(nil, query_774291, nil, formData_774292, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_774276(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_774277, base: "/",
    url: url_PostDescribeEventCategories_774278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_774260 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEventCategories_774262(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventCategories_774261(path: JsonNode; query: JsonNode;
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
  var valid_774263 = query.getOrDefault("SourceType")
  valid_774263 = validateParameter(valid_774263, JString, required = false,
                                 default = nil)
  if valid_774263 != nil:
    section.add "SourceType", valid_774263
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774264 = query.getOrDefault("Action")
  valid_774264 = validateParameter(valid_774264, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_774264 != nil:
    section.add "Action", valid_774264
  var valid_774265 = query.getOrDefault("Version")
  valid_774265 = validateParameter(valid_774265, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774265 != nil:
    section.add "Version", valid_774265
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774266 = header.getOrDefault("X-Amz-Date")
  valid_774266 = validateParameter(valid_774266, JString, required = false,
                                 default = nil)
  if valid_774266 != nil:
    section.add "X-Amz-Date", valid_774266
  var valid_774267 = header.getOrDefault("X-Amz-Security-Token")
  valid_774267 = validateParameter(valid_774267, JString, required = false,
                                 default = nil)
  if valid_774267 != nil:
    section.add "X-Amz-Security-Token", valid_774267
  var valid_774268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774268 = validateParameter(valid_774268, JString, required = false,
                                 default = nil)
  if valid_774268 != nil:
    section.add "X-Amz-Content-Sha256", valid_774268
  var valid_774269 = header.getOrDefault("X-Amz-Algorithm")
  valid_774269 = validateParameter(valid_774269, JString, required = false,
                                 default = nil)
  if valid_774269 != nil:
    section.add "X-Amz-Algorithm", valid_774269
  var valid_774270 = header.getOrDefault("X-Amz-Signature")
  valid_774270 = validateParameter(valid_774270, JString, required = false,
                                 default = nil)
  if valid_774270 != nil:
    section.add "X-Amz-Signature", valid_774270
  var valid_774271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774271 = validateParameter(valid_774271, JString, required = false,
                                 default = nil)
  if valid_774271 != nil:
    section.add "X-Amz-SignedHeaders", valid_774271
  var valid_774272 = header.getOrDefault("X-Amz-Credential")
  valid_774272 = validateParameter(valid_774272, JString, required = false,
                                 default = nil)
  if valid_774272 != nil:
    section.add "X-Amz-Credential", valid_774272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774273: Call_GetDescribeEventCategories_774260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774273.validator(path, query, header, formData, body)
  let scheme = call_774273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774273.url(scheme.get, call_774273.host, call_774273.base,
                         call_774273.route, valid.getOrDefault("path"))
  result = hook(call_774273, url, valid)

proc call*(call_774274: Call_GetDescribeEventCategories_774260;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774275 = newJObject()
  add(query_774275, "SourceType", newJString(SourceType))
  add(query_774275, "Action", newJString(Action))
  add(query_774275, "Version", newJString(Version))
  result = call_774274.call(nil, query_774275, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_774260(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_774261, base: "/",
    url: url_GetDescribeEventCategories_774262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_774311 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEventSubscriptions_774313(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventSubscriptions_774312(path: JsonNode;
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
  var valid_774314 = query.getOrDefault("Action")
  valid_774314 = validateParameter(valid_774314, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_774314 != nil:
    section.add "Action", valid_774314
  var valid_774315 = query.getOrDefault("Version")
  valid_774315 = validateParameter(valid_774315, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774315 != nil:
    section.add "Version", valid_774315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774316 = header.getOrDefault("X-Amz-Date")
  valid_774316 = validateParameter(valid_774316, JString, required = false,
                                 default = nil)
  if valid_774316 != nil:
    section.add "X-Amz-Date", valid_774316
  var valid_774317 = header.getOrDefault("X-Amz-Security-Token")
  valid_774317 = validateParameter(valid_774317, JString, required = false,
                                 default = nil)
  if valid_774317 != nil:
    section.add "X-Amz-Security-Token", valid_774317
  var valid_774318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774318 = validateParameter(valid_774318, JString, required = false,
                                 default = nil)
  if valid_774318 != nil:
    section.add "X-Amz-Content-Sha256", valid_774318
  var valid_774319 = header.getOrDefault("X-Amz-Algorithm")
  valid_774319 = validateParameter(valid_774319, JString, required = false,
                                 default = nil)
  if valid_774319 != nil:
    section.add "X-Amz-Algorithm", valid_774319
  var valid_774320 = header.getOrDefault("X-Amz-Signature")
  valid_774320 = validateParameter(valid_774320, JString, required = false,
                                 default = nil)
  if valid_774320 != nil:
    section.add "X-Amz-Signature", valid_774320
  var valid_774321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774321 = validateParameter(valid_774321, JString, required = false,
                                 default = nil)
  if valid_774321 != nil:
    section.add "X-Amz-SignedHeaders", valid_774321
  var valid_774322 = header.getOrDefault("X-Amz-Credential")
  valid_774322 = validateParameter(valid_774322, JString, required = false,
                                 default = nil)
  if valid_774322 != nil:
    section.add "X-Amz-Credential", valid_774322
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774323 = formData.getOrDefault("Marker")
  valid_774323 = validateParameter(valid_774323, JString, required = false,
                                 default = nil)
  if valid_774323 != nil:
    section.add "Marker", valid_774323
  var valid_774324 = formData.getOrDefault("SubscriptionName")
  valid_774324 = validateParameter(valid_774324, JString, required = false,
                                 default = nil)
  if valid_774324 != nil:
    section.add "SubscriptionName", valid_774324
  var valid_774325 = formData.getOrDefault("MaxRecords")
  valid_774325 = validateParameter(valid_774325, JInt, required = false, default = nil)
  if valid_774325 != nil:
    section.add "MaxRecords", valid_774325
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774326: Call_PostDescribeEventSubscriptions_774311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774326.validator(path, query, header, formData, body)
  let scheme = call_774326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774326.url(scheme.get, call_774326.host, call_774326.base,
                         call_774326.route, valid.getOrDefault("path"))
  result = hook(call_774326, url, valid)

proc call*(call_774327: Call_PostDescribeEventSubscriptions_774311;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_774328 = newJObject()
  var formData_774329 = newJObject()
  add(formData_774329, "Marker", newJString(Marker))
  add(formData_774329, "SubscriptionName", newJString(SubscriptionName))
  add(query_774328, "Action", newJString(Action))
  add(formData_774329, "MaxRecords", newJInt(MaxRecords))
  add(query_774328, "Version", newJString(Version))
  result = call_774327.call(nil, query_774328, nil, formData_774329, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_774311(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_774312, base: "/",
    url: url_PostDescribeEventSubscriptions_774313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_774293 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEventSubscriptions_774295(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventSubscriptions_774294(path: JsonNode; query: JsonNode;
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
  var valid_774296 = query.getOrDefault("MaxRecords")
  valid_774296 = validateParameter(valid_774296, JInt, required = false, default = nil)
  if valid_774296 != nil:
    section.add "MaxRecords", valid_774296
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774297 = query.getOrDefault("Action")
  valid_774297 = validateParameter(valid_774297, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_774297 != nil:
    section.add "Action", valid_774297
  var valid_774298 = query.getOrDefault("Marker")
  valid_774298 = validateParameter(valid_774298, JString, required = false,
                                 default = nil)
  if valid_774298 != nil:
    section.add "Marker", valid_774298
  var valid_774299 = query.getOrDefault("SubscriptionName")
  valid_774299 = validateParameter(valid_774299, JString, required = false,
                                 default = nil)
  if valid_774299 != nil:
    section.add "SubscriptionName", valid_774299
  var valid_774300 = query.getOrDefault("Version")
  valid_774300 = validateParameter(valid_774300, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774300 != nil:
    section.add "Version", valid_774300
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774301 = header.getOrDefault("X-Amz-Date")
  valid_774301 = validateParameter(valid_774301, JString, required = false,
                                 default = nil)
  if valid_774301 != nil:
    section.add "X-Amz-Date", valid_774301
  var valid_774302 = header.getOrDefault("X-Amz-Security-Token")
  valid_774302 = validateParameter(valid_774302, JString, required = false,
                                 default = nil)
  if valid_774302 != nil:
    section.add "X-Amz-Security-Token", valid_774302
  var valid_774303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774303 = validateParameter(valid_774303, JString, required = false,
                                 default = nil)
  if valid_774303 != nil:
    section.add "X-Amz-Content-Sha256", valid_774303
  var valid_774304 = header.getOrDefault("X-Amz-Algorithm")
  valid_774304 = validateParameter(valid_774304, JString, required = false,
                                 default = nil)
  if valid_774304 != nil:
    section.add "X-Amz-Algorithm", valid_774304
  var valid_774305 = header.getOrDefault("X-Amz-Signature")
  valid_774305 = validateParameter(valid_774305, JString, required = false,
                                 default = nil)
  if valid_774305 != nil:
    section.add "X-Amz-Signature", valid_774305
  var valid_774306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774306 = validateParameter(valid_774306, JString, required = false,
                                 default = nil)
  if valid_774306 != nil:
    section.add "X-Amz-SignedHeaders", valid_774306
  var valid_774307 = header.getOrDefault("X-Amz-Credential")
  valid_774307 = validateParameter(valid_774307, JString, required = false,
                                 default = nil)
  if valid_774307 != nil:
    section.add "X-Amz-Credential", valid_774307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774308: Call_GetDescribeEventSubscriptions_774293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774308.validator(path, query, header, formData, body)
  let scheme = call_774308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774308.url(scheme.get, call_774308.host, call_774308.base,
                         call_774308.route, valid.getOrDefault("path"))
  result = hook(call_774308, url, valid)

proc call*(call_774309: Call_GetDescribeEventSubscriptions_774293;
          MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
          Marker: string = ""; SubscriptionName: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_774310 = newJObject()
  add(query_774310, "MaxRecords", newJInt(MaxRecords))
  add(query_774310, "Action", newJString(Action))
  add(query_774310, "Marker", newJString(Marker))
  add(query_774310, "SubscriptionName", newJString(SubscriptionName))
  add(query_774310, "Version", newJString(Version))
  result = call_774309.call(nil, query_774310, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_774293(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_774294, base: "/",
    url: url_GetDescribeEventSubscriptions_774295,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_774353 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEvents_774355(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_774354(path: JsonNode; query: JsonNode;
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
  var valid_774356 = query.getOrDefault("Action")
  valid_774356 = validateParameter(valid_774356, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_774356 != nil:
    section.add "Action", valid_774356
  var valid_774357 = query.getOrDefault("Version")
  valid_774357 = validateParameter(valid_774357, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   SourceIdentifier: JString
  ##   EventCategories: JArray
  ##   Marker: JString
  ##   StartTime: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   MaxRecords: JInt
  ##   SourceType: JString
  section = newJObject()
  var valid_774365 = formData.getOrDefault("SourceIdentifier")
  valid_774365 = validateParameter(valid_774365, JString, required = false,
                                 default = nil)
  if valid_774365 != nil:
    section.add "SourceIdentifier", valid_774365
  var valid_774366 = formData.getOrDefault("EventCategories")
  valid_774366 = validateParameter(valid_774366, JArray, required = false,
                                 default = nil)
  if valid_774366 != nil:
    section.add "EventCategories", valid_774366
  var valid_774367 = formData.getOrDefault("Marker")
  valid_774367 = validateParameter(valid_774367, JString, required = false,
                                 default = nil)
  if valid_774367 != nil:
    section.add "Marker", valid_774367
  var valid_774368 = formData.getOrDefault("StartTime")
  valid_774368 = validateParameter(valid_774368, JString, required = false,
                                 default = nil)
  if valid_774368 != nil:
    section.add "StartTime", valid_774368
  var valid_774369 = formData.getOrDefault("Duration")
  valid_774369 = validateParameter(valid_774369, JInt, required = false, default = nil)
  if valid_774369 != nil:
    section.add "Duration", valid_774369
  var valid_774370 = formData.getOrDefault("EndTime")
  valid_774370 = validateParameter(valid_774370, JString, required = false,
                                 default = nil)
  if valid_774370 != nil:
    section.add "EndTime", valid_774370
  var valid_774371 = formData.getOrDefault("MaxRecords")
  valid_774371 = validateParameter(valid_774371, JInt, required = false, default = nil)
  if valid_774371 != nil:
    section.add "MaxRecords", valid_774371
  var valid_774372 = formData.getOrDefault("SourceType")
  valid_774372 = validateParameter(valid_774372, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_774372 != nil:
    section.add "SourceType", valid_774372
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774373: Call_PostDescribeEvents_774353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774373.validator(path, query, header, formData, body)
  let scheme = call_774373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774373.url(scheme.get, call_774373.host, call_774373.base,
                         call_774373.route, valid.getOrDefault("path"))
  result = hook(call_774373, url, valid)

proc call*(call_774374: Call_PostDescribeEvents_774353;
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
  var query_774375 = newJObject()
  var formData_774376 = newJObject()
  add(formData_774376, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_774376.add "EventCategories", EventCategories
  add(formData_774376, "Marker", newJString(Marker))
  add(formData_774376, "StartTime", newJString(StartTime))
  add(query_774375, "Action", newJString(Action))
  add(formData_774376, "Duration", newJInt(Duration))
  add(formData_774376, "EndTime", newJString(EndTime))
  add(formData_774376, "MaxRecords", newJInt(MaxRecords))
  add(query_774375, "Version", newJString(Version))
  add(formData_774376, "SourceType", newJString(SourceType))
  result = call_774374.call(nil, query_774375, nil, formData_774376, nil)

var postDescribeEvents* = Call_PostDescribeEvents_774353(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_774354, base: "/",
    url: url_PostDescribeEvents_774355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_774330 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEvents_774332(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_774331(path: JsonNode; query: JsonNode;
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
  var valid_774333 = query.getOrDefault("SourceType")
  valid_774333 = validateParameter(valid_774333, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_774333 != nil:
    section.add "SourceType", valid_774333
  var valid_774334 = query.getOrDefault("MaxRecords")
  valid_774334 = validateParameter(valid_774334, JInt, required = false, default = nil)
  if valid_774334 != nil:
    section.add "MaxRecords", valid_774334
  var valid_774335 = query.getOrDefault("StartTime")
  valid_774335 = validateParameter(valid_774335, JString, required = false,
                                 default = nil)
  if valid_774335 != nil:
    section.add "StartTime", valid_774335
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774336 = query.getOrDefault("Action")
  valid_774336 = validateParameter(valid_774336, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_774336 != nil:
    section.add "Action", valid_774336
  var valid_774337 = query.getOrDefault("SourceIdentifier")
  valid_774337 = validateParameter(valid_774337, JString, required = false,
                                 default = nil)
  if valid_774337 != nil:
    section.add "SourceIdentifier", valid_774337
  var valid_774338 = query.getOrDefault("Marker")
  valid_774338 = validateParameter(valid_774338, JString, required = false,
                                 default = nil)
  if valid_774338 != nil:
    section.add "Marker", valid_774338
  var valid_774339 = query.getOrDefault("EventCategories")
  valid_774339 = validateParameter(valid_774339, JArray, required = false,
                                 default = nil)
  if valid_774339 != nil:
    section.add "EventCategories", valid_774339
  var valid_774340 = query.getOrDefault("Duration")
  valid_774340 = validateParameter(valid_774340, JInt, required = false, default = nil)
  if valid_774340 != nil:
    section.add "Duration", valid_774340
  var valid_774341 = query.getOrDefault("EndTime")
  valid_774341 = validateParameter(valid_774341, JString, required = false,
                                 default = nil)
  if valid_774341 != nil:
    section.add "EndTime", valid_774341
  var valid_774342 = query.getOrDefault("Version")
  valid_774342 = validateParameter(valid_774342, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774342 != nil:
    section.add "Version", valid_774342
  result.add "query", section
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

proc call*(call_774350: Call_GetDescribeEvents_774330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774350.validator(path, query, header, formData, body)
  let scheme = call_774350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774350.url(scheme.get, call_774350.host, call_774350.base,
                         call_774350.route, valid.getOrDefault("path"))
  result = hook(call_774350, url, valid)

proc call*(call_774351: Call_GetDescribeEvents_774330;
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
  var query_774352 = newJObject()
  add(query_774352, "SourceType", newJString(SourceType))
  add(query_774352, "MaxRecords", newJInt(MaxRecords))
  add(query_774352, "StartTime", newJString(StartTime))
  add(query_774352, "Action", newJString(Action))
  add(query_774352, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_774352, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_774352.add "EventCategories", EventCategories
  add(query_774352, "Duration", newJInt(Duration))
  add(query_774352, "EndTime", newJString(EndTime))
  add(query_774352, "Version", newJString(Version))
  result = call_774351.call(nil, query_774352, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_774330(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_774331,
    base: "/", url: url_GetDescribeEvents_774332,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_774396 = ref object of OpenApiRestCall_772581
proc url_PostDescribeOptionGroupOptions_774398(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroupOptions_774397(path: JsonNode;
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
  var valid_774399 = query.getOrDefault("Action")
  valid_774399 = validateParameter(valid_774399, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_774399 != nil:
    section.add "Action", valid_774399
  var valid_774400 = query.getOrDefault("Version")
  valid_774400 = validateParameter(valid_774400, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774400 != nil:
    section.add "Version", valid_774400
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774401 = header.getOrDefault("X-Amz-Date")
  valid_774401 = validateParameter(valid_774401, JString, required = false,
                                 default = nil)
  if valid_774401 != nil:
    section.add "X-Amz-Date", valid_774401
  var valid_774402 = header.getOrDefault("X-Amz-Security-Token")
  valid_774402 = validateParameter(valid_774402, JString, required = false,
                                 default = nil)
  if valid_774402 != nil:
    section.add "X-Amz-Security-Token", valid_774402
  var valid_774403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774403 = validateParameter(valid_774403, JString, required = false,
                                 default = nil)
  if valid_774403 != nil:
    section.add "X-Amz-Content-Sha256", valid_774403
  var valid_774404 = header.getOrDefault("X-Amz-Algorithm")
  valid_774404 = validateParameter(valid_774404, JString, required = false,
                                 default = nil)
  if valid_774404 != nil:
    section.add "X-Amz-Algorithm", valid_774404
  var valid_774405 = header.getOrDefault("X-Amz-Signature")
  valid_774405 = validateParameter(valid_774405, JString, required = false,
                                 default = nil)
  if valid_774405 != nil:
    section.add "X-Amz-Signature", valid_774405
  var valid_774406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774406 = validateParameter(valid_774406, JString, required = false,
                                 default = nil)
  if valid_774406 != nil:
    section.add "X-Amz-SignedHeaders", valid_774406
  var valid_774407 = header.getOrDefault("X-Amz-Credential")
  valid_774407 = validateParameter(valid_774407, JString, required = false,
                                 default = nil)
  if valid_774407 != nil:
    section.add "X-Amz-Credential", valid_774407
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774408 = formData.getOrDefault("MajorEngineVersion")
  valid_774408 = validateParameter(valid_774408, JString, required = false,
                                 default = nil)
  if valid_774408 != nil:
    section.add "MajorEngineVersion", valid_774408
  var valid_774409 = formData.getOrDefault("Marker")
  valid_774409 = validateParameter(valid_774409, JString, required = false,
                                 default = nil)
  if valid_774409 != nil:
    section.add "Marker", valid_774409
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_774410 = formData.getOrDefault("EngineName")
  valid_774410 = validateParameter(valid_774410, JString, required = true,
                                 default = nil)
  if valid_774410 != nil:
    section.add "EngineName", valid_774410
  var valid_774411 = formData.getOrDefault("MaxRecords")
  valid_774411 = validateParameter(valid_774411, JInt, required = false, default = nil)
  if valid_774411 != nil:
    section.add "MaxRecords", valid_774411
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774412: Call_PostDescribeOptionGroupOptions_774396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774412.validator(path, query, header, formData, body)
  let scheme = call_774412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774412.url(scheme.get, call_774412.host, call_774412.base,
                         call_774412.route, valid.getOrDefault("path"))
  result = hook(call_774412, url, valid)

proc call*(call_774413: Call_PostDescribeOptionGroupOptions_774396;
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
  var query_774414 = newJObject()
  var formData_774415 = newJObject()
  add(formData_774415, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_774415, "Marker", newJString(Marker))
  add(query_774414, "Action", newJString(Action))
  add(formData_774415, "EngineName", newJString(EngineName))
  add(formData_774415, "MaxRecords", newJInt(MaxRecords))
  add(query_774414, "Version", newJString(Version))
  result = call_774413.call(nil, query_774414, nil, formData_774415, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_774396(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_774397, base: "/",
    url: url_PostDescribeOptionGroupOptions_774398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_774377 = ref object of OpenApiRestCall_772581
proc url_GetDescribeOptionGroupOptions_774379(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroupOptions_774378(path: JsonNode; query: JsonNode;
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
  var valid_774380 = query.getOrDefault("MaxRecords")
  valid_774380 = validateParameter(valid_774380, JInt, required = false, default = nil)
  if valid_774380 != nil:
    section.add "MaxRecords", valid_774380
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774381 = query.getOrDefault("Action")
  valid_774381 = validateParameter(valid_774381, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_774381 != nil:
    section.add "Action", valid_774381
  var valid_774382 = query.getOrDefault("Marker")
  valid_774382 = validateParameter(valid_774382, JString, required = false,
                                 default = nil)
  if valid_774382 != nil:
    section.add "Marker", valid_774382
  var valid_774383 = query.getOrDefault("Version")
  valid_774383 = validateParameter(valid_774383, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774383 != nil:
    section.add "Version", valid_774383
  var valid_774384 = query.getOrDefault("EngineName")
  valid_774384 = validateParameter(valid_774384, JString, required = true,
                                 default = nil)
  if valid_774384 != nil:
    section.add "EngineName", valid_774384
  var valid_774385 = query.getOrDefault("MajorEngineVersion")
  valid_774385 = validateParameter(valid_774385, JString, required = false,
                                 default = nil)
  if valid_774385 != nil:
    section.add "MajorEngineVersion", valid_774385
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774386 = header.getOrDefault("X-Amz-Date")
  valid_774386 = validateParameter(valid_774386, JString, required = false,
                                 default = nil)
  if valid_774386 != nil:
    section.add "X-Amz-Date", valid_774386
  var valid_774387 = header.getOrDefault("X-Amz-Security-Token")
  valid_774387 = validateParameter(valid_774387, JString, required = false,
                                 default = nil)
  if valid_774387 != nil:
    section.add "X-Amz-Security-Token", valid_774387
  var valid_774388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774388 = validateParameter(valid_774388, JString, required = false,
                                 default = nil)
  if valid_774388 != nil:
    section.add "X-Amz-Content-Sha256", valid_774388
  var valid_774389 = header.getOrDefault("X-Amz-Algorithm")
  valid_774389 = validateParameter(valid_774389, JString, required = false,
                                 default = nil)
  if valid_774389 != nil:
    section.add "X-Amz-Algorithm", valid_774389
  var valid_774390 = header.getOrDefault("X-Amz-Signature")
  valid_774390 = validateParameter(valid_774390, JString, required = false,
                                 default = nil)
  if valid_774390 != nil:
    section.add "X-Amz-Signature", valid_774390
  var valid_774391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774391 = validateParameter(valid_774391, JString, required = false,
                                 default = nil)
  if valid_774391 != nil:
    section.add "X-Amz-SignedHeaders", valid_774391
  var valid_774392 = header.getOrDefault("X-Amz-Credential")
  valid_774392 = validateParameter(valid_774392, JString, required = false,
                                 default = nil)
  if valid_774392 != nil:
    section.add "X-Amz-Credential", valid_774392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774393: Call_GetDescribeOptionGroupOptions_774377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774393.validator(path, query, header, formData, body)
  let scheme = call_774393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774393.url(scheme.get, call_774393.host, call_774393.base,
                         call_774393.route, valid.getOrDefault("path"))
  result = hook(call_774393, url, valid)

proc call*(call_774394: Call_GetDescribeOptionGroupOptions_774377;
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
  var query_774395 = newJObject()
  add(query_774395, "MaxRecords", newJInt(MaxRecords))
  add(query_774395, "Action", newJString(Action))
  add(query_774395, "Marker", newJString(Marker))
  add(query_774395, "Version", newJString(Version))
  add(query_774395, "EngineName", newJString(EngineName))
  add(query_774395, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_774394.call(nil, query_774395, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_774377(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_774378, base: "/",
    url: url_GetDescribeOptionGroupOptions_774379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_774436 = ref object of OpenApiRestCall_772581
proc url_PostDescribeOptionGroups_774438(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroups_774437(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_774439 = validateParameter(valid_774439, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_774439 != nil:
    section.add "Action", valid_774439
  var valid_774440 = query.getOrDefault("Version")
  valid_774440 = validateParameter(valid_774440, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774448 = formData.getOrDefault("MajorEngineVersion")
  valid_774448 = validateParameter(valid_774448, JString, required = false,
                                 default = nil)
  if valid_774448 != nil:
    section.add "MajorEngineVersion", valid_774448
  var valid_774449 = formData.getOrDefault("OptionGroupName")
  valid_774449 = validateParameter(valid_774449, JString, required = false,
                                 default = nil)
  if valid_774449 != nil:
    section.add "OptionGroupName", valid_774449
  var valid_774450 = formData.getOrDefault("Marker")
  valid_774450 = validateParameter(valid_774450, JString, required = false,
                                 default = nil)
  if valid_774450 != nil:
    section.add "Marker", valid_774450
  var valid_774451 = formData.getOrDefault("EngineName")
  valid_774451 = validateParameter(valid_774451, JString, required = false,
                                 default = nil)
  if valid_774451 != nil:
    section.add "EngineName", valid_774451
  var valid_774452 = formData.getOrDefault("MaxRecords")
  valid_774452 = validateParameter(valid_774452, JInt, required = false, default = nil)
  if valid_774452 != nil:
    section.add "MaxRecords", valid_774452
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774453: Call_PostDescribeOptionGroups_774436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774453.validator(path, query, header, formData, body)
  let scheme = call_774453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774453.url(scheme.get, call_774453.host, call_774453.base,
                         call_774453.route, valid.getOrDefault("path"))
  result = hook(call_774453, url, valid)

proc call*(call_774454: Call_PostDescribeOptionGroups_774436;
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
  var query_774455 = newJObject()
  var formData_774456 = newJObject()
  add(formData_774456, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_774456, "OptionGroupName", newJString(OptionGroupName))
  add(formData_774456, "Marker", newJString(Marker))
  add(query_774455, "Action", newJString(Action))
  add(formData_774456, "EngineName", newJString(EngineName))
  add(formData_774456, "MaxRecords", newJInt(MaxRecords))
  add(query_774455, "Version", newJString(Version))
  result = call_774454.call(nil, query_774455, nil, formData_774456, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_774436(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_774437, base: "/",
    url: url_PostDescribeOptionGroups_774438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_774416 = ref object of OpenApiRestCall_772581
proc url_GetDescribeOptionGroups_774418(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroups_774417(path: JsonNode; query: JsonNode;
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
  var valid_774419 = query.getOrDefault("MaxRecords")
  valid_774419 = validateParameter(valid_774419, JInt, required = false, default = nil)
  if valid_774419 != nil:
    section.add "MaxRecords", valid_774419
  var valid_774420 = query.getOrDefault("OptionGroupName")
  valid_774420 = validateParameter(valid_774420, JString, required = false,
                                 default = nil)
  if valid_774420 != nil:
    section.add "OptionGroupName", valid_774420
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774421 = query.getOrDefault("Action")
  valid_774421 = validateParameter(valid_774421, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_774421 != nil:
    section.add "Action", valid_774421
  var valid_774422 = query.getOrDefault("Marker")
  valid_774422 = validateParameter(valid_774422, JString, required = false,
                                 default = nil)
  if valid_774422 != nil:
    section.add "Marker", valid_774422
  var valid_774423 = query.getOrDefault("Version")
  valid_774423 = validateParameter(valid_774423, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774423 != nil:
    section.add "Version", valid_774423
  var valid_774424 = query.getOrDefault("EngineName")
  valid_774424 = validateParameter(valid_774424, JString, required = false,
                                 default = nil)
  if valid_774424 != nil:
    section.add "EngineName", valid_774424
  var valid_774425 = query.getOrDefault("MajorEngineVersion")
  valid_774425 = validateParameter(valid_774425, JString, required = false,
                                 default = nil)
  if valid_774425 != nil:
    section.add "MajorEngineVersion", valid_774425
  result.add "query", section
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

proc call*(call_774433: Call_GetDescribeOptionGroups_774416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774433.validator(path, query, header, formData, body)
  let scheme = call_774433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774433.url(scheme.get, call_774433.host, call_774433.base,
                         call_774433.route, valid.getOrDefault("path"))
  result = hook(call_774433, url, valid)

proc call*(call_774434: Call_GetDescribeOptionGroups_774416; MaxRecords: int = 0;
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
  var query_774435 = newJObject()
  add(query_774435, "MaxRecords", newJInt(MaxRecords))
  add(query_774435, "OptionGroupName", newJString(OptionGroupName))
  add(query_774435, "Action", newJString(Action))
  add(query_774435, "Marker", newJString(Marker))
  add(query_774435, "Version", newJString(Version))
  add(query_774435, "EngineName", newJString(EngineName))
  add(query_774435, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_774434.call(nil, query_774435, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_774416(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_774417, base: "/",
    url: url_GetDescribeOptionGroups_774418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_774479 = ref object of OpenApiRestCall_772581
proc url_PostDescribeOrderableDBInstanceOptions_774481(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOrderableDBInstanceOptions_774480(path: JsonNode;
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
  var valid_774482 = query.getOrDefault("Action")
  valid_774482 = validateParameter(valid_774482, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_774482 != nil:
    section.add "Action", valid_774482
  var valid_774483 = query.getOrDefault("Version")
  valid_774483 = validateParameter(valid_774483, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774483 != nil:
    section.add "Version", valid_774483
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774484 = header.getOrDefault("X-Amz-Date")
  valid_774484 = validateParameter(valid_774484, JString, required = false,
                                 default = nil)
  if valid_774484 != nil:
    section.add "X-Amz-Date", valid_774484
  var valid_774485 = header.getOrDefault("X-Amz-Security-Token")
  valid_774485 = validateParameter(valid_774485, JString, required = false,
                                 default = nil)
  if valid_774485 != nil:
    section.add "X-Amz-Security-Token", valid_774485
  var valid_774486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774486 = validateParameter(valid_774486, JString, required = false,
                                 default = nil)
  if valid_774486 != nil:
    section.add "X-Amz-Content-Sha256", valid_774486
  var valid_774487 = header.getOrDefault("X-Amz-Algorithm")
  valid_774487 = validateParameter(valid_774487, JString, required = false,
                                 default = nil)
  if valid_774487 != nil:
    section.add "X-Amz-Algorithm", valid_774487
  var valid_774488 = header.getOrDefault("X-Amz-Signature")
  valid_774488 = validateParameter(valid_774488, JString, required = false,
                                 default = nil)
  if valid_774488 != nil:
    section.add "X-Amz-Signature", valid_774488
  var valid_774489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774489 = validateParameter(valid_774489, JString, required = false,
                                 default = nil)
  if valid_774489 != nil:
    section.add "X-Amz-SignedHeaders", valid_774489
  var valid_774490 = header.getOrDefault("X-Amz-Credential")
  valid_774490 = validateParameter(valid_774490, JString, required = false,
                                 default = nil)
  if valid_774490 != nil:
    section.add "X-Amz-Credential", valid_774490
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
  var valid_774491 = formData.getOrDefault("Engine")
  valid_774491 = validateParameter(valid_774491, JString, required = true,
                                 default = nil)
  if valid_774491 != nil:
    section.add "Engine", valid_774491
  var valid_774492 = formData.getOrDefault("Marker")
  valid_774492 = validateParameter(valid_774492, JString, required = false,
                                 default = nil)
  if valid_774492 != nil:
    section.add "Marker", valid_774492
  var valid_774493 = formData.getOrDefault("Vpc")
  valid_774493 = validateParameter(valid_774493, JBool, required = false, default = nil)
  if valid_774493 != nil:
    section.add "Vpc", valid_774493
  var valid_774494 = formData.getOrDefault("DBInstanceClass")
  valid_774494 = validateParameter(valid_774494, JString, required = false,
                                 default = nil)
  if valid_774494 != nil:
    section.add "DBInstanceClass", valid_774494
  var valid_774495 = formData.getOrDefault("LicenseModel")
  valid_774495 = validateParameter(valid_774495, JString, required = false,
                                 default = nil)
  if valid_774495 != nil:
    section.add "LicenseModel", valid_774495
  var valid_774496 = formData.getOrDefault("MaxRecords")
  valid_774496 = validateParameter(valid_774496, JInt, required = false, default = nil)
  if valid_774496 != nil:
    section.add "MaxRecords", valid_774496
  var valid_774497 = formData.getOrDefault("EngineVersion")
  valid_774497 = validateParameter(valid_774497, JString, required = false,
                                 default = nil)
  if valid_774497 != nil:
    section.add "EngineVersion", valid_774497
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774498: Call_PostDescribeOrderableDBInstanceOptions_774479;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774498.validator(path, query, header, formData, body)
  let scheme = call_774498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774498.url(scheme.get, call_774498.host, call_774498.base,
                         call_774498.route, valid.getOrDefault("path"))
  result = hook(call_774498, url, valid)

proc call*(call_774499: Call_PostDescribeOrderableDBInstanceOptions_774479;
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
  var query_774500 = newJObject()
  var formData_774501 = newJObject()
  add(formData_774501, "Engine", newJString(Engine))
  add(formData_774501, "Marker", newJString(Marker))
  add(query_774500, "Action", newJString(Action))
  add(formData_774501, "Vpc", newJBool(Vpc))
  add(formData_774501, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_774501, "LicenseModel", newJString(LicenseModel))
  add(formData_774501, "MaxRecords", newJInt(MaxRecords))
  add(formData_774501, "EngineVersion", newJString(EngineVersion))
  add(query_774500, "Version", newJString(Version))
  result = call_774499.call(nil, query_774500, nil, formData_774501, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_774479(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_774480, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_774481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_774457 = ref object of OpenApiRestCall_772581
proc url_GetDescribeOrderableDBInstanceOptions_774459(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOrderableDBInstanceOptions_774458(path: JsonNode;
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
  var valid_774460 = query.getOrDefault("Engine")
  valid_774460 = validateParameter(valid_774460, JString, required = true,
                                 default = nil)
  if valid_774460 != nil:
    section.add "Engine", valid_774460
  var valid_774461 = query.getOrDefault("MaxRecords")
  valid_774461 = validateParameter(valid_774461, JInt, required = false, default = nil)
  if valid_774461 != nil:
    section.add "MaxRecords", valid_774461
  var valid_774462 = query.getOrDefault("LicenseModel")
  valid_774462 = validateParameter(valid_774462, JString, required = false,
                                 default = nil)
  if valid_774462 != nil:
    section.add "LicenseModel", valid_774462
  var valid_774463 = query.getOrDefault("Vpc")
  valid_774463 = validateParameter(valid_774463, JBool, required = false, default = nil)
  if valid_774463 != nil:
    section.add "Vpc", valid_774463
  var valid_774464 = query.getOrDefault("DBInstanceClass")
  valid_774464 = validateParameter(valid_774464, JString, required = false,
                                 default = nil)
  if valid_774464 != nil:
    section.add "DBInstanceClass", valid_774464
  var valid_774465 = query.getOrDefault("Action")
  valid_774465 = validateParameter(valid_774465, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_774465 != nil:
    section.add "Action", valid_774465
  var valid_774466 = query.getOrDefault("Marker")
  valid_774466 = validateParameter(valid_774466, JString, required = false,
                                 default = nil)
  if valid_774466 != nil:
    section.add "Marker", valid_774466
  var valid_774467 = query.getOrDefault("EngineVersion")
  valid_774467 = validateParameter(valid_774467, JString, required = false,
                                 default = nil)
  if valid_774467 != nil:
    section.add "EngineVersion", valid_774467
  var valid_774468 = query.getOrDefault("Version")
  valid_774468 = validateParameter(valid_774468, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774468 != nil:
    section.add "Version", valid_774468
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774469 = header.getOrDefault("X-Amz-Date")
  valid_774469 = validateParameter(valid_774469, JString, required = false,
                                 default = nil)
  if valid_774469 != nil:
    section.add "X-Amz-Date", valid_774469
  var valid_774470 = header.getOrDefault("X-Amz-Security-Token")
  valid_774470 = validateParameter(valid_774470, JString, required = false,
                                 default = nil)
  if valid_774470 != nil:
    section.add "X-Amz-Security-Token", valid_774470
  var valid_774471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774471 = validateParameter(valid_774471, JString, required = false,
                                 default = nil)
  if valid_774471 != nil:
    section.add "X-Amz-Content-Sha256", valid_774471
  var valid_774472 = header.getOrDefault("X-Amz-Algorithm")
  valid_774472 = validateParameter(valid_774472, JString, required = false,
                                 default = nil)
  if valid_774472 != nil:
    section.add "X-Amz-Algorithm", valid_774472
  var valid_774473 = header.getOrDefault("X-Amz-Signature")
  valid_774473 = validateParameter(valid_774473, JString, required = false,
                                 default = nil)
  if valid_774473 != nil:
    section.add "X-Amz-Signature", valid_774473
  var valid_774474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774474 = validateParameter(valid_774474, JString, required = false,
                                 default = nil)
  if valid_774474 != nil:
    section.add "X-Amz-SignedHeaders", valid_774474
  var valid_774475 = header.getOrDefault("X-Amz-Credential")
  valid_774475 = validateParameter(valid_774475, JString, required = false,
                                 default = nil)
  if valid_774475 != nil:
    section.add "X-Amz-Credential", valid_774475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774476: Call_GetDescribeOrderableDBInstanceOptions_774457;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774476.validator(path, query, header, formData, body)
  let scheme = call_774476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774476.url(scheme.get, call_774476.host, call_774476.base,
                         call_774476.route, valid.getOrDefault("path"))
  result = hook(call_774476, url, valid)

proc call*(call_774477: Call_GetDescribeOrderableDBInstanceOptions_774457;
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
  var query_774478 = newJObject()
  add(query_774478, "Engine", newJString(Engine))
  add(query_774478, "MaxRecords", newJInt(MaxRecords))
  add(query_774478, "LicenseModel", newJString(LicenseModel))
  add(query_774478, "Vpc", newJBool(Vpc))
  add(query_774478, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774478, "Action", newJString(Action))
  add(query_774478, "Marker", newJString(Marker))
  add(query_774478, "EngineVersion", newJString(EngineVersion))
  add(query_774478, "Version", newJString(Version))
  result = call_774477.call(nil, query_774478, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_774457(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_774458, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_774459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_774526 = ref object of OpenApiRestCall_772581
proc url_PostDescribeReservedDBInstances_774528(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstances_774527(path: JsonNode;
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
  var valid_774529 = query.getOrDefault("Action")
  valid_774529 = validateParameter(valid_774529, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_774529 != nil:
    section.add "Action", valid_774529
  var valid_774530 = query.getOrDefault("Version")
  valid_774530 = validateParameter(valid_774530, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774530 != nil:
    section.add "Version", valid_774530
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774531 = header.getOrDefault("X-Amz-Date")
  valid_774531 = validateParameter(valid_774531, JString, required = false,
                                 default = nil)
  if valid_774531 != nil:
    section.add "X-Amz-Date", valid_774531
  var valid_774532 = header.getOrDefault("X-Amz-Security-Token")
  valid_774532 = validateParameter(valid_774532, JString, required = false,
                                 default = nil)
  if valid_774532 != nil:
    section.add "X-Amz-Security-Token", valid_774532
  var valid_774533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774533 = validateParameter(valid_774533, JString, required = false,
                                 default = nil)
  if valid_774533 != nil:
    section.add "X-Amz-Content-Sha256", valid_774533
  var valid_774534 = header.getOrDefault("X-Amz-Algorithm")
  valid_774534 = validateParameter(valid_774534, JString, required = false,
                                 default = nil)
  if valid_774534 != nil:
    section.add "X-Amz-Algorithm", valid_774534
  var valid_774535 = header.getOrDefault("X-Amz-Signature")
  valid_774535 = validateParameter(valid_774535, JString, required = false,
                                 default = nil)
  if valid_774535 != nil:
    section.add "X-Amz-Signature", valid_774535
  var valid_774536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774536 = validateParameter(valid_774536, JString, required = false,
                                 default = nil)
  if valid_774536 != nil:
    section.add "X-Amz-SignedHeaders", valid_774536
  var valid_774537 = header.getOrDefault("X-Amz-Credential")
  valid_774537 = validateParameter(valid_774537, JString, required = false,
                                 default = nil)
  if valid_774537 != nil:
    section.add "X-Amz-Credential", valid_774537
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
  var valid_774538 = formData.getOrDefault("OfferingType")
  valid_774538 = validateParameter(valid_774538, JString, required = false,
                                 default = nil)
  if valid_774538 != nil:
    section.add "OfferingType", valid_774538
  var valid_774539 = formData.getOrDefault("ReservedDBInstanceId")
  valid_774539 = validateParameter(valid_774539, JString, required = false,
                                 default = nil)
  if valid_774539 != nil:
    section.add "ReservedDBInstanceId", valid_774539
  var valid_774540 = formData.getOrDefault("Marker")
  valid_774540 = validateParameter(valid_774540, JString, required = false,
                                 default = nil)
  if valid_774540 != nil:
    section.add "Marker", valid_774540
  var valid_774541 = formData.getOrDefault("MultiAZ")
  valid_774541 = validateParameter(valid_774541, JBool, required = false, default = nil)
  if valid_774541 != nil:
    section.add "MultiAZ", valid_774541
  var valid_774542 = formData.getOrDefault("Duration")
  valid_774542 = validateParameter(valid_774542, JString, required = false,
                                 default = nil)
  if valid_774542 != nil:
    section.add "Duration", valid_774542
  var valid_774543 = formData.getOrDefault("DBInstanceClass")
  valid_774543 = validateParameter(valid_774543, JString, required = false,
                                 default = nil)
  if valid_774543 != nil:
    section.add "DBInstanceClass", valid_774543
  var valid_774544 = formData.getOrDefault("ProductDescription")
  valid_774544 = validateParameter(valid_774544, JString, required = false,
                                 default = nil)
  if valid_774544 != nil:
    section.add "ProductDescription", valid_774544
  var valid_774545 = formData.getOrDefault("MaxRecords")
  valid_774545 = validateParameter(valid_774545, JInt, required = false, default = nil)
  if valid_774545 != nil:
    section.add "MaxRecords", valid_774545
  var valid_774546 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774546 = validateParameter(valid_774546, JString, required = false,
                                 default = nil)
  if valid_774546 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774546
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774547: Call_PostDescribeReservedDBInstances_774526;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774547.validator(path, query, header, formData, body)
  let scheme = call_774547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774547.url(scheme.get, call_774547.host, call_774547.base,
                         call_774547.route, valid.getOrDefault("path"))
  result = hook(call_774547, url, valid)

proc call*(call_774548: Call_PostDescribeReservedDBInstances_774526;
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
  var query_774549 = newJObject()
  var formData_774550 = newJObject()
  add(formData_774550, "OfferingType", newJString(OfferingType))
  add(formData_774550, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_774550, "Marker", newJString(Marker))
  add(formData_774550, "MultiAZ", newJBool(MultiAZ))
  add(query_774549, "Action", newJString(Action))
  add(formData_774550, "Duration", newJString(Duration))
  add(formData_774550, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_774550, "ProductDescription", newJString(ProductDescription))
  add(formData_774550, "MaxRecords", newJInt(MaxRecords))
  add(formData_774550, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774549, "Version", newJString(Version))
  result = call_774548.call(nil, query_774549, nil, formData_774550, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_774526(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_774527, base: "/",
    url: url_PostDescribeReservedDBInstances_774528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_774502 = ref object of OpenApiRestCall_772581
proc url_GetDescribeReservedDBInstances_774504(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstances_774503(path: JsonNode;
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
  var valid_774505 = query.getOrDefault("ProductDescription")
  valid_774505 = validateParameter(valid_774505, JString, required = false,
                                 default = nil)
  if valid_774505 != nil:
    section.add "ProductDescription", valid_774505
  var valid_774506 = query.getOrDefault("MaxRecords")
  valid_774506 = validateParameter(valid_774506, JInt, required = false, default = nil)
  if valid_774506 != nil:
    section.add "MaxRecords", valid_774506
  var valid_774507 = query.getOrDefault("OfferingType")
  valid_774507 = validateParameter(valid_774507, JString, required = false,
                                 default = nil)
  if valid_774507 != nil:
    section.add "OfferingType", valid_774507
  var valid_774508 = query.getOrDefault("MultiAZ")
  valid_774508 = validateParameter(valid_774508, JBool, required = false, default = nil)
  if valid_774508 != nil:
    section.add "MultiAZ", valid_774508
  var valid_774509 = query.getOrDefault("ReservedDBInstanceId")
  valid_774509 = validateParameter(valid_774509, JString, required = false,
                                 default = nil)
  if valid_774509 != nil:
    section.add "ReservedDBInstanceId", valid_774509
  var valid_774510 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774510 = validateParameter(valid_774510, JString, required = false,
                                 default = nil)
  if valid_774510 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774510
  var valid_774511 = query.getOrDefault("DBInstanceClass")
  valid_774511 = validateParameter(valid_774511, JString, required = false,
                                 default = nil)
  if valid_774511 != nil:
    section.add "DBInstanceClass", valid_774511
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774512 = query.getOrDefault("Action")
  valid_774512 = validateParameter(valid_774512, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_774512 != nil:
    section.add "Action", valid_774512
  var valid_774513 = query.getOrDefault("Marker")
  valid_774513 = validateParameter(valid_774513, JString, required = false,
                                 default = nil)
  if valid_774513 != nil:
    section.add "Marker", valid_774513
  var valid_774514 = query.getOrDefault("Duration")
  valid_774514 = validateParameter(valid_774514, JString, required = false,
                                 default = nil)
  if valid_774514 != nil:
    section.add "Duration", valid_774514
  var valid_774515 = query.getOrDefault("Version")
  valid_774515 = validateParameter(valid_774515, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774515 != nil:
    section.add "Version", valid_774515
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774516 = header.getOrDefault("X-Amz-Date")
  valid_774516 = validateParameter(valid_774516, JString, required = false,
                                 default = nil)
  if valid_774516 != nil:
    section.add "X-Amz-Date", valid_774516
  var valid_774517 = header.getOrDefault("X-Amz-Security-Token")
  valid_774517 = validateParameter(valid_774517, JString, required = false,
                                 default = nil)
  if valid_774517 != nil:
    section.add "X-Amz-Security-Token", valid_774517
  var valid_774518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774518 = validateParameter(valid_774518, JString, required = false,
                                 default = nil)
  if valid_774518 != nil:
    section.add "X-Amz-Content-Sha256", valid_774518
  var valid_774519 = header.getOrDefault("X-Amz-Algorithm")
  valid_774519 = validateParameter(valid_774519, JString, required = false,
                                 default = nil)
  if valid_774519 != nil:
    section.add "X-Amz-Algorithm", valid_774519
  var valid_774520 = header.getOrDefault("X-Amz-Signature")
  valid_774520 = validateParameter(valid_774520, JString, required = false,
                                 default = nil)
  if valid_774520 != nil:
    section.add "X-Amz-Signature", valid_774520
  var valid_774521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774521 = validateParameter(valid_774521, JString, required = false,
                                 default = nil)
  if valid_774521 != nil:
    section.add "X-Amz-SignedHeaders", valid_774521
  var valid_774522 = header.getOrDefault("X-Amz-Credential")
  valid_774522 = validateParameter(valid_774522, JString, required = false,
                                 default = nil)
  if valid_774522 != nil:
    section.add "X-Amz-Credential", valid_774522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774523: Call_GetDescribeReservedDBInstances_774502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774523.validator(path, query, header, formData, body)
  let scheme = call_774523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774523.url(scheme.get, call_774523.host, call_774523.base,
                         call_774523.route, valid.getOrDefault("path"))
  result = hook(call_774523, url, valid)

proc call*(call_774524: Call_GetDescribeReservedDBInstances_774502;
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
  var query_774525 = newJObject()
  add(query_774525, "ProductDescription", newJString(ProductDescription))
  add(query_774525, "MaxRecords", newJInt(MaxRecords))
  add(query_774525, "OfferingType", newJString(OfferingType))
  add(query_774525, "MultiAZ", newJBool(MultiAZ))
  add(query_774525, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_774525, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774525, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774525, "Action", newJString(Action))
  add(query_774525, "Marker", newJString(Marker))
  add(query_774525, "Duration", newJString(Duration))
  add(query_774525, "Version", newJString(Version))
  result = call_774524.call(nil, query_774525, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_774502(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_774503, base: "/",
    url: url_GetDescribeReservedDBInstances_774504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_774574 = ref object of OpenApiRestCall_772581
proc url_PostDescribeReservedDBInstancesOfferings_774576(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstancesOfferings_774575(path: JsonNode;
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
  var valid_774577 = query.getOrDefault("Action")
  valid_774577 = validateParameter(valid_774577, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_774577 != nil:
    section.add "Action", valid_774577
  var valid_774578 = query.getOrDefault("Version")
  valid_774578 = validateParameter(valid_774578, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774578 != nil:
    section.add "Version", valid_774578
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774579 = header.getOrDefault("X-Amz-Date")
  valid_774579 = validateParameter(valid_774579, JString, required = false,
                                 default = nil)
  if valid_774579 != nil:
    section.add "X-Amz-Date", valid_774579
  var valid_774580 = header.getOrDefault("X-Amz-Security-Token")
  valid_774580 = validateParameter(valid_774580, JString, required = false,
                                 default = nil)
  if valid_774580 != nil:
    section.add "X-Amz-Security-Token", valid_774580
  var valid_774581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774581 = validateParameter(valid_774581, JString, required = false,
                                 default = nil)
  if valid_774581 != nil:
    section.add "X-Amz-Content-Sha256", valid_774581
  var valid_774582 = header.getOrDefault("X-Amz-Algorithm")
  valid_774582 = validateParameter(valid_774582, JString, required = false,
                                 default = nil)
  if valid_774582 != nil:
    section.add "X-Amz-Algorithm", valid_774582
  var valid_774583 = header.getOrDefault("X-Amz-Signature")
  valid_774583 = validateParameter(valid_774583, JString, required = false,
                                 default = nil)
  if valid_774583 != nil:
    section.add "X-Amz-Signature", valid_774583
  var valid_774584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774584 = validateParameter(valid_774584, JString, required = false,
                                 default = nil)
  if valid_774584 != nil:
    section.add "X-Amz-SignedHeaders", valid_774584
  var valid_774585 = header.getOrDefault("X-Amz-Credential")
  valid_774585 = validateParameter(valid_774585, JString, required = false,
                                 default = nil)
  if valid_774585 != nil:
    section.add "X-Amz-Credential", valid_774585
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
  var valid_774586 = formData.getOrDefault("OfferingType")
  valid_774586 = validateParameter(valid_774586, JString, required = false,
                                 default = nil)
  if valid_774586 != nil:
    section.add "OfferingType", valid_774586
  var valid_774587 = formData.getOrDefault("Marker")
  valid_774587 = validateParameter(valid_774587, JString, required = false,
                                 default = nil)
  if valid_774587 != nil:
    section.add "Marker", valid_774587
  var valid_774588 = formData.getOrDefault("MultiAZ")
  valid_774588 = validateParameter(valid_774588, JBool, required = false, default = nil)
  if valid_774588 != nil:
    section.add "MultiAZ", valid_774588
  var valid_774589 = formData.getOrDefault("Duration")
  valid_774589 = validateParameter(valid_774589, JString, required = false,
                                 default = nil)
  if valid_774589 != nil:
    section.add "Duration", valid_774589
  var valid_774590 = formData.getOrDefault("DBInstanceClass")
  valid_774590 = validateParameter(valid_774590, JString, required = false,
                                 default = nil)
  if valid_774590 != nil:
    section.add "DBInstanceClass", valid_774590
  var valid_774591 = formData.getOrDefault("ProductDescription")
  valid_774591 = validateParameter(valid_774591, JString, required = false,
                                 default = nil)
  if valid_774591 != nil:
    section.add "ProductDescription", valid_774591
  var valid_774592 = formData.getOrDefault("MaxRecords")
  valid_774592 = validateParameter(valid_774592, JInt, required = false, default = nil)
  if valid_774592 != nil:
    section.add "MaxRecords", valid_774592
  var valid_774593 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774593 = validateParameter(valid_774593, JString, required = false,
                                 default = nil)
  if valid_774593 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774593
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774594: Call_PostDescribeReservedDBInstancesOfferings_774574;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774594.validator(path, query, header, formData, body)
  let scheme = call_774594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774594.url(scheme.get, call_774594.host, call_774594.base,
                         call_774594.route, valid.getOrDefault("path"))
  result = hook(call_774594, url, valid)

proc call*(call_774595: Call_PostDescribeReservedDBInstancesOfferings_774574;
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
  var query_774596 = newJObject()
  var formData_774597 = newJObject()
  add(formData_774597, "OfferingType", newJString(OfferingType))
  add(formData_774597, "Marker", newJString(Marker))
  add(formData_774597, "MultiAZ", newJBool(MultiAZ))
  add(query_774596, "Action", newJString(Action))
  add(formData_774597, "Duration", newJString(Duration))
  add(formData_774597, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_774597, "ProductDescription", newJString(ProductDescription))
  add(formData_774597, "MaxRecords", newJInt(MaxRecords))
  add(formData_774597, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774596, "Version", newJString(Version))
  result = call_774595.call(nil, query_774596, nil, formData_774597, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_774574(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_774575,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_774576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_774551 = ref object of OpenApiRestCall_772581
proc url_GetDescribeReservedDBInstancesOfferings_774553(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstancesOfferings_774552(path: JsonNode;
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
  var valid_774554 = query.getOrDefault("ProductDescription")
  valid_774554 = validateParameter(valid_774554, JString, required = false,
                                 default = nil)
  if valid_774554 != nil:
    section.add "ProductDescription", valid_774554
  var valid_774555 = query.getOrDefault("MaxRecords")
  valid_774555 = validateParameter(valid_774555, JInt, required = false, default = nil)
  if valid_774555 != nil:
    section.add "MaxRecords", valid_774555
  var valid_774556 = query.getOrDefault("OfferingType")
  valid_774556 = validateParameter(valid_774556, JString, required = false,
                                 default = nil)
  if valid_774556 != nil:
    section.add "OfferingType", valid_774556
  var valid_774557 = query.getOrDefault("MultiAZ")
  valid_774557 = validateParameter(valid_774557, JBool, required = false, default = nil)
  if valid_774557 != nil:
    section.add "MultiAZ", valid_774557
  var valid_774558 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774558 = validateParameter(valid_774558, JString, required = false,
                                 default = nil)
  if valid_774558 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774558
  var valid_774559 = query.getOrDefault("DBInstanceClass")
  valid_774559 = validateParameter(valid_774559, JString, required = false,
                                 default = nil)
  if valid_774559 != nil:
    section.add "DBInstanceClass", valid_774559
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774560 = query.getOrDefault("Action")
  valid_774560 = validateParameter(valid_774560, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_774560 != nil:
    section.add "Action", valid_774560
  var valid_774561 = query.getOrDefault("Marker")
  valid_774561 = validateParameter(valid_774561, JString, required = false,
                                 default = nil)
  if valid_774561 != nil:
    section.add "Marker", valid_774561
  var valid_774562 = query.getOrDefault("Duration")
  valid_774562 = validateParameter(valid_774562, JString, required = false,
                                 default = nil)
  if valid_774562 != nil:
    section.add "Duration", valid_774562
  var valid_774563 = query.getOrDefault("Version")
  valid_774563 = validateParameter(valid_774563, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774563 != nil:
    section.add "Version", valid_774563
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774564 = header.getOrDefault("X-Amz-Date")
  valid_774564 = validateParameter(valid_774564, JString, required = false,
                                 default = nil)
  if valid_774564 != nil:
    section.add "X-Amz-Date", valid_774564
  var valid_774565 = header.getOrDefault("X-Amz-Security-Token")
  valid_774565 = validateParameter(valid_774565, JString, required = false,
                                 default = nil)
  if valid_774565 != nil:
    section.add "X-Amz-Security-Token", valid_774565
  var valid_774566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774566 = validateParameter(valid_774566, JString, required = false,
                                 default = nil)
  if valid_774566 != nil:
    section.add "X-Amz-Content-Sha256", valid_774566
  var valid_774567 = header.getOrDefault("X-Amz-Algorithm")
  valid_774567 = validateParameter(valid_774567, JString, required = false,
                                 default = nil)
  if valid_774567 != nil:
    section.add "X-Amz-Algorithm", valid_774567
  var valid_774568 = header.getOrDefault("X-Amz-Signature")
  valid_774568 = validateParameter(valid_774568, JString, required = false,
                                 default = nil)
  if valid_774568 != nil:
    section.add "X-Amz-Signature", valid_774568
  var valid_774569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774569 = validateParameter(valid_774569, JString, required = false,
                                 default = nil)
  if valid_774569 != nil:
    section.add "X-Amz-SignedHeaders", valid_774569
  var valid_774570 = header.getOrDefault("X-Amz-Credential")
  valid_774570 = validateParameter(valid_774570, JString, required = false,
                                 default = nil)
  if valid_774570 != nil:
    section.add "X-Amz-Credential", valid_774570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774571: Call_GetDescribeReservedDBInstancesOfferings_774551;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774571.validator(path, query, header, formData, body)
  let scheme = call_774571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774571.url(scheme.get, call_774571.host, call_774571.base,
                         call_774571.route, valid.getOrDefault("path"))
  result = hook(call_774571, url, valid)

proc call*(call_774572: Call_GetDescribeReservedDBInstancesOfferings_774551;
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
  var query_774573 = newJObject()
  add(query_774573, "ProductDescription", newJString(ProductDescription))
  add(query_774573, "MaxRecords", newJInt(MaxRecords))
  add(query_774573, "OfferingType", newJString(OfferingType))
  add(query_774573, "MultiAZ", newJBool(MultiAZ))
  add(query_774573, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774573, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774573, "Action", newJString(Action))
  add(query_774573, "Marker", newJString(Marker))
  add(query_774573, "Duration", newJString(Duration))
  add(query_774573, "Version", newJString(Version))
  result = call_774572.call(nil, query_774573, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_774551(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_774552, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_774553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_774617 = ref object of OpenApiRestCall_772581
proc url_PostDownloadDBLogFilePortion_774619(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDownloadDBLogFilePortion_774618(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774620 = query.getOrDefault("Action")
  valid_774620 = validateParameter(valid_774620, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_774620 != nil:
    section.add "Action", valid_774620
  var valid_774621 = query.getOrDefault("Version")
  valid_774621 = validateParameter(valid_774621, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774621 != nil:
    section.add "Version", valid_774621
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774622 = header.getOrDefault("X-Amz-Date")
  valid_774622 = validateParameter(valid_774622, JString, required = false,
                                 default = nil)
  if valid_774622 != nil:
    section.add "X-Amz-Date", valid_774622
  var valid_774623 = header.getOrDefault("X-Amz-Security-Token")
  valid_774623 = validateParameter(valid_774623, JString, required = false,
                                 default = nil)
  if valid_774623 != nil:
    section.add "X-Amz-Security-Token", valid_774623
  var valid_774624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774624 = validateParameter(valid_774624, JString, required = false,
                                 default = nil)
  if valid_774624 != nil:
    section.add "X-Amz-Content-Sha256", valid_774624
  var valid_774625 = header.getOrDefault("X-Amz-Algorithm")
  valid_774625 = validateParameter(valid_774625, JString, required = false,
                                 default = nil)
  if valid_774625 != nil:
    section.add "X-Amz-Algorithm", valid_774625
  var valid_774626 = header.getOrDefault("X-Amz-Signature")
  valid_774626 = validateParameter(valid_774626, JString, required = false,
                                 default = nil)
  if valid_774626 != nil:
    section.add "X-Amz-Signature", valid_774626
  var valid_774627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774627 = validateParameter(valid_774627, JString, required = false,
                                 default = nil)
  if valid_774627 != nil:
    section.add "X-Amz-SignedHeaders", valid_774627
  var valid_774628 = header.getOrDefault("X-Amz-Credential")
  valid_774628 = validateParameter(valid_774628, JString, required = false,
                                 default = nil)
  if valid_774628 != nil:
    section.add "X-Amz-Credential", valid_774628
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_774629 = formData.getOrDefault("NumberOfLines")
  valid_774629 = validateParameter(valid_774629, JInt, required = false, default = nil)
  if valid_774629 != nil:
    section.add "NumberOfLines", valid_774629
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774630 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774630 = validateParameter(valid_774630, JString, required = true,
                                 default = nil)
  if valid_774630 != nil:
    section.add "DBInstanceIdentifier", valid_774630
  var valid_774631 = formData.getOrDefault("Marker")
  valid_774631 = validateParameter(valid_774631, JString, required = false,
                                 default = nil)
  if valid_774631 != nil:
    section.add "Marker", valid_774631
  var valid_774632 = formData.getOrDefault("LogFileName")
  valid_774632 = validateParameter(valid_774632, JString, required = true,
                                 default = nil)
  if valid_774632 != nil:
    section.add "LogFileName", valid_774632
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774633: Call_PostDownloadDBLogFilePortion_774617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774633.validator(path, query, header, formData, body)
  let scheme = call_774633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774633.url(scheme.get, call_774633.host, call_774633.base,
                         call_774633.route, valid.getOrDefault("path"))
  result = hook(call_774633, url, valid)

proc call*(call_774634: Call_PostDownloadDBLogFilePortion_774617;
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
  var query_774635 = newJObject()
  var formData_774636 = newJObject()
  add(formData_774636, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_774636, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774636, "Marker", newJString(Marker))
  add(query_774635, "Action", newJString(Action))
  add(formData_774636, "LogFileName", newJString(LogFileName))
  add(query_774635, "Version", newJString(Version))
  result = call_774634.call(nil, query_774635, nil, formData_774636, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_774617(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_774618, base: "/",
    url: url_PostDownloadDBLogFilePortion_774619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_774598 = ref object of OpenApiRestCall_772581
proc url_GetDownloadDBLogFilePortion_774600(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDownloadDBLogFilePortion_774599(path: JsonNode; query: JsonNode;
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
  var valid_774601 = query.getOrDefault("NumberOfLines")
  valid_774601 = validateParameter(valid_774601, JInt, required = false, default = nil)
  if valid_774601 != nil:
    section.add "NumberOfLines", valid_774601
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_774602 = query.getOrDefault("LogFileName")
  valid_774602 = validateParameter(valid_774602, JString, required = true,
                                 default = nil)
  if valid_774602 != nil:
    section.add "LogFileName", valid_774602
  var valid_774603 = query.getOrDefault("Action")
  valid_774603 = validateParameter(valid_774603, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_774603 != nil:
    section.add "Action", valid_774603
  var valid_774604 = query.getOrDefault("Marker")
  valid_774604 = validateParameter(valid_774604, JString, required = false,
                                 default = nil)
  if valid_774604 != nil:
    section.add "Marker", valid_774604
  var valid_774605 = query.getOrDefault("Version")
  valid_774605 = validateParameter(valid_774605, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774605 != nil:
    section.add "Version", valid_774605
  var valid_774606 = query.getOrDefault("DBInstanceIdentifier")
  valid_774606 = validateParameter(valid_774606, JString, required = true,
                                 default = nil)
  if valid_774606 != nil:
    section.add "DBInstanceIdentifier", valid_774606
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774607 = header.getOrDefault("X-Amz-Date")
  valid_774607 = validateParameter(valid_774607, JString, required = false,
                                 default = nil)
  if valid_774607 != nil:
    section.add "X-Amz-Date", valid_774607
  var valid_774608 = header.getOrDefault("X-Amz-Security-Token")
  valid_774608 = validateParameter(valid_774608, JString, required = false,
                                 default = nil)
  if valid_774608 != nil:
    section.add "X-Amz-Security-Token", valid_774608
  var valid_774609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774609 = validateParameter(valid_774609, JString, required = false,
                                 default = nil)
  if valid_774609 != nil:
    section.add "X-Amz-Content-Sha256", valid_774609
  var valid_774610 = header.getOrDefault("X-Amz-Algorithm")
  valid_774610 = validateParameter(valid_774610, JString, required = false,
                                 default = nil)
  if valid_774610 != nil:
    section.add "X-Amz-Algorithm", valid_774610
  var valid_774611 = header.getOrDefault("X-Amz-Signature")
  valid_774611 = validateParameter(valid_774611, JString, required = false,
                                 default = nil)
  if valid_774611 != nil:
    section.add "X-Amz-Signature", valid_774611
  var valid_774612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774612 = validateParameter(valid_774612, JString, required = false,
                                 default = nil)
  if valid_774612 != nil:
    section.add "X-Amz-SignedHeaders", valid_774612
  var valid_774613 = header.getOrDefault("X-Amz-Credential")
  valid_774613 = validateParameter(valid_774613, JString, required = false,
                                 default = nil)
  if valid_774613 != nil:
    section.add "X-Amz-Credential", valid_774613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774614: Call_GetDownloadDBLogFilePortion_774598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774614.validator(path, query, header, formData, body)
  let scheme = call_774614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774614.url(scheme.get, call_774614.host, call_774614.base,
                         call_774614.route, valid.getOrDefault("path"))
  result = hook(call_774614, url, valid)

proc call*(call_774615: Call_GetDownloadDBLogFilePortion_774598;
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
  var query_774616 = newJObject()
  add(query_774616, "NumberOfLines", newJInt(NumberOfLines))
  add(query_774616, "LogFileName", newJString(LogFileName))
  add(query_774616, "Action", newJString(Action))
  add(query_774616, "Marker", newJString(Marker))
  add(query_774616, "Version", newJString(Version))
  add(query_774616, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_774615.call(nil, query_774616, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_774598(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_774599, base: "/",
    url: url_GetDownloadDBLogFilePortion_774600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_774653 = ref object of OpenApiRestCall_772581
proc url_PostListTagsForResource_774655(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_774654(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774656 = query.getOrDefault("Action")
  valid_774656 = validateParameter(valid_774656, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_774656 != nil:
    section.add "Action", valid_774656
  var valid_774657 = query.getOrDefault("Version")
  valid_774657 = validateParameter(valid_774657, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774657 != nil:
    section.add "Version", valid_774657
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774658 = header.getOrDefault("X-Amz-Date")
  valid_774658 = validateParameter(valid_774658, JString, required = false,
                                 default = nil)
  if valid_774658 != nil:
    section.add "X-Amz-Date", valid_774658
  var valid_774659 = header.getOrDefault("X-Amz-Security-Token")
  valid_774659 = validateParameter(valid_774659, JString, required = false,
                                 default = nil)
  if valid_774659 != nil:
    section.add "X-Amz-Security-Token", valid_774659
  var valid_774660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774660 = validateParameter(valid_774660, JString, required = false,
                                 default = nil)
  if valid_774660 != nil:
    section.add "X-Amz-Content-Sha256", valid_774660
  var valid_774661 = header.getOrDefault("X-Amz-Algorithm")
  valid_774661 = validateParameter(valid_774661, JString, required = false,
                                 default = nil)
  if valid_774661 != nil:
    section.add "X-Amz-Algorithm", valid_774661
  var valid_774662 = header.getOrDefault("X-Amz-Signature")
  valid_774662 = validateParameter(valid_774662, JString, required = false,
                                 default = nil)
  if valid_774662 != nil:
    section.add "X-Amz-Signature", valid_774662
  var valid_774663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774663 = validateParameter(valid_774663, JString, required = false,
                                 default = nil)
  if valid_774663 != nil:
    section.add "X-Amz-SignedHeaders", valid_774663
  var valid_774664 = header.getOrDefault("X-Amz-Credential")
  valid_774664 = validateParameter(valid_774664, JString, required = false,
                                 default = nil)
  if valid_774664 != nil:
    section.add "X-Amz-Credential", valid_774664
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_774665 = formData.getOrDefault("ResourceName")
  valid_774665 = validateParameter(valid_774665, JString, required = true,
                                 default = nil)
  if valid_774665 != nil:
    section.add "ResourceName", valid_774665
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774666: Call_PostListTagsForResource_774653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774666.validator(path, query, header, formData, body)
  let scheme = call_774666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774666.url(scheme.get, call_774666.host, call_774666.base,
                         call_774666.route, valid.getOrDefault("path"))
  result = hook(call_774666, url, valid)

proc call*(call_774667: Call_PostListTagsForResource_774653; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_774668 = newJObject()
  var formData_774669 = newJObject()
  add(query_774668, "Action", newJString(Action))
  add(formData_774669, "ResourceName", newJString(ResourceName))
  add(query_774668, "Version", newJString(Version))
  result = call_774667.call(nil, query_774668, nil, formData_774669, nil)

var postListTagsForResource* = Call_PostListTagsForResource_774653(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_774654, base: "/",
    url: url_PostListTagsForResource_774655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_774637 = ref object of OpenApiRestCall_772581
proc url_GetListTagsForResource_774639(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_774638(path: JsonNode; query: JsonNode;
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
  var valid_774640 = query.getOrDefault("ResourceName")
  valid_774640 = validateParameter(valid_774640, JString, required = true,
                                 default = nil)
  if valid_774640 != nil:
    section.add "ResourceName", valid_774640
  var valid_774641 = query.getOrDefault("Action")
  valid_774641 = validateParameter(valid_774641, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_774641 != nil:
    section.add "Action", valid_774641
  var valid_774642 = query.getOrDefault("Version")
  valid_774642 = validateParameter(valid_774642, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774642 != nil:
    section.add "Version", valid_774642
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774643 = header.getOrDefault("X-Amz-Date")
  valid_774643 = validateParameter(valid_774643, JString, required = false,
                                 default = nil)
  if valid_774643 != nil:
    section.add "X-Amz-Date", valid_774643
  var valid_774644 = header.getOrDefault("X-Amz-Security-Token")
  valid_774644 = validateParameter(valid_774644, JString, required = false,
                                 default = nil)
  if valid_774644 != nil:
    section.add "X-Amz-Security-Token", valid_774644
  var valid_774645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774645 = validateParameter(valid_774645, JString, required = false,
                                 default = nil)
  if valid_774645 != nil:
    section.add "X-Amz-Content-Sha256", valid_774645
  var valid_774646 = header.getOrDefault("X-Amz-Algorithm")
  valid_774646 = validateParameter(valid_774646, JString, required = false,
                                 default = nil)
  if valid_774646 != nil:
    section.add "X-Amz-Algorithm", valid_774646
  var valid_774647 = header.getOrDefault("X-Amz-Signature")
  valid_774647 = validateParameter(valid_774647, JString, required = false,
                                 default = nil)
  if valid_774647 != nil:
    section.add "X-Amz-Signature", valid_774647
  var valid_774648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774648 = validateParameter(valid_774648, JString, required = false,
                                 default = nil)
  if valid_774648 != nil:
    section.add "X-Amz-SignedHeaders", valid_774648
  var valid_774649 = header.getOrDefault("X-Amz-Credential")
  valid_774649 = validateParameter(valid_774649, JString, required = false,
                                 default = nil)
  if valid_774649 != nil:
    section.add "X-Amz-Credential", valid_774649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774650: Call_GetListTagsForResource_774637; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774650.validator(path, query, header, formData, body)
  let scheme = call_774650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774650.url(scheme.get, call_774650.host, call_774650.base,
                         call_774650.route, valid.getOrDefault("path"))
  result = hook(call_774650, url, valid)

proc call*(call_774651: Call_GetListTagsForResource_774637; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774652 = newJObject()
  add(query_774652, "ResourceName", newJString(ResourceName))
  add(query_774652, "Action", newJString(Action))
  add(query_774652, "Version", newJString(Version))
  result = call_774651.call(nil, query_774652, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_774637(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_774638, base: "/",
    url: url_GetListTagsForResource_774639, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_774703 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBInstance_774705(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBInstance_774704(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774706 = query.getOrDefault("Action")
  valid_774706 = validateParameter(valid_774706, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_774706 != nil:
    section.add "Action", valid_774706
  var valid_774707 = query.getOrDefault("Version")
  valid_774707 = validateParameter(valid_774707, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774707 != nil:
    section.add "Version", valid_774707
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774708 = header.getOrDefault("X-Amz-Date")
  valid_774708 = validateParameter(valid_774708, JString, required = false,
                                 default = nil)
  if valid_774708 != nil:
    section.add "X-Amz-Date", valid_774708
  var valid_774709 = header.getOrDefault("X-Amz-Security-Token")
  valid_774709 = validateParameter(valid_774709, JString, required = false,
                                 default = nil)
  if valid_774709 != nil:
    section.add "X-Amz-Security-Token", valid_774709
  var valid_774710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774710 = validateParameter(valid_774710, JString, required = false,
                                 default = nil)
  if valid_774710 != nil:
    section.add "X-Amz-Content-Sha256", valid_774710
  var valid_774711 = header.getOrDefault("X-Amz-Algorithm")
  valid_774711 = validateParameter(valid_774711, JString, required = false,
                                 default = nil)
  if valid_774711 != nil:
    section.add "X-Amz-Algorithm", valid_774711
  var valid_774712 = header.getOrDefault("X-Amz-Signature")
  valid_774712 = validateParameter(valid_774712, JString, required = false,
                                 default = nil)
  if valid_774712 != nil:
    section.add "X-Amz-Signature", valid_774712
  var valid_774713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774713 = validateParameter(valid_774713, JString, required = false,
                                 default = nil)
  if valid_774713 != nil:
    section.add "X-Amz-SignedHeaders", valid_774713
  var valid_774714 = header.getOrDefault("X-Amz-Credential")
  valid_774714 = validateParameter(valid_774714, JString, required = false,
                                 default = nil)
  if valid_774714 != nil:
    section.add "X-Amz-Credential", valid_774714
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
  var valid_774715 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_774715 = validateParameter(valid_774715, JString, required = false,
                                 default = nil)
  if valid_774715 != nil:
    section.add "PreferredMaintenanceWindow", valid_774715
  var valid_774716 = formData.getOrDefault("DBSecurityGroups")
  valid_774716 = validateParameter(valid_774716, JArray, required = false,
                                 default = nil)
  if valid_774716 != nil:
    section.add "DBSecurityGroups", valid_774716
  var valid_774717 = formData.getOrDefault("ApplyImmediately")
  valid_774717 = validateParameter(valid_774717, JBool, required = false, default = nil)
  if valid_774717 != nil:
    section.add "ApplyImmediately", valid_774717
  var valid_774718 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_774718 = validateParameter(valid_774718, JArray, required = false,
                                 default = nil)
  if valid_774718 != nil:
    section.add "VpcSecurityGroupIds", valid_774718
  var valid_774719 = formData.getOrDefault("Iops")
  valid_774719 = validateParameter(valid_774719, JInt, required = false, default = nil)
  if valid_774719 != nil:
    section.add "Iops", valid_774719
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774720 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774720 = validateParameter(valid_774720, JString, required = true,
                                 default = nil)
  if valid_774720 != nil:
    section.add "DBInstanceIdentifier", valid_774720
  var valid_774721 = formData.getOrDefault("BackupRetentionPeriod")
  valid_774721 = validateParameter(valid_774721, JInt, required = false, default = nil)
  if valid_774721 != nil:
    section.add "BackupRetentionPeriod", valid_774721
  var valid_774722 = formData.getOrDefault("DBParameterGroupName")
  valid_774722 = validateParameter(valid_774722, JString, required = false,
                                 default = nil)
  if valid_774722 != nil:
    section.add "DBParameterGroupName", valid_774722
  var valid_774723 = formData.getOrDefault("OptionGroupName")
  valid_774723 = validateParameter(valid_774723, JString, required = false,
                                 default = nil)
  if valid_774723 != nil:
    section.add "OptionGroupName", valid_774723
  var valid_774724 = formData.getOrDefault("MasterUserPassword")
  valid_774724 = validateParameter(valid_774724, JString, required = false,
                                 default = nil)
  if valid_774724 != nil:
    section.add "MasterUserPassword", valid_774724
  var valid_774725 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_774725 = validateParameter(valid_774725, JString, required = false,
                                 default = nil)
  if valid_774725 != nil:
    section.add "NewDBInstanceIdentifier", valid_774725
  var valid_774726 = formData.getOrDefault("MultiAZ")
  valid_774726 = validateParameter(valid_774726, JBool, required = false, default = nil)
  if valid_774726 != nil:
    section.add "MultiAZ", valid_774726
  var valid_774727 = formData.getOrDefault("AllocatedStorage")
  valid_774727 = validateParameter(valid_774727, JInt, required = false, default = nil)
  if valid_774727 != nil:
    section.add "AllocatedStorage", valid_774727
  var valid_774728 = formData.getOrDefault("DBInstanceClass")
  valid_774728 = validateParameter(valid_774728, JString, required = false,
                                 default = nil)
  if valid_774728 != nil:
    section.add "DBInstanceClass", valid_774728
  var valid_774729 = formData.getOrDefault("PreferredBackupWindow")
  valid_774729 = validateParameter(valid_774729, JString, required = false,
                                 default = nil)
  if valid_774729 != nil:
    section.add "PreferredBackupWindow", valid_774729
  var valid_774730 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_774730 = validateParameter(valid_774730, JBool, required = false, default = nil)
  if valid_774730 != nil:
    section.add "AutoMinorVersionUpgrade", valid_774730
  var valid_774731 = formData.getOrDefault("EngineVersion")
  valid_774731 = validateParameter(valid_774731, JString, required = false,
                                 default = nil)
  if valid_774731 != nil:
    section.add "EngineVersion", valid_774731
  var valid_774732 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_774732 = validateParameter(valid_774732, JBool, required = false, default = nil)
  if valid_774732 != nil:
    section.add "AllowMajorVersionUpgrade", valid_774732
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774733: Call_PostModifyDBInstance_774703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774733.validator(path, query, header, formData, body)
  let scheme = call_774733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774733.url(scheme.get, call_774733.host, call_774733.base,
                         call_774733.route, valid.getOrDefault("path"))
  result = hook(call_774733, url, valid)

proc call*(call_774734: Call_PostModifyDBInstance_774703;
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
  var query_774735 = newJObject()
  var formData_774736 = newJObject()
  add(formData_774736, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_774736.add "DBSecurityGroups", DBSecurityGroups
  add(formData_774736, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_774736.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_774736, "Iops", newJInt(Iops))
  add(formData_774736, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774736, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_774736, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_774736, "OptionGroupName", newJString(OptionGroupName))
  add(formData_774736, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_774736, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_774736, "MultiAZ", newJBool(MultiAZ))
  add(query_774735, "Action", newJString(Action))
  add(formData_774736, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_774736, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_774736, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_774736, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_774736, "EngineVersion", newJString(EngineVersion))
  add(query_774735, "Version", newJString(Version))
  add(formData_774736, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_774734.call(nil, query_774735, nil, formData_774736, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_774703(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_774704, base: "/",
    url: url_PostModifyDBInstance_774705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_774670 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBInstance_774672(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBInstance_774671(path: JsonNode; query: JsonNode;
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
  var valid_774673 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_774673 = validateParameter(valid_774673, JString, required = false,
                                 default = nil)
  if valid_774673 != nil:
    section.add "PreferredMaintenanceWindow", valid_774673
  var valid_774674 = query.getOrDefault("AllocatedStorage")
  valid_774674 = validateParameter(valid_774674, JInt, required = false, default = nil)
  if valid_774674 != nil:
    section.add "AllocatedStorage", valid_774674
  var valid_774675 = query.getOrDefault("OptionGroupName")
  valid_774675 = validateParameter(valid_774675, JString, required = false,
                                 default = nil)
  if valid_774675 != nil:
    section.add "OptionGroupName", valid_774675
  var valid_774676 = query.getOrDefault("DBSecurityGroups")
  valid_774676 = validateParameter(valid_774676, JArray, required = false,
                                 default = nil)
  if valid_774676 != nil:
    section.add "DBSecurityGroups", valid_774676
  var valid_774677 = query.getOrDefault("MasterUserPassword")
  valid_774677 = validateParameter(valid_774677, JString, required = false,
                                 default = nil)
  if valid_774677 != nil:
    section.add "MasterUserPassword", valid_774677
  var valid_774678 = query.getOrDefault("Iops")
  valid_774678 = validateParameter(valid_774678, JInt, required = false, default = nil)
  if valid_774678 != nil:
    section.add "Iops", valid_774678
  var valid_774679 = query.getOrDefault("VpcSecurityGroupIds")
  valid_774679 = validateParameter(valid_774679, JArray, required = false,
                                 default = nil)
  if valid_774679 != nil:
    section.add "VpcSecurityGroupIds", valid_774679
  var valid_774680 = query.getOrDefault("MultiAZ")
  valid_774680 = validateParameter(valid_774680, JBool, required = false, default = nil)
  if valid_774680 != nil:
    section.add "MultiAZ", valid_774680
  var valid_774681 = query.getOrDefault("BackupRetentionPeriod")
  valid_774681 = validateParameter(valid_774681, JInt, required = false, default = nil)
  if valid_774681 != nil:
    section.add "BackupRetentionPeriod", valid_774681
  var valid_774682 = query.getOrDefault("DBParameterGroupName")
  valid_774682 = validateParameter(valid_774682, JString, required = false,
                                 default = nil)
  if valid_774682 != nil:
    section.add "DBParameterGroupName", valid_774682
  var valid_774683 = query.getOrDefault("DBInstanceClass")
  valid_774683 = validateParameter(valid_774683, JString, required = false,
                                 default = nil)
  if valid_774683 != nil:
    section.add "DBInstanceClass", valid_774683
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774684 = query.getOrDefault("Action")
  valid_774684 = validateParameter(valid_774684, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_774684 != nil:
    section.add "Action", valid_774684
  var valid_774685 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_774685 = validateParameter(valid_774685, JBool, required = false, default = nil)
  if valid_774685 != nil:
    section.add "AllowMajorVersionUpgrade", valid_774685
  var valid_774686 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_774686 = validateParameter(valid_774686, JString, required = false,
                                 default = nil)
  if valid_774686 != nil:
    section.add "NewDBInstanceIdentifier", valid_774686
  var valid_774687 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_774687 = validateParameter(valid_774687, JBool, required = false, default = nil)
  if valid_774687 != nil:
    section.add "AutoMinorVersionUpgrade", valid_774687
  var valid_774688 = query.getOrDefault("EngineVersion")
  valid_774688 = validateParameter(valid_774688, JString, required = false,
                                 default = nil)
  if valid_774688 != nil:
    section.add "EngineVersion", valid_774688
  var valid_774689 = query.getOrDefault("PreferredBackupWindow")
  valid_774689 = validateParameter(valid_774689, JString, required = false,
                                 default = nil)
  if valid_774689 != nil:
    section.add "PreferredBackupWindow", valid_774689
  var valid_774690 = query.getOrDefault("Version")
  valid_774690 = validateParameter(valid_774690, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774690 != nil:
    section.add "Version", valid_774690
  var valid_774691 = query.getOrDefault("DBInstanceIdentifier")
  valid_774691 = validateParameter(valid_774691, JString, required = true,
                                 default = nil)
  if valid_774691 != nil:
    section.add "DBInstanceIdentifier", valid_774691
  var valid_774692 = query.getOrDefault("ApplyImmediately")
  valid_774692 = validateParameter(valid_774692, JBool, required = false, default = nil)
  if valid_774692 != nil:
    section.add "ApplyImmediately", valid_774692
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774693 = header.getOrDefault("X-Amz-Date")
  valid_774693 = validateParameter(valid_774693, JString, required = false,
                                 default = nil)
  if valid_774693 != nil:
    section.add "X-Amz-Date", valid_774693
  var valid_774694 = header.getOrDefault("X-Amz-Security-Token")
  valid_774694 = validateParameter(valid_774694, JString, required = false,
                                 default = nil)
  if valid_774694 != nil:
    section.add "X-Amz-Security-Token", valid_774694
  var valid_774695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774695 = validateParameter(valid_774695, JString, required = false,
                                 default = nil)
  if valid_774695 != nil:
    section.add "X-Amz-Content-Sha256", valid_774695
  var valid_774696 = header.getOrDefault("X-Amz-Algorithm")
  valid_774696 = validateParameter(valid_774696, JString, required = false,
                                 default = nil)
  if valid_774696 != nil:
    section.add "X-Amz-Algorithm", valid_774696
  var valid_774697 = header.getOrDefault("X-Amz-Signature")
  valid_774697 = validateParameter(valid_774697, JString, required = false,
                                 default = nil)
  if valid_774697 != nil:
    section.add "X-Amz-Signature", valid_774697
  var valid_774698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774698 = validateParameter(valid_774698, JString, required = false,
                                 default = nil)
  if valid_774698 != nil:
    section.add "X-Amz-SignedHeaders", valid_774698
  var valid_774699 = header.getOrDefault("X-Amz-Credential")
  valid_774699 = validateParameter(valid_774699, JString, required = false,
                                 default = nil)
  if valid_774699 != nil:
    section.add "X-Amz-Credential", valid_774699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774700: Call_GetModifyDBInstance_774670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774700.validator(path, query, header, formData, body)
  let scheme = call_774700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774700.url(scheme.get, call_774700.host, call_774700.base,
                         call_774700.route, valid.getOrDefault("path"))
  result = hook(call_774700, url, valid)

proc call*(call_774701: Call_GetModifyDBInstance_774670;
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
  var query_774702 = newJObject()
  add(query_774702, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_774702, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_774702, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_774702.add "DBSecurityGroups", DBSecurityGroups
  add(query_774702, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_774702, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_774702.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_774702, "MultiAZ", newJBool(MultiAZ))
  add(query_774702, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_774702, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_774702, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774702, "Action", newJString(Action))
  add(query_774702, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_774702, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_774702, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_774702, "EngineVersion", newJString(EngineVersion))
  add(query_774702, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_774702, "Version", newJString(Version))
  add(query_774702, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_774702, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_774701.call(nil, query_774702, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_774670(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_774671, base: "/",
    url: url_GetModifyDBInstance_774672, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_774754 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBParameterGroup_774756(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBParameterGroup_774755(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774757 = query.getOrDefault("Action")
  valid_774757 = validateParameter(valid_774757, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_774757 != nil:
    section.add "Action", valid_774757
  var valid_774758 = query.getOrDefault("Version")
  valid_774758 = validateParameter(valid_774758, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774758 != nil:
    section.add "Version", valid_774758
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774759 = header.getOrDefault("X-Amz-Date")
  valid_774759 = validateParameter(valid_774759, JString, required = false,
                                 default = nil)
  if valid_774759 != nil:
    section.add "X-Amz-Date", valid_774759
  var valid_774760 = header.getOrDefault("X-Amz-Security-Token")
  valid_774760 = validateParameter(valid_774760, JString, required = false,
                                 default = nil)
  if valid_774760 != nil:
    section.add "X-Amz-Security-Token", valid_774760
  var valid_774761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774761 = validateParameter(valid_774761, JString, required = false,
                                 default = nil)
  if valid_774761 != nil:
    section.add "X-Amz-Content-Sha256", valid_774761
  var valid_774762 = header.getOrDefault("X-Amz-Algorithm")
  valid_774762 = validateParameter(valid_774762, JString, required = false,
                                 default = nil)
  if valid_774762 != nil:
    section.add "X-Amz-Algorithm", valid_774762
  var valid_774763 = header.getOrDefault("X-Amz-Signature")
  valid_774763 = validateParameter(valid_774763, JString, required = false,
                                 default = nil)
  if valid_774763 != nil:
    section.add "X-Amz-Signature", valid_774763
  var valid_774764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774764 = validateParameter(valid_774764, JString, required = false,
                                 default = nil)
  if valid_774764 != nil:
    section.add "X-Amz-SignedHeaders", valid_774764
  var valid_774765 = header.getOrDefault("X-Amz-Credential")
  valid_774765 = validateParameter(valid_774765, JString, required = false,
                                 default = nil)
  if valid_774765 != nil:
    section.add "X-Amz-Credential", valid_774765
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_774766 = formData.getOrDefault("DBParameterGroupName")
  valid_774766 = validateParameter(valid_774766, JString, required = true,
                                 default = nil)
  if valid_774766 != nil:
    section.add "DBParameterGroupName", valid_774766
  var valid_774767 = formData.getOrDefault("Parameters")
  valid_774767 = validateParameter(valid_774767, JArray, required = true, default = nil)
  if valid_774767 != nil:
    section.add "Parameters", valid_774767
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774768: Call_PostModifyDBParameterGroup_774754; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774768.validator(path, query, header, formData, body)
  let scheme = call_774768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774768.url(scheme.get, call_774768.host, call_774768.base,
                         call_774768.route, valid.getOrDefault("path"))
  result = hook(call_774768, url, valid)

proc call*(call_774769: Call_PostModifyDBParameterGroup_774754;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774770 = newJObject()
  var formData_774771 = newJObject()
  add(formData_774771, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_774771.add "Parameters", Parameters
  add(query_774770, "Action", newJString(Action))
  add(query_774770, "Version", newJString(Version))
  result = call_774769.call(nil, query_774770, nil, formData_774771, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_774754(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_774755, base: "/",
    url: url_PostModifyDBParameterGroup_774756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_774737 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBParameterGroup_774739(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBParameterGroup_774738(path: JsonNode; query: JsonNode;
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
  var valid_774740 = query.getOrDefault("DBParameterGroupName")
  valid_774740 = validateParameter(valid_774740, JString, required = true,
                                 default = nil)
  if valid_774740 != nil:
    section.add "DBParameterGroupName", valid_774740
  var valid_774741 = query.getOrDefault("Parameters")
  valid_774741 = validateParameter(valid_774741, JArray, required = true, default = nil)
  if valid_774741 != nil:
    section.add "Parameters", valid_774741
  var valid_774742 = query.getOrDefault("Action")
  valid_774742 = validateParameter(valid_774742, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_774742 != nil:
    section.add "Action", valid_774742
  var valid_774743 = query.getOrDefault("Version")
  valid_774743 = validateParameter(valid_774743, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774743 != nil:
    section.add "Version", valid_774743
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774744 = header.getOrDefault("X-Amz-Date")
  valid_774744 = validateParameter(valid_774744, JString, required = false,
                                 default = nil)
  if valid_774744 != nil:
    section.add "X-Amz-Date", valid_774744
  var valid_774745 = header.getOrDefault("X-Amz-Security-Token")
  valid_774745 = validateParameter(valid_774745, JString, required = false,
                                 default = nil)
  if valid_774745 != nil:
    section.add "X-Amz-Security-Token", valid_774745
  var valid_774746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774746 = validateParameter(valid_774746, JString, required = false,
                                 default = nil)
  if valid_774746 != nil:
    section.add "X-Amz-Content-Sha256", valid_774746
  var valid_774747 = header.getOrDefault("X-Amz-Algorithm")
  valid_774747 = validateParameter(valid_774747, JString, required = false,
                                 default = nil)
  if valid_774747 != nil:
    section.add "X-Amz-Algorithm", valid_774747
  var valid_774748 = header.getOrDefault("X-Amz-Signature")
  valid_774748 = validateParameter(valid_774748, JString, required = false,
                                 default = nil)
  if valid_774748 != nil:
    section.add "X-Amz-Signature", valid_774748
  var valid_774749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774749 = validateParameter(valid_774749, JString, required = false,
                                 default = nil)
  if valid_774749 != nil:
    section.add "X-Amz-SignedHeaders", valid_774749
  var valid_774750 = header.getOrDefault("X-Amz-Credential")
  valid_774750 = validateParameter(valid_774750, JString, required = false,
                                 default = nil)
  if valid_774750 != nil:
    section.add "X-Amz-Credential", valid_774750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774751: Call_GetModifyDBParameterGroup_774737; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774751.validator(path, query, header, formData, body)
  let scheme = call_774751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774751.url(scheme.get, call_774751.host, call_774751.base,
                         call_774751.route, valid.getOrDefault("path"))
  result = hook(call_774751, url, valid)

proc call*(call_774752: Call_GetModifyDBParameterGroup_774737;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774753 = newJObject()
  add(query_774753, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_774753.add "Parameters", Parameters
  add(query_774753, "Action", newJString(Action))
  add(query_774753, "Version", newJString(Version))
  result = call_774752.call(nil, query_774753, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_774737(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_774738, base: "/",
    url: url_GetModifyDBParameterGroup_774739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_774790 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBSubnetGroup_774792(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBSubnetGroup_774791(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774793 = query.getOrDefault("Action")
  valid_774793 = validateParameter(valid_774793, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_774793 != nil:
    section.add "Action", valid_774793
  var valid_774794 = query.getOrDefault("Version")
  valid_774794 = validateParameter(valid_774794, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774794 != nil:
    section.add "Version", valid_774794
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774795 = header.getOrDefault("X-Amz-Date")
  valid_774795 = validateParameter(valid_774795, JString, required = false,
                                 default = nil)
  if valid_774795 != nil:
    section.add "X-Amz-Date", valid_774795
  var valid_774796 = header.getOrDefault("X-Amz-Security-Token")
  valid_774796 = validateParameter(valid_774796, JString, required = false,
                                 default = nil)
  if valid_774796 != nil:
    section.add "X-Amz-Security-Token", valid_774796
  var valid_774797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774797 = validateParameter(valid_774797, JString, required = false,
                                 default = nil)
  if valid_774797 != nil:
    section.add "X-Amz-Content-Sha256", valid_774797
  var valid_774798 = header.getOrDefault("X-Amz-Algorithm")
  valid_774798 = validateParameter(valid_774798, JString, required = false,
                                 default = nil)
  if valid_774798 != nil:
    section.add "X-Amz-Algorithm", valid_774798
  var valid_774799 = header.getOrDefault("X-Amz-Signature")
  valid_774799 = validateParameter(valid_774799, JString, required = false,
                                 default = nil)
  if valid_774799 != nil:
    section.add "X-Amz-Signature", valid_774799
  var valid_774800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774800 = validateParameter(valid_774800, JString, required = false,
                                 default = nil)
  if valid_774800 != nil:
    section.add "X-Amz-SignedHeaders", valid_774800
  var valid_774801 = header.getOrDefault("X-Amz-Credential")
  valid_774801 = validateParameter(valid_774801, JString, required = false,
                                 default = nil)
  if valid_774801 != nil:
    section.add "X-Amz-Credential", valid_774801
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_774802 = formData.getOrDefault("DBSubnetGroupName")
  valid_774802 = validateParameter(valid_774802, JString, required = true,
                                 default = nil)
  if valid_774802 != nil:
    section.add "DBSubnetGroupName", valid_774802
  var valid_774803 = formData.getOrDefault("SubnetIds")
  valid_774803 = validateParameter(valid_774803, JArray, required = true, default = nil)
  if valid_774803 != nil:
    section.add "SubnetIds", valid_774803
  var valid_774804 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_774804 = validateParameter(valid_774804, JString, required = false,
                                 default = nil)
  if valid_774804 != nil:
    section.add "DBSubnetGroupDescription", valid_774804
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774805: Call_PostModifyDBSubnetGroup_774790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774805.validator(path, query, header, formData, body)
  let scheme = call_774805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774805.url(scheme.get, call_774805.host, call_774805.base,
                         call_774805.route, valid.getOrDefault("path"))
  result = hook(call_774805, url, valid)

proc call*(call_774806: Call_PostModifyDBSubnetGroup_774790;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_774807 = newJObject()
  var formData_774808 = newJObject()
  add(formData_774808, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_774808.add "SubnetIds", SubnetIds
  add(query_774807, "Action", newJString(Action))
  add(formData_774808, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_774807, "Version", newJString(Version))
  result = call_774806.call(nil, query_774807, nil, formData_774808, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_774790(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_774791, base: "/",
    url: url_PostModifyDBSubnetGroup_774792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_774772 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBSubnetGroup_774774(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBSubnetGroup_774773(path: JsonNode; query: JsonNode;
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
  var valid_774775 = query.getOrDefault("Action")
  valid_774775 = validateParameter(valid_774775, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_774775 != nil:
    section.add "Action", valid_774775
  var valid_774776 = query.getOrDefault("DBSubnetGroupName")
  valid_774776 = validateParameter(valid_774776, JString, required = true,
                                 default = nil)
  if valid_774776 != nil:
    section.add "DBSubnetGroupName", valid_774776
  var valid_774777 = query.getOrDefault("SubnetIds")
  valid_774777 = validateParameter(valid_774777, JArray, required = true, default = nil)
  if valid_774777 != nil:
    section.add "SubnetIds", valid_774777
  var valid_774778 = query.getOrDefault("DBSubnetGroupDescription")
  valid_774778 = validateParameter(valid_774778, JString, required = false,
                                 default = nil)
  if valid_774778 != nil:
    section.add "DBSubnetGroupDescription", valid_774778
  var valid_774779 = query.getOrDefault("Version")
  valid_774779 = validateParameter(valid_774779, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774779 != nil:
    section.add "Version", valid_774779
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774780 = header.getOrDefault("X-Amz-Date")
  valid_774780 = validateParameter(valid_774780, JString, required = false,
                                 default = nil)
  if valid_774780 != nil:
    section.add "X-Amz-Date", valid_774780
  var valid_774781 = header.getOrDefault("X-Amz-Security-Token")
  valid_774781 = validateParameter(valid_774781, JString, required = false,
                                 default = nil)
  if valid_774781 != nil:
    section.add "X-Amz-Security-Token", valid_774781
  var valid_774782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774782 = validateParameter(valid_774782, JString, required = false,
                                 default = nil)
  if valid_774782 != nil:
    section.add "X-Amz-Content-Sha256", valid_774782
  var valid_774783 = header.getOrDefault("X-Amz-Algorithm")
  valid_774783 = validateParameter(valid_774783, JString, required = false,
                                 default = nil)
  if valid_774783 != nil:
    section.add "X-Amz-Algorithm", valid_774783
  var valid_774784 = header.getOrDefault("X-Amz-Signature")
  valid_774784 = validateParameter(valid_774784, JString, required = false,
                                 default = nil)
  if valid_774784 != nil:
    section.add "X-Amz-Signature", valid_774784
  var valid_774785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774785 = validateParameter(valid_774785, JString, required = false,
                                 default = nil)
  if valid_774785 != nil:
    section.add "X-Amz-SignedHeaders", valid_774785
  var valid_774786 = header.getOrDefault("X-Amz-Credential")
  valid_774786 = validateParameter(valid_774786, JString, required = false,
                                 default = nil)
  if valid_774786 != nil:
    section.add "X-Amz-Credential", valid_774786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774787: Call_GetModifyDBSubnetGroup_774772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774787.validator(path, query, header, formData, body)
  let scheme = call_774787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774787.url(scheme.get, call_774787.host, call_774787.base,
                         call_774787.route, valid.getOrDefault("path"))
  result = hook(call_774787, url, valid)

proc call*(call_774788: Call_GetModifyDBSubnetGroup_774772;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_774789 = newJObject()
  add(query_774789, "Action", newJString(Action))
  add(query_774789, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_774789.add "SubnetIds", SubnetIds
  add(query_774789, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_774789, "Version", newJString(Version))
  result = call_774788.call(nil, query_774789, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_774772(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_774773, base: "/",
    url: url_GetModifyDBSubnetGroup_774774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_774829 = ref object of OpenApiRestCall_772581
proc url_PostModifyEventSubscription_774831(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyEventSubscription_774830(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774832 = query.getOrDefault("Action")
  valid_774832 = validateParameter(valid_774832, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_774832 != nil:
    section.add "Action", valid_774832
  var valid_774833 = query.getOrDefault("Version")
  valid_774833 = validateParameter(valid_774833, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774833 != nil:
    section.add "Version", valid_774833
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774834 = header.getOrDefault("X-Amz-Date")
  valid_774834 = validateParameter(valid_774834, JString, required = false,
                                 default = nil)
  if valid_774834 != nil:
    section.add "X-Amz-Date", valid_774834
  var valid_774835 = header.getOrDefault("X-Amz-Security-Token")
  valid_774835 = validateParameter(valid_774835, JString, required = false,
                                 default = nil)
  if valid_774835 != nil:
    section.add "X-Amz-Security-Token", valid_774835
  var valid_774836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774836 = validateParameter(valid_774836, JString, required = false,
                                 default = nil)
  if valid_774836 != nil:
    section.add "X-Amz-Content-Sha256", valid_774836
  var valid_774837 = header.getOrDefault("X-Amz-Algorithm")
  valid_774837 = validateParameter(valid_774837, JString, required = false,
                                 default = nil)
  if valid_774837 != nil:
    section.add "X-Amz-Algorithm", valid_774837
  var valid_774838 = header.getOrDefault("X-Amz-Signature")
  valid_774838 = validateParameter(valid_774838, JString, required = false,
                                 default = nil)
  if valid_774838 != nil:
    section.add "X-Amz-Signature", valid_774838
  var valid_774839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774839 = validateParameter(valid_774839, JString, required = false,
                                 default = nil)
  if valid_774839 != nil:
    section.add "X-Amz-SignedHeaders", valid_774839
  var valid_774840 = header.getOrDefault("X-Amz-Credential")
  valid_774840 = validateParameter(valid_774840, JString, required = false,
                                 default = nil)
  if valid_774840 != nil:
    section.add "X-Amz-Credential", valid_774840
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_774841 = formData.getOrDefault("Enabled")
  valid_774841 = validateParameter(valid_774841, JBool, required = false, default = nil)
  if valid_774841 != nil:
    section.add "Enabled", valid_774841
  var valid_774842 = formData.getOrDefault("EventCategories")
  valid_774842 = validateParameter(valid_774842, JArray, required = false,
                                 default = nil)
  if valid_774842 != nil:
    section.add "EventCategories", valid_774842
  var valid_774843 = formData.getOrDefault("SnsTopicArn")
  valid_774843 = validateParameter(valid_774843, JString, required = false,
                                 default = nil)
  if valid_774843 != nil:
    section.add "SnsTopicArn", valid_774843
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_774844 = formData.getOrDefault("SubscriptionName")
  valid_774844 = validateParameter(valid_774844, JString, required = true,
                                 default = nil)
  if valid_774844 != nil:
    section.add "SubscriptionName", valid_774844
  var valid_774845 = formData.getOrDefault("SourceType")
  valid_774845 = validateParameter(valid_774845, JString, required = false,
                                 default = nil)
  if valid_774845 != nil:
    section.add "SourceType", valid_774845
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774846: Call_PostModifyEventSubscription_774829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774846.validator(path, query, header, formData, body)
  let scheme = call_774846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774846.url(scheme.get, call_774846.host, call_774846.base,
                         call_774846.route, valid.getOrDefault("path"))
  result = hook(call_774846, url, valid)

proc call*(call_774847: Call_PostModifyEventSubscription_774829;
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
  var query_774848 = newJObject()
  var formData_774849 = newJObject()
  add(formData_774849, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_774849.add "EventCategories", EventCategories
  add(formData_774849, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_774849, "SubscriptionName", newJString(SubscriptionName))
  add(query_774848, "Action", newJString(Action))
  add(query_774848, "Version", newJString(Version))
  add(formData_774849, "SourceType", newJString(SourceType))
  result = call_774847.call(nil, query_774848, nil, formData_774849, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_774829(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_774830, base: "/",
    url: url_PostModifyEventSubscription_774831,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_774809 = ref object of OpenApiRestCall_772581
proc url_GetModifyEventSubscription_774811(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyEventSubscription_774810(path: JsonNode; query: JsonNode;
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
  var valid_774812 = query.getOrDefault("SourceType")
  valid_774812 = validateParameter(valid_774812, JString, required = false,
                                 default = nil)
  if valid_774812 != nil:
    section.add "SourceType", valid_774812
  var valid_774813 = query.getOrDefault("Enabled")
  valid_774813 = validateParameter(valid_774813, JBool, required = false, default = nil)
  if valid_774813 != nil:
    section.add "Enabled", valid_774813
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774814 = query.getOrDefault("Action")
  valid_774814 = validateParameter(valid_774814, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_774814 != nil:
    section.add "Action", valid_774814
  var valid_774815 = query.getOrDefault("SnsTopicArn")
  valid_774815 = validateParameter(valid_774815, JString, required = false,
                                 default = nil)
  if valid_774815 != nil:
    section.add "SnsTopicArn", valid_774815
  var valid_774816 = query.getOrDefault("EventCategories")
  valid_774816 = validateParameter(valid_774816, JArray, required = false,
                                 default = nil)
  if valid_774816 != nil:
    section.add "EventCategories", valid_774816
  var valid_774817 = query.getOrDefault("SubscriptionName")
  valid_774817 = validateParameter(valid_774817, JString, required = true,
                                 default = nil)
  if valid_774817 != nil:
    section.add "SubscriptionName", valid_774817
  var valid_774818 = query.getOrDefault("Version")
  valid_774818 = validateParameter(valid_774818, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774818 != nil:
    section.add "Version", valid_774818
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774819 = header.getOrDefault("X-Amz-Date")
  valid_774819 = validateParameter(valid_774819, JString, required = false,
                                 default = nil)
  if valid_774819 != nil:
    section.add "X-Amz-Date", valid_774819
  var valid_774820 = header.getOrDefault("X-Amz-Security-Token")
  valid_774820 = validateParameter(valid_774820, JString, required = false,
                                 default = nil)
  if valid_774820 != nil:
    section.add "X-Amz-Security-Token", valid_774820
  var valid_774821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774821 = validateParameter(valid_774821, JString, required = false,
                                 default = nil)
  if valid_774821 != nil:
    section.add "X-Amz-Content-Sha256", valid_774821
  var valid_774822 = header.getOrDefault("X-Amz-Algorithm")
  valid_774822 = validateParameter(valid_774822, JString, required = false,
                                 default = nil)
  if valid_774822 != nil:
    section.add "X-Amz-Algorithm", valid_774822
  var valid_774823 = header.getOrDefault("X-Amz-Signature")
  valid_774823 = validateParameter(valid_774823, JString, required = false,
                                 default = nil)
  if valid_774823 != nil:
    section.add "X-Amz-Signature", valid_774823
  var valid_774824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774824 = validateParameter(valid_774824, JString, required = false,
                                 default = nil)
  if valid_774824 != nil:
    section.add "X-Amz-SignedHeaders", valid_774824
  var valid_774825 = header.getOrDefault("X-Amz-Credential")
  valid_774825 = validateParameter(valid_774825, JString, required = false,
                                 default = nil)
  if valid_774825 != nil:
    section.add "X-Amz-Credential", valid_774825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774826: Call_GetModifyEventSubscription_774809; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774826.validator(path, query, header, formData, body)
  let scheme = call_774826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774826.url(scheme.get, call_774826.host, call_774826.base,
                         call_774826.route, valid.getOrDefault("path"))
  result = hook(call_774826, url, valid)

proc call*(call_774827: Call_GetModifyEventSubscription_774809;
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
  var query_774828 = newJObject()
  add(query_774828, "SourceType", newJString(SourceType))
  add(query_774828, "Enabled", newJBool(Enabled))
  add(query_774828, "Action", newJString(Action))
  add(query_774828, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_774828.add "EventCategories", EventCategories
  add(query_774828, "SubscriptionName", newJString(SubscriptionName))
  add(query_774828, "Version", newJString(Version))
  result = call_774827.call(nil, query_774828, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_774809(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_774810, base: "/",
    url: url_GetModifyEventSubscription_774811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_774869 = ref object of OpenApiRestCall_772581
proc url_PostModifyOptionGroup_774871(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyOptionGroup_774870(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774872 = query.getOrDefault("Action")
  valid_774872 = validateParameter(valid_774872, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_774872 != nil:
    section.add "Action", valid_774872
  var valid_774873 = query.getOrDefault("Version")
  valid_774873 = validateParameter(valid_774873, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774873 != nil:
    section.add "Version", valid_774873
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774874 = header.getOrDefault("X-Amz-Date")
  valid_774874 = validateParameter(valid_774874, JString, required = false,
                                 default = nil)
  if valid_774874 != nil:
    section.add "X-Amz-Date", valid_774874
  var valid_774875 = header.getOrDefault("X-Amz-Security-Token")
  valid_774875 = validateParameter(valid_774875, JString, required = false,
                                 default = nil)
  if valid_774875 != nil:
    section.add "X-Amz-Security-Token", valid_774875
  var valid_774876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774876 = validateParameter(valid_774876, JString, required = false,
                                 default = nil)
  if valid_774876 != nil:
    section.add "X-Amz-Content-Sha256", valid_774876
  var valid_774877 = header.getOrDefault("X-Amz-Algorithm")
  valid_774877 = validateParameter(valid_774877, JString, required = false,
                                 default = nil)
  if valid_774877 != nil:
    section.add "X-Amz-Algorithm", valid_774877
  var valid_774878 = header.getOrDefault("X-Amz-Signature")
  valid_774878 = validateParameter(valid_774878, JString, required = false,
                                 default = nil)
  if valid_774878 != nil:
    section.add "X-Amz-Signature", valid_774878
  var valid_774879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774879 = validateParameter(valid_774879, JString, required = false,
                                 default = nil)
  if valid_774879 != nil:
    section.add "X-Amz-SignedHeaders", valid_774879
  var valid_774880 = header.getOrDefault("X-Amz-Credential")
  valid_774880 = validateParameter(valid_774880, JString, required = false,
                                 default = nil)
  if valid_774880 != nil:
    section.add "X-Amz-Credential", valid_774880
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_774881 = formData.getOrDefault("OptionsToRemove")
  valid_774881 = validateParameter(valid_774881, JArray, required = false,
                                 default = nil)
  if valid_774881 != nil:
    section.add "OptionsToRemove", valid_774881
  var valid_774882 = formData.getOrDefault("ApplyImmediately")
  valid_774882 = validateParameter(valid_774882, JBool, required = false, default = nil)
  if valid_774882 != nil:
    section.add "ApplyImmediately", valid_774882
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_774883 = formData.getOrDefault("OptionGroupName")
  valid_774883 = validateParameter(valid_774883, JString, required = true,
                                 default = nil)
  if valid_774883 != nil:
    section.add "OptionGroupName", valid_774883
  var valid_774884 = formData.getOrDefault("OptionsToInclude")
  valid_774884 = validateParameter(valid_774884, JArray, required = false,
                                 default = nil)
  if valid_774884 != nil:
    section.add "OptionsToInclude", valid_774884
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774885: Call_PostModifyOptionGroup_774869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774885.validator(path, query, header, formData, body)
  let scheme = call_774885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774885.url(scheme.get, call_774885.host, call_774885.base,
                         call_774885.route, valid.getOrDefault("path"))
  result = hook(call_774885, url, valid)

proc call*(call_774886: Call_PostModifyOptionGroup_774869; OptionGroupName: string;
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
  var query_774887 = newJObject()
  var formData_774888 = newJObject()
  if OptionsToRemove != nil:
    formData_774888.add "OptionsToRemove", OptionsToRemove
  add(formData_774888, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_774888, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_774888.add "OptionsToInclude", OptionsToInclude
  add(query_774887, "Action", newJString(Action))
  add(query_774887, "Version", newJString(Version))
  result = call_774886.call(nil, query_774887, nil, formData_774888, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_774869(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_774870, base: "/",
    url: url_PostModifyOptionGroup_774871, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_774850 = ref object of OpenApiRestCall_772581
proc url_GetModifyOptionGroup_774852(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyOptionGroup_774851(path: JsonNode; query: JsonNode;
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
  var valid_774853 = query.getOrDefault("OptionGroupName")
  valid_774853 = validateParameter(valid_774853, JString, required = true,
                                 default = nil)
  if valid_774853 != nil:
    section.add "OptionGroupName", valid_774853
  var valid_774854 = query.getOrDefault("OptionsToRemove")
  valid_774854 = validateParameter(valid_774854, JArray, required = false,
                                 default = nil)
  if valid_774854 != nil:
    section.add "OptionsToRemove", valid_774854
  var valid_774855 = query.getOrDefault("Action")
  valid_774855 = validateParameter(valid_774855, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_774855 != nil:
    section.add "Action", valid_774855
  var valid_774856 = query.getOrDefault("Version")
  valid_774856 = validateParameter(valid_774856, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774856 != nil:
    section.add "Version", valid_774856
  var valid_774857 = query.getOrDefault("ApplyImmediately")
  valid_774857 = validateParameter(valid_774857, JBool, required = false, default = nil)
  if valid_774857 != nil:
    section.add "ApplyImmediately", valid_774857
  var valid_774858 = query.getOrDefault("OptionsToInclude")
  valid_774858 = validateParameter(valid_774858, JArray, required = false,
                                 default = nil)
  if valid_774858 != nil:
    section.add "OptionsToInclude", valid_774858
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774859 = header.getOrDefault("X-Amz-Date")
  valid_774859 = validateParameter(valid_774859, JString, required = false,
                                 default = nil)
  if valid_774859 != nil:
    section.add "X-Amz-Date", valid_774859
  var valid_774860 = header.getOrDefault("X-Amz-Security-Token")
  valid_774860 = validateParameter(valid_774860, JString, required = false,
                                 default = nil)
  if valid_774860 != nil:
    section.add "X-Amz-Security-Token", valid_774860
  var valid_774861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774861 = validateParameter(valid_774861, JString, required = false,
                                 default = nil)
  if valid_774861 != nil:
    section.add "X-Amz-Content-Sha256", valid_774861
  var valid_774862 = header.getOrDefault("X-Amz-Algorithm")
  valid_774862 = validateParameter(valid_774862, JString, required = false,
                                 default = nil)
  if valid_774862 != nil:
    section.add "X-Amz-Algorithm", valid_774862
  var valid_774863 = header.getOrDefault("X-Amz-Signature")
  valid_774863 = validateParameter(valid_774863, JString, required = false,
                                 default = nil)
  if valid_774863 != nil:
    section.add "X-Amz-Signature", valid_774863
  var valid_774864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774864 = validateParameter(valid_774864, JString, required = false,
                                 default = nil)
  if valid_774864 != nil:
    section.add "X-Amz-SignedHeaders", valid_774864
  var valid_774865 = header.getOrDefault("X-Amz-Credential")
  valid_774865 = validateParameter(valid_774865, JString, required = false,
                                 default = nil)
  if valid_774865 != nil:
    section.add "X-Amz-Credential", valid_774865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774866: Call_GetModifyOptionGroup_774850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774866.validator(path, query, header, formData, body)
  let scheme = call_774866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774866.url(scheme.get, call_774866.host, call_774866.base,
                         call_774866.route, valid.getOrDefault("path"))
  result = hook(call_774866, url, valid)

proc call*(call_774867: Call_GetModifyOptionGroup_774850; OptionGroupName: string;
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
  var query_774868 = newJObject()
  add(query_774868, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_774868.add "OptionsToRemove", OptionsToRemove
  add(query_774868, "Action", newJString(Action))
  add(query_774868, "Version", newJString(Version))
  add(query_774868, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_774868.add "OptionsToInclude", OptionsToInclude
  result = call_774867.call(nil, query_774868, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_774850(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_774851, base: "/",
    url: url_GetModifyOptionGroup_774852, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_774907 = ref object of OpenApiRestCall_772581
proc url_PostPromoteReadReplica_774909(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPromoteReadReplica_774908(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774910 = query.getOrDefault("Action")
  valid_774910 = validateParameter(valid_774910, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_774910 != nil:
    section.add "Action", valid_774910
  var valid_774911 = query.getOrDefault("Version")
  valid_774911 = validateParameter(valid_774911, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774911 != nil:
    section.add "Version", valid_774911
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774912 = header.getOrDefault("X-Amz-Date")
  valid_774912 = validateParameter(valid_774912, JString, required = false,
                                 default = nil)
  if valid_774912 != nil:
    section.add "X-Amz-Date", valid_774912
  var valid_774913 = header.getOrDefault("X-Amz-Security-Token")
  valid_774913 = validateParameter(valid_774913, JString, required = false,
                                 default = nil)
  if valid_774913 != nil:
    section.add "X-Amz-Security-Token", valid_774913
  var valid_774914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774914 = validateParameter(valid_774914, JString, required = false,
                                 default = nil)
  if valid_774914 != nil:
    section.add "X-Amz-Content-Sha256", valid_774914
  var valid_774915 = header.getOrDefault("X-Amz-Algorithm")
  valid_774915 = validateParameter(valid_774915, JString, required = false,
                                 default = nil)
  if valid_774915 != nil:
    section.add "X-Amz-Algorithm", valid_774915
  var valid_774916 = header.getOrDefault("X-Amz-Signature")
  valid_774916 = validateParameter(valid_774916, JString, required = false,
                                 default = nil)
  if valid_774916 != nil:
    section.add "X-Amz-Signature", valid_774916
  var valid_774917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774917 = validateParameter(valid_774917, JString, required = false,
                                 default = nil)
  if valid_774917 != nil:
    section.add "X-Amz-SignedHeaders", valid_774917
  var valid_774918 = header.getOrDefault("X-Amz-Credential")
  valid_774918 = validateParameter(valid_774918, JString, required = false,
                                 default = nil)
  if valid_774918 != nil:
    section.add "X-Amz-Credential", valid_774918
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774919 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774919 = validateParameter(valid_774919, JString, required = true,
                                 default = nil)
  if valid_774919 != nil:
    section.add "DBInstanceIdentifier", valid_774919
  var valid_774920 = formData.getOrDefault("BackupRetentionPeriod")
  valid_774920 = validateParameter(valid_774920, JInt, required = false, default = nil)
  if valid_774920 != nil:
    section.add "BackupRetentionPeriod", valid_774920
  var valid_774921 = formData.getOrDefault("PreferredBackupWindow")
  valid_774921 = validateParameter(valid_774921, JString, required = false,
                                 default = nil)
  if valid_774921 != nil:
    section.add "PreferredBackupWindow", valid_774921
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774922: Call_PostPromoteReadReplica_774907; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774922.validator(path, query, header, formData, body)
  let scheme = call_774922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774922.url(scheme.get, call_774922.host, call_774922.base,
                         call_774922.route, valid.getOrDefault("path"))
  result = hook(call_774922, url, valid)

proc call*(call_774923: Call_PostPromoteReadReplica_774907;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_774924 = newJObject()
  var formData_774925 = newJObject()
  add(formData_774925, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774925, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_774924, "Action", newJString(Action))
  add(formData_774925, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_774924, "Version", newJString(Version))
  result = call_774923.call(nil, query_774924, nil, formData_774925, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_774907(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_774908, base: "/",
    url: url_PostPromoteReadReplica_774909, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_774889 = ref object of OpenApiRestCall_772581
proc url_GetPromoteReadReplica_774891(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPromoteReadReplica_774890(path: JsonNode; query: JsonNode;
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
  var valid_774892 = query.getOrDefault("BackupRetentionPeriod")
  valid_774892 = validateParameter(valid_774892, JInt, required = false, default = nil)
  if valid_774892 != nil:
    section.add "BackupRetentionPeriod", valid_774892
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774893 = query.getOrDefault("Action")
  valid_774893 = validateParameter(valid_774893, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_774893 != nil:
    section.add "Action", valid_774893
  var valid_774894 = query.getOrDefault("PreferredBackupWindow")
  valid_774894 = validateParameter(valid_774894, JString, required = false,
                                 default = nil)
  if valid_774894 != nil:
    section.add "PreferredBackupWindow", valid_774894
  var valid_774895 = query.getOrDefault("Version")
  valid_774895 = validateParameter(valid_774895, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774895 != nil:
    section.add "Version", valid_774895
  var valid_774896 = query.getOrDefault("DBInstanceIdentifier")
  valid_774896 = validateParameter(valid_774896, JString, required = true,
                                 default = nil)
  if valid_774896 != nil:
    section.add "DBInstanceIdentifier", valid_774896
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774897 = header.getOrDefault("X-Amz-Date")
  valid_774897 = validateParameter(valid_774897, JString, required = false,
                                 default = nil)
  if valid_774897 != nil:
    section.add "X-Amz-Date", valid_774897
  var valid_774898 = header.getOrDefault("X-Amz-Security-Token")
  valid_774898 = validateParameter(valid_774898, JString, required = false,
                                 default = nil)
  if valid_774898 != nil:
    section.add "X-Amz-Security-Token", valid_774898
  var valid_774899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774899 = validateParameter(valid_774899, JString, required = false,
                                 default = nil)
  if valid_774899 != nil:
    section.add "X-Amz-Content-Sha256", valid_774899
  var valid_774900 = header.getOrDefault("X-Amz-Algorithm")
  valid_774900 = validateParameter(valid_774900, JString, required = false,
                                 default = nil)
  if valid_774900 != nil:
    section.add "X-Amz-Algorithm", valid_774900
  var valid_774901 = header.getOrDefault("X-Amz-Signature")
  valid_774901 = validateParameter(valid_774901, JString, required = false,
                                 default = nil)
  if valid_774901 != nil:
    section.add "X-Amz-Signature", valid_774901
  var valid_774902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774902 = validateParameter(valid_774902, JString, required = false,
                                 default = nil)
  if valid_774902 != nil:
    section.add "X-Amz-SignedHeaders", valid_774902
  var valid_774903 = header.getOrDefault("X-Amz-Credential")
  valid_774903 = validateParameter(valid_774903, JString, required = false,
                                 default = nil)
  if valid_774903 != nil:
    section.add "X-Amz-Credential", valid_774903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774904: Call_GetPromoteReadReplica_774889; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774904.validator(path, query, header, formData, body)
  let scheme = call_774904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774904.url(scheme.get, call_774904.host, call_774904.base,
                         call_774904.route, valid.getOrDefault("path"))
  result = hook(call_774904, url, valid)

proc call*(call_774905: Call_GetPromoteReadReplica_774889;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_774906 = newJObject()
  add(query_774906, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_774906, "Action", newJString(Action))
  add(query_774906, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_774906, "Version", newJString(Version))
  add(query_774906, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_774905.call(nil, query_774906, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_774889(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_774890, base: "/",
    url: url_GetPromoteReadReplica_774891, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_774944 = ref object of OpenApiRestCall_772581
proc url_PostPurchaseReservedDBInstancesOffering_774946(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPurchaseReservedDBInstancesOffering_774945(path: JsonNode;
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
  var valid_774947 = query.getOrDefault("Action")
  valid_774947 = validateParameter(valid_774947, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_774947 != nil:
    section.add "Action", valid_774947
  var valid_774948 = query.getOrDefault("Version")
  valid_774948 = validateParameter(valid_774948, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774948 != nil:
    section.add "Version", valid_774948
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774949 = header.getOrDefault("X-Amz-Date")
  valid_774949 = validateParameter(valid_774949, JString, required = false,
                                 default = nil)
  if valid_774949 != nil:
    section.add "X-Amz-Date", valid_774949
  var valid_774950 = header.getOrDefault("X-Amz-Security-Token")
  valid_774950 = validateParameter(valid_774950, JString, required = false,
                                 default = nil)
  if valid_774950 != nil:
    section.add "X-Amz-Security-Token", valid_774950
  var valid_774951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774951 = validateParameter(valid_774951, JString, required = false,
                                 default = nil)
  if valid_774951 != nil:
    section.add "X-Amz-Content-Sha256", valid_774951
  var valid_774952 = header.getOrDefault("X-Amz-Algorithm")
  valid_774952 = validateParameter(valid_774952, JString, required = false,
                                 default = nil)
  if valid_774952 != nil:
    section.add "X-Amz-Algorithm", valid_774952
  var valid_774953 = header.getOrDefault("X-Amz-Signature")
  valid_774953 = validateParameter(valid_774953, JString, required = false,
                                 default = nil)
  if valid_774953 != nil:
    section.add "X-Amz-Signature", valid_774953
  var valid_774954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774954 = validateParameter(valid_774954, JString, required = false,
                                 default = nil)
  if valid_774954 != nil:
    section.add "X-Amz-SignedHeaders", valid_774954
  var valid_774955 = header.getOrDefault("X-Amz-Credential")
  valid_774955 = validateParameter(valid_774955, JString, required = false,
                                 default = nil)
  if valid_774955 != nil:
    section.add "X-Amz-Credential", valid_774955
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_774956 = formData.getOrDefault("ReservedDBInstanceId")
  valid_774956 = validateParameter(valid_774956, JString, required = false,
                                 default = nil)
  if valid_774956 != nil:
    section.add "ReservedDBInstanceId", valid_774956
  var valid_774957 = formData.getOrDefault("DBInstanceCount")
  valid_774957 = validateParameter(valid_774957, JInt, required = false, default = nil)
  if valid_774957 != nil:
    section.add "DBInstanceCount", valid_774957
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_774958 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774958 = validateParameter(valid_774958, JString, required = true,
                                 default = nil)
  if valid_774958 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774958
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774959: Call_PostPurchaseReservedDBInstancesOffering_774944;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774959.validator(path, query, header, formData, body)
  let scheme = call_774959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774959.url(scheme.get, call_774959.host, call_774959.base,
                         call_774959.route, valid.getOrDefault("path"))
  result = hook(call_774959, url, valid)

proc call*(call_774960: Call_PostPurchaseReservedDBInstancesOffering_774944;
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
  var query_774961 = newJObject()
  var formData_774962 = newJObject()
  add(formData_774962, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_774962, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_774961, "Action", newJString(Action))
  add(formData_774962, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774961, "Version", newJString(Version))
  result = call_774960.call(nil, query_774961, nil, formData_774962, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_774944(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_774945, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_774946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_774926 = ref object of OpenApiRestCall_772581
proc url_GetPurchaseReservedDBInstancesOffering_774928(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPurchaseReservedDBInstancesOffering_774927(path: JsonNode;
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
  var valid_774929 = query.getOrDefault("DBInstanceCount")
  valid_774929 = validateParameter(valid_774929, JInt, required = false, default = nil)
  if valid_774929 != nil:
    section.add "DBInstanceCount", valid_774929
  var valid_774930 = query.getOrDefault("ReservedDBInstanceId")
  valid_774930 = validateParameter(valid_774930, JString, required = false,
                                 default = nil)
  if valid_774930 != nil:
    section.add "ReservedDBInstanceId", valid_774930
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_774931 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774931 = validateParameter(valid_774931, JString, required = true,
                                 default = nil)
  if valid_774931 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774931
  var valid_774932 = query.getOrDefault("Action")
  valid_774932 = validateParameter(valid_774932, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_774932 != nil:
    section.add "Action", valid_774932
  var valid_774933 = query.getOrDefault("Version")
  valid_774933 = validateParameter(valid_774933, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774933 != nil:
    section.add "Version", valid_774933
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774934 = header.getOrDefault("X-Amz-Date")
  valid_774934 = validateParameter(valid_774934, JString, required = false,
                                 default = nil)
  if valid_774934 != nil:
    section.add "X-Amz-Date", valid_774934
  var valid_774935 = header.getOrDefault("X-Amz-Security-Token")
  valid_774935 = validateParameter(valid_774935, JString, required = false,
                                 default = nil)
  if valid_774935 != nil:
    section.add "X-Amz-Security-Token", valid_774935
  var valid_774936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774936 = validateParameter(valid_774936, JString, required = false,
                                 default = nil)
  if valid_774936 != nil:
    section.add "X-Amz-Content-Sha256", valid_774936
  var valid_774937 = header.getOrDefault("X-Amz-Algorithm")
  valid_774937 = validateParameter(valid_774937, JString, required = false,
                                 default = nil)
  if valid_774937 != nil:
    section.add "X-Amz-Algorithm", valid_774937
  var valid_774938 = header.getOrDefault("X-Amz-Signature")
  valid_774938 = validateParameter(valid_774938, JString, required = false,
                                 default = nil)
  if valid_774938 != nil:
    section.add "X-Amz-Signature", valid_774938
  var valid_774939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774939 = validateParameter(valid_774939, JString, required = false,
                                 default = nil)
  if valid_774939 != nil:
    section.add "X-Amz-SignedHeaders", valid_774939
  var valid_774940 = header.getOrDefault("X-Amz-Credential")
  valid_774940 = validateParameter(valid_774940, JString, required = false,
                                 default = nil)
  if valid_774940 != nil:
    section.add "X-Amz-Credential", valid_774940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774941: Call_GetPurchaseReservedDBInstancesOffering_774926;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774941.validator(path, query, header, formData, body)
  let scheme = call_774941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774941.url(scheme.get, call_774941.host, call_774941.base,
                         call_774941.route, valid.getOrDefault("path"))
  result = hook(call_774941, url, valid)

proc call*(call_774942: Call_GetPurchaseReservedDBInstancesOffering_774926;
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
  var query_774943 = newJObject()
  add(query_774943, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_774943, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_774943, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774943, "Action", newJString(Action))
  add(query_774943, "Version", newJString(Version))
  result = call_774942.call(nil, query_774943, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_774926(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_774927, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_774928,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_774980 = ref object of OpenApiRestCall_772581
proc url_PostRebootDBInstance_774982(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebootDBInstance_774981(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774983 = query.getOrDefault("Action")
  valid_774983 = validateParameter(valid_774983, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_774983 != nil:
    section.add "Action", valid_774983
  var valid_774984 = query.getOrDefault("Version")
  valid_774984 = validateParameter(valid_774984, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774984 != nil:
    section.add "Version", valid_774984
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774985 = header.getOrDefault("X-Amz-Date")
  valid_774985 = validateParameter(valid_774985, JString, required = false,
                                 default = nil)
  if valid_774985 != nil:
    section.add "X-Amz-Date", valid_774985
  var valid_774986 = header.getOrDefault("X-Amz-Security-Token")
  valid_774986 = validateParameter(valid_774986, JString, required = false,
                                 default = nil)
  if valid_774986 != nil:
    section.add "X-Amz-Security-Token", valid_774986
  var valid_774987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774987 = validateParameter(valid_774987, JString, required = false,
                                 default = nil)
  if valid_774987 != nil:
    section.add "X-Amz-Content-Sha256", valid_774987
  var valid_774988 = header.getOrDefault("X-Amz-Algorithm")
  valid_774988 = validateParameter(valid_774988, JString, required = false,
                                 default = nil)
  if valid_774988 != nil:
    section.add "X-Amz-Algorithm", valid_774988
  var valid_774989 = header.getOrDefault("X-Amz-Signature")
  valid_774989 = validateParameter(valid_774989, JString, required = false,
                                 default = nil)
  if valid_774989 != nil:
    section.add "X-Amz-Signature", valid_774989
  var valid_774990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774990 = validateParameter(valid_774990, JString, required = false,
                                 default = nil)
  if valid_774990 != nil:
    section.add "X-Amz-SignedHeaders", valid_774990
  var valid_774991 = header.getOrDefault("X-Amz-Credential")
  valid_774991 = validateParameter(valid_774991, JString, required = false,
                                 default = nil)
  if valid_774991 != nil:
    section.add "X-Amz-Credential", valid_774991
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774992 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774992 = validateParameter(valid_774992, JString, required = true,
                                 default = nil)
  if valid_774992 != nil:
    section.add "DBInstanceIdentifier", valid_774992
  var valid_774993 = formData.getOrDefault("ForceFailover")
  valid_774993 = validateParameter(valid_774993, JBool, required = false, default = nil)
  if valid_774993 != nil:
    section.add "ForceFailover", valid_774993
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774994: Call_PostRebootDBInstance_774980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774994.validator(path, query, header, formData, body)
  let scheme = call_774994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774994.url(scheme.get, call_774994.host, call_774994.base,
                         call_774994.route, valid.getOrDefault("path"))
  result = hook(call_774994, url, valid)

proc call*(call_774995: Call_PostRebootDBInstance_774980;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_774996 = newJObject()
  var formData_774997 = newJObject()
  add(formData_774997, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_774996, "Action", newJString(Action))
  add(formData_774997, "ForceFailover", newJBool(ForceFailover))
  add(query_774996, "Version", newJString(Version))
  result = call_774995.call(nil, query_774996, nil, formData_774997, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_774980(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_774981, base: "/",
    url: url_PostRebootDBInstance_774982, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_774963 = ref object of OpenApiRestCall_772581
proc url_GetRebootDBInstance_774965(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebootDBInstance_774964(path: JsonNode; query: JsonNode;
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
  var valid_774966 = query.getOrDefault("Action")
  valid_774966 = validateParameter(valid_774966, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_774966 != nil:
    section.add "Action", valid_774966
  var valid_774967 = query.getOrDefault("ForceFailover")
  valid_774967 = validateParameter(valid_774967, JBool, required = false, default = nil)
  if valid_774967 != nil:
    section.add "ForceFailover", valid_774967
  var valid_774968 = query.getOrDefault("Version")
  valid_774968 = validateParameter(valid_774968, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_774968 != nil:
    section.add "Version", valid_774968
  var valid_774969 = query.getOrDefault("DBInstanceIdentifier")
  valid_774969 = validateParameter(valid_774969, JString, required = true,
                                 default = nil)
  if valid_774969 != nil:
    section.add "DBInstanceIdentifier", valid_774969
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774970 = header.getOrDefault("X-Amz-Date")
  valid_774970 = validateParameter(valid_774970, JString, required = false,
                                 default = nil)
  if valid_774970 != nil:
    section.add "X-Amz-Date", valid_774970
  var valid_774971 = header.getOrDefault("X-Amz-Security-Token")
  valid_774971 = validateParameter(valid_774971, JString, required = false,
                                 default = nil)
  if valid_774971 != nil:
    section.add "X-Amz-Security-Token", valid_774971
  var valid_774972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774972 = validateParameter(valid_774972, JString, required = false,
                                 default = nil)
  if valid_774972 != nil:
    section.add "X-Amz-Content-Sha256", valid_774972
  var valid_774973 = header.getOrDefault("X-Amz-Algorithm")
  valid_774973 = validateParameter(valid_774973, JString, required = false,
                                 default = nil)
  if valid_774973 != nil:
    section.add "X-Amz-Algorithm", valid_774973
  var valid_774974 = header.getOrDefault("X-Amz-Signature")
  valid_774974 = validateParameter(valid_774974, JString, required = false,
                                 default = nil)
  if valid_774974 != nil:
    section.add "X-Amz-Signature", valid_774974
  var valid_774975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774975 = validateParameter(valid_774975, JString, required = false,
                                 default = nil)
  if valid_774975 != nil:
    section.add "X-Amz-SignedHeaders", valid_774975
  var valid_774976 = header.getOrDefault("X-Amz-Credential")
  valid_774976 = validateParameter(valid_774976, JString, required = false,
                                 default = nil)
  if valid_774976 != nil:
    section.add "X-Amz-Credential", valid_774976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774977: Call_GetRebootDBInstance_774963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774977.validator(path, query, header, formData, body)
  let scheme = call_774977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774977.url(scheme.get, call_774977.host, call_774977.base,
                         call_774977.route, valid.getOrDefault("path"))
  result = hook(call_774977, url, valid)

proc call*(call_774978: Call_GetRebootDBInstance_774963;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-02-12"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_774979 = newJObject()
  add(query_774979, "Action", newJString(Action))
  add(query_774979, "ForceFailover", newJBool(ForceFailover))
  add(query_774979, "Version", newJString(Version))
  add(query_774979, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_774978.call(nil, query_774979, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_774963(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_774964, base: "/",
    url: url_GetRebootDBInstance_774965, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_775015 = ref object of OpenApiRestCall_772581
proc url_PostRemoveSourceIdentifierFromSubscription_775017(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_775016(path: JsonNode;
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
  var valid_775018 = query.getOrDefault("Action")
  valid_775018 = validateParameter(valid_775018, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_775018 != nil:
    section.add "Action", valid_775018
  var valid_775019 = query.getOrDefault("Version")
  valid_775019 = validateParameter(valid_775019, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_775019 != nil:
    section.add "Version", valid_775019
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775020 = header.getOrDefault("X-Amz-Date")
  valid_775020 = validateParameter(valid_775020, JString, required = false,
                                 default = nil)
  if valid_775020 != nil:
    section.add "X-Amz-Date", valid_775020
  var valid_775021 = header.getOrDefault("X-Amz-Security-Token")
  valid_775021 = validateParameter(valid_775021, JString, required = false,
                                 default = nil)
  if valid_775021 != nil:
    section.add "X-Amz-Security-Token", valid_775021
  var valid_775022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775022 = validateParameter(valid_775022, JString, required = false,
                                 default = nil)
  if valid_775022 != nil:
    section.add "X-Amz-Content-Sha256", valid_775022
  var valid_775023 = header.getOrDefault("X-Amz-Algorithm")
  valid_775023 = validateParameter(valid_775023, JString, required = false,
                                 default = nil)
  if valid_775023 != nil:
    section.add "X-Amz-Algorithm", valid_775023
  var valid_775024 = header.getOrDefault("X-Amz-Signature")
  valid_775024 = validateParameter(valid_775024, JString, required = false,
                                 default = nil)
  if valid_775024 != nil:
    section.add "X-Amz-Signature", valid_775024
  var valid_775025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775025 = validateParameter(valid_775025, JString, required = false,
                                 default = nil)
  if valid_775025 != nil:
    section.add "X-Amz-SignedHeaders", valid_775025
  var valid_775026 = header.getOrDefault("X-Amz-Credential")
  valid_775026 = validateParameter(valid_775026, JString, required = false,
                                 default = nil)
  if valid_775026 != nil:
    section.add "X-Amz-Credential", valid_775026
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_775027 = formData.getOrDefault("SourceIdentifier")
  valid_775027 = validateParameter(valid_775027, JString, required = true,
                                 default = nil)
  if valid_775027 != nil:
    section.add "SourceIdentifier", valid_775027
  var valid_775028 = formData.getOrDefault("SubscriptionName")
  valid_775028 = validateParameter(valid_775028, JString, required = true,
                                 default = nil)
  if valid_775028 != nil:
    section.add "SubscriptionName", valid_775028
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775029: Call_PostRemoveSourceIdentifierFromSubscription_775015;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775029.validator(path, query, header, formData, body)
  let scheme = call_775029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775029.url(scheme.get, call_775029.host, call_775029.base,
                         call_775029.route, valid.getOrDefault("path"))
  result = hook(call_775029, url, valid)

proc call*(call_775030: Call_PostRemoveSourceIdentifierFromSubscription_775015;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_775031 = newJObject()
  var formData_775032 = newJObject()
  add(formData_775032, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_775032, "SubscriptionName", newJString(SubscriptionName))
  add(query_775031, "Action", newJString(Action))
  add(query_775031, "Version", newJString(Version))
  result = call_775030.call(nil, query_775031, nil, formData_775032, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_775015(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_775016,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_775017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_774998 = ref object of OpenApiRestCall_772581
proc url_GetRemoveSourceIdentifierFromSubscription_775000(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_774999(path: JsonNode;
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
  var valid_775001 = query.getOrDefault("Action")
  valid_775001 = validateParameter(valid_775001, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_775001 != nil:
    section.add "Action", valid_775001
  var valid_775002 = query.getOrDefault("SourceIdentifier")
  valid_775002 = validateParameter(valid_775002, JString, required = true,
                                 default = nil)
  if valid_775002 != nil:
    section.add "SourceIdentifier", valid_775002
  var valid_775003 = query.getOrDefault("SubscriptionName")
  valid_775003 = validateParameter(valid_775003, JString, required = true,
                                 default = nil)
  if valid_775003 != nil:
    section.add "SubscriptionName", valid_775003
  var valid_775004 = query.getOrDefault("Version")
  valid_775004 = validateParameter(valid_775004, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_775004 != nil:
    section.add "Version", valid_775004
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775005 = header.getOrDefault("X-Amz-Date")
  valid_775005 = validateParameter(valid_775005, JString, required = false,
                                 default = nil)
  if valid_775005 != nil:
    section.add "X-Amz-Date", valid_775005
  var valid_775006 = header.getOrDefault("X-Amz-Security-Token")
  valid_775006 = validateParameter(valid_775006, JString, required = false,
                                 default = nil)
  if valid_775006 != nil:
    section.add "X-Amz-Security-Token", valid_775006
  var valid_775007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775007 = validateParameter(valid_775007, JString, required = false,
                                 default = nil)
  if valid_775007 != nil:
    section.add "X-Amz-Content-Sha256", valid_775007
  var valid_775008 = header.getOrDefault("X-Amz-Algorithm")
  valid_775008 = validateParameter(valid_775008, JString, required = false,
                                 default = nil)
  if valid_775008 != nil:
    section.add "X-Amz-Algorithm", valid_775008
  var valid_775009 = header.getOrDefault("X-Amz-Signature")
  valid_775009 = validateParameter(valid_775009, JString, required = false,
                                 default = nil)
  if valid_775009 != nil:
    section.add "X-Amz-Signature", valid_775009
  var valid_775010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775010 = validateParameter(valid_775010, JString, required = false,
                                 default = nil)
  if valid_775010 != nil:
    section.add "X-Amz-SignedHeaders", valid_775010
  var valid_775011 = header.getOrDefault("X-Amz-Credential")
  valid_775011 = validateParameter(valid_775011, JString, required = false,
                                 default = nil)
  if valid_775011 != nil:
    section.add "X-Amz-Credential", valid_775011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775012: Call_GetRemoveSourceIdentifierFromSubscription_774998;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775012.validator(path, query, header, formData, body)
  let scheme = call_775012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775012.url(scheme.get, call_775012.host, call_775012.base,
                         call_775012.route, valid.getOrDefault("path"))
  result = hook(call_775012, url, valid)

proc call*(call_775013: Call_GetRemoveSourceIdentifierFromSubscription_774998;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_775014 = newJObject()
  add(query_775014, "Action", newJString(Action))
  add(query_775014, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_775014, "SubscriptionName", newJString(SubscriptionName))
  add(query_775014, "Version", newJString(Version))
  result = call_775013.call(nil, query_775014, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_774998(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_774999,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_775000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_775050 = ref object of OpenApiRestCall_772581
proc url_PostRemoveTagsFromResource_775052(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTagsFromResource_775051(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775053 = query.getOrDefault("Action")
  valid_775053 = validateParameter(valid_775053, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_775053 != nil:
    section.add "Action", valid_775053
  var valid_775054 = query.getOrDefault("Version")
  valid_775054 = validateParameter(valid_775054, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_775054 != nil:
    section.add "Version", valid_775054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775055 = header.getOrDefault("X-Amz-Date")
  valid_775055 = validateParameter(valid_775055, JString, required = false,
                                 default = nil)
  if valid_775055 != nil:
    section.add "X-Amz-Date", valid_775055
  var valid_775056 = header.getOrDefault("X-Amz-Security-Token")
  valid_775056 = validateParameter(valid_775056, JString, required = false,
                                 default = nil)
  if valid_775056 != nil:
    section.add "X-Amz-Security-Token", valid_775056
  var valid_775057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775057 = validateParameter(valid_775057, JString, required = false,
                                 default = nil)
  if valid_775057 != nil:
    section.add "X-Amz-Content-Sha256", valid_775057
  var valid_775058 = header.getOrDefault("X-Amz-Algorithm")
  valid_775058 = validateParameter(valid_775058, JString, required = false,
                                 default = nil)
  if valid_775058 != nil:
    section.add "X-Amz-Algorithm", valid_775058
  var valid_775059 = header.getOrDefault("X-Amz-Signature")
  valid_775059 = validateParameter(valid_775059, JString, required = false,
                                 default = nil)
  if valid_775059 != nil:
    section.add "X-Amz-Signature", valid_775059
  var valid_775060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775060 = validateParameter(valid_775060, JString, required = false,
                                 default = nil)
  if valid_775060 != nil:
    section.add "X-Amz-SignedHeaders", valid_775060
  var valid_775061 = header.getOrDefault("X-Amz-Credential")
  valid_775061 = validateParameter(valid_775061, JString, required = false,
                                 default = nil)
  if valid_775061 != nil:
    section.add "X-Amz-Credential", valid_775061
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_775062 = formData.getOrDefault("TagKeys")
  valid_775062 = validateParameter(valid_775062, JArray, required = true, default = nil)
  if valid_775062 != nil:
    section.add "TagKeys", valid_775062
  var valid_775063 = formData.getOrDefault("ResourceName")
  valid_775063 = validateParameter(valid_775063, JString, required = true,
                                 default = nil)
  if valid_775063 != nil:
    section.add "ResourceName", valid_775063
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775064: Call_PostRemoveTagsFromResource_775050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775064.validator(path, query, header, formData, body)
  let scheme = call_775064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775064.url(scheme.get, call_775064.host, call_775064.base,
                         call_775064.route, valid.getOrDefault("path"))
  result = hook(call_775064, url, valid)

proc call*(call_775065: Call_PostRemoveTagsFromResource_775050; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_775066 = newJObject()
  var formData_775067 = newJObject()
  add(query_775066, "Action", newJString(Action))
  if TagKeys != nil:
    formData_775067.add "TagKeys", TagKeys
  add(formData_775067, "ResourceName", newJString(ResourceName))
  add(query_775066, "Version", newJString(Version))
  result = call_775065.call(nil, query_775066, nil, formData_775067, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_775050(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_775051, base: "/",
    url: url_PostRemoveTagsFromResource_775052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_775033 = ref object of OpenApiRestCall_772581
proc url_GetRemoveTagsFromResource_775035(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTagsFromResource_775034(path: JsonNode; query: JsonNode;
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
  var valid_775036 = query.getOrDefault("ResourceName")
  valid_775036 = validateParameter(valid_775036, JString, required = true,
                                 default = nil)
  if valid_775036 != nil:
    section.add "ResourceName", valid_775036
  var valid_775037 = query.getOrDefault("Action")
  valid_775037 = validateParameter(valid_775037, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_775037 != nil:
    section.add "Action", valid_775037
  var valid_775038 = query.getOrDefault("TagKeys")
  valid_775038 = validateParameter(valid_775038, JArray, required = true, default = nil)
  if valid_775038 != nil:
    section.add "TagKeys", valid_775038
  var valid_775039 = query.getOrDefault("Version")
  valid_775039 = validateParameter(valid_775039, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_775039 != nil:
    section.add "Version", valid_775039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775040 = header.getOrDefault("X-Amz-Date")
  valid_775040 = validateParameter(valid_775040, JString, required = false,
                                 default = nil)
  if valid_775040 != nil:
    section.add "X-Amz-Date", valid_775040
  var valid_775041 = header.getOrDefault("X-Amz-Security-Token")
  valid_775041 = validateParameter(valid_775041, JString, required = false,
                                 default = nil)
  if valid_775041 != nil:
    section.add "X-Amz-Security-Token", valid_775041
  var valid_775042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775042 = validateParameter(valid_775042, JString, required = false,
                                 default = nil)
  if valid_775042 != nil:
    section.add "X-Amz-Content-Sha256", valid_775042
  var valid_775043 = header.getOrDefault("X-Amz-Algorithm")
  valid_775043 = validateParameter(valid_775043, JString, required = false,
                                 default = nil)
  if valid_775043 != nil:
    section.add "X-Amz-Algorithm", valid_775043
  var valid_775044 = header.getOrDefault("X-Amz-Signature")
  valid_775044 = validateParameter(valid_775044, JString, required = false,
                                 default = nil)
  if valid_775044 != nil:
    section.add "X-Amz-Signature", valid_775044
  var valid_775045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775045 = validateParameter(valid_775045, JString, required = false,
                                 default = nil)
  if valid_775045 != nil:
    section.add "X-Amz-SignedHeaders", valid_775045
  var valid_775046 = header.getOrDefault("X-Amz-Credential")
  valid_775046 = validateParameter(valid_775046, JString, required = false,
                                 default = nil)
  if valid_775046 != nil:
    section.add "X-Amz-Credential", valid_775046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775047: Call_GetRemoveTagsFromResource_775033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775047.validator(path, query, header, formData, body)
  let scheme = call_775047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775047.url(scheme.get, call_775047.host, call_775047.base,
                         call_775047.route, valid.getOrDefault("path"))
  result = hook(call_775047, url, valid)

proc call*(call_775048: Call_GetRemoveTagsFromResource_775033;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-02-12"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_775049 = newJObject()
  add(query_775049, "ResourceName", newJString(ResourceName))
  add(query_775049, "Action", newJString(Action))
  if TagKeys != nil:
    query_775049.add "TagKeys", TagKeys
  add(query_775049, "Version", newJString(Version))
  result = call_775048.call(nil, query_775049, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_775033(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_775034, base: "/",
    url: url_GetRemoveTagsFromResource_775035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_775086 = ref object of OpenApiRestCall_772581
proc url_PostResetDBParameterGroup_775088(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostResetDBParameterGroup_775087(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775089 = query.getOrDefault("Action")
  valid_775089 = validateParameter(valid_775089, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_775089 != nil:
    section.add "Action", valid_775089
  var valid_775090 = query.getOrDefault("Version")
  valid_775090 = validateParameter(valid_775090, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_775090 != nil:
    section.add "Version", valid_775090
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775091 = header.getOrDefault("X-Amz-Date")
  valid_775091 = validateParameter(valid_775091, JString, required = false,
                                 default = nil)
  if valid_775091 != nil:
    section.add "X-Amz-Date", valid_775091
  var valid_775092 = header.getOrDefault("X-Amz-Security-Token")
  valid_775092 = validateParameter(valid_775092, JString, required = false,
                                 default = nil)
  if valid_775092 != nil:
    section.add "X-Amz-Security-Token", valid_775092
  var valid_775093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775093 = validateParameter(valid_775093, JString, required = false,
                                 default = nil)
  if valid_775093 != nil:
    section.add "X-Amz-Content-Sha256", valid_775093
  var valid_775094 = header.getOrDefault("X-Amz-Algorithm")
  valid_775094 = validateParameter(valid_775094, JString, required = false,
                                 default = nil)
  if valid_775094 != nil:
    section.add "X-Amz-Algorithm", valid_775094
  var valid_775095 = header.getOrDefault("X-Amz-Signature")
  valid_775095 = validateParameter(valid_775095, JString, required = false,
                                 default = nil)
  if valid_775095 != nil:
    section.add "X-Amz-Signature", valid_775095
  var valid_775096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775096 = validateParameter(valid_775096, JString, required = false,
                                 default = nil)
  if valid_775096 != nil:
    section.add "X-Amz-SignedHeaders", valid_775096
  var valid_775097 = header.getOrDefault("X-Amz-Credential")
  valid_775097 = validateParameter(valid_775097, JString, required = false,
                                 default = nil)
  if valid_775097 != nil:
    section.add "X-Amz-Credential", valid_775097
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_775098 = formData.getOrDefault("DBParameterGroupName")
  valid_775098 = validateParameter(valid_775098, JString, required = true,
                                 default = nil)
  if valid_775098 != nil:
    section.add "DBParameterGroupName", valid_775098
  var valid_775099 = formData.getOrDefault("Parameters")
  valid_775099 = validateParameter(valid_775099, JArray, required = false,
                                 default = nil)
  if valid_775099 != nil:
    section.add "Parameters", valid_775099
  var valid_775100 = formData.getOrDefault("ResetAllParameters")
  valid_775100 = validateParameter(valid_775100, JBool, required = false, default = nil)
  if valid_775100 != nil:
    section.add "ResetAllParameters", valid_775100
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775101: Call_PostResetDBParameterGroup_775086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775101.validator(path, query, header, formData, body)
  let scheme = call_775101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775101.url(scheme.get, call_775101.host, call_775101.base,
                         call_775101.route, valid.getOrDefault("path"))
  result = hook(call_775101, url, valid)

proc call*(call_775102: Call_PostResetDBParameterGroup_775086;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_775103 = newJObject()
  var formData_775104 = newJObject()
  add(formData_775104, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_775104.add "Parameters", Parameters
  add(query_775103, "Action", newJString(Action))
  add(formData_775104, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_775103, "Version", newJString(Version))
  result = call_775102.call(nil, query_775103, nil, formData_775104, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_775086(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_775087, base: "/",
    url: url_PostResetDBParameterGroup_775088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_775068 = ref object of OpenApiRestCall_772581
proc url_GetResetDBParameterGroup_775070(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResetDBParameterGroup_775069(path: JsonNode; query: JsonNode;
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
  var valid_775071 = query.getOrDefault("DBParameterGroupName")
  valid_775071 = validateParameter(valid_775071, JString, required = true,
                                 default = nil)
  if valid_775071 != nil:
    section.add "DBParameterGroupName", valid_775071
  var valid_775072 = query.getOrDefault("Parameters")
  valid_775072 = validateParameter(valid_775072, JArray, required = false,
                                 default = nil)
  if valid_775072 != nil:
    section.add "Parameters", valid_775072
  var valid_775073 = query.getOrDefault("Action")
  valid_775073 = validateParameter(valid_775073, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_775073 != nil:
    section.add "Action", valid_775073
  var valid_775074 = query.getOrDefault("ResetAllParameters")
  valid_775074 = validateParameter(valid_775074, JBool, required = false, default = nil)
  if valid_775074 != nil:
    section.add "ResetAllParameters", valid_775074
  var valid_775075 = query.getOrDefault("Version")
  valid_775075 = validateParameter(valid_775075, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_775075 != nil:
    section.add "Version", valid_775075
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775076 = header.getOrDefault("X-Amz-Date")
  valid_775076 = validateParameter(valid_775076, JString, required = false,
                                 default = nil)
  if valid_775076 != nil:
    section.add "X-Amz-Date", valid_775076
  var valid_775077 = header.getOrDefault("X-Amz-Security-Token")
  valid_775077 = validateParameter(valid_775077, JString, required = false,
                                 default = nil)
  if valid_775077 != nil:
    section.add "X-Amz-Security-Token", valid_775077
  var valid_775078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775078 = validateParameter(valid_775078, JString, required = false,
                                 default = nil)
  if valid_775078 != nil:
    section.add "X-Amz-Content-Sha256", valid_775078
  var valid_775079 = header.getOrDefault("X-Amz-Algorithm")
  valid_775079 = validateParameter(valid_775079, JString, required = false,
                                 default = nil)
  if valid_775079 != nil:
    section.add "X-Amz-Algorithm", valid_775079
  var valid_775080 = header.getOrDefault("X-Amz-Signature")
  valid_775080 = validateParameter(valid_775080, JString, required = false,
                                 default = nil)
  if valid_775080 != nil:
    section.add "X-Amz-Signature", valid_775080
  var valid_775081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775081 = validateParameter(valid_775081, JString, required = false,
                                 default = nil)
  if valid_775081 != nil:
    section.add "X-Amz-SignedHeaders", valid_775081
  var valid_775082 = header.getOrDefault("X-Amz-Credential")
  valid_775082 = validateParameter(valid_775082, JString, required = false,
                                 default = nil)
  if valid_775082 != nil:
    section.add "X-Amz-Credential", valid_775082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775083: Call_GetResetDBParameterGroup_775068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775083.validator(path, query, header, formData, body)
  let scheme = call_775083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775083.url(scheme.get, call_775083.host, call_775083.base,
                         call_775083.route, valid.getOrDefault("path"))
  result = hook(call_775083, url, valid)

proc call*(call_775084: Call_GetResetDBParameterGroup_775068;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-02-12"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_775085 = newJObject()
  add(query_775085, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_775085.add "Parameters", Parameters
  add(query_775085, "Action", newJString(Action))
  add(query_775085, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_775085, "Version", newJString(Version))
  result = call_775084.call(nil, query_775085, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_775068(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_775069, base: "/",
    url: url_GetResetDBParameterGroup_775070, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_775134 = ref object of OpenApiRestCall_772581
proc url_PostRestoreDBInstanceFromDBSnapshot_775136(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_775135(path: JsonNode;
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
  var valid_775137 = query.getOrDefault("Action")
  valid_775137 = validateParameter(valid_775137, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_775137 != nil:
    section.add "Action", valid_775137
  var valid_775138 = query.getOrDefault("Version")
  valid_775138 = validateParameter(valid_775138, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_775138 != nil:
    section.add "Version", valid_775138
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775139 = header.getOrDefault("X-Amz-Date")
  valid_775139 = validateParameter(valid_775139, JString, required = false,
                                 default = nil)
  if valid_775139 != nil:
    section.add "X-Amz-Date", valid_775139
  var valid_775140 = header.getOrDefault("X-Amz-Security-Token")
  valid_775140 = validateParameter(valid_775140, JString, required = false,
                                 default = nil)
  if valid_775140 != nil:
    section.add "X-Amz-Security-Token", valid_775140
  var valid_775141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775141 = validateParameter(valid_775141, JString, required = false,
                                 default = nil)
  if valid_775141 != nil:
    section.add "X-Amz-Content-Sha256", valid_775141
  var valid_775142 = header.getOrDefault("X-Amz-Algorithm")
  valid_775142 = validateParameter(valid_775142, JString, required = false,
                                 default = nil)
  if valid_775142 != nil:
    section.add "X-Amz-Algorithm", valid_775142
  var valid_775143 = header.getOrDefault("X-Amz-Signature")
  valid_775143 = validateParameter(valid_775143, JString, required = false,
                                 default = nil)
  if valid_775143 != nil:
    section.add "X-Amz-Signature", valid_775143
  var valid_775144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775144 = validateParameter(valid_775144, JString, required = false,
                                 default = nil)
  if valid_775144 != nil:
    section.add "X-Amz-SignedHeaders", valid_775144
  var valid_775145 = header.getOrDefault("X-Amz-Credential")
  valid_775145 = validateParameter(valid_775145, JString, required = false,
                                 default = nil)
  if valid_775145 != nil:
    section.add "X-Amz-Credential", valid_775145
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
  var valid_775146 = formData.getOrDefault("Port")
  valid_775146 = validateParameter(valid_775146, JInt, required = false, default = nil)
  if valid_775146 != nil:
    section.add "Port", valid_775146
  var valid_775147 = formData.getOrDefault("Engine")
  valid_775147 = validateParameter(valid_775147, JString, required = false,
                                 default = nil)
  if valid_775147 != nil:
    section.add "Engine", valid_775147
  var valid_775148 = formData.getOrDefault("Iops")
  valid_775148 = validateParameter(valid_775148, JInt, required = false, default = nil)
  if valid_775148 != nil:
    section.add "Iops", valid_775148
  var valid_775149 = formData.getOrDefault("DBName")
  valid_775149 = validateParameter(valid_775149, JString, required = false,
                                 default = nil)
  if valid_775149 != nil:
    section.add "DBName", valid_775149
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_775150 = formData.getOrDefault("DBInstanceIdentifier")
  valid_775150 = validateParameter(valid_775150, JString, required = true,
                                 default = nil)
  if valid_775150 != nil:
    section.add "DBInstanceIdentifier", valid_775150
  var valid_775151 = formData.getOrDefault("OptionGroupName")
  valid_775151 = validateParameter(valid_775151, JString, required = false,
                                 default = nil)
  if valid_775151 != nil:
    section.add "OptionGroupName", valid_775151
  var valid_775152 = formData.getOrDefault("DBSubnetGroupName")
  valid_775152 = validateParameter(valid_775152, JString, required = false,
                                 default = nil)
  if valid_775152 != nil:
    section.add "DBSubnetGroupName", valid_775152
  var valid_775153 = formData.getOrDefault("AvailabilityZone")
  valid_775153 = validateParameter(valid_775153, JString, required = false,
                                 default = nil)
  if valid_775153 != nil:
    section.add "AvailabilityZone", valid_775153
  var valid_775154 = formData.getOrDefault("MultiAZ")
  valid_775154 = validateParameter(valid_775154, JBool, required = false, default = nil)
  if valid_775154 != nil:
    section.add "MultiAZ", valid_775154
  var valid_775155 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_775155 = validateParameter(valid_775155, JString, required = true,
                                 default = nil)
  if valid_775155 != nil:
    section.add "DBSnapshotIdentifier", valid_775155
  var valid_775156 = formData.getOrDefault("PubliclyAccessible")
  valid_775156 = validateParameter(valid_775156, JBool, required = false, default = nil)
  if valid_775156 != nil:
    section.add "PubliclyAccessible", valid_775156
  var valid_775157 = formData.getOrDefault("DBInstanceClass")
  valid_775157 = validateParameter(valid_775157, JString, required = false,
                                 default = nil)
  if valid_775157 != nil:
    section.add "DBInstanceClass", valid_775157
  var valid_775158 = formData.getOrDefault("LicenseModel")
  valid_775158 = validateParameter(valid_775158, JString, required = false,
                                 default = nil)
  if valid_775158 != nil:
    section.add "LicenseModel", valid_775158
  var valid_775159 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_775159 = validateParameter(valid_775159, JBool, required = false, default = nil)
  if valid_775159 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775159
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775160: Call_PostRestoreDBInstanceFromDBSnapshot_775134;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775160.validator(path, query, header, formData, body)
  let scheme = call_775160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775160.url(scheme.get, call_775160.host, call_775160.base,
                         call_775160.route, valid.getOrDefault("path"))
  result = hook(call_775160, url, valid)

proc call*(call_775161: Call_PostRestoreDBInstanceFromDBSnapshot_775134;
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
  var query_775162 = newJObject()
  var formData_775163 = newJObject()
  add(formData_775163, "Port", newJInt(Port))
  add(formData_775163, "Engine", newJString(Engine))
  add(formData_775163, "Iops", newJInt(Iops))
  add(formData_775163, "DBName", newJString(DBName))
  add(formData_775163, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_775163, "OptionGroupName", newJString(OptionGroupName))
  add(formData_775163, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_775163, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_775163, "MultiAZ", newJBool(MultiAZ))
  add(formData_775163, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_775162, "Action", newJString(Action))
  add(formData_775163, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_775163, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_775163, "LicenseModel", newJString(LicenseModel))
  add(formData_775163, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_775162, "Version", newJString(Version))
  result = call_775161.call(nil, query_775162, nil, formData_775163, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_775134(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_775135, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_775136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_775105 = ref object of OpenApiRestCall_772581
proc url_GetRestoreDBInstanceFromDBSnapshot_775107(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_775106(path: JsonNode;
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
  var valid_775108 = query.getOrDefault("Engine")
  valid_775108 = validateParameter(valid_775108, JString, required = false,
                                 default = nil)
  if valid_775108 != nil:
    section.add "Engine", valid_775108
  var valid_775109 = query.getOrDefault("OptionGroupName")
  valid_775109 = validateParameter(valid_775109, JString, required = false,
                                 default = nil)
  if valid_775109 != nil:
    section.add "OptionGroupName", valid_775109
  var valid_775110 = query.getOrDefault("AvailabilityZone")
  valid_775110 = validateParameter(valid_775110, JString, required = false,
                                 default = nil)
  if valid_775110 != nil:
    section.add "AvailabilityZone", valid_775110
  var valid_775111 = query.getOrDefault("Iops")
  valid_775111 = validateParameter(valid_775111, JInt, required = false, default = nil)
  if valid_775111 != nil:
    section.add "Iops", valid_775111
  var valid_775112 = query.getOrDefault("MultiAZ")
  valid_775112 = validateParameter(valid_775112, JBool, required = false, default = nil)
  if valid_775112 != nil:
    section.add "MultiAZ", valid_775112
  var valid_775113 = query.getOrDefault("LicenseModel")
  valid_775113 = validateParameter(valid_775113, JString, required = false,
                                 default = nil)
  if valid_775113 != nil:
    section.add "LicenseModel", valid_775113
  var valid_775114 = query.getOrDefault("DBName")
  valid_775114 = validateParameter(valid_775114, JString, required = false,
                                 default = nil)
  if valid_775114 != nil:
    section.add "DBName", valid_775114
  var valid_775115 = query.getOrDefault("DBInstanceClass")
  valid_775115 = validateParameter(valid_775115, JString, required = false,
                                 default = nil)
  if valid_775115 != nil:
    section.add "DBInstanceClass", valid_775115
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775116 = query.getOrDefault("Action")
  valid_775116 = validateParameter(valid_775116, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_775116 != nil:
    section.add "Action", valid_775116
  var valid_775117 = query.getOrDefault("DBSubnetGroupName")
  valid_775117 = validateParameter(valid_775117, JString, required = false,
                                 default = nil)
  if valid_775117 != nil:
    section.add "DBSubnetGroupName", valid_775117
  var valid_775118 = query.getOrDefault("PubliclyAccessible")
  valid_775118 = validateParameter(valid_775118, JBool, required = false, default = nil)
  if valid_775118 != nil:
    section.add "PubliclyAccessible", valid_775118
  var valid_775119 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_775119 = validateParameter(valid_775119, JBool, required = false, default = nil)
  if valid_775119 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775119
  var valid_775120 = query.getOrDefault("Port")
  valid_775120 = validateParameter(valid_775120, JInt, required = false, default = nil)
  if valid_775120 != nil:
    section.add "Port", valid_775120
  var valid_775121 = query.getOrDefault("Version")
  valid_775121 = validateParameter(valid_775121, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_775121 != nil:
    section.add "Version", valid_775121
  var valid_775122 = query.getOrDefault("DBInstanceIdentifier")
  valid_775122 = validateParameter(valid_775122, JString, required = true,
                                 default = nil)
  if valid_775122 != nil:
    section.add "DBInstanceIdentifier", valid_775122
  var valid_775123 = query.getOrDefault("DBSnapshotIdentifier")
  valid_775123 = validateParameter(valid_775123, JString, required = true,
                                 default = nil)
  if valid_775123 != nil:
    section.add "DBSnapshotIdentifier", valid_775123
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775124 = header.getOrDefault("X-Amz-Date")
  valid_775124 = validateParameter(valid_775124, JString, required = false,
                                 default = nil)
  if valid_775124 != nil:
    section.add "X-Amz-Date", valid_775124
  var valid_775125 = header.getOrDefault("X-Amz-Security-Token")
  valid_775125 = validateParameter(valid_775125, JString, required = false,
                                 default = nil)
  if valid_775125 != nil:
    section.add "X-Amz-Security-Token", valid_775125
  var valid_775126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775126 = validateParameter(valid_775126, JString, required = false,
                                 default = nil)
  if valid_775126 != nil:
    section.add "X-Amz-Content-Sha256", valid_775126
  var valid_775127 = header.getOrDefault("X-Amz-Algorithm")
  valid_775127 = validateParameter(valid_775127, JString, required = false,
                                 default = nil)
  if valid_775127 != nil:
    section.add "X-Amz-Algorithm", valid_775127
  var valid_775128 = header.getOrDefault("X-Amz-Signature")
  valid_775128 = validateParameter(valid_775128, JString, required = false,
                                 default = nil)
  if valid_775128 != nil:
    section.add "X-Amz-Signature", valid_775128
  var valid_775129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775129 = validateParameter(valid_775129, JString, required = false,
                                 default = nil)
  if valid_775129 != nil:
    section.add "X-Amz-SignedHeaders", valid_775129
  var valid_775130 = header.getOrDefault("X-Amz-Credential")
  valid_775130 = validateParameter(valid_775130, JString, required = false,
                                 default = nil)
  if valid_775130 != nil:
    section.add "X-Amz-Credential", valid_775130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775131: Call_GetRestoreDBInstanceFromDBSnapshot_775105;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775131.validator(path, query, header, formData, body)
  let scheme = call_775131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775131.url(scheme.get, call_775131.host, call_775131.base,
                         call_775131.route, valid.getOrDefault("path"))
  result = hook(call_775131, url, valid)

proc call*(call_775132: Call_GetRestoreDBInstanceFromDBSnapshot_775105;
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
  var query_775133 = newJObject()
  add(query_775133, "Engine", newJString(Engine))
  add(query_775133, "OptionGroupName", newJString(OptionGroupName))
  add(query_775133, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_775133, "Iops", newJInt(Iops))
  add(query_775133, "MultiAZ", newJBool(MultiAZ))
  add(query_775133, "LicenseModel", newJString(LicenseModel))
  add(query_775133, "DBName", newJString(DBName))
  add(query_775133, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_775133, "Action", newJString(Action))
  add(query_775133, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_775133, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_775133, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_775133, "Port", newJInt(Port))
  add(query_775133, "Version", newJString(Version))
  add(query_775133, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_775133, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_775132.call(nil, query_775133, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_775105(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_775106, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_775107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_775195 = ref object of OpenApiRestCall_772581
proc url_PostRestoreDBInstanceToPointInTime_775197(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceToPointInTime_775196(path: JsonNode;
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
  var valid_775198 = query.getOrDefault("Action")
  valid_775198 = validateParameter(valid_775198, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_775198 != nil:
    section.add "Action", valid_775198
  var valid_775199 = query.getOrDefault("Version")
  valid_775199 = validateParameter(valid_775199, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_775199 != nil:
    section.add "Version", valid_775199
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775200 = header.getOrDefault("X-Amz-Date")
  valid_775200 = validateParameter(valid_775200, JString, required = false,
                                 default = nil)
  if valid_775200 != nil:
    section.add "X-Amz-Date", valid_775200
  var valid_775201 = header.getOrDefault("X-Amz-Security-Token")
  valid_775201 = validateParameter(valid_775201, JString, required = false,
                                 default = nil)
  if valid_775201 != nil:
    section.add "X-Amz-Security-Token", valid_775201
  var valid_775202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775202 = validateParameter(valid_775202, JString, required = false,
                                 default = nil)
  if valid_775202 != nil:
    section.add "X-Amz-Content-Sha256", valid_775202
  var valid_775203 = header.getOrDefault("X-Amz-Algorithm")
  valid_775203 = validateParameter(valid_775203, JString, required = false,
                                 default = nil)
  if valid_775203 != nil:
    section.add "X-Amz-Algorithm", valid_775203
  var valid_775204 = header.getOrDefault("X-Amz-Signature")
  valid_775204 = validateParameter(valid_775204, JString, required = false,
                                 default = nil)
  if valid_775204 != nil:
    section.add "X-Amz-Signature", valid_775204
  var valid_775205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775205 = validateParameter(valid_775205, JString, required = false,
                                 default = nil)
  if valid_775205 != nil:
    section.add "X-Amz-SignedHeaders", valid_775205
  var valid_775206 = header.getOrDefault("X-Amz-Credential")
  valid_775206 = validateParameter(valid_775206, JString, required = false,
                                 default = nil)
  if valid_775206 != nil:
    section.add "X-Amz-Credential", valid_775206
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
  var valid_775207 = formData.getOrDefault("UseLatestRestorableTime")
  valid_775207 = validateParameter(valid_775207, JBool, required = false, default = nil)
  if valid_775207 != nil:
    section.add "UseLatestRestorableTime", valid_775207
  var valid_775208 = formData.getOrDefault("Port")
  valid_775208 = validateParameter(valid_775208, JInt, required = false, default = nil)
  if valid_775208 != nil:
    section.add "Port", valid_775208
  var valid_775209 = formData.getOrDefault("Engine")
  valid_775209 = validateParameter(valid_775209, JString, required = false,
                                 default = nil)
  if valid_775209 != nil:
    section.add "Engine", valid_775209
  var valid_775210 = formData.getOrDefault("Iops")
  valid_775210 = validateParameter(valid_775210, JInt, required = false, default = nil)
  if valid_775210 != nil:
    section.add "Iops", valid_775210
  var valid_775211 = formData.getOrDefault("DBName")
  valid_775211 = validateParameter(valid_775211, JString, required = false,
                                 default = nil)
  if valid_775211 != nil:
    section.add "DBName", valid_775211
  var valid_775212 = formData.getOrDefault("OptionGroupName")
  valid_775212 = validateParameter(valid_775212, JString, required = false,
                                 default = nil)
  if valid_775212 != nil:
    section.add "OptionGroupName", valid_775212
  var valid_775213 = formData.getOrDefault("DBSubnetGroupName")
  valid_775213 = validateParameter(valid_775213, JString, required = false,
                                 default = nil)
  if valid_775213 != nil:
    section.add "DBSubnetGroupName", valid_775213
  var valid_775214 = formData.getOrDefault("AvailabilityZone")
  valid_775214 = validateParameter(valid_775214, JString, required = false,
                                 default = nil)
  if valid_775214 != nil:
    section.add "AvailabilityZone", valid_775214
  var valid_775215 = formData.getOrDefault("MultiAZ")
  valid_775215 = validateParameter(valid_775215, JBool, required = false, default = nil)
  if valid_775215 != nil:
    section.add "MultiAZ", valid_775215
  var valid_775216 = formData.getOrDefault("RestoreTime")
  valid_775216 = validateParameter(valid_775216, JString, required = false,
                                 default = nil)
  if valid_775216 != nil:
    section.add "RestoreTime", valid_775216
  var valid_775217 = formData.getOrDefault("PubliclyAccessible")
  valid_775217 = validateParameter(valid_775217, JBool, required = false, default = nil)
  if valid_775217 != nil:
    section.add "PubliclyAccessible", valid_775217
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_775218 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_775218 = validateParameter(valid_775218, JString, required = true,
                                 default = nil)
  if valid_775218 != nil:
    section.add "TargetDBInstanceIdentifier", valid_775218
  var valid_775219 = formData.getOrDefault("DBInstanceClass")
  valid_775219 = validateParameter(valid_775219, JString, required = false,
                                 default = nil)
  if valid_775219 != nil:
    section.add "DBInstanceClass", valid_775219
  var valid_775220 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_775220 = validateParameter(valid_775220, JString, required = true,
                                 default = nil)
  if valid_775220 != nil:
    section.add "SourceDBInstanceIdentifier", valid_775220
  var valid_775221 = formData.getOrDefault("LicenseModel")
  valid_775221 = validateParameter(valid_775221, JString, required = false,
                                 default = nil)
  if valid_775221 != nil:
    section.add "LicenseModel", valid_775221
  var valid_775222 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_775222 = validateParameter(valid_775222, JBool, required = false, default = nil)
  if valid_775222 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775222
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775223: Call_PostRestoreDBInstanceToPointInTime_775195;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775223.validator(path, query, header, formData, body)
  let scheme = call_775223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775223.url(scheme.get, call_775223.host, call_775223.base,
                         call_775223.route, valid.getOrDefault("path"))
  result = hook(call_775223, url, valid)

proc call*(call_775224: Call_PostRestoreDBInstanceToPointInTime_775195;
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
  var query_775225 = newJObject()
  var formData_775226 = newJObject()
  add(formData_775226, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_775226, "Port", newJInt(Port))
  add(formData_775226, "Engine", newJString(Engine))
  add(formData_775226, "Iops", newJInt(Iops))
  add(formData_775226, "DBName", newJString(DBName))
  add(formData_775226, "OptionGroupName", newJString(OptionGroupName))
  add(formData_775226, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_775226, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_775226, "MultiAZ", newJBool(MultiAZ))
  add(query_775225, "Action", newJString(Action))
  add(formData_775226, "RestoreTime", newJString(RestoreTime))
  add(formData_775226, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_775226, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_775226, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_775226, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_775226, "LicenseModel", newJString(LicenseModel))
  add(formData_775226, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_775225, "Version", newJString(Version))
  result = call_775224.call(nil, query_775225, nil, formData_775226, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_775195(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_775196, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_775197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_775164 = ref object of OpenApiRestCall_772581
proc url_GetRestoreDBInstanceToPointInTime_775166(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceToPointInTime_775165(path: JsonNode;
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
  var valid_775167 = query.getOrDefault("Engine")
  valid_775167 = validateParameter(valid_775167, JString, required = false,
                                 default = nil)
  if valid_775167 != nil:
    section.add "Engine", valid_775167
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_775168 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_775168 = validateParameter(valid_775168, JString, required = true,
                                 default = nil)
  if valid_775168 != nil:
    section.add "SourceDBInstanceIdentifier", valid_775168
  var valid_775169 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_775169 = validateParameter(valid_775169, JString, required = true,
                                 default = nil)
  if valid_775169 != nil:
    section.add "TargetDBInstanceIdentifier", valid_775169
  var valid_775170 = query.getOrDefault("AvailabilityZone")
  valid_775170 = validateParameter(valid_775170, JString, required = false,
                                 default = nil)
  if valid_775170 != nil:
    section.add "AvailabilityZone", valid_775170
  var valid_775171 = query.getOrDefault("Iops")
  valid_775171 = validateParameter(valid_775171, JInt, required = false, default = nil)
  if valid_775171 != nil:
    section.add "Iops", valid_775171
  var valid_775172 = query.getOrDefault("OptionGroupName")
  valid_775172 = validateParameter(valid_775172, JString, required = false,
                                 default = nil)
  if valid_775172 != nil:
    section.add "OptionGroupName", valid_775172
  var valid_775173 = query.getOrDefault("RestoreTime")
  valid_775173 = validateParameter(valid_775173, JString, required = false,
                                 default = nil)
  if valid_775173 != nil:
    section.add "RestoreTime", valid_775173
  var valid_775174 = query.getOrDefault("MultiAZ")
  valid_775174 = validateParameter(valid_775174, JBool, required = false, default = nil)
  if valid_775174 != nil:
    section.add "MultiAZ", valid_775174
  var valid_775175 = query.getOrDefault("LicenseModel")
  valid_775175 = validateParameter(valid_775175, JString, required = false,
                                 default = nil)
  if valid_775175 != nil:
    section.add "LicenseModel", valid_775175
  var valid_775176 = query.getOrDefault("DBName")
  valid_775176 = validateParameter(valid_775176, JString, required = false,
                                 default = nil)
  if valid_775176 != nil:
    section.add "DBName", valid_775176
  var valid_775177 = query.getOrDefault("DBInstanceClass")
  valid_775177 = validateParameter(valid_775177, JString, required = false,
                                 default = nil)
  if valid_775177 != nil:
    section.add "DBInstanceClass", valid_775177
  var valid_775178 = query.getOrDefault("Action")
  valid_775178 = validateParameter(valid_775178, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_775178 != nil:
    section.add "Action", valid_775178
  var valid_775179 = query.getOrDefault("UseLatestRestorableTime")
  valid_775179 = validateParameter(valid_775179, JBool, required = false, default = nil)
  if valid_775179 != nil:
    section.add "UseLatestRestorableTime", valid_775179
  var valid_775180 = query.getOrDefault("DBSubnetGroupName")
  valid_775180 = validateParameter(valid_775180, JString, required = false,
                                 default = nil)
  if valid_775180 != nil:
    section.add "DBSubnetGroupName", valid_775180
  var valid_775181 = query.getOrDefault("PubliclyAccessible")
  valid_775181 = validateParameter(valid_775181, JBool, required = false, default = nil)
  if valid_775181 != nil:
    section.add "PubliclyAccessible", valid_775181
  var valid_775182 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_775182 = validateParameter(valid_775182, JBool, required = false, default = nil)
  if valid_775182 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775182
  var valid_775183 = query.getOrDefault("Port")
  valid_775183 = validateParameter(valid_775183, JInt, required = false, default = nil)
  if valid_775183 != nil:
    section.add "Port", valid_775183
  var valid_775184 = query.getOrDefault("Version")
  valid_775184 = validateParameter(valid_775184, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_775184 != nil:
    section.add "Version", valid_775184
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775185 = header.getOrDefault("X-Amz-Date")
  valid_775185 = validateParameter(valid_775185, JString, required = false,
                                 default = nil)
  if valid_775185 != nil:
    section.add "X-Amz-Date", valid_775185
  var valid_775186 = header.getOrDefault("X-Amz-Security-Token")
  valid_775186 = validateParameter(valid_775186, JString, required = false,
                                 default = nil)
  if valid_775186 != nil:
    section.add "X-Amz-Security-Token", valid_775186
  var valid_775187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775187 = validateParameter(valid_775187, JString, required = false,
                                 default = nil)
  if valid_775187 != nil:
    section.add "X-Amz-Content-Sha256", valid_775187
  var valid_775188 = header.getOrDefault("X-Amz-Algorithm")
  valid_775188 = validateParameter(valid_775188, JString, required = false,
                                 default = nil)
  if valid_775188 != nil:
    section.add "X-Amz-Algorithm", valid_775188
  var valid_775189 = header.getOrDefault("X-Amz-Signature")
  valid_775189 = validateParameter(valid_775189, JString, required = false,
                                 default = nil)
  if valid_775189 != nil:
    section.add "X-Amz-Signature", valid_775189
  var valid_775190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775190 = validateParameter(valid_775190, JString, required = false,
                                 default = nil)
  if valid_775190 != nil:
    section.add "X-Amz-SignedHeaders", valid_775190
  var valid_775191 = header.getOrDefault("X-Amz-Credential")
  valid_775191 = validateParameter(valid_775191, JString, required = false,
                                 default = nil)
  if valid_775191 != nil:
    section.add "X-Amz-Credential", valid_775191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775192: Call_GetRestoreDBInstanceToPointInTime_775164;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775192.validator(path, query, header, formData, body)
  let scheme = call_775192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775192.url(scheme.get, call_775192.host, call_775192.base,
                         call_775192.route, valid.getOrDefault("path"))
  result = hook(call_775192, url, valid)

proc call*(call_775193: Call_GetRestoreDBInstanceToPointInTime_775164;
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
  var query_775194 = newJObject()
  add(query_775194, "Engine", newJString(Engine))
  add(query_775194, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_775194, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_775194, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_775194, "Iops", newJInt(Iops))
  add(query_775194, "OptionGroupName", newJString(OptionGroupName))
  add(query_775194, "RestoreTime", newJString(RestoreTime))
  add(query_775194, "MultiAZ", newJBool(MultiAZ))
  add(query_775194, "LicenseModel", newJString(LicenseModel))
  add(query_775194, "DBName", newJString(DBName))
  add(query_775194, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_775194, "Action", newJString(Action))
  add(query_775194, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_775194, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_775194, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_775194, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_775194, "Port", newJInt(Port))
  add(query_775194, "Version", newJString(Version))
  result = call_775193.call(nil, query_775194, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_775164(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_775165, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_775166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_775247 = ref object of OpenApiRestCall_772581
proc url_PostRevokeDBSecurityGroupIngress_775249(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRevokeDBSecurityGroupIngress_775248(path: JsonNode;
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
  var valid_775250 = query.getOrDefault("Action")
  valid_775250 = validateParameter(valid_775250, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_775250 != nil:
    section.add "Action", valid_775250
  var valid_775251 = query.getOrDefault("Version")
  valid_775251 = validateParameter(valid_775251, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_775251 != nil:
    section.add "Version", valid_775251
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775252 = header.getOrDefault("X-Amz-Date")
  valid_775252 = validateParameter(valid_775252, JString, required = false,
                                 default = nil)
  if valid_775252 != nil:
    section.add "X-Amz-Date", valid_775252
  var valid_775253 = header.getOrDefault("X-Amz-Security-Token")
  valid_775253 = validateParameter(valid_775253, JString, required = false,
                                 default = nil)
  if valid_775253 != nil:
    section.add "X-Amz-Security-Token", valid_775253
  var valid_775254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775254 = validateParameter(valid_775254, JString, required = false,
                                 default = nil)
  if valid_775254 != nil:
    section.add "X-Amz-Content-Sha256", valid_775254
  var valid_775255 = header.getOrDefault("X-Amz-Algorithm")
  valid_775255 = validateParameter(valid_775255, JString, required = false,
                                 default = nil)
  if valid_775255 != nil:
    section.add "X-Amz-Algorithm", valid_775255
  var valid_775256 = header.getOrDefault("X-Amz-Signature")
  valid_775256 = validateParameter(valid_775256, JString, required = false,
                                 default = nil)
  if valid_775256 != nil:
    section.add "X-Amz-Signature", valid_775256
  var valid_775257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775257 = validateParameter(valid_775257, JString, required = false,
                                 default = nil)
  if valid_775257 != nil:
    section.add "X-Amz-SignedHeaders", valid_775257
  var valid_775258 = header.getOrDefault("X-Amz-Credential")
  valid_775258 = validateParameter(valid_775258, JString, required = false,
                                 default = nil)
  if valid_775258 != nil:
    section.add "X-Amz-Credential", valid_775258
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_775259 = formData.getOrDefault("DBSecurityGroupName")
  valid_775259 = validateParameter(valid_775259, JString, required = true,
                                 default = nil)
  if valid_775259 != nil:
    section.add "DBSecurityGroupName", valid_775259
  var valid_775260 = formData.getOrDefault("EC2SecurityGroupName")
  valid_775260 = validateParameter(valid_775260, JString, required = false,
                                 default = nil)
  if valid_775260 != nil:
    section.add "EC2SecurityGroupName", valid_775260
  var valid_775261 = formData.getOrDefault("EC2SecurityGroupId")
  valid_775261 = validateParameter(valid_775261, JString, required = false,
                                 default = nil)
  if valid_775261 != nil:
    section.add "EC2SecurityGroupId", valid_775261
  var valid_775262 = formData.getOrDefault("CIDRIP")
  valid_775262 = validateParameter(valid_775262, JString, required = false,
                                 default = nil)
  if valid_775262 != nil:
    section.add "CIDRIP", valid_775262
  var valid_775263 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_775263 = validateParameter(valid_775263, JString, required = false,
                                 default = nil)
  if valid_775263 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_775263
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775264: Call_PostRevokeDBSecurityGroupIngress_775247;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775264.validator(path, query, header, formData, body)
  let scheme = call_775264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775264.url(scheme.get, call_775264.host, call_775264.base,
                         call_775264.route, valid.getOrDefault("path"))
  result = hook(call_775264, url, valid)

proc call*(call_775265: Call_PostRevokeDBSecurityGroupIngress_775247;
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
  var query_775266 = newJObject()
  var formData_775267 = newJObject()
  add(formData_775267, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_775266, "Action", newJString(Action))
  add(formData_775267, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_775267, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_775267, "CIDRIP", newJString(CIDRIP))
  add(query_775266, "Version", newJString(Version))
  add(formData_775267, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_775265.call(nil, query_775266, nil, formData_775267, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_775247(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_775248, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_775249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_775227 = ref object of OpenApiRestCall_772581
proc url_GetRevokeDBSecurityGroupIngress_775229(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRevokeDBSecurityGroupIngress_775228(path: JsonNode;
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
  var valid_775230 = query.getOrDefault("EC2SecurityGroupId")
  valid_775230 = validateParameter(valid_775230, JString, required = false,
                                 default = nil)
  if valid_775230 != nil:
    section.add "EC2SecurityGroupId", valid_775230
  var valid_775231 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_775231 = validateParameter(valid_775231, JString, required = false,
                                 default = nil)
  if valid_775231 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_775231
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_775232 = query.getOrDefault("DBSecurityGroupName")
  valid_775232 = validateParameter(valid_775232, JString, required = true,
                                 default = nil)
  if valid_775232 != nil:
    section.add "DBSecurityGroupName", valid_775232
  var valid_775233 = query.getOrDefault("Action")
  valid_775233 = validateParameter(valid_775233, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_775233 != nil:
    section.add "Action", valid_775233
  var valid_775234 = query.getOrDefault("CIDRIP")
  valid_775234 = validateParameter(valid_775234, JString, required = false,
                                 default = nil)
  if valid_775234 != nil:
    section.add "CIDRIP", valid_775234
  var valid_775235 = query.getOrDefault("EC2SecurityGroupName")
  valid_775235 = validateParameter(valid_775235, JString, required = false,
                                 default = nil)
  if valid_775235 != nil:
    section.add "EC2SecurityGroupName", valid_775235
  var valid_775236 = query.getOrDefault("Version")
  valid_775236 = validateParameter(valid_775236, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_775236 != nil:
    section.add "Version", valid_775236
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775237 = header.getOrDefault("X-Amz-Date")
  valid_775237 = validateParameter(valid_775237, JString, required = false,
                                 default = nil)
  if valid_775237 != nil:
    section.add "X-Amz-Date", valid_775237
  var valid_775238 = header.getOrDefault("X-Amz-Security-Token")
  valid_775238 = validateParameter(valid_775238, JString, required = false,
                                 default = nil)
  if valid_775238 != nil:
    section.add "X-Amz-Security-Token", valid_775238
  var valid_775239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775239 = validateParameter(valid_775239, JString, required = false,
                                 default = nil)
  if valid_775239 != nil:
    section.add "X-Amz-Content-Sha256", valid_775239
  var valid_775240 = header.getOrDefault("X-Amz-Algorithm")
  valid_775240 = validateParameter(valid_775240, JString, required = false,
                                 default = nil)
  if valid_775240 != nil:
    section.add "X-Amz-Algorithm", valid_775240
  var valid_775241 = header.getOrDefault("X-Amz-Signature")
  valid_775241 = validateParameter(valid_775241, JString, required = false,
                                 default = nil)
  if valid_775241 != nil:
    section.add "X-Amz-Signature", valid_775241
  var valid_775242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775242 = validateParameter(valid_775242, JString, required = false,
                                 default = nil)
  if valid_775242 != nil:
    section.add "X-Amz-SignedHeaders", valid_775242
  var valid_775243 = header.getOrDefault("X-Amz-Credential")
  valid_775243 = validateParameter(valid_775243, JString, required = false,
                                 default = nil)
  if valid_775243 != nil:
    section.add "X-Amz-Credential", valid_775243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775244: Call_GetRevokeDBSecurityGroupIngress_775227;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775244.validator(path, query, header, formData, body)
  let scheme = call_775244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775244.url(scheme.get, call_775244.host, call_775244.base,
                         call_775244.route, valid.getOrDefault("path"))
  result = hook(call_775244, url, valid)

proc call*(call_775245: Call_GetRevokeDBSecurityGroupIngress_775227;
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
  var query_775246 = newJObject()
  add(query_775246, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_775246, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_775246, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_775246, "Action", newJString(Action))
  add(query_775246, "CIDRIP", newJString(CIDRIP))
  add(query_775246, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_775246, "Version", newJString(Version))
  result = call_775245.call(nil, query_775246, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_775227(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_775228, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_775229,
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
