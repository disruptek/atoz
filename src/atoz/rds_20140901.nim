
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
                                 default = newJString("2014-09-01"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2014-09-01"): Recallable =
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
  Call_PostCopyDBParameterGroup_773302 = ref object of OpenApiRestCall_772581
proc url_PostCopyDBParameterGroup_773304(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBParameterGroup_773303(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773305 = query.getOrDefault("Action")
  valid_773305 = validateParameter(valid_773305, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_773305 != nil:
    section.add "Action", valid_773305
  var valid_773306 = query.getOrDefault("Version")
  valid_773306 = validateParameter(valid_773306, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773306 != nil:
    section.add "Version", valid_773306
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773307 = header.getOrDefault("X-Amz-Date")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Date", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-Security-Token")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-Security-Token", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Content-Sha256", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-Algorithm")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Algorithm", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Signature")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Signature", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-SignedHeaders", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Credential")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Credential", valid_773313
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   SourceDBParameterGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBParameterGroupIdentifier` field"
  var valid_773314 = formData.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_773314 = validateParameter(valid_773314, JString, required = true,
                                 default = nil)
  if valid_773314 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_773314
  var valid_773315 = formData.getOrDefault("Tags")
  valid_773315 = validateParameter(valid_773315, JArray, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "Tags", valid_773315
  var valid_773316 = formData.getOrDefault("TargetDBParameterGroupDescription")
  valid_773316 = validateParameter(valid_773316, JString, required = true,
                                 default = nil)
  if valid_773316 != nil:
    section.add "TargetDBParameterGroupDescription", valid_773316
  var valid_773317 = formData.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_773317 = validateParameter(valid_773317, JString, required = true,
                                 default = nil)
  if valid_773317 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_773317
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773318: Call_PostCopyDBParameterGroup_773302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773318.validator(path, query, header, formData, body)
  let scheme = call_773318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773318.url(scheme.get, call_773318.host, call_773318.base,
                         call_773318.route, valid.getOrDefault("path"))
  result = hook(call_773318, url, valid)

proc call*(call_773319: Call_PostCopyDBParameterGroup_773302;
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
  var query_773320 = newJObject()
  var formData_773321 = newJObject()
  add(formData_773321, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  if Tags != nil:
    formData_773321.add "Tags", Tags
  add(query_773320, "Action", newJString(Action))
  add(formData_773321, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(formData_773321, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_773320, "Version", newJString(Version))
  result = call_773319.call(nil, query_773320, nil, formData_773321, nil)

var postCopyDBParameterGroup* = Call_PostCopyDBParameterGroup_773302(
    name: "postCopyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_PostCopyDBParameterGroup_773303, base: "/",
    url: url_PostCopyDBParameterGroup_773304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBParameterGroup_773283 = ref object of OpenApiRestCall_772581
proc url_GetCopyDBParameterGroup_773285(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBParameterGroup_773284(path: JsonNode; query: JsonNode;
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
  var valid_773286 = query.getOrDefault("Tags")
  valid_773286 = validateParameter(valid_773286, JArray, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "Tags", valid_773286
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773287 = query.getOrDefault("Action")
  valid_773287 = validateParameter(valid_773287, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_773287 != nil:
    section.add "Action", valid_773287
  var valid_773288 = query.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_773288 = validateParameter(valid_773288, JString, required = true,
                                 default = nil)
  if valid_773288 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_773288
  var valid_773289 = query.getOrDefault("Version")
  valid_773289 = validateParameter(valid_773289, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773289 != nil:
    section.add "Version", valid_773289
  var valid_773290 = query.getOrDefault("TargetDBParameterGroupDescription")
  valid_773290 = validateParameter(valid_773290, JString, required = true,
                                 default = nil)
  if valid_773290 != nil:
    section.add "TargetDBParameterGroupDescription", valid_773290
  var valid_773291 = query.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_773291 = validateParameter(valid_773291, JString, required = true,
                                 default = nil)
  if valid_773291 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_773291
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773292 = header.getOrDefault("X-Amz-Date")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Date", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Security-Token")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Security-Token", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-Content-Sha256", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Algorithm")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Algorithm", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Signature")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Signature", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-SignedHeaders", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Credential")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Credential", valid_773298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773299: Call_GetCopyDBParameterGroup_773283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773299.validator(path, query, header, formData, body)
  let scheme = call_773299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773299.url(scheme.get, call_773299.host, call_773299.base,
                         call_773299.route, valid.getOrDefault("path"))
  result = hook(call_773299, url, valid)

proc call*(call_773300: Call_GetCopyDBParameterGroup_773283;
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
  var query_773301 = newJObject()
  if Tags != nil:
    query_773301.add "Tags", Tags
  add(query_773301, "Action", newJString(Action))
  add(query_773301, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_773301, "Version", newJString(Version))
  add(query_773301, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_773301, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  result = call_773300.call(nil, query_773301, nil, nil, nil)

var getCopyDBParameterGroup* = Call_GetCopyDBParameterGroup_773283(
    name: "getCopyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_GetCopyDBParameterGroup_773284, base: "/",
    url: url_GetCopyDBParameterGroup_773285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_773340 = ref object of OpenApiRestCall_772581
proc url_PostCopyDBSnapshot_773342(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBSnapshot_773341(path: JsonNode; query: JsonNode;
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
  var valid_773343 = query.getOrDefault("Action")
  valid_773343 = validateParameter(valid_773343, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_773343 != nil:
    section.add "Action", valid_773343
  var valid_773344 = query.getOrDefault("Version")
  valid_773344 = validateParameter(valid_773344, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773344 != nil:
    section.add "Version", valid_773344
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773345 = header.getOrDefault("X-Amz-Date")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Date", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Security-Token")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Security-Token", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Content-Sha256", valid_773347
  var valid_773348 = header.getOrDefault("X-Amz-Algorithm")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-Algorithm", valid_773348
  var valid_773349 = header.getOrDefault("X-Amz-Signature")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-Signature", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-SignedHeaders", valid_773350
  var valid_773351 = header.getOrDefault("X-Amz-Credential")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-Credential", valid_773351
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_773352 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_773352 = validateParameter(valid_773352, JString, required = true,
                                 default = nil)
  if valid_773352 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_773352
  var valid_773353 = formData.getOrDefault("Tags")
  valid_773353 = validateParameter(valid_773353, JArray, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "Tags", valid_773353
  var valid_773354 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_773354 = validateParameter(valid_773354, JString, required = true,
                                 default = nil)
  if valid_773354 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_773354
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773355: Call_PostCopyDBSnapshot_773340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773355.validator(path, query, header, formData, body)
  let scheme = call_773355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773355.url(scheme.get, call_773355.host, call_773355.base,
                         call_773355.route, valid.getOrDefault("path"))
  result = hook(call_773355, url, valid)

proc call*(call_773356: Call_PostCopyDBSnapshot_773340;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_773357 = newJObject()
  var formData_773358 = newJObject()
  add(formData_773358, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_773358.add "Tags", Tags
  add(query_773357, "Action", newJString(Action))
  add(formData_773358, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_773357, "Version", newJString(Version))
  result = call_773356.call(nil, query_773357, nil, formData_773358, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_773340(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_773341, base: "/",
    url: url_PostCopyDBSnapshot_773342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_773322 = ref object of OpenApiRestCall_772581
proc url_GetCopyDBSnapshot_773324(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBSnapshot_773323(path: JsonNode; query: JsonNode;
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
  var valid_773325 = query.getOrDefault("Tags")
  valid_773325 = validateParameter(valid_773325, JArray, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "Tags", valid_773325
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_773326 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_773326 = validateParameter(valid_773326, JString, required = true,
                                 default = nil)
  if valid_773326 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_773326
  var valid_773327 = query.getOrDefault("Action")
  valid_773327 = validateParameter(valid_773327, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_773327 != nil:
    section.add "Action", valid_773327
  var valid_773328 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_773328 = validateParameter(valid_773328, JString, required = true,
                                 default = nil)
  if valid_773328 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_773328
  var valid_773329 = query.getOrDefault("Version")
  valid_773329 = validateParameter(valid_773329, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773329 != nil:
    section.add "Version", valid_773329
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773330 = header.getOrDefault("X-Amz-Date")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Date", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-Security-Token")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Security-Token", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Content-Sha256", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Algorithm")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Algorithm", valid_773333
  var valid_773334 = header.getOrDefault("X-Amz-Signature")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "X-Amz-Signature", valid_773334
  var valid_773335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-SignedHeaders", valid_773335
  var valid_773336 = header.getOrDefault("X-Amz-Credential")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "X-Amz-Credential", valid_773336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773337: Call_GetCopyDBSnapshot_773322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773337.validator(path, query, header, formData, body)
  let scheme = call_773337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773337.url(scheme.get, call_773337.host, call_773337.base,
                         call_773337.route, valid.getOrDefault("path"))
  result = hook(call_773337, url, valid)

proc call*(call_773338: Call_GetCopyDBSnapshot_773322;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_773339 = newJObject()
  if Tags != nil:
    query_773339.add "Tags", Tags
  add(query_773339, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_773339, "Action", newJString(Action))
  add(query_773339, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_773339, "Version", newJString(Version))
  result = call_773338.call(nil, query_773339, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_773322(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_773323,
    base: "/", url: url_GetCopyDBSnapshot_773324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyOptionGroup_773378 = ref object of OpenApiRestCall_772581
proc url_PostCopyOptionGroup_773380(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyOptionGroup_773379(path: JsonNode; query: JsonNode;
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
  var valid_773381 = query.getOrDefault("Action")
  valid_773381 = validateParameter(valid_773381, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_773381 != nil:
    section.add "Action", valid_773381
  var valid_773382 = query.getOrDefault("Version")
  valid_773382 = validateParameter(valid_773382, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773382 != nil:
    section.add "Version", valid_773382
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773383 = header.getOrDefault("X-Amz-Date")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Date", valid_773383
  var valid_773384 = header.getOrDefault("X-Amz-Security-Token")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "X-Amz-Security-Token", valid_773384
  var valid_773385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Content-Sha256", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Algorithm")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Algorithm", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-Signature")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Signature", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-SignedHeaders", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Credential")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Credential", valid_773389
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetOptionGroupDescription: JString (required)
  ##   Tags: JArray
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   TargetOptionGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetOptionGroupDescription` field"
  var valid_773390 = formData.getOrDefault("TargetOptionGroupDescription")
  valid_773390 = validateParameter(valid_773390, JString, required = true,
                                 default = nil)
  if valid_773390 != nil:
    section.add "TargetOptionGroupDescription", valid_773390
  var valid_773391 = formData.getOrDefault("Tags")
  valid_773391 = validateParameter(valid_773391, JArray, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "Tags", valid_773391
  var valid_773392 = formData.getOrDefault("SourceOptionGroupIdentifier")
  valid_773392 = validateParameter(valid_773392, JString, required = true,
                                 default = nil)
  if valid_773392 != nil:
    section.add "SourceOptionGroupIdentifier", valid_773392
  var valid_773393 = formData.getOrDefault("TargetOptionGroupIdentifier")
  valid_773393 = validateParameter(valid_773393, JString, required = true,
                                 default = nil)
  if valid_773393 != nil:
    section.add "TargetOptionGroupIdentifier", valid_773393
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773394: Call_PostCopyOptionGroup_773378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773394.validator(path, query, header, formData, body)
  let scheme = call_773394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773394.url(scheme.get, call_773394.host, call_773394.base,
                         call_773394.route, valid.getOrDefault("path"))
  result = hook(call_773394, url, valid)

proc call*(call_773395: Call_PostCopyOptionGroup_773378;
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
  var query_773396 = newJObject()
  var formData_773397 = newJObject()
  add(formData_773397, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  if Tags != nil:
    formData_773397.add "Tags", Tags
  add(formData_773397, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_773396, "Action", newJString(Action))
  add(formData_773397, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(query_773396, "Version", newJString(Version))
  result = call_773395.call(nil, query_773396, nil, formData_773397, nil)

var postCopyOptionGroup* = Call_PostCopyOptionGroup_773378(
    name: "postCopyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_PostCopyOptionGroup_773379, base: "/",
    url: url_PostCopyOptionGroup_773380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyOptionGroup_773359 = ref object of OpenApiRestCall_772581
proc url_GetCopyOptionGroup_773361(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyOptionGroup_773360(path: JsonNode; query: JsonNode;
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
  var valid_773362 = query.getOrDefault("SourceOptionGroupIdentifier")
  valid_773362 = validateParameter(valid_773362, JString, required = true,
                                 default = nil)
  if valid_773362 != nil:
    section.add "SourceOptionGroupIdentifier", valid_773362
  var valid_773363 = query.getOrDefault("Tags")
  valid_773363 = validateParameter(valid_773363, JArray, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "Tags", valid_773363
  var valid_773364 = query.getOrDefault("Action")
  valid_773364 = validateParameter(valid_773364, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_773364 != nil:
    section.add "Action", valid_773364
  var valid_773365 = query.getOrDefault("TargetOptionGroupDescription")
  valid_773365 = validateParameter(valid_773365, JString, required = true,
                                 default = nil)
  if valid_773365 != nil:
    section.add "TargetOptionGroupDescription", valid_773365
  var valid_773366 = query.getOrDefault("Version")
  valid_773366 = validateParameter(valid_773366, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773366 != nil:
    section.add "Version", valid_773366
  var valid_773367 = query.getOrDefault("TargetOptionGroupIdentifier")
  valid_773367 = validateParameter(valid_773367, JString, required = true,
                                 default = nil)
  if valid_773367 != nil:
    section.add "TargetOptionGroupIdentifier", valid_773367
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773368 = header.getOrDefault("X-Amz-Date")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Date", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-Security-Token")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Security-Token", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Content-Sha256", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Algorithm")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Algorithm", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Signature")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Signature", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-SignedHeaders", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Credential")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Credential", valid_773374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773375: Call_GetCopyOptionGroup_773359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773375.validator(path, query, header, formData, body)
  let scheme = call_773375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773375.url(scheme.get, call_773375.host, call_773375.base,
                         call_773375.route, valid.getOrDefault("path"))
  result = hook(call_773375, url, valid)

proc call*(call_773376: Call_GetCopyOptionGroup_773359;
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
  var query_773377 = newJObject()
  add(query_773377, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  if Tags != nil:
    query_773377.add "Tags", Tags
  add(query_773377, "Action", newJString(Action))
  add(query_773377, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(query_773377, "Version", newJString(Version))
  add(query_773377, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  result = call_773376.call(nil, query_773377, nil, nil, nil)

var getCopyOptionGroup* = Call_GetCopyOptionGroup_773359(
    name: "getCopyOptionGroup", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyOptionGroup", validator: validate_GetCopyOptionGroup_773360,
    base: "/", url: url_GetCopyOptionGroup_773361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_773441 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBInstance_773443(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstance_773442(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773444 = query.getOrDefault("Action")
  valid_773444 = validateParameter(valid_773444, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_773444 != nil:
    section.add "Action", valid_773444
  var valid_773445 = query.getOrDefault("Version")
  valid_773445 = validateParameter(valid_773445, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773445 != nil:
    section.add "Version", valid_773445
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773446 = header.getOrDefault("X-Amz-Date")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Date", valid_773446
  var valid_773447 = header.getOrDefault("X-Amz-Security-Token")
  valid_773447 = validateParameter(valid_773447, JString, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "X-Amz-Security-Token", valid_773447
  var valid_773448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-Content-Sha256", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Algorithm")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Algorithm", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-Signature")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Signature", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-SignedHeaders", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Credential")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Credential", valid_773452
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
  var valid_773453 = formData.getOrDefault("DBSecurityGroups")
  valid_773453 = validateParameter(valid_773453, JArray, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "DBSecurityGroups", valid_773453
  var valid_773454 = formData.getOrDefault("Port")
  valid_773454 = validateParameter(valid_773454, JInt, required = false, default = nil)
  if valid_773454 != nil:
    section.add "Port", valid_773454
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_773455 = formData.getOrDefault("Engine")
  valid_773455 = validateParameter(valid_773455, JString, required = true,
                                 default = nil)
  if valid_773455 != nil:
    section.add "Engine", valid_773455
  var valid_773456 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_773456 = validateParameter(valid_773456, JArray, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "VpcSecurityGroupIds", valid_773456
  var valid_773457 = formData.getOrDefault("Iops")
  valid_773457 = validateParameter(valid_773457, JInt, required = false, default = nil)
  if valid_773457 != nil:
    section.add "Iops", valid_773457
  var valid_773458 = formData.getOrDefault("DBName")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "DBName", valid_773458
  var valid_773459 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773459 = validateParameter(valid_773459, JString, required = true,
                                 default = nil)
  if valid_773459 != nil:
    section.add "DBInstanceIdentifier", valid_773459
  var valid_773460 = formData.getOrDefault("BackupRetentionPeriod")
  valid_773460 = validateParameter(valid_773460, JInt, required = false, default = nil)
  if valid_773460 != nil:
    section.add "BackupRetentionPeriod", valid_773460
  var valid_773461 = formData.getOrDefault("DBParameterGroupName")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "DBParameterGroupName", valid_773461
  var valid_773462 = formData.getOrDefault("OptionGroupName")
  valid_773462 = validateParameter(valid_773462, JString, required = false,
                                 default = nil)
  if valid_773462 != nil:
    section.add "OptionGroupName", valid_773462
  var valid_773463 = formData.getOrDefault("Tags")
  valid_773463 = validateParameter(valid_773463, JArray, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "Tags", valid_773463
  var valid_773464 = formData.getOrDefault("MasterUserPassword")
  valid_773464 = validateParameter(valid_773464, JString, required = true,
                                 default = nil)
  if valid_773464 != nil:
    section.add "MasterUserPassword", valid_773464
  var valid_773465 = formData.getOrDefault("TdeCredentialArn")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "TdeCredentialArn", valid_773465
  var valid_773466 = formData.getOrDefault("DBSubnetGroupName")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "DBSubnetGroupName", valid_773466
  var valid_773467 = formData.getOrDefault("TdeCredentialPassword")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "TdeCredentialPassword", valid_773467
  var valid_773468 = formData.getOrDefault("AvailabilityZone")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "AvailabilityZone", valid_773468
  var valid_773469 = formData.getOrDefault("MultiAZ")
  valid_773469 = validateParameter(valid_773469, JBool, required = false, default = nil)
  if valid_773469 != nil:
    section.add "MultiAZ", valid_773469
  var valid_773470 = formData.getOrDefault("AllocatedStorage")
  valid_773470 = validateParameter(valid_773470, JInt, required = true, default = nil)
  if valid_773470 != nil:
    section.add "AllocatedStorage", valid_773470
  var valid_773471 = formData.getOrDefault("PubliclyAccessible")
  valid_773471 = validateParameter(valid_773471, JBool, required = false, default = nil)
  if valid_773471 != nil:
    section.add "PubliclyAccessible", valid_773471
  var valid_773472 = formData.getOrDefault("MasterUsername")
  valid_773472 = validateParameter(valid_773472, JString, required = true,
                                 default = nil)
  if valid_773472 != nil:
    section.add "MasterUsername", valid_773472
  var valid_773473 = formData.getOrDefault("StorageType")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "StorageType", valid_773473
  var valid_773474 = formData.getOrDefault("DBInstanceClass")
  valid_773474 = validateParameter(valid_773474, JString, required = true,
                                 default = nil)
  if valid_773474 != nil:
    section.add "DBInstanceClass", valid_773474
  var valid_773475 = formData.getOrDefault("CharacterSetName")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "CharacterSetName", valid_773475
  var valid_773476 = formData.getOrDefault("PreferredBackupWindow")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "PreferredBackupWindow", valid_773476
  var valid_773477 = formData.getOrDefault("LicenseModel")
  valid_773477 = validateParameter(valid_773477, JString, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "LicenseModel", valid_773477
  var valid_773478 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_773478 = validateParameter(valid_773478, JBool, required = false, default = nil)
  if valid_773478 != nil:
    section.add "AutoMinorVersionUpgrade", valid_773478
  var valid_773479 = formData.getOrDefault("EngineVersion")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "EngineVersion", valid_773479
  var valid_773480 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "PreferredMaintenanceWindow", valid_773480
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773481: Call_PostCreateDBInstance_773441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773481.validator(path, query, header, formData, body)
  let scheme = call_773481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773481.url(scheme.get, call_773481.host, call_773481.base,
                         call_773481.route, valid.getOrDefault("path"))
  result = hook(call_773481, url, valid)

proc call*(call_773482: Call_PostCreateDBInstance_773441; Engine: string;
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
  var query_773483 = newJObject()
  var formData_773484 = newJObject()
  if DBSecurityGroups != nil:
    formData_773484.add "DBSecurityGroups", DBSecurityGroups
  add(formData_773484, "Port", newJInt(Port))
  add(formData_773484, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_773484.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_773484, "Iops", newJInt(Iops))
  add(formData_773484, "DBName", newJString(DBName))
  add(formData_773484, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_773484, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_773484, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_773484, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_773484.add "Tags", Tags
  add(formData_773484, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_773484, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_773484, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_773484, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_773484, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_773484, "MultiAZ", newJBool(MultiAZ))
  add(query_773483, "Action", newJString(Action))
  add(formData_773484, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_773484, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_773484, "MasterUsername", newJString(MasterUsername))
  add(formData_773484, "StorageType", newJString(StorageType))
  add(formData_773484, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_773484, "CharacterSetName", newJString(CharacterSetName))
  add(formData_773484, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_773484, "LicenseModel", newJString(LicenseModel))
  add(formData_773484, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_773484, "EngineVersion", newJString(EngineVersion))
  add(query_773483, "Version", newJString(Version))
  add(formData_773484, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_773482.call(nil, query_773483, nil, formData_773484, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_773441(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_773442, base: "/",
    url: url_PostCreateDBInstance_773443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_773398 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBInstance_773400(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstance_773399(path: JsonNode; query: JsonNode;
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
  var valid_773401 = query.getOrDefault("Engine")
  valid_773401 = validateParameter(valid_773401, JString, required = true,
                                 default = nil)
  if valid_773401 != nil:
    section.add "Engine", valid_773401
  var valid_773402 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "PreferredMaintenanceWindow", valid_773402
  var valid_773403 = query.getOrDefault("AllocatedStorage")
  valid_773403 = validateParameter(valid_773403, JInt, required = true, default = nil)
  if valid_773403 != nil:
    section.add "AllocatedStorage", valid_773403
  var valid_773404 = query.getOrDefault("StorageType")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "StorageType", valid_773404
  var valid_773405 = query.getOrDefault("OptionGroupName")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "OptionGroupName", valid_773405
  var valid_773406 = query.getOrDefault("DBSecurityGroups")
  valid_773406 = validateParameter(valid_773406, JArray, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "DBSecurityGroups", valid_773406
  var valid_773407 = query.getOrDefault("MasterUserPassword")
  valid_773407 = validateParameter(valid_773407, JString, required = true,
                                 default = nil)
  if valid_773407 != nil:
    section.add "MasterUserPassword", valid_773407
  var valid_773408 = query.getOrDefault("AvailabilityZone")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "AvailabilityZone", valid_773408
  var valid_773409 = query.getOrDefault("Iops")
  valid_773409 = validateParameter(valid_773409, JInt, required = false, default = nil)
  if valid_773409 != nil:
    section.add "Iops", valid_773409
  var valid_773410 = query.getOrDefault("VpcSecurityGroupIds")
  valid_773410 = validateParameter(valid_773410, JArray, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "VpcSecurityGroupIds", valid_773410
  var valid_773411 = query.getOrDefault("MultiAZ")
  valid_773411 = validateParameter(valid_773411, JBool, required = false, default = nil)
  if valid_773411 != nil:
    section.add "MultiAZ", valid_773411
  var valid_773412 = query.getOrDefault("TdeCredentialPassword")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "TdeCredentialPassword", valid_773412
  var valid_773413 = query.getOrDefault("LicenseModel")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "LicenseModel", valid_773413
  var valid_773414 = query.getOrDefault("BackupRetentionPeriod")
  valid_773414 = validateParameter(valid_773414, JInt, required = false, default = nil)
  if valid_773414 != nil:
    section.add "BackupRetentionPeriod", valid_773414
  var valid_773415 = query.getOrDefault("DBName")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "DBName", valid_773415
  var valid_773416 = query.getOrDefault("DBParameterGroupName")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "DBParameterGroupName", valid_773416
  var valid_773417 = query.getOrDefault("Tags")
  valid_773417 = validateParameter(valid_773417, JArray, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "Tags", valid_773417
  var valid_773418 = query.getOrDefault("DBInstanceClass")
  valid_773418 = validateParameter(valid_773418, JString, required = true,
                                 default = nil)
  if valid_773418 != nil:
    section.add "DBInstanceClass", valid_773418
  var valid_773419 = query.getOrDefault("Action")
  valid_773419 = validateParameter(valid_773419, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_773419 != nil:
    section.add "Action", valid_773419
  var valid_773420 = query.getOrDefault("DBSubnetGroupName")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "DBSubnetGroupName", valid_773420
  var valid_773421 = query.getOrDefault("CharacterSetName")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "CharacterSetName", valid_773421
  var valid_773422 = query.getOrDefault("TdeCredentialArn")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "TdeCredentialArn", valid_773422
  var valid_773423 = query.getOrDefault("PubliclyAccessible")
  valid_773423 = validateParameter(valid_773423, JBool, required = false, default = nil)
  if valid_773423 != nil:
    section.add "PubliclyAccessible", valid_773423
  var valid_773424 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_773424 = validateParameter(valid_773424, JBool, required = false, default = nil)
  if valid_773424 != nil:
    section.add "AutoMinorVersionUpgrade", valid_773424
  var valid_773425 = query.getOrDefault("EngineVersion")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "EngineVersion", valid_773425
  var valid_773426 = query.getOrDefault("Port")
  valid_773426 = validateParameter(valid_773426, JInt, required = false, default = nil)
  if valid_773426 != nil:
    section.add "Port", valid_773426
  var valid_773427 = query.getOrDefault("PreferredBackupWindow")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "PreferredBackupWindow", valid_773427
  var valid_773428 = query.getOrDefault("Version")
  valid_773428 = validateParameter(valid_773428, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773428 != nil:
    section.add "Version", valid_773428
  var valid_773429 = query.getOrDefault("DBInstanceIdentifier")
  valid_773429 = validateParameter(valid_773429, JString, required = true,
                                 default = nil)
  if valid_773429 != nil:
    section.add "DBInstanceIdentifier", valid_773429
  var valid_773430 = query.getOrDefault("MasterUsername")
  valid_773430 = validateParameter(valid_773430, JString, required = true,
                                 default = nil)
  if valid_773430 != nil:
    section.add "MasterUsername", valid_773430
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773431 = header.getOrDefault("X-Amz-Date")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-Date", valid_773431
  var valid_773432 = header.getOrDefault("X-Amz-Security-Token")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-Security-Token", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Content-Sha256", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-Algorithm")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Algorithm", valid_773434
  var valid_773435 = header.getOrDefault("X-Amz-Signature")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-Signature", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-SignedHeaders", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-Credential")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Credential", valid_773437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773438: Call_GetCreateDBInstance_773398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773438.validator(path, query, header, formData, body)
  let scheme = call_773438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773438.url(scheme.get, call_773438.host, call_773438.base,
                         call_773438.route, valid.getOrDefault("path"))
  result = hook(call_773438, url, valid)

proc call*(call_773439: Call_GetCreateDBInstance_773398; Engine: string;
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
  var query_773440 = newJObject()
  add(query_773440, "Engine", newJString(Engine))
  add(query_773440, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_773440, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_773440, "StorageType", newJString(StorageType))
  add(query_773440, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_773440.add "DBSecurityGroups", DBSecurityGroups
  add(query_773440, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_773440, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_773440, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_773440.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_773440, "MultiAZ", newJBool(MultiAZ))
  add(query_773440, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_773440, "LicenseModel", newJString(LicenseModel))
  add(query_773440, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_773440, "DBName", newJString(DBName))
  add(query_773440, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_773440.add "Tags", Tags
  add(query_773440, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_773440, "Action", newJString(Action))
  add(query_773440, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773440, "CharacterSetName", newJString(CharacterSetName))
  add(query_773440, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_773440, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_773440, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_773440, "EngineVersion", newJString(EngineVersion))
  add(query_773440, "Port", newJInt(Port))
  add(query_773440, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_773440, "Version", newJString(Version))
  add(query_773440, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_773440, "MasterUsername", newJString(MasterUsername))
  result = call_773439.call(nil, query_773440, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_773398(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_773399, base: "/",
    url: url_GetCreateDBInstance_773400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_773512 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBInstanceReadReplica_773514(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstanceReadReplica_773513(path: JsonNode;
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
  var valid_773515 = query.getOrDefault("Action")
  valid_773515 = validateParameter(valid_773515, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_773515 != nil:
    section.add "Action", valid_773515
  var valid_773516 = query.getOrDefault("Version")
  valid_773516 = validateParameter(valid_773516, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773516 != nil:
    section.add "Version", valid_773516
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773517 = header.getOrDefault("X-Amz-Date")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Date", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Security-Token")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Security-Token", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-Content-Sha256", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-Algorithm")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Algorithm", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-Signature")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Signature", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-SignedHeaders", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-Credential")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-Credential", valid_773523
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
  var valid_773524 = formData.getOrDefault("Port")
  valid_773524 = validateParameter(valid_773524, JInt, required = false, default = nil)
  if valid_773524 != nil:
    section.add "Port", valid_773524
  var valid_773525 = formData.getOrDefault("Iops")
  valid_773525 = validateParameter(valid_773525, JInt, required = false, default = nil)
  if valid_773525 != nil:
    section.add "Iops", valid_773525
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_773526 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773526 = validateParameter(valid_773526, JString, required = true,
                                 default = nil)
  if valid_773526 != nil:
    section.add "DBInstanceIdentifier", valid_773526
  var valid_773527 = formData.getOrDefault("OptionGroupName")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "OptionGroupName", valid_773527
  var valid_773528 = formData.getOrDefault("Tags")
  valid_773528 = validateParameter(valid_773528, JArray, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "Tags", valid_773528
  var valid_773529 = formData.getOrDefault("DBSubnetGroupName")
  valid_773529 = validateParameter(valid_773529, JString, required = false,
                                 default = nil)
  if valid_773529 != nil:
    section.add "DBSubnetGroupName", valid_773529
  var valid_773530 = formData.getOrDefault("AvailabilityZone")
  valid_773530 = validateParameter(valid_773530, JString, required = false,
                                 default = nil)
  if valid_773530 != nil:
    section.add "AvailabilityZone", valid_773530
  var valid_773531 = formData.getOrDefault("PubliclyAccessible")
  valid_773531 = validateParameter(valid_773531, JBool, required = false, default = nil)
  if valid_773531 != nil:
    section.add "PubliclyAccessible", valid_773531
  var valid_773532 = formData.getOrDefault("StorageType")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "StorageType", valid_773532
  var valid_773533 = formData.getOrDefault("DBInstanceClass")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "DBInstanceClass", valid_773533
  var valid_773534 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_773534 = validateParameter(valid_773534, JString, required = true,
                                 default = nil)
  if valid_773534 != nil:
    section.add "SourceDBInstanceIdentifier", valid_773534
  var valid_773535 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_773535 = validateParameter(valid_773535, JBool, required = false, default = nil)
  if valid_773535 != nil:
    section.add "AutoMinorVersionUpgrade", valid_773535
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773536: Call_PostCreateDBInstanceReadReplica_773512;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_773536.validator(path, query, header, formData, body)
  let scheme = call_773536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773536.url(scheme.get, call_773536.host, call_773536.base,
                         call_773536.route, valid.getOrDefault("path"))
  result = hook(call_773536, url, valid)

proc call*(call_773537: Call_PostCreateDBInstanceReadReplica_773512;
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
  var query_773538 = newJObject()
  var formData_773539 = newJObject()
  add(formData_773539, "Port", newJInt(Port))
  add(formData_773539, "Iops", newJInt(Iops))
  add(formData_773539, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_773539, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_773539.add "Tags", Tags
  add(formData_773539, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_773539, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_773538, "Action", newJString(Action))
  add(formData_773539, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_773539, "StorageType", newJString(StorageType))
  add(formData_773539, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_773539, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_773539, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_773538, "Version", newJString(Version))
  result = call_773537.call(nil, query_773538, nil, formData_773539, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_773512(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_773513, base: "/",
    url: url_PostCreateDBInstanceReadReplica_773514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_773485 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBInstanceReadReplica_773487(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstanceReadReplica_773486(path: JsonNode;
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
  var valid_773488 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_773488 = validateParameter(valid_773488, JString, required = true,
                                 default = nil)
  if valid_773488 != nil:
    section.add "SourceDBInstanceIdentifier", valid_773488
  var valid_773489 = query.getOrDefault("StorageType")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "StorageType", valid_773489
  var valid_773490 = query.getOrDefault("OptionGroupName")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "OptionGroupName", valid_773490
  var valid_773491 = query.getOrDefault("AvailabilityZone")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "AvailabilityZone", valid_773491
  var valid_773492 = query.getOrDefault("Iops")
  valid_773492 = validateParameter(valid_773492, JInt, required = false, default = nil)
  if valid_773492 != nil:
    section.add "Iops", valid_773492
  var valid_773493 = query.getOrDefault("Tags")
  valid_773493 = validateParameter(valid_773493, JArray, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "Tags", valid_773493
  var valid_773494 = query.getOrDefault("DBInstanceClass")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "DBInstanceClass", valid_773494
  var valid_773495 = query.getOrDefault("Action")
  valid_773495 = validateParameter(valid_773495, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_773495 != nil:
    section.add "Action", valid_773495
  var valid_773496 = query.getOrDefault("DBSubnetGroupName")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "DBSubnetGroupName", valid_773496
  var valid_773497 = query.getOrDefault("PubliclyAccessible")
  valid_773497 = validateParameter(valid_773497, JBool, required = false, default = nil)
  if valid_773497 != nil:
    section.add "PubliclyAccessible", valid_773497
  var valid_773498 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_773498 = validateParameter(valid_773498, JBool, required = false, default = nil)
  if valid_773498 != nil:
    section.add "AutoMinorVersionUpgrade", valid_773498
  var valid_773499 = query.getOrDefault("Port")
  valid_773499 = validateParameter(valid_773499, JInt, required = false, default = nil)
  if valid_773499 != nil:
    section.add "Port", valid_773499
  var valid_773500 = query.getOrDefault("Version")
  valid_773500 = validateParameter(valid_773500, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773500 != nil:
    section.add "Version", valid_773500
  var valid_773501 = query.getOrDefault("DBInstanceIdentifier")
  valid_773501 = validateParameter(valid_773501, JString, required = true,
                                 default = nil)
  if valid_773501 != nil:
    section.add "DBInstanceIdentifier", valid_773501
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773502 = header.getOrDefault("X-Amz-Date")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Date", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-Security-Token")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Security-Token", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Content-Sha256", valid_773504
  var valid_773505 = header.getOrDefault("X-Amz-Algorithm")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Algorithm", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-Signature")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Signature", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-SignedHeaders", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-Credential")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-Credential", valid_773508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773509: Call_GetCreateDBInstanceReadReplica_773485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773509.validator(path, query, header, formData, body)
  let scheme = call_773509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773509.url(scheme.get, call_773509.host, call_773509.base,
                         call_773509.route, valid.getOrDefault("path"))
  result = hook(call_773509, url, valid)

proc call*(call_773510: Call_GetCreateDBInstanceReadReplica_773485;
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
  var query_773511 = newJObject()
  add(query_773511, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_773511, "StorageType", newJString(StorageType))
  add(query_773511, "OptionGroupName", newJString(OptionGroupName))
  add(query_773511, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_773511, "Iops", newJInt(Iops))
  if Tags != nil:
    query_773511.add "Tags", Tags
  add(query_773511, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_773511, "Action", newJString(Action))
  add(query_773511, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773511, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_773511, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_773511, "Port", newJInt(Port))
  add(query_773511, "Version", newJString(Version))
  add(query_773511, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_773510.call(nil, query_773511, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_773485(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_773486, base: "/",
    url: url_GetCreateDBInstanceReadReplica_773487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_773559 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBParameterGroup_773561(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBParameterGroup_773560(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773562 = query.getOrDefault("Action")
  valid_773562 = validateParameter(valid_773562, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_773562 != nil:
    section.add "Action", valid_773562
  var valid_773563 = query.getOrDefault("Version")
  valid_773563 = validateParameter(valid_773563, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773563 != nil:
    section.add "Version", valid_773563
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773564 = header.getOrDefault("X-Amz-Date")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-Date", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-Security-Token")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-Security-Token", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Content-Sha256", valid_773566
  var valid_773567 = header.getOrDefault("X-Amz-Algorithm")
  valid_773567 = validateParameter(valid_773567, JString, required = false,
                                 default = nil)
  if valid_773567 != nil:
    section.add "X-Amz-Algorithm", valid_773567
  var valid_773568 = header.getOrDefault("X-Amz-Signature")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "X-Amz-Signature", valid_773568
  var valid_773569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-SignedHeaders", valid_773569
  var valid_773570 = header.getOrDefault("X-Amz-Credential")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "X-Amz-Credential", valid_773570
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_773571 = formData.getOrDefault("DBParameterGroupName")
  valid_773571 = validateParameter(valid_773571, JString, required = true,
                                 default = nil)
  if valid_773571 != nil:
    section.add "DBParameterGroupName", valid_773571
  var valid_773572 = formData.getOrDefault("Tags")
  valid_773572 = validateParameter(valid_773572, JArray, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "Tags", valid_773572
  var valid_773573 = formData.getOrDefault("DBParameterGroupFamily")
  valid_773573 = validateParameter(valid_773573, JString, required = true,
                                 default = nil)
  if valid_773573 != nil:
    section.add "DBParameterGroupFamily", valid_773573
  var valid_773574 = formData.getOrDefault("Description")
  valid_773574 = validateParameter(valid_773574, JString, required = true,
                                 default = nil)
  if valid_773574 != nil:
    section.add "Description", valid_773574
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773575: Call_PostCreateDBParameterGroup_773559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773575.validator(path, query, header, formData, body)
  let scheme = call_773575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773575.url(scheme.get, call_773575.host, call_773575.base,
                         call_773575.route, valid.getOrDefault("path"))
  result = hook(call_773575, url, valid)

proc call*(call_773576: Call_PostCreateDBParameterGroup_773559;
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
  var query_773577 = newJObject()
  var formData_773578 = newJObject()
  add(formData_773578, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_773578.add "Tags", Tags
  add(query_773577, "Action", newJString(Action))
  add(formData_773578, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_773577, "Version", newJString(Version))
  add(formData_773578, "Description", newJString(Description))
  result = call_773576.call(nil, query_773577, nil, formData_773578, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_773559(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_773560, base: "/",
    url: url_PostCreateDBParameterGroup_773561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_773540 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBParameterGroup_773542(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBParameterGroup_773541(path: JsonNode; query: JsonNode;
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
  var valid_773543 = query.getOrDefault("Description")
  valid_773543 = validateParameter(valid_773543, JString, required = true,
                                 default = nil)
  if valid_773543 != nil:
    section.add "Description", valid_773543
  var valid_773544 = query.getOrDefault("DBParameterGroupFamily")
  valid_773544 = validateParameter(valid_773544, JString, required = true,
                                 default = nil)
  if valid_773544 != nil:
    section.add "DBParameterGroupFamily", valid_773544
  var valid_773545 = query.getOrDefault("Tags")
  valid_773545 = validateParameter(valid_773545, JArray, required = false,
                                 default = nil)
  if valid_773545 != nil:
    section.add "Tags", valid_773545
  var valid_773546 = query.getOrDefault("DBParameterGroupName")
  valid_773546 = validateParameter(valid_773546, JString, required = true,
                                 default = nil)
  if valid_773546 != nil:
    section.add "DBParameterGroupName", valid_773546
  var valid_773547 = query.getOrDefault("Action")
  valid_773547 = validateParameter(valid_773547, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_773547 != nil:
    section.add "Action", valid_773547
  var valid_773548 = query.getOrDefault("Version")
  valid_773548 = validateParameter(valid_773548, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773548 != nil:
    section.add "Version", valid_773548
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773549 = header.getOrDefault("X-Amz-Date")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-Date", valid_773549
  var valid_773550 = header.getOrDefault("X-Amz-Security-Token")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Security-Token", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Content-Sha256", valid_773551
  var valid_773552 = header.getOrDefault("X-Amz-Algorithm")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-Algorithm", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-Signature")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Signature", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-SignedHeaders", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-Credential")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-Credential", valid_773555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773556: Call_GetCreateDBParameterGroup_773540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773556.validator(path, query, header, formData, body)
  let scheme = call_773556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773556.url(scheme.get, call_773556.host, call_773556.base,
                         call_773556.route, valid.getOrDefault("path"))
  result = hook(call_773556, url, valid)

proc call*(call_773557: Call_GetCreateDBParameterGroup_773540; Description: string;
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
  var query_773558 = newJObject()
  add(query_773558, "Description", newJString(Description))
  add(query_773558, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_773558.add "Tags", Tags
  add(query_773558, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_773558, "Action", newJString(Action))
  add(query_773558, "Version", newJString(Version))
  result = call_773557.call(nil, query_773558, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_773540(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_773541, base: "/",
    url: url_GetCreateDBParameterGroup_773542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_773597 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBSecurityGroup_773599(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSecurityGroup_773598(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773600 = query.getOrDefault("Action")
  valid_773600 = validateParameter(valid_773600, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_773600 != nil:
    section.add "Action", valid_773600
  var valid_773601 = query.getOrDefault("Version")
  valid_773601 = validateParameter(valid_773601, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773601 != nil:
    section.add "Version", valid_773601
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773602 = header.getOrDefault("X-Amz-Date")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Date", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-Security-Token")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-Security-Token", valid_773603
  var valid_773604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "X-Amz-Content-Sha256", valid_773604
  var valid_773605 = header.getOrDefault("X-Amz-Algorithm")
  valid_773605 = validateParameter(valid_773605, JString, required = false,
                                 default = nil)
  if valid_773605 != nil:
    section.add "X-Amz-Algorithm", valid_773605
  var valid_773606 = header.getOrDefault("X-Amz-Signature")
  valid_773606 = validateParameter(valid_773606, JString, required = false,
                                 default = nil)
  if valid_773606 != nil:
    section.add "X-Amz-Signature", valid_773606
  var valid_773607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773607 = validateParameter(valid_773607, JString, required = false,
                                 default = nil)
  if valid_773607 != nil:
    section.add "X-Amz-SignedHeaders", valid_773607
  var valid_773608 = header.getOrDefault("X-Amz-Credential")
  valid_773608 = validateParameter(valid_773608, JString, required = false,
                                 default = nil)
  if valid_773608 != nil:
    section.add "X-Amz-Credential", valid_773608
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_773609 = formData.getOrDefault("DBSecurityGroupName")
  valid_773609 = validateParameter(valid_773609, JString, required = true,
                                 default = nil)
  if valid_773609 != nil:
    section.add "DBSecurityGroupName", valid_773609
  var valid_773610 = formData.getOrDefault("Tags")
  valid_773610 = validateParameter(valid_773610, JArray, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "Tags", valid_773610
  var valid_773611 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_773611 = validateParameter(valid_773611, JString, required = true,
                                 default = nil)
  if valid_773611 != nil:
    section.add "DBSecurityGroupDescription", valid_773611
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773612: Call_PostCreateDBSecurityGroup_773597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773612.validator(path, query, header, formData, body)
  let scheme = call_773612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773612.url(scheme.get, call_773612.host, call_773612.base,
                         call_773612.route, valid.getOrDefault("path"))
  result = hook(call_773612, url, valid)

proc call*(call_773613: Call_PostCreateDBSecurityGroup_773597;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_773614 = newJObject()
  var formData_773615 = newJObject()
  add(formData_773615, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_773615.add "Tags", Tags
  add(query_773614, "Action", newJString(Action))
  add(formData_773615, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_773614, "Version", newJString(Version))
  result = call_773613.call(nil, query_773614, nil, formData_773615, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_773597(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_773598, base: "/",
    url: url_PostCreateDBSecurityGroup_773599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_773579 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBSecurityGroup_773581(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSecurityGroup_773580(path: JsonNode; query: JsonNode;
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
  var valid_773582 = query.getOrDefault("DBSecurityGroupName")
  valid_773582 = validateParameter(valid_773582, JString, required = true,
                                 default = nil)
  if valid_773582 != nil:
    section.add "DBSecurityGroupName", valid_773582
  var valid_773583 = query.getOrDefault("DBSecurityGroupDescription")
  valid_773583 = validateParameter(valid_773583, JString, required = true,
                                 default = nil)
  if valid_773583 != nil:
    section.add "DBSecurityGroupDescription", valid_773583
  var valid_773584 = query.getOrDefault("Tags")
  valid_773584 = validateParameter(valid_773584, JArray, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "Tags", valid_773584
  var valid_773585 = query.getOrDefault("Action")
  valid_773585 = validateParameter(valid_773585, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_773585 != nil:
    section.add "Action", valid_773585
  var valid_773586 = query.getOrDefault("Version")
  valid_773586 = validateParameter(valid_773586, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773586 != nil:
    section.add "Version", valid_773586
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773587 = header.getOrDefault("X-Amz-Date")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Date", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-Security-Token")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-Security-Token", valid_773588
  var valid_773589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773589 = validateParameter(valid_773589, JString, required = false,
                                 default = nil)
  if valid_773589 != nil:
    section.add "X-Amz-Content-Sha256", valid_773589
  var valid_773590 = header.getOrDefault("X-Amz-Algorithm")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "X-Amz-Algorithm", valid_773590
  var valid_773591 = header.getOrDefault("X-Amz-Signature")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "X-Amz-Signature", valid_773591
  var valid_773592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773592 = validateParameter(valid_773592, JString, required = false,
                                 default = nil)
  if valid_773592 != nil:
    section.add "X-Amz-SignedHeaders", valid_773592
  var valid_773593 = header.getOrDefault("X-Amz-Credential")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "X-Amz-Credential", valid_773593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773594: Call_GetCreateDBSecurityGroup_773579; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773594.validator(path, query, header, formData, body)
  let scheme = call_773594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773594.url(scheme.get, call_773594.host, call_773594.base,
                         call_773594.route, valid.getOrDefault("path"))
  result = hook(call_773594, url, valid)

proc call*(call_773595: Call_GetCreateDBSecurityGroup_773579;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773596 = newJObject()
  add(query_773596, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_773596, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_773596.add "Tags", Tags
  add(query_773596, "Action", newJString(Action))
  add(query_773596, "Version", newJString(Version))
  result = call_773595.call(nil, query_773596, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_773579(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_773580, base: "/",
    url: url_GetCreateDBSecurityGroup_773581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_773634 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBSnapshot_773636(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSnapshot_773635(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773637 = query.getOrDefault("Action")
  valid_773637 = validateParameter(valid_773637, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_773637 != nil:
    section.add "Action", valid_773637
  var valid_773638 = query.getOrDefault("Version")
  valid_773638 = validateParameter(valid_773638, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773638 != nil:
    section.add "Version", valid_773638
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773639 = header.getOrDefault("X-Amz-Date")
  valid_773639 = validateParameter(valid_773639, JString, required = false,
                                 default = nil)
  if valid_773639 != nil:
    section.add "X-Amz-Date", valid_773639
  var valid_773640 = header.getOrDefault("X-Amz-Security-Token")
  valid_773640 = validateParameter(valid_773640, JString, required = false,
                                 default = nil)
  if valid_773640 != nil:
    section.add "X-Amz-Security-Token", valid_773640
  var valid_773641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773641 = validateParameter(valid_773641, JString, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "X-Amz-Content-Sha256", valid_773641
  var valid_773642 = header.getOrDefault("X-Amz-Algorithm")
  valid_773642 = validateParameter(valid_773642, JString, required = false,
                                 default = nil)
  if valid_773642 != nil:
    section.add "X-Amz-Algorithm", valid_773642
  var valid_773643 = header.getOrDefault("X-Amz-Signature")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-Signature", valid_773643
  var valid_773644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-SignedHeaders", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Credential")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Credential", valid_773645
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_773646 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773646 = validateParameter(valid_773646, JString, required = true,
                                 default = nil)
  if valid_773646 != nil:
    section.add "DBInstanceIdentifier", valid_773646
  var valid_773647 = formData.getOrDefault("Tags")
  valid_773647 = validateParameter(valid_773647, JArray, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "Tags", valid_773647
  var valid_773648 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_773648 = validateParameter(valid_773648, JString, required = true,
                                 default = nil)
  if valid_773648 != nil:
    section.add "DBSnapshotIdentifier", valid_773648
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773649: Call_PostCreateDBSnapshot_773634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773649.validator(path, query, header, formData, body)
  let scheme = call_773649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773649.url(scheme.get, call_773649.host, call_773649.base,
                         call_773649.route, valid.getOrDefault("path"))
  result = hook(call_773649, url, valid)

proc call*(call_773650: Call_PostCreateDBSnapshot_773634;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773651 = newJObject()
  var formData_773652 = newJObject()
  add(formData_773652, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_773652.add "Tags", Tags
  add(formData_773652, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_773651, "Action", newJString(Action))
  add(query_773651, "Version", newJString(Version))
  result = call_773650.call(nil, query_773651, nil, formData_773652, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_773634(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_773635, base: "/",
    url: url_PostCreateDBSnapshot_773636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_773616 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBSnapshot_773618(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSnapshot_773617(path: JsonNode; query: JsonNode;
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
  var valid_773619 = query.getOrDefault("Tags")
  valid_773619 = validateParameter(valid_773619, JArray, required = false,
                                 default = nil)
  if valid_773619 != nil:
    section.add "Tags", valid_773619
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773620 = query.getOrDefault("Action")
  valid_773620 = validateParameter(valid_773620, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_773620 != nil:
    section.add "Action", valid_773620
  var valid_773621 = query.getOrDefault("Version")
  valid_773621 = validateParameter(valid_773621, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773621 != nil:
    section.add "Version", valid_773621
  var valid_773622 = query.getOrDefault("DBInstanceIdentifier")
  valid_773622 = validateParameter(valid_773622, JString, required = true,
                                 default = nil)
  if valid_773622 != nil:
    section.add "DBInstanceIdentifier", valid_773622
  var valid_773623 = query.getOrDefault("DBSnapshotIdentifier")
  valid_773623 = validateParameter(valid_773623, JString, required = true,
                                 default = nil)
  if valid_773623 != nil:
    section.add "DBSnapshotIdentifier", valid_773623
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773624 = header.getOrDefault("X-Amz-Date")
  valid_773624 = validateParameter(valid_773624, JString, required = false,
                                 default = nil)
  if valid_773624 != nil:
    section.add "X-Amz-Date", valid_773624
  var valid_773625 = header.getOrDefault("X-Amz-Security-Token")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-Security-Token", valid_773625
  var valid_773626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-Content-Sha256", valid_773626
  var valid_773627 = header.getOrDefault("X-Amz-Algorithm")
  valid_773627 = validateParameter(valid_773627, JString, required = false,
                                 default = nil)
  if valid_773627 != nil:
    section.add "X-Amz-Algorithm", valid_773627
  var valid_773628 = header.getOrDefault("X-Amz-Signature")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "X-Amz-Signature", valid_773628
  var valid_773629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-SignedHeaders", valid_773629
  var valid_773630 = header.getOrDefault("X-Amz-Credential")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "X-Amz-Credential", valid_773630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773631: Call_GetCreateDBSnapshot_773616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773631.validator(path, query, header, formData, body)
  let scheme = call_773631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773631.url(scheme.get, call_773631.host, call_773631.base,
                         call_773631.route, valid.getOrDefault("path"))
  result = hook(call_773631, url, valid)

proc call*(call_773632: Call_GetCreateDBSnapshot_773616;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_773633 = newJObject()
  if Tags != nil:
    query_773633.add "Tags", Tags
  add(query_773633, "Action", newJString(Action))
  add(query_773633, "Version", newJString(Version))
  add(query_773633, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_773633, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_773632.call(nil, query_773633, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_773616(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_773617, base: "/",
    url: url_GetCreateDBSnapshot_773618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_773672 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBSubnetGroup_773674(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSubnetGroup_773673(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773675 = query.getOrDefault("Action")
  valid_773675 = validateParameter(valid_773675, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_773675 != nil:
    section.add "Action", valid_773675
  var valid_773676 = query.getOrDefault("Version")
  valid_773676 = validateParameter(valid_773676, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773676 != nil:
    section.add "Version", valid_773676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773677 = header.getOrDefault("X-Amz-Date")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Date", valid_773677
  var valid_773678 = header.getOrDefault("X-Amz-Security-Token")
  valid_773678 = validateParameter(valid_773678, JString, required = false,
                                 default = nil)
  if valid_773678 != nil:
    section.add "X-Amz-Security-Token", valid_773678
  var valid_773679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "X-Amz-Content-Sha256", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-Algorithm")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Algorithm", valid_773680
  var valid_773681 = header.getOrDefault("X-Amz-Signature")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-Signature", valid_773681
  var valid_773682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-SignedHeaders", valid_773682
  var valid_773683 = header.getOrDefault("X-Amz-Credential")
  valid_773683 = validateParameter(valid_773683, JString, required = false,
                                 default = nil)
  if valid_773683 != nil:
    section.add "X-Amz-Credential", valid_773683
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_773684 = formData.getOrDefault("Tags")
  valid_773684 = validateParameter(valid_773684, JArray, required = false,
                                 default = nil)
  if valid_773684 != nil:
    section.add "Tags", valid_773684
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_773685 = formData.getOrDefault("DBSubnetGroupName")
  valid_773685 = validateParameter(valid_773685, JString, required = true,
                                 default = nil)
  if valid_773685 != nil:
    section.add "DBSubnetGroupName", valid_773685
  var valid_773686 = formData.getOrDefault("SubnetIds")
  valid_773686 = validateParameter(valid_773686, JArray, required = true, default = nil)
  if valid_773686 != nil:
    section.add "SubnetIds", valid_773686
  var valid_773687 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_773687 = validateParameter(valid_773687, JString, required = true,
                                 default = nil)
  if valid_773687 != nil:
    section.add "DBSubnetGroupDescription", valid_773687
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773688: Call_PostCreateDBSubnetGroup_773672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773688.validator(path, query, header, formData, body)
  let scheme = call_773688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773688.url(scheme.get, call_773688.host, call_773688.base,
                         call_773688.route, valid.getOrDefault("path"))
  result = hook(call_773688, url, valid)

proc call*(call_773689: Call_PostCreateDBSubnetGroup_773672;
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
  var query_773690 = newJObject()
  var formData_773691 = newJObject()
  if Tags != nil:
    formData_773691.add "Tags", Tags
  add(formData_773691, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_773691.add "SubnetIds", SubnetIds
  add(query_773690, "Action", newJString(Action))
  add(formData_773691, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_773690, "Version", newJString(Version))
  result = call_773689.call(nil, query_773690, nil, formData_773691, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_773672(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_773673, base: "/",
    url: url_PostCreateDBSubnetGroup_773674, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_773653 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBSubnetGroup_773655(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSubnetGroup_773654(path: JsonNode; query: JsonNode;
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
  var valid_773656 = query.getOrDefault("Tags")
  valid_773656 = validateParameter(valid_773656, JArray, required = false,
                                 default = nil)
  if valid_773656 != nil:
    section.add "Tags", valid_773656
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773657 = query.getOrDefault("Action")
  valid_773657 = validateParameter(valid_773657, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_773657 != nil:
    section.add "Action", valid_773657
  var valid_773658 = query.getOrDefault("DBSubnetGroupName")
  valid_773658 = validateParameter(valid_773658, JString, required = true,
                                 default = nil)
  if valid_773658 != nil:
    section.add "DBSubnetGroupName", valid_773658
  var valid_773659 = query.getOrDefault("SubnetIds")
  valid_773659 = validateParameter(valid_773659, JArray, required = true, default = nil)
  if valid_773659 != nil:
    section.add "SubnetIds", valid_773659
  var valid_773660 = query.getOrDefault("DBSubnetGroupDescription")
  valid_773660 = validateParameter(valid_773660, JString, required = true,
                                 default = nil)
  if valid_773660 != nil:
    section.add "DBSubnetGroupDescription", valid_773660
  var valid_773661 = query.getOrDefault("Version")
  valid_773661 = validateParameter(valid_773661, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773661 != nil:
    section.add "Version", valid_773661
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773662 = header.getOrDefault("X-Amz-Date")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Date", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-Security-Token")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Security-Token", valid_773663
  var valid_773664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773664 = validateParameter(valid_773664, JString, required = false,
                                 default = nil)
  if valid_773664 != nil:
    section.add "X-Amz-Content-Sha256", valid_773664
  var valid_773665 = header.getOrDefault("X-Amz-Algorithm")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-Algorithm", valid_773665
  var valid_773666 = header.getOrDefault("X-Amz-Signature")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "X-Amz-Signature", valid_773666
  var valid_773667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773667 = validateParameter(valid_773667, JString, required = false,
                                 default = nil)
  if valid_773667 != nil:
    section.add "X-Amz-SignedHeaders", valid_773667
  var valid_773668 = header.getOrDefault("X-Amz-Credential")
  valid_773668 = validateParameter(valid_773668, JString, required = false,
                                 default = nil)
  if valid_773668 != nil:
    section.add "X-Amz-Credential", valid_773668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773669: Call_GetCreateDBSubnetGroup_773653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773669.validator(path, query, header, formData, body)
  let scheme = call_773669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773669.url(scheme.get, call_773669.host, call_773669.base,
                         call_773669.route, valid.getOrDefault("path"))
  result = hook(call_773669, url, valid)

proc call*(call_773670: Call_GetCreateDBSubnetGroup_773653;
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
  var query_773671 = newJObject()
  if Tags != nil:
    query_773671.add "Tags", Tags
  add(query_773671, "Action", newJString(Action))
  add(query_773671, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_773671.add "SubnetIds", SubnetIds
  add(query_773671, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_773671, "Version", newJString(Version))
  result = call_773670.call(nil, query_773671, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_773653(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_773654, base: "/",
    url: url_GetCreateDBSubnetGroup_773655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_773714 = ref object of OpenApiRestCall_772581
proc url_PostCreateEventSubscription_773716(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateEventSubscription_773715(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773717 = query.getOrDefault("Action")
  valid_773717 = validateParameter(valid_773717, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_773717 != nil:
    section.add "Action", valid_773717
  var valid_773718 = query.getOrDefault("Version")
  valid_773718 = validateParameter(valid_773718, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773718 != nil:
    section.add "Version", valid_773718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773719 = header.getOrDefault("X-Amz-Date")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "X-Amz-Date", valid_773719
  var valid_773720 = header.getOrDefault("X-Amz-Security-Token")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "X-Amz-Security-Token", valid_773720
  var valid_773721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773721 = validateParameter(valid_773721, JString, required = false,
                                 default = nil)
  if valid_773721 != nil:
    section.add "X-Amz-Content-Sha256", valid_773721
  var valid_773722 = header.getOrDefault("X-Amz-Algorithm")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "X-Amz-Algorithm", valid_773722
  var valid_773723 = header.getOrDefault("X-Amz-Signature")
  valid_773723 = validateParameter(valid_773723, JString, required = false,
                                 default = nil)
  if valid_773723 != nil:
    section.add "X-Amz-Signature", valid_773723
  var valid_773724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773724 = validateParameter(valid_773724, JString, required = false,
                                 default = nil)
  if valid_773724 != nil:
    section.add "X-Amz-SignedHeaders", valid_773724
  var valid_773725 = header.getOrDefault("X-Amz-Credential")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "X-Amz-Credential", valid_773725
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
  var valid_773726 = formData.getOrDefault("Enabled")
  valid_773726 = validateParameter(valid_773726, JBool, required = false, default = nil)
  if valid_773726 != nil:
    section.add "Enabled", valid_773726
  var valid_773727 = formData.getOrDefault("EventCategories")
  valid_773727 = validateParameter(valid_773727, JArray, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "EventCategories", valid_773727
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_773728 = formData.getOrDefault("SnsTopicArn")
  valid_773728 = validateParameter(valid_773728, JString, required = true,
                                 default = nil)
  if valid_773728 != nil:
    section.add "SnsTopicArn", valid_773728
  var valid_773729 = formData.getOrDefault("SourceIds")
  valid_773729 = validateParameter(valid_773729, JArray, required = false,
                                 default = nil)
  if valid_773729 != nil:
    section.add "SourceIds", valid_773729
  var valid_773730 = formData.getOrDefault("Tags")
  valid_773730 = validateParameter(valid_773730, JArray, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "Tags", valid_773730
  var valid_773731 = formData.getOrDefault("SubscriptionName")
  valid_773731 = validateParameter(valid_773731, JString, required = true,
                                 default = nil)
  if valid_773731 != nil:
    section.add "SubscriptionName", valid_773731
  var valid_773732 = formData.getOrDefault("SourceType")
  valid_773732 = validateParameter(valid_773732, JString, required = false,
                                 default = nil)
  if valid_773732 != nil:
    section.add "SourceType", valid_773732
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773733: Call_PostCreateEventSubscription_773714; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773733.validator(path, query, header, formData, body)
  let scheme = call_773733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773733.url(scheme.get, call_773733.host, call_773733.base,
                         call_773733.route, valid.getOrDefault("path"))
  result = hook(call_773733, url, valid)

proc call*(call_773734: Call_PostCreateEventSubscription_773714;
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
  var query_773735 = newJObject()
  var formData_773736 = newJObject()
  add(formData_773736, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_773736.add "EventCategories", EventCategories
  add(formData_773736, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_773736.add "SourceIds", SourceIds
  if Tags != nil:
    formData_773736.add "Tags", Tags
  add(formData_773736, "SubscriptionName", newJString(SubscriptionName))
  add(query_773735, "Action", newJString(Action))
  add(query_773735, "Version", newJString(Version))
  add(formData_773736, "SourceType", newJString(SourceType))
  result = call_773734.call(nil, query_773735, nil, formData_773736, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_773714(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_773715, base: "/",
    url: url_PostCreateEventSubscription_773716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_773692 = ref object of OpenApiRestCall_772581
proc url_GetCreateEventSubscription_773694(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateEventSubscription_773693(path: JsonNode; query: JsonNode;
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
  var valid_773695 = query.getOrDefault("SourceType")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "SourceType", valid_773695
  var valid_773696 = query.getOrDefault("SourceIds")
  valid_773696 = validateParameter(valid_773696, JArray, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "SourceIds", valid_773696
  var valid_773697 = query.getOrDefault("Enabled")
  valid_773697 = validateParameter(valid_773697, JBool, required = false, default = nil)
  if valid_773697 != nil:
    section.add "Enabled", valid_773697
  var valid_773698 = query.getOrDefault("Tags")
  valid_773698 = validateParameter(valid_773698, JArray, required = false,
                                 default = nil)
  if valid_773698 != nil:
    section.add "Tags", valid_773698
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773699 = query.getOrDefault("Action")
  valid_773699 = validateParameter(valid_773699, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_773699 != nil:
    section.add "Action", valid_773699
  var valid_773700 = query.getOrDefault("SnsTopicArn")
  valid_773700 = validateParameter(valid_773700, JString, required = true,
                                 default = nil)
  if valid_773700 != nil:
    section.add "SnsTopicArn", valid_773700
  var valid_773701 = query.getOrDefault("EventCategories")
  valid_773701 = validateParameter(valid_773701, JArray, required = false,
                                 default = nil)
  if valid_773701 != nil:
    section.add "EventCategories", valid_773701
  var valid_773702 = query.getOrDefault("SubscriptionName")
  valid_773702 = validateParameter(valid_773702, JString, required = true,
                                 default = nil)
  if valid_773702 != nil:
    section.add "SubscriptionName", valid_773702
  var valid_773703 = query.getOrDefault("Version")
  valid_773703 = validateParameter(valid_773703, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773703 != nil:
    section.add "Version", valid_773703
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773704 = header.getOrDefault("X-Amz-Date")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "X-Amz-Date", valid_773704
  var valid_773705 = header.getOrDefault("X-Amz-Security-Token")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "X-Amz-Security-Token", valid_773705
  var valid_773706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "X-Amz-Content-Sha256", valid_773706
  var valid_773707 = header.getOrDefault("X-Amz-Algorithm")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Algorithm", valid_773707
  var valid_773708 = header.getOrDefault("X-Amz-Signature")
  valid_773708 = validateParameter(valid_773708, JString, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "X-Amz-Signature", valid_773708
  var valid_773709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773709 = validateParameter(valid_773709, JString, required = false,
                                 default = nil)
  if valid_773709 != nil:
    section.add "X-Amz-SignedHeaders", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-Credential")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-Credential", valid_773710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773711: Call_GetCreateEventSubscription_773692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773711.validator(path, query, header, formData, body)
  let scheme = call_773711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773711.url(scheme.get, call_773711.host, call_773711.base,
                         call_773711.route, valid.getOrDefault("path"))
  result = hook(call_773711, url, valid)

proc call*(call_773712: Call_GetCreateEventSubscription_773692;
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
  var query_773713 = newJObject()
  add(query_773713, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_773713.add "SourceIds", SourceIds
  add(query_773713, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_773713.add "Tags", Tags
  add(query_773713, "Action", newJString(Action))
  add(query_773713, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_773713.add "EventCategories", EventCategories
  add(query_773713, "SubscriptionName", newJString(SubscriptionName))
  add(query_773713, "Version", newJString(Version))
  result = call_773712.call(nil, query_773713, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_773692(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_773693, base: "/",
    url: url_GetCreateEventSubscription_773694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_773757 = ref object of OpenApiRestCall_772581
proc url_PostCreateOptionGroup_773759(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateOptionGroup_773758(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773760 = query.getOrDefault("Action")
  valid_773760 = validateParameter(valid_773760, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_773760 != nil:
    section.add "Action", valid_773760
  var valid_773761 = query.getOrDefault("Version")
  valid_773761 = validateParameter(valid_773761, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773761 != nil:
    section.add "Version", valid_773761
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773762 = header.getOrDefault("X-Amz-Date")
  valid_773762 = validateParameter(valid_773762, JString, required = false,
                                 default = nil)
  if valid_773762 != nil:
    section.add "X-Amz-Date", valid_773762
  var valid_773763 = header.getOrDefault("X-Amz-Security-Token")
  valid_773763 = validateParameter(valid_773763, JString, required = false,
                                 default = nil)
  if valid_773763 != nil:
    section.add "X-Amz-Security-Token", valid_773763
  var valid_773764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "X-Amz-Content-Sha256", valid_773764
  var valid_773765 = header.getOrDefault("X-Amz-Algorithm")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "X-Amz-Algorithm", valid_773765
  var valid_773766 = header.getOrDefault("X-Amz-Signature")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "X-Amz-Signature", valid_773766
  var valid_773767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "X-Amz-SignedHeaders", valid_773767
  var valid_773768 = header.getOrDefault("X-Amz-Credential")
  valid_773768 = validateParameter(valid_773768, JString, required = false,
                                 default = nil)
  if valid_773768 != nil:
    section.add "X-Amz-Credential", valid_773768
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_773769 = formData.getOrDefault("MajorEngineVersion")
  valid_773769 = validateParameter(valid_773769, JString, required = true,
                                 default = nil)
  if valid_773769 != nil:
    section.add "MajorEngineVersion", valid_773769
  var valid_773770 = formData.getOrDefault("OptionGroupName")
  valid_773770 = validateParameter(valid_773770, JString, required = true,
                                 default = nil)
  if valid_773770 != nil:
    section.add "OptionGroupName", valid_773770
  var valid_773771 = formData.getOrDefault("Tags")
  valid_773771 = validateParameter(valid_773771, JArray, required = false,
                                 default = nil)
  if valid_773771 != nil:
    section.add "Tags", valid_773771
  var valid_773772 = formData.getOrDefault("EngineName")
  valid_773772 = validateParameter(valid_773772, JString, required = true,
                                 default = nil)
  if valid_773772 != nil:
    section.add "EngineName", valid_773772
  var valid_773773 = formData.getOrDefault("OptionGroupDescription")
  valid_773773 = validateParameter(valid_773773, JString, required = true,
                                 default = nil)
  if valid_773773 != nil:
    section.add "OptionGroupDescription", valid_773773
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773774: Call_PostCreateOptionGroup_773757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773774.validator(path, query, header, formData, body)
  let scheme = call_773774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773774.url(scheme.get, call_773774.host, call_773774.base,
                         call_773774.route, valid.getOrDefault("path"))
  result = hook(call_773774, url, valid)

proc call*(call_773775: Call_PostCreateOptionGroup_773757;
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
  var query_773776 = newJObject()
  var formData_773777 = newJObject()
  add(formData_773777, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_773777, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_773777.add "Tags", Tags
  add(query_773776, "Action", newJString(Action))
  add(formData_773777, "EngineName", newJString(EngineName))
  add(formData_773777, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_773776, "Version", newJString(Version))
  result = call_773775.call(nil, query_773776, nil, formData_773777, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_773757(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_773758, base: "/",
    url: url_PostCreateOptionGroup_773759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_773737 = ref object of OpenApiRestCall_772581
proc url_GetCreateOptionGroup_773739(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateOptionGroup_773738(path: JsonNode; query: JsonNode;
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
  var valid_773740 = query.getOrDefault("OptionGroupName")
  valid_773740 = validateParameter(valid_773740, JString, required = true,
                                 default = nil)
  if valid_773740 != nil:
    section.add "OptionGroupName", valid_773740
  var valid_773741 = query.getOrDefault("Tags")
  valid_773741 = validateParameter(valid_773741, JArray, required = false,
                                 default = nil)
  if valid_773741 != nil:
    section.add "Tags", valid_773741
  var valid_773742 = query.getOrDefault("OptionGroupDescription")
  valid_773742 = validateParameter(valid_773742, JString, required = true,
                                 default = nil)
  if valid_773742 != nil:
    section.add "OptionGroupDescription", valid_773742
  var valid_773743 = query.getOrDefault("Action")
  valid_773743 = validateParameter(valid_773743, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_773743 != nil:
    section.add "Action", valid_773743
  var valid_773744 = query.getOrDefault("Version")
  valid_773744 = validateParameter(valid_773744, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773744 != nil:
    section.add "Version", valid_773744
  var valid_773745 = query.getOrDefault("EngineName")
  valid_773745 = validateParameter(valid_773745, JString, required = true,
                                 default = nil)
  if valid_773745 != nil:
    section.add "EngineName", valid_773745
  var valid_773746 = query.getOrDefault("MajorEngineVersion")
  valid_773746 = validateParameter(valid_773746, JString, required = true,
                                 default = nil)
  if valid_773746 != nil:
    section.add "MajorEngineVersion", valid_773746
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773747 = header.getOrDefault("X-Amz-Date")
  valid_773747 = validateParameter(valid_773747, JString, required = false,
                                 default = nil)
  if valid_773747 != nil:
    section.add "X-Amz-Date", valid_773747
  var valid_773748 = header.getOrDefault("X-Amz-Security-Token")
  valid_773748 = validateParameter(valid_773748, JString, required = false,
                                 default = nil)
  if valid_773748 != nil:
    section.add "X-Amz-Security-Token", valid_773748
  var valid_773749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "X-Amz-Content-Sha256", valid_773749
  var valid_773750 = header.getOrDefault("X-Amz-Algorithm")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "X-Amz-Algorithm", valid_773750
  var valid_773751 = header.getOrDefault("X-Amz-Signature")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-Signature", valid_773751
  var valid_773752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-SignedHeaders", valid_773752
  var valid_773753 = header.getOrDefault("X-Amz-Credential")
  valid_773753 = validateParameter(valid_773753, JString, required = false,
                                 default = nil)
  if valid_773753 != nil:
    section.add "X-Amz-Credential", valid_773753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773754: Call_GetCreateOptionGroup_773737; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773754.validator(path, query, header, formData, body)
  let scheme = call_773754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773754.url(scheme.get, call_773754.host, call_773754.base,
                         call_773754.route, valid.getOrDefault("path"))
  result = hook(call_773754, url, valid)

proc call*(call_773755: Call_GetCreateOptionGroup_773737; OptionGroupName: string;
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
  var query_773756 = newJObject()
  add(query_773756, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_773756.add "Tags", Tags
  add(query_773756, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_773756, "Action", newJString(Action))
  add(query_773756, "Version", newJString(Version))
  add(query_773756, "EngineName", newJString(EngineName))
  add(query_773756, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_773755.call(nil, query_773756, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_773737(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_773738, base: "/",
    url: url_GetCreateOptionGroup_773739, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_773796 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBInstance_773798(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBInstance_773797(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773799 = query.getOrDefault("Action")
  valid_773799 = validateParameter(valid_773799, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_773799 != nil:
    section.add "Action", valid_773799
  var valid_773800 = query.getOrDefault("Version")
  valid_773800 = validateParameter(valid_773800, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773800 != nil:
    section.add "Version", valid_773800
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773801 = header.getOrDefault("X-Amz-Date")
  valid_773801 = validateParameter(valid_773801, JString, required = false,
                                 default = nil)
  if valid_773801 != nil:
    section.add "X-Amz-Date", valid_773801
  var valid_773802 = header.getOrDefault("X-Amz-Security-Token")
  valid_773802 = validateParameter(valid_773802, JString, required = false,
                                 default = nil)
  if valid_773802 != nil:
    section.add "X-Amz-Security-Token", valid_773802
  var valid_773803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773803 = validateParameter(valid_773803, JString, required = false,
                                 default = nil)
  if valid_773803 != nil:
    section.add "X-Amz-Content-Sha256", valid_773803
  var valid_773804 = header.getOrDefault("X-Amz-Algorithm")
  valid_773804 = validateParameter(valid_773804, JString, required = false,
                                 default = nil)
  if valid_773804 != nil:
    section.add "X-Amz-Algorithm", valid_773804
  var valid_773805 = header.getOrDefault("X-Amz-Signature")
  valid_773805 = validateParameter(valid_773805, JString, required = false,
                                 default = nil)
  if valid_773805 != nil:
    section.add "X-Amz-Signature", valid_773805
  var valid_773806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773806 = validateParameter(valid_773806, JString, required = false,
                                 default = nil)
  if valid_773806 != nil:
    section.add "X-Amz-SignedHeaders", valid_773806
  var valid_773807 = header.getOrDefault("X-Amz-Credential")
  valid_773807 = validateParameter(valid_773807, JString, required = false,
                                 default = nil)
  if valid_773807 != nil:
    section.add "X-Amz-Credential", valid_773807
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_773808 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773808 = validateParameter(valid_773808, JString, required = true,
                                 default = nil)
  if valid_773808 != nil:
    section.add "DBInstanceIdentifier", valid_773808
  var valid_773809 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_773809 = validateParameter(valid_773809, JString, required = false,
                                 default = nil)
  if valid_773809 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_773809
  var valid_773810 = formData.getOrDefault("SkipFinalSnapshot")
  valid_773810 = validateParameter(valid_773810, JBool, required = false, default = nil)
  if valid_773810 != nil:
    section.add "SkipFinalSnapshot", valid_773810
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773811: Call_PostDeleteDBInstance_773796; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773811.validator(path, query, header, formData, body)
  let scheme = call_773811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773811.url(scheme.get, call_773811.host, call_773811.base,
                         call_773811.route, valid.getOrDefault("path"))
  result = hook(call_773811, url, valid)

proc call*(call_773812: Call_PostDeleteDBInstance_773796;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2014-09-01";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_773813 = newJObject()
  var formData_773814 = newJObject()
  add(formData_773814, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_773814, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_773813, "Action", newJString(Action))
  add(query_773813, "Version", newJString(Version))
  add(formData_773814, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_773812.call(nil, query_773813, nil, formData_773814, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_773796(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_773797, base: "/",
    url: url_PostDeleteDBInstance_773798, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_773778 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBInstance_773780(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBInstance_773779(path: JsonNode; query: JsonNode;
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
  var valid_773781 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_773781 = validateParameter(valid_773781, JString, required = false,
                                 default = nil)
  if valid_773781 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_773781
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773782 = query.getOrDefault("Action")
  valid_773782 = validateParameter(valid_773782, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_773782 != nil:
    section.add "Action", valid_773782
  var valid_773783 = query.getOrDefault("SkipFinalSnapshot")
  valid_773783 = validateParameter(valid_773783, JBool, required = false, default = nil)
  if valid_773783 != nil:
    section.add "SkipFinalSnapshot", valid_773783
  var valid_773784 = query.getOrDefault("Version")
  valid_773784 = validateParameter(valid_773784, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773784 != nil:
    section.add "Version", valid_773784
  var valid_773785 = query.getOrDefault("DBInstanceIdentifier")
  valid_773785 = validateParameter(valid_773785, JString, required = true,
                                 default = nil)
  if valid_773785 != nil:
    section.add "DBInstanceIdentifier", valid_773785
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773786 = header.getOrDefault("X-Amz-Date")
  valid_773786 = validateParameter(valid_773786, JString, required = false,
                                 default = nil)
  if valid_773786 != nil:
    section.add "X-Amz-Date", valid_773786
  var valid_773787 = header.getOrDefault("X-Amz-Security-Token")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-Security-Token", valid_773787
  var valid_773788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773788 = validateParameter(valid_773788, JString, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "X-Amz-Content-Sha256", valid_773788
  var valid_773789 = header.getOrDefault("X-Amz-Algorithm")
  valid_773789 = validateParameter(valid_773789, JString, required = false,
                                 default = nil)
  if valid_773789 != nil:
    section.add "X-Amz-Algorithm", valid_773789
  var valid_773790 = header.getOrDefault("X-Amz-Signature")
  valid_773790 = validateParameter(valid_773790, JString, required = false,
                                 default = nil)
  if valid_773790 != nil:
    section.add "X-Amz-Signature", valid_773790
  var valid_773791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773791 = validateParameter(valid_773791, JString, required = false,
                                 default = nil)
  if valid_773791 != nil:
    section.add "X-Amz-SignedHeaders", valid_773791
  var valid_773792 = header.getOrDefault("X-Amz-Credential")
  valid_773792 = validateParameter(valid_773792, JString, required = false,
                                 default = nil)
  if valid_773792 != nil:
    section.add "X-Amz-Credential", valid_773792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773793: Call_GetDeleteDBInstance_773778; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773793.validator(path, query, header, formData, body)
  let scheme = call_773793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773793.url(scheme.get, call_773793.host, call_773793.base,
                         call_773793.route, valid.getOrDefault("path"))
  result = hook(call_773793, url, valid)

proc call*(call_773794: Call_GetDeleteDBInstance_773778;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_773795 = newJObject()
  add(query_773795, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_773795, "Action", newJString(Action))
  add(query_773795, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_773795, "Version", newJString(Version))
  add(query_773795, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_773794.call(nil, query_773795, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_773778(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_773779, base: "/",
    url: url_GetDeleteDBInstance_773780, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_773831 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBParameterGroup_773833(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBParameterGroup_773832(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773834 = query.getOrDefault("Action")
  valid_773834 = validateParameter(valid_773834, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_773834 != nil:
    section.add "Action", valid_773834
  var valid_773835 = query.getOrDefault("Version")
  valid_773835 = validateParameter(valid_773835, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773835 != nil:
    section.add "Version", valid_773835
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773836 = header.getOrDefault("X-Amz-Date")
  valid_773836 = validateParameter(valid_773836, JString, required = false,
                                 default = nil)
  if valid_773836 != nil:
    section.add "X-Amz-Date", valid_773836
  var valid_773837 = header.getOrDefault("X-Amz-Security-Token")
  valid_773837 = validateParameter(valid_773837, JString, required = false,
                                 default = nil)
  if valid_773837 != nil:
    section.add "X-Amz-Security-Token", valid_773837
  var valid_773838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773838 = validateParameter(valid_773838, JString, required = false,
                                 default = nil)
  if valid_773838 != nil:
    section.add "X-Amz-Content-Sha256", valid_773838
  var valid_773839 = header.getOrDefault("X-Amz-Algorithm")
  valid_773839 = validateParameter(valid_773839, JString, required = false,
                                 default = nil)
  if valid_773839 != nil:
    section.add "X-Amz-Algorithm", valid_773839
  var valid_773840 = header.getOrDefault("X-Amz-Signature")
  valid_773840 = validateParameter(valid_773840, JString, required = false,
                                 default = nil)
  if valid_773840 != nil:
    section.add "X-Amz-Signature", valid_773840
  var valid_773841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773841 = validateParameter(valid_773841, JString, required = false,
                                 default = nil)
  if valid_773841 != nil:
    section.add "X-Amz-SignedHeaders", valid_773841
  var valid_773842 = header.getOrDefault("X-Amz-Credential")
  valid_773842 = validateParameter(valid_773842, JString, required = false,
                                 default = nil)
  if valid_773842 != nil:
    section.add "X-Amz-Credential", valid_773842
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_773843 = formData.getOrDefault("DBParameterGroupName")
  valid_773843 = validateParameter(valid_773843, JString, required = true,
                                 default = nil)
  if valid_773843 != nil:
    section.add "DBParameterGroupName", valid_773843
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773844: Call_PostDeleteDBParameterGroup_773831; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773844.validator(path, query, header, formData, body)
  let scheme = call_773844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773844.url(scheme.get, call_773844.host, call_773844.base,
                         call_773844.route, valid.getOrDefault("path"))
  result = hook(call_773844, url, valid)

proc call*(call_773845: Call_PostDeleteDBParameterGroup_773831;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773846 = newJObject()
  var formData_773847 = newJObject()
  add(formData_773847, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_773846, "Action", newJString(Action))
  add(query_773846, "Version", newJString(Version))
  result = call_773845.call(nil, query_773846, nil, formData_773847, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_773831(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_773832, base: "/",
    url: url_PostDeleteDBParameterGroup_773833,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_773815 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBParameterGroup_773817(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBParameterGroup_773816(path: JsonNode; query: JsonNode;
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
  var valid_773818 = query.getOrDefault("DBParameterGroupName")
  valid_773818 = validateParameter(valid_773818, JString, required = true,
                                 default = nil)
  if valid_773818 != nil:
    section.add "DBParameterGroupName", valid_773818
  var valid_773819 = query.getOrDefault("Action")
  valid_773819 = validateParameter(valid_773819, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_773819 != nil:
    section.add "Action", valid_773819
  var valid_773820 = query.getOrDefault("Version")
  valid_773820 = validateParameter(valid_773820, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773820 != nil:
    section.add "Version", valid_773820
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773821 = header.getOrDefault("X-Amz-Date")
  valid_773821 = validateParameter(valid_773821, JString, required = false,
                                 default = nil)
  if valid_773821 != nil:
    section.add "X-Amz-Date", valid_773821
  var valid_773822 = header.getOrDefault("X-Amz-Security-Token")
  valid_773822 = validateParameter(valid_773822, JString, required = false,
                                 default = nil)
  if valid_773822 != nil:
    section.add "X-Amz-Security-Token", valid_773822
  var valid_773823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773823 = validateParameter(valid_773823, JString, required = false,
                                 default = nil)
  if valid_773823 != nil:
    section.add "X-Amz-Content-Sha256", valid_773823
  var valid_773824 = header.getOrDefault("X-Amz-Algorithm")
  valid_773824 = validateParameter(valid_773824, JString, required = false,
                                 default = nil)
  if valid_773824 != nil:
    section.add "X-Amz-Algorithm", valid_773824
  var valid_773825 = header.getOrDefault("X-Amz-Signature")
  valid_773825 = validateParameter(valid_773825, JString, required = false,
                                 default = nil)
  if valid_773825 != nil:
    section.add "X-Amz-Signature", valid_773825
  var valid_773826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773826 = validateParameter(valid_773826, JString, required = false,
                                 default = nil)
  if valid_773826 != nil:
    section.add "X-Amz-SignedHeaders", valid_773826
  var valid_773827 = header.getOrDefault("X-Amz-Credential")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "X-Amz-Credential", valid_773827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773828: Call_GetDeleteDBParameterGroup_773815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773828.validator(path, query, header, formData, body)
  let scheme = call_773828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773828.url(scheme.get, call_773828.host, call_773828.base,
                         call_773828.route, valid.getOrDefault("path"))
  result = hook(call_773828, url, valid)

proc call*(call_773829: Call_GetDeleteDBParameterGroup_773815;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773830 = newJObject()
  add(query_773830, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_773830, "Action", newJString(Action))
  add(query_773830, "Version", newJString(Version))
  result = call_773829.call(nil, query_773830, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_773815(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_773816, base: "/",
    url: url_GetDeleteDBParameterGroup_773817,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_773864 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBSecurityGroup_773866(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSecurityGroup_773865(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773867 = query.getOrDefault("Action")
  valid_773867 = validateParameter(valid_773867, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_773867 != nil:
    section.add "Action", valid_773867
  var valid_773868 = query.getOrDefault("Version")
  valid_773868 = validateParameter(valid_773868, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773868 != nil:
    section.add "Version", valid_773868
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773869 = header.getOrDefault("X-Amz-Date")
  valid_773869 = validateParameter(valid_773869, JString, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "X-Amz-Date", valid_773869
  var valid_773870 = header.getOrDefault("X-Amz-Security-Token")
  valid_773870 = validateParameter(valid_773870, JString, required = false,
                                 default = nil)
  if valid_773870 != nil:
    section.add "X-Amz-Security-Token", valid_773870
  var valid_773871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773871 = validateParameter(valid_773871, JString, required = false,
                                 default = nil)
  if valid_773871 != nil:
    section.add "X-Amz-Content-Sha256", valid_773871
  var valid_773872 = header.getOrDefault("X-Amz-Algorithm")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-Algorithm", valid_773872
  var valid_773873 = header.getOrDefault("X-Amz-Signature")
  valid_773873 = validateParameter(valid_773873, JString, required = false,
                                 default = nil)
  if valid_773873 != nil:
    section.add "X-Amz-Signature", valid_773873
  var valid_773874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773874 = validateParameter(valid_773874, JString, required = false,
                                 default = nil)
  if valid_773874 != nil:
    section.add "X-Amz-SignedHeaders", valid_773874
  var valid_773875 = header.getOrDefault("X-Amz-Credential")
  valid_773875 = validateParameter(valid_773875, JString, required = false,
                                 default = nil)
  if valid_773875 != nil:
    section.add "X-Amz-Credential", valid_773875
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_773876 = formData.getOrDefault("DBSecurityGroupName")
  valid_773876 = validateParameter(valid_773876, JString, required = true,
                                 default = nil)
  if valid_773876 != nil:
    section.add "DBSecurityGroupName", valid_773876
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773877: Call_PostDeleteDBSecurityGroup_773864; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773877.validator(path, query, header, formData, body)
  let scheme = call_773877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773877.url(scheme.get, call_773877.host, call_773877.base,
                         call_773877.route, valid.getOrDefault("path"))
  result = hook(call_773877, url, valid)

proc call*(call_773878: Call_PostDeleteDBSecurityGroup_773864;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773879 = newJObject()
  var formData_773880 = newJObject()
  add(formData_773880, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_773879, "Action", newJString(Action))
  add(query_773879, "Version", newJString(Version))
  result = call_773878.call(nil, query_773879, nil, formData_773880, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_773864(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_773865, base: "/",
    url: url_PostDeleteDBSecurityGroup_773866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_773848 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBSecurityGroup_773850(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSecurityGroup_773849(path: JsonNode; query: JsonNode;
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
  var valid_773851 = query.getOrDefault("DBSecurityGroupName")
  valid_773851 = validateParameter(valid_773851, JString, required = true,
                                 default = nil)
  if valid_773851 != nil:
    section.add "DBSecurityGroupName", valid_773851
  var valid_773852 = query.getOrDefault("Action")
  valid_773852 = validateParameter(valid_773852, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_773852 != nil:
    section.add "Action", valid_773852
  var valid_773853 = query.getOrDefault("Version")
  valid_773853 = validateParameter(valid_773853, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773853 != nil:
    section.add "Version", valid_773853
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773854 = header.getOrDefault("X-Amz-Date")
  valid_773854 = validateParameter(valid_773854, JString, required = false,
                                 default = nil)
  if valid_773854 != nil:
    section.add "X-Amz-Date", valid_773854
  var valid_773855 = header.getOrDefault("X-Amz-Security-Token")
  valid_773855 = validateParameter(valid_773855, JString, required = false,
                                 default = nil)
  if valid_773855 != nil:
    section.add "X-Amz-Security-Token", valid_773855
  var valid_773856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773856 = validateParameter(valid_773856, JString, required = false,
                                 default = nil)
  if valid_773856 != nil:
    section.add "X-Amz-Content-Sha256", valid_773856
  var valid_773857 = header.getOrDefault("X-Amz-Algorithm")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-Algorithm", valid_773857
  var valid_773858 = header.getOrDefault("X-Amz-Signature")
  valid_773858 = validateParameter(valid_773858, JString, required = false,
                                 default = nil)
  if valid_773858 != nil:
    section.add "X-Amz-Signature", valid_773858
  var valid_773859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773859 = validateParameter(valid_773859, JString, required = false,
                                 default = nil)
  if valid_773859 != nil:
    section.add "X-Amz-SignedHeaders", valid_773859
  var valid_773860 = header.getOrDefault("X-Amz-Credential")
  valid_773860 = validateParameter(valid_773860, JString, required = false,
                                 default = nil)
  if valid_773860 != nil:
    section.add "X-Amz-Credential", valid_773860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773861: Call_GetDeleteDBSecurityGroup_773848; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773861.validator(path, query, header, formData, body)
  let scheme = call_773861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773861.url(scheme.get, call_773861.host, call_773861.base,
                         call_773861.route, valid.getOrDefault("path"))
  result = hook(call_773861, url, valid)

proc call*(call_773862: Call_GetDeleteDBSecurityGroup_773848;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773863 = newJObject()
  add(query_773863, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_773863, "Action", newJString(Action))
  add(query_773863, "Version", newJString(Version))
  result = call_773862.call(nil, query_773863, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_773848(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_773849, base: "/",
    url: url_GetDeleteDBSecurityGroup_773850, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_773897 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBSnapshot_773899(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSnapshot_773898(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773900 = query.getOrDefault("Action")
  valid_773900 = validateParameter(valid_773900, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_773900 != nil:
    section.add "Action", valid_773900
  var valid_773901 = query.getOrDefault("Version")
  valid_773901 = validateParameter(valid_773901, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773901 != nil:
    section.add "Version", valid_773901
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773902 = header.getOrDefault("X-Amz-Date")
  valid_773902 = validateParameter(valid_773902, JString, required = false,
                                 default = nil)
  if valid_773902 != nil:
    section.add "X-Amz-Date", valid_773902
  var valid_773903 = header.getOrDefault("X-Amz-Security-Token")
  valid_773903 = validateParameter(valid_773903, JString, required = false,
                                 default = nil)
  if valid_773903 != nil:
    section.add "X-Amz-Security-Token", valid_773903
  var valid_773904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773904 = validateParameter(valid_773904, JString, required = false,
                                 default = nil)
  if valid_773904 != nil:
    section.add "X-Amz-Content-Sha256", valid_773904
  var valid_773905 = header.getOrDefault("X-Amz-Algorithm")
  valid_773905 = validateParameter(valid_773905, JString, required = false,
                                 default = nil)
  if valid_773905 != nil:
    section.add "X-Amz-Algorithm", valid_773905
  var valid_773906 = header.getOrDefault("X-Amz-Signature")
  valid_773906 = validateParameter(valid_773906, JString, required = false,
                                 default = nil)
  if valid_773906 != nil:
    section.add "X-Amz-Signature", valid_773906
  var valid_773907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773907 = validateParameter(valid_773907, JString, required = false,
                                 default = nil)
  if valid_773907 != nil:
    section.add "X-Amz-SignedHeaders", valid_773907
  var valid_773908 = header.getOrDefault("X-Amz-Credential")
  valid_773908 = validateParameter(valid_773908, JString, required = false,
                                 default = nil)
  if valid_773908 != nil:
    section.add "X-Amz-Credential", valid_773908
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_773909 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_773909 = validateParameter(valid_773909, JString, required = true,
                                 default = nil)
  if valid_773909 != nil:
    section.add "DBSnapshotIdentifier", valid_773909
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773910: Call_PostDeleteDBSnapshot_773897; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773910.validator(path, query, header, formData, body)
  let scheme = call_773910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773910.url(scheme.get, call_773910.host, call_773910.base,
                         call_773910.route, valid.getOrDefault("path"))
  result = hook(call_773910, url, valid)

proc call*(call_773911: Call_PostDeleteDBSnapshot_773897;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773912 = newJObject()
  var formData_773913 = newJObject()
  add(formData_773913, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_773912, "Action", newJString(Action))
  add(query_773912, "Version", newJString(Version))
  result = call_773911.call(nil, query_773912, nil, formData_773913, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_773897(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_773898, base: "/",
    url: url_PostDeleteDBSnapshot_773899, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_773881 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBSnapshot_773883(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSnapshot_773882(path: JsonNode; query: JsonNode;
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
  var valid_773884 = query.getOrDefault("Action")
  valid_773884 = validateParameter(valid_773884, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_773884 != nil:
    section.add "Action", valid_773884
  var valid_773885 = query.getOrDefault("Version")
  valid_773885 = validateParameter(valid_773885, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773885 != nil:
    section.add "Version", valid_773885
  var valid_773886 = query.getOrDefault("DBSnapshotIdentifier")
  valid_773886 = validateParameter(valid_773886, JString, required = true,
                                 default = nil)
  if valid_773886 != nil:
    section.add "DBSnapshotIdentifier", valid_773886
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773887 = header.getOrDefault("X-Amz-Date")
  valid_773887 = validateParameter(valid_773887, JString, required = false,
                                 default = nil)
  if valid_773887 != nil:
    section.add "X-Amz-Date", valid_773887
  var valid_773888 = header.getOrDefault("X-Amz-Security-Token")
  valid_773888 = validateParameter(valid_773888, JString, required = false,
                                 default = nil)
  if valid_773888 != nil:
    section.add "X-Amz-Security-Token", valid_773888
  var valid_773889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773889 = validateParameter(valid_773889, JString, required = false,
                                 default = nil)
  if valid_773889 != nil:
    section.add "X-Amz-Content-Sha256", valid_773889
  var valid_773890 = header.getOrDefault("X-Amz-Algorithm")
  valid_773890 = validateParameter(valid_773890, JString, required = false,
                                 default = nil)
  if valid_773890 != nil:
    section.add "X-Amz-Algorithm", valid_773890
  var valid_773891 = header.getOrDefault("X-Amz-Signature")
  valid_773891 = validateParameter(valid_773891, JString, required = false,
                                 default = nil)
  if valid_773891 != nil:
    section.add "X-Amz-Signature", valid_773891
  var valid_773892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773892 = validateParameter(valid_773892, JString, required = false,
                                 default = nil)
  if valid_773892 != nil:
    section.add "X-Amz-SignedHeaders", valid_773892
  var valid_773893 = header.getOrDefault("X-Amz-Credential")
  valid_773893 = validateParameter(valid_773893, JString, required = false,
                                 default = nil)
  if valid_773893 != nil:
    section.add "X-Amz-Credential", valid_773893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773894: Call_GetDeleteDBSnapshot_773881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773894.validator(path, query, header, formData, body)
  let scheme = call_773894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773894.url(scheme.get, call_773894.host, call_773894.base,
                         call_773894.route, valid.getOrDefault("path"))
  result = hook(call_773894, url, valid)

proc call*(call_773895: Call_GetDeleteDBSnapshot_773881;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_773896 = newJObject()
  add(query_773896, "Action", newJString(Action))
  add(query_773896, "Version", newJString(Version))
  add(query_773896, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_773895.call(nil, query_773896, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_773881(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_773882, base: "/",
    url: url_GetDeleteDBSnapshot_773883, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_773930 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBSubnetGroup_773932(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSubnetGroup_773931(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773933 = query.getOrDefault("Action")
  valid_773933 = validateParameter(valid_773933, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_773933 != nil:
    section.add "Action", valid_773933
  var valid_773934 = query.getOrDefault("Version")
  valid_773934 = validateParameter(valid_773934, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773934 != nil:
    section.add "Version", valid_773934
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773935 = header.getOrDefault("X-Amz-Date")
  valid_773935 = validateParameter(valid_773935, JString, required = false,
                                 default = nil)
  if valid_773935 != nil:
    section.add "X-Amz-Date", valid_773935
  var valid_773936 = header.getOrDefault("X-Amz-Security-Token")
  valid_773936 = validateParameter(valid_773936, JString, required = false,
                                 default = nil)
  if valid_773936 != nil:
    section.add "X-Amz-Security-Token", valid_773936
  var valid_773937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773937 = validateParameter(valid_773937, JString, required = false,
                                 default = nil)
  if valid_773937 != nil:
    section.add "X-Amz-Content-Sha256", valid_773937
  var valid_773938 = header.getOrDefault("X-Amz-Algorithm")
  valid_773938 = validateParameter(valid_773938, JString, required = false,
                                 default = nil)
  if valid_773938 != nil:
    section.add "X-Amz-Algorithm", valid_773938
  var valid_773939 = header.getOrDefault("X-Amz-Signature")
  valid_773939 = validateParameter(valid_773939, JString, required = false,
                                 default = nil)
  if valid_773939 != nil:
    section.add "X-Amz-Signature", valid_773939
  var valid_773940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773940 = validateParameter(valid_773940, JString, required = false,
                                 default = nil)
  if valid_773940 != nil:
    section.add "X-Amz-SignedHeaders", valid_773940
  var valid_773941 = header.getOrDefault("X-Amz-Credential")
  valid_773941 = validateParameter(valid_773941, JString, required = false,
                                 default = nil)
  if valid_773941 != nil:
    section.add "X-Amz-Credential", valid_773941
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_773942 = formData.getOrDefault("DBSubnetGroupName")
  valid_773942 = validateParameter(valid_773942, JString, required = true,
                                 default = nil)
  if valid_773942 != nil:
    section.add "DBSubnetGroupName", valid_773942
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773943: Call_PostDeleteDBSubnetGroup_773930; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773943.validator(path, query, header, formData, body)
  let scheme = call_773943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773943.url(scheme.get, call_773943.host, call_773943.base,
                         call_773943.route, valid.getOrDefault("path"))
  result = hook(call_773943, url, valid)

proc call*(call_773944: Call_PostDeleteDBSubnetGroup_773930;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773945 = newJObject()
  var formData_773946 = newJObject()
  add(formData_773946, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773945, "Action", newJString(Action))
  add(query_773945, "Version", newJString(Version))
  result = call_773944.call(nil, query_773945, nil, formData_773946, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_773930(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_773931, base: "/",
    url: url_PostDeleteDBSubnetGroup_773932, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_773914 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBSubnetGroup_773916(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSubnetGroup_773915(path: JsonNode; query: JsonNode;
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
  var valid_773917 = query.getOrDefault("Action")
  valid_773917 = validateParameter(valid_773917, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_773917 != nil:
    section.add "Action", valid_773917
  var valid_773918 = query.getOrDefault("DBSubnetGroupName")
  valid_773918 = validateParameter(valid_773918, JString, required = true,
                                 default = nil)
  if valid_773918 != nil:
    section.add "DBSubnetGroupName", valid_773918
  var valid_773919 = query.getOrDefault("Version")
  valid_773919 = validateParameter(valid_773919, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773919 != nil:
    section.add "Version", valid_773919
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773920 = header.getOrDefault("X-Amz-Date")
  valid_773920 = validateParameter(valid_773920, JString, required = false,
                                 default = nil)
  if valid_773920 != nil:
    section.add "X-Amz-Date", valid_773920
  var valid_773921 = header.getOrDefault("X-Amz-Security-Token")
  valid_773921 = validateParameter(valid_773921, JString, required = false,
                                 default = nil)
  if valid_773921 != nil:
    section.add "X-Amz-Security-Token", valid_773921
  var valid_773922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773922 = validateParameter(valid_773922, JString, required = false,
                                 default = nil)
  if valid_773922 != nil:
    section.add "X-Amz-Content-Sha256", valid_773922
  var valid_773923 = header.getOrDefault("X-Amz-Algorithm")
  valid_773923 = validateParameter(valid_773923, JString, required = false,
                                 default = nil)
  if valid_773923 != nil:
    section.add "X-Amz-Algorithm", valid_773923
  var valid_773924 = header.getOrDefault("X-Amz-Signature")
  valid_773924 = validateParameter(valid_773924, JString, required = false,
                                 default = nil)
  if valid_773924 != nil:
    section.add "X-Amz-Signature", valid_773924
  var valid_773925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773925 = validateParameter(valid_773925, JString, required = false,
                                 default = nil)
  if valid_773925 != nil:
    section.add "X-Amz-SignedHeaders", valid_773925
  var valid_773926 = header.getOrDefault("X-Amz-Credential")
  valid_773926 = validateParameter(valid_773926, JString, required = false,
                                 default = nil)
  if valid_773926 != nil:
    section.add "X-Amz-Credential", valid_773926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773927: Call_GetDeleteDBSubnetGroup_773914; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773927.validator(path, query, header, formData, body)
  let scheme = call_773927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773927.url(scheme.get, call_773927.host, call_773927.base,
                         call_773927.route, valid.getOrDefault("path"))
  result = hook(call_773927, url, valid)

proc call*(call_773928: Call_GetDeleteDBSubnetGroup_773914;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_773929 = newJObject()
  add(query_773929, "Action", newJString(Action))
  add(query_773929, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773929, "Version", newJString(Version))
  result = call_773928.call(nil, query_773929, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_773914(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_773915, base: "/",
    url: url_GetDeleteDBSubnetGroup_773916, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_773963 = ref object of OpenApiRestCall_772581
proc url_PostDeleteEventSubscription_773965(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEventSubscription_773964(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773966 = query.getOrDefault("Action")
  valid_773966 = validateParameter(valid_773966, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_773966 != nil:
    section.add "Action", valid_773966
  var valid_773967 = query.getOrDefault("Version")
  valid_773967 = validateParameter(valid_773967, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773967 != nil:
    section.add "Version", valid_773967
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773968 = header.getOrDefault("X-Amz-Date")
  valid_773968 = validateParameter(valid_773968, JString, required = false,
                                 default = nil)
  if valid_773968 != nil:
    section.add "X-Amz-Date", valid_773968
  var valid_773969 = header.getOrDefault("X-Amz-Security-Token")
  valid_773969 = validateParameter(valid_773969, JString, required = false,
                                 default = nil)
  if valid_773969 != nil:
    section.add "X-Amz-Security-Token", valid_773969
  var valid_773970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773970 = validateParameter(valid_773970, JString, required = false,
                                 default = nil)
  if valid_773970 != nil:
    section.add "X-Amz-Content-Sha256", valid_773970
  var valid_773971 = header.getOrDefault("X-Amz-Algorithm")
  valid_773971 = validateParameter(valid_773971, JString, required = false,
                                 default = nil)
  if valid_773971 != nil:
    section.add "X-Amz-Algorithm", valid_773971
  var valid_773972 = header.getOrDefault("X-Amz-Signature")
  valid_773972 = validateParameter(valid_773972, JString, required = false,
                                 default = nil)
  if valid_773972 != nil:
    section.add "X-Amz-Signature", valid_773972
  var valid_773973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773973 = validateParameter(valid_773973, JString, required = false,
                                 default = nil)
  if valid_773973 != nil:
    section.add "X-Amz-SignedHeaders", valid_773973
  var valid_773974 = header.getOrDefault("X-Amz-Credential")
  valid_773974 = validateParameter(valid_773974, JString, required = false,
                                 default = nil)
  if valid_773974 != nil:
    section.add "X-Amz-Credential", valid_773974
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_773975 = formData.getOrDefault("SubscriptionName")
  valid_773975 = validateParameter(valid_773975, JString, required = true,
                                 default = nil)
  if valid_773975 != nil:
    section.add "SubscriptionName", valid_773975
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773976: Call_PostDeleteEventSubscription_773963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773976.validator(path, query, header, formData, body)
  let scheme = call_773976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773976.url(scheme.get, call_773976.host, call_773976.base,
                         call_773976.route, valid.getOrDefault("path"))
  result = hook(call_773976, url, valid)

proc call*(call_773977: Call_PostDeleteEventSubscription_773963;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773978 = newJObject()
  var formData_773979 = newJObject()
  add(formData_773979, "SubscriptionName", newJString(SubscriptionName))
  add(query_773978, "Action", newJString(Action))
  add(query_773978, "Version", newJString(Version))
  result = call_773977.call(nil, query_773978, nil, formData_773979, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_773963(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_773964, base: "/",
    url: url_PostDeleteEventSubscription_773965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_773947 = ref object of OpenApiRestCall_772581
proc url_GetDeleteEventSubscription_773949(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEventSubscription_773948(path: JsonNode; query: JsonNode;
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
  var valid_773950 = query.getOrDefault("Action")
  valid_773950 = validateParameter(valid_773950, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_773950 != nil:
    section.add "Action", valid_773950
  var valid_773951 = query.getOrDefault("SubscriptionName")
  valid_773951 = validateParameter(valid_773951, JString, required = true,
                                 default = nil)
  if valid_773951 != nil:
    section.add "SubscriptionName", valid_773951
  var valid_773952 = query.getOrDefault("Version")
  valid_773952 = validateParameter(valid_773952, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773952 != nil:
    section.add "Version", valid_773952
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773953 = header.getOrDefault("X-Amz-Date")
  valid_773953 = validateParameter(valid_773953, JString, required = false,
                                 default = nil)
  if valid_773953 != nil:
    section.add "X-Amz-Date", valid_773953
  var valid_773954 = header.getOrDefault("X-Amz-Security-Token")
  valid_773954 = validateParameter(valid_773954, JString, required = false,
                                 default = nil)
  if valid_773954 != nil:
    section.add "X-Amz-Security-Token", valid_773954
  var valid_773955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773955 = validateParameter(valid_773955, JString, required = false,
                                 default = nil)
  if valid_773955 != nil:
    section.add "X-Amz-Content-Sha256", valid_773955
  var valid_773956 = header.getOrDefault("X-Amz-Algorithm")
  valid_773956 = validateParameter(valid_773956, JString, required = false,
                                 default = nil)
  if valid_773956 != nil:
    section.add "X-Amz-Algorithm", valid_773956
  var valid_773957 = header.getOrDefault("X-Amz-Signature")
  valid_773957 = validateParameter(valid_773957, JString, required = false,
                                 default = nil)
  if valid_773957 != nil:
    section.add "X-Amz-Signature", valid_773957
  var valid_773958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773958 = validateParameter(valid_773958, JString, required = false,
                                 default = nil)
  if valid_773958 != nil:
    section.add "X-Amz-SignedHeaders", valid_773958
  var valid_773959 = header.getOrDefault("X-Amz-Credential")
  valid_773959 = validateParameter(valid_773959, JString, required = false,
                                 default = nil)
  if valid_773959 != nil:
    section.add "X-Amz-Credential", valid_773959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773960: Call_GetDeleteEventSubscription_773947; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773960.validator(path, query, header, formData, body)
  let scheme = call_773960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773960.url(scheme.get, call_773960.host, call_773960.base,
                         call_773960.route, valid.getOrDefault("path"))
  result = hook(call_773960, url, valid)

proc call*(call_773961: Call_GetDeleteEventSubscription_773947;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_773962 = newJObject()
  add(query_773962, "Action", newJString(Action))
  add(query_773962, "SubscriptionName", newJString(SubscriptionName))
  add(query_773962, "Version", newJString(Version))
  result = call_773961.call(nil, query_773962, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_773947(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_773948, base: "/",
    url: url_GetDeleteEventSubscription_773949,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_773996 = ref object of OpenApiRestCall_772581
proc url_PostDeleteOptionGroup_773998(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteOptionGroup_773997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773999 = query.getOrDefault("Action")
  valid_773999 = validateParameter(valid_773999, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_773999 != nil:
    section.add "Action", valid_773999
  var valid_774000 = query.getOrDefault("Version")
  valid_774000 = validateParameter(valid_774000, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774000 != nil:
    section.add "Version", valid_774000
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774001 = header.getOrDefault("X-Amz-Date")
  valid_774001 = validateParameter(valid_774001, JString, required = false,
                                 default = nil)
  if valid_774001 != nil:
    section.add "X-Amz-Date", valid_774001
  var valid_774002 = header.getOrDefault("X-Amz-Security-Token")
  valid_774002 = validateParameter(valid_774002, JString, required = false,
                                 default = nil)
  if valid_774002 != nil:
    section.add "X-Amz-Security-Token", valid_774002
  var valid_774003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774003 = validateParameter(valid_774003, JString, required = false,
                                 default = nil)
  if valid_774003 != nil:
    section.add "X-Amz-Content-Sha256", valid_774003
  var valid_774004 = header.getOrDefault("X-Amz-Algorithm")
  valid_774004 = validateParameter(valid_774004, JString, required = false,
                                 default = nil)
  if valid_774004 != nil:
    section.add "X-Amz-Algorithm", valid_774004
  var valid_774005 = header.getOrDefault("X-Amz-Signature")
  valid_774005 = validateParameter(valid_774005, JString, required = false,
                                 default = nil)
  if valid_774005 != nil:
    section.add "X-Amz-Signature", valid_774005
  var valid_774006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774006 = validateParameter(valid_774006, JString, required = false,
                                 default = nil)
  if valid_774006 != nil:
    section.add "X-Amz-SignedHeaders", valid_774006
  var valid_774007 = header.getOrDefault("X-Amz-Credential")
  valid_774007 = validateParameter(valid_774007, JString, required = false,
                                 default = nil)
  if valid_774007 != nil:
    section.add "X-Amz-Credential", valid_774007
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_774008 = formData.getOrDefault("OptionGroupName")
  valid_774008 = validateParameter(valid_774008, JString, required = true,
                                 default = nil)
  if valid_774008 != nil:
    section.add "OptionGroupName", valid_774008
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774009: Call_PostDeleteOptionGroup_773996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774009.validator(path, query, header, formData, body)
  let scheme = call_774009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774009.url(scheme.get, call_774009.host, call_774009.base,
                         call_774009.route, valid.getOrDefault("path"))
  result = hook(call_774009, url, valid)

proc call*(call_774010: Call_PostDeleteOptionGroup_773996; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774011 = newJObject()
  var formData_774012 = newJObject()
  add(formData_774012, "OptionGroupName", newJString(OptionGroupName))
  add(query_774011, "Action", newJString(Action))
  add(query_774011, "Version", newJString(Version))
  result = call_774010.call(nil, query_774011, nil, formData_774012, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_773996(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_773997, base: "/",
    url: url_PostDeleteOptionGroup_773998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_773980 = ref object of OpenApiRestCall_772581
proc url_GetDeleteOptionGroup_773982(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteOptionGroup_773981(path: JsonNode; query: JsonNode;
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
  var valid_773983 = query.getOrDefault("OptionGroupName")
  valid_773983 = validateParameter(valid_773983, JString, required = true,
                                 default = nil)
  if valid_773983 != nil:
    section.add "OptionGroupName", valid_773983
  var valid_773984 = query.getOrDefault("Action")
  valid_773984 = validateParameter(valid_773984, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_773984 != nil:
    section.add "Action", valid_773984
  var valid_773985 = query.getOrDefault("Version")
  valid_773985 = validateParameter(valid_773985, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_773985 != nil:
    section.add "Version", valid_773985
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773986 = header.getOrDefault("X-Amz-Date")
  valid_773986 = validateParameter(valid_773986, JString, required = false,
                                 default = nil)
  if valid_773986 != nil:
    section.add "X-Amz-Date", valid_773986
  var valid_773987 = header.getOrDefault("X-Amz-Security-Token")
  valid_773987 = validateParameter(valid_773987, JString, required = false,
                                 default = nil)
  if valid_773987 != nil:
    section.add "X-Amz-Security-Token", valid_773987
  var valid_773988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773988 = validateParameter(valid_773988, JString, required = false,
                                 default = nil)
  if valid_773988 != nil:
    section.add "X-Amz-Content-Sha256", valid_773988
  var valid_773989 = header.getOrDefault("X-Amz-Algorithm")
  valid_773989 = validateParameter(valid_773989, JString, required = false,
                                 default = nil)
  if valid_773989 != nil:
    section.add "X-Amz-Algorithm", valid_773989
  var valid_773990 = header.getOrDefault("X-Amz-Signature")
  valid_773990 = validateParameter(valid_773990, JString, required = false,
                                 default = nil)
  if valid_773990 != nil:
    section.add "X-Amz-Signature", valid_773990
  var valid_773991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773991 = validateParameter(valid_773991, JString, required = false,
                                 default = nil)
  if valid_773991 != nil:
    section.add "X-Amz-SignedHeaders", valid_773991
  var valid_773992 = header.getOrDefault("X-Amz-Credential")
  valid_773992 = validateParameter(valid_773992, JString, required = false,
                                 default = nil)
  if valid_773992 != nil:
    section.add "X-Amz-Credential", valid_773992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773993: Call_GetDeleteOptionGroup_773980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773993.validator(path, query, header, formData, body)
  let scheme = call_773993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773993.url(scheme.get, call_773993.host, call_773993.base,
                         call_773993.route, valid.getOrDefault("path"))
  result = hook(call_773993, url, valid)

proc call*(call_773994: Call_GetDeleteOptionGroup_773980; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773995 = newJObject()
  add(query_773995, "OptionGroupName", newJString(OptionGroupName))
  add(query_773995, "Action", newJString(Action))
  add(query_773995, "Version", newJString(Version))
  result = call_773994.call(nil, query_773995, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_773980(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_773981, base: "/",
    url: url_GetDeleteOptionGroup_773982, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_774036 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBEngineVersions_774038(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBEngineVersions_774037(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774039 = query.getOrDefault("Action")
  valid_774039 = validateParameter(valid_774039, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_774039 != nil:
    section.add "Action", valid_774039
  var valid_774040 = query.getOrDefault("Version")
  valid_774040 = validateParameter(valid_774040, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774040 != nil:
    section.add "Version", valid_774040
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774041 = header.getOrDefault("X-Amz-Date")
  valid_774041 = validateParameter(valid_774041, JString, required = false,
                                 default = nil)
  if valid_774041 != nil:
    section.add "X-Amz-Date", valid_774041
  var valid_774042 = header.getOrDefault("X-Amz-Security-Token")
  valid_774042 = validateParameter(valid_774042, JString, required = false,
                                 default = nil)
  if valid_774042 != nil:
    section.add "X-Amz-Security-Token", valid_774042
  var valid_774043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774043 = validateParameter(valid_774043, JString, required = false,
                                 default = nil)
  if valid_774043 != nil:
    section.add "X-Amz-Content-Sha256", valid_774043
  var valid_774044 = header.getOrDefault("X-Amz-Algorithm")
  valid_774044 = validateParameter(valid_774044, JString, required = false,
                                 default = nil)
  if valid_774044 != nil:
    section.add "X-Amz-Algorithm", valid_774044
  var valid_774045 = header.getOrDefault("X-Amz-Signature")
  valid_774045 = validateParameter(valid_774045, JString, required = false,
                                 default = nil)
  if valid_774045 != nil:
    section.add "X-Amz-Signature", valid_774045
  var valid_774046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774046 = validateParameter(valid_774046, JString, required = false,
                                 default = nil)
  if valid_774046 != nil:
    section.add "X-Amz-SignedHeaders", valid_774046
  var valid_774047 = header.getOrDefault("X-Amz-Credential")
  valid_774047 = validateParameter(valid_774047, JString, required = false,
                                 default = nil)
  if valid_774047 != nil:
    section.add "X-Amz-Credential", valid_774047
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
  var valid_774048 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_774048 = validateParameter(valid_774048, JBool, required = false, default = nil)
  if valid_774048 != nil:
    section.add "ListSupportedCharacterSets", valid_774048
  var valid_774049 = formData.getOrDefault("Engine")
  valid_774049 = validateParameter(valid_774049, JString, required = false,
                                 default = nil)
  if valid_774049 != nil:
    section.add "Engine", valid_774049
  var valid_774050 = formData.getOrDefault("Marker")
  valid_774050 = validateParameter(valid_774050, JString, required = false,
                                 default = nil)
  if valid_774050 != nil:
    section.add "Marker", valid_774050
  var valid_774051 = formData.getOrDefault("DBParameterGroupFamily")
  valid_774051 = validateParameter(valid_774051, JString, required = false,
                                 default = nil)
  if valid_774051 != nil:
    section.add "DBParameterGroupFamily", valid_774051
  var valid_774052 = formData.getOrDefault("Filters")
  valid_774052 = validateParameter(valid_774052, JArray, required = false,
                                 default = nil)
  if valid_774052 != nil:
    section.add "Filters", valid_774052
  var valid_774053 = formData.getOrDefault("MaxRecords")
  valid_774053 = validateParameter(valid_774053, JInt, required = false, default = nil)
  if valid_774053 != nil:
    section.add "MaxRecords", valid_774053
  var valid_774054 = formData.getOrDefault("EngineVersion")
  valid_774054 = validateParameter(valid_774054, JString, required = false,
                                 default = nil)
  if valid_774054 != nil:
    section.add "EngineVersion", valid_774054
  var valid_774055 = formData.getOrDefault("DefaultOnly")
  valid_774055 = validateParameter(valid_774055, JBool, required = false, default = nil)
  if valid_774055 != nil:
    section.add "DefaultOnly", valid_774055
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774056: Call_PostDescribeDBEngineVersions_774036; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774056.validator(path, query, header, formData, body)
  let scheme = call_774056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774056.url(scheme.get, call_774056.host, call_774056.base,
                         call_774056.route, valid.getOrDefault("path"))
  result = hook(call_774056, url, valid)

proc call*(call_774057: Call_PostDescribeDBEngineVersions_774036;
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
  var query_774058 = newJObject()
  var formData_774059 = newJObject()
  add(formData_774059, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_774059, "Engine", newJString(Engine))
  add(formData_774059, "Marker", newJString(Marker))
  add(query_774058, "Action", newJString(Action))
  add(formData_774059, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_774059.add "Filters", Filters
  add(formData_774059, "MaxRecords", newJInt(MaxRecords))
  add(formData_774059, "EngineVersion", newJString(EngineVersion))
  add(query_774058, "Version", newJString(Version))
  add(formData_774059, "DefaultOnly", newJBool(DefaultOnly))
  result = call_774057.call(nil, query_774058, nil, formData_774059, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_774036(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_774037, base: "/",
    url: url_PostDescribeDBEngineVersions_774038,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_774013 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBEngineVersions_774015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBEngineVersions_774014(path: JsonNode; query: JsonNode;
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
  var valid_774016 = query.getOrDefault("Engine")
  valid_774016 = validateParameter(valid_774016, JString, required = false,
                                 default = nil)
  if valid_774016 != nil:
    section.add "Engine", valid_774016
  var valid_774017 = query.getOrDefault("ListSupportedCharacterSets")
  valid_774017 = validateParameter(valid_774017, JBool, required = false, default = nil)
  if valid_774017 != nil:
    section.add "ListSupportedCharacterSets", valid_774017
  var valid_774018 = query.getOrDefault("MaxRecords")
  valid_774018 = validateParameter(valid_774018, JInt, required = false, default = nil)
  if valid_774018 != nil:
    section.add "MaxRecords", valid_774018
  var valid_774019 = query.getOrDefault("DBParameterGroupFamily")
  valid_774019 = validateParameter(valid_774019, JString, required = false,
                                 default = nil)
  if valid_774019 != nil:
    section.add "DBParameterGroupFamily", valid_774019
  var valid_774020 = query.getOrDefault("Filters")
  valid_774020 = validateParameter(valid_774020, JArray, required = false,
                                 default = nil)
  if valid_774020 != nil:
    section.add "Filters", valid_774020
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774021 = query.getOrDefault("Action")
  valid_774021 = validateParameter(valid_774021, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_774021 != nil:
    section.add "Action", valid_774021
  var valid_774022 = query.getOrDefault("Marker")
  valid_774022 = validateParameter(valid_774022, JString, required = false,
                                 default = nil)
  if valid_774022 != nil:
    section.add "Marker", valid_774022
  var valid_774023 = query.getOrDefault("EngineVersion")
  valid_774023 = validateParameter(valid_774023, JString, required = false,
                                 default = nil)
  if valid_774023 != nil:
    section.add "EngineVersion", valid_774023
  var valid_774024 = query.getOrDefault("DefaultOnly")
  valid_774024 = validateParameter(valid_774024, JBool, required = false, default = nil)
  if valid_774024 != nil:
    section.add "DefaultOnly", valid_774024
  var valid_774025 = query.getOrDefault("Version")
  valid_774025 = validateParameter(valid_774025, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774025 != nil:
    section.add "Version", valid_774025
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774026 = header.getOrDefault("X-Amz-Date")
  valid_774026 = validateParameter(valid_774026, JString, required = false,
                                 default = nil)
  if valid_774026 != nil:
    section.add "X-Amz-Date", valid_774026
  var valid_774027 = header.getOrDefault("X-Amz-Security-Token")
  valid_774027 = validateParameter(valid_774027, JString, required = false,
                                 default = nil)
  if valid_774027 != nil:
    section.add "X-Amz-Security-Token", valid_774027
  var valid_774028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774028 = validateParameter(valid_774028, JString, required = false,
                                 default = nil)
  if valid_774028 != nil:
    section.add "X-Amz-Content-Sha256", valid_774028
  var valid_774029 = header.getOrDefault("X-Amz-Algorithm")
  valid_774029 = validateParameter(valid_774029, JString, required = false,
                                 default = nil)
  if valid_774029 != nil:
    section.add "X-Amz-Algorithm", valid_774029
  var valid_774030 = header.getOrDefault("X-Amz-Signature")
  valid_774030 = validateParameter(valid_774030, JString, required = false,
                                 default = nil)
  if valid_774030 != nil:
    section.add "X-Amz-Signature", valid_774030
  var valid_774031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774031 = validateParameter(valid_774031, JString, required = false,
                                 default = nil)
  if valid_774031 != nil:
    section.add "X-Amz-SignedHeaders", valid_774031
  var valid_774032 = header.getOrDefault("X-Amz-Credential")
  valid_774032 = validateParameter(valid_774032, JString, required = false,
                                 default = nil)
  if valid_774032 != nil:
    section.add "X-Amz-Credential", valid_774032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774033: Call_GetDescribeDBEngineVersions_774013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774033.validator(path, query, header, formData, body)
  let scheme = call_774033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774033.url(scheme.get, call_774033.host, call_774033.base,
                         call_774033.route, valid.getOrDefault("path"))
  result = hook(call_774033, url, valid)

proc call*(call_774034: Call_GetDescribeDBEngineVersions_774013;
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
  var query_774035 = newJObject()
  add(query_774035, "Engine", newJString(Engine))
  add(query_774035, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_774035, "MaxRecords", newJInt(MaxRecords))
  add(query_774035, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_774035.add "Filters", Filters
  add(query_774035, "Action", newJString(Action))
  add(query_774035, "Marker", newJString(Marker))
  add(query_774035, "EngineVersion", newJString(EngineVersion))
  add(query_774035, "DefaultOnly", newJBool(DefaultOnly))
  add(query_774035, "Version", newJString(Version))
  result = call_774034.call(nil, query_774035, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_774013(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_774014, base: "/",
    url: url_GetDescribeDBEngineVersions_774015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_774079 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBInstances_774081(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBInstances_774080(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774082 = query.getOrDefault("Action")
  valid_774082 = validateParameter(valid_774082, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_774082 != nil:
    section.add "Action", valid_774082
  var valid_774083 = query.getOrDefault("Version")
  valid_774083 = validateParameter(valid_774083, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774083 != nil:
    section.add "Version", valid_774083
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774084 = header.getOrDefault("X-Amz-Date")
  valid_774084 = validateParameter(valid_774084, JString, required = false,
                                 default = nil)
  if valid_774084 != nil:
    section.add "X-Amz-Date", valid_774084
  var valid_774085 = header.getOrDefault("X-Amz-Security-Token")
  valid_774085 = validateParameter(valid_774085, JString, required = false,
                                 default = nil)
  if valid_774085 != nil:
    section.add "X-Amz-Security-Token", valid_774085
  var valid_774086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774086 = validateParameter(valid_774086, JString, required = false,
                                 default = nil)
  if valid_774086 != nil:
    section.add "X-Amz-Content-Sha256", valid_774086
  var valid_774087 = header.getOrDefault("X-Amz-Algorithm")
  valid_774087 = validateParameter(valid_774087, JString, required = false,
                                 default = nil)
  if valid_774087 != nil:
    section.add "X-Amz-Algorithm", valid_774087
  var valid_774088 = header.getOrDefault("X-Amz-Signature")
  valid_774088 = validateParameter(valid_774088, JString, required = false,
                                 default = nil)
  if valid_774088 != nil:
    section.add "X-Amz-Signature", valid_774088
  var valid_774089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774089 = validateParameter(valid_774089, JString, required = false,
                                 default = nil)
  if valid_774089 != nil:
    section.add "X-Amz-SignedHeaders", valid_774089
  var valid_774090 = header.getOrDefault("X-Amz-Credential")
  valid_774090 = validateParameter(valid_774090, JString, required = false,
                                 default = nil)
  if valid_774090 != nil:
    section.add "X-Amz-Credential", valid_774090
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774091 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774091 = validateParameter(valid_774091, JString, required = false,
                                 default = nil)
  if valid_774091 != nil:
    section.add "DBInstanceIdentifier", valid_774091
  var valid_774092 = formData.getOrDefault("Marker")
  valid_774092 = validateParameter(valid_774092, JString, required = false,
                                 default = nil)
  if valid_774092 != nil:
    section.add "Marker", valid_774092
  var valid_774093 = formData.getOrDefault("Filters")
  valid_774093 = validateParameter(valid_774093, JArray, required = false,
                                 default = nil)
  if valid_774093 != nil:
    section.add "Filters", valid_774093
  var valid_774094 = formData.getOrDefault("MaxRecords")
  valid_774094 = validateParameter(valid_774094, JInt, required = false, default = nil)
  if valid_774094 != nil:
    section.add "MaxRecords", valid_774094
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774095: Call_PostDescribeDBInstances_774079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774095.validator(path, query, header, formData, body)
  let scheme = call_774095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774095.url(scheme.get, call_774095.host, call_774095.base,
                         call_774095.route, valid.getOrDefault("path"))
  result = hook(call_774095, url, valid)

proc call*(call_774096: Call_PostDescribeDBInstances_774079;
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
  var query_774097 = newJObject()
  var formData_774098 = newJObject()
  add(formData_774098, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774098, "Marker", newJString(Marker))
  add(query_774097, "Action", newJString(Action))
  if Filters != nil:
    formData_774098.add "Filters", Filters
  add(formData_774098, "MaxRecords", newJInt(MaxRecords))
  add(query_774097, "Version", newJString(Version))
  result = call_774096.call(nil, query_774097, nil, formData_774098, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_774079(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_774080, base: "/",
    url: url_PostDescribeDBInstances_774081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_774060 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBInstances_774062(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBInstances_774061(path: JsonNode; query: JsonNode;
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
  var valid_774063 = query.getOrDefault("MaxRecords")
  valid_774063 = validateParameter(valid_774063, JInt, required = false, default = nil)
  if valid_774063 != nil:
    section.add "MaxRecords", valid_774063
  var valid_774064 = query.getOrDefault("Filters")
  valid_774064 = validateParameter(valid_774064, JArray, required = false,
                                 default = nil)
  if valid_774064 != nil:
    section.add "Filters", valid_774064
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774065 = query.getOrDefault("Action")
  valid_774065 = validateParameter(valid_774065, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_774065 != nil:
    section.add "Action", valid_774065
  var valid_774066 = query.getOrDefault("Marker")
  valid_774066 = validateParameter(valid_774066, JString, required = false,
                                 default = nil)
  if valid_774066 != nil:
    section.add "Marker", valid_774066
  var valid_774067 = query.getOrDefault("Version")
  valid_774067 = validateParameter(valid_774067, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774067 != nil:
    section.add "Version", valid_774067
  var valid_774068 = query.getOrDefault("DBInstanceIdentifier")
  valid_774068 = validateParameter(valid_774068, JString, required = false,
                                 default = nil)
  if valid_774068 != nil:
    section.add "DBInstanceIdentifier", valid_774068
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774069 = header.getOrDefault("X-Amz-Date")
  valid_774069 = validateParameter(valid_774069, JString, required = false,
                                 default = nil)
  if valid_774069 != nil:
    section.add "X-Amz-Date", valid_774069
  var valid_774070 = header.getOrDefault("X-Amz-Security-Token")
  valid_774070 = validateParameter(valid_774070, JString, required = false,
                                 default = nil)
  if valid_774070 != nil:
    section.add "X-Amz-Security-Token", valid_774070
  var valid_774071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774071 = validateParameter(valid_774071, JString, required = false,
                                 default = nil)
  if valid_774071 != nil:
    section.add "X-Amz-Content-Sha256", valid_774071
  var valid_774072 = header.getOrDefault("X-Amz-Algorithm")
  valid_774072 = validateParameter(valid_774072, JString, required = false,
                                 default = nil)
  if valid_774072 != nil:
    section.add "X-Amz-Algorithm", valid_774072
  var valid_774073 = header.getOrDefault("X-Amz-Signature")
  valid_774073 = validateParameter(valid_774073, JString, required = false,
                                 default = nil)
  if valid_774073 != nil:
    section.add "X-Amz-Signature", valid_774073
  var valid_774074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774074 = validateParameter(valid_774074, JString, required = false,
                                 default = nil)
  if valid_774074 != nil:
    section.add "X-Amz-SignedHeaders", valid_774074
  var valid_774075 = header.getOrDefault("X-Amz-Credential")
  valid_774075 = validateParameter(valid_774075, JString, required = false,
                                 default = nil)
  if valid_774075 != nil:
    section.add "X-Amz-Credential", valid_774075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774076: Call_GetDescribeDBInstances_774060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774076.validator(path, query, header, formData, body)
  let scheme = call_774076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774076.url(scheme.get, call_774076.host, call_774076.base,
                         call_774076.route, valid.getOrDefault("path"))
  result = hook(call_774076, url, valid)

proc call*(call_774077: Call_GetDescribeDBInstances_774060; MaxRecords: int = 0;
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
  var query_774078 = newJObject()
  add(query_774078, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774078.add "Filters", Filters
  add(query_774078, "Action", newJString(Action))
  add(query_774078, "Marker", newJString(Marker))
  add(query_774078, "Version", newJString(Version))
  add(query_774078, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_774077.call(nil, query_774078, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_774060(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_774061, base: "/",
    url: url_GetDescribeDBInstances_774062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_774121 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBLogFiles_774123(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBLogFiles_774122(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774124 = query.getOrDefault("Action")
  valid_774124 = validateParameter(valid_774124, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_774124 != nil:
    section.add "Action", valid_774124
  var valid_774125 = query.getOrDefault("Version")
  valid_774125 = validateParameter(valid_774125, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774125 != nil:
    section.add "Version", valid_774125
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774126 = header.getOrDefault("X-Amz-Date")
  valid_774126 = validateParameter(valid_774126, JString, required = false,
                                 default = nil)
  if valid_774126 != nil:
    section.add "X-Amz-Date", valid_774126
  var valid_774127 = header.getOrDefault("X-Amz-Security-Token")
  valid_774127 = validateParameter(valid_774127, JString, required = false,
                                 default = nil)
  if valid_774127 != nil:
    section.add "X-Amz-Security-Token", valid_774127
  var valid_774128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774128 = validateParameter(valid_774128, JString, required = false,
                                 default = nil)
  if valid_774128 != nil:
    section.add "X-Amz-Content-Sha256", valid_774128
  var valid_774129 = header.getOrDefault("X-Amz-Algorithm")
  valid_774129 = validateParameter(valid_774129, JString, required = false,
                                 default = nil)
  if valid_774129 != nil:
    section.add "X-Amz-Algorithm", valid_774129
  var valid_774130 = header.getOrDefault("X-Amz-Signature")
  valid_774130 = validateParameter(valid_774130, JString, required = false,
                                 default = nil)
  if valid_774130 != nil:
    section.add "X-Amz-Signature", valid_774130
  var valid_774131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774131 = validateParameter(valid_774131, JString, required = false,
                                 default = nil)
  if valid_774131 != nil:
    section.add "X-Amz-SignedHeaders", valid_774131
  var valid_774132 = header.getOrDefault("X-Amz-Credential")
  valid_774132 = validateParameter(valid_774132, JString, required = false,
                                 default = nil)
  if valid_774132 != nil:
    section.add "X-Amz-Credential", valid_774132
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
  var valid_774133 = formData.getOrDefault("FilenameContains")
  valid_774133 = validateParameter(valid_774133, JString, required = false,
                                 default = nil)
  if valid_774133 != nil:
    section.add "FilenameContains", valid_774133
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774134 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774134 = validateParameter(valid_774134, JString, required = true,
                                 default = nil)
  if valid_774134 != nil:
    section.add "DBInstanceIdentifier", valid_774134
  var valid_774135 = formData.getOrDefault("FileSize")
  valid_774135 = validateParameter(valid_774135, JInt, required = false, default = nil)
  if valid_774135 != nil:
    section.add "FileSize", valid_774135
  var valid_774136 = formData.getOrDefault("Marker")
  valid_774136 = validateParameter(valid_774136, JString, required = false,
                                 default = nil)
  if valid_774136 != nil:
    section.add "Marker", valid_774136
  var valid_774137 = formData.getOrDefault("Filters")
  valid_774137 = validateParameter(valid_774137, JArray, required = false,
                                 default = nil)
  if valid_774137 != nil:
    section.add "Filters", valid_774137
  var valid_774138 = formData.getOrDefault("MaxRecords")
  valid_774138 = validateParameter(valid_774138, JInt, required = false, default = nil)
  if valid_774138 != nil:
    section.add "MaxRecords", valid_774138
  var valid_774139 = formData.getOrDefault("FileLastWritten")
  valid_774139 = validateParameter(valid_774139, JInt, required = false, default = nil)
  if valid_774139 != nil:
    section.add "FileLastWritten", valid_774139
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774140: Call_PostDescribeDBLogFiles_774121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774140.validator(path, query, header, formData, body)
  let scheme = call_774140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774140.url(scheme.get, call_774140.host, call_774140.base,
                         call_774140.route, valid.getOrDefault("path"))
  result = hook(call_774140, url, valid)

proc call*(call_774141: Call_PostDescribeDBLogFiles_774121;
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
  var query_774142 = newJObject()
  var formData_774143 = newJObject()
  add(formData_774143, "FilenameContains", newJString(FilenameContains))
  add(formData_774143, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774143, "FileSize", newJInt(FileSize))
  add(formData_774143, "Marker", newJString(Marker))
  add(query_774142, "Action", newJString(Action))
  if Filters != nil:
    formData_774143.add "Filters", Filters
  add(formData_774143, "MaxRecords", newJInt(MaxRecords))
  add(formData_774143, "FileLastWritten", newJInt(FileLastWritten))
  add(query_774142, "Version", newJString(Version))
  result = call_774141.call(nil, query_774142, nil, formData_774143, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_774121(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_774122, base: "/",
    url: url_PostDescribeDBLogFiles_774123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_774099 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBLogFiles_774101(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBLogFiles_774100(path: JsonNode; query: JsonNode;
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
  var valid_774102 = query.getOrDefault("FileLastWritten")
  valid_774102 = validateParameter(valid_774102, JInt, required = false, default = nil)
  if valid_774102 != nil:
    section.add "FileLastWritten", valid_774102
  var valid_774103 = query.getOrDefault("MaxRecords")
  valid_774103 = validateParameter(valid_774103, JInt, required = false, default = nil)
  if valid_774103 != nil:
    section.add "MaxRecords", valid_774103
  var valid_774104 = query.getOrDefault("FilenameContains")
  valid_774104 = validateParameter(valid_774104, JString, required = false,
                                 default = nil)
  if valid_774104 != nil:
    section.add "FilenameContains", valid_774104
  var valid_774105 = query.getOrDefault("FileSize")
  valid_774105 = validateParameter(valid_774105, JInt, required = false, default = nil)
  if valid_774105 != nil:
    section.add "FileSize", valid_774105
  var valid_774106 = query.getOrDefault("Filters")
  valid_774106 = validateParameter(valid_774106, JArray, required = false,
                                 default = nil)
  if valid_774106 != nil:
    section.add "Filters", valid_774106
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774107 = query.getOrDefault("Action")
  valid_774107 = validateParameter(valid_774107, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_774107 != nil:
    section.add "Action", valid_774107
  var valid_774108 = query.getOrDefault("Marker")
  valid_774108 = validateParameter(valid_774108, JString, required = false,
                                 default = nil)
  if valid_774108 != nil:
    section.add "Marker", valid_774108
  var valid_774109 = query.getOrDefault("Version")
  valid_774109 = validateParameter(valid_774109, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774109 != nil:
    section.add "Version", valid_774109
  var valid_774110 = query.getOrDefault("DBInstanceIdentifier")
  valid_774110 = validateParameter(valid_774110, JString, required = true,
                                 default = nil)
  if valid_774110 != nil:
    section.add "DBInstanceIdentifier", valid_774110
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774111 = header.getOrDefault("X-Amz-Date")
  valid_774111 = validateParameter(valid_774111, JString, required = false,
                                 default = nil)
  if valid_774111 != nil:
    section.add "X-Amz-Date", valid_774111
  var valid_774112 = header.getOrDefault("X-Amz-Security-Token")
  valid_774112 = validateParameter(valid_774112, JString, required = false,
                                 default = nil)
  if valid_774112 != nil:
    section.add "X-Amz-Security-Token", valid_774112
  var valid_774113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774113 = validateParameter(valid_774113, JString, required = false,
                                 default = nil)
  if valid_774113 != nil:
    section.add "X-Amz-Content-Sha256", valid_774113
  var valid_774114 = header.getOrDefault("X-Amz-Algorithm")
  valid_774114 = validateParameter(valid_774114, JString, required = false,
                                 default = nil)
  if valid_774114 != nil:
    section.add "X-Amz-Algorithm", valid_774114
  var valid_774115 = header.getOrDefault("X-Amz-Signature")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "X-Amz-Signature", valid_774115
  var valid_774116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "X-Amz-SignedHeaders", valid_774116
  var valid_774117 = header.getOrDefault("X-Amz-Credential")
  valid_774117 = validateParameter(valid_774117, JString, required = false,
                                 default = nil)
  if valid_774117 != nil:
    section.add "X-Amz-Credential", valid_774117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774118: Call_GetDescribeDBLogFiles_774099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774118.validator(path, query, header, formData, body)
  let scheme = call_774118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774118.url(scheme.get, call_774118.host, call_774118.base,
                         call_774118.route, valid.getOrDefault("path"))
  result = hook(call_774118, url, valid)

proc call*(call_774119: Call_GetDescribeDBLogFiles_774099;
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
  var query_774120 = newJObject()
  add(query_774120, "FileLastWritten", newJInt(FileLastWritten))
  add(query_774120, "MaxRecords", newJInt(MaxRecords))
  add(query_774120, "FilenameContains", newJString(FilenameContains))
  add(query_774120, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_774120.add "Filters", Filters
  add(query_774120, "Action", newJString(Action))
  add(query_774120, "Marker", newJString(Marker))
  add(query_774120, "Version", newJString(Version))
  add(query_774120, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_774119.call(nil, query_774120, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_774099(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_774100, base: "/",
    url: url_GetDescribeDBLogFiles_774101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_774163 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBParameterGroups_774165(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameterGroups_774164(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774166 = query.getOrDefault("Action")
  valid_774166 = validateParameter(valid_774166, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_774166 != nil:
    section.add "Action", valid_774166
  var valid_774167 = query.getOrDefault("Version")
  valid_774167 = validateParameter(valid_774167, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774167 != nil:
    section.add "Version", valid_774167
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774168 = header.getOrDefault("X-Amz-Date")
  valid_774168 = validateParameter(valid_774168, JString, required = false,
                                 default = nil)
  if valid_774168 != nil:
    section.add "X-Amz-Date", valid_774168
  var valid_774169 = header.getOrDefault("X-Amz-Security-Token")
  valid_774169 = validateParameter(valid_774169, JString, required = false,
                                 default = nil)
  if valid_774169 != nil:
    section.add "X-Amz-Security-Token", valid_774169
  var valid_774170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774170 = validateParameter(valid_774170, JString, required = false,
                                 default = nil)
  if valid_774170 != nil:
    section.add "X-Amz-Content-Sha256", valid_774170
  var valid_774171 = header.getOrDefault("X-Amz-Algorithm")
  valid_774171 = validateParameter(valid_774171, JString, required = false,
                                 default = nil)
  if valid_774171 != nil:
    section.add "X-Amz-Algorithm", valid_774171
  var valid_774172 = header.getOrDefault("X-Amz-Signature")
  valid_774172 = validateParameter(valid_774172, JString, required = false,
                                 default = nil)
  if valid_774172 != nil:
    section.add "X-Amz-Signature", valid_774172
  var valid_774173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774173 = validateParameter(valid_774173, JString, required = false,
                                 default = nil)
  if valid_774173 != nil:
    section.add "X-Amz-SignedHeaders", valid_774173
  var valid_774174 = header.getOrDefault("X-Amz-Credential")
  valid_774174 = validateParameter(valid_774174, JString, required = false,
                                 default = nil)
  if valid_774174 != nil:
    section.add "X-Amz-Credential", valid_774174
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774175 = formData.getOrDefault("DBParameterGroupName")
  valid_774175 = validateParameter(valid_774175, JString, required = false,
                                 default = nil)
  if valid_774175 != nil:
    section.add "DBParameterGroupName", valid_774175
  var valid_774176 = formData.getOrDefault("Marker")
  valid_774176 = validateParameter(valid_774176, JString, required = false,
                                 default = nil)
  if valid_774176 != nil:
    section.add "Marker", valid_774176
  var valid_774177 = formData.getOrDefault("Filters")
  valid_774177 = validateParameter(valid_774177, JArray, required = false,
                                 default = nil)
  if valid_774177 != nil:
    section.add "Filters", valid_774177
  var valid_774178 = formData.getOrDefault("MaxRecords")
  valid_774178 = validateParameter(valid_774178, JInt, required = false, default = nil)
  if valid_774178 != nil:
    section.add "MaxRecords", valid_774178
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774179: Call_PostDescribeDBParameterGroups_774163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774179.validator(path, query, header, formData, body)
  let scheme = call_774179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774179.url(scheme.get, call_774179.host, call_774179.base,
                         call_774179.route, valid.getOrDefault("path"))
  result = hook(call_774179, url, valid)

proc call*(call_774180: Call_PostDescribeDBParameterGroups_774163;
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
  var query_774181 = newJObject()
  var formData_774182 = newJObject()
  add(formData_774182, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_774182, "Marker", newJString(Marker))
  add(query_774181, "Action", newJString(Action))
  if Filters != nil:
    formData_774182.add "Filters", Filters
  add(formData_774182, "MaxRecords", newJInt(MaxRecords))
  add(query_774181, "Version", newJString(Version))
  result = call_774180.call(nil, query_774181, nil, formData_774182, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_774163(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_774164, base: "/",
    url: url_PostDescribeDBParameterGroups_774165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_774144 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBParameterGroups_774146(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameterGroups_774145(path: JsonNode; query: JsonNode;
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
  var valid_774147 = query.getOrDefault("MaxRecords")
  valid_774147 = validateParameter(valid_774147, JInt, required = false, default = nil)
  if valid_774147 != nil:
    section.add "MaxRecords", valid_774147
  var valid_774148 = query.getOrDefault("Filters")
  valid_774148 = validateParameter(valid_774148, JArray, required = false,
                                 default = nil)
  if valid_774148 != nil:
    section.add "Filters", valid_774148
  var valid_774149 = query.getOrDefault("DBParameterGroupName")
  valid_774149 = validateParameter(valid_774149, JString, required = false,
                                 default = nil)
  if valid_774149 != nil:
    section.add "DBParameterGroupName", valid_774149
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774150 = query.getOrDefault("Action")
  valid_774150 = validateParameter(valid_774150, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_774150 != nil:
    section.add "Action", valid_774150
  var valid_774151 = query.getOrDefault("Marker")
  valid_774151 = validateParameter(valid_774151, JString, required = false,
                                 default = nil)
  if valid_774151 != nil:
    section.add "Marker", valid_774151
  var valid_774152 = query.getOrDefault("Version")
  valid_774152 = validateParameter(valid_774152, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774152 != nil:
    section.add "Version", valid_774152
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774153 = header.getOrDefault("X-Amz-Date")
  valid_774153 = validateParameter(valid_774153, JString, required = false,
                                 default = nil)
  if valid_774153 != nil:
    section.add "X-Amz-Date", valid_774153
  var valid_774154 = header.getOrDefault("X-Amz-Security-Token")
  valid_774154 = validateParameter(valid_774154, JString, required = false,
                                 default = nil)
  if valid_774154 != nil:
    section.add "X-Amz-Security-Token", valid_774154
  var valid_774155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774155 = validateParameter(valid_774155, JString, required = false,
                                 default = nil)
  if valid_774155 != nil:
    section.add "X-Amz-Content-Sha256", valid_774155
  var valid_774156 = header.getOrDefault("X-Amz-Algorithm")
  valid_774156 = validateParameter(valid_774156, JString, required = false,
                                 default = nil)
  if valid_774156 != nil:
    section.add "X-Amz-Algorithm", valid_774156
  var valid_774157 = header.getOrDefault("X-Amz-Signature")
  valid_774157 = validateParameter(valid_774157, JString, required = false,
                                 default = nil)
  if valid_774157 != nil:
    section.add "X-Amz-Signature", valid_774157
  var valid_774158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774158 = validateParameter(valid_774158, JString, required = false,
                                 default = nil)
  if valid_774158 != nil:
    section.add "X-Amz-SignedHeaders", valid_774158
  var valid_774159 = header.getOrDefault("X-Amz-Credential")
  valid_774159 = validateParameter(valid_774159, JString, required = false,
                                 default = nil)
  if valid_774159 != nil:
    section.add "X-Amz-Credential", valid_774159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774160: Call_GetDescribeDBParameterGroups_774144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774160.validator(path, query, header, formData, body)
  let scheme = call_774160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774160.url(scheme.get, call_774160.host, call_774160.base,
                         call_774160.route, valid.getOrDefault("path"))
  result = hook(call_774160, url, valid)

proc call*(call_774161: Call_GetDescribeDBParameterGroups_774144;
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
  var query_774162 = newJObject()
  add(query_774162, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774162.add "Filters", Filters
  add(query_774162, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_774162, "Action", newJString(Action))
  add(query_774162, "Marker", newJString(Marker))
  add(query_774162, "Version", newJString(Version))
  result = call_774161.call(nil, query_774162, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_774144(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_774145, base: "/",
    url: url_GetDescribeDBParameterGroups_774146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_774203 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBParameters_774205(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameters_774204(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774206 = query.getOrDefault("Action")
  valid_774206 = validateParameter(valid_774206, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_774206 != nil:
    section.add "Action", valid_774206
  var valid_774207 = query.getOrDefault("Version")
  valid_774207 = validateParameter(valid_774207, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774207 != nil:
    section.add "Version", valid_774207
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774208 = header.getOrDefault("X-Amz-Date")
  valid_774208 = validateParameter(valid_774208, JString, required = false,
                                 default = nil)
  if valid_774208 != nil:
    section.add "X-Amz-Date", valid_774208
  var valid_774209 = header.getOrDefault("X-Amz-Security-Token")
  valid_774209 = validateParameter(valid_774209, JString, required = false,
                                 default = nil)
  if valid_774209 != nil:
    section.add "X-Amz-Security-Token", valid_774209
  var valid_774210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774210 = validateParameter(valid_774210, JString, required = false,
                                 default = nil)
  if valid_774210 != nil:
    section.add "X-Amz-Content-Sha256", valid_774210
  var valid_774211 = header.getOrDefault("X-Amz-Algorithm")
  valid_774211 = validateParameter(valid_774211, JString, required = false,
                                 default = nil)
  if valid_774211 != nil:
    section.add "X-Amz-Algorithm", valid_774211
  var valid_774212 = header.getOrDefault("X-Amz-Signature")
  valid_774212 = validateParameter(valid_774212, JString, required = false,
                                 default = nil)
  if valid_774212 != nil:
    section.add "X-Amz-Signature", valid_774212
  var valid_774213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774213 = validateParameter(valid_774213, JString, required = false,
                                 default = nil)
  if valid_774213 != nil:
    section.add "X-Amz-SignedHeaders", valid_774213
  var valid_774214 = header.getOrDefault("X-Amz-Credential")
  valid_774214 = validateParameter(valid_774214, JString, required = false,
                                 default = nil)
  if valid_774214 != nil:
    section.add "X-Amz-Credential", valid_774214
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_774215 = formData.getOrDefault("DBParameterGroupName")
  valid_774215 = validateParameter(valid_774215, JString, required = true,
                                 default = nil)
  if valid_774215 != nil:
    section.add "DBParameterGroupName", valid_774215
  var valid_774216 = formData.getOrDefault("Marker")
  valid_774216 = validateParameter(valid_774216, JString, required = false,
                                 default = nil)
  if valid_774216 != nil:
    section.add "Marker", valid_774216
  var valid_774217 = formData.getOrDefault("Filters")
  valid_774217 = validateParameter(valid_774217, JArray, required = false,
                                 default = nil)
  if valid_774217 != nil:
    section.add "Filters", valid_774217
  var valid_774218 = formData.getOrDefault("MaxRecords")
  valid_774218 = validateParameter(valid_774218, JInt, required = false, default = nil)
  if valid_774218 != nil:
    section.add "MaxRecords", valid_774218
  var valid_774219 = formData.getOrDefault("Source")
  valid_774219 = validateParameter(valid_774219, JString, required = false,
                                 default = nil)
  if valid_774219 != nil:
    section.add "Source", valid_774219
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774220: Call_PostDescribeDBParameters_774203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774220.validator(path, query, header, formData, body)
  let scheme = call_774220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774220.url(scheme.get, call_774220.host, call_774220.base,
                         call_774220.route, valid.getOrDefault("path"))
  result = hook(call_774220, url, valid)

proc call*(call_774221: Call_PostDescribeDBParameters_774203;
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
  var query_774222 = newJObject()
  var formData_774223 = newJObject()
  add(formData_774223, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_774223, "Marker", newJString(Marker))
  add(query_774222, "Action", newJString(Action))
  if Filters != nil:
    formData_774223.add "Filters", Filters
  add(formData_774223, "MaxRecords", newJInt(MaxRecords))
  add(query_774222, "Version", newJString(Version))
  add(formData_774223, "Source", newJString(Source))
  result = call_774221.call(nil, query_774222, nil, formData_774223, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_774203(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_774204, base: "/",
    url: url_PostDescribeDBParameters_774205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_774183 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBParameters_774185(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameters_774184(path: JsonNode; query: JsonNode;
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
  var valid_774186 = query.getOrDefault("MaxRecords")
  valid_774186 = validateParameter(valid_774186, JInt, required = false, default = nil)
  if valid_774186 != nil:
    section.add "MaxRecords", valid_774186
  var valid_774187 = query.getOrDefault("Filters")
  valid_774187 = validateParameter(valid_774187, JArray, required = false,
                                 default = nil)
  if valid_774187 != nil:
    section.add "Filters", valid_774187
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_774188 = query.getOrDefault("DBParameterGroupName")
  valid_774188 = validateParameter(valid_774188, JString, required = true,
                                 default = nil)
  if valid_774188 != nil:
    section.add "DBParameterGroupName", valid_774188
  var valid_774189 = query.getOrDefault("Action")
  valid_774189 = validateParameter(valid_774189, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_774189 != nil:
    section.add "Action", valid_774189
  var valid_774190 = query.getOrDefault("Marker")
  valid_774190 = validateParameter(valid_774190, JString, required = false,
                                 default = nil)
  if valid_774190 != nil:
    section.add "Marker", valid_774190
  var valid_774191 = query.getOrDefault("Source")
  valid_774191 = validateParameter(valid_774191, JString, required = false,
                                 default = nil)
  if valid_774191 != nil:
    section.add "Source", valid_774191
  var valid_774192 = query.getOrDefault("Version")
  valid_774192 = validateParameter(valid_774192, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774192 != nil:
    section.add "Version", valid_774192
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774193 = header.getOrDefault("X-Amz-Date")
  valid_774193 = validateParameter(valid_774193, JString, required = false,
                                 default = nil)
  if valid_774193 != nil:
    section.add "X-Amz-Date", valid_774193
  var valid_774194 = header.getOrDefault("X-Amz-Security-Token")
  valid_774194 = validateParameter(valid_774194, JString, required = false,
                                 default = nil)
  if valid_774194 != nil:
    section.add "X-Amz-Security-Token", valid_774194
  var valid_774195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774195 = validateParameter(valid_774195, JString, required = false,
                                 default = nil)
  if valid_774195 != nil:
    section.add "X-Amz-Content-Sha256", valid_774195
  var valid_774196 = header.getOrDefault("X-Amz-Algorithm")
  valid_774196 = validateParameter(valid_774196, JString, required = false,
                                 default = nil)
  if valid_774196 != nil:
    section.add "X-Amz-Algorithm", valid_774196
  var valid_774197 = header.getOrDefault("X-Amz-Signature")
  valid_774197 = validateParameter(valid_774197, JString, required = false,
                                 default = nil)
  if valid_774197 != nil:
    section.add "X-Amz-Signature", valid_774197
  var valid_774198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774198 = validateParameter(valid_774198, JString, required = false,
                                 default = nil)
  if valid_774198 != nil:
    section.add "X-Amz-SignedHeaders", valid_774198
  var valid_774199 = header.getOrDefault("X-Amz-Credential")
  valid_774199 = validateParameter(valid_774199, JString, required = false,
                                 default = nil)
  if valid_774199 != nil:
    section.add "X-Amz-Credential", valid_774199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774200: Call_GetDescribeDBParameters_774183; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774200.validator(path, query, header, formData, body)
  let scheme = call_774200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774200.url(scheme.get, call_774200.host, call_774200.base,
                         call_774200.route, valid.getOrDefault("path"))
  result = hook(call_774200, url, valid)

proc call*(call_774201: Call_GetDescribeDBParameters_774183;
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
  var query_774202 = newJObject()
  add(query_774202, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774202.add "Filters", Filters
  add(query_774202, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_774202, "Action", newJString(Action))
  add(query_774202, "Marker", newJString(Marker))
  add(query_774202, "Source", newJString(Source))
  add(query_774202, "Version", newJString(Version))
  result = call_774201.call(nil, query_774202, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_774183(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_774184, base: "/",
    url: url_GetDescribeDBParameters_774185, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_774243 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBSecurityGroups_774245(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSecurityGroups_774244(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774246 = query.getOrDefault("Action")
  valid_774246 = validateParameter(valid_774246, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_774246 != nil:
    section.add "Action", valid_774246
  var valid_774247 = query.getOrDefault("Version")
  valid_774247 = validateParameter(valid_774247, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774247 != nil:
    section.add "Version", valid_774247
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774248 = header.getOrDefault("X-Amz-Date")
  valid_774248 = validateParameter(valid_774248, JString, required = false,
                                 default = nil)
  if valid_774248 != nil:
    section.add "X-Amz-Date", valid_774248
  var valid_774249 = header.getOrDefault("X-Amz-Security-Token")
  valid_774249 = validateParameter(valid_774249, JString, required = false,
                                 default = nil)
  if valid_774249 != nil:
    section.add "X-Amz-Security-Token", valid_774249
  var valid_774250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774250 = validateParameter(valid_774250, JString, required = false,
                                 default = nil)
  if valid_774250 != nil:
    section.add "X-Amz-Content-Sha256", valid_774250
  var valid_774251 = header.getOrDefault("X-Amz-Algorithm")
  valid_774251 = validateParameter(valid_774251, JString, required = false,
                                 default = nil)
  if valid_774251 != nil:
    section.add "X-Amz-Algorithm", valid_774251
  var valid_774252 = header.getOrDefault("X-Amz-Signature")
  valid_774252 = validateParameter(valid_774252, JString, required = false,
                                 default = nil)
  if valid_774252 != nil:
    section.add "X-Amz-Signature", valid_774252
  var valid_774253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774253 = validateParameter(valid_774253, JString, required = false,
                                 default = nil)
  if valid_774253 != nil:
    section.add "X-Amz-SignedHeaders", valid_774253
  var valid_774254 = header.getOrDefault("X-Amz-Credential")
  valid_774254 = validateParameter(valid_774254, JString, required = false,
                                 default = nil)
  if valid_774254 != nil:
    section.add "X-Amz-Credential", valid_774254
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774255 = formData.getOrDefault("DBSecurityGroupName")
  valid_774255 = validateParameter(valid_774255, JString, required = false,
                                 default = nil)
  if valid_774255 != nil:
    section.add "DBSecurityGroupName", valid_774255
  var valid_774256 = formData.getOrDefault("Marker")
  valid_774256 = validateParameter(valid_774256, JString, required = false,
                                 default = nil)
  if valid_774256 != nil:
    section.add "Marker", valid_774256
  var valid_774257 = formData.getOrDefault("Filters")
  valid_774257 = validateParameter(valid_774257, JArray, required = false,
                                 default = nil)
  if valid_774257 != nil:
    section.add "Filters", valid_774257
  var valid_774258 = formData.getOrDefault("MaxRecords")
  valid_774258 = validateParameter(valid_774258, JInt, required = false, default = nil)
  if valid_774258 != nil:
    section.add "MaxRecords", valid_774258
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774259: Call_PostDescribeDBSecurityGroups_774243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774259.validator(path, query, header, formData, body)
  let scheme = call_774259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774259.url(scheme.get, call_774259.host, call_774259.base,
                         call_774259.route, valid.getOrDefault("path"))
  result = hook(call_774259, url, valid)

proc call*(call_774260: Call_PostDescribeDBSecurityGroups_774243;
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
  var query_774261 = newJObject()
  var formData_774262 = newJObject()
  add(formData_774262, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_774262, "Marker", newJString(Marker))
  add(query_774261, "Action", newJString(Action))
  if Filters != nil:
    formData_774262.add "Filters", Filters
  add(formData_774262, "MaxRecords", newJInt(MaxRecords))
  add(query_774261, "Version", newJString(Version))
  result = call_774260.call(nil, query_774261, nil, formData_774262, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_774243(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_774244, base: "/",
    url: url_PostDescribeDBSecurityGroups_774245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_774224 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBSecurityGroups_774226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSecurityGroups_774225(path: JsonNode; query: JsonNode;
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
  var valid_774227 = query.getOrDefault("MaxRecords")
  valid_774227 = validateParameter(valid_774227, JInt, required = false, default = nil)
  if valid_774227 != nil:
    section.add "MaxRecords", valid_774227
  var valid_774228 = query.getOrDefault("DBSecurityGroupName")
  valid_774228 = validateParameter(valid_774228, JString, required = false,
                                 default = nil)
  if valid_774228 != nil:
    section.add "DBSecurityGroupName", valid_774228
  var valid_774229 = query.getOrDefault("Filters")
  valid_774229 = validateParameter(valid_774229, JArray, required = false,
                                 default = nil)
  if valid_774229 != nil:
    section.add "Filters", valid_774229
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774230 = query.getOrDefault("Action")
  valid_774230 = validateParameter(valid_774230, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_774230 != nil:
    section.add "Action", valid_774230
  var valid_774231 = query.getOrDefault("Marker")
  valid_774231 = validateParameter(valid_774231, JString, required = false,
                                 default = nil)
  if valid_774231 != nil:
    section.add "Marker", valid_774231
  var valid_774232 = query.getOrDefault("Version")
  valid_774232 = validateParameter(valid_774232, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774232 != nil:
    section.add "Version", valid_774232
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774233 = header.getOrDefault("X-Amz-Date")
  valid_774233 = validateParameter(valid_774233, JString, required = false,
                                 default = nil)
  if valid_774233 != nil:
    section.add "X-Amz-Date", valid_774233
  var valid_774234 = header.getOrDefault("X-Amz-Security-Token")
  valid_774234 = validateParameter(valid_774234, JString, required = false,
                                 default = nil)
  if valid_774234 != nil:
    section.add "X-Amz-Security-Token", valid_774234
  var valid_774235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774235 = validateParameter(valid_774235, JString, required = false,
                                 default = nil)
  if valid_774235 != nil:
    section.add "X-Amz-Content-Sha256", valid_774235
  var valid_774236 = header.getOrDefault("X-Amz-Algorithm")
  valid_774236 = validateParameter(valid_774236, JString, required = false,
                                 default = nil)
  if valid_774236 != nil:
    section.add "X-Amz-Algorithm", valid_774236
  var valid_774237 = header.getOrDefault("X-Amz-Signature")
  valid_774237 = validateParameter(valid_774237, JString, required = false,
                                 default = nil)
  if valid_774237 != nil:
    section.add "X-Amz-Signature", valid_774237
  var valid_774238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774238 = validateParameter(valid_774238, JString, required = false,
                                 default = nil)
  if valid_774238 != nil:
    section.add "X-Amz-SignedHeaders", valid_774238
  var valid_774239 = header.getOrDefault("X-Amz-Credential")
  valid_774239 = validateParameter(valid_774239, JString, required = false,
                                 default = nil)
  if valid_774239 != nil:
    section.add "X-Amz-Credential", valid_774239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774240: Call_GetDescribeDBSecurityGroups_774224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774240.validator(path, query, header, formData, body)
  let scheme = call_774240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774240.url(scheme.get, call_774240.host, call_774240.base,
                         call_774240.route, valid.getOrDefault("path"))
  result = hook(call_774240, url, valid)

proc call*(call_774241: Call_GetDescribeDBSecurityGroups_774224;
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
  var query_774242 = newJObject()
  add(query_774242, "MaxRecords", newJInt(MaxRecords))
  add(query_774242, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_774242.add "Filters", Filters
  add(query_774242, "Action", newJString(Action))
  add(query_774242, "Marker", newJString(Marker))
  add(query_774242, "Version", newJString(Version))
  result = call_774241.call(nil, query_774242, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_774224(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_774225, base: "/",
    url: url_GetDescribeDBSecurityGroups_774226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_774284 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBSnapshots_774286(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSnapshots_774285(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774287 = query.getOrDefault("Action")
  valid_774287 = validateParameter(valid_774287, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_774287 != nil:
    section.add "Action", valid_774287
  var valid_774288 = query.getOrDefault("Version")
  valid_774288 = validateParameter(valid_774288, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774288 != nil:
    section.add "Version", valid_774288
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774289 = header.getOrDefault("X-Amz-Date")
  valid_774289 = validateParameter(valid_774289, JString, required = false,
                                 default = nil)
  if valid_774289 != nil:
    section.add "X-Amz-Date", valid_774289
  var valid_774290 = header.getOrDefault("X-Amz-Security-Token")
  valid_774290 = validateParameter(valid_774290, JString, required = false,
                                 default = nil)
  if valid_774290 != nil:
    section.add "X-Amz-Security-Token", valid_774290
  var valid_774291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774291 = validateParameter(valid_774291, JString, required = false,
                                 default = nil)
  if valid_774291 != nil:
    section.add "X-Amz-Content-Sha256", valid_774291
  var valid_774292 = header.getOrDefault("X-Amz-Algorithm")
  valid_774292 = validateParameter(valid_774292, JString, required = false,
                                 default = nil)
  if valid_774292 != nil:
    section.add "X-Amz-Algorithm", valid_774292
  var valid_774293 = header.getOrDefault("X-Amz-Signature")
  valid_774293 = validateParameter(valid_774293, JString, required = false,
                                 default = nil)
  if valid_774293 != nil:
    section.add "X-Amz-Signature", valid_774293
  var valid_774294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774294 = validateParameter(valid_774294, JString, required = false,
                                 default = nil)
  if valid_774294 != nil:
    section.add "X-Amz-SignedHeaders", valid_774294
  var valid_774295 = header.getOrDefault("X-Amz-Credential")
  valid_774295 = validateParameter(valid_774295, JString, required = false,
                                 default = nil)
  if valid_774295 != nil:
    section.add "X-Amz-Credential", valid_774295
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774296 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774296 = validateParameter(valid_774296, JString, required = false,
                                 default = nil)
  if valid_774296 != nil:
    section.add "DBInstanceIdentifier", valid_774296
  var valid_774297 = formData.getOrDefault("SnapshotType")
  valid_774297 = validateParameter(valid_774297, JString, required = false,
                                 default = nil)
  if valid_774297 != nil:
    section.add "SnapshotType", valid_774297
  var valid_774298 = formData.getOrDefault("Marker")
  valid_774298 = validateParameter(valid_774298, JString, required = false,
                                 default = nil)
  if valid_774298 != nil:
    section.add "Marker", valid_774298
  var valid_774299 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_774299 = validateParameter(valid_774299, JString, required = false,
                                 default = nil)
  if valid_774299 != nil:
    section.add "DBSnapshotIdentifier", valid_774299
  var valid_774300 = formData.getOrDefault("Filters")
  valid_774300 = validateParameter(valid_774300, JArray, required = false,
                                 default = nil)
  if valid_774300 != nil:
    section.add "Filters", valid_774300
  var valid_774301 = formData.getOrDefault("MaxRecords")
  valid_774301 = validateParameter(valid_774301, JInt, required = false, default = nil)
  if valid_774301 != nil:
    section.add "MaxRecords", valid_774301
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774302: Call_PostDescribeDBSnapshots_774284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774302.validator(path, query, header, formData, body)
  let scheme = call_774302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774302.url(scheme.get, call_774302.host, call_774302.base,
                         call_774302.route, valid.getOrDefault("path"))
  result = hook(call_774302, url, valid)

proc call*(call_774303: Call_PostDescribeDBSnapshots_774284;
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
  var query_774304 = newJObject()
  var formData_774305 = newJObject()
  add(formData_774305, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774305, "SnapshotType", newJString(SnapshotType))
  add(formData_774305, "Marker", newJString(Marker))
  add(formData_774305, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_774304, "Action", newJString(Action))
  if Filters != nil:
    formData_774305.add "Filters", Filters
  add(formData_774305, "MaxRecords", newJInt(MaxRecords))
  add(query_774304, "Version", newJString(Version))
  result = call_774303.call(nil, query_774304, nil, formData_774305, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_774284(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_774285, base: "/",
    url: url_PostDescribeDBSnapshots_774286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_774263 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBSnapshots_774265(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSnapshots_774264(path: JsonNode; query: JsonNode;
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
  var valid_774266 = query.getOrDefault("MaxRecords")
  valid_774266 = validateParameter(valid_774266, JInt, required = false, default = nil)
  if valid_774266 != nil:
    section.add "MaxRecords", valid_774266
  var valid_774267 = query.getOrDefault("Filters")
  valid_774267 = validateParameter(valid_774267, JArray, required = false,
                                 default = nil)
  if valid_774267 != nil:
    section.add "Filters", valid_774267
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774268 = query.getOrDefault("Action")
  valid_774268 = validateParameter(valid_774268, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_774268 != nil:
    section.add "Action", valid_774268
  var valid_774269 = query.getOrDefault("Marker")
  valid_774269 = validateParameter(valid_774269, JString, required = false,
                                 default = nil)
  if valid_774269 != nil:
    section.add "Marker", valid_774269
  var valid_774270 = query.getOrDefault("SnapshotType")
  valid_774270 = validateParameter(valid_774270, JString, required = false,
                                 default = nil)
  if valid_774270 != nil:
    section.add "SnapshotType", valid_774270
  var valid_774271 = query.getOrDefault("Version")
  valid_774271 = validateParameter(valid_774271, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774271 != nil:
    section.add "Version", valid_774271
  var valid_774272 = query.getOrDefault("DBInstanceIdentifier")
  valid_774272 = validateParameter(valid_774272, JString, required = false,
                                 default = nil)
  if valid_774272 != nil:
    section.add "DBInstanceIdentifier", valid_774272
  var valid_774273 = query.getOrDefault("DBSnapshotIdentifier")
  valid_774273 = validateParameter(valid_774273, JString, required = false,
                                 default = nil)
  if valid_774273 != nil:
    section.add "DBSnapshotIdentifier", valid_774273
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774274 = header.getOrDefault("X-Amz-Date")
  valid_774274 = validateParameter(valid_774274, JString, required = false,
                                 default = nil)
  if valid_774274 != nil:
    section.add "X-Amz-Date", valid_774274
  var valid_774275 = header.getOrDefault("X-Amz-Security-Token")
  valid_774275 = validateParameter(valid_774275, JString, required = false,
                                 default = nil)
  if valid_774275 != nil:
    section.add "X-Amz-Security-Token", valid_774275
  var valid_774276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774276 = validateParameter(valid_774276, JString, required = false,
                                 default = nil)
  if valid_774276 != nil:
    section.add "X-Amz-Content-Sha256", valid_774276
  var valid_774277 = header.getOrDefault("X-Amz-Algorithm")
  valid_774277 = validateParameter(valid_774277, JString, required = false,
                                 default = nil)
  if valid_774277 != nil:
    section.add "X-Amz-Algorithm", valid_774277
  var valid_774278 = header.getOrDefault("X-Amz-Signature")
  valid_774278 = validateParameter(valid_774278, JString, required = false,
                                 default = nil)
  if valid_774278 != nil:
    section.add "X-Amz-Signature", valid_774278
  var valid_774279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774279 = validateParameter(valid_774279, JString, required = false,
                                 default = nil)
  if valid_774279 != nil:
    section.add "X-Amz-SignedHeaders", valid_774279
  var valid_774280 = header.getOrDefault("X-Amz-Credential")
  valid_774280 = validateParameter(valid_774280, JString, required = false,
                                 default = nil)
  if valid_774280 != nil:
    section.add "X-Amz-Credential", valid_774280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774281: Call_GetDescribeDBSnapshots_774263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774281.validator(path, query, header, formData, body)
  let scheme = call_774281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774281.url(scheme.get, call_774281.host, call_774281.base,
                         call_774281.route, valid.getOrDefault("path"))
  result = hook(call_774281, url, valid)

proc call*(call_774282: Call_GetDescribeDBSnapshots_774263; MaxRecords: int = 0;
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
  var query_774283 = newJObject()
  add(query_774283, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774283.add "Filters", Filters
  add(query_774283, "Action", newJString(Action))
  add(query_774283, "Marker", newJString(Marker))
  add(query_774283, "SnapshotType", newJString(SnapshotType))
  add(query_774283, "Version", newJString(Version))
  add(query_774283, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_774283, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_774282.call(nil, query_774283, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_774263(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_774264, base: "/",
    url: url_GetDescribeDBSnapshots_774265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_774325 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBSubnetGroups_774327(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSubnetGroups_774326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774328 = query.getOrDefault("Action")
  valid_774328 = validateParameter(valid_774328, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_774328 != nil:
    section.add "Action", valid_774328
  var valid_774329 = query.getOrDefault("Version")
  valid_774329 = validateParameter(valid_774329, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774329 != nil:
    section.add "Version", valid_774329
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774330 = header.getOrDefault("X-Amz-Date")
  valid_774330 = validateParameter(valid_774330, JString, required = false,
                                 default = nil)
  if valid_774330 != nil:
    section.add "X-Amz-Date", valid_774330
  var valid_774331 = header.getOrDefault("X-Amz-Security-Token")
  valid_774331 = validateParameter(valid_774331, JString, required = false,
                                 default = nil)
  if valid_774331 != nil:
    section.add "X-Amz-Security-Token", valid_774331
  var valid_774332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774332 = validateParameter(valid_774332, JString, required = false,
                                 default = nil)
  if valid_774332 != nil:
    section.add "X-Amz-Content-Sha256", valid_774332
  var valid_774333 = header.getOrDefault("X-Amz-Algorithm")
  valid_774333 = validateParameter(valid_774333, JString, required = false,
                                 default = nil)
  if valid_774333 != nil:
    section.add "X-Amz-Algorithm", valid_774333
  var valid_774334 = header.getOrDefault("X-Amz-Signature")
  valid_774334 = validateParameter(valid_774334, JString, required = false,
                                 default = nil)
  if valid_774334 != nil:
    section.add "X-Amz-Signature", valid_774334
  var valid_774335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774335 = validateParameter(valid_774335, JString, required = false,
                                 default = nil)
  if valid_774335 != nil:
    section.add "X-Amz-SignedHeaders", valid_774335
  var valid_774336 = header.getOrDefault("X-Amz-Credential")
  valid_774336 = validateParameter(valid_774336, JString, required = false,
                                 default = nil)
  if valid_774336 != nil:
    section.add "X-Amz-Credential", valid_774336
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774337 = formData.getOrDefault("DBSubnetGroupName")
  valid_774337 = validateParameter(valid_774337, JString, required = false,
                                 default = nil)
  if valid_774337 != nil:
    section.add "DBSubnetGroupName", valid_774337
  var valid_774338 = formData.getOrDefault("Marker")
  valid_774338 = validateParameter(valid_774338, JString, required = false,
                                 default = nil)
  if valid_774338 != nil:
    section.add "Marker", valid_774338
  var valid_774339 = formData.getOrDefault("Filters")
  valid_774339 = validateParameter(valid_774339, JArray, required = false,
                                 default = nil)
  if valid_774339 != nil:
    section.add "Filters", valid_774339
  var valid_774340 = formData.getOrDefault("MaxRecords")
  valid_774340 = validateParameter(valid_774340, JInt, required = false, default = nil)
  if valid_774340 != nil:
    section.add "MaxRecords", valid_774340
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774341: Call_PostDescribeDBSubnetGroups_774325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774341.validator(path, query, header, formData, body)
  let scheme = call_774341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774341.url(scheme.get, call_774341.host, call_774341.base,
                         call_774341.route, valid.getOrDefault("path"))
  result = hook(call_774341, url, valid)

proc call*(call_774342: Call_PostDescribeDBSubnetGroups_774325;
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
  var query_774343 = newJObject()
  var formData_774344 = newJObject()
  add(formData_774344, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_774344, "Marker", newJString(Marker))
  add(query_774343, "Action", newJString(Action))
  if Filters != nil:
    formData_774344.add "Filters", Filters
  add(formData_774344, "MaxRecords", newJInt(MaxRecords))
  add(query_774343, "Version", newJString(Version))
  result = call_774342.call(nil, query_774343, nil, formData_774344, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_774325(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_774326, base: "/",
    url: url_PostDescribeDBSubnetGroups_774327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_774306 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBSubnetGroups_774308(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSubnetGroups_774307(path: JsonNode; query: JsonNode;
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
  var valid_774309 = query.getOrDefault("MaxRecords")
  valid_774309 = validateParameter(valid_774309, JInt, required = false, default = nil)
  if valid_774309 != nil:
    section.add "MaxRecords", valid_774309
  var valid_774310 = query.getOrDefault("Filters")
  valid_774310 = validateParameter(valid_774310, JArray, required = false,
                                 default = nil)
  if valid_774310 != nil:
    section.add "Filters", valid_774310
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774311 = query.getOrDefault("Action")
  valid_774311 = validateParameter(valid_774311, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_774311 != nil:
    section.add "Action", valid_774311
  var valid_774312 = query.getOrDefault("Marker")
  valid_774312 = validateParameter(valid_774312, JString, required = false,
                                 default = nil)
  if valid_774312 != nil:
    section.add "Marker", valid_774312
  var valid_774313 = query.getOrDefault("DBSubnetGroupName")
  valid_774313 = validateParameter(valid_774313, JString, required = false,
                                 default = nil)
  if valid_774313 != nil:
    section.add "DBSubnetGroupName", valid_774313
  var valid_774314 = query.getOrDefault("Version")
  valid_774314 = validateParameter(valid_774314, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774322: Call_GetDescribeDBSubnetGroups_774306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774322.validator(path, query, header, formData, body)
  let scheme = call_774322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774322.url(scheme.get, call_774322.host, call_774322.base,
                         call_774322.route, valid.getOrDefault("path"))
  result = hook(call_774322, url, valid)

proc call*(call_774323: Call_GetDescribeDBSubnetGroups_774306; MaxRecords: int = 0;
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
  var query_774324 = newJObject()
  add(query_774324, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774324.add "Filters", Filters
  add(query_774324, "Action", newJString(Action))
  add(query_774324, "Marker", newJString(Marker))
  add(query_774324, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_774324, "Version", newJString(Version))
  result = call_774323.call(nil, query_774324, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_774306(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_774307, base: "/",
    url: url_GetDescribeDBSubnetGroups_774308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_774364 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEngineDefaultParameters_774366(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEngineDefaultParameters_774365(path: JsonNode;
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
  var valid_774367 = query.getOrDefault("Action")
  valid_774367 = validateParameter(valid_774367, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_774367 != nil:
    section.add "Action", valid_774367
  var valid_774368 = query.getOrDefault("Version")
  valid_774368 = validateParameter(valid_774368, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774368 != nil:
    section.add "Version", valid_774368
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774369 = header.getOrDefault("X-Amz-Date")
  valid_774369 = validateParameter(valid_774369, JString, required = false,
                                 default = nil)
  if valid_774369 != nil:
    section.add "X-Amz-Date", valid_774369
  var valid_774370 = header.getOrDefault("X-Amz-Security-Token")
  valid_774370 = validateParameter(valid_774370, JString, required = false,
                                 default = nil)
  if valid_774370 != nil:
    section.add "X-Amz-Security-Token", valid_774370
  var valid_774371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774371 = validateParameter(valid_774371, JString, required = false,
                                 default = nil)
  if valid_774371 != nil:
    section.add "X-Amz-Content-Sha256", valid_774371
  var valid_774372 = header.getOrDefault("X-Amz-Algorithm")
  valid_774372 = validateParameter(valid_774372, JString, required = false,
                                 default = nil)
  if valid_774372 != nil:
    section.add "X-Amz-Algorithm", valid_774372
  var valid_774373 = header.getOrDefault("X-Amz-Signature")
  valid_774373 = validateParameter(valid_774373, JString, required = false,
                                 default = nil)
  if valid_774373 != nil:
    section.add "X-Amz-Signature", valid_774373
  var valid_774374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774374 = validateParameter(valid_774374, JString, required = false,
                                 default = nil)
  if valid_774374 != nil:
    section.add "X-Amz-SignedHeaders", valid_774374
  var valid_774375 = header.getOrDefault("X-Amz-Credential")
  valid_774375 = validateParameter(valid_774375, JString, required = false,
                                 default = nil)
  if valid_774375 != nil:
    section.add "X-Amz-Credential", valid_774375
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774376 = formData.getOrDefault("Marker")
  valid_774376 = validateParameter(valid_774376, JString, required = false,
                                 default = nil)
  if valid_774376 != nil:
    section.add "Marker", valid_774376
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_774377 = formData.getOrDefault("DBParameterGroupFamily")
  valid_774377 = validateParameter(valid_774377, JString, required = true,
                                 default = nil)
  if valid_774377 != nil:
    section.add "DBParameterGroupFamily", valid_774377
  var valid_774378 = formData.getOrDefault("Filters")
  valid_774378 = validateParameter(valid_774378, JArray, required = false,
                                 default = nil)
  if valid_774378 != nil:
    section.add "Filters", valid_774378
  var valid_774379 = formData.getOrDefault("MaxRecords")
  valid_774379 = validateParameter(valid_774379, JInt, required = false, default = nil)
  if valid_774379 != nil:
    section.add "MaxRecords", valid_774379
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774380: Call_PostDescribeEngineDefaultParameters_774364;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774380.validator(path, query, header, formData, body)
  let scheme = call_774380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774380.url(scheme.get, call_774380.host, call_774380.base,
                         call_774380.route, valid.getOrDefault("path"))
  result = hook(call_774380, url, valid)

proc call*(call_774381: Call_PostDescribeEngineDefaultParameters_774364;
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
  var query_774382 = newJObject()
  var formData_774383 = newJObject()
  add(formData_774383, "Marker", newJString(Marker))
  add(query_774382, "Action", newJString(Action))
  add(formData_774383, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_774383.add "Filters", Filters
  add(formData_774383, "MaxRecords", newJInt(MaxRecords))
  add(query_774382, "Version", newJString(Version))
  result = call_774381.call(nil, query_774382, nil, formData_774383, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_774364(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_774365, base: "/",
    url: url_PostDescribeEngineDefaultParameters_774366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_774345 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEngineDefaultParameters_774347(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEngineDefaultParameters_774346(path: JsonNode;
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
  var valid_774348 = query.getOrDefault("MaxRecords")
  valid_774348 = validateParameter(valid_774348, JInt, required = false, default = nil)
  if valid_774348 != nil:
    section.add "MaxRecords", valid_774348
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_774349 = query.getOrDefault("DBParameterGroupFamily")
  valid_774349 = validateParameter(valid_774349, JString, required = true,
                                 default = nil)
  if valid_774349 != nil:
    section.add "DBParameterGroupFamily", valid_774349
  var valid_774350 = query.getOrDefault("Filters")
  valid_774350 = validateParameter(valid_774350, JArray, required = false,
                                 default = nil)
  if valid_774350 != nil:
    section.add "Filters", valid_774350
  var valid_774351 = query.getOrDefault("Action")
  valid_774351 = validateParameter(valid_774351, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_774351 != nil:
    section.add "Action", valid_774351
  var valid_774352 = query.getOrDefault("Marker")
  valid_774352 = validateParameter(valid_774352, JString, required = false,
                                 default = nil)
  if valid_774352 != nil:
    section.add "Marker", valid_774352
  var valid_774353 = query.getOrDefault("Version")
  valid_774353 = validateParameter(valid_774353, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774353 != nil:
    section.add "Version", valid_774353
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774354 = header.getOrDefault("X-Amz-Date")
  valid_774354 = validateParameter(valid_774354, JString, required = false,
                                 default = nil)
  if valid_774354 != nil:
    section.add "X-Amz-Date", valid_774354
  var valid_774355 = header.getOrDefault("X-Amz-Security-Token")
  valid_774355 = validateParameter(valid_774355, JString, required = false,
                                 default = nil)
  if valid_774355 != nil:
    section.add "X-Amz-Security-Token", valid_774355
  var valid_774356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774356 = validateParameter(valid_774356, JString, required = false,
                                 default = nil)
  if valid_774356 != nil:
    section.add "X-Amz-Content-Sha256", valid_774356
  var valid_774357 = header.getOrDefault("X-Amz-Algorithm")
  valid_774357 = validateParameter(valid_774357, JString, required = false,
                                 default = nil)
  if valid_774357 != nil:
    section.add "X-Amz-Algorithm", valid_774357
  var valid_774358 = header.getOrDefault("X-Amz-Signature")
  valid_774358 = validateParameter(valid_774358, JString, required = false,
                                 default = nil)
  if valid_774358 != nil:
    section.add "X-Amz-Signature", valid_774358
  var valid_774359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774359 = validateParameter(valid_774359, JString, required = false,
                                 default = nil)
  if valid_774359 != nil:
    section.add "X-Amz-SignedHeaders", valid_774359
  var valid_774360 = header.getOrDefault("X-Amz-Credential")
  valid_774360 = validateParameter(valid_774360, JString, required = false,
                                 default = nil)
  if valid_774360 != nil:
    section.add "X-Amz-Credential", valid_774360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774361: Call_GetDescribeEngineDefaultParameters_774345;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774361.validator(path, query, header, formData, body)
  let scheme = call_774361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774361.url(scheme.get, call_774361.host, call_774361.base,
                         call_774361.route, valid.getOrDefault("path"))
  result = hook(call_774361, url, valid)

proc call*(call_774362: Call_GetDescribeEngineDefaultParameters_774345;
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
  var query_774363 = newJObject()
  add(query_774363, "MaxRecords", newJInt(MaxRecords))
  add(query_774363, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_774363.add "Filters", Filters
  add(query_774363, "Action", newJString(Action))
  add(query_774363, "Marker", newJString(Marker))
  add(query_774363, "Version", newJString(Version))
  result = call_774362.call(nil, query_774363, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_774345(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_774346, base: "/",
    url: url_GetDescribeEngineDefaultParameters_774347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_774401 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEventCategories_774403(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventCategories_774402(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774404 = query.getOrDefault("Action")
  valid_774404 = validateParameter(valid_774404, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_774404 != nil:
    section.add "Action", valid_774404
  var valid_774405 = query.getOrDefault("Version")
  valid_774405 = validateParameter(valid_774405, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774405 != nil:
    section.add "Version", valid_774405
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774406 = header.getOrDefault("X-Amz-Date")
  valid_774406 = validateParameter(valid_774406, JString, required = false,
                                 default = nil)
  if valid_774406 != nil:
    section.add "X-Amz-Date", valid_774406
  var valid_774407 = header.getOrDefault("X-Amz-Security-Token")
  valid_774407 = validateParameter(valid_774407, JString, required = false,
                                 default = nil)
  if valid_774407 != nil:
    section.add "X-Amz-Security-Token", valid_774407
  var valid_774408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774408 = validateParameter(valid_774408, JString, required = false,
                                 default = nil)
  if valid_774408 != nil:
    section.add "X-Amz-Content-Sha256", valid_774408
  var valid_774409 = header.getOrDefault("X-Amz-Algorithm")
  valid_774409 = validateParameter(valid_774409, JString, required = false,
                                 default = nil)
  if valid_774409 != nil:
    section.add "X-Amz-Algorithm", valid_774409
  var valid_774410 = header.getOrDefault("X-Amz-Signature")
  valid_774410 = validateParameter(valid_774410, JString, required = false,
                                 default = nil)
  if valid_774410 != nil:
    section.add "X-Amz-Signature", valid_774410
  var valid_774411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774411 = validateParameter(valid_774411, JString, required = false,
                                 default = nil)
  if valid_774411 != nil:
    section.add "X-Amz-SignedHeaders", valid_774411
  var valid_774412 = header.getOrDefault("X-Amz-Credential")
  valid_774412 = validateParameter(valid_774412, JString, required = false,
                                 default = nil)
  if valid_774412 != nil:
    section.add "X-Amz-Credential", valid_774412
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_774413 = formData.getOrDefault("Filters")
  valid_774413 = validateParameter(valid_774413, JArray, required = false,
                                 default = nil)
  if valid_774413 != nil:
    section.add "Filters", valid_774413
  var valid_774414 = formData.getOrDefault("SourceType")
  valid_774414 = validateParameter(valid_774414, JString, required = false,
                                 default = nil)
  if valid_774414 != nil:
    section.add "SourceType", valid_774414
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774415: Call_PostDescribeEventCategories_774401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774415.validator(path, query, header, formData, body)
  let scheme = call_774415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774415.url(scheme.get, call_774415.host, call_774415.base,
                         call_774415.route, valid.getOrDefault("path"))
  result = hook(call_774415, url, valid)

proc call*(call_774416: Call_PostDescribeEventCategories_774401;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_774417 = newJObject()
  var formData_774418 = newJObject()
  add(query_774417, "Action", newJString(Action))
  if Filters != nil:
    formData_774418.add "Filters", Filters
  add(query_774417, "Version", newJString(Version))
  add(formData_774418, "SourceType", newJString(SourceType))
  result = call_774416.call(nil, query_774417, nil, formData_774418, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_774401(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_774402, base: "/",
    url: url_PostDescribeEventCategories_774403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_774384 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEventCategories_774386(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventCategories_774385(path: JsonNode; query: JsonNode;
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
  var valid_774387 = query.getOrDefault("SourceType")
  valid_774387 = validateParameter(valid_774387, JString, required = false,
                                 default = nil)
  if valid_774387 != nil:
    section.add "SourceType", valid_774387
  var valid_774388 = query.getOrDefault("Filters")
  valid_774388 = validateParameter(valid_774388, JArray, required = false,
                                 default = nil)
  if valid_774388 != nil:
    section.add "Filters", valid_774388
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774389 = query.getOrDefault("Action")
  valid_774389 = validateParameter(valid_774389, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_774389 != nil:
    section.add "Action", valid_774389
  var valid_774390 = query.getOrDefault("Version")
  valid_774390 = validateParameter(valid_774390, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774390 != nil:
    section.add "Version", valid_774390
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774391 = header.getOrDefault("X-Amz-Date")
  valid_774391 = validateParameter(valid_774391, JString, required = false,
                                 default = nil)
  if valid_774391 != nil:
    section.add "X-Amz-Date", valid_774391
  var valid_774392 = header.getOrDefault("X-Amz-Security-Token")
  valid_774392 = validateParameter(valid_774392, JString, required = false,
                                 default = nil)
  if valid_774392 != nil:
    section.add "X-Amz-Security-Token", valid_774392
  var valid_774393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774393 = validateParameter(valid_774393, JString, required = false,
                                 default = nil)
  if valid_774393 != nil:
    section.add "X-Amz-Content-Sha256", valid_774393
  var valid_774394 = header.getOrDefault("X-Amz-Algorithm")
  valid_774394 = validateParameter(valid_774394, JString, required = false,
                                 default = nil)
  if valid_774394 != nil:
    section.add "X-Amz-Algorithm", valid_774394
  var valid_774395 = header.getOrDefault("X-Amz-Signature")
  valid_774395 = validateParameter(valid_774395, JString, required = false,
                                 default = nil)
  if valid_774395 != nil:
    section.add "X-Amz-Signature", valid_774395
  var valid_774396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774396 = validateParameter(valid_774396, JString, required = false,
                                 default = nil)
  if valid_774396 != nil:
    section.add "X-Amz-SignedHeaders", valid_774396
  var valid_774397 = header.getOrDefault("X-Amz-Credential")
  valid_774397 = validateParameter(valid_774397, JString, required = false,
                                 default = nil)
  if valid_774397 != nil:
    section.add "X-Amz-Credential", valid_774397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774398: Call_GetDescribeEventCategories_774384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774398.validator(path, query, header, formData, body)
  let scheme = call_774398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774398.url(scheme.get, call_774398.host, call_774398.base,
                         call_774398.route, valid.getOrDefault("path"))
  result = hook(call_774398, url, valid)

proc call*(call_774399: Call_GetDescribeEventCategories_774384;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2014-09-01"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774400 = newJObject()
  add(query_774400, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_774400.add "Filters", Filters
  add(query_774400, "Action", newJString(Action))
  add(query_774400, "Version", newJString(Version))
  result = call_774399.call(nil, query_774400, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_774384(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_774385, base: "/",
    url: url_GetDescribeEventCategories_774386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_774438 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEventSubscriptions_774440(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventSubscriptions_774439(path: JsonNode;
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
  var valid_774441 = query.getOrDefault("Action")
  valid_774441 = validateParameter(valid_774441, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_774441 != nil:
    section.add "Action", valid_774441
  var valid_774442 = query.getOrDefault("Version")
  valid_774442 = validateParameter(valid_774442, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774442 != nil:
    section.add "Version", valid_774442
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774443 = header.getOrDefault("X-Amz-Date")
  valid_774443 = validateParameter(valid_774443, JString, required = false,
                                 default = nil)
  if valid_774443 != nil:
    section.add "X-Amz-Date", valid_774443
  var valid_774444 = header.getOrDefault("X-Amz-Security-Token")
  valid_774444 = validateParameter(valid_774444, JString, required = false,
                                 default = nil)
  if valid_774444 != nil:
    section.add "X-Amz-Security-Token", valid_774444
  var valid_774445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774445 = validateParameter(valid_774445, JString, required = false,
                                 default = nil)
  if valid_774445 != nil:
    section.add "X-Amz-Content-Sha256", valid_774445
  var valid_774446 = header.getOrDefault("X-Amz-Algorithm")
  valid_774446 = validateParameter(valid_774446, JString, required = false,
                                 default = nil)
  if valid_774446 != nil:
    section.add "X-Amz-Algorithm", valid_774446
  var valid_774447 = header.getOrDefault("X-Amz-Signature")
  valid_774447 = validateParameter(valid_774447, JString, required = false,
                                 default = nil)
  if valid_774447 != nil:
    section.add "X-Amz-Signature", valid_774447
  var valid_774448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774448 = validateParameter(valid_774448, JString, required = false,
                                 default = nil)
  if valid_774448 != nil:
    section.add "X-Amz-SignedHeaders", valid_774448
  var valid_774449 = header.getOrDefault("X-Amz-Credential")
  valid_774449 = validateParameter(valid_774449, JString, required = false,
                                 default = nil)
  if valid_774449 != nil:
    section.add "X-Amz-Credential", valid_774449
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774450 = formData.getOrDefault("Marker")
  valid_774450 = validateParameter(valid_774450, JString, required = false,
                                 default = nil)
  if valid_774450 != nil:
    section.add "Marker", valid_774450
  var valid_774451 = formData.getOrDefault("SubscriptionName")
  valid_774451 = validateParameter(valid_774451, JString, required = false,
                                 default = nil)
  if valid_774451 != nil:
    section.add "SubscriptionName", valid_774451
  var valid_774452 = formData.getOrDefault("Filters")
  valid_774452 = validateParameter(valid_774452, JArray, required = false,
                                 default = nil)
  if valid_774452 != nil:
    section.add "Filters", valid_774452
  var valid_774453 = formData.getOrDefault("MaxRecords")
  valid_774453 = validateParameter(valid_774453, JInt, required = false, default = nil)
  if valid_774453 != nil:
    section.add "MaxRecords", valid_774453
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774454: Call_PostDescribeEventSubscriptions_774438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774454.validator(path, query, header, formData, body)
  let scheme = call_774454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774454.url(scheme.get, call_774454.host, call_774454.base,
                         call_774454.route, valid.getOrDefault("path"))
  result = hook(call_774454, url, valid)

proc call*(call_774455: Call_PostDescribeEventSubscriptions_774438;
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
  var query_774456 = newJObject()
  var formData_774457 = newJObject()
  add(formData_774457, "Marker", newJString(Marker))
  add(formData_774457, "SubscriptionName", newJString(SubscriptionName))
  add(query_774456, "Action", newJString(Action))
  if Filters != nil:
    formData_774457.add "Filters", Filters
  add(formData_774457, "MaxRecords", newJInt(MaxRecords))
  add(query_774456, "Version", newJString(Version))
  result = call_774455.call(nil, query_774456, nil, formData_774457, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_774438(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_774439, base: "/",
    url: url_PostDescribeEventSubscriptions_774440,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_774419 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEventSubscriptions_774421(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventSubscriptions_774420(path: JsonNode; query: JsonNode;
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
  var valid_774422 = query.getOrDefault("MaxRecords")
  valid_774422 = validateParameter(valid_774422, JInt, required = false, default = nil)
  if valid_774422 != nil:
    section.add "MaxRecords", valid_774422
  var valid_774423 = query.getOrDefault("Filters")
  valid_774423 = validateParameter(valid_774423, JArray, required = false,
                                 default = nil)
  if valid_774423 != nil:
    section.add "Filters", valid_774423
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774424 = query.getOrDefault("Action")
  valid_774424 = validateParameter(valid_774424, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_774424 != nil:
    section.add "Action", valid_774424
  var valid_774425 = query.getOrDefault("Marker")
  valid_774425 = validateParameter(valid_774425, JString, required = false,
                                 default = nil)
  if valid_774425 != nil:
    section.add "Marker", valid_774425
  var valid_774426 = query.getOrDefault("SubscriptionName")
  valid_774426 = validateParameter(valid_774426, JString, required = false,
                                 default = nil)
  if valid_774426 != nil:
    section.add "SubscriptionName", valid_774426
  var valid_774427 = query.getOrDefault("Version")
  valid_774427 = validateParameter(valid_774427, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774427 != nil:
    section.add "Version", valid_774427
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774428 = header.getOrDefault("X-Amz-Date")
  valid_774428 = validateParameter(valid_774428, JString, required = false,
                                 default = nil)
  if valid_774428 != nil:
    section.add "X-Amz-Date", valid_774428
  var valid_774429 = header.getOrDefault("X-Amz-Security-Token")
  valid_774429 = validateParameter(valid_774429, JString, required = false,
                                 default = nil)
  if valid_774429 != nil:
    section.add "X-Amz-Security-Token", valid_774429
  var valid_774430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774430 = validateParameter(valid_774430, JString, required = false,
                                 default = nil)
  if valid_774430 != nil:
    section.add "X-Amz-Content-Sha256", valid_774430
  var valid_774431 = header.getOrDefault("X-Amz-Algorithm")
  valid_774431 = validateParameter(valid_774431, JString, required = false,
                                 default = nil)
  if valid_774431 != nil:
    section.add "X-Amz-Algorithm", valid_774431
  var valid_774432 = header.getOrDefault("X-Amz-Signature")
  valid_774432 = validateParameter(valid_774432, JString, required = false,
                                 default = nil)
  if valid_774432 != nil:
    section.add "X-Amz-Signature", valid_774432
  var valid_774433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774433 = validateParameter(valid_774433, JString, required = false,
                                 default = nil)
  if valid_774433 != nil:
    section.add "X-Amz-SignedHeaders", valid_774433
  var valid_774434 = header.getOrDefault("X-Amz-Credential")
  valid_774434 = validateParameter(valid_774434, JString, required = false,
                                 default = nil)
  if valid_774434 != nil:
    section.add "X-Amz-Credential", valid_774434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774435: Call_GetDescribeEventSubscriptions_774419; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774435.validator(path, query, header, formData, body)
  let scheme = call_774435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774435.url(scheme.get, call_774435.host, call_774435.base,
                         call_774435.route, valid.getOrDefault("path"))
  result = hook(call_774435, url, valid)

proc call*(call_774436: Call_GetDescribeEventSubscriptions_774419;
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
  var query_774437 = newJObject()
  add(query_774437, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774437.add "Filters", Filters
  add(query_774437, "Action", newJString(Action))
  add(query_774437, "Marker", newJString(Marker))
  add(query_774437, "SubscriptionName", newJString(SubscriptionName))
  add(query_774437, "Version", newJString(Version))
  result = call_774436.call(nil, query_774437, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_774419(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_774420, base: "/",
    url: url_GetDescribeEventSubscriptions_774421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_774482 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEvents_774484(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_774483(path: JsonNode; query: JsonNode;
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
  var valid_774485 = query.getOrDefault("Action")
  valid_774485 = validateParameter(valid_774485, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_774485 != nil:
    section.add "Action", valid_774485
  var valid_774486 = query.getOrDefault("Version")
  valid_774486 = validateParameter(valid_774486, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774486 != nil:
    section.add "Version", valid_774486
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774487 = header.getOrDefault("X-Amz-Date")
  valid_774487 = validateParameter(valid_774487, JString, required = false,
                                 default = nil)
  if valid_774487 != nil:
    section.add "X-Amz-Date", valid_774487
  var valid_774488 = header.getOrDefault("X-Amz-Security-Token")
  valid_774488 = validateParameter(valid_774488, JString, required = false,
                                 default = nil)
  if valid_774488 != nil:
    section.add "X-Amz-Security-Token", valid_774488
  var valid_774489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774489 = validateParameter(valid_774489, JString, required = false,
                                 default = nil)
  if valid_774489 != nil:
    section.add "X-Amz-Content-Sha256", valid_774489
  var valid_774490 = header.getOrDefault("X-Amz-Algorithm")
  valid_774490 = validateParameter(valid_774490, JString, required = false,
                                 default = nil)
  if valid_774490 != nil:
    section.add "X-Amz-Algorithm", valid_774490
  var valid_774491 = header.getOrDefault("X-Amz-Signature")
  valid_774491 = validateParameter(valid_774491, JString, required = false,
                                 default = nil)
  if valid_774491 != nil:
    section.add "X-Amz-Signature", valid_774491
  var valid_774492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774492 = validateParameter(valid_774492, JString, required = false,
                                 default = nil)
  if valid_774492 != nil:
    section.add "X-Amz-SignedHeaders", valid_774492
  var valid_774493 = header.getOrDefault("X-Amz-Credential")
  valid_774493 = validateParameter(valid_774493, JString, required = false,
                                 default = nil)
  if valid_774493 != nil:
    section.add "X-Amz-Credential", valid_774493
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
  var valid_774494 = formData.getOrDefault("SourceIdentifier")
  valid_774494 = validateParameter(valid_774494, JString, required = false,
                                 default = nil)
  if valid_774494 != nil:
    section.add "SourceIdentifier", valid_774494
  var valid_774495 = formData.getOrDefault("EventCategories")
  valid_774495 = validateParameter(valid_774495, JArray, required = false,
                                 default = nil)
  if valid_774495 != nil:
    section.add "EventCategories", valid_774495
  var valid_774496 = formData.getOrDefault("Marker")
  valid_774496 = validateParameter(valid_774496, JString, required = false,
                                 default = nil)
  if valid_774496 != nil:
    section.add "Marker", valid_774496
  var valid_774497 = formData.getOrDefault("StartTime")
  valid_774497 = validateParameter(valid_774497, JString, required = false,
                                 default = nil)
  if valid_774497 != nil:
    section.add "StartTime", valid_774497
  var valid_774498 = formData.getOrDefault("Duration")
  valid_774498 = validateParameter(valid_774498, JInt, required = false, default = nil)
  if valid_774498 != nil:
    section.add "Duration", valid_774498
  var valid_774499 = formData.getOrDefault("Filters")
  valid_774499 = validateParameter(valid_774499, JArray, required = false,
                                 default = nil)
  if valid_774499 != nil:
    section.add "Filters", valid_774499
  var valid_774500 = formData.getOrDefault("EndTime")
  valid_774500 = validateParameter(valid_774500, JString, required = false,
                                 default = nil)
  if valid_774500 != nil:
    section.add "EndTime", valid_774500
  var valid_774501 = formData.getOrDefault("MaxRecords")
  valid_774501 = validateParameter(valid_774501, JInt, required = false, default = nil)
  if valid_774501 != nil:
    section.add "MaxRecords", valid_774501
  var valid_774502 = formData.getOrDefault("SourceType")
  valid_774502 = validateParameter(valid_774502, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_774502 != nil:
    section.add "SourceType", valid_774502
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774503: Call_PostDescribeEvents_774482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774503.validator(path, query, header, formData, body)
  let scheme = call_774503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774503.url(scheme.get, call_774503.host, call_774503.base,
                         call_774503.route, valid.getOrDefault("path"))
  result = hook(call_774503, url, valid)

proc call*(call_774504: Call_PostDescribeEvents_774482;
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
  var query_774505 = newJObject()
  var formData_774506 = newJObject()
  add(formData_774506, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_774506.add "EventCategories", EventCategories
  add(formData_774506, "Marker", newJString(Marker))
  add(formData_774506, "StartTime", newJString(StartTime))
  add(query_774505, "Action", newJString(Action))
  add(formData_774506, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_774506.add "Filters", Filters
  add(formData_774506, "EndTime", newJString(EndTime))
  add(formData_774506, "MaxRecords", newJInt(MaxRecords))
  add(query_774505, "Version", newJString(Version))
  add(formData_774506, "SourceType", newJString(SourceType))
  result = call_774504.call(nil, query_774505, nil, formData_774506, nil)

var postDescribeEvents* = Call_PostDescribeEvents_774482(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_774483, base: "/",
    url: url_PostDescribeEvents_774484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_774458 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEvents_774460(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_774459(path: JsonNode; query: JsonNode;
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
  var valid_774461 = query.getOrDefault("SourceType")
  valid_774461 = validateParameter(valid_774461, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_774461 != nil:
    section.add "SourceType", valid_774461
  var valid_774462 = query.getOrDefault("MaxRecords")
  valid_774462 = validateParameter(valid_774462, JInt, required = false, default = nil)
  if valid_774462 != nil:
    section.add "MaxRecords", valid_774462
  var valid_774463 = query.getOrDefault("StartTime")
  valid_774463 = validateParameter(valid_774463, JString, required = false,
                                 default = nil)
  if valid_774463 != nil:
    section.add "StartTime", valid_774463
  var valid_774464 = query.getOrDefault("Filters")
  valid_774464 = validateParameter(valid_774464, JArray, required = false,
                                 default = nil)
  if valid_774464 != nil:
    section.add "Filters", valid_774464
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774465 = query.getOrDefault("Action")
  valid_774465 = validateParameter(valid_774465, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_774465 != nil:
    section.add "Action", valid_774465
  var valid_774466 = query.getOrDefault("SourceIdentifier")
  valid_774466 = validateParameter(valid_774466, JString, required = false,
                                 default = nil)
  if valid_774466 != nil:
    section.add "SourceIdentifier", valid_774466
  var valid_774467 = query.getOrDefault("Marker")
  valid_774467 = validateParameter(valid_774467, JString, required = false,
                                 default = nil)
  if valid_774467 != nil:
    section.add "Marker", valid_774467
  var valid_774468 = query.getOrDefault("EventCategories")
  valid_774468 = validateParameter(valid_774468, JArray, required = false,
                                 default = nil)
  if valid_774468 != nil:
    section.add "EventCategories", valid_774468
  var valid_774469 = query.getOrDefault("Duration")
  valid_774469 = validateParameter(valid_774469, JInt, required = false, default = nil)
  if valid_774469 != nil:
    section.add "Duration", valid_774469
  var valid_774470 = query.getOrDefault("EndTime")
  valid_774470 = validateParameter(valid_774470, JString, required = false,
                                 default = nil)
  if valid_774470 != nil:
    section.add "EndTime", valid_774470
  var valid_774471 = query.getOrDefault("Version")
  valid_774471 = validateParameter(valid_774471, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774471 != nil:
    section.add "Version", valid_774471
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774472 = header.getOrDefault("X-Amz-Date")
  valid_774472 = validateParameter(valid_774472, JString, required = false,
                                 default = nil)
  if valid_774472 != nil:
    section.add "X-Amz-Date", valid_774472
  var valid_774473 = header.getOrDefault("X-Amz-Security-Token")
  valid_774473 = validateParameter(valid_774473, JString, required = false,
                                 default = nil)
  if valid_774473 != nil:
    section.add "X-Amz-Security-Token", valid_774473
  var valid_774474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774474 = validateParameter(valid_774474, JString, required = false,
                                 default = nil)
  if valid_774474 != nil:
    section.add "X-Amz-Content-Sha256", valid_774474
  var valid_774475 = header.getOrDefault("X-Amz-Algorithm")
  valid_774475 = validateParameter(valid_774475, JString, required = false,
                                 default = nil)
  if valid_774475 != nil:
    section.add "X-Amz-Algorithm", valid_774475
  var valid_774476 = header.getOrDefault("X-Amz-Signature")
  valid_774476 = validateParameter(valid_774476, JString, required = false,
                                 default = nil)
  if valid_774476 != nil:
    section.add "X-Amz-Signature", valid_774476
  var valid_774477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774477 = validateParameter(valid_774477, JString, required = false,
                                 default = nil)
  if valid_774477 != nil:
    section.add "X-Amz-SignedHeaders", valid_774477
  var valid_774478 = header.getOrDefault("X-Amz-Credential")
  valid_774478 = validateParameter(valid_774478, JString, required = false,
                                 default = nil)
  if valid_774478 != nil:
    section.add "X-Amz-Credential", valid_774478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774479: Call_GetDescribeEvents_774458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774479.validator(path, query, header, formData, body)
  let scheme = call_774479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774479.url(scheme.get, call_774479.host, call_774479.base,
                         call_774479.route, valid.getOrDefault("path"))
  result = hook(call_774479, url, valid)

proc call*(call_774480: Call_GetDescribeEvents_774458;
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
  var query_774481 = newJObject()
  add(query_774481, "SourceType", newJString(SourceType))
  add(query_774481, "MaxRecords", newJInt(MaxRecords))
  add(query_774481, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_774481.add "Filters", Filters
  add(query_774481, "Action", newJString(Action))
  add(query_774481, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_774481, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_774481.add "EventCategories", EventCategories
  add(query_774481, "Duration", newJInt(Duration))
  add(query_774481, "EndTime", newJString(EndTime))
  add(query_774481, "Version", newJString(Version))
  result = call_774480.call(nil, query_774481, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_774458(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_774459,
    base: "/", url: url_GetDescribeEvents_774460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_774527 = ref object of OpenApiRestCall_772581
proc url_PostDescribeOptionGroupOptions_774529(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroupOptions_774528(path: JsonNode;
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
  var valid_774530 = query.getOrDefault("Action")
  valid_774530 = validateParameter(valid_774530, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_774530 != nil:
    section.add "Action", valid_774530
  var valid_774531 = query.getOrDefault("Version")
  valid_774531 = validateParameter(valid_774531, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774531 != nil:
    section.add "Version", valid_774531
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774532 = header.getOrDefault("X-Amz-Date")
  valid_774532 = validateParameter(valid_774532, JString, required = false,
                                 default = nil)
  if valid_774532 != nil:
    section.add "X-Amz-Date", valid_774532
  var valid_774533 = header.getOrDefault("X-Amz-Security-Token")
  valid_774533 = validateParameter(valid_774533, JString, required = false,
                                 default = nil)
  if valid_774533 != nil:
    section.add "X-Amz-Security-Token", valid_774533
  var valid_774534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774534 = validateParameter(valid_774534, JString, required = false,
                                 default = nil)
  if valid_774534 != nil:
    section.add "X-Amz-Content-Sha256", valid_774534
  var valid_774535 = header.getOrDefault("X-Amz-Algorithm")
  valid_774535 = validateParameter(valid_774535, JString, required = false,
                                 default = nil)
  if valid_774535 != nil:
    section.add "X-Amz-Algorithm", valid_774535
  var valid_774536 = header.getOrDefault("X-Amz-Signature")
  valid_774536 = validateParameter(valid_774536, JString, required = false,
                                 default = nil)
  if valid_774536 != nil:
    section.add "X-Amz-Signature", valid_774536
  var valid_774537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774537 = validateParameter(valid_774537, JString, required = false,
                                 default = nil)
  if valid_774537 != nil:
    section.add "X-Amz-SignedHeaders", valid_774537
  var valid_774538 = header.getOrDefault("X-Amz-Credential")
  valid_774538 = validateParameter(valid_774538, JString, required = false,
                                 default = nil)
  if valid_774538 != nil:
    section.add "X-Amz-Credential", valid_774538
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774539 = formData.getOrDefault("MajorEngineVersion")
  valid_774539 = validateParameter(valid_774539, JString, required = false,
                                 default = nil)
  if valid_774539 != nil:
    section.add "MajorEngineVersion", valid_774539
  var valid_774540 = formData.getOrDefault("Marker")
  valid_774540 = validateParameter(valid_774540, JString, required = false,
                                 default = nil)
  if valid_774540 != nil:
    section.add "Marker", valid_774540
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_774541 = formData.getOrDefault("EngineName")
  valid_774541 = validateParameter(valid_774541, JString, required = true,
                                 default = nil)
  if valid_774541 != nil:
    section.add "EngineName", valid_774541
  var valid_774542 = formData.getOrDefault("Filters")
  valid_774542 = validateParameter(valid_774542, JArray, required = false,
                                 default = nil)
  if valid_774542 != nil:
    section.add "Filters", valid_774542
  var valid_774543 = formData.getOrDefault("MaxRecords")
  valid_774543 = validateParameter(valid_774543, JInt, required = false, default = nil)
  if valid_774543 != nil:
    section.add "MaxRecords", valid_774543
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774544: Call_PostDescribeOptionGroupOptions_774527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774544.validator(path, query, header, formData, body)
  let scheme = call_774544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774544.url(scheme.get, call_774544.host, call_774544.base,
                         call_774544.route, valid.getOrDefault("path"))
  result = hook(call_774544, url, valid)

proc call*(call_774545: Call_PostDescribeOptionGroupOptions_774527;
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
  var query_774546 = newJObject()
  var formData_774547 = newJObject()
  add(formData_774547, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_774547, "Marker", newJString(Marker))
  add(query_774546, "Action", newJString(Action))
  add(formData_774547, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_774547.add "Filters", Filters
  add(formData_774547, "MaxRecords", newJInt(MaxRecords))
  add(query_774546, "Version", newJString(Version))
  result = call_774545.call(nil, query_774546, nil, formData_774547, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_774527(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_774528, base: "/",
    url: url_PostDescribeOptionGroupOptions_774529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_774507 = ref object of OpenApiRestCall_772581
proc url_GetDescribeOptionGroupOptions_774509(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroupOptions_774508(path: JsonNode; query: JsonNode;
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
  var valid_774510 = query.getOrDefault("MaxRecords")
  valid_774510 = validateParameter(valid_774510, JInt, required = false, default = nil)
  if valid_774510 != nil:
    section.add "MaxRecords", valid_774510
  var valid_774511 = query.getOrDefault("Filters")
  valid_774511 = validateParameter(valid_774511, JArray, required = false,
                                 default = nil)
  if valid_774511 != nil:
    section.add "Filters", valid_774511
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774512 = query.getOrDefault("Action")
  valid_774512 = validateParameter(valid_774512, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_774512 != nil:
    section.add "Action", valid_774512
  var valid_774513 = query.getOrDefault("Marker")
  valid_774513 = validateParameter(valid_774513, JString, required = false,
                                 default = nil)
  if valid_774513 != nil:
    section.add "Marker", valid_774513
  var valid_774514 = query.getOrDefault("Version")
  valid_774514 = validateParameter(valid_774514, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774514 != nil:
    section.add "Version", valid_774514
  var valid_774515 = query.getOrDefault("EngineName")
  valid_774515 = validateParameter(valid_774515, JString, required = true,
                                 default = nil)
  if valid_774515 != nil:
    section.add "EngineName", valid_774515
  var valid_774516 = query.getOrDefault("MajorEngineVersion")
  valid_774516 = validateParameter(valid_774516, JString, required = false,
                                 default = nil)
  if valid_774516 != nil:
    section.add "MajorEngineVersion", valid_774516
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774517 = header.getOrDefault("X-Amz-Date")
  valid_774517 = validateParameter(valid_774517, JString, required = false,
                                 default = nil)
  if valid_774517 != nil:
    section.add "X-Amz-Date", valid_774517
  var valid_774518 = header.getOrDefault("X-Amz-Security-Token")
  valid_774518 = validateParameter(valid_774518, JString, required = false,
                                 default = nil)
  if valid_774518 != nil:
    section.add "X-Amz-Security-Token", valid_774518
  var valid_774519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774519 = validateParameter(valid_774519, JString, required = false,
                                 default = nil)
  if valid_774519 != nil:
    section.add "X-Amz-Content-Sha256", valid_774519
  var valid_774520 = header.getOrDefault("X-Amz-Algorithm")
  valid_774520 = validateParameter(valid_774520, JString, required = false,
                                 default = nil)
  if valid_774520 != nil:
    section.add "X-Amz-Algorithm", valid_774520
  var valid_774521 = header.getOrDefault("X-Amz-Signature")
  valid_774521 = validateParameter(valid_774521, JString, required = false,
                                 default = nil)
  if valid_774521 != nil:
    section.add "X-Amz-Signature", valid_774521
  var valid_774522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774522 = validateParameter(valid_774522, JString, required = false,
                                 default = nil)
  if valid_774522 != nil:
    section.add "X-Amz-SignedHeaders", valid_774522
  var valid_774523 = header.getOrDefault("X-Amz-Credential")
  valid_774523 = validateParameter(valid_774523, JString, required = false,
                                 default = nil)
  if valid_774523 != nil:
    section.add "X-Amz-Credential", valid_774523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774524: Call_GetDescribeOptionGroupOptions_774507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774524.validator(path, query, header, formData, body)
  let scheme = call_774524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774524.url(scheme.get, call_774524.host, call_774524.base,
                         call_774524.route, valid.getOrDefault("path"))
  result = hook(call_774524, url, valid)

proc call*(call_774525: Call_GetDescribeOptionGroupOptions_774507;
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
  var query_774526 = newJObject()
  add(query_774526, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774526.add "Filters", Filters
  add(query_774526, "Action", newJString(Action))
  add(query_774526, "Marker", newJString(Marker))
  add(query_774526, "Version", newJString(Version))
  add(query_774526, "EngineName", newJString(EngineName))
  add(query_774526, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_774525.call(nil, query_774526, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_774507(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_774508, base: "/",
    url: url_GetDescribeOptionGroupOptions_774509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_774569 = ref object of OpenApiRestCall_772581
proc url_PostDescribeOptionGroups_774571(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroups_774570(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774572 = query.getOrDefault("Action")
  valid_774572 = validateParameter(valid_774572, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_774572 != nil:
    section.add "Action", valid_774572
  var valid_774573 = query.getOrDefault("Version")
  valid_774573 = validateParameter(valid_774573, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774573 != nil:
    section.add "Version", valid_774573
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774574 = header.getOrDefault("X-Amz-Date")
  valid_774574 = validateParameter(valid_774574, JString, required = false,
                                 default = nil)
  if valid_774574 != nil:
    section.add "X-Amz-Date", valid_774574
  var valid_774575 = header.getOrDefault("X-Amz-Security-Token")
  valid_774575 = validateParameter(valid_774575, JString, required = false,
                                 default = nil)
  if valid_774575 != nil:
    section.add "X-Amz-Security-Token", valid_774575
  var valid_774576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774576 = validateParameter(valid_774576, JString, required = false,
                                 default = nil)
  if valid_774576 != nil:
    section.add "X-Amz-Content-Sha256", valid_774576
  var valid_774577 = header.getOrDefault("X-Amz-Algorithm")
  valid_774577 = validateParameter(valid_774577, JString, required = false,
                                 default = nil)
  if valid_774577 != nil:
    section.add "X-Amz-Algorithm", valid_774577
  var valid_774578 = header.getOrDefault("X-Amz-Signature")
  valid_774578 = validateParameter(valid_774578, JString, required = false,
                                 default = nil)
  if valid_774578 != nil:
    section.add "X-Amz-Signature", valid_774578
  var valid_774579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774579 = validateParameter(valid_774579, JString, required = false,
                                 default = nil)
  if valid_774579 != nil:
    section.add "X-Amz-SignedHeaders", valid_774579
  var valid_774580 = header.getOrDefault("X-Amz-Credential")
  valid_774580 = validateParameter(valid_774580, JString, required = false,
                                 default = nil)
  if valid_774580 != nil:
    section.add "X-Amz-Credential", valid_774580
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774581 = formData.getOrDefault("MajorEngineVersion")
  valid_774581 = validateParameter(valid_774581, JString, required = false,
                                 default = nil)
  if valid_774581 != nil:
    section.add "MajorEngineVersion", valid_774581
  var valid_774582 = formData.getOrDefault("OptionGroupName")
  valid_774582 = validateParameter(valid_774582, JString, required = false,
                                 default = nil)
  if valid_774582 != nil:
    section.add "OptionGroupName", valid_774582
  var valid_774583 = formData.getOrDefault("Marker")
  valid_774583 = validateParameter(valid_774583, JString, required = false,
                                 default = nil)
  if valid_774583 != nil:
    section.add "Marker", valid_774583
  var valid_774584 = formData.getOrDefault("EngineName")
  valid_774584 = validateParameter(valid_774584, JString, required = false,
                                 default = nil)
  if valid_774584 != nil:
    section.add "EngineName", valid_774584
  var valid_774585 = formData.getOrDefault("Filters")
  valid_774585 = validateParameter(valid_774585, JArray, required = false,
                                 default = nil)
  if valid_774585 != nil:
    section.add "Filters", valid_774585
  var valid_774586 = formData.getOrDefault("MaxRecords")
  valid_774586 = validateParameter(valid_774586, JInt, required = false, default = nil)
  if valid_774586 != nil:
    section.add "MaxRecords", valid_774586
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774587: Call_PostDescribeOptionGroups_774569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774587.validator(path, query, header, formData, body)
  let scheme = call_774587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774587.url(scheme.get, call_774587.host, call_774587.base,
                         call_774587.route, valid.getOrDefault("path"))
  result = hook(call_774587, url, valid)

proc call*(call_774588: Call_PostDescribeOptionGroups_774569;
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
  var query_774589 = newJObject()
  var formData_774590 = newJObject()
  add(formData_774590, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_774590, "OptionGroupName", newJString(OptionGroupName))
  add(formData_774590, "Marker", newJString(Marker))
  add(query_774589, "Action", newJString(Action))
  add(formData_774590, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_774590.add "Filters", Filters
  add(formData_774590, "MaxRecords", newJInt(MaxRecords))
  add(query_774589, "Version", newJString(Version))
  result = call_774588.call(nil, query_774589, nil, formData_774590, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_774569(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_774570, base: "/",
    url: url_PostDescribeOptionGroups_774571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_774548 = ref object of OpenApiRestCall_772581
proc url_GetDescribeOptionGroups_774550(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroups_774549(path: JsonNode; query: JsonNode;
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
  var valid_774551 = query.getOrDefault("MaxRecords")
  valid_774551 = validateParameter(valid_774551, JInt, required = false, default = nil)
  if valid_774551 != nil:
    section.add "MaxRecords", valid_774551
  var valid_774552 = query.getOrDefault("OptionGroupName")
  valid_774552 = validateParameter(valid_774552, JString, required = false,
                                 default = nil)
  if valid_774552 != nil:
    section.add "OptionGroupName", valid_774552
  var valid_774553 = query.getOrDefault("Filters")
  valid_774553 = validateParameter(valid_774553, JArray, required = false,
                                 default = nil)
  if valid_774553 != nil:
    section.add "Filters", valid_774553
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774554 = query.getOrDefault("Action")
  valid_774554 = validateParameter(valid_774554, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_774554 != nil:
    section.add "Action", valid_774554
  var valid_774555 = query.getOrDefault("Marker")
  valid_774555 = validateParameter(valid_774555, JString, required = false,
                                 default = nil)
  if valid_774555 != nil:
    section.add "Marker", valid_774555
  var valid_774556 = query.getOrDefault("Version")
  valid_774556 = validateParameter(valid_774556, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774556 != nil:
    section.add "Version", valid_774556
  var valid_774557 = query.getOrDefault("EngineName")
  valid_774557 = validateParameter(valid_774557, JString, required = false,
                                 default = nil)
  if valid_774557 != nil:
    section.add "EngineName", valid_774557
  var valid_774558 = query.getOrDefault("MajorEngineVersion")
  valid_774558 = validateParameter(valid_774558, JString, required = false,
                                 default = nil)
  if valid_774558 != nil:
    section.add "MajorEngineVersion", valid_774558
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774559 = header.getOrDefault("X-Amz-Date")
  valid_774559 = validateParameter(valid_774559, JString, required = false,
                                 default = nil)
  if valid_774559 != nil:
    section.add "X-Amz-Date", valid_774559
  var valid_774560 = header.getOrDefault("X-Amz-Security-Token")
  valid_774560 = validateParameter(valid_774560, JString, required = false,
                                 default = nil)
  if valid_774560 != nil:
    section.add "X-Amz-Security-Token", valid_774560
  var valid_774561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774561 = validateParameter(valid_774561, JString, required = false,
                                 default = nil)
  if valid_774561 != nil:
    section.add "X-Amz-Content-Sha256", valid_774561
  var valid_774562 = header.getOrDefault("X-Amz-Algorithm")
  valid_774562 = validateParameter(valid_774562, JString, required = false,
                                 default = nil)
  if valid_774562 != nil:
    section.add "X-Amz-Algorithm", valid_774562
  var valid_774563 = header.getOrDefault("X-Amz-Signature")
  valid_774563 = validateParameter(valid_774563, JString, required = false,
                                 default = nil)
  if valid_774563 != nil:
    section.add "X-Amz-Signature", valid_774563
  var valid_774564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774564 = validateParameter(valid_774564, JString, required = false,
                                 default = nil)
  if valid_774564 != nil:
    section.add "X-Amz-SignedHeaders", valid_774564
  var valid_774565 = header.getOrDefault("X-Amz-Credential")
  valid_774565 = validateParameter(valid_774565, JString, required = false,
                                 default = nil)
  if valid_774565 != nil:
    section.add "X-Amz-Credential", valid_774565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774566: Call_GetDescribeOptionGroups_774548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774566.validator(path, query, header, formData, body)
  let scheme = call_774566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774566.url(scheme.get, call_774566.host, call_774566.base,
                         call_774566.route, valid.getOrDefault("path"))
  result = hook(call_774566, url, valid)

proc call*(call_774567: Call_GetDescribeOptionGroups_774548; MaxRecords: int = 0;
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
  var query_774568 = newJObject()
  add(query_774568, "MaxRecords", newJInt(MaxRecords))
  add(query_774568, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_774568.add "Filters", Filters
  add(query_774568, "Action", newJString(Action))
  add(query_774568, "Marker", newJString(Marker))
  add(query_774568, "Version", newJString(Version))
  add(query_774568, "EngineName", newJString(EngineName))
  add(query_774568, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_774567.call(nil, query_774568, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_774548(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_774549, base: "/",
    url: url_GetDescribeOptionGroups_774550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_774614 = ref object of OpenApiRestCall_772581
proc url_PostDescribeOrderableDBInstanceOptions_774616(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOrderableDBInstanceOptions_774615(path: JsonNode;
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
  var valid_774617 = query.getOrDefault("Action")
  valid_774617 = validateParameter(valid_774617, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_774617 != nil:
    section.add "Action", valid_774617
  var valid_774618 = query.getOrDefault("Version")
  valid_774618 = validateParameter(valid_774618, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774618 != nil:
    section.add "Version", valid_774618
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774619 = header.getOrDefault("X-Amz-Date")
  valid_774619 = validateParameter(valid_774619, JString, required = false,
                                 default = nil)
  if valid_774619 != nil:
    section.add "X-Amz-Date", valid_774619
  var valid_774620 = header.getOrDefault("X-Amz-Security-Token")
  valid_774620 = validateParameter(valid_774620, JString, required = false,
                                 default = nil)
  if valid_774620 != nil:
    section.add "X-Amz-Security-Token", valid_774620
  var valid_774621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774621 = validateParameter(valid_774621, JString, required = false,
                                 default = nil)
  if valid_774621 != nil:
    section.add "X-Amz-Content-Sha256", valid_774621
  var valid_774622 = header.getOrDefault("X-Amz-Algorithm")
  valid_774622 = validateParameter(valid_774622, JString, required = false,
                                 default = nil)
  if valid_774622 != nil:
    section.add "X-Amz-Algorithm", valid_774622
  var valid_774623 = header.getOrDefault("X-Amz-Signature")
  valid_774623 = validateParameter(valid_774623, JString, required = false,
                                 default = nil)
  if valid_774623 != nil:
    section.add "X-Amz-Signature", valid_774623
  var valid_774624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774624 = validateParameter(valid_774624, JString, required = false,
                                 default = nil)
  if valid_774624 != nil:
    section.add "X-Amz-SignedHeaders", valid_774624
  var valid_774625 = header.getOrDefault("X-Amz-Credential")
  valid_774625 = validateParameter(valid_774625, JString, required = false,
                                 default = nil)
  if valid_774625 != nil:
    section.add "X-Amz-Credential", valid_774625
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
  var valid_774626 = formData.getOrDefault("Engine")
  valid_774626 = validateParameter(valid_774626, JString, required = true,
                                 default = nil)
  if valid_774626 != nil:
    section.add "Engine", valid_774626
  var valid_774627 = formData.getOrDefault("Marker")
  valid_774627 = validateParameter(valid_774627, JString, required = false,
                                 default = nil)
  if valid_774627 != nil:
    section.add "Marker", valid_774627
  var valid_774628 = formData.getOrDefault("Vpc")
  valid_774628 = validateParameter(valid_774628, JBool, required = false, default = nil)
  if valid_774628 != nil:
    section.add "Vpc", valid_774628
  var valid_774629 = formData.getOrDefault("DBInstanceClass")
  valid_774629 = validateParameter(valid_774629, JString, required = false,
                                 default = nil)
  if valid_774629 != nil:
    section.add "DBInstanceClass", valid_774629
  var valid_774630 = formData.getOrDefault("Filters")
  valid_774630 = validateParameter(valid_774630, JArray, required = false,
                                 default = nil)
  if valid_774630 != nil:
    section.add "Filters", valid_774630
  var valid_774631 = formData.getOrDefault("LicenseModel")
  valid_774631 = validateParameter(valid_774631, JString, required = false,
                                 default = nil)
  if valid_774631 != nil:
    section.add "LicenseModel", valid_774631
  var valid_774632 = formData.getOrDefault("MaxRecords")
  valid_774632 = validateParameter(valid_774632, JInt, required = false, default = nil)
  if valid_774632 != nil:
    section.add "MaxRecords", valid_774632
  var valid_774633 = formData.getOrDefault("EngineVersion")
  valid_774633 = validateParameter(valid_774633, JString, required = false,
                                 default = nil)
  if valid_774633 != nil:
    section.add "EngineVersion", valid_774633
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774634: Call_PostDescribeOrderableDBInstanceOptions_774614;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774634.validator(path, query, header, formData, body)
  let scheme = call_774634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774634.url(scheme.get, call_774634.host, call_774634.base,
                         call_774634.route, valid.getOrDefault("path"))
  result = hook(call_774634, url, valid)

proc call*(call_774635: Call_PostDescribeOrderableDBInstanceOptions_774614;
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
  var query_774636 = newJObject()
  var formData_774637 = newJObject()
  add(formData_774637, "Engine", newJString(Engine))
  add(formData_774637, "Marker", newJString(Marker))
  add(query_774636, "Action", newJString(Action))
  add(formData_774637, "Vpc", newJBool(Vpc))
  add(formData_774637, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_774637.add "Filters", Filters
  add(formData_774637, "LicenseModel", newJString(LicenseModel))
  add(formData_774637, "MaxRecords", newJInt(MaxRecords))
  add(formData_774637, "EngineVersion", newJString(EngineVersion))
  add(query_774636, "Version", newJString(Version))
  result = call_774635.call(nil, query_774636, nil, formData_774637, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_774614(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_774615, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_774616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_774591 = ref object of OpenApiRestCall_772581
proc url_GetDescribeOrderableDBInstanceOptions_774593(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOrderableDBInstanceOptions_774592(path: JsonNode;
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
  var valid_774594 = query.getOrDefault("Engine")
  valid_774594 = validateParameter(valid_774594, JString, required = true,
                                 default = nil)
  if valid_774594 != nil:
    section.add "Engine", valid_774594
  var valid_774595 = query.getOrDefault("MaxRecords")
  valid_774595 = validateParameter(valid_774595, JInt, required = false, default = nil)
  if valid_774595 != nil:
    section.add "MaxRecords", valid_774595
  var valid_774596 = query.getOrDefault("Filters")
  valid_774596 = validateParameter(valid_774596, JArray, required = false,
                                 default = nil)
  if valid_774596 != nil:
    section.add "Filters", valid_774596
  var valid_774597 = query.getOrDefault("LicenseModel")
  valid_774597 = validateParameter(valid_774597, JString, required = false,
                                 default = nil)
  if valid_774597 != nil:
    section.add "LicenseModel", valid_774597
  var valid_774598 = query.getOrDefault("Vpc")
  valid_774598 = validateParameter(valid_774598, JBool, required = false, default = nil)
  if valid_774598 != nil:
    section.add "Vpc", valid_774598
  var valid_774599 = query.getOrDefault("DBInstanceClass")
  valid_774599 = validateParameter(valid_774599, JString, required = false,
                                 default = nil)
  if valid_774599 != nil:
    section.add "DBInstanceClass", valid_774599
  var valid_774600 = query.getOrDefault("Action")
  valid_774600 = validateParameter(valid_774600, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_774600 != nil:
    section.add "Action", valid_774600
  var valid_774601 = query.getOrDefault("Marker")
  valid_774601 = validateParameter(valid_774601, JString, required = false,
                                 default = nil)
  if valid_774601 != nil:
    section.add "Marker", valid_774601
  var valid_774602 = query.getOrDefault("EngineVersion")
  valid_774602 = validateParameter(valid_774602, JString, required = false,
                                 default = nil)
  if valid_774602 != nil:
    section.add "EngineVersion", valid_774602
  var valid_774603 = query.getOrDefault("Version")
  valid_774603 = validateParameter(valid_774603, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774603 != nil:
    section.add "Version", valid_774603
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774604 = header.getOrDefault("X-Amz-Date")
  valid_774604 = validateParameter(valid_774604, JString, required = false,
                                 default = nil)
  if valid_774604 != nil:
    section.add "X-Amz-Date", valid_774604
  var valid_774605 = header.getOrDefault("X-Amz-Security-Token")
  valid_774605 = validateParameter(valid_774605, JString, required = false,
                                 default = nil)
  if valid_774605 != nil:
    section.add "X-Amz-Security-Token", valid_774605
  var valid_774606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774606 = validateParameter(valid_774606, JString, required = false,
                                 default = nil)
  if valid_774606 != nil:
    section.add "X-Amz-Content-Sha256", valid_774606
  var valid_774607 = header.getOrDefault("X-Amz-Algorithm")
  valid_774607 = validateParameter(valid_774607, JString, required = false,
                                 default = nil)
  if valid_774607 != nil:
    section.add "X-Amz-Algorithm", valid_774607
  var valid_774608 = header.getOrDefault("X-Amz-Signature")
  valid_774608 = validateParameter(valid_774608, JString, required = false,
                                 default = nil)
  if valid_774608 != nil:
    section.add "X-Amz-Signature", valid_774608
  var valid_774609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774609 = validateParameter(valid_774609, JString, required = false,
                                 default = nil)
  if valid_774609 != nil:
    section.add "X-Amz-SignedHeaders", valid_774609
  var valid_774610 = header.getOrDefault("X-Amz-Credential")
  valid_774610 = validateParameter(valid_774610, JString, required = false,
                                 default = nil)
  if valid_774610 != nil:
    section.add "X-Amz-Credential", valid_774610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774611: Call_GetDescribeOrderableDBInstanceOptions_774591;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774611.validator(path, query, header, formData, body)
  let scheme = call_774611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774611.url(scheme.get, call_774611.host, call_774611.base,
                         call_774611.route, valid.getOrDefault("path"))
  result = hook(call_774611, url, valid)

proc call*(call_774612: Call_GetDescribeOrderableDBInstanceOptions_774591;
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
  var query_774613 = newJObject()
  add(query_774613, "Engine", newJString(Engine))
  add(query_774613, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774613.add "Filters", Filters
  add(query_774613, "LicenseModel", newJString(LicenseModel))
  add(query_774613, "Vpc", newJBool(Vpc))
  add(query_774613, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774613, "Action", newJString(Action))
  add(query_774613, "Marker", newJString(Marker))
  add(query_774613, "EngineVersion", newJString(EngineVersion))
  add(query_774613, "Version", newJString(Version))
  result = call_774612.call(nil, query_774613, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_774591(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_774592, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_774593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_774663 = ref object of OpenApiRestCall_772581
proc url_PostDescribeReservedDBInstances_774665(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstances_774664(path: JsonNode;
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
  var valid_774666 = query.getOrDefault("Action")
  valid_774666 = validateParameter(valid_774666, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_774666 != nil:
    section.add "Action", valid_774666
  var valid_774667 = query.getOrDefault("Version")
  valid_774667 = validateParameter(valid_774667, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774667 != nil:
    section.add "Version", valid_774667
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774668 = header.getOrDefault("X-Amz-Date")
  valid_774668 = validateParameter(valid_774668, JString, required = false,
                                 default = nil)
  if valid_774668 != nil:
    section.add "X-Amz-Date", valid_774668
  var valid_774669 = header.getOrDefault("X-Amz-Security-Token")
  valid_774669 = validateParameter(valid_774669, JString, required = false,
                                 default = nil)
  if valid_774669 != nil:
    section.add "X-Amz-Security-Token", valid_774669
  var valid_774670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774670 = validateParameter(valid_774670, JString, required = false,
                                 default = nil)
  if valid_774670 != nil:
    section.add "X-Amz-Content-Sha256", valid_774670
  var valid_774671 = header.getOrDefault("X-Amz-Algorithm")
  valid_774671 = validateParameter(valid_774671, JString, required = false,
                                 default = nil)
  if valid_774671 != nil:
    section.add "X-Amz-Algorithm", valid_774671
  var valid_774672 = header.getOrDefault("X-Amz-Signature")
  valid_774672 = validateParameter(valid_774672, JString, required = false,
                                 default = nil)
  if valid_774672 != nil:
    section.add "X-Amz-Signature", valid_774672
  var valid_774673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774673 = validateParameter(valid_774673, JString, required = false,
                                 default = nil)
  if valid_774673 != nil:
    section.add "X-Amz-SignedHeaders", valid_774673
  var valid_774674 = header.getOrDefault("X-Amz-Credential")
  valid_774674 = validateParameter(valid_774674, JString, required = false,
                                 default = nil)
  if valid_774674 != nil:
    section.add "X-Amz-Credential", valid_774674
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
  var valid_774675 = formData.getOrDefault("OfferingType")
  valid_774675 = validateParameter(valid_774675, JString, required = false,
                                 default = nil)
  if valid_774675 != nil:
    section.add "OfferingType", valid_774675
  var valid_774676 = formData.getOrDefault("ReservedDBInstanceId")
  valid_774676 = validateParameter(valid_774676, JString, required = false,
                                 default = nil)
  if valid_774676 != nil:
    section.add "ReservedDBInstanceId", valid_774676
  var valid_774677 = formData.getOrDefault("Marker")
  valid_774677 = validateParameter(valid_774677, JString, required = false,
                                 default = nil)
  if valid_774677 != nil:
    section.add "Marker", valid_774677
  var valid_774678 = formData.getOrDefault("MultiAZ")
  valid_774678 = validateParameter(valid_774678, JBool, required = false, default = nil)
  if valid_774678 != nil:
    section.add "MultiAZ", valid_774678
  var valid_774679 = formData.getOrDefault("Duration")
  valid_774679 = validateParameter(valid_774679, JString, required = false,
                                 default = nil)
  if valid_774679 != nil:
    section.add "Duration", valid_774679
  var valid_774680 = formData.getOrDefault("DBInstanceClass")
  valid_774680 = validateParameter(valid_774680, JString, required = false,
                                 default = nil)
  if valid_774680 != nil:
    section.add "DBInstanceClass", valid_774680
  var valid_774681 = formData.getOrDefault("Filters")
  valid_774681 = validateParameter(valid_774681, JArray, required = false,
                                 default = nil)
  if valid_774681 != nil:
    section.add "Filters", valid_774681
  var valid_774682 = formData.getOrDefault("ProductDescription")
  valid_774682 = validateParameter(valid_774682, JString, required = false,
                                 default = nil)
  if valid_774682 != nil:
    section.add "ProductDescription", valid_774682
  var valid_774683 = formData.getOrDefault("MaxRecords")
  valid_774683 = validateParameter(valid_774683, JInt, required = false, default = nil)
  if valid_774683 != nil:
    section.add "MaxRecords", valid_774683
  var valid_774684 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774684 = validateParameter(valid_774684, JString, required = false,
                                 default = nil)
  if valid_774684 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774684
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774685: Call_PostDescribeReservedDBInstances_774663;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774685.validator(path, query, header, formData, body)
  let scheme = call_774685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774685.url(scheme.get, call_774685.host, call_774685.base,
                         call_774685.route, valid.getOrDefault("path"))
  result = hook(call_774685, url, valid)

proc call*(call_774686: Call_PostDescribeReservedDBInstances_774663;
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
  var query_774687 = newJObject()
  var formData_774688 = newJObject()
  add(formData_774688, "OfferingType", newJString(OfferingType))
  add(formData_774688, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_774688, "Marker", newJString(Marker))
  add(formData_774688, "MultiAZ", newJBool(MultiAZ))
  add(query_774687, "Action", newJString(Action))
  add(formData_774688, "Duration", newJString(Duration))
  add(formData_774688, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_774688.add "Filters", Filters
  add(formData_774688, "ProductDescription", newJString(ProductDescription))
  add(formData_774688, "MaxRecords", newJInt(MaxRecords))
  add(formData_774688, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774687, "Version", newJString(Version))
  result = call_774686.call(nil, query_774687, nil, formData_774688, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_774663(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_774664, base: "/",
    url: url_PostDescribeReservedDBInstances_774665,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_774638 = ref object of OpenApiRestCall_772581
proc url_GetDescribeReservedDBInstances_774640(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstances_774639(path: JsonNode;
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
  var valid_774641 = query.getOrDefault("ProductDescription")
  valid_774641 = validateParameter(valid_774641, JString, required = false,
                                 default = nil)
  if valid_774641 != nil:
    section.add "ProductDescription", valid_774641
  var valid_774642 = query.getOrDefault("MaxRecords")
  valid_774642 = validateParameter(valid_774642, JInt, required = false, default = nil)
  if valid_774642 != nil:
    section.add "MaxRecords", valid_774642
  var valid_774643 = query.getOrDefault("OfferingType")
  valid_774643 = validateParameter(valid_774643, JString, required = false,
                                 default = nil)
  if valid_774643 != nil:
    section.add "OfferingType", valid_774643
  var valid_774644 = query.getOrDefault("Filters")
  valid_774644 = validateParameter(valid_774644, JArray, required = false,
                                 default = nil)
  if valid_774644 != nil:
    section.add "Filters", valid_774644
  var valid_774645 = query.getOrDefault("MultiAZ")
  valid_774645 = validateParameter(valid_774645, JBool, required = false, default = nil)
  if valid_774645 != nil:
    section.add "MultiAZ", valid_774645
  var valid_774646 = query.getOrDefault("ReservedDBInstanceId")
  valid_774646 = validateParameter(valid_774646, JString, required = false,
                                 default = nil)
  if valid_774646 != nil:
    section.add "ReservedDBInstanceId", valid_774646
  var valid_774647 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774647 = validateParameter(valid_774647, JString, required = false,
                                 default = nil)
  if valid_774647 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774647
  var valid_774648 = query.getOrDefault("DBInstanceClass")
  valid_774648 = validateParameter(valid_774648, JString, required = false,
                                 default = nil)
  if valid_774648 != nil:
    section.add "DBInstanceClass", valid_774648
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774649 = query.getOrDefault("Action")
  valid_774649 = validateParameter(valid_774649, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_774649 != nil:
    section.add "Action", valid_774649
  var valid_774650 = query.getOrDefault("Marker")
  valid_774650 = validateParameter(valid_774650, JString, required = false,
                                 default = nil)
  if valid_774650 != nil:
    section.add "Marker", valid_774650
  var valid_774651 = query.getOrDefault("Duration")
  valid_774651 = validateParameter(valid_774651, JString, required = false,
                                 default = nil)
  if valid_774651 != nil:
    section.add "Duration", valid_774651
  var valid_774652 = query.getOrDefault("Version")
  valid_774652 = validateParameter(valid_774652, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774652 != nil:
    section.add "Version", valid_774652
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774653 = header.getOrDefault("X-Amz-Date")
  valid_774653 = validateParameter(valid_774653, JString, required = false,
                                 default = nil)
  if valid_774653 != nil:
    section.add "X-Amz-Date", valid_774653
  var valid_774654 = header.getOrDefault("X-Amz-Security-Token")
  valid_774654 = validateParameter(valid_774654, JString, required = false,
                                 default = nil)
  if valid_774654 != nil:
    section.add "X-Amz-Security-Token", valid_774654
  var valid_774655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774655 = validateParameter(valid_774655, JString, required = false,
                                 default = nil)
  if valid_774655 != nil:
    section.add "X-Amz-Content-Sha256", valid_774655
  var valid_774656 = header.getOrDefault("X-Amz-Algorithm")
  valid_774656 = validateParameter(valid_774656, JString, required = false,
                                 default = nil)
  if valid_774656 != nil:
    section.add "X-Amz-Algorithm", valid_774656
  var valid_774657 = header.getOrDefault("X-Amz-Signature")
  valid_774657 = validateParameter(valid_774657, JString, required = false,
                                 default = nil)
  if valid_774657 != nil:
    section.add "X-Amz-Signature", valid_774657
  var valid_774658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774658 = validateParameter(valid_774658, JString, required = false,
                                 default = nil)
  if valid_774658 != nil:
    section.add "X-Amz-SignedHeaders", valid_774658
  var valid_774659 = header.getOrDefault("X-Amz-Credential")
  valid_774659 = validateParameter(valid_774659, JString, required = false,
                                 default = nil)
  if valid_774659 != nil:
    section.add "X-Amz-Credential", valid_774659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774660: Call_GetDescribeReservedDBInstances_774638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774660.validator(path, query, header, formData, body)
  let scheme = call_774660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774660.url(scheme.get, call_774660.host, call_774660.base,
                         call_774660.route, valid.getOrDefault("path"))
  result = hook(call_774660, url, valid)

proc call*(call_774661: Call_GetDescribeReservedDBInstances_774638;
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
  var query_774662 = newJObject()
  add(query_774662, "ProductDescription", newJString(ProductDescription))
  add(query_774662, "MaxRecords", newJInt(MaxRecords))
  add(query_774662, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_774662.add "Filters", Filters
  add(query_774662, "MultiAZ", newJBool(MultiAZ))
  add(query_774662, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_774662, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774662, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774662, "Action", newJString(Action))
  add(query_774662, "Marker", newJString(Marker))
  add(query_774662, "Duration", newJString(Duration))
  add(query_774662, "Version", newJString(Version))
  result = call_774661.call(nil, query_774662, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_774638(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_774639, base: "/",
    url: url_GetDescribeReservedDBInstances_774640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_774713 = ref object of OpenApiRestCall_772581
proc url_PostDescribeReservedDBInstancesOfferings_774715(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstancesOfferings_774714(path: JsonNode;
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
  var valid_774716 = query.getOrDefault("Action")
  valid_774716 = validateParameter(valid_774716, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_774716 != nil:
    section.add "Action", valid_774716
  var valid_774717 = query.getOrDefault("Version")
  valid_774717 = validateParameter(valid_774717, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774717 != nil:
    section.add "Version", valid_774717
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774718 = header.getOrDefault("X-Amz-Date")
  valid_774718 = validateParameter(valid_774718, JString, required = false,
                                 default = nil)
  if valid_774718 != nil:
    section.add "X-Amz-Date", valid_774718
  var valid_774719 = header.getOrDefault("X-Amz-Security-Token")
  valid_774719 = validateParameter(valid_774719, JString, required = false,
                                 default = nil)
  if valid_774719 != nil:
    section.add "X-Amz-Security-Token", valid_774719
  var valid_774720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774720 = validateParameter(valid_774720, JString, required = false,
                                 default = nil)
  if valid_774720 != nil:
    section.add "X-Amz-Content-Sha256", valid_774720
  var valid_774721 = header.getOrDefault("X-Amz-Algorithm")
  valid_774721 = validateParameter(valid_774721, JString, required = false,
                                 default = nil)
  if valid_774721 != nil:
    section.add "X-Amz-Algorithm", valid_774721
  var valid_774722 = header.getOrDefault("X-Amz-Signature")
  valid_774722 = validateParameter(valid_774722, JString, required = false,
                                 default = nil)
  if valid_774722 != nil:
    section.add "X-Amz-Signature", valid_774722
  var valid_774723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774723 = validateParameter(valid_774723, JString, required = false,
                                 default = nil)
  if valid_774723 != nil:
    section.add "X-Amz-SignedHeaders", valid_774723
  var valid_774724 = header.getOrDefault("X-Amz-Credential")
  valid_774724 = validateParameter(valid_774724, JString, required = false,
                                 default = nil)
  if valid_774724 != nil:
    section.add "X-Amz-Credential", valid_774724
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
  var valid_774725 = formData.getOrDefault("OfferingType")
  valid_774725 = validateParameter(valid_774725, JString, required = false,
                                 default = nil)
  if valid_774725 != nil:
    section.add "OfferingType", valid_774725
  var valid_774726 = formData.getOrDefault("Marker")
  valid_774726 = validateParameter(valid_774726, JString, required = false,
                                 default = nil)
  if valid_774726 != nil:
    section.add "Marker", valid_774726
  var valid_774727 = formData.getOrDefault("MultiAZ")
  valid_774727 = validateParameter(valid_774727, JBool, required = false, default = nil)
  if valid_774727 != nil:
    section.add "MultiAZ", valid_774727
  var valid_774728 = formData.getOrDefault("Duration")
  valid_774728 = validateParameter(valid_774728, JString, required = false,
                                 default = nil)
  if valid_774728 != nil:
    section.add "Duration", valid_774728
  var valid_774729 = formData.getOrDefault("DBInstanceClass")
  valid_774729 = validateParameter(valid_774729, JString, required = false,
                                 default = nil)
  if valid_774729 != nil:
    section.add "DBInstanceClass", valid_774729
  var valid_774730 = formData.getOrDefault("Filters")
  valid_774730 = validateParameter(valid_774730, JArray, required = false,
                                 default = nil)
  if valid_774730 != nil:
    section.add "Filters", valid_774730
  var valid_774731 = formData.getOrDefault("ProductDescription")
  valid_774731 = validateParameter(valid_774731, JString, required = false,
                                 default = nil)
  if valid_774731 != nil:
    section.add "ProductDescription", valid_774731
  var valid_774732 = formData.getOrDefault("MaxRecords")
  valid_774732 = validateParameter(valid_774732, JInt, required = false, default = nil)
  if valid_774732 != nil:
    section.add "MaxRecords", valid_774732
  var valid_774733 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774733 = validateParameter(valid_774733, JString, required = false,
                                 default = nil)
  if valid_774733 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774733
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774734: Call_PostDescribeReservedDBInstancesOfferings_774713;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774734.validator(path, query, header, formData, body)
  let scheme = call_774734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774734.url(scheme.get, call_774734.host, call_774734.base,
                         call_774734.route, valid.getOrDefault("path"))
  result = hook(call_774734, url, valid)

proc call*(call_774735: Call_PostDescribeReservedDBInstancesOfferings_774713;
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
  var query_774736 = newJObject()
  var formData_774737 = newJObject()
  add(formData_774737, "OfferingType", newJString(OfferingType))
  add(formData_774737, "Marker", newJString(Marker))
  add(formData_774737, "MultiAZ", newJBool(MultiAZ))
  add(query_774736, "Action", newJString(Action))
  add(formData_774737, "Duration", newJString(Duration))
  add(formData_774737, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_774737.add "Filters", Filters
  add(formData_774737, "ProductDescription", newJString(ProductDescription))
  add(formData_774737, "MaxRecords", newJInt(MaxRecords))
  add(formData_774737, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774736, "Version", newJString(Version))
  result = call_774735.call(nil, query_774736, nil, formData_774737, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_774713(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_774714,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_774715,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_774689 = ref object of OpenApiRestCall_772581
proc url_GetDescribeReservedDBInstancesOfferings_774691(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstancesOfferings_774690(path: JsonNode;
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
  var valid_774692 = query.getOrDefault("ProductDescription")
  valid_774692 = validateParameter(valid_774692, JString, required = false,
                                 default = nil)
  if valid_774692 != nil:
    section.add "ProductDescription", valid_774692
  var valid_774693 = query.getOrDefault("MaxRecords")
  valid_774693 = validateParameter(valid_774693, JInt, required = false, default = nil)
  if valid_774693 != nil:
    section.add "MaxRecords", valid_774693
  var valid_774694 = query.getOrDefault("OfferingType")
  valid_774694 = validateParameter(valid_774694, JString, required = false,
                                 default = nil)
  if valid_774694 != nil:
    section.add "OfferingType", valid_774694
  var valid_774695 = query.getOrDefault("Filters")
  valid_774695 = validateParameter(valid_774695, JArray, required = false,
                                 default = nil)
  if valid_774695 != nil:
    section.add "Filters", valid_774695
  var valid_774696 = query.getOrDefault("MultiAZ")
  valid_774696 = validateParameter(valid_774696, JBool, required = false, default = nil)
  if valid_774696 != nil:
    section.add "MultiAZ", valid_774696
  var valid_774697 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774697 = validateParameter(valid_774697, JString, required = false,
                                 default = nil)
  if valid_774697 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774697
  var valid_774698 = query.getOrDefault("DBInstanceClass")
  valid_774698 = validateParameter(valid_774698, JString, required = false,
                                 default = nil)
  if valid_774698 != nil:
    section.add "DBInstanceClass", valid_774698
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774699 = query.getOrDefault("Action")
  valid_774699 = validateParameter(valid_774699, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_774699 != nil:
    section.add "Action", valid_774699
  var valid_774700 = query.getOrDefault("Marker")
  valid_774700 = validateParameter(valid_774700, JString, required = false,
                                 default = nil)
  if valid_774700 != nil:
    section.add "Marker", valid_774700
  var valid_774701 = query.getOrDefault("Duration")
  valid_774701 = validateParameter(valid_774701, JString, required = false,
                                 default = nil)
  if valid_774701 != nil:
    section.add "Duration", valid_774701
  var valid_774702 = query.getOrDefault("Version")
  valid_774702 = validateParameter(valid_774702, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774702 != nil:
    section.add "Version", valid_774702
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774703 = header.getOrDefault("X-Amz-Date")
  valid_774703 = validateParameter(valid_774703, JString, required = false,
                                 default = nil)
  if valid_774703 != nil:
    section.add "X-Amz-Date", valid_774703
  var valid_774704 = header.getOrDefault("X-Amz-Security-Token")
  valid_774704 = validateParameter(valid_774704, JString, required = false,
                                 default = nil)
  if valid_774704 != nil:
    section.add "X-Amz-Security-Token", valid_774704
  var valid_774705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774705 = validateParameter(valid_774705, JString, required = false,
                                 default = nil)
  if valid_774705 != nil:
    section.add "X-Amz-Content-Sha256", valid_774705
  var valid_774706 = header.getOrDefault("X-Amz-Algorithm")
  valid_774706 = validateParameter(valid_774706, JString, required = false,
                                 default = nil)
  if valid_774706 != nil:
    section.add "X-Amz-Algorithm", valid_774706
  var valid_774707 = header.getOrDefault("X-Amz-Signature")
  valid_774707 = validateParameter(valid_774707, JString, required = false,
                                 default = nil)
  if valid_774707 != nil:
    section.add "X-Amz-Signature", valid_774707
  var valid_774708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774708 = validateParameter(valid_774708, JString, required = false,
                                 default = nil)
  if valid_774708 != nil:
    section.add "X-Amz-SignedHeaders", valid_774708
  var valid_774709 = header.getOrDefault("X-Amz-Credential")
  valid_774709 = validateParameter(valid_774709, JString, required = false,
                                 default = nil)
  if valid_774709 != nil:
    section.add "X-Amz-Credential", valid_774709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774710: Call_GetDescribeReservedDBInstancesOfferings_774689;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774710.validator(path, query, header, formData, body)
  let scheme = call_774710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774710.url(scheme.get, call_774710.host, call_774710.base,
                         call_774710.route, valid.getOrDefault("path"))
  result = hook(call_774710, url, valid)

proc call*(call_774711: Call_GetDescribeReservedDBInstancesOfferings_774689;
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
  var query_774712 = newJObject()
  add(query_774712, "ProductDescription", newJString(ProductDescription))
  add(query_774712, "MaxRecords", newJInt(MaxRecords))
  add(query_774712, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_774712.add "Filters", Filters
  add(query_774712, "MultiAZ", newJBool(MultiAZ))
  add(query_774712, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774712, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774712, "Action", newJString(Action))
  add(query_774712, "Marker", newJString(Marker))
  add(query_774712, "Duration", newJString(Duration))
  add(query_774712, "Version", newJString(Version))
  result = call_774711.call(nil, query_774712, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_774689(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_774690, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_774691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_774757 = ref object of OpenApiRestCall_772581
proc url_PostDownloadDBLogFilePortion_774759(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDownloadDBLogFilePortion_774758(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774760 = query.getOrDefault("Action")
  valid_774760 = validateParameter(valid_774760, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_774760 != nil:
    section.add "Action", valid_774760
  var valid_774761 = query.getOrDefault("Version")
  valid_774761 = validateParameter(valid_774761, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774761 != nil:
    section.add "Version", valid_774761
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774762 = header.getOrDefault("X-Amz-Date")
  valid_774762 = validateParameter(valid_774762, JString, required = false,
                                 default = nil)
  if valid_774762 != nil:
    section.add "X-Amz-Date", valid_774762
  var valid_774763 = header.getOrDefault("X-Amz-Security-Token")
  valid_774763 = validateParameter(valid_774763, JString, required = false,
                                 default = nil)
  if valid_774763 != nil:
    section.add "X-Amz-Security-Token", valid_774763
  var valid_774764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774764 = validateParameter(valid_774764, JString, required = false,
                                 default = nil)
  if valid_774764 != nil:
    section.add "X-Amz-Content-Sha256", valid_774764
  var valid_774765 = header.getOrDefault("X-Amz-Algorithm")
  valid_774765 = validateParameter(valid_774765, JString, required = false,
                                 default = nil)
  if valid_774765 != nil:
    section.add "X-Amz-Algorithm", valid_774765
  var valid_774766 = header.getOrDefault("X-Amz-Signature")
  valid_774766 = validateParameter(valid_774766, JString, required = false,
                                 default = nil)
  if valid_774766 != nil:
    section.add "X-Amz-Signature", valid_774766
  var valid_774767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774767 = validateParameter(valid_774767, JString, required = false,
                                 default = nil)
  if valid_774767 != nil:
    section.add "X-Amz-SignedHeaders", valid_774767
  var valid_774768 = header.getOrDefault("X-Amz-Credential")
  valid_774768 = validateParameter(valid_774768, JString, required = false,
                                 default = nil)
  if valid_774768 != nil:
    section.add "X-Amz-Credential", valid_774768
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_774769 = formData.getOrDefault("NumberOfLines")
  valid_774769 = validateParameter(valid_774769, JInt, required = false, default = nil)
  if valid_774769 != nil:
    section.add "NumberOfLines", valid_774769
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774770 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774770 = validateParameter(valid_774770, JString, required = true,
                                 default = nil)
  if valid_774770 != nil:
    section.add "DBInstanceIdentifier", valid_774770
  var valid_774771 = formData.getOrDefault("Marker")
  valid_774771 = validateParameter(valid_774771, JString, required = false,
                                 default = nil)
  if valid_774771 != nil:
    section.add "Marker", valid_774771
  var valid_774772 = formData.getOrDefault("LogFileName")
  valid_774772 = validateParameter(valid_774772, JString, required = true,
                                 default = nil)
  if valid_774772 != nil:
    section.add "LogFileName", valid_774772
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774773: Call_PostDownloadDBLogFilePortion_774757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774773.validator(path, query, header, formData, body)
  let scheme = call_774773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774773.url(scheme.get, call_774773.host, call_774773.base,
                         call_774773.route, valid.getOrDefault("path"))
  result = hook(call_774773, url, valid)

proc call*(call_774774: Call_PostDownloadDBLogFilePortion_774757;
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
  var query_774775 = newJObject()
  var formData_774776 = newJObject()
  add(formData_774776, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_774776, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774776, "Marker", newJString(Marker))
  add(query_774775, "Action", newJString(Action))
  add(formData_774776, "LogFileName", newJString(LogFileName))
  add(query_774775, "Version", newJString(Version))
  result = call_774774.call(nil, query_774775, nil, formData_774776, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_774757(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_774758, base: "/",
    url: url_PostDownloadDBLogFilePortion_774759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_774738 = ref object of OpenApiRestCall_772581
proc url_GetDownloadDBLogFilePortion_774740(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDownloadDBLogFilePortion_774739(path: JsonNode; query: JsonNode;
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
  var valid_774741 = query.getOrDefault("NumberOfLines")
  valid_774741 = validateParameter(valid_774741, JInt, required = false, default = nil)
  if valid_774741 != nil:
    section.add "NumberOfLines", valid_774741
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_774742 = query.getOrDefault("LogFileName")
  valid_774742 = validateParameter(valid_774742, JString, required = true,
                                 default = nil)
  if valid_774742 != nil:
    section.add "LogFileName", valid_774742
  var valid_774743 = query.getOrDefault("Action")
  valid_774743 = validateParameter(valid_774743, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_774743 != nil:
    section.add "Action", valid_774743
  var valid_774744 = query.getOrDefault("Marker")
  valid_774744 = validateParameter(valid_774744, JString, required = false,
                                 default = nil)
  if valid_774744 != nil:
    section.add "Marker", valid_774744
  var valid_774745 = query.getOrDefault("Version")
  valid_774745 = validateParameter(valid_774745, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774745 != nil:
    section.add "Version", valid_774745
  var valid_774746 = query.getOrDefault("DBInstanceIdentifier")
  valid_774746 = validateParameter(valid_774746, JString, required = true,
                                 default = nil)
  if valid_774746 != nil:
    section.add "DBInstanceIdentifier", valid_774746
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774747 = header.getOrDefault("X-Amz-Date")
  valid_774747 = validateParameter(valid_774747, JString, required = false,
                                 default = nil)
  if valid_774747 != nil:
    section.add "X-Amz-Date", valid_774747
  var valid_774748 = header.getOrDefault("X-Amz-Security-Token")
  valid_774748 = validateParameter(valid_774748, JString, required = false,
                                 default = nil)
  if valid_774748 != nil:
    section.add "X-Amz-Security-Token", valid_774748
  var valid_774749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774749 = validateParameter(valid_774749, JString, required = false,
                                 default = nil)
  if valid_774749 != nil:
    section.add "X-Amz-Content-Sha256", valid_774749
  var valid_774750 = header.getOrDefault("X-Amz-Algorithm")
  valid_774750 = validateParameter(valid_774750, JString, required = false,
                                 default = nil)
  if valid_774750 != nil:
    section.add "X-Amz-Algorithm", valid_774750
  var valid_774751 = header.getOrDefault("X-Amz-Signature")
  valid_774751 = validateParameter(valid_774751, JString, required = false,
                                 default = nil)
  if valid_774751 != nil:
    section.add "X-Amz-Signature", valid_774751
  var valid_774752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774752 = validateParameter(valid_774752, JString, required = false,
                                 default = nil)
  if valid_774752 != nil:
    section.add "X-Amz-SignedHeaders", valid_774752
  var valid_774753 = header.getOrDefault("X-Amz-Credential")
  valid_774753 = validateParameter(valid_774753, JString, required = false,
                                 default = nil)
  if valid_774753 != nil:
    section.add "X-Amz-Credential", valid_774753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774754: Call_GetDownloadDBLogFilePortion_774738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774754.validator(path, query, header, formData, body)
  let scheme = call_774754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774754.url(scheme.get, call_774754.host, call_774754.base,
                         call_774754.route, valid.getOrDefault("path"))
  result = hook(call_774754, url, valid)

proc call*(call_774755: Call_GetDownloadDBLogFilePortion_774738;
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
  var query_774756 = newJObject()
  add(query_774756, "NumberOfLines", newJInt(NumberOfLines))
  add(query_774756, "LogFileName", newJString(LogFileName))
  add(query_774756, "Action", newJString(Action))
  add(query_774756, "Marker", newJString(Marker))
  add(query_774756, "Version", newJString(Version))
  add(query_774756, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_774755.call(nil, query_774756, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_774738(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_774739, base: "/",
    url: url_GetDownloadDBLogFilePortion_774740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_774794 = ref object of OpenApiRestCall_772581
proc url_PostListTagsForResource_774796(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_774795(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774797 = query.getOrDefault("Action")
  valid_774797 = validateParameter(valid_774797, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_774797 != nil:
    section.add "Action", valid_774797
  var valid_774798 = query.getOrDefault("Version")
  valid_774798 = validateParameter(valid_774798, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774798 != nil:
    section.add "Version", valid_774798
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774799 = header.getOrDefault("X-Amz-Date")
  valid_774799 = validateParameter(valid_774799, JString, required = false,
                                 default = nil)
  if valid_774799 != nil:
    section.add "X-Amz-Date", valid_774799
  var valid_774800 = header.getOrDefault("X-Amz-Security-Token")
  valid_774800 = validateParameter(valid_774800, JString, required = false,
                                 default = nil)
  if valid_774800 != nil:
    section.add "X-Amz-Security-Token", valid_774800
  var valid_774801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774801 = validateParameter(valid_774801, JString, required = false,
                                 default = nil)
  if valid_774801 != nil:
    section.add "X-Amz-Content-Sha256", valid_774801
  var valid_774802 = header.getOrDefault("X-Amz-Algorithm")
  valid_774802 = validateParameter(valid_774802, JString, required = false,
                                 default = nil)
  if valid_774802 != nil:
    section.add "X-Amz-Algorithm", valid_774802
  var valid_774803 = header.getOrDefault("X-Amz-Signature")
  valid_774803 = validateParameter(valid_774803, JString, required = false,
                                 default = nil)
  if valid_774803 != nil:
    section.add "X-Amz-Signature", valid_774803
  var valid_774804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774804 = validateParameter(valid_774804, JString, required = false,
                                 default = nil)
  if valid_774804 != nil:
    section.add "X-Amz-SignedHeaders", valid_774804
  var valid_774805 = header.getOrDefault("X-Amz-Credential")
  valid_774805 = validateParameter(valid_774805, JString, required = false,
                                 default = nil)
  if valid_774805 != nil:
    section.add "X-Amz-Credential", valid_774805
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_774806 = formData.getOrDefault("Filters")
  valid_774806 = validateParameter(valid_774806, JArray, required = false,
                                 default = nil)
  if valid_774806 != nil:
    section.add "Filters", valid_774806
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_774807 = formData.getOrDefault("ResourceName")
  valid_774807 = validateParameter(valid_774807, JString, required = true,
                                 default = nil)
  if valid_774807 != nil:
    section.add "ResourceName", valid_774807
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774808: Call_PostListTagsForResource_774794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774808.validator(path, query, header, formData, body)
  let scheme = call_774808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774808.url(scheme.get, call_774808.host, call_774808.base,
                         call_774808.route, valid.getOrDefault("path"))
  result = hook(call_774808, url, valid)

proc call*(call_774809: Call_PostListTagsForResource_774794; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_774810 = newJObject()
  var formData_774811 = newJObject()
  add(query_774810, "Action", newJString(Action))
  if Filters != nil:
    formData_774811.add "Filters", Filters
  add(formData_774811, "ResourceName", newJString(ResourceName))
  add(query_774810, "Version", newJString(Version))
  result = call_774809.call(nil, query_774810, nil, formData_774811, nil)

var postListTagsForResource* = Call_PostListTagsForResource_774794(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_774795, base: "/",
    url: url_PostListTagsForResource_774796, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_774777 = ref object of OpenApiRestCall_772581
proc url_GetListTagsForResource_774779(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_774778(path: JsonNode; query: JsonNode;
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
  var valid_774780 = query.getOrDefault("Filters")
  valid_774780 = validateParameter(valid_774780, JArray, required = false,
                                 default = nil)
  if valid_774780 != nil:
    section.add "Filters", valid_774780
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_774781 = query.getOrDefault("ResourceName")
  valid_774781 = validateParameter(valid_774781, JString, required = true,
                                 default = nil)
  if valid_774781 != nil:
    section.add "ResourceName", valid_774781
  var valid_774782 = query.getOrDefault("Action")
  valid_774782 = validateParameter(valid_774782, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_774782 != nil:
    section.add "Action", valid_774782
  var valid_774783 = query.getOrDefault("Version")
  valid_774783 = validateParameter(valid_774783, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774783 != nil:
    section.add "Version", valid_774783
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774784 = header.getOrDefault("X-Amz-Date")
  valid_774784 = validateParameter(valid_774784, JString, required = false,
                                 default = nil)
  if valid_774784 != nil:
    section.add "X-Amz-Date", valid_774784
  var valid_774785 = header.getOrDefault("X-Amz-Security-Token")
  valid_774785 = validateParameter(valid_774785, JString, required = false,
                                 default = nil)
  if valid_774785 != nil:
    section.add "X-Amz-Security-Token", valid_774785
  var valid_774786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774786 = validateParameter(valid_774786, JString, required = false,
                                 default = nil)
  if valid_774786 != nil:
    section.add "X-Amz-Content-Sha256", valid_774786
  var valid_774787 = header.getOrDefault("X-Amz-Algorithm")
  valid_774787 = validateParameter(valid_774787, JString, required = false,
                                 default = nil)
  if valid_774787 != nil:
    section.add "X-Amz-Algorithm", valid_774787
  var valid_774788 = header.getOrDefault("X-Amz-Signature")
  valid_774788 = validateParameter(valid_774788, JString, required = false,
                                 default = nil)
  if valid_774788 != nil:
    section.add "X-Amz-Signature", valid_774788
  var valid_774789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774789 = validateParameter(valid_774789, JString, required = false,
                                 default = nil)
  if valid_774789 != nil:
    section.add "X-Amz-SignedHeaders", valid_774789
  var valid_774790 = header.getOrDefault("X-Amz-Credential")
  valid_774790 = validateParameter(valid_774790, JString, required = false,
                                 default = nil)
  if valid_774790 != nil:
    section.add "X-Amz-Credential", valid_774790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774791: Call_GetListTagsForResource_774777; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774791.validator(path, query, header, formData, body)
  let scheme = call_774791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774791.url(scheme.get, call_774791.host, call_774791.base,
                         call_774791.route, valid.getOrDefault("path"))
  result = hook(call_774791, url, valid)

proc call*(call_774792: Call_GetListTagsForResource_774777; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2014-09-01"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774793 = newJObject()
  if Filters != nil:
    query_774793.add "Filters", Filters
  add(query_774793, "ResourceName", newJString(ResourceName))
  add(query_774793, "Action", newJString(Action))
  add(query_774793, "Version", newJString(Version))
  result = call_774792.call(nil, query_774793, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_774777(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_774778, base: "/",
    url: url_GetListTagsForResource_774779, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_774848 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBInstance_774850(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBInstance_774849(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774851 = query.getOrDefault("Action")
  valid_774851 = validateParameter(valid_774851, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_774851 != nil:
    section.add "Action", valid_774851
  var valid_774852 = query.getOrDefault("Version")
  valid_774852 = validateParameter(valid_774852, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774852 != nil:
    section.add "Version", valid_774852
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774853 = header.getOrDefault("X-Amz-Date")
  valid_774853 = validateParameter(valid_774853, JString, required = false,
                                 default = nil)
  if valid_774853 != nil:
    section.add "X-Amz-Date", valid_774853
  var valid_774854 = header.getOrDefault("X-Amz-Security-Token")
  valid_774854 = validateParameter(valid_774854, JString, required = false,
                                 default = nil)
  if valid_774854 != nil:
    section.add "X-Amz-Security-Token", valid_774854
  var valid_774855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774855 = validateParameter(valid_774855, JString, required = false,
                                 default = nil)
  if valid_774855 != nil:
    section.add "X-Amz-Content-Sha256", valid_774855
  var valid_774856 = header.getOrDefault("X-Amz-Algorithm")
  valid_774856 = validateParameter(valid_774856, JString, required = false,
                                 default = nil)
  if valid_774856 != nil:
    section.add "X-Amz-Algorithm", valid_774856
  var valid_774857 = header.getOrDefault("X-Amz-Signature")
  valid_774857 = validateParameter(valid_774857, JString, required = false,
                                 default = nil)
  if valid_774857 != nil:
    section.add "X-Amz-Signature", valid_774857
  var valid_774858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774858 = validateParameter(valid_774858, JString, required = false,
                                 default = nil)
  if valid_774858 != nil:
    section.add "X-Amz-SignedHeaders", valid_774858
  var valid_774859 = header.getOrDefault("X-Amz-Credential")
  valid_774859 = validateParameter(valid_774859, JString, required = false,
                                 default = nil)
  if valid_774859 != nil:
    section.add "X-Amz-Credential", valid_774859
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
  var valid_774860 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_774860 = validateParameter(valid_774860, JString, required = false,
                                 default = nil)
  if valid_774860 != nil:
    section.add "PreferredMaintenanceWindow", valid_774860
  var valid_774861 = formData.getOrDefault("DBSecurityGroups")
  valid_774861 = validateParameter(valid_774861, JArray, required = false,
                                 default = nil)
  if valid_774861 != nil:
    section.add "DBSecurityGroups", valid_774861
  var valid_774862 = formData.getOrDefault("ApplyImmediately")
  valid_774862 = validateParameter(valid_774862, JBool, required = false, default = nil)
  if valid_774862 != nil:
    section.add "ApplyImmediately", valid_774862
  var valid_774863 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_774863 = validateParameter(valid_774863, JArray, required = false,
                                 default = nil)
  if valid_774863 != nil:
    section.add "VpcSecurityGroupIds", valid_774863
  var valid_774864 = formData.getOrDefault("Iops")
  valid_774864 = validateParameter(valid_774864, JInt, required = false, default = nil)
  if valid_774864 != nil:
    section.add "Iops", valid_774864
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774865 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774865 = validateParameter(valid_774865, JString, required = true,
                                 default = nil)
  if valid_774865 != nil:
    section.add "DBInstanceIdentifier", valid_774865
  var valid_774866 = formData.getOrDefault("BackupRetentionPeriod")
  valid_774866 = validateParameter(valid_774866, JInt, required = false, default = nil)
  if valid_774866 != nil:
    section.add "BackupRetentionPeriod", valid_774866
  var valid_774867 = formData.getOrDefault("DBParameterGroupName")
  valid_774867 = validateParameter(valid_774867, JString, required = false,
                                 default = nil)
  if valid_774867 != nil:
    section.add "DBParameterGroupName", valid_774867
  var valid_774868 = formData.getOrDefault("OptionGroupName")
  valid_774868 = validateParameter(valid_774868, JString, required = false,
                                 default = nil)
  if valid_774868 != nil:
    section.add "OptionGroupName", valid_774868
  var valid_774869 = formData.getOrDefault("MasterUserPassword")
  valid_774869 = validateParameter(valid_774869, JString, required = false,
                                 default = nil)
  if valid_774869 != nil:
    section.add "MasterUserPassword", valid_774869
  var valid_774870 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_774870 = validateParameter(valid_774870, JString, required = false,
                                 default = nil)
  if valid_774870 != nil:
    section.add "NewDBInstanceIdentifier", valid_774870
  var valid_774871 = formData.getOrDefault("TdeCredentialArn")
  valid_774871 = validateParameter(valid_774871, JString, required = false,
                                 default = nil)
  if valid_774871 != nil:
    section.add "TdeCredentialArn", valid_774871
  var valid_774872 = formData.getOrDefault("TdeCredentialPassword")
  valid_774872 = validateParameter(valid_774872, JString, required = false,
                                 default = nil)
  if valid_774872 != nil:
    section.add "TdeCredentialPassword", valid_774872
  var valid_774873 = formData.getOrDefault("MultiAZ")
  valid_774873 = validateParameter(valid_774873, JBool, required = false, default = nil)
  if valid_774873 != nil:
    section.add "MultiAZ", valid_774873
  var valid_774874 = formData.getOrDefault("AllocatedStorage")
  valid_774874 = validateParameter(valid_774874, JInt, required = false, default = nil)
  if valid_774874 != nil:
    section.add "AllocatedStorage", valid_774874
  var valid_774875 = formData.getOrDefault("StorageType")
  valid_774875 = validateParameter(valid_774875, JString, required = false,
                                 default = nil)
  if valid_774875 != nil:
    section.add "StorageType", valid_774875
  var valid_774876 = formData.getOrDefault("DBInstanceClass")
  valid_774876 = validateParameter(valid_774876, JString, required = false,
                                 default = nil)
  if valid_774876 != nil:
    section.add "DBInstanceClass", valid_774876
  var valid_774877 = formData.getOrDefault("PreferredBackupWindow")
  valid_774877 = validateParameter(valid_774877, JString, required = false,
                                 default = nil)
  if valid_774877 != nil:
    section.add "PreferredBackupWindow", valid_774877
  var valid_774878 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_774878 = validateParameter(valid_774878, JBool, required = false, default = nil)
  if valid_774878 != nil:
    section.add "AutoMinorVersionUpgrade", valid_774878
  var valid_774879 = formData.getOrDefault("EngineVersion")
  valid_774879 = validateParameter(valid_774879, JString, required = false,
                                 default = nil)
  if valid_774879 != nil:
    section.add "EngineVersion", valid_774879
  var valid_774880 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_774880 = validateParameter(valid_774880, JBool, required = false, default = nil)
  if valid_774880 != nil:
    section.add "AllowMajorVersionUpgrade", valid_774880
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774881: Call_PostModifyDBInstance_774848; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774881.validator(path, query, header, formData, body)
  let scheme = call_774881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774881.url(scheme.get, call_774881.host, call_774881.base,
                         call_774881.route, valid.getOrDefault("path"))
  result = hook(call_774881, url, valid)

proc call*(call_774882: Call_PostModifyDBInstance_774848;
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
  var query_774883 = newJObject()
  var formData_774884 = newJObject()
  add(formData_774884, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_774884.add "DBSecurityGroups", DBSecurityGroups
  add(formData_774884, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_774884.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_774884, "Iops", newJInt(Iops))
  add(formData_774884, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774884, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_774884, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_774884, "OptionGroupName", newJString(OptionGroupName))
  add(formData_774884, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_774884, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_774884, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_774884, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_774884, "MultiAZ", newJBool(MultiAZ))
  add(query_774883, "Action", newJString(Action))
  add(formData_774884, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_774884, "StorageType", newJString(StorageType))
  add(formData_774884, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_774884, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_774884, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_774884, "EngineVersion", newJString(EngineVersion))
  add(query_774883, "Version", newJString(Version))
  add(formData_774884, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_774882.call(nil, query_774883, nil, formData_774884, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_774848(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_774849, base: "/",
    url: url_PostModifyDBInstance_774850, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_774812 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBInstance_774814(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBInstance_774813(path: JsonNode; query: JsonNode;
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
  var valid_774815 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_774815 = validateParameter(valid_774815, JString, required = false,
                                 default = nil)
  if valid_774815 != nil:
    section.add "PreferredMaintenanceWindow", valid_774815
  var valid_774816 = query.getOrDefault("AllocatedStorage")
  valid_774816 = validateParameter(valid_774816, JInt, required = false, default = nil)
  if valid_774816 != nil:
    section.add "AllocatedStorage", valid_774816
  var valid_774817 = query.getOrDefault("StorageType")
  valid_774817 = validateParameter(valid_774817, JString, required = false,
                                 default = nil)
  if valid_774817 != nil:
    section.add "StorageType", valid_774817
  var valid_774818 = query.getOrDefault("OptionGroupName")
  valid_774818 = validateParameter(valid_774818, JString, required = false,
                                 default = nil)
  if valid_774818 != nil:
    section.add "OptionGroupName", valid_774818
  var valid_774819 = query.getOrDefault("DBSecurityGroups")
  valid_774819 = validateParameter(valid_774819, JArray, required = false,
                                 default = nil)
  if valid_774819 != nil:
    section.add "DBSecurityGroups", valid_774819
  var valid_774820 = query.getOrDefault("MasterUserPassword")
  valid_774820 = validateParameter(valid_774820, JString, required = false,
                                 default = nil)
  if valid_774820 != nil:
    section.add "MasterUserPassword", valid_774820
  var valid_774821 = query.getOrDefault("Iops")
  valid_774821 = validateParameter(valid_774821, JInt, required = false, default = nil)
  if valid_774821 != nil:
    section.add "Iops", valid_774821
  var valid_774822 = query.getOrDefault("VpcSecurityGroupIds")
  valid_774822 = validateParameter(valid_774822, JArray, required = false,
                                 default = nil)
  if valid_774822 != nil:
    section.add "VpcSecurityGroupIds", valid_774822
  var valid_774823 = query.getOrDefault("MultiAZ")
  valid_774823 = validateParameter(valid_774823, JBool, required = false, default = nil)
  if valid_774823 != nil:
    section.add "MultiAZ", valid_774823
  var valid_774824 = query.getOrDefault("TdeCredentialPassword")
  valid_774824 = validateParameter(valid_774824, JString, required = false,
                                 default = nil)
  if valid_774824 != nil:
    section.add "TdeCredentialPassword", valid_774824
  var valid_774825 = query.getOrDefault("BackupRetentionPeriod")
  valid_774825 = validateParameter(valid_774825, JInt, required = false, default = nil)
  if valid_774825 != nil:
    section.add "BackupRetentionPeriod", valid_774825
  var valid_774826 = query.getOrDefault("DBParameterGroupName")
  valid_774826 = validateParameter(valid_774826, JString, required = false,
                                 default = nil)
  if valid_774826 != nil:
    section.add "DBParameterGroupName", valid_774826
  var valid_774827 = query.getOrDefault("DBInstanceClass")
  valid_774827 = validateParameter(valid_774827, JString, required = false,
                                 default = nil)
  if valid_774827 != nil:
    section.add "DBInstanceClass", valid_774827
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774828 = query.getOrDefault("Action")
  valid_774828 = validateParameter(valid_774828, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_774828 != nil:
    section.add "Action", valid_774828
  var valid_774829 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_774829 = validateParameter(valid_774829, JBool, required = false, default = nil)
  if valid_774829 != nil:
    section.add "AllowMajorVersionUpgrade", valid_774829
  var valid_774830 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_774830 = validateParameter(valid_774830, JString, required = false,
                                 default = nil)
  if valid_774830 != nil:
    section.add "NewDBInstanceIdentifier", valid_774830
  var valid_774831 = query.getOrDefault("TdeCredentialArn")
  valid_774831 = validateParameter(valid_774831, JString, required = false,
                                 default = nil)
  if valid_774831 != nil:
    section.add "TdeCredentialArn", valid_774831
  var valid_774832 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_774832 = validateParameter(valid_774832, JBool, required = false, default = nil)
  if valid_774832 != nil:
    section.add "AutoMinorVersionUpgrade", valid_774832
  var valid_774833 = query.getOrDefault("EngineVersion")
  valid_774833 = validateParameter(valid_774833, JString, required = false,
                                 default = nil)
  if valid_774833 != nil:
    section.add "EngineVersion", valid_774833
  var valid_774834 = query.getOrDefault("PreferredBackupWindow")
  valid_774834 = validateParameter(valid_774834, JString, required = false,
                                 default = nil)
  if valid_774834 != nil:
    section.add "PreferredBackupWindow", valid_774834
  var valid_774835 = query.getOrDefault("Version")
  valid_774835 = validateParameter(valid_774835, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774835 != nil:
    section.add "Version", valid_774835
  var valid_774836 = query.getOrDefault("DBInstanceIdentifier")
  valid_774836 = validateParameter(valid_774836, JString, required = true,
                                 default = nil)
  if valid_774836 != nil:
    section.add "DBInstanceIdentifier", valid_774836
  var valid_774837 = query.getOrDefault("ApplyImmediately")
  valid_774837 = validateParameter(valid_774837, JBool, required = false, default = nil)
  if valid_774837 != nil:
    section.add "ApplyImmediately", valid_774837
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774838 = header.getOrDefault("X-Amz-Date")
  valid_774838 = validateParameter(valid_774838, JString, required = false,
                                 default = nil)
  if valid_774838 != nil:
    section.add "X-Amz-Date", valid_774838
  var valid_774839 = header.getOrDefault("X-Amz-Security-Token")
  valid_774839 = validateParameter(valid_774839, JString, required = false,
                                 default = nil)
  if valid_774839 != nil:
    section.add "X-Amz-Security-Token", valid_774839
  var valid_774840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774840 = validateParameter(valid_774840, JString, required = false,
                                 default = nil)
  if valid_774840 != nil:
    section.add "X-Amz-Content-Sha256", valid_774840
  var valid_774841 = header.getOrDefault("X-Amz-Algorithm")
  valid_774841 = validateParameter(valid_774841, JString, required = false,
                                 default = nil)
  if valid_774841 != nil:
    section.add "X-Amz-Algorithm", valid_774841
  var valid_774842 = header.getOrDefault("X-Amz-Signature")
  valid_774842 = validateParameter(valid_774842, JString, required = false,
                                 default = nil)
  if valid_774842 != nil:
    section.add "X-Amz-Signature", valid_774842
  var valid_774843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774843 = validateParameter(valid_774843, JString, required = false,
                                 default = nil)
  if valid_774843 != nil:
    section.add "X-Amz-SignedHeaders", valid_774843
  var valid_774844 = header.getOrDefault("X-Amz-Credential")
  valid_774844 = validateParameter(valid_774844, JString, required = false,
                                 default = nil)
  if valid_774844 != nil:
    section.add "X-Amz-Credential", valid_774844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774845: Call_GetModifyDBInstance_774812; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774845.validator(path, query, header, formData, body)
  let scheme = call_774845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774845.url(scheme.get, call_774845.host, call_774845.base,
                         call_774845.route, valid.getOrDefault("path"))
  result = hook(call_774845, url, valid)

proc call*(call_774846: Call_GetModifyDBInstance_774812;
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
  var query_774847 = newJObject()
  add(query_774847, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_774847, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_774847, "StorageType", newJString(StorageType))
  add(query_774847, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_774847.add "DBSecurityGroups", DBSecurityGroups
  add(query_774847, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_774847, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_774847.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_774847, "MultiAZ", newJBool(MultiAZ))
  add(query_774847, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_774847, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_774847, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_774847, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774847, "Action", newJString(Action))
  add(query_774847, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_774847, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_774847, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_774847, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_774847, "EngineVersion", newJString(EngineVersion))
  add(query_774847, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_774847, "Version", newJString(Version))
  add(query_774847, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_774847, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_774846.call(nil, query_774847, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_774812(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_774813, base: "/",
    url: url_GetModifyDBInstance_774814, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_774902 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBParameterGroup_774904(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBParameterGroup_774903(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774905 = query.getOrDefault("Action")
  valid_774905 = validateParameter(valid_774905, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_774905 != nil:
    section.add "Action", valid_774905
  var valid_774906 = query.getOrDefault("Version")
  valid_774906 = validateParameter(valid_774906, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774906 != nil:
    section.add "Version", valid_774906
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774907 = header.getOrDefault("X-Amz-Date")
  valid_774907 = validateParameter(valid_774907, JString, required = false,
                                 default = nil)
  if valid_774907 != nil:
    section.add "X-Amz-Date", valid_774907
  var valid_774908 = header.getOrDefault("X-Amz-Security-Token")
  valid_774908 = validateParameter(valid_774908, JString, required = false,
                                 default = nil)
  if valid_774908 != nil:
    section.add "X-Amz-Security-Token", valid_774908
  var valid_774909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774909 = validateParameter(valid_774909, JString, required = false,
                                 default = nil)
  if valid_774909 != nil:
    section.add "X-Amz-Content-Sha256", valid_774909
  var valid_774910 = header.getOrDefault("X-Amz-Algorithm")
  valid_774910 = validateParameter(valid_774910, JString, required = false,
                                 default = nil)
  if valid_774910 != nil:
    section.add "X-Amz-Algorithm", valid_774910
  var valid_774911 = header.getOrDefault("X-Amz-Signature")
  valid_774911 = validateParameter(valid_774911, JString, required = false,
                                 default = nil)
  if valid_774911 != nil:
    section.add "X-Amz-Signature", valid_774911
  var valid_774912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774912 = validateParameter(valid_774912, JString, required = false,
                                 default = nil)
  if valid_774912 != nil:
    section.add "X-Amz-SignedHeaders", valid_774912
  var valid_774913 = header.getOrDefault("X-Amz-Credential")
  valid_774913 = validateParameter(valid_774913, JString, required = false,
                                 default = nil)
  if valid_774913 != nil:
    section.add "X-Amz-Credential", valid_774913
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_774914 = formData.getOrDefault("DBParameterGroupName")
  valid_774914 = validateParameter(valid_774914, JString, required = true,
                                 default = nil)
  if valid_774914 != nil:
    section.add "DBParameterGroupName", valid_774914
  var valid_774915 = formData.getOrDefault("Parameters")
  valid_774915 = validateParameter(valid_774915, JArray, required = true, default = nil)
  if valid_774915 != nil:
    section.add "Parameters", valid_774915
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774916: Call_PostModifyDBParameterGroup_774902; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774916.validator(path, query, header, formData, body)
  let scheme = call_774916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774916.url(scheme.get, call_774916.host, call_774916.base,
                         call_774916.route, valid.getOrDefault("path"))
  result = hook(call_774916, url, valid)

proc call*(call_774917: Call_PostModifyDBParameterGroup_774902;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774918 = newJObject()
  var formData_774919 = newJObject()
  add(formData_774919, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_774919.add "Parameters", Parameters
  add(query_774918, "Action", newJString(Action))
  add(query_774918, "Version", newJString(Version))
  result = call_774917.call(nil, query_774918, nil, formData_774919, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_774902(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_774903, base: "/",
    url: url_PostModifyDBParameterGroup_774904,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_774885 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBParameterGroup_774887(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBParameterGroup_774886(path: JsonNode; query: JsonNode;
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
  var valid_774888 = query.getOrDefault("DBParameterGroupName")
  valid_774888 = validateParameter(valid_774888, JString, required = true,
                                 default = nil)
  if valid_774888 != nil:
    section.add "DBParameterGroupName", valid_774888
  var valid_774889 = query.getOrDefault("Parameters")
  valid_774889 = validateParameter(valid_774889, JArray, required = true, default = nil)
  if valid_774889 != nil:
    section.add "Parameters", valid_774889
  var valid_774890 = query.getOrDefault("Action")
  valid_774890 = validateParameter(valid_774890, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_774890 != nil:
    section.add "Action", valid_774890
  var valid_774891 = query.getOrDefault("Version")
  valid_774891 = validateParameter(valid_774891, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774891 != nil:
    section.add "Version", valid_774891
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774892 = header.getOrDefault("X-Amz-Date")
  valid_774892 = validateParameter(valid_774892, JString, required = false,
                                 default = nil)
  if valid_774892 != nil:
    section.add "X-Amz-Date", valid_774892
  var valid_774893 = header.getOrDefault("X-Amz-Security-Token")
  valid_774893 = validateParameter(valid_774893, JString, required = false,
                                 default = nil)
  if valid_774893 != nil:
    section.add "X-Amz-Security-Token", valid_774893
  var valid_774894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774894 = validateParameter(valid_774894, JString, required = false,
                                 default = nil)
  if valid_774894 != nil:
    section.add "X-Amz-Content-Sha256", valid_774894
  var valid_774895 = header.getOrDefault("X-Amz-Algorithm")
  valid_774895 = validateParameter(valid_774895, JString, required = false,
                                 default = nil)
  if valid_774895 != nil:
    section.add "X-Amz-Algorithm", valid_774895
  var valid_774896 = header.getOrDefault("X-Amz-Signature")
  valid_774896 = validateParameter(valid_774896, JString, required = false,
                                 default = nil)
  if valid_774896 != nil:
    section.add "X-Amz-Signature", valid_774896
  var valid_774897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774897 = validateParameter(valid_774897, JString, required = false,
                                 default = nil)
  if valid_774897 != nil:
    section.add "X-Amz-SignedHeaders", valid_774897
  var valid_774898 = header.getOrDefault("X-Amz-Credential")
  valid_774898 = validateParameter(valid_774898, JString, required = false,
                                 default = nil)
  if valid_774898 != nil:
    section.add "X-Amz-Credential", valid_774898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774899: Call_GetModifyDBParameterGroup_774885; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774899.validator(path, query, header, formData, body)
  let scheme = call_774899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774899.url(scheme.get, call_774899.host, call_774899.base,
                         call_774899.route, valid.getOrDefault("path"))
  result = hook(call_774899, url, valid)

proc call*(call_774900: Call_GetModifyDBParameterGroup_774885;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774901 = newJObject()
  add(query_774901, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_774901.add "Parameters", Parameters
  add(query_774901, "Action", newJString(Action))
  add(query_774901, "Version", newJString(Version))
  result = call_774900.call(nil, query_774901, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_774885(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_774886, base: "/",
    url: url_GetModifyDBParameterGroup_774887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_774938 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBSubnetGroup_774940(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBSubnetGroup_774939(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774941 = query.getOrDefault("Action")
  valid_774941 = validateParameter(valid_774941, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_774941 != nil:
    section.add "Action", valid_774941
  var valid_774942 = query.getOrDefault("Version")
  valid_774942 = validateParameter(valid_774942, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774942 != nil:
    section.add "Version", valid_774942
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774943 = header.getOrDefault("X-Amz-Date")
  valid_774943 = validateParameter(valid_774943, JString, required = false,
                                 default = nil)
  if valid_774943 != nil:
    section.add "X-Amz-Date", valid_774943
  var valid_774944 = header.getOrDefault("X-Amz-Security-Token")
  valid_774944 = validateParameter(valid_774944, JString, required = false,
                                 default = nil)
  if valid_774944 != nil:
    section.add "X-Amz-Security-Token", valid_774944
  var valid_774945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774945 = validateParameter(valid_774945, JString, required = false,
                                 default = nil)
  if valid_774945 != nil:
    section.add "X-Amz-Content-Sha256", valid_774945
  var valid_774946 = header.getOrDefault("X-Amz-Algorithm")
  valid_774946 = validateParameter(valid_774946, JString, required = false,
                                 default = nil)
  if valid_774946 != nil:
    section.add "X-Amz-Algorithm", valid_774946
  var valid_774947 = header.getOrDefault("X-Amz-Signature")
  valid_774947 = validateParameter(valid_774947, JString, required = false,
                                 default = nil)
  if valid_774947 != nil:
    section.add "X-Amz-Signature", valid_774947
  var valid_774948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774948 = validateParameter(valid_774948, JString, required = false,
                                 default = nil)
  if valid_774948 != nil:
    section.add "X-Amz-SignedHeaders", valid_774948
  var valid_774949 = header.getOrDefault("X-Amz-Credential")
  valid_774949 = validateParameter(valid_774949, JString, required = false,
                                 default = nil)
  if valid_774949 != nil:
    section.add "X-Amz-Credential", valid_774949
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_774950 = formData.getOrDefault("DBSubnetGroupName")
  valid_774950 = validateParameter(valid_774950, JString, required = true,
                                 default = nil)
  if valid_774950 != nil:
    section.add "DBSubnetGroupName", valid_774950
  var valid_774951 = formData.getOrDefault("SubnetIds")
  valid_774951 = validateParameter(valid_774951, JArray, required = true, default = nil)
  if valid_774951 != nil:
    section.add "SubnetIds", valid_774951
  var valid_774952 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_774952 = validateParameter(valid_774952, JString, required = false,
                                 default = nil)
  if valid_774952 != nil:
    section.add "DBSubnetGroupDescription", valid_774952
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774953: Call_PostModifyDBSubnetGroup_774938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774953.validator(path, query, header, formData, body)
  let scheme = call_774953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774953.url(scheme.get, call_774953.host, call_774953.base,
                         call_774953.route, valid.getOrDefault("path"))
  result = hook(call_774953, url, valid)

proc call*(call_774954: Call_PostModifyDBSubnetGroup_774938;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_774955 = newJObject()
  var formData_774956 = newJObject()
  add(formData_774956, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_774956.add "SubnetIds", SubnetIds
  add(query_774955, "Action", newJString(Action))
  add(formData_774956, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_774955, "Version", newJString(Version))
  result = call_774954.call(nil, query_774955, nil, formData_774956, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_774938(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_774939, base: "/",
    url: url_PostModifyDBSubnetGroup_774940, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_774920 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBSubnetGroup_774922(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBSubnetGroup_774921(path: JsonNode; query: JsonNode;
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
  var valid_774923 = query.getOrDefault("Action")
  valid_774923 = validateParameter(valid_774923, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_774923 != nil:
    section.add "Action", valid_774923
  var valid_774924 = query.getOrDefault("DBSubnetGroupName")
  valid_774924 = validateParameter(valid_774924, JString, required = true,
                                 default = nil)
  if valid_774924 != nil:
    section.add "DBSubnetGroupName", valid_774924
  var valid_774925 = query.getOrDefault("SubnetIds")
  valid_774925 = validateParameter(valid_774925, JArray, required = true, default = nil)
  if valid_774925 != nil:
    section.add "SubnetIds", valid_774925
  var valid_774926 = query.getOrDefault("DBSubnetGroupDescription")
  valid_774926 = validateParameter(valid_774926, JString, required = false,
                                 default = nil)
  if valid_774926 != nil:
    section.add "DBSubnetGroupDescription", valid_774926
  var valid_774927 = query.getOrDefault("Version")
  valid_774927 = validateParameter(valid_774927, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774927 != nil:
    section.add "Version", valid_774927
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774928 = header.getOrDefault("X-Amz-Date")
  valid_774928 = validateParameter(valid_774928, JString, required = false,
                                 default = nil)
  if valid_774928 != nil:
    section.add "X-Amz-Date", valid_774928
  var valid_774929 = header.getOrDefault("X-Amz-Security-Token")
  valid_774929 = validateParameter(valid_774929, JString, required = false,
                                 default = nil)
  if valid_774929 != nil:
    section.add "X-Amz-Security-Token", valid_774929
  var valid_774930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774930 = validateParameter(valid_774930, JString, required = false,
                                 default = nil)
  if valid_774930 != nil:
    section.add "X-Amz-Content-Sha256", valid_774930
  var valid_774931 = header.getOrDefault("X-Amz-Algorithm")
  valid_774931 = validateParameter(valid_774931, JString, required = false,
                                 default = nil)
  if valid_774931 != nil:
    section.add "X-Amz-Algorithm", valid_774931
  var valid_774932 = header.getOrDefault("X-Amz-Signature")
  valid_774932 = validateParameter(valid_774932, JString, required = false,
                                 default = nil)
  if valid_774932 != nil:
    section.add "X-Amz-Signature", valid_774932
  var valid_774933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774933 = validateParameter(valid_774933, JString, required = false,
                                 default = nil)
  if valid_774933 != nil:
    section.add "X-Amz-SignedHeaders", valid_774933
  var valid_774934 = header.getOrDefault("X-Amz-Credential")
  valid_774934 = validateParameter(valid_774934, JString, required = false,
                                 default = nil)
  if valid_774934 != nil:
    section.add "X-Amz-Credential", valid_774934
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774935: Call_GetModifyDBSubnetGroup_774920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774935.validator(path, query, header, formData, body)
  let scheme = call_774935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774935.url(scheme.get, call_774935.host, call_774935.base,
                         call_774935.route, valid.getOrDefault("path"))
  result = hook(call_774935, url, valid)

proc call*(call_774936: Call_GetModifyDBSubnetGroup_774920;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_774937 = newJObject()
  add(query_774937, "Action", newJString(Action))
  add(query_774937, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_774937.add "SubnetIds", SubnetIds
  add(query_774937, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_774937, "Version", newJString(Version))
  result = call_774936.call(nil, query_774937, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_774920(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_774921, base: "/",
    url: url_GetModifyDBSubnetGroup_774922, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_774977 = ref object of OpenApiRestCall_772581
proc url_PostModifyEventSubscription_774979(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyEventSubscription_774978(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774980 = query.getOrDefault("Action")
  valid_774980 = validateParameter(valid_774980, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_774980 != nil:
    section.add "Action", valid_774980
  var valid_774981 = query.getOrDefault("Version")
  valid_774981 = validateParameter(valid_774981, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774981 != nil:
    section.add "Version", valid_774981
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774982 = header.getOrDefault("X-Amz-Date")
  valid_774982 = validateParameter(valid_774982, JString, required = false,
                                 default = nil)
  if valid_774982 != nil:
    section.add "X-Amz-Date", valid_774982
  var valid_774983 = header.getOrDefault("X-Amz-Security-Token")
  valid_774983 = validateParameter(valid_774983, JString, required = false,
                                 default = nil)
  if valid_774983 != nil:
    section.add "X-Amz-Security-Token", valid_774983
  var valid_774984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774984 = validateParameter(valid_774984, JString, required = false,
                                 default = nil)
  if valid_774984 != nil:
    section.add "X-Amz-Content-Sha256", valid_774984
  var valid_774985 = header.getOrDefault("X-Amz-Algorithm")
  valid_774985 = validateParameter(valid_774985, JString, required = false,
                                 default = nil)
  if valid_774985 != nil:
    section.add "X-Amz-Algorithm", valid_774985
  var valid_774986 = header.getOrDefault("X-Amz-Signature")
  valid_774986 = validateParameter(valid_774986, JString, required = false,
                                 default = nil)
  if valid_774986 != nil:
    section.add "X-Amz-Signature", valid_774986
  var valid_774987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774987 = validateParameter(valid_774987, JString, required = false,
                                 default = nil)
  if valid_774987 != nil:
    section.add "X-Amz-SignedHeaders", valid_774987
  var valid_774988 = header.getOrDefault("X-Amz-Credential")
  valid_774988 = validateParameter(valid_774988, JString, required = false,
                                 default = nil)
  if valid_774988 != nil:
    section.add "X-Amz-Credential", valid_774988
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_774989 = formData.getOrDefault("Enabled")
  valid_774989 = validateParameter(valid_774989, JBool, required = false, default = nil)
  if valid_774989 != nil:
    section.add "Enabled", valid_774989
  var valid_774990 = formData.getOrDefault("EventCategories")
  valid_774990 = validateParameter(valid_774990, JArray, required = false,
                                 default = nil)
  if valid_774990 != nil:
    section.add "EventCategories", valid_774990
  var valid_774991 = formData.getOrDefault("SnsTopicArn")
  valid_774991 = validateParameter(valid_774991, JString, required = false,
                                 default = nil)
  if valid_774991 != nil:
    section.add "SnsTopicArn", valid_774991
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_774992 = formData.getOrDefault("SubscriptionName")
  valid_774992 = validateParameter(valid_774992, JString, required = true,
                                 default = nil)
  if valid_774992 != nil:
    section.add "SubscriptionName", valid_774992
  var valid_774993 = formData.getOrDefault("SourceType")
  valid_774993 = validateParameter(valid_774993, JString, required = false,
                                 default = nil)
  if valid_774993 != nil:
    section.add "SourceType", valid_774993
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774994: Call_PostModifyEventSubscription_774977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774994.validator(path, query, header, formData, body)
  let scheme = call_774994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774994.url(scheme.get, call_774994.host, call_774994.base,
                         call_774994.route, valid.getOrDefault("path"))
  result = hook(call_774994, url, valid)

proc call*(call_774995: Call_PostModifyEventSubscription_774977;
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
  var query_774996 = newJObject()
  var formData_774997 = newJObject()
  add(formData_774997, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_774997.add "EventCategories", EventCategories
  add(formData_774997, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_774997, "SubscriptionName", newJString(SubscriptionName))
  add(query_774996, "Action", newJString(Action))
  add(query_774996, "Version", newJString(Version))
  add(formData_774997, "SourceType", newJString(SourceType))
  result = call_774995.call(nil, query_774996, nil, formData_774997, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_774977(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_774978, base: "/",
    url: url_PostModifyEventSubscription_774979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_774957 = ref object of OpenApiRestCall_772581
proc url_GetModifyEventSubscription_774959(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyEventSubscription_774958(path: JsonNode; query: JsonNode;
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
  var valid_774960 = query.getOrDefault("SourceType")
  valid_774960 = validateParameter(valid_774960, JString, required = false,
                                 default = nil)
  if valid_774960 != nil:
    section.add "SourceType", valid_774960
  var valid_774961 = query.getOrDefault("Enabled")
  valid_774961 = validateParameter(valid_774961, JBool, required = false, default = nil)
  if valid_774961 != nil:
    section.add "Enabled", valid_774961
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774962 = query.getOrDefault("Action")
  valid_774962 = validateParameter(valid_774962, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_774962 != nil:
    section.add "Action", valid_774962
  var valid_774963 = query.getOrDefault("SnsTopicArn")
  valid_774963 = validateParameter(valid_774963, JString, required = false,
                                 default = nil)
  if valid_774963 != nil:
    section.add "SnsTopicArn", valid_774963
  var valid_774964 = query.getOrDefault("EventCategories")
  valid_774964 = validateParameter(valid_774964, JArray, required = false,
                                 default = nil)
  if valid_774964 != nil:
    section.add "EventCategories", valid_774964
  var valid_774965 = query.getOrDefault("SubscriptionName")
  valid_774965 = validateParameter(valid_774965, JString, required = true,
                                 default = nil)
  if valid_774965 != nil:
    section.add "SubscriptionName", valid_774965
  var valid_774966 = query.getOrDefault("Version")
  valid_774966 = validateParameter(valid_774966, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_774966 != nil:
    section.add "Version", valid_774966
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774967 = header.getOrDefault("X-Amz-Date")
  valid_774967 = validateParameter(valid_774967, JString, required = false,
                                 default = nil)
  if valid_774967 != nil:
    section.add "X-Amz-Date", valid_774967
  var valid_774968 = header.getOrDefault("X-Amz-Security-Token")
  valid_774968 = validateParameter(valid_774968, JString, required = false,
                                 default = nil)
  if valid_774968 != nil:
    section.add "X-Amz-Security-Token", valid_774968
  var valid_774969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774969 = validateParameter(valid_774969, JString, required = false,
                                 default = nil)
  if valid_774969 != nil:
    section.add "X-Amz-Content-Sha256", valid_774969
  var valid_774970 = header.getOrDefault("X-Amz-Algorithm")
  valid_774970 = validateParameter(valid_774970, JString, required = false,
                                 default = nil)
  if valid_774970 != nil:
    section.add "X-Amz-Algorithm", valid_774970
  var valid_774971 = header.getOrDefault("X-Amz-Signature")
  valid_774971 = validateParameter(valid_774971, JString, required = false,
                                 default = nil)
  if valid_774971 != nil:
    section.add "X-Amz-Signature", valid_774971
  var valid_774972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774972 = validateParameter(valid_774972, JString, required = false,
                                 default = nil)
  if valid_774972 != nil:
    section.add "X-Amz-SignedHeaders", valid_774972
  var valid_774973 = header.getOrDefault("X-Amz-Credential")
  valid_774973 = validateParameter(valid_774973, JString, required = false,
                                 default = nil)
  if valid_774973 != nil:
    section.add "X-Amz-Credential", valid_774973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774974: Call_GetModifyEventSubscription_774957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774974.validator(path, query, header, formData, body)
  let scheme = call_774974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774974.url(scheme.get, call_774974.host, call_774974.base,
                         call_774974.route, valid.getOrDefault("path"))
  result = hook(call_774974, url, valid)

proc call*(call_774975: Call_GetModifyEventSubscription_774957;
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
  var query_774976 = newJObject()
  add(query_774976, "SourceType", newJString(SourceType))
  add(query_774976, "Enabled", newJBool(Enabled))
  add(query_774976, "Action", newJString(Action))
  add(query_774976, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_774976.add "EventCategories", EventCategories
  add(query_774976, "SubscriptionName", newJString(SubscriptionName))
  add(query_774976, "Version", newJString(Version))
  result = call_774975.call(nil, query_774976, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_774957(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_774958, base: "/",
    url: url_GetModifyEventSubscription_774959,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_775017 = ref object of OpenApiRestCall_772581
proc url_PostModifyOptionGroup_775019(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyOptionGroup_775018(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775020 = query.getOrDefault("Action")
  valid_775020 = validateParameter(valid_775020, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_775020 != nil:
    section.add "Action", valid_775020
  var valid_775021 = query.getOrDefault("Version")
  valid_775021 = validateParameter(valid_775021, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775021 != nil:
    section.add "Version", valid_775021
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775022 = header.getOrDefault("X-Amz-Date")
  valid_775022 = validateParameter(valid_775022, JString, required = false,
                                 default = nil)
  if valid_775022 != nil:
    section.add "X-Amz-Date", valid_775022
  var valid_775023 = header.getOrDefault("X-Amz-Security-Token")
  valid_775023 = validateParameter(valid_775023, JString, required = false,
                                 default = nil)
  if valid_775023 != nil:
    section.add "X-Amz-Security-Token", valid_775023
  var valid_775024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775024 = validateParameter(valid_775024, JString, required = false,
                                 default = nil)
  if valid_775024 != nil:
    section.add "X-Amz-Content-Sha256", valid_775024
  var valid_775025 = header.getOrDefault("X-Amz-Algorithm")
  valid_775025 = validateParameter(valid_775025, JString, required = false,
                                 default = nil)
  if valid_775025 != nil:
    section.add "X-Amz-Algorithm", valid_775025
  var valid_775026 = header.getOrDefault("X-Amz-Signature")
  valid_775026 = validateParameter(valid_775026, JString, required = false,
                                 default = nil)
  if valid_775026 != nil:
    section.add "X-Amz-Signature", valid_775026
  var valid_775027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775027 = validateParameter(valid_775027, JString, required = false,
                                 default = nil)
  if valid_775027 != nil:
    section.add "X-Amz-SignedHeaders", valid_775027
  var valid_775028 = header.getOrDefault("X-Amz-Credential")
  valid_775028 = validateParameter(valid_775028, JString, required = false,
                                 default = nil)
  if valid_775028 != nil:
    section.add "X-Amz-Credential", valid_775028
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_775029 = formData.getOrDefault("OptionsToRemove")
  valid_775029 = validateParameter(valid_775029, JArray, required = false,
                                 default = nil)
  if valid_775029 != nil:
    section.add "OptionsToRemove", valid_775029
  var valid_775030 = formData.getOrDefault("ApplyImmediately")
  valid_775030 = validateParameter(valid_775030, JBool, required = false, default = nil)
  if valid_775030 != nil:
    section.add "ApplyImmediately", valid_775030
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_775031 = formData.getOrDefault("OptionGroupName")
  valid_775031 = validateParameter(valid_775031, JString, required = true,
                                 default = nil)
  if valid_775031 != nil:
    section.add "OptionGroupName", valid_775031
  var valid_775032 = formData.getOrDefault("OptionsToInclude")
  valid_775032 = validateParameter(valid_775032, JArray, required = false,
                                 default = nil)
  if valid_775032 != nil:
    section.add "OptionsToInclude", valid_775032
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775033: Call_PostModifyOptionGroup_775017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775033.validator(path, query, header, formData, body)
  let scheme = call_775033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775033.url(scheme.get, call_775033.host, call_775033.base,
                         call_775033.route, valid.getOrDefault("path"))
  result = hook(call_775033, url, valid)

proc call*(call_775034: Call_PostModifyOptionGroup_775017; OptionGroupName: string;
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
  var query_775035 = newJObject()
  var formData_775036 = newJObject()
  if OptionsToRemove != nil:
    formData_775036.add "OptionsToRemove", OptionsToRemove
  add(formData_775036, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_775036, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_775036.add "OptionsToInclude", OptionsToInclude
  add(query_775035, "Action", newJString(Action))
  add(query_775035, "Version", newJString(Version))
  result = call_775034.call(nil, query_775035, nil, formData_775036, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_775017(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_775018, base: "/",
    url: url_PostModifyOptionGroup_775019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_774998 = ref object of OpenApiRestCall_772581
proc url_GetModifyOptionGroup_775000(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyOptionGroup_774999(path: JsonNode; query: JsonNode;
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
  var valid_775001 = query.getOrDefault("OptionGroupName")
  valid_775001 = validateParameter(valid_775001, JString, required = true,
                                 default = nil)
  if valid_775001 != nil:
    section.add "OptionGroupName", valid_775001
  var valid_775002 = query.getOrDefault("OptionsToRemove")
  valid_775002 = validateParameter(valid_775002, JArray, required = false,
                                 default = nil)
  if valid_775002 != nil:
    section.add "OptionsToRemove", valid_775002
  var valid_775003 = query.getOrDefault("Action")
  valid_775003 = validateParameter(valid_775003, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_775003 != nil:
    section.add "Action", valid_775003
  var valid_775004 = query.getOrDefault("Version")
  valid_775004 = validateParameter(valid_775004, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775004 != nil:
    section.add "Version", valid_775004
  var valid_775005 = query.getOrDefault("ApplyImmediately")
  valid_775005 = validateParameter(valid_775005, JBool, required = false, default = nil)
  if valid_775005 != nil:
    section.add "ApplyImmediately", valid_775005
  var valid_775006 = query.getOrDefault("OptionsToInclude")
  valid_775006 = validateParameter(valid_775006, JArray, required = false,
                                 default = nil)
  if valid_775006 != nil:
    section.add "OptionsToInclude", valid_775006
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775007 = header.getOrDefault("X-Amz-Date")
  valid_775007 = validateParameter(valid_775007, JString, required = false,
                                 default = nil)
  if valid_775007 != nil:
    section.add "X-Amz-Date", valid_775007
  var valid_775008 = header.getOrDefault("X-Amz-Security-Token")
  valid_775008 = validateParameter(valid_775008, JString, required = false,
                                 default = nil)
  if valid_775008 != nil:
    section.add "X-Amz-Security-Token", valid_775008
  var valid_775009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775009 = validateParameter(valid_775009, JString, required = false,
                                 default = nil)
  if valid_775009 != nil:
    section.add "X-Amz-Content-Sha256", valid_775009
  var valid_775010 = header.getOrDefault("X-Amz-Algorithm")
  valid_775010 = validateParameter(valid_775010, JString, required = false,
                                 default = nil)
  if valid_775010 != nil:
    section.add "X-Amz-Algorithm", valid_775010
  var valid_775011 = header.getOrDefault("X-Amz-Signature")
  valid_775011 = validateParameter(valid_775011, JString, required = false,
                                 default = nil)
  if valid_775011 != nil:
    section.add "X-Amz-Signature", valid_775011
  var valid_775012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775012 = validateParameter(valid_775012, JString, required = false,
                                 default = nil)
  if valid_775012 != nil:
    section.add "X-Amz-SignedHeaders", valid_775012
  var valid_775013 = header.getOrDefault("X-Amz-Credential")
  valid_775013 = validateParameter(valid_775013, JString, required = false,
                                 default = nil)
  if valid_775013 != nil:
    section.add "X-Amz-Credential", valid_775013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775014: Call_GetModifyOptionGroup_774998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775014.validator(path, query, header, formData, body)
  let scheme = call_775014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775014.url(scheme.get, call_775014.host, call_775014.base,
                         call_775014.route, valid.getOrDefault("path"))
  result = hook(call_775014, url, valid)

proc call*(call_775015: Call_GetModifyOptionGroup_774998; OptionGroupName: string;
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
  var query_775016 = newJObject()
  add(query_775016, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_775016.add "OptionsToRemove", OptionsToRemove
  add(query_775016, "Action", newJString(Action))
  add(query_775016, "Version", newJString(Version))
  add(query_775016, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_775016.add "OptionsToInclude", OptionsToInclude
  result = call_775015.call(nil, query_775016, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_774998(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_774999, base: "/",
    url: url_GetModifyOptionGroup_775000, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_775055 = ref object of OpenApiRestCall_772581
proc url_PostPromoteReadReplica_775057(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPromoteReadReplica_775056(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775058 = query.getOrDefault("Action")
  valid_775058 = validateParameter(valid_775058, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_775058 != nil:
    section.add "Action", valid_775058
  var valid_775059 = query.getOrDefault("Version")
  valid_775059 = validateParameter(valid_775059, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775059 != nil:
    section.add "Version", valid_775059
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775060 = header.getOrDefault("X-Amz-Date")
  valid_775060 = validateParameter(valid_775060, JString, required = false,
                                 default = nil)
  if valid_775060 != nil:
    section.add "X-Amz-Date", valid_775060
  var valid_775061 = header.getOrDefault("X-Amz-Security-Token")
  valid_775061 = validateParameter(valid_775061, JString, required = false,
                                 default = nil)
  if valid_775061 != nil:
    section.add "X-Amz-Security-Token", valid_775061
  var valid_775062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775062 = validateParameter(valid_775062, JString, required = false,
                                 default = nil)
  if valid_775062 != nil:
    section.add "X-Amz-Content-Sha256", valid_775062
  var valid_775063 = header.getOrDefault("X-Amz-Algorithm")
  valid_775063 = validateParameter(valid_775063, JString, required = false,
                                 default = nil)
  if valid_775063 != nil:
    section.add "X-Amz-Algorithm", valid_775063
  var valid_775064 = header.getOrDefault("X-Amz-Signature")
  valid_775064 = validateParameter(valid_775064, JString, required = false,
                                 default = nil)
  if valid_775064 != nil:
    section.add "X-Amz-Signature", valid_775064
  var valid_775065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775065 = validateParameter(valid_775065, JString, required = false,
                                 default = nil)
  if valid_775065 != nil:
    section.add "X-Amz-SignedHeaders", valid_775065
  var valid_775066 = header.getOrDefault("X-Amz-Credential")
  valid_775066 = validateParameter(valid_775066, JString, required = false,
                                 default = nil)
  if valid_775066 != nil:
    section.add "X-Amz-Credential", valid_775066
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_775067 = formData.getOrDefault("DBInstanceIdentifier")
  valid_775067 = validateParameter(valid_775067, JString, required = true,
                                 default = nil)
  if valid_775067 != nil:
    section.add "DBInstanceIdentifier", valid_775067
  var valid_775068 = formData.getOrDefault("BackupRetentionPeriod")
  valid_775068 = validateParameter(valid_775068, JInt, required = false, default = nil)
  if valid_775068 != nil:
    section.add "BackupRetentionPeriod", valid_775068
  var valid_775069 = formData.getOrDefault("PreferredBackupWindow")
  valid_775069 = validateParameter(valid_775069, JString, required = false,
                                 default = nil)
  if valid_775069 != nil:
    section.add "PreferredBackupWindow", valid_775069
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775070: Call_PostPromoteReadReplica_775055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775070.validator(path, query, header, formData, body)
  let scheme = call_775070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775070.url(scheme.get, call_775070.host, call_775070.base,
                         call_775070.route, valid.getOrDefault("path"))
  result = hook(call_775070, url, valid)

proc call*(call_775071: Call_PostPromoteReadReplica_775055;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_775072 = newJObject()
  var formData_775073 = newJObject()
  add(formData_775073, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_775073, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_775072, "Action", newJString(Action))
  add(formData_775073, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_775072, "Version", newJString(Version))
  result = call_775071.call(nil, query_775072, nil, formData_775073, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_775055(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_775056, base: "/",
    url: url_PostPromoteReadReplica_775057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_775037 = ref object of OpenApiRestCall_772581
proc url_GetPromoteReadReplica_775039(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPromoteReadReplica_775038(path: JsonNode; query: JsonNode;
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
  var valid_775040 = query.getOrDefault("BackupRetentionPeriod")
  valid_775040 = validateParameter(valid_775040, JInt, required = false, default = nil)
  if valid_775040 != nil:
    section.add "BackupRetentionPeriod", valid_775040
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775041 = query.getOrDefault("Action")
  valid_775041 = validateParameter(valid_775041, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_775041 != nil:
    section.add "Action", valid_775041
  var valid_775042 = query.getOrDefault("PreferredBackupWindow")
  valid_775042 = validateParameter(valid_775042, JString, required = false,
                                 default = nil)
  if valid_775042 != nil:
    section.add "PreferredBackupWindow", valid_775042
  var valid_775043 = query.getOrDefault("Version")
  valid_775043 = validateParameter(valid_775043, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775043 != nil:
    section.add "Version", valid_775043
  var valid_775044 = query.getOrDefault("DBInstanceIdentifier")
  valid_775044 = validateParameter(valid_775044, JString, required = true,
                                 default = nil)
  if valid_775044 != nil:
    section.add "DBInstanceIdentifier", valid_775044
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775045 = header.getOrDefault("X-Amz-Date")
  valid_775045 = validateParameter(valid_775045, JString, required = false,
                                 default = nil)
  if valid_775045 != nil:
    section.add "X-Amz-Date", valid_775045
  var valid_775046 = header.getOrDefault("X-Amz-Security-Token")
  valid_775046 = validateParameter(valid_775046, JString, required = false,
                                 default = nil)
  if valid_775046 != nil:
    section.add "X-Amz-Security-Token", valid_775046
  var valid_775047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775047 = validateParameter(valid_775047, JString, required = false,
                                 default = nil)
  if valid_775047 != nil:
    section.add "X-Amz-Content-Sha256", valid_775047
  var valid_775048 = header.getOrDefault("X-Amz-Algorithm")
  valid_775048 = validateParameter(valid_775048, JString, required = false,
                                 default = nil)
  if valid_775048 != nil:
    section.add "X-Amz-Algorithm", valid_775048
  var valid_775049 = header.getOrDefault("X-Amz-Signature")
  valid_775049 = validateParameter(valid_775049, JString, required = false,
                                 default = nil)
  if valid_775049 != nil:
    section.add "X-Amz-Signature", valid_775049
  var valid_775050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775050 = validateParameter(valid_775050, JString, required = false,
                                 default = nil)
  if valid_775050 != nil:
    section.add "X-Amz-SignedHeaders", valid_775050
  var valid_775051 = header.getOrDefault("X-Amz-Credential")
  valid_775051 = validateParameter(valid_775051, JString, required = false,
                                 default = nil)
  if valid_775051 != nil:
    section.add "X-Amz-Credential", valid_775051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775052: Call_GetPromoteReadReplica_775037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775052.validator(path, query, header, formData, body)
  let scheme = call_775052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775052.url(scheme.get, call_775052.host, call_775052.base,
                         call_775052.route, valid.getOrDefault("path"))
  result = hook(call_775052, url, valid)

proc call*(call_775053: Call_GetPromoteReadReplica_775037;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_775054 = newJObject()
  add(query_775054, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_775054, "Action", newJString(Action))
  add(query_775054, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_775054, "Version", newJString(Version))
  add(query_775054, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_775053.call(nil, query_775054, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_775037(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_775038, base: "/",
    url: url_GetPromoteReadReplica_775039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_775093 = ref object of OpenApiRestCall_772581
proc url_PostPurchaseReservedDBInstancesOffering_775095(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPurchaseReservedDBInstancesOffering_775094(path: JsonNode;
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
  var valid_775096 = query.getOrDefault("Action")
  valid_775096 = validateParameter(valid_775096, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_775096 != nil:
    section.add "Action", valid_775096
  var valid_775097 = query.getOrDefault("Version")
  valid_775097 = validateParameter(valid_775097, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775097 != nil:
    section.add "Version", valid_775097
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775098 = header.getOrDefault("X-Amz-Date")
  valid_775098 = validateParameter(valid_775098, JString, required = false,
                                 default = nil)
  if valid_775098 != nil:
    section.add "X-Amz-Date", valid_775098
  var valid_775099 = header.getOrDefault("X-Amz-Security-Token")
  valid_775099 = validateParameter(valid_775099, JString, required = false,
                                 default = nil)
  if valid_775099 != nil:
    section.add "X-Amz-Security-Token", valid_775099
  var valid_775100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775100 = validateParameter(valid_775100, JString, required = false,
                                 default = nil)
  if valid_775100 != nil:
    section.add "X-Amz-Content-Sha256", valid_775100
  var valid_775101 = header.getOrDefault("X-Amz-Algorithm")
  valid_775101 = validateParameter(valid_775101, JString, required = false,
                                 default = nil)
  if valid_775101 != nil:
    section.add "X-Amz-Algorithm", valid_775101
  var valid_775102 = header.getOrDefault("X-Amz-Signature")
  valid_775102 = validateParameter(valid_775102, JString, required = false,
                                 default = nil)
  if valid_775102 != nil:
    section.add "X-Amz-Signature", valid_775102
  var valid_775103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775103 = validateParameter(valid_775103, JString, required = false,
                                 default = nil)
  if valid_775103 != nil:
    section.add "X-Amz-SignedHeaders", valid_775103
  var valid_775104 = header.getOrDefault("X-Amz-Credential")
  valid_775104 = validateParameter(valid_775104, JString, required = false,
                                 default = nil)
  if valid_775104 != nil:
    section.add "X-Amz-Credential", valid_775104
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_775105 = formData.getOrDefault("ReservedDBInstanceId")
  valid_775105 = validateParameter(valid_775105, JString, required = false,
                                 default = nil)
  if valid_775105 != nil:
    section.add "ReservedDBInstanceId", valid_775105
  var valid_775106 = formData.getOrDefault("Tags")
  valid_775106 = validateParameter(valid_775106, JArray, required = false,
                                 default = nil)
  if valid_775106 != nil:
    section.add "Tags", valid_775106
  var valid_775107 = formData.getOrDefault("DBInstanceCount")
  valid_775107 = validateParameter(valid_775107, JInt, required = false, default = nil)
  if valid_775107 != nil:
    section.add "DBInstanceCount", valid_775107
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_775108 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_775108 = validateParameter(valid_775108, JString, required = true,
                                 default = nil)
  if valid_775108 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_775108
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775109: Call_PostPurchaseReservedDBInstancesOffering_775093;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775109.validator(path, query, header, formData, body)
  let scheme = call_775109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775109.url(scheme.get, call_775109.host, call_775109.base,
                         call_775109.route, valid.getOrDefault("path"))
  result = hook(call_775109, url, valid)

proc call*(call_775110: Call_PostPurchaseReservedDBInstancesOffering_775093;
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
  var query_775111 = newJObject()
  var formData_775112 = newJObject()
  add(formData_775112, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_775112.add "Tags", Tags
  add(formData_775112, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_775111, "Action", newJString(Action))
  add(formData_775112, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_775111, "Version", newJString(Version))
  result = call_775110.call(nil, query_775111, nil, formData_775112, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_775093(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_775094, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_775095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_775074 = ref object of OpenApiRestCall_772581
proc url_GetPurchaseReservedDBInstancesOffering_775076(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPurchaseReservedDBInstancesOffering_775075(path: JsonNode;
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
  var valid_775077 = query.getOrDefault("DBInstanceCount")
  valid_775077 = validateParameter(valid_775077, JInt, required = false, default = nil)
  if valid_775077 != nil:
    section.add "DBInstanceCount", valid_775077
  var valid_775078 = query.getOrDefault("Tags")
  valid_775078 = validateParameter(valid_775078, JArray, required = false,
                                 default = nil)
  if valid_775078 != nil:
    section.add "Tags", valid_775078
  var valid_775079 = query.getOrDefault("ReservedDBInstanceId")
  valid_775079 = validateParameter(valid_775079, JString, required = false,
                                 default = nil)
  if valid_775079 != nil:
    section.add "ReservedDBInstanceId", valid_775079
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_775080 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_775080 = validateParameter(valid_775080, JString, required = true,
                                 default = nil)
  if valid_775080 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_775080
  var valid_775081 = query.getOrDefault("Action")
  valid_775081 = validateParameter(valid_775081, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_775081 != nil:
    section.add "Action", valid_775081
  var valid_775082 = query.getOrDefault("Version")
  valid_775082 = validateParameter(valid_775082, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775082 != nil:
    section.add "Version", valid_775082
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775083 = header.getOrDefault("X-Amz-Date")
  valid_775083 = validateParameter(valid_775083, JString, required = false,
                                 default = nil)
  if valid_775083 != nil:
    section.add "X-Amz-Date", valid_775083
  var valid_775084 = header.getOrDefault("X-Amz-Security-Token")
  valid_775084 = validateParameter(valid_775084, JString, required = false,
                                 default = nil)
  if valid_775084 != nil:
    section.add "X-Amz-Security-Token", valid_775084
  var valid_775085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775085 = validateParameter(valid_775085, JString, required = false,
                                 default = nil)
  if valid_775085 != nil:
    section.add "X-Amz-Content-Sha256", valid_775085
  var valid_775086 = header.getOrDefault("X-Amz-Algorithm")
  valid_775086 = validateParameter(valid_775086, JString, required = false,
                                 default = nil)
  if valid_775086 != nil:
    section.add "X-Amz-Algorithm", valid_775086
  var valid_775087 = header.getOrDefault("X-Amz-Signature")
  valid_775087 = validateParameter(valid_775087, JString, required = false,
                                 default = nil)
  if valid_775087 != nil:
    section.add "X-Amz-Signature", valid_775087
  var valid_775088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775088 = validateParameter(valid_775088, JString, required = false,
                                 default = nil)
  if valid_775088 != nil:
    section.add "X-Amz-SignedHeaders", valid_775088
  var valid_775089 = header.getOrDefault("X-Amz-Credential")
  valid_775089 = validateParameter(valid_775089, JString, required = false,
                                 default = nil)
  if valid_775089 != nil:
    section.add "X-Amz-Credential", valid_775089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775090: Call_GetPurchaseReservedDBInstancesOffering_775074;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775090.validator(path, query, header, formData, body)
  let scheme = call_775090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775090.url(scheme.get, call_775090.host, call_775090.base,
                         call_775090.route, valid.getOrDefault("path"))
  result = hook(call_775090, url, valid)

proc call*(call_775091: Call_GetPurchaseReservedDBInstancesOffering_775074;
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
  var query_775092 = newJObject()
  add(query_775092, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_775092.add "Tags", Tags
  add(query_775092, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_775092, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_775092, "Action", newJString(Action))
  add(query_775092, "Version", newJString(Version))
  result = call_775091.call(nil, query_775092, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_775074(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_775075, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_775076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_775130 = ref object of OpenApiRestCall_772581
proc url_PostRebootDBInstance_775132(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebootDBInstance_775131(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775133 = query.getOrDefault("Action")
  valid_775133 = validateParameter(valid_775133, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_775133 != nil:
    section.add "Action", valid_775133
  var valid_775134 = query.getOrDefault("Version")
  valid_775134 = validateParameter(valid_775134, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775134 != nil:
    section.add "Version", valid_775134
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775135 = header.getOrDefault("X-Amz-Date")
  valid_775135 = validateParameter(valid_775135, JString, required = false,
                                 default = nil)
  if valid_775135 != nil:
    section.add "X-Amz-Date", valid_775135
  var valid_775136 = header.getOrDefault("X-Amz-Security-Token")
  valid_775136 = validateParameter(valid_775136, JString, required = false,
                                 default = nil)
  if valid_775136 != nil:
    section.add "X-Amz-Security-Token", valid_775136
  var valid_775137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775137 = validateParameter(valid_775137, JString, required = false,
                                 default = nil)
  if valid_775137 != nil:
    section.add "X-Amz-Content-Sha256", valid_775137
  var valid_775138 = header.getOrDefault("X-Amz-Algorithm")
  valid_775138 = validateParameter(valid_775138, JString, required = false,
                                 default = nil)
  if valid_775138 != nil:
    section.add "X-Amz-Algorithm", valid_775138
  var valid_775139 = header.getOrDefault("X-Amz-Signature")
  valid_775139 = validateParameter(valid_775139, JString, required = false,
                                 default = nil)
  if valid_775139 != nil:
    section.add "X-Amz-Signature", valid_775139
  var valid_775140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775140 = validateParameter(valid_775140, JString, required = false,
                                 default = nil)
  if valid_775140 != nil:
    section.add "X-Amz-SignedHeaders", valid_775140
  var valid_775141 = header.getOrDefault("X-Amz-Credential")
  valid_775141 = validateParameter(valid_775141, JString, required = false,
                                 default = nil)
  if valid_775141 != nil:
    section.add "X-Amz-Credential", valid_775141
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_775142 = formData.getOrDefault("DBInstanceIdentifier")
  valid_775142 = validateParameter(valid_775142, JString, required = true,
                                 default = nil)
  if valid_775142 != nil:
    section.add "DBInstanceIdentifier", valid_775142
  var valid_775143 = formData.getOrDefault("ForceFailover")
  valid_775143 = validateParameter(valid_775143, JBool, required = false, default = nil)
  if valid_775143 != nil:
    section.add "ForceFailover", valid_775143
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775144: Call_PostRebootDBInstance_775130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775144.validator(path, query, header, formData, body)
  let scheme = call_775144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775144.url(scheme.get, call_775144.host, call_775144.base,
                         call_775144.route, valid.getOrDefault("path"))
  result = hook(call_775144, url, valid)

proc call*(call_775145: Call_PostRebootDBInstance_775130;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_775146 = newJObject()
  var formData_775147 = newJObject()
  add(formData_775147, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_775146, "Action", newJString(Action))
  add(formData_775147, "ForceFailover", newJBool(ForceFailover))
  add(query_775146, "Version", newJString(Version))
  result = call_775145.call(nil, query_775146, nil, formData_775147, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_775130(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_775131, base: "/",
    url: url_PostRebootDBInstance_775132, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_775113 = ref object of OpenApiRestCall_772581
proc url_GetRebootDBInstance_775115(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebootDBInstance_775114(path: JsonNode; query: JsonNode;
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
  var valid_775116 = query.getOrDefault("Action")
  valid_775116 = validateParameter(valid_775116, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_775116 != nil:
    section.add "Action", valid_775116
  var valid_775117 = query.getOrDefault("ForceFailover")
  valid_775117 = validateParameter(valid_775117, JBool, required = false, default = nil)
  if valid_775117 != nil:
    section.add "ForceFailover", valid_775117
  var valid_775118 = query.getOrDefault("Version")
  valid_775118 = validateParameter(valid_775118, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775118 != nil:
    section.add "Version", valid_775118
  var valid_775119 = query.getOrDefault("DBInstanceIdentifier")
  valid_775119 = validateParameter(valid_775119, JString, required = true,
                                 default = nil)
  if valid_775119 != nil:
    section.add "DBInstanceIdentifier", valid_775119
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775120 = header.getOrDefault("X-Amz-Date")
  valid_775120 = validateParameter(valid_775120, JString, required = false,
                                 default = nil)
  if valid_775120 != nil:
    section.add "X-Amz-Date", valid_775120
  var valid_775121 = header.getOrDefault("X-Amz-Security-Token")
  valid_775121 = validateParameter(valid_775121, JString, required = false,
                                 default = nil)
  if valid_775121 != nil:
    section.add "X-Amz-Security-Token", valid_775121
  var valid_775122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775122 = validateParameter(valid_775122, JString, required = false,
                                 default = nil)
  if valid_775122 != nil:
    section.add "X-Amz-Content-Sha256", valid_775122
  var valid_775123 = header.getOrDefault("X-Amz-Algorithm")
  valid_775123 = validateParameter(valid_775123, JString, required = false,
                                 default = nil)
  if valid_775123 != nil:
    section.add "X-Amz-Algorithm", valid_775123
  var valid_775124 = header.getOrDefault("X-Amz-Signature")
  valid_775124 = validateParameter(valid_775124, JString, required = false,
                                 default = nil)
  if valid_775124 != nil:
    section.add "X-Amz-Signature", valid_775124
  var valid_775125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775125 = validateParameter(valid_775125, JString, required = false,
                                 default = nil)
  if valid_775125 != nil:
    section.add "X-Amz-SignedHeaders", valid_775125
  var valid_775126 = header.getOrDefault("X-Amz-Credential")
  valid_775126 = validateParameter(valid_775126, JString, required = false,
                                 default = nil)
  if valid_775126 != nil:
    section.add "X-Amz-Credential", valid_775126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775127: Call_GetRebootDBInstance_775113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775127.validator(path, query, header, formData, body)
  let scheme = call_775127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775127.url(scheme.get, call_775127.host, call_775127.base,
                         call_775127.route, valid.getOrDefault("path"))
  result = hook(call_775127, url, valid)

proc call*(call_775128: Call_GetRebootDBInstance_775113;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_775129 = newJObject()
  add(query_775129, "Action", newJString(Action))
  add(query_775129, "ForceFailover", newJBool(ForceFailover))
  add(query_775129, "Version", newJString(Version))
  add(query_775129, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_775128.call(nil, query_775129, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_775113(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_775114, base: "/",
    url: url_GetRebootDBInstance_775115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_775165 = ref object of OpenApiRestCall_772581
proc url_PostRemoveSourceIdentifierFromSubscription_775167(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_775166(path: JsonNode;
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
      "RemoveSourceIdentifierFromSubscription"))
  if valid_775168 != nil:
    section.add "Action", valid_775168
  var valid_775169 = query.getOrDefault("Version")
  valid_775169 = validateParameter(valid_775169, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_775177 = formData.getOrDefault("SourceIdentifier")
  valid_775177 = validateParameter(valid_775177, JString, required = true,
                                 default = nil)
  if valid_775177 != nil:
    section.add "SourceIdentifier", valid_775177
  var valid_775178 = formData.getOrDefault("SubscriptionName")
  valid_775178 = validateParameter(valid_775178, JString, required = true,
                                 default = nil)
  if valid_775178 != nil:
    section.add "SubscriptionName", valid_775178
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775179: Call_PostRemoveSourceIdentifierFromSubscription_775165;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775179.validator(path, query, header, formData, body)
  let scheme = call_775179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775179.url(scheme.get, call_775179.host, call_775179.base,
                         call_775179.route, valid.getOrDefault("path"))
  result = hook(call_775179, url, valid)

proc call*(call_775180: Call_PostRemoveSourceIdentifierFromSubscription_775165;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_775181 = newJObject()
  var formData_775182 = newJObject()
  add(formData_775182, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_775182, "SubscriptionName", newJString(SubscriptionName))
  add(query_775181, "Action", newJString(Action))
  add(query_775181, "Version", newJString(Version))
  result = call_775180.call(nil, query_775181, nil, formData_775182, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_775165(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_775166,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_775167,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_775148 = ref object of OpenApiRestCall_772581
proc url_GetRemoveSourceIdentifierFromSubscription_775150(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_775149(path: JsonNode;
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
  var valid_775151 = query.getOrDefault("Action")
  valid_775151 = validateParameter(valid_775151, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_775151 != nil:
    section.add "Action", valid_775151
  var valid_775152 = query.getOrDefault("SourceIdentifier")
  valid_775152 = validateParameter(valid_775152, JString, required = true,
                                 default = nil)
  if valid_775152 != nil:
    section.add "SourceIdentifier", valid_775152
  var valid_775153 = query.getOrDefault("SubscriptionName")
  valid_775153 = validateParameter(valid_775153, JString, required = true,
                                 default = nil)
  if valid_775153 != nil:
    section.add "SubscriptionName", valid_775153
  var valid_775154 = query.getOrDefault("Version")
  valid_775154 = validateParameter(valid_775154, JString, required = true,
                                 default = newJString("2014-09-01"))
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

proc call*(call_775162: Call_GetRemoveSourceIdentifierFromSubscription_775148;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775162.validator(path, query, header, formData, body)
  let scheme = call_775162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775162.url(scheme.get, call_775162.host, call_775162.base,
                         call_775162.route, valid.getOrDefault("path"))
  result = hook(call_775162, url, valid)

proc call*(call_775163: Call_GetRemoveSourceIdentifierFromSubscription_775148;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_775164 = newJObject()
  add(query_775164, "Action", newJString(Action))
  add(query_775164, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_775164, "SubscriptionName", newJString(SubscriptionName))
  add(query_775164, "Version", newJString(Version))
  result = call_775163.call(nil, query_775164, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_775148(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_775149,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_775150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_775200 = ref object of OpenApiRestCall_772581
proc url_PostRemoveTagsFromResource_775202(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTagsFromResource_775201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775203 = query.getOrDefault("Action")
  valid_775203 = validateParameter(valid_775203, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_775203 != nil:
    section.add "Action", valid_775203
  var valid_775204 = query.getOrDefault("Version")
  valid_775204 = validateParameter(valid_775204, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775204 != nil:
    section.add "Version", valid_775204
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775205 = header.getOrDefault("X-Amz-Date")
  valid_775205 = validateParameter(valid_775205, JString, required = false,
                                 default = nil)
  if valid_775205 != nil:
    section.add "X-Amz-Date", valid_775205
  var valid_775206 = header.getOrDefault("X-Amz-Security-Token")
  valid_775206 = validateParameter(valid_775206, JString, required = false,
                                 default = nil)
  if valid_775206 != nil:
    section.add "X-Amz-Security-Token", valid_775206
  var valid_775207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775207 = validateParameter(valid_775207, JString, required = false,
                                 default = nil)
  if valid_775207 != nil:
    section.add "X-Amz-Content-Sha256", valid_775207
  var valid_775208 = header.getOrDefault("X-Amz-Algorithm")
  valid_775208 = validateParameter(valid_775208, JString, required = false,
                                 default = nil)
  if valid_775208 != nil:
    section.add "X-Amz-Algorithm", valid_775208
  var valid_775209 = header.getOrDefault("X-Amz-Signature")
  valid_775209 = validateParameter(valid_775209, JString, required = false,
                                 default = nil)
  if valid_775209 != nil:
    section.add "X-Amz-Signature", valid_775209
  var valid_775210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775210 = validateParameter(valid_775210, JString, required = false,
                                 default = nil)
  if valid_775210 != nil:
    section.add "X-Amz-SignedHeaders", valid_775210
  var valid_775211 = header.getOrDefault("X-Amz-Credential")
  valid_775211 = validateParameter(valid_775211, JString, required = false,
                                 default = nil)
  if valid_775211 != nil:
    section.add "X-Amz-Credential", valid_775211
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_775212 = formData.getOrDefault("TagKeys")
  valid_775212 = validateParameter(valid_775212, JArray, required = true, default = nil)
  if valid_775212 != nil:
    section.add "TagKeys", valid_775212
  var valid_775213 = formData.getOrDefault("ResourceName")
  valid_775213 = validateParameter(valid_775213, JString, required = true,
                                 default = nil)
  if valid_775213 != nil:
    section.add "ResourceName", valid_775213
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775214: Call_PostRemoveTagsFromResource_775200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775214.validator(path, query, header, formData, body)
  let scheme = call_775214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775214.url(scheme.get, call_775214.host, call_775214.base,
                         call_775214.route, valid.getOrDefault("path"))
  result = hook(call_775214, url, valid)

proc call*(call_775215: Call_PostRemoveTagsFromResource_775200; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_775216 = newJObject()
  var formData_775217 = newJObject()
  add(query_775216, "Action", newJString(Action))
  if TagKeys != nil:
    formData_775217.add "TagKeys", TagKeys
  add(formData_775217, "ResourceName", newJString(ResourceName))
  add(query_775216, "Version", newJString(Version))
  result = call_775215.call(nil, query_775216, nil, formData_775217, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_775200(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_775201, base: "/",
    url: url_PostRemoveTagsFromResource_775202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_775183 = ref object of OpenApiRestCall_772581
proc url_GetRemoveTagsFromResource_775185(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTagsFromResource_775184(path: JsonNode; query: JsonNode;
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
  var valid_775186 = query.getOrDefault("ResourceName")
  valid_775186 = validateParameter(valid_775186, JString, required = true,
                                 default = nil)
  if valid_775186 != nil:
    section.add "ResourceName", valid_775186
  var valid_775187 = query.getOrDefault("Action")
  valid_775187 = validateParameter(valid_775187, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_775187 != nil:
    section.add "Action", valid_775187
  var valid_775188 = query.getOrDefault("TagKeys")
  valid_775188 = validateParameter(valid_775188, JArray, required = true, default = nil)
  if valid_775188 != nil:
    section.add "TagKeys", valid_775188
  var valid_775189 = query.getOrDefault("Version")
  valid_775189 = validateParameter(valid_775189, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775189 != nil:
    section.add "Version", valid_775189
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775190 = header.getOrDefault("X-Amz-Date")
  valid_775190 = validateParameter(valid_775190, JString, required = false,
                                 default = nil)
  if valid_775190 != nil:
    section.add "X-Amz-Date", valid_775190
  var valid_775191 = header.getOrDefault("X-Amz-Security-Token")
  valid_775191 = validateParameter(valid_775191, JString, required = false,
                                 default = nil)
  if valid_775191 != nil:
    section.add "X-Amz-Security-Token", valid_775191
  var valid_775192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775192 = validateParameter(valid_775192, JString, required = false,
                                 default = nil)
  if valid_775192 != nil:
    section.add "X-Amz-Content-Sha256", valid_775192
  var valid_775193 = header.getOrDefault("X-Amz-Algorithm")
  valid_775193 = validateParameter(valid_775193, JString, required = false,
                                 default = nil)
  if valid_775193 != nil:
    section.add "X-Amz-Algorithm", valid_775193
  var valid_775194 = header.getOrDefault("X-Amz-Signature")
  valid_775194 = validateParameter(valid_775194, JString, required = false,
                                 default = nil)
  if valid_775194 != nil:
    section.add "X-Amz-Signature", valid_775194
  var valid_775195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775195 = validateParameter(valid_775195, JString, required = false,
                                 default = nil)
  if valid_775195 != nil:
    section.add "X-Amz-SignedHeaders", valid_775195
  var valid_775196 = header.getOrDefault("X-Amz-Credential")
  valid_775196 = validateParameter(valid_775196, JString, required = false,
                                 default = nil)
  if valid_775196 != nil:
    section.add "X-Amz-Credential", valid_775196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775197: Call_GetRemoveTagsFromResource_775183; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775197.validator(path, query, header, formData, body)
  let scheme = call_775197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775197.url(scheme.get, call_775197.host, call_775197.base,
                         call_775197.route, valid.getOrDefault("path"))
  result = hook(call_775197, url, valid)

proc call*(call_775198: Call_GetRemoveTagsFromResource_775183;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-09-01"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_775199 = newJObject()
  add(query_775199, "ResourceName", newJString(ResourceName))
  add(query_775199, "Action", newJString(Action))
  if TagKeys != nil:
    query_775199.add "TagKeys", TagKeys
  add(query_775199, "Version", newJString(Version))
  result = call_775198.call(nil, query_775199, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_775183(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_775184, base: "/",
    url: url_GetRemoveTagsFromResource_775185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_775236 = ref object of OpenApiRestCall_772581
proc url_PostResetDBParameterGroup_775238(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostResetDBParameterGroup_775237(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775239 = query.getOrDefault("Action")
  valid_775239 = validateParameter(valid_775239, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_775239 != nil:
    section.add "Action", valid_775239
  var valid_775240 = query.getOrDefault("Version")
  valid_775240 = validateParameter(valid_775240, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775240 != nil:
    section.add "Version", valid_775240
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775241 = header.getOrDefault("X-Amz-Date")
  valid_775241 = validateParameter(valid_775241, JString, required = false,
                                 default = nil)
  if valid_775241 != nil:
    section.add "X-Amz-Date", valid_775241
  var valid_775242 = header.getOrDefault("X-Amz-Security-Token")
  valid_775242 = validateParameter(valid_775242, JString, required = false,
                                 default = nil)
  if valid_775242 != nil:
    section.add "X-Amz-Security-Token", valid_775242
  var valid_775243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775243 = validateParameter(valid_775243, JString, required = false,
                                 default = nil)
  if valid_775243 != nil:
    section.add "X-Amz-Content-Sha256", valid_775243
  var valid_775244 = header.getOrDefault("X-Amz-Algorithm")
  valid_775244 = validateParameter(valid_775244, JString, required = false,
                                 default = nil)
  if valid_775244 != nil:
    section.add "X-Amz-Algorithm", valid_775244
  var valid_775245 = header.getOrDefault("X-Amz-Signature")
  valid_775245 = validateParameter(valid_775245, JString, required = false,
                                 default = nil)
  if valid_775245 != nil:
    section.add "X-Amz-Signature", valid_775245
  var valid_775246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775246 = validateParameter(valid_775246, JString, required = false,
                                 default = nil)
  if valid_775246 != nil:
    section.add "X-Amz-SignedHeaders", valid_775246
  var valid_775247 = header.getOrDefault("X-Amz-Credential")
  valid_775247 = validateParameter(valid_775247, JString, required = false,
                                 default = nil)
  if valid_775247 != nil:
    section.add "X-Amz-Credential", valid_775247
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_775248 = formData.getOrDefault("DBParameterGroupName")
  valid_775248 = validateParameter(valid_775248, JString, required = true,
                                 default = nil)
  if valid_775248 != nil:
    section.add "DBParameterGroupName", valid_775248
  var valid_775249 = formData.getOrDefault("Parameters")
  valid_775249 = validateParameter(valid_775249, JArray, required = false,
                                 default = nil)
  if valid_775249 != nil:
    section.add "Parameters", valid_775249
  var valid_775250 = formData.getOrDefault("ResetAllParameters")
  valid_775250 = validateParameter(valid_775250, JBool, required = false, default = nil)
  if valid_775250 != nil:
    section.add "ResetAllParameters", valid_775250
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775251: Call_PostResetDBParameterGroup_775236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775251.validator(path, query, header, formData, body)
  let scheme = call_775251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775251.url(scheme.get, call_775251.host, call_775251.base,
                         call_775251.route, valid.getOrDefault("path"))
  result = hook(call_775251, url, valid)

proc call*(call_775252: Call_PostResetDBParameterGroup_775236;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_775253 = newJObject()
  var formData_775254 = newJObject()
  add(formData_775254, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_775254.add "Parameters", Parameters
  add(query_775253, "Action", newJString(Action))
  add(formData_775254, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_775253, "Version", newJString(Version))
  result = call_775252.call(nil, query_775253, nil, formData_775254, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_775236(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_775237, base: "/",
    url: url_PostResetDBParameterGroup_775238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_775218 = ref object of OpenApiRestCall_772581
proc url_GetResetDBParameterGroup_775220(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResetDBParameterGroup_775219(path: JsonNode; query: JsonNode;
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
  var valid_775221 = query.getOrDefault("DBParameterGroupName")
  valid_775221 = validateParameter(valid_775221, JString, required = true,
                                 default = nil)
  if valid_775221 != nil:
    section.add "DBParameterGroupName", valid_775221
  var valid_775222 = query.getOrDefault("Parameters")
  valid_775222 = validateParameter(valid_775222, JArray, required = false,
                                 default = nil)
  if valid_775222 != nil:
    section.add "Parameters", valid_775222
  var valid_775223 = query.getOrDefault("Action")
  valid_775223 = validateParameter(valid_775223, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_775223 != nil:
    section.add "Action", valid_775223
  var valid_775224 = query.getOrDefault("ResetAllParameters")
  valid_775224 = validateParameter(valid_775224, JBool, required = false, default = nil)
  if valid_775224 != nil:
    section.add "ResetAllParameters", valid_775224
  var valid_775225 = query.getOrDefault("Version")
  valid_775225 = validateParameter(valid_775225, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775225 != nil:
    section.add "Version", valid_775225
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775226 = header.getOrDefault("X-Amz-Date")
  valid_775226 = validateParameter(valid_775226, JString, required = false,
                                 default = nil)
  if valid_775226 != nil:
    section.add "X-Amz-Date", valid_775226
  var valid_775227 = header.getOrDefault("X-Amz-Security-Token")
  valid_775227 = validateParameter(valid_775227, JString, required = false,
                                 default = nil)
  if valid_775227 != nil:
    section.add "X-Amz-Security-Token", valid_775227
  var valid_775228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775228 = validateParameter(valid_775228, JString, required = false,
                                 default = nil)
  if valid_775228 != nil:
    section.add "X-Amz-Content-Sha256", valid_775228
  var valid_775229 = header.getOrDefault("X-Amz-Algorithm")
  valid_775229 = validateParameter(valid_775229, JString, required = false,
                                 default = nil)
  if valid_775229 != nil:
    section.add "X-Amz-Algorithm", valid_775229
  var valid_775230 = header.getOrDefault("X-Amz-Signature")
  valid_775230 = validateParameter(valid_775230, JString, required = false,
                                 default = nil)
  if valid_775230 != nil:
    section.add "X-Amz-Signature", valid_775230
  var valid_775231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775231 = validateParameter(valid_775231, JString, required = false,
                                 default = nil)
  if valid_775231 != nil:
    section.add "X-Amz-SignedHeaders", valid_775231
  var valid_775232 = header.getOrDefault("X-Amz-Credential")
  valid_775232 = validateParameter(valid_775232, JString, required = false,
                                 default = nil)
  if valid_775232 != nil:
    section.add "X-Amz-Credential", valid_775232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775233: Call_GetResetDBParameterGroup_775218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775233.validator(path, query, header, formData, body)
  let scheme = call_775233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775233.url(scheme.get, call_775233.host, call_775233.base,
                         call_775233.route, valid.getOrDefault("path"))
  result = hook(call_775233, url, valid)

proc call*(call_775234: Call_GetResetDBParameterGroup_775218;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_775235 = newJObject()
  add(query_775235, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_775235.add "Parameters", Parameters
  add(query_775235, "Action", newJString(Action))
  add(query_775235, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_775235, "Version", newJString(Version))
  result = call_775234.call(nil, query_775235, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_775218(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_775219, base: "/",
    url: url_GetResetDBParameterGroup_775220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_775288 = ref object of OpenApiRestCall_772581
proc url_PostRestoreDBInstanceFromDBSnapshot_775290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_775289(path: JsonNode;
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
  var valid_775291 = query.getOrDefault("Action")
  valid_775291 = validateParameter(valid_775291, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_775291 != nil:
    section.add "Action", valid_775291
  var valid_775292 = query.getOrDefault("Version")
  valid_775292 = validateParameter(valid_775292, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775292 != nil:
    section.add "Version", valid_775292
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775293 = header.getOrDefault("X-Amz-Date")
  valid_775293 = validateParameter(valid_775293, JString, required = false,
                                 default = nil)
  if valid_775293 != nil:
    section.add "X-Amz-Date", valid_775293
  var valid_775294 = header.getOrDefault("X-Amz-Security-Token")
  valid_775294 = validateParameter(valid_775294, JString, required = false,
                                 default = nil)
  if valid_775294 != nil:
    section.add "X-Amz-Security-Token", valid_775294
  var valid_775295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775295 = validateParameter(valid_775295, JString, required = false,
                                 default = nil)
  if valid_775295 != nil:
    section.add "X-Amz-Content-Sha256", valid_775295
  var valid_775296 = header.getOrDefault("X-Amz-Algorithm")
  valid_775296 = validateParameter(valid_775296, JString, required = false,
                                 default = nil)
  if valid_775296 != nil:
    section.add "X-Amz-Algorithm", valid_775296
  var valid_775297 = header.getOrDefault("X-Amz-Signature")
  valid_775297 = validateParameter(valid_775297, JString, required = false,
                                 default = nil)
  if valid_775297 != nil:
    section.add "X-Amz-Signature", valid_775297
  var valid_775298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775298 = validateParameter(valid_775298, JString, required = false,
                                 default = nil)
  if valid_775298 != nil:
    section.add "X-Amz-SignedHeaders", valid_775298
  var valid_775299 = header.getOrDefault("X-Amz-Credential")
  valid_775299 = validateParameter(valid_775299, JString, required = false,
                                 default = nil)
  if valid_775299 != nil:
    section.add "X-Amz-Credential", valid_775299
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
  var valid_775300 = formData.getOrDefault("Port")
  valid_775300 = validateParameter(valid_775300, JInt, required = false, default = nil)
  if valid_775300 != nil:
    section.add "Port", valid_775300
  var valid_775301 = formData.getOrDefault("Engine")
  valid_775301 = validateParameter(valid_775301, JString, required = false,
                                 default = nil)
  if valid_775301 != nil:
    section.add "Engine", valid_775301
  var valid_775302 = formData.getOrDefault("Iops")
  valid_775302 = validateParameter(valid_775302, JInt, required = false, default = nil)
  if valid_775302 != nil:
    section.add "Iops", valid_775302
  var valid_775303 = formData.getOrDefault("DBName")
  valid_775303 = validateParameter(valid_775303, JString, required = false,
                                 default = nil)
  if valid_775303 != nil:
    section.add "DBName", valid_775303
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_775304 = formData.getOrDefault("DBInstanceIdentifier")
  valid_775304 = validateParameter(valid_775304, JString, required = true,
                                 default = nil)
  if valid_775304 != nil:
    section.add "DBInstanceIdentifier", valid_775304
  var valid_775305 = formData.getOrDefault("OptionGroupName")
  valid_775305 = validateParameter(valid_775305, JString, required = false,
                                 default = nil)
  if valid_775305 != nil:
    section.add "OptionGroupName", valid_775305
  var valid_775306 = formData.getOrDefault("Tags")
  valid_775306 = validateParameter(valid_775306, JArray, required = false,
                                 default = nil)
  if valid_775306 != nil:
    section.add "Tags", valid_775306
  var valid_775307 = formData.getOrDefault("TdeCredentialArn")
  valid_775307 = validateParameter(valid_775307, JString, required = false,
                                 default = nil)
  if valid_775307 != nil:
    section.add "TdeCredentialArn", valid_775307
  var valid_775308 = formData.getOrDefault("DBSubnetGroupName")
  valid_775308 = validateParameter(valid_775308, JString, required = false,
                                 default = nil)
  if valid_775308 != nil:
    section.add "DBSubnetGroupName", valid_775308
  var valid_775309 = formData.getOrDefault("TdeCredentialPassword")
  valid_775309 = validateParameter(valid_775309, JString, required = false,
                                 default = nil)
  if valid_775309 != nil:
    section.add "TdeCredentialPassword", valid_775309
  var valid_775310 = formData.getOrDefault("AvailabilityZone")
  valid_775310 = validateParameter(valid_775310, JString, required = false,
                                 default = nil)
  if valid_775310 != nil:
    section.add "AvailabilityZone", valid_775310
  var valid_775311 = formData.getOrDefault("MultiAZ")
  valid_775311 = validateParameter(valid_775311, JBool, required = false, default = nil)
  if valid_775311 != nil:
    section.add "MultiAZ", valid_775311
  var valid_775312 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_775312 = validateParameter(valid_775312, JString, required = true,
                                 default = nil)
  if valid_775312 != nil:
    section.add "DBSnapshotIdentifier", valid_775312
  var valid_775313 = formData.getOrDefault("PubliclyAccessible")
  valid_775313 = validateParameter(valid_775313, JBool, required = false, default = nil)
  if valid_775313 != nil:
    section.add "PubliclyAccessible", valid_775313
  var valid_775314 = formData.getOrDefault("StorageType")
  valid_775314 = validateParameter(valid_775314, JString, required = false,
                                 default = nil)
  if valid_775314 != nil:
    section.add "StorageType", valid_775314
  var valid_775315 = formData.getOrDefault("DBInstanceClass")
  valid_775315 = validateParameter(valid_775315, JString, required = false,
                                 default = nil)
  if valid_775315 != nil:
    section.add "DBInstanceClass", valid_775315
  var valid_775316 = formData.getOrDefault("LicenseModel")
  valid_775316 = validateParameter(valid_775316, JString, required = false,
                                 default = nil)
  if valid_775316 != nil:
    section.add "LicenseModel", valid_775316
  var valid_775317 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_775317 = validateParameter(valid_775317, JBool, required = false, default = nil)
  if valid_775317 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775317
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775318: Call_PostRestoreDBInstanceFromDBSnapshot_775288;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775318.validator(path, query, header, formData, body)
  let scheme = call_775318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775318.url(scheme.get, call_775318.host, call_775318.base,
                         call_775318.route, valid.getOrDefault("path"))
  result = hook(call_775318, url, valid)

proc call*(call_775319: Call_PostRestoreDBInstanceFromDBSnapshot_775288;
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
  var query_775320 = newJObject()
  var formData_775321 = newJObject()
  add(formData_775321, "Port", newJInt(Port))
  add(formData_775321, "Engine", newJString(Engine))
  add(formData_775321, "Iops", newJInt(Iops))
  add(formData_775321, "DBName", newJString(DBName))
  add(formData_775321, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_775321, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_775321.add "Tags", Tags
  add(formData_775321, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_775321, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_775321, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_775321, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_775321, "MultiAZ", newJBool(MultiAZ))
  add(formData_775321, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_775320, "Action", newJString(Action))
  add(formData_775321, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_775321, "StorageType", newJString(StorageType))
  add(formData_775321, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_775321, "LicenseModel", newJString(LicenseModel))
  add(formData_775321, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_775320, "Version", newJString(Version))
  result = call_775319.call(nil, query_775320, nil, formData_775321, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_775288(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_775289, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_775290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_775255 = ref object of OpenApiRestCall_772581
proc url_GetRestoreDBInstanceFromDBSnapshot_775257(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_775256(path: JsonNode;
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
  var valid_775258 = query.getOrDefault("Engine")
  valid_775258 = validateParameter(valid_775258, JString, required = false,
                                 default = nil)
  if valid_775258 != nil:
    section.add "Engine", valid_775258
  var valid_775259 = query.getOrDefault("StorageType")
  valid_775259 = validateParameter(valid_775259, JString, required = false,
                                 default = nil)
  if valid_775259 != nil:
    section.add "StorageType", valid_775259
  var valid_775260 = query.getOrDefault("OptionGroupName")
  valid_775260 = validateParameter(valid_775260, JString, required = false,
                                 default = nil)
  if valid_775260 != nil:
    section.add "OptionGroupName", valid_775260
  var valid_775261 = query.getOrDefault("AvailabilityZone")
  valid_775261 = validateParameter(valid_775261, JString, required = false,
                                 default = nil)
  if valid_775261 != nil:
    section.add "AvailabilityZone", valid_775261
  var valid_775262 = query.getOrDefault("Iops")
  valid_775262 = validateParameter(valid_775262, JInt, required = false, default = nil)
  if valid_775262 != nil:
    section.add "Iops", valid_775262
  var valid_775263 = query.getOrDefault("MultiAZ")
  valid_775263 = validateParameter(valid_775263, JBool, required = false, default = nil)
  if valid_775263 != nil:
    section.add "MultiAZ", valid_775263
  var valid_775264 = query.getOrDefault("TdeCredentialPassword")
  valid_775264 = validateParameter(valid_775264, JString, required = false,
                                 default = nil)
  if valid_775264 != nil:
    section.add "TdeCredentialPassword", valid_775264
  var valid_775265 = query.getOrDefault("LicenseModel")
  valid_775265 = validateParameter(valid_775265, JString, required = false,
                                 default = nil)
  if valid_775265 != nil:
    section.add "LicenseModel", valid_775265
  var valid_775266 = query.getOrDefault("Tags")
  valid_775266 = validateParameter(valid_775266, JArray, required = false,
                                 default = nil)
  if valid_775266 != nil:
    section.add "Tags", valid_775266
  var valid_775267 = query.getOrDefault("DBName")
  valid_775267 = validateParameter(valid_775267, JString, required = false,
                                 default = nil)
  if valid_775267 != nil:
    section.add "DBName", valid_775267
  var valid_775268 = query.getOrDefault("DBInstanceClass")
  valid_775268 = validateParameter(valid_775268, JString, required = false,
                                 default = nil)
  if valid_775268 != nil:
    section.add "DBInstanceClass", valid_775268
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775269 = query.getOrDefault("Action")
  valid_775269 = validateParameter(valid_775269, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_775269 != nil:
    section.add "Action", valid_775269
  var valid_775270 = query.getOrDefault("DBSubnetGroupName")
  valid_775270 = validateParameter(valid_775270, JString, required = false,
                                 default = nil)
  if valid_775270 != nil:
    section.add "DBSubnetGroupName", valid_775270
  var valid_775271 = query.getOrDefault("TdeCredentialArn")
  valid_775271 = validateParameter(valid_775271, JString, required = false,
                                 default = nil)
  if valid_775271 != nil:
    section.add "TdeCredentialArn", valid_775271
  var valid_775272 = query.getOrDefault("PubliclyAccessible")
  valid_775272 = validateParameter(valid_775272, JBool, required = false, default = nil)
  if valid_775272 != nil:
    section.add "PubliclyAccessible", valid_775272
  var valid_775273 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_775273 = validateParameter(valid_775273, JBool, required = false, default = nil)
  if valid_775273 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775273
  var valid_775274 = query.getOrDefault("Port")
  valid_775274 = validateParameter(valid_775274, JInt, required = false, default = nil)
  if valid_775274 != nil:
    section.add "Port", valid_775274
  var valid_775275 = query.getOrDefault("Version")
  valid_775275 = validateParameter(valid_775275, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775275 != nil:
    section.add "Version", valid_775275
  var valid_775276 = query.getOrDefault("DBInstanceIdentifier")
  valid_775276 = validateParameter(valid_775276, JString, required = true,
                                 default = nil)
  if valid_775276 != nil:
    section.add "DBInstanceIdentifier", valid_775276
  var valid_775277 = query.getOrDefault("DBSnapshotIdentifier")
  valid_775277 = validateParameter(valid_775277, JString, required = true,
                                 default = nil)
  if valid_775277 != nil:
    section.add "DBSnapshotIdentifier", valid_775277
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775278 = header.getOrDefault("X-Amz-Date")
  valid_775278 = validateParameter(valid_775278, JString, required = false,
                                 default = nil)
  if valid_775278 != nil:
    section.add "X-Amz-Date", valid_775278
  var valid_775279 = header.getOrDefault("X-Amz-Security-Token")
  valid_775279 = validateParameter(valid_775279, JString, required = false,
                                 default = nil)
  if valid_775279 != nil:
    section.add "X-Amz-Security-Token", valid_775279
  var valid_775280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775280 = validateParameter(valid_775280, JString, required = false,
                                 default = nil)
  if valid_775280 != nil:
    section.add "X-Amz-Content-Sha256", valid_775280
  var valid_775281 = header.getOrDefault("X-Amz-Algorithm")
  valid_775281 = validateParameter(valid_775281, JString, required = false,
                                 default = nil)
  if valid_775281 != nil:
    section.add "X-Amz-Algorithm", valid_775281
  var valid_775282 = header.getOrDefault("X-Amz-Signature")
  valid_775282 = validateParameter(valid_775282, JString, required = false,
                                 default = nil)
  if valid_775282 != nil:
    section.add "X-Amz-Signature", valid_775282
  var valid_775283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775283 = validateParameter(valid_775283, JString, required = false,
                                 default = nil)
  if valid_775283 != nil:
    section.add "X-Amz-SignedHeaders", valid_775283
  var valid_775284 = header.getOrDefault("X-Amz-Credential")
  valid_775284 = validateParameter(valid_775284, JString, required = false,
                                 default = nil)
  if valid_775284 != nil:
    section.add "X-Amz-Credential", valid_775284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775285: Call_GetRestoreDBInstanceFromDBSnapshot_775255;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775285.validator(path, query, header, formData, body)
  let scheme = call_775285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775285.url(scheme.get, call_775285.host, call_775285.base,
                         call_775285.route, valid.getOrDefault("path"))
  result = hook(call_775285, url, valid)

proc call*(call_775286: Call_GetRestoreDBInstanceFromDBSnapshot_775255;
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
  var query_775287 = newJObject()
  add(query_775287, "Engine", newJString(Engine))
  add(query_775287, "StorageType", newJString(StorageType))
  add(query_775287, "OptionGroupName", newJString(OptionGroupName))
  add(query_775287, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_775287, "Iops", newJInt(Iops))
  add(query_775287, "MultiAZ", newJBool(MultiAZ))
  add(query_775287, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_775287, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_775287.add "Tags", Tags
  add(query_775287, "DBName", newJString(DBName))
  add(query_775287, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_775287, "Action", newJString(Action))
  add(query_775287, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_775287, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_775287, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_775287, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_775287, "Port", newJInt(Port))
  add(query_775287, "Version", newJString(Version))
  add(query_775287, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_775287, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_775286.call(nil, query_775287, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_775255(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_775256, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_775257,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_775357 = ref object of OpenApiRestCall_772581
proc url_PostRestoreDBInstanceToPointInTime_775359(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceToPointInTime_775358(path: JsonNode;
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
  var valid_775360 = query.getOrDefault("Action")
  valid_775360 = validateParameter(valid_775360, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_775360 != nil:
    section.add "Action", valid_775360
  var valid_775361 = query.getOrDefault("Version")
  valid_775361 = validateParameter(valid_775361, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775361 != nil:
    section.add "Version", valid_775361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775362 = header.getOrDefault("X-Amz-Date")
  valid_775362 = validateParameter(valid_775362, JString, required = false,
                                 default = nil)
  if valid_775362 != nil:
    section.add "X-Amz-Date", valid_775362
  var valid_775363 = header.getOrDefault("X-Amz-Security-Token")
  valid_775363 = validateParameter(valid_775363, JString, required = false,
                                 default = nil)
  if valid_775363 != nil:
    section.add "X-Amz-Security-Token", valid_775363
  var valid_775364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775364 = validateParameter(valid_775364, JString, required = false,
                                 default = nil)
  if valid_775364 != nil:
    section.add "X-Amz-Content-Sha256", valid_775364
  var valid_775365 = header.getOrDefault("X-Amz-Algorithm")
  valid_775365 = validateParameter(valid_775365, JString, required = false,
                                 default = nil)
  if valid_775365 != nil:
    section.add "X-Amz-Algorithm", valid_775365
  var valid_775366 = header.getOrDefault("X-Amz-Signature")
  valid_775366 = validateParameter(valid_775366, JString, required = false,
                                 default = nil)
  if valid_775366 != nil:
    section.add "X-Amz-Signature", valid_775366
  var valid_775367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775367 = validateParameter(valid_775367, JString, required = false,
                                 default = nil)
  if valid_775367 != nil:
    section.add "X-Amz-SignedHeaders", valid_775367
  var valid_775368 = header.getOrDefault("X-Amz-Credential")
  valid_775368 = validateParameter(valid_775368, JString, required = false,
                                 default = nil)
  if valid_775368 != nil:
    section.add "X-Amz-Credential", valid_775368
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
  var valid_775369 = formData.getOrDefault("UseLatestRestorableTime")
  valid_775369 = validateParameter(valid_775369, JBool, required = false, default = nil)
  if valid_775369 != nil:
    section.add "UseLatestRestorableTime", valid_775369
  var valid_775370 = formData.getOrDefault("Port")
  valid_775370 = validateParameter(valid_775370, JInt, required = false, default = nil)
  if valid_775370 != nil:
    section.add "Port", valid_775370
  var valid_775371 = formData.getOrDefault("Engine")
  valid_775371 = validateParameter(valid_775371, JString, required = false,
                                 default = nil)
  if valid_775371 != nil:
    section.add "Engine", valid_775371
  var valid_775372 = formData.getOrDefault("Iops")
  valid_775372 = validateParameter(valid_775372, JInt, required = false, default = nil)
  if valid_775372 != nil:
    section.add "Iops", valid_775372
  var valid_775373 = formData.getOrDefault("DBName")
  valid_775373 = validateParameter(valid_775373, JString, required = false,
                                 default = nil)
  if valid_775373 != nil:
    section.add "DBName", valid_775373
  var valid_775374 = formData.getOrDefault("OptionGroupName")
  valid_775374 = validateParameter(valid_775374, JString, required = false,
                                 default = nil)
  if valid_775374 != nil:
    section.add "OptionGroupName", valid_775374
  var valid_775375 = formData.getOrDefault("Tags")
  valid_775375 = validateParameter(valid_775375, JArray, required = false,
                                 default = nil)
  if valid_775375 != nil:
    section.add "Tags", valid_775375
  var valid_775376 = formData.getOrDefault("TdeCredentialArn")
  valid_775376 = validateParameter(valid_775376, JString, required = false,
                                 default = nil)
  if valid_775376 != nil:
    section.add "TdeCredentialArn", valid_775376
  var valid_775377 = formData.getOrDefault("DBSubnetGroupName")
  valid_775377 = validateParameter(valid_775377, JString, required = false,
                                 default = nil)
  if valid_775377 != nil:
    section.add "DBSubnetGroupName", valid_775377
  var valid_775378 = formData.getOrDefault("TdeCredentialPassword")
  valid_775378 = validateParameter(valid_775378, JString, required = false,
                                 default = nil)
  if valid_775378 != nil:
    section.add "TdeCredentialPassword", valid_775378
  var valid_775379 = formData.getOrDefault("AvailabilityZone")
  valid_775379 = validateParameter(valid_775379, JString, required = false,
                                 default = nil)
  if valid_775379 != nil:
    section.add "AvailabilityZone", valid_775379
  var valid_775380 = formData.getOrDefault("MultiAZ")
  valid_775380 = validateParameter(valid_775380, JBool, required = false, default = nil)
  if valid_775380 != nil:
    section.add "MultiAZ", valid_775380
  var valid_775381 = formData.getOrDefault("RestoreTime")
  valid_775381 = validateParameter(valid_775381, JString, required = false,
                                 default = nil)
  if valid_775381 != nil:
    section.add "RestoreTime", valid_775381
  var valid_775382 = formData.getOrDefault("PubliclyAccessible")
  valid_775382 = validateParameter(valid_775382, JBool, required = false, default = nil)
  if valid_775382 != nil:
    section.add "PubliclyAccessible", valid_775382
  var valid_775383 = formData.getOrDefault("StorageType")
  valid_775383 = validateParameter(valid_775383, JString, required = false,
                                 default = nil)
  if valid_775383 != nil:
    section.add "StorageType", valid_775383
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_775384 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_775384 = validateParameter(valid_775384, JString, required = true,
                                 default = nil)
  if valid_775384 != nil:
    section.add "TargetDBInstanceIdentifier", valid_775384
  var valid_775385 = formData.getOrDefault("DBInstanceClass")
  valid_775385 = validateParameter(valid_775385, JString, required = false,
                                 default = nil)
  if valid_775385 != nil:
    section.add "DBInstanceClass", valid_775385
  var valid_775386 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_775386 = validateParameter(valid_775386, JString, required = true,
                                 default = nil)
  if valid_775386 != nil:
    section.add "SourceDBInstanceIdentifier", valid_775386
  var valid_775387 = formData.getOrDefault("LicenseModel")
  valid_775387 = validateParameter(valid_775387, JString, required = false,
                                 default = nil)
  if valid_775387 != nil:
    section.add "LicenseModel", valid_775387
  var valid_775388 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_775388 = validateParameter(valid_775388, JBool, required = false, default = nil)
  if valid_775388 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775389: Call_PostRestoreDBInstanceToPointInTime_775357;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775389.validator(path, query, header, formData, body)
  let scheme = call_775389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775389.url(scheme.get, call_775389.host, call_775389.base,
                         call_775389.route, valid.getOrDefault("path"))
  result = hook(call_775389, url, valid)

proc call*(call_775390: Call_PostRestoreDBInstanceToPointInTime_775357;
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
  var query_775391 = newJObject()
  var formData_775392 = newJObject()
  add(formData_775392, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_775392, "Port", newJInt(Port))
  add(formData_775392, "Engine", newJString(Engine))
  add(formData_775392, "Iops", newJInt(Iops))
  add(formData_775392, "DBName", newJString(DBName))
  add(formData_775392, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_775392.add "Tags", Tags
  add(formData_775392, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_775392, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_775392, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_775392, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_775392, "MultiAZ", newJBool(MultiAZ))
  add(query_775391, "Action", newJString(Action))
  add(formData_775392, "RestoreTime", newJString(RestoreTime))
  add(formData_775392, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_775392, "StorageType", newJString(StorageType))
  add(formData_775392, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_775392, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_775392, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_775392, "LicenseModel", newJString(LicenseModel))
  add(formData_775392, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_775391, "Version", newJString(Version))
  result = call_775390.call(nil, query_775391, nil, formData_775392, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_775357(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_775358, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_775359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_775322 = ref object of OpenApiRestCall_772581
proc url_GetRestoreDBInstanceToPointInTime_775324(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceToPointInTime_775323(path: JsonNode;
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
  var valid_775325 = query.getOrDefault("Engine")
  valid_775325 = validateParameter(valid_775325, JString, required = false,
                                 default = nil)
  if valid_775325 != nil:
    section.add "Engine", valid_775325
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_775326 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_775326 = validateParameter(valid_775326, JString, required = true,
                                 default = nil)
  if valid_775326 != nil:
    section.add "SourceDBInstanceIdentifier", valid_775326
  var valid_775327 = query.getOrDefault("StorageType")
  valid_775327 = validateParameter(valid_775327, JString, required = false,
                                 default = nil)
  if valid_775327 != nil:
    section.add "StorageType", valid_775327
  var valid_775328 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_775328 = validateParameter(valid_775328, JString, required = true,
                                 default = nil)
  if valid_775328 != nil:
    section.add "TargetDBInstanceIdentifier", valid_775328
  var valid_775329 = query.getOrDefault("AvailabilityZone")
  valid_775329 = validateParameter(valid_775329, JString, required = false,
                                 default = nil)
  if valid_775329 != nil:
    section.add "AvailabilityZone", valid_775329
  var valid_775330 = query.getOrDefault("Iops")
  valid_775330 = validateParameter(valid_775330, JInt, required = false, default = nil)
  if valid_775330 != nil:
    section.add "Iops", valid_775330
  var valid_775331 = query.getOrDefault("OptionGroupName")
  valid_775331 = validateParameter(valid_775331, JString, required = false,
                                 default = nil)
  if valid_775331 != nil:
    section.add "OptionGroupName", valid_775331
  var valid_775332 = query.getOrDefault("RestoreTime")
  valid_775332 = validateParameter(valid_775332, JString, required = false,
                                 default = nil)
  if valid_775332 != nil:
    section.add "RestoreTime", valid_775332
  var valid_775333 = query.getOrDefault("MultiAZ")
  valid_775333 = validateParameter(valid_775333, JBool, required = false, default = nil)
  if valid_775333 != nil:
    section.add "MultiAZ", valid_775333
  var valid_775334 = query.getOrDefault("TdeCredentialPassword")
  valid_775334 = validateParameter(valid_775334, JString, required = false,
                                 default = nil)
  if valid_775334 != nil:
    section.add "TdeCredentialPassword", valid_775334
  var valid_775335 = query.getOrDefault("LicenseModel")
  valid_775335 = validateParameter(valid_775335, JString, required = false,
                                 default = nil)
  if valid_775335 != nil:
    section.add "LicenseModel", valid_775335
  var valid_775336 = query.getOrDefault("Tags")
  valid_775336 = validateParameter(valid_775336, JArray, required = false,
                                 default = nil)
  if valid_775336 != nil:
    section.add "Tags", valid_775336
  var valid_775337 = query.getOrDefault("DBName")
  valid_775337 = validateParameter(valid_775337, JString, required = false,
                                 default = nil)
  if valid_775337 != nil:
    section.add "DBName", valid_775337
  var valid_775338 = query.getOrDefault("DBInstanceClass")
  valid_775338 = validateParameter(valid_775338, JString, required = false,
                                 default = nil)
  if valid_775338 != nil:
    section.add "DBInstanceClass", valid_775338
  var valid_775339 = query.getOrDefault("Action")
  valid_775339 = validateParameter(valid_775339, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_775339 != nil:
    section.add "Action", valid_775339
  var valid_775340 = query.getOrDefault("UseLatestRestorableTime")
  valid_775340 = validateParameter(valid_775340, JBool, required = false, default = nil)
  if valid_775340 != nil:
    section.add "UseLatestRestorableTime", valid_775340
  var valid_775341 = query.getOrDefault("DBSubnetGroupName")
  valid_775341 = validateParameter(valid_775341, JString, required = false,
                                 default = nil)
  if valid_775341 != nil:
    section.add "DBSubnetGroupName", valid_775341
  var valid_775342 = query.getOrDefault("TdeCredentialArn")
  valid_775342 = validateParameter(valid_775342, JString, required = false,
                                 default = nil)
  if valid_775342 != nil:
    section.add "TdeCredentialArn", valid_775342
  var valid_775343 = query.getOrDefault("PubliclyAccessible")
  valid_775343 = validateParameter(valid_775343, JBool, required = false, default = nil)
  if valid_775343 != nil:
    section.add "PubliclyAccessible", valid_775343
  var valid_775344 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_775344 = validateParameter(valid_775344, JBool, required = false, default = nil)
  if valid_775344 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775344
  var valid_775345 = query.getOrDefault("Port")
  valid_775345 = validateParameter(valid_775345, JInt, required = false, default = nil)
  if valid_775345 != nil:
    section.add "Port", valid_775345
  var valid_775346 = query.getOrDefault("Version")
  valid_775346 = validateParameter(valid_775346, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775346 != nil:
    section.add "Version", valid_775346
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775347 = header.getOrDefault("X-Amz-Date")
  valid_775347 = validateParameter(valid_775347, JString, required = false,
                                 default = nil)
  if valid_775347 != nil:
    section.add "X-Amz-Date", valid_775347
  var valid_775348 = header.getOrDefault("X-Amz-Security-Token")
  valid_775348 = validateParameter(valid_775348, JString, required = false,
                                 default = nil)
  if valid_775348 != nil:
    section.add "X-Amz-Security-Token", valid_775348
  var valid_775349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775349 = validateParameter(valid_775349, JString, required = false,
                                 default = nil)
  if valid_775349 != nil:
    section.add "X-Amz-Content-Sha256", valid_775349
  var valid_775350 = header.getOrDefault("X-Amz-Algorithm")
  valid_775350 = validateParameter(valid_775350, JString, required = false,
                                 default = nil)
  if valid_775350 != nil:
    section.add "X-Amz-Algorithm", valid_775350
  var valid_775351 = header.getOrDefault("X-Amz-Signature")
  valid_775351 = validateParameter(valid_775351, JString, required = false,
                                 default = nil)
  if valid_775351 != nil:
    section.add "X-Amz-Signature", valid_775351
  var valid_775352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775352 = validateParameter(valid_775352, JString, required = false,
                                 default = nil)
  if valid_775352 != nil:
    section.add "X-Amz-SignedHeaders", valid_775352
  var valid_775353 = header.getOrDefault("X-Amz-Credential")
  valid_775353 = validateParameter(valid_775353, JString, required = false,
                                 default = nil)
  if valid_775353 != nil:
    section.add "X-Amz-Credential", valid_775353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775354: Call_GetRestoreDBInstanceToPointInTime_775322;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775354.validator(path, query, header, formData, body)
  let scheme = call_775354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775354.url(scheme.get, call_775354.host, call_775354.base,
                         call_775354.route, valid.getOrDefault("path"))
  result = hook(call_775354, url, valid)

proc call*(call_775355: Call_GetRestoreDBInstanceToPointInTime_775322;
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
  var query_775356 = newJObject()
  add(query_775356, "Engine", newJString(Engine))
  add(query_775356, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_775356, "StorageType", newJString(StorageType))
  add(query_775356, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_775356, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_775356, "Iops", newJInt(Iops))
  add(query_775356, "OptionGroupName", newJString(OptionGroupName))
  add(query_775356, "RestoreTime", newJString(RestoreTime))
  add(query_775356, "MultiAZ", newJBool(MultiAZ))
  add(query_775356, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_775356, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_775356.add "Tags", Tags
  add(query_775356, "DBName", newJString(DBName))
  add(query_775356, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_775356, "Action", newJString(Action))
  add(query_775356, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_775356, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_775356, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_775356, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_775356, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_775356, "Port", newJInt(Port))
  add(query_775356, "Version", newJString(Version))
  result = call_775355.call(nil, query_775356, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_775322(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_775323, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_775324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_775413 = ref object of OpenApiRestCall_772581
proc url_PostRevokeDBSecurityGroupIngress_775415(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRevokeDBSecurityGroupIngress_775414(path: JsonNode;
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
  var valid_775416 = query.getOrDefault("Action")
  valid_775416 = validateParameter(valid_775416, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_775416 != nil:
    section.add "Action", valid_775416
  var valid_775417 = query.getOrDefault("Version")
  valid_775417 = validateParameter(valid_775417, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775417 != nil:
    section.add "Version", valid_775417
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775418 = header.getOrDefault("X-Amz-Date")
  valid_775418 = validateParameter(valid_775418, JString, required = false,
                                 default = nil)
  if valid_775418 != nil:
    section.add "X-Amz-Date", valid_775418
  var valid_775419 = header.getOrDefault("X-Amz-Security-Token")
  valid_775419 = validateParameter(valid_775419, JString, required = false,
                                 default = nil)
  if valid_775419 != nil:
    section.add "X-Amz-Security-Token", valid_775419
  var valid_775420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775420 = validateParameter(valid_775420, JString, required = false,
                                 default = nil)
  if valid_775420 != nil:
    section.add "X-Amz-Content-Sha256", valid_775420
  var valid_775421 = header.getOrDefault("X-Amz-Algorithm")
  valid_775421 = validateParameter(valid_775421, JString, required = false,
                                 default = nil)
  if valid_775421 != nil:
    section.add "X-Amz-Algorithm", valid_775421
  var valid_775422 = header.getOrDefault("X-Amz-Signature")
  valid_775422 = validateParameter(valid_775422, JString, required = false,
                                 default = nil)
  if valid_775422 != nil:
    section.add "X-Amz-Signature", valid_775422
  var valid_775423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775423 = validateParameter(valid_775423, JString, required = false,
                                 default = nil)
  if valid_775423 != nil:
    section.add "X-Amz-SignedHeaders", valid_775423
  var valid_775424 = header.getOrDefault("X-Amz-Credential")
  valid_775424 = validateParameter(valid_775424, JString, required = false,
                                 default = nil)
  if valid_775424 != nil:
    section.add "X-Amz-Credential", valid_775424
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_775425 = formData.getOrDefault("DBSecurityGroupName")
  valid_775425 = validateParameter(valid_775425, JString, required = true,
                                 default = nil)
  if valid_775425 != nil:
    section.add "DBSecurityGroupName", valid_775425
  var valid_775426 = formData.getOrDefault("EC2SecurityGroupName")
  valid_775426 = validateParameter(valid_775426, JString, required = false,
                                 default = nil)
  if valid_775426 != nil:
    section.add "EC2SecurityGroupName", valid_775426
  var valid_775427 = formData.getOrDefault("EC2SecurityGroupId")
  valid_775427 = validateParameter(valid_775427, JString, required = false,
                                 default = nil)
  if valid_775427 != nil:
    section.add "EC2SecurityGroupId", valid_775427
  var valid_775428 = formData.getOrDefault("CIDRIP")
  valid_775428 = validateParameter(valid_775428, JString, required = false,
                                 default = nil)
  if valid_775428 != nil:
    section.add "CIDRIP", valid_775428
  var valid_775429 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_775429 = validateParameter(valid_775429, JString, required = false,
                                 default = nil)
  if valid_775429 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_775429
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775430: Call_PostRevokeDBSecurityGroupIngress_775413;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775430.validator(path, query, header, formData, body)
  let scheme = call_775430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775430.url(scheme.get, call_775430.host, call_775430.base,
                         call_775430.route, valid.getOrDefault("path"))
  result = hook(call_775430, url, valid)

proc call*(call_775431: Call_PostRevokeDBSecurityGroupIngress_775413;
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
  var query_775432 = newJObject()
  var formData_775433 = newJObject()
  add(formData_775433, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_775432, "Action", newJString(Action))
  add(formData_775433, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_775433, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_775433, "CIDRIP", newJString(CIDRIP))
  add(query_775432, "Version", newJString(Version))
  add(formData_775433, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_775431.call(nil, query_775432, nil, formData_775433, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_775413(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_775414, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_775415,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_775393 = ref object of OpenApiRestCall_772581
proc url_GetRevokeDBSecurityGroupIngress_775395(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRevokeDBSecurityGroupIngress_775394(path: JsonNode;
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
  var valid_775396 = query.getOrDefault("EC2SecurityGroupId")
  valid_775396 = validateParameter(valid_775396, JString, required = false,
                                 default = nil)
  if valid_775396 != nil:
    section.add "EC2SecurityGroupId", valid_775396
  var valid_775397 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_775397 = validateParameter(valid_775397, JString, required = false,
                                 default = nil)
  if valid_775397 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_775397
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_775398 = query.getOrDefault("DBSecurityGroupName")
  valid_775398 = validateParameter(valid_775398, JString, required = true,
                                 default = nil)
  if valid_775398 != nil:
    section.add "DBSecurityGroupName", valid_775398
  var valid_775399 = query.getOrDefault("Action")
  valid_775399 = validateParameter(valid_775399, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_775399 != nil:
    section.add "Action", valid_775399
  var valid_775400 = query.getOrDefault("CIDRIP")
  valid_775400 = validateParameter(valid_775400, JString, required = false,
                                 default = nil)
  if valid_775400 != nil:
    section.add "CIDRIP", valid_775400
  var valid_775401 = query.getOrDefault("EC2SecurityGroupName")
  valid_775401 = validateParameter(valid_775401, JString, required = false,
                                 default = nil)
  if valid_775401 != nil:
    section.add "EC2SecurityGroupName", valid_775401
  var valid_775402 = query.getOrDefault("Version")
  valid_775402 = validateParameter(valid_775402, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_775402 != nil:
    section.add "Version", valid_775402
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775403 = header.getOrDefault("X-Amz-Date")
  valid_775403 = validateParameter(valid_775403, JString, required = false,
                                 default = nil)
  if valid_775403 != nil:
    section.add "X-Amz-Date", valid_775403
  var valid_775404 = header.getOrDefault("X-Amz-Security-Token")
  valid_775404 = validateParameter(valid_775404, JString, required = false,
                                 default = nil)
  if valid_775404 != nil:
    section.add "X-Amz-Security-Token", valid_775404
  var valid_775405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775405 = validateParameter(valid_775405, JString, required = false,
                                 default = nil)
  if valid_775405 != nil:
    section.add "X-Amz-Content-Sha256", valid_775405
  var valid_775406 = header.getOrDefault("X-Amz-Algorithm")
  valid_775406 = validateParameter(valid_775406, JString, required = false,
                                 default = nil)
  if valid_775406 != nil:
    section.add "X-Amz-Algorithm", valid_775406
  var valid_775407 = header.getOrDefault("X-Amz-Signature")
  valid_775407 = validateParameter(valid_775407, JString, required = false,
                                 default = nil)
  if valid_775407 != nil:
    section.add "X-Amz-Signature", valid_775407
  var valid_775408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775408 = validateParameter(valid_775408, JString, required = false,
                                 default = nil)
  if valid_775408 != nil:
    section.add "X-Amz-SignedHeaders", valid_775408
  var valid_775409 = header.getOrDefault("X-Amz-Credential")
  valid_775409 = validateParameter(valid_775409, JString, required = false,
                                 default = nil)
  if valid_775409 != nil:
    section.add "X-Amz-Credential", valid_775409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775410: Call_GetRevokeDBSecurityGroupIngress_775393;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775410.validator(path, query, header, formData, body)
  let scheme = call_775410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775410.url(scheme.get, call_775410.host, call_775410.base,
                         call_775410.route, valid.getOrDefault("path"))
  result = hook(call_775410, url, valid)

proc call*(call_775411: Call_GetRevokeDBSecurityGroupIngress_775393;
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
  var query_775412 = newJObject()
  add(query_775412, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_775412, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_775412, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_775412, "Action", newJString(Action))
  add(query_775412, "CIDRIP", newJString(CIDRIP))
  add(query_775412, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_775412, "Version", newJString(Version))
  result = call_775411.call(nil, query_775412, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_775393(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_775394, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_775395,
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
