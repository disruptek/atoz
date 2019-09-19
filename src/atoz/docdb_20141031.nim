
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon DocumentDB with MongoDB compatibility
## version: 2014-10-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon DocumentDB API documentation
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
  awsServiceName = "docdb"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostAddTagsToResource_773189 = ref object of OpenApiRestCall_772581
proc url_PostAddTagsToResource_773191(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddTagsToResource_773190(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
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
  valid_773192 = validateParameter(valid_773192, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_773192 != nil:
    section.add "Action", valid_773192
  var valid_773193 = query.getOrDefault("Version")
  valid_773193 = validateParameter(valid_773193, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_773201 = formData.getOrDefault("Tags")
  valid_773201 = validateParameter(valid_773201, JArray, required = true, default = nil)
  if valid_773201 != nil:
    section.add "Tags", valid_773201
  var valid_773202 = formData.getOrDefault("ResourceName")
  valid_773202 = validateParameter(valid_773202, JString, required = true,
                                 default = nil)
  if valid_773202 != nil:
    section.add "ResourceName", valid_773202
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773203: Call_PostAddTagsToResource_773189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_773203.validator(path, query, header, formData, body)
  let scheme = call_773203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773203.url(scheme.get, call_773203.host, call_773203.base,
                         call_773203.route, valid.getOrDefault("path"))
  result = hook(call_773203, url, valid)

proc call*(call_773204: Call_PostAddTagsToResource_773189; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-10-31"): Recallable =
  ## postAddTagsToResource
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  ##   Version: string (required)
  var query_773205 = newJObject()
  var formData_773206 = newJObject()
  if Tags != nil:
    formData_773206.add "Tags", Tags
  add(query_773205, "Action", newJString(Action))
  add(formData_773206, "ResourceName", newJString(ResourceName))
  add(query_773205, "Version", newJString(Version))
  result = call_773204.call(nil, query_773205, nil, formData_773206, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_773189(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_773190, base: "/",
    url: url_PostAddTagsToResource_773191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_772917 = ref object of OpenApiRestCall_772581
proc url_GetAddTagsToResource_772919(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddTagsToResource_772918(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_773031 = query.getOrDefault("Tags")
  valid_773031 = validateParameter(valid_773031, JArray, required = true, default = nil)
  if valid_773031 != nil:
    section.add "Tags", valid_773031
  var valid_773032 = query.getOrDefault("ResourceName")
  valid_773032 = validateParameter(valid_773032, JString, required = true,
                                 default = nil)
  if valid_773032 != nil:
    section.add "ResourceName", valid_773032
  var valid_773046 = query.getOrDefault("Action")
  valid_773046 = validateParameter(valid_773046, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_773046 != nil:
    section.add "Action", valid_773046
  var valid_773047 = query.getOrDefault("Version")
  valid_773047 = validateParameter(valid_773047, JString, required = true,
                                 default = newJString("2014-10-31"))
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

proc call*(call_773077: Call_GetAddTagsToResource_772917; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_773077.validator(path, query, header, formData, body)
  let scheme = call_773077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773077.url(scheme.get, call_773077.host, call_773077.base,
                         call_773077.route, valid.getOrDefault("path"))
  result = hook(call_773077, url, valid)

proc call*(call_773148: Call_GetAddTagsToResource_772917; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-10-31"): Recallable =
  ## getAddTagsToResource
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773149 = newJObject()
  if Tags != nil:
    query_773149.add "Tags", Tags
  add(query_773149, "ResourceName", newJString(ResourceName))
  add(query_773149, "Action", newJString(Action))
  add(query_773149, "Version", newJString(Version))
  result = call_773148.call(nil, query_773149, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_772917(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_772918, base: "/",
    url: url_GetAddTagsToResource_772919, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyPendingMaintenanceAction_773225 = ref object of OpenApiRestCall_772581
proc url_PostApplyPendingMaintenanceAction_773227(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostApplyPendingMaintenanceAction_773226(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773228 = query.getOrDefault("Action")
  valid_773228 = validateParameter(valid_773228, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_773228 != nil:
    section.add "Action", valid_773228
  var valid_773229 = query.getOrDefault("Version")
  valid_773229 = validateParameter(valid_773229, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773229 != nil:
    section.add "Version", valid_773229
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773230 = header.getOrDefault("X-Amz-Date")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Date", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Security-Token")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Security-Token", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-Content-Sha256", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Algorithm")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Algorithm", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Signature")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Signature", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-SignedHeaders", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Credential")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Credential", valid_773236
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplyAction: JString (required)
  ##              : <p>The pending maintenance action to apply to this resource.</p> <p>Valid values: <code>system-update</code>, <code>db-upgrade</code> </p>
  ##   ResourceIdentifier: JString (required)
  ##                     : The Amazon Resource Name (ARN) of the resource that the pending maintenance action applies to.
  ##   OptInType: JString (required)
  ##            : <p>A value that specifies the type of opt-in request or undoes an opt-in request. An opt-in request of type <code>immediate</code> can't be undone.</p> <p>Valid values:</p> <ul> <li> <p> <code>immediate</code> - Apply the maintenance action immediately.</p> </li> <li> <p> <code>next-maintenance</code> - Apply the maintenance action during the next maintenance window for the resource.</p> </li> <li> <p> <code>undo-opt-in</code> - Cancel any existing <code>next-maintenance</code> opt-in requests.</p> </li> </ul>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ApplyAction` field"
  var valid_773237 = formData.getOrDefault("ApplyAction")
  valid_773237 = validateParameter(valid_773237, JString, required = true,
                                 default = nil)
  if valid_773237 != nil:
    section.add "ApplyAction", valid_773237
  var valid_773238 = formData.getOrDefault("ResourceIdentifier")
  valid_773238 = validateParameter(valid_773238, JString, required = true,
                                 default = nil)
  if valid_773238 != nil:
    section.add "ResourceIdentifier", valid_773238
  var valid_773239 = formData.getOrDefault("OptInType")
  valid_773239 = validateParameter(valid_773239, JString, required = true,
                                 default = nil)
  if valid_773239 != nil:
    section.add "OptInType", valid_773239
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773240: Call_PostApplyPendingMaintenanceAction_773225;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_773240.validator(path, query, header, formData, body)
  let scheme = call_773240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773240.url(scheme.get, call_773240.host, call_773240.base,
                         call_773240.route, valid.getOrDefault("path"))
  result = hook(call_773240, url, valid)

proc call*(call_773241: Call_PostApplyPendingMaintenanceAction_773225;
          ApplyAction: string; ResourceIdentifier: string; OptInType: string;
          Action: string = "ApplyPendingMaintenanceAction";
          Version: string = "2014-10-31"): Recallable =
  ## postApplyPendingMaintenanceAction
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ##   Action: string (required)
  ##   ApplyAction: string (required)
  ##              : <p>The pending maintenance action to apply to this resource.</p> <p>Valid values: <code>system-update</code>, <code>db-upgrade</code> </p>
  ##   ResourceIdentifier: string (required)
  ##                     : The Amazon Resource Name (ARN) of the resource that the pending maintenance action applies to.
  ##   OptInType: string (required)
  ##            : <p>A value that specifies the type of opt-in request or undoes an opt-in request. An opt-in request of type <code>immediate</code> can't be undone.</p> <p>Valid values:</p> <ul> <li> <p> <code>immediate</code> - Apply the maintenance action immediately.</p> </li> <li> <p> <code>next-maintenance</code> - Apply the maintenance action during the next maintenance window for the resource.</p> </li> <li> <p> <code>undo-opt-in</code> - Cancel any existing <code>next-maintenance</code> opt-in requests.</p> </li> </ul>
  ##   Version: string (required)
  var query_773242 = newJObject()
  var formData_773243 = newJObject()
  add(query_773242, "Action", newJString(Action))
  add(formData_773243, "ApplyAction", newJString(ApplyAction))
  add(formData_773243, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(formData_773243, "OptInType", newJString(OptInType))
  add(query_773242, "Version", newJString(Version))
  result = call_773241.call(nil, query_773242, nil, formData_773243, nil)

var postApplyPendingMaintenanceAction* = Call_PostApplyPendingMaintenanceAction_773225(
    name: "postApplyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_PostApplyPendingMaintenanceAction_773226, base: "/",
    url: url_PostApplyPendingMaintenanceAction_773227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyPendingMaintenanceAction_773207 = ref object of OpenApiRestCall_772581
proc url_GetApplyPendingMaintenanceAction_773209(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApplyPendingMaintenanceAction_773208(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplyAction: JString (required)
  ##              : <p>The pending maintenance action to apply to this resource.</p> <p>Valid values: <code>system-update</code>, <code>db-upgrade</code> </p>
  ##   ResourceIdentifier: JString (required)
  ##                     : The Amazon Resource Name (ARN) of the resource that the pending maintenance action applies to.
  ##   Action: JString (required)
  ##   OptInType: JString (required)
  ##            : <p>A value that specifies the type of opt-in request or undoes an opt-in request. An opt-in request of type <code>immediate</code> can't be undone.</p> <p>Valid values:</p> <ul> <li> <p> <code>immediate</code> - Apply the maintenance action immediately.</p> </li> <li> <p> <code>next-maintenance</code> - Apply the maintenance action during the next maintenance window for the resource.</p> </li> <li> <p> <code>undo-opt-in</code> - Cancel any existing <code>next-maintenance</code> opt-in requests.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplyAction` field"
  var valid_773210 = query.getOrDefault("ApplyAction")
  valid_773210 = validateParameter(valid_773210, JString, required = true,
                                 default = nil)
  if valid_773210 != nil:
    section.add "ApplyAction", valid_773210
  var valid_773211 = query.getOrDefault("ResourceIdentifier")
  valid_773211 = validateParameter(valid_773211, JString, required = true,
                                 default = nil)
  if valid_773211 != nil:
    section.add "ResourceIdentifier", valid_773211
  var valid_773212 = query.getOrDefault("Action")
  valid_773212 = validateParameter(valid_773212, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_773212 != nil:
    section.add "Action", valid_773212
  var valid_773213 = query.getOrDefault("OptInType")
  valid_773213 = validateParameter(valid_773213, JString, required = true,
                                 default = nil)
  if valid_773213 != nil:
    section.add "OptInType", valid_773213
  var valid_773214 = query.getOrDefault("Version")
  valid_773214 = validateParameter(valid_773214, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773214 != nil:
    section.add "Version", valid_773214
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773215 = header.getOrDefault("X-Amz-Date")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Date", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-Security-Token")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-Security-Token", valid_773216
  var valid_773217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773217 = validateParameter(valid_773217, JString, required = false,
                                 default = nil)
  if valid_773217 != nil:
    section.add "X-Amz-Content-Sha256", valid_773217
  var valid_773218 = header.getOrDefault("X-Amz-Algorithm")
  valid_773218 = validateParameter(valid_773218, JString, required = false,
                                 default = nil)
  if valid_773218 != nil:
    section.add "X-Amz-Algorithm", valid_773218
  var valid_773219 = header.getOrDefault("X-Amz-Signature")
  valid_773219 = validateParameter(valid_773219, JString, required = false,
                                 default = nil)
  if valid_773219 != nil:
    section.add "X-Amz-Signature", valid_773219
  var valid_773220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-SignedHeaders", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Credential")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Credential", valid_773221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773222: Call_GetApplyPendingMaintenanceAction_773207;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_773222.validator(path, query, header, formData, body)
  let scheme = call_773222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773222.url(scheme.get, call_773222.host, call_773222.base,
                         call_773222.route, valid.getOrDefault("path"))
  result = hook(call_773222, url, valid)

proc call*(call_773223: Call_GetApplyPendingMaintenanceAction_773207;
          ApplyAction: string; ResourceIdentifier: string; OptInType: string;
          Action: string = "ApplyPendingMaintenanceAction";
          Version: string = "2014-10-31"): Recallable =
  ## getApplyPendingMaintenanceAction
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ##   ApplyAction: string (required)
  ##              : <p>The pending maintenance action to apply to this resource.</p> <p>Valid values: <code>system-update</code>, <code>db-upgrade</code> </p>
  ##   ResourceIdentifier: string (required)
  ##                     : The Amazon Resource Name (ARN) of the resource that the pending maintenance action applies to.
  ##   Action: string (required)
  ##   OptInType: string (required)
  ##            : <p>A value that specifies the type of opt-in request or undoes an opt-in request. An opt-in request of type <code>immediate</code> can't be undone.</p> <p>Valid values:</p> <ul> <li> <p> <code>immediate</code> - Apply the maintenance action immediately.</p> </li> <li> <p> <code>next-maintenance</code> - Apply the maintenance action during the next maintenance window for the resource.</p> </li> <li> <p> <code>undo-opt-in</code> - Cancel any existing <code>next-maintenance</code> opt-in requests.</p> </li> </ul>
  ##   Version: string (required)
  var query_773224 = newJObject()
  add(query_773224, "ApplyAction", newJString(ApplyAction))
  add(query_773224, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_773224, "Action", newJString(Action))
  add(query_773224, "OptInType", newJString(OptInType))
  add(query_773224, "Version", newJString(Version))
  result = call_773223.call(nil, query_773224, nil, nil, nil)

var getApplyPendingMaintenanceAction* = Call_GetApplyPendingMaintenanceAction_773207(
    name: "getApplyPendingMaintenanceAction", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_GetApplyPendingMaintenanceAction_773208, base: "/",
    url: url_GetApplyPendingMaintenanceAction_773209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterParameterGroup_773263 = ref object of OpenApiRestCall_772581
proc url_PostCopyDBClusterParameterGroup_773265(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBClusterParameterGroup_773264(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Copies the specified DB cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773266 = query.getOrDefault("Action")
  valid_773266 = validateParameter(valid_773266, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_773266 != nil:
    section.add "Action", valid_773266
  var valid_773267 = query.getOrDefault("Version")
  valid_773267 = validateParameter(valid_773267, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773267 != nil:
    section.add "Version", valid_773267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773268 = header.getOrDefault("X-Amz-Date")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Date", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Security-Token")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Security-Token", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Content-Sha256", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Algorithm")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Algorithm", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Signature")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Signature", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-SignedHeaders", valid_773273
  var valid_773274 = header.getOrDefault("X-Amz-Credential")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-Credential", valid_773274
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBClusterParameterGroupDescription: JString (required)
  ##                                           : A description for the copied DB cluster parameter group.
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   SourceDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid DB cluster parameter group.</p> </li> <li> <p>If the source DB cluster parameter group is in the same AWS Region as the copy, specify a valid DB parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source DB parameter group is in a different AWS Region than the copy, specify a valid DB cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   TargetDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier for the copied DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBClusterParameterGroupDescription` field"
  var valid_773275 = formData.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_773275 = validateParameter(valid_773275, JString, required = true,
                                 default = nil)
  if valid_773275 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_773275
  var valid_773276 = formData.getOrDefault("Tags")
  valid_773276 = validateParameter(valid_773276, JArray, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "Tags", valid_773276
  var valid_773277 = formData.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_773277 = validateParameter(valid_773277, JString, required = true,
                                 default = nil)
  if valid_773277 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_773277
  var valid_773278 = formData.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_773278 = validateParameter(valid_773278, JString, required = true,
                                 default = nil)
  if valid_773278 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_773278
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773279: Call_PostCopyDBClusterParameterGroup_773263;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_773279.validator(path, query, header, formData, body)
  let scheme = call_773279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773279.url(scheme.get, call_773279.host, call_773279.base,
                         call_773279.route, valid.getOrDefault("path"))
  result = hook(call_773279, url, valid)

proc call*(call_773280: Call_PostCopyDBClusterParameterGroup_773263;
          TargetDBClusterParameterGroupDescription: string;
          SourceDBClusterParameterGroupIdentifier: string;
          TargetDBClusterParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postCopyDBClusterParameterGroup
  ## Copies the specified DB cluster parameter group.
  ##   TargetDBClusterParameterGroupDescription: string (required)
  ##                                           : A description for the copied DB cluster parameter group.
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   Action: string (required)
  ##   SourceDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid DB cluster parameter group.</p> </li> <li> <p>If the source DB cluster parameter group is in the same AWS Region as the copy, specify a valid DB parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source DB parameter group is in a different AWS Region than the copy, specify a valid DB cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   TargetDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier for the copied DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   Version: string (required)
  var query_773281 = newJObject()
  var formData_773282 = newJObject()
  add(formData_773282, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  if Tags != nil:
    formData_773282.add "Tags", Tags
  add(query_773281, "Action", newJString(Action))
  add(formData_773282, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(formData_773282, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_773281, "Version", newJString(Version))
  result = call_773280.call(nil, query_773281, nil, formData_773282, nil)

var postCopyDBClusterParameterGroup* = Call_PostCopyDBClusterParameterGroup_773263(
    name: "postCopyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_PostCopyDBClusterParameterGroup_773264, base: "/",
    url: url_PostCopyDBClusterParameterGroup_773265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterParameterGroup_773244 = ref object of OpenApiRestCall_772581
proc url_GetCopyDBClusterParameterGroup_773246(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBClusterParameterGroup_773245(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Copies the specified DB cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid DB cluster parameter group.</p> </li> <li> <p>If the source DB cluster parameter group is in the same AWS Region as the copy, specify a valid DB parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source DB parameter group is in a different AWS Region than the copy, specify a valid DB cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   TargetDBClusterParameterGroupDescription: JString (required)
  ##                                           : A description for the copied DB cluster parameter group.
  ##   Action: JString (required)
  ##   TargetDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier for the copied DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBClusterParameterGroupIdentifier` field"
  var valid_773247 = query.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_773247 = validateParameter(valid_773247, JString, required = true,
                                 default = nil)
  if valid_773247 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_773247
  var valid_773248 = query.getOrDefault("Tags")
  valid_773248 = validateParameter(valid_773248, JArray, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "Tags", valid_773248
  var valid_773249 = query.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_773249 = validateParameter(valid_773249, JString, required = true,
                                 default = nil)
  if valid_773249 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_773249
  var valid_773250 = query.getOrDefault("Action")
  valid_773250 = validateParameter(valid_773250, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_773250 != nil:
    section.add "Action", valid_773250
  var valid_773251 = query.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_773251 = validateParameter(valid_773251, JString, required = true,
                                 default = nil)
  if valid_773251 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_773251
  var valid_773252 = query.getOrDefault("Version")
  valid_773252 = validateParameter(valid_773252, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773252 != nil:
    section.add "Version", valid_773252
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773253 = header.getOrDefault("X-Amz-Date")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Date", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Security-Token")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Security-Token", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Content-Sha256", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Algorithm")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Algorithm", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Signature")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Signature", valid_773257
  var valid_773258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-SignedHeaders", valid_773258
  var valid_773259 = header.getOrDefault("X-Amz-Credential")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-Credential", valid_773259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773260: Call_GetCopyDBClusterParameterGroup_773244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_773260.validator(path, query, header, formData, body)
  let scheme = call_773260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773260.url(scheme.get, call_773260.host, call_773260.base,
                         call_773260.route, valid.getOrDefault("path"))
  result = hook(call_773260, url, valid)

proc call*(call_773261: Call_GetCopyDBClusterParameterGroup_773244;
          SourceDBClusterParameterGroupIdentifier: string;
          TargetDBClusterParameterGroupDescription: string;
          TargetDBClusterParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getCopyDBClusterParameterGroup
  ## Copies the specified DB cluster parameter group.
  ##   SourceDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid DB cluster parameter group.</p> </li> <li> <p>If the source DB cluster parameter group is in the same AWS Region as the copy, specify a valid DB parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source DB parameter group is in a different AWS Region than the copy, specify a valid DB cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   TargetDBClusterParameterGroupDescription: string (required)
  ##                                           : A description for the copied DB cluster parameter group.
  ##   Action: string (required)
  ##   TargetDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier for the copied DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   Version: string (required)
  var query_773262 = newJObject()
  add(query_773262, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  if Tags != nil:
    query_773262.add "Tags", Tags
  add(query_773262, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  add(query_773262, "Action", newJString(Action))
  add(query_773262, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_773262, "Version", newJString(Version))
  result = call_773261.call(nil, query_773262, nil, nil, nil)

var getCopyDBClusterParameterGroup* = Call_GetCopyDBClusterParameterGroup_773244(
    name: "getCopyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_GetCopyDBClusterParameterGroup_773245, base: "/",
    url: url_GetCopyDBClusterParameterGroup_773246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterSnapshot_773304 = ref object of OpenApiRestCall_772581
proc url_PostCopyDBClusterSnapshot_773306(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBClusterSnapshot_773305(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773307 = query.getOrDefault("Action")
  valid_773307 = validateParameter(valid_773307, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_773307 != nil:
    section.add "Action", valid_773307
  var valid_773308 = query.getOrDefault("Version")
  valid_773308 = validateParameter(valid_773308, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773308 != nil:
    section.add "Version", valid_773308
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773309 = header.getOrDefault("X-Amz-Date")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Date", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-Security-Token")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Security-Token", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Content-Sha256", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-Algorithm")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-Algorithm", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Signature")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Signature", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-SignedHeaders", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Credential")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Credential", valid_773315
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreSignedUrl: JString
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source DB cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted DB cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the DB cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The DB cluster snapshot identifier for the encrypted DB cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted DB cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   CopyTags: JBool
  ##           : Set to <code>true</code> to copy all tags from the source DB cluster snapshot to the target DB cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   SourceDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the DB cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared DB cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid DB snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid DB cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   TargetDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the new DB cluster snapshot to create from the source DB cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key ID for an encrypted DB cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted DB cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the DB cluster snapshot is encrypted with the same AWS KMS key as the source DB cluster snapshot. </p> <p>If you copy an encrypted DB cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted DB cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the DB cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted DB cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  section = newJObject()
  var valid_773316 = formData.getOrDefault("PreSignedUrl")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "PreSignedUrl", valid_773316
  var valid_773317 = formData.getOrDefault("Tags")
  valid_773317 = validateParameter(valid_773317, JArray, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "Tags", valid_773317
  var valid_773318 = formData.getOrDefault("CopyTags")
  valid_773318 = validateParameter(valid_773318, JBool, required = false, default = nil)
  if valid_773318 != nil:
    section.add "CopyTags", valid_773318
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterSnapshotIdentifier` field"
  var valid_773319 = formData.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_773319 = validateParameter(valid_773319, JString, required = true,
                                 default = nil)
  if valid_773319 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_773319
  var valid_773320 = formData.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_773320 = validateParameter(valid_773320, JString, required = true,
                                 default = nil)
  if valid_773320 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_773320
  var valid_773321 = formData.getOrDefault("KmsKeyId")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = nil)
  if valid_773321 != nil:
    section.add "KmsKeyId", valid_773321
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773322: Call_PostCopyDBClusterSnapshot_773304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_773322.validator(path, query, header, formData, body)
  let scheme = call_773322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773322.url(scheme.get, call_773322.host, call_773322.base,
                         call_773322.route, valid.getOrDefault("path"))
  result = hook(call_773322, url, valid)

proc call*(call_773323: Call_PostCopyDBClusterSnapshot_773304;
          SourceDBClusterSnapshotIdentifier: string;
          TargetDBClusterSnapshotIdentifier: string; PreSignedUrl: string = "";
          Tags: JsonNode = nil; CopyTags: bool = false;
          Action: string = "CopyDBClusterSnapshot"; KmsKeyId: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postCopyDBClusterSnapshot
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ##   PreSignedUrl: string
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source DB cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted DB cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the DB cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The DB cluster snapshot identifier for the encrypted DB cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted DB cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   CopyTags: bool
  ##           : Set to <code>true</code> to copy all tags from the source DB cluster snapshot to the target DB cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   SourceDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the DB cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared DB cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid DB snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid DB cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   TargetDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the new DB cluster snapshot to create from the source DB cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   Action: string (required)
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key ID for an encrypted DB cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted DB cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the DB cluster snapshot is encrypted with the same AWS KMS key as the source DB cluster snapshot. </p> <p>If you copy an encrypted DB cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted DB cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the DB cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted DB cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   Version: string (required)
  var query_773324 = newJObject()
  var formData_773325 = newJObject()
  add(formData_773325, "PreSignedUrl", newJString(PreSignedUrl))
  if Tags != nil:
    formData_773325.add "Tags", Tags
  add(formData_773325, "CopyTags", newJBool(CopyTags))
  add(formData_773325, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(formData_773325, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_773324, "Action", newJString(Action))
  add(formData_773325, "KmsKeyId", newJString(KmsKeyId))
  add(query_773324, "Version", newJString(Version))
  result = call_773323.call(nil, query_773324, nil, formData_773325, nil)

var postCopyDBClusterSnapshot* = Call_PostCopyDBClusterSnapshot_773304(
    name: "postCopyDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_PostCopyDBClusterSnapshot_773305, base: "/",
    url: url_PostCopyDBClusterSnapshot_773306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterSnapshot_773283 = ref object of OpenApiRestCall_772581
proc url_GetCopyDBClusterSnapshot_773285(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBClusterSnapshot_773284(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PreSignedUrl: JString
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source DB cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted DB cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the DB cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The DB cluster snapshot identifier for the encrypted DB cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted DB cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   TargetDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the new DB cluster snapshot to create from the source DB cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   Action: JString (required)
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key ID for an encrypted DB cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted DB cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the DB cluster snapshot is encrypted with the same AWS KMS key as the source DB cluster snapshot. </p> <p>If you copy an encrypted DB cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted DB cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the DB cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted DB cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   SourceDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the DB cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared DB cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid DB snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid DB cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Version: JString (required)
  ##   CopyTags: JBool
  ##           : Set to <code>true</code> to copy all tags from the source DB cluster snapshot to the target DB cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  section = newJObject()
  var valid_773286 = query.getOrDefault("PreSignedUrl")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "PreSignedUrl", valid_773286
  assert query != nil, "query argument is necessary due to required `TargetDBClusterSnapshotIdentifier` field"
  var valid_773287 = query.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_773287 = validateParameter(valid_773287, JString, required = true,
                                 default = nil)
  if valid_773287 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_773287
  var valid_773288 = query.getOrDefault("Tags")
  valid_773288 = validateParameter(valid_773288, JArray, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "Tags", valid_773288
  var valid_773289 = query.getOrDefault("Action")
  valid_773289 = validateParameter(valid_773289, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_773289 != nil:
    section.add "Action", valid_773289
  var valid_773290 = query.getOrDefault("KmsKeyId")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "KmsKeyId", valid_773290
  var valid_773291 = query.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_773291 = validateParameter(valid_773291, JString, required = true,
                                 default = nil)
  if valid_773291 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_773291
  var valid_773292 = query.getOrDefault("Version")
  valid_773292 = validateParameter(valid_773292, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773292 != nil:
    section.add "Version", valid_773292
  var valid_773293 = query.getOrDefault("CopyTags")
  valid_773293 = validateParameter(valid_773293, JBool, required = false, default = nil)
  if valid_773293 != nil:
    section.add "CopyTags", valid_773293
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773294 = header.getOrDefault("X-Amz-Date")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-Date", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Security-Token")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Security-Token", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Content-Sha256", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-Algorithm")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-Algorithm", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Signature")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Signature", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-SignedHeaders", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Credential")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Credential", valid_773300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773301: Call_GetCopyDBClusterSnapshot_773283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_773301.validator(path, query, header, formData, body)
  let scheme = call_773301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773301.url(scheme.get, call_773301.host, call_773301.base,
                         call_773301.route, valid.getOrDefault("path"))
  result = hook(call_773301, url, valid)

proc call*(call_773302: Call_GetCopyDBClusterSnapshot_773283;
          TargetDBClusterSnapshotIdentifier: string;
          SourceDBClusterSnapshotIdentifier: string; PreSignedUrl: string = "";
          Tags: JsonNode = nil; Action: string = "CopyDBClusterSnapshot";
          KmsKeyId: string = ""; Version: string = "2014-10-31"; CopyTags: bool = false): Recallable =
  ## getCopyDBClusterSnapshot
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ##   PreSignedUrl: string
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source DB cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted DB cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the DB cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The DB cluster snapshot identifier for the encrypted DB cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted DB cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   TargetDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the new DB cluster snapshot to create from the source DB cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   Action: string (required)
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key ID for an encrypted DB cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted DB cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the DB cluster snapshot is encrypted with the same AWS KMS key as the source DB cluster snapshot. </p> <p>If you copy an encrypted DB cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted DB cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the DB cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted DB cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   SourceDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the DB cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared DB cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid DB snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid DB cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Version: string (required)
  ##   CopyTags: bool
  ##           : Set to <code>true</code> to copy all tags from the source DB cluster snapshot to the target DB cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  var query_773303 = newJObject()
  add(query_773303, "PreSignedUrl", newJString(PreSignedUrl))
  add(query_773303, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  if Tags != nil:
    query_773303.add "Tags", Tags
  add(query_773303, "Action", newJString(Action))
  add(query_773303, "KmsKeyId", newJString(KmsKeyId))
  add(query_773303, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(query_773303, "Version", newJString(Version))
  add(query_773303, "CopyTags", newJBool(CopyTags))
  result = call_773302.call(nil, query_773303, nil, nil, nil)

var getCopyDBClusterSnapshot* = Call_GetCopyDBClusterSnapshot_773283(
    name: "getCopyDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_GetCopyDBClusterSnapshot_773284, base: "/",
    url: url_GetCopyDBClusterSnapshot_773285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBCluster_773359 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBCluster_773361(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBCluster_773360(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773362 = query.getOrDefault("Action")
  valid_773362 = validateParameter(valid_773362, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_773362 != nil:
    section.add "Action", valid_773362
  var valid_773363 = query.getOrDefault("Version")
  valid_773363 = validateParameter(valid_773363, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773363 != nil:
    section.add "Version", valid_773363
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773364 = header.getOrDefault("X-Amz-Date")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-Date", valid_773364
  var valid_773365 = header.getOrDefault("X-Amz-Security-Token")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-Security-Token", valid_773365
  var valid_773366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773366 = validateParameter(valid_773366, JString, required = false,
                                 default = nil)
  if valid_773366 != nil:
    section.add "X-Amz-Content-Sha256", valid_773366
  var valid_773367 = header.getOrDefault("X-Amz-Algorithm")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "X-Amz-Algorithm", valid_773367
  var valid_773368 = header.getOrDefault("X-Amz-Signature")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Signature", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-SignedHeaders", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-Credential")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Credential", valid_773370
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : The port number on which the instances in the DB cluster accept connections.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this DB cluster.
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this DB cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster.
  ##   MasterUserPassword: JString (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: JString
  ##                    : <p>A DB subnet group to associate with this DB cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the DB cluster can be created in.
  ##   DBClusterParameterGroupName: JString
  ##                              :  The name of the DB cluster parameter group to associate with this DB cluster.
  ##   MasterUsername: JString (required)
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 16 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier for an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a DB cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new DB cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted DB cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   StorageEncrypted: JBool
  ##                   : Specifies whether the DB cluster is encrypted.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   EngineVersion: JString
  ##                : The version number of the database engine to use.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  section = newJObject()
  var valid_773371 = formData.getOrDefault("Port")
  valid_773371 = validateParameter(valid_773371, JInt, required = false, default = nil)
  if valid_773371 != nil:
    section.add "Port", valid_773371
  var valid_773372 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_773372 = validateParameter(valid_773372, JArray, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "VpcSecurityGroupIds", valid_773372
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_773373 = formData.getOrDefault("Engine")
  valid_773373 = validateParameter(valid_773373, JString, required = true,
                                 default = nil)
  if valid_773373 != nil:
    section.add "Engine", valid_773373
  var valid_773374 = formData.getOrDefault("BackupRetentionPeriod")
  valid_773374 = validateParameter(valid_773374, JInt, required = false, default = nil)
  if valid_773374 != nil:
    section.add "BackupRetentionPeriod", valid_773374
  var valid_773375 = formData.getOrDefault("Tags")
  valid_773375 = validateParameter(valid_773375, JArray, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "Tags", valid_773375
  var valid_773376 = formData.getOrDefault("MasterUserPassword")
  valid_773376 = validateParameter(valid_773376, JString, required = true,
                                 default = nil)
  if valid_773376 != nil:
    section.add "MasterUserPassword", valid_773376
  var valid_773377 = formData.getOrDefault("DeletionProtection")
  valid_773377 = validateParameter(valid_773377, JBool, required = false, default = nil)
  if valid_773377 != nil:
    section.add "DeletionProtection", valid_773377
  var valid_773378 = formData.getOrDefault("DBSubnetGroupName")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "DBSubnetGroupName", valid_773378
  var valid_773379 = formData.getOrDefault("AvailabilityZones")
  valid_773379 = validateParameter(valid_773379, JArray, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "AvailabilityZones", valid_773379
  var valid_773380 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "DBClusterParameterGroupName", valid_773380
  var valid_773381 = formData.getOrDefault("MasterUsername")
  valid_773381 = validateParameter(valid_773381, JString, required = true,
                                 default = nil)
  if valid_773381 != nil:
    section.add "MasterUsername", valid_773381
  var valid_773382 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_773382 = validateParameter(valid_773382, JArray, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "EnableCloudwatchLogsExports", valid_773382
  var valid_773383 = formData.getOrDefault("PreferredBackupWindow")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "PreferredBackupWindow", valid_773383
  var valid_773384 = formData.getOrDefault("KmsKeyId")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "KmsKeyId", valid_773384
  var valid_773385 = formData.getOrDefault("StorageEncrypted")
  valid_773385 = validateParameter(valid_773385, JBool, required = false, default = nil)
  if valid_773385 != nil:
    section.add "StorageEncrypted", valid_773385
  var valid_773386 = formData.getOrDefault("DBClusterIdentifier")
  valid_773386 = validateParameter(valid_773386, JString, required = true,
                                 default = nil)
  if valid_773386 != nil:
    section.add "DBClusterIdentifier", valid_773386
  var valid_773387 = formData.getOrDefault("EngineVersion")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "EngineVersion", valid_773387
  var valid_773388 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "PreferredMaintenanceWindow", valid_773388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773389: Call_PostCreateDBCluster_773359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_773389.validator(path, query, header, formData, body)
  let scheme = call_773389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773389.url(scheme.get, call_773389.host, call_773389.base,
                         call_773389.route, valid.getOrDefault("path"))
  result = hook(call_773389, url, valid)

proc call*(call_773390: Call_PostCreateDBCluster_773359; Engine: string;
          MasterUserPassword: string; MasterUsername: string;
          DBClusterIdentifier: string; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          Tags: JsonNode = nil; DeletionProtection: bool = false;
          DBSubnetGroupName: string = ""; Action: string = "CreateDBCluster";
          AvailabilityZones: JsonNode = nil;
          DBClusterParameterGroupName: string = "";
          EnableCloudwatchLogsExports: JsonNode = nil;
          PreferredBackupWindow: string = ""; KmsKeyId: string = "";
          StorageEncrypted: bool = false; EngineVersion: string = "";
          Version: string = "2014-10-31"; PreferredMaintenanceWindow: string = ""): Recallable =
  ## postCreateDBCluster
  ## Creates a new Amazon DocumentDB DB cluster.
  ##   Port: int
  ##       : The port number on which the instances in the DB cluster accept connections.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this DB cluster.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this DB cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster.
  ##   MasterUserPassword: string (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: string
  ##                    : <p>A DB subnet group to associate with this DB cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the DB cluster can be created in.
  ##   DBClusterParameterGroupName: string
  ##                              :  The name of the DB cluster parameter group to associate with this DB cluster.
  ##   MasterUsername: string (required)
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 16 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier for an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a DB cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new DB cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted DB cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   StorageEncrypted: bool
  ##                   : Specifies whether the DB cluster is encrypted.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   EngineVersion: string
  ##                : The version number of the database engine to use.
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  var query_773391 = newJObject()
  var formData_773392 = newJObject()
  add(formData_773392, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_773392.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_773392, "Engine", newJString(Engine))
  add(formData_773392, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if Tags != nil:
    formData_773392.add "Tags", Tags
  add(formData_773392, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_773392, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_773392, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773391, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_773392.add "AvailabilityZones", AvailabilityZones
  add(formData_773392, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_773392, "MasterUsername", newJString(MasterUsername))
  if EnableCloudwatchLogsExports != nil:
    formData_773392.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_773392, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_773392, "KmsKeyId", newJString(KmsKeyId))
  add(formData_773392, "StorageEncrypted", newJBool(StorageEncrypted))
  add(formData_773392, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_773392, "EngineVersion", newJString(EngineVersion))
  add(query_773391, "Version", newJString(Version))
  add(formData_773392, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_773390.call(nil, query_773391, nil, formData_773392, nil)

var postCreateDBCluster* = Call_PostCreateDBCluster_773359(
    name: "postCreateDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBCluster",
    validator: validate_PostCreateDBCluster_773360, base: "/",
    url: url_PostCreateDBCluster_773361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBCluster_773326 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBCluster_773328(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBCluster_773327(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this DB cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: JString
  ##                              :  The name of the DB cluster parameter group to associate with this DB cluster.
  ##   StorageEncrypted: JBool
  ##                   : Specifies whether the DB cluster is encrypted.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the DB cluster can be created in.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   MasterUserPassword: JString (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this DB cluster.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##                    : <p>A DB subnet group to associate with this DB cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier for an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a DB cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new DB cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted DB cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   EngineVersion: JString
  ##                : The version number of the database engine to use.
  ##   Port: JInt
  ##       : The port number on which the instances in the DB cluster accept connections.
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Version: JString (required)
  ##   MasterUsername: JString (required)
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 16 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_773329 = query.getOrDefault("Engine")
  valid_773329 = validateParameter(valid_773329, JString, required = true,
                                 default = nil)
  if valid_773329 != nil:
    section.add "Engine", valid_773329
  var valid_773330 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "PreferredMaintenanceWindow", valid_773330
  var valid_773331 = query.getOrDefault("DBClusterParameterGroupName")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "DBClusterParameterGroupName", valid_773331
  var valid_773332 = query.getOrDefault("StorageEncrypted")
  valid_773332 = validateParameter(valid_773332, JBool, required = false, default = nil)
  if valid_773332 != nil:
    section.add "StorageEncrypted", valid_773332
  var valid_773333 = query.getOrDefault("AvailabilityZones")
  valid_773333 = validateParameter(valid_773333, JArray, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "AvailabilityZones", valid_773333
  var valid_773334 = query.getOrDefault("DBClusterIdentifier")
  valid_773334 = validateParameter(valid_773334, JString, required = true,
                                 default = nil)
  if valid_773334 != nil:
    section.add "DBClusterIdentifier", valid_773334
  var valid_773335 = query.getOrDefault("MasterUserPassword")
  valid_773335 = validateParameter(valid_773335, JString, required = true,
                                 default = nil)
  if valid_773335 != nil:
    section.add "MasterUserPassword", valid_773335
  var valid_773336 = query.getOrDefault("VpcSecurityGroupIds")
  valid_773336 = validateParameter(valid_773336, JArray, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "VpcSecurityGroupIds", valid_773336
  var valid_773337 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_773337 = validateParameter(valid_773337, JArray, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "EnableCloudwatchLogsExports", valid_773337
  var valid_773338 = query.getOrDefault("Tags")
  valid_773338 = validateParameter(valid_773338, JArray, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "Tags", valid_773338
  var valid_773339 = query.getOrDefault("BackupRetentionPeriod")
  valid_773339 = validateParameter(valid_773339, JInt, required = false, default = nil)
  if valid_773339 != nil:
    section.add "BackupRetentionPeriod", valid_773339
  var valid_773340 = query.getOrDefault("DeletionProtection")
  valid_773340 = validateParameter(valid_773340, JBool, required = false, default = nil)
  if valid_773340 != nil:
    section.add "DeletionProtection", valid_773340
  var valid_773341 = query.getOrDefault("Action")
  valid_773341 = validateParameter(valid_773341, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_773341 != nil:
    section.add "Action", valid_773341
  var valid_773342 = query.getOrDefault("DBSubnetGroupName")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "DBSubnetGroupName", valid_773342
  var valid_773343 = query.getOrDefault("KmsKeyId")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "KmsKeyId", valid_773343
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
                                 default = newJString("2014-10-31"))
  if valid_773347 != nil:
    section.add "Version", valid_773347
  var valid_773348 = query.getOrDefault("MasterUsername")
  valid_773348 = validateParameter(valid_773348, JString, required = true,
                                 default = nil)
  if valid_773348 != nil:
    section.add "MasterUsername", valid_773348
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773349 = header.getOrDefault("X-Amz-Date")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-Date", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-Security-Token")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Security-Token", valid_773350
  var valid_773351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-Content-Sha256", valid_773351
  var valid_773352 = header.getOrDefault("X-Amz-Algorithm")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-Algorithm", valid_773352
  var valid_773353 = header.getOrDefault("X-Amz-Signature")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-Signature", valid_773353
  var valid_773354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-SignedHeaders", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-Credential")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Credential", valid_773355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773356: Call_GetCreateDBCluster_773326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_773356.validator(path, query, header, formData, body)
  let scheme = call_773356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773356.url(scheme.get, call_773356.host, call_773356.base,
                         call_773356.route, valid.getOrDefault("path"))
  result = hook(call_773356, url, valid)

proc call*(call_773357: Call_GetCreateDBCluster_773326; Engine: string;
          DBClusterIdentifier: string; MasterUserPassword: string;
          MasterUsername: string; PreferredMaintenanceWindow: string = "";
          DBClusterParameterGroupName: string = ""; StorageEncrypted: bool = false;
          AvailabilityZones: JsonNode = nil; VpcSecurityGroupIds: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; Tags: JsonNode = nil;
          BackupRetentionPeriod: int = 0; DeletionProtection: bool = false;
          Action: string = "CreateDBCluster"; DBSubnetGroupName: string = "";
          KmsKeyId: string = ""; EngineVersion: string = ""; Port: int = 0;
          PreferredBackupWindow: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getCreateDBCluster
  ## Creates a new Amazon DocumentDB DB cluster.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this DB cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: string
  ##                              :  The name of the DB cluster parameter group to associate with this DB cluster.
  ##   StorageEncrypted: bool
  ##                   : Specifies whether the DB cluster is encrypted.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the DB cluster can be created in.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   MasterUserPassword: string (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this DB cluster.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##                    : <p>A DB subnet group to associate with this DB cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier for an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a DB cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new DB cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted DB cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   EngineVersion: string
  ##                : The version number of the database engine to use.
  ##   Port: int
  ##       : The port number on which the instances in the DB cluster accept connections.
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Version: string (required)
  ##   MasterUsername: string (required)
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 16 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  var query_773358 = newJObject()
  add(query_773358, "Engine", newJString(Engine))
  add(query_773358, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_773358, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_773358, "StorageEncrypted", newJBool(StorageEncrypted))
  if AvailabilityZones != nil:
    query_773358.add "AvailabilityZones", AvailabilityZones
  add(query_773358, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_773358, "MasterUserPassword", newJString(MasterUserPassword))
  if VpcSecurityGroupIds != nil:
    query_773358.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_773358.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_773358.add "Tags", Tags
  add(query_773358, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_773358, "DeletionProtection", newJBool(DeletionProtection))
  add(query_773358, "Action", newJString(Action))
  add(query_773358, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773358, "KmsKeyId", newJString(KmsKeyId))
  add(query_773358, "EngineVersion", newJString(EngineVersion))
  add(query_773358, "Port", newJInt(Port))
  add(query_773358, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_773358, "Version", newJString(Version))
  add(query_773358, "MasterUsername", newJString(MasterUsername))
  result = call_773357.call(nil, query_773358, nil, nil, nil)

var getCreateDBCluster* = Call_GetCreateDBCluster_773326(
    name: "getCreateDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CreateDBCluster", validator: validate_GetCreateDBCluster_773327,
    base: "/", url: url_GetCreateDBCluster_773328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterParameterGroup_773412 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBClusterParameterGroup_773414(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBClusterParameterGroup_773413(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773415 = query.getOrDefault("Action")
  valid_773415 = validateParameter(valid_773415, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_773415 != nil:
    section.add "Action", valid_773415
  var valid_773416 = query.getOrDefault("Version")
  valid_773416 = validateParameter(valid_773416, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773416 != nil:
    section.add "Version", valid_773416
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster parameter group.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The DB cluster parameter group family name.
  ##   Description: JString (required)
  ##              : The description for the DB cluster parameter group.
  section = newJObject()
  var valid_773424 = formData.getOrDefault("Tags")
  valid_773424 = validateParameter(valid_773424, JArray, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "Tags", valid_773424
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_773425 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_773425 = validateParameter(valid_773425, JString, required = true,
                                 default = nil)
  if valid_773425 != nil:
    section.add "DBClusterParameterGroupName", valid_773425
  var valid_773426 = formData.getOrDefault("DBParameterGroupFamily")
  valid_773426 = validateParameter(valid_773426, JString, required = true,
                                 default = nil)
  if valid_773426 != nil:
    section.add "DBParameterGroupFamily", valid_773426
  var valid_773427 = formData.getOrDefault("Description")
  valid_773427 = validateParameter(valid_773427, JString, required = true,
                                 default = nil)
  if valid_773427 != nil:
    section.add "Description", valid_773427
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773428: Call_PostCreateDBClusterParameterGroup_773412;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_773428.validator(path, query, header, formData, body)
  let scheme = call_773428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773428.url(scheme.get, call_773428.host, call_773428.base,
                         call_773428.route, valid.getOrDefault("path"))
  result = hook(call_773428, url, valid)

proc call*(call_773429: Call_PostCreateDBClusterParameterGroup_773412;
          DBClusterParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postCreateDBClusterParameterGroup
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster parameter group.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   DBParameterGroupFamily: string (required)
  ##                         : The DB cluster parameter group family name.
  ##   Version: string (required)
  ##   Description: string (required)
  ##              : The description for the DB cluster parameter group.
  var query_773430 = newJObject()
  var formData_773431 = newJObject()
  if Tags != nil:
    formData_773431.add "Tags", Tags
  add(query_773430, "Action", newJString(Action))
  add(formData_773431, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_773431, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_773430, "Version", newJString(Version))
  add(formData_773431, "Description", newJString(Description))
  result = call_773429.call(nil, query_773430, nil, formData_773431, nil)

var postCreateDBClusterParameterGroup* = Call_PostCreateDBClusterParameterGroup_773412(
    name: "postCreateDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_PostCreateDBClusterParameterGroup_773413, base: "/",
    url: url_PostCreateDBClusterParameterGroup_773414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterParameterGroup_773393 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBClusterParameterGroup_773395(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBClusterParameterGroup_773394(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   Description: JString (required)
  ##              : The description for the DB cluster parameter group.
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The DB cluster parameter group family name.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster parameter group.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_773396 = query.getOrDefault("DBClusterParameterGroupName")
  valid_773396 = validateParameter(valid_773396, JString, required = true,
                                 default = nil)
  if valid_773396 != nil:
    section.add "DBClusterParameterGroupName", valid_773396
  var valid_773397 = query.getOrDefault("Description")
  valid_773397 = validateParameter(valid_773397, JString, required = true,
                                 default = nil)
  if valid_773397 != nil:
    section.add "Description", valid_773397
  var valid_773398 = query.getOrDefault("DBParameterGroupFamily")
  valid_773398 = validateParameter(valid_773398, JString, required = true,
                                 default = nil)
  if valid_773398 != nil:
    section.add "DBParameterGroupFamily", valid_773398
  var valid_773399 = query.getOrDefault("Tags")
  valid_773399 = validateParameter(valid_773399, JArray, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "Tags", valid_773399
  var valid_773400 = query.getOrDefault("Action")
  valid_773400 = validateParameter(valid_773400, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_773400 != nil:
    section.add "Action", valid_773400
  var valid_773401 = query.getOrDefault("Version")
  valid_773401 = validateParameter(valid_773401, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773401 != nil:
    section.add "Version", valid_773401
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773402 = header.getOrDefault("X-Amz-Date")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Date", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Security-Token")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Security-Token", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Content-Sha256", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Algorithm")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Algorithm", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-Signature")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Signature", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-SignedHeaders", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-Credential")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Credential", valid_773408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773409: Call_GetCreateDBClusterParameterGroup_773393;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_773409.validator(path, query, header, formData, body)
  let scheme = call_773409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773409.url(scheme.get, call_773409.host, call_773409.base,
                         call_773409.route, valid.getOrDefault("path"))
  result = hook(call_773409, url, valid)

proc call*(call_773410: Call_GetCreateDBClusterParameterGroup_773393;
          DBClusterParameterGroupName: string; Description: string;
          DBParameterGroupFamily: string; Tags: JsonNode = nil;
          Action: string = "CreateDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getCreateDBClusterParameterGroup
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   Description: string (required)
  ##              : The description for the DB cluster parameter group.
  ##   DBParameterGroupFamily: string (required)
  ##                         : The DB cluster parameter group family name.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster parameter group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773411 = newJObject()
  add(query_773411, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_773411, "Description", newJString(Description))
  add(query_773411, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_773411.add "Tags", Tags
  add(query_773411, "Action", newJString(Action))
  add(query_773411, "Version", newJString(Version))
  result = call_773410.call(nil, query_773411, nil, nil, nil)

var getCreateDBClusterParameterGroup* = Call_GetCreateDBClusterParameterGroup_773393(
    name: "getCreateDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_GetCreateDBClusterParameterGroup_773394, base: "/",
    url: url_GetCreateDBClusterParameterGroup_773395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterSnapshot_773450 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBClusterSnapshot_773452(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBClusterSnapshot_773451(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a snapshot of a DB cluster. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773453 = query.getOrDefault("Action")
  valid_773453 = validateParameter(valid_773453, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_773453 != nil:
    section.add "Action", valid_773453
  var valid_773454 = query.getOrDefault("Version")
  valid_773454 = validateParameter(valid_773454, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773454 != nil:
    section.add "Version", valid_773454
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773455 = header.getOrDefault("X-Amz-Date")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Date", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-Security-Token")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Security-Token", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Content-Sha256", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-Algorithm")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-Algorithm", valid_773458
  var valid_773459 = header.getOrDefault("X-Amz-Signature")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "X-Amz-Signature", valid_773459
  var valid_773460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-SignedHeaders", valid_773460
  var valid_773461 = header.getOrDefault("X-Amz-Credential")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-Credential", valid_773461
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The identifier of the DB cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_773462 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_773462 = validateParameter(valid_773462, JString, required = true,
                                 default = nil)
  if valid_773462 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_773462
  var valid_773463 = formData.getOrDefault("Tags")
  valid_773463 = validateParameter(valid_773463, JArray, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "Tags", valid_773463
  var valid_773464 = formData.getOrDefault("DBClusterIdentifier")
  valid_773464 = validateParameter(valid_773464, JString, required = true,
                                 default = nil)
  if valid_773464 != nil:
    section.add "DBClusterIdentifier", valid_773464
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773465: Call_PostCreateDBClusterSnapshot_773450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_773465.validator(path, query, header, formData, body)
  let scheme = call_773465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773465.url(scheme.get, call_773465.host, call_773465.base,
                         call_773465.route, valid.getOrDefault("path"))
  result = hook(call_773465, url, valid)

proc call*(call_773466: Call_PostCreateDBClusterSnapshot_773450;
          DBClusterSnapshotIdentifier: string; DBClusterIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBClusterSnapshot";
          Version: string = "2014-10-31"): Recallable =
  ## postCreateDBClusterSnapshot
  ## Creates a snapshot of a DB cluster. 
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The identifier of the DB cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   Version: string (required)
  var query_773467 = newJObject()
  var formData_773468 = newJObject()
  add(formData_773468, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    formData_773468.add "Tags", Tags
  add(query_773467, "Action", newJString(Action))
  add(formData_773468, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_773467, "Version", newJString(Version))
  result = call_773466.call(nil, query_773467, nil, formData_773468, nil)

var postCreateDBClusterSnapshot* = Call_PostCreateDBClusterSnapshot_773450(
    name: "postCreateDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_PostCreateDBClusterSnapshot_773451, base: "/",
    url: url_PostCreateDBClusterSnapshot_773452,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterSnapshot_773432 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBClusterSnapshot_773434(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBClusterSnapshot_773433(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a snapshot of a DB cluster. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The identifier of the DB cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_773435 = query.getOrDefault("DBClusterIdentifier")
  valid_773435 = validateParameter(valid_773435, JString, required = true,
                                 default = nil)
  if valid_773435 != nil:
    section.add "DBClusterIdentifier", valid_773435
  var valid_773436 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_773436 = validateParameter(valid_773436, JString, required = true,
                                 default = nil)
  if valid_773436 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_773436
  var valid_773437 = query.getOrDefault("Tags")
  valid_773437 = validateParameter(valid_773437, JArray, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "Tags", valid_773437
  var valid_773438 = query.getOrDefault("Action")
  valid_773438 = validateParameter(valid_773438, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_773438 != nil:
    section.add "Action", valid_773438
  var valid_773439 = query.getOrDefault("Version")
  valid_773439 = validateParameter(valid_773439, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773439 != nil:
    section.add "Version", valid_773439
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773440 = header.getOrDefault("X-Amz-Date")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Date", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-Security-Token")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Security-Token", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Content-Sha256", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-Algorithm")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-Algorithm", valid_773443
  var valid_773444 = header.getOrDefault("X-Amz-Signature")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "X-Amz-Signature", valid_773444
  var valid_773445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-SignedHeaders", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-Credential")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Credential", valid_773446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773447: Call_GetCreateDBClusterSnapshot_773432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_773447.validator(path, query, header, formData, body)
  let scheme = call_773447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773447.url(scheme.get, call_773447.host, call_773447.base,
                         call_773447.route, valid.getOrDefault("path"))
  result = hook(call_773447, url, valid)

proc call*(call_773448: Call_GetCreateDBClusterSnapshot_773432;
          DBClusterIdentifier: string; DBClusterSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBClusterSnapshot";
          Version: string = "2014-10-31"): Recallable =
  ## getCreateDBClusterSnapshot
  ## Creates a snapshot of a DB cluster. 
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The identifier of the DB cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773449 = newJObject()
  add(query_773449, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_773449, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    query_773449.add "Tags", Tags
  add(query_773449, "Action", newJString(Action))
  add(query_773449, "Version", newJString(Version))
  result = call_773448.call(nil, query_773449, nil, nil, nil)

var getCreateDBClusterSnapshot* = Call_GetCreateDBClusterSnapshot_773432(
    name: "getCreateDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_GetCreateDBClusterSnapshot_773433, base: "/",
    url: url_GetCreateDBClusterSnapshot_773434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_773493 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBInstance_773495(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstance_773494(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new DB instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773496 = query.getOrDefault("Action")
  valid_773496 = validateParameter(valid_773496, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_773496 != nil:
    section.add "Action", valid_773496
  var valid_773497 = query.getOrDefault("Version")
  valid_773497 = validateParameter(valid_773497, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773497 != nil:
    section.add "Version", valid_773497
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773498 = header.getOrDefault("X-Amz-Date")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "X-Amz-Date", valid_773498
  var valid_773499 = header.getOrDefault("X-Amz-Security-Token")
  valid_773499 = validateParameter(valid_773499, JString, required = false,
                                 default = nil)
  if valid_773499 != nil:
    section.add "X-Amz-Security-Token", valid_773499
  var valid_773500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Content-Sha256", valid_773500
  var valid_773501 = header.getOrDefault("X-Amz-Algorithm")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Algorithm", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Signature")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Signature", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-SignedHeaders", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Credential")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Credential", valid_773504
  result.add "header", section
  ## parameters in `formData` object:
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB instance.
  ##   AvailabilityZone: JString
  ##                   : <p> The Amazon EC2 Availability Zone that the DB instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: JString (required)
  ##                  : The compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. 
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the DB cluster that the instance will belong to.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_773505 = formData.getOrDefault("Engine")
  valid_773505 = validateParameter(valid_773505, JString, required = true,
                                 default = nil)
  if valid_773505 != nil:
    section.add "Engine", valid_773505
  var valid_773506 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773506 = validateParameter(valid_773506, JString, required = true,
                                 default = nil)
  if valid_773506 != nil:
    section.add "DBInstanceIdentifier", valid_773506
  var valid_773507 = formData.getOrDefault("Tags")
  valid_773507 = validateParameter(valid_773507, JArray, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "Tags", valid_773507
  var valid_773508 = formData.getOrDefault("AvailabilityZone")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "AvailabilityZone", valid_773508
  var valid_773509 = formData.getOrDefault("PromotionTier")
  valid_773509 = validateParameter(valid_773509, JInt, required = false, default = nil)
  if valid_773509 != nil:
    section.add "PromotionTier", valid_773509
  var valid_773510 = formData.getOrDefault("DBInstanceClass")
  valid_773510 = validateParameter(valid_773510, JString, required = true,
                                 default = nil)
  if valid_773510 != nil:
    section.add "DBInstanceClass", valid_773510
  var valid_773511 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_773511 = validateParameter(valid_773511, JBool, required = false, default = nil)
  if valid_773511 != nil:
    section.add "AutoMinorVersionUpgrade", valid_773511
  var valid_773512 = formData.getOrDefault("DBClusterIdentifier")
  valid_773512 = validateParameter(valid_773512, JString, required = true,
                                 default = nil)
  if valid_773512 != nil:
    section.add "DBClusterIdentifier", valid_773512
  var valid_773513 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_773513 = validateParameter(valid_773513, JString, required = false,
                                 default = nil)
  if valid_773513 != nil:
    section.add "PreferredMaintenanceWindow", valid_773513
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773514: Call_PostCreateDBInstance_773493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_773514.validator(path, query, header, formData, body)
  let scheme = call_773514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773514.url(scheme.get, call_773514.host, call_773514.base,
                         call_773514.route, valid.getOrDefault("path"))
  result = hook(call_773514, url, valid)

proc call*(call_773515: Call_PostCreateDBInstance_773493; Engine: string;
          DBInstanceIdentifier: string; DBInstanceClass: string;
          DBClusterIdentifier: string; Tags: JsonNode = nil;
          AvailabilityZone: string = ""; Action: string = "CreateDBInstance";
          PromotionTier: int = 0; AutoMinorVersionUpgrade: bool = false;
          Version: string = "2014-10-31"; PreferredMaintenanceWindow: string = ""): Recallable =
  ## postCreateDBInstance
  ## Creates a new DB instance.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB instance.
  ##   AvailabilityZone: string
  ##                   : <p> The Amazon EC2 Availability Zone that the DB instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Action: string (required)
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: string (required)
  ##                  : The compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. 
  ##   AutoMinorVersionUpgrade: bool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the DB cluster that the instance will belong to.
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  var query_773516 = newJObject()
  var formData_773517 = newJObject()
  add(formData_773517, "Engine", newJString(Engine))
  add(formData_773517, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_773517.add "Tags", Tags
  add(formData_773517, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_773516, "Action", newJString(Action))
  add(formData_773517, "PromotionTier", newJInt(PromotionTier))
  add(formData_773517, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_773517, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_773517, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_773516, "Version", newJString(Version))
  add(formData_773517, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_773515.call(nil, query_773516, nil, formData_773517, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_773493(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_773494, base: "/",
    url: url_PostCreateDBInstance_773495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_773469 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBInstance_773471(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstance_773470(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a new DB instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the DB cluster that the instance will belong to.
  ##   AvailabilityZone: JString
  ##                   : <p> The Amazon EC2 Availability Zone that the DB instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB instance.
  ##   DBInstanceClass: JString (required)
  ##                  : The compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. 
  ##   Action: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_773472 = query.getOrDefault("Engine")
  valid_773472 = validateParameter(valid_773472, JString, required = true,
                                 default = nil)
  if valid_773472 != nil:
    section.add "Engine", valid_773472
  var valid_773473 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "PreferredMaintenanceWindow", valid_773473
  var valid_773474 = query.getOrDefault("PromotionTier")
  valid_773474 = validateParameter(valid_773474, JInt, required = false, default = nil)
  if valid_773474 != nil:
    section.add "PromotionTier", valid_773474
  var valid_773475 = query.getOrDefault("DBClusterIdentifier")
  valid_773475 = validateParameter(valid_773475, JString, required = true,
                                 default = nil)
  if valid_773475 != nil:
    section.add "DBClusterIdentifier", valid_773475
  var valid_773476 = query.getOrDefault("AvailabilityZone")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "AvailabilityZone", valid_773476
  var valid_773477 = query.getOrDefault("Tags")
  valid_773477 = validateParameter(valid_773477, JArray, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "Tags", valid_773477
  var valid_773478 = query.getOrDefault("DBInstanceClass")
  valid_773478 = validateParameter(valid_773478, JString, required = true,
                                 default = nil)
  if valid_773478 != nil:
    section.add "DBInstanceClass", valid_773478
  var valid_773479 = query.getOrDefault("Action")
  valid_773479 = validateParameter(valid_773479, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_773479 != nil:
    section.add "Action", valid_773479
  var valid_773480 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_773480 = validateParameter(valid_773480, JBool, required = false, default = nil)
  if valid_773480 != nil:
    section.add "AutoMinorVersionUpgrade", valid_773480
  var valid_773481 = query.getOrDefault("Version")
  valid_773481 = validateParameter(valid_773481, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773481 != nil:
    section.add "Version", valid_773481
  var valid_773482 = query.getOrDefault("DBInstanceIdentifier")
  valid_773482 = validateParameter(valid_773482, JString, required = true,
                                 default = nil)
  if valid_773482 != nil:
    section.add "DBInstanceIdentifier", valid_773482
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773483 = header.getOrDefault("X-Amz-Date")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Date", valid_773483
  var valid_773484 = header.getOrDefault("X-Amz-Security-Token")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-Security-Token", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-Content-Sha256", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-Algorithm")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Algorithm", valid_773486
  var valid_773487 = header.getOrDefault("X-Amz-Signature")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Signature", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-SignedHeaders", valid_773488
  var valid_773489 = header.getOrDefault("X-Amz-Credential")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-Credential", valid_773489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773490: Call_GetCreateDBInstance_773469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_773490.validator(path, query, header, formData, body)
  let scheme = call_773490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773490.url(scheme.get, call_773490.host, call_773490.base,
                         call_773490.route, valid.getOrDefault("path"))
  result = hook(call_773490, url, valid)

proc call*(call_773491: Call_GetCreateDBInstance_773469; Engine: string;
          DBClusterIdentifier: string; DBInstanceClass: string;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          PromotionTier: int = 0; AvailabilityZone: string = ""; Tags: JsonNode = nil;
          Action: string = "CreateDBInstance";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2014-10-31"): Recallable =
  ## getCreateDBInstance
  ## Creates a new DB instance.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the DB cluster that the instance will belong to.
  ##   AvailabilityZone: string
  ##                   : <p> The Amazon EC2 Availability Zone that the DB instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB instance.
  ##   DBInstanceClass: string (required)
  ##                  : The compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. 
  ##   Action: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  var query_773492 = newJObject()
  add(query_773492, "Engine", newJString(Engine))
  add(query_773492, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_773492, "PromotionTier", newJInt(PromotionTier))
  add(query_773492, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_773492, "AvailabilityZone", newJString(AvailabilityZone))
  if Tags != nil:
    query_773492.add "Tags", Tags
  add(query_773492, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_773492, "Action", newJString(Action))
  add(query_773492, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_773492, "Version", newJString(Version))
  add(query_773492, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_773491.call(nil, query_773492, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_773469(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_773470, base: "/",
    url: url_GetCreateDBInstance_773471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_773537 = ref object of OpenApiRestCall_772581
proc url_PostCreateDBSubnetGroup_773539(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSubnetGroup_773538(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773540 = query.getOrDefault("Action")
  valid_773540 = validateParameter(valid_773540, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_773540 != nil:
    section.add "Action", valid_773540
  var valid_773541 = query.getOrDefault("Version")
  valid_773541 = validateParameter(valid_773541, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773541 != nil:
    section.add "Version", valid_773541
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773542 = header.getOrDefault("X-Amz-Date")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Date", valid_773542
  var valid_773543 = header.getOrDefault("X-Amz-Security-Token")
  valid_773543 = validateParameter(valid_773543, JString, required = false,
                                 default = nil)
  if valid_773543 != nil:
    section.add "X-Amz-Security-Token", valid_773543
  var valid_773544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773544 = validateParameter(valid_773544, JString, required = false,
                                 default = nil)
  if valid_773544 != nil:
    section.add "X-Amz-Content-Sha256", valid_773544
  var valid_773545 = header.getOrDefault("X-Amz-Algorithm")
  valid_773545 = validateParameter(valid_773545, JString, required = false,
                                 default = nil)
  if valid_773545 != nil:
    section.add "X-Amz-Algorithm", valid_773545
  var valid_773546 = header.getOrDefault("X-Amz-Signature")
  valid_773546 = validateParameter(valid_773546, JString, required = false,
                                 default = nil)
  if valid_773546 != nil:
    section.add "X-Amz-Signature", valid_773546
  var valid_773547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-SignedHeaders", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-Credential")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-Credential", valid_773548
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   DBSubnetGroupDescription: JString (required)
  ##                           : The description for the DB subnet group.
  section = newJObject()
  var valid_773549 = formData.getOrDefault("Tags")
  valid_773549 = validateParameter(valid_773549, JArray, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "Tags", valid_773549
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_773550 = formData.getOrDefault("DBSubnetGroupName")
  valid_773550 = validateParameter(valid_773550, JString, required = true,
                                 default = nil)
  if valid_773550 != nil:
    section.add "DBSubnetGroupName", valid_773550
  var valid_773551 = formData.getOrDefault("SubnetIds")
  valid_773551 = validateParameter(valid_773551, JArray, required = true, default = nil)
  if valid_773551 != nil:
    section.add "SubnetIds", valid_773551
  var valid_773552 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_773552 = validateParameter(valid_773552, JString, required = true,
                                 default = nil)
  if valid_773552 != nil:
    section.add "DBSubnetGroupDescription", valid_773552
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773553: Call_PostCreateDBSubnetGroup_773537; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_773553.validator(path, query, header, formData, body)
  let scheme = call_773553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773553.url(scheme.get, call_773553.host, call_773553.base,
                         call_773553.route, valid.getOrDefault("path"))
  result = hook(call_773553, url, valid)

proc call*(call_773554: Call_PostCreateDBSubnetGroup_773537;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2014-10-31"): Recallable =
  ## postCreateDBSubnetGroup
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB subnet group.
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##                           : The description for the DB subnet group.
  ##   Version: string (required)
  var query_773555 = newJObject()
  var formData_773556 = newJObject()
  if Tags != nil:
    formData_773556.add "Tags", Tags
  add(formData_773556, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_773556.add "SubnetIds", SubnetIds
  add(query_773555, "Action", newJString(Action))
  add(formData_773556, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_773555, "Version", newJString(Version))
  result = call_773554.call(nil, query_773555, nil, formData_773556, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_773537(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_773538, base: "/",
    url: url_PostCreateDBSubnetGroup_773539, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_773518 = ref object of OpenApiRestCall_772581
proc url_GetCreateDBSubnetGroup_773520(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSubnetGroup_773519(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB subnet group.
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   DBSubnetGroupDescription: JString (required)
  ##                           : The description for the DB subnet group.
  ##   Version: JString (required)
  section = newJObject()
  var valid_773521 = query.getOrDefault("Tags")
  valid_773521 = validateParameter(valid_773521, JArray, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "Tags", valid_773521
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773522 = query.getOrDefault("Action")
  valid_773522 = validateParameter(valid_773522, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_773522 != nil:
    section.add "Action", valid_773522
  var valid_773523 = query.getOrDefault("DBSubnetGroupName")
  valid_773523 = validateParameter(valid_773523, JString, required = true,
                                 default = nil)
  if valid_773523 != nil:
    section.add "DBSubnetGroupName", valid_773523
  var valid_773524 = query.getOrDefault("SubnetIds")
  valid_773524 = validateParameter(valid_773524, JArray, required = true, default = nil)
  if valid_773524 != nil:
    section.add "SubnetIds", valid_773524
  var valid_773525 = query.getOrDefault("DBSubnetGroupDescription")
  valid_773525 = validateParameter(valid_773525, JString, required = true,
                                 default = nil)
  if valid_773525 != nil:
    section.add "DBSubnetGroupDescription", valid_773525
  var valid_773526 = query.getOrDefault("Version")
  valid_773526 = validateParameter(valid_773526, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773526 != nil:
    section.add "Version", valid_773526
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773527 = header.getOrDefault("X-Amz-Date")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Date", valid_773527
  var valid_773528 = header.getOrDefault("X-Amz-Security-Token")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "X-Amz-Security-Token", valid_773528
  var valid_773529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773529 = validateParameter(valid_773529, JString, required = false,
                                 default = nil)
  if valid_773529 != nil:
    section.add "X-Amz-Content-Sha256", valid_773529
  var valid_773530 = header.getOrDefault("X-Amz-Algorithm")
  valid_773530 = validateParameter(valid_773530, JString, required = false,
                                 default = nil)
  if valid_773530 != nil:
    section.add "X-Amz-Algorithm", valid_773530
  var valid_773531 = header.getOrDefault("X-Amz-Signature")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "X-Amz-Signature", valid_773531
  var valid_773532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-SignedHeaders", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-Credential")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Credential", valid_773533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773534: Call_GetCreateDBSubnetGroup_773518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_773534.validator(path, query, header, formData, body)
  let scheme = call_773534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773534.url(scheme.get, call_773534.host, call_773534.base,
                         call_773534.route, valid.getOrDefault("path"))
  result = hook(call_773534, url, valid)

proc call*(call_773535: Call_GetCreateDBSubnetGroup_773518;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2014-10-31"): Recallable =
  ## getCreateDBSubnetGroup
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   DBSubnetGroupDescription: string (required)
  ##                           : The description for the DB subnet group.
  ##   Version: string (required)
  var query_773536 = newJObject()
  if Tags != nil:
    query_773536.add "Tags", Tags
  add(query_773536, "Action", newJString(Action))
  add(query_773536, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_773536.add "SubnetIds", SubnetIds
  add(query_773536, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_773536, "Version", newJString(Version))
  result = call_773535.call(nil, query_773536, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_773518(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_773519, base: "/",
    url: url_GetCreateDBSubnetGroup_773520, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBCluster_773575 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBCluster_773577(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBCluster_773576(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773578 = query.getOrDefault("Action")
  valid_773578 = validateParameter(valid_773578, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_773578 != nil:
    section.add "Action", valid_773578
  var valid_773579 = query.getOrDefault("Version")
  valid_773579 = validateParameter(valid_773579, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773579 != nil:
    section.add "Version", valid_773579
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773580 = header.getOrDefault("X-Amz-Date")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Date", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Security-Token")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Security-Token", valid_773581
  var valid_773582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "X-Amz-Content-Sha256", valid_773582
  var valid_773583 = header.getOrDefault("X-Amz-Algorithm")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-Algorithm", valid_773583
  var valid_773584 = header.getOrDefault("X-Amz-Signature")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Signature", valid_773584
  var valid_773585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-SignedHeaders", valid_773585
  var valid_773586 = header.getOrDefault("X-Amz-Credential")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-Credential", valid_773586
  result.add "header", section
  ## parameters in `formData` object:
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_773587 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_773587
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_773588 = formData.getOrDefault("DBClusterIdentifier")
  valid_773588 = validateParameter(valid_773588, JString, required = true,
                                 default = nil)
  if valid_773588 != nil:
    section.add "DBClusterIdentifier", valid_773588
  var valid_773589 = formData.getOrDefault("SkipFinalSnapshot")
  valid_773589 = validateParameter(valid_773589, JBool, required = false, default = nil)
  if valid_773589 != nil:
    section.add "SkipFinalSnapshot", valid_773589
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773590: Call_PostDeleteDBCluster_773575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_773590.validator(path, query, header, formData, body)
  let scheme = call_773590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773590.url(scheme.get, call_773590.host, call_773590.base,
                         call_773590.route, valid.getOrDefault("path"))
  result = hook(call_773590, url, valid)

proc call*(call_773591: Call_PostDeleteDBCluster_773575;
          DBClusterIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBCluster"; Version: string = "2014-10-31";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBCluster
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ##   FinalDBSnapshotIdentifier: string
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  var query_773592 = newJObject()
  var formData_773593 = newJObject()
  add(formData_773593, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_773592, "Action", newJString(Action))
  add(formData_773593, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_773592, "Version", newJString(Version))
  add(formData_773593, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_773591.call(nil, query_773592, nil, formData_773593, nil)

var postDeleteDBCluster* = Call_PostDeleteDBCluster_773575(
    name: "postDeleteDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBCluster",
    validator: validate_PostDeleteDBCluster_773576, base: "/",
    url: url_PostDeleteDBCluster_773577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBCluster_773557 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBCluster_773559(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBCluster_773558(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Action: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_773560 = query.getOrDefault("DBClusterIdentifier")
  valid_773560 = validateParameter(valid_773560, JString, required = true,
                                 default = nil)
  if valid_773560 != nil:
    section.add "DBClusterIdentifier", valid_773560
  var valid_773561 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_773561
  var valid_773562 = query.getOrDefault("Action")
  valid_773562 = validateParameter(valid_773562, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_773562 != nil:
    section.add "Action", valid_773562
  var valid_773563 = query.getOrDefault("SkipFinalSnapshot")
  valid_773563 = validateParameter(valid_773563, JBool, required = false, default = nil)
  if valid_773563 != nil:
    section.add "SkipFinalSnapshot", valid_773563
  var valid_773564 = query.getOrDefault("Version")
  valid_773564 = validateParameter(valid_773564, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773564 != nil:
    section.add "Version", valid_773564
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773565 = header.getOrDefault("X-Amz-Date")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-Date", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Security-Token")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Security-Token", valid_773566
  var valid_773567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773567 = validateParameter(valid_773567, JString, required = false,
                                 default = nil)
  if valid_773567 != nil:
    section.add "X-Amz-Content-Sha256", valid_773567
  var valid_773568 = header.getOrDefault("X-Amz-Algorithm")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "X-Amz-Algorithm", valid_773568
  var valid_773569 = header.getOrDefault("X-Amz-Signature")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Signature", valid_773569
  var valid_773570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "X-Amz-SignedHeaders", valid_773570
  var valid_773571 = header.getOrDefault("X-Amz-Credential")
  valid_773571 = validateParameter(valid_773571, JString, required = false,
                                 default = nil)
  if valid_773571 != nil:
    section.add "X-Amz-Credential", valid_773571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773572: Call_GetDeleteDBCluster_773557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_773572.validator(path, query, header, formData, body)
  let scheme = call_773572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773572.url(scheme.get, call_773572.host, call_773572.base,
                         call_773572.route, valid.getOrDefault("path"))
  result = hook(call_773572, url, valid)

proc call*(call_773573: Call_GetDeleteDBCluster_773557;
          DBClusterIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBCluster"; SkipFinalSnapshot: bool = false;
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBCluster
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   FinalDBSnapshotIdentifier: string
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   Version: string (required)
  var query_773574 = newJObject()
  add(query_773574, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_773574, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_773574, "Action", newJString(Action))
  add(query_773574, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_773574, "Version", newJString(Version))
  result = call_773573.call(nil, query_773574, nil, nil, nil)

var getDeleteDBCluster* = Call_GetDeleteDBCluster_773557(
    name: "getDeleteDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DeleteDBCluster", validator: validate_GetDeleteDBCluster_773558,
    base: "/", url: url_GetDeleteDBCluster_773559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterParameterGroup_773610 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBClusterParameterGroup_773612(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBClusterParameterGroup_773611(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773613 = query.getOrDefault("Action")
  valid_773613 = validateParameter(valid_773613, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_773613 != nil:
    section.add "Action", valid_773613
  var valid_773614 = query.getOrDefault("Version")
  valid_773614 = validateParameter(valid_773614, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773614 != nil:
    section.add "Version", valid_773614
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773615 = header.getOrDefault("X-Amz-Date")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-Date", valid_773615
  var valid_773616 = header.getOrDefault("X-Amz-Security-Token")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-Security-Token", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Content-Sha256", valid_773617
  var valid_773618 = header.getOrDefault("X-Amz-Algorithm")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-Algorithm", valid_773618
  var valid_773619 = header.getOrDefault("X-Amz-Signature")
  valid_773619 = validateParameter(valid_773619, JString, required = false,
                                 default = nil)
  if valid_773619 != nil:
    section.add "X-Amz-Signature", valid_773619
  var valid_773620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "X-Amz-SignedHeaders", valid_773620
  var valid_773621 = header.getOrDefault("X-Amz-Credential")
  valid_773621 = validateParameter(valid_773621, JString, required = false,
                                 default = nil)
  if valid_773621 != nil:
    section.add "X-Amz-Credential", valid_773621
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_773622 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_773622 = validateParameter(valid_773622, JString, required = true,
                                 default = nil)
  if valid_773622 != nil:
    section.add "DBClusterParameterGroupName", valid_773622
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773623: Call_PostDeleteDBClusterParameterGroup_773610;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_773623.validator(path, query, header, formData, body)
  let scheme = call_773623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773623.url(scheme.get, call_773623.host, call_773623.base,
                         call_773623.route, valid.getOrDefault("path"))
  result = hook(call_773623, url, valid)

proc call*(call_773624: Call_PostDeleteDBClusterParameterGroup_773610;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Version: string (required)
  var query_773625 = newJObject()
  var formData_773626 = newJObject()
  add(query_773625, "Action", newJString(Action))
  add(formData_773626, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_773625, "Version", newJString(Version))
  result = call_773624.call(nil, query_773625, nil, formData_773626, nil)

var postDeleteDBClusterParameterGroup* = Call_PostDeleteDBClusterParameterGroup_773610(
    name: "postDeleteDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_PostDeleteDBClusterParameterGroup_773611, base: "/",
    url: url_PostDeleteDBClusterParameterGroup_773612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterParameterGroup_773594 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBClusterParameterGroup_773596(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBClusterParameterGroup_773595(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_773597 = query.getOrDefault("DBClusterParameterGroupName")
  valid_773597 = validateParameter(valid_773597, JString, required = true,
                                 default = nil)
  if valid_773597 != nil:
    section.add "DBClusterParameterGroupName", valid_773597
  var valid_773598 = query.getOrDefault("Action")
  valid_773598 = validateParameter(valid_773598, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_773598 != nil:
    section.add "Action", valid_773598
  var valid_773599 = query.getOrDefault("Version")
  valid_773599 = validateParameter(valid_773599, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773599 != nil:
    section.add "Version", valid_773599
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773600 = header.getOrDefault("X-Amz-Date")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Date", valid_773600
  var valid_773601 = header.getOrDefault("X-Amz-Security-Token")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-Security-Token", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Content-Sha256", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-Algorithm")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-Algorithm", valid_773603
  var valid_773604 = header.getOrDefault("X-Amz-Signature")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "X-Amz-Signature", valid_773604
  var valid_773605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773605 = validateParameter(valid_773605, JString, required = false,
                                 default = nil)
  if valid_773605 != nil:
    section.add "X-Amz-SignedHeaders", valid_773605
  var valid_773606 = header.getOrDefault("X-Amz-Credential")
  valid_773606 = validateParameter(valid_773606, JString, required = false,
                                 default = nil)
  if valid_773606 != nil:
    section.add "X-Amz-Credential", valid_773606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773607: Call_GetDeleteDBClusterParameterGroup_773594;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_773607.validator(path, query, header, formData, body)
  let scheme = call_773607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773607.url(scheme.get, call_773607.host, call_773607.base,
                         call_773607.route, valid.getOrDefault("path"))
  result = hook(call_773607, url, valid)

proc call*(call_773608: Call_GetDeleteDBClusterParameterGroup_773594;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773609 = newJObject()
  add(query_773609, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_773609, "Action", newJString(Action))
  add(query_773609, "Version", newJString(Version))
  result = call_773608.call(nil, query_773609, nil, nil, nil)

var getDeleteDBClusterParameterGroup* = Call_GetDeleteDBClusterParameterGroup_773594(
    name: "getDeleteDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_GetDeleteDBClusterParameterGroup_773595, base: "/",
    url: url_GetDeleteDBClusterParameterGroup_773596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterSnapshot_773643 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBClusterSnapshot_773645(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBClusterSnapshot_773644(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773646 = query.getOrDefault("Action")
  valid_773646 = validateParameter(valid_773646, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_773646 != nil:
    section.add "Action", valid_773646
  var valid_773647 = query.getOrDefault("Version")
  valid_773647 = validateParameter(valid_773647, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773647 != nil:
    section.add "Version", valid_773647
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773648 = header.getOrDefault("X-Amz-Date")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-Date", valid_773648
  var valid_773649 = header.getOrDefault("X-Amz-Security-Token")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-Security-Token", valid_773649
  var valid_773650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773650 = validateParameter(valid_773650, JString, required = false,
                                 default = nil)
  if valid_773650 != nil:
    section.add "X-Amz-Content-Sha256", valid_773650
  var valid_773651 = header.getOrDefault("X-Amz-Algorithm")
  valid_773651 = validateParameter(valid_773651, JString, required = false,
                                 default = nil)
  if valid_773651 != nil:
    section.add "X-Amz-Algorithm", valid_773651
  var valid_773652 = header.getOrDefault("X-Amz-Signature")
  valid_773652 = validateParameter(valid_773652, JString, required = false,
                                 default = nil)
  if valid_773652 != nil:
    section.add "X-Amz-Signature", valid_773652
  var valid_773653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773653 = validateParameter(valid_773653, JString, required = false,
                                 default = nil)
  if valid_773653 != nil:
    section.add "X-Amz-SignedHeaders", valid_773653
  var valid_773654 = header.getOrDefault("X-Amz-Credential")
  valid_773654 = validateParameter(valid_773654, JString, required = false,
                                 default = nil)
  if valid_773654 != nil:
    section.add "X-Amz-Credential", valid_773654
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_773655 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_773655 = validateParameter(valid_773655, JString, required = true,
                                 default = nil)
  if valid_773655 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_773655
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773656: Call_PostDeleteDBClusterSnapshot_773643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_773656.validator(path, query, header, formData, body)
  let scheme = call_773656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773656.url(scheme.get, call_773656.host, call_773656.base,
                         call_773656.route, valid.getOrDefault("path"))
  result = hook(call_773656, url, valid)

proc call*(call_773657: Call_PostDeleteDBClusterSnapshot_773643;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773658 = newJObject()
  var formData_773659 = newJObject()
  add(formData_773659, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_773658, "Action", newJString(Action))
  add(query_773658, "Version", newJString(Version))
  result = call_773657.call(nil, query_773658, nil, formData_773659, nil)

var postDeleteDBClusterSnapshot* = Call_PostDeleteDBClusterSnapshot_773643(
    name: "postDeleteDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_PostDeleteDBClusterSnapshot_773644, base: "/",
    url: url_PostDeleteDBClusterSnapshot_773645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterSnapshot_773627 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBClusterSnapshot_773629(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBClusterSnapshot_773628(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_773630 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_773630 = validateParameter(valid_773630, JString, required = true,
                                 default = nil)
  if valid_773630 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_773630
  var valid_773631 = query.getOrDefault("Action")
  valid_773631 = validateParameter(valid_773631, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_773631 != nil:
    section.add "Action", valid_773631
  var valid_773632 = query.getOrDefault("Version")
  valid_773632 = validateParameter(valid_773632, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773640: Call_GetDeleteDBClusterSnapshot_773627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_773640.validator(path, query, header, formData, body)
  let scheme = call_773640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773640.url(scheme.get, call_773640.host, call_773640.base,
                         call_773640.route, valid.getOrDefault("path"))
  result = hook(call_773640, url, valid)

proc call*(call_773641: Call_GetDeleteDBClusterSnapshot_773627;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773642 = newJObject()
  add(query_773642, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_773642, "Action", newJString(Action))
  add(query_773642, "Version", newJString(Version))
  result = call_773641.call(nil, query_773642, nil, nil, nil)

var getDeleteDBClusterSnapshot* = Call_GetDeleteDBClusterSnapshot_773627(
    name: "getDeleteDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_GetDeleteDBClusterSnapshot_773628, base: "/",
    url: url_GetDeleteDBClusterSnapshot_773629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_773676 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBInstance_773678(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBInstance_773677(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a previously provisioned DB instance. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773679 = query.getOrDefault("Action")
  valid_773679 = validateParameter(valid_773679, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_773679 != nil:
    section.add "Action", valid_773679
  var valid_773680 = query.getOrDefault("Version")
  valid_773680 = validateParameter(valid_773680, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773680 != nil:
    section.add "Version", valid_773680
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773681 = header.getOrDefault("X-Amz-Date")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-Date", valid_773681
  var valid_773682 = header.getOrDefault("X-Amz-Security-Token")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-Security-Token", valid_773682
  var valid_773683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773683 = validateParameter(valid_773683, JString, required = false,
                                 default = nil)
  if valid_773683 != nil:
    section.add "X-Amz-Content-Sha256", valid_773683
  var valid_773684 = header.getOrDefault("X-Amz-Algorithm")
  valid_773684 = validateParameter(valid_773684, JString, required = false,
                                 default = nil)
  if valid_773684 != nil:
    section.add "X-Amz-Algorithm", valid_773684
  var valid_773685 = header.getOrDefault("X-Amz-Signature")
  valid_773685 = validateParameter(valid_773685, JString, required = false,
                                 default = nil)
  if valid_773685 != nil:
    section.add "X-Amz-Signature", valid_773685
  var valid_773686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773686 = validateParameter(valid_773686, JString, required = false,
                                 default = nil)
  if valid_773686 != nil:
    section.add "X-Amz-SignedHeaders", valid_773686
  var valid_773687 = header.getOrDefault("X-Amz-Credential")
  valid_773687 = validateParameter(valid_773687, JString, required = false,
                                 default = nil)
  if valid_773687 != nil:
    section.add "X-Amz-Credential", valid_773687
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_773688 = formData.getOrDefault("DBInstanceIdentifier")
  valid_773688 = validateParameter(valid_773688, JString, required = true,
                                 default = nil)
  if valid_773688 != nil:
    section.add "DBInstanceIdentifier", valid_773688
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773689: Call_PostDeleteDBInstance_773676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_773689.validator(path, query, header, formData, body)
  let scheme = call_773689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773689.url(scheme.get, call_773689.host, call_773689.base,
                         call_773689.route, valid.getOrDefault("path"))
  result = hook(call_773689, url, valid)

proc call*(call_773690: Call_PostDeleteDBInstance_773676;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773691 = newJObject()
  var formData_773692 = newJObject()
  add(formData_773692, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_773691, "Action", newJString(Action))
  add(query_773691, "Version", newJString(Version))
  result = call_773690.call(nil, query_773691, nil, formData_773692, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_773676(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_773677, base: "/",
    url: url_PostDeleteDBInstance_773678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_773660 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBInstance_773662(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBInstance_773661(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a previously provisioned DB instance. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773663 = query.getOrDefault("Action")
  valid_773663 = validateParameter(valid_773663, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_773663 != nil:
    section.add "Action", valid_773663
  var valid_773664 = query.getOrDefault("Version")
  valid_773664 = validateParameter(valid_773664, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773664 != nil:
    section.add "Version", valid_773664
  var valid_773665 = query.getOrDefault("DBInstanceIdentifier")
  valid_773665 = validateParameter(valid_773665, JString, required = true,
                                 default = nil)
  if valid_773665 != nil:
    section.add "DBInstanceIdentifier", valid_773665
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773666 = header.getOrDefault("X-Amz-Date")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "X-Amz-Date", valid_773666
  var valid_773667 = header.getOrDefault("X-Amz-Security-Token")
  valid_773667 = validateParameter(valid_773667, JString, required = false,
                                 default = nil)
  if valid_773667 != nil:
    section.add "X-Amz-Security-Token", valid_773667
  var valid_773668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773668 = validateParameter(valid_773668, JString, required = false,
                                 default = nil)
  if valid_773668 != nil:
    section.add "X-Amz-Content-Sha256", valid_773668
  var valid_773669 = header.getOrDefault("X-Amz-Algorithm")
  valid_773669 = validateParameter(valid_773669, JString, required = false,
                                 default = nil)
  if valid_773669 != nil:
    section.add "X-Amz-Algorithm", valid_773669
  var valid_773670 = header.getOrDefault("X-Amz-Signature")
  valid_773670 = validateParameter(valid_773670, JString, required = false,
                                 default = nil)
  if valid_773670 != nil:
    section.add "X-Amz-Signature", valid_773670
  var valid_773671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773671 = validateParameter(valid_773671, JString, required = false,
                                 default = nil)
  if valid_773671 != nil:
    section.add "X-Amz-SignedHeaders", valid_773671
  var valid_773672 = header.getOrDefault("X-Amz-Credential")
  valid_773672 = validateParameter(valid_773672, JString, required = false,
                                 default = nil)
  if valid_773672 != nil:
    section.add "X-Amz-Credential", valid_773672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773673: Call_GetDeleteDBInstance_773660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_773673.validator(path, query, header, formData, body)
  let scheme = call_773673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773673.url(scheme.get, call_773673.host, call_773673.base,
                         call_773673.route, valid.getOrDefault("path"))
  result = hook(call_773673, url, valid)

proc call*(call_773674: Call_GetDeleteDBInstance_773660;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  var query_773675 = newJObject()
  add(query_773675, "Action", newJString(Action))
  add(query_773675, "Version", newJString(Version))
  add(query_773675, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_773674.call(nil, query_773675, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_773660(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_773661, base: "/",
    url: url_GetDeleteDBInstance_773662, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_773709 = ref object of OpenApiRestCall_772581
proc url_PostDeleteDBSubnetGroup_773711(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSubnetGroup_773710(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773712 = query.getOrDefault("Action")
  valid_773712 = validateParameter(valid_773712, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_773712 != nil:
    section.add "Action", valid_773712
  var valid_773713 = query.getOrDefault("Version")
  valid_773713 = validateParameter(valid_773713, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773713 != nil:
    section.add "Version", valid_773713
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773714 = header.getOrDefault("X-Amz-Date")
  valid_773714 = validateParameter(valid_773714, JString, required = false,
                                 default = nil)
  if valid_773714 != nil:
    section.add "X-Amz-Date", valid_773714
  var valid_773715 = header.getOrDefault("X-Amz-Security-Token")
  valid_773715 = validateParameter(valid_773715, JString, required = false,
                                 default = nil)
  if valid_773715 != nil:
    section.add "X-Amz-Security-Token", valid_773715
  var valid_773716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773716 = validateParameter(valid_773716, JString, required = false,
                                 default = nil)
  if valid_773716 != nil:
    section.add "X-Amz-Content-Sha256", valid_773716
  var valid_773717 = header.getOrDefault("X-Amz-Algorithm")
  valid_773717 = validateParameter(valid_773717, JString, required = false,
                                 default = nil)
  if valid_773717 != nil:
    section.add "X-Amz-Algorithm", valid_773717
  var valid_773718 = header.getOrDefault("X-Amz-Signature")
  valid_773718 = validateParameter(valid_773718, JString, required = false,
                                 default = nil)
  if valid_773718 != nil:
    section.add "X-Amz-Signature", valid_773718
  var valid_773719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "X-Amz-SignedHeaders", valid_773719
  var valid_773720 = header.getOrDefault("X-Amz-Credential")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "X-Amz-Credential", valid_773720
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_773721 = formData.getOrDefault("DBSubnetGroupName")
  valid_773721 = validateParameter(valid_773721, JString, required = true,
                                 default = nil)
  if valid_773721 != nil:
    section.add "DBSubnetGroupName", valid_773721
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773722: Call_PostDeleteDBSubnetGroup_773709; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_773722.validator(path, query, header, formData, body)
  let scheme = call_773722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773722.url(scheme.get, call_773722.host, call_773722.base,
                         call_773722.route, valid.getOrDefault("path"))
  result = hook(call_773722, url, valid)

proc call*(call_773723: Call_PostDeleteDBSubnetGroup_773709;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773724 = newJObject()
  var formData_773725 = newJObject()
  add(formData_773725, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773724, "Action", newJString(Action))
  add(query_773724, "Version", newJString(Version))
  result = call_773723.call(nil, query_773724, nil, formData_773725, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_773709(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_773710, base: "/",
    url: url_PostDeleteDBSubnetGroup_773711, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_773693 = ref object of OpenApiRestCall_772581
proc url_GetDeleteDBSubnetGroup_773695(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSubnetGroup_773694(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773696 = query.getOrDefault("Action")
  valid_773696 = validateParameter(valid_773696, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_773696 != nil:
    section.add "Action", valid_773696
  var valid_773697 = query.getOrDefault("DBSubnetGroupName")
  valid_773697 = validateParameter(valid_773697, JString, required = true,
                                 default = nil)
  if valid_773697 != nil:
    section.add "DBSubnetGroupName", valid_773697
  var valid_773698 = query.getOrDefault("Version")
  valid_773698 = validateParameter(valid_773698, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773698 != nil:
    section.add "Version", valid_773698
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773699 = header.getOrDefault("X-Amz-Date")
  valid_773699 = validateParameter(valid_773699, JString, required = false,
                                 default = nil)
  if valid_773699 != nil:
    section.add "X-Amz-Date", valid_773699
  var valid_773700 = header.getOrDefault("X-Amz-Security-Token")
  valid_773700 = validateParameter(valid_773700, JString, required = false,
                                 default = nil)
  if valid_773700 != nil:
    section.add "X-Amz-Security-Token", valid_773700
  var valid_773701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773701 = validateParameter(valid_773701, JString, required = false,
                                 default = nil)
  if valid_773701 != nil:
    section.add "X-Amz-Content-Sha256", valid_773701
  var valid_773702 = header.getOrDefault("X-Amz-Algorithm")
  valid_773702 = validateParameter(valid_773702, JString, required = false,
                                 default = nil)
  if valid_773702 != nil:
    section.add "X-Amz-Algorithm", valid_773702
  var valid_773703 = header.getOrDefault("X-Amz-Signature")
  valid_773703 = validateParameter(valid_773703, JString, required = false,
                                 default = nil)
  if valid_773703 != nil:
    section.add "X-Amz-Signature", valid_773703
  var valid_773704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "X-Amz-SignedHeaders", valid_773704
  var valid_773705 = header.getOrDefault("X-Amz-Credential")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "X-Amz-Credential", valid_773705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773706: Call_GetDeleteDBSubnetGroup_773693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_773706.validator(path, query, header, formData, body)
  let scheme = call_773706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773706.url(scheme.get, call_773706.host, call_773706.base,
                         call_773706.route, valid.getOrDefault("path"))
  result = hook(call_773706, url, valid)

proc call*(call_773707: Call_GetDeleteDBSubnetGroup_773693;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_773708 = newJObject()
  add(query_773708, "Action", newJString(Action))
  add(query_773708, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_773708, "Version", newJString(Version))
  result = call_773707.call(nil, query_773708, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_773693(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_773694, base: "/",
    url: url_GetDeleteDBSubnetGroup_773695, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameterGroups_773745 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBClusterParameterGroups_773747(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusterParameterGroups_773746(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
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
  valid_773748 = validateParameter(valid_773748, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_773748 != nil:
    section.add "Action", valid_773748
  var valid_773749 = query.getOrDefault("Version")
  valid_773749 = validateParameter(valid_773749, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterParameterGroupName: JString
  ##                              : <p>The name of a specific DB cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_773757 = formData.getOrDefault("Marker")
  valid_773757 = validateParameter(valid_773757, JString, required = false,
                                 default = nil)
  if valid_773757 != nil:
    section.add "Marker", valid_773757
  var valid_773758 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_773758 = validateParameter(valid_773758, JString, required = false,
                                 default = nil)
  if valid_773758 != nil:
    section.add "DBClusterParameterGroupName", valid_773758
  var valid_773759 = formData.getOrDefault("Filters")
  valid_773759 = validateParameter(valid_773759, JArray, required = false,
                                 default = nil)
  if valid_773759 != nil:
    section.add "Filters", valid_773759
  var valid_773760 = formData.getOrDefault("MaxRecords")
  valid_773760 = validateParameter(valid_773760, JInt, required = false, default = nil)
  if valid_773760 != nil:
    section.add "MaxRecords", valid_773760
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773761: Call_PostDescribeDBClusterParameterGroups_773745;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_773761.validator(path, query, header, formData, body)
  let scheme = call_773761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773761.url(scheme.get, call_773761.host, call_773761.base,
                         call_773761.route, valid.getOrDefault("path"))
  result = hook(call_773761, url, valid)

proc call*(call_773762: Call_PostDescribeDBClusterParameterGroups_773745;
          Marker: string = ""; Action: string = "DescribeDBClusterParameterGroups";
          DBClusterParameterGroupName: string = ""; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterParameterGroups
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string
  ##                              : <p>The name of a specific DB cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_773763 = newJObject()
  var formData_773764 = newJObject()
  add(formData_773764, "Marker", newJString(Marker))
  add(query_773763, "Action", newJString(Action))
  add(formData_773764, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_773764.add "Filters", Filters
  add(formData_773764, "MaxRecords", newJInt(MaxRecords))
  add(query_773763, "Version", newJString(Version))
  result = call_773762.call(nil, query_773763, nil, formData_773764, nil)

var postDescribeDBClusterParameterGroups* = Call_PostDescribeDBClusterParameterGroups_773745(
    name: "postDescribeDBClusterParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_PostDescribeDBClusterParameterGroups_773746, base: "/",
    url: url_PostDescribeDBClusterParameterGroups_773747,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameterGroups_773726 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBClusterParameterGroups_773728(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusterParameterGroups_773727(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterParameterGroupName: JString
  ##                              : <p>The name of a specific DB cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_773729 = query.getOrDefault("MaxRecords")
  valid_773729 = validateParameter(valid_773729, JInt, required = false, default = nil)
  if valid_773729 != nil:
    section.add "MaxRecords", valid_773729
  var valid_773730 = query.getOrDefault("DBClusterParameterGroupName")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "DBClusterParameterGroupName", valid_773730
  var valid_773731 = query.getOrDefault("Filters")
  valid_773731 = validateParameter(valid_773731, JArray, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "Filters", valid_773731
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773732 = query.getOrDefault("Action")
  valid_773732 = validateParameter(valid_773732, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_773732 != nil:
    section.add "Action", valid_773732
  var valid_773733 = query.getOrDefault("Marker")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = nil)
  if valid_773733 != nil:
    section.add "Marker", valid_773733
  var valid_773734 = query.getOrDefault("Version")
  valid_773734 = validateParameter(valid_773734, JString, required = true,
                                 default = newJString("2014-10-31"))
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

proc call*(call_773742: Call_GetDescribeDBClusterParameterGroups_773726;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_773742.validator(path, query, header, formData, body)
  let scheme = call_773742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773742.url(scheme.get, call_773742.host, call_773742.base,
                         call_773742.route, valid.getOrDefault("path"))
  result = hook(call_773742, url, valid)

proc call*(call_773743: Call_GetDescribeDBClusterParameterGroups_773726;
          MaxRecords: int = 0; DBClusterParameterGroupName: string = "";
          Filters: JsonNode = nil;
          Action: string = "DescribeDBClusterParameterGroups"; Marker: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterParameterGroups
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterParameterGroupName: string
  ##                              : <p>The name of a specific DB cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  var query_773744 = newJObject()
  add(query_773744, "MaxRecords", newJInt(MaxRecords))
  add(query_773744, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_773744.add "Filters", Filters
  add(query_773744, "Action", newJString(Action))
  add(query_773744, "Marker", newJString(Marker))
  add(query_773744, "Version", newJString(Version))
  result = call_773743.call(nil, query_773744, nil, nil, nil)

var getDescribeDBClusterParameterGroups* = Call_GetDescribeDBClusterParameterGroups_773726(
    name: "getDescribeDBClusterParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_GetDescribeDBClusterParameterGroups_773727, base: "/",
    url: url_GetDescribeDBClusterParameterGroups_773728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameters_773785 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBClusterParameters_773787(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusterParameters_773786(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773788 = query.getOrDefault("Action")
  valid_773788 = validateParameter(valid_773788, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_773788 != nil:
    section.add "Action", valid_773788
  var valid_773789 = query.getOrDefault("Version")
  valid_773789 = validateParameter(valid_773789, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773789 != nil:
    section.add "Version", valid_773789
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773790 = header.getOrDefault("X-Amz-Date")
  valid_773790 = validateParameter(valid_773790, JString, required = false,
                                 default = nil)
  if valid_773790 != nil:
    section.add "X-Amz-Date", valid_773790
  var valid_773791 = header.getOrDefault("X-Amz-Security-Token")
  valid_773791 = validateParameter(valid_773791, JString, required = false,
                                 default = nil)
  if valid_773791 != nil:
    section.add "X-Amz-Security-Token", valid_773791
  var valid_773792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773792 = validateParameter(valid_773792, JString, required = false,
                                 default = nil)
  if valid_773792 != nil:
    section.add "X-Amz-Content-Sha256", valid_773792
  var valid_773793 = header.getOrDefault("X-Amz-Algorithm")
  valid_773793 = validateParameter(valid_773793, JString, required = false,
                                 default = nil)
  if valid_773793 != nil:
    section.add "X-Amz-Algorithm", valid_773793
  var valid_773794 = header.getOrDefault("X-Amz-Signature")
  valid_773794 = validateParameter(valid_773794, JString, required = false,
                                 default = nil)
  if valid_773794 != nil:
    section.add "X-Amz-Signature", valid_773794
  var valid_773795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773795 = validateParameter(valid_773795, JString, required = false,
                                 default = nil)
  if valid_773795 != nil:
    section.add "X-Amz-SignedHeaders", valid_773795
  var valid_773796 = header.getOrDefault("X-Amz-Credential")
  valid_773796 = validateParameter(valid_773796, JString, required = false,
                                 default = nil)
  if valid_773796 != nil:
    section.add "X-Amz-Credential", valid_773796
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of a specific DB cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Source: JString
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  section = newJObject()
  var valid_773797 = formData.getOrDefault("Marker")
  valid_773797 = validateParameter(valid_773797, JString, required = false,
                                 default = nil)
  if valid_773797 != nil:
    section.add "Marker", valid_773797
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_773798 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_773798 = validateParameter(valid_773798, JString, required = true,
                                 default = nil)
  if valid_773798 != nil:
    section.add "DBClusterParameterGroupName", valid_773798
  var valid_773799 = formData.getOrDefault("Filters")
  valid_773799 = validateParameter(valid_773799, JArray, required = false,
                                 default = nil)
  if valid_773799 != nil:
    section.add "Filters", valid_773799
  var valid_773800 = formData.getOrDefault("MaxRecords")
  valid_773800 = validateParameter(valid_773800, JInt, required = false, default = nil)
  if valid_773800 != nil:
    section.add "MaxRecords", valid_773800
  var valid_773801 = formData.getOrDefault("Source")
  valid_773801 = validateParameter(valid_773801, JString, required = false,
                                 default = nil)
  if valid_773801 != nil:
    section.add "Source", valid_773801
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773802: Call_PostDescribeDBClusterParameters_773785;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_773802.validator(path, query, header, formData, body)
  let scheme = call_773802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773802.url(scheme.get, call_773802.host, call_773802.base,
                         call_773802.route, valid.getOrDefault("path"))
  result = hook(call_773802, url, valid)

proc call*(call_773803: Call_PostDescribeDBClusterParameters_773785;
          DBClusterParameterGroupName: string; Marker: string = "";
          Action: string = "DescribeDBClusterParameters"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-10-31"; Source: string = ""): Recallable =
  ## postDescribeDBClusterParameters
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of a specific DB cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  ##   Source: string
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  var query_773804 = newJObject()
  var formData_773805 = newJObject()
  add(formData_773805, "Marker", newJString(Marker))
  add(query_773804, "Action", newJString(Action))
  add(formData_773805, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_773805.add "Filters", Filters
  add(formData_773805, "MaxRecords", newJInt(MaxRecords))
  add(query_773804, "Version", newJString(Version))
  add(formData_773805, "Source", newJString(Source))
  result = call_773803.call(nil, query_773804, nil, formData_773805, nil)

var postDescribeDBClusterParameters* = Call_PostDescribeDBClusterParameters_773785(
    name: "postDescribeDBClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_PostDescribeDBClusterParameters_773786, base: "/",
    url: url_PostDescribeDBClusterParameters_773787,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameters_773765 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBClusterParameters_773767(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusterParameters_773766(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of a specific DB cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Source: JString
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  ##   Version: JString (required)
  section = newJObject()
  var valid_773768 = query.getOrDefault("MaxRecords")
  valid_773768 = validateParameter(valid_773768, JInt, required = false, default = nil)
  if valid_773768 != nil:
    section.add "MaxRecords", valid_773768
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_773769 = query.getOrDefault("DBClusterParameterGroupName")
  valid_773769 = validateParameter(valid_773769, JString, required = true,
                                 default = nil)
  if valid_773769 != nil:
    section.add "DBClusterParameterGroupName", valid_773769
  var valid_773770 = query.getOrDefault("Filters")
  valid_773770 = validateParameter(valid_773770, JArray, required = false,
                                 default = nil)
  if valid_773770 != nil:
    section.add "Filters", valid_773770
  var valid_773771 = query.getOrDefault("Action")
  valid_773771 = validateParameter(valid_773771, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_773771 != nil:
    section.add "Action", valid_773771
  var valid_773772 = query.getOrDefault("Marker")
  valid_773772 = validateParameter(valid_773772, JString, required = false,
                                 default = nil)
  if valid_773772 != nil:
    section.add "Marker", valid_773772
  var valid_773773 = query.getOrDefault("Source")
  valid_773773 = validateParameter(valid_773773, JString, required = false,
                                 default = nil)
  if valid_773773 != nil:
    section.add "Source", valid_773773
  var valid_773774 = query.getOrDefault("Version")
  valid_773774 = validateParameter(valid_773774, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773774 != nil:
    section.add "Version", valid_773774
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773775 = header.getOrDefault("X-Amz-Date")
  valid_773775 = validateParameter(valid_773775, JString, required = false,
                                 default = nil)
  if valid_773775 != nil:
    section.add "X-Amz-Date", valid_773775
  var valid_773776 = header.getOrDefault("X-Amz-Security-Token")
  valid_773776 = validateParameter(valid_773776, JString, required = false,
                                 default = nil)
  if valid_773776 != nil:
    section.add "X-Amz-Security-Token", valid_773776
  var valid_773777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773777 = validateParameter(valid_773777, JString, required = false,
                                 default = nil)
  if valid_773777 != nil:
    section.add "X-Amz-Content-Sha256", valid_773777
  var valid_773778 = header.getOrDefault("X-Amz-Algorithm")
  valid_773778 = validateParameter(valid_773778, JString, required = false,
                                 default = nil)
  if valid_773778 != nil:
    section.add "X-Amz-Algorithm", valid_773778
  var valid_773779 = header.getOrDefault("X-Amz-Signature")
  valid_773779 = validateParameter(valid_773779, JString, required = false,
                                 default = nil)
  if valid_773779 != nil:
    section.add "X-Amz-Signature", valid_773779
  var valid_773780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773780 = validateParameter(valid_773780, JString, required = false,
                                 default = nil)
  if valid_773780 != nil:
    section.add "X-Amz-SignedHeaders", valid_773780
  var valid_773781 = header.getOrDefault("X-Amz-Credential")
  valid_773781 = validateParameter(valid_773781, JString, required = false,
                                 default = nil)
  if valid_773781 != nil:
    section.add "X-Amz-Credential", valid_773781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773782: Call_GetDescribeDBClusterParameters_773765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_773782.validator(path, query, header, formData, body)
  let scheme = call_773782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773782.url(scheme.get, call_773782.host, call_773782.base,
                         call_773782.route, valid.getOrDefault("path"))
  result = hook(call_773782, url, valid)

proc call*(call_773783: Call_GetDescribeDBClusterParameters_773765;
          DBClusterParameterGroupName: string; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBClusterParameters";
          Marker: string = ""; Source: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterParameters
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of a specific DB cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Source: string
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  ##   Version: string (required)
  var query_773784 = newJObject()
  add(query_773784, "MaxRecords", newJInt(MaxRecords))
  add(query_773784, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_773784.add "Filters", Filters
  add(query_773784, "Action", newJString(Action))
  add(query_773784, "Marker", newJString(Marker))
  add(query_773784, "Source", newJString(Source))
  add(query_773784, "Version", newJString(Version))
  result = call_773783.call(nil, query_773784, nil, nil, nil)

var getDescribeDBClusterParameters* = Call_GetDescribeDBClusterParameters_773765(
    name: "getDescribeDBClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_GetDescribeDBClusterParameters_773766, base: "/",
    url: url_GetDescribeDBClusterParameters_773767,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshotAttributes_773822 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBClusterSnapshotAttributes_773824(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusterSnapshotAttributes_773823(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773825 = query.getOrDefault("Action")
  valid_773825 = validateParameter(valid_773825, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_773825 != nil:
    section.add "Action", valid_773825
  var valid_773826 = query.getOrDefault("Version")
  valid_773826 = validateParameter(valid_773826, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773826 != nil:
    section.add "Version", valid_773826
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773827 = header.getOrDefault("X-Amz-Date")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "X-Amz-Date", valid_773827
  var valid_773828 = header.getOrDefault("X-Amz-Security-Token")
  valid_773828 = validateParameter(valid_773828, JString, required = false,
                                 default = nil)
  if valid_773828 != nil:
    section.add "X-Amz-Security-Token", valid_773828
  var valid_773829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773829 = validateParameter(valid_773829, JString, required = false,
                                 default = nil)
  if valid_773829 != nil:
    section.add "X-Amz-Content-Sha256", valid_773829
  var valid_773830 = header.getOrDefault("X-Amz-Algorithm")
  valid_773830 = validateParameter(valid_773830, JString, required = false,
                                 default = nil)
  if valid_773830 != nil:
    section.add "X-Amz-Algorithm", valid_773830
  var valid_773831 = header.getOrDefault("X-Amz-Signature")
  valid_773831 = validateParameter(valid_773831, JString, required = false,
                                 default = nil)
  if valid_773831 != nil:
    section.add "X-Amz-Signature", valid_773831
  var valid_773832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773832 = validateParameter(valid_773832, JString, required = false,
                                 default = nil)
  if valid_773832 != nil:
    section.add "X-Amz-SignedHeaders", valid_773832
  var valid_773833 = header.getOrDefault("X-Amz-Credential")
  valid_773833 = validateParameter(valid_773833, JString, required = false,
                                 default = nil)
  if valid_773833 != nil:
    section.add "X-Amz-Credential", valid_773833
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_773834 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_773834 = validateParameter(valid_773834, JString, required = true,
                                 default = nil)
  if valid_773834 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_773834
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773835: Call_PostDescribeDBClusterSnapshotAttributes_773822;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_773835.validator(path, query, header, formData, body)
  let scheme = call_773835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773835.url(scheme.get, call_773835.host, call_773835.base,
                         call_773835.route, valid.getOrDefault("path"))
  result = hook(call_773835, url, valid)

proc call*(call_773836: Call_PostDescribeDBClusterSnapshotAttributes_773822;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773837 = newJObject()
  var formData_773838 = newJObject()
  add(formData_773838, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_773837, "Action", newJString(Action))
  add(query_773837, "Version", newJString(Version))
  result = call_773836.call(nil, query_773837, nil, formData_773838, nil)

var postDescribeDBClusterSnapshotAttributes* = Call_PostDescribeDBClusterSnapshotAttributes_773822(
    name: "postDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_PostDescribeDBClusterSnapshotAttributes_773823, base: "/",
    url: url_PostDescribeDBClusterSnapshotAttributes_773824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshotAttributes_773806 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBClusterSnapshotAttributes_773808(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusterSnapshotAttributes_773807(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_773809 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_773809 = validateParameter(valid_773809, JString, required = true,
                                 default = nil)
  if valid_773809 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_773809
  var valid_773810 = query.getOrDefault("Action")
  valid_773810 = validateParameter(valid_773810, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_773810 != nil:
    section.add "Action", valid_773810
  var valid_773811 = query.getOrDefault("Version")
  valid_773811 = validateParameter(valid_773811, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773811 != nil:
    section.add "Version", valid_773811
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773812 = header.getOrDefault("X-Amz-Date")
  valid_773812 = validateParameter(valid_773812, JString, required = false,
                                 default = nil)
  if valid_773812 != nil:
    section.add "X-Amz-Date", valid_773812
  var valid_773813 = header.getOrDefault("X-Amz-Security-Token")
  valid_773813 = validateParameter(valid_773813, JString, required = false,
                                 default = nil)
  if valid_773813 != nil:
    section.add "X-Amz-Security-Token", valid_773813
  var valid_773814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773814 = validateParameter(valid_773814, JString, required = false,
                                 default = nil)
  if valid_773814 != nil:
    section.add "X-Amz-Content-Sha256", valid_773814
  var valid_773815 = header.getOrDefault("X-Amz-Algorithm")
  valid_773815 = validateParameter(valid_773815, JString, required = false,
                                 default = nil)
  if valid_773815 != nil:
    section.add "X-Amz-Algorithm", valid_773815
  var valid_773816 = header.getOrDefault("X-Amz-Signature")
  valid_773816 = validateParameter(valid_773816, JString, required = false,
                                 default = nil)
  if valid_773816 != nil:
    section.add "X-Amz-Signature", valid_773816
  var valid_773817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-SignedHeaders", valid_773817
  var valid_773818 = header.getOrDefault("X-Amz-Credential")
  valid_773818 = validateParameter(valid_773818, JString, required = false,
                                 default = nil)
  if valid_773818 != nil:
    section.add "X-Amz-Credential", valid_773818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773819: Call_GetDescribeDBClusterSnapshotAttributes_773806;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_773819.validator(path, query, header, formData, body)
  let scheme = call_773819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773819.url(scheme.get, call_773819.host, call_773819.base,
                         call_773819.route, valid.getOrDefault("path"))
  result = hook(call_773819, url, valid)

proc call*(call_773820: Call_GetDescribeDBClusterSnapshotAttributes_773806;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773821 = newJObject()
  add(query_773821, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_773821, "Action", newJString(Action))
  add(query_773821, "Version", newJString(Version))
  result = call_773820.call(nil, query_773821, nil, nil, nil)

var getDescribeDBClusterSnapshotAttributes* = Call_GetDescribeDBClusterSnapshotAttributes_773806(
    name: "getDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_GetDescribeDBClusterSnapshotAttributes_773807, base: "/",
    url: url_GetDescribeDBClusterSnapshotAttributes_773808,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshots_773862 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBClusterSnapshots_773864(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusterSnapshots_773863(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773865 = query.getOrDefault("Action")
  valid_773865 = validateParameter(valid_773865, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_773865 != nil:
    section.add "Action", valid_773865
  var valid_773866 = query.getOrDefault("Version")
  valid_773866 = validateParameter(valid_773866, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString
  ##                              : <p>A specific DB cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   IncludeShared: JBool
  ##                : Set to <code>true</code> to include shared manual DB cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   IncludePublic: JBool
  ##                : Set to <code>true</code> to include manual DB cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   SnapshotType: JString
  ##               : <p>The type of DB cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all DB cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all DB cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual DB cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all DB cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual DB cluster snapshots are returned. You can include shared DB cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public DB cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The ID of the DB cluster to retrieve the list of DB cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_773874 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_773874 = validateParameter(valid_773874, JString, required = false,
                                 default = nil)
  if valid_773874 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_773874
  var valid_773875 = formData.getOrDefault("IncludeShared")
  valid_773875 = validateParameter(valid_773875, JBool, required = false, default = nil)
  if valid_773875 != nil:
    section.add "IncludeShared", valid_773875
  var valid_773876 = formData.getOrDefault("IncludePublic")
  valid_773876 = validateParameter(valid_773876, JBool, required = false, default = nil)
  if valid_773876 != nil:
    section.add "IncludePublic", valid_773876
  var valid_773877 = formData.getOrDefault("SnapshotType")
  valid_773877 = validateParameter(valid_773877, JString, required = false,
                                 default = nil)
  if valid_773877 != nil:
    section.add "SnapshotType", valid_773877
  var valid_773878 = formData.getOrDefault("Marker")
  valid_773878 = validateParameter(valid_773878, JString, required = false,
                                 default = nil)
  if valid_773878 != nil:
    section.add "Marker", valid_773878
  var valid_773879 = formData.getOrDefault("Filters")
  valid_773879 = validateParameter(valid_773879, JArray, required = false,
                                 default = nil)
  if valid_773879 != nil:
    section.add "Filters", valid_773879
  var valid_773880 = formData.getOrDefault("MaxRecords")
  valid_773880 = validateParameter(valid_773880, JInt, required = false, default = nil)
  if valid_773880 != nil:
    section.add "MaxRecords", valid_773880
  var valid_773881 = formData.getOrDefault("DBClusterIdentifier")
  valid_773881 = validateParameter(valid_773881, JString, required = false,
                                 default = nil)
  if valid_773881 != nil:
    section.add "DBClusterIdentifier", valid_773881
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773882: Call_PostDescribeDBClusterSnapshots_773862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_773882.validator(path, query, header, formData, body)
  let scheme = call_773882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773882.url(scheme.get, call_773882.host, call_773882.base,
                         call_773882.route, valid.getOrDefault("path"))
  result = hook(call_773882, url, valid)

proc call*(call_773883: Call_PostDescribeDBClusterSnapshots_773862;
          DBClusterSnapshotIdentifier: string = ""; IncludeShared: bool = false;
          IncludePublic: bool = false; SnapshotType: string = ""; Marker: string = "";
          Action: string = "DescribeDBClusterSnapshots"; Filters: JsonNode = nil;
          MaxRecords: int = 0; DBClusterIdentifier: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshots
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ##   DBClusterSnapshotIdentifier: string
  ##                              : <p>A specific DB cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   IncludeShared: bool
  ##                : Set to <code>true</code> to include shared manual DB cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   IncludePublic: bool
  ##                : Set to <code>true</code> to include manual DB cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   SnapshotType: string
  ##               : <p>The type of DB cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all DB cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all DB cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual DB cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all DB cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual DB cluster snapshots are returned. You can include shared DB cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public DB cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>The ID of the DB cluster to retrieve the list of DB cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_773884 = newJObject()
  var formData_773885 = newJObject()
  add(formData_773885, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(formData_773885, "IncludeShared", newJBool(IncludeShared))
  add(formData_773885, "IncludePublic", newJBool(IncludePublic))
  add(formData_773885, "SnapshotType", newJString(SnapshotType))
  add(formData_773885, "Marker", newJString(Marker))
  add(query_773884, "Action", newJString(Action))
  if Filters != nil:
    formData_773885.add "Filters", Filters
  add(formData_773885, "MaxRecords", newJInt(MaxRecords))
  add(formData_773885, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_773884, "Version", newJString(Version))
  result = call_773883.call(nil, query_773884, nil, formData_773885, nil)

var postDescribeDBClusterSnapshots* = Call_PostDescribeDBClusterSnapshots_773862(
    name: "postDescribeDBClusterSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_PostDescribeDBClusterSnapshots_773863, base: "/",
    url: url_PostDescribeDBClusterSnapshots_773864,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshots_773839 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBClusterSnapshots_773841(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusterSnapshots_773840(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IncludePublic: JBool
  ##                : Set to <code>true</code> to include manual DB cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The ID of the DB cluster to retrieve the list of DB cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   DBClusterSnapshotIdentifier: JString
  ##                              : <p>A specific DB cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   IncludeShared: JBool
  ##                : Set to <code>true</code> to include shared manual DB cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   SnapshotType: JString
  ##               : <p>The type of DB cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all DB cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all DB cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual DB cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all DB cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual DB cluster snapshots are returned. You can include shared DB cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public DB cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_773842 = query.getOrDefault("IncludePublic")
  valid_773842 = validateParameter(valid_773842, JBool, required = false, default = nil)
  if valid_773842 != nil:
    section.add "IncludePublic", valid_773842
  var valid_773843 = query.getOrDefault("MaxRecords")
  valid_773843 = validateParameter(valid_773843, JInt, required = false, default = nil)
  if valid_773843 != nil:
    section.add "MaxRecords", valid_773843
  var valid_773844 = query.getOrDefault("DBClusterIdentifier")
  valid_773844 = validateParameter(valid_773844, JString, required = false,
                                 default = nil)
  if valid_773844 != nil:
    section.add "DBClusterIdentifier", valid_773844
  var valid_773845 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_773845 = validateParameter(valid_773845, JString, required = false,
                                 default = nil)
  if valid_773845 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_773845
  var valid_773846 = query.getOrDefault("Filters")
  valid_773846 = validateParameter(valid_773846, JArray, required = false,
                                 default = nil)
  if valid_773846 != nil:
    section.add "Filters", valid_773846
  var valid_773847 = query.getOrDefault("IncludeShared")
  valid_773847 = validateParameter(valid_773847, JBool, required = false, default = nil)
  if valid_773847 != nil:
    section.add "IncludeShared", valid_773847
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773848 = query.getOrDefault("Action")
  valid_773848 = validateParameter(valid_773848, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_773848 != nil:
    section.add "Action", valid_773848
  var valid_773849 = query.getOrDefault("Marker")
  valid_773849 = validateParameter(valid_773849, JString, required = false,
                                 default = nil)
  if valid_773849 != nil:
    section.add "Marker", valid_773849
  var valid_773850 = query.getOrDefault("SnapshotType")
  valid_773850 = validateParameter(valid_773850, JString, required = false,
                                 default = nil)
  if valid_773850 != nil:
    section.add "SnapshotType", valid_773850
  var valid_773851 = query.getOrDefault("Version")
  valid_773851 = validateParameter(valid_773851, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773851 != nil:
    section.add "Version", valid_773851
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773852 = header.getOrDefault("X-Amz-Date")
  valid_773852 = validateParameter(valid_773852, JString, required = false,
                                 default = nil)
  if valid_773852 != nil:
    section.add "X-Amz-Date", valid_773852
  var valid_773853 = header.getOrDefault("X-Amz-Security-Token")
  valid_773853 = validateParameter(valid_773853, JString, required = false,
                                 default = nil)
  if valid_773853 != nil:
    section.add "X-Amz-Security-Token", valid_773853
  var valid_773854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773854 = validateParameter(valid_773854, JString, required = false,
                                 default = nil)
  if valid_773854 != nil:
    section.add "X-Amz-Content-Sha256", valid_773854
  var valid_773855 = header.getOrDefault("X-Amz-Algorithm")
  valid_773855 = validateParameter(valid_773855, JString, required = false,
                                 default = nil)
  if valid_773855 != nil:
    section.add "X-Amz-Algorithm", valid_773855
  var valid_773856 = header.getOrDefault("X-Amz-Signature")
  valid_773856 = validateParameter(valid_773856, JString, required = false,
                                 default = nil)
  if valid_773856 != nil:
    section.add "X-Amz-Signature", valid_773856
  var valid_773857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-SignedHeaders", valid_773857
  var valid_773858 = header.getOrDefault("X-Amz-Credential")
  valid_773858 = validateParameter(valid_773858, JString, required = false,
                                 default = nil)
  if valid_773858 != nil:
    section.add "X-Amz-Credential", valid_773858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773859: Call_GetDescribeDBClusterSnapshots_773839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_773859.validator(path, query, header, formData, body)
  let scheme = call_773859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773859.url(scheme.get, call_773859.host, call_773859.base,
                         call_773859.route, valid.getOrDefault("path"))
  result = hook(call_773859, url, valid)

proc call*(call_773860: Call_GetDescribeDBClusterSnapshots_773839;
          IncludePublic: bool = false; MaxRecords: int = 0;
          DBClusterIdentifier: string = "";
          DBClusterSnapshotIdentifier: string = ""; Filters: JsonNode = nil;
          IncludeShared: bool = false;
          Action: string = "DescribeDBClusterSnapshots"; Marker: string = "";
          SnapshotType: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshots
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ##   IncludePublic: bool
  ##                : Set to <code>true</code> to include manual DB cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>The ID of the DB cluster to retrieve the list of DB cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   DBClusterSnapshotIdentifier: string
  ##                              : <p>A specific DB cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   IncludeShared: bool
  ##                : Set to <code>true</code> to include shared manual DB cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   SnapshotType: string
  ##               : <p>The type of DB cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all DB cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all DB cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual DB cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all DB cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual DB cluster snapshots are returned. You can include shared DB cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public DB cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   Version: string (required)
  var query_773861 = newJObject()
  add(query_773861, "IncludePublic", newJBool(IncludePublic))
  add(query_773861, "MaxRecords", newJInt(MaxRecords))
  add(query_773861, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_773861, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Filters != nil:
    query_773861.add "Filters", Filters
  add(query_773861, "IncludeShared", newJBool(IncludeShared))
  add(query_773861, "Action", newJString(Action))
  add(query_773861, "Marker", newJString(Marker))
  add(query_773861, "SnapshotType", newJString(SnapshotType))
  add(query_773861, "Version", newJString(Version))
  result = call_773860.call(nil, query_773861, nil, nil, nil)

var getDescribeDBClusterSnapshots* = Call_GetDescribeDBClusterSnapshots_773839(
    name: "getDescribeDBClusterSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_GetDescribeDBClusterSnapshots_773840, base: "/",
    url: url_GetDescribeDBClusterSnapshots_773841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusters_773905 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBClusters_773907(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusters_773906(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773908 = query.getOrDefault("Action")
  valid_773908 = validateParameter(valid_773908, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_773908 != nil:
    section.add "Action", valid_773908
  var valid_773909 = query.getOrDefault("Version")
  valid_773909 = validateParameter(valid_773909, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773909 != nil:
    section.add "Version", valid_773909
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773910 = header.getOrDefault("X-Amz-Date")
  valid_773910 = validateParameter(valid_773910, JString, required = false,
                                 default = nil)
  if valid_773910 != nil:
    section.add "X-Amz-Date", valid_773910
  var valid_773911 = header.getOrDefault("X-Amz-Security-Token")
  valid_773911 = validateParameter(valid_773911, JString, required = false,
                                 default = nil)
  if valid_773911 != nil:
    section.add "X-Amz-Security-Token", valid_773911
  var valid_773912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773912 = validateParameter(valid_773912, JString, required = false,
                                 default = nil)
  if valid_773912 != nil:
    section.add "X-Amz-Content-Sha256", valid_773912
  var valid_773913 = header.getOrDefault("X-Amz-Algorithm")
  valid_773913 = validateParameter(valid_773913, JString, required = false,
                                 default = nil)
  if valid_773913 != nil:
    section.add "X-Amz-Algorithm", valid_773913
  var valid_773914 = header.getOrDefault("X-Amz-Signature")
  valid_773914 = validateParameter(valid_773914, JString, required = false,
                                 default = nil)
  if valid_773914 != nil:
    section.add "X-Amz-Signature", valid_773914
  var valid_773915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773915 = validateParameter(valid_773915, JString, required = false,
                                 default = nil)
  if valid_773915 != nil:
    section.add "X-Amz-SignedHeaders", valid_773915
  var valid_773916 = header.getOrDefault("X-Amz-Credential")
  valid_773916 = validateParameter(valid_773916, JString, required = false,
                                 default = nil)
  if valid_773916 != nil:
    section.add "X-Amz-Credential", valid_773916
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list only includes information about the DB clusters identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The user-provided DB cluster identifier. If this parameter is specified, information from only the specific DB cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  section = newJObject()
  var valid_773917 = formData.getOrDefault("Marker")
  valid_773917 = validateParameter(valid_773917, JString, required = false,
                                 default = nil)
  if valid_773917 != nil:
    section.add "Marker", valid_773917
  var valid_773918 = formData.getOrDefault("Filters")
  valid_773918 = validateParameter(valid_773918, JArray, required = false,
                                 default = nil)
  if valid_773918 != nil:
    section.add "Filters", valid_773918
  var valid_773919 = formData.getOrDefault("MaxRecords")
  valid_773919 = validateParameter(valid_773919, JInt, required = false, default = nil)
  if valid_773919 != nil:
    section.add "MaxRecords", valid_773919
  var valid_773920 = formData.getOrDefault("DBClusterIdentifier")
  valid_773920 = validateParameter(valid_773920, JString, required = false,
                                 default = nil)
  if valid_773920 != nil:
    section.add "DBClusterIdentifier", valid_773920
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773921: Call_PostDescribeDBClusters_773905; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_773921.validator(path, query, header, formData, body)
  let scheme = call_773921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773921.url(scheme.get, call_773921.host, call_773921.base,
                         call_773921.route, valid.getOrDefault("path"))
  result = hook(call_773921, url, valid)

proc call*(call_773922: Call_PostDescribeDBClusters_773905; Marker: string = "";
          Action: string = "DescribeDBClusters"; Filters: JsonNode = nil;
          MaxRecords: int = 0; DBClusterIdentifier: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusters
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list only includes information about the DB clusters identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>The user-provided DB cluster identifier. If this parameter is specified, information from only the specific DB cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_773923 = newJObject()
  var formData_773924 = newJObject()
  add(formData_773924, "Marker", newJString(Marker))
  add(query_773923, "Action", newJString(Action))
  if Filters != nil:
    formData_773924.add "Filters", Filters
  add(formData_773924, "MaxRecords", newJInt(MaxRecords))
  add(formData_773924, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_773923, "Version", newJString(Version))
  result = call_773922.call(nil, query_773923, nil, formData_773924, nil)

var postDescribeDBClusters* = Call_PostDescribeDBClusters_773905(
    name: "postDescribeDBClusters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_PostDescribeDBClusters_773906, base: "/",
    url: url_PostDescribeDBClusters_773907, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusters_773886 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBClusters_773888(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusters_773887(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The user-provided DB cluster identifier. If this parameter is specified, information from only the specific DB cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list only includes information about the DB clusters identified by these ARNs.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_773889 = query.getOrDefault("MaxRecords")
  valid_773889 = validateParameter(valid_773889, JInt, required = false, default = nil)
  if valid_773889 != nil:
    section.add "MaxRecords", valid_773889
  var valid_773890 = query.getOrDefault("DBClusterIdentifier")
  valid_773890 = validateParameter(valid_773890, JString, required = false,
                                 default = nil)
  if valid_773890 != nil:
    section.add "DBClusterIdentifier", valid_773890
  var valid_773891 = query.getOrDefault("Filters")
  valid_773891 = validateParameter(valid_773891, JArray, required = false,
                                 default = nil)
  if valid_773891 != nil:
    section.add "Filters", valid_773891
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773892 = query.getOrDefault("Action")
  valid_773892 = validateParameter(valid_773892, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_773892 != nil:
    section.add "Action", valid_773892
  var valid_773893 = query.getOrDefault("Marker")
  valid_773893 = validateParameter(valid_773893, JString, required = false,
                                 default = nil)
  if valid_773893 != nil:
    section.add "Marker", valid_773893
  var valid_773894 = query.getOrDefault("Version")
  valid_773894 = validateParameter(valid_773894, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773902: Call_GetDescribeDBClusters_773886; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_773902.validator(path, query, header, formData, body)
  let scheme = call_773902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773902.url(scheme.get, call_773902.host, call_773902.base,
                         call_773902.route, valid.getOrDefault("path"))
  result = hook(call_773902, url, valid)

proc call*(call_773903: Call_GetDescribeDBClusters_773886; MaxRecords: int = 0;
          DBClusterIdentifier: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeDBClusters"; Marker: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusters
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>The user-provided DB cluster identifier. If this parameter is specified, information from only the specific DB cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list only includes information about the DB clusters identified by these ARNs.</p> </li> </ul>
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  var query_773904 = newJObject()
  add(query_773904, "MaxRecords", newJInt(MaxRecords))
  add(query_773904, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if Filters != nil:
    query_773904.add "Filters", Filters
  add(query_773904, "Action", newJString(Action))
  add(query_773904, "Marker", newJString(Marker))
  add(query_773904, "Version", newJString(Version))
  result = call_773903.call(nil, query_773904, nil, nil, nil)

var getDescribeDBClusters* = Call_GetDescribeDBClusters_773886(
    name: "getDescribeDBClusters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_GetDescribeDBClusters_773887, base: "/",
    url: url_GetDescribeDBClusters_773888, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_773949 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBEngineVersions_773951(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBEngineVersions_773950(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the available DB engines.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773952 = query.getOrDefault("Action")
  valid_773952 = validateParameter(valid_773952, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_773952 != nil:
    section.add "Action", valid_773952
  var valid_773953 = query.getOrDefault("Version")
  valid_773953 = validateParameter(valid_773953, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773953 != nil:
    section.add "Version", valid_773953
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773954 = header.getOrDefault("X-Amz-Date")
  valid_773954 = validateParameter(valid_773954, JString, required = false,
                                 default = nil)
  if valid_773954 != nil:
    section.add "X-Amz-Date", valid_773954
  var valid_773955 = header.getOrDefault("X-Amz-Security-Token")
  valid_773955 = validateParameter(valid_773955, JString, required = false,
                                 default = nil)
  if valid_773955 != nil:
    section.add "X-Amz-Security-Token", valid_773955
  var valid_773956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773956 = validateParameter(valid_773956, JString, required = false,
                                 default = nil)
  if valid_773956 != nil:
    section.add "X-Amz-Content-Sha256", valid_773956
  var valid_773957 = header.getOrDefault("X-Amz-Algorithm")
  valid_773957 = validateParameter(valid_773957, JString, required = false,
                                 default = nil)
  if valid_773957 != nil:
    section.add "X-Amz-Algorithm", valid_773957
  var valid_773958 = header.getOrDefault("X-Amz-Signature")
  valid_773958 = validateParameter(valid_773958, JString, required = false,
                                 default = nil)
  if valid_773958 != nil:
    section.add "X-Amz-Signature", valid_773958
  var valid_773959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773959 = validateParameter(valid_773959, JString, required = false,
                                 default = nil)
  if valid_773959 != nil:
    section.add "X-Amz-SignedHeaders", valid_773959
  var valid_773960 = header.getOrDefault("X-Amz-Credential")
  valid_773960 = validateParameter(valid_773960, JString, required = false,
                                 default = nil)
  if valid_773960 != nil:
    section.add "X-Amz-Credential", valid_773960
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListSupportedCharacterSets: JBool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   Engine: JString
  ##         : The database engine to return.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBParameterGroupFamily: JString
  ##                         : <p>The name of a specific DB parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: JString
  ##                : <p>The database engine version to return.</p> <p>Example: <code>5.1.49</code> </p>
  ##   ListSupportedTimezones: JBool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   DefaultOnly: JBool
  ##              : Indicates that only the default version of the specified engine or engine and major version combination is returned.
  section = newJObject()
  var valid_773961 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_773961 = validateParameter(valid_773961, JBool, required = false, default = nil)
  if valid_773961 != nil:
    section.add "ListSupportedCharacterSets", valid_773961
  var valid_773962 = formData.getOrDefault("Engine")
  valid_773962 = validateParameter(valid_773962, JString, required = false,
                                 default = nil)
  if valid_773962 != nil:
    section.add "Engine", valid_773962
  var valid_773963 = formData.getOrDefault("Marker")
  valid_773963 = validateParameter(valid_773963, JString, required = false,
                                 default = nil)
  if valid_773963 != nil:
    section.add "Marker", valid_773963
  var valid_773964 = formData.getOrDefault("DBParameterGroupFamily")
  valid_773964 = validateParameter(valid_773964, JString, required = false,
                                 default = nil)
  if valid_773964 != nil:
    section.add "DBParameterGroupFamily", valid_773964
  var valid_773965 = formData.getOrDefault("Filters")
  valid_773965 = validateParameter(valid_773965, JArray, required = false,
                                 default = nil)
  if valid_773965 != nil:
    section.add "Filters", valid_773965
  var valid_773966 = formData.getOrDefault("MaxRecords")
  valid_773966 = validateParameter(valid_773966, JInt, required = false, default = nil)
  if valid_773966 != nil:
    section.add "MaxRecords", valid_773966
  var valid_773967 = formData.getOrDefault("EngineVersion")
  valid_773967 = validateParameter(valid_773967, JString, required = false,
                                 default = nil)
  if valid_773967 != nil:
    section.add "EngineVersion", valid_773967
  var valid_773968 = formData.getOrDefault("ListSupportedTimezones")
  valid_773968 = validateParameter(valid_773968, JBool, required = false, default = nil)
  if valid_773968 != nil:
    section.add "ListSupportedTimezones", valid_773968
  var valid_773969 = formData.getOrDefault("DefaultOnly")
  valid_773969 = validateParameter(valid_773969, JBool, required = false, default = nil)
  if valid_773969 != nil:
    section.add "DefaultOnly", valid_773969
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773970: Call_PostDescribeDBEngineVersions_773949; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_773970.validator(path, query, header, formData, body)
  let scheme = call_773970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773970.url(scheme.get, call_773970.host, call_773970.base,
                         call_773970.route, valid.getOrDefault("path"))
  result = hook(call_773970, url, valid)

proc call*(call_773971: Call_PostDescribeDBEngineVersions_773949;
          ListSupportedCharacterSets: bool = false; Engine: string = "";
          Marker: string = ""; Action: string = "DescribeDBEngineVersions";
          DBParameterGroupFamily: string = ""; Filters: JsonNode = nil;
          MaxRecords: int = 0; EngineVersion: string = "";
          ListSupportedTimezones: bool = false; Version: string = "2014-10-31";
          DefaultOnly: bool = false): Recallable =
  ## postDescribeDBEngineVersions
  ## Returns a list of the available DB engines.
  ##   ListSupportedCharacterSets: bool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   Engine: string
  ##         : The database engine to return.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string
  ##                         : <p>The name of a specific DB parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: string
  ##                : <p>The database engine version to return.</p> <p>Example: <code>5.1.49</code> </p>
  ##   ListSupportedTimezones: bool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   Version: string (required)
  ##   DefaultOnly: bool
  ##              : Indicates that only the default version of the specified engine or engine and major version combination is returned.
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
  add(formData_773973, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_773972, "Version", newJString(Version))
  add(formData_773973, "DefaultOnly", newJBool(DefaultOnly))
  result = call_773971.call(nil, query_773972, nil, formData_773973, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_773949(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_773950, base: "/",
    url: url_PostDescribeDBEngineVersions_773951,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_773925 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBEngineVersions_773927(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBEngineVersions_773926(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the available DB engines.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString
  ##         : The database engine to return.
  ##   ListSupportedCharacterSets: JBool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBParameterGroupFamily: JString
  ##                         : <p>The name of a specific DB parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ListSupportedTimezones: JBool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EngineVersion: JString
  ##                : <p>The database engine version to return.</p> <p>Example: <code>5.1.49</code> </p>
  ##   DefaultOnly: JBool
  ##              : Indicates that only the default version of the specified engine or engine and major version combination is returned.
  ##   Version: JString (required)
  section = newJObject()
  var valid_773928 = query.getOrDefault("Engine")
  valid_773928 = validateParameter(valid_773928, JString, required = false,
                                 default = nil)
  if valid_773928 != nil:
    section.add "Engine", valid_773928
  var valid_773929 = query.getOrDefault("ListSupportedCharacterSets")
  valid_773929 = validateParameter(valid_773929, JBool, required = false, default = nil)
  if valid_773929 != nil:
    section.add "ListSupportedCharacterSets", valid_773929
  var valid_773930 = query.getOrDefault("MaxRecords")
  valid_773930 = validateParameter(valid_773930, JInt, required = false, default = nil)
  if valid_773930 != nil:
    section.add "MaxRecords", valid_773930
  var valid_773931 = query.getOrDefault("DBParameterGroupFamily")
  valid_773931 = validateParameter(valid_773931, JString, required = false,
                                 default = nil)
  if valid_773931 != nil:
    section.add "DBParameterGroupFamily", valid_773931
  var valid_773932 = query.getOrDefault("Filters")
  valid_773932 = validateParameter(valid_773932, JArray, required = false,
                                 default = nil)
  if valid_773932 != nil:
    section.add "Filters", valid_773932
  var valid_773933 = query.getOrDefault("ListSupportedTimezones")
  valid_773933 = validateParameter(valid_773933, JBool, required = false, default = nil)
  if valid_773933 != nil:
    section.add "ListSupportedTimezones", valid_773933
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773934 = query.getOrDefault("Action")
  valid_773934 = validateParameter(valid_773934, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_773934 != nil:
    section.add "Action", valid_773934
  var valid_773935 = query.getOrDefault("Marker")
  valid_773935 = validateParameter(valid_773935, JString, required = false,
                                 default = nil)
  if valid_773935 != nil:
    section.add "Marker", valid_773935
  var valid_773936 = query.getOrDefault("EngineVersion")
  valid_773936 = validateParameter(valid_773936, JString, required = false,
                                 default = nil)
  if valid_773936 != nil:
    section.add "EngineVersion", valid_773936
  var valid_773937 = query.getOrDefault("DefaultOnly")
  valid_773937 = validateParameter(valid_773937, JBool, required = false, default = nil)
  if valid_773937 != nil:
    section.add "DefaultOnly", valid_773937
  var valid_773938 = query.getOrDefault("Version")
  valid_773938 = validateParameter(valid_773938, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_773938 != nil:
    section.add "Version", valid_773938
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773939 = header.getOrDefault("X-Amz-Date")
  valid_773939 = validateParameter(valid_773939, JString, required = false,
                                 default = nil)
  if valid_773939 != nil:
    section.add "X-Amz-Date", valid_773939
  var valid_773940 = header.getOrDefault("X-Amz-Security-Token")
  valid_773940 = validateParameter(valid_773940, JString, required = false,
                                 default = nil)
  if valid_773940 != nil:
    section.add "X-Amz-Security-Token", valid_773940
  var valid_773941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773941 = validateParameter(valid_773941, JString, required = false,
                                 default = nil)
  if valid_773941 != nil:
    section.add "X-Amz-Content-Sha256", valid_773941
  var valid_773942 = header.getOrDefault("X-Amz-Algorithm")
  valid_773942 = validateParameter(valid_773942, JString, required = false,
                                 default = nil)
  if valid_773942 != nil:
    section.add "X-Amz-Algorithm", valid_773942
  var valid_773943 = header.getOrDefault("X-Amz-Signature")
  valid_773943 = validateParameter(valid_773943, JString, required = false,
                                 default = nil)
  if valid_773943 != nil:
    section.add "X-Amz-Signature", valid_773943
  var valid_773944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773944 = validateParameter(valid_773944, JString, required = false,
                                 default = nil)
  if valid_773944 != nil:
    section.add "X-Amz-SignedHeaders", valid_773944
  var valid_773945 = header.getOrDefault("X-Amz-Credential")
  valid_773945 = validateParameter(valid_773945, JString, required = false,
                                 default = nil)
  if valid_773945 != nil:
    section.add "X-Amz-Credential", valid_773945
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773946: Call_GetDescribeDBEngineVersions_773925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_773946.validator(path, query, header, formData, body)
  let scheme = call_773946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773946.url(scheme.get, call_773946.host, call_773946.base,
                         call_773946.route, valid.getOrDefault("path"))
  result = hook(call_773946, url, valid)

proc call*(call_773947: Call_GetDescribeDBEngineVersions_773925;
          Engine: string = ""; ListSupportedCharacterSets: bool = false;
          MaxRecords: int = 0; DBParameterGroupFamily: string = "";
          Filters: JsonNode = nil; ListSupportedTimezones: bool = false;
          Action: string = "DescribeDBEngineVersions"; Marker: string = "";
          EngineVersion: string = ""; DefaultOnly: bool = false;
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBEngineVersions
  ## Returns a list of the available DB engines.
  ##   Engine: string
  ##         : The database engine to return.
  ##   ListSupportedCharacterSets: bool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBParameterGroupFamily: string
  ##                         : <p>The name of a specific DB parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ListSupportedTimezones: bool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EngineVersion: string
  ##                : <p>The database engine version to return.</p> <p>Example: <code>5.1.49</code> </p>
  ##   DefaultOnly: bool
  ##              : Indicates that only the default version of the specified engine or engine and major version combination is returned.
  ##   Version: string (required)
  var query_773948 = newJObject()
  add(query_773948, "Engine", newJString(Engine))
  add(query_773948, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_773948, "MaxRecords", newJInt(MaxRecords))
  add(query_773948, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_773948.add "Filters", Filters
  add(query_773948, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_773948, "Action", newJString(Action))
  add(query_773948, "Marker", newJString(Marker))
  add(query_773948, "EngineVersion", newJString(EngineVersion))
  add(query_773948, "DefaultOnly", newJBool(DefaultOnly))
  add(query_773948, "Version", newJString(Version))
  result = call_773947.call(nil, query_773948, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_773925(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_773926, base: "/",
    url: url_GetDescribeDBEngineVersions_773927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_773993 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBInstances_773995(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBInstances_773994(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
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
                                 default = newJString("2014-10-31"))
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
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific DB instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only the information about the DB instances that are associated with the DB clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only the information about the DB instances that are identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
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
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
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
          MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBInstances
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ##   DBInstanceIdentifier: string
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific DB instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only the information about the DB instances that are associated with the DB clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only the information about the DB instances that are identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
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
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only the information about the DB instances that are associated with the DB clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only the information about the DB instances that are identified by these ARNs.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific DB instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
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
                                 default = newJString("2014-10-31"))
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
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_773990.validator(path, query, header, formData, body)
  let scheme = call_773990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773990.url(scheme.get, call_773990.host, call_773990.base,
                         call_773990.route, valid.getOrDefault("path"))
  result = hook(call_773990, url, valid)

proc call*(call_773991: Call_GetDescribeDBInstances_773974; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBInstances";
          Marker: string = ""; Version: string = "2014-10-31";
          DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only the information about the DB instances that are associated with the DB clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only the information about the DB instances that are identified by these ARNs.</p> </li> </ul>
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific DB instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
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
  Call_PostDescribeDBSubnetGroups_774032 = ref object of OpenApiRestCall_772581
proc url_PostDescribeDBSubnetGroups_774034(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSubnetGroups_774033(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774035 = query.getOrDefault("Action")
  valid_774035 = validateParameter(valid_774035, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_774035 != nil:
    section.add "Action", valid_774035
  var valid_774036 = query.getOrDefault("Version")
  valid_774036 = validateParameter(valid_774036, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774036 != nil:
    section.add "Version", valid_774036
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774037 = header.getOrDefault("X-Amz-Date")
  valid_774037 = validateParameter(valid_774037, JString, required = false,
                                 default = nil)
  if valid_774037 != nil:
    section.add "X-Amz-Date", valid_774037
  var valid_774038 = header.getOrDefault("X-Amz-Security-Token")
  valid_774038 = validateParameter(valid_774038, JString, required = false,
                                 default = nil)
  if valid_774038 != nil:
    section.add "X-Amz-Security-Token", valid_774038
  var valid_774039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774039 = validateParameter(valid_774039, JString, required = false,
                                 default = nil)
  if valid_774039 != nil:
    section.add "X-Amz-Content-Sha256", valid_774039
  var valid_774040 = header.getOrDefault("X-Amz-Algorithm")
  valid_774040 = validateParameter(valid_774040, JString, required = false,
                                 default = nil)
  if valid_774040 != nil:
    section.add "X-Amz-Algorithm", valid_774040
  var valid_774041 = header.getOrDefault("X-Amz-Signature")
  valid_774041 = validateParameter(valid_774041, JString, required = false,
                                 default = nil)
  if valid_774041 != nil:
    section.add "X-Amz-Signature", valid_774041
  var valid_774042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774042 = validateParameter(valid_774042, JString, required = false,
                                 default = nil)
  if valid_774042 != nil:
    section.add "X-Amz-SignedHeaders", valid_774042
  var valid_774043 = header.getOrDefault("X-Amz-Credential")
  valid_774043 = validateParameter(valid_774043, JString, required = false,
                                 default = nil)
  if valid_774043 != nil:
    section.add "X-Amz-Credential", valid_774043
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##                    : The name of the DB subnet group to return details for.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_774044 = formData.getOrDefault("DBSubnetGroupName")
  valid_774044 = validateParameter(valid_774044, JString, required = false,
                                 default = nil)
  if valid_774044 != nil:
    section.add "DBSubnetGroupName", valid_774044
  var valid_774045 = formData.getOrDefault("Marker")
  valid_774045 = validateParameter(valid_774045, JString, required = false,
                                 default = nil)
  if valid_774045 != nil:
    section.add "Marker", valid_774045
  var valid_774046 = formData.getOrDefault("Filters")
  valid_774046 = validateParameter(valid_774046, JArray, required = false,
                                 default = nil)
  if valid_774046 != nil:
    section.add "Filters", valid_774046
  var valid_774047 = formData.getOrDefault("MaxRecords")
  valid_774047 = validateParameter(valid_774047, JInt, required = false, default = nil)
  if valid_774047 != nil:
    section.add "MaxRecords", valid_774047
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774048: Call_PostDescribeDBSubnetGroups_774032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_774048.validator(path, query, header, formData, body)
  let scheme = call_774048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774048.url(scheme.get, call_774048.host, call_774048.base,
                         call_774048.route, valid.getOrDefault("path"))
  result = hook(call_774048, url, valid)

proc call*(call_774049: Call_PostDescribeDBSubnetGroups_774032;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBSubnetGroups
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ##   DBSubnetGroupName: string
  ##                    : The name of the DB subnet group to return details for.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_774050 = newJObject()
  var formData_774051 = newJObject()
  add(formData_774051, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_774051, "Marker", newJString(Marker))
  add(query_774050, "Action", newJString(Action))
  if Filters != nil:
    formData_774051.add "Filters", Filters
  add(formData_774051, "MaxRecords", newJInt(MaxRecords))
  add(query_774050, "Version", newJString(Version))
  result = call_774049.call(nil, query_774050, nil, formData_774051, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_774032(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_774033, base: "/",
    url: url_PostDescribeDBSubnetGroups_774034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_774013 = ref object of OpenApiRestCall_772581
proc url_GetDescribeDBSubnetGroups_774015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSubnetGroups_774014(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBSubnetGroupName: JString
  ##                    : The name of the DB subnet group to return details for.
  ##   Version: JString (required)
  section = newJObject()
  var valid_774016 = query.getOrDefault("MaxRecords")
  valid_774016 = validateParameter(valid_774016, JInt, required = false, default = nil)
  if valid_774016 != nil:
    section.add "MaxRecords", valid_774016
  var valid_774017 = query.getOrDefault("Filters")
  valid_774017 = validateParameter(valid_774017, JArray, required = false,
                                 default = nil)
  if valid_774017 != nil:
    section.add "Filters", valid_774017
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774018 = query.getOrDefault("Action")
  valid_774018 = validateParameter(valid_774018, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_774018 != nil:
    section.add "Action", valid_774018
  var valid_774019 = query.getOrDefault("Marker")
  valid_774019 = validateParameter(valid_774019, JString, required = false,
                                 default = nil)
  if valid_774019 != nil:
    section.add "Marker", valid_774019
  var valid_774020 = query.getOrDefault("DBSubnetGroupName")
  valid_774020 = validateParameter(valid_774020, JString, required = false,
                                 default = nil)
  if valid_774020 != nil:
    section.add "DBSubnetGroupName", valid_774020
  var valid_774021 = query.getOrDefault("Version")
  valid_774021 = validateParameter(valid_774021, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774021 != nil:
    section.add "Version", valid_774021
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774022 = header.getOrDefault("X-Amz-Date")
  valid_774022 = validateParameter(valid_774022, JString, required = false,
                                 default = nil)
  if valid_774022 != nil:
    section.add "X-Amz-Date", valid_774022
  var valid_774023 = header.getOrDefault("X-Amz-Security-Token")
  valid_774023 = validateParameter(valid_774023, JString, required = false,
                                 default = nil)
  if valid_774023 != nil:
    section.add "X-Amz-Security-Token", valid_774023
  var valid_774024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774024 = validateParameter(valid_774024, JString, required = false,
                                 default = nil)
  if valid_774024 != nil:
    section.add "X-Amz-Content-Sha256", valid_774024
  var valid_774025 = header.getOrDefault("X-Amz-Algorithm")
  valid_774025 = validateParameter(valid_774025, JString, required = false,
                                 default = nil)
  if valid_774025 != nil:
    section.add "X-Amz-Algorithm", valid_774025
  var valid_774026 = header.getOrDefault("X-Amz-Signature")
  valid_774026 = validateParameter(valid_774026, JString, required = false,
                                 default = nil)
  if valid_774026 != nil:
    section.add "X-Amz-Signature", valid_774026
  var valid_774027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774027 = validateParameter(valid_774027, JString, required = false,
                                 default = nil)
  if valid_774027 != nil:
    section.add "X-Amz-SignedHeaders", valid_774027
  var valid_774028 = header.getOrDefault("X-Amz-Credential")
  valid_774028 = validateParameter(valid_774028, JString, required = false,
                                 default = nil)
  if valid_774028 != nil:
    section.add "X-Amz-Credential", valid_774028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774029: Call_GetDescribeDBSubnetGroups_774013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_774029.validator(path, query, header, formData, body)
  let scheme = call_774029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774029.url(scheme.get, call_774029.host, call_774029.base,
                         call_774029.route, valid.getOrDefault("path"))
  result = hook(call_774029, url, valid)

proc call*(call_774030: Call_GetDescribeDBSubnetGroups_774013; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBSubnetGroups";
          Marker: string = ""; DBSubnetGroupName: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBSubnetGroups
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBSubnetGroupName: string
  ##                    : The name of the DB subnet group to return details for.
  ##   Version: string (required)
  var query_774031 = newJObject()
  add(query_774031, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774031.add "Filters", Filters
  add(query_774031, "Action", newJString(Action))
  add(query_774031, "Marker", newJString(Marker))
  add(query_774031, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_774031, "Version", newJString(Version))
  result = call_774030.call(nil, query_774031, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_774013(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_774014, base: "/",
    url: url_GetDescribeDBSubnetGroups_774015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultClusterParameters_774071 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEngineDefaultClusterParameters_774073(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEngineDefaultClusterParameters_774072(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774074 = query.getOrDefault("Action")
  valid_774074 = validateParameter(valid_774074, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_774074 != nil:
    section.add "Action", valid_774074
  var valid_774075 = query.getOrDefault("Version")
  valid_774075 = validateParameter(valid_774075, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774075 != nil:
    section.add "Version", valid_774075
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774076 = header.getOrDefault("X-Amz-Date")
  valid_774076 = validateParameter(valid_774076, JString, required = false,
                                 default = nil)
  if valid_774076 != nil:
    section.add "X-Amz-Date", valid_774076
  var valid_774077 = header.getOrDefault("X-Amz-Security-Token")
  valid_774077 = validateParameter(valid_774077, JString, required = false,
                                 default = nil)
  if valid_774077 != nil:
    section.add "X-Amz-Security-Token", valid_774077
  var valid_774078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774078 = validateParameter(valid_774078, JString, required = false,
                                 default = nil)
  if valid_774078 != nil:
    section.add "X-Amz-Content-Sha256", valid_774078
  var valid_774079 = header.getOrDefault("X-Amz-Algorithm")
  valid_774079 = validateParameter(valid_774079, JString, required = false,
                                 default = nil)
  if valid_774079 != nil:
    section.add "X-Amz-Algorithm", valid_774079
  var valid_774080 = header.getOrDefault("X-Amz-Signature")
  valid_774080 = validateParameter(valid_774080, JString, required = false,
                                 default = nil)
  if valid_774080 != nil:
    section.add "X-Amz-Signature", valid_774080
  var valid_774081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774081 = validateParameter(valid_774081, JString, required = false,
                                 default = nil)
  if valid_774081 != nil:
    section.add "X-Amz-SignedHeaders", valid_774081
  var valid_774082 = header.getOrDefault("X-Amz-Credential")
  valid_774082 = validateParameter(valid_774082, JString, required = false,
                                 default = nil)
  if valid_774082 != nil:
    section.add "X-Amz-Credential", valid_774082
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The name of the DB cluster parameter group family to return the engine parameter information for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_774083 = formData.getOrDefault("Marker")
  valid_774083 = validateParameter(valid_774083, JString, required = false,
                                 default = nil)
  if valid_774083 != nil:
    section.add "Marker", valid_774083
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_774084 = formData.getOrDefault("DBParameterGroupFamily")
  valid_774084 = validateParameter(valid_774084, JString, required = true,
                                 default = nil)
  if valid_774084 != nil:
    section.add "DBParameterGroupFamily", valid_774084
  var valid_774085 = formData.getOrDefault("Filters")
  valid_774085 = validateParameter(valid_774085, JArray, required = false,
                                 default = nil)
  if valid_774085 != nil:
    section.add "Filters", valid_774085
  var valid_774086 = formData.getOrDefault("MaxRecords")
  valid_774086 = validateParameter(valid_774086, JInt, required = false, default = nil)
  if valid_774086 != nil:
    section.add "MaxRecords", valid_774086
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774087: Call_PostDescribeEngineDefaultClusterParameters_774071;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_774087.validator(path, query, header, formData, body)
  let scheme = call_774087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774087.url(scheme.get, call_774087.host, call_774087.base,
                         call_774087.route, valid.getOrDefault("path"))
  result = hook(call_774087, url, valid)

proc call*(call_774088: Call_PostDescribeEngineDefaultClusterParameters_774071;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultClusterParameters";
          Filters: JsonNode = nil; MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeEngineDefaultClusterParameters
  ## Returns the default engine and system parameter information for the cluster database engine.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##                         : The name of the DB cluster parameter group family to return the engine parameter information for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_774089 = newJObject()
  var formData_774090 = newJObject()
  add(formData_774090, "Marker", newJString(Marker))
  add(query_774089, "Action", newJString(Action))
  add(formData_774090, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_774090.add "Filters", Filters
  add(formData_774090, "MaxRecords", newJInt(MaxRecords))
  add(query_774089, "Version", newJString(Version))
  result = call_774088.call(nil, query_774089, nil, formData_774090, nil)

var postDescribeEngineDefaultClusterParameters* = Call_PostDescribeEngineDefaultClusterParameters_774071(
    name: "postDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_PostDescribeEngineDefaultClusterParameters_774072,
    base: "/", url: url_PostDescribeEngineDefaultClusterParameters_774073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultClusterParameters_774052 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEngineDefaultClusterParameters_774054(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEngineDefaultClusterParameters_774053(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The name of the DB cluster parameter group family to return the engine parameter information for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_774055 = query.getOrDefault("MaxRecords")
  valid_774055 = validateParameter(valid_774055, JInt, required = false, default = nil)
  if valid_774055 != nil:
    section.add "MaxRecords", valid_774055
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_774056 = query.getOrDefault("DBParameterGroupFamily")
  valid_774056 = validateParameter(valid_774056, JString, required = true,
                                 default = nil)
  if valid_774056 != nil:
    section.add "DBParameterGroupFamily", valid_774056
  var valid_774057 = query.getOrDefault("Filters")
  valid_774057 = validateParameter(valid_774057, JArray, required = false,
                                 default = nil)
  if valid_774057 != nil:
    section.add "Filters", valid_774057
  var valid_774058 = query.getOrDefault("Action")
  valid_774058 = validateParameter(valid_774058, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_774058 != nil:
    section.add "Action", valid_774058
  var valid_774059 = query.getOrDefault("Marker")
  valid_774059 = validateParameter(valid_774059, JString, required = false,
                                 default = nil)
  if valid_774059 != nil:
    section.add "Marker", valid_774059
  var valid_774060 = query.getOrDefault("Version")
  valid_774060 = validateParameter(valid_774060, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774060 != nil:
    section.add "Version", valid_774060
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774061 = header.getOrDefault("X-Amz-Date")
  valid_774061 = validateParameter(valid_774061, JString, required = false,
                                 default = nil)
  if valid_774061 != nil:
    section.add "X-Amz-Date", valid_774061
  var valid_774062 = header.getOrDefault("X-Amz-Security-Token")
  valid_774062 = validateParameter(valid_774062, JString, required = false,
                                 default = nil)
  if valid_774062 != nil:
    section.add "X-Amz-Security-Token", valid_774062
  var valid_774063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774063 = validateParameter(valid_774063, JString, required = false,
                                 default = nil)
  if valid_774063 != nil:
    section.add "X-Amz-Content-Sha256", valid_774063
  var valid_774064 = header.getOrDefault("X-Amz-Algorithm")
  valid_774064 = validateParameter(valid_774064, JString, required = false,
                                 default = nil)
  if valid_774064 != nil:
    section.add "X-Amz-Algorithm", valid_774064
  var valid_774065 = header.getOrDefault("X-Amz-Signature")
  valid_774065 = validateParameter(valid_774065, JString, required = false,
                                 default = nil)
  if valid_774065 != nil:
    section.add "X-Amz-Signature", valid_774065
  var valid_774066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774066 = validateParameter(valid_774066, JString, required = false,
                                 default = nil)
  if valid_774066 != nil:
    section.add "X-Amz-SignedHeaders", valid_774066
  var valid_774067 = header.getOrDefault("X-Amz-Credential")
  valid_774067 = validateParameter(valid_774067, JString, required = false,
                                 default = nil)
  if valid_774067 != nil:
    section.add "X-Amz-Credential", valid_774067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774068: Call_GetDescribeEngineDefaultClusterParameters_774052;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_774068.validator(path, query, header, formData, body)
  let scheme = call_774068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774068.url(scheme.get, call_774068.host, call_774068.base,
                         call_774068.route, valid.getOrDefault("path"))
  result = hook(call_774068, url, valid)

proc call*(call_774069: Call_GetDescribeEngineDefaultClusterParameters_774052;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Filters: JsonNode = nil;
          Action: string = "DescribeEngineDefaultClusterParameters";
          Marker: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getDescribeEngineDefaultClusterParameters
  ## Returns the default engine and system parameter information for the cluster database engine.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBParameterGroupFamily: string (required)
  ##                         : The name of the DB cluster parameter group family to return the engine parameter information for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  var query_774070 = newJObject()
  add(query_774070, "MaxRecords", newJInt(MaxRecords))
  add(query_774070, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_774070.add "Filters", Filters
  add(query_774070, "Action", newJString(Action))
  add(query_774070, "Marker", newJString(Marker))
  add(query_774070, "Version", newJString(Version))
  result = call_774069.call(nil, query_774070, nil, nil, nil)

var getDescribeEngineDefaultClusterParameters* = Call_GetDescribeEngineDefaultClusterParameters_774052(
    name: "getDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_GetDescribeEngineDefaultClusterParameters_774053,
    base: "/", url: url_GetDescribeEngineDefaultClusterParameters_774054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_774108 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEventCategories_774110(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventCategories_774109(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774111 = query.getOrDefault("Action")
  valid_774111 = validateParameter(valid_774111, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_774111 != nil:
    section.add "Action", valid_774111
  var valid_774112 = query.getOrDefault("Version")
  valid_774112 = validateParameter(valid_774112, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774112 != nil:
    section.add "Version", valid_774112
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774113 = header.getOrDefault("X-Amz-Date")
  valid_774113 = validateParameter(valid_774113, JString, required = false,
                                 default = nil)
  if valid_774113 != nil:
    section.add "X-Amz-Date", valid_774113
  var valid_774114 = header.getOrDefault("X-Amz-Security-Token")
  valid_774114 = validateParameter(valid_774114, JString, required = false,
                                 default = nil)
  if valid_774114 != nil:
    section.add "X-Amz-Security-Token", valid_774114
  var valid_774115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "X-Amz-Content-Sha256", valid_774115
  var valid_774116 = header.getOrDefault("X-Amz-Algorithm")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "X-Amz-Algorithm", valid_774116
  var valid_774117 = header.getOrDefault("X-Amz-Signature")
  valid_774117 = validateParameter(valid_774117, JString, required = false,
                                 default = nil)
  if valid_774117 != nil:
    section.add "X-Amz-Signature", valid_774117
  var valid_774118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774118 = validateParameter(valid_774118, JString, required = false,
                                 default = nil)
  if valid_774118 != nil:
    section.add "X-Amz-SignedHeaders", valid_774118
  var valid_774119 = header.getOrDefault("X-Amz-Credential")
  valid_774119 = validateParameter(valid_774119, JString, required = false,
                                 default = nil)
  if valid_774119 != nil:
    section.add "X-Amz-Credential", valid_774119
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  section = newJObject()
  var valid_774120 = formData.getOrDefault("Filters")
  valid_774120 = validateParameter(valid_774120, JArray, required = false,
                                 default = nil)
  if valid_774120 != nil:
    section.add "Filters", valid_774120
  var valid_774121 = formData.getOrDefault("SourceType")
  valid_774121 = validateParameter(valid_774121, JString, required = false,
                                 default = nil)
  if valid_774121 != nil:
    section.add "SourceType", valid_774121
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774122: Call_PostDescribeEventCategories_774108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_774122.validator(path, query, header, formData, body)
  let scheme = call_774122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774122.url(scheme.get, call_774122.host, call_774122.base,
                         call_774122.route, valid.getOrDefault("path"))
  result = hook(call_774122, url, valid)

proc call*(call_774123: Call_PostDescribeEventCategories_774108;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2014-10-31"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Version: string (required)
  ##   SourceType: string
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  var query_774124 = newJObject()
  var formData_774125 = newJObject()
  add(query_774124, "Action", newJString(Action))
  if Filters != nil:
    formData_774125.add "Filters", Filters
  add(query_774124, "Version", newJString(Version))
  add(formData_774125, "SourceType", newJString(SourceType))
  result = call_774123.call(nil, query_774124, nil, formData_774125, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_774108(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_774109, base: "/",
    url: url_PostDescribeEventCategories_774110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_774091 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEventCategories_774093(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventCategories_774092(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_774094 = query.getOrDefault("SourceType")
  valid_774094 = validateParameter(valid_774094, JString, required = false,
                                 default = nil)
  if valid_774094 != nil:
    section.add "SourceType", valid_774094
  var valid_774095 = query.getOrDefault("Filters")
  valid_774095 = validateParameter(valid_774095, JArray, required = false,
                                 default = nil)
  if valid_774095 != nil:
    section.add "Filters", valid_774095
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774096 = query.getOrDefault("Action")
  valid_774096 = validateParameter(valid_774096, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_774096 != nil:
    section.add "Action", valid_774096
  var valid_774097 = query.getOrDefault("Version")
  valid_774097 = validateParameter(valid_774097, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774097 != nil:
    section.add "Version", valid_774097
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774098 = header.getOrDefault("X-Amz-Date")
  valid_774098 = validateParameter(valid_774098, JString, required = false,
                                 default = nil)
  if valid_774098 != nil:
    section.add "X-Amz-Date", valid_774098
  var valid_774099 = header.getOrDefault("X-Amz-Security-Token")
  valid_774099 = validateParameter(valid_774099, JString, required = false,
                                 default = nil)
  if valid_774099 != nil:
    section.add "X-Amz-Security-Token", valid_774099
  var valid_774100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774100 = validateParameter(valid_774100, JString, required = false,
                                 default = nil)
  if valid_774100 != nil:
    section.add "X-Amz-Content-Sha256", valid_774100
  var valid_774101 = header.getOrDefault("X-Amz-Algorithm")
  valid_774101 = validateParameter(valid_774101, JString, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "X-Amz-Algorithm", valid_774101
  var valid_774102 = header.getOrDefault("X-Amz-Signature")
  valid_774102 = validateParameter(valid_774102, JString, required = false,
                                 default = nil)
  if valid_774102 != nil:
    section.add "X-Amz-Signature", valid_774102
  var valid_774103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774103 = validateParameter(valid_774103, JString, required = false,
                                 default = nil)
  if valid_774103 != nil:
    section.add "X-Amz-SignedHeaders", valid_774103
  var valid_774104 = header.getOrDefault("X-Amz-Credential")
  valid_774104 = validateParameter(valid_774104, JString, required = false,
                                 default = nil)
  if valid_774104 != nil:
    section.add "X-Amz-Credential", valid_774104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774105: Call_GetDescribeEventCategories_774091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_774105.validator(path, query, header, formData, body)
  let scheme = call_774105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774105.url(scheme.get, call_774105.host, call_774105.base,
                         call_774105.route, valid.getOrDefault("path"))
  result = hook(call_774105, url, valid)

proc call*(call_774106: Call_GetDescribeEventCategories_774091;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2014-10-31"): Recallable =
  ## getDescribeEventCategories
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ##   SourceType: string
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774107 = newJObject()
  add(query_774107, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_774107.add "Filters", Filters
  add(query_774107, "Action", newJString(Action))
  add(query_774107, "Version", newJString(Version))
  result = call_774106.call(nil, query_774107, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_774091(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_774092, base: "/",
    url: url_GetDescribeEventCategories_774093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_774150 = ref object of OpenApiRestCall_772581
proc url_PostDescribeEvents_774152(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_774151(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774153 = query.getOrDefault("Action")
  valid_774153 = validateParameter(valid_774153, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_774153 != nil:
    section.add "Action", valid_774153
  var valid_774154 = query.getOrDefault("Version")
  valid_774154 = validateParameter(valid_774154, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774154 != nil:
    section.add "Version", valid_774154
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString
  ##                   : <p>The identifier of the event source for which events are returned. If not specified, then all sources are included in the response.</p> <p>Constraints:</p> <ul> <li> <p>If <code>SourceIdentifier</code> is provided, <code>SourceType</code> must also be provided.</p> </li> <li> <p>If the source type is <code>DBInstance</code>, a <code>DBInstanceIdentifier</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSecurityGroup</code>, a <code>DBSecurityGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBParameterGroup</code>, a <code>DBParameterGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSnapshot</code>, a <code>DBSnapshotIdentifier</code> must be provided.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   EventCategories: JArray
  ##                  : A list of event categories that trigger notifications for an event notification subscription.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   StartTime: JString
  ##            : <p> The beginning of the time interval to retrieve events for, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Duration: JInt
  ##           : <p>The number of minutes to retrieve events for.</p> <p>Default: 60</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   EndTime: JString
  ##          : <p> The end of the time interval for which to retrieve events, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   SourceType: JString
  ##             : The event source to retrieve events for. If no value is specified, all events are returned.
  section = newJObject()
  var valid_774162 = formData.getOrDefault("SourceIdentifier")
  valid_774162 = validateParameter(valid_774162, JString, required = false,
                                 default = nil)
  if valid_774162 != nil:
    section.add "SourceIdentifier", valid_774162
  var valid_774163 = formData.getOrDefault("EventCategories")
  valid_774163 = validateParameter(valid_774163, JArray, required = false,
                                 default = nil)
  if valid_774163 != nil:
    section.add "EventCategories", valid_774163
  var valid_774164 = formData.getOrDefault("Marker")
  valid_774164 = validateParameter(valid_774164, JString, required = false,
                                 default = nil)
  if valid_774164 != nil:
    section.add "Marker", valid_774164
  var valid_774165 = formData.getOrDefault("StartTime")
  valid_774165 = validateParameter(valid_774165, JString, required = false,
                                 default = nil)
  if valid_774165 != nil:
    section.add "StartTime", valid_774165
  var valid_774166 = formData.getOrDefault("Duration")
  valid_774166 = validateParameter(valid_774166, JInt, required = false, default = nil)
  if valid_774166 != nil:
    section.add "Duration", valid_774166
  var valid_774167 = formData.getOrDefault("Filters")
  valid_774167 = validateParameter(valid_774167, JArray, required = false,
                                 default = nil)
  if valid_774167 != nil:
    section.add "Filters", valid_774167
  var valid_774168 = formData.getOrDefault("EndTime")
  valid_774168 = validateParameter(valid_774168, JString, required = false,
                                 default = nil)
  if valid_774168 != nil:
    section.add "EndTime", valid_774168
  var valid_774169 = formData.getOrDefault("MaxRecords")
  valid_774169 = validateParameter(valid_774169, JInt, required = false, default = nil)
  if valid_774169 != nil:
    section.add "MaxRecords", valid_774169
  var valid_774170 = formData.getOrDefault("SourceType")
  valid_774170 = validateParameter(valid_774170, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_774170 != nil:
    section.add "SourceType", valid_774170
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774171: Call_PostDescribeEvents_774150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_774171.validator(path, query, header, formData, body)
  let scheme = call_774171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774171.url(scheme.get, call_774171.host, call_774171.base,
                         call_774171.route, valid.getOrDefault("path"))
  result = hook(call_774171, url, valid)

proc call*(call_774172: Call_PostDescribeEvents_774150;
          SourceIdentifier: string = ""; EventCategories: JsonNode = nil;
          Marker: string = ""; StartTime: string = "";
          Action: string = "DescribeEvents"; Duration: int = 0; Filters: JsonNode = nil;
          EndTime: string = ""; MaxRecords: int = 0; Version: string = "2014-10-31";
          SourceType: string = "db-instance"): Recallable =
  ## postDescribeEvents
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ##   SourceIdentifier: string
  ##                   : <p>The identifier of the event source for which events are returned. If not specified, then all sources are included in the response.</p> <p>Constraints:</p> <ul> <li> <p>If <code>SourceIdentifier</code> is provided, <code>SourceType</code> must also be provided.</p> </li> <li> <p>If the source type is <code>DBInstance</code>, a <code>DBInstanceIdentifier</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSecurityGroup</code>, a <code>DBSecurityGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBParameterGroup</code>, a <code>DBParameterGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSnapshot</code>, a <code>DBSnapshotIdentifier</code> must be provided.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   EventCategories: JArray
  ##                  : A list of event categories that trigger notifications for an event notification subscription.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   StartTime: string
  ##            : <p> The beginning of the time interval to retrieve events for, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Action: string (required)
  ##   Duration: int
  ##           : <p>The number of minutes to retrieve events for.</p> <p>Default: 60</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   EndTime: string
  ##          : <p> The end of the time interval for which to retrieve events, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  ##   SourceType: string
  ##             : The event source to retrieve events for. If no value is specified, all events are returned.
  var query_774173 = newJObject()
  var formData_774174 = newJObject()
  add(formData_774174, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_774174.add "EventCategories", EventCategories
  add(formData_774174, "Marker", newJString(Marker))
  add(formData_774174, "StartTime", newJString(StartTime))
  add(query_774173, "Action", newJString(Action))
  add(formData_774174, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_774174.add "Filters", Filters
  add(formData_774174, "EndTime", newJString(EndTime))
  add(formData_774174, "MaxRecords", newJInt(MaxRecords))
  add(query_774173, "Version", newJString(Version))
  add(formData_774174, "SourceType", newJString(SourceType))
  result = call_774172.call(nil, query_774173, nil, formData_774174, nil)

var postDescribeEvents* = Call_PostDescribeEvents_774150(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_774151, base: "/",
    url: url_PostDescribeEvents_774152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_774126 = ref object of OpenApiRestCall_772581
proc url_GetDescribeEvents_774128(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_774127(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##             : The event source to retrieve events for. If no value is specified, all events are returned.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   StartTime: JString
  ##            : <p> The beginning of the time interval to retrieve events for, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   SourceIdentifier: JString
  ##                   : <p>The identifier of the event source for which events are returned. If not specified, then all sources are included in the response.</p> <p>Constraints:</p> <ul> <li> <p>If <code>SourceIdentifier</code> is provided, <code>SourceType</code> must also be provided.</p> </li> <li> <p>If the source type is <code>DBInstance</code>, a <code>DBInstanceIdentifier</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSecurityGroup</code>, a <code>DBSecurityGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBParameterGroup</code>, a <code>DBParameterGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSnapshot</code>, a <code>DBSnapshotIdentifier</code> must be provided.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EventCategories: JArray
  ##                  : A list of event categories that trigger notifications for an event notification subscription.
  ##   Duration: JInt
  ##           : <p>The number of minutes to retrieve events for.</p> <p>Default: 60</p>
  ##   EndTime: JString
  ##          : <p> The end of the time interval for which to retrieve events, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_774129 = query.getOrDefault("SourceType")
  valid_774129 = validateParameter(valid_774129, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_774129 != nil:
    section.add "SourceType", valid_774129
  var valid_774130 = query.getOrDefault("MaxRecords")
  valid_774130 = validateParameter(valid_774130, JInt, required = false, default = nil)
  if valid_774130 != nil:
    section.add "MaxRecords", valid_774130
  var valid_774131 = query.getOrDefault("StartTime")
  valid_774131 = validateParameter(valid_774131, JString, required = false,
                                 default = nil)
  if valid_774131 != nil:
    section.add "StartTime", valid_774131
  var valid_774132 = query.getOrDefault("Filters")
  valid_774132 = validateParameter(valid_774132, JArray, required = false,
                                 default = nil)
  if valid_774132 != nil:
    section.add "Filters", valid_774132
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774133 = query.getOrDefault("Action")
  valid_774133 = validateParameter(valid_774133, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_774133 != nil:
    section.add "Action", valid_774133
  var valid_774134 = query.getOrDefault("SourceIdentifier")
  valid_774134 = validateParameter(valid_774134, JString, required = false,
                                 default = nil)
  if valid_774134 != nil:
    section.add "SourceIdentifier", valid_774134
  var valid_774135 = query.getOrDefault("Marker")
  valid_774135 = validateParameter(valid_774135, JString, required = false,
                                 default = nil)
  if valid_774135 != nil:
    section.add "Marker", valid_774135
  var valid_774136 = query.getOrDefault("EventCategories")
  valid_774136 = validateParameter(valid_774136, JArray, required = false,
                                 default = nil)
  if valid_774136 != nil:
    section.add "EventCategories", valid_774136
  var valid_774137 = query.getOrDefault("Duration")
  valid_774137 = validateParameter(valid_774137, JInt, required = false, default = nil)
  if valid_774137 != nil:
    section.add "Duration", valid_774137
  var valid_774138 = query.getOrDefault("EndTime")
  valid_774138 = validateParameter(valid_774138, JString, required = false,
                                 default = nil)
  if valid_774138 != nil:
    section.add "EndTime", valid_774138
  var valid_774139 = query.getOrDefault("Version")
  valid_774139 = validateParameter(valid_774139, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774139 != nil:
    section.add "Version", valid_774139
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774140 = header.getOrDefault("X-Amz-Date")
  valid_774140 = validateParameter(valid_774140, JString, required = false,
                                 default = nil)
  if valid_774140 != nil:
    section.add "X-Amz-Date", valid_774140
  var valid_774141 = header.getOrDefault("X-Amz-Security-Token")
  valid_774141 = validateParameter(valid_774141, JString, required = false,
                                 default = nil)
  if valid_774141 != nil:
    section.add "X-Amz-Security-Token", valid_774141
  var valid_774142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774142 = validateParameter(valid_774142, JString, required = false,
                                 default = nil)
  if valid_774142 != nil:
    section.add "X-Amz-Content-Sha256", valid_774142
  var valid_774143 = header.getOrDefault("X-Amz-Algorithm")
  valid_774143 = validateParameter(valid_774143, JString, required = false,
                                 default = nil)
  if valid_774143 != nil:
    section.add "X-Amz-Algorithm", valid_774143
  var valid_774144 = header.getOrDefault("X-Amz-Signature")
  valid_774144 = validateParameter(valid_774144, JString, required = false,
                                 default = nil)
  if valid_774144 != nil:
    section.add "X-Amz-Signature", valid_774144
  var valid_774145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774145 = validateParameter(valid_774145, JString, required = false,
                                 default = nil)
  if valid_774145 != nil:
    section.add "X-Amz-SignedHeaders", valid_774145
  var valid_774146 = header.getOrDefault("X-Amz-Credential")
  valid_774146 = validateParameter(valid_774146, JString, required = false,
                                 default = nil)
  if valid_774146 != nil:
    section.add "X-Amz-Credential", valid_774146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774147: Call_GetDescribeEvents_774126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_774147.validator(path, query, header, formData, body)
  let scheme = call_774147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774147.url(scheme.get, call_774147.host, call_774147.base,
                         call_774147.route, valid.getOrDefault("path"))
  result = hook(call_774147, url, valid)

proc call*(call_774148: Call_GetDescribeEvents_774126;
          SourceType: string = "db-instance"; MaxRecords: int = 0;
          StartTime: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEvents"; SourceIdentifier: string = "";
          Marker: string = ""; EventCategories: JsonNode = nil; Duration: int = 0;
          EndTime: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getDescribeEvents
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ##   SourceType: string
  ##             : The event source to retrieve events for. If no value is specified, all events are returned.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   StartTime: string
  ##            : <p> The beginning of the time interval to retrieve events for, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   SourceIdentifier: string
  ##                   : <p>The identifier of the event source for which events are returned. If not specified, then all sources are included in the response.</p> <p>Constraints:</p> <ul> <li> <p>If <code>SourceIdentifier</code> is provided, <code>SourceType</code> must also be provided.</p> </li> <li> <p>If the source type is <code>DBInstance</code>, a <code>DBInstanceIdentifier</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSecurityGroup</code>, a <code>DBSecurityGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBParameterGroup</code>, a <code>DBParameterGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSnapshot</code>, a <code>DBSnapshotIdentifier</code> must be provided.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EventCategories: JArray
  ##                  : A list of event categories that trigger notifications for an event notification subscription.
  ##   Duration: int
  ##           : <p>The number of minutes to retrieve events for.</p> <p>Default: 60</p>
  ##   EndTime: string
  ##          : <p> The end of the time interval for which to retrieve events, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Version: string (required)
  var query_774149 = newJObject()
  add(query_774149, "SourceType", newJString(SourceType))
  add(query_774149, "MaxRecords", newJInt(MaxRecords))
  add(query_774149, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_774149.add "Filters", Filters
  add(query_774149, "Action", newJString(Action))
  add(query_774149, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_774149, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_774149.add "EventCategories", EventCategories
  add(query_774149, "Duration", newJInt(Duration))
  add(query_774149, "EndTime", newJString(EndTime))
  add(query_774149, "Version", newJString(Version))
  result = call_774148.call(nil, query_774149, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_774126(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_774127,
    base: "/", url: url_GetDescribeEvents_774128,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_774198 = ref object of OpenApiRestCall_772581
proc url_PostDescribeOrderableDBInstanceOptions_774200(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOrderableDBInstanceOptions_774199(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
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
      "DescribeOrderableDBInstanceOptions"))
  if valid_774201 != nil:
    section.add "Action", valid_774201
  var valid_774202 = query.getOrDefault("Version")
  valid_774202 = validateParameter(valid_774202, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  ##   Engine: JString (required)
  ##         : The name of the engine to retrieve DB instance options for.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Vpc: JBool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   DBInstanceClass: JString
  ##                  : The DB instance class filter value. Specify this parameter to show only the available offerings that match the specified DB instance class.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: JString
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: JString
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_774210 = formData.getOrDefault("Engine")
  valid_774210 = validateParameter(valid_774210, JString, required = true,
                                 default = nil)
  if valid_774210 != nil:
    section.add "Engine", valid_774210
  var valid_774211 = formData.getOrDefault("Marker")
  valid_774211 = validateParameter(valid_774211, JString, required = false,
                                 default = nil)
  if valid_774211 != nil:
    section.add "Marker", valid_774211
  var valid_774212 = formData.getOrDefault("Vpc")
  valid_774212 = validateParameter(valid_774212, JBool, required = false, default = nil)
  if valid_774212 != nil:
    section.add "Vpc", valid_774212
  var valid_774213 = formData.getOrDefault("DBInstanceClass")
  valid_774213 = validateParameter(valid_774213, JString, required = false,
                                 default = nil)
  if valid_774213 != nil:
    section.add "DBInstanceClass", valid_774213
  var valid_774214 = formData.getOrDefault("Filters")
  valid_774214 = validateParameter(valid_774214, JArray, required = false,
                                 default = nil)
  if valid_774214 != nil:
    section.add "Filters", valid_774214
  var valid_774215 = formData.getOrDefault("LicenseModel")
  valid_774215 = validateParameter(valid_774215, JString, required = false,
                                 default = nil)
  if valid_774215 != nil:
    section.add "LicenseModel", valid_774215
  var valid_774216 = formData.getOrDefault("MaxRecords")
  valid_774216 = validateParameter(valid_774216, JInt, required = false, default = nil)
  if valid_774216 != nil:
    section.add "MaxRecords", valid_774216
  var valid_774217 = formData.getOrDefault("EngineVersion")
  valid_774217 = validateParameter(valid_774217, JString, required = false,
                                 default = nil)
  if valid_774217 != nil:
    section.add "EngineVersion", valid_774217
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774218: Call_PostDescribeOrderableDBInstanceOptions_774198;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_774218.validator(path, query, header, formData, body)
  let scheme = call_774218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774218.url(scheme.get, call_774218.host, call_774218.base,
                         call_774218.route, valid.getOrDefault("path"))
  result = hook(call_774218, url, valid)

proc call*(call_774219: Call_PostDescribeOrderableDBInstanceOptions_774198;
          Engine: string; Marker: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions"; Vpc: bool = false;
          DBInstanceClass: string = ""; Filters: JsonNode = nil;
          LicenseModel: string = ""; MaxRecords: int = 0; EngineVersion: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ## Returns a list of orderable DB instance options for the specified engine.
  ##   Engine: string (required)
  ##         : The name of the engine to retrieve DB instance options for.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Vpc: bool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   DBInstanceClass: string
  ##                  : The DB instance class filter value. Specify this parameter to show only the available offerings that match the specified DB instance class.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: string
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: string
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Version: string (required)
  var query_774220 = newJObject()
  var formData_774221 = newJObject()
  add(formData_774221, "Engine", newJString(Engine))
  add(formData_774221, "Marker", newJString(Marker))
  add(query_774220, "Action", newJString(Action))
  add(formData_774221, "Vpc", newJBool(Vpc))
  add(formData_774221, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_774221.add "Filters", Filters
  add(formData_774221, "LicenseModel", newJString(LicenseModel))
  add(formData_774221, "MaxRecords", newJInt(MaxRecords))
  add(formData_774221, "EngineVersion", newJString(EngineVersion))
  add(query_774220, "Version", newJString(Version))
  result = call_774219.call(nil, query_774220, nil, formData_774221, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_774198(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_774199, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_774200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_774175 = ref object of OpenApiRestCall_772581
proc url_GetDescribeOrderableDBInstanceOptions_774177(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOrderableDBInstanceOptions_774176(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##         : The name of the engine to retrieve DB instance options for.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: JString
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Vpc: JBool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   DBInstanceClass: JString
  ##                  : The DB instance class filter value. Specify this parameter to show only the available offerings that match the specified DB instance class.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EngineVersion: JString
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_774178 = query.getOrDefault("Engine")
  valid_774178 = validateParameter(valid_774178, JString, required = true,
                                 default = nil)
  if valid_774178 != nil:
    section.add "Engine", valid_774178
  var valid_774179 = query.getOrDefault("MaxRecords")
  valid_774179 = validateParameter(valid_774179, JInt, required = false, default = nil)
  if valid_774179 != nil:
    section.add "MaxRecords", valid_774179
  var valid_774180 = query.getOrDefault("Filters")
  valid_774180 = validateParameter(valid_774180, JArray, required = false,
                                 default = nil)
  if valid_774180 != nil:
    section.add "Filters", valid_774180
  var valid_774181 = query.getOrDefault("LicenseModel")
  valid_774181 = validateParameter(valid_774181, JString, required = false,
                                 default = nil)
  if valid_774181 != nil:
    section.add "LicenseModel", valid_774181
  var valid_774182 = query.getOrDefault("Vpc")
  valid_774182 = validateParameter(valid_774182, JBool, required = false, default = nil)
  if valid_774182 != nil:
    section.add "Vpc", valid_774182
  var valid_774183 = query.getOrDefault("DBInstanceClass")
  valid_774183 = validateParameter(valid_774183, JString, required = false,
                                 default = nil)
  if valid_774183 != nil:
    section.add "DBInstanceClass", valid_774183
  var valid_774184 = query.getOrDefault("Action")
  valid_774184 = validateParameter(valid_774184, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_774184 != nil:
    section.add "Action", valid_774184
  var valid_774185 = query.getOrDefault("Marker")
  valid_774185 = validateParameter(valid_774185, JString, required = false,
                                 default = nil)
  if valid_774185 != nil:
    section.add "Marker", valid_774185
  var valid_774186 = query.getOrDefault("EngineVersion")
  valid_774186 = validateParameter(valid_774186, JString, required = false,
                                 default = nil)
  if valid_774186 != nil:
    section.add "EngineVersion", valid_774186
  var valid_774187 = query.getOrDefault("Version")
  valid_774187 = validateParameter(valid_774187, JString, required = true,
                                 default = newJString("2014-10-31"))
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

proc call*(call_774195: Call_GetDescribeOrderableDBInstanceOptions_774175;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_774195.validator(path, query, header, formData, body)
  let scheme = call_774195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774195.url(scheme.get, call_774195.host, call_774195.base,
                         call_774195.route, valid.getOrDefault("path"))
  result = hook(call_774195, url, valid)

proc call*(call_774196: Call_GetDescribeOrderableDBInstanceOptions_774175;
          Engine: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          LicenseModel: string = ""; Vpc: bool = false; DBInstanceClass: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Marker: string = ""; EngineVersion: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ## Returns a list of orderable DB instance options for the specified engine.
  ##   Engine: string (required)
  ##         : The name of the engine to retrieve DB instance options for.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: string
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Vpc: bool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   DBInstanceClass: string
  ##                  : The DB instance class filter value. Specify this parameter to show only the available offerings that match the specified DB instance class.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EngineVersion: string
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Version: string (required)
  var query_774197 = newJObject()
  add(query_774197, "Engine", newJString(Engine))
  add(query_774197, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774197.add "Filters", Filters
  add(query_774197, "LicenseModel", newJString(LicenseModel))
  add(query_774197, "Vpc", newJBool(Vpc))
  add(query_774197, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774197, "Action", newJString(Action))
  add(query_774197, "Marker", newJString(Marker))
  add(query_774197, "EngineVersion", newJString(EngineVersion))
  add(query_774197, "Version", newJString(Version))
  result = call_774196.call(nil, query_774197, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_774175(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_774176, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_774177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePendingMaintenanceActions_774241 = ref object of OpenApiRestCall_772581
proc url_PostDescribePendingMaintenanceActions_774243(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribePendingMaintenanceActions_774242(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
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
      "DescribePendingMaintenanceActions"))
  if valid_774244 != nil:
    section.add "Action", valid_774244
  var valid_774245 = query.getOrDefault("Version")
  valid_774245 = validateParameter(valid_774245, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   ResourceIdentifier: JString
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the DB clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_774253 = formData.getOrDefault("Marker")
  valid_774253 = validateParameter(valid_774253, JString, required = false,
                                 default = nil)
  if valid_774253 != nil:
    section.add "Marker", valid_774253
  var valid_774254 = formData.getOrDefault("ResourceIdentifier")
  valid_774254 = validateParameter(valid_774254, JString, required = false,
                                 default = nil)
  if valid_774254 != nil:
    section.add "ResourceIdentifier", valid_774254
  var valid_774255 = formData.getOrDefault("Filters")
  valid_774255 = validateParameter(valid_774255, JArray, required = false,
                                 default = nil)
  if valid_774255 != nil:
    section.add "Filters", valid_774255
  var valid_774256 = formData.getOrDefault("MaxRecords")
  valid_774256 = validateParameter(valid_774256, JInt, required = false, default = nil)
  if valid_774256 != nil:
    section.add "MaxRecords", valid_774256
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774257: Call_PostDescribePendingMaintenanceActions_774241;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_774257.validator(path, query, header, formData, body)
  let scheme = call_774257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774257.url(scheme.get, call_774257.host, call_774257.base,
                         call_774257.route, valid.getOrDefault("path"))
  result = hook(call_774257, url, valid)

proc call*(call_774258: Call_PostDescribePendingMaintenanceActions_774241;
          Marker: string = ""; Action: string = "DescribePendingMaintenanceActions";
          ResourceIdentifier: string = ""; Filters: JsonNode = nil; MaxRecords: int = 0;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribePendingMaintenanceActions
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   ResourceIdentifier: string
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the DB clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_774259 = newJObject()
  var formData_774260 = newJObject()
  add(formData_774260, "Marker", newJString(Marker))
  add(query_774259, "Action", newJString(Action))
  add(formData_774260, "ResourceIdentifier", newJString(ResourceIdentifier))
  if Filters != nil:
    formData_774260.add "Filters", Filters
  add(formData_774260, "MaxRecords", newJInt(MaxRecords))
  add(query_774259, "Version", newJString(Version))
  result = call_774258.call(nil, query_774259, nil, formData_774260, nil)

var postDescribePendingMaintenanceActions* = Call_PostDescribePendingMaintenanceActions_774241(
    name: "postDescribePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_PostDescribePendingMaintenanceActions_774242, base: "/",
    url: url_PostDescribePendingMaintenanceActions_774243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePendingMaintenanceActions_774222 = ref object of OpenApiRestCall_772581
proc url_GetDescribePendingMaintenanceActions_774224(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribePendingMaintenanceActions_774223(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the DB clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   ResourceIdentifier: JString
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_774225 = query.getOrDefault("MaxRecords")
  valid_774225 = validateParameter(valid_774225, JInt, required = false, default = nil)
  if valid_774225 != nil:
    section.add "MaxRecords", valid_774225
  var valid_774226 = query.getOrDefault("Filters")
  valid_774226 = validateParameter(valid_774226, JArray, required = false,
                                 default = nil)
  if valid_774226 != nil:
    section.add "Filters", valid_774226
  var valid_774227 = query.getOrDefault("ResourceIdentifier")
  valid_774227 = validateParameter(valid_774227, JString, required = false,
                                 default = nil)
  if valid_774227 != nil:
    section.add "ResourceIdentifier", valid_774227
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774228 = query.getOrDefault("Action")
  valid_774228 = validateParameter(valid_774228, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_774228 != nil:
    section.add "Action", valid_774228
  var valid_774229 = query.getOrDefault("Marker")
  valid_774229 = validateParameter(valid_774229, JString, required = false,
                                 default = nil)
  if valid_774229 != nil:
    section.add "Marker", valid_774229
  var valid_774230 = query.getOrDefault("Version")
  valid_774230 = validateParameter(valid_774230, JString, required = true,
                                 default = newJString("2014-10-31"))
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

proc call*(call_774238: Call_GetDescribePendingMaintenanceActions_774222;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_774238.validator(path, query, header, formData, body)
  let scheme = call_774238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774238.url(scheme.get, call_774238.host, call_774238.base,
                         call_774238.route, valid.getOrDefault("path"))
  result = hook(call_774238, url, valid)

proc call*(call_774239: Call_GetDescribePendingMaintenanceActions_774222;
          MaxRecords: int = 0; Filters: JsonNode = nil; ResourceIdentifier: string = "";
          Action: string = "DescribePendingMaintenanceActions"; Marker: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribePendingMaintenanceActions
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the DB clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   ResourceIdentifier: string
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  var query_774240 = newJObject()
  add(query_774240, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774240.add "Filters", Filters
  add(query_774240, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_774240, "Action", newJString(Action))
  add(query_774240, "Marker", newJString(Marker))
  add(query_774240, "Version", newJString(Version))
  result = call_774239.call(nil, query_774240, nil, nil, nil)

var getDescribePendingMaintenanceActions* = Call_GetDescribePendingMaintenanceActions_774222(
    name: "getDescribePendingMaintenanceActions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_GetDescribePendingMaintenanceActions_774223, base: "/",
    url: url_GetDescribePendingMaintenanceActions_774224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostFailoverDBCluster_774278 = ref object of OpenApiRestCall_772581
proc url_PostFailoverDBCluster_774280(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostFailoverDBCluster_774279(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
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
  valid_774281 = validateParameter(valid_774281, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_774281 != nil:
    section.add "Action", valid_774281
  var valid_774282 = query.getOrDefault("Version")
  valid_774282 = validateParameter(valid_774282, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_774290 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_774290 = validateParameter(valid_774290, JString, required = false,
                                 default = nil)
  if valid_774290 != nil:
    section.add "TargetDBInstanceIdentifier", valid_774290
  var valid_774291 = formData.getOrDefault("DBClusterIdentifier")
  valid_774291 = validateParameter(valid_774291, JString, required = false,
                                 default = nil)
  if valid_774291 != nil:
    section.add "DBClusterIdentifier", valid_774291
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774292: Call_PostFailoverDBCluster_774278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_774292.validator(path, query, header, formData, body)
  let scheme = call_774292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774292.url(scheme.get, call_774292.host, call_774292.base,
                         call_774292.route, valid.getOrDefault("path"))
  result = hook(call_774292, url, valid)

proc call*(call_774293: Call_PostFailoverDBCluster_774278;
          Action: string = "FailoverDBCluster";
          TargetDBInstanceIdentifier: string = ""; DBClusterIdentifier: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postFailoverDBCluster
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ##   Action: string (required)
  ##   TargetDBInstanceIdentifier: string
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_774294 = newJObject()
  var formData_774295 = newJObject()
  add(query_774294, "Action", newJString(Action))
  add(formData_774295, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_774295, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_774294, "Version", newJString(Version))
  result = call_774293.call(nil, query_774294, nil, formData_774295, nil)

var postFailoverDBCluster* = Call_PostFailoverDBCluster_774278(
    name: "postFailoverDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_PostFailoverDBCluster_774279, base: "/",
    url: url_PostFailoverDBCluster_774280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFailoverDBCluster_774261 = ref object of OpenApiRestCall_772581
proc url_GetFailoverDBCluster_774263(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetFailoverDBCluster_774262(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_774264 = query.getOrDefault("DBClusterIdentifier")
  valid_774264 = validateParameter(valid_774264, JString, required = false,
                                 default = nil)
  if valid_774264 != nil:
    section.add "DBClusterIdentifier", valid_774264
  var valid_774265 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_774265 = validateParameter(valid_774265, JString, required = false,
                                 default = nil)
  if valid_774265 != nil:
    section.add "TargetDBInstanceIdentifier", valid_774265
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774266 = query.getOrDefault("Action")
  valid_774266 = validateParameter(valid_774266, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_774266 != nil:
    section.add "Action", valid_774266
  var valid_774267 = query.getOrDefault("Version")
  valid_774267 = validateParameter(valid_774267, JString, required = true,
                                 default = newJString("2014-10-31"))
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

proc call*(call_774275: Call_GetFailoverDBCluster_774261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_774275.validator(path, query, header, formData, body)
  let scheme = call_774275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774275.url(scheme.get, call_774275.host, call_774275.base,
                         call_774275.route, valid.getOrDefault("path"))
  result = hook(call_774275, url, valid)

proc call*(call_774276: Call_GetFailoverDBCluster_774261;
          DBClusterIdentifier: string = ""; TargetDBInstanceIdentifier: string = "";
          Action: string = "FailoverDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getFailoverDBCluster
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   TargetDBInstanceIdentifier: string
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774277 = newJObject()
  add(query_774277, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_774277, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_774277, "Action", newJString(Action))
  add(query_774277, "Version", newJString(Version))
  result = call_774276.call(nil, query_774277, nil, nil, nil)

var getFailoverDBCluster* = Call_GetFailoverDBCluster_774261(
    name: "getFailoverDBCluster", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_GetFailoverDBCluster_774262, base: "/",
    url: url_GetFailoverDBCluster_774263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_774313 = ref object of OpenApiRestCall_772581
proc url_PostListTagsForResource_774315(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_774314(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774316 = query.getOrDefault("Action")
  valid_774316 = validateParameter(valid_774316, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_774316 != nil:
    section.add "Action", valid_774316
  var valid_774317 = query.getOrDefault("Version")
  valid_774317 = validateParameter(valid_774317, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774317 != nil:
    section.add "Version", valid_774317
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774318 = header.getOrDefault("X-Amz-Date")
  valid_774318 = validateParameter(valid_774318, JString, required = false,
                                 default = nil)
  if valid_774318 != nil:
    section.add "X-Amz-Date", valid_774318
  var valid_774319 = header.getOrDefault("X-Amz-Security-Token")
  valid_774319 = validateParameter(valid_774319, JString, required = false,
                                 default = nil)
  if valid_774319 != nil:
    section.add "X-Amz-Security-Token", valid_774319
  var valid_774320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774320 = validateParameter(valid_774320, JString, required = false,
                                 default = nil)
  if valid_774320 != nil:
    section.add "X-Amz-Content-Sha256", valid_774320
  var valid_774321 = header.getOrDefault("X-Amz-Algorithm")
  valid_774321 = validateParameter(valid_774321, JString, required = false,
                                 default = nil)
  if valid_774321 != nil:
    section.add "X-Amz-Algorithm", valid_774321
  var valid_774322 = header.getOrDefault("X-Amz-Signature")
  valid_774322 = validateParameter(valid_774322, JString, required = false,
                                 default = nil)
  if valid_774322 != nil:
    section.add "X-Amz-Signature", valid_774322
  var valid_774323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774323 = validateParameter(valid_774323, JString, required = false,
                                 default = nil)
  if valid_774323 != nil:
    section.add "X-Amz-SignedHeaders", valid_774323
  var valid_774324 = header.getOrDefault("X-Amz-Credential")
  valid_774324 = validateParameter(valid_774324, JString, required = false,
                                 default = nil)
  if valid_774324 != nil:
    section.add "X-Amz-Credential", valid_774324
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  var valid_774325 = formData.getOrDefault("Filters")
  valid_774325 = validateParameter(valid_774325, JArray, required = false,
                                 default = nil)
  if valid_774325 != nil:
    section.add "Filters", valid_774325
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_774326 = formData.getOrDefault("ResourceName")
  valid_774326 = validateParameter(valid_774326, JString, required = true,
                                 default = nil)
  if valid_774326 != nil:
    section.add "ResourceName", valid_774326
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774327: Call_PostListTagsForResource_774313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_774327.validator(path, query, header, formData, body)
  let scheme = call_774327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774327.url(scheme.get, call_774327.host, call_774327.base,
                         call_774327.route, valid.getOrDefault("path"))
  result = hook(call_774327, url, valid)

proc call*(call_774328: Call_PostListTagsForResource_774313; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postListTagsForResource
  ## Lists all tags on an Amazon DocumentDB resource.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  ##   Version: string (required)
  var query_774329 = newJObject()
  var formData_774330 = newJObject()
  add(query_774329, "Action", newJString(Action))
  if Filters != nil:
    formData_774330.add "Filters", Filters
  add(formData_774330, "ResourceName", newJString(ResourceName))
  add(query_774329, "Version", newJString(Version))
  result = call_774328.call(nil, query_774329, nil, formData_774330, nil)

var postListTagsForResource* = Call_PostListTagsForResource_774313(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_774314, base: "/",
    url: url_PostListTagsForResource_774315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_774296 = ref object of OpenApiRestCall_772581
proc url_GetListTagsForResource_774298(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_774297(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_774299 = query.getOrDefault("Filters")
  valid_774299 = validateParameter(valid_774299, JArray, required = false,
                                 default = nil)
  if valid_774299 != nil:
    section.add "Filters", valid_774299
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_774300 = query.getOrDefault("ResourceName")
  valid_774300 = validateParameter(valid_774300, JString, required = true,
                                 default = nil)
  if valid_774300 != nil:
    section.add "ResourceName", valid_774300
  var valid_774301 = query.getOrDefault("Action")
  valid_774301 = validateParameter(valid_774301, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_774301 != nil:
    section.add "Action", valid_774301
  var valid_774302 = query.getOrDefault("Version")
  valid_774302 = validateParameter(valid_774302, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774302 != nil:
    section.add "Version", valid_774302
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774303 = header.getOrDefault("X-Amz-Date")
  valid_774303 = validateParameter(valid_774303, JString, required = false,
                                 default = nil)
  if valid_774303 != nil:
    section.add "X-Amz-Date", valid_774303
  var valid_774304 = header.getOrDefault("X-Amz-Security-Token")
  valid_774304 = validateParameter(valid_774304, JString, required = false,
                                 default = nil)
  if valid_774304 != nil:
    section.add "X-Amz-Security-Token", valid_774304
  var valid_774305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774305 = validateParameter(valid_774305, JString, required = false,
                                 default = nil)
  if valid_774305 != nil:
    section.add "X-Amz-Content-Sha256", valid_774305
  var valid_774306 = header.getOrDefault("X-Amz-Algorithm")
  valid_774306 = validateParameter(valid_774306, JString, required = false,
                                 default = nil)
  if valid_774306 != nil:
    section.add "X-Amz-Algorithm", valid_774306
  var valid_774307 = header.getOrDefault("X-Amz-Signature")
  valid_774307 = validateParameter(valid_774307, JString, required = false,
                                 default = nil)
  if valid_774307 != nil:
    section.add "X-Amz-Signature", valid_774307
  var valid_774308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774308 = validateParameter(valid_774308, JString, required = false,
                                 default = nil)
  if valid_774308 != nil:
    section.add "X-Amz-SignedHeaders", valid_774308
  var valid_774309 = header.getOrDefault("X-Amz-Credential")
  valid_774309 = validateParameter(valid_774309, JString, required = false,
                                 default = nil)
  if valid_774309 != nil:
    section.add "X-Amz-Credential", valid_774309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774310: Call_GetListTagsForResource_774296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_774310.validator(path, query, header, formData, body)
  let scheme = call_774310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774310.url(scheme.get, call_774310.host, call_774310.base,
                         call_774310.route, valid.getOrDefault("path"))
  result = hook(call_774310, url, valid)

proc call*(call_774311: Call_GetListTagsForResource_774296; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2014-10-31"): Recallable =
  ## getListTagsForResource
  ## Lists all tags on an Amazon DocumentDB resource.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774312 = newJObject()
  if Filters != nil:
    query_774312.add "Filters", Filters
  add(query_774312, "ResourceName", newJString(ResourceName))
  add(query_774312, "Action", newJString(Action))
  add(query_774312, "Version", newJString(Version))
  result = call_774311.call(nil, query_774312, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_774296(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_774297, base: "/",
    url: url_GetListTagsForResource_774298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBCluster_774360 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBCluster_774362(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBCluster_774361(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774363 = query.getOrDefault("Action")
  valid_774363 = validateParameter(valid_774363, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_774363 != nil:
    section.add "Action", valid_774363
  var valid_774364 = query.getOrDefault("Version")
  valid_774364 = validateParameter(valid_774364, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774364 != nil:
    section.add "Version", valid_774364
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774365 = header.getOrDefault("X-Amz-Date")
  valid_774365 = validateParameter(valid_774365, JString, required = false,
                                 default = nil)
  if valid_774365 != nil:
    section.add "X-Amz-Date", valid_774365
  var valid_774366 = header.getOrDefault("X-Amz-Security-Token")
  valid_774366 = validateParameter(valid_774366, JString, required = false,
                                 default = nil)
  if valid_774366 != nil:
    section.add "X-Amz-Security-Token", valid_774366
  var valid_774367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774367 = validateParameter(valid_774367, JString, required = false,
                                 default = nil)
  if valid_774367 != nil:
    section.add "X-Amz-Content-Sha256", valid_774367
  var valid_774368 = header.getOrDefault("X-Amz-Algorithm")
  valid_774368 = validateParameter(valid_774368, JString, required = false,
                                 default = nil)
  if valid_774368 != nil:
    section.add "X-Amz-Algorithm", valid_774368
  var valid_774369 = header.getOrDefault("X-Amz-Signature")
  valid_774369 = validateParameter(valid_774369, JString, required = false,
                                 default = nil)
  if valid_774369 != nil:
    section.add "X-Amz-Signature", valid_774369
  var valid_774370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774370 = validateParameter(valid_774370, JString, required = false,
                                 default = nil)
  if valid_774370 != nil:
    section.add "X-Amz-SignedHeaders", valid_774370
  var valid_774371 = header.getOrDefault("X-Amz-Credential")
  valid_774371 = validateParameter(valid_774371, JString, required = false,
                                 default = nil)
  if valid_774371 != nil:
    section.add "X-Amz-Credential", valid_774371
  result.add "header", section
  ## parameters in `formData` object:
  ##   CloudwatchLogsExportConfiguration.EnableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to enable.
  ##   ApplyImmediately: JBool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB cluster. If this parameter is set to <code>false</code>, changes to the DB cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   Port: JInt
  ##       : <p>The port number on which the DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original DB cluster.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the DB cluster will belong to.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   MasterUserPassword: JString
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   NewDBClusterIdentifier: JString
  ##                         : <p>The new DB cluster identifier for the DB cluster when renaming a DB cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   CloudwatchLogsExportConfiguration.DisableLogTypes: JArray
  ##                                                    : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to disable.
  ##   DBClusterParameterGroupName: JString
  ##                              : The name of the DB cluster parameter group to use for the DB cluster.
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   EngineVersion: JString
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  section = newJObject()
  var valid_774372 = formData.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_774372 = validateParameter(valid_774372, JArray, required = false,
                                 default = nil)
  if valid_774372 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_774372
  var valid_774373 = formData.getOrDefault("ApplyImmediately")
  valid_774373 = validateParameter(valid_774373, JBool, required = false, default = nil)
  if valid_774373 != nil:
    section.add "ApplyImmediately", valid_774373
  var valid_774374 = formData.getOrDefault("Port")
  valid_774374 = validateParameter(valid_774374, JInt, required = false, default = nil)
  if valid_774374 != nil:
    section.add "Port", valid_774374
  var valid_774375 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_774375 = validateParameter(valid_774375, JArray, required = false,
                                 default = nil)
  if valid_774375 != nil:
    section.add "VpcSecurityGroupIds", valid_774375
  var valid_774376 = formData.getOrDefault("BackupRetentionPeriod")
  valid_774376 = validateParameter(valid_774376, JInt, required = false, default = nil)
  if valid_774376 != nil:
    section.add "BackupRetentionPeriod", valid_774376
  var valid_774377 = formData.getOrDefault("MasterUserPassword")
  valid_774377 = validateParameter(valid_774377, JString, required = false,
                                 default = nil)
  if valid_774377 != nil:
    section.add "MasterUserPassword", valid_774377
  var valid_774378 = formData.getOrDefault("DeletionProtection")
  valid_774378 = validateParameter(valid_774378, JBool, required = false, default = nil)
  if valid_774378 != nil:
    section.add "DeletionProtection", valid_774378
  var valid_774379 = formData.getOrDefault("NewDBClusterIdentifier")
  valid_774379 = validateParameter(valid_774379, JString, required = false,
                                 default = nil)
  if valid_774379 != nil:
    section.add "NewDBClusterIdentifier", valid_774379
  var valid_774380 = formData.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_774380 = validateParameter(valid_774380, JArray, required = false,
                                 default = nil)
  if valid_774380 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_774380
  var valid_774381 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_774381 = validateParameter(valid_774381, JString, required = false,
                                 default = nil)
  if valid_774381 != nil:
    section.add "DBClusterParameterGroupName", valid_774381
  var valid_774382 = formData.getOrDefault("PreferredBackupWindow")
  valid_774382 = validateParameter(valid_774382, JString, required = false,
                                 default = nil)
  if valid_774382 != nil:
    section.add "PreferredBackupWindow", valid_774382
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_774383 = formData.getOrDefault("DBClusterIdentifier")
  valid_774383 = validateParameter(valid_774383, JString, required = true,
                                 default = nil)
  if valid_774383 != nil:
    section.add "DBClusterIdentifier", valid_774383
  var valid_774384 = formData.getOrDefault("EngineVersion")
  valid_774384 = validateParameter(valid_774384, JString, required = false,
                                 default = nil)
  if valid_774384 != nil:
    section.add "EngineVersion", valid_774384
  var valid_774385 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_774385 = validateParameter(valid_774385, JString, required = false,
                                 default = nil)
  if valid_774385 != nil:
    section.add "PreferredMaintenanceWindow", valid_774385
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774386: Call_PostModifyDBCluster_774360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_774386.validator(path, query, header, formData, body)
  let scheme = call_774386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774386.url(scheme.get, call_774386.host, call_774386.base,
                         call_774386.route, valid.getOrDefault("path"))
  result = hook(call_774386, url, valid)

proc call*(call_774387: Call_PostModifyDBCluster_774360;
          DBClusterIdentifier: string;
          CloudwatchLogsExportConfigurationEnableLogTypes: JsonNode = nil;
          ApplyImmediately: bool = false; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          MasterUserPassword: string = ""; DeletionProtection: bool = false;
          NewDBClusterIdentifier: string = "";
          CloudwatchLogsExportConfigurationDisableLogTypes: JsonNode = nil;
          Action: string = "ModifyDBCluster";
          DBClusterParameterGroupName: string = "";
          PreferredBackupWindow: string = ""; EngineVersion: string = "";
          Version: string = "2014-10-31"; PreferredMaintenanceWindow: string = ""): Recallable =
  ## postModifyDBCluster
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ##   CloudwatchLogsExportConfigurationEnableLogTypes: JArray
  ##                                                  : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to enable.
  ##   ApplyImmediately: bool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB cluster. If this parameter is set to <code>false</code>, changes to the DB cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   Port: int
  ##       : <p>The port number on which the DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original DB cluster.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the DB cluster will belong to.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   MasterUserPassword: string
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   NewDBClusterIdentifier: string
  ##                         : <p>The new DB cluster identifier for the DB cluster when renaming a DB cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   CloudwatchLogsExportConfigurationDisableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to disable.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string
  ##                              : The name of the DB cluster parameter group to use for the DB cluster.
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   EngineVersion: string
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  var query_774388 = newJObject()
  var formData_774389 = newJObject()
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    formData_774389.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                       CloudwatchLogsExportConfigurationEnableLogTypes
  add(formData_774389, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_774389, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_774389.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_774389, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_774389, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_774389, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_774389, "NewDBClusterIdentifier",
      newJString(NewDBClusterIdentifier))
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    formData_774389.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                       CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_774388, "Action", newJString(Action))
  add(formData_774389, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_774389, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_774389, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_774389, "EngineVersion", newJString(EngineVersion))
  add(query_774388, "Version", newJString(Version))
  add(formData_774389, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_774387.call(nil, query_774388, nil, formData_774389, nil)

var postModifyDBCluster* = Call_PostModifyDBCluster_774360(
    name: "postModifyDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBCluster",
    validator: validate_PostModifyDBCluster_774361, base: "/",
    url: url_PostModifyDBCluster_774362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBCluster_774331 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBCluster_774333(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBCluster_774332(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: JString
  ##                              : The name of the DB cluster parameter group to use for the DB cluster.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   MasterUserPassword: JString
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
  ##   CloudwatchLogsExportConfiguration.EnableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to enable.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the DB cluster will belong to.
  ##   CloudwatchLogsExportConfiguration.DisableLogTypes: JArray
  ##                                                    : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to disable.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   NewDBClusterIdentifier: JString
  ##                         : <p>The new DB cluster identifier for the DB cluster when renaming a DB cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: JString (required)
  ##   EngineVersion: JString
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Port: JInt
  ##       : <p>The port number on which the DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original DB cluster.</p>
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Version: JString (required)
  ##   ApplyImmediately: JBool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB cluster. If this parameter is set to <code>false</code>, changes to the DB cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_774334 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_774334 = validateParameter(valid_774334, JString, required = false,
                                 default = nil)
  if valid_774334 != nil:
    section.add "PreferredMaintenanceWindow", valid_774334
  var valid_774335 = query.getOrDefault("DBClusterParameterGroupName")
  valid_774335 = validateParameter(valid_774335, JString, required = false,
                                 default = nil)
  if valid_774335 != nil:
    section.add "DBClusterParameterGroupName", valid_774335
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_774336 = query.getOrDefault("DBClusterIdentifier")
  valid_774336 = validateParameter(valid_774336, JString, required = true,
                                 default = nil)
  if valid_774336 != nil:
    section.add "DBClusterIdentifier", valid_774336
  var valid_774337 = query.getOrDefault("MasterUserPassword")
  valid_774337 = validateParameter(valid_774337, JString, required = false,
                                 default = nil)
  if valid_774337 != nil:
    section.add "MasterUserPassword", valid_774337
  var valid_774338 = query.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_774338 = validateParameter(valid_774338, JArray, required = false,
                                 default = nil)
  if valid_774338 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_774338
  var valid_774339 = query.getOrDefault("VpcSecurityGroupIds")
  valid_774339 = validateParameter(valid_774339, JArray, required = false,
                                 default = nil)
  if valid_774339 != nil:
    section.add "VpcSecurityGroupIds", valid_774339
  var valid_774340 = query.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_774340 = validateParameter(valid_774340, JArray, required = false,
                                 default = nil)
  if valid_774340 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_774340
  var valid_774341 = query.getOrDefault("BackupRetentionPeriod")
  valid_774341 = validateParameter(valid_774341, JInt, required = false, default = nil)
  if valid_774341 != nil:
    section.add "BackupRetentionPeriod", valid_774341
  var valid_774342 = query.getOrDefault("NewDBClusterIdentifier")
  valid_774342 = validateParameter(valid_774342, JString, required = false,
                                 default = nil)
  if valid_774342 != nil:
    section.add "NewDBClusterIdentifier", valid_774342
  var valid_774343 = query.getOrDefault("DeletionProtection")
  valid_774343 = validateParameter(valid_774343, JBool, required = false, default = nil)
  if valid_774343 != nil:
    section.add "DeletionProtection", valid_774343
  var valid_774344 = query.getOrDefault("Action")
  valid_774344 = validateParameter(valid_774344, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_774344 != nil:
    section.add "Action", valid_774344
  var valid_774345 = query.getOrDefault("EngineVersion")
  valid_774345 = validateParameter(valid_774345, JString, required = false,
                                 default = nil)
  if valid_774345 != nil:
    section.add "EngineVersion", valid_774345
  var valid_774346 = query.getOrDefault("Port")
  valid_774346 = validateParameter(valid_774346, JInt, required = false, default = nil)
  if valid_774346 != nil:
    section.add "Port", valid_774346
  var valid_774347 = query.getOrDefault("PreferredBackupWindow")
  valid_774347 = validateParameter(valid_774347, JString, required = false,
                                 default = nil)
  if valid_774347 != nil:
    section.add "PreferredBackupWindow", valid_774347
  var valid_774348 = query.getOrDefault("Version")
  valid_774348 = validateParameter(valid_774348, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774348 != nil:
    section.add "Version", valid_774348
  var valid_774349 = query.getOrDefault("ApplyImmediately")
  valid_774349 = validateParameter(valid_774349, JBool, required = false, default = nil)
  if valid_774349 != nil:
    section.add "ApplyImmediately", valid_774349
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774350 = header.getOrDefault("X-Amz-Date")
  valid_774350 = validateParameter(valid_774350, JString, required = false,
                                 default = nil)
  if valid_774350 != nil:
    section.add "X-Amz-Date", valid_774350
  var valid_774351 = header.getOrDefault("X-Amz-Security-Token")
  valid_774351 = validateParameter(valid_774351, JString, required = false,
                                 default = nil)
  if valid_774351 != nil:
    section.add "X-Amz-Security-Token", valid_774351
  var valid_774352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774352 = validateParameter(valid_774352, JString, required = false,
                                 default = nil)
  if valid_774352 != nil:
    section.add "X-Amz-Content-Sha256", valid_774352
  var valid_774353 = header.getOrDefault("X-Amz-Algorithm")
  valid_774353 = validateParameter(valid_774353, JString, required = false,
                                 default = nil)
  if valid_774353 != nil:
    section.add "X-Amz-Algorithm", valid_774353
  var valid_774354 = header.getOrDefault("X-Amz-Signature")
  valid_774354 = validateParameter(valid_774354, JString, required = false,
                                 default = nil)
  if valid_774354 != nil:
    section.add "X-Amz-Signature", valid_774354
  var valid_774355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774355 = validateParameter(valid_774355, JString, required = false,
                                 default = nil)
  if valid_774355 != nil:
    section.add "X-Amz-SignedHeaders", valid_774355
  var valid_774356 = header.getOrDefault("X-Amz-Credential")
  valid_774356 = validateParameter(valid_774356, JString, required = false,
                                 default = nil)
  if valid_774356 != nil:
    section.add "X-Amz-Credential", valid_774356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774357: Call_GetModifyDBCluster_774331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_774357.validator(path, query, header, formData, body)
  let scheme = call_774357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774357.url(scheme.get, call_774357.host, call_774357.base,
                         call_774357.route, valid.getOrDefault("path"))
  result = hook(call_774357, url, valid)

proc call*(call_774358: Call_GetModifyDBCluster_774331;
          DBClusterIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBClusterParameterGroupName: string = ""; MasterUserPassword: string = "";
          CloudwatchLogsExportConfigurationEnableLogTypes: JsonNode = nil;
          VpcSecurityGroupIds: JsonNode = nil;
          CloudwatchLogsExportConfigurationDisableLogTypes: JsonNode = nil;
          BackupRetentionPeriod: int = 0; NewDBClusterIdentifier: string = "";
          DeletionProtection: bool = false; Action: string = "ModifyDBCluster";
          EngineVersion: string = ""; Port: int = 0; PreferredBackupWindow: string = "";
          Version: string = "2014-10-31"; ApplyImmediately: bool = false): Recallable =
  ## getModifyDBCluster
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: string
  ##                              : The name of the DB cluster parameter group to use for the DB cluster.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   MasterUserPassword: string
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
  ##   CloudwatchLogsExportConfigurationEnableLogTypes: JArray
  ##                                                  : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to enable.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the DB cluster will belong to.
  ##   CloudwatchLogsExportConfigurationDisableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to disable.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   NewDBClusterIdentifier: string
  ##                         : <p>The new DB cluster identifier for the DB cluster when renaming a DB cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: string (required)
  ##   EngineVersion: string
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Port: int
  ##       : <p>The port number on which the DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original DB cluster.</p>
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB cluster. If this parameter is set to <code>false</code>, changes to the DB cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  var query_774359 = newJObject()
  add(query_774359, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_774359, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_774359, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_774359, "MasterUserPassword", newJString(MasterUserPassword))
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    query_774359.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                    CloudwatchLogsExportConfigurationEnableLogTypes
  if VpcSecurityGroupIds != nil:
    query_774359.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    query_774359.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                    CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_774359, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_774359, "NewDBClusterIdentifier", newJString(NewDBClusterIdentifier))
  add(query_774359, "DeletionProtection", newJBool(DeletionProtection))
  add(query_774359, "Action", newJString(Action))
  add(query_774359, "EngineVersion", newJString(EngineVersion))
  add(query_774359, "Port", newJInt(Port))
  add(query_774359, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_774359, "Version", newJString(Version))
  add(query_774359, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_774358.call(nil, query_774359, nil, nil, nil)

var getModifyDBCluster* = Call_GetModifyDBCluster_774331(
    name: "getModifyDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=ModifyDBCluster", validator: validate_GetModifyDBCluster_774332,
    base: "/", url: url_GetModifyDBCluster_774333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterParameterGroup_774407 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBClusterParameterGroup_774409(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBClusterParameterGroup_774408(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774410 = query.getOrDefault("Action")
  valid_774410 = validateParameter(valid_774410, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_774410 != nil:
    section.add "Action", valid_774410
  var valid_774411 = query.getOrDefault("Version")
  valid_774411 = validateParameter(valid_774411, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774411 != nil:
    section.add "Version", valid_774411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774412 = header.getOrDefault("X-Amz-Date")
  valid_774412 = validateParameter(valid_774412, JString, required = false,
                                 default = nil)
  if valid_774412 != nil:
    section.add "X-Amz-Date", valid_774412
  var valid_774413 = header.getOrDefault("X-Amz-Security-Token")
  valid_774413 = validateParameter(valid_774413, JString, required = false,
                                 default = nil)
  if valid_774413 != nil:
    section.add "X-Amz-Security-Token", valid_774413
  var valid_774414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774414 = validateParameter(valid_774414, JString, required = false,
                                 default = nil)
  if valid_774414 != nil:
    section.add "X-Amz-Content-Sha256", valid_774414
  var valid_774415 = header.getOrDefault("X-Amz-Algorithm")
  valid_774415 = validateParameter(valid_774415, JString, required = false,
                                 default = nil)
  if valid_774415 != nil:
    section.add "X-Amz-Algorithm", valid_774415
  var valid_774416 = header.getOrDefault("X-Amz-Signature")
  valid_774416 = validateParameter(valid_774416, JString, required = false,
                                 default = nil)
  if valid_774416 != nil:
    section.add "X-Amz-Signature", valid_774416
  var valid_774417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774417 = validateParameter(valid_774417, JString, required = false,
                                 default = nil)
  if valid_774417 != nil:
    section.add "X-Amz-SignedHeaders", valid_774417
  var valid_774418 = header.getOrDefault("X-Amz-Credential")
  valid_774418 = validateParameter(valid_774418, JString, required = false,
                                 default = nil)
  if valid_774418 != nil:
    section.add "X-Amz-Credential", valid_774418
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Parameters` field"
  var valid_774419 = formData.getOrDefault("Parameters")
  valid_774419 = validateParameter(valid_774419, JArray, required = true, default = nil)
  if valid_774419 != nil:
    section.add "Parameters", valid_774419
  var valid_774420 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_774420 = validateParameter(valid_774420, JString, required = true,
                                 default = nil)
  if valid_774420 != nil:
    section.add "DBClusterParameterGroupName", valid_774420
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774421: Call_PostModifyDBClusterParameterGroup_774407;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_774421.validator(path, query, header, formData, body)
  let scheme = call_774421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774421.url(scheme.get, call_774421.host, call_774421.base,
                         call_774421.route, valid.getOrDefault("path"))
  result = hook(call_774421, url, valid)

proc call*(call_774422: Call_PostModifyDBClusterParameterGroup_774407;
          Parameters: JsonNode; DBClusterParameterGroupName: string;
          Action: string = "ModifyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postModifyDBClusterParameterGroup
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the DB cluster parameter group to modify.
  ##   Version: string (required)
  var query_774423 = newJObject()
  var formData_774424 = newJObject()
  if Parameters != nil:
    formData_774424.add "Parameters", Parameters
  add(query_774423, "Action", newJString(Action))
  add(formData_774424, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_774423, "Version", newJString(Version))
  result = call_774422.call(nil, query_774423, nil, formData_774424, nil)

var postModifyDBClusterParameterGroup* = Call_PostModifyDBClusterParameterGroup_774407(
    name: "postModifyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_PostModifyDBClusterParameterGroup_774408, base: "/",
    url: url_PostModifyDBClusterParameterGroup_774409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterParameterGroup_774390 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBClusterParameterGroup_774392(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBClusterParameterGroup_774391(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to modify.
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_774393 = query.getOrDefault("DBClusterParameterGroupName")
  valid_774393 = validateParameter(valid_774393, JString, required = true,
                                 default = nil)
  if valid_774393 != nil:
    section.add "DBClusterParameterGroupName", valid_774393
  var valid_774394 = query.getOrDefault("Parameters")
  valid_774394 = validateParameter(valid_774394, JArray, required = true, default = nil)
  if valid_774394 != nil:
    section.add "Parameters", valid_774394
  var valid_774395 = query.getOrDefault("Action")
  valid_774395 = validateParameter(valid_774395, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_774395 != nil:
    section.add "Action", valid_774395
  var valid_774396 = query.getOrDefault("Version")
  valid_774396 = validateParameter(valid_774396, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774396 != nil:
    section.add "Version", valid_774396
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774397 = header.getOrDefault("X-Amz-Date")
  valid_774397 = validateParameter(valid_774397, JString, required = false,
                                 default = nil)
  if valid_774397 != nil:
    section.add "X-Amz-Date", valid_774397
  var valid_774398 = header.getOrDefault("X-Amz-Security-Token")
  valid_774398 = validateParameter(valid_774398, JString, required = false,
                                 default = nil)
  if valid_774398 != nil:
    section.add "X-Amz-Security-Token", valid_774398
  var valid_774399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774399 = validateParameter(valid_774399, JString, required = false,
                                 default = nil)
  if valid_774399 != nil:
    section.add "X-Amz-Content-Sha256", valid_774399
  var valid_774400 = header.getOrDefault("X-Amz-Algorithm")
  valid_774400 = validateParameter(valid_774400, JString, required = false,
                                 default = nil)
  if valid_774400 != nil:
    section.add "X-Amz-Algorithm", valid_774400
  var valid_774401 = header.getOrDefault("X-Amz-Signature")
  valid_774401 = validateParameter(valid_774401, JString, required = false,
                                 default = nil)
  if valid_774401 != nil:
    section.add "X-Amz-Signature", valid_774401
  var valid_774402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774402 = validateParameter(valid_774402, JString, required = false,
                                 default = nil)
  if valid_774402 != nil:
    section.add "X-Amz-SignedHeaders", valid_774402
  var valid_774403 = header.getOrDefault("X-Amz-Credential")
  valid_774403 = validateParameter(valid_774403, JString, required = false,
                                 default = nil)
  if valid_774403 != nil:
    section.add "X-Amz-Credential", valid_774403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774404: Call_GetModifyDBClusterParameterGroup_774390;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_774404.validator(path, query, header, formData, body)
  let scheme = call_774404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774404.url(scheme.get, call_774404.host, call_774404.base,
                         call_774404.route, valid.getOrDefault("path"))
  result = hook(call_774404, url, valid)

proc call*(call_774405: Call_GetModifyDBClusterParameterGroup_774390;
          DBClusterParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getModifyDBClusterParameterGroup
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the DB cluster parameter group to modify.
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774406 = newJObject()
  add(query_774406, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_774406.add "Parameters", Parameters
  add(query_774406, "Action", newJString(Action))
  add(query_774406, "Version", newJString(Version))
  result = call_774405.call(nil, query_774406, nil, nil, nil)

var getModifyDBClusterParameterGroup* = Call_GetModifyDBClusterParameterGroup_774390(
    name: "getModifyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_GetModifyDBClusterParameterGroup_774391, base: "/",
    url: url_GetModifyDBClusterParameterGroup_774392,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterSnapshotAttribute_774444 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBClusterSnapshotAttribute_774446(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBClusterSnapshotAttribute_774445(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774447 = query.getOrDefault("Action")
  valid_774447 = validateParameter(valid_774447, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_774447 != nil:
    section.add "Action", valid_774447
  var valid_774448 = query.getOrDefault("Version")
  valid_774448 = validateParameter(valid_774448, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774448 != nil:
    section.add "Version", valid_774448
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774449 = header.getOrDefault("X-Amz-Date")
  valid_774449 = validateParameter(valid_774449, JString, required = false,
                                 default = nil)
  if valid_774449 != nil:
    section.add "X-Amz-Date", valid_774449
  var valid_774450 = header.getOrDefault("X-Amz-Security-Token")
  valid_774450 = validateParameter(valid_774450, JString, required = false,
                                 default = nil)
  if valid_774450 != nil:
    section.add "X-Amz-Security-Token", valid_774450
  var valid_774451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774451 = validateParameter(valid_774451, JString, required = false,
                                 default = nil)
  if valid_774451 != nil:
    section.add "X-Amz-Content-Sha256", valid_774451
  var valid_774452 = header.getOrDefault("X-Amz-Algorithm")
  valid_774452 = validateParameter(valid_774452, JString, required = false,
                                 default = nil)
  if valid_774452 != nil:
    section.add "X-Amz-Algorithm", valid_774452
  var valid_774453 = header.getOrDefault("X-Amz-Signature")
  valid_774453 = validateParameter(valid_774453, JString, required = false,
                                 default = nil)
  if valid_774453 != nil:
    section.add "X-Amz-Signature", valid_774453
  var valid_774454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774454 = validateParameter(valid_774454, JString, required = false,
                                 default = nil)
  if valid_774454 != nil:
    section.add "X-Amz-SignedHeaders", valid_774454
  var valid_774455 = header.getOrDefault("X-Amz-Credential")
  valid_774455 = validateParameter(valid_774455, JString, required = false,
                                 default = nil)
  if valid_774455 != nil:
    section.add "X-Amz-Credential", valid_774455
  result.add "header", section
  ## parameters in `formData` object:
  ##   AttributeName: JString (required)
  ##                : <p>The name of the DB cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this value to <code>restore</code>.</p>
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to modify the attributes for.
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of DB cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the DB cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual DB cluster snapshot.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of DB cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account IDs. To make the manual DB cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_774456 = formData.getOrDefault("AttributeName")
  valid_774456 = validateParameter(valid_774456, JString, required = true,
                                 default = nil)
  if valid_774456 != nil:
    section.add "AttributeName", valid_774456
  var valid_774457 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_774457 = validateParameter(valid_774457, JString, required = true,
                                 default = nil)
  if valid_774457 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_774457
  var valid_774458 = formData.getOrDefault("ValuesToRemove")
  valid_774458 = validateParameter(valid_774458, JArray, required = false,
                                 default = nil)
  if valid_774458 != nil:
    section.add "ValuesToRemove", valid_774458
  var valid_774459 = formData.getOrDefault("ValuesToAdd")
  valid_774459 = validateParameter(valid_774459, JArray, required = false,
                                 default = nil)
  if valid_774459 != nil:
    section.add "ValuesToAdd", valid_774459
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774460: Call_PostModifyDBClusterSnapshotAttribute_774444;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_774460.validator(path, query, header, formData, body)
  let scheme = call_774460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774460.url(scheme.get, call_774460.host, call_774460.base,
                         call_774460.route, valid.getOrDefault("path"))
  result = hook(call_774460, url, valid)

proc call*(call_774461: Call_PostModifyDBClusterSnapshotAttribute_774444;
          AttributeName: string; DBClusterSnapshotIdentifier: string;
          Action: string = "ModifyDBClusterSnapshotAttribute";
          ValuesToRemove: JsonNode = nil; ValuesToAdd: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postModifyDBClusterSnapshotAttribute
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ##   AttributeName: string (required)
  ##                : <p>The name of the DB cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this value to <code>restore</code>.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to modify the attributes for.
  ##   Action: string (required)
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of DB cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the DB cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual DB cluster snapshot.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of DB cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account IDs. To make the manual DB cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Version: string (required)
  var query_774462 = newJObject()
  var formData_774463 = newJObject()
  add(formData_774463, "AttributeName", newJString(AttributeName))
  add(formData_774463, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_774462, "Action", newJString(Action))
  if ValuesToRemove != nil:
    formData_774463.add "ValuesToRemove", ValuesToRemove
  if ValuesToAdd != nil:
    formData_774463.add "ValuesToAdd", ValuesToAdd
  add(query_774462, "Version", newJString(Version))
  result = call_774461.call(nil, query_774462, nil, formData_774463, nil)

var postModifyDBClusterSnapshotAttribute* = Call_PostModifyDBClusterSnapshotAttribute_774444(
    name: "postModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_PostModifyDBClusterSnapshotAttribute_774445, base: "/",
    url: url_PostModifyDBClusterSnapshotAttribute_774446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterSnapshotAttribute_774425 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBClusterSnapshotAttribute_774427(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBClusterSnapshotAttribute_774426(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AttributeName: JString (required)
  ##                : <p>The name of the DB cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this value to <code>restore</code>.</p>
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to modify the attributes for.
  ##   ValuesToAdd: JArray
  ##              : <p>A list of DB cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account IDs. To make the manual DB cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Action: JString (required)
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of DB cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the DB cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual DB cluster snapshot.</p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AttributeName` field"
  var valid_774428 = query.getOrDefault("AttributeName")
  valid_774428 = validateParameter(valid_774428, JString, required = true,
                                 default = nil)
  if valid_774428 != nil:
    section.add "AttributeName", valid_774428
  var valid_774429 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_774429 = validateParameter(valid_774429, JString, required = true,
                                 default = nil)
  if valid_774429 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_774429
  var valid_774430 = query.getOrDefault("ValuesToAdd")
  valid_774430 = validateParameter(valid_774430, JArray, required = false,
                                 default = nil)
  if valid_774430 != nil:
    section.add "ValuesToAdd", valid_774430
  var valid_774431 = query.getOrDefault("Action")
  valid_774431 = validateParameter(valid_774431, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_774431 != nil:
    section.add "Action", valid_774431
  var valid_774432 = query.getOrDefault("ValuesToRemove")
  valid_774432 = validateParameter(valid_774432, JArray, required = false,
                                 default = nil)
  if valid_774432 != nil:
    section.add "ValuesToRemove", valid_774432
  var valid_774433 = query.getOrDefault("Version")
  valid_774433 = validateParameter(valid_774433, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774433 != nil:
    section.add "Version", valid_774433
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774434 = header.getOrDefault("X-Amz-Date")
  valid_774434 = validateParameter(valid_774434, JString, required = false,
                                 default = nil)
  if valid_774434 != nil:
    section.add "X-Amz-Date", valid_774434
  var valid_774435 = header.getOrDefault("X-Amz-Security-Token")
  valid_774435 = validateParameter(valid_774435, JString, required = false,
                                 default = nil)
  if valid_774435 != nil:
    section.add "X-Amz-Security-Token", valid_774435
  var valid_774436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774436 = validateParameter(valid_774436, JString, required = false,
                                 default = nil)
  if valid_774436 != nil:
    section.add "X-Amz-Content-Sha256", valid_774436
  var valid_774437 = header.getOrDefault("X-Amz-Algorithm")
  valid_774437 = validateParameter(valid_774437, JString, required = false,
                                 default = nil)
  if valid_774437 != nil:
    section.add "X-Amz-Algorithm", valid_774437
  var valid_774438 = header.getOrDefault("X-Amz-Signature")
  valid_774438 = validateParameter(valid_774438, JString, required = false,
                                 default = nil)
  if valid_774438 != nil:
    section.add "X-Amz-Signature", valid_774438
  var valid_774439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774439 = validateParameter(valid_774439, JString, required = false,
                                 default = nil)
  if valid_774439 != nil:
    section.add "X-Amz-SignedHeaders", valid_774439
  var valid_774440 = header.getOrDefault("X-Amz-Credential")
  valid_774440 = validateParameter(valid_774440, JString, required = false,
                                 default = nil)
  if valid_774440 != nil:
    section.add "X-Amz-Credential", valid_774440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774441: Call_GetModifyDBClusterSnapshotAttribute_774425;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_774441.validator(path, query, header, formData, body)
  let scheme = call_774441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774441.url(scheme.get, call_774441.host, call_774441.base,
                         call_774441.route, valid.getOrDefault("path"))
  result = hook(call_774441, url, valid)

proc call*(call_774442: Call_GetModifyDBClusterSnapshotAttribute_774425;
          AttributeName: string; DBClusterSnapshotIdentifier: string;
          ValuesToAdd: JsonNode = nil;
          Action: string = "ModifyDBClusterSnapshotAttribute";
          ValuesToRemove: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## getModifyDBClusterSnapshotAttribute
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ##   AttributeName: string (required)
  ##                : <p>The name of the DB cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this value to <code>restore</code>.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to modify the attributes for.
  ##   ValuesToAdd: JArray
  ##              : <p>A list of DB cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account IDs. To make the manual DB cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Action: string (required)
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of DB cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the DB cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual DB cluster snapshot.</p>
  ##   Version: string (required)
  var query_774443 = newJObject()
  add(query_774443, "AttributeName", newJString(AttributeName))
  add(query_774443, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if ValuesToAdd != nil:
    query_774443.add "ValuesToAdd", ValuesToAdd
  add(query_774443, "Action", newJString(Action))
  if ValuesToRemove != nil:
    query_774443.add "ValuesToRemove", ValuesToRemove
  add(query_774443, "Version", newJString(Version))
  result = call_774442.call(nil, query_774443, nil, nil, nil)

var getModifyDBClusterSnapshotAttribute* = Call_GetModifyDBClusterSnapshotAttribute_774425(
    name: "getModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_GetModifyDBClusterSnapshotAttribute_774426, base: "/",
    url: url_GetModifyDBClusterSnapshotAttribute_774427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_774486 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBInstance_774488(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBInstance_774487(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774489 = query.getOrDefault("Action")
  valid_774489 = validateParameter(valid_774489, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_774489 != nil:
    section.add "Action", valid_774489
  var valid_774490 = query.getOrDefault("Version")
  valid_774490 = validateParameter(valid_774490, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774490 != nil:
    section.add "Version", valid_774490
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774491 = header.getOrDefault("X-Amz-Date")
  valid_774491 = validateParameter(valid_774491, JString, required = false,
                                 default = nil)
  if valid_774491 != nil:
    section.add "X-Amz-Date", valid_774491
  var valid_774492 = header.getOrDefault("X-Amz-Security-Token")
  valid_774492 = validateParameter(valid_774492, JString, required = false,
                                 default = nil)
  if valid_774492 != nil:
    section.add "X-Amz-Security-Token", valid_774492
  var valid_774493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774493 = validateParameter(valid_774493, JString, required = false,
                                 default = nil)
  if valid_774493 != nil:
    section.add "X-Amz-Content-Sha256", valid_774493
  var valid_774494 = header.getOrDefault("X-Amz-Algorithm")
  valid_774494 = validateParameter(valid_774494, JString, required = false,
                                 default = nil)
  if valid_774494 != nil:
    section.add "X-Amz-Algorithm", valid_774494
  var valid_774495 = header.getOrDefault("X-Amz-Signature")
  valid_774495 = validateParameter(valid_774495, JString, required = false,
                                 default = nil)
  if valid_774495 != nil:
    section.add "X-Amz-Signature", valid_774495
  var valid_774496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774496 = validateParameter(valid_774496, JString, required = false,
                                 default = nil)
  if valid_774496 != nil:
    section.add "X-Amz-SignedHeaders", valid_774496
  var valid_774497 = header.getOrDefault("X-Amz-Credential")
  valid_774497 = validateParameter(valid_774497, JString, required = false,
                                 default = nil)
  if valid_774497 != nil:
    section.add "X-Amz-Credential", valid_774497
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplyImmediately: JBool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB instance. </p> <p> If this parameter is set to <code>false</code>, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   NewDBInstanceIdentifier: JString
  ##                          : <p> The new DB instance identifier for the DB instance when renaming a DB instance. When you change the DB instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: JString
  ##                  : <p>The new compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. Not all DB instance classes are available in all AWS Regions. </p> <p>If you modify the DB instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : Indicates that minor version upgrades are applied automatically to the DB instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the DB instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  section = newJObject()
  var valid_774498 = formData.getOrDefault("ApplyImmediately")
  valid_774498 = validateParameter(valid_774498, JBool, required = false, default = nil)
  if valid_774498 != nil:
    section.add "ApplyImmediately", valid_774498
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774499 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774499 = validateParameter(valid_774499, JString, required = true,
                                 default = nil)
  if valid_774499 != nil:
    section.add "DBInstanceIdentifier", valid_774499
  var valid_774500 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_774500 = validateParameter(valid_774500, JString, required = false,
                                 default = nil)
  if valid_774500 != nil:
    section.add "NewDBInstanceIdentifier", valid_774500
  var valid_774501 = formData.getOrDefault("PromotionTier")
  valid_774501 = validateParameter(valid_774501, JInt, required = false, default = nil)
  if valid_774501 != nil:
    section.add "PromotionTier", valid_774501
  var valid_774502 = formData.getOrDefault("DBInstanceClass")
  valid_774502 = validateParameter(valid_774502, JString, required = false,
                                 default = nil)
  if valid_774502 != nil:
    section.add "DBInstanceClass", valid_774502
  var valid_774503 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_774503 = validateParameter(valid_774503, JBool, required = false, default = nil)
  if valid_774503 != nil:
    section.add "AutoMinorVersionUpgrade", valid_774503
  var valid_774504 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_774504 = validateParameter(valid_774504, JString, required = false,
                                 default = nil)
  if valid_774504 != nil:
    section.add "PreferredMaintenanceWindow", valid_774504
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774505: Call_PostModifyDBInstance_774486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_774505.validator(path, query, header, formData, body)
  let scheme = call_774505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774505.url(scheme.get, call_774505.host, call_774505.base,
                         call_774505.route, valid.getOrDefault("path"))
  result = hook(call_774505, url, valid)

proc call*(call_774506: Call_PostModifyDBInstance_774486;
          DBInstanceIdentifier: string; ApplyImmediately: bool = false;
          NewDBInstanceIdentifier: string = ""; Action: string = "ModifyDBInstance";
          PromotionTier: int = 0; DBInstanceClass: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2014-10-31";
          PreferredMaintenanceWindow: string = ""): Recallable =
  ## postModifyDBInstance
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ##   ApplyImmediately: bool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB instance. </p> <p> If this parameter is set to <code>false</code>, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   NewDBInstanceIdentifier: string
  ##                          : <p> The new DB instance identifier for the DB instance when renaming a DB instance. When you change the DB instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Action: string (required)
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: string
  ##                  : <p>The new compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. Not all DB instance classes are available in all AWS Regions. </p> <p>If you modify the DB instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   AutoMinorVersionUpgrade: bool
  ##                          : Indicates that minor version upgrades are applied automatically to the DB instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the DB instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  var query_774507 = newJObject()
  var formData_774508 = newJObject()
  add(formData_774508, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_774508, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_774508, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_774507, "Action", newJString(Action))
  add(formData_774508, "PromotionTier", newJInt(PromotionTier))
  add(formData_774508, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_774508, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_774507, "Version", newJString(Version))
  add(formData_774508, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_774506.call(nil, query_774507, nil, formData_774508, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_774486(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_774487, base: "/",
    url: url_PostModifyDBInstance_774488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_774464 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBInstance_774466(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBInstance_774465(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the DB instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: JString
  ##                  : <p>The new compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. Not all DB instance classes are available in all AWS Regions. </p> <p>If you modify the DB instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   Action: JString (required)
  ##   NewDBInstanceIdentifier: JString
  ##                          : <p> The new DB instance identifier for the DB instance when renaming a DB instance. When you change the DB instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : Indicates that minor version upgrades are applied automatically to the DB instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ApplyImmediately: JBool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB instance. </p> <p> If this parameter is set to <code>false</code>, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_774467 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_774467 = validateParameter(valid_774467, JString, required = false,
                                 default = nil)
  if valid_774467 != nil:
    section.add "PreferredMaintenanceWindow", valid_774467
  var valid_774468 = query.getOrDefault("PromotionTier")
  valid_774468 = validateParameter(valid_774468, JInt, required = false, default = nil)
  if valid_774468 != nil:
    section.add "PromotionTier", valid_774468
  var valid_774469 = query.getOrDefault("DBInstanceClass")
  valid_774469 = validateParameter(valid_774469, JString, required = false,
                                 default = nil)
  if valid_774469 != nil:
    section.add "DBInstanceClass", valid_774469
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774470 = query.getOrDefault("Action")
  valid_774470 = validateParameter(valid_774470, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_774470 != nil:
    section.add "Action", valid_774470
  var valid_774471 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_774471 = validateParameter(valid_774471, JString, required = false,
                                 default = nil)
  if valid_774471 != nil:
    section.add "NewDBInstanceIdentifier", valid_774471
  var valid_774472 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_774472 = validateParameter(valid_774472, JBool, required = false, default = nil)
  if valid_774472 != nil:
    section.add "AutoMinorVersionUpgrade", valid_774472
  var valid_774473 = query.getOrDefault("Version")
  valid_774473 = validateParameter(valid_774473, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774473 != nil:
    section.add "Version", valid_774473
  var valid_774474 = query.getOrDefault("DBInstanceIdentifier")
  valid_774474 = validateParameter(valid_774474, JString, required = true,
                                 default = nil)
  if valid_774474 != nil:
    section.add "DBInstanceIdentifier", valid_774474
  var valid_774475 = query.getOrDefault("ApplyImmediately")
  valid_774475 = validateParameter(valid_774475, JBool, required = false, default = nil)
  if valid_774475 != nil:
    section.add "ApplyImmediately", valid_774475
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774476 = header.getOrDefault("X-Amz-Date")
  valid_774476 = validateParameter(valid_774476, JString, required = false,
                                 default = nil)
  if valid_774476 != nil:
    section.add "X-Amz-Date", valid_774476
  var valid_774477 = header.getOrDefault("X-Amz-Security-Token")
  valid_774477 = validateParameter(valid_774477, JString, required = false,
                                 default = nil)
  if valid_774477 != nil:
    section.add "X-Amz-Security-Token", valid_774477
  var valid_774478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774478 = validateParameter(valid_774478, JString, required = false,
                                 default = nil)
  if valid_774478 != nil:
    section.add "X-Amz-Content-Sha256", valid_774478
  var valid_774479 = header.getOrDefault("X-Amz-Algorithm")
  valid_774479 = validateParameter(valid_774479, JString, required = false,
                                 default = nil)
  if valid_774479 != nil:
    section.add "X-Amz-Algorithm", valid_774479
  var valid_774480 = header.getOrDefault("X-Amz-Signature")
  valid_774480 = validateParameter(valid_774480, JString, required = false,
                                 default = nil)
  if valid_774480 != nil:
    section.add "X-Amz-Signature", valid_774480
  var valid_774481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774481 = validateParameter(valid_774481, JString, required = false,
                                 default = nil)
  if valid_774481 != nil:
    section.add "X-Amz-SignedHeaders", valid_774481
  var valid_774482 = header.getOrDefault("X-Amz-Credential")
  valid_774482 = validateParameter(valid_774482, JString, required = false,
                                 default = nil)
  if valid_774482 != nil:
    section.add "X-Amz-Credential", valid_774482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774483: Call_GetModifyDBInstance_774464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_774483.validator(path, query, header, formData, body)
  let scheme = call_774483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774483.url(scheme.get, call_774483.host, call_774483.base,
                         call_774483.route, valid.getOrDefault("path"))
  result = hook(call_774483, url, valid)

proc call*(call_774484: Call_GetModifyDBInstance_774464;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          PromotionTier: int = 0; DBInstanceClass: string = "";
          Action: string = "ModifyDBInstance"; NewDBInstanceIdentifier: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2014-10-31";
          ApplyImmediately: bool = false): Recallable =
  ## getModifyDBInstance
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the DB instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: string
  ##                  : <p>The new compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. Not all DB instance classes are available in all AWS Regions. </p> <p>If you modify the DB instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   Action: string (required)
  ##   NewDBInstanceIdentifier: string
  ##                          : <p> The new DB instance identifier for the DB instance when renaming a DB instance. When you change the DB instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   AutoMinorVersionUpgrade: bool
  ##                          : Indicates that minor version upgrades are applied automatically to the DB instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ApplyImmediately: bool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB instance. </p> <p> If this parameter is set to <code>false</code>, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  var query_774485 = newJObject()
  add(query_774485, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_774485, "PromotionTier", newJInt(PromotionTier))
  add(query_774485, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_774485, "Action", newJString(Action))
  add(query_774485, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_774485, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_774485, "Version", newJString(Version))
  add(query_774485, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_774485, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_774484.call(nil, query_774485, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_774464(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_774465, base: "/",
    url: url_GetModifyDBInstance_774466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_774527 = ref object of OpenApiRestCall_772581
proc url_PostModifyDBSubnetGroup_774529(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBSubnetGroup_774528(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
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
  valid_774530 = validateParameter(valid_774530, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_774530 != nil:
    section.add "Action", valid_774530
  var valid_774531 = query.getOrDefault("Version")
  valid_774531 = validateParameter(valid_774531, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   DBSubnetGroupDescription: JString
  ##                           : The description for the DB subnet group.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_774539 = formData.getOrDefault("DBSubnetGroupName")
  valid_774539 = validateParameter(valid_774539, JString, required = true,
                                 default = nil)
  if valid_774539 != nil:
    section.add "DBSubnetGroupName", valid_774539
  var valid_774540 = formData.getOrDefault("SubnetIds")
  valid_774540 = validateParameter(valid_774540, JArray, required = true, default = nil)
  if valid_774540 != nil:
    section.add "SubnetIds", valid_774540
  var valid_774541 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_774541 = validateParameter(valid_774541, JString, required = false,
                                 default = nil)
  if valid_774541 != nil:
    section.add "DBSubnetGroupDescription", valid_774541
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774542: Call_PostModifyDBSubnetGroup_774527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_774542.validator(path, query, header, formData, body)
  let scheme = call_774542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774542.url(scheme.get, call_774542.host, call_774542.base,
                         call_774542.route, valid.getOrDefault("path"))
  result = hook(call_774542, url, valid)

proc call*(call_774543: Call_PostModifyDBSubnetGroup_774527;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-10-31"): Recallable =
  ## postModifyDBSubnetGroup
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##                           : The description for the DB subnet group.
  ##   Version: string (required)
  var query_774544 = newJObject()
  var formData_774545 = newJObject()
  add(formData_774545, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_774545.add "SubnetIds", SubnetIds
  add(query_774544, "Action", newJString(Action))
  add(formData_774545, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_774544, "Version", newJString(Version))
  result = call_774543.call(nil, query_774544, nil, formData_774545, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_774527(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_774528, base: "/",
    url: url_PostModifyDBSubnetGroup_774529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_774509 = ref object of OpenApiRestCall_772581
proc url_GetModifyDBSubnetGroup_774511(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBSubnetGroup_774510(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   DBSubnetGroupDescription: JString
  ##                           : The description for the DB subnet group.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774512 = query.getOrDefault("Action")
  valid_774512 = validateParameter(valid_774512, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_774512 != nil:
    section.add "Action", valid_774512
  var valid_774513 = query.getOrDefault("DBSubnetGroupName")
  valid_774513 = validateParameter(valid_774513, JString, required = true,
                                 default = nil)
  if valid_774513 != nil:
    section.add "DBSubnetGroupName", valid_774513
  var valid_774514 = query.getOrDefault("SubnetIds")
  valid_774514 = validateParameter(valid_774514, JArray, required = true, default = nil)
  if valid_774514 != nil:
    section.add "SubnetIds", valid_774514
  var valid_774515 = query.getOrDefault("DBSubnetGroupDescription")
  valid_774515 = validateParameter(valid_774515, JString, required = false,
                                 default = nil)
  if valid_774515 != nil:
    section.add "DBSubnetGroupDescription", valid_774515
  var valid_774516 = query.getOrDefault("Version")
  valid_774516 = validateParameter(valid_774516, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774516 != nil:
    section.add "Version", valid_774516
  result.add "query", section
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

proc call*(call_774524: Call_GetModifyDBSubnetGroup_774509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_774524.validator(path, query, header, formData, body)
  let scheme = call_774524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774524.url(scheme.get, call_774524.host, call_774524.base,
                         call_774524.route, valid.getOrDefault("path"))
  result = hook(call_774524, url, valid)

proc call*(call_774525: Call_GetModifyDBSubnetGroup_774509;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getModifyDBSubnetGroup
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   DBSubnetGroupDescription: string
  ##                           : The description for the DB subnet group.
  ##   Version: string (required)
  var query_774526 = newJObject()
  add(query_774526, "Action", newJString(Action))
  add(query_774526, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_774526.add "SubnetIds", SubnetIds
  add(query_774526, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_774526, "Version", newJString(Version))
  result = call_774525.call(nil, query_774526, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_774509(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_774510, base: "/",
    url: url_GetModifyDBSubnetGroup_774511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_774563 = ref object of OpenApiRestCall_772581
proc url_PostRebootDBInstance_774565(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebootDBInstance_774564(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774566 = query.getOrDefault("Action")
  valid_774566 = validateParameter(valid_774566, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_774566 != nil:
    section.add "Action", valid_774566
  var valid_774567 = query.getOrDefault("Version")
  valid_774567 = validateParameter(valid_774567, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774567 != nil:
    section.add "Version", valid_774567
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774568 = header.getOrDefault("X-Amz-Date")
  valid_774568 = validateParameter(valid_774568, JString, required = false,
                                 default = nil)
  if valid_774568 != nil:
    section.add "X-Amz-Date", valid_774568
  var valid_774569 = header.getOrDefault("X-Amz-Security-Token")
  valid_774569 = validateParameter(valid_774569, JString, required = false,
                                 default = nil)
  if valid_774569 != nil:
    section.add "X-Amz-Security-Token", valid_774569
  var valid_774570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774570 = validateParameter(valid_774570, JString, required = false,
                                 default = nil)
  if valid_774570 != nil:
    section.add "X-Amz-Content-Sha256", valid_774570
  var valid_774571 = header.getOrDefault("X-Amz-Algorithm")
  valid_774571 = validateParameter(valid_774571, JString, required = false,
                                 default = nil)
  if valid_774571 != nil:
    section.add "X-Amz-Algorithm", valid_774571
  var valid_774572 = header.getOrDefault("X-Amz-Signature")
  valid_774572 = validateParameter(valid_774572, JString, required = false,
                                 default = nil)
  if valid_774572 != nil:
    section.add "X-Amz-Signature", valid_774572
  var valid_774573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774573 = validateParameter(valid_774573, JString, required = false,
                                 default = nil)
  if valid_774573 != nil:
    section.add "X-Amz-SignedHeaders", valid_774573
  var valid_774574 = header.getOrDefault("X-Amz-Credential")
  valid_774574 = validateParameter(valid_774574, JString, required = false,
                                 default = nil)
  if valid_774574 != nil:
    section.add "X-Amz-Credential", valid_774574
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_774575 = formData.getOrDefault("DBInstanceIdentifier")
  valid_774575 = validateParameter(valid_774575, JString, required = true,
                                 default = nil)
  if valid_774575 != nil:
    section.add "DBInstanceIdentifier", valid_774575
  var valid_774576 = formData.getOrDefault("ForceFailover")
  valid_774576 = validateParameter(valid_774576, JBool, required = false, default = nil)
  if valid_774576 != nil:
    section.add "ForceFailover", valid_774576
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774577: Call_PostRebootDBInstance_774563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_774577.validator(path, query, header, formData, body)
  let scheme = call_774577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774577.url(scheme.get, call_774577.host, call_774577.base,
                         call_774577.route, valid.getOrDefault("path"))
  result = hook(call_774577, url, valid)

proc call*(call_774578: Call_PostRebootDBInstance_774563;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-10-31"): Recallable =
  ## postRebootDBInstance
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   Version: string (required)
  var query_774579 = newJObject()
  var formData_774580 = newJObject()
  add(formData_774580, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_774579, "Action", newJString(Action))
  add(formData_774580, "ForceFailover", newJBool(ForceFailover))
  add(query_774579, "Version", newJString(Version))
  result = call_774578.call(nil, query_774579, nil, formData_774580, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_774563(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_774564, base: "/",
    url: url_PostRebootDBInstance_774565, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_774546 = ref object of OpenApiRestCall_772581
proc url_GetRebootDBInstance_774548(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebootDBInstance_774547(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774549 = query.getOrDefault("Action")
  valid_774549 = validateParameter(valid_774549, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_774549 != nil:
    section.add "Action", valid_774549
  var valid_774550 = query.getOrDefault("ForceFailover")
  valid_774550 = validateParameter(valid_774550, JBool, required = false, default = nil)
  if valid_774550 != nil:
    section.add "ForceFailover", valid_774550
  var valid_774551 = query.getOrDefault("Version")
  valid_774551 = validateParameter(valid_774551, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774551 != nil:
    section.add "Version", valid_774551
  var valid_774552 = query.getOrDefault("DBInstanceIdentifier")
  valid_774552 = validateParameter(valid_774552, JString, required = true,
                                 default = nil)
  if valid_774552 != nil:
    section.add "DBInstanceIdentifier", valid_774552
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774553 = header.getOrDefault("X-Amz-Date")
  valid_774553 = validateParameter(valid_774553, JString, required = false,
                                 default = nil)
  if valid_774553 != nil:
    section.add "X-Amz-Date", valid_774553
  var valid_774554 = header.getOrDefault("X-Amz-Security-Token")
  valid_774554 = validateParameter(valid_774554, JString, required = false,
                                 default = nil)
  if valid_774554 != nil:
    section.add "X-Amz-Security-Token", valid_774554
  var valid_774555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774555 = validateParameter(valid_774555, JString, required = false,
                                 default = nil)
  if valid_774555 != nil:
    section.add "X-Amz-Content-Sha256", valid_774555
  var valid_774556 = header.getOrDefault("X-Amz-Algorithm")
  valid_774556 = validateParameter(valid_774556, JString, required = false,
                                 default = nil)
  if valid_774556 != nil:
    section.add "X-Amz-Algorithm", valid_774556
  var valid_774557 = header.getOrDefault("X-Amz-Signature")
  valid_774557 = validateParameter(valid_774557, JString, required = false,
                                 default = nil)
  if valid_774557 != nil:
    section.add "X-Amz-Signature", valid_774557
  var valid_774558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774558 = validateParameter(valid_774558, JString, required = false,
                                 default = nil)
  if valid_774558 != nil:
    section.add "X-Amz-SignedHeaders", valid_774558
  var valid_774559 = header.getOrDefault("X-Amz-Credential")
  valid_774559 = validateParameter(valid_774559, JString, required = false,
                                 default = nil)
  if valid_774559 != nil:
    section.add "X-Amz-Credential", valid_774559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774560: Call_GetRebootDBInstance_774546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_774560.validator(path, query, header, formData, body)
  let scheme = call_774560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774560.url(scheme.get, call_774560.host, call_774560.base,
                         call_774560.route, valid.getOrDefault("path"))
  result = hook(call_774560, url, valid)

proc call*(call_774561: Call_GetRebootDBInstance_774546;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-10-31"): Recallable =
  ## getRebootDBInstance
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  var query_774562 = newJObject()
  add(query_774562, "Action", newJString(Action))
  add(query_774562, "ForceFailover", newJBool(ForceFailover))
  add(query_774562, "Version", newJString(Version))
  add(query_774562, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_774561.call(nil, query_774562, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_774546(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_774547, base: "/",
    url: url_GetRebootDBInstance_774548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_774598 = ref object of OpenApiRestCall_772581
proc url_PostRemoveTagsFromResource_774600(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTagsFromResource_774599(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774601 = query.getOrDefault("Action")
  valid_774601 = validateParameter(valid_774601, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_774601 != nil:
    section.add "Action", valid_774601
  var valid_774602 = query.getOrDefault("Version")
  valid_774602 = validateParameter(valid_774602, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774602 != nil:
    section.add "Version", valid_774602
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774603 = header.getOrDefault("X-Amz-Date")
  valid_774603 = validateParameter(valid_774603, JString, required = false,
                                 default = nil)
  if valid_774603 != nil:
    section.add "X-Amz-Date", valid_774603
  var valid_774604 = header.getOrDefault("X-Amz-Security-Token")
  valid_774604 = validateParameter(valid_774604, JString, required = false,
                                 default = nil)
  if valid_774604 != nil:
    section.add "X-Amz-Security-Token", valid_774604
  var valid_774605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774605 = validateParameter(valid_774605, JString, required = false,
                                 default = nil)
  if valid_774605 != nil:
    section.add "X-Amz-Content-Sha256", valid_774605
  var valid_774606 = header.getOrDefault("X-Amz-Algorithm")
  valid_774606 = validateParameter(valid_774606, JString, required = false,
                                 default = nil)
  if valid_774606 != nil:
    section.add "X-Amz-Algorithm", valid_774606
  var valid_774607 = header.getOrDefault("X-Amz-Signature")
  valid_774607 = validateParameter(valid_774607, JString, required = false,
                                 default = nil)
  if valid_774607 != nil:
    section.add "X-Amz-Signature", valid_774607
  var valid_774608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774608 = validateParameter(valid_774608, JString, required = false,
                                 default = nil)
  if valid_774608 != nil:
    section.add "X-Amz-SignedHeaders", valid_774608
  var valid_774609 = header.getOrDefault("X-Amz-Credential")
  valid_774609 = validateParameter(valid_774609, JString, required = false,
                                 default = nil)
  if valid_774609 != nil:
    section.add "X-Amz-Credential", valid_774609
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_774610 = formData.getOrDefault("TagKeys")
  valid_774610 = validateParameter(valid_774610, JArray, required = true, default = nil)
  if valid_774610 != nil:
    section.add "TagKeys", valid_774610
  var valid_774611 = formData.getOrDefault("ResourceName")
  valid_774611 = validateParameter(valid_774611, JString, required = true,
                                 default = nil)
  if valid_774611 != nil:
    section.add "ResourceName", valid_774611
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774612: Call_PostRemoveTagsFromResource_774598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_774612.validator(path, query, header, formData, body)
  let scheme = call_774612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774612.url(scheme.get, call_774612.host, call_774612.base,
                         call_774612.route, valid.getOrDefault("path"))
  result = hook(call_774612, url, valid)

proc call*(call_774613: Call_PostRemoveTagsFromResource_774598; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-10-31"): Recallable =
  ## postRemoveTagsFromResource
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  ##   Version: string (required)
  var query_774614 = newJObject()
  var formData_774615 = newJObject()
  add(query_774614, "Action", newJString(Action))
  if TagKeys != nil:
    formData_774615.add "TagKeys", TagKeys
  add(formData_774615, "ResourceName", newJString(ResourceName))
  add(query_774614, "Version", newJString(Version))
  result = call_774613.call(nil, query_774614, nil, formData_774615, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_774598(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_774599, base: "/",
    url: url_PostRemoveTagsFromResource_774600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_774581 = ref object of OpenApiRestCall_772581
proc url_GetRemoveTagsFromResource_774583(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTagsFromResource_774582(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  ##   Action: JString (required)
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_774584 = query.getOrDefault("ResourceName")
  valid_774584 = validateParameter(valid_774584, JString, required = true,
                                 default = nil)
  if valid_774584 != nil:
    section.add "ResourceName", valid_774584
  var valid_774585 = query.getOrDefault("Action")
  valid_774585 = validateParameter(valid_774585, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_774585 != nil:
    section.add "Action", valid_774585
  var valid_774586 = query.getOrDefault("TagKeys")
  valid_774586 = validateParameter(valid_774586, JArray, required = true, default = nil)
  if valid_774586 != nil:
    section.add "TagKeys", valid_774586
  var valid_774587 = query.getOrDefault("Version")
  valid_774587 = validateParameter(valid_774587, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774587 != nil:
    section.add "Version", valid_774587
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774588 = header.getOrDefault("X-Amz-Date")
  valid_774588 = validateParameter(valid_774588, JString, required = false,
                                 default = nil)
  if valid_774588 != nil:
    section.add "X-Amz-Date", valid_774588
  var valid_774589 = header.getOrDefault("X-Amz-Security-Token")
  valid_774589 = validateParameter(valid_774589, JString, required = false,
                                 default = nil)
  if valid_774589 != nil:
    section.add "X-Amz-Security-Token", valid_774589
  var valid_774590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774590 = validateParameter(valid_774590, JString, required = false,
                                 default = nil)
  if valid_774590 != nil:
    section.add "X-Amz-Content-Sha256", valid_774590
  var valid_774591 = header.getOrDefault("X-Amz-Algorithm")
  valid_774591 = validateParameter(valid_774591, JString, required = false,
                                 default = nil)
  if valid_774591 != nil:
    section.add "X-Amz-Algorithm", valid_774591
  var valid_774592 = header.getOrDefault("X-Amz-Signature")
  valid_774592 = validateParameter(valid_774592, JString, required = false,
                                 default = nil)
  if valid_774592 != nil:
    section.add "X-Amz-Signature", valid_774592
  var valid_774593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774593 = validateParameter(valid_774593, JString, required = false,
                                 default = nil)
  if valid_774593 != nil:
    section.add "X-Amz-SignedHeaders", valid_774593
  var valid_774594 = header.getOrDefault("X-Amz-Credential")
  valid_774594 = validateParameter(valid_774594, JString, required = false,
                                 default = nil)
  if valid_774594 != nil:
    section.add "X-Amz-Credential", valid_774594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774595: Call_GetRemoveTagsFromResource_774581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_774595.validator(path, query, header, formData, body)
  let scheme = call_774595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774595.url(scheme.get, call_774595.host, call_774595.base,
                         call_774595.route, valid.getOrDefault("path"))
  result = hook(call_774595, url, valid)

proc call*(call_774596: Call_GetRemoveTagsFromResource_774581;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-10-31"): Recallable =
  ## getRemoveTagsFromResource
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   Version: string (required)
  var query_774597 = newJObject()
  add(query_774597, "ResourceName", newJString(ResourceName))
  add(query_774597, "Action", newJString(Action))
  if TagKeys != nil:
    query_774597.add "TagKeys", TagKeys
  add(query_774597, "Version", newJString(Version))
  result = call_774596.call(nil, query_774597, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_774581(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_774582, base: "/",
    url: url_GetRemoveTagsFromResource_774583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBClusterParameterGroup_774634 = ref object of OpenApiRestCall_772581
proc url_PostResetDBClusterParameterGroup_774636(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostResetDBClusterParameterGroup_774635(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774637 = query.getOrDefault("Action")
  valid_774637 = validateParameter(valid_774637, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_774637 != nil:
    section.add "Action", valid_774637
  var valid_774638 = query.getOrDefault("Version")
  valid_774638 = validateParameter(valid_774638, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774638 != nil:
    section.add "Version", valid_774638
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774639 = header.getOrDefault("X-Amz-Date")
  valid_774639 = validateParameter(valid_774639, JString, required = false,
                                 default = nil)
  if valid_774639 != nil:
    section.add "X-Amz-Date", valid_774639
  var valid_774640 = header.getOrDefault("X-Amz-Security-Token")
  valid_774640 = validateParameter(valid_774640, JString, required = false,
                                 default = nil)
  if valid_774640 != nil:
    section.add "X-Amz-Security-Token", valid_774640
  var valid_774641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774641 = validateParameter(valid_774641, JString, required = false,
                                 default = nil)
  if valid_774641 != nil:
    section.add "X-Amz-Content-Sha256", valid_774641
  var valid_774642 = header.getOrDefault("X-Amz-Algorithm")
  valid_774642 = validateParameter(valid_774642, JString, required = false,
                                 default = nil)
  if valid_774642 != nil:
    section.add "X-Amz-Algorithm", valid_774642
  var valid_774643 = header.getOrDefault("X-Amz-Signature")
  valid_774643 = validateParameter(valid_774643, JString, required = false,
                                 default = nil)
  if valid_774643 != nil:
    section.add "X-Amz-Signature", valid_774643
  var valid_774644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774644 = validateParameter(valid_774644, JString, required = false,
                                 default = nil)
  if valid_774644 != nil:
    section.add "X-Amz-SignedHeaders", valid_774644
  var valid_774645 = header.getOrDefault("X-Amz-Credential")
  valid_774645 = validateParameter(valid_774645, JString, required = false,
                                 default = nil)
  if valid_774645 != nil:
    section.add "X-Amz-Credential", valid_774645
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  section = newJObject()
  var valid_774646 = formData.getOrDefault("Parameters")
  valid_774646 = validateParameter(valid_774646, JArray, required = false,
                                 default = nil)
  if valid_774646 != nil:
    section.add "Parameters", valid_774646
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_774647 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_774647 = validateParameter(valid_774647, JString, required = true,
                                 default = nil)
  if valid_774647 != nil:
    section.add "DBClusterParameterGroupName", valid_774647
  var valid_774648 = formData.getOrDefault("ResetAllParameters")
  valid_774648 = validateParameter(valid_774648, JBool, required = false, default = nil)
  if valid_774648 != nil:
    section.add "ResetAllParameters", valid_774648
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774649: Call_PostResetDBClusterParameterGroup_774634;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_774649.validator(path, query, header, formData, body)
  let scheme = call_774649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774649.url(scheme.get, call_774649.host, call_774649.base,
                         call_774649.route, valid.getOrDefault("path"))
  result = hook(call_774649, url, valid)

proc call*(call_774650: Call_PostResetDBClusterParameterGroup_774634;
          DBClusterParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBClusterParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-10-31"): Recallable =
  ## postResetDBClusterParameterGroup
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   ResetAllParameters: bool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Version: string (required)
  var query_774651 = newJObject()
  var formData_774652 = newJObject()
  if Parameters != nil:
    formData_774652.add "Parameters", Parameters
  add(query_774651, "Action", newJString(Action))
  add(formData_774652, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_774652, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_774651, "Version", newJString(Version))
  result = call_774650.call(nil, query_774651, nil, formData_774652, nil)

var postResetDBClusterParameterGroup* = Call_PostResetDBClusterParameterGroup_774634(
    name: "postResetDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_PostResetDBClusterParameterGroup_774635, base: "/",
    url: url_PostResetDBClusterParameterGroup_774636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBClusterParameterGroup_774616 = ref object of OpenApiRestCall_772581
proc url_GetResetDBClusterParameterGroup_774618(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResetDBClusterParameterGroup_774617(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   Action: JString (required)
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_774619 = query.getOrDefault("DBClusterParameterGroupName")
  valid_774619 = validateParameter(valid_774619, JString, required = true,
                                 default = nil)
  if valid_774619 != nil:
    section.add "DBClusterParameterGroupName", valid_774619
  var valid_774620 = query.getOrDefault("Parameters")
  valid_774620 = validateParameter(valid_774620, JArray, required = false,
                                 default = nil)
  if valid_774620 != nil:
    section.add "Parameters", valid_774620
  var valid_774621 = query.getOrDefault("Action")
  valid_774621 = validateParameter(valid_774621, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_774621 != nil:
    section.add "Action", valid_774621
  var valid_774622 = query.getOrDefault("ResetAllParameters")
  valid_774622 = validateParameter(valid_774622, JBool, required = false, default = nil)
  if valid_774622 != nil:
    section.add "ResetAllParameters", valid_774622
  var valid_774623 = query.getOrDefault("Version")
  valid_774623 = validateParameter(valid_774623, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774623 != nil:
    section.add "Version", valid_774623
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774624 = header.getOrDefault("X-Amz-Date")
  valid_774624 = validateParameter(valid_774624, JString, required = false,
                                 default = nil)
  if valid_774624 != nil:
    section.add "X-Amz-Date", valid_774624
  var valid_774625 = header.getOrDefault("X-Amz-Security-Token")
  valid_774625 = validateParameter(valid_774625, JString, required = false,
                                 default = nil)
  if valid_774625 != nil:
    section.add "X-Amz-Security-Token", valid_774625
  var valid_774626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774626 = validateParameter(valid_774626, JString, required = false,
                                 default = nil)
  if valid_774626 != nil:
    section.add "X-Amz-Content-Sha256", valid_774626
  var valid_774627 = header.getOrDefault("X-Amz-Algorithm")
  valid_774627 = validateParameter(valid_774627, JString, required = false,
                                 default = nil)
  if valid_774627 != nil:
    section.add "X-Amz-Algorithm", valid_774627
  var valid_774628 = header.getOrDefault("X-Amz-Signature")
  valid_774628 = validateParameter(valid_774628, JString, required = false,
                                 default = nil)
  if valid_774628 != nil:
    section.add "X-Amz-Signature", valid_774628
  var valid_774629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774629 = validateParameter(valid_774629, JString, required = false,
                                 default = nil)
  if valid_774629 != nil:
    section.add "X-Amz-SignedHeaders", valid_774629
  var valid_774630 = header.getOrDefault("X-Amz-Credential")
  valid_774630 = validateParameter(valid_774630, JString, required = false,
                                 default = nil)
  if valid_774630 != nil:
    section.add "X-Amz-Credential", valid_774630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774631: Call_GetResetDBClusterParameterGroup_774616;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_774631.validator(path, query, header, formData, body)
  let scheme = call_774631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774631.url(scheme.get, call_774631.host, call_774631.base,
                         call_774631.route, valid.getOrDefault("path"))
  result = hook(call_774631, url, valid)

proc call*(call_774632: Call_GetResetDBClusterParameterGroup_774616;
          DBClusterParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBClusterParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-10-31"): Recallable =
  ## getResetDBClusterParameterGroup
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Version: string (required)
  var query_774633 = newJObject()
  add(query_774633, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_774633.add "Parameters", Parameters
  add(query_774633, "Action", newJString(Action))
  add(query_774633, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_774633, "Version", newJString(Version))
  result = call_774632.call(nil, query_774633, nil, nil, nil)

var getResetDBClusterParameterGroup* = Call_GetResetDBClusterParameterGroup_774616(
    name: "getResetDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_GetResetDBClusterParameterGroup_774617, base: "/",
    url: url_GetResetDBClusterParameterGroup_774618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterFromSnapshot_774680 = ref object of OpenApiRestCall_772581
proc url_PostRestoreDBClusterFromSnapshot_774682(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBClusterFromSnapshot_774681(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774683 = query.getOrDefault("Action")
  valid_774683 = validateParameter(valid_774683, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_774683 != nil:
    section.add "Action", valid_774683
  var valid_774684 = query.getOrDefault("Version")
  valid_774684 = validateParameter(valid_774684, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774684 != nil:
    section.add "Version", valid_774684
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774685 = header.getOrDefault("X-Amz-Date")
  valid_774685 = validateParameter(valid_774685, JString, required = false,
                                 default = nil)
  if valid_774685 != nil:
    section.add "X-Amz-Date", valid_774685
  var valid_774686 = header.getOrDefault("X-Amz-Security-Token")
  valid_774686 = validateParameter(valid_774686, JString, required = false,
                                 default = nil)
  if valid_774686 != nil:
    section.add "X-Amz-Security-Token", valid_774686
  var valid_774687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774687 = validateParameter(valid_774687, JString, required = false,
                                 default = nil)
  if valid_774687 != nil:
    section.add "X-Amz-Content-Sha256", valid_774687
  var valid_774688 = header.getOrDefault("X-Amz-Algorithm")
  valid_774688 = validateParameter(valid_774688, JString, required = false,
                                 default = nil)
  if valid_774688 != nil:
    section.add "X-Amz-Algorithm", valid_774688
  var valid_774689 = header.getOrDefault("X-Amz-Signature")
  valid_774689 = validateParameter(valid_774689, JString, required = false,
                                 default = nil)
  if valid_774689 != nil:
    section.add "X-Amz-Signature", valid_774689
  var valid_774690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774690 = validateParameter(valid_774690, JString, required = false,
                                 default = nil)
  if valid_774690 != nil:
    section.add "X-Amz-SignedHeaders", valid_774690
  var valid_774691 = header.getOrDefault("X-Amz-Credential")
  valid_774691 = validateParameter(valid_774691, JString, required = false,
                                 default = nil)
  if valid_774691 != nil:
    section.add "X-Amz-Credential", valid_774691
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original DB cluster.</p>
  ##   Engine: JString (required)
  ##         : <p>The database engine to use for the new DB cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new DB cluster will belong to.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The name of the DB subnet group to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB snapshot or DB cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the DB snapshot or the DB cluster snapshot.</p> </li> <li> <p>If the DB snapshot or the DB cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   SnapshotIdentifier: JString (required)
  ##                     : <p>The identifier for the DB snapshot or DB cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a DB cluster snapshot. However, you can use only the ARN to specify a DB snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the DB cluster to create from the DB snapshot or DB cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   EngineVersion: JString
  ##                : The version of the database engine to use for the new DB cluster.
  section = newJObject()
  var valid_774692 = formData.getOrDefault("Port")
  valid_774692 = validateParameter(valid_774692, JInt, required = false, default = nil)
  if valid_774692 != nil:
    section.add "Port", valid_774692
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_774693 = formData.getOrDefault("Engine")
  valid_774693 = validateParameter(valid_774693, JString, required = true,
                                 default = nil)
  if valid_774693 != nil:
    section.add "Engine", valid_774693
  var valid_774694 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_774694 = validateParameter(valid_774694, JArray, required = false,
                                 default = nil)
  if valid_774694 != nil:
    section.add "VpcSecurityGroupIds", valid_774694
  var valid_774695 = formData.getOrDefault("Tags")
  valid_774695 = validateParameter(valid_774695, JArray, required = false,
                                 default = nil)
  if valid_774695 != nil:
    section.add "Tags", valid_774695
  var valid_774696 = formData.getOrDefault("DeletionProtection")
  valid_774696 = validateParameter(valid_774696, JBool, required = false, default = nil)
  if valid_774696 != nil:
    section.add "DeletionProtection", valid_774696
  var valid_774697 = formData.getOrDefault("DBSubnetGroupName")
  valid_774697 = validateParameter(valid_774697, JString, required = false,
                                 default = nil)
  if valid_774697 != nil:
    section.add "DBSubnetGroupName", valid_774697
  var valid_774698 = formData.getOrDefault("AvailabilityZones")
  valid_774698 = validateParameter(valid_774698, JArray, required = false,
                                 default = nil)
  if valid_774698 != nil:
    section.add "AvailabilityZones", valid_774698
  var valid_774699 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_774699 = validateParameter(valid_774699, JArray, required = false,
                                 default = nil)
  if valid_774699 != nil:
    section.add "EnableCloudwatchLogsExports", valid_774699
  var valid_774700 = formData.getOrDefault("KmsKeyId")
  valid_774700 = validateParameter(valid_774700, JString, required = false,
                                 default = nil)
  if valid_774700 != nil:
    section.add "KmsKeyId", valid_774700
  var valid_774701 = formData.getOrDefault("SnapshotIdentifier")
  valid_774701 = validateParameter(valid_774701, JString, required = true,
                                 default = nil)
  if valid_774701 != nil:
    section.add "SnapshotIdentifier", valid_774701
  var valid_774702 = formData.getOrDefault("DBClusterIdentifier")
  valid_774702 = validateParameter(valid_774702, JString, required = true,
                                 default = nil)
  if valid_774702 != nil:
    section.add "DBClusterIdentifier", valid_774702
  var valid_774703 = formData.getOrDefault("EngineVersion")
  valid_774703 = validateParameter(valid_774703, JString, required = false,
                                 default = nil)
  if valid_774703 != nil:
    section.add "EngineVersion", valid_774703
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774704: Call_PostRestoreDBClusterFromSnapshot_774680;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_774704.validator(path, query, header, formData, body)
  let scheme = call_774704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774704.url(scheme.get, call_774704.host, call_774704.base,
                         call_774704.route, valid.getOrDefault("path"))
  result = hook(call_774704, url, valid)

proc call*(call_774705: Call_PostRestoreDBClusterFromSnapshot_774680;
          Engine: string; SnapshotIdentifier: string; DBClusterIdentifier: string;
          Port: int = 0; VpcSecurityGroupIds: JsonNode = nil; Tags: JsonNode = nil;
          DeletionProtection: bool = false; DBSubnetGroupName: string = "";
          Action: string = "RestoreDBClusterFromSnapshot";
          AvailabilityZones: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; KmsKeyId: string = "";
          EngineVersion: string = ""; Version: string = "2014-10-31"): Recallable =
  ## postRestoreDBClusterFromSnapshot
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ##   Port: int
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original DB cluster.</p>
  ##   Engine: string (required)
  ##         : <p>The database engine to use for the new DB cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new DB cluster will belong to.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: string
  ##                    : <p>The name of the DB subnet group to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB snapshot or DB cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the DB snapshot or the DB cluster snapshot.</p> </li> <li> <p>If the DB snapshot or the DB cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   SnapshotIdentifier: string (required)
  ##                     : <p>The identifier for the DB snapshot or DB cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a DB cluster snapshot. However, you can use only the ARN to specify a DB snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the DB cluster to create from the DB snapshot or DB cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   EngineVersion: string
  ##                : The version of the database engine to use for the new DB cluster.
  ##   Version: string (required)
  var query_774706 = newJObject()
  var formData_774707 = newJObject()
  add(formData_774707, "Port", newJInt(Port))
  add(formData_774707, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_774707.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if Tags != nil:
    formData_774707.add "Tags", Tags
  add(formData_774707, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_774707, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_774706, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_774707.add "AvailabilityZones", AvailabilityZones
  if EnableCloudwatchLogsExports != nil:
    formData_774707.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_774707, "KmsKeyId", newJString(KmsKeyId))
  add(formData_774707, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(formData_774707, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_774707, "EngineVersion", newJString(EngineVersion))
  add(query_774706, "Version", newJString(Version))
  result = call_774705.call(nil, query_774706, nil, formData_774707, nil)

var postRestoreDBClusterFromSnapshot* = Call_PostRestoreDBClusterFromSnapshot_774680(
    name: "postRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_PostRestoreDBClusterFromSnapshot_774681, base: "/",
    url: url_PostRestoreDBClusterFromSnapshot_774682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterFromSnapshot_774653 = ref object of OpenApiRestCall_772581
proc url_GetRestoreDBClusterFromSnapshot_774655(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBClusterFromSnapshot_774654(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##         : <p>The database engine to use for the new DB cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the DB cluster to create from the DB snapshot or DB cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new DB cluster will belong to.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##                    : <p>The name of the DB subnet group to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB snapshot or DB cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the DB snapshot or the DB cluster snapshot.</p> </li> <li> <p>If the DB snapshot or the DB cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   EngineVersion: JString
  ##                : The version of the database engine to use for the new DB cluster.
  ##   Port: JInt
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original DB cluster.</p>
  ##   SnapshotIdentifier: JString (required)
  ##                     : <p>The identifier for the DB snapshot or DB cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a DB cluster snapshot. However, you can use only the ARN to specify a DB snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_774656 = query.getOrDefault("Engine")
  valid_774656 = validateParameter(valid_774656, JString, required = true,
                                 default = nil)
  if valid_774656 != nil:
    section.add "Engine", valid_774656
  var valid_774657 = query.getOrDefault("AvailabilityZones")
  valid_774657 = validateParameter(valid_774657, JArray, required = false,
                                 default = nil)
  if valid_774657 != nil:
    section.add "AvailabilityZones", valid_774657
  var valid_774658 = query.getOrDefault("DBClusterIdentifier")
  valid_774658 = validateParameter(valid_774658, JString, required = true,
                                 default = nil)
  if valid_774658 != nil:
    section.add "DBClusterIdentifier", valid_774658
  var valid_774659 = query.getOrDefault("VpcSecurityGroupIds")
  valid_774659 = validateParameter(valid_774659, JArray, required = false,
                                 default = nil)
  if valid_774659 != nil:
    section.add "VpcSecurityGroupIds", valid_774659
  var valid_774660 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_774660 = validateParameter(valid_774660, JArray, required = false,
                                 default = nil)
  if valid_774660 != nil:
    section.add "EnableCloudwatchLogsExports", valid_774660
  var valid_774661 = query.getOrDefault("Tags")
  valid_774661 = validateParameter(valid_774661, JArray, required = false,
                                 default = nil)
  if valid_774661 != nil:
    section.add "Tags", valid_774661
  var valid_774662 = query.getOrDefault("DeletionProtection")
  valid_774662 = validateParameter(valid_774662, JBool, required = false, default = nil)
  if valid_774662 != nil:
    section.add "DeletionProtection", valid_774662
  var valid_774663 = query.getOrDefault("Action")
  valid_774663 = validateParameter(valid_774663, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_774663 != nil:
    section.add "Action", valid_774663
  var valid_774664 = query.getOrDefault("DBSubnetGroupName")
  valid_774664 = validateParameter(valid_774664, JString, required = false,
                                 default = nil)
  if valid_774664 != nil:
    section.add "DBSubnetGroupName", valid_774664
  var valid_774665 = query.getOrDefault("KmsKeyId")
  valid_774665 = validateParameter(valid_774665, JString, required = false,
                                 default = nil)
  if valid_774665 != nil:
    section.add "KmsKeyId", valid_774665
  var valid_774666 = query.getOrDefault("EngineVersion")
  valid_774666 = validateParameter(valid_774666, JString, required = false,
                                 default = nil)
  if valid_774666 != nil:
    section.add "EngineVersion", valid_774666
  var valid_774667 = query.getOrDefault("Port")
  valid_774667 = validateParameter(valid_774667, JInt, required = false, default = nil)
  if valid_774667 != nil:
    section.add "Port", valid_774667
  var valid_774668 = query.getOrDefault("SnapshotIdentifier")
  valid_774668 = validateParameter(valid_774668, JString, required = true,
                                 default = nil)
  if valid_774668 != nil:
    section.add "SnapshotIdentifier", valid_774668
  var valid_774669 = query.getOrDefault("Version")
  valid_774669 = validateParameter(valid_774669, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774669 != nil:
    section.add "Version", valid_774669
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774670 = header.getOrDefault("X-Amz-Date")
  valid_774670 = validateParameter(valid_774670, JString, required = false,
                                 default = nil)
  if valid_774670 != nil:
    section.add "X-Amz-Date", valid_774670
  var valid_774671 = header.getOrDefault("X-Amz-Security-Token")
  valid_774671 = validateParameter(valid_774671, JString, required = false,
                                 default = nil)
  if valid_774671 != nil:
    section.add "X-Amz-Security-Token", valid_774671
  var valid_774672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774672 = validateParameter(valid_774672, JString, required = false,
                                 default = nil)
  if valid_774672 != nil:
    section.add "X-Amz-Content-Sha256", valid_774672
  var valid_774673 = header.getOrDefault("X-Amz-Algorithm")
  valid_774673 = validateParameter(valid_774673, JString, required = false,
                                 default = nil)
  if valid_774673 != nil:
    section.add "X-Amz-Algorithm", valid_774673
  var valid_774674 = header.getOrDefault("X-Amz-Signature")
  valid_774674 = validateParameter(valid_774674, JString, required = false,
                                 default = nil)
  if valid_774674 != nil:
    section.add "X-Amz-Signature", valid_774674
  var valid_774675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774675 = validateParameter(valid_774675, JString, required = false,
                                 default = nil)
  if valid_774675 != nil:
    section.add "X-Amz-SignedHeaders", valid_774675
  var valid_774676 = header.getOrDefault("X-Amz-Credential")
  valid_774676 = validateParameter(valid_774676, JString, required = false,
                                 default = nil)
  if valid_774676 != nil:
    section.add "X-Amz-Credential", valid_774676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774677: Call_GetRestoreDBClusterFromSnapshot_774653;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_774677.validator(path, query, header, formData, body)
  let scheme = call_774677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774677.url(scheme.get, call_774677.host, call_774677.base,
                         call_774677.route, valid.getOrDefault("path"))
  result = hook(call_774677, url, valid)

proc call*(call_774678: Call_GetRestoreDBClusterFromSnapshot_774653;
          Engine: string; DBClusterIdentifier: string; SnapshotIdentifier: string;
          AvailabilityZones: JsonNode = nil; VpcSecurityGroupIds: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; Tags: JsonNode = nil;
          DeletionProtection: bool = false;
          Action: string = "RestoreDBClusterFromSnapshot";
          DBSubnetGroupName: string = ""; KmsKeyId: string = "";
          EngineVersion: string = ""; Port: int = 0; Version: string = "2014-10-31"): Recallable =
  ## getRestoreDBClusterFromSnapshot
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ##   Engine: string (required)
  ##         : <p>The database engine to use for the new DB cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the DB cluster to create from the DB snapshot or DB cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new DB cluster will belong to.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##                    : <p>The name of the DB subnet group to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB snapshot or DB cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the DB snapshot or the DB cluster snapshot.</p> </li> <li> <p>If the DB snapshot or the DB cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   EngineVersion: string
  ##                : The version of the database engine to use for the new DB cluster.
  ##   Port: int
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original DB cluster.</p>
  ##   SnapshotIdentifier: string (required)
  ##                     : <p>The identifier for the DB snapshot or DB cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a DB cluster snapshot. However, you can use only the ARN to specify a DB snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   Version: string (required)
  var query_774679 = newJObject()
  add(query_774679, "Engine", newJString(Engine))
  if AvailabilityZones != nil:
    query_774679.add "AvailabilityZones", AvailabilityZones
  add(query_774679, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_774679.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_774679.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_774679.add "Tags", Tags
  add(query_774679, "DeletionProtection", newJBool(DeletionProtection))
  add(query_774679, "Action", newJString(Action))
  add(query_774679, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_774679, "KmsKeyId", newJString(KmsKeyId))
  add(query_774679, "EngineVersion", newJString(EngineVersion))
  add(query_774679, "Port", newJInt(Port))
  add(query_774679, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(query_774679, "Version", newJString(Version))
  result = call_774678.call(nil, query_774679, nil, nil, nil)

var getRestoreDBClusterFromSnapshot* = Call_GetRestoreDBClusterFromSnapshot_774653(
    name: "getRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_GetRestoreDBClusterFromSnapshot_774654, base: "/",
    url: url_GetRestoreDBClusterFromSnapshot_774655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterToPointInTime_774734 = ref object of OpenApiRestCall_772581
proc url_PostRestoreDBClusterToPointInTime_774736(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBClusterToPointInTime_774735(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774737 = query.getOrDefault("Action")
  valid_774737 = validateParameter(valid_774737, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_774737 != nil:
    section.add "Action", valid_774737
  var valid_774738 = query.getOrDefault("Version")
  valid_774738 = validateParameter(valid_774738, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774738 != nil:
    section.add "Version", valid_774738
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774739 = header.getOrDefault("X-Amz-Date")
  valid_774739 = validateParameter(valid_774739, JString, required = false,
                                 default = nil)
  if valid_774739 != nil:
    section.add "X-Amz-Date", valid_774739
  var valid_774740 = header.getOrDefault("X-Amz-Security-Token")
  valid_774740 = validateParameter(valid_774740, JString, required = false,
                                 default = nil)
  if valid_774740 != nil:
    section.add "X-Amz-Security-Token", valid_774740
  var valid_774741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774741 = validateParameter(valid_774741, JString, required = false,
                                 default = nil)
  if valid_774741 != nil:
    section.add "X-Amz-Content-Sha256", valid_774741
  var valid_774742 = header.getOrDefault("X-Amz-Algorithm")
  valid_774742 = validateParameter(valid_774742, JString, required = false,
                                 default = nil)
  if valid_774742 != nil:
    section.add "X-Amz-Algorithm", valid_774742
  var valid_774743 = header.getOrDefault("X-Amz-Signature")
  valid_774743 = validateParameter(valid_774743, JString, required = false,
                                 default = nil)
  if valid_774743 != nil:
    section.add "X-Amz-Signature", valid_774743
  var valid_774744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774744 = validateParameter(valid_774744, JString, required = false,
                                 default = nil)
  if valid_774744 != nil:
    section.add "X-Amz-SignedHeaders", valid_774744
  var valid_774745 = header.getOrDefault("X-Amz-Credential")
  valid_774745 = validateParameter(valid_774745, JString, required = false,
                                 default = nil)
  if valid_774745 != nil:
    section.add "X-Amz-Credential", valid_774745
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBClusterIdentifier: JString (required)
  ##                            : <p>The identifier of the source DB cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   UseLatestRestorableTime: JBool
  ##                          : <p>A value that is set to <code>true</code> to restore the DB cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   Port: JInt
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new DB cluster belongs to.
  ##   RestoreToTime: JString
  ##                : <p>The date and time to restore the DB cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the DB instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The DB subnet group name to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new DB cluster and encrypt the new DB cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source DB cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB cluster is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the source DB cluster.</p> </li> <li> <p>If the DB cluster is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a DB cluster that is not encrypted, then the restore request is rejected.</p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the new DB cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterIdentifier` field"
  var valid_774746 = formData.getOrDefault("SourceDBClusterIdentifier")
  valid_774746 = validateParameter(valid_774746, JString, required = true,
                                 default = nil)
  if valid_774746 != nil:
    section.add "SourceDBClusterIdentifier", valid_774746
  var valid_774747 = formData.getOrDefault("UseLatestRestorableTime")
  valid_774747 = validateParameter(valid_774747, JBool, required = false, default = nil)
  if valid_774747 != nil:
    section.add "UseLatestRestorableTime", valid_774747
  var valid_774748 = formData.getOrDefault("Port")
  valid_774748 = validateParameter(valid_774748, JInt, required = false, default = nil)
  if valid_774748 != nil:
    section.add "Port", valid_774748
  var valid_774749 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_774749 = validateParameter(valid_774749, JArray, required = false,
                                 default = nil)
  if valid_774749 != nil:
    section.add "VpcSecurityGroupIds", valid_774749
  var valid_774750 = formData.getOrDefault("RestoreToTime")
  valid_774750 = validateParameter(valid_774750, JString, required = false,
                                 default = nil)
  if valid_774750 != nil:
    section.add "RestoreToTime", valid_774750
  var valid_774751 = formData.getOrDefault("Tags")
  valid_774751 = validateParameter(valid_774751, JArray, required = false,
                                 default = nil)
  if valid_774751 != nil:
    section.add "Tags", valid_774751
  var valid_774752 = formData.getOrDefault("DeletionProtection")
  valid_774752 = validateParameter(valid_774752, JBool, required = false, default = nil)
  if valid_774752 != nil:
    section.add "DeletionProtection", valid_774752
  var valid_774753 = formData.getOrDefault("DBSubnetGroupName")
  valid_774753 = validateParameter(valid_774753, JString, required = false,
                                 default = nil)
  if valid_774753 != nil:
    section.add "DBSubnetGroupName", valid_774753
  var valid_774754 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_774754 = validateParameter(valid_774754, JArray, required = false,
                                 default = nil)
  if valid_774754 != nil:
    section.add "EnableCloudwatchLogsExports", valid_774754
  var valid_774755 = formData.getOrDefault("KmsKeyId")
  valid_774755 = validateParameter(valid_774755, JString, required = false,
                                 default = nil)
  if valid_774755 != nil:
    section.add "KmsKeyId", valid_774755
  var valid_774756 = formData.getOrDefault("DBClusterIdentifier")
  valid_774756 = validateParameter(valid_774756, JString, required = true,
                                 default = nil)
  if valid_774756 != nil:
    section.add "DBClusterIdentifier", valid_774756
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774757: Call_PostRestoreDBClusterToPointInTime_774734;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_774757.validator(path, query, header, formData, body)
  let scheme = call_774757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774757.url(scheme.get, call_774757.host, call_774757.base,
                         call_774757.route, valid.getOrDefault("path"))
  result = hook(call_774757, url, valid)

proc call*(call_774758: Call_PostRestoreDBClusterToPointInTime_774734;
          SourceDBClusterIdentifier: string; DBClusterIdentifier: string;
          UseLatestRestorableTime: bool = false; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; RestoreToTime: string = "";
          Tags: JsonNode = nil; DeletionProtection: bool = false;
          DBSubnetGroupName: string = "";
          Action: string = "RestoreDBClusterToPointInTime";
          EnableCloudwatchLogsExports: JsonNode = nil; KmsKeyId: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postRestoreDBClusterToPointInTime
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ##   SourceDBClusterIdentifier: string (required)
  ##                            : <p>The identifier of the source DB cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   UseLatestRestorableTime: bool
  ##                          : <p>A value that is set to <code>true</code> to restore the DB cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   Port: int
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new DB cluster belongs to.
  ##   RestoreToTime: string
  ##                : <p>The date and time to restore the DB cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the DB instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: string
  ##                    : <p>The DB subnet group name to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new DB cluster and encrypt the new DB cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source DB cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB cluster is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the source DB cluster.</p> </li> <li> <p>If the DB cluster is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a DB cluster that is not encrypted, then the restore request is rejected.</p>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the new DB cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Version: string (required)
  var query_774759 = newJObject()
  var formData_774760 = newJObject()
  add(formData_774760, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(formData_774760, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_774760, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_774760.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_774760, "RestoreToTime", newJString(RestoreToTime))
  if Tags != nil:
    formData_774760.add "Tags", Tags
  add(formData_774760, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_774760, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_774759, "Action", newJString(Action))
  if EnableCloudwatchLogsExports != nil:
    formData_774760.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_774760, "KmsKeyId", newJString(KmsKeyId))
  add(formData_774760, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_774759, "Version", newJString(Version))
  result = call_774758.call(nil, query_774759, nil, formData_774760, nil)

var postRestoreDBClusterToPointInTime* = Call_PostRestoreDBClusterToPointInTime_774734(
    name: "postRestoreDBClusterToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_PostRestoreDBClusterToPointInTime_774735, base: "/",
    url: url_PostRestoreDBClusterToPointInTime_774736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterToPointInTime_774708 = ref object of OpenApiRestCall_772581
proc url_GetRestoreDBClusterToPointInTime_774710(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBClusterToPointInTime_774709(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RestoreToTime: JString
  ##                : <p>The date and time to restore the DB cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the DB instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the new DB cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new DB cluster belongs to.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   UseLatestRestorableTime: JBool
  ##                          : <p>A value that is set to <code>true</code> to restore the DB cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##                    : <p>The DB subnet group name to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new DB cluster and encrypt the new DB cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source DB cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB cluster is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the source DB cluster.</p> </li> <li> <p>If the DB cluster is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a DB cluster that is not encrypted, then the restore request is rejected.</p>
  ##   Port: JInt
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   SourceDBClusterIdentifier: JString (required)
  ##                            : <p>The identifier of the source DB cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  var valid_774711 = query.getOrDefault("RestoreToTime")
  valid_774711 = validateParameter(valid_774711, JString, required = false,
                                 default = nil)
  if valid_774711 != nil:
    section.add "RestoreToTime", valid_774711
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_774712 = query.getOrDefault("DBClusterIdentifier")
  valid_774712 = validateParameter(valid_774712, JString, required = true,
                                 default = nil)
  if valid_774712 != nil:
    section.add "DBClusterIdentifier", valid_774712
  var valid_774713 = query.getOrDefault("VpcSecurityGroupIds")
  valid_774713 = validateParameter(valid_774713, JArray, required = false,
                                 default = nil)
  if valid_774713 != nil:
    section.add "VpcSecurityGroupIds", valid_774713
  var valid_774714 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_774714 = validateParameter(valid_774714, JArray, required = false,
                                 default = nil)
  if valid_774714 != nil:
    section.add "EnableCloudwatchLogsExports", valid_774714
  var valid_774715 = query.getOrDefault("Tags")
  valid_774715 = validateParameter(valid_774715, JArray, required = false,
                                 default = nil)
  if valid_774715 != nil:
    section.add "Tags", valid_774715
  var valid_774716 = query.getOrDefault("DeletionProtection")
  valid_774716 = validateParameter(valid_774716, JBool, required = false, default = nil)
  if valid_774716 != nil:
    section.add "DeletionProtection", valid_774716
  var valid_774717 = query.getOrDefault("UseLatestRestorableTime")
  valid_774717 = validateParameter(valid_774717, JBool, required = false, default = nil)
  if valid_774717 != nil:
    section.add "UseLatestRestorableTime", valid_774717
  var valid_774718 = query.getOrDefault("Action")
  valid_774718 = validateParameter(valid_774718, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_774718 != nil:
    section.add "Action", valid_774718
  var valid_774719 = query.getOrDefault("DBSubnetGroupName")
  valid_774719 = validateParameter(valid_774719, JString, required = false,
                                 default = nil)
  if valid_774719 != nil:
    section.add "DBSubnetGroupName", valid_774719
  var valid_774720 = query.getOrDefault("KmsKeyId")
  valid_774720 = validateParameter(valid_774720, JString, required = false,
                                 default = nil)
  if valid_774720 != nil:
    section.add "KmsKeyId", valid_774720
  var valid_774721 = query.getOrDefault("Port")
  valid_774721 = validateParameter(valid_774721, JInt, required = false, default = nil)
  if valid_774721 != nil:
    section.add "Port", valid_774721
  var valid_774722 = query.getOrDefault("SourceDBClusterIdentifier")
  valid_774722 = validateParameter(valid_774722, JString, required = true,
                                 default = nil)
  if valid_774722 != nil:
    section.add "SourceDBClusterIdentifier", valid_774722
  var valid_774723 = query.getOrDefault("Version")
  valid_774723 = validateParameter(valid_774723, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774723 != nil:
    section.add "Version", valid_774723
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774724 = header.getOrDefault("X-Amz-Date")
  valid_774724 = validateParameter(valid_774724, JString, required = false,
                                 default = nil)
  if valid_774724 != nil:
    section.add "X-Amz-Date", valid_774724
  var valid_774725 = header.getOrDefault("X-Amz-Security-Token")
  valid_774725 = validateParameter(valid_774725, JString, required = false,
                                 default = nil)
  if valid_774725 != nil:
    section.add "X-Amz-Security-Token", valid_774725
  var valid_774726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774726 = validateParameter(valid_774726, JString, required = false,
                                 default = nil)
  if valid_774726 != nil:
    section.add "X-Amz-Content-Sha256", valid_774726
  var valid_774727 = header.getOrDefault("X-Amz-Algorithm")
  valid_774727 = validateParameter(valid_774727, JString, required = false,
                                 default = nil)
  if valid_774727 != nil:
    section.add "X-Amz-Algorithm", valid_774727
  var valid_774728 = header.getOrDefault("X-Amz-Signature")
  valid_774728 = validateParameter(valid_774728, JString, required = false,
                                 default = nil)
  if valid_774728 != nil:
    section.add "X-Amz-Signature", valid_774728
  var valid_774729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774729 = validateParameter(valid_774729, JString, required = false,
                                 default = nil)
  if valid_774729 != nil:
    section.add "X-Amz-SignedHeaders", valid_774729
  var valid_774730 = header.getOrDefault("X-Amz-Credential")
  valid_774730 = validateParameter(valid_774730, JString, required = false,
                                 default = nil)
  if valid_774730 != nil:
    section.add "X-Amz-Credential", valid_774730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774731: Call_GetRestoreDBClusterToPointInTime_774708;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_774731.validator(path, query, header, formData, body)
  let scheme = call_774731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774731.url(scheme.get, call_774731.host, call_774731.base,
                         call_774731.route, valid.getOrDefault("path"))
  result = hook(call_774731, url, valid)

proc call*(call_774732: Call_GetRestoreDBClusterToPointInTime_774708;
          DBClusterIdentifier: string; SourceDBClusterIdentifier: string;
          RestoreToTime: string = ""; VpcSecurityGroupIds: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; Tags: JsonNode = nil;
          DeletionProtection: bool = false; UseLatestRestorableTime: bool = false;
          Action: string = "RestoreDBClusterToPointInTime";
          DBSubnetGroupName: string = ""; KmsKeyId: string = ""; Port: int = 0;
          Version: string = "2014-10-31"): Recallable =
  ## getRestoreDBClusterToPointInTime
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ##   RestoreToTime: string
  ##                : <p>The date and time to restore the DB cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the DB instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the new DB cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new DB cluster belongs to.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   UseLatestRestorableTime: bool
  ##                          : <p>A value that is set to <code>true</code> to restore the DB cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##                    : <p>The DB subnet group name to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new DB cluster and encrypt the new DB cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source DB cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB cluster is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the source DB cluster.</p> </li> <li> <p>If the DB cluster is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a DB cluster that is not encrypted, then the restore request is rejected.</p>
  ##   Port: int
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   SourceDBClusterIdentifier: string (required)
  ##                            : <p>The identifier of the source DB cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_774733 = newJObject()
  add(query_774733, "RestoreToTime", newJString(RestoreToTime))
  add(query_774733, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_774733.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_774733.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_774733.add "Tags", Tags
  add(query_774733, "DeletionProtection", newJBool(DeletionProtection))
  add(query_774733, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_774733, "Action", newJString(Action))
  add(query_774733, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_774733, "KmsKeyId", newJString(KmsKeyId))
  add(query_774733, "Port", newJInt(Port))
  add(query_774733, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(query_774733, "Version", newJString(Version))
  result = call_774732.call(nil, query_774733, nil, nil, nil)

var getRestoreDBClusterToPointInTime* = Call_GetRestoreDBClusterToPointInTime_774708(
    name: "getRestoreDBClusterToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_GetRestoreDBClusterToPointInTime_774709, base: "/",
    url: url_GetRestoreDBClusterToPointInTime_774710,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStartDBCluster_774777 = ref object of OpenApiRestCall_772581
proc url_PostStartDBCluster_774779(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostStartDBCluster_774778(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774780 = query.getOrDefault("Action")
  valid_774780 = validateParameter(valid_774780, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_774780 != nil:
    section.add "Action", valid_774780
  var valid_774781 = query.getOrDefault("Version")
  valid_774781 = validateParameter(valid_774781, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774781 != nil:
    section.add "Version", valid_774781
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774782 = header.getOrDefault("X-Amz-Date")
  valid_774782 = validateParameter(valid_774782, JString, required = false,
                                 default = nil)
  if valid_774782 != nil:
    section.add "X-Amz-Date", valid_774782
  var valid_774783 = header.getOrDefault("X-Amz-Security-Token")
  valid_774783 = validateParameter(valid_774783, JString, required = false,
                                 default = nil)
  if valid_774783 != nil:
    section.add "X-Amz-Security-Token", valid_774783
  var valid_774784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774784 = validateParameter(valid_774784, JString, required = false,
                                 default = nil)
  if valid_774784 != nil:
    section.add "X-Amz-Content-Sha256", valid_774784
  var valid_774785 = header.getOrDefault("X-Amz-Algorithm")
  valid_774785 = validateParameter(valid_774785, JString, required = false,
                                 default = nil)
  if valid_774785 != nil:
    section.add "X-Amz-Algorithm", valid_774785
  var valid_774786 = header.getOrDefault("X-Amz-Signature")
  valid_774786 = validateParameter(valid_774786, JString, required = false,
                                 default = nil)
  if valid_774786 != nil:
    section.add "X-Amz-Signature", valid_774786
  var valid_774787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774787 = validateParameter(valid_774787, JString, required = false,
                                 default = nil)
  if valid_774787 != nil:
    section.add "X-Amz-SignedHeaders", valid_774787
  var valid_774788 = header.getOrDefault("X-Amz-Credential")
  valid_774788 = validateParameter(valid_774788, JString, required = false,
                                 default = nil)
  if valid_774788 != nil:
    section.add "X-Amz-Credential", valid_774788
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_774789 = formData.getOrDefault("DBClusterIdentifier")
  valid_774789 = validateParameter(valid_774789, JString, required = true,
                                 default = nil)
  if valid_774789 != nil:
    section.add "DBClusterIdentifier", valid_774789
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774790: Call_PostStartDBCluster_774777; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_774790.validator(path, query, header, formData, body)
  let scheme = call_774790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774790.url(scheme.get, call_774790.host, call_774790.base,
                         call_774790.route, valid.getOrDefault("path"))
  result = hook(call_774790, url, valid)

proc call*(call_774791: Call_PostStartDBCluster_774777;
          DBClusterIdentifier: string; Action: string = "StartDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## postStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_774792 = newJObject()
  var formData_774793 = newJObject()
  add(query_774792, "Action", newJString(Action))
  add(formData_774793, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_774792, "Version", newJString(Version))
  result = call_774791.call(nil, query_774792, nil, formData_774793, nil)

var postStartDBCluster* = Call_PostStartDBCluster_774777(
    name: "postStartDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=StartDBCluster",
    validator: validate_PostStartDBCluster_774778, base: "/",
    url: url_PostStartDBCluster_774779, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStartDBCluster_774761 = ref object of OpenApiRestCall_772581
proc url_GetStartDBCluster_774763(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetStartDBCluster_774762(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_774764 = query.getOrDefault("DBClusterIdentifier")
  valid_774764 = validateParameter(valid_774764, JString, required = true,
                                 default = nil)
  if valid_774764 != nil:
    section.add "DBClusterIdentifier", valid_774764
  var valid_774765 = query.getOrDefault("Action")
  valid_774765 = validateParameter(valid_774765, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_774765 != nil:
    section.add "Action", valid_774765
  var valid_774766 = query.getOrDefault("Version")
  valid_774766 = validateParameter(valid_774766, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_774766 != nil:
    section.add "Version", valid_774766
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774767 = header.getOrDefault("X-Amz-Date")
  valid_774767 = validateParameter(valid_774767, JString, required = false,
                                 default = nil)
  if valid_774767 != nil:
    section.add "X-Amz-Date", valid_774767
  var valid_774768 = header.getOrDefault("X-Amz-Security-Token")
  valid_774768 = validateParameter(valid_774768, JString, required = false,
                                 default = nil)
  if valid_774768 != nil:
    section.add "X-Amz-Security-Token", valid_774768
  var valid_774769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774769 = validateParameter(valid_774769, JString, required = false,
                                 default = nil)
  if valid_774769 != nil:
    section.add "X-Amz-Content-Sha256", valid_774769
  var valid_774770 = header.getOrDefault("X-Amz-Algorithm")
  valid_774770 = validateParameter(valid_774770, JString, required = false,
                                 default = nil)
  if valid_774770 != nil:
    section.add "X-Amz-Algorithm", valid_774770
  var valid_774771 = header.getOrDefault("X-Amz-Signature")
  valid_774771 = validateParameter(valid_774771, JString, required = false,
                                 default = nil)
  if valid_774771 != nil:
    section.add "X-Amz-Signature", valid_774771
  var valid_774772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774772 = validateParameter(valid_774772, JString, required = false,
                                 default = nil)
  if valid_774772 != nil:
    section.add "X-Amz-SignedHeaders", valid_774772
  var valid_774773 = header.getOrDefault("X-Amz-Credential")
  valid_774773 = validateParameter(valid_774773, JString, required = false,
                                 default = nil)
  if valid_774773 != nil:
    section.add "X-Amz-Credential", valid_774773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774774: Call_GetStartDBCluster_774761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_774774.validator(path, query, header, formData, body)
  let scheme = call_774774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774774.url(scheme.get, call_774774.host, call_774774.base,
                         call_774774.route, valid.getOrDefault("path"))
  result = hook(call_774774, url, valid)

proc call*(call_774775: Call_GetStartDBCluster_774761; DBClusterIdentifier: string;
          Action: string = "StartDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774776 = newJObject()
  add(query_774776, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_774776, "Action", newJString(Action))
  add(query_774776, "Version", newJString(Version))
  result = call_774775.call(nil, query_774776, nil, nil, nil)

var getStartDBCluster* = Call_GetStartDBCluster_774761(name: "getStartDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StartDBCluster", validator: validate_GetStartDBCluster_774762,
    base: "/", url: url_GetStartDBCluster_774763,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStopDBCluster_774810 = ref object of OpenApiRestCall_772581
proc url_PostStopDBCluster_774812(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostStopDBCluster_774811(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
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
                                 default = newJString("StopDBCluster"))
  if valid_774813 != nil:
    section.add "Action", valid_774813
  var valid_774814 = query.getOrDefault("Version")
  valid_774814 = validateParameter(valid_774814, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_774822 = formData.getOrDefault("DBClusterIdentifier")
  valid_774822 = validateParameter(valid_774822, JString, required = true,
                                 default = nil)
  if valid_774822 != nil:
    section.add "DBClusterIdentifier", valid_774822
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774823: Call_PostStopDBCluster_774810; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_774823.validator(path, query, header, formData, body)
  let scheme = call_774823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774823.url(scheme.get, call_774823.host, call_774823.base,
                         call_774823.route, valid.getOrDefault("path"))
  result = hook(call_774823, url, valid)

proc call*(call_774824: Call_PostStopDBCluster_774810; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## postStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_774825 = newJObject()
  var formData_774826 = newJObject()
  add(query_774825, "Action", newJString(Action))
  add(formData_774826, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_774825, "Version", newJString(Version))
  result = call_774824.call(nil, query_774825, nil, formData_774826, nil)

var postStopDBCluster* = Call_PostStopDBCluster_774810(name: "postStopDBCluster",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_PostStopDBCluster_774811,
    base: "/", url: url_PostStopDBCluster_774812,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStopDBCluster_774794 = ref object of OpenApiRestCall_772581
proc url_GetStopDBCluster_774796(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetStopDBCluster_774795(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_774797 = query.getOrDefault("DBClusterIdentifier")
  valid_774797 = validateParameter(valid_774797, JString, required = true,
                                 default = nil)
  if valid_774797 != nil:
    section.add "DBClusterIdentifier", valid_774797
  var valid_774798 = query.getOrDefault("Action")
  valid_774798 = validateParameter(valid_774798, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_774798 != nil:
    section.add "Action", valid_774798
  var valid_774799 = query.getOrDefault("Version")
  valid_774799 = validateParameter(valid_774799, JString, required = true,
                                 default = newJString("2014-10-31"))
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

proc call*(call_774807: Call_GetStopDBCluster_774794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_774807.validator(path, query, header, formData, body)
  let scheme = call_774807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774807.url(scheme.get, call_774807.host, call_774807.base,
                         call_774807.route, valid.getOrDefault("path"))
  result = hook(call_774807, url, valid)

proc call*(call_774808: Call_GetStopDBCluster_774794; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774809 = newJObject()
  add(query_774809, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_774809, "Action", newJString(Action))
  add(query_774809, "Version", newJString(Version))
  result = call_774808.call(nil, query_774809, nil, nil, nil)

var getStopDBCluster* = Call_GetStopDBCluster_774794(name: "getStopDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_GetStopDBCluster_774795,
    base: "/", url: url_GetStopDBCluster_774796,
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
