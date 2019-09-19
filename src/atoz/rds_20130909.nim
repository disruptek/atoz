
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
                                 default = newJString("2013-09-09"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2013-09-09"): Recallable =
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
  Call_PostCopyDBSnapshot_773301 = ref object of OpenApiRestCall_772581
proc url_PostCopyDBSnapshot_773303(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBSnapshot_773302(path: JsonNode; query: JsonNode;
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
  var valid_773304 = query.getOrDefault("Action")
  valid_773304 = validateParameter(valid_773304, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_773304 != nil:
    section.add "Action", valid_773304
  var valid_773305 = query.getOrDefault("Version")
  valid_773305 = validateParameter(valid_773305, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773305 != nil:
    section.add "Version", valid_773305
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773306 = header.getOrDefault("X-Amz-Date")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Date", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-Security-Token")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Security-Token", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-Content-Sha256", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-Algorithm")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Algorithm", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-Signature")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Signature", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-SignedHeaders", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-Credential")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-Credential", valid_773312
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_773313 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_773313 = validateParameter(valid_773313, JString, required = true,
                                 default = nil)
  if valid_773313 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_773313
  var valid_773314 = formData.getOrDefault("Tags")
  valid_773314 = validateParameter(valid_773314, JArray, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "Tags", valid_773314
  var valid_773315 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_773315 = validateParameter(valid_773315, JString, required = true,
                                 default = nil)
  if valid_773315 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_773315
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773316: Call_PostCopyDBSnapshot_773301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773316.validator(path, query, header, formData, body)
  let scheme = call_773316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773316.url(scheme.get, call_773316.host, call_773316.base,
                         call_773316.route, valid.getOrDefault("path"))
  result = hook(call_773316, url, valid)

proc call*(call_773317: Call_PostCopyDBSnapshot_773301;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_773318 = newJObject()
  var formData_773319 = newJObject()
  add(formData_773319, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_773319.add "Tags", Tags
  add(query_773318, "Action", newJString(Action))
  add(formData_773319, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_773318, "Version", newJString(Version))
  result = call_773317.call(nil, query_773318, nil, formData_773319, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_773301(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_773302, base: "/",
    url: url_PostCopyDBSnapshot_773303, schemes: {Scheme.Https, Scheme.Http})
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
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_773286 = query.getOrDefault("Tags")
  valid_773286 = validateParameter(valid_773286, JArray, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "Tags", valid_773286
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_773287 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_773287 = validateParameter(valid_773287, JString, required = true,
                                 default = nil)
  if valid_773287 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_773287
  var valid_773288 = query.getOrDefault("Action")
  valid_773288 = validateParameter(valid_773288, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_773288 != nil:
    section.add "Action", valid_773288
  var valid_773289 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_773289 = validateParameter(valid_773289, JString, required = true,
                                 default = nil)
  if valid_773289 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_773289
  var valid_773290 = query.getOrDefault("Version")
  valid_773290 = validateParameter(valid_773290, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773290 != nil:
    section.add "Version", valid_773290
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773291 = header.getOrDefault("X-Amz-Date")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-Date", valid_773291
  var valid_773292 = header.getOrDefault("X-Amz-Security-Token")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Security-Token", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Content-Sha256", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-Algorithm")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-Algorithm", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Signature")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Signature", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-SignedHeaders", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-Credential")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-Credential", valid_773297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773298: Call_GetCopyDBSnapshot_773283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773298.validator(path, query, header, formData, body)
  let scheme = call_773298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773298.url(scheme.get, call_773298.host, call_773298.base,
                         call_773298.route, valid.getOrDefault("path"))
  result = hook(call_773298, url, valid)

proc call*(call_773299: Call_GetCopyDBSnapshot_773283;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_773300 = newJObject()
  if Tags != nil:
    query_773300.add "Tags", Tags
  add(query_773300, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_773300, "Action", newJString(Action))
  add(query_773300, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_773300, "Version", newJString(Version))
  result = call_773299.call(nil, query_773300, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_773283(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_773284,
    base: "/", url: url_GetCopyDBSnapshot_773285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_773360 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBInstance_773362(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstance_773361(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773363 = query.getOrDefault("Action")
  valid_773363 = validateParameter(valid_773363, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_773363 != nil:
    section.add "Action", valid_773363
  var valid_773364 = query.getOrDefault("Version")
  valid_773364 = validateParameter(valid_773364, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773364 != nil:
    section.add "Version", valid_773364
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773365 = header.getOrDefault("X-Amz-Date")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-Date", valid_773365
  var valid_773366 = header.getOrDefault("X-Amz-Security-Token")
  valid_773366 = validateParameter(valid_773366, JString, required = false,
                                 default = nil)
  if valid_773366 != nil:
    section.add "X-Amz-Security-Token", valid_773366
  var valid_773367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "X-Amz-Content-Sha256", valid_773367
  var valid_773368 = header.getOrDefault("X-Amz-Algorithm")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Algorithm", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-Signature")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Signature", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-SignedHeaders", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Credential")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Credential", valid_773371
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
  var valid_773372 = formData.getOrDefault("DBSecurityGroups")
  valid_773372 = validateParameter(valid_773372, JArray, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "DBSecurityGroups", valid_773372
  var valid_773373 = formData.getOrDefault("Port")
  valid_773373 = validateParameter(valid_773373, JInt, required = false, default = nil)
  if valid_773373 != nil:
    section.add "Port", valid_773373
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_773374 = formData.getOrDefault("Engine")
  valid_773374 = validateParameter(valid_773374, JString, required = true,
                                 default = nil)
  if valid_773374 != nil:
    section.add "Engine", valid_773374
  var valid_773375 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_773375 = validateParameter(valid_773375, JArray, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "VpcSecurityGroupIds", valid_773375
  var valid_773376 = formData.getOrDefault("Iops")
  valid_773376 = validateParameter(valid_773376, JInt, required = false, default = nil)
  if valid_773376 != nil:
    section.add "Iops", valid_773376
  var valid_773377 = formData.getOrDefault("DBName")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "DBName", valid_773377
  var valid_773378 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773378 = validateParameter(valid_773378, JString, required = true,
                                 default = nil)
  if valid_773378 != nil:
    section.add "DBInstanceIdentifier", valid_773378
  var valid_773379 = formData.getOrDefault("BackupRetentionPeriod")
  valid_773379 = validateParameter(valid_773379, JInt, required = false, default = nil)
  if valid_773379 != nil:
    section.add "BackupRetentionPeriod", valid_773379
  var valid_773380 = formData.getOrDefault("DBParameterGroupName")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "DBParameterGroupName", valid_773380
  var valid_773381 = formData.getOrDefault("OptionGroupName")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "OptionGroupName", valid_773381
  var valid_773382 = formData.getOrDefault("Tags")
  valid_773382 = validateParameter(valid_773382, JArray, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "Tags", valid_773382
  var valid_773383 = formData.getOrDefault("MasterUserPassword")
  valid_773383 = validateParameter(valid_773383, JString, required = true,
                                 default = nil)
  if valid_773383 != nil:
    section.add "MasterUserPassword", valid_773383
  var valid_773384 = formData.getOrDefault("DBSubnetGroupName")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "DBSubnetGroupName", valid_773384
  var valid_773385 = formData.getOrDefault("AvailabilityZone")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "AvailabilityZone", valid_773385
  var valid_773386 = formData.getOrDefault("MultiAZ")
  valid_773386 = validateParameter(valid_773386, JBool, required = false, default = nil)
  if valid_773386 != nil:
    section.add "MultiAZ", valid_773386
  var valid_773387 = formData.getOrDefault("AllocatedStorage")
  valid_773387 = validateParameter(valid_773387, JInt, required = true, default = nil)
  if valid_773387 != nil:
    section.add "AllocatedStorage", valid_773387
  var valid_773388 = formData.getOrDefault("PubliclyAccessible")
  valid_773388 = validateParameter(valid_773388, JBool, required = false, default = nil)
  if valid_773388 != nil:
    section.add "PubliclyAccessible", valid_773388
  var valid_773389 = formData.getOrDefault("MasterUsername")
  valid_773389 = validateParameter(valid_773389, JString, required = true,
                                 default = nil)
  if valid_773389 != nil:
    section.add "MasterUsername", valid_773389
  var valid_773390 = formData.getOrDefault("DBInstanceClass")
  valid_773390 = validateParameter(valid_773390, JString, required = true,
                                 default = nil)
  if valid_773390 != nil:
    section.add "DBInstanceClass", valid_773390
  var valid_773391 = formData.getOrDefault("CharacterSetName")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "CharacterSetName", valid_773391
  var valid_773392 = formData.getOrDefault("PreferredBackupWindow")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "PreferredBackupWindow", valid_773392
  var valid_773393 = formData.getOrDefault("LicenseModel")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "LicenseModel", valid_773393
  var valid_773394 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_773394 = validateParameter(valid_773394, JBool, required = false, default = nil)
  if valid_773394 != nil:
    section.add "AutoMinorVersionUpgrade", valid_773394
  var valid_773395 = formData.getOrDefault("EngineVersion")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "EngineVersion", valid_773395
  var valid_773396 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "PreferredMaintenanceWindow", valid_773396
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773397: Call_PostCreateDBInstance_773360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773397.validator(path, query, header, formData, body)
  let scheme = call_773397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773397.url(scheme.get, call_773397.host, call_773397.base,
                         call_773397.route, valid.getOrDefault("path"))
  result = hook(call_773397, url, valid)

proc call*(call_773398: Call_PostCreateDBInstance_773360; Engine: string;
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
  var query_773399 = newJObject()
  var formData_773400 = newJObject()
  if DBSecurityGroups != nil:
    formData_773400.add "DBSecurityGroups", DBSecurityGroups
  add(formData_773400, "Port", newJInt(Port))
  add(formData_773400, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_773400.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_773400, "Iops", newJInt(Iops))
  add(formData_773400, "DBName", newJString(DBName))
  add(formData_773400, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_773400, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_773400, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_773400, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_773400.add "Tags", Tags
  add(formData_773400, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_773400, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_773400, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_773400, "MultiAZ", newJBool(MultiAZ))
  add(query_773399, "Action", newJString(Action))
  add(formData_773400, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_773400, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_773400, "MasterUsername", newJString(MasterUsername))
  add(formData_773400, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_773400, "CharacterSetName", newJString(CharacterSetName))
  add(formData_773400, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_773400, "LicenseModel", newJString(LicenseModel))
  add(formData_773400, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_773400, "EngineVersion", newJString(EngineVersion))
  add(query_773399, "Version", newJString(Version))
  add(formData_773400, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_773398.call(nil, query_773399, nil, formData_773400, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_773360(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_773361, base: "/",
    url: url_PostCreateDBInstance_773362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_773320 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBInstance_773322(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstance_773321(path: JsonNode; query: JsonNode;
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
  var valid_773323 = query.getOrDefault("Engine")
  valid_773323 = validateParameter(valid_773323, JString, required = true,
                                 default = nil)
  if valid_773323 != nil:
    section.add "Engine", valid_773323
  var valid_773324 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "PreferredMaintenanceWindow", valid_773324
  var valid_773325 = query.getOrDefault("AllocatedStorage")
  valid_773325 = validateParameter(valid_773325, JInt, required = true, default = nil)
  if valid_773325 != nil:
    section.add "AllocatedStorage", valid_773325
  var valid_773326 = query.getOrDefault("OptionGroupName")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "OptionGroupName", valid_773326
  var valid_773327 = query.getOrDefault("DBSecurityGroups")
  valid_773327 = validateParameter(valid_773327, JArray, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "DBSecurityGroups", valid_773327
  var valid_773328 = query.getOrDefault("MasterUserPassword")
  valid_773328 = validateParameter(valid_773328, JString, required = true,
                                 default = nil)
  if valid_773328 != nil:
    section.add "MasterUserPassword", valid_773328
  var valid_773329 = query.getOrDefault("AvailabilityZone")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "AvailabilityZone", valid_773329
  var valid_773330 = query.getOrDefault("Iops")
  valid_773330 = validateParameter(valid_773330, JInt, required = false, default = nil)
  if valid_773330 != nil:
    section.add "Iops", valid_773330
  var valid_773331 = query.getOrDefault("VpcSecurityGroupIds")
  valid_773331 = validateParameter(valid_773331, JArray, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "VpcSecurityGroupIds", valid_773331
  var valid_773332 = query.getOrDefault("MultiAZ")
  valid_773332 = validateParameter(valid_773332, JBool, required = false, default = nil)
  if valid_773332 != nil:
    section.add "MultiAZ", valid_773332
  var valid_773333 = query.getOrDefault("LicenseModel")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "LicenseModel", valid_773333
  var valid_773334 = query.getOrDefault("BackupRetentionPeriod")
  valid_773334 = validateParameter(valid_773334, JInt, required = false, default = nil)
  if valid_773334 != nil:
    section.add "BackupRetentionPeriod", valid_773334
  var valid_773335 = query.getOrDefault("DBName")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "DBName", valid_773335
  var valid_773336 = query.getOrDefault("DBParameterGroupName")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "DBParameterGroupName", valid_773336
  var valid_773337 = query.getOrDefault("Tags")
  valid_773337 = validateParameter(valid_773337, JArray, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "Tags", valid_773337
  var valid_773338 = query.getOrDefault("DBInstanceClass")
  valid_773338 = validateParameter(valid_773338, JString, required = true,
                                 default = nil)
  if valid_773338 != nil:
    section.add "DBInstanceClass", valid_773338
  var valid_773339 = query.getOrDefault("Action")
  valid_773339 = validateParameter(valid_773339, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_773339 != nil:
    section.add "Action", valid_773339
  var valid_773340 = query.getOrDefault("DBSubnetGroupName")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "DBSubnetGroupName", valid_773340
  var valid_773341 = query.getOrDefault("CharacterSetName")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "CharacterSetName", valid_773341
  var valid_773342 = query.getOrDefault("PubliclyAccessible")
  valid_773342 = validateParameter(valid_773342, JBool, required = false, default = nil)
  if valid_773342 != nil:
    section.add "PubliclyAccessible", valid_773342
  var valid_773343 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_773343 = validateParameter(valid_773343, JBool, required = false, default = nil)
  if valid_773343 != nil:
    section.add "AutoMinorVersionUpgrade", valid_773343
  var valid_773344 = query.getOrDefault("EngineVersion")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "EngineVersion", valid_773344
  var valid_773345 = query.getOrDefault("Port")
  valid_773345 = validateParameter(valid_773345, JInt, required = false, default = nil)
  if valid_773345 != nil:
    section.add "Port", valid_773345
  var valid_773346 = query.getOrDefault("PreferredBackupWindow")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "PreferredBackupWindow", valid_773346
  var valid_773347 = query.getOrDefault("Version")
  valid_773347 = validateParameter(valid_773347, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773347 != nil:
    section.add "Version", valid_773347
  var valid_773348 = query.getOrDefault("DBInstanceIdentifier")
  valid_773348 = validateParameter(valid_773348, JString, required = true,
                                 default = nil)
  if valid_773348 != nil:
    section.add "DBInstanceIdentifier", valid_773348
  var valid_773349 = query.getOrDefault("MasterUsername")
  valid_773349 = validateParameter(valid_773349, JString, required = true,
                                 default = nil)
  if valid_773349 != nil:
    section.add "MasterUsername", valid_773349
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773350 = header.getOrDefault("X-Amz-Date")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Date", valid_773350
  var valid_773351 = header.getOrDefault("X-Amz-Security-Token")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-Security-Token", valid_773351
  var valid_773352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-Content-Sha256", valid_773352
  var valid_773353 = header.getOrDefault("X-Amz-Algorithm")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-Algorithm", valid_773353
  var valid_773354 = header.getOrDefault("X-Amz-Signature")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-Signature", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-SignedHeaders", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Credential")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Credential", valid_773356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773357: Call_GetCreateDBInstance_773320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773357.validator(path, query, header, formData, body)
  let scheme = call_773357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773357.url(scheme.get, call_773357.host, call_773357.base,
                         call_773357.route, valid.getOrDefault("path"))
  result = hook(call_773357, url, valid)

proc call*(call_773358: Call_GetCreateDBInstance_773320; Engine: string;
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
  var query_773359 = newJObject()
  add(query_773359, "Engine", newJString(Engine))
  add(query_773359, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_773359, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_773359, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_773359.add "DBSecurityGroups", DBSecurityGroups
  add(query_773359, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_773359, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_773359, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_773359.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_773359, "MultiAZ", newJBool(MultiAZ))
  add(query_773359, "LicenseModel", newJString(LicenseModel))
  add(query_773359, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_773359, "DBName", newJString(DBName))
  add(query_773359, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_773359.add "Tags", Tags
  add(query_773359, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_773359, "Action", newJString(Action))
  add(query_773359, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773359, "CharacterSetName", newJString(CharacterSetName))
  add(query_773359, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_773359, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_773359, "EngineVersion", newJString(EngineVersion))
  add(query_773359, "Port", newJInt(Port))
  add(query_773359, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_773359, "Version", newJString(Version))
  add(query_773359, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_773359, "MasterUsername", newJString(MasterUsername))
  result = call_773358.call(nil, query_773359, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_773320(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_773321, base: "/",
    url: url_GetCreateDBInstance_773322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_773427 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBInstanceReadReplica_773429(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstanceReadReplica_773428(path: JsonNode;
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
  var valid_773430 = query.getOrDefault("Action")
  valid_773430 = validateParameter(valid_773430, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_773430 != nil:
    section.add "Action", valid_773430
  var valid_773431 = query.getOrDefault("Version")
  valid_773431 = validateParameter(valid_773431, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773431 != nil:
    section.add "Version", valid_773431
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773432 = header.getOrDefault("X-Amz-Date")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-Date", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-Security-Token")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Security-Token", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Content-Sha256", valid_773434
  var valid_773435 = header.getOrDefault("X-Amz-Algorithm")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-Algorithm", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-Signature")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-Signature", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-SignedHeaders", valid_773437
  var valid_773438 = header.getOrDefault("X-Amz-Credential")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Credential", valid_773438
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
  var valid_773439 = formData.getOrDefault("Port")
  valid_773439 = validateParameter(valid_773439, JInt, required = false, default = nil)
  if valid_773439 != nil:
    section.add "Port", valid_773439
  var valid_773440 = formData.getOrDefault("Iops")
  valid_773440 = validateParameter(valid_773440, JInt, required = false, default = nil)
  if valid_773440 != nil:
    section.add "Iops", valid_773440
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_773441 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773441 = validateParameter(valid_773441, JString, required = true,
                                 default = nil)
  if valid_773441 != nil:
    section.add "DBInstanceIdentifier", valid_773441
  var valid_773442 = formData.getOrDefault("OptionGroupName")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "OptionGroupName", valid_773442
  var valid_773443 = formData.getOrDefault("Tags")
  valid_773443 = validateParameter(valid_773443, JArray, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "Tags", valid_773443
  var valid_773444 = formData.getOrDefault("DBSubnetGroupName")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "DBSubnetGroupName", valid_773444
  var valid_773445 = formData.getOrDefault("AvailabilityZone")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "AvailabilityZone", valid_773445
  var valid_773446 = formData.getOrDefault("PubliclyAccessible")
  valid_773446 = validateParameter(valid_773446, JBool, required = false, default = nil)
  if valid_773446 != nil:
    section.add "PubliclyAccessible", valid_773446
  var valid_773447 = formData.getOrDefault("DBInstanceClass")
  valid_773447 = validateParameter(valid_773447, JString, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "DBInstanceClass", valid_773447
  var valid_773448 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_773448 = validateParameter(valid_773448, JString, required = true,
                                 default = nil)
  if valid_773448 != nil:
    section.add "SourceDBInstanceIdentifier", valid_773448
  var valid_773449 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_773449 = validateParameter(valid_773449, JBool, required = false, default = nil)
  if valid_773449 != nil:
    section.add "AutoMinorVersionUpgrade", valid_773449
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773450: Call_PostCreateDBInstanceReadReplica_773427;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_773450.validator(path, query, header, formData, body)
  let scheme = call_773450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773450.url(scheme.get, call_773450.host, call_773450.base,
                         call_773450.route, valid.getOrDefault("path"))
  result = hook(call_773450, url, valid)

proc call*(call_773451: Call_PostCreateDBInstanceReadReplica_773427;
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
  var query_773452 = newJObject()
  var formData_773453 = newJObject()
  add(formData_773453, "Port", newJInt(Port))
  add(formData_773453, "Iops", newJInt(Iops))
  add(formData_773453, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_773453, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_773453.add "Tags", Tags
  add(formData_773453, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_773453, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_773452, "Action", newJString(Action))
  add(formData_773453, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_773453, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_773453, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_773453, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_773452, "Version", newJString(Version))
  result = call_773451.call(nil, query_773452, nil, formData_773453, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_773427(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_773428, base: "/",
    url: url_PostCreateDBInstanceReadReplica_773429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_773401 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBInstanceReadReplica_773403(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstanceReadReplica_773402(path: JsonNode;
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
  var valid_773404 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_773404 = validateParameter(valid_773404, JString, required = true,
                                 default = nil)
  if valid_773404 != nil:
    section.add "SourceDBInstanceIdentifier", valid_773404
  var valid_773405 = query.getOrDefault("OptionGroupName")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "OptionGroupName", valid_773405
  var valid_773406 = query.getOrDefault("AvailabilityZone")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "AvailabilityZone", valid_773406
  var valid_773407 = query.getOrDefault("Iops")
  valid_773407 = validateParameter(valid_773407, JInt, required = false, default = nil)
  if valid_773407 != nil:
    section.add "Iops", valid_773407
  var valid_773408 = query.getOrDefault("Tags")
  valid_773408 = validateParameter(valid_773408, JArray, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "Tags", valid_773408
  var valid_773409 = query.getOrDefault("DBInstanceClass")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "DBInstanceClass", valid_773409
  var valid_773410 = query.getOrDefault("Action")
  valid_773410 = validateParameter(valid_773410, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_773410 != nil:
    section.add "Action", valid_773410
  var valid_773411 = query.getOrDefault("DBSubnetGroupName")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "DBSubnetGroupName", valid_773411
  var valid_773412 = query.getOrDefault("PubliclyAccessible")
  valid_773412 = validateParameter(valid_773412, JBool, required = false, default = nil)
  if valid_773412 != nil:
    section.add "PubliclyAccessible", valid_773412
  var valid_773413 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_773413 = validateParameter(valid_773413, JBool, required = false, default = nil)
  if valid_773413 != nil:
    section.add "AutoMinorVersionUpgrade", valid_773413
  var valid_773414 = query.getOrDefault("Port")
  valid_773414 = validateParameter(valid_773414, JInt, required = false, default = nil)
  if valid_773414 != nil:
    section.add "Port", valid_773414
  var valid_773415 = query.getOrDefault("Version")
  valid_773415 = validateParameter(valid_773415, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773415 != nil:
    section.add "Version", valid_773415
  var valid_773416 = query.getOrDefault("DBInstanceIdentifier")
  valid_773416 = validateParameter(valid_773416, JString, required = true,
                                 default = nil)
  if valid_773416 != nil:
    section.add "DBInstanceIdentifier", valid_773416
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773417 = header.getOrDefault("X-Amz-Date")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Date", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Security-Token")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Security-Token", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Content-Sha256", valid_773419
  var valid_773420 = header.getOrDefault("X-Amz-Algorithm")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Algorithm", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-Signature")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-Signature", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-SignedHeaders", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-Credential")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Credential", valid_773423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773424: Call_GetCreateDBInstanceReadReplica_773401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773424.validator(path, query, header, formData, body)
  let scheme = call_773424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773424.url(scheme.get, call_773424.host, call_773424.base,
                         call_773424.route, valid.getOrDefault("path"))
  result = hook(call_773424, url, valid)

proc call*(call_773425: Call_GetCreateDBInstanceReadReplica_773401;
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
  var query_773426 = newJObject()
  add(query_773426, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_773426, "OptionGroupName", newJString(OptionGroupName))
  add(query_773426, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_773426, "Iops", newJInt(Iops))
  if Tags != nil:
    query_773426.add "Tags", Tags
  add(query_773426, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_773426, "Action", newJString(Action))
  add(query_773426, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773426, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_773426, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_773426, "Port", newJInt(Port))
  add(query_773426, "Version", newJString(Version))
  add(query_773426, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_773425.call(nil, query_773426, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_773401(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_773402, base: "/",
    url: url_GetCreateDBInstanceReadReplica_773403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_773473 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBParameterGroup_773475(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBParameterGroup_773474(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773476 = query.getOrDefault("Action")
  valid_773476 = validateParameter(valid_773476, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_773476 != nil:
    section.add "Action", valid_773476
  var valid_773477 = query.getOrDefault("Version")
  valid_773477 = validateParameter(valid_773477, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773477 != nil:
    section.add "Version", valid_773477
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773478 = header.getOrDefault("X-Amz-Date")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "X-Amz-Date", valid_773478
  var valid_773479 = header.getOrDefault("X-Amz-Security-Token")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Security-Token", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Content-Sha256", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-Algorithm")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-Algorithm", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-Signature")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Signature", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-SignedHeaders", valid_773483
  var valid_773484 = header.getOrDefault("X-Amz-Credential")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-Credential", valid_773484
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_773485 = formData.getOrDefault("DBParameterGroupName")
  valid_773485 = validateParameter(valid_773485, JString, required = true,
                                 default = nil)
  if valid_773485 != nil:
    section.add "DBParameterGroupName", valid_773485
  var valid_773486 = formData.getOrDefault("Tags")
  valid_773486 = validateParameter(valid_773486, JArray, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "Tags", valid_773486
  var valid_773487 = formData.getOrDefault("DBParameterGroupFamily")
  valid_773487 = validateParameter(valid_773487, JString, required = true,
                                 default = nil)
  if valid_773487 != nil:
    section.add "DBParameterGroupFamily", valid_773487
  var valid_773488 = formData.getOrDefault("Description")
  valid_773488 = validateParameter(valid_773488, JString, required = true,
                                 default = nil)
  if valid_773488 != nil:
    section.add "Description", valid_773488
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773489: Call_PostCreateDBParameterGroup_773473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773489.validator(path, query, header, formData, body)
  let scheme = call_773489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773489.url(scheme.get, call_773489.host, call_773489.base,
                         call_773489.route, valid.getOrDefault("path"))
  result = hook(call_773489, url, valid)

proc call*(call_773490: Call_PostCreateDBParameterGroup_773473;
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
  var query_773491 = newJObject()
  var formData_773492 = newJObject()
  add(formData_773492, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_773492.add "Tags", Tags
  add(query_773491, "Action", newJString(Action))
  add(formData_773492, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_773491, "Version", newJString(Version))
  add(formData_773492, "Description", newJString(Description))
  result = call_773490.call(nil, query_773491, nil, formData_773492, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_773473(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_773474, base: "/",
    url: url_PostCreateDBParameterGroup_773475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_773454 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBParameterGroup_773456(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBParameterGroup_773455(path: JsonNode; query: JsonNode;
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
  var valid_773457 = query.getOrDefault("Description")
  valid_773457 = validateParameter(valid_773457, JString, required = true,
                                 default = nil)
  if valid_773457 != nil:
    section.add "Description", valid_773457
  var valid_773458 = query.getOrDefault("DBParameterGroupFamily")
  valid_773458 = validateParameter(valid_773458, JString, required = true,
                                 default = nil)
  if valid_773458 != nil:
    section.add "DBParameterGroupFamily", valid_773458
  var valid_773459 = query.getOrDefault("Tags")
  valid_773459 = validateParameter(valid_773459, JArray, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "Tags", valid_773459
  var valid_773460 = query.getOrDefault("DBParameterGroupName")
  valid_773460 = validateParameter(valid_773460, JString, required = true,
                                 default = nil)
  if valid_773460 != nil:
    section.add "DBParameterGroupName", valid_773460
  var valid_773461 = query.getOrDefault("Action")
  valid_773461 = validateParameter(valid_773461, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_773461 != nil:
    section.add "Action", valid_773461
  var valid_773462 = query.getOrDefault("Version")
  valid_773462 = validateParameter(valid_773462, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773462 != nil:
    section.add "Version", valid_773462
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773463 = header.getOrDefault("X-Amz-Date")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-Date", valid_773463
  var valid_773464 = header.getOrDefault("X-Amz-Security-Token")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Security-Token", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Content-Sha256", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-Algorithm")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-Algorithm", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Signature")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Signature", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-SignedHeaders", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-Credential")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Credential", valid_773469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773470: Call_GetCreateDBParameterGroup_773454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773470.validator(path, query, header, formData, body)
  let scheme = call_773470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773470.url(scheme.get, call_773470.host, call_773470.base,
                         call_773470.route, valid.getOrDefault("path"))
  result = hook(call_773470, url, valid)

proc call*(call_773471: Call_GetCreateDBParameterGroup_773454; Description: string;
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
  var query_773472 = newJObject()
  add(query_773472, "Description", newJString(Description))
  add(query_773472, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_773472.add "Tags", Tags
  add(query_773472, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_773472, "Action", newJString(Action))
  add(query_773472, "Version", newJString(Version))
  result = call_773471.call(nil, query_773472, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_773454(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_773455, base: "/",
    url: url_GetCreateDBParameterGroup_773456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_773511 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBSecurityGroup_773513(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSecurityGroup_773512(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773514 = query.getOrDefault("Action")
  valid_773514 = validateParameter(valid_773514, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_773514 != nil:
    section.add "Action", valid_773514
  var valid_773515 = query.getOrDefault("Version")
  valid_773515 = validateParameter(valid_773515, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773515 != nil:
    section.add "Version", valid_773515
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773516 = header.getOrDefault("X-Amz-Date")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Date", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-Security-Token")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Security-Token", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Content-Sha256", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-Algorithm")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-Algorithm", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-Signature")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Signature", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-SignedHeaders", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-Credential")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Credential", valid_773522
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_773523 = formData.getOrDefault("DBSecurityGroupName")
  valid_773523 = validateParameter(valid_773523, JString, required = true,
                                 default = nil)
  if valid_773523 != nil:
    section.add "DBSecurityGroupName", valid_773523
  var valid_773524 = formData.getOrDefault("Tags")
  valid_773524 = validateParameter(valid_773524, JArray, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "Tags", valid_773524
  var valid_773525 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_773525 = validateParameter(valid_773525, JString, required = true,
                                 default = nil)
  if valid_773525 != nil:
    section.add "DBSecurityGroupDescription", valid_773525
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773526: Call_PostCreateDBSecurityGroup_773511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773526.validator(path, query, header, formData, body)
  let scheme = call_773526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773526.url(scheme.get, call_773526.host, call_773526.base,
                         call_773526.route, valid.getOrDefault("path"))
  result = hook(call_773526, url, valid)

proc call*(call_773527: Call_PostCreateDBSecurityGroup_773511;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_773528 = newJObject()
  var formData_773529 = newJObject()
  add(formData_773529, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_773529.add "Tags", Tags
  add(query_773528, "Action", newJString(Action))
  add(formData_773529, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_773528, "Version", newJString(Version))
  result = call_773527.call(nil, query_773528, nil, formData_773529, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_773511(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_773512, base: "/",
    url: url_PostCreateDBSecurityGroup_773513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_773493 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBSecurityGroup_773495(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSecurityGroup_773494(path: JsonNode; query: JsonNode;
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
  var valid_773496 = query.getOrDefault("DBSecurityGroupName")
  valid_773496 = validateParameter(valid_773496, JString, required = true,
                                 default = nil)
  if valid_773496 != nil:
    section.add "DBSecurityGroupName", valid_773496
  var valid_773497 = query.getOrDefault("DBSecurityGroupDescription")
  valid_773497 = validateParameter(valid_773497, JString, required = true,
                                 default = nil)
  if valid_773497 != nil:
    section.add "DBSecurityGroupDescription", valid_773497
  var valid_773498 = query.getOrDefault("Tags")
  valid_773498 = validateParameter(valid_773498, JArray, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "Tags", valid_773498
  var valid_773499 = query.getOrDefault("Action")
  valid_773499 = validateParameter(valid_773499, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_773499 != nil:
    section.add "Action", valid_773499
  var valid_773500 = query.getOrDefault("Version")
  valid_773500 = validateParameter(valid_773500, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773500 != nil:
    section.add "Version", valid_773500
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773501 = header.getOrDefault("X-Amz-Date")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Date", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Security-Token")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Security-Token", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Content-Sha256", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Algorithm")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Algorithm", valid_773504
  var valid_773505 = header.getOrDefault("X-Amz-Signature")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Signature", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-SignedHeaders", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Credential")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Credential", valid_773507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773508: Call_GetCreateDBSecurityGroup_773493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773508.validator(path, query, header, formData, body)
  let scheme = call_773508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773508.url(scheme.get, call_773508.host, call_773508.base,
                         call_773508.route, valid.getOrDefault("path"))
  result = hook(call_773508, url, valid)

proc call*(call_773509: Call_GetCreateDBSecurityGroup_773493;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773510 = newJObject()
  add(query_773510, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_773510, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_773510.add "Tags", Tags
  add(query_773510, "Action", newJString(Action))
  add(query_773510, "Version", newJString(Version))
  result = call_773509.call(nil, query_773510, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_773493(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_773494, base: "/",
    url: url_GetCreateDBSecurityGroup_773495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_773548 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBSnapshot_773550(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSnapshot_773549(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773551 = query.getOrDefault("Action")
  valid_773551 = validateParameter(valid_773551, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_773551 != nil:
    section.add "Action", valid_773551
  var valid_773552 = query.getOrDefault("Version")
  valid_773552 = validateParameter(valid_773552, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773552 != nil:
    section.add "Version", valid_773552
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773553 = header.getOrDefault("X-Amz-Date")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Date", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Security-Token")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Security-Token", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-Content-Sha256", valid_773555
  var valid_773556 = header.getOrDefault("X-Amz-Algorithm")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "X-Amz-Algorithm", valid_773556
  var valid_773557 = header.getOrDefault("X-Amz-Signature")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-Signature", valid_773557
  var valid_773558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773558 = validateParameter(valid_773558, JString, required = false,
                                 default = nil)
  if valid_773558 != nil:
    section.add "X-Amz-SignedHeaders", valid_773558
  var valid_773559 = header.getOrDefault("X-Amz-Credential")
  valid_773559 = validateParameter(valid_773559, JString, required = false,
                                 default = nil)
  if valid_773559 != nil:
    section.add "X-Amz-Credential", valid_773559
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_773560 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773560 = validateParameter(valid_773560, JString, required = true,
                                 default = nil)
  if valid_773560 != nil:
    section.add "DBInstanceIdentifier", valid_773560
  var valid_773561 = formData.getOrDefault("Tags")
  valid_773561 = validateParameter(valid_773561, JArray, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "Tags", valid_773561
  var valid_773562 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_773562 = validateParameter(valid_773562, JString, required = true,
                                 default = nil)
  if valid_773562 != nil:
    section.add "DBSnapshotIdentifier", valid_773562
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773563: Call_PostCreateDBSnapshot_773548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773563.validator(path, query, header, formData, body)
  let scheme = call_773563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773563.url(scheme.get, call_773563.host, call_773563.base,
                         call_773563.route, valid.getOrDefault("path"))
  result = hook(call_773563, url, valid)

proc call*(call_773564: Call_PostCreateDBSnapshot_773548;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773565 = newJObject()
  var formData_773566 = newJObject()
  add(formData_773566, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_773566.add "Tags", Tags
  add(formData_773566, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_773565, "Action", newJString(Action))
  add(query_773565, "Version", newJString(Version))
  result = call_773564.call(nil, query_773565, nil, formData_773566, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_773548(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_773549, base: "/",
    url: url_PostCreateDBSnapshot_773550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_773530 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBSnapshot_773532(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSnapshot_773531(path: JsonNode; query: JsonNode;
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
  var valid_773533 = query.getOrDefault("Tags")
  valid_773533 = validateParameter(valid_773533, JArray, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "Tags", valid_773533
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773534 = query.getOrDefault("Action")
  valid_773534 = validateParameter(valid_773534, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_773534 != nil:
    section.add "Action", valid_773534
  var valid_773535 = query.getOrDefault("Version")
  valid_773535 = validateParameter(valid_773535, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773535 != nil:
    section.add "Version", valid_773535
  var valid_773536 = query.getOrDefault("DBInstanceIdentifier")
  valid_773536 = validateParameter(valid_773536, JString, required = true,
                                 default = nil)
  if valid_773536 != nil:
    section.add "DBInstanceIdentifier", valid_773536
  var valid_773537 = query.getOrDefault("DBSnapshotIdentifier")
  valid_773537 = validateParameter(valid_773537, JString, required = true,
                                 default = nil)
  if valid_773537 != nil:
    section.add "DBSnapshotIdentifier", valid_773537
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773538 = header.getOrDefault("X-Amz-Date")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Date", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-Security-Token")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-Security-Token", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Content-Sha256", valid_773540
  var valid_773541 = header.getOrDefault("X-Amz-Algorithm")
  valid_773541 = validateParameter(valid_773541, JString, required = false,
                                 default = nil)
  if valid_773541 != nil:
    section.add "X-Amz-Algorithm", valid_773541
  var valid_773542 = header.getOrDefault("X-Amz-Signature")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Signature", valid_773542
  var valid_773543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773543 = validateParameter(valid_773543, JString, required = false,
                                 default = nil)
  if valid_773543 != nil:
    section.add "X-Amz-SignedHeaders", valid_773543
  var valid_773544 = header.getOrDefault("X-Amz-Credential")
  valid_773544 = validateParameter(valid_773544, JString, required = false,
                                 default = nil)
  if valid_773544 != nil:
    section.add "X-Amz-Credential", valid_773544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773545: Call_GetCreateDBSnapshot_773530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773545.validator(path, query, header, formData, body)
  let scheme = call_773545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773545.url(scheme.get, call_773545.host, call_773545.base,
                         call_773545.route, valid.getOrDefault("path"))
  result = hook(call_773545, url, valid)

proc call*(call_773546: Call_GetCreateDBSnapshot_773530;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_773547 = newJObject()
  if Tags != nil:
    query_773547.add "Tags", Tags
  add(query_773547, "Action", newJString(Action))
  add(query_773547, "Version", newJString(Version))
  add(query_773547, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_773547, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_773546.call(nil, query_773547, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_773530(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_773531, base: "/",
    url: url_GetCreateDBSnapshot_773532, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_773586 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBSubnetGroup_773588(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSubnetGroup_773587(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773589 = query.getOrDefault("Action")
  valid_773589 = validateParameter(valid_773589, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_773589 != nil:
    section.add "Action", valid_773589
  var valid_773590 = query.getOrDefault("Version")
  valid_773590 = validateParameter(valid_773590, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773590 != nil:
    section.add "Version", valid_773590
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773591 = header.getOrDefault("X-Amz-Date")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "X-Amz-Date", valid_773591
  var valid_773592 = header.getOrDefault("X-Amz-Security-Token")
  valid_773592 = validateParameter(valid_773592, JString, required = false,
                                 default = nil)
  if valid_773592 != nil:
    section.add "X-Amz-Security-Token", valid_773592
  var valid_773593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "X-Amz-Content-Sha256", valid_773593
  var valid_773594 = header.getOrDefault("X-Amz-Algorithm")
  valid_773594 = validateParameter(valid_773594, JString, required = false,
                                 default = nil)
  if valid_773594 != nil:
    section.add "X-Amz-Algorithm", valid_773594
  var valid_773595 = header.getOrDefault("X-Amz-Signature")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "X-Amz-Signature", valid_773595
  var valid_773596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-SignedHeaders", valid_773596
  var valid_773597 = header.getOrDefault("X-Amz-Credential")
  valid_773597 = validateParameter(valid_773597, JString, required = false,
                                 default = nil)
  if valid_773597 != nil:
    section.add "X-Amz-Credential", valid_773597
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_773598 = formData.getOrDefault("Tags")
  valid_773598 = validateParameter(valid_773598, JArray, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "Tags", valid_773598
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_773599 = formData.getOrDefault("DBSubnetGroupName")
  valid_773599 = validateParameter(valid_773599, JString, required = true,
                                 default = nil)
  if valid_773599 != nil:
    section.add "DBSubnetGroupName", valid_773599
  var valid_773600 = formData.getOrDefault("SubnetIds")
  valid_773600 = validateParameter(valid_773600, JArray, required = true, default = nil)
  if valid_773600 != nil:
    section.add "SubnetIds", valid_773600
  var valid_773601 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_773601 = validateParameter(valid_773601, JString, required = true,
                                 default = nil)
  if valid_773601 != nil:
    section.add "DBSubnetGroupDescription", valid_773601
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773602: Call_PostCreateDBSubnetGroup_773586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773602.validator(path, query, header, formData, body)
  let scheme = call_773602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773602.url(scheme.get, call_773602.host, call_773602.base,
                         call_773602.route, valid.getOrDefault("path"))
  result = hook(call_773602, url, valid)

proc call*(call_773603: Call_PostCreateDBSubnetGroup_773586;
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
  var query_773604 = newJObject()
  var formData_773605 = newJObject()
  if Tags != nil:
    formData_773605.add "Tags", Tags
  add(formData_773605, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_773605.add "SubnetIds", SubnetIds
  add(query_773604, "Action", newJString(Action))
  add(formData_773605, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_773604, "Version", newJString(Version))
  result = call_773603.call(nil, query_773604, nil, formData_773605, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_773586(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_773587, base: "/",
    url: url_PostCreateDBSubnetGroup_773588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_773567 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBSubnetGroup_773569(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSubnetGroup_773568(path: JsonNode; query: JsonNode;
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
  var valid_773570 = query.getOrDefault("Tags")
  valid_773570 = validateParameter(valid_773570, JArray, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "Tags", valid_773570
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773571 = query.getOrDefault("Action")
  valid_773571 = validateParameter(valid_773571, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_773571 != nil:
    section.add "Action", valid_773571
  var valid_773572 = query.getOrDefault("DBSubnetGroupName")
  valid_773572 = validateParameter(valid_773572, JString, required = true,
                                 default = nil)
  if valid_773572 != nil:
    section.add "DBSubnetGroupName", valid_773572
  var valid_773573 = query.getOrDefault("SubnetIds")
  valid_773573 = validateParameter(valid_773573, JArray, required = true, default = nil)
  if valid_773573 != nil:
    section.add "SubnetIds", valid_773573
  var valid_773574 = query.getOrDefault("DBSubnetGroupDescription")
  valid_773574 = validateParameter(valid_773574, JString, required = true,
                                 default = nil)
  if valid_773574 != nil:
    section.add "DBSubnetGroupDescription", valid_773574
  var valid_773575 = query.getOrDefault("Version")
  valid_773575 = validateParameter(valid_773575, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773583: Call_GetCreateDBSubnetGroup_773567; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773583.validator(path, query, header, formData, body)
  let scheme = call_773583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773583.url(scheme.get, call_773583.host, call_773583.base,
                         call_773583.route, valid.getOrDefault("path"))
  result = hook(call_773583, url, valid)

proc call*(call_773584: Call_GetCreateDBSubnetGroup_773567;
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
  var query_773585 = newJObject()
  if Tags != nil:
    query_773585.add "Tags", Tags
  add(query_773585, "Action", newJString(Action))
  add(query_773585, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_773585.add "SubnetIds", SubnetIds
  add(query_773585, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_773585, "Version", newJString(Version))
  result = call_773584.call(nil, query_773585, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_773567(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_773568, base: "/",
    url: url_GetCreateDBSubnetGroup_773569, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_773628 = ref object of OpenApiRestCall_772581
proc url_PostCreateEventSubscription_773630(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateEventSubscription_773629(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773631 = query.getOrDefault("Action")
  valid_773631 = validateParameter(valid_773631, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_773631 != nil:
    section.add "Action", valid_773631
  var valid_773632 = query.getOrDefault("Version")
  valid_773632 = validateParameter(valid_773632, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773632 != nil:
    section.add "Version", valid_773632
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773633 = header.getOrDefault("X-Amz-Date")
  valid_773633 = validateParameter(valid_773633, JString, required = false,
                                 default = nil)
  if valid_773633 != nil:
    section.add "X-Amz-Date", valid_773633
  var valid_773634 = header.getOrDefault("X-Amz-Security-Token")
  valid_773634 = validateParameter(valid_773634, JString, required = false,
                                 default = nil)
  if valid_773634 != nil:
    section.add "X-Amz-Security-Token", valid_773634
  var valid_773635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773635 = validateParameter(valid_773635, JString, required = false,
                                 default = nil)
  if valid_773635 != nil:
    section.add "X-Amz-Content-Sha256", valid_773635
  var valid_773636 = header.getOrDefault("X-Amz-Algorithm")
  valid_773636 = validateParameter(valid_773636, JString, required = false,
                                 default = nil)
  if valid_773636 != nil:
    section.add "X-Amz-Algorithm", valid_773636
  var valid_773637 = header.getOrDefault("X-Amz-Signature")
  valid_773637 = validateParameter(valid_773637, JString, required = false,
                                 default = nil)
  if valid_773637 != nil:
    section.add "X-Amz-Signature", valid_773637
  var valid_773638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773638 = validateParameter(valid_773638, JString, required = false,
                                 default = nil)
  if valid_773638 != nil:
    section.add "X-Amz-SignedHeaders", valid_773638
  var valid_773639 = header.getOrDefault("X-Amz-Credential")
  valid_773639 = validateParameter(valid_773639, JString, required = false,
                                 default = nil)
  if valid_773639 != nil:
    section.add "X-Amz-Credential", valid_773639
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
  var valid_773640 = formData.getOrDefault("Enabled")
  valid_773640 = validateParameter(valid_773640, JBool, required = false, default = nil)
  if valid_773640 != nil:
    section.add "Enabled", valid_773640
  var valid_773641 = formData.getOrDefault("EventCategories")
  valid_773641 = validateParameter(valid_773641, JArray, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "EventCategories", valid_773641
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_773642 = formData.getOrDefault("SnsTopicArn")
  valid_773642 = validateParameter(valid_773642, JString, required = true,
                                 default = nil)
  if valid_773642 != nil:
    section.add "SnsTopicArn", valid_773642
  var valid_773643 = formData.getOrDefault("SourceIds")
  valid_773643 = validateParameter(valid_773643, JArray, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "SourceIds", valid_773643
  var valid_773644 = formData.getOrDefault("Tags")
  valid_773644 = validateParameter(valid_773644, JArray, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "Tags", valid_773644
  var valid_773645 = formData.getOrDefault("SubscriptionName")
  valid_773645 = validateParameter(valid_773645, JString, required = true,
                                 default = nil)
  if valid_773645 != nil:
    section.add "SubscriptionName", valid_773645
  var valid_773646 = formData.getOrDefault("SourceType")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "SourceType", valid_773646
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773647: Call_PostCreateEventSubscription_773628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773647.validator(path, query, header, formData, body)
  let scheme = call_773647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773647.url(scheme.get, call_773647.host, call_773647.base,
                         call_773647.route, valid.getOrDefault("path"))
  result = hook(call_773647, url, valid)

proc call*(call_773648: Call_PostCreateEventSubscription_773628;
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
  var query_773649 = newJObject()
  var formData_773650 = newJObject()
  add(formData_773650, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_773650.add "EventCategories", EventCategories
  add(formData_773650, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_773650.add "SourceIds", SourceIds
  if Tags != nil:
    formData_773650.add "Tags", Tags
  add(formData_773650, "SubscriptionName", newJString(SubscriptionName))
  add(query_773649, "Action", newJString(Action))
  add(query_773649, "Version", newJString(Version))
  add(formData_773650, "SourceType", newJString(SourceType))
  result = call_773648.call(nil, query_773649, nil, formData_773650, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_773628(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_773629, base: "/",
    url: url_PostCreateEventSubscription_773630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_773606 = ref object of OpenApiRestCall_772581
proc url_GetCreateEventSubscription_773608(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateEventSubscription_773607(path: JsonNode; query: JsonNode;
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
  var valid_773609 = query.getOrDefault("SourceType")
  valid_773609 = validateParameter(valid_773609, JString, required = false,
                                 default = nil)
  if valid_773609 != nil:
    section.add "SourceType", valid_773609
  var valid_773610 = query.getOrDefault("SourceIds")
  valid_773610 = validateParameter(valid_773610, JArray, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "SourceIds", valid_773610
  var valid_773611 = query.getOrDefault("Enabled")
  valid_773611 = validateParameter(valid_773611, JBool, required = false, default = nil)
  if valid_773611 != nil:
    section.add "Enabled", valid_773611
  var valid_773612 = query.getOrDefault("Tags")
  valid_773612 = validateParameter(valid_773612, JArray, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "Tags", valid_773612
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773613 = query.getOrDefault("Action")
  valid_773613 = validateParameter(valid_773613, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_773613 != nil:
    section.add "Action", valid_773613
  var valid_773614 = query.getOrDefault("SnsTopicArn")
  valid_773614 = validateParameter(valid_773614, JString, required = true,
                                 default = nil)
  if valid_773614 != nil:
    section.add "SnsTopicArn", valid_773614
  var valid_773615 = query.getOrDefault("EventCategories")
  valid_773615 = validateParameter(valid_773615, JArray, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "EventCategories", valid_773615
  var valid_773616 = query.getOrDefault("SubscriptionName")
  valid_773616 = validateParameter(valid_773616, JString, required = true,
                                 default = nil)
  if valid_773616 != nil:
    section.add "SubscriptionName", valid_773616
  var valid_773617 = query.getOrDefault("Version")
  valid_773617 = validateParameter(valid_773617, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773617 != nil:
    section.add "Version", valid_773617
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773618 = header.getOrDefault("X-Amz-Date")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-Date", valid_773618
  var valid_773619 = header.getOrDefault("X-Amz-Security-Token")
  valid_773619 = validateParameter(valid_773619, JString, required = false,
                                 default = nil)
  if valid_773619 != nil:
    section.add "X-Amz-Security-Token", valid_773619
  var valid_773620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "X-Amz-Content-Sha256", valid_773620
  var valid_773621 = header.getOrDefault("X-Amz-Algorithm")
  valid_773621 = validateParameter(valid_773621, JString, required = false,
                                 default = nil)
  if valid_773621 != nil:
    section.add "X-Amz-Algorithm", valid_773621
  var valid_773622 = header.getOrDefault("X-Amz-Signature")
  valid_773622 = validateParameter(valid_773622, JString, required = false,
                                 default = nil)
  if valid_773622 != nil:
    section.add "X-Amz-Signature", valid_773622
  var valid_773623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773623 = validateParameter(valid_773623, JString, required = false,
                                 default = nil)
  if valid_773623 != nil:
    section.add "X-Amz-SignedHeaders", valid_773623
  var valid_773624 = header.getOrDefault("X-Amz-Credential")
  valid_773624 = validateParameter(valid_773624, JString, required = false,
                                 default = nil)
  if valid_773624 != nil:
    section.add "X-Amz-Credential", valid_773624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773625: Call_GetCreateEventSubscription_773606; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773625.validator(path, query, header, formData, body)
  let scheme = call_773625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773625.url(scheme.get, call_773625.host, call_773625.base,
                         call_773625.route, valid.getOrDefault("path"))
  result = hook(call_773625, url, valid)

proc call*(call_773626: Call_GetCreateEventSubscription_773606;
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
  var query_773627 = newJObject()
  add(query_773627, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_773627.add "SourceIds", SourceIds
  add(query_773627, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_773627.add "Tags", Tags
  add(query_773627, "Action", newJString(Action))
  add(query_773627, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_773627.add "EventCategories", EventCategories
  add(query_773627, "SubscriptionName", newJString(SubscriptionName))
  add(query_773627, "Version", newJString(Version))
  result = call_773626.call(nil, query_773627, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_773606(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_773607, base: "/",
    url: url_GetCreateEventSubscription_773608,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_773671 = ref object of OpenApiRestCall_772581
proc url_PostCreateOptionGroup_773673(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateOptionGroup_773672(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773674 = query.getOrDefault("Action")
  valid_773674 = validateParameter(valid_773674, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_773674 != nil:
    section.add "Action", valid_773674
  var valid_773675 = query.getOrDefault("Version")
  valid_773675 = validateParameter(valid_773675, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773675 != nil:
    section.add "Version", valid_773675
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773676 = header.getOrDefault("X-Amz-Date")
  valid_773676 = validateParameter(valid_773676, JString, required = false,
                                 default = nil)
  if valid_773676 != nil:
    section.add "X-Amz-Date", valid_773676
  var valid_773677 = header.getOrDefault("X-Amz-Security-Token")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Security-Token", valid_773677
  var valid_773678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773678 = validateParameter(valid_773678, JString, required = false,
                                 default = nil)
  if valid_773678 != nil:
    section.add "X-Amz-Content-Sha256", valid_773678
  var valid_773679 = header.getOrDefault("X-Amz-Algorithm")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "X-Amz-Algorithm", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-Signature")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Signature", valid_773680
  var valid_773681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-SignedHeaders", valid_773681
  var valid_773682 = header.getOrDefault("X-Amz-Credential")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-Credential", valid_773682
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_773683 = formData.getOrDefault("MajorEngineVersion")
  valid_773683 = validateParameter(valid_773683, JString, required = true,
                                 default = nil)
  if valid_773683 != nil:
    section.add "MajorEngineVersion", valid_773683
  var valid_773684 = formData.getOrDefault("OptionGroupName")
  valid_773684 = validateParameter(valid_773684, JString, required = true,
                                 default = nil)
  if valid_773684 != nil:
    section.add "OptionGroupName", valid_773684
  var valid_773685 = formData.getOrDefault("Tags")
  valid_773685 = validateParameter(valid_773685, JArray, required = false,
                                 default = nil)
  if valid_773685 != nil:
    section.add "Tags", valid_773685
  var valid_773686 = formData.getOrDefault("EngineName")
  valid_773686 = validateParameter(valid_773686, JString, required = true,
                                 default = nil)
  if valid_773686 != nil:
    section.add "EngineName", valid_773686
  var valid_773687 = formData.getOrDefault("OptionGroupDescription")
  valid_773687 = validateParameter(valid_773687, JString, required = true,
                                 default = nil)
  if valid_773687 != nil:
    section.add "OptionGroupDescription", valid_773687
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773688: Call_PostCreateOptionGroup_773671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773688.validator(path, query, header, formData, body)
  let scheme = call_773688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773688.url(scheme.get, call_773688.host, call_773688.base,
                         call_773688.route, valid.getOrDefault("path"))
  result = hook(call_773688, url, valid)

proc call*(call_773689: Call_PostCreateOptionGroup_773671;
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
  var query_773690 = newJObject()
  var formData_773691 = newJObject()
  add(formData_773691, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_773691, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_773691.add "Tags", Tags
  add(query_773690, "Action", newJString(Action))
  add(formData_773691, "EngineName", newJString(EngineName))
  add(formData_773691, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_773690, "Version", newJString(Version))
  result = call_773689.call(nil, query_773690, nil, formData_773691, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_773671(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_773672, base: "/",
    url: url_PostCreateOptionGroup_773673, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_773651 = ref object of OpenApiRestCall_772581
proc url_GetCreateOptionGroup_773653(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateOptionGroup_773652(path: JsonNode; query: JsonNode;
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
  var valid_773654 = query.getOrDefault("OptionGroupName")
  valid_773654 = validateParameter(valid_773654, JString, required = true,
                                 default = nil)
  if valid_773654 != nil:
    section.add "OptionGroupName", valid_773654
  var valid_773655 = query.getOrDefault("Tags")
  valid_773655 = validateParameter(valid_773655, JArray, required = false,
                                 default = nil)
  if valid_773655 != nil:
    section.add "Tags", valid_773655
  var valid_773656 = query.getOrDefault("OptionGroupDescription")
  valid_773656 = validateParameter(valid_773656, JString, required = true,
                                 default = nil)
  if valid_773656 != nil:
    section.add "OptionGroupDescription", valid_773656
  var valid_773657 = query.getOrDefault("Action")
  valid_773657 = validateParameter(valid_773657, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_773657 != nil:
    section.add "Action", valid_773657
  var valid_773658 = query.getOrDefault("Version")
  valid_773658 = validateParameter(valid_773658, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773658 != nil:
    section.add "Version", valid_773658
  var valid_773659 = query.getOrDefault("EngineName")
  valid_773659 = validateParameter(valid_773659, JString, required = true,
                                 default = nil)
  if valid_773659 != nil:
    section.add "EngineName", valid_773659
  var valid_773660 = query.getOrDefault("MajorEngineVersion")
  valid_773660 = validateParameter(valid_773660, JString, required = true,
                                 default = nil)
  if valid_773660 != nil:
    section.add "MajorEngineVersion", valid_773660
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773661 = header.getOrDefault("X-Amz-Date")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-Date", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Security-Token")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Security-Token", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Content-Sha256", valid_773663
  var valid_773664 = header.getOrDefault("X-Amz-Algorithm")
  valid_773664 = validateParameter(valid_773664, JString, required = false,
                                 default = nil)
  if valid_773664 != nil:
    section.add "X-Amz-Algorithm", valid_773664
  var valid_773665 = header.getOrDefault("X-Amz-Signature")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-Signature", valid_773665
  var valid_773666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "X-Amz-SignedHeaders", valid_773666
  var valid_773667 = header.getOrDefault("X-Amz-Credential")
  valid_773667 = validateParameter(valid_773667, JString, required = false,
                                 default = nil)
  if valid_773667 != nil:
    section.add "X-Amz-Credential", valid_773667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773668: Call_GetCreateOptionGroup_773651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773668.validator(path, query, header, formData, body)
  let scheme = call_773668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773668.url(scheme.get, call_773668.host, call_773668.base,
                         call_773668.route, valid.getOrDefault("path"))
  result = hook(call_773668, url, valid)

proc call*(call_773669: Call_GetCreateOptionGroup_773651; OptionGroupName: string;
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
  var query_773670 = newJObject()
  add(query_773670, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_773670.add "Tags", Tags
  add(query_773670, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_773670, "Action", newJString(Action))
  add(query_773670, "Version", newJString(Version))
  add(query_773670, "EngineName", newJString(EngineName))
  add(query_773670, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_773669.call(nil, query_773670, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_773651(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_773652, base: "/",
    url: url_GetCreateOptionGroup_773653, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_773710 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBInstance_773712(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBInstance_773711(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773713 = query.getOrDefault("Action")
  valid_773713 = validateParameter(valid_773713, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_773713 != nil:
    section.add "Action", valid_773713
  var valid_773714 = query.getOrDefault("Version")
  valid_773714 = validateParameter(valid_773714, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_773722 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773722 = validateParameter(valid_773722, JString, required = true,
                                 default = nil)
  if valid_773722 != nil:
    section.add "DBInstanceIdentifier", valid_773722
  var valid_773723 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_773723 = validateParameter(valid_773723, JString, required = false,
                                 default = nil)
  if valid_773723 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_773723
  var valid_773724 = formData.getOrDefault("SkipFinalSnapshot")
  valid_773724 = validateParameter(valid_773724, JBool, required = false, default = nil)
  if valid_773724 != nil:
    section.add "SkipFinalSnapshot", valid_773724
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773725: Call_PostDeleteDBInstance_773710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773725.validator(path, query, header, formData, body)
  let scheme = call_773725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773725.url(scheme.get, call_773725.host, call_773725.base,
                         call_773725.route, valid.getOrDefault("path"))
  result = hook(call_773725, url, valid)

proc call*(call_773726: Call_PostDeleteDBInstance_773710;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-09-09";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_773727 = newJObject()
  var formData_773728 = newJObject()
  add(formData_773728, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_773728, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_773727, "Action", newJString(Action))
  add(query_773727, "Version", newJString(Version))
  add(formData_773728, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_773726.call(nil, query_773727, nil, formData_773728, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_773710(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_773711, base: "/",
    url: url_PostDeleteDBInstance_773712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_773692 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBInstance_773694(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBInstance_773693(path: JsonNode; query: JsonNode;
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
  var valid_773695 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_773695
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773696 = query.getOrDefault("Action")
  valid_773696 = validateParameter(valid_773696, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_773696 != nil:
    section.add "Action", valid_773696
  var valid_773697 = query.getOrDefault("SkipFinalSnapshot")
  valid_773697 = validateParameter(valid_773697, JBool, required = false, default = nil)
  if valid_773697 != nil:
    section.add "SkipFinalSnapshot", valid_773697
  var valid_773698 = query.getOrDefault("Version")
  valid_773698 = validateParameter(valid_773698, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773698 != nil:
    section.add "Version", valid_773698
  var valid_773699 = query.getOrDefault("DBInstanceIdentifier")
  valid_773699 = validateParameter(valid_773699, JString, required = true,
                                 default = nil)
  if valid_773699 != nil:
    section.add "DBInstanceIdentifier", valid_773699
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773700 = header.getOrDefault("X-Amz-Date")
  valid_773700 = validateParameter(valid_773700, JString, required = false,
                                 default = nil)
  if valid_773700 != nil:
    section.add "X-Amz-Date", valid_773700
  var valid_773701 = header.getOrDefault("X-Amz-Security-Token")
  valid_773701 = validateParameter(valid_773701, JString, required = false,
                                 default = nil)
  if valid_773701 != nil:
    section.add "X-Amz-Security-Token", valid_773701
  var valid_773702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773702 = validateParameter(valid_773702, JString, required = false,
                                 default = nil)
  if valid_773702 != nil:
    section.add "X-Amz-Content-Sha256", valid_773702
  var valid_773703 = header.getOrDefault("X-Amz-Algorithm")
  valid_773703 = validateParameter(valid_773703, JString, required = false,
                                 default = nil)
  if valid_773703 != nil:
    section.add "X-Amz-Algorithm", valid_773703
  var valid_773704 = header.getOrDefault("X-Amz-Signature")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "X-Amz-Signature", valid_773704
  var valid_773705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "X-Amz-SignedHeaders", valid_773705
  var valid_773706 = header.getOrDefault("X-Amz-Credential")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "X-Amz-Credential", valid_773706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773707: Call_GetDeleteDBInstance_773692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773707.validator(path, query, header, formData, body)
  let scheme = call_773707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773707.url(scheme.get, call_773707.host, call_773707.base,
                         call_773707.route, valid.getOrDefault("path"))
  result = hook(call_773707, url, valid)

proc call*(call_773708: Call_GetDeleteDBInstance_773692;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_773709 = newJObject()
  add(query_773709, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_773709, "Action", newJString(Action))
  add(query_773709, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_773709, "Version", newJString(Version))
  add(query_773709, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_773708.call(nil, query_773709, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_773692(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_773693, base: "/",
    url: url_GetDeleteDBInstance_773694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_773745 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBParameterGroup_773747(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBParameterGroup_773746(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773748 = query.getOrDefault("Action")
  valid_773748 = validateParameter(valid_773748, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_773748 != nil:
    section.add "Action", valid_773748
  var valid_773749 = query.getOrDefault("Version")
  valid_773749 = validateParameter(valid_773749, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773749 != nil:
    section.add "Version", valid_773749
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773750 = header.getOrDefault("X-Amz-Date")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "X-Amz-Date", valid_773750
  var valid_773751 = header.getOrDefault("X-Amz-Security-Token")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-Security-Token", valid_773751
  var valid_773752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-Content-Sha256", valid_773752
  var valid_773753 = header.getOrDefault("X-Amz-Algorithm")
  valid_773753 = validateParameter(valid_773753, JString, required = false,
                                 default = nil)
  if valid_773753 != nil:
    section.add "X-Amz-Algorithm", valid_773753
  var valid_773754 = header.getOrDefault("X-Amz-Signature")
  valid_773754 = validateParameter(valid_773754, JString, required = false,
                                 default = nil)
  if valid_773754 != nil:
    section.add "X-Amz-Signature", valid_773754
  var valid_773755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773755 = validateParameter(valid_773755, JString, required = false,
                                 default = nil)
  if valid_773755 != nil:
    section.add "X-Amz-SignedHeaders", valid_773755
  var valid_773756 = header.getOrDefault("X-Amz-Credential")
  valid_773756 = validateParameter(valid_773756, JString, required = false,
                                 default = nil)
  if valid_773756 != nil:
    section.add "X-Amz-Credential", valid_773756
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_773757 = formData.getOrDefault("DBParameterGroupName")
  valid_773757 = validateParameter(valid_773757, JString, required = true,
                                 default = nil)
  if valid_773757 != nil:
    section.add "DBParameterGroupName", valid_773757
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773758: Call_PostDeleteDBParameterGroup_773745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773758.validator(path, query, header, formData, body)
  let scheme = call_773758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773758.url(scheme.get, call_773758.host, call_773758.base,
                         call_773758.route, valid.getOrDefault("path"))
  result = hook(call_773758, url, valid)

proc call*(call_773759: Call_PostDeleteDBParameterGroup_773745;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773760 = newJObject()
  var formData_773761 = newJObject()
  add(formData_773761, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_773760, "Action", newJString(Action))
  add(query_773760, "Version", newJString(Version))
  result = call_773759.call(nil, query_773760, nil, formData_773761, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_773745(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_773746, base: "/",
    url: url_PostDeleteDBParameterGroup_773747,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_773729 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBParameterGroup_773731(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBParameterGroup_773730(path: JsonNode; query: JsonNode;
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
  var valid_773732 = query.getOrDefault("DBParameterGroupName")
  valid_773732 = validateParameter(valid_773732, JString, required = true,
                                 default = nil)
  if valid_773732 != nil:
    section.add "DBParameterGroupName", valid_773732
  var valid_773733 = query.getOrDefault("Action")
  valid_773733 = validateParameter(valid_773733, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_773733 != nil:
    section.add "Action", valid_773733
  var valid_773734 = query.getOrDefault("Version")
  valid_773734 = validateParameter(valid_773734, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773734 != nil:
    section.add "Version", valid_773734
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773735 = header.getOrDefault("X-Amz-Date")
  valid_773735 = validateParameter(valid_773735, JString, required = false,
                                 default = nil)
  if valid_773735 != nil:
    section.add "X-Amz-Date", valid_773735
  var valid_773736 = header.getOrDefault("X-Amz-Security-Token")
  valid_773736 = validateParameter(valid_773736, JString, required = false,
                                 default = nil)
  if valid_773736 != nil:
    section.add "X-Amz-Security-Token", valid_773736
  var valid_773737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773737 = validateParameter(valid_773737, JString, required = false,
                                 default = nil)
  if valid_773737 != nil:
    section.add "X-Amz-Content-Sha256", valid_773737
  var valid_773738 = header.getOrDefault("X-Amz-Algorithm")
  valid_773738 = validateParameter(valid_773738, JString, required = false,
                                 default = nil)
  if valid_773738 != nil:
    section.add "X-Amz-Algorithm", valid_773738
  var valid_773739 = header.getOrDefault("X-Amz-Signature")
  valid_773739 = validateParameter(valid_773739, JString, required = false,
                                 default = nil)
  if valid_773739 != nil:
    section.add "X-Amz-Signature", valid_773739
  var valid_773740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773740 = validateParameter(valid_773740, JString, required = false,
                                 default = nil)
  if valid_773740 != nil:
    section.add "X-Amz-SignedHeaders", valid_773740
  var valid_773741 = header.getOrDefault("X-Amz-Credential")
  valid_773741 = validateParameter(valid_773741, JString, required = false,
                                 default = nil)
  if valid_773741 != nil:
    section.add "X-Amz-Credential", valid_773741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773742: Call_GetDeleteDBParameterGroup_773729; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773742.validator(path, query, header, formData, body)
  let scheme = call_773742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773742.url(scheme.get, call_773742.host, call_773742.base,
                         call_773742.route, valid.getOrDefault("path"))
  result = hook(call_773742, url, valid)

proc call*(call_773743: Call_GetDeleteDBParameterGroup_773729;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773744 = newJObject()
  add(query_773744, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_773744, "Action", newJString(Action))
  add(query_773744, "Version", newJString(Version))
  result = call_773743.call(nil, query_773744, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_773729(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_773730, base: "/",
    url: url_GetDeleteDBParameterGroup_773731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_773778 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBSecurityGroup_773780(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSecurityGroup_773779(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773781 = query.getOrDefault("Action")
  valid_773781 = validateParameter(valid_773781, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_773781 != nil:
    section.add "Action", valid_773781
  var valid_773782 = query.getOrDefault("Version")
  valid_773782 = validateParameter(valid_773782, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773782 != nil:
    section.add "Version", valid_773782
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773783 = header.getOrDefault("X-Amz-Date")
  valid_773783 = validateParameter(valid_773783, JString, required = false,
                                 default = nil)
  if valid_773783 != nil:
    section.add "X-Amz-Date", valid_773783
  var valid_773784 = header.getOrDefault("X-Amz-Security-Token")
  valid_773784 = validateParameter(valid_773784, JString, required = false,
                                 default = nil)
  if valid_773784 != nil:
    section.add "X-Amz-Security-Token", valid_773784
  var valid_773785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773785 = validateParameter(valid_773785, JString, required = false,
                                 default = nil)
  if valid_773785 != nil:
    section.add "X-Amz-Content-Sha256", valid_773785
  var valid_773786 = header.getOrDefault("X-Amz-Algorithm")
  valid_773786 = validateParameter(valid_773786, JString, required = false,
                                 default = nil)
  if valid_773786 != nil:
    section.add "X-Amz-Algorithm", valid_773786
  var valid_773787 = header.getOrDefault("X-Amz-Signature")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-Signature", valid_773787
  var valid_773788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773788 = validateParameter(valid_773788, JString, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "X-Amz-SignedHeaders", valid_773788
  var valid_773789 = header.getOrDefault("X-Amz-Credential")
  valid_773789 = validateParameter(valid_773789, JString, required = false,
                                 default = nil)
  if valid_773789 != nil:
    section.add "X-Amz-Credential", valid_773789
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_773790 = formData.getOrDefault("DBSecurityGroupName")
  valid_773790 = validateParameter(valid_773790, JString, required = true,
                                 default = nil)
  if valid_773790 != nil:
    section.add "DBSecurityGroupName", valid_773790
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773791: Call_PostDeleteDBSecurityGroup_773778; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773791.validator(path, query, header, formData, body)
  let scheme = call_773791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773791.url(scheme.get, call_773791.host, call_773791.base,
                         call_773791.route, valid.getOrDefault("path"))
  result = hook(call_773791, url, valid)

proc call*(call_773792: Call_PostDeleteDBSecurityGroup_773778;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773793 = newJObject()
  var formData_773794 = newJObject()
  add(formData_773794, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_773793, "Action", newJString(Action))
  add(query_773793, "Version", newJString(Version))
  result = call_773792.call(nil, query_773793, nil, formData_773794, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_773778(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_773779, base: "/",
    url: url_PostDeleteDBSecurityGroup_773780,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_773762 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBSecurityGroup_773764(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSecurityGroup_773763(path: JsonNode; query: JsonNode;
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
  var valid_773765 = query.getOrDefault("DBSecurityGroupName")
  valid_773765 = validateParameter(valid_773765, JString, required = true,
                                 default = nil)
  if valid_773765 != nil:
    section.add "DBSecurityGroupName", valid_773765
  var valid_773766 = query.getOrDefault("Action")
  valid_773766 = validateParameter(valid_773766, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_773766 != nil:
    section.add "Action", valid_773766
  var valid_773767 = query.getOrDefault("Version")
  valid_773767 = validateParameter(valid_773767, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773767 != nil:
    section.add "Version", valid_773767
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773768 = header.getOrDefault("X-Amz-Date")
  valid_773768 = validateParameter(valid_773768, JString, required = false,
                                 default = nil)
  if valid_773768 != nil:
    section.add "X-Amz-Date", valid_773768
  var valid_773769 = header.getOrDefault("X-Amz-Security-Token")
  valid_773769 = validateParameter(valid_773769, JString, required = false,
                                 default = nil)
  if valid_773769 != nil:
    section.add "X-Amz-Security-Token", valid_773769
  var valid_773770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773770 = validateParameter(valid_773770, JString, required = false,
                                 default = nil)
  if valid_773770 != nil:
    section.add "X-Amz-Content-Sha256", valid_773770
  var valid_773771 = header.getOrDefault("X-Amz-Algorithm")
  valid_773771 = validateParameter(valid_773771, JString, required = false,
                                 default = nil)
  if valid_773771 != nil:
    section.add "X-Amz-Algorithm", valid_773771
  var valid_773772 = header.getOrDefault("X-Amz-Signature")
  valid_773772 = validateParameter(valid_773772, JString, required = false,
                                 default = nil)
  if valid_773772 != nil:
    section.add "X-Amz-Signature", valid_773772
  var valid_773773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773773 = validateParameter(valid_773773, JString, required = false,
                                 default = nil)
  if valid_773773 != nil:
    section.add "X-Amz-SignedHeaders", valid_773773
  var valid_773774 = header.getOrDefault("X-Amz-Credential")
  valid_773774 = validateParameter(valid_773774, JString, required = false,
                                 default = nil)
  if valid_773774 != nil:
    section.add "X-Amz-Credential", valid_773774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773775: Call_GetDeleteDBSecurityGroup_773762; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773775.validator(path, query, header, formData, body)
  let scheme = call_773775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773775.url(scheme.get, call_773775.host, call_773775.base,
                         call_773775.route, valid.getOrDefault("path"))
  result = hook(call_773775, url, valid)

proc call*(call_773776: Call_GetDeleteDBSecurityGroup_773762;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773777 = newJObject()
  add(query_773777, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_773777, "Action", newJString(Action))
  add(query_773777, "Version", newJString(Version))
  result = call_773776.call(nil, query_773777, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_773762(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_773763, base: "/",
    url: url_GetDeleteDBSecurityGroup_773764, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_773811 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBSnapshot_773813(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSnapshot_773812(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773814 = query.getOrDefault("Action")
  valid_773814 = validateParameter(valid_773814, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_773814 != nil:
    section.add "Action", valid_773814
  var valid_773815 = query.getOrDefault("Version")
  valid_773815 = validateParameter(valid_773815, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773815 != nil:
    section.add "Version", valid_773815
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773816 = header.getOrDefault("X-Amz-Date")
  valid_773816 = validateParameter(valid_773816, JString, required = false,
                                 default = nil)
  if valid_773816 != nil:
    section.add "X-Amz-Date", valid_773816
  var valid_773817 = header.getOrDefault("X-Amz-Security-Token")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-Security-Token", valid_773817
  var valid_773818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773818 = validateParameter(valid_773818, JString, required = false,
                                 default = nil)
  if valid_773818 != nil:
    section.add "X-Amz-Content-Sha256", valid_773818
  var valid_773819 = header.getOrDefault("X-Amz-Algorithm")
  valid_773819 = validateParameter(valid_773819, JString, required = false,
                                 default = nil)
  if valid_773819 != nil:
    section.add "X-Amz-Algorithm", valid_773819
  var valid_773820 = header.getOrDefault("X-Amz-Signature")
  valid_773820 = validateParameter(valid_773820, JString, required = false,
                                 default = nil)
  if valid_773820 != nil:
    section.add "X-Amz-Signature", valid_773820
  var valid_773821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773821 = validateParameter(valid_773821, JString, required = false,
                                 default = nil)
  if valid_773821 != nil:
    section.add "X-Amz-SignedHeaders", valid_773821
  var valid_773822 = header.getOrDefault("X-Amz-Credential")
  valid_773822 = validateParameter(valid_773822, JString, required = false,
                                 default = nil)
  if valid_773822 != nil:
    section.add "X-Amz-Credential", valid_773822
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_773823 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_773823 = validateParameter(valid_773823, JString, required = true,
                                 default = nil)
  if valid_773823 != nil:
    section.add "DBSnapshotIdentifier", valid_773823
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773824: Call_PostDeleteDBSnapshot_773811; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773824.validator(path, query, header, formData, body)
  let scheme = call_773824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773824.url(scheme.get, call_773824.host, call_773824.base,
                         call_773824.route, valid.getOrDefault("path"))
  result = hook(call_773824, url, valid)

proc call*(call_773825: Call_PostDeleteDBSnapshot_773811;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773826 = newJObject()
  var formData_773827 = newJObject()
  add(formData_773827, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_773826, "Action", newJString(Action))
  add(query_773826, "Version", newJString(Version))
  result = call_773825.call(nil, query_773826, nil, formData_773827, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_773811(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_773812, base: "/",
    url: url_PostDeleteDBSnapshot_773813, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_773795 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBSnapshot_773797(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSnapshot_773796(path: JsonNode; query: JsonNode;
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
  var valid_773798 = query.getOrDefault("Action")
  valid_773798 = validateParameter(valid_773798, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_773798 != nil:
    section.add "Action", valid_773798
  var valid_773799 = query.getOrDefault("Version")
  valid_773799 = validateParameter(valid_773799, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773799 != nil:
    section.add "Version", valid_773799
  var valid_773800 = query.getOrDefault("DBSnapshotIdentifier")
  valid_773800 = validateParameter(valid_773800, JString, required = true,
                                 default = nil)
  if valid_773800 != nil:
    section.add "DBSnapshotIdentifier", valid_773800
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773808: Call_GetDeleteDBSnapshot_773795; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773808.validator(path, query, header, formData, body)
  let scheme = call_773808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773808.url(scheme.get, call_773808.host, call_773808.base,
                         call_773808.route, valid.getOrDefault("path"))
  result = hook(call_773808, url, valid)

proc call*(call_773809: Call_GetDeleteDBSnapshot_773795;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_773810 = newJObject()
  add(query_773810, "Action", newJString(Action))
  add(query_773810, "Version", newJString(Version))
  add(query_773810, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_773809.call(nil, query_773810, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_773795(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_773796, base: "/",
    url: url_GetDeleteDBSnapshot_773797, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_773844 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBSubnetGroup_773846(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSubnetGroup_773845(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773847 = query.getOrDefault("Action")
  valid_773847 = validateParameter(valid_773847, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_773847 != nil:
    section.add "Action", valid_773847
  var valid_773848 = query.getOrDefault("Version")
  valid_773848 = validateParameter(valid_773848, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773848 != nil:
    section.add "Version", valid_773848
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773849 = header.getOrDefault("X-Amz-Date")
  valid_773849 = validateParameter(valid_773849, JString, required = false,
                                 default = nil)
  if valid_773849 != nil:
    section.add "X-Amz-Date", valid_773849
  var valid_773850 = header.getOrDefault("X-Amz-Security-Token")
  valid_773850 = validateParameter(valid_773850, JString, required = false,
                                 default = nil)
  if valid_773850 != nil:
    section.add "X-Amz-Security-Token", valid_773850
  var valid_773851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773851 = validateParameter(valid_773851, JString, required = false,
                                 default = nil)
  if valid_773851 != nil:
    section.add "X-Amz-Content-Sha256", valid_773851
  var valid_773852 = header.getOrDefault("X-Amz-Algorithm")
  valid_773852 = validateParameter(valid_773852, JString, required = false,
                                 default = nil)
  if valid_773852 != nil:
    section.add "X-Amz-Algorithm", valid_773852
  var valid_773853 = header.getOrDefault("X-Amz-Signature")
  valid_773853 = validateParameter(valid_773853, JString, required = false,
                                 default = nil)
  if valid_773853 != nil:
    section.add "X-Amz-Signature", valid_773853
  var valid_773854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773854 = validateParameter(valid_773854, JString, required = false,
                                 default = nil)
  if valid_773854 != nil:
    section.add "X-Amz-SignedHeaders", valid_773854
  var valid_773855 = header.getOrDefault("X-Amz-Credential")
  valid_773855 = validateParameter(valid_773855, JString, required = false,
                                 default = nil)
  if valid_773855 != nil:
    section.add "X-Amz-Credential", valid_773855
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_773856 = formData.getOrDefault("DBSubnetGroupName")
  valid_773856 = validateParameter(valid_773856, JString, required = true,
                                 default = nil)
  if valid_773856 != nil:
    section.add "DBSubnetGroupName", valid_773856
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773857: Call_PostDeleteDBSubnetGroup_773844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773857.validator(path, query, header, formData, body)
  let scheme = call_773857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773857.url(scheme.get, call_773857.host, call_773857.base,
                         call_773857.route, valid.getOrDefault("path"))
  result = hook(call_773857, url, valid)

proc call*(call_773858: Call_PostDeleteDBSubnetGroup_773844;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773859 = newJObject()
  var formData_773860 = newJObject()
  add(formData_773860, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773859, "Action", newJString(Action))
  add(query_773859, "Version", newJString(Version))
  result = call_773858.call(nil, query_773859, nil, formData_773860, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_773844(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_773845, base: "/",
    url: url_PostDeleteDBSubnetGroup_773846, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_773828 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBSubnetGroup_773830(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSubnetGroup_773829(path: JsonNode; query: JsonNode;
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
  var valid_773831 = query.getOrDefault("Action")
  valid_773831 = validateParameter(valid_773831, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_773831 != nil:
    section.add "Action", valid_773831
  var valid_773832 = query.getOrDefault("DBSubnetGroupName")
  valid_773832 = validateParameter(valid_773832, JString, required = true,
                                 default = nil)
  if valid_773832 != nil:
    section.add "DBSubnetGroupName", valid_773832
  var valid_773833 = query.getOrDefault("Version")
  valid_773833 = validateParameter(valid_773833, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773833 != nil:
    section.add "Version", valid_773833
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773834 = header.getOrDefault("X-Amz-Date")
  valid_773834 = validateParameter(valid_773834, JString, required = false,
                                 default = nil)
  if valid_773834 != nil:
    section.add "X-Amz-Date", valid_773834
  var valid_773835 = header.getOrDefault("X-Amz-Security-Token")
  valid_773835 = validateParameter(valid_773835, JString, required = false,
                                 default = nil)
  if valid_773835 != nil:
    section.add "X-Amz-Security-Token", valid_773835
  var valid_773836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773836 = validateParameter(valid_773836, JString, required = false,
                                 default = nil)
  if valid_773836 != nil:
    section.add "X-Amz-Content-Sha256", valid_773836
  var valid_773837 = header.getOrDefault("X-Amz-Algorithm")
  valid_773837 = validateParameter(valid_773837, JString, required = false,
                                 default = nil)
  if valid_773837 != nil:
    section.add "X-Amz-Algorithm", valid_773837
  var valid_773838 = header.getOrDefault("X-Amz-Signature")
  valid_773838 = validateParameter(valid_773838, JString, required = false,
                                 default = nil)
  if valid_773838 != nil:
    section.add "X-Amz-Signature", valid_773838
  var valid_773839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773839 = validateParameter(valid_773839, JString, required = false,
                                 default = nil)
  if valid_773839 != nil:
    section.add "X-Amz-SignedHeaders", valid_773839
  var valid_773840 = header.getOrDefault("X-Amz-Credential")
  valid_773840 = validateParameter(valid_773840, JString, required = false,
                                 default = nil)
  if valid_773840 != nil:
    section.add "X-Amz-Credential", valid_773840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773841: Call_GetDeleteDBSubnetGroup_773828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773841.validator(path, query, header, formData, body)
  let scheme = call_773841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773841.url(scheme.get, call_773841.host, call_773841.base,
                         call_773841.route, valid.getOrDefault("path"))
  result = hook(call_773841, url, valid)

proc call*(call_773842: Call_GetDeleteDBSubnetGroup_773828;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_773843 = newJObject()
  add(query_773843, "Action", newJString(Action))
  add(query_773843, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773843, "Version", newJString(Version))
  result = call_773842.call(nil, query_773843, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_773828(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_773829, base: "/",
    url: url_GetDeleteDBSubnetGroup_773830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_773877 = ref object of OpenApiRestCall_772581
proc url_PostDeleteEventSubscription_773879(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEventSubscription_773878(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773880 = query.getOrDefault("Action")
  valid_773880 = validateParameter(valid_773880, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_773880 != nil:
    section.add "Action", valid_773880
  var valid_773881 = query.getOrDefault("Version")
  valid_773881 = validateParameter(valid_773881, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773881 != nil:
    section.add "Version", valid_773881
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773882 = header.getOrDefault("X-Amz-Date")
  valid_773882 = validateParameter(valid_773882, JString, required = false,
                                 default = nil)
  if valid_773882 != nil:
    section.add "X-Amz-Date", valid_773882
  var valid_773883 = header.getOrDefault("X-Amz-Security-Token")
  valid_773883 = validateParameter(valid_773883, JString, required = false,
                                 default = nil)
  if valid_773883 != nil:
    section.add "X-Amz-Security-Token", valid_773883
  var valid_773884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773884 = validateParameter(valid_773884, JString, required = false,
                                 default = nil)
  if valid_773884 != nil:
    section.add "X-Amz-Content-Sha256", valid_773884
  var valid_773885 = header.getOrDefault("X-Amz-Algorithm")
  valid_773885 = validateParameter(valid_773885, JString, required = false,
                                 default = nil)
  if valid_773885 != nil:
    section.add "X-Amz-Algorithm", valid_773885
  var valid_773886 = header.getOrDefault("X-Amz-Signature")
  valid_773886 = validateParameter(valid_773886, JString, required = false,
                                 default = nil)
  if valid_773886 != nil:
    section.add "X-Amz-Signature", valid_773886
  var valid_773887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773887 = validateParameter(valid_773887, JString, required = false,
                                 default = nil)
  if valid_773887 != nil:
    section.add "X-Amz-SignedHeaders", valid_773887
  var valid_773888 = header.getOrDefault("X-Amz-Credential")
  valid_773888 = validateParameter(valid_773888, JString, required = false,
                                 default = nil)
  if valid_773888 != nil:
    section.add "X-Amz-Credential", valid_773888
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_773889 = formData.getOrDefault("SubscriptionName")
  valid_773889 = validateParameter(valid_773889, JString, required = true,
                                 default = nil)
  if valid_773889 != nil:
    section.add "SubscriptionName", valid_773889
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773890: Call_PostDeleteEventSubscription_773877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773890.validator(path, query, header, formData, body)
  let scheme = call_773890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773890.url(scheme.get, call_773890.host, call_773890.base,
                         call_773890.route, valid.getOrDefault("path"))
  result = hook(call_773890, url, valid)

proc call*(call_773891: Call_PostDeleteEventSubscription_773877;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773892 = newJObject()
  var formData_773893 = newJObject()
  add(formData_773893, "SubscriptionName", newJString(SubscriptionName))
  add(query_773892, "Action", newJString(Action))
  add(query_773892, "Version", newJString(Version))
  result = call_773891.call(nil, query_773892, nil, formData_773893, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_773877(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_773878, base: "/",
    url: url_PostDeleteEventSubscription_773879,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_773861 = ref object of OpenApiRestCall_772581
proc url_GetDeleteEventSubscription_773863(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEventSubscription_773862(path: JsonNode; query: JsonNode;
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
  var valid_773864 = query.getOrDefault("Action")
  valid_773864 = validateParameter(valid_773864, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_773864 != nil:
    section.add "Action", valid_773864
  var valid_773865 = query.getOrDefault("SubscriptionName")
  valid_773865 = validateParameter(valid_773865, JString, required = true,
                                 default = nil)
  if valid_773865 != nil:
    section.add "SubscriptionName", valid_773865
  var valid_773866 = query.getOrDefault("Version")
  valid_773866 = validateParameter(valid_773866, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773866 != nil:
    section.add "Version", valid_773866
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773867 = header.getOrDefault("X-Amz-Date")
  valid_773867 = validateParameter(valid_773867, JString, required = false,
                                 default = nil)
  if valid_773867 != nil:
    section.add "X-Amz-Date", valid_773867
  var valid_773868 = header.getOrDefault("X-Amz-Security-Token")
  valid_773868 = validateParameter(valid_773868, JString, required = false,
                                 default = nil)
  if valid_773868 != nil:
    section.add "X-Amz-Security-Token", valid_773868
  var valid_773869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773869 = validateParameter(valid_773869, JString, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "X-Amz-Content-Sha256", valid_773869
  var valid_773870 = header.getOrDefault("X-Amz-Algorithm")
  valid_773870 = validateParameter(valid_773870, JString, required = false,
                                 default = nil)
  if valid_773870 != nil:
    section.add "X-Amz-Algorithm", valid_773870
  var valid_773871 = header.getOrDefault("X-Amz-Signature")
  valid_773871 = validateParameter(valid_773871, JString, required = false,
                                 default = nil)
  if valid_773871 != nil:
    section.add "X-Amz-Signature", valid_773871
  var valid_773872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-SignedHeaders", valid_773872
  var valid_773873 = header.getOrDefault("X-Amz-Credential")
  valid_773873 = validateParameter(valid_773873, JString, required = false,
                                 default = nil)
  if valid_773873 != nil:
    section.add "X-Amz-Credential", valid_773873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773874: Call_GetDeleteEventSubscription_773861; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773874.validator(path, query, header, formData, body)
  let scheme = call_773874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773874.url(scheme.get, call_773874.host, call_773874.base,
                         call_773874.route, valid.getOrDefault("path"))
  result = hook(call_773874, url, valid)

proc call*(call_773875: Call_GetDeleteEventSubscription_773861;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_773876 = newJObject()
  add(query_773876, "Action", newJString(Action))
  add(query_773876, "SubscriptionName", newJString(SubscriptionName))
  add(query_773876, "Version", newJString(Version))
  result = call_773875.call(nil, query_773876, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_773861(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_773862, base: "/",
    url: url_GetDeleteEventSubscription_773863,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_773910 = ref object of OpenApiRestCall_772581
proc url_PostDeleteOptionGroup_773912(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteOptionGroup_773911(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773913 = query.getOrDefault("Action")
  valid_773913 = validateParameter(valid_773913, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_773913 != nil:
    section.add "Action", valid_773913
  var valid_773914 = query.getOrDefault("Version")
  valid_773914 = validateParameter(valid_773914, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773914 != nil:
    section.add "Version", valid_773914
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773915 = header.getOrDefault("X-Amz-Date")
  valid_773915 = validateParameter(valid_773915, JString, required = false,
                                 default = nil)
  if valid_773915 != nil:
    section.add "X-Amz-Date", valid_773915
  var valid_773916 = header.getOrDefault("X-Amz-Security-Token")
  valid_773916 = validateParameter(valid_773916, JString, required = false,
                                 default = nil)
  if valid_773916 != nil:
    section.add "X-Amz-Security-Token", valid_773916
  var valid_773917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773917 = validateParameter(valid_773917, JString, required = false,
                                 default = nil)
  if valid_773917 != nil:
    section.add "X-Amz-Content-Sha256", valid_773917
  var valid_773918 = header.getOrDefault("X-Amz-Algorithm")
  valid_773918 = validateParameter(valid_773918, JString, required = false,
                                 default = nil)
  if valid_773918 != nil:
    section.add "X-Amz-Algorithm", valid_773918
  var valid_773919 = header.getOrDefault("X-Amz-Signature")
  valid_773919 = validateParameter(valid_773919, JString, required = false,
                                 default = nil)
  if valid_773919 != nil:
    section.add "X-Amz-Signature", valid_773919
  var valid_773920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773920 = validateParameter(valid_773920, JString, required = false,
                                 default = nil)
  if valid_773920 != nil:
    section.add "X-Amz-SignedHeaders", valid_773920
  var valid_773921 = header.getOrDefault("X-Amz-Credential")
  valid_773921 = validateParameter(valid_773921, JString, required = false,
                                 default = nil)
  if valid_773921 != nil:
    section.add "X-Amz-Credential", valid_773921
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_773922 = formData.getOrDefault("OptionGroupName")
  valid_773922 = validateParameter(valid_773922, JString, required = true,
                                 default = nil)
  if valid_773922 != nil:
    section.add "OptionGroupName", valid_773922
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773923: Call_PostDeleteOptionGroup_773910; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773923.validator(path, query, header, formData, body)
  let scheme = call_773923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773923.url(scheme.get, call_773923.host, call_773923.base,
                         call_773923.route, valid.getOrDefault("path"))
  result = hook(call_773923, url, valid)

proc call*(call_773924: Call_PostDeleteOptionGroup_773910; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773925 = newJObject()
  var formData_773926 = newJObject()
  add(formData_773926, "OptionGroupName", newJString(OptionGroupName))
  add(query_773925, "Action", newJString(Action))
  add(query_773925, "Version", newJString(Version))
  result = call_773924.call(nil, query_773925, nil, formData_773926, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_773910(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_773911, base: "/",
    url: url_PostDeleteOptionGroup_773912, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_773894 = ref object of OpenApiRestCall_772581
proc url_GetDeleteOptionGroup_773896(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteOptionGroup_773895(path: JsonNode; query: JsonNode;
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
  var valid_773897 = query.getOrDefault("OptionGroupName")
  valid_773897 = validateParameter(valid_773897, JString, required = true,
                                 default = nil)
  if valid_773897 != nil:
    section.add "OptionGroupName", valid_773897
  var valid_773898 = query.getOrDefault("Action")
  valid_773898 = validateParameter(valid_773898, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_773898 != nil:
    section.add "Action", valid_773898
  var valid_773899 = query.getOrDefault("Version")
  valid_773899 = validateParameter(valid_773899, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773899 != nil:
    section.add "Version", valid_773899
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773900 = header.getOrDefault("X-Amz-Date")
  valid_773900 = validateParameter(valid_773900, JString, required = false,
                                 default = nil)
  if valid_773900 != nil:
    section.add "X-Amz-Date", valid_773900
  var valid_773901 = header.getOrDefault("X-Amz-Security-Token")
  valid_773901 = validateParameter(valid_773901, JString, required = false,
                                 default = nil)
  if valid_773901 != nil:
    section.add "X-Amz-Security-Token", valid_773901
  var valid_773902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773902 = validateParameter(valid_773902, JString, required = false,
                                 default = nil)
  if valid_773902 != nil:
    section.add "X-Amz-Content-Sha256", valid_773902
  var valid_773903 = header.getOrDefault("X-Amz-Algorithm")
  valid_773903 = validateParameter(valid_773903, JString, required = false,
                                 default = nil)
  if valid_773903 != nil:
    section.add "X-Amz-Algorithm", valid_773903
  var valid_773904 = header.getOrDefault("X-Amz-Signature")
  valid_773904 = validateParameter(valid_773904, JString, required = false,
                                 default = nil)
  if valid_773904 != nil:
    section.add "X-Amz-Signature", valid_773904
  var valid_773905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773905 = validateParameter(valid_773905, JString, required = false,
                                 default = nil)
  if valid_773905 != nil:
    section.add "X-Amz-SignedHeaders", valid_773905
  var valid_773906 = header.getOrDefault("X-Amz-Credential")
  valid_773906 = validateParameter(valid_773906, JString, required = false,
                                 default = nil)
  if valid_773906 != nil:
    section.add "X-Amz-Credential", valid_773906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773907: Call_GetDeleteOptionGroup_773894; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773907.validator(path, query, header, formData, body)
  let scheme = call_773907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773907.url(scheme.get, call_773907.host, call_773907.base,
                         call_773907.route, valid.getOrDefault("path"))
  result = hook(call_773907, url, valid)

proc call*(call_773908: Call_GetDeleteOptionGroup_773894; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773909 = newJObject()
  add(query_773909, "OptionGroupName", newJString(OptionGroupName))
  add(query_773909, "Action", newJString(Action))
  add(query_773909, "Version", newJString(Version))
  result = call_773908.call(nil, query_773909, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_773894(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_773895, base: "/",
    url: url_GetDeleteOptionGroup_773896, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_773950 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBEngineVersions_773952(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBEngineVersions_773951(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773953 = query.getOrDefault("Action")
  valid_773953 = validateParameter(valid_773953, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_773953 != nil:
    section.add "Action", valid_773953
  var valid_773954 = query.getOrDefault("Version")
  valid_773954 = validateParameter(valid_773954, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773954 != nil:
    section.add "Version", valid_773954
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773955 = header.getOrDefault("X-Amz-Date")
  valid_773955 = validateParameter(valid_773955, JString, required = false,
                                 default = nil)
  if valid_773955 != nil:
    section.add "X-Amz-Date", valid_773955
  var valid_773956 = header.getOrDefault("X-Amz-Security-Token")
  valid_773956 = validateParameter(valid_773956, JString, required = false,
                                 default = nil)
  if valid_773956 != nil:
    section.add "X-Amz-Security-Token", valid_773956
  var valid_773957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773957 = validateParameter(valid_773957, JString, required = false,
                                 default = nil)
  if valid_773957 != nil:
    section.add "X-Amz-Content-Sha256", valid_773957
  var valid_773958 = header.getOrDefault("X-Amz-Algorithm")
  valid_773958 = validateParameter(valid_773958, JString, required = false,
                                 default = nil)
  if valid_773958 != nil:
    section.add "X-Amz-Algorithm", valid_773958
  var valid_773959 = header.getOrDefault("X-Amz-Signature")
  valid_773959 = validateParameter(valid_773959, JString, required = false,
                                 default = nil)
  if valid_773959 != nil:
    section.add "X-Amz-Signature", valid_773959
  var valid_773960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773960 = validateParameter(valid_773960, JString, required = false,
                                 default = nil)
  if valid_773960 != nil:
    section.add "X-Amz-SignedHeaders", valid_773960
  var valid_773961 = header.getOrDefault("X-Amz-Credential")
  valid_773961 = validateParameter(valid_773961, JString, required = false,
                                 default = nil)
  if valid_773961 != nil:
    section.add "X-Amz-Credential", valid_773961
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
  var valid_773962 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_773962 = validateParameter(valid_773962, JBool, required = false, default = nil)
  if valid_773962 != nil:
    section.add "ListSupportedCharacterSets", valid_773962
  var valid_773963 = formData.getOrDefault("Engine")
  valid_773963 = validateParameter(valid_773963, JString, required = false,
                                 default = nil)
  if valid_773963 != nil:
    section.add "Engine", valid_773963
  var valid_773964 = formData.getOrDefault("Marker")
  valid_773964 = validateParameter(valid_773964, JString, required = false,
                                 default = nil)
  if valid_773964 != nil:
    section.add "Marker", valid_773964
  var valid_773965 = formData.getOrDefault("DBParameterGroupFamily")
  valid_773965 = validateParameter(valid_773965, JString, required = false,
                                 default = nil)
  if valid_773965 != nil:
    section.add "DBParameterGroupFamily", valid_773965
  var valid_773966 = formData.getOrDefault("Filters")
  valid_773966 = validateParameter(valid_773966, JArray, required = false,
                                 default = nil)
  if valid_773966 != nil:
    section.add "Filters", valid_773966
  var valid_773967 = formData.getOrDefault("MaxRecords")
  valid_773967 = validateParameter(valid_773967, JInt, required = false, default = nil)
  if valid_773967 != nil:
    section.add "MaxRecords", valid_773967
  var valid_773968 = formData.getOrDefault("EngineVersion")
  valid_773968 = validateParameter(valid_773968, JString, required = false,
                                 default = nil)
  if valid_773968 != nil:
    section.add "EngineVersion", valid_773968
  var valid_773969 = formData.getOrDefault("DefaultOnly")
  valid_773969 = validateParameter(valid_773969, JBool, required = false, default = nil)
  if valid_773969 != nil:
    section.add "DefaultOnly", valid_773969
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773970: Call_PostDescribeDBEngineVersions_773950; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773970.validator(path, query, header, formData, body)
  let scheme = call_773970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773970.url(scheme.get, call_773970.host, call_773970.base,
                         call_773970.route, valid.getOrDefault("path"))
  result = hook(call_773970, url, valid)

proc call*(call_773971: Call_PostDescribeDBEngineVersions_773950;
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
  var query_773972 = newJObject()
  var formData_773973 = newJObject()
  add(formData_773973, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_773973, "Engine", newJString(Engine))
  add(formData_773973, "Marker", newJString(Marker))
  add(query_773972, "Action", newJString(Action))
  add(formData_773973, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_773973.add "Filters", Filters
  add(formData_773973, "MaxRecords", newJInt(MaxRecords))
  add(formData_773973, "EngineVersion", newJString(EngineVersion))
  add(query_773972, "Version", newJString(Version))
  add(formData_773973, "DefaultOnly", newJBool(DefaultOnly))
  result = call_773971.call(nil, query_773972, nil, formData_773973, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_773950(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_773951, base: "/",
    url: url_PostDescribeDBEngineVersions_773952,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_773927 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBEngineVersions_773929(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBEngineVersions_773928(path: JsonNode; query: JsonNode;
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
  var valid_773930 = query.getOrDefault("Engine")
  valid_773930 = validateParameter(valid_773930, JString, required = false,
                                 default = nil)
  if valid_773930 != nil:
    section.add "Engine", valid_773930
  var valid_773931 = query.getOrDefault("ListSupportedCharacterSets")
  valid_773931 = validateParameter(valid_773931, JBool, required = false, default = nil)
  if valid_773931 != nil:
    section.add "ListSupportedCharacterSets", valid_773931
  var valid_773932 = query.getOrDefault("MaxRecords")
  valid_773932 = validateParameter(valid_773932, JInt, required = false, default = nil)
  if valid_773932 != nil:
    section.add "MaxRecords", valid_773932
  var valid_773933 = query.getOrDefault("DBParameterGroupFamily")
  valid_773933 = validateParameter(valid_773933, JString, required = false,
                                 default = nil)
  if valid_773933 != nil:
    section.add "DBParameterGroupFamily", valid_773933
  var valid_773934 = query.getOrDefault("Filters")
  valid_773934 = validateParameter(valid_773934, JArray, required = false,
                                 default = nil)
  if valid_773934 != nil:
    section.add "Filters", valid_773934
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773935 = query.getOrDefault("Action")
  valid_773935 = validateParameter(valid_773935, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_773935 != nil:
    section.add "Action", valid_773935
  var valid_773936 = query.getOrDefault("Marker")
  valid_773936 = validateParameter(valid_773936, JString, required = false,
                                 default = nil)
  if valid_773936 != nil:
    section.add "Marker", valid_773936
  var valid_773937 = query.getOrDefault("EngineVersion")
  valid_773937 = validateParameter(valid_773937, JString, required = false,
                                 default = nil)
  if valid_773937 != nil:
    section.add "EngineVersion", valid_773937
  var valid_773938 = query.getOrDefault("DefaultOnly")
  valid_773938 = validateParameter(valid_773938, JBool, required = false, default = nil)
  if valid_773938 != nil:
    section.add "DefaultOnly", valid_773938
  var valid_773939 = query.getOrDefault("Version")
  valid_773939 = validateParameter(valid_773939, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773939 != nil:
    section.add "Version", valid_773939
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773940 = header.getOrDefault("X-Amz-Date")
  valid_773940 = validateParameter(valid_773940, JString, required = false,
                                 default = nil)
  if valid_773940 != nil:
    section.add "X-Amz-Date", valid_773940
  var valid_773941 = header.getOrDefault("X-Amz-Security-Token")
  valid_773941 = validateParameter(valid_773941, JString, required = false,
                                 default = nil)
  if valid_773941 != nil:
    section.add "X-Amz-Security-Token", valid_773941
  var valid_773942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773942 = validateParameter(valid_773942, JString, required = false,
                                 default = nil)
  if valid_773942 != nil:
    section.add "X-Amz-Content-Sha256", valid_773942
  var valid_773943 = header.getOrDefault("X-Amz-Algorithm")
  valid_773943 = validateParameter(valid_773943, JString, required = false,
                                 default = nil)
  if valid_773943 != nil:
    section.add "X-Amz-Algorithm", valid_773943
  var valid_773944 = header.getOrDefault("X-Amz-Signature")
  valid_773944 = validateParameter(valid_773944, JString, required = false,
                                 default = nil)
  if valid_773944 != nil:
    section.add "X-Amz-Signature", valid_773944
  var valid_773945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773945 = validateParameter(valid_773945, JString, required = false,
                                 default = nil)
  if valid_773945 != nil:
    section.add "X-Amz-SignedHeaders", valid_773945
  var valid_773946 = header.getOrDefault("X-Amz-Credential")
  valid_773946 = validateParameter(valid_773946, JString, required = false,
                                 default = nil)
  if valid_773946 != nil:
    section.add "X-Amz-Credential", valid_773946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773947: Call_GetDescribeDBEngineVersions_773927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773947.validator(path, query, header, formData, body)
  let scheme = call_773947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773947.url(scheme.get, call_773947.host, call_773947.base,
                         call_773947.route, valid.getOrDefault("path"))
  result = hook(call_773947, url, valid)

proc call*(call_773948: Call_GetDescribeDBEngineVersions_773927;
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
  var query_773949 = newJObject()
  add(query_773949, "Engine", newJString(Engine))
  add(query_773949, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_773949, "MaxRecords", newJInt(MaxRecords))
  add(query_773949, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_773949.add "Filters", Filters
  add(query_773949, "Action", newJString(Action))
  add(query_773949, "Marker", newJString(Marker))
  add(query_773949, "EngineVersion", newJString(EngineVersion))
  add(query_773949, "DefaultOnly", newJBool(DefaultOnly))
  add(query_773949, "Version", newJString(Version))
  result = call_773948.call(nil, query_773949, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_773927(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_773928, base: "/",
    url: url_GetDescribeDBEngineVersions_773929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_773993 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBInstances_773995(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBInstances_773994(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773996 = query.getOrDefault("Action")
  valid_773996 = validateParameter(valid_773996, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_773996 != nil:
    section.add "Action", valid_773996
  var valid_773997 = query.getOrDefault("Version")
  valid_773997 = validateParameter(valid_773997, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773997 != nil:
    section.add "Version", valid_773997
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773998 = header.getOrDefault("X-Amz-Date")
  valid_773998 = validateParameter(valid_773998, JString, required = false,
                                 default = nil)
  if valid_773998 != nil:
    section.add "X-Amz-Date", valid_773998
  var valid_773999 = header.getOrDefault("X-Amz-Security-Token")
  valid_773999 = validateParameter(valid_773999, JString, required = false,
                                 default = nil)
  if valid_773999 != nil:
    section.add "X-Amz-Security-Token", valid_773999
  var valid_774000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774000 = validateParameter(valid_774000, JString, required = false,
                                 default = nil)
  if valid_774000 != nil:
    section.add "X-Amz-Content-Sha256", valid_774000
  var valid_774001 = header.getOrDefault("X-Amz-Algorithm")
  valid_774001 = validateParameter(valid_774001, JString, required = false,
                                 default = nil)
  if valid_774001 != nil:
    section.add "X-Amz-Algorithm", valid_774001
  var valid_774002 = header.getOrDefault("X-Amz-Signature")
  valid_774002 = validateParameter(valid_774002, JString, required = false,
                                 default = nil)
  if valid_774002 != nil:
    section.add "X-Amz-Signature", valid_774002
  var valid_774003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774003 = validateParameter(valid_774003, JString, required = false,
                                 default = nil)
  if valid_774003 != nil:
    section.add "X-Amz-SignedHeaders", valid_774003
  var valid_774004 = header.getOrDefault("X-Amz-Credential")
  valid_774004 = validateParameter(valid_774004, JString, required = false,
                                 default = nil)
  if valid_774004 != nil:
    section.add "X-Amz-Credential", valid_774004
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774005 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774005 = validateParameter(valid_774005, JString, required = false,
                                 default = nil)
  if valid_774005 != nil:
    section.add "DBInstanceIdentifier", valid_774005
  var valid_774006 = formData.getOrDefault("Marker")
  valid_774006 = validateParameter(valid_774006, JString, required = false,
                                 default = nil)
  if valid_774006 != nil:
    section.add "Marker", valid_774006
  var valid_774007 = formData.getOrDefault("Filters")
  valid_774007 = validateParameter(valid_774007, JArray, required = false,
                                 default = nil)
  if valid_774007 != nil:
    section.add "Filters", valid_774007
  var valid_774008 = formData.getOrDefault("MaxRecords")
  valid_774008 = validateParameter(valid_774008, JInt, required = false, default = nil)
  if valid_774008 != nil:
    section.add "MaxRecords", valid_774008
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774009: Call_PostDescribeDBInstances_773993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774009.validator(path, query, header, formData, body)
  let scheme = call_774009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774009.url(scheme.get, call_774009.host, call_774009.base,
                         call_774009.route, valid.getOrDefault("path"))
  result = hook(call_774009, url, valid)

proc call*(call_774010: Call_PostDescribeDBInstances_773993;
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
  var query_774011 = newJObject()
  var formData_774012 = newJObject()
  add(formData_774012, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774012, "Marker", newJString(Marker))
  add(query_774011, "Action", newJString(Action))
  if Filters != nil:
    formData_774012.add "Filters", Filters
  add(formData_774012, "MaxRecords", newJInt(MaxRecords))
  add(query_774011, "Version", newJString(Version))
  result = call_774010.call(nil, query_774011, nil, formData_774012, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_773993(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_773994, base: "/",
    url: url_PostDescribeDBInstances_773995, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_773974 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBInstances_773976(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBInstances_773975(path: JsonNode; query: JsonNode;
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
  var valid_773977 = query.getOrDefault("MaxRecords")
  valid_773977 = validateParameter(valid_773977, JInt, required = false, default = nil)
  if valid_773977 != nil:
    section.add "MaxRecords", valid_773977
  var valid_773978 = query.getOrDefault("Filters")
  valid_773978 = validateParameter(valid_773978, JArray, required = false,
                                 default = nil)
  if valid_773978 != nil:
    section.add "Filters", valid_773978
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773979 = query.getOrDefault("Action")
  valid_773979 = validateParameter(valid_773979, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_773979 != nil:
    section.add "Action", valid_773979
  var valid_773980 = query.getOrDefault("Marker")
  valid_773980 = validateParameter(valid_773980, JString, required = false,
                                 default = nil)
  if valid_773980 != nil:
    section.add "Marker", valid_773980
  var valid_773981 = query.getOrDefault("Version")
  valid_773981 = validateParameter(valid_773981, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_773981 != nil:
    section.add "Version", valid_773981
  var valid_773982 = query.getOrDefault("DBInstanceIdentifier")
  valid_773982 = validateParameter(valid_773982, JString, required = false,
                                 default = nil)
  if valid_773982 != nil:
    section.add "DBInstanceIdentifier", valid_773982
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773983 = header.getOrDefault("X-Amz-Date")
  valid_773983 = validateParameter(valid_773983, JString, required = false,
                                 default = nil)
  if valid_773983 != nil:
    section.add "X-Amz-Date", valid_773983
  var valid_773984 = header.getOrDefault("X-Amz-Security-Token")
  valid_773984 = validateParameter(valid_773984, JString, required = false,
                                 default = nil)
  if valid_773984 != nil:
    section.add "X-Amz-Security-Token", valid_773984
  var valid_773985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773985 = validateParameter(valid_773985, JString, required = false,
                                 default = nil)
  if valid_773985 != nil:
    section.add "X-Amz-Content-Sha256", valid_773985
  var valid_773986 = header.getOrDefault("X-Amz-Algorithm")
  valid_773986 = validateParameter(valid_773986, JString, required = false,
                                 default = nil)
  if valid_773986 != nil:
    section.add "X-Amz-Algorithm", valid_773986
  var valid_773987 = header.getOrDefault("X-Amz-Signature")
  valid_773987 = validateParameter(valid_773987, JString, required = false,
                                 default = nil)
  if valid_773987 != nil:
    section.add "X-Amz-Signature", valid_773987
  var valid_773988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773988 = validateParameter(valid_773988, JString, required = false,
                                 default = nil)
  if valid_773988 != nil:
    section.add "X-Amz-SignedHeaders", valid_773988
  var valid_773989 = header.getOrDefault("X-Amz-Credential")
  valid_773989 = validateParameter(valid_773989, JString, required = false,
                                 default = nil)
  if valid_773989 != nil:
    section.add "X-Amz-Credential", valid_773989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773990: Call_GetDescribeDBInstances_773974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_773990.validator(path, query, header, formData, body)
  let scheme = call_773990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773990.url(scheme.get, call_773990.host, call_773990.base,
                         call_773990.route, valid.getOrDefault("path"))
  result = hook(call_773990, url, valid)

proc call*(call_773991: Call_GetDescribeDBInstances_773974; MaxRecords: int = 0;
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
  var query_773992 = newJObject()
  add(query_773992, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_773992.add "Filters", Filters
  add(query_773992, "Action", newJString(Action))
  add(query_773992, "Marker", newJString(Marker))
  add(query_773992, "Version", newJString(Version))
  add(query_773992, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_773991.call(nil, query_773992, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_773974(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_773975, base: "/",
    url: url_GetDescribeDBInstances_773976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_774035 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBLogFiles_774037(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBLogFiles_774036(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774038 = query.getOrDefault("Action")
  valid_774038 = validateParameter(valid_774038, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_774038 != nil:
    section.add "Action", valid_774038
  var valid_774039 = query.getOrDefault("Version")
  valid_774039 = validateParameter(valid_774039, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ## parameters in `formData` object:
  ##   FilenameContains: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FileSize: JInt
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_774047 = formData.getOrDefault("FilenameContains")
  valid_774047 = validateParameter(valid_774047, JString, required = false,
                                 default = nil)
  if valid_774047 != nil:
    section.add "FilenameContains", valid_774047
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774048 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774048 = validateParameter(valid_774048, JString, required = true,
                                 default = nil)
  if valid_774048 != nil:
    section.add "DBInstanceIdentifier", valid_774048
  var valid_774049 = formData.getOrDefault("FileSize")
  valid_774049 = validateParameter(valid_774049, JInt, required = false, default = nil)
  if valid_774049 != nil:
    section.add "FileSize", valid_774049
  var valid_774050 = formData.getOrDefault("Marker")
  valid_774050 = validateParameter(valid_774050, JString, required = false,
                                 default = nil)
  if valid_774050 != nil:
    section.add "Marker", valid_774050
  var valid_774051 = formData.getOrDefault("Filters")
  valid_774051 = validateParameter(valid_774051, JArray, required = false,
                                 default = nil)
  if valid_774051 != nil:
    section.add "Filters", valid_774051
  var valid_774052 = formData.getOrDefault("MaxRecords")
  valid_774052 = validateParameter(valid_774052, JInt, required = false, default = nil)
  if valid_774052 != nil:
    section.add "MaxRecords", valid_774052
  var valid_774053 = formData.getOrDefault("FileLastWritten")
  valid_774053 = validateParameter(valid_774053, JInt, required = false, default = nil)
  if valid_774053 != nil:
    section.add "FileLastWritten", valid_774053
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774054: Call_PostDescribeDBLogFiles_774035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774054.validator(path, query, header, formData, body)
  let scheme = call_774054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774054.url(scheme.get, call_774054.host, call_774054.base,
                         call_774054.route, valid.getOrDefault("path"))
  result = hook(call_774054, url, valid)

proc call*(call_774055: Call_PostDescribeDBLogFiles_774035;
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
  var query_774056 = newJObject()
  var formData_774057 = newJObject()
  add(formData_774057, "FilenameContains", newJString(FilenameContains))
  add(formData_774057, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774057, "FileSize", newJInt(FileSize))
  add(formData_774057, "Marker", newJString(Marker))
  add(query_774056, "Action", newJString(Action))
  if Filters != nil:
    formData_774057.add "Filters", Filters
  add(formData_774057, "MaxRecords", newJInt(MaxRecords))
  add(formData_774057, "FileLastWritten", newJInt(FileLastWritten))
  add(query_774056, "Version", newJString(Version))
  result = call_774055.call(nil, query_774056, nil, formData_774057, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_774035(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_774036, base: "/",
    url: url_PostDescribeDBLogFiles_774037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_774013 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBLogFiles_774015(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBLogFiles_774014(path: JsonNode; query: JsonNode;
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
  var valid_774016 = query.getOrDefault("FileLastWritten")
  valid_774016 = validateParameter(valid_774016, JInt, required = false, default = nil)
  if valid_774016 != nil:
    section.add "FileLastWritten", valid_774016
  var valid_774017 = query.getOrDefault("MaxRecords")
  valid_774017 = validateParameter(valid_774017, JInt, required = false, default = nil)
  if valid_774017 != nil:
    section.add "MaxRecords", valid_774017
  var valid_774018 = query.getOrDefault("FilenameContains")
  valid_774018 = validateParameter(valid_774018, JString, required = false,
                                 default = nil)
  if valid_774018 != nil:
    section.add "FilenameContains", valid_774018
  var valid_774019 = query.getOrDefault("FileSize")
  valid_774019 = validateParameter(valid_774019, JInt, required = false, default = nil)
  if valid_774019 != nil:
    section.add "FileSize", valid_774019
  var valid_774020 = query.getOrDefault("Filters")
  valid_774020 = validateParameter(valid_774020, JArray, required = false,
                                 default = nil)
  if valid_774020 != nil:
    section.add "Filters", valid_774020
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774021 = query.getOrDefault("Action")
  valid_774021 = validateParameter(valid_774021, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_774021 != nil:
    section.add "Action", valid_774021
  var valid_774022 = query.getOrDefault("Marker")
  valid_774022 = validateParameter(valid_774022, JString, required = false,
                                 default = nil)
  if valid_774022 != nil:
    section.add "Marker", valid_774022
  var valid_774023 = query.getOrDefault("Version")
  valid_774023 = validateParameter(valid_774023, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774023 != nil:
    section.add "Version", valid_774023
  var valid_774024 = query.getOrDefault("DBInstanceIdentifier")
  valid_774024 = validateParameter(valid_774024, JString, required = true,
                                 default = nil)
  if valid_774024 != nil:
    section.add "DBInstanceIdentifier", valid_774024
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774025 = header.getOrDefault("X-Amz-Date")
  valid_774025 = validateParameter(valid_774025, JString, required = false,
                                 default = nil)
  if valid_774025 != nil:
    section.add "X-Amz-Date", valid_774025
  var valid_774026 = header.getOrDefault("X-Amz-Security-Token")
  valid_774026 = validateParameter(valid_774026, JString, required = false,
                                 default = nil)
  if valid_774026 != nil:
    section.add "X-Amz-Security-Token", valid_774026
  var valid_774027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774027 = validateParameter(valid_774027, JString, required = false,
                                 default = nil)
  if valid_774027 != nil:
    section.add "X-Amz-Content-Sha256", valid_774027
  var valid_774028 = header.getOrDefault("X-Amz-Algorithm")
  valid_774028 = validateParameter(valid_774028, JString, required = false,
                                 default = nil)
  if valid_774028 != nil:
    section.add "X-Amz-Algorithm", valid_774028
  var valid_774029 = header.getOrDefault("X-Amz-Signature")
  valid_774029 = validateParameter(valid_774029, JString, required = false,
                                 default = nil)
  if valid_774029 != nil:
    section.add "X-Amz-Signature", valid_774029
  var valid_774030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774030 = validateParameter(valid_774030, JString, required = false,
                                 default = nil)
  if valid_774030 != nil:
    section.add "X-Amz-SignedHeaders", valid_774030
  var valid_774031 = header.getOrDefault("X-Amz-Credential")
  valid_774031 = validateParameter(valid_774031, JString, required = false,
                                 default = nil)
  if valid_774031 != nil:
    section.add "X-Amz-Credential", valid_774031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774032: Call_GetDescribeDBLogFiles_774013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774032.validator(path, query, header, formData, body)
  let scheme = call_774032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774032.url(scheme.get, call_774032.host, call_774032.base,
                         call_774032.route, valid.getOrDefault("path"))
  result = hook(call_774032, url, valid)

proc call*(call_774033: Call_GetDescribeDBLogFiles_774013;
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
  var query_774034 = newJObject()
  add(query_774034, "FileLastWritten", newJInt(FileLastWritten))
  add(query_774034, "MaxRecords", newJInt(MaxRecords))
  add(query_774034, "FilenameContains", newJString(FilenameContains))
  add(query_774034, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_774034.add "Filters", Filters
  add(query_774034, "Action", newJString(Action))
  add(query_774034, "Marker", newJString(Marker))
  add(query_774034, "Version", newJString(Version))
  add(query_774034, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_774033.call(nil, query_774034, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_774013(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_774014, base: "/",
    url: url_GetDescribeDBLogFiles_774015, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_774077 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBParameterGroups_774079(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameterGroups_774078(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774080 = query.getOrDefault("Action")
  valid_774080 = validateParameter(valid_774080, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_774080 != nil:
    section.add "Action", valid_774080
  var valid_774081 = query.getOrDefault("Version")
  valid_774081 = validateParameter(valid_774081, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774081 != nil:
    section.add "Version", valid_774081
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774082 = header.getOrDefault("X-Amz-Date")
  valid_774082 = validateParameter(valid_774082, JString, required = false,
                                 default = nil)
  if valid_774082 != nil:
    section.add "X-Amz-Date", valid_774082
  var valid_774083 = header.getOrDefault("X-Amz-Security-Token")
  valid_774083 = validateParameter(valid_774083, JString, required = false,
                                 default = nil)
  if valid_774083 != nil:
    section.add "X-Amz-Security-Token", valid_774083
  var valid_774084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774084 = validateParameter(valid_774084, JString, required = false,
                                 default = nil)
  if valid_774084 != nil:
    section.add "X-Amz-Content-Sha256", valid_774084
  var valid_774085 = header.getOrDefault("X-Amz-Algorithm")
  valid_774085 = validateParameter(valid_774085, JString, required = false,
                                 default = nil)
  if valid_774085 != nil:
    section.add "X-Amz-Algorithm", valid_774085
  var valid_774086 = header.getOrDefault("X-Amz-Signature")
  valid_774086 = validateParameter(valid_774086, JString, required = false,
                                 default = nil)
  if valid_774086 != nil:
    section.add "X-Amz-Signature", valid_774086
  var valid_774087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774087 = validateParameter(valid_774087, JString, required = false,
                                 default = nil)
  if valid_774087 != nil:
    section.add "X-Amz-SignedHeaders", valid_774087
  var valid_774088 = header.getOrDefault("X-Amz-Credential")
  valid_774088 = validateParameter(valid_774088, JString, required = false,
                                 default = nil)
  if valid_774088 != nil:
    section.add "X-Amz-Credential", valid_774088
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774089 = formData.getOrDefault("DBParameterGroupName")
  valid_774089 = validateParameter(valid_774089, JString, required = false,
                                 default = nil)
  if valid_774089 != nil:
    section.add "DBParameterGroupName", valid_774089
  var valid_774090 = formData.getOrDefault("Marker")
  valid_774090 = validateParameter(valid_774090, JString, required = false,
                                 default = nil)
  if valid_774090 != nil:
    section.add "Marker", valid_774090
  var valid_774091 = formData.getOrDefault("Filters")
  valid_774091 = validateParameter(valid_774091, JArray, required = false,
                                 default = nil)
  if valid_774091 != nil:
    section.add "Filters", valid_774091
  var valid_774092 = formData.getOrDefault("MaxRecords")
  valid_774092 = validateParameter(valid_774092, JInt, required = false, default = nil)
  if valid_774092 != nil:
    section.add "MaxRecords", valid_774092
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774093: Call_PostDescribeDBParameterGroups_774077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774093.validator(path, query, header, formData, body)
  let scheme = call_774093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774093.url(scheme.get, call_774093.host, call_774093.base,
                         call_774093.route, valid.getOrDefault("path"))
  result = hook(call_774093, url, valid)

proc call*(call_774094: Call_PostDescribeDBParameterGroups_774077;
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
  var query_774095 = newJObject()
  var formData_774096 = newJObject()
  add(formData_774096, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_774096, "Marker", newJString(Marker))
  add(query_774095, "Action", newJString(Action))
  if Filters != nil:
    formData_774096.add "Filters", Filters
  add(formData_774096, "MaxRecords", newJInt(MaxRecords))
  add(query_774095, "Version", newJString(Version))
  result = call_774094.call(nil, query_774095, nil, formData_774096, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_774077(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_774078, base: "/",
    url: url_PostDescribeDBParameterGroups_774079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_774058 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBParameterGroups_774060(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameterGroups_774059(path: JsonNode; query: JsonNode;
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
  var valid_774061 = query.getOrDefault("MaxRecords")
  valid_774061 = validateParameter(valid_774061, JInt, required = false, default = nil)
  if valid_774061 != nil:
    section.add "MaxRecords", valid_774061
  var valid_774062 = query.getOrDefault("Filters")
  valid_774062 = validateParameter(valid_774062, JArray, required = false,
                                 default = nil)
  if valid_774062 != nil:
    section.add "Filters", valid_774062
  var valid_774063 = query.getOrDefault("DBParameterGroupName")
  valid_774063 = validateParameter(valid_774063, JString, required = false,
                                 default = nil)
  if valid_774063 != nil:
    section.add "DBParameterGroupName", valid_774063
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774064 = query.getOrDefault("Action")
  valid_774064 = validateParameter(valid_774064, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_774064 != nil:
    section.add "Action", valid_774064
  var valid_774065 = query.getOrDefault("Marker")
  valid_774065 = validateParameter(valid_774065, JString, required = false,
                                 default = nil)
  if valid_774065 != nil:
    section.add "Marker", valid_774065
  var valid_774066 = query.getOrDefault("Version")
  valid_774066 = validateParameter(valid_774066, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774066 != nil:
    section.add "Version", valid_774066
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774067 = header.getOrDefault("X-Amz-Date")
  valid_774067 = validateParameter(valid_774067, JString, required = false,
                                 default = nil)
  if valid_774067 != nil:
    section.add "X-Amz-Date", valid_774067
  var valid_774068 = header.getOrDefault("X-Amz-Security-Token")
  valid_774068 = validateParameter(valid_774068, JString, required = false,
                                 default = nil)
  if valid_774068 != nil:
    section.add "X-Amz-Security-Token", valid_774068
  var valid_774069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774069 = validateParameter(valid_774069, JString, required = false,
                                 default = nil)
  if valid_774069 != nil:
    section.add "X-Amz-Content-Sha256", valid_774069
  var valid_774070 = header.getOrDefault("X-Amz-Algorithm")
  valid_774070 = validateParameter(valid_774070, JString, required = false,
                                 default = nil)
  if valid_774070 != nil:
    section.add "X-Amz-Algorithm", valid_774070
  var valid_774071 = header.getOrDefault("X-Amz-Signature")
  valid_774071 = validateParameter(valid_774071, JString, required = false,
                                 default = nil)
  if valid_774071 != nil:
    section.add "X-Amz-Signature", valid_774071
  var valid_774072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774072 = validateParameter(valid_774072, JString, required = false,
                                 default = nil)
  if valid_774072 != nil:
    section.add "X-Amz-SignedHeaders", valid_774072
  var valid_774073 = header.getOrDefault("X-Amz-Credential")
  valid_774073 = validateParameter(valid_774073, JString, required = false,
                                 default = nil)
  if valid_774073 != nil:
    section.add "X-Amz-Credential", valid_774073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774074: Call_GetDescribeDBParameterGroups_774058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774074.validator(path, query, header, formData, body)
  let scheme = call_774074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774074.url(scheme.get, call_774074.host, call_774074.base,
                         call_774074.route, valid.getOrDefault("path"))
  result = hook(call_774074, url, valid)

proc call*(call_774075: Call_GetDescribeDBParameterGroups_774058;
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
  var query_774076 = newJObject()
  add(query_774076, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774076.add "Filters", Filters
  add(query_774076, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_774076, "Action", newJString(Action))
  add(query_774076, "Marker", newJString(Marker))
  add(query_774076, "Version", newJString(Version))
  result = call_774075.call(nil, query_774076, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_774058(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_774059, base: "/",
    url: url_GetDescribeDBParameterGroups_774060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_774117 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBParameters_774119(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameters_774118(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774120 = query.getOrDefault("Action")
  valid_774120 = validateParameter(valid_774120, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_774120 != nil:
    section.add "Action", valid_774120
  var valid_774121 = query.getOrDefault("Version")
  valid_774121 = validateParameter(valid_774121, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774121 != nil:
    section.add "Version", valid_774121
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774122 = header.getOrDefault("X-Amz-Date")
  valid_774122 = validateParameter(valid_774122, JString, required = false,
                                 default = nil)
  if valid_774122 != nil:
    section.add "X-Amz-Date", valid_774122
  var valid_774123 = header.getOrDefault("X-Amz-Security-Token")
  valid_774123 = validateParameter(valid_774123, JString, required = false,
                                 default = nil)
  if valid_774123 != nil:
    section.add "X-Amz-Security-Token", valid_774123
  var valid_774124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774124 = validateParameter(valid_774124, JString, required = false,
                                 default = nil)
  if valid_774124 != nil:
    section.add "X-Amz-Content-Sha256", valid_774124
  var valid_774125 = header.getOrDefault("X-Amz-Algorithm")
  valid_774125 = validateParameter(valid_774125, JString, required = false,
                                 default = nil)
  if valid_774125 != nil:
    section.add "X-Amz-Algorithm", valid_774125
  var valid_774126 = header.getOrDefault("X-Amz-Signature")
  valid_774126 = validateParameter(valid_774126, JString, required = false,
                                 default = nil)
  if valid_774126 != nil:
    section.add "X-Amz-Signature", valid_774126
  var valid_774127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774127 = validateParameter(valid_774127, JString, required = false,
                                 default = nil)
  if valid_774127 != nil:
    section.add "X-Amz-SignedHeaders", valid_774127
  var valid_774128 = header.getOrDefault("X-Amz-Credential")
  valid_774128 = validateParameter(valid_774128, JString, required = false,
                                 default = nil)
  if valid_774128 != nil:
    section.add "X-Amz-Credential", valid_774128
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_774129 = formData.getOrDefault("DBParameterGroupName")
  valid_774129 = validateParameter(valid_774129, JString, required = true,
                                 default = nil)
  if valid_774129 != nil:
    section.add "DBParameterGroupName", valid_774129
  var valid_774130 = formData.getOrDefault("Marker")
  valid_774130 = validateParameter(valid_774130, JString, required = false,
                                 default = nil)
  if valid_774130 != nil:
    section.add "Marker", valid_774130
  var valid_774131 = formData.getOrDefault("Filters")
  valid_774131 = validateParameter(valid_774131, JArray, required = false,
                                 default = nil)
  if valid_774131 != nil:
    section.add "Filters", valid_774131
  var valid_774132 = formData.getOrDefault("MaxRecords")
  valid_774132 = validateParameter(valid_774132, JInt, required = false, default = nil)
  if valid_774132 != nil:
    section.add "MaxRecords", valid_774132
  var valid_774133 = formData.getOrDefault("Source")
  valid_774133 = validateParameter(valid_774133, JString, required = false,
                                 default = nil)
  if valid_774133 != nil:
    section.add "Source", valid_774133
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774134: Call_PostDescribeDBParameters_774117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774134.validator(path, query, header, formData, body)
  let scheme = call_774134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774134.url(scheme.get, call_774134.host, call_774134.base,
                         call_774134.route, valid.getOrDefault("path"))
  result = hook(call_774134, url, valid)

proc call*(call_774135: Call_PostDescribeDBParameters_774117;
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
  var query_774136 = newJObject()
  var formData_774137 = newJObject()
  add(formData_774137, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_774137, "Marker", newJString(Marker))
  add(query_774136, "Action", newJString(Action))
  if Filters != nil:
    formData_774137.add "Filters", Filters
  add(formData_774137, "MaxRecords", newJInt(MaxRecords))
  add(query_774136, "Version", newJString(Version))
  add(formData_774137, "Source", newJString(Source))
  result = call_774135.call(nil, query_774136, nil, formData_774137, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_774117(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_774118, base: "/",
    url: url_PostDescribeDBParameters_774119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_774097 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBParameters_774099(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameters_774098(path: JsonNode; query: JsonNode;
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
  var valid_774100 = query.getOrDefault("MaxRecords")
  valid_774100 = validateParameter(valid_774100, JInt, required = false, default = nil)
  if valid_774100 != nil:
    section.add "MaxRecords", valid_774100
  var valid_774101 = query.getOrDefault("Filters")
  valid_774101 = validateParameter(valid_774101, JArray, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "Filters", valid_774101
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_774102 = query.getOrDefault("DBParameterGroupName")
  valid_774102 = validateParameter(valid_774102, JString, required = true,
                                 default = nil)
  if valid_774102 != nil:
    section.add "DBParameterGroupName", valid_774102
  var valid_774103 = query.getOrDefault("Action")
  valid_774103 = validateParameter(valid_774103, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_774103 != nil:
    section.add "Action", valid_774103
  var valid_774104 = query.getOrDefault("Marker")
  valid_774104 = validateParameter(valid_774104, JString, required = false,
                                 default = nil)
  if valid_774104 != nil:
    section.add "Marker", valid_774104
  var valid_774105 = query.getOrDefault("Source")
  valid_774105 = validateParameter(valid_774105, JString, required = false,
                                 default = nil)
  if valid_774105 != nil:
    section.add "Source", valid_774105
  var valid_774106 = query.getOrDefault("Version")
  valid_774106 = validateParameter(valid_774106, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774106 != nil:
    section.add "Version", valid_774106
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774107 = header.getOrDefault("X-Amz-Date")
  valid_774107 = validateParameter(valid_774107, JString, required = false,
                                 default = nil)
  if valid_774107 != nil:
    section.add "X-Amz-Date", valid_774107
  var valid_774108 = header.getOrDefault("X-Amz-Security-Token")
  valid_774108 = validateParameter(valid_774108, JString, required = false,
                                 default = nil)
  if valid_774108 != nil:
    section.add "X-Amz-Security-Token", valid_774108
  var valid_774109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774109 = validateParameter(valid_774109, JString, required = false,
                                 default = nil)
  if valid_774109 != nil:
    section.add "X-Amz-Content-Sha256", valid_774109
  var valid_774110 = header.getOrDefault("X-Amz-Algorithm")
  valid_774110 = validateParameter(valid_774110, JString, required = false,
                                 default = nil)
  if valid_774110 != nil:
    section.add "X-Amz-Algorithm", valid_774110
  var valid_774111 = header.getOrDefault("X-Amz-Signature")
  valid_774111 = validateParameter(valid_774111, JString, required = false,
                                 default = nil)
  if valid_774111 != nil:
    section.add "X-Amz-Signature", valid_774111
  var valid_774112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774112 = validateParameter(valid_774112, JString, required = false,
                                 default = nil)
  if valid_774112 != nil:
    section.add "X-Amz-SignedHeaders", valid_774112
  var valid_774113 = header.getOrDefault("X-Amz-Credential")
  valid_774113 = validateParameter(valid_774113, JString, required = false,
                                 default = nil)
  if valid_774113 != nil:
    section.add "X-Amz-Credential", valid_774113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774114: Call_GetDescribeDBParameters_774097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774114.validator(path, query, header, formData, body)
  let scheme = call_774114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774114.url(scheme.get, call_774114.host, call_774114.base,
                         call_774114.route, valid.getOrDefault("path"))
  result = hook(call_774114, url, valid)

proc call*(call_774115: Call_GetDescribeDBParameters_774097;
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
  var query_774116 = newJObject()
  add(query_774116, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774116.add "Filters", Filters
  add(query_774116, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_774116, "Action", newJString(Action))
  add(query_774116, "Marker", newJString(Marker))
  add(query_774116, "Source", newJString(Source))
  add(query_774116, "Version", newJString(Version))
  result = call_774115.call(nil, query_774116, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_774097(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_774098, base: "/",
    url: url_GetDescribeDBParameters_774099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_774157 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBSecurityGroups_774159(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSecurityGroups_774158(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774160 = query.getOrDefault("Action")
  valid_774160 = validateParameter(valid_774160, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_774160 != nil:
    section.add "Action", valid_774160
  var valid_774161 = query.getOrDefault("Version")
  valid_774161 = validateParameter(valid_774161, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774161 != nil:
    section.add "Version", valid_774161
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774162 = header.getOrDefault("X-Amz-Date")
  valid_774162 = validateParameter(valid_774162, JString, required = false,
                                 default = nil)
  if valid_774162 != nil:
    section.add "X-Amz-Date", valid_774162
  var valid_774163 = header.getOrDefault("X-Amz-Security-Token")
  valid_774163 = validateParameter(valid_774163, JString, required = false,
                                 default = nil)
  if valid_774163 != nil:
    section.add "X-Amz-Security-Token", valid_774163
  var valid_774164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774164 = validateParameter(valid_774164, JString, required = false,
                                 default = nil)
  if valid_774164 != nil:
    section.add "X-Amz-Content-Sha256", valid_774164
  var valid_774165 = header.getOrDefault("X-Amz-Algorithm")
  valid_774165 = validateParameter(valid_774165, JString, required = false,
                                 default = nil)
  if valid_774165 != nil:
    section.add "X-Amz-Algorithm", valid_774165
  var valid_774166 = header.getOrDefault("X-Amz-Signature")
  valid_774166 = validateParameter(valid_774166, JString, required = false,
                                 default = nil)
  if valid_774166 != nil:
    section.add "X-Amz-Signature", valid_774166
  var valid_774167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774167 = validateParameter(valid_774167, JString, required = false,
                                 default = nil)
  if valid_774167 != nil:
    section.add "X-Amz-SignedHeaders", valid_774167
  var valid_774168 = header.getOrDefault("X-Amz-Credential")
  valid_774168 = validateParameter(valid_774168, JString, required = false,
                                 default = nil)
  if valid_774168 != nil:
    section.add "X-Amz-Credential", valid_774168
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774169 = formData.getOrDefault("DBSecurityGroupName")
  valid_774169 = validateParameter(valid_774169, JString, required = false,
                                 default = nil)
  if valid_774169 != nil:
    section.add "DBSecurityGroupName", valid_774169
  var valid_774170 = formData.getOrDefault("Marker")
  valid_774170 = validateParameter(valid_774170, JString, required = false,
                                 default = nil)
  if valid_774170 != nil:
    section.add "Marker", valid_774170
  var valid_774171 = formData.getOrDefault("Filters")
  valid_774171 = validateParameter(valid_774171, JArray, required = false,
                                 default = nil)
  if valid_774171 != nil:
    section.add "Filters", valid_774171
  var valid_774172 = formData.getOrDefault("MaxRecords")
  valid_774172 = validateParameter(valid_774172, JInt, required = false, default = nil)
  if valid_774172 != nil:
    section.add "MaxRecords", valid_774172
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774173: Call_PostDescribeDBSecurityGroups_774157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774173.validator(path, query, header, formData, body)
  let scheme = call_774173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774173.url(scheme.get, call_774173.host, call_774173.base,
                         call_774173.route, valid.getOrDefault("path"))
  result = hook(call_774173, url, valid)

proc call*(call_774174: Call_PostDescribeDBSecurityGroups_774157;
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
  var query_774175 = newJObject()
  var formData_774176 = newJObject()
  add(formData_774176, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_774176, "Marker", newJString(Marker))
  add(query_774175, "Action", newJString(Action))
  if Filters != nil:
    formData_774176.add "Filters", Filters
  add(formData_774176, "MaxRecords", newJInt(MaxRecords))
  add(query_774175, "Version", newJString(Version))
  result = call_774174.call(nil, query_774175, nil, formData_774176, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_774157(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_774158, base: "/",
    url: url_PostDescribeDBSecurityGroups_774159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_774138 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBSecurityGroups_774140(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSecurityGroups_774139(path: JsonNode; query: JsonNode;
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
  var valid_774141 = query.getOrDefault("MaxRecords")
  valid_774141 = validateParameter(valid_774141, JInt, required = false, default = nil)
  if valid_774141 != nil:
    section.add "MaxRecords", valid_774141
  var valid_774142 = query.getOrDefault("DBSecurityGroupName")
  valid_774142 = validateParameter(valid_774142, JString, required = false,
                                 default = nil)
  if valid_774142 != nil:
    section.add "DBSecurityGroupName", valid_774142
  var valid_774143 = query.getOrDefault("Filters")
  valid_774143 = validateParameter(valid_774143, JArray, required = false,
                                 default = nil)
  if valid_774143 != nil:
    section.add "Filters", valid_774143
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774144 = query.getOrDefault("Action")
  valid_774144 = validateParameter(valid_774144, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_774144 != nil:
    section.add "Action", valid_774144
  var valid_774145 = query.getOrDefault("Marker")
  valid_774145 = validateParameter(valid_774145, JString, required = false,
                                 default = nil)
  if valid_774145 != nil:
    section.add "Marker", valid_774145
  var valid_774146 = query.getOrDefault("Version")
  valid_774146 = validateParameter(valid_774146, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774146 != nil:
    section.add "Version", valid_774146
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774147 = header.getOrDefault("X-Amz-Date")
  valid_774147 = validateParameter(valid_774147, JString, required = false,
                                 default = nil)
  if valid_774147 != nil:
    section.add "X-Amz-Date", valid_774147
  var valid_774148 = header.getOrDefault("X-Amz-Security-Token")
  valid_774148 = validateParameter(valid_774148, JString, required = false,
                                 default = nil)
  if valid_774148 != nil:
    section.add "X-Amz-Security-Token", valid_774148
  var valid_774149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774149 = validateParameter(valid_774149, JString, required = false,
                                 default = nil)
  if valid_774149 != nil:
    section.add "X-Amz-Content-Sha256", valid_774149
  var valid_774150 = header.getOrDefault("X-Amz-Algorithm")
  valid_774150 = validateParameter(valid_774150, JString, required = false,
                                 default = nil)
  if valid_774150 != nil:
    section.add "X-Amz-Algorithm", valid_774150
  var valid_774151 = header.getOrDefault("X-Amz-Signature")
  valid_774151 = validateParameter(valid_774151, JString, required = false,
                                 default = nil)
  if valid_774151 != nil:
    section.add "X-Amz-Signature", valid_774151
  var valid_774152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774152 = validateParameter(valid_774152, JString, required = false,
                                 default = nil)
  if valid_774152 != nil:
    section.add "X-Amz-SignedHeaders", valid_774152
  var valid_774153 = header.getOrDefault("X-Amz-Credential")
  valid_774153 = validateParameter(valid_774153, JString, required = false,
                                 default = nil)
  if valid_774153 != nil:
    section.add "X-Amz-Credential", valid_774153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774154: Call_GetDescribeDBSecurityGroups_774138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774154.validator(path, query, header, formData, body)
  let scheme = call_774154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774154.url(scheme.get, call_774154.host, call_774154.base,
                         call_774154.route, valid.getOrDefault("path"))
  result = hook(call_774154, url, valid)

proc call*(call_774155: Call_GetDescribeDBSecurityGroups_774138;
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
  var query_774156 = newJObject()
  add(query_774156, "MaxRecords", newJInt(MaxRecords))
  add(query_774156, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_774156.add "Filters", Filters
  add(query_774156, "Action", newJString(Action))
  add(query_774156, "Marker", newJString(Marker))
  add(query_774156, "Version", newJString(Version))
  result = call_774155.call(nil, query_774156, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_774138(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_774139, base: "/",
    url: url_GetDescribeDBSecurityGroups_774140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_774198 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBSnapshots_774200(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSnapshots_774199(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_774201 = validateParameter(valid_774201, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_774201 != nil:
    section.add "Action", valid_774201
  var valid_774202 = query.getOrDefault("Version")
  valid_774202 = validateParameter(valid_774202, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774210 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774210 = validateParameter(valid_774210, JString, required = false,
                                 default = nil)
  if valid_774210 != nil:
    section.add "DBInstanceIdentifier", valid_774210
  var valid_774211 = formData.getOrDefault("SnapshotType")
  valid_774211 = validateParameter(valid_774211, JString, required = false,
                                 default = nil)
  if valid_774211 != nil:
    section.add "SnapshotType", valid_774211
  var valid_774212 = formData.getOrDefault("Marker")
  valid_774212 = validateParameter(valid_774212, JString, required = false,
                                 default = nil)
  if valid_774212 != nil:
    section.add "Marker", valid_774212
  var valid_774213 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_774213 = validateParameter(valid_774213, JString, required = false,
                                 default = nil)
  if valid_774213 != nil:
    section.add "DBSnapshotIdentifier", valid_774213
  var valid_774214 = formData.getOrDefault("Filters")
  valid_774214 = validateParameter(valid_774214, JArray, required = false,
                                 default = nil)
  if valid_774214 != nil:
    section.add "Filters", valid_774214
  var valid_774215 = formData.getOrDefault("MaxRecords")
  valid_774215 = validateParameter(valid_774215, JInt, required = false, default = nil)
  if valid_774215 != nil:
    section.add "MaxRecords", valid_774215
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774216: Call_PostDescribeDBSnapshots_774198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774216.validator(path, query, header, formData, body)
  let scheme = call_774216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774216.url(scheme.get, call_774216.host, call_774216.base,
                         call_774216.route, valid.getOrDefault("path"))
  result = hook(call_774216, url, valid)

proc call*(call_774217: Call_PostDescribeDBSnapshots_774198;
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
  var query_774218 = newJObject()
  var formData_774219 = newJObject()
  add(formData_774219, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774219, "SnapshotType", newJString(SnapshotType))
  add(formData_774219, "Marker", newJString(Marker))
  add(formData_774219, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_774218, "Action", newJString(Action))
  if Filters != nil:
    formData_774219.add "Filters", Filters
  add(formData_774219, "MaxRecords", newJInt(MaxRecords))
  add(query_774218, "Version", newJString(Version))
  result = call_774217.call(nil, query_774218, nil, formData_774219, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_774198(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_774199, base: "/",
    url: url_PostDescribeDBSnapshots_774200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_774177 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBSnapshots_774179(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSnapshots_774178(path: JsonNode; query: JsonNode;
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
  var valid_774180 = query.getOrDefault("MaxRecords")
  valid_774180 = validateParameter(valid_774180, JInt, required = false, default = nil)
  if valid_774180 != nil:
    section.add "MaxRecords", valid_774180
  var valid_774181 = query.getOrDefault("Filters")
  valid_774181 = validateParameter(valid_774181, JArray, required = false,
                                 default = nil)
  if valid_774181 != nil:
    section.add "Filters", valid_774181
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774182 = query.getOrDefault("Action")
  valid_774182 = validateParameter(valid_774182, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_774182 != nil:
    section.add "Action", valid_774182
  var valid_774183 = query.getOrDefault("Marker")
  valid_774183 = validateParameter(valid_774183, JString, required = false,
                                 default = nil)
  if valid_774183 != nil:
    section.add "Marker", valid_774183
  var valid_774184 = query.getOrDefault("SnapshotType")
  valid_774184 = validateParameter(valid_774184, JString, required = false,
                                 default = nil)
  if valid_774184 != nil:
    section.add "SnapshotType", valid_774184
  var valid_774185 = query.getOrDefault("Version")
  valid_774185 = validateParameter(valid_774185, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774185 != nil:
    section.add "Version", valid_774185
  var valid_774186 = query.getOrDefault("DBInstanceIdentifier")
  valid_774186 = validateParameter(valid_774186, JString, required = false,
                                 default = nil)
  if valid_774186 != nil:
    section.add "DBInstanceIdentifier", valid_774186
  var valid_774187 = query.getOrDefault("DBSnapshotIdentifier")
  valid_774187 = validateParameter(valid_774187, JString, required = false,
                                 default = nil)
  if valid_774187 != nil:
    section.add "DBSnapshotIdentifier", valid_774187
  result.add "query", section
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

proc call*(call_774195: Call_GetDescribeDBSnapshots_774177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774195.validator(path, query, header, formData, body)
  let scheme = call_774195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774195.url(scheme.get, call_774195.host, call_774195.base,
                         call_774195.route, valid.getOrDefault("path"))
  result = hook(call_774195, url, valid)

proc call*(call_774196: Call_GetDescribeDBSnapshots_774177; MaxRecords: int = 0;
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
  var query_774197 = newJObject()
  add(query_774197, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774197.add "Filters", Filters
  add(query_774197, "Action", newJString(Action))
  add(query_774197, "Marker", newJString(Marker))
  add(query_774197, "SnapshotType", newJString(SnapshotType))
  add(query_774197, "Version", newJString(Version))
  add(query_774197, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_774197, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_774196.call(nil, query_774197, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_774177(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_774178, base: "/",
    url: url_GetDescribeDBSnapshots_774179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_774239 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBSubnetGroups_774241(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSubnetGroups_774240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774242 = query.getOrDefault("Action")
  valid_774242 = validateParameter(valid_774242, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_774242 != nil:
    section.add "Action", valid_774242
  var valid_774243 = query.getOrDefault("Version")
  valid_774243 = validateParameter(valid_774243, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774243 != nil:
    section.add "Version", valid_774243
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774244 = header.getOrDefault("X-Amz-Date")
  valid_774244 = validateParameter(valid_774244, JString, required = false,
                                 default = nil)
  if valid_774244 != nil:
    section.add "X-Amz-Date", valid_774244
  var valid_774245 = header.getOrDefault("X-Amz-Security-Token")
  valid_774245 = validateParameter(valid_774245, JString, required = false,
                                 default = nil)
  if valid_774245 != nil:
    section.add "X-Amz-Security-Token", valid_774245
  var valid_774246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774246 = validateParameter(valid_774246, JString, required = false,
                                 default = nil)
  if valid_774246 != nil:
    section.add "X-Amz-Content-Sha256", valid_774246
  var valid_774247 = header.getOrDefault("X-Amz-Algorithm")
  valid_774247 = validateParameter(valid_774247, JString, required = false,
                                 default = nil)
  if valid_774247 != nil:
    section.add "X-Amz-Algorithm", valid_774247
  var valid_774248 = header.getOrDefault("X-Amz-Signature")
  valid_774248 = validateParameter(valid_774248, JString, required = false,
                                 default = nil)
  if valid_774248 != nil:
    section.add "X-Amz-Signature", valid_774248
  var valid_774249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774249 = validateParameter(valid_774249, JString, required = false,
                                 default = nil)
  if valid_774249 != nil:
    section.add "X-Amz-SignedHeaders", valid_774249
  var valid_774250 = header.getOrDefault("X-Amz-Credential")
  valid_774250 = validateParameter(valid_774250, JString, required = false,
                                 default = nil)
  if valid_774250 != nil:
    section.add "X-Amz-Credential", valid_774250
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774251 = formData.getOrDefault("DBSubnetGroupName")
  valid_774251 = validateParameter(valid_774251, JString, required = false,
                                 default = nil)
  if valid_774251 != nil:
    section.add "DBSubnetGroupName", valid_774251
  var valid_774252 = formData.getOrDefault("Marker")
  valid_774252 = validateParameter(valid_774252, JString, required = false,
                                 default = nil)
  if valid_774252 != nil:
    section.add "Marker", valid_774252
  var valid_774253 = formData.getOrDefault("Filters")
  valid_774253 = validateParameter(valid_774253, JArray, required = false,
                                 default = nil)
  if valid_774253 != nil:
    section.add "Filters", valid_774253
  var valid_774254 = formData.getOrDefault("MaxRecords")
  valid_774254 = validateParameter(valid_774254, JInt, required = false, default = nil)
  if valid_774254 != nil:
    section.add "MaxRecords", valid_774254
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774255: Call_PostDescribeDBSubnetGroups_774239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774255.validator(path, query, header, formData, body)
  let scheme = call_774255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774255.url(scheme.get, call_774255.host, call_774255.base,
                         call_774255.route, valid.getOrDefault("path"))
  result = hook(call_774255, url, valid)

proc call*(call_774256: Call_PostDescribeDBSubnetGroups_774239;
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
  var query_774257 = newJObject()
  var formData_774258 = newJObject()
  add(formData_774258, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_774258, "Marker", newJString(Marker))
  add(query_774257, "Action", newJString(Action))
  if Filters != nil:
    formData_774258.add "Filters", Filters
  add(formData_774258, "MaxRecords", newJInt(MaxRecords))
  add(query_774257, "Version", newJString(Version))
  result = call_774256.call(nil, query_774257, nil, formData_774258, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_774239(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_774240, base: "/",
    url: url_PostDescribeDBSubnetGroups_774241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_774220 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBSubnetGroups_774222(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSubnetGroups_774221(path: JsonNode; query: JsonNode;
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
  var valid_774223 = query.getOrDefault("MaxRecords")
  valid_774223 = validateParameter(valid_774223, JInt, required = false, default = nil)
  if valid_774223 != nil:
    section.add "MaxRecords", valid_774223
  var valid_774224 = query.getOrDefault("Filters")
  valid_774224 = validateParameter(valid_774224, JArray, required = false,
                                 default = nil)
  if valid_774224 != nil:
    section.add "Filters", valid_774224
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774225 = query.getOrDefault("Action")
  valid_774225 = validateParameter(valid_774225, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_774225 != nil:
    section.add "Action", valid_774225
  var valid_774226 = query.getOrDefault("Marker")
  valid_774226 = validateParameter(valid_774226, JString, required = false,
                                 default = nil)
  if valid_774226 != nil:
    section.add "Marker", valid_774226
  var valid_774227 = query.getOrDefault("DBSubnetGroupName")
  valid_774227 = validateParameter(valid_774227, JString, required = false,
                                 default = nil)
  if valid_774227 != nil:
    section.add "DBSubnetGroupName", valid_774227
  var valid_774228 = query.getOrDefault("Version")
  valid_774228 = validateParameter(valid_774228, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774228 != nil:
    section.add "Version", valid_774228
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774229 = header.getOrDefault("X-Amz-Date")
  valid_774229 = validateParameter(valid_774229, JString, required = false,
                                 default = nil)
  if valid_774229 != nil:
    section.add "X-Amz-Date", valid_774229
  var valid_774230 = header.getOrDefault("X-Amz-Security-Token")
  valid_774230 = validateParameter(valid_774230, JString, required = false,
                                 default = nil)
  if valid_774230 != nil:
    section.add "X-Amz-Security-Token", valid_774230
  var valid_774231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774231 = validateParameter(valid_774231, JString, required = false,
                                 default = nil)
  if valid_774231 != nil:
    section.add "X-Amz-Content-Sha256", valid_774231
  var valid_774232 = header.getOrDefault("X-Amz-Algorithm")
  valid_774232 = validateParameter(valid_774232, JString, required = false,
                                 default = nil)
  if valid_774232 != nil:
    section.add "X-Amz-Algorithm", valid_774232
  var valid_774233 = header.getOrDefault("X-Amz-Signature")
  valid_774233 = validateParameter(valid_774233, JString, required = false,
                                 default = nil)
  if valid_774233 != nil:
    section.add "X-Amz-Signature", valid_774233
  var valid_774234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774234 = validateParameter(valid_774234, JString, required = false,
                                 default = nil)
  if valid_774234 != nil:
    section.add "X-Amz-SignedHeaders", valid_774234
  var valid_774235 = header.getOrDefault("X-Amz-Credential")
  valid_774235 = validateParameter(valid_774235, JString, required = false,
                                 default = nil)
  if valid_774235 != nil:
    section.add "X-Amz-Credential", valid_774235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774236: Call_GetDescribeDBSubnetGroups_774220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774236.validator(path, query, header, formData, body)
  let scheme = call_774236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774236.url(scheme.get, call_774236.host, call_774236.base,
                         call_774236.route, valid.getOrDefault("path"))
  result = hook(call_774236, url, valid)

proc call*(call_774237: Call_GetDescribeDBSubnetGroups_774220; MaxRecords: int = 0;
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
  var query_774238 = newJObject()
  add(query_774238, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774238.add "Filters", Filters
  add(query_774238, "Action", newJString(Action))
  add(query_774238, "Marker", newJString(Marker))
  add(query_774238, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_774238, "Version", newJString(Version))
  result = call_774237.call(nil, query_774238, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_774220(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_774221, base: "/",
    url: url_GetDescribeDBSubnetGroups_774222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_774278 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEngineDefaultParameters_774280(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEngineDefaultParameters_774279(path: JsonNode;
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
  var valid_774281 = query.getOrDefault("Action")
  valid_774281 = validateParameter(valid_774281, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_774281 != nil:
    section.add "Action", valid_774281
  var valid_774282 = query.getOrDefault("Version")
  valid_774282 = validateParameter(valid_774282, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774282 != nil:
    section.add "Version", valid_774282
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774283 = header.getOrDefault("X-Amz-Date")
  valid_774283 = validateParameter(valid_774283, JString, required = false,
                                 default = nil)
  if valid_774283 != nil:
    section.add "X-Amz-Date", valid_774283
  var valid_774284 = header.getOrDefault("X-Amz-Security-Token")
  valid_774284 = validateParameter(valid_774284, JString, required = false,
                                 default = nil)
  if valid_774284 != nil:
    section.add "X-Amz-Security-Token", valid_774284
  var valid_774285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774285 = validateParameter(valid_774285, JString, required = false,
                                 default = nil)
  if valid_774285 != nil:
    section.add "X-Amz-Content-Sha256", valid_774285
  var valid_774286 = header.getOrDefault("X-Amz-Algorithm")
  valid_774286 = validateParameter(valid_774286, JString, required = false,
                                 default = nil)
  if valid_774286 != nil:
    section.add "X-Amz-Algorithm", valid_774286
  var valid_774287 = header.getOrDefault("X-Amz-Signature")
  valid_774287 = validateParameter(valid_774287, JString, required = false,
                                 default = nil)
  if valid_774287 != nil:
    section.add "X-Amz-Signature", valid_774287
  var valid_774288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774288 = validateParameter(valid_774288, JString, required = false,
                                 default = nil)
  if valid_774288 != nil:
    section.add "X-Amz-SignedHeaders", valid_774288
  var valid_774289 = header.getOrDefault("X-Amz-Credential")
  valid_774289 = validateParameter(valid_774289, JString, required = false,
                                 default = nil)
  if valid_774289 != nil:
    section.add "X-Amz-Credential", valid_774289
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774290 = formData.getOrDefault("Marker")
  valid_774290 = validateParameter(valid_774290, JString, required = false,
                                 default = nil)
  if valid_774290 != nil:
    section.add "Marker", valid_774290
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_774291 = formData.getOrDefault("DBParameterGroupFamily")
  valid_774291 = validateParameter(valid_774291, JString, required = true,
                                 default = nil)
  if valid_774291 != nil:
    section.add "DBParameterGroupFamily", valid_774291
  var valid_774292 = formData.getOrDefault("Filters")
  valid_774292 = validateParameter(valid_774292, JArray, required = false,
                                 default = nil)
  if valid_774292 != nil:
    section.add "Filters", valid_774292
  var valid_774293 = formData.getOrDefault("MaxRecords")
  valid_774293 = validateParameter(valid_774293, JInt, required = false, default = nil)
  if valid_774293 != nil:
    section.add "MaxRecords", valid_774293
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774294: Call_PostDescribeEngineDefaultParameters_774278;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774294.validator(path, query, header, formData, body)
  let scheme = call_774294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774294.url(scheme.get, call_774294.host, call_774294.base,
                         call_774294.route, valid.getOrDefault("path"))
  result = hook(call_774294, url, valid)

proc call*(call_774295: Call_PostDescribeEngineDefaultParameters_774278;
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
  var query_774296 = newJObject()
  var formData_774297 = newJObject()
  add(formData_774297, "Marker", newJString(Marker))
  add(query_774296, "Action", newJString(Action))
  add(formData_774297, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_774297.add "Filters", Filters
  add(formData_774297, "MaxRecords", newJInt(MaxRecords))
  add(query_774296, "Version", newJString(Version))
  result = call_774295.call(nil, query_774296, nil, formData_774297, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_774278(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_774279, base: "/",
    url: url_PostDescribeEngineDefaultParameters_774280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_774259 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEngineDefaultParameters_774261(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEngineDefaultParameters_774260(path: JsonNode;
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
  var valid_774262 = query.getOrDefault("MaxRecords")
  valid_774262 = validateParameter(valid_774262, JInt, required = false, default = nil)
  if valid_774262 != nil:
    section.add "MaxRecords", valid_774262
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_774263 = query.getOrDefault("DBParameterGroupFamily")
  valid_774263 = validateParameter(valid_774263, JString, required = true,
                                 default = nil)
  if valid_774263 != nil:
    section.add "DBParameterGroupFamily", valid_774263
  var valid_774264 = query.getOrDefault("Filters")
  valid_774264 = validateParameter(valid_774264, JArray, required = false,
                                 default = nil)
  if valid_774264 != nil:
    section.add "Filters", valid_774264
  var valid_774265 = query.getOrDefault("Action")
  valid_774265 = validateParameter(valid_774265, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_774265 != nil:
    section.add "Action", valid_774265
  var valid_774266 = query.getOrDefault("Marker")
  valid_774266 = validateParameter(valid_774266, JString, required = false,
                                 default = nil)
  if valid_774266 != nil:
    section.add "Marker", valid_774266
  var valid_774267 = query.getOrDefault("Version")
  valid_774267 = validateParameter(valid_774267, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774267 != nil:
    section.add "Version", valid_774267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774268 = header.getOrDefault("X-Amz-Date")
  valid_774268 = validateParameter(valid_774268, JString, required = false,
                                 default = nil)
  if valid_774268 != nil:
    section.add "X-Amz-Date", valid_774268
  var valid_774269 = header.getOrDefault("X-Amz-Security-Token")
  valid_774269 = validateParameter(valid_774269, JString, required = false,
                                 default = nil)
  if valid_774269 != nil:
    section.add "X-Amz-Security-Token", valid_774269
  var valid_774270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774270 = validateParameter(valid_774270, JString, required = false,
                                 default = nil)
  if valid_774270 != nil:
    section.add "X-Amz-Content-Sha256", valid_774270
  var valid_774271 = header.getOrDefault("X-Amz-Algorithm")
  valid_774271 = validateParameter(valid_774271, JString, required = false,
                                 default = nil)
  if valid_774271 != nil:
    section.add "X-Amz-Algorithm", valid_774271
  var valid_774272 = header.getOrDefault("X-Amz-Signature")
  valid_774272 = validateParameter(valid_774272, JString, required = false,
                                 default = nil)
  if valid_774272 != nil:
    section.add "X-Amz-Signature", valid_774272
  var valid_774273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774273 = validateParameter(valid_774273, JString, required = false,
                                 default = nil)
  if valid_774273 != nil:
    section.add "X-Amz-SignedHeaders", valid_774273
  var valid_774274 = header.getOrDefault("X-Amz-Credential")
  valid_774274 = validateParameter(valid_774274, JString, required = false,
                                 default = nil)
  if valid_774274 != nil:
    section.add "X-Amz-Credential", valid_774274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774275: Call_GetDescribeEngineDefaultParameters_774259;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774275.validator(path, query, header, formData, body)
  let scheme = call_774275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774275.url(scheme.get, call_774275.host, call_774275.base,
                         call_774275.route, valid.getOrDefault("path"))
  result = hook(call_774275, url, valid)

proc call*(call_774276: Call_GetDescribeEngineDefaultParameters_774259;
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
  var query_774277 = newJObject()
  add(query_774277, "MaxRecords", newJInt(MaxRecords))
  add(query_774277, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_774277.add "Filters", Filters
  add(query_774277, "Action", newJString(Action))
  add(query_774277, "Marker", newJString(Marker))
  add(query_774277, "Version", newJString(Version))
  result = call_774276.call(nil, query_774277, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_774259(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_774260, base: "/",
    url: url_GetDescribeEngineDefaultParameters_774261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_774315 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEventCategories_774317(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventCategories_774316(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774318 = query.getOrDefault("Action")
  valid_774318 = validateParameter(valid_774318, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_774318 != nil:
    section.add "Action", valid_774318
  var valid_774319 = query.getOrDefault("Version")
  valid_774319 = validateParameter(valid_774319, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774319 != nil:
    section.add "Version", valid_774319
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774320 = header.getOrDefault("X-Amz-Date")
  valid_774320 = validateParameter(valid_774320, JString, required = false,
                                 default = nil)
  if valid_774320 != nil:
    section.add "X-Amz-Date", valid_774320
  var valid_774321 = header.getOrDefault("X-Amz-Security-Token")
  valid_774321 = validateParameter(valid_774321, JString, required = false,
                                 default = nil)
  if valid_774321 != nil:
    section.add "X-Amz-Security-Token", valid_774321
  var valid_774322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774322 = validateParameter(valid_774322, JString, required = false,
                                 default = nil)
  if valid_774322 != nil:
    section.add "X-Amz-Content-Sha256", valid_774322
  var valid_774323 = header.getOrDefault("X-Amz-Algorithm")
  valid_774323 = validateParameter(valid_774323, JString, required = false,
                                 default = nil)
  if valid_774323 != nil:
    section.add "X-Amz-Algorithm", valid_774323
  var valid_774324 = header.getOrDefault("X-Amz-Signature")
  valid_774324 = validateParameter(valid_774324, JString, required = false,
                                 default = nil)
  if valid_774324 != nil:
    section.add "X-Amz-Signature", valid_774324
  var valid_774325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774325 = validateParameter(valid_774325, JString, required = false,
                                 default = nil)
  if valid_774325 != nil:
    section.add "X-Amz-SignedHeaders", valid_774325
  var valid_774326 = header.getOrDefault("X-Amz-Credential")
  valid_774326 = validateParameter(valid_774326, JString, required = false,
                                 default = nil)
  if valid_774326 != nil:
    section.add "X-Amz-Credential", valid_774326
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_774327 = formData.getOrDefault("Filters")
  valid_774327 = validateParameter(valid_774327, JArray, required = false,
                                 default = nil)
  if valid_774327 != nil:
    section.add "Filters", valid_774327
  var valid_774328 = formData.getOrDefault("SourceType")
  valid_774328 = validateParameter(valid_774328, JString, required = false,
                                 default = nil)
  if valid_774328 != nil:
    section.add "SourceType", valid_774328
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774329: Call_PostDescribeEventCategories_774315; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774329.validator(path, query, header, formData, body)
  let scheme = call_774329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774329.url(scheme.get, call_774329.host, call_774329.base,
                         call_774329.route, valid.getOrDefault("path"))
  result = hook(call_774329, url, valid)

proc call*(call_774330: Call_PostDescribeEventCategories_774315;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_774331 = newJObject()
  var formData_774332 = newJObject()
  add(query_774331, "Action", newJString(Action))
  if Filters != nil:
    formData_774332.add "Filters", Filters
  add(query_774331, "Version", newJString(Version))
  add(formData_774332, "SourceType", newJString(SourceType))
  result = call_774330.call(nil, query_774331, nil, formData_774332, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_774315(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_774316, base: "/",
    url: url_PostDescribeEventCategories_774317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_774298 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEventCategories_774300(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventCategories_774299(path: JsonNode; query: JsonNode;
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
  var valid_774301 = query.getOrDefault("SourceType")
  valid_774301 = validateParameter(valid_774301, JString, required = false,
                                 default = nil)
  if valid_774301 != nil:
    section.add "SourceType", valid_774301
  var valid_774302 = query.getOrDefault("Filters")
  valid_774302 = validateParameter(valid_774302, JArray, required = false,
                                 default = nil)
  if valid_774302 != nil:
    section.add "Filters", valid_774302
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774303 = query.getOrDefault("Action")
  valid_774303 = validateParameter(valid_774303, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_774303 != nil:
    section.add "Action", valid_774303
  var valid_774304 = query.getOrDefault("Version")
  valid_774304 = validateParameter(valid_774304, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774304 != nil:
    section.add "Version", valid_774304
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774305 = header.getOrDefault("X-Amz-Date")
  valid_774305 = validateParameter(valid_774305, JString, required = false,
                                 default = nil)
  if valid_774305 != nil:
    section.add "X-Amz-Date", valid_774305
  var valid_774306 = header.getOrDefault("X-Amz-Security-Token")
  valid_774306 = validateParameter(valid_774306, JString, required = false,
                                 default = nil)
  if valid_774306 != nil:
    section.add "X-Amz-Security-Token", valid_774306
  var valid_774307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774307 = validateParameter(valid_774307, JString, required = false,
                                 default = nil)
  if valid_774307 != nil:
    section.add "X-Amz-Content-Sha256", valid_774307
  var valid_774308 = header.getOrDefault("X-Amz-Algorithm")
  valid_774308 = validateParameter(valid_774308, JString, required = false,
                                 default = nil)
  if valid_774308 != nil:
    section.add "X-Amz-Algorithm", valid_774308
  var valid_774309 = header.getOrDefault("X-Amz-Signature")
  valid_774309 = validateParameter(valid_774309, JString, required = false,
                                 default = nil)
  if valid_774309 != nil:
    section.add "X-Amz-Signature", valid_774309
  var valid_774310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774310 = validateParameter(valid_774310, JString, required = false,
                                 default = nil)
  if valid_774310 != nil:
    section.add "X-Amz-SignedHeaders", valid_774310
  var valid_774311 = header.getOrDefault("X-Amz-Credential")
  valid_774311 = validateParameter(valid_774311, JString, required = false,
                                 default = nil)
  if valid_774311 != nil:
    section.add "X-Amz-Credential", valid_774311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774312: Call_GetDescribeEventCategories_774298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774312.validator(path, query, header, formData, body)
  let scheme = call_774312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774312.url(scheme.get, call_774312.host, call_774312.base,
                         call_774312.route, valid.getOrDefault("path"))
  result = hook(call_774312, url, valid)

proc call*(call_774313: Call_GetDescribeEventCategories_774298;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2013-09-09"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774314 = newJObject()
  add(query_774314, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_774314.add "Filters", Filters
  add(query_774314, "Action", newJString(Action))
  add(query_774314, "Version", newJString(Version))
  result = call_774313.call(nil, query_774314, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_774298(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_774299, base: "/",
    url: url_GetDescribeEventCategories_774300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_774352 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEventSubscriptions_774354(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventSubscriptions_774353(path: JsonNode;
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
  var valid_774355 = query.getOrDefault("Action")
  valid_774355 = validateParameter(valid_774355, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_774355 != nil:
    section.add "Action", valid_774355
  var valid_774356 = query.getOrDefault("Version")
  valid_774356 = validateParameter(valid_774356, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774356 != nil:
    section.add "Version", valid_774356
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774357 = header.getOrDefault("X-Amz-Date")
  valid_774357 = validateParameter(valid_774357, JString, required = false,
                                 default = nil)
  if valid_774357 != nil:
    section.add "X-Amz-Date", valid_774357
  var valid_774358 = header.getOrDefault("X-Amz-Security-Token")
  valid_774358 = validateParameter(valid_774358, JString, required = false,
                                 default = nil)
  if valid_774358 != nil:
    section.add "X-Amz-Security-Token", valid_774358
  var valid_774359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774359 = validateParameter(valid_774359, JString, required = false,
                                 default = nil)
  if valid_774359 != nil:
    section.add "X-Amz-Content-Sha256", valid_774359
  var valid_774360 = header.getOrDefault("X-Amz-Algorithm")
  valid_774360 = validateParameter(valid_774360, JString, required = false,
                                 default = nil)
  if valid_774360 != nil:
    section.add "X-Amz-Algorithm", valid_774360
  var valid_774361 = header.getOrDefault("X-Amz-Signature")
  valid_774361 = validateParameter(valid_774361, JString, required = false,
                                 default = nil)
  if valid_774361 != nil:
    section.add "X-Amz-Signature", valid_774361
  var valid_774362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774362 = validateParameter(valid_774362, JString, required = false,
                                 default = nil)
  if valid_774362 != nil:
    section.add "X-Amz-SignedHeaders", valid_774362
  var valid_774363 = header.getOrDefault("X-Amz-Credential")
  valid_774363 = validateParameter(valid_774363, JString, required = false,
                                 default = nil)
  if valid_774363 != nil:
    section.add "X-Amz-Credential", valid_774363
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774364 = formData.getOrDefault("Marker")
  valid_774364 = validateParameter(valid_774364, JString, required = false,
                                 default = nil)
  if valid_774364 != nil:
    section.add "Marker", valid_774364
  var valid_774365 = formData.getOrDefault("SubscriptionName")
  valid_774365 = validateParameter(valid_774365, JString, required = false,
                                 default = nil)
  if valid_774365 != nil:
    section.add "SubscriptionName", valid_774365
  var valid_774366 = formData.getOrDefault("Filters")
  valid_774366 = validateParameter(valid_774366, JArray, required = false,
                                 default = nil)
  if valid_774366 != nil:
    section.add "Filters", valid_774366
  var valid_774367 = formData.getOrDefault("MaxRecords")
  valid_774367 = validateParameter(valid_774367, JInt, required = false, default = nil)
  if valid_774367 != nil:
    section.add "MaxRecords", valid_774367
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774368: Call_PostDescribeEventSubscriptions_774352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774368.validator(path, query, header, formData, body)
  let scheme = call_774368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774368.url(scheme.get, call_774368.host, call_774368.base,
                         call_774368.route, valid.getOrDefault("path"))
  result = hook(call_774368, url, valid)

proc call*(call_774369: Call_PostDescribeEventSubscriptions_774352;
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
  var query_774370 = newJObject()
  var formData_774371 = newJObject()
  add(formData_774371, "Marker", newJString(Marker))
  add(formData_774371, "SubscriptionName", newJString(SubscriptionName))
  add(query_774370, "Action", newJString(Action))
  if Filters != nil:
    formData_774371.add "Filters", Filters
  add(formData_774371, "MaxRecords", newJInt(MaxRecords))
  add(query_774370, "Version", newJString(Version))
  result = call_774369.call(nil, query_774370, nil, formData_774371, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_774352(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_774353, base: "/",
    url: url_PostDescribeEventSubscriptions_774354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_774333 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEventSubscriptions_774335(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventSubscriptions_774334(path: JsonNode; query: JsonNode;
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
  var valid_774336 = query.getOrDefault("MaxRecords")
  valid_774336 = validateParameter(valid_774336, JInt, required = false, default = nil)
  if valid_774336 != nil:
    section.add "MaxRecords", valid_774336
  var valid_774337 = query.getOrDefault("Filters")
  valid_774337 = validateParameter(valid_774337, JArray, required = false,
                                 default = nil)
  if valid_774337 != nil:
    section.add "Filters", valid_774337
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774338 = query.getOrDefault("Action")
  valid_774338 = validateParameter(valid_774338, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_774338 != nil:
    section.add "Action", valid_774338
  var valid_774339 = query.getOrDefault("Marker")
  valid_774339 = validateParameter(valid_774339, JString, required = false,
                                 default = nil)
  if valid_774339 != nil:
    section.add "Marker", valid_774339
  var valid_774340 = query.getOrDefault("SubscriptionName")
  valid_774340 = validateParameter(valid_774340, JString, required = false,
                                 default = nil)
  if valid_774340 != nil:
    section.add "SubscriptionName", valid_774340
  var valid_774341 = query.getOrDefault("Version")
  valid_774341 = validateParameter(valid_774341, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774341 != nil:
    section.add "Version", valid_774341
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774342 = header.getOrDefault("X-Amz-Date")
  valid_774342 = validateParameter(valid_774342, JString, required = false,
                                 default = nil)
  if valid_774342 != nil:
    section.add "X-Amz-Date", valid_774342
  var valid_774343 = header.getOrDefault("X-Amz-Security-Token")
  valid_774343 = validateParameter(valid_774343, JString, required = false,
                                 default = nil)
  if valid_774343 != nil:
    section.add "X-Amz-Security-Token", valid_774343
  var valid_774344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774344 = validateParameter(valid_774344, JString, required = false,
                                 default = nil)
  if valid_774344 != nil:
    section.add "X-Amz-Content-Sha256", valid_774344
  var valid_774345 = header.getOrDefault("X-Amz-Algorithm")
  valid_774345 = validateParameter(valid_774345, JString, required = false,
                                 default = nil)
  if valid_774345 != nil:
    section.add "X-Amz-Algorithm", valid_774345
  var valid_774346 = header.getOrDefault("X-Amz-Signature")
  valid_774346 = validateParameter(valid_774346, JString, required = false,
                                 default = nil)
  if valid_774346 != nil:
    section.add "X-Amz-Signature", valid_774346
  var valid_774347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774347 = validateParameter(valid_774347, JString, required = false,
                                 default = nil)
  if valid_774347 != nil:
    section.add "X-Amz-SignedHeaders", valid_774347
  var valid_774348 = header.getOrDefault("X-Amz-Credential")
  valid_774348 = validateParameter(valid_774348, JString, required = false,
                                 default = nil)
  if valid_774348 != nil:
    section.add "X-Amz-Credential", valid_774348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774349: Call_GetDescribeEventSubscriptions_774333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774349.validator(path, query, header, formData, body)
  let scheme = call_774349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774349.url(scheme.get, call_774349.host, call_774349.base,
                         call_774349.route, valid.getOrDefault("path"))
  result = hook(call_774349, url, valid)

proc call*(call_774350: Call_GetDescribeEventSubscriptions_774333;
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
  var query_774351 = newJObject()
  add(query_774351, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774351.add "Filters", Filters
  add(query_774351, "Action", newJString(Action))
  add(query_774351, "Marker", newJString(Marker))
  add(query_774351, "SubscriptionName", newJString(SubscriptionName))
  add(query_774351, "Version", newJString(Version))
  result = call_774350.call(nil, query_774351, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_774333(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_774334, base: "/",
    url: url_GetDescribeEventSubscriptions_774335,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_774396 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEvents_774398(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_774397(path: JsonNode; query: JsonNode;
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
  var valid_774399 = query.getOrDefault("Action")
  valid_774399 = validateParameter(valid_774399, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_774399 != nil:
    section.add "Action", valid_774399
  var valid_774400 = query.getOrDefault("Version")
  valid_774400 = validateParameter(valid_774400, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  var valid_774408 = formData.getOrDefault("SourceIdentifier")
  valid_774408 = validateParameter(valid_774408, JString, required = false,
                                 default = nil)
  if valid_774408 != nil:
    section.add "SourceIdentifier", valid_774408
  var valid_774409 = formData.getOrDefault("EventCategories")
  valid_774409 = validateParameter(valid_774409, JArray, required = false,
                                 default = nil)
  if valid_774409 != nil:
    section.add "EventCategories", valid_774409
  var valid_774410 = formData.getOrDefault("Marker")
  valid_774410 = validateParameter(valid_774410, JString, required = false,
                                 default = nil)
  if valid_774410 != nil:
    section.add "Marker", valid_774410
  var valid_774411 = formData.getOrDefault("StartTime")
  valid_774411 = validateParameter(valid_774411, JString, required = false,
                                 default = nil)
  if valid_774411 != nil:
    section.add "StartTime", valid_774411
  var valid_774412 = formData.getOrDefault("Duration")
  valid_774412 = validateParameter(valid_774412, JInt, required = false, default = nil)
  if valid_774412 != nil:
    section.add "Duration", valid_774412
  var valid_774413 = formData.getOrDefault("Filters")
  valid_774413 = validateParameter(valid_774413, JArray, required = false,
                                 default = nil)
  if valid_774413 != nil:
    section.add "Filters", valid_774413
  var valid_774414 = formData.getOrDefault("EndTime")
  valid_774414 = validateParameter(valid_774414, JString, required = false,
                                 default = nil)
  if valid_774414 != nil:
    section.add "EndTime", valid_774414
  var valid_774415 = formData.getOrDefault("MaxRecords")
  valid_774415 = validateParameter(valid_774415, JInt, required = false, default = nil)
  if valid_774415 != nil:
    section.add "MaxRecords", valid_774415
  var valid_774416 = formData.getOrDefault("SourceType")
  valid_774416 = validateParameter(valid_774416, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_774416 != nil:
    section.add "SourceType", valid_774416
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774417: Call_PostDescribeEvents_774396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774417.validator(path, query, header, formData, body)
  let scheme = call_774417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774417.url(scheme.get, call_774417.host, call_774417.base,
                         call_774417.route, valid.getOrDefault("path"))
  result = hook(call_774417, url, valid)

proc call*(call_774418: Call_PostDescribeEvents_774396;
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
  var query_774419 = newJObject()
  var formData_774420 = newJObject()
  add(formData_774420, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_774420.add "EventCategories", EventCategories
  add(formData_774420, "Marker", newJString(Marker))
  add(formData_774420, "StartTime", newJString(StartTime))
  add(query_774419, "Action", newJString(Action))
  add(formData_774420, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_774420.add "Filters", Filters
  add(formData_774420, "EndTime", newJString(EndTime))
  add(formData_774420, "MaxRecords", newJInt(MaxRecords))
  add(query_774419, "Version", newJString(Version))
  add(formData_774420, "SourceType", newJString(SourceType))
  result = call_774418.call(nil, query_774419, nil, formData_774420, nil)

var postDescribeEvents* = Call_PostDescribeEvents_774396(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_774397, base: "/",
    url: url_PostDescribeEvents_774398, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_774372 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEvents_774374(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_774373(path: JsonNode; query: JsonNode;
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
  var valid_774375 = query.getOrDefault("SourceType")
  valid_774375 = validateParameter(valid_774375, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_774375 != nil:
    section.add "SourceType", valid_774375
  var valid_774376 = query.getOrDefault("MaxRecords")
  valid_774376 = validateParameter(valid_774376, JInt, required = false, default = nil)
  if valid_774376 != nil:
    section.add "MaxRecords", valid_774376
  var valid_774377 = query.getOrDefault("StartTime")
  valid_774377 = validateParameter(valid_774377, JString, required = false,
                                 default = nil)
  if valid_774377 != nil:
    section.add "StartTime", valid_774377
  var valid_774378 = query.getOrDefault("Filters")
  valid_774378 = validateParameter(valid_774378, JArray, required = false,
                                 default = nil)
  if valid_774378 != nil:
    section.add "Filters", valid_774378
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774379 = query.getOrDefault("Action")
  valid_774379 = validateParameter(valid_774379, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_774379 != nil:
    section.add "Action", valid_774379
  var valid_774380 = query.getOrDefault("SourceIdentifier")
  valid_774380 = validateParameter(valid_774380, JString, required = false,
                                 default = nil)
  if valid_774380 != nil:
    section.add "SourceIdentifier", valid_774380
  var valid_774381 = query.getOrDefault("Marker")
  valid_774381 = validateParameter(valid_774381, JString, required = false,
                                 default = nil)
  if valid_774381 != nil:
    section.add "Marker", valid_774381
  var valid_774382 = query.getOrDefault("EventCategories")
  valid_774382 = validateParameter(valid_774382, JArray, required = false,
                                 default = nil)
  if valid_774382 != nil:
    section.add "EventCategories", valid_774382
  var valid_774383 = query.getOrDefault("Duration")
  valid_774383 = validateParameter(valid_774383, JInt, required = false, default = nil)
  if valid_774383 != nil:
    section.add "Duration", valid_774383
  var valid_774384 = query.getOrDefault("EndTime")
  valid_774384 = validateParameter(valid_774384, JString, required = false,
                                 default = nil)
  if valid_774384 != nil:
    section.add "EndTime", valid_774384
  var valid_774385 = query.getOrDefault("Version")
  valid_774385 = validateParameter(valid_774385, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774385 != nil:
    section.add "Version", valid_774385
  result.add "query", section
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

proc call*(call_774393: Call_GetDescribeEvents_774372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774393.validator(path, query, header, formData, body)
  let scheme = call_774393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774393.url(scheme.get, call_774393.host, call_774393.base,
                         call_774393.route, valid.getOrDefault("path"))
  result = hook(call_774393, url, valid)

proc call*(call_774394: Call_GetDescribeEvents_774372;
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
  var query_774395 = newJObject()
  add(query_774395, "SourceType", newJString(SourceType))
  add(query_774395, "MaxRecords", newJInt(MaxRecords))
  add(query_774395, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_774395.add "Filters", Filters
  add(query_774395, "Action", newJString(Action))
  add(query_774395, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_774395, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_774395.add "EventCategories", EventCategories
  add(query_774395, "Duration", newJInt(Duration))
  add(query_774395, "EndTime", newJString(EndTime))
  add(query_774395, "Version", newJString(Version))
  result = call_774394.call(nil, query_774395, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_774372(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_774373,
    base: "/", url: url_GetDescribeEvents_774374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_774441 = ref object of OpenApiRestCall_772581
proc url_PostDescribeOptionGroupOptions_774443(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroupOptions_774442(path: JsonNode;
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
  var valid_774444 = query.getOrDefault("Action")
  valid_774444 = validateParameter(valid_774444, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_774444 != nil:
    section.add "Action", valid_774444
  var valid_774445 = query.getOrDefault("Version")
  valid_774445 = validateParameter(valid_774445, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774445 != nil:
    section.add "Version", valid_774445
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774446 = header.getOrDefault("X-Amz-Date")
  valid_774446 = validateParameter(valid_774446, JString, required = false,
                                 default = nil)
  if valid_774446 != nil:
    section.add "X-Amz-Date", valid_774446
  var valid_774447 = header.getOrDefault("X-Amz-Security-Token")
  valid_774447 = validateParameter(valid_774447, JString, required = false,
                                 default = nil)
  if valid_774447 != nil:
    section.add "X-Amz-Security-Token", valid_774447
  var valid_774448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774448 = validateParameter(valid_774448, JString, required = false,
                                 default = nil)
  if valid_774448 != nil:
    section.add "X-Amz-Content-Sha256", valid_774448
  var valid_774449 = header.getOrDefault("X-Amz-Algorithm")
  valid_774449 = validateParameter(valid_774449, JString, required = false,
                                 default = nil)
  if valid_774449 != nil:
    section.add "X-Amz-Algorithm", valid_774449
  var valid_774450 = header.getOrDefault("X-Amz-Signature")
  valid_774450 = validateParameter(valid_774450, JString, required = false,
                                 default = nil)
  if valid_774450 != nil:
    section.add "X-Amz-Signature", valid_774450
  var valid_774451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774451 = validateParameter(valid_774451, JString, required = false,
                                 default = nil)
  if valid_774451 != nil:
    section.add "X-Amz-SignedHeaders", valid_774451
  var valid_774452 = header.getOrDefault("X-Amz-Credential")
  valid_774452 = validateParameter(valid_774452, JString, required = false,
                                 default = nil)
  if valid_774452 != nil:
    section.add "X-Amz-Credential", valid_774452
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774453 = formData.getOrDefault("MajorEngineVersion")
  valid_774453 = validateParameter(valid_774453, JString, required = false,
                                 default = nil)
  if valid_774453 != nil:
    section.add "MajorEngineVersion", valid_774453
  var valid_774454 = formData.getOrDefault("Marker")
  valid_774454 = validateParameter(valid_774454, JString, required = false,
                                 default = nil)
  if valid_774454 != nil:
    section.add "Marker", valid_774454
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_774455 = formData.getOrDefault("EngineName")
  valid_774455 = validateParameter(valid_774455, JString, required = true,
                                 default = nil)
  if valid_774455 != nil:
    section.add "EngineName", valid_774455
  var valid_774456 = formData.getOrDefault("Filters")
  valid_774456 = validateParameter(valid_774456, JArray, required = false,
                                 default = nil)
  if valid_774456 != nil:
    section.add "Filters", valid_774456
  var valid_774457 = formData.getOrDefault("MaxRecords")
  valid_774457 = validateParameter(valid_774457, JInt, required = false, default = nil)
  if valid_774457 != nil:
    section.add "MaxRecords", valid_774457
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774458: Call_PostDescribeOptionGroupOptions_774441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774458.validator(path, query, header, formData, body)
  let scheme = call_774458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774458.url(scheme.get, call_774458.host, call_774458.base,
                         call_774458.route, valid.getOrDefault("path"))
  result = hook(call_774458, url, valid)

proc call*(call_774459: Call_PostDescribeOptionGroupOptions_774441;
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
  var query_774460 = newJObject()
  var formData_774461 = newJObject()
  add(formData_774461, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_774461, "Marker", newJString(Marker))
  add(query_774460, "Action", newJString(Action))
  add(formData_774461, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_774461.add "Filters", Filters
  add(formData_774461, "MaxRecords", newJInt(MaxRecords))
  add(query_774460, "Version", newJString(Version))
  result = call_774459.call(nil, query_774460, nil, formData_774461, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_774441(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_774442, base: "/",
    url: url_PostDescribeOptionGroupOptions_774443,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_774421 = ref object of OpenApiRestCall_772581
proc url_GetDescribeOptionGroupOptions_774423(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroupOptions_774422(path: JsonNode; query: JsonNode;
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
  var valid_774424 = query.getOrDefault("MaxRecords")
  valid_774424 = validateParameter(valid_774424, JInt, required = false, default = nil)
  if valid_774424 != nil:
    section.add "MaxRecords", valid_774424
  var valid_774425 = query.getOrDefault("Filters")
  valid_774425 = validateParameter(valid_774425, JArray, required = false,
                                 default = nil)
  if valid_774425 != nil:
    section.add "Filters", valid_774425
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774426 = query.getOrDefault("Action")
  valid_774426 = validateParameter(valid_774426, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_774426 != nil:
    section.add "Action", valid_774426
  var valid_774427 = query.getOrDefault("Marker")
  valid_774427 = validateParameter(valid_774427, JString, required = false,
                                 default = nil)
  if valid_774427 != nil:
    section.add "Marker", valid_774427
  var valid_774428 = query.getOrDefault("Version")
  valid_774428 = validateParameter(valid_774428, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774428 != nil:
    section.add "Version", valid_774428
  var valid_774429 = query.getOrDefault("EngineName")
  valid_774429 = validateParameter(valid_774429, JString, required = true,
                                 default = nil)
  if valid_774429 != nil:
    section.add "EngineName", valid_774429
  var valid_774430 = query.getOrDefault("MajorEngineVersion")
  valid_774430 = validateParameter(valid_774430, JString, required = false,
                                 default = nil)
  if valid_774430 != nil:
    section.add "MajorEngineVersion", valid_774430
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774431 = header.getOrDefault("X-Amz-Date")
  valid_774431 = validateParameter(valid_774431, JString, required = false,
                                 default = nil)
  if valid_774431 != nil:
    section.add "X-Amz-Date", valid_774431
  var valid_774432 = header.getOrDefault("X-Amz-Security-Token")
  valid_774432 = validateParameter(valid_774432, JString, required = false,
                                 default = nil)
  if valid_774432 != nil:
    section.add "X-Amz-Security-Token", valid_774432
  var valid_774433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774433 = validateParameter(valid_774433, JString, required = false,
                                 default = nil)
  if valid_774433 != nil:
    section.add "X-Amz-Content-Sha256", valid_774433
  var valid_774434 = header.getOrDefault("X-Amz-Algorithm")
  valid_774434 = validateParameter(valid_774434, JString, required = false,
                                 default = nil)
  if valid_774434 != nil:
    section.add "X-Amz-Algorithm", valid_774434
  var valid_774435 = header.getOrDefault("X-Amz-Signature")
  valid_774435 = validateParameter(valid_774435, JString, required = false,
                                 default = nil)
  if valid_774435 != nil:
    section.add "X-Amz-Signature", valid_774435
  var valid_774436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774436 = validateParameter(valid_774436, JString, required = false,
                                 default = nil)
  if valid_774436 != nil:
    section.add "X-Amz-SignedHeaders", valid_774436
  var valid_774437 = header.getOrDefault("X-Amz-Credential")
  valid_774437 = validateParameter(valid_774437, JString, required = false,
                                 default = nil)
  if valid_774437 != nil:
    section.add "X-Amz-Credential", valid_774437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774438: Call_GetDescribeOptionGroupOptions_774421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774438.validator(path, query, header, formData, body)
  let scheme = call_774438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774438.url(scheme.get, call_774438.host, call_774438.base,
                         call_774438.route, valid.getOrDefault("path"))
  result = hook(call_774438, url, valid)

proc call*(call_774439: Call_GetDescribeOptionGroupOptions_774421;
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
  var query_774440 = newJObject()
  add(query_774440, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774440.add "Filters", Filters
  add(query_774440, "Action", newJString(Action))
  add(query_774440, "Marker", newJString(Marker))
  add(query_774440, "Version", newJString(Version))
  add(query_774440, "EngineName", newJString(EngineName))
  add(query_774440, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_774439.call(nil, query_774440, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_774421(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_774422, base: "/",
    url: url_GetDescribeOptionGroupOptions_774423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_774483 = ref object of OpenApiRestCall_772581
proc url_PostDescribeOptionGroups_774485(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroups_774484(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_774486 = validateParameter(valid_774486, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_774486 != nil:
    section.add "Action", valid_774486
  var valid_774487 = query.getOrDefault("Version")
  valid_774487 = validateParameter(valid_774487, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_774495 = formData.getOrDefault("MajorEngineVersion")
  valid_774495 = validateParameter(valid_774495, JString, required = false,
                                 default = nil)
  if valid_774495 != nil:
    section.add "MajorEngineVersion", valid_774495
  var valid_774496 = formData.getOrDefault("OptionGroupName")
  valid_774496 = validateParameter(valid_774496, JString, required = false,
                                 default = nil)
  if valid_774496 != nil:
    section.add "OptionGroupName", valid_774496
  var valid_774497 = formData.getOrDefault("Marker")
  valid_774497 = validateParameter(valid_774497, JString, required = false,
                                 default = nil)
  if valid_774497 != nil:
    section.add "Marker", valid_774497
  var valid_774498 = formData.getOrDefault("EngineName")
  valid_774498 = validateParameter(valid_774498, JString, required = false,
                                 default = nil)
  if valid_774498 != nil:
    section.add "EngineName", valid_774498
  var valid_774499 = formData.getOrDefault("Filters")
  valid_774499 = validateParameter(valid_774499, JArray, required = false,
                                 default = nil)
  if valid_774499 != nil:
    section.add "Filters", valid_774499
  var valid_774500 = formData.getOrDefault("MaxRecords")
  valid_774500 = validateParameter(valid_774500, JInt, required = false, default = nil)
  if valid_774500 != nil:
    section.add "MaxRecords", valid_774500
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774501: Call_PostDescribeOptionGroups_774483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774501.validator(path, query, header, formData, body)
  let scheme = call_774501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774501.url(scheme.get, call_774501.host, call_774501.base,
                         call_774501.route, valid.getOrDefault("path"))
  result = hook(call_774501, url, valid)

proc call*(call_774502: Call_PostDescribeOptionGroups_774483;
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
  var query_774503 = newJObject()
  var formData_774504 = newJObject()
  add(formData_774504, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_774504, "OptionGroupName", newJString(OptionGroupName))
  add(formData_774504, "Marker", newJString(Marker))
  add(query_774503, "Action", newJString(Action))
  add(formData_774504, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_774504.add "Filters", Filters
  add(formData_774504, "MaxRecords", newJInt(MaxRecords))
  add(query_774503, "Version", newJString(Version))
  result = call_774502.call(nil, query_774503, nil, formData_774504, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_774483(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_774484, base: "/",
    url: url_PostDescribeOptionGroups_774485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_774462 = ref object of OpenApiRestCall_772581
proc url_GetDescribeOptionGroups_774464(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroups_774463(path: JsonNode; query: JsonNode;
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
  var valid_774465 = query.getOrDefault("MaxRecords")
  valid_774465 = validateParameter(valid_774465, JInt, required = false, default = nil)
  if valid_774465 != nil:
    section.add "MaxRecords", valid_774465
  var valid_774466 = query.getOrDefault("OptionGroupName")
  valid_774466 = validateParameter(valid_774466, JString, required = false,
                                 default = nil)
  if valid_774466 != nil:
    section.add "OptionGroupName", valid_774466
  var valid_774467 = query.getOrDefault("Filters")
  valid_774467 = validateParameter(valid_774467, JArray, required = false,
                                 default = nil)
  if valid_774467 != nil:
    section.add "Filters", valid_774467
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774468 = query.getOrDefault("Action")
  valid_774468 = validateParameter(valid_774468, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_774468 != nil:
    section.add "Action", valid_774468
  var valid_774469 = query.getOrDefault("Marker")
  valid_774469 = validateParameter(valid_774469, JString, required = false,
                                 default = nil)
  if valid_774469 != nil:
    section.add "Marker", valid_774469
  var valid_774470 = query.getOrDefault("Version")
  valid_774470 = validateParameter(valid_774470, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774470 != nil:
    section.add "Version", valid_774470
  var valid_774471 = query.getOrDefault("EngineName")
  valid_774471 = validateParameter(valid_774471, JString, required = false,
                                 default = nil)
  if valid_774471 != nil:
    section.add "EngineName", valid_774471
  var valid_774472 = query.getOrDefault("MajorEngineVersion")
  valid_774472 = validateParameter(valid_774472, JString, required = false,
                                 default = nil)
  if valid_774472 != nil:
    section.add "MajorEngineVersion", valid_774472
  result.add "query", section
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

proc call*(call_774480: Call_GetDescribeOptionGroups_774462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774480.validator(path, query, header, formData, body)
  let scheme = call_774480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774480.url(scheme.get, call_774480.host, call_774480.base,
                         call_774480.route, valid.getOrDefault("path"))
  result = hook(call_774480, url, valid)

proc call*(call_774481: Call_GetDescribeOptionGroups_774462; MaxRecords: int = 0;
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
  var query_774482 = newJObject()
  add(query_774482, "MaxRecords", newJInt(MaxRecords))
  add(query_774482, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_774482.add "Filters", Filters
  add(query_774482, "Action", newJString(Action))
  add(query_774482, "Marker", newJString(Marker))
  add(query_774482, "Version", newJString(Version))
  add(query_774482, "EngineName", newJString(EngineName))
  add(query_774482, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_774481.call(nil, query_774482, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_774462(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_774463, base: "/",
    url: url_GetDescribeOptionGroups_774464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_774528 = ref object of OpenApiRestCall_772581
proc url_PostDescribeOrderableDBInstanceOptions_774530(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOrderableDBInstanceOptions_774529(path: JsonNode;
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
  var valid_774531 = query.getOrDefault("Action")
  valid_774531 = validateParameter(valid_774531, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_774531 != nil:
    section.add "Action", valid_774531
  var valid_774532 = query.getOrDefault("Version")
  valid_774532 = validateParameter(valid_774532, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774532 != nil:
    section.add "Version", valid_774532
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774533 = header.getOrDefault("X-Amz-Date")
  valid_774533 = validateParameter(valid_774533, JString, required = false,
                                 default = nil)
  if valid_774533 != nil:
    section.add "X-Amz-Date", valid_774533
  var valid_774534 = header.getOrDefault("X-Amz-Security-Token")
  valid_774534 = validateParameter(valid_774534, JString, required = false,
                                 default = nil)
  if valid_774534 != nil:
    section.add "X-Amz-Security-Token", valid_774534
  var valid_774535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774535 = validateParameter(valid_774535, JString, required = false,
                                 default = nil)
  if valid_774535 != nil:
    section.add "X-Amz-Content-Sha256", valid_774535
  var valid_774536 = header.getOrDefault("X-Amz-Algorithm")
  valid_774536 = validateParameter(valid_774536, JString, required = false,
                                 default = nil)
  if valid_774536 != nil:
    section.add "X-Amz-Algorithm", valid_774536
  var valid_774537 = header.getOrDefault("X-Amz-Signature")
  valid_774537 = validateParameter(valid_774537, JString, required = false,
                                 default = nil)
  if valid_774537 != nil:
    section.add "X-Amz-Signature", valid_774537
  var valid_774538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774538 = validateParameter(valid_774538, JString, required = false,
                                 default = nil)
  if valid_774538 != nil:
    section.add "X-Amz-SignedHeaders", valid_774538
  var valid_774539 = header.getOrDefault("X-Amz-Credential")
  valid_774539 = validateParameter(valid_774539, JString, required = false,
                                 default = nil)
  if valid_774539 != nil:
    section.add "X-Amz-Credential", valid_774539
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
  var valid_774540 = formData.getOrDefault("Engine")
  valid_774540 = validateParameter(valid_774540, JString, required = true,
                                 default = nil)
  if valid_774540 != nil:
    section.add "Engine", valid_774540
  var valid_774541 = formData.getOrDefault("Marker")
  valid_774541 = validateParameter(valid_774541, JString, required = false,
                                 default = nil)
  if valid_774541 != nil:
    section.add "Marker", valid_774541
  var valid_774542 = formData.getOrDefault("Vpc")
  valid_774542 = validateParameter(valid_774542, JBool, required = false, default = nil)
  if valid_774542 != nil:
    section.add "Vpc", valid_774542
  var valid_774543 = formData.getOrDefault("DBInstanceClass")
  valid_774543 = validateParameter(valid_774543, JString, required = false,
                                 default = nil)
  if valid_774543 != nil:
    section.add "DBInstanceClass", valid_774543
  var valid_774544 = formData.getOrDefault("Filters")
  valid_774544 = validateParameter(valid_774544, JArray, required = false,
                                 default = nil)
  if valid_774544 != nil:
    section.add "Filters", valid_774544
  var valid_774545 = formData.getOrDefault("LicenseModel")
  valid_774545 = validateParameter(valid_774545, JString, required = false,
                                 default = nil)
  if valid_774545 != nil:
    section.add "LicenseModel", valid_774545
  var valid_774546 = formData.getOrDefault("MaxRecords")
  valid_774546 = validateParameter(valid_774546, JInt, required = false, default = nil)
  if valid_774546 != nil:
    section.add "MaxRecords", valid_774546
  var valid_774547 = formData.getOrDefault("EngineVersion")
  valid_774547 = validateParameter(valid_774547, JString, required = false,
                                 default = nil)
  if valid_774547 != nil:
    section.add "EngineVersion", valid_774547
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774548: Call_PostDescribeOrderableDBInstanceOptions_774528;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774548.validator(path, query, header, formData, body)
  let scheme = call_774548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774548.url(scheme.get, call_774548.host, call_774548.base,
                         call_774548.route, valid.getOrDefault("path"))
  result = hook(call_774548, url, valid)

proc call*(call_774549: Call_PostDescribeOrderableDBInstanceOptions_774528;
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
  var query_774550 = newJObject()
  var formData_774551 = newJObject()
  add(formData_774551, "Engine", newJString(Engine))
  add(formData_774551, "Marker", newJString(Marker))
  add(query_774550, "Action", newJString(Action))
  add(formData_774551, "Vpc", newJBool(Vpc))
  add(formData_774551, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_774551.add "Filters", Filters
  add(formData_774551, "LicenseModel", newJString(LicenseModel))
  add(formData_774551, "MaxRecords", newJInt(MaxRecords))
  add(formData_774551, "EngineVersion", newJString(EngineVersion))
  add(query_774550, "Version", newJString(Version))
  result = call_774549.call(nil, query_774550, nil, formData_774551, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_774528(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_774529, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_774530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_774505 = ref object of OpenApiRestCall_772581
proc url_GetDescribeOrderableDBInstanceOptions_774507(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOrderableDBInstanceOptions_774506(path: JsonNode;
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
  var valid_774508 = query.getOrDefault("Engine")
  valid_774508 = validateParameter(valid_774508, JString, required = true,
                                 default = nil)
  if valid_774508 != nil:
    section.add "Engine", valid_774508
  var valid_774509 = query.getOrDefault("MaxRecords")
  valid_774509 = validateParameter(valid_774509, JInt, required = false, default = nil)
  if valid_774509 != nil:
    section.add "MaxRecords", valid_774509
  var valid_774510 = query.getOrDefault("Filters")
  valid_774510 = validateParameter(valid_774510, JArray, required = false,
                                 default = nil)
  if valid_774510 != nil:
    section.add "Filters", valid_774510
  var valid_774511 = query.getOrDefault("LicenseModel")
  valid_774511 = validateParameter(valid_774511, JString, required = false,
                                 default = nil)
  if valid_774511 != nil:
    section.add "LicenseModel", valid_774511
  var valid_774512 = query.getOrDefault("Vpc")
  valid_774512 = validateParameter(valid_774512, JBool, required = false, default = nil)
  if valid_774512 != nil:
    section.add "Vpc", valid_774512
  var valid_774513 = query.getOrDefault("DBInstanceClass")
  valid_774513 = validateParameter(valid_774513, JString, required = false,
                                 default = nil)
  if valid_774513 != nil:
    section.add "DBInstanceClass", valid_774513
  var valid_774514 = query.getOrDefault("Action")
  valid_774514 = validateParameter(valid_774514, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_774514 != nil:
    section.add "Action", valid_774514
  var valid_774515 = query.getOrDefault("Marker")
  valid_774515 = validateParameter(valid_774515, JString, required = false,
                                 default = nil)
  if valid_774515 != nil:
    section.add "Marker", valid_774515
  var valid_774516 = query.getOrDefault("EngineVersion")
  valid_774516 = validateParameter(valid_774516, JString, required = false,
                                 default = nil)
  if valid_774516 != nil:
    section.add "EngineVersion", valid_774516
  var valid_774517 = query.getOrDefault("Version")
  valid_774517 = validateParameter(valid_774517, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774517 != nil:
    section.add "Version", valid_774517
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774518 = header.getOrDefault("X-Amz-Date")
  valid_774518 = validateParameter(valid_774518, JString, required = false,
                                 default = nil)
  if valid_774518 != nil:
    section.add "X-Amz-Date", valid_774518
  var valid_774519 = header.getOrDefault("X-Amz-Security-Token")
  valid_774519 = validateParameter(valid_774519, JString, required = false,
                                 default = nil)
  if valid_774519 != nil:
    section.add "X-Amz-Security-Token", valid_774519
  var valid_774520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774520 = validateParameter(valid_774520, JString, required = false,
                                 default = nil)
  if valid_774520 != nil:
    section.add "X-Amz-Content-Sha256", valid_774520
  var valid_774521 = header.getOrDefault("X-Amz-Algorithm")
  valid_774521 = validateParameter(valid_774521, JString, required = false,
                                 default = nil)
  if valid_774521 != nil:
    section.add "X-Amz-Algorithm", valid_774521
  var valid_774522 = header.getOrDefault("X-Amz-Signature")
  valid_774522 = validateParameter(valid_774522, JString, required = false,
                                 default = nil)
  if valid_774522 != nil:
    section.add "X-Amz-Signature", valid_774522
  var valid_774523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774523 = validateParameter(valid_774523, JString, required = false,
                                 default = nil)
  if valid_774523 != nil:
    section.add "X-Amz-SignedHeaders", valid_774523
  var valid_774524 = header.getOrDefault("X-Amz-Credential")
  valid_774524 = validateParameter(valid_774524, JString, required = false,
                                 default = nil)
  if valid_774524 != nil:
    section.add "X-Amz-Credential", valid_774524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774525: Call_GetDescribeOrderableDBInstanceOptions_774505;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774525.validator(path, query, header, formData, body)
  let scheme = call_774525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774525.url(scheme.get, call_774525.host, call_774525.base,
                         call_774525.route, valid.getOrDefault("path"))
  result = hook(call_774525, url, valid)

proc call*(call_774526: Call_GetDescribeOrderableDBInstanceOptions_774505;
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
  var query_774527 = newJObject()
  add(query_774527, "Engine", newJString(Engine))
  add(query_774527, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774527.add "Filters", Filters
  add(query_774527, "LicenseModel", newJString(LicenseModel))
  add(query_774527, "Vpc", newJBool(Vpc))
  add(query_774527, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774527, "Action", newJString(Action))
  add(query_774527, "Marker", newJString(Marker))
  add(query_774527, "EngineVersion", newJString(EngineVersion))
  add(query_774527, "Version", newJString(Version))
  result = call_774526.call(nil, query_774527, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_774505(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_774506, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_774507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_774577 = ref object of OpenApiRestCall_772581
proc url_PostDescribeReservedDBInstances_774579(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstances_774578(path: JsonNode;
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
  var valid_774580 = query.getOrDefault("Action")
  valid_774580 = validateParameter(valid_774580, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_774580 != nil:
    section.add "Action", valid_774580
  var valid_774581 = query.getOrDefault("Version")
  valid_774581 = validateParameter(valid_774581, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774581 != nil:
    section.add "Version", valid_774581
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774582 = header.getOrDefault("X-Amz-Date")
  valid_774582 = validateParameter(valid_774582, JString, required = false,
                                 default = nil)
  if valid_774582 != nil:
    section.add "X-Amz-Date", valid_774582
  var valid_774583 = header.getOrDefault("X-Amz-Security-Token")
  valid_774583 = validateParameter(valid_774583, JString, required = false,
                                 default = nil)
  if valid_774583 != nil:
    section.add "X-Amz-Security-Token", valid_774583
  var valid_774584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774584 = validateParameter(valid_774584, JString, required = false,
                                 default = nil)
  if valid_774584 != nil:
    section.add "X-Amz-Content-Sha256", valid_774584
  var valid_774585 = header.getOrDefault("X-Amz-Algorithm")
  valid_774585 = validateParameter(valid_774585, JString, required = false,
                                 default = nil)
  if valid_774585 != nil:
    section.add "X-Amz-Algorithm", valid_774585
  var valid_774586 = header.getOrDefault("X-Amz-Signature")
  valid_774586 = validateParameter(valid_774586, JString, required = false,
                                 default = nil)
  if valid_774586 != nil:
    section.add "X-Amz-Signature", valid_774586
  var valid_774587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774587 = validateParameter(valid_774587, JString, required = false,
                                 default = nil)
  if valid_774587 != nil:
    section.add "X-Amz-SignedHeaders", valid_774587
  var valid_774588 = header.getOrDefault("X-Amz-Credential")
  valid_774588 = validateParameter(valid_774588, JString, required = false,
                                 default = nil)
  if valid_774588 != nil:
    section.add "X-Amz-Credential", valid_774588
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
  var valid_774589 = formData.getOrDefault("OfferingType")
  valid_774589 = validateParameter(valid_774589, JString, required = false,
                                 default = nil)
  if valid_774589 != nil:
    section.add "OfferingType", valid_774589
  var valid_774590 = formData.getOrDefault("ReservedDBInstanceId")
  valid_774590 = validateParameter(valid_774590, JString, required = false,
                                 default = nil)
  if valid_774590 != nil:
    section.add "ReservedDBInstanceId", valid_774590
  var valid_774591 = formData.getOrDefault("Marker")
  valid_774591 = validateParameter(valid_774591, JString, required = false,
                                 default = nil)
  if valid_774591 != nil:
    section.add "Marker", valid_774591
  var valid_774592 = formData.getOrDefault("MultiAZ")
  valid_774592 = validateParameter(valid_774592, JBool, required = false, default = nil)
  if valid_774592 != nil:
    section.add "MultiAZ", valid_774592
  var valid_774593 = formData.getOrDefault("Duration")
  valid_774593 = validateParameter(valid_774593, JString, required = false,
                                 default = nil)
  if valid_774593 != nil:
    section.add "Duration", valid_774593
  var valid_774594 = formData.getOrDefault("DBInstanceClass")
  valid_774594 = validateParameter(valid_774594, JString, required = false,
                                 default = nil)
  if valid_774594 != nil:
    section.add "DBInstanceClass", valid_774594
  var valid_774595 = formData.getOrDefault("Filters")
  valid_774595 = validateParameter(valid_774595, JArray, required = false,
                                 default = nil)
  if valid_774595 != nil:
    section.add "Filters", valid_774595
  var valid_774596 = formData.getOrDefault("ProductDescription")
  valid_774596 = validateParameter(valid_774596, JString, required = false,
                                 default = nil)
  if valid_774596 != nil:
    section.add "ProductDescription", valid_774596
  var valid_774597 = formData.getOrDefault("MaxRecords")
  valid_774597 = validateParameter(valid_774597, JInt, required = false, default = nil)
  if valid_774597 != nil:
    section.add "MaxRecords", valid_774597
  var valid_774598 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774598 = validateParameter(valid_774598, JString, required = false,
                                 default = nil)
  if valid_774598 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774598
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774599: Call_PostDescribeReservedDBInstances_774577;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774599.validator(path, query, header, formData, body)
  let scheme = call_774599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774599.url(scheme.get, call_774599.host, call_774599.base,
                         call_774599.route, valid.getOrDefault("path"))
  result = hook(call_774599, url, valid)

proc call*(call_774600: Call_PostDescribeReservedDBInstances_774577;
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
  var query_774601 = newJObject()
  var formData_774602 = newJObject()
  add(formData_774602, "OfferingType", newJString(OfferingType))
  add(formData_774602, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_774602, "Marker", newJString(Marker))
  add(formData_774602, "MultiAZ", newJBool(MultiAZ))
  add(query_774601, "Action", newJString(Action))
  add(formData_774602, "Duration", newJString(Duration))
  add(formData_774602, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_774602.add "Filters", Filters
  add(formData_774602, "ProductDescription", newJString(ProductDescription))
  add(formData_774602, "MaxRecords", newJInt(MaxRecords))
  add(formData_774602, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774601, "Version", newJString(Version))
  result = call_774600.call(nil, query_774601, nil, formData_774602, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_774577(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_774578, base: "/",
    url: url_PostDescribeReservedDBInstances_774579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_774552 = ref object of OpenApiRestCall_772581
proc url_GetDescribeReservedDBInstances_774554(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstances_774553(path: JsonNode;
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
  var valid_774555 = query.getOrDefault("ProductDescription")
  valid_774555 = validateParameter(valid_774555, JString, required = false,
                                 default = nil)
  if valid_774555 != nil:
    section.add "ProductDescription", valid_774555
  var valid_774556 = query.getOrDefault("MaxRecords")
  valid_774556 = validateParameter(valid_774556, JInt, required = false, default = nil)
  if valid_774556 != nil:
    section.add "MaxRecords", valid_774556
  var valid_774557 = query.getOrDefault("OfferingType")
  valid_774557 = validateParameter(valid_774557, JString, required = false,
                                 default = nil)
  if valid_774557 != nil:
    section.add "OfferingType", valid_774557
  var valid_774558 = query.getOrDefault("Filters")
  valid_774558 = validateParameter(valid_774558, JArray, required = false,
                                 default = nil)
  if valid_774558 != nil:
    section.add "Filters", valid_774558
  var valid_774559 = query.getOrDefault("MultiAZ")
  valid_774559 = validateParameter(valid_774559, JBool, required = false, default = nil)
  if valid_774559 != nil:
    section.add "MultiAZ", valid_774559
  var valid_774560 = query.getOrDefault("ReservedDBInstanceId")
  valid_774560 = validateParameter(valid_774560, JString, required = false,
                                 default = nil)
  if valid_774560 != nil:
    section.add "ReservedDBInstanceId", valid_774560
  var valid_774561 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774561 = validateParameter(valid_774561, JString, required = false,
                                 default = nil)
  if valid_774561 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774561
  var valid_774562 = query.getOrDefault("DBInstanceClass")
  valid_774562 = validateParameter(valid_774562, JString, required = false,
                                 default = nil)
  if valid_774562 != nil:
    section.add "DBInstanceClass", valid_774562
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774563 = query.getOrDefault("Action")
  valid_774563 = validateParameter(valid_774563, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_774563 != nil:
    section.add "Action", valid_774563
  var valid_774564 = query.getOrDefault("Marker")
  valid_774564 = validateParameter(valid_774564, JString, required = false,
                                 default = nil)
  if valid_774564 != nil:
    section.add "Marker", valid_774564
  var valid_774565 = query.getOrDefault("Duration")
  valid_774565 = validateParameter(valid_774565, JString, required = false,
                                 default = nil)
  if valid_774565 != nil:
    section.add "Duration", valid_774565
  var valid_774566 = query.getOrDefault("Version")
  valid_774566 = validateParameter(valid_774566, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774566 != nil:
    section.add "Version", valid_774566
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774567 = header.getOrDefault("X-Amz-Date")
  valid_774567 = validateParameter(valid_774567, JString, required = false,
                                 default = nil)
  if valid_774567 != nil:
    section.add "X-Amz-Date", valid_774567
  var valid_774568 = header.getOrDefault("X-Amz-Security-Token")
  valid_774568 = validateParameter(valid_774568, JString, required = false,
                                 default = nil)
  if valid_774568 != nil:
    section.add "X-Amz-Security-Token", valid_774568
  var valid_774569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774569 = validateParameter(valid_774569, JString, required = false,
                                 default = nil)
  if valid_774569 != nil:
    section.add "X-Amz-Content-Sha256", valid_774569
  var valid_774570 = header.getOrDefault("X-Amz-Algorithm")
  valid_774570 = validateParameter(valid_774570, JString, required = false,
                                 default = nil)
  if valid_774570 != nil:
    section.add "X-Amz-Algorithm", valid_774570
  var valid_774571 = header.getOrDefault("X-Amz-Signature")
  valid_774571 = validateParameter(valid_774571, JString, required = false,
                                 default = nil)
  if valid_774571 != nil:
    section.add "X-Amz-Signature", valid_774571
  var valid_774572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774572 = validateParameter(valid_774572, JString, required = false,
                                 default = nil)
  if valid_774572 != nil:
    section.add "X-Amz-SignedHeaders", valid_774572
  var valid_774573 = header.getOrDefault("X-Amz-Credential")
  valid_774573 = validateParameter(valid_774573, JString, required = false,
                                 default = nil)
  if valid_774573 != nil:
    section.add "X-Amz-Credential", valid_774573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774574: Call_GetDescribeReservedDBInstances_774552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774574.validator(path, query, header, formData, body)
  let scheme = call_774574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774574.url(scheme.get, call_774574.host, call_774574.base,
                         call_774574.route, valid.getOrDefault("path"))
  result = hook(call_774574, url, valid)

proc call*(call_774575: Call_GetDescribeReservedDBInstances_774552;
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
  var query_774576 = newJObject()
  add(query_774576, "ProductDescription", newJString(ProductDescription))
  add(query_774576, "MaxRecords", newJInt(MaxRecords))
  add(query_774576, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_774576.add "Filters", Filters
  add(query_774576, "MultiAZ", newJBool(MultiAZ))
  add(query_774576, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_774576, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774576, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774576, "Action", newJString(Action))
  add(query_774576, "Marker", newJString(Marker))
  add(query_774576, "Duration", newJString(Duration))
  add(query_774576, "Version", newJString(Version))
  result = call_774575.call(nil, query_774576, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_774552(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_774553, base: "/",
    url: url_GetDescribeReservedDBInstances_774554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_774627 = ref object of OpenApiRestCall_772581
proc url_PostDescribeReservedDBInstancesOfferings_774629(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstancesOfferings_774628(path: JsonNode;
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
  var valid_774630 = query.getOrDefault("Action")
  valid_774630 = validateParameter(valid_774630, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_774630 != nil:
    section.add "Action", valid_774630
  var valid_774631 = query.getOrDefault("Version")
  valid_774631 = validateParameter(valid_774631, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774631 != nil:
    section.add "Version", valid_774631
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774632 = header.getOrDefault("X-Amz-Date")
  valid_774632 = validateParameter(valid_774632, JString, required = false,
                                 default = nil)
  if valid_774632 != nil:
    section.add "X-Amz-Date", valid_774632
  var valid_774633 = header.getOrDefault("X-Amz-Security-Token")
  valid_774633 = validateParameter(valid_774633, JString, required = false,
                                 default = nil)
  if valid_774633 != nil:
    section.add "X-Amz-Security-Token", valid_774633
  var valid_774634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774634 = validateParameter(valid_774634, JString, required = false,
                                 default = nil)
  if valid_774634 != nil:
    section.add "X-Amz-Content-Sha256", valid_774634
  var valid_774635 = header.getOrDefault("X-Amz-Algorithm")
  valid_774635 = validateParameter(valid_774635, JString, required = false,
                                 default = nil)
  if valid_774635 != nil:
    section.add "X-Amz-Algorithm", valid_774635
  var valid_774636 = header.getOrDefault("X-Amz-Signature")
  valid_774636 = validateParameter(valid_774636, JString, required = false,
                                 default = nil)
  if valid_774636 != nil:
    section.add "X-Amz-Signature", valid_774636
  var valid_774637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774637 = validateParameter(valid_774637, JString, required = false,
                                 default = nil)
  if valid_774637 != nil:
    section.add "X-Amz-SignedHeaders", valid_774637
  var valid_774638 = header.getOrDefault("X-Amz-Credential")
  valid_774638 = validateParameter(valid_774638, JString, required = false,
                                 default = nil)
  if valid_774638 != nil:
    section.add "X-Amz-Credential", valid_774638
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
  var valid_774639 = formData.getOrDefault("OfferingType")
  valid_774639 = validateParameter(valid_774639, JString, required = false,
                                 default = nil)
  if valid_774639 != nil:
    section.add "OfferingType", valid_774639
  var valid_774640 = formData.getOrDefault("Marker")
  valid_774640 = validateParameter(valid_774640, JString, required = false,
                                 default = nil)
  if valid_774640 != nil:
    section.add "Marker", valid_774640
  var valid_774641 = formData.getOrDefault("MultiAZ")
  valid_774641 = validateParameter(valid_774641, JBool, required = false, default = nil)
  if valid_774641 != nil:
    section.add "MultiAZ", valid_774641
  var valid_774642 = formData.getOrDefault("Duration")
  valid_774642 = validateParameter(valid_774642, JString, required = false,
                                 default = nil)
  if valid_774642 != nil:
    section.add "Duration", valid_774642
  var valid_774643 = formData.getOrDefault("DBInstanceClass")
  valid_774643 = validateParameter(valid_774643, JString, required = false,
                                 default = nil)
  if valid_774643 != nil:
    section.add "DBInstanceClass", valid_774643
  var valid_774644 = formData.getOrDefault("Filters")
  valid_774644 = validateParameter(valid_774644, JArray, required = false,
                                 default = nil)
  if valid_774644 != nil:
    section.add "Filters", valid_774644
  var valid_774645 = formData.getOrDefault("ProductDescription")
  valid_774645 = validateParameter(valid_774645, JString, required = false,
                                 default = nil)
  if valid_774645 != nil:
    section.add "ProductDescription", valid_774645
  var valid_774646 = formData.getOrDefault("MaxRecords")
  valid_774646 = validateParameter(valid_774646, JInt, required = false, default = nil)
  if valid_774646 != nil:
    section.add "MaxRecords", valid_774646
  var valid_774647 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774647 = validateParameter(valid_774647, JString, required = false,
                                 default = nil)
  if valid_774647 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774647
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774648: Call_PostDescribeReservedDBInstancesOfferings_774627;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774648.validator(path, query, header, formData, body)
  let scheme = call_774648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774648.url(scheme.get, call_774648.host, call_774648.base,
                         call_774648.route, valid.getOrDefault("path"))
  result = hook(call_774648, url, valid)

proc call*(call_774649: Call_PostDescribeReservedDBInstancesOfferings_774627;
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
  var query_774650 = newJObject()
  var formData_774651 = newJObject()
  add(formData_774651, "OfferingType", newJString(OfferingType))
  add(formData_774651, "Marker", newJString(Marker))
  add(formData_774651, "MultiAZ", newJBool(MultiAZ))
  add(query_774650, "Action", newJString(Action))
  add(formData_774651, "Duration", newJString(Duration))
  add(formData_774651, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_774651.add "Filters", Filters
  add(formData_774651, "ProductDescription", newJString(ProductDescription))
  add(formData_774651, "MaxRecords", newJInt(MaxRecords))
  add(formData_774651, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774650, "Version", newJString(Version))
  result = call_774649.call(nil, query_774650, nil, formData_774651, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_774627(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_774628,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_774629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_774603 = ref object of OpenApiRestCall_772581
proc url_GetDescribeReservedDBInstancesOfferings_774605(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstancesOfferings_774604(path: JsonNode;
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
  var valid_774606 = query.getOrDefault("ProductDescription")
  valid_774606 = validateParameter(valid_774606, JString, required = false,
                                 default = nil)
  if valid_774606 != nil:
    section.add "ProductDescription", valid_774606
  var valid_774607 = query.getOrDefault("MaxRecords")
  valid_774607 = validateParameter(valid_774607, JInt, required = false, default = nil)
  if valid_774607 != nil:
    section.add "MaxRecords", valid_774607
  var valid_774608 = query.getOrDefault("OfferingType")
  valid_774608 = validateParameter(valid_774608, JString, required = false,
                                 default = nil)
  if valid_774608 != nil:
    section.add "OfferingType", valid_774608
  var valid_774609 = query.getOrDefault("Filters")
  valid_774609 = validateParameter(valid_774609, JArray, required = false,
                                 default = nil)
  if valid_774609 != nil:
    section.add "Filters", valid_774609
  var valid_774610 = query.getOrDefault("MultiAZ")
  valid_774610 = validateParameter(valid_774610, JBool, required = false, default = nil)
  if valid_774610 != nil:
    section.add "MultiAZ", valid_774610
  var valid_774611 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774611 = validateParameter(valid_774611, JString, required = false,
                                 default = nil)
  if valid_774611 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774611
  var valid_774612 = query.getOrDefault("DBInstanceClass")
  valid_774612 = validateParameter(valid_774612, JString, required = false,
                                 default = nil)
  if valid_774612 != nil:
    section.add "DBInstanceClass", valid_774612
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774613 = query.getOrDefault("Action")
  valid_774613 = validateParameter(valid_774613, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_774613 != nil:
    section.add "Action", valid_774613
  var valid_774614 = query.getOrDefault("Marker")
  valid_774614 = validateParameter(valid_774614, JString, required = false,
                                 default = nil)
  if valid_774614 != nil:
    section.add "Marker", valid_774614
  var valid_774615 = query.getOrDefault("Duration")
  valid_774615 = validateParameter(valid_774615, JString, required = false,
                                 default = nil)
  if valid_774615 != nil:
    section.add "Duration", valid_774615
  var valid_774616 = query.getOrDefault("Version")
  valid_774616 = validateParameter(valid_774616, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774616 != nil:
    section.add "Version", valid_774616
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774617 = header.getOrDefault("X-Amz-Date")
  valid_774617 = validateParameter(valid_774617, JString, required = false,
                                 default = nil)
  if valid_774617 != nil:
    section.add "X-Amz-Date", valid_774617
  var valid_774618 = header.getOrDefault("X-Amz-Security-Token")
  valid_774618 = validateParameter(valid_774618, JString, required = false,
                                 default = nil)
  if valid_774618 != nil:
    section.add "X-Amz-Security-Token", valid_774618
  var valid_774619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774619 = validateParameter(valid_774619, JString, required = false,
                                 default = nil)
  if valid_774619 != nil:
    section.add "X-Amz-Content-Sha256", valid_774619
  var valid_774620 = header.getOrDefault("X-Amz-Algorithm")
  valid_774620 = validateParameter(valid_774620, JString, required = false,
                                 default = nil)
  if valid_774620 != nil:
    section.add "X-Amz-Algorithm", valid_774620
  var valid_774621 = header.getOrDefault("X-Amz-Signature")
  valid_774621 = validateParameter(valid_774621, JString, required = false,
                                 default = nil)
  if valid_774621 != nil:
    section.add "X-Amz-Signature", valid_774621
  var valid_774622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774622 = validateParameter(valid_774622, JString, required = false,
                                 default = nil)
  if valid_774622 != nil:
    section.add "X-Amz-SignedHeaders", valid_774622
  var valid_774623 = header.getOrDefault("X-Amz-Credential")
  valid_774623 = validateParameter(valid_774623, JString, required = false,
                                 default = nil)
  if valid_774623 != nil:
    section.add "X-Amz-Credential", valid_774623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774624: Call_GetDescribeReservedDBInstancesOfferings_774603;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774624.validator(path, query, header, formData, body)
  let scheme = call_774624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774624.url(scheme.get, call_774624.host, call_774624.base,
                         call_774624.route, valid.getOrDefault("path"))
  result = hook(call_774624, url, valid)

proc call*(call_774625: Call_GetDescribeReservedDBInstancesOfferings_774603;
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
  var query_774626 = newJObject()
  add(query_774626, "ProductDescription", newJString(ProductDescription))
  add(query_774626, "MaxRecords", newJInt(MaxRecords))
  add(query_774626, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_774626.add "Filters", Filters
  add(query_774626, "MultiAZ", newJBool(MultiAZ))
  add(query_774626, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_774626, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774626, "Action", newJString(Action))
  add(query_774626, "Marker", newJString(Marker))
  add(query_774626, "Duration", newJString(Duration))
  add(query_774626, "Version", newJString(Version))
  result = call_774625.call(nil, query_774626, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_774603(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_774604, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_774605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_774671 = ref object of OpenApiRestCall_772581
proc url_PostDownloadDBLogFilePortion_774673(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDownloadDBLogFilePortion_774672(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774674 = query.getOrDefault("Action")
  valid_774674 = validateParameter(valid_774674, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_774674 != nil:
    section.add "Action", valid_774674
  var valid_774675 = query.getOrDefault("Version")
  valid_774675 = validateParameter(valid_774675, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774675 != nil:
    section.add "Version", valid_774675
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774676 = header.getOrDefault("X-Amz-Date")
  valid_774676 = validateParameter(valid_774676, JString, required = false,
                                 default = nil)
  if valid_774676 != nil:
    section.add "X-Amz-Date", valid_774676
  var valid_774677 = header.getOrDefault("X-Amz-Security-Token")
  valid_774677 = validateParameter(valid_774677, JString, required = false,
                                 default = nil)
  if valid_774677 != nil:
    section.add "X-Amz-Security-Token", valid_774677
  var valid_774678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774678 = validateParameter(valid_774678, JString, required = false,
                                 default = nil)
  if valid_774678 != nil:
    section.add "X-Amz-Content-Sha256", valid_774678
  var valid_774679 = header.getOrDefault("X-Amz-Algorithm")
  valid_774679 = validateParameter(valid_774679, JString, required = false,
                                 default = nil)
  if valid_774679 != nil:
    section.add "X-Amz-Algorithm", valid_774679
  var valid_774680 = header.getOrDefault("X-Amz-Signature")
  valid_774680 = validateParameter(valid_774680, JString, required = false,
                                 default = nil)
  if valid_774680 != nil:
    section.add "X-Amz-Signature", valid_774680
  var valid_774681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774681 = validateParameter(valid_774681, JString, required = false,
                                 default = nil)
  if valid_774681 != nil:
    section.add "X-Amz-SignedHeaders", valid_774681
  var valid_774682 = header.getOrDefault("X-Amz-Credential")
  valid_774682 = validateParameter(valid_774682, JString, required = false,
                                 default = nil)
  if valid_774682 != nil:
    section.add "X-Amz-Credential", valid_774682
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_774683 = formData.getOrDefault("NumberOfLines")
  valid_774683 = validateParameter(valid_774683, JInt, required = false, default = nil)
  if valid_774683 != nil:
    section.add "NumberOfLines", valid_774683
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774684 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774684 = validateParameter(valid_774684, JString, required = true,
                                 default = nil)
  if valid_774684 != nil:
    section.add "DBInstanceIdentifier", valid_774684
  var valid_774685 = formData.getOrDefault("Marker")
  valid_774685 = validateParameter(valid_774685, JString, required = false,
                                 default = nil)
  if valid_774685 != nil:
    section.add "Marker", valid_774685
  var valid_774686 = formData.getOrDefault("LogFileName")
  valid_774686 = validateParameter(valid_774686, JString, required = true,
                                 default = nil)
  if valid_774686 != nil:
    section.add "LogFileName", valid_774686
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774687: Call_PostDownloadDBLogFilePortion_774671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774687.validator(path, query, header, formData, body)
  let scheme = call_774687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774687.url(scheme.get, call_774687.host, call_774687.base,
                         call_774687.route, valid.getOrDefault("path"))
  result = hook(call_774687, url, valid)

proc call*(call_774688: Call_PostDownloadDBLogFilePortion_774671;
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
  var query_774689 = newJObject()
  var formData_774690 = newJObject()
  add(formData_774690, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_774690, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774690, "Marker", newJString(Marker))
  add(query_774689, "Action", newJString(Action))
  add(formData_774690, "LogFileName", newJString(LogFileName))
  add(query_774689, "Version", newJString(Version))
  result = call_774688.call(nil, query_774689, nil, formData_774690, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_774671(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_774672, base: "/",
    url: url_PostDownloadDBLogFilePortion_774673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_774652 = ref object of OpenApiRestCall_772581
proc url_GetDownloadDBLogFilePortion_774654(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDownloadDBLogFilePortion_774653(path: JsonNode; query: JsonNode;
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
  var valid_774655 = query.getOrDefault("NumberOfLines")
  valid_774655 = validateParameter(valid_774655, JInt, required = false, default = nil)
  if valid_774655 != nil:
    section.add "NumberOfLines", valid_774655
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_774656 = query.getOrDefault("LogFileName")
  valid_774656 = validateParameter(valid_774656, JString, required = true,
                                 default = nil)
  if valid_774656 != nil:
    section.add "LogFileName", valid_774656
  var valid_774657 = query.getOrDefault("Action")
  valid_774657 = validateParameter(valid_774657, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_774657 != nil:
    section.add "Action", valid_774657
  var valid_774658 = query.getOrDefault("Marker")
  valid_774658 = validateParameter(valid_774658, JString, required = false,
                                 default = nil)
  if valid_774658 != nil:
    section.add "Marker", valid_774658
  var valid_774659 = query.getOrDefault("Version")
  valid_774659 = validateParameter(valid_774659, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774659 != nil:
    section.add "Version", valid_774659
  var valid_774660 = query.getOrDefault("DBInstanceIdentifier")
  valid_774660 = validateParameter(valid_774660, JString, required = true,
                                 default = nil)
  if valid_774660 != nil:
    section.add "DBInstanceIdentifier", valid_774660
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774661 = header.getOrDefault("X-Amz-Date")
  valid_774661 = validateParameter(valid_774661, JString, required = false,
                                 default = nil)
  if valid_774661 != nil:
    section.add "X-Amz-Date", valid_774661
  var valid_774662 = header.getOrDefault("X-Amz-Security-Token")
  valid_774662 = validateParameter(valid_774662, JString, required = false,
                                 default = nil)
  if valid_774662 != nil:
    section.add "X-Amz-Security-Token", valid_774662
  var valid_774663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774663 = validateParameter(valid_774663, JString, required = false,
                                 default = nil)
  if valid_774663 != nil:
    section.add "X-Amz-Content-Sha256", valid_774663
  var valid_774664 = header.getOrDefault("X-Amz-Algorithm")
  valid_774664 = validateParameter(valid_774664, JString, required = false,
                                 default = nil)
  if valid_774664 != nil:
    section.add "X-Amz-Algorithm", valid_774664
  var valid_774665 = header.getOrDefault("X-Amz-Signature")
  valid_774665 = validateParameter(valid_774665, JString, required = false,
                                 default = nil)
  if valid_774665 != nil:
    section.add "X-Amz-Signature", valid_774665
  var valid_774666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774666 = validateParameter(valid_774666, JString, required = false,
                                 default = nil)
  if valid_774666 != nil:
    section.add "X-Amz-SignedHeaders", valid_774666
  var valid_774667 = header.getOrDefault("X-Amz-Credential")
  valid_774667 = validateParameter(valid_774667, JString, required = false,
                                 default = nil)
  if valid_774667 != nil:
    section.add "X-Amz-Credential", valid_774667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774668: Call_GetDownloadDBLogFilePortion_774652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774668.validator(path, query, header, formData, body)
  let scheme = call_774668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774668.url(scheme.get, call_774668.host, call_774668.base,
                         call_774668.route, valid.getOrDefault("path"))
  result = hook(call_774668, url, valid)

proc call*(call_774669: Call_GetDownloadDBLogFilePortion_774652;
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
  var query_774670 = newJObject()
  add(query_774670, "NumberOfLines", newJInt(NumberOfLines))
  add(query_774670, "LogFileName", newJString(LogFileName))
  add(query_774670, "Action", newJString(Action))
  add(query_774670, "Marker", newJString(Marker))
  add(query_774670, "Version", newJString(Version))
  add(query_774670, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_774669.call(nil, query_774670, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_774652(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_774653, base: "/",
    url: url_GetDownloadDBLogFilePortion_774654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_774708 = ref object of OpenApiRestCall_772581
proc url_PostListTagsForResource_774710(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_774709(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("ListTagsForResource"))
  if valid_774711 != nil:
    section.add "Action", valid_774711
  var valid_774712 = query.getOrDefault("Version")
  valid_774712 = validateParameter(valid_774712, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_774720 = formData.getOrDefault("Filters")
  valid_774720 = validateParameter(valid_774720, JArray, required = false,
                                 default = nil)
  if valid_774720 != nil:
    section.add "Filters", valid_774720
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_774721 = formData.getOrDefault("ResourceName")
  valid_774721 = validateParameter(valid_774721, JString, required = true,
                                 default = nil)
  if valid_774721 != nil:
    section.add "ResourceName", valid_774721
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774722: Call_PostListTagsForResource_774708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774722.validator(path, query, header, formData, body)
  let scheme = call_774722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774722.url(scheme.get, call_774722.host, call_774722.base,
                         call_774722.route, valid.getOrDefault("path"))
  result = hook(call_774722, url, valid)

proc call*(call_774723: Call_PostListTagsForResource_774708; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_774724 = newJObject()
  var formData_774725 = newJObject()
  add(query_774724, "Action", newJString(Action))
  if Filters != nil:
    formData_774725.add "Filters", Filters
  add(formData_774725, "ResourceName", newJString(ResourceName))
  add(query_774724, "Version", newJString(Version))
  result = call_774723.call(nil, query_774724, nil, formData_774725, nil)

var postListTagsForResource* = Call_PostListTagsForResource_774708(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_774709, base: "/",
    url: url_PostListTagsForResource_774710, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_774691 = ref object of OpenApiRestCall_772581
proc url_GetListTagsForResource_774693(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_774692(path: JsonNode; query: JsonNode;
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
  var valid_774694 = query.getOrDefault("Filters")
  valid_774694 = validateParameter(valid_774694, JArray, required = false,
                                 default = nil)
  if valid_774694 != nil:
    section.add "Filters", valid_774694
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_774695 = query.getOrDefault("ResourceName")
  valid_774695 = validateParameter(valid_774695, JString, required = true,
                                 default = nil)
  if valid_774695 != nil:
    section.add "ResourceName", valid_774695
  var valid_774696 = query.getOrDefault("Action")
  valid_774696 = validateParameter(valid_774696, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_774696 != nil:
    section.add "Action", valid_774696
  var valid_774697 = query.getOrDefault("Version")
  valid_774697 = validateParameter(valid_774697, JString, required = true,
                                 default = newJString("2013-09-09"))
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

proc call*(call_774705: Call_GetListTagsForResource_774691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774705.validator(path, query, header, formData, body)
  let scheme = call_774705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774705.url(scheme.get, call_774705.host, call_774705.base,
                         call_774705.route, valid.getOrDefault("path"))
  result = hook(call_774705, url, valid)

proc call*(call_774706: Call_GetListTagsForResource_774691; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2013-09-09"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774707 = newJObject()
  if Filters != nil:
    query_774707.add "Filters", Filters
  add(query_774707, "ResourceName", newJString(ResourceName))
  add(query_774707, "Action", newJString(Action))
  add(query_774707, "Version", newJString(Version))
  result = call_774706.call(nil, query_774707, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_774691(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_774692, base: "/",
    url: url_GetListTagsForResource_774693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_774759 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBInstance_774761(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBInstance_774760(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774762 = query.getOrDefault("Action")
  valid_774762 = validateParameter(valid_774762, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_774762 != nil:
    section.add "Action", valid_774762
  var valid_774763 = query.getOrDefault("Version")
  valid_774763 = validateParameter(valid_774763, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774763 != nil:
    section.add "Version", valid_774763
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774764 = header.getOrDefault("X-Amz-Date")
  valid_774764 = validateParameter(valid_774764, JString, required = false,
                                 default = nil)
  if valid_774764 != nil:
    section.add "X-Amz-Date", valid_774764
  var valid_774765 = header.getOrDefault("X-Amz-Security-Token")
  valid_774765 = validateParameter(valid_774765, JString, required = false,
                                 default = nil)
  if valid_774765 != nil:
    section.add "X-Amz-Security-Token", valid_774765
  var valid_774766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774766 = validateParameter(valid_774766, JString, required = false,
                                 default = nil)
  if valid_774766 != nil:
    section.add "X-Amz-Content-Sha256", valid_774766
  var valid_774767 = header.getOrDefault("X-Amz-Algorithm")
  valid_774767 = validateParameter(valid_774767, JString, required = false,
                                 default = nil)
  if valid_774767 != nil:
    section.add "X-Amz-Algorithm", valid_774767
  var valid_774768 = header.getOrDefault("X-Amz-Signature")
  valid_774768 = validateParameter(valid_774768, JString, required = false,
                                 default = nil)
  if valid_774768 != nil:
    section.add "X-Amz-Signature", valid_774768
  var valid_774769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774769 = validateParameter(valid_774769, JString, required = false,
                                 default = nil)
  if valid_774769 != nil:
    section.add "X-Amz-SignedHeaders", valid_774769
  var valid_774770 = header.getOrDefault("X-Amz-Credential")
  valid_774770 = validateParameter(valid_774770, JString, required = false,
                                 default = nil)
  if valid_774770 != nil:
    section.add "X-Amz-Credential", valid_774770
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
  var valid_774771 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_774771 = validateParameter(valid_774771, JString, required = false,
                                 default = nil)
  if valid_774771 != nil:
    section.add "PreferredMaintenanceWindow", valid_774771
  var valid_774772 = formData.getOrDefault("DBSecurityGroups")
  valid_774772 = validateParameter(valid_774772, JArray, required = false,
                                 default = nil)
  if valid_774772 != nil:
    section.add "DBSecurityGroups", valid_774772
  var valid_774773 = formData.getOrDefault("ApplyImmediately")
  valid_774773 = validateParameter(valid_774773, JBool, required = false, default = nil)
  if valid_774773 != nil:
    section.add "ApplyImmediately", valid_774773
  var valid_774774 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_774774 = validateParameter(valid_774774, JArray, required = false,
                                 default = nil)
  if valid_774774 != nil:
    section.add "VpcSecurityGroupIds", valid_774774
  var valid_774775 = formData.getOrDefault("Iops")
  valid_774775 = validateParameter(valid_774775, JInt, required = false, default = nil)
  if valid_774775 != nil:
    section.add "Iops", valid_774775
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774776 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774776 = validateParameter(valid_774776, JString, required = true,
                                 default = nil)
  if valid_774776 != nil:
    section.add "DBInstanceIdentifier", valid_774776
  var valid_774777 = formData.getOrDefault("BackupRetentionPeriod")
  valid_774777 = validateParameter(valid_774777, JInt, required = false, default = nil)
  if valid_774777 != nil:
    section.add "BackupRetentionPeriod", valid_774777
  var valid_774778 = formData.getOrDefault("DBParameterGroupName")
  valid_774778 = validateParameter(valid_774778, JString, required = false,
                                 default = nil)
  if valid_774778 != nil:
    section.add "DBParameterGroupName", valid_774778
  var valid_774779 = formData.getOrDefault("OptionGroupName")
  valid_774779 = validateParameter(valid_774779, JString, required = false,
                                 default = nil)
  if valid_774779 != nil:
    section.add "OptionGroupName", valid_774779
  var valid_774780 = formData.getOrDefault("MasterUserPassword")
  valid_774780 = validateParameter(valid_774780, JString, required = false,
                                 default = nil)
  if valid_774780 != nil:
    section.add "MasterUserPassword", valid_774780
  var valid_774781 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_774781 = validateParameter(valid_774781, JString, required = false,
                                 default = nil)
  if valid_774781 != nil:
    section.add "NewDBInstanceIdentifier", valid_774781
  var valid_774782 = formData.getOrDefault("MultiAZ")
  valid_774782 = validateParameter(valid_774782, JBool, required = false, default = nil)
  if valid_774782 != nil:
    section.add "MultiAZ", valid_774782
  var valid_774783 = formData.getOrDefault("AllocatedStorage")
  valid_774783 = validateParameter(valid_774783, JInt, required = false, default = nil)
  if valid_774783 != nil:
    section.add "AllocatedStorage", valid_774783
  var valid_774784 = formData.getOrDefault("DBInstanceClass")
  valid_774784 = validateParameter(valid_774784, JString, required = false,
                                 default = nil)
  if valid_774784 != nil:
    section.add "DBInstanceClass", valid_774784
  var valid_774785 = formData.getOrDefault("PreferredBackupWindow")
  valid_774785 = validateParameter(valid_774785, JString, required = false,
                                 default = nil)
  if valid_774785 != nil:
    section.add "PreferredBackupWindow", valid_774785
  var valid_774786 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_774786 = validateParameter(valid_774786, JBool, required = false, default = nil)
  if valid_774786 != nil:
    section.add "AutoMinorVersionUpgrade", valid_774786
  var valid_774787 = formData.getOrDefault("EngineVersion")
  valid_774787 = validateParameter(valid_774787, JString, required = false,
                                 default = nil)
  if valid_774787 != nil:
    section.add "EngineVersion", valid_774787
  var valid_774788 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_774788 = validateParameter(valid_774788, JBool, required = false, default = nil)
  if valid_774788 != nil:
    section.add "AllowMajorVersionUpgrade", valid_774788
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774789: Call_PostModifyDBInstance_774759; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774789.validator(path, query, header, formData, body)
  let scheme = call_774789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774789.url(scheme.get, call_774789.host, call_774789.base,
                         call_774789.route, valid.getOrDefault("path"))
  result = hook(call_774789, url, valid)

proc call*(call_774790: Call_PostModifyDBInstance_774759;
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
  var query_774791 = newJObject()
  var formData_774792 = newJObject()
  add(formData_774792, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_774792.add "DBSecurityGroups", DBSecurityGroups
  add(formData_774792, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_774792.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_774792, "Iops", newJInt(Iops))
  add(formData_774792, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774792, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_774792, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_774792, "OptionGroupName", newJString(OptionGroupName))
  add(formData_774792, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_774792, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_774792, "MultiAZ", newJBool(MultiAZ))
  add(query_774791, "Action", newJString(Action))
  add(formData_774792, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_774792, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_774792, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_774792, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_774792, "EngineVersion", newJString(EngineVersion))
  add(query_774791, "Version", newJString(Version))
  add(formData_774792, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_774790.call(nil, query_774791, nil, formData_774792, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_774759(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_774760, base: "/",
    url: url_PostModifyDBInstance_774761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_774726 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBInstance_774728(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBInstance_774727(path: JsonNode; query: JsonNode;
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
  var valid_774729 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_774729 = validateParameter(valid_774729, JString, required = false,
                                 default = nil)
  if valid_774729 != nil:
    section.add "PreferredMaintenanceWindow", valid_774729
  var valid_774730 = query.getOrDefault("AllocatedStorage")
  valid_774730 = validateParameter(valid_774730, JInt, required = false, default = nil)
  if valid_774730 != nil:
    section.add "AllocatedStorage", valid_774730
  var valid_774731 = query.getOrDefault("OptionGroupName")
  valid_774731 = validateParameter(valid_774731, JString, required = false,
                                 default = nil)
  if valid_774731 != nil:
    section.add "OptionGroupName", valid_774731
  var valid_774732 = query.getOrDefault("DBSecurityGroups")
  valid_774732 = validateParameter(valid_774732, JArray, required = false,
                                 default = nil)
  if valid_774732 != nil:
    section.add "DBSecurityGroups", valid_774732
  var valid_774733 = query.getOrDefault("MasterUserPassword")
  valid_774733 = validateParameter(valid_774733, JString, required = false,
                                 default = nil)
  if valid_774733 != nil:
    section.add "MasterUserPassword", valid_774733
  var valid_774734 = query.getOrDefault("Iops")
  valid_774734 = validateParameter(valid_774734, JInt, required = false, default = nil)
  if valid_774734 != nil:
    section.add "Iops", valid_774734
  var valid_774735 = query.getOrDefault("VpcSecurityGroupIds")
  valid_774735 = validateParameter(valid_774735, JArray, required = false,
                                 default = nil)
  if valid_774735 != nil:
    section.add "VpcSecurityGroupIds", valid_774735
  var valid_774736 = query.getOrDefault("MultiAZ")
  valid_774736 = validateParameter(valid_774736, JBool, required = false, default = nil)
  if valid_774736 != nil:
    section.add "MultiAZ", valid_774736
  var valid_774737 = query.getOrDefault("BackupRetentionPeriod")
  valid_774737 = validateParameter(valid_774737, JInt, required = false, default = nil)
  if valid_774737 != nil:
    section.add "BackupRetentionPeriod", valid_774737
  var valid_774738 = query.getOrDefault("DBParameterGroupName")
  valid_774738 = validateParameter(valid_774738, JString, required = false,
                                 default = nil)
  if valid_774738 != nil:
    section.add "DBParameterGroupName", valid_774738
  var valid_774739 = query.getOrDefault("DBInstanceClass")
  valid_774739 = validateParameter(valid_774739, JString, required = false,
                                 default = nil)
  if valid_774739 != nil:
    section.add "DBInstanceClass", valid_774739
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774740 = query.getOrDefault("Action")
  valid_774740 = validateParameter(valid_774740, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_774740 != nil:
    section.add "Action", valid_774740
  var valid_774741 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_774741 = validateParameter(valid_774741, JBool, required = false, default = nil)
  if valid_774741 != nil:
    section.add "AllowMajorVersionUpgrade", valid_774741
  var valid_774742 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_774742 = validateParameter(valid_774742, JString, required = false,
                                 default = nil)
  if valid_774742 != nil:
    section.add "NewDBInstanceIdentifier", valid_774742
  var valid_774743 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_774743 = validateParameter(valid_774743, JBool, required = false, default = nil)
  if valid_774743 != nil:
    section.add "AutoMinorVersionUpgrade", valid_774743
  var valid_774744 = query.getOrDefault("EngineVersion")
  valid_774744 = validateParameter(valid_774744, JString, required = false,
                                 default = nil)
  if valid_774744 != nil:
    section.add "EngineVersion", valid_774744
  var valid_774745 = query.getOrDefault("PreferredBackupWindow")
  valid_774745 = validateParameter(valid_774745, JString, required = false,
                                 default = nil)
  if valid_774745 != nil:
    section.add "PreferredBackupWindow", valid_774745
  var valid_774746 = query.getOrDefault("Version")
  valid_774746 = validateParameter(valid_774746, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774746 != nil:
    section.add "Version", valid_774746
  var valid_774747 = query.getOrDefault("DBInstanceIdentifier")
  valid_774747 = validateParameter(valid_774747, JString, required = true,
                                 default = nil)
  if valid_774747 != nil:
    section.add "DBInstanceIdentifier", valid_774747
  var valid_774748 = query.getOrDefault("ApplyImmediately")
  valid_774748 = validateParameter(valid_774748, JBool, required = false, default = nil)
  if valid_774748 != nil:
    section.add "ApplyImmediately", valid_774748
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774749 = header.getOrDefault("X-Amz-Date")
  valid_774749 = validateParameter(valid_774749, JString, required = false,
                                 default = nil)
  if valid_774749 != nil:
    section.add "X-Amz-Date", valid_774749
  var valid_774750 = header.getOrDefault("X-Amz-Security-Token")
  valid_774750 = validateParameter(valid_774750, JString, required = false,
                                 default = nil)
  if valid_774750 != nil:
    section.add "X-Amz-Security-Token", valid_774750
  var valid_774751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774751 = validateParameter(valid_774751, JString, required = false,
                                 default = nil)
  if valid_774751 != nil:
    section.add "X-Amz-Content-Sha256", valid_774751
  var valid_774752 = header.getOrDefault("X-Amz-Algorithm")
  valid_774752 = validateParameter(valid_774752, JString, required = false,
                                 default = nil)
  if valid_774752 != nil:
    section.add "X-Amz-Algorithm", valid_774752
  var valid_774753 = header.getOrDefault("X-Amz-Signature")
  valid_774753 = validateParameter(valid_774753, JString, required = false,
                                 default = nil)
  if valid_774753 != nil:
    section.add "X-Amz-Signature", valid_774753
  var valid_774754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774754 = validateParameter(valid_774754, JString, required = false,
                                 default = nil)
  if valid_774754 != nil:
    section.add "X-Amz-SignedHeaders", valid_774754
  var valid_774755 = header.getOrDefault("X-Amz-Credential")
  valid_774755 = validateParameter(valid_774755, JString, required = false,
                                 default = nil)
  if valid_774755 != nil:
    section.add "X-Amz-Credential", valid_774755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774756: Call_GetModifyDBInstance_774726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774756.validator(path, query, header, formData, body)
  let scheme = call_774756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774756.url(scheme.get, call_774756.host, call_774756.base,
                         call_774756.route, valid.getOrDefault("path"))
  result = hook(call_774756, url, valid)

proc call*(call_774757: Call_GetModifyDBInstance_774726;
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
  var query_774758 = newJObject()
  add(query_774758, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_774758, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_774758, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_774758.add "DBSecurityGroups", DBSecurityGroups
  add(query_774758, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_774758, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_774758.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_774758, "MultiAZ", newJBool(MultiAZ))
  add(query_774758, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_774758, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_774758, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774758, "Action", newJString(Action))
  add(query_774758, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_774758, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_774758, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_774758, "EngineVersion", newJString(EngineVersion))
  add(query_774758, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_774758, "Version", newJString(Version))
  add(query_774758, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_774758, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_774757.call(nil, query_774758, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_774726(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_774727, base: "/",
    url: url_GetModifyDBInstance_774728, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_774810 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBParameterGroup_774812(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBParameterGroup_774811(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774813 = query.getOrDefault("Action")
  valid_774813 = validateParameter(valid_774813, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_774813 != nil:
    section.add "Action", valid_774813
  var valid_774814 = query.getOrDefault("Version")
  valid_774814 = validateParameter(valid_774814, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774814 != nil:
    section.add "Version", valid_774814
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_774822 = formData.getOrDefault("DBParameterGroupName")
  valid_774822 = validateParameter(valid_774822, JString, required = true,
                                 default = nil)
  if valid_774822 != nil:
    section.add "DBParameterGroupName", valid_774822
  var valid_774823 = formData.getOrDefault("Parameters")
  valid_774823 = validateParameter(valid_774823, JArray, required = true, default = nil)
  if valid_774823 != nil:
    section.add "Parameters", valid_774823
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774824: Call_PostModifyDBParameterGroup_774810; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774824.validator(path, query, header, formData, body)
  let scheme = call_774824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774824.url(scheme.get, call_774824.host, call_774824.base,
                         call_774824.route, valid.getOrDefault("path"))
  result = hook(call_774824, url, valid)

proc call*(call_774825: Call_PostModifyDBParameterGroup_774810;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774826 = newJObject()
  var formData_774827 = newJObject()
  add(formData_774827, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_774827.add "Parameters", Parameters
  add(query_774826, "Action", newJString(Action))
  add(query_774826, "Version", newJString(Version))
  result = call_774825.call(nil, query_774826, nil, formData_774827, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_774810(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_774811, base: "/",
    url: url_PostModifyDBParameterGroup_774812,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_774793 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBParameterGroup_774795(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBParameterGroup_774794(path: JsonNode; query: JsonNode;
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
  var valid_774796 = query.getOrDefault("DBParameterGroupName")
  valid_774796 = validateParameter(valid_774796, JString, required = true,
                                 default = nil)
  if valid_774796 != nil:
    section.add "DBParameterGroupName", valid_774796
  var valid_774797 = query.getOrDefault("Parameters")
  valid_774797 = validateParameter(valid_774797, JArray, required = true, default = nil)
  if valid_774797 != nil:
    section.add "Parameters", valid_774797
  var valid_774798 = query.getOrDefault("Action")
  valid_774798 = validateParameter(valid_774798, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_774798 != nil:
    section.add "Action", valid_774798
  var valid_774799 = query.getOrDefault("Version")
  valid_774799 = validateParameter(valid_774799, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774799 != nil:
    section.add "Version", valid_774799
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774800 = header.getOrDefault("X-Amz-Date")
  valid_774800 = validateParameter(valid_774800, JString, required = false,
                                 default = nil)
  if valid_774800 != nil:
    section.add "X-Amz-Date", valid_774800
  var valid_774801 = header.getOrDefault("X-Amz-Security-Token")
  valid_774801 = validateParameter(valid_774801, JString, required = false,
                                 default = nil)
  if valid_774801 != nil:
    section.add "X-Amz-Security-Token", valid_774801
  var valid_774802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774802 = validateParameter(valid_774802, JString, required = false,
                                 default = nil)
  if valid_774802 != nil:
    section.add "X-Amz-Content-Sha256", valid_774802
  var valid_774803 = header.getOrDefault("X-Amz-Algorithm")
  valid_774803 = validateParameter(valid_774803, JString, required = false,
                                 default = nil)
  if valid_774803 != nil:
    section.add "X-Amz-Algorithm", valid_774803
  var valid_774804 = header.getOrDefault("X-Amz-Signature")
  valid_774804 = validateParameter(valid_774804, JString, required = false,
                                 default = nil)
  if valid_774804 != nil:
    section.add "X-Amz-Signature", valid_774804
  var valid_774805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774805 = validateParameter(valid_774805, JString, required = false,
                                 default = nil)
  if valid_774805 != nil:
    section.add "X-Amz-SignedHeaders", valid_774805
  var valid_774806 = header.getOrDefault("X-Amz-Credential")
  valid_774806 = validateParameter(valid_774806, JString, required = false,
                                 default = nil)
  if valid_774806 != nil:
    section.add "X-Amz-Credential", valid_774806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774807: Call_GetModifyDBParameterGroup_774793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774807.validator(path, query, header, formData, body)
  let scheme = call_774807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774807.url(scheme.get, call_774807.host, call_774807.base,
                         call_774807.route, valid.getOrDefault("path"))
  result = hook(call_774807, url, valid)

proc call*(call_774808: Call_GetModifyDBParameterGroup_774793;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774809 = newJObject()
  add(query_774809, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_774809.add "Parameters", Parameters
  add(query_774809, "Action", newJString(Action))
  add(query_774809, "Version", newJString(Version))
  result = call_774808.call(nil, query_774809, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_774793(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_774794, base: "/",
    url: url_GetModifyDBParameterGroup_774795,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_774846 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBSubnetGroup_774848(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBSubnetGroup_774847(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774849 = query.getOrDefault("Action")
  valid_774849 = validateParameter(valid_774849, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_774849 != nil:
    section.add "Action", valid_774849
  var valid_774850 = query.getOrDefault("Version")
  valid_774850 = validateParameter(valid_774850, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774850 != nil:
    section.add "Version", valid_774850
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774851 = header.getOrDefault("X-Amz-Date")
  valid_774851 = validateParameter(valid_774851, JString, required = false,
                                 default = nil)
  if valid_774851 != nil:
    section.add "X-Amz-Date", valid_774851
  var valid_774852 = header.getOrDefault("X-Amz-Security-Token")
  valid_774852 = validateParameter(valid_774852, JString, required = false,
                                 default = nil)
  if valid_774852 != nil:
    section.add "X-Amz-Security-Token", valid_774852
  var valid_774853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774853 = validateParameter(valid_774853, JString, required = false,
                                 default = nil)
  if valid_774853 != nil:
    section.add "X-Amz-Content-Sha256", valid_774853
  var valid_774854 = header.getOrDefault("X-Amz-Algorithm")
  valid_774854 = validateParameter(valid_774854, JString, required = false,
                                 default = nil)
  if valid_774854 != nil:
    section.add "X-Amz-Algorithm", valid_774854
  var valid_774855 = header.getOrDefault("X-Amz-Signature")
  valid_774855 = validateParameter(valid_774855, JString, required = false,
                                 default = nil)
  if valid_774855 != nil:
    section.add "X-Amz-Signature", valid_774855
  var valid_774856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774856 = validateParameter(valid_774856, JString, required = false,
                                 default = nil)
  if valid_774856 != nil:
    section.add "X-Amz-SignedHeaders", valid_774856
  var valid_774857 = header.getOrDefault("X-Amz-Credential")
  valid_774857 = validateParameter(valid_774857, JString, required = false,
                                 default = nil)
  if valid_774857 != nil:
    section.add "X-Amz-Credential", valid_774857
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_774858 = formData.getOrDefault("DBSubnetGroupName")
  valid_774858 = validateParameter(valid_774858, JString, required = true,
                                 default = nil)
  if valid_774858 != nil:
    section.add "DBSubnetGroupName", valid_774858
  var valid_774859 = formData.getOrDefault("SubnetIds")
  valid_774859 = validateParameter(valid_774859, JArray, required = true, default = nil)
  if valid_774859 != nil:
    section.add "SubnetIds", valid_774859
  var valid_774860 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_774860 = validateParameter(valid_774860, JString, required = false,
                                 default = nil)
  if valid_774860 != nil:
    section.add "DBSubnetGroupDescription", valid_774860
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774861: Call_PostModifyDBSubnetGroup_774846; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774861.validator(path, query, header, formData, body)
  let scheme = call_774861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774861.url(scheme.get, call_774861.host, call_774861.base,
                         call_774861.route, valid.getOrDefault("path"))
  result = hook(call_774861, url, valid)

proc call*(call_774862: Call_PostModifyDBSubnetGroup_774846;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_774863 = newJObject()
  var formData_774864 = newJObject()
  add(formData_774864, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_774864.add "SubnetIds", SubnetIds
  add(query_774863, "Action", newJString(Action))
  add(formData_774864, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_774863, "Version", newJString(Version))
  result = call_774862.call(nil, query_774863, nil, formData_774864, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_774846(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_774847, base: "/",
    url: url_PostModifyDBSubnetGroup_774848, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_774828 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBSubnetGroup_774830(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBSubnetGroup_774829(path: JsonNode; query: JsonNode;
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
  var valid_774831 = query.getOrDefault("Action")
  valid_774831 = validateParameter(valid_774831, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_774831 != nil:
    section.add "Action", valid_774831
  var valid_774832 = query.getOrDefault("DBSubnetGroupName")
  valid_774832 = validateParameter(valid_774832, JString, required = true,
                                 default = nil)
  if valid_774832 != nil:
    section.add "DBSubnetGroupName", valid_774832
  var valid_774833 = query.getOrDefault("SubnetIds")
  valid_774833 = validateParameter(valid_774833, JArray, required = true, default = nil)
  if valid_774833 != nil:
    section.add "SubnetIds", valid_774833
  var valid_774834 = query.getOrDefault("DBSubnetGroupDescription")
  valid_774834 = validateParameter(valid_774834, JString, required = false,
                                 default = nil)
  if valid_774834 != nil:
    section.add "DBSubnetGroupDescription", valid_774834
  var valid_774835 = query.getOrDefault("Version")
  valid_774835 = validateParameter(valid_774835, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774835 != nil:
    section.add "Version", valid_774835
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774836 = header.getOrDefault("X-Amz-Date")
  valid_774836 = validateParameter(valid_774836, JString, required = false,
                                 default = nil)
  if valid_774836 != nil:
    section.add "X-Amz-Date", valid_774836
  var valid_774837 = header.getOrDefault("X-Amz-Security-Token")
  valid_774837 = validateParameter(valid_774837, JString, required = false,
                                 default = nil)
  if valid_774837 != nil:
    section.add "X-Amz-Security-Token", valid_774837
  var valid_774838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774838 = validateParameter(valid_774838, JString, required = false,
                                 default = nil)
  if valid_774838 != nil:
    section.add "X-Amz-Content-Sha256", valid_774838
  var valid_774839 = header.getOrDefault("X-Amz-Algorithm")
  valid_774839 = validateParameter(valid_774839, JString, required = false,
                                 default = nil)
  if valid_774839 != nil:
    section.add "X-Amz-Algorithm", valid_774839
  var valid_774840 = header.getOrDefault("X-Amz-Signature")
  valid_774840 = validateParameter(valid_774840, JString, required = false,
                                 default = nil)
  if valid_774840 != nil:
    section.add "X-Amz-Signature", valid_774840
  var valid_774841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774841 = validateParameter(valid_774841, JString, required = false,
                                 default = nil)
  if valid_774841 != nil:
    section.add "X-Amz-SignedHeaders", valid_774841
  var valid_774842 = header.getOrDefault("X-Amz-Credential")
  valid_774842 = validateParameter(valid_774842, JString, required = false,
                                 default = nil)
  if valid_774842 != nil:
    section.add "X-Amz-Credential", valid_774842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774843: Call_GetModifyDBSubnetGroup_774828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774843.validator(path, query, header, formData, body)
  let scheme = call_774843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774843.url(scheme.get, call_774843.host, call_774843.base,
                         call_774843.route, valid.getOrDefault("path"))
  result = hook(call_774843, url, valid)

proc call*(call_774844: Call_GetModifyDBSubnetGroup_774828;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_774845 = newJObject()
  add(query_774845, "Action", newJString(Action))
  add(query_774845, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_774845.add "SubnetIds", SubnetIds
  add(query_774845, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_774845, "Version", newJString(Version))
  result = call_774844.call(nil, query_774845, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_774828(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_774829, base: "/",
    url: url_GetModifyDBSubnetGroup_774830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_774885 = ref object of OpenApiRestCall_772581
proc url_PostModifyEventSubscription_774887(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyEventSubscription_774886(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774888 = query.getOrDefault("Action")
  valid_774888 = validateParameter(valid_774888, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_774888 != nil:
    section.add "Action", valid_774888
  var valid_774889 = query.getOrDefault("Version")
  valid_774889 = validateParameter(valid_774889, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774889 != nil:
    section.add "Version", valid_774889
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774890 = header.getOrDefault("X-Amz-Date")
  valid_774890 = validateParameter(valid_774890, JString, required = false,
                                 default = nil)
  if valid_774890 != nil:
    section.add "X-Amz-Date", valid_774890
  var valid_774891 = header.getOrDefault("X-Amz-Security-Token")
  valid_774891 = validateParameter(valid_774891, JString, required = false,
                                 default = nil)
  if valid_774891 != nil:
    section.add "X-Amz-Security-Token", valid_774891
  var valid_774892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774892 = validateParameter(valid_774892, JString, required = false,
                                 default = nil)
  if valid_774892 != nil:
    section.add "X-Amz-Content-Sha256", valid_774892
  var valid_774893 = header.getOrDefault("X-Amz-Algorithm")
  valid_774893 = validateParameter(valid_774893, JString, required = false,
                                 default = nil)
  if valid_774893 != nil:
    section.add "X-Amz-Algorithm", valid_774893
  var valid_774894 = header.getOrDefault("X-Amz-Signature")
  valid_774894 = validateParameter(valid_774894, JString, required = false,
                                 default = nil)
  if valid_774894 != nil:
    section.add "X-Amz-Signature", valid_774894
  var valid_774895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774895 = validateParameter(valid_774895, JString, required = false,
                                 default = nil)
  if valid_774895 != nil:
    section.add "X-Amz-SignedHeaders", valid_774895
  var valid_774896 = header.getOrDefault("X-Amz-Credential")
  valid_774896 = validateParameter(valid_774896, JString, required = false,
                                 default = nil)
  if valid_774896 != nil:
    section.add "X-Amz-Credential", valid_774896
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_774897 = formData.getOrDefault("Enabled")
  valid_774897 = validateParameter(valid_774897, JBool, required = false, default = nil)
  if valid_774897 != nil:
    section.add "Enabled", valid_774897
  var valid_774898 = formData.getOrDefault("EventCategories")
  valid_774898 = validateParameter(valid_774898, JArray, required = false,
                                 default = nil)
  if valid_774898 != nil:
    section.add "EventCategories", valid_774898
  var valid_774899 = formData.getOrDefault("SnsTopicArn")
  valid_774899 = validateParameter(valid_774899, JString, required = false,
                                 default = nil)
  if valid_774899 != nil:
    section.add "SnsTopicArn", valid_774899
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_774900 = formData.getOrDefault("SubscriptionName")
  valid_774900 = validateParameter(valid_774900, JString, required = true,
                                 default = nil)
  if valid_774900 != nil:
    section.add "SubscriptionName", valid_774900
  var valid_774901 = formData.getOrDefault("SourceType")
  valid_774901 = validateParameter(valid_774901, JString, required = false,
                                 default = nil)
  if valid_774901 != nil:
    section.add "SourceType", valid_774901
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774902: Call_PostModifyEventSubscription_774885; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774902.validator(path, query, header, formData, body)
  let scheme = call_774902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774902.url(scheme.get, call_774902.host, call_774902.base,
                         call_774902.route, valid.getOrDefault("path"))
  result = hook(call_774902, url, valid)

proc call*(call_774903: Call_PostModifyEventSubscription_774885;
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
  var query_774904 = newJObject()
  var formData_774905 = newJObject()
  add(formData_774905, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_774905.add "EventCategories", EventCategories
  add(formData_774905, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_774905, "SubscriptionName", newJString(SubscriptionName))
  add(query_774904, "Action", newJString(Action))
  add(query_774904, "Version", newJString(Version))
  add(formData_774905, "SourceType", newJString(SourceType))
  result = call_774903.call(nil, query_774904, nil, formData_774905, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_774885(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_774886, base: "/",
    url: url_PostModifyEventSubscription_774887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_774865 = ref object of OpenApiRestCall_772581
proc url_GetModifyEventSubscription_774867(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyEventSubscription_774866(path: JsonNode; query: JsonNode;
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
  var valid_774868 = query.getOrDefault("SourceType")
  valid_774868 = validateParameter(valid_774868, JString, required = false,
                                 default = nil)
  if valid_774868 != nil:
    section.add "SourceType", valid_774868
  var valid_774869 = query.getOrDefault("Enabled")
  valid_774869 = validateParameter(valid_774869, JBool, required = false, default = nil)
  if valid_774869 != nil:
    section.add "Enabled", valid_774869
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774870 = query.getOrDefault("Action")
  valid_774870 = validateParameter(valid_774870, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_774870 != nil:
    section.add "Action", valid_774870
  var valid_774871 = query.getOrDefault("SnsTopicArn")
  valid_774871 = validateParameter(valid_774871, JString, required = false,
                                 default = nil)
  if valid_774871 != nil:
    section.add "SnsTopicArn", valid_774871
  var valid_774872 = query.getOrDefault("EventCategories")
  valid_774872 = validateParameter(valid_774872, JArray, required = false,
                                 default = nil)
  if valid_774872 != nil:
    section.add "EventCategories", valid_774872
  var valid_774873 = query.getOrDefault("SubscriptionName")
  valid_774873 = validateParameter(valid_774873, JString, required = true,
                                 default = nil)
  if valid_774873 != nil:
    section.add "SubscriptionName", valid_774873
  var valid_774874 = query.getOrDefault("Version")
  valid_774874 = validateParameter(valid_774874, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774874 != nil:
    section.add "Version", valid_774874
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774875 = header.getOrDefault("X-Amz-Date")
  valid_774875 = validateParameter(valid_774875, JString, required = false,
                                 default = nil)
  if valid_774875 != nil:
    section.add "X-Amz-Date", valid_774875
  var valid_774876 = header.getOrDefault("X-Amz-Security-Token")
  valid_774876 = validateParameter(valid_774876, JString, required = false,
                                 default = nil)
  if valid_774876 != nil:
    section.add "X-Amz-Security-Token", valid_774876
  var valid_774877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774877 = validateParameter(valid_774877, JString, required = false,
                                 default = nil)
  if valid_774877 != nil:
    section.add "X-Amz-Content-Sha256", valid_774877
  var valid_774878 = header.getOrDefault("X-Amz-Algorithm")
  valid_774878 = validateParameter(valid_774878, JString, required = false,
                                 default = nil)
  if valid_774878 != nil:
    section.add "X-Amz-Algorithm", valid_774878
  var valid_774879 = header.getOrDefault("X-Amz-Signature")
  valid_774879 = validateParameter(valid_774879, JString, required = false,
                                 default = nil)
  if valid_774879 != nil:
    section.add "X-Amz-Signature", valid_774879
  var valid_774880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774880 = validateParameter(valid_774880, JString, required = false,
                                 default = nil)
  if valid_774880 != nil:
    section.add "X-Amz-SignedHeaders", valid_774880
  var valid_774881 = header.getOrDefault("X-Amz-Credential")
  valid_774881 = validateParameter(valid_774881, JString, required = false,
                                 default = nil)
  if valid_774881 != nil:
    section.add "X-Amz-Credential", valid_774881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774882: Call_GetModifyEventSubscription_774865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774882.validator(path, query, header, formData, body)
  let scheme = call_774882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774882.url(scheme.get, call_774882.host, call_774882.base,
                         call_774882.route, valid.getOrDefault("path"))
  result = hook(call_774882, url, valid)

proc call*(call_774883: Call_GetModifyEventSubscription_774865;
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
  var query_774884 = newJObject()
  add(query_774884, "SourceType", newJString(SourceType))
  add(query_774884, "Enabled", newJBool(Enabled))
  add(query_774884, "Action", newJString(Action))
  add(query_774884, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_774884.add "EventCategories", EventCategories
  add(query_774884, "SubscriptionName", newJString(SubscriptionName))
  add(query_774884, "Version", newJString(Version))
  result = call_774883.call(nil, query_774884, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_774865(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_774866, base: "/",
    url: url_GetModifyEventSubscription_774867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_774925 = ref object of OpenApiRestCall_772581
proc url_PostModifyOptionGroup_774927(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyOptionGroup_774926(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774928 = query.getOrDefault("Action")
  valid_774928 = validateParameter(valid_774928, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_774928 != nil:
    section.add "Action", valid_774928
  var valid_774929 = query.getOrDefault("Version")
  valid_774929 = validateParameter(valid_774929, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774929 != nil:
    section.add "Version", valid_774929
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774930 = header.getOrDefault("X-Amz-Date")
  valid_774930 = validateParameter(valid_774930, JString, required = false,
                                 default = nil)
  if valid_774930 != nil:
    section.add "X-Amz-Date", valid_774930
  var valid_774931 = header.getOrDefault("X-Amz-Security-Token")
  valid_774931 = validateParameter(valid_774931, JString, required = false,
                                 default = nil)
  if valid_774931 != nil:
    section.add "X-Amz-Security-Token", valid_774931
  var valid_774932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774932 = validateParameter(valid_774932, JString, required = false,
                                 default = nil)
  if valid_774932 != nil:
    section.add "X-Amz-Content-Sha256", valid_774932
  var valid_774933 = header.getOrDefault("X-Amz-Algorithm")
  valid_774933 = validateParameter(valid_774933, JString, required = false,
                                 default = nil)
  if valid_774933 != nil:
    section.add "X-Amz-Algorithm", valid_774933
  var valid_774934 = header.getOrDefault("X-Amz-Signature")
  valid_774934 = validateParameter(valid_774934, JString, required = false,
                                 default = nil)
  if valid_774934 != nil:
    section.add "X-Amz-Signature", valid_774934
  var valid_774935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774935 = validateParameter(valid_774935, JString, required = false,
                                 default = nil)
  if valid_774935 != nil:
    section.add "X-Amz-SignedHeaders", valid_774935
  var valid_774936 = header.getOrDefault("X-Amz-Credential")
  valid_774936 = validateParameter(valid_774936, JString, required = false,
                                 default = nil)
  if valid_774936 != nil:
    section.add "X-Amz-Credential", valid_774936
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_774937 = formData.getOrDefault("OptionsToRemove")
  valid_774937 = validateParameter(valid_774937, JArray, required = false,
                                 default = nil)
  if valid_774937 != nil:
    section.add "OptionsToRemove", valid_774937
  var valid_774938 = formData.getOrDefault("ApplyImmediately")
  valid_774938 = validateParameter(valid_774938, JBool, required = false, default = nil)
  if valid_774938 != nil:
    section.add "ApplyImmediately", valid_774938
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_774939 = formData.getOrDefault("OptionGroupName")
  valid_774939 = validateParameter(valid_774939, JString, required = true,
                                 default = nil)
  if valid_774939 != nil:
    section.add "OptionGroupName", valid_774939
  var valid_774940 = formData.getOrDefault("OptionsToInclude")
  valid_774940 = validateParameter(valid_774940, JArray, required = false,
                                 default = nil)
  if valid_774940 != nil:
    section.add "OptionsToInclude", valid_774940
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774941: Call_PostModifyOptionGroup_774925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774941.validator(path, query, header, formData, body)
  let scheme = call_774941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774941.url(scheme.get, call_774941.host, call_774941.base,
                         call_774941.route, valid.getOrDefault("path"))
  result = hook(call_774941, url, valid)

proc call*(call_774942: Call_PostModifyOptionGroup_774925; OptionGroupName: string;
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
  var query_774943 = newJObject()
  var formData_774944 = newJObject()
  if OptionsToRemove != nil:
    formData_774944.add "OptionsToRemove", OptionsToRemove
  add(formData_774944, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_774944, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_774944.add "OptionsToInclude", OptionsToInclude
  add(query_774943, "Action", newJString(Action))
  add(query_774943, "Version", newJString(Version))
  result = call_774942.call(nil, query_774943, nil, formData_774944, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_774925(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_774926, base: "/",
    url: url_PostModifyOptionGroup_774927, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_774906 = ref object of OpenApiRestCall_772581
proc url_GetModifyOptionGroup_774908(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyOptionGroup_774907(path: JsonNode; query: JsonNode;
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
  var valid_774909 = query.getOrDefault("OptionGroupName")
  valid_774909 = validateParameter(valid_774909, JString, required = true,
                                 default = nil)
  if valid_774909 != nil:
    section.add "OptionGroupName", valid_774909
  var valid_774910 = query.getOrDefault("OptionsToRemove")
  valid_774910 = validateParameter(valid_774910, JArray, required = false,
                                 default = nil)
  if valid_774910 != nil:
    section.add "OptionsToRemove", valid_774910
  var valid_774911 = query.getOrDefault("Action")
  valid_774911 = validateParameter(valid_774911, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_774911 != nil:
    section.add "Action", valid_774911
  var valid_774912 = query.getOrDefault("Version")
  valid_774912 = validateParameter(valid_774912, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774912 != nil:
    section.add "Version", valid_774912
  var valid_774913 = query.getOrDefault("ApplyImmediately")
  valid_774913 = validateParameter(valid_774913, JBool, required = false, default = nil)
  if valid_774913 != nil:
    section.add "ApplyImmediately", valid_774913
  var valid_774914 = query.getOrDefault("OptionsToInclude")
  valid_774914 = validateParameter(valid_774914, JArray, required = false,
                                 default = nil)
  if valid_774914 != nil:
    section.add "OptionsToInclude", valid_774914
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774915 = header.getOrDefault("X-Amz-Date")
  valid_774915 = validateParameter(valid_774915, JString, required = false,
                                 default = nil)
  if valid_774915 != nil:
    section.add "X-Amz-Date", valid_774915
  var valid_774916 = header.getOrDefault("X-Amz-Security-Token")
  valid_774916 = validateParameter(valid_774916, JString, required = false,
                                 default = nil)
  if valid_774916 != nil:
    section.add "X-Amz-Security-Token", valid_774916
  var valid_774917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774917 = validateParameter(valid_774917, JString, required = false,
                                 default = nil)
  if valid_774917 != nil:
    section.add "X-Amz-Content-Sha256", valid_774917
  var valid_774918 = header.getOrDefault("X-Amz-Algorithm")
  valid_774918 = validateParameter(valid_774918, JString, required = false,
                                 default = nil)
  if valid_774918 != nil:
    section.add "X-Amz-Algorithm", valid_774918
  var valid_774919 = header.getOrDefault("X-Amz-Signature")
  valid_774919 = validateParameter(valid_774919, JString, required = false,
                                 default = nil)
  if valid_774919 != nil:
    section.add "X-Amz-Signature", valid_774919
  var valid_774920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774920 = validateParameter(valid_774920, JString, required = false,
                                 default = nil)
  if valid_774920 != nil:
    section.add "X-Amz-SignedHeaders", valid_774920
  var valid_774921 = header.getOrDefault("X-Amz-Credential")
  valid_774921 = validateParameter(valid_774921, JString, required = false,
                                 default = nil)
  if valid_774921 != nil:
    section.add "X-Amz-Credential", valid_774921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774922: Call_GetModifyOptionGroup_774906; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774922.validator(path, query, header, formData, body)
  let scheme = call_774922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774922.url(scheme.get, call_774922.host, call_774922.base,
                         call_774922.route, valid.getOrDefault("path"))
  result = hook(call_774922, url, valid)

proc call*(call_774923: Call_GetModifyOptionGroup_774906; OptionGroupName: string;
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
  var query_774924 = newJObject()
  add(query_774924, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_774924.add "OptionsToRemove", OptionsToRemove
  add(query_774924, "Action", newJString(Action))
  add(query_774924, "Version", newJString(Version))
  add(query_774924, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_774924.add "OptionsToInclude", OptionsToInclude
  result = call_774923.call(nil, query_774924, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_774906(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_774907, base: "/",
    url: url_GetModifyOptionGroup_774908, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_774963 = ref object of OpenApiRestCall_772581
proc url_PostPromoteReadReplica_774965(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPromoteReadReplica_774964(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774966 = query.getOrDefault("Action")
  valid_774966 = validateParameter(valid_774966, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_774966 != nil:
    section.add "Action", valid_774966
  var valid_774967 = query.getOrDefault("Version")
  valid_774967 = validateParameter(valid_774967, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774967 != nil:
    section.add "Version", valid_774967
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774968 = header.getOrDefault("X-Amz-Date")
  valid_774968 = validateParameter(valid_774968, JString, required = false,
                                 default = nil)
  if valid_774968 != nil:
    section.add "X-Amz-Date", valid_774968
  var valid_774969 = header.getOrDefault("X-Amz-Security-Token")
  valid_774969 = validateParameter(valid_774969, JString, required = false,
                                 default = nil)
  if valid_774969 != nil:
    section.add "X-Amz-Security-Token", valid_774969
  var valid_774970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774970 = validateParameter(valid_774970, JString, required = false,
                                 default = nil)
  if valid_774970 != nil:
    section.add "X-Amz-Content-Sha256", valid_774970
  var valid_774971 = header.getOrDefault("X-Amz-Algorithm")
  valid_774971 = validateParameter(valid_774971, JString, required = false,
                                 default = nil)
  if valid_774971 != nil:
    section.add "X-Amz-Algorithm", valid_774971
  var valid_774972 = header.getOrDefault("X-Amz-Signature")
  valid_774972 = validateParameter(valid_774972, JString, required = false,
                                 default = nil)
  if valid_774972 != nil:
    section.add "X-Amz-Signature", valid_774972
  var valid_774973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774973 = validateParameter(valid_774973, JString, required = false,
                                 default = nil)
  if valid_774973 != nil:
    section.add "X-Amz-SignedHeaders", valid_774973
  var valid_774974 = header.getOrDefault("X-Amz-Credential")
  valid_774974 = validateParameter(valid_774974, JString, required = false,
                                 default = nil)
  if valid_774974 != nil:
    section.add "X-Amz-Credential", valid_774974
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774975 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774975 = validateParameter(valid_774975, JString, required = true,
                                 default = nil)
  if valid_774975 != nil:
    section.add "DBInstanceIdentifier", valid_774975
  var valid_774976 = formData.getOrDefault("BackupRetentionPeriod")
  valid_774976 = validateParameter(valid_774976, JInt, required = false, default = nil)
  if valid_774976 != nil:
    section.add "BackupRetentionPeriod", valid_774976
  var valid_774977 = formData.getOrDefault("PreferredBackupWindow")
  valid_774977 = validateParameter(valid_774977, JString, required = false,
                                 default = nil)
  if valid_774977 != nil:
    section.add "PreferredBackupWindow", valid_774977
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774978: Call_PostPromoteReadReplica_774963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774978.validator(path, query, header, formData, body)
  let scheme = call_774978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774978.url(scheme.get, call_774978.host, call_774978.base,
                         call_774978.route, valid.getOrDefault("path"))
  result = hook(call_774978, url, valid)

proc call*(call_774979: Call_PostPromoteReadReplica_774963;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_774980 = newJObject()
  var formData_774981 = newJObject()
  add(formData_774981, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774981, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_774980, "Action", newJString(Action))
  add(formData_774981, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_774980, "Version", newJString(Version))
  result = call_774979.call(nil, query_774980, nil, formData_774981, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_774963(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_774964, base: "/",
    url: url_PostPromoteReadReplica_774965, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_774945 = ref object of OpenApiRestCall_772581
proc url_GetPromoteReadReplica_774947(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPromoteReadReplica_774946(path: JsonNode; query: JsonNode;
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
  var valid_774948 = query.getOrDefault("BackupRetentionPeriod")
  valid_774948 = validateParameter(valid_774948, JInt, required = false, default = nil)
  if valid_774948 != nil:
    section.add "BackupRetentionPeriod", valid_774948
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774949 = query.getOrDefault("Action")
  valid_774949 = validateParameter(valid_774949, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_774949 != nil:
    section.add "Action", valid_774949
  var valid_774950 = query.getOrDefault("PreferredBackupWindow")
  valid_774950 = validateParameter(valid_774950, JString, required = false,
                                 default = nil)
  if valid_774950 != nil:
    section.add "PreferredBackupWindow", valid_774950
  var valid_774951 = query.getOrDefault("Version")
  valid_774951 = validateParameter(valid_774951, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774951 != nil:
    section.add "Version", valid_774951
  var valid_774952 = query.getOrDefault("DBInstanceIdentifier")
  valid_774952 = validateParameter(valid_774952, JString, required = true,
                                 default = nil)
  if valid_774952 != nil:
    section.add "DBInstanceIdentifier", valid_774952
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774953 = header.getOrDefault("X-Amz-Date")
  valid_774953 = validateParameter(valid_774953, JString, required = false,
                                 default = nil)
  if valid_774953 != nil:
    section.add "X-Amz-Date", valid_774953
  var valid_774954 = header.getOrDefault("X-Amz-Security-Token")
  valid_774954 = validateParameter(valid_774954, JString, required = false,
                                 default = nil)
  if valid_774954 != nil:
    section.add "X-Amz-Security-Token", valid_774954
  var valid_774955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774955 = validateParameter(valid_774955, JString, required = false,
                                 default = nil)
  if valid_774955 != nil:
    section.add "X-Amz-Content-Sha256", valid_774955
  var valid_774956 = header.getOrDefault("X-Amz-Algorithm")
  valid_774956 = validateParameter(valid_774956, JString, required = false,
                                 default = nil)
  if valid_774956 != nil:
    section.add "X-Amz-Algorithm", valid_774956
  var valid_774957 = header.getOrDefault("X-Amz-Signature")
  valid_774957 = validateParameter(valid_774957, JString, required = false,
                                 default = nil)
  if valid_774957 != nil:
    section.add "X-Amz-Signature", valid_774957
  var valid_774958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774958 = validateParameter(valid_774958, JString, required = false,
                                 default = nil)
  if valid_774958 != nil:
    section.add "X-Amz-SignedHeaders", valid_774958
  var valid_774959 = header.getOrDefault("X-Amz-Credential")
  valid_774959 = validateParameter(valid_774959, JString, required = false,
                                 default = nil)
  if valid_774959 != nil:
    section.add "X-Amz-Credential", valid_774959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774960: Call_GetPromoteReadReplica_774945; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_774960.validator(path, query, header, formData, body)
  let scheme = call_774960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774960.url(scheme.get, call_774960.host, call_774960.base,
                         call_774960.route, valid.getOrDefault("path"))
  result = hook(call_774960, url, valid)

proc call*(call_774961: Call_GetPromoteReadReplica_774945;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_774962 = newJObject()
  add(query_774962, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_774962, "Action", newJString(Action))
  add(query_774962, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_774962, "Version", newJString(Version))
  add(query_774962, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_774961.call(nil, query_774962, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_774945(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_774946, base: "/",
    url: url_GetPromoteReadReplica_774947, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_775001 = ref object of OpenApiRestCall_772581
proc url_PostPurchaseReservedDBInstancesOffering_775003(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPurchaseReservedDBInstancesOffering_775002(path: JsonNode;
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
  var valid_775004 = query.getOrDefault("Action")
  valid_775004 = validateParameter(valid_775004, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_775004 != nil:
    section.add "Action", valid_775004
  var valid_775005 = query.getOrDefault("Version")
  valid_775005 = validateParameter(valid_775005, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_775005 != nil:
    section.add "Version", valid_775005
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775006 = header.getOrDefault("X-Amz-Date")
  valid_775006 = validateParameter(valid_775006, JString, required = false,
                                 default = nil)
  if valid_775006 != nil:
    section.add "X-Amz-Date", valid_775006
  var valid_775007 = header.getOrDefault("X-Amz-Security-Token")
  valid_775007 = validateParameter(valid_775007, JString, required = false,
                                 default = nil)
  if valid_775007 != nil:
    section.add "X-Amz-Security-Token", valid_775007
  var valid_775008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775008 = validateParameter(valid_775008, JString, required = false,
                                 default = nil)
  if valid_775008 != nil:
    section.add "X-Amz-Content-Sha256", valid_775008
  var valid_775009 = header.getOrDefault("X-Amz-Algorithm")
  valid_775009 = validateParameter(valid_775009, JString, required = false,
                                 default = nil)
  if valid_775009 != nil:
    section.add "X-Amz-Algorithm", valid_775009
  var valid_775010 = header.getOrDefault("X-Amz-Signature")
  valid_775010 = validateParameter(valid_775010, JString, required = false,
                                 default = nil)
  if valid_775010 != nil:
    section.add "X-Amz-Signature", valid_775010
  var valid_775011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775011 = validateParameter(valid_775011, JString, required = false,
                                 default = nil)
  if valid_775011 != nil:
    section.add "X-Amz-SignedHeaders", valid_775011
  var valid_775012 = header.getOrDefault("X-Amz-Credential")
  valid_775012 = validateParameter(valid_775012, JString, required = false,
                                 default = nil)
  if valid_775012 != nil:
    section.add "X-Amz-Credential", valid_775012
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_775013 = formData.getOrDefault("ReservedDBInstanceId")
  valid_775013 = validateParameter(valid_775013, JString, required = false,
                                 default = nil)
  if valid_775013 != nil:
    section.add "ReservedDBInstanceId", valid_775013
  var valid_775014 = formData.getOrDefault("Tags")
  valid_775014 = validateParameter(valid_775014, JArray, required = false,
                                 default = nil)
  if valid_775014 != nil:
    section.add "Tags", valid_775014
  var valid_775015 = formData.getOrDefault("DBInstanceCount")
  valid_775015 = validateParameter(valid_775015, JInt, required = false, default = nil)
  if valid_775015 != nil:
    section.add "DBInstanceCount", valid_775015
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_775016 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_775016 = validateParameter(valid_775016, JString, required = true,
                                 default = nil)
  if valid_775016 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_775016
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775017: Call_PostPurchaseReservedDBInstancesOffering_775001;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775017.validator(path, query, header, formData, body)
  let scheme = call_775017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775017.url(scheme.get, call_775017.host, call_775017.base,
                         call_775017.route, valid.getOrDefault("path"))
  result = hook(call_775017, url, valid)

proc call*(call_775018: Call_PostPurchaseReservedDBInstancesOffering_775001;
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
  var query_775019 = newJObject()
  var formData_775020 = newJObject()
  add(formData_775020, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_775020.add "Tags", Tags
  add(formData_775020, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_775019, "Action", newJString(Action))
  add(formData_775020, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_775019, "Version", newJString(Version))
  result = call_775018.call(nil, query_775019, nil, formData_775020, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_775001(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_775002, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_775003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_774982 = ref object of OpenApiRestCall_772581
proc url_GetPurchaseReservedDBInstancesOffering_774984(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPurchaseReservedDBInstancesOffering_774983(path: JsonNode;
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
  var valid_774985 = query.getOrDefault("DBInstanceCount")
  valid_774985 = validateParameter(valid_774985, JInt, required = false, default = nil)
  if valid_774985 != nil:
    section.add "DBInstanceCount", valid_774985
  var valid_774986 = query.getOrDefault("Tags")
  valid_774986 = validateParameter(valid_774986, JArray, required = false,
                                 default = nil)
  if valid_774986 != nil:
    section.add "Tags", valid_774986
  var valid_774987 = query.getOrDefault("ReservedDBInstanceId")
  valid_774987 = validateParameter(valid_774987, JString, required = false,
                                 default = nil)
  if valid_774987 != nil:
    section.add "ReservedDBInstanceId", valid_774987
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_774988 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_774988 = validateParameter(valid_774988, JString, required = true,
                                 default = nil)
  if valid_774988 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_774988
  var valid_774989 = query.getOrDefault("Action")
  valid_774989 = validateParameter(valid_774989, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_774989 != nil:
    section.add "Action", valid_774989
  var valid_774990 = query.getOrDefault("Version")
  valid_774990 = validateParameter(valid_774990, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_774990 != nil:
    section.add "Version", valid_774990
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774991 = header.getOrDefault("X-Amz-Date")
  valid_774991 = validateParameter(valid_774991, JString, required = false,
                                 default = nil)
  if valid_774991 != nil:
    section.add "X-Amz-Date", valid_774991
  var valid_774992 = header.getOrDefault("X-Amz-Security-Token")
  valid_774992 = validateParameter(valid_774992, JString, required = false,
                                 default = nil)
  if valid_774992 != nil:
    section.add "X-Amz-Security-Token", valid_774992
  var valid_774993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774993 = validateParameter(valid_774993, JString, required = false,
                                 default = nil)
  if valid_774993 != nil:
    section.add "X-Amz-Content-Sha256", valid_774993
  var valid_774994 = header.getOrDefault("X-Amz-Algorithm")
  valid_774994 = validateParameter(valid_774994, JString, required = false,
                                 default = nil)
  if valid_774994 != nil:
    section.add "X-Amz-Algorithm", valid_774994
  var valid_774995 = header.getOrDefault("X-Amz-Signature")
  valid_774995 = validateParameter(valid_774995, JString, required = false,
                                 default = nil)
  if valid_774995 != nil:
    section.add "X-Amz-Signature", valid_774995
  var valid_774996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774996 = validateParameter(valid_774996, JString, required = false,
                                 default = nil)
  if valid_774996 != nil:
    section.add "X-Amz-SignedHeaders", valid_774996
  var valid_774997 = header.getOrDefault("X-Amz-Credential")
  valid_774997 = validateParameter(valid_774997, JString, required = false,
                                 default = nil)
  if valid_774997 != nil:
    section.add "X-Amz-Credential", valid_774997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774998: Call_GetPurchaseReservedDBInstancesOffering_774982;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_774998.validator(path, query, header, formData, body)
  let scheme = call_774998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774998.url(scheme.get, call_774998.host, call_774998.base,
                         call_774998.route, valid.getOrDefault("path"))
  result = hook(call_774998, url, valid)

proc call*(call_774999: Call_GetPurchaseReservedDBInstancesOffering_774982;
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
  var query_775000 = newJObject()
  add(query_775000, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_775000.add "Tags", Tags
  add(query_775000, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_775000, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_775000, "Action", newJString(Action))
  add(query_775000, "Version", newJString(Version))
  result = call_774999.call(nil, query_775000, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_774982(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_774983, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_774984,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_775038 = ref object of OpenApiRestCall_772581
proc url_PostRebootDBInstance_775040(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebootDBInstance_775039(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775041 = query.getOrDefault("Action")
  valid_775041 = validateParameter(valid_775041, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_775041 != nil:
    section.add "Action", valid_775041
  var valid_775042 = query.getOrDefault("Version")
  valid_775042 = validateParameter(valid_775042, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_775042 != nil:
    section.add "Version", valid_775042
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775043 = header.getOrDefault("X-Amz-Date")
  valid_775043 = validateParameter(valid_775043, JString, required = false,
                                 default = nil)
  if valid_775043 != nil:
    section.add "X-Amz-Date", valid_775043
  var valid_775044 = header.getOrDefault("X-Amz-Security-Token")
  valid_775044 = validateParameter(valid_775044, JString, required = false,
                                 default = nil)
  if valid_775044 != nil:
    section.add "X-Amz-Security-Token", valid_775044
  var valid_775045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775045 = validateParameter(valid_775045, JString, required = false,
                                 default = nil)
  if valid_775045 != nil:
    section.add "X-Amz-Content-Sha256", valid_775045
  var valid_775046 = header.getOrDefault("X-Amz-Algorithm")
  valid_775046 = validateParameter(valid_775046, JString, required = false,
                                 default = nil)
  if valid_775046 != nil:
    section.add "X-Amz-Algorithm", valid_775046
  var valid_775047 = header.getOrDefault("X-Amz-Signature")
  valid_775047 = validateParameter(valid_775047, JString, required = false,
                                 default = nil)
  if valid_775047 != nil:
    section.add "X-Amz-Signature", valid_775047
  var valid_775048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775048 = validateParameter(valid_775048, JString, required = false,
                                 default = nil)
  if valid_775048 != nil:
    section.add "X-Amz-SignedHeaders", valid_775048
  var valid_775049 = header.getOrDefault("X-Amz-Credential")
  valid_775049 = validateParameter(valid_775049, JString, required = false,
                                 default = nil)
  if valid_775049 != nil:
    section.add "X-Amz-Credential", valid_775049
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_775050 = formData.getOrDefault("DBInstanceIdentifier")
  valid_775050 = validateParameter(valid_775050, JString, required = true,
                                 default = nil)
  if valid_775050 != nil:
    section.add "DBInstanceIdentifier", valid_775050
  var valid_775051 = formData.getOrDefault("ForceFailover")
  valid_775051 = validateParameter(valid_775051, JBool, required = false, default = nil)
  if valid_775051 != nil:
    section.add "ForceFailover", valid_775051
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775052: Call_PostRebootDBInstance_775038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775052.validator(path, query, header, formData, body)
  let scheme = call_775052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775052.url(scheme.get, call_775052.host, call_775052.base,
                         call_775052.route, valid.getOrDefault("path"))
  result = hook(call_775052, url, valid)

proc call*(call_775053: Call_PostRebootDBInstance_775038;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_775054 = newJObject()
  var formData_775055 = newJObject()
  add(formData_775055, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_775054, "Action", newJString(Action))
  add(formData_775055, "ForceFailover", newJBool(ForceFailover))
  add(query_775054, "Version", newJString(Version))
  result = call_775053.call(nil, query_775054, nil, formData_775055, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_775038(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_775039, base: "/",
    url: url_PostRebootDBInstance_775040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_775021 = ref object of OpenApiRestCall_772581
proc url_GetRebootDBInstance_775023(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebootDBInstance_775022(path: JsonNode; query: JsonNode;
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
  var valid_775024 = query.getOrDefault("Action")
  valid_775024 = validateParameter(valid_775024, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_775024 != nil:
    section.add "Action", valid_775024
  var valid_775025 = query.getOrDefault("ForceFailover")
  valid_775025 = validateParameter(valid_775025, JBool, required = false, default = nil)
  if valid_775025 != nil:
    section.add "ForceFailover", valid_775025
  var valid_775026 = query.getOrDefault("Version")
  valid_775026 = validateParameter(valid_775026, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_775026 != nil:
    section.add "Version", valid_775026
  var valid_775027 = query.getOrDefault("DBInstanceIdentifier")
  valid_775027 = validateParameter(valid_775027, JString, required = true,
                                 default = nil)
  if valid_775027 != nil:
    section.add "DBInstanceIdentifier", valid_775027
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775028 = header.getOrDefault("X-Amz-Date")
  valid_775028 = validateParameter(valid_775028, JString, required = false,
                                 default = nil)
  if valid_775028 != nil:
    section.add "X-Amz-Date", valid_775028
  var valid_775029 = header.getOrDefault("X-Amz-Security-Token")
  valid_775029 = validateParameter(valid_775029, JString, required = false,
                                 default = nil)
  if valid_775029 != nil:
    section.add "X-Amz-Security-Token", valid_775029
  var valid_775030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775030 = validateParameter(valid_775030, JString, required = false,
                                 default = nil)
  if valid_775030 != nil:
    section.add "X-Amz-Content-Sha256", valid_775030
  var valid_775031 = header.getOrDefault("X-Amz-Algorithm")
  valid_775031 = validateParameter(valid_775031, JString, required = false,
                                 default = nil)
  if valid_775031 != nil:
    section.add "X-Amz-Algorithm", valid_775031
  var valid_775032 = header.getOrDefault("X-Amz-Signature")
  valid_775032 = validateParameter(valid_775032, JString, required = false,
                                 default = nil)
  if valid_775032 != nil:
    section.add "X-Amz-Signature", valid_775032
  var valid_775033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775033 = validateParameter(valid_775033, JString, required = false,
                                 default = nil)
  if valid_775033 != nil:
    section.add "X-Amz-SignedHeaders", valid_775033
  var valid_775034 = header.getOrDefault("X-Amz-Credential")
  valid_775034 = validateParameter(valid_775034, JString, required = false,
                                 default = nil)
  if valid_775034 != nil:
    section.add "X-Amz-Credential", valid_775034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775035: Call_GetRebootDBInstance_775021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775035.validator(path, query, header, formData, body)
  let scheme = call_775035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775035.url(scheme.get, call_775035.host, call_775035.base,
                         call_775035.route, valid.getOrDefault("path"))
  result = hook(call_775035, url, valid)

proc call*(call_775036: Call_GetRebootDBInstance_775021;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_775037 = newJObject()
  add(query_775037, "Action", newJString(Action))
  add(query_775037, "ForceFailover", newJBool(ForceFailover))
  add(query_775037, "Version", newJString(Version))
  add(query_775037, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_775036.call(nil, query_775037, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_775021(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_775022, base: "/",
    url: url_GetRebootDBInstance_775023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_775073 = ref object of OpenApiRestCall_772581
proc url_PostRemoveSourceIdentifierFromSubscription_775075(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_775074(path: JsonNode;
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
  var valid_775076 = query.getOrDefault("Action")
  valid_775076 = validateParameter(valid_775076, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_775076 != nil:
    section.add "Action", valid_775076
  var valid_775077 = query.getOrDefault("Version")
  valid_775077 = validateParameter(valid_775077, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_775077 != nil:
    section.add "Version", valid_775077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775078 = header.getOrDefault("X-Amz-Date")
  valid_775078 = validateParameter(valid_775078, JString, required = false,
                                 default = nil)
  if valid_775078 != nil:
    section.add "X-Amz-Date", valid_775078
  var valid_775079 = header.getOrDefault("X-Amz-Security-Token")
  valid_775079 = validateParameter(valid_775079, JString, required = false,
                                 default = nil)
  if valid_775079 != nil:
    section.add "X-Amz-Security-Token", valid_775079
  var valid_775080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775080 = validateParameter(valid_775080, JString, required = false,
                                 default = nil)
  if valid_775080 != nil:
    section.add "X-Amz-Content-Sha256", valid_775080
  var valid_775081 = header.getOrDefault("X-Amz-Algorithm")
  valid_775081 = validateParameter(valid_775081, JString, required = false,
                                 default = nil)
  if valid_775081 != nil:
    section.add "X-Amz-Algorithm", valid_775081
  var valid_775082 = header.getOrDefault("X-Amz-Signature")
  valid_775082 = validateParameter(valid_775082, JString, required = false,
                                 default = nil)
  if valid_775082 != nil:
    section.add "X-Amz-Signature", valid_775082
  var valid_775083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775083 = validateParameter(valid_775083, JString, required = false,
                                 default = nil)
  if valid_775083 != nil:
    section.add "X-Amz-SignedHeaders", valid_775083
  var valid_775084 = header.getOrDefault("X-Amz-Credential")
  valid_775084 = validateParameter(valid_775084, JString, required = false,
                                 default = nil)
  if valid_775084 != nil:
    section.add "X-Amz-Credential", valid_775084
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_775085 = formData.getOrDefault("SourceIdentifier")
  valid_775085 = validateParameter(valid_775085, JString, required = true,
                                 default = nil)
  if valid_775085 != nil:
    section.add "SourceIdentifier", valid_775085
  var valid_775086 = formData.getOrDefault("SubscriptionName")
  valid_775086 = validateParameter(valid_775086, JString, required = true,
                                 default = nil)
  if valid_775086 != nil:
    section.add "SubscriptionName", valid_775086
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775087: Call_PostRemoveSourceIdentifierFromSubscription_775073;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775087.validator(path, query, header, formData, body)
  let scheme = call_775087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775087.url(scheme.get, call_775087.host, call_775087.base,
                         call_775087.route, valid.getOrDefault("path"))
  result = hook(call_775087, url, valid)

proc call*(call_775088: Call_PostRemoveSourceIdentifierFromSubscription_775073;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_775089 = newJObject()
  var formData_775090 = newJObject()
  add(formData_775090, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_775090, "SubscriptionName", newJString(SubscriptionName))
  add(query_775089, "Action", newJString(Action))
  add(query_775089, "Version", newJString(Version))
  result = call_775088.call(nil, query_775089, nil, formData_775090, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_775073(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_775074,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_775075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_775056 = ref object of OpenApiRestCall_772581
proc url_GetRemoveSourceIdentifierFromSubscription_775058(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_775057(path: JsonNode;
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
  var valid_775059 = query.getOrDefault("Action")
  valid_775059 = validateParameter(valid_775059, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_775059 != nil:
    section.add "Action", valid_775059
  var valid_775060 = query.getOrDefault("SourceIdentifier")
  valid_775060 = validateParameter(valid_775060, JString, required = true,
                                 default = nil)
  if valid_775060 != nil:
    section.add "SourceIdentifier", valid_775060
  var valid_775061 = query.getOrDefault("SubscriptionName")
  valid_775061 = validateParameter(valid_775061, JString, required = true,
                                 default = nil)
  if valid_775061 != nil:
    section.add "SubscriptionName", valid_775061
  var valid_775062 = query.getOrDefault("Version")
  valid_775062 = validateParameter(valid_775062, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_775062 != nil:
    section.add "Version", valid_775062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775063 = header.getOrDefault("X-Amz-Date")
  valid_775063 = validateParameter(valid_775063, JString, required = false,
                                 default = nil)
  if valid_775063 != nil:
    section.add "X-Amz-Date", valid_775063
  var valid_775064 = header.getOrDefault("X-Amz-Security-Token")
  valid_775064 = validateParameter(valid_775064, JString, required = false,
                                 default = nil)
  if valid_775064 != nil:
    section.add "X-Amz-Security-Token", valid_775064
  var valid_775065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775065 = validateParameter(valid_775065, JString, required = false,
                                 default = nil)
  if valid_775065 != nil:
    section.add "X-Amz-Content-Sha256", valid_775065
  var valid_775066 = header.getOrDefault("X-Amz-Algorithm")
  valid_775066 = validateParameter(valid_775066, JString, required = false,
                                 default = nil)
  if valid_775066 != nil:
    section.add "X-Amz-Algorithm", valid_775066
  var valid_775067 = header.getOrDefault("X-Amz-Signature")
  valid_775067 = validateParameter(valid_775067, JString, required = false,
                                 default = nil)
  if valid_775067 != nil:
    section.add "X-Amz-Signature", valid_775067
  var valid_775068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775068 = validateParameter(valid_775068, JString, required = false,
                                 default = nil)
  if valid_775068 != nil:
    section.add "X-Amz-SignedHeaders", valid_775068
  var valid_775069 = header.getOrDefault("X-Amz-Credential")
  valid_775069 = validateParameter(valid_775069, JString, required = false,
                                 default = nil)
  if valid_775069 != nil:
    section.add "X-Amz-Credential", valid_775069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775070: Call_GetRemoveSourceIdentifierFromSubscription_775056;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775070.validator(path, query, header, formData, body)
  let scheme = call_775070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775070.url(scheme.get, call_775070.host, call_775070.base,
                         call_775070.route, valid.getOrDefault("path"))
  result = hook(call_775070, url, valid)

proc call*(call_775071: Call_GetRemoveSourceIdentifierFromSubscription_775056;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_775072 = newJObject()
  add(query_775072, "Action", newJString(Action))
  add(query_775072, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_775072, "SubscriptionName", newJString(SubscriptionName))
  add(query_775072, "Version", newJString(Version))
  result = call_775071.call(nil, query_775072, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_775056(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_775057,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_775058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_775108 = ref object of OpenApiRestCall_772581
proc url_PostRemoveTagsFromResource_775110(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTagsFromResource_775109(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775111 = query.getOrDefault("Action")
  valid_775111 = validateParameter(valid_775111, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_775111 != nil:
    section.add "Action", valid_775111
  var valid_775112 = query.getOrDefault("Version")
  valid_775112 = validateParameter(valid_775112, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_775112 != nil:
    section.add "Version", valid_775112
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775113 = header.getOrDefault("X-Amz-Date")
  valid_775113 = validateParameter(valid_775113, JString, required = false,
                                 default = nil)
  if valid_775113 != nil:
    section.add "X-Amz-Date", valid_775113
  var valid_775114 = header.getOrDefault("X-Amz-Security-Token")
  valid_775114 = validateParameter(valid_775114, JString, required = false,
                                 default = nil)
  if valid_775114 != nil:
    section.add "X-Amz-Security-Token", valid_775114
  var valid_775115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775115 = validateParameter(valid_775115, JString, required = false,
                                 default = nil)
  if valid_775115 != nil:
    section.add "X-Amz-Content-Sha256", valid_775115
  var valid_775116 = header.getOrDefault("X-Amz-Algorithm")
  valid_775116 = validateParameter(valid_775116, JString, required = false,
                                 default = nil)
  if valid_775116 != nil:
    section.add "X-Amz-Algorithm", valid_775116
  var valid_775117 = header.getOrDefault("X-Amz-Signature")
  valid_775117 = validateParameter(valid_775117, JString, required = false,
                                 default = nil)
  if valid_775117 != nil:
    section.add "X-Amz-Signature", valid_775117
  var valid_775118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775118 = validateParameter(valid_775118, JString, required = false,
                                 default = nil)
  if valid_775118 != nil:
    section.add "X-Amz-SignedHeaders", valid_775118
  var valid_775119 = header.getOrDefault("X-Amz-Credential")
  valid_775119 = validateParameter(valid_775119, JString, required = false,
                                 default = nil)
  if valid_775119 != nil:
    section.add "X-Amz-Credential", valid_775119
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_775120 = formData.getOrDefault("TagKeys")
  valid_775120 = validateParameter(valid_775120, JArray, required = true, default = nil)
  if valid_775120 != nil:
    section.add "TagKeys", valid_775120
  var valid_775121 = formData.getOrDefault("ResourceName")
  valid_775121 = validateParameter(valid_775121, JString, required = true,
                                 default = nil)
  if valid_775121 != nil:
    section.add "ResourceName", valid_775121
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775122: Call_PostRemoveTagsFromResource_775108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775122.validator(path, query, header, formData, body)
  let scheme = call_775122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775122.url(scheme.get, call_775122.host, call_775122.base,
                         call_775122.route, valid.getOrDefault("path"))
  result = hook(call_775122, url, valid)

proc call*(call_775123: Call_PostRemoveTagsFromResource_775108; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_775124 = newJObject()
  var formData_775125 = newJObject()
  add(query_775124, "Action", newJString(Action))
  if TagKeys != nil:
    formData_775125.add "TagKeys", TagKeys
  add(formData_775125, "ResourceName", newJString(ResourceName))
  add(query_775124, "Version", newJString(Version))
  result = call_775123.call(nil, query_775124, nil, formData_775125, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_775108(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_775109, base: "/",
    url: url_PostRemoveTagsFromResource_775110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_775091 = ref object of OpenApiRestCall_772581
proc url_GetRemoveTagsFromResource_775093(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTagsFromResource_775092(path: JsonNode; query: JsonNode;
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
  var valid_775094 = query.getOrDefault("ResourceName")
  valid_775094 = validateParameter(valid_775094, JString, required = true,
                                 default = nil)
  if valid_775094 != nil:
    section.add "ResourceName", valid_775094
  var valid_775095 = query.getOrDefault("Action")
  valid_775095 = validateParameter(valid_775095, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_775095 != nil:
    section.add "Action", valid_775095
  var valid_775096 = query.getOrDefault("TagKeys")
  valid_775096 = validateParameter(valid_775096, JArray, required = true, default = nil)
  if valid_775096 != nil:
    section.add "TagKeys", valid_775096
  var valid_775097 = query.getOrDefault("Version")
  valid_775097 = validateParameter(valid_775097, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775105: Call_GetRemoveTagsFromResource_775091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775105.validator(path, query, header, formData, body)
  let scheme = call_775105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775105.url(scheme.get, call_775105.host, call_775105.base,
                         call_775105.route, valid.getOrDefault("path"))
  result = hook(call_775105, url, valid)

proc call*(call_775106: Call_GetRemoveTagsFromResource_775091;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-09-09"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_775107 = newJObject()
  add(query_775107, "ResourceName", newJString(ResourceName))
  add(query_775107, "Action", newJString(Action))
  if TagKeys != nil:
    query_775107.add "TagKeys", TagKeys
  add(query_775107, "Version", newJString(Version))
  result = call_775106.call(nil, query_775107, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_775091(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_775092, base: "/",
    url: url_GetRemoveTagsFromResource_775093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_775144 = ref object of OpenApiRestCall_772581
proc url_PostResetDBParameterGroup_775146(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostResetDBParameterGroup_775145(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775147 = query.getOrDefault("Action")
  valid_775147 = validateParameter(valid_775147, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_775147 != nil:
    section.add "Action", valid_775147
  var valid_775148 = query.getOrDefault("Version")
  valid_775148 = validateParameter(valid_775148, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_775148 != nil:
    section.add "Version", valid_775148
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775149 = header.getOrDefault("X-Amz-Date")
  valid_775149 = validateParameter(valid_775149, JString, required = false,
                                 default = nil)
  if valid_775149 != nil:
    section.add "X-Amz-Date", valid_775149
  var valid_775150 = header.getOrDefault("X-Amz-Security-Token")
  valid_775150 = validateParameter(valid_775150, JString, required = false,
                                 default = nil)
  if valid_775150 != nil:
    section.add "X-Amz-Security-Token", valid_775150
  var valid_775151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775151 = validateParameter(valid_775151, JString, required = false,
                                 default = nil)
  if valid_775151 != nil:
    section.add "X-Amz-Content-Sha256", valid_775151
  var valid_775152 = header.getOrDefault("X-Amz-Algorithm")
  valid_775152 = validateParameter(valid_775152, JString, required = false,
                                 default = nil)
  if valid_775152 != nil:
    section.add "X-Amz-Algorithm", valid_775152
  var valid_775153 = header.getOrDefault("X-Amz-Signature")
  valid_775153 = validateParameter(valid_775153, JString, required = false,
                                 default = nil)
  if valid_775153 != nil:
    section.add "X-Amz-Signature", valid_775153
  var valid_775154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775154 = validateParameter(valid_775154, JString, required = false,
                                 default = nil)
  if valid_775154 != nil:
    section.add "X-Amz-SignedHeaders", valid_775154
  var valid_775155 = header.getOrDefault("X-Amz-Credential")
  valid_775155 = validateParameter(valid_775155, JString, required = false,
                                 default = nil)
  if valid_775155 != nil:
    section.add "X-Amz-Credential", valid_775155
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_775156 = formData.getOrDefault("DBParameterGroupName")
  valid_775156 = validateParameter(valid_775156, JString, required = true,
                                 default = nil)
  if valid_775156 != nil:
    section.add "DBParameterGroupName", valid_775156
  var valid_775157 = formData.getOrDefault("Parameters")
  valid_775157 = validateParameter(valid_775157, JArray, required = false,
                                 default = nil)
  if valid_775157 != nil:
    section.add "Parameters", valid_775157
  var valid_775158 = formData.getOrDefault("ResetAllParameters")
  valid_775158 = validateParameter(valid_775158, JBool, required = false, default = nil)
  if valid_775158 != nil:
    section.add "ResetAllParameters", valid_775158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775159: Call_PostResetDBParameterGroup_775144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775159.validator(path, query, header, formData, body)
  let scheme = call_775159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775159.url(scheme.get, call_775159.host, call_775159.base,
                         call_775159.route, valid.getOrDefault("path"))
  result = hook(call_775159, url, valid)

proc call*(call_775160: Call_PostResetDBParameterGroup_775144;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_775161 = newJObject()
  var formData_775162 = newJObject()
  add(formData_775162, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_775162.add "Parameters", Parameters
  add(query_775161, "Action", newJString(Action))
  add(formData_775162, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_775161, "Version", newJString(Version))
  result = call_775160.call(nil, query_775161, nil, formData_775162, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_775144(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_775145, base: "/",
    url: url_PostResetDBParameterGroup_775146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_775126 = ref object of OpenApiRestCall_772581
proc url_GetResetDBParameterGroup_775128(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResetDBParameterGroup_775127(path: JsonNode; query: JsonNode;
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
  var valid_775129 = query.getOrDefault("DBParameterGroupName")
  valid_775129 = validateParameter(valid_775129, JString, required = true,
                                 default = nil)
  if valid_775129 != nil:
    section.add "DBParameterGroupName", valid_775129
  var valid_775130 = query.getOrDefault("Parameters")
  valid_775130 = validateParameter(valid_775130, JArray, required = false,
                                 default = nil)
  if valid_775130 != nil:
    section.add "Parameters", valid_775130
  var valid_775131 = query.getOrDefault("Action")
  valid_775131 = validateParameter(valid_775131, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_775131 != nil:
    section.add "Action", valid_775131
  var valid_775132 = query.getOrDefault("ResetAllParameters")
  valid_775132 = validateParameter(valid_775132, JBool, required = false, default = nil)
  if valid_775132 != nil:
    section.add "ResetAllParameters", valid_775132
  var valid_775133 = query.getOrDefault("Version")
  valid_775133 = validateParameter(valid_775133, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_775133 != nil:
    section.add "Version", valid_775133
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775134 = header.getOrDefault("X-Amz-Date")
  valid_775134 = validateParameter(valid_775134, JString, required = false,
                                 default = nil)
  if valid_775134 != nil:
    section.add "X-Amz-Date", valid_775134
  var valid_775135 = header.getOrDefault("X-Amz-Security-Token")
  valid_775135 = validateParameter(valid_775135, JString, required = false,
                                 default = nil)
  if valid_775135 != nil:
    section.add "X-Amz-Security-Token", valid_775135
  var valid_775136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775136 = validateParameter(valid_775136, JString, required = false,
                                 default = nil)
  if valid_775136 != nil:
    section.add "X-Amz-Content-Sha256", valid_775136
  var valid_775137 = header.getOrDefault("X-Amz-Algorithm")
  valid_775137 = validateParameter(valid_775137, JString, required = false,
                                 default = nil)
  if valid_775137 != nil:
    section.add "X-Amz-Algorithm", valid_775137
  var valid_775138 = header.getOrDefault("X-Amz-Signature")
  valid_775138 = validateParameter(valid_775138, JString, required = false,
                                 default = nil)
  if valid_775138 != nil:
    section.add "X-Amz-Signature", valid_775138
  var valid_775139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775139 = validateParameter(valid_775139, JString, required = false,
                                 default = nil)
  if valid_775139 != nil:
    section.add "X-Amz-SignedHeaders", valid_775139
  var valid_775140 = header.getOrDefault("X-Amz-Credential")
  valid_775140 = validateParameter(valid_775140, JString, required = false,
                                 default = nil)
  if valid_775140 != nil:
    section.add "X-Amz-Credential", valid_775140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775141: Call_GetResetDBParameterGroup_775126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_775141.validator(path, query, header, formData, body)
  let scheme = call_775141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775141.url(scheme.get, call_775141.host, call_775141.base,
                         call_775141.route, valid.getOrDefault("path"))
  result = hook(call_775141, url, valid)

proc call*(call_775142: Call_GetResetDBParameterGroup_775126;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_775143 = newJObject()
  add(query_775143, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_775143.add "Parameters", Parameters
  add(query_775143, "Action", newJString(Action))
  add(query_775143, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_775143, "Version", newJString(Version))
  result = call_775142.call(nil, query_775143, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_775126(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_775127, base: "/",
    url: url_GetResetDBParameterGroup_775128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_775193 = ref object of OpenApiRestCall_772581
proc url_PostRestoreDBInstanceFromDBSnapshot_775195(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_775194(path: JsonNode;
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
  var valid_775196 = query.getOrDefault("Action")
  valid_775196 = validateParameter(valid_775196, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_775196 != nil:
    section.add "Action", valid_775196
  var valid_775197 = query.getOrDefault("Version")
  valid_775197 = validateParameter(valid_775197, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_775197 != nil:
    section.add "Version", valid_775197
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775198 = header.getOrDefault("X-Amz-Date")
  valid_775198 = validateParameter(valid_775198, JString, required = false,
                                 default = nil)
  if valid_775198 != nil:
    section.add "X-Amz-Date", valid_775198
  var valid_775199 = header.getOrDefault("X-Amz-Security-Token")
  valid_775199 = validateParameter(valid_775199, JString, required = false,
                                 default = nil)
  if valid_775199 != nil:
    section.add "X-Amz-Security-Token", valid_775199
  var valid_775200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775200 = validateParameter(valid_775200, JString, required = false,
                                 default = nil)
  if valid_775200 != nil:
    section.add "X-Amz-Content-Sha256", valid_775200
  var valid_775201 = header.getOrDefault("X-Amz-Algorithm")
  valid_775201 = validateParameter(valid_775201, JString, required = false,
                                 default = nil)
  if valid_775201 != nil:
    section.add "X-Amz-Algorithm", valid_775201
  var valid_775202 = header.getOrDefault("X-Amz-Signature")
  valid_775202 = validateParameter(valid_775202, JString, required = false,
                                 default = nil)
  if valid_775202 != nil:
    section.add "X-Amz-Signature", valid_775202
  var valid_775203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775203 = validateParameter(valid_775203, JString, required = false,
                                 default = nil)
  if valid_775203 != nil:
    section.add "X-Amz-SignedHeaders", valid_775203
  var valid_775204 = header.getOrDefault("X-Amz-Credential")
  valid_775204 = validateParameter(valid_775204, JString, required = false,
                                 default = nil)
  if valid_775204 != nil:
    section.add "X-Amz-Credential", valid_775204
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
  var valid_775205 = formData.getOrDefault("Port")
  valid_775205 = validateParameter(valid_775205, JInt, required = false, default = nil)
  if valid_775205 != nil:
    section.add "Port", valid_775205
  var valid_775206 = formData.getOrDefault("Engine")
  valid_775206 = validateParameter(valid_775206, JString, required = false,
                                 default = nil)
  if valid_775206 != nil:
    section.add "Engine", valid_775206
  var valid_775207 = formData.getOrDefault("Iops")
  valid_775207 = validateParameter(valid_775207, JInt, required = false, default = nil)
  if valid_775207 != nil:
    section.add "Iops", valid_775207
  var valid_775208 = formData.getOrDefault("DBName")
  valid_775208 = validateParameter(valid_775208, JString, required = false,
                                 default = nil)
  if valid_775208 != nil:
    section.add "DBName", valid_775208
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_775209 = formData.getOrDefault("DBInstanceIdentifier")
  valid_775209 = validateParameter(valid_775209, JString, required = true,
                                 default = nil)
  if valid_775209 != nil:
    section.add "DBInstanceIdentifier", valid_775209
  var valid_775210 = formData.getOrDefault("OptionGroupName")
  valid_775210 = validateParameter(valid_775210, JString, required = false,
                                 default = nil)
  if valid_775210 != nil:
    section.add "OptionGroupName", valid_775210
  var valid_775211 = formData.getOrDefault("Tags")
  valid_775211 = validateParameter(valid_775211, JArray, required = false,
                                 default = nil)
  if valid_775211 != nil:
    section.add "Tags", valid_775211
  var valid_775212 = formData.getOrDefault("DBSubnetGroupName")
  valid_775212 = validateParameter(valid_775212, JString, required = false,
                                 default = nil)
  if valid_775212 != nil:
    section.add "DBSubnetGroupName", valid_775212
  var valid_775213 = formData.getOrDefault("AvailabilityZone")
  valid_775213 = validateParameter(valid_775213, JString, required = false,
                                 default = nil)
  if valid_775213 != nil:
    section.add "AvailabilityZone", valid_775213
  var valid_775214 = formData.getOrDefault("MultiAZ")
  valid_775214 = validateParameter(valid_775214, JBool, required = false, default = nil)
  if valid_775214 != nil:
    section.add "MultiAZ", valid_775214
  var valid_775215 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_775215 = validateParameter(valid_775215, JString, required = true,
                                 default = nil)
  if valid_775215 != nil:
    section.add "DBSnapshotIdentifier", valid_775215
  var valid_775216 = formData.getOrDefault("PubliclyAccessible")
  valid_775216 = validateParameter(valid_775216, JBool, required = false, default = nil)
  if valid_775216 != nil:
    section.add "PubliclyAccessible", valid_775216
  var valid_775217 = formData.getOrDefault("DBInstanceClass")
  valid_775217 = validateParameter(valid_775217, JString, required = false,
                                 default = nil)
  if valid_775217 != nil:
    section.add "DBInstanceClass", valid_775217
  var valid_775218 = formData.getOrDefault("LicenseModel")
  valid_775218 = validateParameter(valid_775218, JString, required = false,
                                 default = nil)
  if valid_775218 != nil:
    section.add "LicenseModel", valid_775218
  var valid_775219 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_775219 = validateParameter(valid_775219, JBool, required = false, default = nil)
  if valid_775219 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775219
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775220: Call_PostRestoreDBInstanceFromDBSnapshot_775193;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775220.validator(path, query, header, formData, body)
  let scheme = call_775220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775220.url(scheme.get, call_775220.host, call_775220.base,
                         call_775220.route, valid.getOrDefault("path"))
  result = hook(call_775220, url, valid)

proc call*(call_775221: Call_PostRestoreDBInstanceFromDBSnapshot_775193;
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
  var query_775222 = newJObject()
  var formData_775223 = newJObject()
  add(formData_775223, "Port", newJInt(Port))
  add(formData_775223, "Engine", newJString(Engine))
  add(formData_775223, "Iops", newJInt(Iops))
  add(formData_775223, "DBName", newJString(DBName))
  add(formData_775223, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_775223, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_775223.add "Tags", Tags
  add(formData_775223, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_775223, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_775223, "MultiAZ", newJBool(MultiAZ))
  add(formData_775223, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_775222, "Action", newJString(Action))
  add(formData_775223, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_775223, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_775223, "LicenseModel", newJString(LicenseModel))
  add(formData_775223, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_775222, "Version", newJString(Version))
  result = call_775221.call(nil, query_775222, nil, formData_775223, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_775193(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_775194, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_775195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_775163 = ref object of OpenApiRestCall_772581
proc url_GetRestoreDBInstanceFromDBSnapshot_775165(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_775164(path: JsonNode;
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
  var valid_775166 = query.getOrDefault("Engine")
  valid_775166 = validateParameter(valid_775166, JString, required = false,
                                 default = nil)
  if valid_775166 != nil:
    section.add "Engine", valid_775166
  var valid_775167 = query.getOrDefault("OptionGroupName")
  valid_775167 = validateParameter(valid_775167, JString, required = false,
                                 default = nil)
  if valid_775167 != nil:
    section.add "OptionGroupName", valid_775167
  var valid_775168 = query.getOrDefault("AvailabilityZone")
  valid_775168 = validateParameter(valid_775168, JString, required = false,
                                 default = nil)
  if valid_775168 != nil:
    section.add "AvailabilityZone", valid_775168
  var valid_775169 = query.getOrDefault("Iops")
  valid_775169 = validateParameter(valid_775169, JInt, required = false, default = nil)
  if valid_775169 != nil:
    section.add "Iops", valid_775169
  var valid_775170 = query.getOrDefault("MultiAZ")
  valid_775170 = validateParameter(valid_775170, JBool, required = false, default = nil)
  if valid_775170 != nil:
    section.add "MultiAZ", valid_775170
  var valid_775171 = query.getOrDefault("LicenseModel")
  valid_775171 = validateParameter(valid_775171, JString, required = false,
                                 default = nil)
  if valid_775171 != nil:
    section.add "LicenseModel", valid_775171
  var valid_775172 = query.getOrDefault("Tags")
  valid_775172 = validateParameter(valid_775172, JArray, required = false,
                                 default = nil)
  if valid_775172 != nil:
    section.add "Tags", valid_775172
  var valid_775173 = query.getOrDefault("DBName")
  valid_775173 = validateParameter(valid_775173, JString, required = false,
                                 default = nil)
  if valid_775173 != nil:
    section.add "DBName", valid_775173
  var valid_775174 = query.getOrDefault("DBInstanceClass")
  valid_775174 = validateParameter(valid_775174, JString, required = false,
                                 default = nil)
  if valid_775174 != nil:
    section.add "DBInstanceClass", valid_775174
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_775175 = query.getOrDefault("Action")
  valid_775175 = validateParameter(valid_775175, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_775175 != nil:
    section.add "Action", valid_775175
  var valid_775176 = query.getOrDefault("DBSubnetGroupName")
  valid_775176 = validateParameter(valid_775176, JString, required = false,
                                 default = nil)
  if valid_775176 != nil:
    section.add "DBSubnetGroupName", valid_775176
  var valid_775177 = query.getOrDefault("PubliclyAccessible")
  valid_775177 = validateParameter(valid_775177, JBool, required = false, default = nil)
  if valid_775177 != nil:
    section.add "PubliclyAccessible", valid_775177
  var valid_775178 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_775178 = validateParameter(valid_775178, JBool, required = false, default = nil)
  if valid_775178 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775178
  var valid_775179 = query.getOrDefault("Port")
  valid_775179 = validateParameter(valid_775179, JInt, required = false, default = nil)
  if valid_775179 != nil:
    section.add "Port", valid_775179
  var valid_775180 = query.getOrDefault("Version")
  valid_775180 = validateParameter(valid_775180, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_775180 != nil:
    section.add "Version", valid_775180
  var valid_775181 = query.getOrDefault("DBInstanceIdentifier")
  valid_775181 = validateParameter(valid_775181, JString, required = true,
                                 default = nil)
  if valid_775181 != nil:
    section.add "DBInstanceIdentifier", valid_775181
  var valid_775182 = query.getOrDefault("DBSnapshotIdentifier")
  valid_775182 = validateParameter(valid_775182, JString, required = true,
                                 default = nil)
  if valid_775182 != nil:
    section.add "DBSnapshotIdentifier", valid_775182
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775183 = header.getOrDefault("X-Amz-Date")
  valid_775183 = validateParameter(valid_775183, JString, required = false,
                                 default = nil)
  if valid_775183 != nil:
    section.add "X-Amz-Date", valid_775183
  var valid_775184 = header.getOrDefault("X-Amz-Security-Token")
  valid_775184 = validateParameter(valid_775184, JString, required = false,
                                 default = nil)
  if valid_775184 != nil:
    section.add "X-Amz-Security-Token", valid_775184
  var valid_775185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775185 = validateParameter(valid_775185, JString, required = false,
                                 default = nil)
  if valid_775185 != nil:
    section.add "X-Amz-Content-Sha256", valid_775185
  var valid_775186 = header.getOrDefault("X-Amz-Algorithm")
  valid_775186 = validateParameter(valid_775186, JString, required = false,
                                 default = nil)
  if valid_775186 != nil:
    section.add "X-Amz-Algorithm", valid_775186
  var valid_775187 = header.getOrDefault("X-Amz-Signature")
  valid_775187 = validateParameter(valid_775187, JString, required = false,
                                 default = nil)
  if valid_775187 != nil:
    section.add "X-Amz-Signature", valid_775187
  var valid_775188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775188 = validateParameter(valid_775188, JString, required = false,
                                 default = nil)
  if valid_775188 != nil:
    section.add "X-Amz-SignedHeaders", valid_775188
  var valid_775189 = header.getOrDefault("X-Amz-Credential")
  valid_775189 = validateParameter(valid_775189, JString, required = false,
                                 default = nil)
  if valid_775189 != nil:
    section.add "X-Amz-Credential", valid_775189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775190: Call_GetRestoreDBInstanceFromDBSnapshot_775163;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775190.validator(path, query, header, formData, body)
  let scheme = call_775190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775190.url(scheme.get, call_775190.host, call_775190.base,
                         call_775190.route, valid.getOrDefault("path"))
  result = hook(call_775190, url, valid)

proc call*(call_775191: Call_GetRestoreDBInstanceFromDBSnapshot_775163;
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
  var query_775192 = newJObject()
  add(query_775192, "Engine", newJString(Engine))
  add(query_775192, "OptionGroupName", newJString(OptionGroupName))
  add(query_775192, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_775192, "Iops", newJInt(Iops))
  add(query_775192, "MultiAZ", newJBool(MultiAZ))
  add(query_775192, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_775192.add "Tags", Tags
  add(query_775192, "DBName", newJString(DBName))
  add(query_775192, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_775192, "Action", newJString(Action))
  add(query_775192, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_775192, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_775192, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_775192, "Port", newJInt(Port))
  add(query_775192, "Version", newJString(Version))
  add(query_775192, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_775192, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_775191.call(nil, query_775192, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_775163(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_775164, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_775165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_775256 = ref object of OpenApiRestCall_772581
proc url_PostRestoreDBInstanceToPointInTime_775258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceToPointInTime_775257(path: JsonNode;
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
  var valid_775259 = query.getOrDefault("Action")
  valid_775259 = validateParameter(valid_775259, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_775259 != nil:
    section.add "Action", valid_775259
  var valid_775260 = query.getOrDefault("Version")
  valid_775260 = validateParameter(valid_775260, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_775260 != nil:
    section.add "Version", valid_775260
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775261 = header.getOrDefault("X-Amz-Date")
  valid_775261 = validateParameter(valid_775261, JString, required = false,
                                 default = nil)
  if valid_775261 != nil:
    section.add "X-Amz-Date", valid_775261
  var valid_775262 = header.getOrDefault("X-Amz-Security-Token")
  valid_775262 = validateParameter(valid_775262, JString, required = false,
                                 default = nil)
  if valid_775262 != nil:
    section.add "X-Amz-Security-Token", valid_775262
  var valid_775263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775263 = validateParameter(valid_775263, JString, required = false,
                                 default = nil)
  if valid_775263 != nil:
    section.add "X-Amz-Content-Sha256", valid_775263
  var valid_775264 = header.getOrDefault("X-Amz-Algorithm")
  valid_775264 = validateParameter(valid_775264, JString, required = false,
                                 default = nil)
  if valid_775264 != nil:
    section.add "X-Amz-Algorithm", valid_775264
  var valid_775265 = header.getOrDefault("X-Amz-Signature")
  valid_775265 = validateParameter(valid_775265, JString, required = false,
                                 default = nil)
  if valid_775265 != nil:
    section.add "X-Amz-Signature", valid_775265
  var valid_775266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775266 = validateParameter(valid_775266, JString, required = false,
                                 default = nil)
  if valid_775266 != nil:
    section.add "X-Amz-SignedHeaders", valid_775266
  var valid_775267 = header.getOrDefault("X-Amz-Credential")
  valid_775267 = validateParameter(valid_775267, JString, required = false,
                                 default = nil)
  if valid_775267 != nil:
    section.add "X-Amz-Credential", valid_775267
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
  var valid_775268 = formData.getOrDefault("UseLatestRestorableTime")
  valid_775268 = validateParameter(valid_775268, JBool, required = false, default = nil)
  if valid_775268 != nil:
    section.add "UseLatestRestorableTime", valid_775268
  var valid_775269 = formData.getOrDefault("Port")
  valid_775269 = validateParameter(valid_775269, JInt, required = false, default = nil)
  if valid_775269 != nil:
    section.add "Port", valid_775269
  var valid_775270 = formData.getOrDefault("Engine")
  valid_775270 = validateParameter(valid_775270, JString, required = false,
                                 default = nil)
  if valid_775270 != nil:
    section.add "Engine", valid_775270
  var valid_775271 = formData.getOrDefault("Iops")
  valid_775271 = validateParameter(valid_775271, JInt, required = false, default = nil)
  if valid_775271 != nil:
    section.add "Iops", valid_775271
  var valid_775272 = formData.getOrDefault("DBName")
  valid_775272 = validateParameter(valid_775272, JString, required = false,
                                 default = nil)
  if valid_775272 != nil:
    section.add "DBName", valid_775272
  var valid_775273 = formData.getOrDefault("OptionGroupName")
  valid_775273 = validateParameter(valid_775273, JString, required = false,
                                 default = nil)
  if valid_775273 != nil:
    section.add "OptionGroupName", valid_775273
  var valid_775274 = formData.getOrDefault("Tags")
  valid_775274 = validateParameter(valid_775274, JArray, required = false,
                                 default = nil)
  if valid_775274 != nil:
    section.add "Tags", valid_775274
  var valid_775275 = formData.getOrDefault("DBSubnetGroupName")
  valid_775275 = validateParameter(valid_775275, JString, required = false,
                                 default = nil)
  if valid_775275 != nil:
    section.add "DBSubnetGroupName", valid_775275
  var valid_775276 = formData.getOrDefault("AvailabilityZone")
  valid_775276 = validateParameter(valid_775276, JString, required = false,
                                 default = nil)
  if valid_775276 != nil:
    section.add "AvailabilityZone", valid_775276
  var valid_775277 = formData.getOrDefault("MultiAZ")
  valid_775277 = validateParameter(valid_775277, JBool, required = false, default = nil)
  if valid_775277 != nil:
    section.add "MultiAZ", valid_775277
  var valid_775278 = formData.getOrDefault("RestoreTime")
  valid_775278 = validateParameter(valid_775278, JString, required = false,
                                 default = nil)
  if valid_775278 != nil:
    section.add "RestoreTime", valid_775278
  var valid_775279 = formData.getOrDefault("PubliclyAccessible")
  valid_775279 = validateParameter(valid_775279, JBool, required = false, default = nil)
  if valid_775279 != nil:
    section.add "PubliclyAccessible", valid_775279
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_775280 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_775280 = validateParameter(valid_775280, JString, required = true,
                                 default = nil)
  if valid_775280 != nil:
    section.add "TargetDBInstanceIdentifier", valid_775280
  var valid_775281 = formData.getOrDefault("DBInstanceClass")
  valid_775281 = validateParameter(valid_775281, JString, required = false,
                                 default = nil)
  if valid_775281 != nil:
    section.add "DBInstanceClass", valid_775281
  var valid_775282 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_775282 = validateParameter(valid_775282, JString, required = true,
                                 default = nil)
  if valid_775282 != nil:
    section.add "SourceDBInstanceIdentifier", valid_775282
  var valid_775283 = formData.getOrDefault("LicenseModel")
  valid_775283 = validateParameter(valid_775283, JString, required = false,
                                 default = nil)
  if valid_775283 != nil:
    section.add "LicenseModel", valid_775283
  var valid_775284 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_775284 = validateParameter(valid_775284, JBool, required = false, default = nil)
  if valid_775284 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775284
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775285: Call_PostRestoreDBInstanceToPointInTime_775256;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775285.validator(path, query, header, formData, body)
  let scheme = call_775285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775285.url(scheme.get, call_775285.host, call_775285.base,
                         call_775285.route, valid.getOrDefault("path"))
  result = hook(call_775285, url, valid)

proc call*(call_775286: Call_PostRestoreDBInstanceToPointInTime_775256;
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
  var query_775287 = newJObject()
  var formData_775288 = newJObject()
  add(formData_775288, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_775288, "Port", newJInt(Port))
  add(formData_775288, "Engine", newJString(Engine))
  add(formData_775288, "Iops", newJInt(Iops))
  add(formData_775288, "DBName", newJString(DBName))
  add(formData_775288, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_775288.add "Tags", Tags
  add(formData_775288, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_775288, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_775288, "MultiAZ", newJBool(MultiAZ))
  add(query_775287, "Action", newJString(Action))
  add(formData_775288, "RestoreTime", newJString(RestoreTime))
  add(formData_775288, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_775288, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_775288, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_775288, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_775288, "LicenseModel", newJString(LicenseModel))
  add(formData_775288, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_775287, "Version", newJString(Version))
  result = call_775286.call(nil, query_775287, nil, formData_775288, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_775256(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_775257, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_775258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_775224 = ref object of OpenApiRestCall_772581
proc url_GetRestoreDBInstanceToPointInTime_775226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceToPointInTime_775225(path: JsonNode;
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
  var valid_775227 = query.getOrDefault("Engine")
  valid_775227 = validateParameter(valid_775227, JString, required = false,
                                 default = nil)
  if valid_775227 != nil:
    section.add "Engine", valid_775227
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_775228 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_775228 = validateParameter(valid_775228, JString, required = true,
                                 default = nil)
  if valid_775228 != nil:
    section.add "SourceDBInstanceIdentifier", valid_775228
  var valid_775229 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_775229 = validateParameter(valid_775229, JString, required = true,
                                 default = nil)
  if valid_775229 != nil:
    section.add "TargetDBInstanceIdentifier", valid_775229
  var valid_775230 = query.getOrDefault("AvailabilityZone")
  valid_775230 = validateParameter(valid_775230, JString, required = false,
                                 default = nil)
  if valid_775230 != nil:
    section.add "AvailabilityZone", valid_775230
  var valid_775231 = query.getOrDefault("Iops")
  valid_775231 = validateParameter(valid_775231, JInt, required = false, default = nil)
  if valid_775231 != nil:
    section.add "Iops", valid_775231
  var valid_775232 = query.getOrDefault("OptionGroupName")
  valid_775232 = validateParameter(valid_775232, JString, required = false,
                                 default = nil)
  if valid_775232 != nil:
    section.add "OptionGroupName", valid_775232
  var valid_775233 = query.getOrDefault("RestoreTime")
  valid_775233 = validateParameter(valid_775233, JString, required = false,
                                 default = nil)
  if valid_775233 != nil:
    section.add "RestoreTime", valid_775233
  var valid_775234 = query.getOrDefault("MultiAZ")
  valid_775234 = validateParameter(valid_775234, JBool, required = false, default = nil)
  if valid_775234 != nil:
    section.add "MultiAZ", valid_775234
  var valid_775235 = query.getOrDefault("LicenseModel")
  valid_775235 = validateParameter(valid_775235, JString, required = false,
                                 default = nil)
  if valid_775235 != nil:
    section.add "LicenseModel", valid_775235
  var valid_775236 = query.getOrDefault("Tags")
  valid_775236 = validateParameter(valid_775236, JArray, required = false,
                                 default = nil)
  if valid_775236 != nil:
    section.add "Tags", valid_775236
  var valid_775237 = query.getOrDefault("DBName")
  valid_775237 = validateParameter(valid_775237, JString, required = false,
                                 default = nil)
  if valid_775237 != nil:
    section.add "DBName", valid_775237
  var valid_775238 = query.getOrDefault("DBInstanceClass")
  valid_775238 = validateParameter(valid_775238, JString, required = false,
                                 default = nil)
  if valid_775238 != nil:
    section.add "DBInstanceClass", valid_775238
  var valid_775239 = query.getOrDefault("Action")
  valid_775239 = validateParameter(valid_775239, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_775239 != nil:
    section.add "Action", valid_775239
  var valid_775240 = query.getOrDefault("UseLatestRestorableTime")
  valid_775240 = validateParameter(valid_775240, JBool, required = false, default = nil)
  if valid_775240 != nil:
    section.add "UseLatestRestorableTime", valid_775240
  var valid_775241 = query.getOrDefault("DBSubnetGroupName")
  valid_775241 = validateParameter(valid_775241, JString, required = false,
                                 default = nil)
  if valid_775241 != nil:
    section.add "DBSubnetGroupName", valid_775241
  var valid_775242 = query.getOrDefault("PubliclyAccessible")
  valid_775242 = validateParameter(valid_775242, JBool, required = false, default = nil)
  if valid_775242 != nil:
    section.add "PubliclyAccessible", valid_775242
  var valid_775243 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_775243 = validateParameter(valid_775243, JBool, required = false, default = nil)
  if valid_775243 != nil:
    section.add "AutoMinorVersionUpgrade", valid_775243
  var valid_775244 = query.getOrDefault("Port")
  valid_775244 = validateParameter(valid_775244, JInt, required = false, default = nil)
  if valid_775244 != nil:
    section.add "Port", valid_775244
  var valid_775245 = query.getOrDefault("Version")
  valid_775245 = validateParameter(valid_775245, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_775245 != nil:
    section.add "Version", valid_775245
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775246 = header.getOrDefault("X-Amz-Date")
  valid_775246 = validateParameter(valid_775246, JString, required = false,
                                 default = nil)
  if valid_775246 != nil:
    section.add "X-Amz-Date", valid_775246
  var valid_775247 = header.getOrDefault("X-Amz-Security-Token")
  valid_775247 = validateParameter(valid_775247, JString, required = false,
                                 default = nil)
  if valid_775247 != nil:
    section.add "X-Amz-Security-Token", valid_775247
  var valid_775248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775248 = validateParameter(valid_775248, JString, required = false,
                                 default = nil)
  if valid_775248 != nil:
    section.add "X-Amz-Content-Sha256", valid_775248
  var valid_775249 = header.getOrDefault("X-Amz-Algorithm")
  valid_775249 = validateParameter(valid_775249, JString, required = false,
                                 default = nil)
  if valid_775249 != nil:
    section.add "X-Amz-Algorithm", valid_775249
  var valid_775250 = header.getOrDefault("X-Amz-Signature")
  valid_775250 = validateParameter(valid_775250, JString, required = false,
                                 default = nil)
  if valid_775250 != nil:
    section.add "X-Amz-Signature", valid_775250
  var valid_775251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775251 = validateParameter(valid_775251, JString, required = false,
                                 default = nil)
  if valid_775251 != nil:
    section.add "X-Amz-SignedHeaders", valid_775251
  var valid_775252 = header.getOrDefault("X-Amz-Credential")
  valid_775252 = validateParameter(valid_775252, JString, required = false,
                                 default = nil)
  if valid_775252 != nil:
    section.add "X-Amz-Credential", valid_775252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775253: Call_GetRestoreDBInstanceToPointInTime_775224;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775253.validator(path, query, header, formData, body)
  let scheme = call_775253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775253.url(scheme.get, call_775253.host, call_775253.base,
                         call_775253.route, valid.getOrDefault("path"))
  result = hook(call_775253, url, valid)

proc call*(call_775254: Call_GetRestoreDBInstanceToPointInTime_775224;
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
  var query_775255 = newJObject()
  add(query_775255, "Engine", newJString(Engine))
  add(query_775255, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_775255, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_775255, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_775255, "Iops", newJInt(Iops))
  add(query_775255, "OptionGroupName", newJString(OptionGroupName))
  add(query_775255, "RestoreTime", newJString(RestoreTime))
  add(query_775255, "MultiAZ", newJBool(MultiAZ))
  add(query_775255, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_775255.add "Tags", Tags
  add(query_775255, "DBName", newJString(DBName))
  add(query_775255, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_775255, "Action", newJString(Action))
  add(query_775255, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_775255, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_775255, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_775255, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_775255, "Port", newJInt(Port))
  add(query_775255, "Version", newJString(Version))
  result = call_775254.call(nil, query_775255, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_775224(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_775225, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_775226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_775309 = ref object of OpenApiRestCall_772581
proc url_PostRevokeDBSecurityGroupIngress_775311(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRevokeDBSecurityGroupIngress_775310(path: JsonNode;
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
  var valid_775312 = query.getOrDefault("Action")
  valid_775312 = validateParameter(valid_775312, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_775312 != nil:
    section.add "Action", valid_775312
  var valid_775313 = query.getOrDefault("Version")
  valid_775313 = validateParameter(valid_775313, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_775313 != nil:
    section.add "Version", valid_775313
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775314 = header.getOrDefault("X-Amz-Date")
  valid_775314 = validateParameter(valid_775314, JString, required = false,
                                 default = nil)
  if valid_775314 != nil:
    section.add "X-Amz-Date", valid_775314
  var valid_775315 = header.getOrDefault("X-Amz-Security-Token")
  valid_775315 = validateParameter(valid_775315, JString, required = false,
                                 default = nil)
  if valid_775315 != nil:
    section.add "X-Amz-Security-Token", valid_775315
  var valid_775316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775316 = validateParameter(valid_775316, JString, required = false,
                                 default = nil)
  if valid_775316 != nil:
    section.add "X-Amz-Content-Sha256", valid_775316
  var valid_775317 = header.getOrDefault("X-Amz-Algorithm")
  valid_775317 = validateParameter(valid_775317, JString, required = false,
                                 default = nil)
  if valid_775317 != nil:
    section.add "X-Amz-Algorithm", valid_775317
  var valid_775318 = header.getOrDefault("X-Amz-Signature")
  valid_775318 = validateParameter(valid_775318, JString, required = false,
                                 default = nil)
  if valid_775318 != nil:
    section.add "X-Amz-Signature", valid_775318
  var valid_775319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775319 = validateParameter(valid_775319, JString, required = false,
                                 default = nil)
  if valid_775319 != nil:
    section.add "X-Amz-SignedHeaders", valid_775319
  var valid_775320 = header.getOrDefault("X-Amz-Credential")
  valid_775320 = validateParameter(valid_775320, JString, required = false,
                                 default = nil)
  if valid_775320 != nil:
    section.add "X-Amz-Credential", valid_775320
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_775321 = formData.getOrDefault("DBSecurityGroupName")
  valid_775321 = validateParameter(valid_775321, JString, required = true,
                                 default = nil)
  if valid_775321 != nil:
    section.add "DBSecurityGroupName", valid_775321
  var valid_775322 = formData.getOrDefault("EC2SecurityGroupName")
  valid_775322 = validateParameter(valid_775322, JString, required = false,
                                 default = nil)
  if valid_775322 != nil:
    section.add "EC2SecurityGroupName", valid_775322
  var valid_775323 = formData.getOrDefault("EC2SecurityGroupId")
  valid_775323 = validateParameter(valid_775323, JString, required = false,
                                 default = nil)
  if valid_775323 != nil:
    section.add "EC2SecurityGroupId", valid_775323
  var valid_775324 = formData.getOrDefault("CIDRIP")
  valid_775324 = validateParameter(valid_775324, JString, required = false,
                                 default = nil)
  if valid_775324 != nil:
    section.add "CIDRIP", valid_775324
  var valid_775325 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_775325 = validateParameter(valid_775325, JString, required = false,
                                 default = nil)
  if valid_775325 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_775325
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775326: Call_PostRevokeDBSecurityGroupIngress_775309;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775326.validator(path, query, header, formData, body)
  let scheme = call_775326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775326.url(scheme.get, call_775326.host, call_775326.base,
                         call_775326.route, valid.getOrDefault("path"))
  result = hook(call_775326, url, valid)

proc call*(call_775327: Call_PostRevokeDBSecurityGroupIngress_775309;
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
  var query_775328 = newJObject()
  var formData_775329 = newJObject()
  add(formData_775329, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_775328, "Action", newJString(Action))
  add(formData_775329, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_775329, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_775329, "CIDRIP", newJString(CIDRIP))
  add(query_775328, "Version", newJString(Version))
  add(formData_775329, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_775327.call(nil, query_775328, nil, formData_775329, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_775309(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_775310, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_775311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_775289 = ref object of OpenApiRestCall_772581
proc url_GetRevokeDBSecurityGroupIngress_775291(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRevokeDBSecurityGroupIngress_775290(path: JsonNode;
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
  var valid_775292 = query.getOrDefault("EC2SecurityGroupId")
  valid_775292 = validateParameter(valid_775292, JString, required = false,
                                 default = nil)
  if valid_775292 != nil:
    section.add "EC2SecurityGroupId", valid_775292
  var valid_775293 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_775293 = validateParameter(valid_775293, JString, required = false,
                                 default = nil)
  if valid_775293 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_775293
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_775294 = query.getOrDefault("DBSecurityGroupName")
  valid_775294 = validateParameter(valid_775294, JString, required = true,
                                 default = nil)
  if valid_775294 != nil:
    section.add "DBSecurityGroupName", valid_775294
  var valid_775295 = query.getOrDefault("Action")
  valid_775295 = validateParameter(valid_775295, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_775295 != nil:
    section.add "Action", valid_775295
  var valid_775296 = query.getOrDefault("CIDRIP")
  valid_775296 = validateParameter(valid_775296, JString, required = false,
                                 default = nil)
  if valid_775296 != nil:
    section.add "CIDRIP", valid_775296
  var valid_775297 = query.getOrDefault("EC2SecurityGroupName")
  valid_775297 = validateParameter(valid_775297, JString, required = false,
                                 default = nil)
  if valid_775297 != nil:
    section.add "EC2SecurityGroupName", valid_775297
  var valid_775298 = query.getOrDefault("Version")
  valid_775298 = validateParameter(valid_775298, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_775298 != nil:
    section.add "Version", valid_775298
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_775299 = header.getOrDefault("X-Amz-Date")
  valid_775299 = validateParameter(valid_775299, JString, required = false,
                                 default = nil)
  if valid_775299 != nil:
    section.add "X-Amz-Date", valid_775299
  var valid_775300 = header.getOrDefault("X-Amz-Security-Token")
  valid_775300 = validateParameter(valid_775300, JString, required = false,
                                 default = nil)
  if valid_775300 != nil:
    section.add "X-Amz-Security-Token", valid_775300
  var valid_775301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_775301 = validateParameter(valid_775301, JString, required = false,
                                 default = nil)
  if valid_775301 != nil:
    section.add "X-Amz-Content-Sha256", valid_775301
  var valid_775302 = header.getOrDefault("X-Amz-Algorithm")
  valid_775302 = validateParameter(valid_775302, JString, required = false,
                                 default = nil)
  if valid_775302 != nil:
    section.add "X-Amz-Algorithm", valid_775302
  var valid_775303 = header.getOrDefault("X-Amz-Signature")
  valid_775303 = validateParameter(valid_775303, JString, required = false,
                                 default = nil)
  if valid_775303 != nil:
    section.add "X-Amz-Signature", valid_775303
  var valid_775304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_775304 = validateParameter(valid_775304, JString, required = false,
                                 default = nil)
  if valid_775304 != nil:
    section.add "X-Amz-SignedHeaders", valid_775304
  var valid_775305 = header.getOrDefault("X-Amz-Credential")
  valid_775305 = validateParameter(valid_775305, JString, required = false,
                                 default = nil)
  if valid_775305 != nil:
    section.add "X-Amz-Credential", valid_775305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_775306: Call_GetRevokeDBSecurityGroupIngress_775289;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_775306.validator(path, query, header, formData, body)
  let scheme = call_775306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_775306.url(scheme.get, call_775306.host, call_775306.base,
                         call_775306.route, valid.getOrDefault("path"))
  result = hook(call_775306, url, valid)

proc call*(call_775307: Call_GetRevokeDBSecurityGroupIngress_775289;
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
  var query_775308 = newJObject()
  add(query_775308, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_775308, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_775308, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_775308, "Action", newJString(Action))
  add(query_775308, "CIDRIP", newJString(CIDRIP))
  add(query_775308, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_775308, "Version", newJString(Version))
  result = call_775307.call(nil, query_775308, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_775289(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_775290, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_775291,
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
