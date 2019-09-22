
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

  OpenApiRestCall_602417 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602417](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602417): Option[Scheme] {.used.} =
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
  awsServiceName = "docdb"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostAddTagsToResource_603026 = ref object of OpenApiRestCall_602417
proc url_PostAddTagsToResource_603028(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddTagsToResource_603027(path: JsonNode; query: JsonNode;
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
  var valid_603029 = query.getOrDefault("Action")
  valid_603029 = validateParameter(valid_603029, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_603029 != nil:
    section.add "Action", valid_603029
  var valid_603030 = query.getOrDefault("Version")
  valid_603030 = validateParameter(valid_603030, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603030 != nil:
    section.add "Version", valid_603030
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603031 = header.getOrDefault("X-Amz-Date")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-Date", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Security-Token")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Security-Token", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-Content-Sha256", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Algorithm")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Algorithm", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-Signature")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Signature", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-SignedHeaders", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-Credential")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-Credential", valid_603037
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_603038 = formData.getOrDefault("Tags")
  valid_603038 = validateParameter(valid_603038, JArray, required = true, default = nil)
  if valid_603038 != nil:
    section.add "Tags", valid_603038
  var valid_603039 = formData.getOrDefault("ResourceName")
  valid_603039 = validateParameter(valid_603039, JString, required = true,
                                 default = nil)
  if valid_603039 != nil:
    section.add "ResourceName", valid_603039
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603040: Call_PostAddTagsToResource_603026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_603040.validator(path, query, header, formData, body)
  let scheme = call_603040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603040.url(scheme.get, call_603040.host, call_603040.base,
                         call_603040.route, valid.getOrDefault("path"))
  result = hook(call_603040, url, valid)

proc call*(call_603041: Call_PostAddTagsToResource_603026; Tags: JsonNode;
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
  var query_603042 = newJObject()
  var formData_603043 = newJObject()
  if Tags != nil:
    formData_603043.add "Tags", Tags
  add(query_603042, "Action", newJString(Action))
  add(formData_603043, "ResourceName", newJString(ResourceName))
  add(query_603042, "Version", newJString(Version))
  result = call_603041.call(nil, query_603042, nil, formData_603043, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_603026(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_603027, base: "/",
    url: url_PostAddTagsToResource_603028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_602754 = ref object of OpenApiRestCall_602417
proc url_GetAddTagsToResource_602756(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddTagsToResource_602755(path: JsonNode; query: JsonNode;
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
  var valid_602868 = query.getOrDefault("Tags")
  valid_602868 = validateParameter(valid_602868, JArray, required = true, default = nil)
  if valid_602868 != nil:
    section.add "Tags", valid_602868
  var valid_602869 = query.getOrDefault("ResourceName")
  valid_602869 = validateParameter(valid_602869, JString, required = true,
                                 default = nil)
  if valid_602869 != nil:
    section.add "ResourceName", valid_602869
  var valid_602883 = query.getOrDefault("Action")
  valid_602883 = validateParameter(valid_602883, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_602883 != nil:
    section.add "Action", valid_602883
  var valid_602884 = query.getOrDefault("Version")
  valid_602884 = validateParameter(valid_602884, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602884 != nil:
    section.add "Version", valid_602884
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602885 = header.getOrDefault("X-Amz-Date")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Date", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Security-Token")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Security-Token", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Content-Sha256", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Algorithm")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Algorithm", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-Signature")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Signature", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-SignedHeaders", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Credential")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Credential", valid_602891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602914: Call_GetAddTagsToResource_602754; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_602914.validator(path, query, header, formData, body)
  let scheme = call_602914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602914.url(scheme.get, call_602914.host, call_602914.base,
                         call_602914.route, valid.getOrDefault("path"))
  result = hook(call_602914, url, valid)

proc call*(call_602985: Call_GetAddTagsToResource_602754; Tags: JsonNode;
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
  var query_602986 = newJObject()
  if Tags != nil:
    query_602986.add "Tags", Tags
  add(query_602986, "ResourceName", newJString(ResourceName))
  add(query_602986, "Action", newJString(Action))
  add(query_602986, "Version", newJString(Version))
  result = call_602985.call(nil, query_602986, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_602754(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_602755, base: "/",
    url: url_GetAddTagsToResource_602756, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyPendingMaintenanceAction_603062 = ref object of OpenApiRestCall_602417
proc url_PostApplyPendingMaintenanceAction_603064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostApplyPendingMaintenanceAction_603063(path: JsonNode;
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
  var valid_603065 = query.getOrDefault("Action")
  valid_603065 = validateParameter(valid_603065, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_603065 != nil:
    section.add "Action", valid_603065
  var valid_603066 = query.getOrDefault("Version")
  valid_603066 = validateParameter(valid_603066, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603066 != nil:
    section.add "Version", valid_603066
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603067 = header.getOrDefault("X-Amz-Date")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Date", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Security-Token")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Security-Token", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Content-Sha256", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Algorithm")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Algorithm", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Signature")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Signature", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-SignedHeaders", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Credential")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Credential", valid_603073
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
  var valid_603074 = formData.getOrDefault("ApplyAction")
  valid_603074 = validateParameter(valid_603074, JString, required = true,
                                 default = nil)
  if valid_603074 != nil:
    section.add "ApplyAction", valid_603074
  var valid_603075 = formData.getOrDefault("ResourceIdentifier")
  valid_603075 = validateParameter(valid_603075, JString, required = true,
                                 default = nil)
  if valid_603075 != nil:
    section.add "ResourceIdentifier", valid_603075
  var valid_603076 = formData.getOrDefault("OptInType")
  valid_603076 = validateParameter(valid_603076, JString, required = true,
                                 default = nil)
  if valid_603076 != nil:
    section.add "OptInType", valid_603076
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603077: Call_PostApplyPendingMaintenanceAction_603062;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_603077.validator(path, query, header, formData, body)
  let scheme = call_603077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603077.url(scheme.get, call_603077.host, call_603077.base,
                         call_603077.route, valid.getOrDefault("path"))
  result = hook(call_603077, url, valid)

proc call*(call_603078: Call_PostApplyPendingMaintenanceAction_603062;
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
  var query_603079 = newJObject()
  var formData_603080 = newJObject()
  add(query_603079, "Action", newJString(Action))
  add(formData_603080, "ApplyAction", newJString(ApplyAction))
  add(formData_603080, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(formData_603080, "OptInType", newJString(OptInType))
  add(query_603079, "Version", newJString(Version))
  result = call_603078.call(nil, query_603079, nil, formData_603080, nil)

var postApplyPendingMaintenanceAction* = Call_PostApplyPendingMaintenanceAction_603062(
    name: "postApplyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_PostApplyPendingMaintenanceAction_603063, base: "/",
    url: url_PostApplyPendingMaintenanceAction_603064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyPendingMaintenanceAction_603044 = ref object of OpenApiRestCall_602417
proc url_GetApplyPendingMaintenanceAction_603046(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApplyPendingMaintenanceAction_603045(path: JsonNode;
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
  var valid_603047 = query.getOrDefault("ApplyAction")
  valid_603047 = validateParameter(valid_603047, JString, required = true,
                                 default = nil)
  if valid_603047 != nil:
    section.add "ApplyAction", valid_603047
  var valid_603048 = query.getOrDefault("ResourceIdentifier")
  valid_603048 = validateParameter(valid_603048, JString, required = true,
                                 default = nil)
  if valid_603048 != nil:
    section.add "ResourceIdentifier", valid_603048
  var valid_603049 = query.getOrDefault("Action")
  valid_603049 = validateParameter(valid_603049, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_603049 != nil:
    section.add "Action", valid_603049
  var valid_603050 = query.getOrDefault("OptInType")
  valid_603050 = validateParameter(valid_603050, JString, required = true,
                                 default = nil)
  if valid_603050 != nil:
    section.add "OptInType", valid_603050
  var valid_603051 = query.getOrDefault("Version")
  valid_603051 = validateParameter(valid_603051, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603051 != nil:
    section.add "Version", valid_603051
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603052 = header.getOrDefault("X-Amz-Date")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Date", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-Security-Token")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Security-Token", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Content-Sha256", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-Algorithm")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-Algorithm", valid_603055
  var valid_603056 = header.getOrDefault("X-Amz-Signature")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "X-Amz-Signature", valid_603056
  var valid_603057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-SignedHeaders", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Credential")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Credential", valid_603058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603059: Call_GetApplyPendingMaintenanceAction_603044;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_603059.validator(path, query, header, formData, body)
  let scheme = call_603059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603059.url(scheme.get, call_603059.host, call_603059.base,
                         call_603059.route, valid.getOrDefault("path"))
  result = hook(call_603059, url, valid)

proc call*(call_603060: Call_GetApplyPendingMaintenanceAction_603044;
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
  var query_603061 = newJObject()
  add(query_603061, "ApplyAction", newJString(ApplyAction))
  add(query_603061, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_603061, "Action", newJString(Action))
  add(query_603061, "OptInType", newJString(OptInType))
  add(query_603061, "Version", newJString(Version))
  result = call_603060.call(nil, query_603061, nil, nil, nil)

var getApplyPendingMaintenanceAction* = Call_GetApplyPendingMaintenanceAction_603044(
    name: "getApplyPendingMaintenanceAction", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_GetApplyPendingMaintenanceAction_603045, base: "/",
    url: url_GetApplyPendingMaintenanceAction_603046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterParameterGroup_603100 = ref object of OpenApiRestCall_602417
proc url_PostCopyDBClusterParameterGroup_603102(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBClusterParameterGroup_603101(path: JsonNode;
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
  var valid_603103 = query.getOrDefault("Action")
  valid_603103 = validateParameter(valid_603103, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_603103 != nil:
    section.add "Action", valid_603103
  var valid_603104 = query.getOrDefault("Version")
  valid_603104 = validateParameter(valid_603104, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603104 != nil:
    section.add "Version", valid_603104
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Content-Sha256", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Algorithm")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Algorithm", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Signature")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Signature", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-SignedHeaders", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Credential")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Credential", valid_603111
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
  var valid_603112 = formData.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_603112 = validateParameter(valid_603112, JString, required = true,
                                 default = nil)
  if valid_603112 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_603112
  var valid_603113 = formData.getOrDefault("Tags")
  valid_603113 = validateParameter(valid_603113, JArray, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "Tags", valid_603113
  var valid_603114 = formData.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_603114 = validateParameter(valid_603114, JString, required = true,
                                 default = nil)
  if valid_603114 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_603114
  var valid_603115 = formData.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_603115 = validateParameter(valid_603115, JString, required = true,
                                 default = nil)
  if valid_603115 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_603115
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603116: Call_PostCopyDBClusterParameterGroup_603100;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_603116.validator(path, query, header, formData, body)
  let scheme = call_603116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603116.url(scheme.get, call_603116.host, call_603116.base,
                         call_603116.route, valid.getOrDefault("path"))
  result = hook(call_603116, url, valid)

proc call*(call_603117: Call_PostCopyDBClusterParameterGroup_603100;
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
  var query_603118 = newJObject()
  var formData_603119 = newJObject()
  add(formData_603119, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  if Tags != nil:
    formData_603119.add "Tags", Tags
  add(query_603118, "Action", newJString(Action))
  add(formData_603119, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(formData_603119, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_603118, "Version", newJString(Version))
  result = call_603117.call(nil, query_603118, nil, formData_603119, nil)

var postCopyDBClusterParameterGroup* = Call_PostCopyDBClusterParameterGroup_603100(
    name: "postCopyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_PostCopyDBClusterParameterGroup_603101, base: "/",
    url: url_PostCopyDBClusterParameterGroup_603102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterParameterGroup_603081 = ref object of OpenApiRestCall_602417
proc url_GetCopyDBClusterParameterGroup_603083(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBClusterParameterGroup_603082(path: JsonNode;
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
  var valid_603084 = query.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_603084 = validateParameter(valid_603084, JString, required = true,
                                 default = nil)
  if valid_603084 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_603084
  var valid_603085 = query.getOrDefault("Tags")
  valid_603085 = validateParameter(valid_603085, JArray, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "Tags", valid_603085
  var valid_603086 = query.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_603086 = validateParameter(valid_603086, JString, required = true,
                                 default = nil)
  if valid_603086 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_603086
  var valid_603087 = query.getOrDefault("Action")
  valid_603087 = validateParameter(valid_603087, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_603087 != nil:
    section.add "Action", valid_603087
  var valid_603088 = query.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_603088 = validateParameter(valid_603088, JString, required = true,
                                 default = nil)
  if valid_603088 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_603088
  var valid_603089 = query.getOrDefault("Version")
  valid_603089 = validateParameter(valid_603089, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603089 != nil:
    section.add "Version", valid_603089
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Content-Sha256", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Algorithm")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Algorithm", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Signature")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Signature", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-SignedHeaders", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Credential")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Credential", valid_603096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603097: Call_GetCopyDBClusterParameterGroup_603081; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_603097.validator(path, query, header, formData, body)
  let scheme = call_603097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603097.url(scheme.get, call_603097.host, call_603097.base,
                         call_603097.route, valid.getOrDefault("path"))
  result = hook(call_603097, url, valid)

proc call*(call_603098: Call_GetCopyDBClusterParameterGroup_603081;
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
  var query_603099 = newJObject()
  add(query_603099, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  if Tags != nil:
    query_603099.add "Tags", Tags
  add(query_603099, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  add(query_603099, "Action", newJString(Action))
  add(query_603099, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_603099, "Version", newJString(Version))
  result = call_603098.call(nil, query_603099, nil, nil, nil)

var getCopyDBClusterParameterGroup* = Call_GetCopyDBClusterParameterGroup_603081(
    name: "getCopyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_GetCopyDBClusterParameterGroup_603082, base: "/",
    url: url_GetCopyDBClusterParameterGroup_603083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterSnapshot_603141 = ref object of OpenApiRestCall_602417
proc url_PostCopyDBClusterSnapshot_603143(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBClusterSnapshot_603142(path: JsonNode; query: JsonNode;
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
  var valid_603144 = query.getOrDefault("Action")
  valid_603144 = validateParameter(valid_603144, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_603144 != nil:
    section.add "Action", valid_603144
  var valid_603145 = query.getOrDefault("Version")
  valid_603145 = validateParameter(valid_603145, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603145 != nil:
    section.add "Version", valid_603145
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603146 = header.getOrDefault("X-Amz-Date")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Date", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-Security-Token")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Security-Token", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Content-Sha256", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Algorithm")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Algorithm", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Signature")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Signature", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-SignedHeaders", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Credential")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Credential", valid_603152
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
  var valid_603153 = formData.getOrDefault("PreSignedUrl")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "PreSignedUrl", valid_603153
  var valid_603154 = formData.getOrDefault("Tags")
  valid_603154 = validateParameter(valid_603154, JArray, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "Tags", valid_603154
  var valid_603155 = formData.getOrDefault("CopyTags")
  valid_603155 = validateParameter(valid_603155, JBool, required = false, default = nil)
  if valid_603155 != nil:
    section.add "CopyTags", valid_603155
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterSnapshotIdentifier` field"
  var valid_603156 = formData.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_603156 = validateParameter(valid_603156, JString, required = true,
                                 default = nil)
  if valid_603156 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_603156
  var valid_603157 = formData.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_603157 = validateParameter(valid_603157, JString, required = true,
                                 default = nil)
  if valid_603157 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_603157
  var valid_603158 = formData.getOrDefault("KmsKeyId")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "KmsKeyId", valid_603158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_PostCopyDBClusterSnapshot_603141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_PostCopyDBClusterSnapshot_603141;
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
  var query_603161 = newJObject()
  var formData_603162 = newJObject()
  add(formData_603162, "PreSignedUrl", newJString(PreSignedUrl))
  if Tags != nil:
    formData_603162.add "Tags", Tags
  add(formData_603162, "CopyTags", newJBool(CopyTags))
  add(formData_603162, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(formData_603162, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_603161, "Action", newJString(Action))
  add(formData_603162, "KmsKeyId", newJString(KmsKeyId))
  add(query_603161, "Version", newJString(Version))
  result = call_603160.call(nil, query_603161, nil, formData_603162, nil)

var postCopyDBClusterSnapshot* = Call_PostCopyDBClusterSnapshot_603141(
    name: "postCopyDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_PostCopyDBClusterSnapshot_603142, base: "/",
    url: url_PostCopyDBClusterSnapshot_603143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterSnapshot_603120 = ref object of OpenApiRestCall_602417
proc url_GetCopyDBClusterSnapshot_603122(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBClusterSnapshot_603121(path: JsonNode; query: JsonNode;
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
  var valid_603123 = query.getOrDefault("PreSignedUrl")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "PreSignedUrl", valid_603123
  assert query != nil, "query argument is necessary due to required `TargetDBClusterSnapshotIdentifier` field"
  var valid_603124 = query.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_603124 = validateParameter(valid_603124, JString, required = true,
                                 default = nil)
  if valid_603124 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_603124
  var valid_603125 = query.getOrDefault("Tags")
  valid_603125 = validateParameter(valid_603125, JArray, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "Tags", valid_603125
  var valid_603126 = query.getOrDefault("Action")
  valid_603126 = validateParameter(valid_603126, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_603126 != nil:
    section.add "Action", valid_603126
  var valid_603127 = query.getOrDefault("KmsKeyId")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "KmsKeyId", valid_603127
  var valid_603128 = query.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_603128 = validateParameter(valid_603128, JString, required = true,
                                 default = nil)
  if valid_603128 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_603128
  var valid_603129 = query.getOrDefault("Version")
  valid_603129 = validateParameter(valid_603129, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603129 != nil:
    section.add "Version", valid_603129
  var valid_603130 = query.getOrDefault("CopyTags")
  valid_603130 = validateParameter(valid_603130, JBool, required = false, default = nil)
  if valid_603130 != nil:
    section.add "CopyTags", valid_603130
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603131 = header.getOrDefault("X-Amz-Date")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Date", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Security-Token")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Security-Token", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Content-Sha256", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Algorithm")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Algorithm", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Signature")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Signature", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-SignedHeaders", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Credential")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Credential", valid_603137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603138: Call_GetCopyDBClusterSnapshot_603120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_603138.validator(path, query, header, formData, body)
  let scheme = call_603138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603138.url(scheme.get, call_603138.host, call_603138.base,
                         call_603138.route, valid.getOrDefault("path"))
  result = hook(call_603138, url, valid)

proc call*(call_603139: Call_GetCopyDBClusterSnapshot_603120;
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
  var query_603140 = newJObject()
  add(query_603140, "PreSignedUrl", newJString(PreSignedUrl))
  add(query_603140, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  if Tags != nil:
    query_603140.add "Tags", Tags
  add(query_603140, "Action", newJString(Action))
  add(query_603140, "KmsKeyId", newJString(KmsKeyId))
  add(query_603140, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(query_603140, "Version", newJString(Version))
  add(query_603140, "CopyTags", newJBool(CopyTags))
  result = call_603139.call(nil, query_603140, nil, nil, nil)

var getCopyDBClusterSnapshot* = Call_GetCopyDBClusterSnapshot_603120(
    name: "getCopyDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_GetCopyDBClusterSnapshot_603121, base: "/",
    url: url_GetCopyDBClusterSnapshot_603122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBCluster_603196 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBCluster_603198(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBCluster_603197(path: JsonNode; query: JsonNode;
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
  var valid_603199 = query.getOrDefault("Action")
  valid_603199 = validateParameter(valid_603199, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_603199 != nil:
    section.add "Action", valid_603199
  var valid_603200 = query.getOrDefault("Version")
  valid_603200 = validateParameter(valid_603200, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603200 != nil:
    section.add "Version", valid_603200
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603201 = header.getOrDefault("X-Amz-Date")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Date", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Security-Token")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Security-Token", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Content-Sha256", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Algorithm")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Algorithm", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Signature")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Signature", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-SignedHeaders", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Credential")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Credential", valid_603207
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
  var valid_603208 = formData.getOrDefault("Port")
  valid_603208 = validateParameter(valid_603208, JInt, required = false, default = nil)
  if valid_603208 != nil:
    section.add "Port", valid_603208
  var valid_603209 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603209 = validateParameter(valid_603209, JArray, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "VpcSecurityGroupIds", valid_603209
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_603210 = formData.getOrDefault("Engine")
  valid_603210 = validateParameter(valid_603210, JString, required = true,
                                 default = nil)
  if valid_603210 != nil:
    section.add "Engine", valid_603210
  var valid_603211 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603211 = validateParameter(valid_603211, JInt, required = false, default = nil)
  if valid_603211 != nil:
    section.add "BackupRetentionPeriod", valid_603211
  var valid_603212 = formData.getOrDefault("Tags")
  valid_603212 = validateParameter(valid_603212, JArray, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "Tags", valid_603212
  var valid_603213 = formData.getOrDefault("MasterUserPassword")
  valid_603213 = validateParameter(valid_603213, JString, required = true,
                                 default = nil)
  if valid_603213 != nil:
    section.add "MasterUserPassword", valid_603213
  var valid_603214 = formData.getOrDefault("DeletionProtection")
  valid_603214 = validateParameter(valid_603214, JBool, required = false, default = nil)
  if valid_603214 != nil:
    section.add "DeletionProtection", valid_603214
  var valid_603215 = formData.getOrDefault("DBSubnetGroupName")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "DBSubnetGroupName", valid_603215
  var valid_603216 = formData.getOrDefault("AvailabilityZones")
  valid_603216 = validateParameter(valid_603216, JArray, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "AvailabilityZones", valid_603216
  var valid_603217 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "DBClusterParameterGroupName", valid_603217
  var valid_603218 = formData.getOrDefault("MasterUsername")
  valid_603218 = validateParameter(valid_603218, JString, required = true,
                                 default = nil)
  if valid_603218 != nil:
    section.add "MasterUsername", valid_603218
  var valid_603219 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_603219 = validateParameter(valid_603219, JArray, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "EnableCloudwatchLogsExports", valid_603219
  var valid_603220 = formData.getOrDefault("PreferredBackupWindow")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "PreferredBackupWindow", valid_603220
  var valid_603221 = formData.getOrDefault("KmsKeyId")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "KmsKeyId", valid_603221
  var valid_603222 = formData.getOrDefault("StorageEncrypted")
  valid_603222 = validateParameter(valid_603222, JBool, required = false, default = nil)
  if valid_603222 != nil:
    section.add "StorageEncrypted", valid_603222
  var valid_603223 = formData.getOrDefault("DBClusterIdentifier")
  valid_603223 = validateParameter(valid_603223, JString, required = true,
                                 default = nil)
  if valid_603223 != nil:
    section.add "DBClusterIdentifier", valid_603223
  var valid_603224 = formData.getOrDefault("EngineVersion")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "EngineVersion", valid_603224
  var valid_603225 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "PreferredMaintenanceWindow", valid_603225
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603226: Call_PostCreateDBCluster_603196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_603226.validator(path, query, header, formData, body)
  let scheme = call_603226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603226.url(scheme.get, call_603226.host, call_603226.base,
                         call_603226.route, valid.getOrDefault("path"))
  result = hook(call_603226, url, valid)

proc call*(call_603227: Call_PostCreateDBCluster_603196; Engine: string;
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
  var query_603228 = newJObject()
  var formData_603229 = newJObject()
  add(formData_603229, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_603229.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_603229, "Engine", newJString(Engine))
  add(formData_603229, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if Tags != nil:
    formData_603229.add "Tags", Tags
  add(formData_603229, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_603229, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_603229, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603228, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_603229.add "AvailabilityZones", AvailabilityZones
  add(formData_603229, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_603229, "MasterUsername", newJString(MasterUsername))
  if EnableCloudwatchLogsExports != nil:
    formData_603229.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_603229, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603229, "KmsKeyId", newJString(KmsKeyId))
  add(formData_603229, "StorageEncrypted", newJBool(StorageEncrypted))
  add(formData_603229, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_603229, "EngineVersion", newJString(EngineVersion))
  add(query_603228, "Version", newJString(Version))
  add(formData_603229, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_603227.call(nil, query_603228, nil, formData_603229, nil)

var postCreateDBCluster* = Call_PostCreateDBCluster_603196(
    name: "postCreateDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBCluster",
    validator: validate_PostCreateDBCluster_603197, base: "/",
    url: url_PostCreateDBCluster_603198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBCluster_603163 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBCluster_603165(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBCluster_603164(path: JsonNode; query: JsonNode;
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
  var valid_603166 = query.getOrDefault("Engine")
  valid_603166 = validateParameter(valid_603166, JString, required = true,
                                 default = nil)
  if valid_603166 != nil:
    section.add "Engine", valid_603166
  var valid_603167 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "PreferredMaintenanceWindow", valid_603167
  var valid_603168 = query.getOrDefault("DBClusterParameterGroupName")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "DBClusterParameterGroupName", valid_603168
  var valid_603169 = query.getOrDefault("StorageEncrypted")
  valid_603169 = validateParameter(valid_603169, JBool, required = false, default = nil)
  if valid_603169 != nil:
    section.add "StorageEncrypted", valid_603169
  var valid_603170 = query.getOrDefault("AvailabilityZones")
  valid_603170 = validateParameter(valid_603170, JArray, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "AvailabilityZones", valid_603170
  var valid_603171 = query.getOrDefault("DBClusterIdentifier")
  valid_603171 = validateParameter(valid_603171, JString, required = true,
                                 default = nil)
  if valid_603171 != nil:
    section.add "DBClusterIdentifier", valid_603171
  var valid_603172 = query.getOrDefault("MasterUserPassword")
  valid_603172 = validateParameter(valid_603172, JString, required = true,
                                 default = nil)
  if valid_603172 != nil:
    section.add "MasterUserPassword", valid_603172
  var valid_603173 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603173 = validateParameter(valid_603173, JArray, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "VpcSecurityGroupIds", valid_603173
  var valid_603174 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_603174 = validateParameter(valid_603174, JArray, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "EnableCloudwatchLogsExports", valid_603174
  var valid_603175 = query.getOrDefault("Tags")
  valid_603175 = validateParameter(valid_603175, JArray, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "Tags", valid_603175
  var valid_603176 = query.getOrDefault("BackupRetentionPeriod")
  valid_603176 = validateParameter(valid_603176, JInt, required = false, default = nil)
  if valid_603176 != nil:
    section.add "BackupRetentionPeriod", valid_603176
  var valid_603177 = query.getOrDefault("DeletionProtection")
  valid_603177 = validateParameter(valid_603177, JBool, required = false, default = nil)
  if valid_603177 != nil:
    section.add "DeletionProtection", valid_603177
  var valid_603178 = query.getOrDefault("Action")
  valid_603178 = validateParameter(valid_603178, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_603178 != nil:
    section.add "Action", valid_603178
  var valid_603179 = query.getOrDefault("DBSubnetGroupName")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "DBSubnetGroupName", valid_603179
  var valid_603180 = query.getOrDefault("KmsKeyId")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "KmsKeyId", valid_603180
  var valid_603181 = query.getOrDefault("EngineVersion")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "EngineVersion", valid_603181
  var valid_603182 = query.getOrDefault("Port")
  valid_603182 = validateParameter(valid_603182, JInt, required = false, default = nil)
  if valid_603182 != nil:
    section.add "Port", valid_603182
  var valid_603183 = query.getOrDefault("PreferredBackupWindow")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "PreferredBackupWindow", valid_603183
  var valid_603184 = query.getOrDefault("Version")
  valid_603184 = validateParameter(valid_603184, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603184 != nil:
    section.add "Version", valid_603184
  var valid_603185 = query.getOrDefault("MasterUsername")
  valid_603185 = validateParameter(valid_603185, JString, required = true,
                                 default = nil)
  if valid_603185 != nil:
    section.add "MasterUsername", valid_603185
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603186 = header.getOrDefault("X-Amz-Date")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Date", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Security-Token")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Security-Token", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Content-Sha256", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Algorithm")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Algorithm", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Signature")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Signature", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-SignedHeaders", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Credential")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Credential", valid_603192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603193: Call_GetCreateDBCluster_603163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_603193.validator(path, query, header, formData, body)
  let scheme = call_603193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603193.url(scheme.get, call_603193.host, call_603193.base,
                         call_603193.route, valid.getOrDefault("path"))
  result = hook(call_603193, url, valid)

proc call*(call_603194: Call_GetCreateDBCluster_603163; Engine: string;
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
  var query_603195 = newJObject()
  add(query_603195, "Engine", newJString(Engine))
  add(query_603195, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603195, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_603195, "StorageEncrypted", newJBool(StorageEncrypted))
  if AvailabilityZones != nil:
    query_603195.add "AvailabilityZones", AvailabilityZones
  add(query_603195, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603195, "MasterUserPassword", newJString(MasterUserPassword))
  if VpcSecurityGroupIds != nil:
    query_603195.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_603195.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_603195.add "Tags", Tags
  add(query_603195, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603195, "DeletionProtection", newJBool(DeletionProtection))
  add(query_603195, "Action", newJString(Action))
  add(query_603195, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603195, "KmsKeyId", newJString(KmsKeyId))
  add(query_603195, "EngineVersion", newJString(EngineVersion))
  add(query_603195, "Port", newJInt(Port))
  add(query_603195, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_603195, "Version", newJString(Version))
  add(query_603195, "MasterUsername", newJString(MasterUsername))
  result = call_603194.call(nil, query_603195, nil, nil, nil)

var getCreateDBCluster* = Call_GetCreateDBCluster_603163(
    name: "getCreateDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CreateDBCluster", validator: validate_GetCreateDBCluster_603164,
    base: "/", url: url_GetCreateDBCluster_603165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterParameterGroup_603249 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBClusterParameterGroup_603251(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBClusterParameterGroup_603250(path: JsonNode;
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
  var valid_603252 = query.getOrDefault("Action")
  valid_603252 = validateParameter(valid_603252, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_603252 != nil:
    section.add "Action", valid_603252
  var valid_603253 = query.getOrDefault("Version")
  valid_603253 = validateParameter(valid_603253, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603253 != nil:
    section.add "Version", valid_603253
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603254 = header.getOrDefault("X-Amz-Date")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Date", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Security-Token")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Security-Token", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Content-Sha256", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Algorithm")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Algorithm", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Signature")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Signature", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-SignedHeaders", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Credential")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Credential", valid_603260
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
  var valid_603261 = formData.getOrDefault("Tags")
  valid_603261 = validateParameter(valid_603261, JArray, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "Tags", valid_603261
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_603262 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_603262 = validateParameter(valid_603262, JString, required = true,
                                 default = nil)
  if valid_603262 != nil:
    section.add "DBClusterParameterGroupName", valid_603262
  var valid_603263 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603263 = validateParameter(valid_603263, JString, required = true,
                                 default = nil)
  if valid_603263 != nil:
    section.add "DBParameterGroupFamily", valid_603263
  var valid_603264 = formData.getOrDefault("Description")
  valid_603264 = validateParameter(valid_603264, JString, required = true,
                                 default = nil)
  if valid_603264 != nil:
    section.add "Description", valid_603264
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603265: Call_PostCreateDBClusterParameterGroup_603249;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_603265.validator(path, query, header, formData, body)
  let scheme = call_603265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603265.url(scheme.get, call_603265.host, call_603265.base,
                         call_603265.route, valid.getOrDefault("path"))
  result = hook(call_603265, url, valid)

proc call*(call_603266: Call_PostCreateDBClusterParameterGroup_603249;
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
  var query_603267 = newJObject()
  var formData_603268 = newJObject()
  if Tags != nil:
    formData_603268.add "Tags", Tags
  add(query_603267, "Action", newJString(Action))
  add(formData_603268, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_603268, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_603267, "Version", newJString(Version))
  add(formData_603268, "Description", newJString(Description))
  result = call_603266.call(nil, query_603267, nil, formData_603268, nil)

var postCreateDBClusterParameterGroup* = Call_PostCreateDBClusterParameterGroup_603249(
    name: "postCreateDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_PostCreateDBClusterParameterGroup_603250, base: "/",
    url: url_PostCreateDBClusterParameterGroup_603251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterParameterGroup_603230 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBClusterParameterGroup_603232(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBClusterParameterGroup_603231(path: JsonNode;
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
  var valid_603233 = query.getOrDefault("DBClusterParameterGroupName")
  valid_603233 = validateParameter(valid_603233, JString, required = true,
                                 default = nil)
  if valid_603233 != nil:
    section.add "DBClusterParameterGroupName", valid_603233
  var valid_603234 = query.getOrDefault("Description")
  valid_603234 = validateParameter(valid_603234, JString, required = true,
                                 default = nil)
  if valid_603234 != nil:
    section.add "Description", valid_603234
  var valid_603235 = query.getOrDefault("DBParameterGroupFamily")
  valid_603235 = validateParameter(valid_603235, JString, required = true,
                                 default = nil)
  if valid_603235 != nil:
    section.add "DBParameterGroupFamily", valid_603235
  var valid_603236 = query.getOrDefault("Tags")
  valid_603236 = validateParameter(valid_603236, JArray, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "Tags", valid_603236
  var valid_603237 = query.getOrDefault("Action")
  valid_603237 = validateParameter(valid_603237, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_603237 != nil:
    section.add "Action", valid_603237
  var valid_603238 = query.getOrDefault("Version")
  valid_603238 = validateParameter(valid_603238, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603238 != nil:
    section.add "Version", valid_603238
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603239 = header.getOrDefault("X-Amz-Date")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Date", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Security-Token")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Security-Token", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Content-Sha256", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Algorithm")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Algorithm", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Signature")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Signature", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-SignedHeaders", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Credential")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Credential", valid_603245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603246: Call_GetCreateDBClusterParameterGroup_603230;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_603246.validator(path, query, header, formData, body)
  let scheme = call_603246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603246.url(scheme.get, call_603246.host, call_603246.base,
                         call_603246.route, valid.getOrDefault("path"))
  result = hook(call_603246, url, valid)

proc call*(call_603247: Call_GetCreateDBClusterParameterGroup_603230;
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
  var query_603248 = newJObject()
  add(query_603248, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_603248, "Description", newJString(Description))
  add(query_603248, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_603248.add "Tags", Tags
  add(query_603248, "Action", newJString(Action))
  add(query_603248, "Version", newJString(Version))
  result = call_603247.call(nil, query_603248, nil, nil, nil)

var getCreateDBClusterParameterGroup* = Call_GetCreateDBClusterParameterGroup_603230(
    name: "getCreateDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_GetCreateDBClusterParameterGroup_603231, base: "/",
    url: url_GetCreateDBClusterParameterGroup_603232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterSnapshot_603287 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBClusterSnapshot_603289(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBClusterSnapshot_603288(path: JsonNode; query: JsonNode;
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
  var valid_603290 = query.getOrDefault("Action")
  valid_603290 = validateParameter(valid_603290, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_603290 != nil:
    section.add "Action", valid_603290
  var valid_603291 = query.getOrDefault("Version")
  valid_603291 = validateParameter(valid_603291, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603291 != nil:
    section.add "Version", valid_603291
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603292 = header.getOrDefault("X-Amz-Date")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Date", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Security-Token")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Security-Token", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Content-Sha256", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Algorithm")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Algorithm", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Signature")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Signature", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-SignedHeaders", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Credential")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Credential", valid_603298
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
  var valid_603299 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603299 = validateParameter(valid_603299, JString, required = true,
                                 default = nil)
  if valid_603299 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603299
  var valid_603300 = formData.getOrDefault("Tags")
  valid_603300 = validateParameter(valid_603300, JArray, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "Tags", valid_603300
  var valid_603301 = formData.getOrDefault("DBClusterIdentifier")
  valid_603301 = validateParameter(valid_603301, JString, required = true,
                                 default = nil)
  if valid_603301 != nil:
    section.add "DBClusterIdentifier", valid_603301
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603302: Call_PostCreateDBClusterSnapshot_603287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_603302.validator(path, query, header, formData, body)
  let scheme = call_603302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603302.url(scheme.get, call_603302.host, call_603302.base,
                         call_603302.route, valid.getOrDefault("path"))
  result = hook(call_603302, url, valid)

proc call*(call_603303: Call_PostCreateDBClusterSnapshot_603287;
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
  var query_603304 = newJObject()
  var formData_603305 = newJObject()
  add(formData_603305, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    formData_603305.add "Tags", Tags
  add(query_603304, "Action", newJString(Action))
  add(formData_603305, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603304, "Version", newJString(Version))
  result = call_603303.call(nil, query_603304, nil, formData_603305, nil)

var postCreateDBClusterSnapshot* = Call_PostCreateDBClusterSnapshot_603287(
    name: "postCreateDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_PostCreateDBClusterSnapshot_603288, base: "/",
    url: url_PostCreateDBClusterSnapshot_603289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterSnapshot_603269 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBClusterSnapshot_603271(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBClusterSnapshot_603270(path: JsonNode; query: JsonNode;
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
  var valid_603272 = query.getOrDefault("DBClusterIdentifier")
  valid_603272 = validateParameter(valid_603272, JString, required = true,
                                 default = nil)
  if valid_603272 != nil:
    section.add "DBClusterIdentifier", valid_603272
  var valid_603273 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603273 = validateParameter(valid_603273, JString, required = true,
                                 default = nil)
  if valid_603273 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603273
  var valid_603274 = query.getOrDefault("Tags")
  valid_603274 = validateParameter(valid_603274, JArray, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "Tags", valid_603274
  var valid_603275 = query.getOrDefault("Action")
  valid_603275 = validateParameter(valid_603275, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_603275 != nil:
    section.add "Action", valid_603275
  var valid_603276 = query.getOrDefault("Version")
  valid_603276 = validateParameter(valid_603276, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603276 != nil:
    section.add "Version", valid_603276
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603277 = header.getOrDefault("X-Amz-Date")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Date", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Security-Token")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Security-Token", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Content-Sha256", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Algorithm")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Algorithm", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Signature")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Signature", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-SignedHeaders", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Credential")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Credential", valid_603283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603284: Call_GetCreateDBClusterSnapshot_603269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_603284.validator(path, query, header, formData, body)
  let scheme = call_603284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603284.url(scheme.get, call_603284.host, call_603284.base,
                         call_603284.route, valid.getOrDefault("path"))
  result = hook(call_603284, url, valid)

proc call*(call_603285: Call_GetCreateDBClusterSnapshot_603269;
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
  var query_603286 = newJObject()
  add(query_603286, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603286, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    query_603286.add "Tags", Tags
  add(query_603286, "Action", newJString(Action))
  add(query_603286, "Version", newJString(Version))
  result = call_603285.call(nil, query_603286, nil, nil, nil)

var getCreateDBClusterSnapshot* = Call_GetCreateDBClusterSnapshot_603269(
    name: "getCreateDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_GetCreateDBClusterSnapshot_603270, base: "/",
    url: url_GetCreateDBClusterSnapshot_603271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_603330 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBInstance_603332(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstance_603331(path: JsonNode; query: JsonNode;
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
  var valid_603333 = query.getOrDefault("Action")
  valid_603333 = validateParameter(valid_603333, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603333 != nil:
    section.add "Action", valid_603333
  var valid_603334 = query.getOrDefault("Version")
  valid_603334 = validateParameter(valid_603334, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603334 != nil:
    section.add "Version", valid_603334
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603335 = header.getOrDefault("X-Amz-Date")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Date", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Security-Token")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Security-Token", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Content-Sha256", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Algorithm")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Algorithm", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Signature")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Signature", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-SignedHeaders", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Credential")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Credential", valid_603341
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
  var valid_603342 = formData.getOrDefault("Engine")
  valid_603342 = validateParameter(valid_603342, JString, required = true,
                                 default = nil)
  if valid_603342 != nil:
    section.add "Engine", valid_603342
  var valid_603343 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603343 = validateParameter(valid_603343, JString, required = true,
                                 default = nil)
  if valid_603343 != nil:
    section.add "DBInstanceIdentifier", valid_603343
  var valid_603344 = formData.getOrDefault("Tags")
  valid_603344 = validateParameter(valid_603344, JArray, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "Tags", valid_603344
  var valid_603345 = formData.getOrDefault("AvailabilityZone")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "AvailabilityZone", valid_603345
  var valid_603346 = formData.getOrDefault("PromotionTier")
  valid_603346 = validateParameter(valid_603346, JInt, required = false, default = nil)
  if valid_603346 != nil:
    section.add "PromotionTier", valid_603346
  var valid_603347 = formData.getOrDefault("DBInstanceClass")
  valid_603347 = validateParameter(valid_603347, JString, required = true,
                                 default = nil)
  if valid_603347 != nil:
    section.add "DBInstanceClass", valid_603347
  var valid_603348 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603348 = validateParameter(valid_603348, JBool, required = false, default = nil)
  if valid_603348 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603348
  var valid_603349 = formData.getOrDefault("DBClusterIdentifier")
  valid_603349 = validateParameter(valid_603349, JString, required = true,
                                 default = nil)
  if valid_603349 != nil:
    section.add "DBClusterIdentifier", valid_603349
  var valid_603350 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "PreferredMaintenanceWindow", valid_603350
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603351: Call_PostCreateDBInstance_603330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_603351.validator(path, query, header, formData, body)
  let scheme = call_603351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603351.url(scheme.get, call_603351.host, call_603351.base,
                         call_603351.route, valid.getOrDefault("path"))
  result = hook(call_603351, url, valid)

proc call*(call_603352: Call_PostCreateDBInstance_603330; Engine: string;
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
  var query_603353 = newJObject()
  var formData_603354 = newJObject()
  add(formData_603354, "Engine", newJString(Engine))
  add(formData_603354, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_603354.add "Tags", Tags
  add(formData_603354, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603353, "Action", newJString(Action))
  add(formData_603354, "PromotionTier", newJInt(PromotionTier))
  add(formData_603354, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603354, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603354, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603353, "Version", newJString(Version))
  add(formData_603354, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_603352.call(nil, query_603353, nil, formData_603354, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_603330(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_603331, base: "/",
    url: url_PostCreateDBInstance_603332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_603306 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBInstance_603308(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstance_603307(path: JsonNode; query: JsonNode;
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
  var valid_603309 = query.getOrDefault("Engine")
  valid_603309 = validateParameter(valid_603309, JString, required = true,
                                 default = nil)
  if valid_603309 != nil:
    section.add "Engine", valid_603309
  var valid_603310 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "PreferredMaintenanceWindow", valid_603310
  var valid_603311 = query.getOrDefault("PromotionTier")
  valid_603311 = validateParameter(valid_603311, JInt, required = false, default = nil)
  if valid_603311 != nil:
    section.add "PromotionTier", valid_603311
  var valid_603312 = query.getOrDefault("DBClusterIdentifier")
  valid_603312 = validateParameter(valid_603312, JString, required = true,
                                 default = nil)
  if valid_603312 != nil:
    section.add "DBClusterIdentifier", valid_603312
  var valid_603313 = query.getOrDefault("AvailabilityZone")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "AvailabilityZone", valid_603313
  var valid_603314 = query.getOrDefault("Tags")
  valid_603314 = validateParameter(valid_603314, JArray, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "Tags", valid_603314
  var valid_603315 = query.getOrDefault("DBInstanceClass")
  valid_603315 = validateParameter(valid_603315, JString, required = true,
                                 default = nil)
  if valid_603315 != nil:
    section.add "DBInstanceClass", valid_603315
  var valid_603316 = query.getOrDefault("Action")
  valid_603316 = validateParameter(valid_603316, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603316 != nil:
    section.add "Action", valid_603316
  var valid_603317 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603317 = validateParameter(valid_603317, JBool, required = false, default = nil)
  if valid_603317 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603317
  var valid_603318 = query.getOrDefault("Version")
  valid_603318 = validateParameter(valid_603318, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603318 != nil:
    section.add "Version", valid_603318
  var valid_603319 = query.getOrDefault("DBInstanceIdentifier")
  valid_603319 = validateParameter(valid_603319, JString, required = true,
                                 default = nil)
  if valid_603319 != nil:
    section.add "DBInstanceIdentifier", valid_603319
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603320 = header.getOrDefault("X-Amz-Date")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Date", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Security-Token")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Security-Token", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Content-Sha256", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Algorithm")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Algorithm", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Signature")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Signature", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-SignedHeaders", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Credential")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Credential", valid_603326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603327: Call_GetCreateDBInstance_603306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_603327.validator(path, query, header, formData, body)
  let scheme = call_603327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603327.url(scheme.get, call_603327.host, call_603327.base,
                         call_603327.route, valid.getOrDefault("path"))
  result = hook(call_603327, url, valid)

proc call*(call_603328: Call_GetCreateDBInstance_603306; Engine: string;
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
  var query_603329 = newJObject()
  add(query_603329, "Engine", newJString(Engine))
  add(query_603329, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603329, "PromotionTier", newJInt(PromotionTier))
  add(query_603329, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603329, "AvailabilityZone", newJString(AvailabilityZone))
  if Tags != nil:
    query_603329.add "Tags", Tags
  add(query_603329, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603329, "Action", newJString(Action))
  add(query_603329, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603329, "Version", newJString(Version))
  add(query_603329, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603328.call(nil, query_603329, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_603306(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_603307, base: "/",
    url: url_GetCreateDBInstance_603308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_603374 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBSubnetGroup_603376(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSubnetGroup_603375(path: JsonNode; query: JsonNode;
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
  var valid_603377 = query.getOrDefault("Action")
  valid_603377 = validateParameter(valid_603377, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603377 != nil:
    section.add "Action", valid_603377
  var valid_603378 = query.getOrDefault("Version")
  valid_603378 = validateParameter(valid_603378, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603378 != nil:
    section.add "Version", valid_603378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603379 = header.getOrDefault("X-Amz-Date")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Date", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Security-Token")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Security-Token", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Content-Sha256", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Algorithm")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Algorithm", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Signature")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Signature", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-SignedHeaders", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Credential")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Credential", valid_603385
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
  var valid_603386 = formData.getOrDefault("Tags")
  valid_603386 = validateParameter(valid_603386, JArray, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "Tags", valid_603386
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603387 = formData.getOrDefault("DBSubnetGroupName")
  valid_603387 = validateParameter(valid_603387, JString, required = true,
                                 default = nil)
  if valid_603387 != nil:
    section.add "DBSubnetGroupName", valid_603387
  var valid_603388 = formData.getOrDefault("SubnetIds")
  valid_603388 = validateParameter(valid_603388, JArray, required = true, default = nil)
  if valid_603388 != nil:
    section.add "SubnetIds", valid_603388
  var valid_603389 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_603389 = validateParameter(valid_603389, JString, required = true,
                                 default = nil)
  if valid_603389 != nil:
    section.add "DBSubnetGroupDescription", valid_603389
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603390: Call_PostCreateDBSubnetGroup_603374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_603390.validator(path, query, header, formData, body)
  let scheme = call_603390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603390.url(scheme.get, call_603390.host, call_603390.base,
                         call_603390.route, valid.getOrDefault("path"))
  result = hook(call_603390, url, valid)

proc call*(call_603391: Call_PostCreateDBSubnetGroup_603374;
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
  var query_603392 = newJObject()
  var formData_603393 = newJObject()
  if Tags != nil:
    formData_603393.add "Tags", Tags
  add(formData_603393, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_603393.add "SubnetIds", SubnetIds
  add(query_603392, "Action", newJString(Action))
  add(formData_603393, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603392, "Version", newJString(Version))
  result = call_603391.call(nil, query_603392, nil, formData_603393, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_603374(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_603375, base: "/",
    url: url_PostCreateDBSubnetGroup_603376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_603355 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBSubnetGroup_603357(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSubnetGroup_603356(path: JsonNode; query: JsonNode;
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
  var valid_603358 = query.getOrDefault("Tags")
  valid_603358 = validateParameter(valid_603358, JArray, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "Tags", valid_603358
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603359 = query.getOrDefault("Action")
  valid_603359 = validateParameter(valid_603359, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603359 != nil:
    section.add "Action", valid_603359
  var valid_603360 = query.getOrDefault("DBSubnetGroupName")
  valid_603360 = validateParameter(valid_603360, JString, required = true,
                                 default = nil)
  if valid_603360 != nil:
    section.add "DBSubnetGroupName", valid_603360
  var valid_603361 = query.getOrDefault("SubnetIds")
  valid_603361 = validateParameter(valid_603361, JArray, required = true, default = nil)
  if valid_603361 != nil:
    section.add "SubnetIds", valid_603361
  var valid_603362 = query.getOrDefault("DBSubnetGroupDescription")
  valid_603362 = validateParameter(valid_603362, JString, required = true,
                                 default = nil)
  if valid_603362 != nil:
    section.add "DBSubnetGroupDescription", valid_603362
  var valid_603363 = query.getOrDefault("Version")
  valid_603363 = validateParameter(valid_603363, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603363 != nil:
    section.add "Version", valid_603363
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603364 = header.getOrDefault("X-Amz-Date")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Date", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Security-Token")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Security-Token", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Content-Sha256", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Algorithm")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Algorithm", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Signature")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Signature", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-SignedHeaders", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Credential")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Credential", valid_603370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603371: Call_GetCreateDBSubnetGroup_603355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_603371.validator(path, query, header, formData, body)
  let scheme = call_603371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603371.url(scheme.get, call_603371.host, call_603371.base,
                         call_603371.route, valid.getOrDefault("path"))
  result = hook(call_603371, url, valid)

proc call*(call_603372: Call_GetCreateDBSubnetGroup_603355;
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
  var query_603373 = newJObject()
  if Tags != nil:
    query_603373.add "Tags", Tags
  add(query_603373, "Action", newJString(Action))
  add(query_603373, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_603373.add "SubnetIds", SubnetIds
  add(query_603373, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603373, "Version", newJString(Version))
  result = call_603372.call(nil, query_603373, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_603355(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_603356, base: "/",
    url: url_GetCreateDBSubnetGroup_603357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBCluster_603412 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBCluster_603414(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBCluster_603413(path: JsonNode; query: JsonNode;
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
  var valid_603415 = query.getOrDefault("Action")
  valid_603415 = validateParameter(valid_603415, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_603415 != nil:
    section.add "Action", valid_603415
  var valid_603416 = query.getOrDefault("Version")
  valid_603416 = validateParameter(valid_603416, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603416 != nil:
    section.add "Version", valid_603416
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603417 = header.getOrDefault("X-Amz-Date")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Date", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Security-Token")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Security-Token", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Content-Sha256", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-Algorithm")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Algorithm", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Signature")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Signature", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-SignedHeaders", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Credential")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Credential", valid_603423
  result.add "header", section
  ## parameters in `formData` object:
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_603424 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603424
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_603425 = formData.getOrDefault("DBClusterIdentifier")
  valid_603425 = validateParameter(valid_603425, JString, required = true,
                                 default = nil)
  if valid_603425 != nil:
    section.add "DBClusterIdentifier", valid_603425
  var valid_603426 = formData.getOrDefault("SkipFinalSnapshot")
  valid_603426 = validateParameter(valid_603426, JBool, required = false, default = nil)
  if valid_603426 != nil:
    section.add "SkipFinalSnapshot", valid_603426
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603427: Call_PostDeleteDBCluster_603412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_603427.validator(path, query, header, formData, body)
  let scheme = call_603427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603427.url(scheme.get, call_603427.host, call_603427.base,
                         call_603427.route, valid.getOrDefault("path"))
  result = hook(call_603427, url, valid)

proc call*(call_603428: Call_PostDeleteDBCluster_603412;
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
  var query_603429 = newJObject()
  var formData_603430 = newJObject()
  add(formData_603430, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603429, "Action", newJString(Action))
  add(formData_603430, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603429, "Version", newJString(Version))
  add(formData_603430, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_603428.call(nil, query_603429, nil, formData_603430, nil)

var postDeleteDBCluster* = Call_PostDeleteDBCluster_603412(
    name: "postDeleteDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBCluster",
    validator: validate_PostDeleteDBCluster_603413, base: "/",
    url: url_PostDeleteDBCluster_603414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBCluster_603394 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBCluster_603396(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBCluster_603395(path: JsonNode; query: JsonNode;
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
  var valid_603397 = query.getOrDefault("DBClusterIdentifier")
  valid_603397 = validateParameter(valid_603397, JString, required = true,
                                 default = nil)
  if valid_603397 != nil:
    section.add "DBClusterIdentifier", valid_603397
  var valid_603398 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603398
  var valid_603399 = query.getOrDefault("Action")
  valid_603399 = validateParameter(valid_603399, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_603399 != nil:
    section.add "Action", valid_603399
  var valid_603400 = query.getOrDefault("SkipFinalSnapshot")
  valid_603400 = validateParameter(valid_603400, JBool, required = false, default = nil)
  if valid_603400 != nil:
    section.add "SkipFinalSnapshot", valid_603400
  var valid_603401 = query.getOrDefault("Version")
  valid_603401 = validateParameter(valid_603401, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603401 != nil:
    section.add "Version", valid_603401
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603402 = header.getOrDefault("X-Amz-Date")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Date", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Security-Token")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Security-Token", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Content-Sha256", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Algorithm")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Algorithm", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Signature")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Signature", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-SignedHeaders", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Credential")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Credential", valid_603408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603409: Call_GetDeleteDBCluster_603394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_603409.validator(path, query, header, formData, body)
  let scheme = call_603409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603409.url(scheme.get, call_603409.host, call_603409.base,
                         call_603409.route, valid.getOrDefault("path"))
  result = hook(call_603409, url, valid)

proc call*(call_603410: Call_GetDeleteDBCluster_603394;
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
  var query_603411 = newJObject()
  add(query_603411, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603411, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603411, "Action", newJString(Action))
  add(query_603411, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_603411, "Version", newJString(Version))
  result = call_603410.call(nil, query_603411, nil, nil, nil)

var getDeleteDBCluster* = Call_GetDeleteDBCluster_603394(
    name: "getDeleteDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DeleteDBCluster", validator: validate_GetDeleteDBCluster_603395,
    base: "/", url: url_GetDeleteDBCluster_603396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterParameterGroup_603447 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBClusterParameterGroup_603449(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBClusterParameterGroup_603448(path: JsonNode;
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
  var valid_603450 = query.getOrDefault("Action")
  valid_603450 = validateParameter(valid_603450, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_603450 != nil:
    section.add "Action", valid_603450
  var valid_603451 = query.getOrDefault("Version")
  valid_603451 = validateParameter(valid_603451, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603451 != nil:
    section.add "Version", valid_603451
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603452 = header.getOrDefault("X-Amz-Date")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Date", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Security-Token")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Security-Token", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Content-Sha256", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Algorithm")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Algorithm", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Signature")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Signature", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-SignedHeaders", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Credential")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Credential", valid_603458
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_603459 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_603459 = validateParameter(valid_603459, JString, required = true,
                                 default = nil)
  if valid_603459 != nil:
    section.add "DBClusterParameterGroupName", valid_603459
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603460: Call_PostDeleteDBClusterParameterGroup_603447;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_603460.validator(path, query, header, formData, body)
  let scheme = call_603460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603460.url(scheme.get, call_603460.host, call_603460.base,
                         call_603460.route, valid.getOrDefault("path"))
  result = hook(call_603460, url, valid)

proc call*(call_603461: Call_PostDeleteDBClusterParameterGroup_603447;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Version: string (required)
  var query_603462 = newJObject()
  var formData_603463 = newJObject()
  add(query_603462, "Action", newJString(Action))
  add(formData_603463, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_603462, "Version", newJString(Version))
  result = call_603461.call(nil, query_603462, nil, formData_603463, nil)

var postDeleteDBClusterParameterGroup* = Call_PostDeleteDBClusterParameterGroup_603447(
    name: "postDeleteDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_PostDeleteDBClusterParameterGroup_603448, base: "/",
    url: url_PostDeleteDBClusterParameterGroup_603449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterParameterGroup_603431 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBClusterParameterGroup_603433(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBClusterParameterGroup_603432(path: JsonNode;
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
  var valid_603434 = query.getOrDefault("DBClusterParameterGroupName")
  valid_603434 = validateParameter(valid_603434, JString, required = true,
                                 default = nil)
  if valid_603434 != nil:
    section.add "DBClusterParameterGroupName", valid_603434
  var valid_603435 = query.getOrDefault("Action")
  valid_603435 = validateParameter(valid_603435, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_603435 != nil:
    section.add "Action", valid_603435
  var valid_603436 = query.getOrDefault("Version")
  valid_603436 = validateParameter(valid_603436, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603436 != nil:
    section.add "Version", valid_603436
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603437 = header.getOrDefault("X-Amz-Date")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Date", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Security-Token")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Security-Token", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Content-Sha256", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Algorithm")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Algorithm", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Signature")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Signature", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-SignedHeaders", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Credential")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Credential", valid_603443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603444: Call_GetDeleteDBClusterParameterGroup_603431;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_603444.validator(path, query, header, formData, body)
  let scheme = call_603444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603444.url(scheme.get, call_603444.host, call_603444.base,
                         call_603444.route, valid.getOrDefault("path"))
  result = hook(call_603444, url, valid)

proc call*(call_603445: Call_GetDeleteDBClusterParameterGroup_603431;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603446 = newJObject()
  add(query_603446, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_603446, "Action", newJString(Action))
  add(query_603446, "Version", newJString(Version))
  result = call_603445.call(nil, query_603446, nil, nil, nil)

var getDeleteDBClusterParameterGroup* = Call_GetDeleteDBClusterParameterGroup_603431(
    name: "getDeleteDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_GetDeleteDBClusterParameterGroup_603432, base: "/",
    url: url_GetDeleteDBClusterParameterGroup_603433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterSnapshot_603480 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBClusterSnapshot_603482(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBClusterSnapshot_603481(path: JsonNode; query: JsonNode;
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
  var valid_603483 = query.getOrDefault("Action")
  valid_603483 = validateParameter(valid_603483, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_603483 != nil:
    section.add "Action", valid_603483
  var valid_603484 = query.getOrDefault("Version")
  valid_603484 = validateParameter(valid_603484, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603484 != nil:
    section.add "Version", valid_603484
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603485 = header.getOrDefault("X-Amz-Date")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Date", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Security-Token")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Security-Token", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Content-Sha256", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Algorithm")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Algorithm", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Signature")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Signature", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-SignedHeaders", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Credential")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Credential", valid_603491
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_603492 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603492 = validateParameter(valid_603492, JString, required = true,
                                 default = nil)
  if valid_603492 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603492
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603493: Call_PostDeleteDBClusterSnapshot_603480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_603493.validator(path, query, header, formData, body)
  let scheme = call_603493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603493.url(scheme.get, call_603493.host, call_603493.base,
                         call_603493.route, valid.getOrDefault("path"))
  result = hook(call_603493, url, valid)

proc call*(call_603494: Call_PostDeleteDBClusterSnapshot_603480;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603495 = newJObject()
  var formData_603496 = newJObject()
  add(formData_603496, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_603495, "Action", newJString(Action))
  add(query_603495, "Version", newJString(Version))
  result = call_603494.call(nil, query_603495, nil, formData_603496, nil)

var postDeleteDBClusterSnapshot* = Call_PostDeleteDBClusterSnapshot_603480(
    name: "postDeleteDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_PostDeleteDBClusterSnapshot_603481, base: "/",
    url: url_PostDeleteDBClusterSnapshot_603482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterSnapshot_603464 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBClusterSnapshot_603466(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBClusterSnapshot_603465(path: JsonNode; query: JsonNode;
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
  var valid_603467 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603467 = validateParameter(valid_603467, JString, required = true,
                                 default = nil)
  if valid_603467 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603467
  var valid_603468 = query.getOrDefault("Action")
  valid_603468 = validateParameter(valid_603468, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_603468 != nil:
    section.add "Action", valid_603468
  var valid_603469 = query.getOrDefault("Version")
  valid_603469 = validateParameter(valid_603469, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603469 != nil:
    section.add "Version", valid_603469
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603470 = header.getOrDefault("X-Amz-Date")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Date", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Security-Token")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Security-Token", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Content-Sha256", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Algorithm")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Algorithm", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Signature")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Signature", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-SignedHeaders", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Credential")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Credential", valid_603476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603477: Call_GetDeleteDBClusterSnapshot_603464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_603477.validator(path, query, header, formData, body)
  let scheme = call_603477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603477.url(scheme.get, call_603477.host, call_603477.base,
                         call_603477.route, valid.getOrDefault("path"))
  result = hook(call_603477, url, valid)

proc call*(call_603478: Call_GetDeleteDBClusterSnapshot_603464;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603479 = newJObject()
  add(query_603479, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_603479, "Action", newJString(Action))
  add(query_603479, "Version", newJString(Version))
  result = call_603478.call(nil, query_603479, nil, nil, nil)

var getDeleteDBClusterSnapshot* = Call_GetDeleteDBClusterSnapshot_603464(
    name: "getDeleteDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_GetDeleteDBClusterSnapshot_603465, base: "/",
    url: url_GetDeleteDBClusterSnapshot_603466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_603513 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBInstance_603515(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBInstance_603514(path: JsonNode; query: JsonNode;
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
  var valid_603516 = query.getOrDefault("Action")
  valid_603516 = validateParameter(valid_603516, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603516 != nil:
    section.add "Action", valid_603516
  var valid_603517 = query.getOrDefault("Version")
  valid_603517 = validateParameter(valid_603517, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603517 != nil:
    section.add "Version", valid_603517
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603518 = header.getOrDefault("X-Amz-Date")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Date", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Security-Token")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Security-Token", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Content-Sha256", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-Algorithm")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Algorithm", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-Signature")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Signature", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-SignedHeaders", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Credential")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Credential", valid_603524
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603525 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603525 = validateParameter(valid_603525, JString, required = true,
                                 default = nil)
  if valid_603525 != nil:
    section.add "DBInstanceIdentifier", valid_603525
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603526: Call_PostDeleteDBInstance_603513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_603526.validator(path, query, header, formData, body)
  let scheme = call_603526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603526.url(scheme.get, call_603526.host, call_603526.base,
                         call_603526.route, valid.getOrDefault("path"))
  result = hook(call_603526, url, valid)

proc call*(call_603527: Call_PostDeleteDBInstance_603513;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603528 = newJObject()
  var formData_603529 = newJObject()
  add(formData_603529, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603528, "Action", newJString(Action))
  add(query_603528, "Version", newJString(Version))
  result = call_603527.call(nil, query_603528, nil, formData_603529, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_603513(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_603514, base: "/",
    url: url_PostDeleteDBInstance_603515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_603497 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBInstance_603499(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBInstance_603498(path: JsonNode; query: JsonNode;
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
  var valid_603500 = query.getOrDefault("Action")
  valid_603500 = validateParameter(valid_603500, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603500 != nil:
    section.add "Action", valid_603500
  var valid_603501 = query.getOrDefault("Version")
  valid_603501 = validateParameter(valid_603501, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603501 != nil:
    section.add "Version", valid_603501
  var valid_603502 = query.getOrDefault("DBInstanceIdentifier")
  valid_603502 = validateParameter(valid_603502, JString, required = true,
                                 default = nil)
  if valid_603502 != nil:
    section.add "DBInstanceIdentifier", valid_603502
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603503 = header.getOrDefault("X-Amz-Date")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Date", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Security-Token")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Security-Token", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Content-Sha256", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Algorithm")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Algorithm", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Signature")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Signature", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-SignedHeaders", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Credential")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Credential", valid_603509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603510: Call_GetDeleteDBInstance_603497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_603510.validator(path, query, header, formData, body)
  let scheme = call_603510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603510.url(scheme.get, call_603510.host, call_603510.base,
                         call_603510.route, valid.getOrDefault("path"))
  result = hook(call_603510, url, valid)

proc call*(call_603511: Call_GetDeleteDBInstance_603497;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  var query_603512 = newJObject()
  add(query_603512, "Action", newJString(Action))
  add(query_603512, "Version", newJString(Version))
  add(query_603512, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603511.call(nil, query_603512, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_603497(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_603498, base: "/",
    url: url_GetDeleteDBInstance_603499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_603546 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBSubnetGroup_603548(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSubnetGroup_603547(path: JsonNode; query: JsonNode;
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
  var valid_603549 = query.getOrDefault("Action")
  valid_603549 = validateParameter(valid_603549, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_603549 != nil:
    section.add "Action", valid_603549
  var valid_603550 = query.getOrDefault("Version")
  valid_603550 = validateParameter(valid_603550, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603550 != nil:
    section.add "Version", valid_603550
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603551 = header.getOrDefault("X-Amz-Date")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Date", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Security-Token")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Security-Token", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Content-Sha256", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Algorithm")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Algorithm", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Signature")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Signature", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-SignedHeaders", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Credential")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Credential", valid_603557
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603558 = formData.getOrDefault("DBSubnetGroupName")
  valid_603558 = validateParameter(valid_603558, JString, required = true,
                                 default = nil)
  if valid_603558 != nil:
    section.add "DBSubnetGroupName", valid_603558
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603559: Call_PostDeleteDBSubnetGroup_603546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_603559.validator(path, query, header, formData, body)
  let scheme = call_603559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603559.url(scheme.get, call_603559.host, call_603559.base,
                         call_603559.route, valid.getOrDefault("path"))
  result = hook(call_603559, url, valid)

proc call*(call_603560: Call_PostDeleteDBSubnetGroup_603546;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603561 = newJObject()
  var formData_603562 = newJObject()
  add(formData_603562, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603561, "Action", newJString(Action))
  add(query_603561, "Version", newJString(Version))
  result = call_603560.call(nil, query_603561, nil, formData_603562, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_603546(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_603547, base: "/",
    url: url_PostDeleteDBSubnetGroup_603548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_603530 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBSubnetGroup_603532(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSubnetGroup_603531(path: JsonNode; query: JsonNode;
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
  var valid_603533 = query.getOrDefault("Action")
  valid_603533 = validateParameter(valid_603533, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_603533 != nil:
    section.add "Action", valid_603533
  var valid_603534 = query.getOrDefault("DBSubnetGroupName")
  valid_603534 = validateParameter(valid_603534, JString, required = true,
                                 default = nil)
  if valid_603534 != nil:
    section.add "DBSubnetGroupName", valid_603534
  var valid_603535 = query.getOrDefault("Version")
  valid_603535 = validateParameter(valid_603535, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603535 != nil:
    section.add "Version", valid_603535
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603536 = header.getOrDefault("X-Amz-Date")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Date", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Security-Token")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Security-Token", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Content-Sha256", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Algorithm")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Algorithm", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-Signature")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Signature", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-SignedHeaders", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Credential")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Credential", valid_603542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603543: Call_GetDeleteDBSubnetGroup_603530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_603543.validator(path, query, header, formData, body)
  let scheme = call_603543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603543.url(scheme.get, call_603543.host, call_603543.base,
                         call_603543.route, valid.getOrDefault("path"))
  result = hook(call_603543, url, valid)

proc call*(call_603544: Call_GetDeleteDBSubnetGroup_603530;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_603545 = newJObject()
  add(query_603545, "Action", newJString(Action))
  add(query_603545, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603545, "Version", newJString(Version))
  result = call_603544.call(nil, query_603545, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_603530(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_603531, base: "/",
    url: url_GetDeleteDBSubnetGroup_603532, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameterGroups_603582 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBClusterParameterGroups_603584(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusterParameterGroups_603583(path: JsonNode;
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
  var valid_603585 = query.getOrDefault("Action")
  valid_603585 = validateParameter(valid_603585, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_603585 != nil:
    section.add "Action", valid_603585
  var valid_603586 = query.getOrDefault("Version")
  valid_603586 = validateParameter(valid_603586, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603586 != nil:
    section.add "Version", valid_603586
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603587 = header.getOrDefault("X-Amz-Date")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Date", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Security-Token")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Security-Token", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Content-Sha256", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Algorithm")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Algorithm", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Signature")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Signature", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-SignedHeaders", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Credential")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Credential", valid_603593
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
  var valid_603594 = formData.getOrDefault("Marker")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "Marker", valid_603594
  var valid_603595 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "DBClusterParameterGroupName", valid_603595
  var valid_603596 = formData.getOrDefault("Filters")
  valid_603596 = validateParameter(valid_603596, JArray, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "Filters", valid_603596
  var valid_603597 = formData.getOrDefault("MaxRecords")
  valid_603597 = validateParameter(valid_603597, JInt, required = false, default = nil)
  if valid_603597 != nil:
    section.add "MaxRecords", valid_603597
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603598: Call_PostDescribeDBClusterParameterGroups_603582;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_603598.validator(path, query, header, formData, body)
  let scheme = call_603598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603598.url(scheme.get, call_603598.host, call_603598.base,
                         call_603598.route, valid.getOrDefault("path"))
  result = hook(call_603598, url, valid)

proc call*(call_603599: Call_PostDescribeDBClusterParameterGroups_603582;
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
  var query_603600 = newJObject()
  var formData_603601 = newJObject()
  add(formData_603601, "Marker", newJString(Marker))
  add(query_603600, "Action", newJString(Action))
  add(formData_603601, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_603601.add "Filters", Filters
  add(formData_603601, "MaxRecords", newJInt(MaxRecords))
  add(query_603600, "Version", newJString(Version))
  result = call_603599.call(nil, query_603600, nil, formData_603601, nil)

var postDescribeDBClusterParameterGroups* = Call_PostDescribeDBClusterParameterGroups_603582(
    name: "postDescribeDBClusterParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_PostDescribeDBClusterParameterGroups_603583, base: "/",
    url: url_PostDescribeDBClusterParameterGroups_603584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameterGroups_603563 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBClusterParameterGroups_603565(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusterParameterGroups_603564(path: JsonNode;
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
  var valid_603566 = query.getOrDefault("MaxRecords")
  valid_603566 = validateParameter(valid_603566, JInt, required = false, default = nil)
  if valid_603566 != nil:
    section.add "MaxRecords", valid_603566
  var valid_603567 = query.getOrDefault("DBClusterParameterGroupName")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "DBClusterParameterGroupName", valid_603567
  var valid_603568 = query.getOrDefault("Filters")
  valid_603568 = validateParameter(valid_603568, JArray, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "Filters", valid_603568
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603569 = query.getOrDefault("Action")
  valid_603569 = validateParameter(valid_603569, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_603569 != nil:
    section.add "Action", valid_603569
  var valid_603570 = query.getOrDefault("Marker")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "Marker", valid_603570
  var valid_603571 = query.getOrDefault("Version")
  valid_603571 = validateParameter(valid_603571, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603571 != nil:
    section.add "Version", valid_603571
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603572 = header.getOrDefault("X-Amz-Date")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Date", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Security-Token")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Security-Token", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Content-Sha256", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Algorithm")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Algorithm", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Signature")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Signature", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-SignedHeaders", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Credential")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Credential", valid_603578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603579: Call_GetDescribeDBClusterParameterGroups_603563;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_603579.validator(path, query, header, formData, body)
  let scheme = call_603579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603579.url(scheme.get, call_603579.host, call_603579.base,
                         call_603579.route, valid.getOrDefault("path"))
  result = hook(call_603579, url, valid)

proc call*(call_603580: Call_GetDescribeDBClusterParameterGroups_603563;
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
  var query_603581 = newJObject()
  add(query_603581, "MaxRecords", newJInt(MaxRecords))
  add(query_603581, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_603581.add "Filters", Filters
  add(query_603581, "Action", newJString(Action))
  add(query_603581, "Marker", newJString(Marker))
  add(query_603581, "Version", newJString(Version))
  result = call_603580.call(nil, query_603581, nil, nil, nil)

var getDescribeDBClusterParameterGroups* = Call_GetDescribeDBClusterParameterGroups_603563(
    name: "getDescribeDBClusterParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_GetDescribeDBClusterParameterGroups_603564, base: "/",
    url: url_GetDescribeDBClusterParameterGroups_603565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameters_603622 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBClusterParameters_603624(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusterParameters_603623(path: JsonNode;
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
  var valid_603625 = query.getOrDefault("Action")
  valid_603625 = validateParameter(valid_603625, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_603625 != nil:
    section.add "Action", valid_603625
  var valid_603626 = query.getOrDefault("Version")
  valid_603626 = validateParameter(valid_603626, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603626 != nil:
    section.add "Version", valid_603626
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603627 = header.getOrDefault("X-Amz-Date")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Date", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-Security-Token")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Security-Token", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Content-Sha256", valid_603629
  var valid_603630 = header.getOrDefault("X-Amz-Algorithm")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Algorithm", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Signature")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Signature", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-SignedHeaders", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Credential")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Credential", valid_603633
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
  var valid_603634 = formData.getOrDefault("Marker")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "Marker", valid_603634
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_603635 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_603635 = validateParameter(valid_603635, JString, required = true,
                                 default = nil)
  if valid_603635 != nil:
    section.add "DBClusterParameterGroupName", valid_603635
  var valid_603636 = formData.getOrDefault("Filters")
  valid_603636 = validateParameter(valid_603636, JArray, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "Filters", valid_603636
  var valid_603637 = formData.getOrDefault("MaxRecords")
  valid_603637 = validateParameter(valid_603637, JInt, required = false, default = nil)
  if valid_603637 != nil:
    section.add "MaxRecords", valid_603637
  var valid_603638 = formData.getOrDefault("Source")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "Source", valid_603638
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603639: Call_PostDescribeDBClusterParameters_603622;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_603639.validator(path, query, header, formData, body)
  let scheme = call_603639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603639.url(scheme.get, call_603639.host, call_603639.base,
                         call_603639.route, valid.getOrDefault("path"))
  result = hook(call_603639, url, valid)

proc call*(call_603640: Call_PostDescribeDBClusterParameters_603622;
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
  var query_603641 = newJObject()
  var formData_603642 = newJObject()
  add(formData_603642, "Marker", newJString(Marker))
  add(query_603641, "Action", newJString(Action))
  add(formData_603642, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_603642.add "Filters", Filters
  add(formData_603642, "MaxRecords", newJInt(MaxRecords))
  add(query_603641, "Version", newJString(Version))
  add(formData_603642, "Source", newJString(Source))
  result = call_603640.call(nil, query_603641, nil, formData_603642, nil)

var postDescribeDBClusterParameters* = Call_PostDescribeDBClusterParameters_603622(
    name: "postDescribeDBClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_PostDescribeDBClusterParameters_603623, base: "/",
    url: url_PostDescribeDBClusterParameters_603624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameters_603602 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBClusterParameters_603604(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusterParameters_603603(path: JsonNode;
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
  var valid_603605 = query.getOrDefault("MaxRecords")
  valid_603605 = validateParameter(valid_603605, JInt, required = false, default = nil)
  if valid_603605 != nil:
    section.add "MaxRecords", valid_603605
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_603606 = query.getOrDefault("DBClusterParameterGroupName")
  valid_603606 = validateParameter(valid_603606, JString, required = true,
                                 default = nil)
  if valid_603606 != nil:
    section.add "DBClusterParameterGroupName", valid_603606
  var valid_603607 = query.getOrDefault("Filters")
  valid_603607 = validateParameter(valid_603607, JArray, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "Filters", valid_603607
  var valid_603608 = query.getOrDefault("Action")
  valid_603608 = validateParameter(valid_603608, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_603608 != nil:
    section.add "Action", valid_603608
  var valid_603609 = query.getOrDefault("Marker")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "Marker", valid_603609
  var valid_603610 = query.getOrDefault("Source")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "Source", valid_603610
  var valid_603611 = query.getOrDefault("Version")
  valid_603611 = validateParameter(valid_603611, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603611 != nil:
    section.add "Version", valid_603611
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603612 = header.getOrDefault("X-Amz-Date")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-Date", valid_603612
  var valid_603613 = header.getOrDefault("X-Amz-Security-Token")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Security-Token", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Content-Sha256", valid_603614
  var valid_603615 = header.getOrDefault("X-Amz-Algorithm")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Algorithm", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Signature")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Signature", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-SignedHeaders", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Credential")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Credential", valid_603618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603619: Call_GetDescribeDBClusterParameters_603602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_603619.validator(path, query, header, formData, body)
  let scheme = call_603619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603619.url(scheme.get, call_603619.host, call_603619.base,
                         call_603619.route, valid.getOrDefault("path"))
  result = hook(call_603619, url, valid)

proc call*(call_603620: Call_GetDescribeDBClusterParameters_603602;
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
  var query_603621 = newJObject()
  add(query_603621, "MaxRecords", newJInt(MaxRecords))
  add(query_603621, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_603621.add "Filters", Filters
  add(query_603621, "Action", newJString(Action))
  add(query_603621, "Marker", newJString(Marker))
  add(query_603621, "Source", newJString(Source))
  add(query_603621, "Version", newJString(Version))
  result = call_603620.call(nil, query_603621, nil, nil, nil)

var getDescribeDBClusterParameters* = Call_GetDescribeDBClusterParameters_603602(
    name: "getDescribeDBClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_GetDescribeDBClusterParameters_603603, base: "/",
    url: url_GetDescribeDBClusterParameters_603604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshotAttributes_603659 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBClusterSnapshotAttributes_603661(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusterSnapshotAttributes_603660(path: JsonNode;
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
  var valid_603662 = query.getOrDefault("Action")
  valid_603662 = validateParameter(valid_603662, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_603662 != nil:
    section.add "Action", valid_603662
  var valid_603663 = query.getOrDefault("Version")
  valid_603663 = validateParameter(valid_603663, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603663 != nil:
    section.add "Version", valid_603663
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603664 = header.getOrDefault("X-Amz-Date")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Date", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Security-Token")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Security-Token", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-Content-Sha256", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-Algorithm")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Algorithm", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-Signature")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Signature", valid_603668
  var valid_603669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-SignedHeaders", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-Credential")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Credential", valid_603670
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_603671 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603671 = validateParameter(valid_603671, JString, required = true,
                                 default = nil)
  if valid_603671 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603671
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603672: Call_PostDescribeDBClusterSnapshotAttributes_603659;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_603672.validator(path, query, header, formData, body)
  let scheme = call_603672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603672.url(scheme.get, call_603672.host, call_603672.base,
                         call_603672.route, valid.getOrDefault("path"))
  result = hook(call_603672, url, valid)

proc call*(call_603673: Call_PostDescribeDBClusterSnapshotAttributes_603659;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603674 = newJObject()
  var formData_603675 = newJObject()
  add(formData_603675, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_603674, "Action", newJString(Action))
  add(query_603674, "Version", newJString(Version))
  result = call_603673.call(nil, query_603674, nil, formData_603675, nil)

var postDescribeDBClusterSnapshotAttributes* = Call_PostDescribeDBClusterSnapshotAttributes_603659(
    name: "postDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_PostDescribeDBClusterSnapshotAttributes_603660, base: "/",
    url: url_PostDescribeDBClusterSnapshotAttributes_603661,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshotAttributes_603643 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBClusterSnapshotAttributes_603645(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusterSnapshotAttributes_603644(path: JsonNode;
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
  var valid_603646 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603646 = validateParameter(valid_603646, JString, required = true,
                                 default = nil)
  if valid_603646 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603646
  var valid_603647 = query.getOrDefault("Action")
  valid_603647 = validateParameter(valid_603647, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_603647 != nil:
    section.add "Action", valid_603647
  var valid_603648 = query.getOrDefault("Version")
  valid_603648 = validateParameter(valid_603648, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603648 != nil:
    section.add "Version", valid_603648
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603649 = header.getOrDefault("X-Amz-Date")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Date", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Security-Token")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Security-Token", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-Content-Sha256", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Algorithm")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Algorithm", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Signature")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Signature", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-SignedHeaders", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Credential")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Credential", valid_603655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603656: Call_GetDescribeDBClusterSnapshotAttributes_603643;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_603656.validator(path, query, header, formData, body)
  let scheme = call_603656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603656.url(scheme.get, call_603656.host, call_603656.base,
                         call_603656.route, valid.getOrDefault("path"))
  result = hook(call_603656, url, valid)

proc call*(call_603657: Call_GetDescribeDBClusterSnapshotAttributes_603643;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603658 = newJObject()
  add(query_603658, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_603658, "Action", newJString(Action))
  add(query_603658, "Version", newJString(Version))
  result = call_603657.call(nil, query_603658, nil, nil, nil)

var getDescribeDBClusterSnapshotAttributes* = Call_GetDescribeDBClusterSnapshotAttributes_603643(
    name: "getDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_GetDescribeDBClusterSnapshotAttributes_603644, base: "/",
    url: url_GetDescribeDBClusterSnapshotAttributes_603645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshots_603699 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBClusterSnapshots_603701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusterSnapshots_603700(path: JsonNode;
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
  var valid_603702 = query.getOrDefault("Action")
  valid_603702 = validateParameter(valid_603702, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_603702 != nil:
    section.add "Action", valid_603702
  var valid_603703 = query.getOrDefault("Version")
  valid_603703 = validateParameter(valid_603703, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603703 != nil:
    section.add "Version", valid_603703
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603704 = header.getOrDefault("X-Amz-Date")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Date", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-Security-Token")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Security-Token", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Content-Sha256", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Algorithm")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Algorithm", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Signature")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Signature", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-SignedHeaders", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Credential")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Credential", valid_603710
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
  var valid_603711 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603711
  var valid_603712 = formData.getOrDefault("IncludeShared")
  valid_603712 = validateParameter(valid_603712, JBool, required = false, default = nil)
  if valid_603712 != nil:
    section.add "IncludeShared", valid_603712
  var valid_603713 = formData.getOrDefault("IncludePublic")
  valid_603713 = validateParameter(valid_603713, JBool, required = false, default = nil)
  if valid_603713 != nil:
    section.add "IncludePublic", valid_603713
  var valid_603714 = formData.getOrDefault("SnapshotType")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "SnapshotType", valid_603714
  var valid_603715 = formData.getOrDefault("Marker")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "Marker", valid_603715
  var valid_603716 = formData.getOrDefault("Filters")
  valid_603716 = validateParameter(valid_603716, JArray, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "Filters", valid_603716
  var valid_603717 = formData.getOrDefault("MaxRecords")
  valid_603717 = validateParameter(valid_603717, JInt, required = false, default = nil)
  if valid_603717 != nil:
    section.add "MaxRecords", valid_603717
  var valid_603718 = formData.getOrDefault("DBClusterIdentifier")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "DBClusterIdentifier", valid_603718
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603719: Call_PostDescribeDBClusterSnapshots_603699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_603719.validator(path, query, header, formData, body)
  let scheme = call_603719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603719.url(scheme.get, call_603719.host, call_603719.base,
                         call_603719.route, valid.getOrDefault("path"))
  result = hook(call_603719, url, valid)

proc call*(call_603720: Call_PostDescribeDBClusterSnapshots_603699;
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
  var query_603721 = newJObject()
  var formData_603722 = newJObject()
  add(formData_603722, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(formData_603722, "IncludeShared", newJBool(IncludeShared))
  add(formData_603722, "IncludePublic", newJBool(IncludePublic))
  add(formData_603722, "SnapshotType", newJString(SnapshotType))
  add(formData_603722, "Marker", newJString(Marker))
  add(query_603721, "Action", newJString(Action))
  if Filters != nil:
    formData_603722.add "Filters", Filters
  add(formData_603722, "MaxRecords", newJInt(MaxRecords))
  add(formData_603722, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603721, "Version", newJString(Version))
  result = call_603720.call(nil, query_603721, nil, formData_603722, nil)

var postDescribeDBClusterSnapshots* = Call_PostDescribeDBClusterSnapshots_603699(
    name: "postDescribeDBClusterSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_PostDescribeDBClusterSnapshots_603700, base: "/",
    url: url_PostDescribeDBClusterSnapshots_603701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshots_603676 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBClusterSnapshots_603678(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusterSnapshots_603677(path: JsonNode; query: JsonNode;
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
  var valid_603679 = query.getOrDefault("IncludePublic")
  valid_603679 = validateParameter(valid_603679, JBool, required = false, default = nil)
  if valid_603679 != nil:
    section.add "IncludePublic", valid_603679
  var valid_603680 = query.getOrDefault("MaxRecords")
  valid_603680 = validateParameter(valid_603680, JInt, required = false, default = nil)
  if valid_603680 != nil:
    section.add "MaxRecords", valid_603680
  var valid_603681 = query.getOrDefault("DBClusterIdentifier")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "DBClusterIdentifier", valid_603681
  var valid_603682 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603682
  var valid_603683 = query.getOrDefault("Filters")
  valid_603683 = validateParameter(valid_603683, JArray, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "Filters", valid_603683
  var valid_603684 = query.getOrDefault("IncludeShared")
  valid_603684 = validateParameter(valid_603684, JBool, required = false, default = nil)
  if valid_603684 != nil:
    section.add "IncludeShared", valid_603684
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603685 = query.getOrDefault("Action")
  valid_603685 = validateParameter(valid_603685, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_603685 != nil:
    section.add "Action", valid_603685
  var valid_603686 = query.getOrDefault("Marker")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "Marker", valid_603686
  var valid_603687 = query.getOrDefault("SnapshotType")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "SnapshotType", valid_603687
  var valid_603688 = query.getOrDefault("Version")
  valid_603688 = validateParameter(valid_603688, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603688 != nil:
    section.add "Version", valid_603688
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603689 = header.getOrDefault("X-Amz-Date")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Date", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Security-Token")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Security-Token", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Content-Sha256", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Algorithm")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Algorithm", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Signature")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Signature", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-SignedHeaders", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Credential")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Credential", valid_603695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603696: Call_GetDescribeDBClusterSnapshots_603676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_603696.validator(path, query, header, formData, body)
  let scheme = call_603696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603696.url(scheme.get, call_603696.host, call_603696.base,
                         call_603696.route, valid.getOrDefault("path"))
  result = hook(call_603696, url, valid)

proc call*(call_603697: Call_GetDescribeDBClusterSnapshots_603676;
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
  var query_603698 = newJObject()
  add(query_603698, "IncludePublic", newJBool(IncludePublic))
  add(query_603698, "MaxRecords", newJInt(MaxRecords))
  add(query_603698, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603698, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Filters != nil:
    query_603698.add "Filters", Filters
  add(query_603698, "IncludeShared", newJBool(IncludeShared))
  add(query_603698, "Action", newJString(Action))
  add(query_603698, "Marker", newJString(Marker))
  add(query_603698, "SnapshotType", newJString(SnapshotType))
  add(query_603698, "Version", newJString(Version))
  result = call_603697.call(nil, query_603698, nil, nil, nil)

var getDescribeDBClusterSnapshots* = Call_GetDescribeDBClusterSnapshots_603676(
    name: "getDescribeDBClusterSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_GetDescribeDBClusterSnapshots_603677, base: "/",
    url: url_GetDescribeDBClusterSnapshots_603678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusters_603742 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBClusters_603744(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBClusters_603743(path: JsonNode; query: JsonNode;
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
  var valid_603745 = query.getOrDefault("Action")
  valid_603745 = validateParameter(valid_603745, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_603745 != nil:
    section.add "Action", valid_603745
  var valid_603746 = query.getOrDefault("Version")
  valid_603746 = validateParameter(valid_603746, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603746 != nil:
    section.add "Version", valid_603746
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603747 = header.getOrDefault("X-Amz-Date")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-Date", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-Security-Token")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Security-Token", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Content-Sha256", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Algorithm")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Algorithm", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Signature")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Signature", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-SignedHeaders", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Credential")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Credential", valid_603753
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
  var valid_603754 = formData.getOrDefault("Marker")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "Marker", valid_603754
  var valid_603755 = formData.getOrDefault("Filters")
  valid_603755 = validateParameter(valid_603755, JArray, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "Filters", valid_603755
  var valid_603756 = formData.getOrDefault("MaxRecords")
  valid_603756 = validateParameter(valid_603756, JInt, required = false, default = nil)
  if valid_603756 != nil:
    section.add "MaxRecords", valid_603756
  var valid_603757 = formData.getOrDefault("DBClusterIdentifier")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "DBClusterIdentifier", valid_603757
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603758: Call_PostDescribeDBClusters_603742; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_603758.validator(path, query, header, formData, body)
  let scheme = call_603758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603758.url(scheme.get, call_603758.host, call_603758.base,
                         call_603758.route, valid.getOrDefault("path"))
  result = hook(call_603758, url, valid)

proc call*(call_603759: Call_PostDescribeDBClusters_603742; Marker: string = "";
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
  var query_603760 = newJObject()
  var formData_603761 = newJObject()
  add(formData_603761, "Marker", newJString(Marker))
  add(query_603760, "Action", newJString(Action))
  if Filters != nil:
    formData_603761.add "Filters", Filters
  add(formData_603761, "MaxRecords", newJInt(MaxRecords))
  add(formData_603761, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603760, "Version", newJString(Version))
  result = call_603759.call(nil, query_603760, nil, formData_603761, nil)

var postDescribeDBClusters* = Call_PostDescribeDBClusters_603742(
    name: "postDescribeDBClusters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_PostDescribeDBClusters_603743, base: "/",
    url: url_PostDescribeDBClusters_603744, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusters_603723 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBClusters_603725(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBClusters_603724(path: JsonNode; query: JsonNode;
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
  var valid_603726 = query.getOrDefault("MaxRecords")
  valid_603726 = validateParameter(valid_603726, JInt, required = false, default = nil)
  if valid_603726 != nil:
    section.add "MaxRecords", valid_603726
  var valid_603727 = query.getOrDefault("DBClusterIdentifier")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "DBClusterIdentifier", valid_603727
  var valid_603728 = query.getOrDefault("Filters")
  valid_603728 = validateParameter(valid_603728, JArray, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "Filters", valid_603728
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603729 = query.getOrDefault("Action")
  valid_603729 = validateParameter(valid_603729, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_603729 != nil:
    section.add "Action", valid_603729
  var valid_603730 = query.getOrDefault("Marker")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "Marker", valid_603730
  var valid_603731 = query.getOrDefault("Version")
  valid_603731 = validateParameter(valid_603731, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603731 != nil:
    section.add "Version", valid_603731
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603732 = header.getOrDefault("X-Amz-Date")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Date", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Security-Token")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Security-Token", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Content-Sha256", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Algorithm")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Algorithm", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Signature")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Signature", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-SignedHeaders", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-Credential")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Credential", valid_603738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603739: Call_GetDescribeDBClusters_603723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_603739.validator(path, query, header, formData, body)
  let scheme = call_603739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603739.url(scheme.get, call_603739.host, call_603739.base,
                         call_603739.route, valid.getOrDefault("path"))
  result = hook(call_603739, url, valid)

proc call*(call_603740: Call_GetDescribeDBClusters_603723; MaxRecords: int = 0;
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
  var query_603741 = newJObject()
  add(query_603741, "MaxRecords", newJInt(MaxRecords))
  add(query_603741, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if Filters != nil:
    query_603741.add "Filters", Filters
  add(query_603741, "Action", newJString(Action))
  add(query_603741, "Marker", newJString(Marker))
  add(query_603741, "Version", newJString(Version))
  result = call_603740.call(nil, query_603741, nil, nil, nil)

var getDescribeDBClusters* = Call_GetDescribeDBClusters_603723(
    name: "getDescribeDBClusters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_GetDescribeDBClusters_603724, base: "/",
    url: url_GetDescribeDBClusters_603725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_603786 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBEngineVersions_603788(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBEngineVersions_603787(path: JsonNode; query: JsonNode;
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
  var valid_603789 = query.getOrDefault("Action")
  valid_603789 = validateParameter(valid_603789, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603789 != nil:
    section.add "Action", valid_603789
  var valid_603790 = query.getOrDefault("Version")
  valid_603790 = validateParameter(valid_603790, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603790 != nil:
    section.add "Version", valid_603790
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603791 = header.getOrDefault("X-Amz-Date")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Date", valid_603791
  var valid_603792 = header.getOrDefault("X-Amz-Security-Token")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-Security-Token", valid_603792
  var valid_603793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-Content-Sha256", valid_603793
  var valid_603794 = header.getOrDefault("X-Amz-Algorithm")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "X-Amz-Algorithm", valid_603794
  var valid_603795 = header.getOrDefault("X-Amz-Signature")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-Signature", valid_603795
  var valid_603796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-SignedHeaders", valid_603796
  var valid_603797 = header.getOrDefault("X-Amz-Credential")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Credential", valid_603797
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
  var valid_603798 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_603798 = validateParameter(valid_603798, JBool, required = false, default = nil)
  if valid_603798 != nil:
    section.add "ListSupportedCharacterSets", valid_603798
  var valid_603799 = formData.getOrDefault("Engine")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "Engine", valid_603799
  var valid_603800 = formData.getOrDefault("Marker")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "Marker", valid_603800
  var valid_603801 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "DBParameterGroupFamily", valid_603801
  var valid_603802 = formData.getOrDefault("Filters")
  valid_603802 = validateParameter(valid_603802, JArray, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "Filters", valid_603802
  var valid_603803 = formData.getOrDefault("MaxRecords")
  valid_603803 = validateParameter(valid_603803, JInt, required = false, default = nil)
  if valid_603803 != nil:
    section.add "MaxRecords", valid_603803
  var valid_603804 = formData.getOrDefault("EngineVersion")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "EngineVersion", valid_603804
  var valid_603805 = formData.getOrDefault("ListSupportedTimezones")
  valid_603805 = validateParameter(valid_603805, JBool, required = false, default = nil)
  if valid_603805 != nil:
    section.add "ListSupportedTimezones", valid_603805
  var valid_603806 = formData.getOrDefault("DefaultOnly")
  valid_603806 = validateParameter(valid_603806, JBool, required = false, default = nil)
  if valid_603806 != nil:
    section.add "DefaultOnly", valid_603806
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603807: Call_PostDescribeDBEngineVersions_603786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_603807.validator(path, query, header, formData, body)
  let scheme = call_603807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603807.url(scheme.get, call_603807.host, call_603807.base,
                         call_603807.route, valid.getOrDefault("path"))
  result = hook(call_603807, url, valid)

proc call*(call_603808: Call_PostDescribeDBEngineVersions_603786;
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
  var query_603809 = newJObject()
  var formData_603810 = newJObject()
  add(formData_603810, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_603810, "Engine", newJString(Engine))
  add(formData_603810, "Marker", newJString(Marker))
  add(query_603809, "Action", newJString(Action))
  add(formData_603810, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_603810.add "Filters", Filters
  add(formData_603810, "MaxRecords", newJInt(MaxRecords))
  add(formData_603810, "EngineVersion", newJString(EngineVersion))
  add(formData_603810, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_603809, "Version", newJString(Version))
  add(formData_603810, "DefaultOnly", newJBool(DefaultOnly))
  result = call_603808.call(nil, query_603809, nil, formData_603810, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_603786(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_603787, base: "/",
    url: url_PostDescribeDBEngineVersions_603788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_603762 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBEngineVersions_603764(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBEngineVersions_603763(path: JsonNode; query: JsonNode;
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
  var valid_603765 = query.getOrDefault("Engine")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "Engine", valid_603765
  var valid_603766 = query.getOrDefault("ListSupportedCharacterSets")
  valid_603766 = validateParameter(valid_603766, JBool, required = false, default = nil)
  if valid_603766 != nil:
    section.add "ListSupportedCharacterSets", valid_603766
  var valid_603767 = query.getOrDefault("MaxRecords")
  valid_603767 = validateParameter(valid_603767, JInt, required = false, default = nil)
  if valid_603767 != nil:
    section.add "MaxRecords", valid_603767
  var valid_603768 = query.getOrDefault("DBParameterGroupFamily")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "DBParameterGroupFamily", valid_603768
  var valid_603769 = query.getOrDefault("Filters")
  valid_603769 = validateParameter(valid_603769, JArray, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "Filters", valid_603769
  var valid_603770 = query.getOrDefault("ListSupportedTimezones")
  valid_603770 = validateParameter(valid_603770, JBool, required = false, default = nil)
  if valid_603770 != nil:
    section.add "ListSupportedTimezones", valid_603770
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603771 = query.getOrDefault("Action")
  valid_603771 = validateParameter(valid_603771, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603771 != nil:
    section.add "Action", valid_603771
  var valid_603772 = query.getOrDefault("Marker")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "Marker", valid_603772
  var valid_603773 = query.getOrDefault("EngineVersion")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "EngineVersion", valid_603773
  var valid_603774 = query.getOrDefault("DefaultOnly")
  valid_603774 = validateParameter(valid_603774, JBool, required = false, default = nil)
  if valid_603774 != nil:
    section.add "DefaultOnly", valid_603774
  var valid_603775 = query.getOrDefault("Version")
  valid_603775 = validateParameter(valid_603775, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603775 != nil:
    section.add "Version", valid_603775
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603776 = header.getOrDefault("X-Amz-Date")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Date", valid_603776
  var valid_603777 = header.getOrDefault("X-Amz-Security-Token")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Security-Token", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-Content-Sha256", valid_603778
  var valid_603779 = header.getOrDefault("X-Amz-Algorithm")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-Algorithm", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Signature")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Signature", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-SignedHeaders", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-Credential")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-Credential", valid_603782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603783: Call_GetDescribeDBEngineVersions_603762; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_603783.validator(path, query, header, formData, body)
  let scheme = call_603783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603783.url(scheme.get, call_603783.host, call_603783.base,
                         call_603783.route, valid.getOrDefault("path"))
  result = hook(call_603783, url, valid)

proc call*(call_603784: Call_GetDescribeDBEngineVersions_603762;
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
  var query_603785 = newJObject()
  add(query_603785, "Engine", newJString(Engine))
  add(query_603785, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_603785, "MaxRecords", newJInt(MaxRecords))
  add(query_603785, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_603785.add "Filters", Filters
  add(query_603785, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_603785, "Action", newJString(Action))
  add(query_603785, "Marker", newJString(Marker))
  add(query_603785, "EngineVersion", newJString(EngineVersion))
  add(query_603785, "DefaultOnly", newJBool(DefaultOnly))
  add(query_603785, "Version", newJString(Version))
  result = call_603784.call(nil, query_603785, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_603762(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_603763, base: "/",
    url: url_GetDescribeDBEngineVersions_603764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_603830 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBInstances_603832(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBInstances_603831(path: JsonNode; query: JsonNode;
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
  var valid_603833 = query.getOrDefault("Action")
  valid_603833 = validateParameter(valid_603833, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603833 != nil:
    section.add "Action", valid_603833
  var valid_603834 = query.getOrDefault("Version")
  valid_603834 = validateParameter(valid_603834, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603834 != nil:
    section.add "Version", valid_603834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603835 = header.getOrDefault("X-Amz-Date")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-Date", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Security-Token")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Security-Token", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Content-Sha256", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-Algorithm")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Algorithm", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Signature")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Signature", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-SignedHeaders", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Credential")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Credential", valid_603841
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
  var valid_603842 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "DBInstanceIdentifier", valid_603842
  var valid_603843 = formData.getOrDefault("Marker")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "Marker", valid_603843
  var valid_603844 = formData.getOrDefault("Filters")
  valid_603844 = validateParameter(valid_603844, JArray, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "Filters", valid_603844
  var valid_603845 = formData.getOrDefault("MaxRecords")
  valid_603845 = validateParameter(valid_603845, JInt, required = false, default = nil)
  if valid_603845 != nil:
    section.add "MaxRecords", valid_603845
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603846: Call_PostDescribeDBInstances_603830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_603846.validator(path, query, header, formData, body)
  let scheme = call_603846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603846.url(scheme.get, call_603846.host, call_603846.base,
                         call_603846.route, valid.getOrDefault("path"))
  result = hook(call_603846, url, valid)

proc call*(call_603847: Call_PostDescribeDBInstances_603830;
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
  var query_603848 = newJObject()
  var formData_603849 = newJObject()
  add(formData_603849, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603849, "Marker", newJString(Marker))
  add(query_603848, "Action", newJString(Action))
  if Filters != nil:
    formData_603849.add "Filters", Filters
  add(formData_603849, "MaxRecords", newJInt(MaxRecords))
  add(query_603848, "Version", newJString(Version))
  result = call_603847.call(nil, query_603848, nil, formData_603849, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_603830(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_603831, base: "/",
    url: url_PostDescribeDBInstances_603832, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_603811 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBInstances_603813(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBInstances_603812(path: JsonNode; query: JsonNode;
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
  var valid_603814 = query.getOrDefault("MaxRecords")
  valid_603814 = validateParameter(valid_603814, JInt, required = false, default = nil)
  if valid_603814 != nil:
    section.add "MaxRecords", valid_603814
  var valid_603815 = query.getOrDefault("Filters")
  valid_603815 = validateParameter(valid_603815, JArray, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "Filters", valid_603815
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603816 = query.getOrDefault("Action")
  valid_603816 = validateParameter(valid_603816, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603816 != nil:
    section.add "Action", valid_603816
  var valid_603817 = query.getOrDefault("Marker")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "Marker", valid_603817
  var valid_603818 = query.getOrDefault("Version")
  valid_603818 = validateParameter(valid_603818, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603818 != nil:
    section.add "Version", valid_603818
  var valid_603819 = query.getOrDefault("DBInstanceIdentifier")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "DBInstanceIdentifier", valid_603819
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603820 = header.getOrDefault("X-Amz-Date")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-Date", valid_603820
  var valid_603821 = header.getOrDefault("X-Amz-Security-Token")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Security-Token", valid_603821
  var valid_603822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "X-Amz-Content-Sha256", valid_603822
  var valid_603823 = header.getOrDefault("X-Amz-Algorithm")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Algorithm", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Signature")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Signature", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-SignedHeaders", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Credential")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Credential", valid_603826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603827: Call_GetDescribeDBInstances_603811; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_603827.validator(path, query, header, formData, body)
  let scheme = call_603827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603827.url(scheme.get, call_603827.host, call_603827.base,
                         call_603827.route, valid.getOrDefault("path"))
  result = hook(call_603827, url, valid)

proc call*(call_603828: Call_GetDescribeDBInstances_603811; MaxRecords: int = 0;
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
  var query_603829 = newJObject()
  add(query_603829, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_603829.add "Filters", Filters
  add(query_603829, "Action", newJString(Action))
  add(query_603829, "Marker", newJString(Marker))
  add(query_603829, "Version", newJString(Version))
  add(query_603829, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603828.call(nil, query_603829, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_603811(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_603812, base: "/",
    url: url_GetDescribeDBInstances_603813, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_603869 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBSubnetGroups_603871(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSubnetGroups_603870(path: JsonNode; query: JsonNode;
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
  var valid_603872 = query.getOrDefault("Action")
  valid_603872 = validateParameter(valid_603872, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_603872 != nil:
    section.add "Action", valid_603872
  var valid_603873 = query.getOrDefault("Version")
  valid_603873 = validateParameter(valid_603873, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603873 != nil:
    section.add "Version", valid_603873
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603874 = header.getOrDefault("X-Amz-Date")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Date", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Security-Token")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Security-Token", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-Content-Sha256", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-Algorithm")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Algorithm", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-Signature")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Signature", valid_603878
  var valid_603879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "X-Amz-SignedHeaders", valid_603879
  var valid_603880 = header.getOrDefault("X-Amz-Credential")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-Credential", valid_603880
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
  var valid_603881 = formData.getOrDefault("DBSubnetGroupName")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "DBSubnetGroupName", valid_603881
  var valid_603882 = formData.getOrDefault("Marker")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "Marker", valid_603882
  var valid_603883 = formData.getOrDefault("Filters")
  valid_603883 = validateParameter(valid_603883, JArray, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "Filters", valid_603883
  var valid_603884 = formData.getOrDefault("MaxRecords")
  valid_603884 = validateParameter(valid_603884, JInt, required = false, default = nil)
  if valid_603884 != nil:
    section.add "MaxRecords", valid_603884
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603885: Call_PostDescribeDBSubnetGroups_603869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_603885.validator(path, query, header, formData, body)
  let scheme = call_603885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603885.url(scheme.get, call_603885.host, call_603885.base,
                         call_603885.route, valid.getOrDefault("path"))
  result = hook(call_603885, url, valid)

proc call*(call_603886: Call_PostDescribeDBSubnetGroups_603869;
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
  var query_603887 = newJObject()
  var formData_603888 = newJObject()
  add(formData_603888, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603888, "Marker", newJString(Marker))
  add(query_603887, "Action", newJString(Action))
  if Filters != nil:
    formData_603888.add "Filters", Filters
  add(formData_603888, "MaxRecords", newJInt(MaxRecords))
  add(query_603887, "Version", newJString(Version))
  result = call_603886.call(nil, query_603887, nil, formData_603888, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_603869(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_603870, base: "/",
    url: url_PostDescribeDBSubnetGroups_603871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_603850 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBSubnetGroups_603852(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSubnetGroups_603851(path: JsonNode; query: JsonNode;
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
  var valid_603853 = query.getOrDefault("MaxRecords")
  valid_603853 = validateParameter(valid_603853, JInt, required = false, default = nil)
  if valid_603853 != nil:
    section.add "MaxRecords", valid_603853
  var valid_603854 = query.getOrDefault("Filters")
  valid_603854 = validateParameter(valid_603854, JArray, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "Filters", valid_603854
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603855 = query.getOrDefault("Action")
  valid_603855 = validateParameter(valid_603855, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_603855 != nil:
    section.add "Action", valid_603855
  var valid_603856 = query.getOrDefault("Marker")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "Marker", valid_603856
  var valid_603857 = query.getOrDefault("DBSubnetGroupName")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "DBSubnetGroupName", valid_603857
  var valid_603858 = query.getOrDefault("Version")
  valid_603858 = validateParameter(valid_603858, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603858 != nil:
    section.add "Version", valid_603858
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603859 = header.getOrDefault("X-Amz-Date")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Date", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-Security-Token")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Security-Token", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-Content-Sha256", valid_603861
  var valid_603862 = header.getOrDefault("X-Amz-Algorithm")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Algorithm", valid_603862
  var valid_603863 = header.getOrDefault("X-Amz-Signature")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Signature", valid_603863
  var valid_603864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-SignedHeaders", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-Credential")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Credential", valid_603865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603866: Call_GetDescribeDBSubnetGroups_603850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_603866.validator(path, query, header, formData, body)
  let scheme = call_603866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603866.url(scheme.get, call_603866.host, call_603866.base,
                         call_603866.route, valid.getOrDefault("path"))
  result = hook(call_603866, url, valid)

proc call*(call_603867: Call_GetDescribeDBSubnetGroups_603850; MaxRecords: int = 0;
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
  var query_603868 = newJObject()
  add(query_603868, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_603868.add "Filters", Filters
  add(query_603868, "Action", newJString(Action))
  add(query_603868, "Marker", newJString(Marker))
  add(query_603868, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603868, "Version", newJString(Version))
  result = call_603867.call(nil, query_603868, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_603850(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_603851, base: "/",
    url: url_GetDescribeDBSubnetGroups_603852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultClusterParameters_603908 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEngineDefaultClusterParameters_603910(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEngineDefaultClusterParameters_603909(path: JsonNode;
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
  var valid_603911 = query.getOrDefault("Action")
  valid_603911 = validateParameter(valid_603911, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_603911 != nil:
    section.add "Action", valid_603911
  var valid_603912 = query.getOrDefault("Version")
  valid_603912 = validateParameter(valid_603912, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603912 != nil:
    section.add "Version", valid_603912
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603913 = header.getOrDefault("X-Amz-Date")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-Date", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-Security-Token")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-Security-Token", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Content-Sha256", valid_603915
  var valid_603916 = header.getOrDefault("X-Amz-Algorithm")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-Algorithm", valid_603916
  var valid_603917 = header.getOrDefault("X-Amz-Signature")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-Signature", valid_603917
  var valid_603918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-SignedHeaders", valid_603918
  var valid_603919 = header.getOrDefault("X-Amz-Credential")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Credential", valid_603919
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
  var valid_603920 = formData.getOrDefault("Marker")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "Marker", valid_603920
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_603921 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603921 = validateParameter(valid_603921, JString, required = true,
                                 default = nil)
  if valid_603921 != nil:
    section.add "DBParameterGroupFamily", valid_603921
  var valid_603922 = formData.getOrDefault("Filters")
  valid_603922 = validateParameter(valid_603922, JArray, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "Filters", valid_603922
  var valid_603923 = formData.getOrDefault("MaxRecords")
  valid_603923 = validateParameter(valid_603923, JInt, required = false, default = nil)
  if valid_603923 != nil:
    section.add "MaxRecords", valid_603923
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603924: Call_PostDescribeEngineDefaultClusterParameters_603908;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_603924.validator(path, query, header, formData, body)
  let scheme = call_603924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603924.url(scheme.get, call_603924.host, call_603924.base,
                         call_603924.route, valid.getOrDefault("path"))
  result = hook(call_603924, url, valid)

proc call*(call_603925: Call_PostDescribeEngineDefaultClusterParameters_603908;
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
  var query_603926 = newJObject()
  var formData_603927 = newJObject()
  add(formData_603927, "Marker", newJString(Marker))
  add(query_603926, "Action", newJString(Action))
  add(formData_603927, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_603927.add "Filters", Filters
  add(formData_603927, "MaxRecords", newJInt(MaxRecords))
  add(query_603926, "Version", newJString(Version))
  result = call_603925.call(nil, query_603926, nil, formData_603927, nil)

var postDescribeEngineDefaultClusterParameters* = Call_PostDescribeEngineDefaultClusterParameters_603908(
    name: "postDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_PostDescribeEngineDefaultClusterParameters_603909,
    base: "/", url: url_PostDescribeEngineDefaultClusterParameters_603910,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultClusterParameters_603889 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEngineDefaultClusterParameters_603891(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEngineDefaultClusterParameters_603890(path: JsonNode;
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
  var valid_603892 = query.getOrDefault("MaxRecords")
  valid_603892 = validateParameter(valid_603892, JInt, required = false, default = nil)
  if valid_603892 != nil:
    section.add "MaxRecords", valid_603892
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_603893 = query.getOrDefault("DBParameterGroupFamily")
  valid_603893 = validateParameter(valid_603893, JString, required = true,
                                 default = nil)
  if valid_603893 != nil:
    section.add "DBParameterGroupFamily", valid_603893
  var valid_603894 = query.getOrDefault("Filters")
  valid_603894 = validateParameter(valid_603894, JArray, required = false,
                                 default = nil)
  if valid_603894 != nil:
    section.add "Filters", valid_603894
  var valid_603895 = query.getOrDefault("Action")
  valid_603895 = validateParameter(valid_603895, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_603895 != nil:
    section.add "Action", valid_603895
  var valid_603896 = query.getOrDefault("Marker")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "Marker", valid_603896
  var valid_603897 = query.getOrDefault("Version")
  valid_603897 = validateParameter(valid_603897, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603897 != nil:
    section.add "Version", valid_603897
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603898 = header.getOrDefault("X-Amz-Date")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Date", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-Security-Token")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-Security-Token", valid_603899
  var valid_603900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-Content-Sha256", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-Algorithm")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-Algorithm", valid_603901
  var valid_603902 = header.getOrDefault("X-Amz-Signature")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "X-Amz-Signature", valid_603902
  var valid_603903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-SignedHeaders", valid_603903
  var valid_603904 = header.getOrDefault("X-Amz-Credential")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Credential", valid_603904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603905: Call_GetDescribeEngineDefaultClusterParameters_603889;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_603905.validator(path, query, header, formData, body)
  let scheme = call_603905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603905.url(scheme.get, call_603905.host, call_603905.base,
                         call_603905.route, valid.getOrDefault("path"))
  result = hook(call_603905, url, valid)

proc call*(call_603906: Call_GetDescribeEngineDefaultClusterParameters_603889;
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
  var query_603907 = newJObject()
  add(query_603907, "MaxRecords", newJInt(MaxRecords))
  add(query_603907, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_603907.add "Filters", Filters
  add(query_603907, "Action", newJString(Action))
  add(query_603907, "Marker", newJString(Marker))
  add(query_603907, "Version", newJString(Version))
  result = call_603906.call(nil, query_603907, nil, nil, nil)

var getDescribeEngineDefaultClusterParameters* = Call_GetDescribeEngineDefaultClusterParameters_603889(
    name: "getDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_GetDescribeEngineDefaultClusterParameters_603890,
    base: "/", url: url_GetDescribeEngineDefaultClusterParameters_603891,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_603945 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEventCategories_603947(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventCategories_603946(path: JsonNode; query: JsonNode;
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
  var valid_603948 = query.getOrDefault("Action")
  valid_603948 = validateParameter(valid_603948, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_603948 != nil:
    section.add "Action", valid_603948
  var valid_603949 = query.getOrDefault("Version")
  valid_603949 = validateParameter(valid_603949, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603949 != nil:
    section.add "Version", valid_603949
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603950 = header.getOrDefault("X-Amz-Date")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Date", valid_603950
  var valid_603951 = header.getOrDefault("X-Amz-Security-Token")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "X-Amz-Security-Token", valid_603951
  var valid_603952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Content-Sha256", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-Algorithm")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Algorithm", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Signature")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Signature", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-SignedHeaders", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Credential")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Credential", valid_603956
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  section = newJObject()
  var valid_603957 = formData.getOrDefault("Filters")
  valid_603957 = validateParameter(valid_603957, JArray, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "Filters", valid_603957
  var valid_603958 = formData.getOrDefault("SourceType")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "SourceType", valid_603958
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603959: Call_PostDescribeEventCategories_603945; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_603959.validator(path, query, header, formData, body)
  let scheme = call_603959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603959.url(scheme.get, call_603959.host, call_603959.base,
                         call_603959.route, valid.getOrDefault("path"))
  result = hook(call_603959, url, valid)

proc call*(call_603960: Call_PostDescribeEventCategories_603945;
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
  var query_603961 = newJObject()
  var formData_603962 = newJObject()
  add(query_603961, "Action", newJString(Action))
  if Filters != nil:
    formData_603962.add "Filters", Filters
  add(query_603961, "Version", newJString(Version))
  add(formData_603962, "SourceType", newJString(SourceType))
  result = call_603960.call(nil, query_603961, nil, formData_603962, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_603945(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_603946, base: "/",
    url: url_PostDescribeEventCategories_603947,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_603928 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEventCategories_603930(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventCategories_603929(path: JsonNode; query: JsonNode;
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
  var valid_603931 = query.getOrDefault("SourceType")
  valid_603931 = validateParameter(valid_603931, JString, required = false,
                                 default = nil)
  if valid_603931 != nil:
    section.add "SourceType", valid_603931
  var valid_603932 = query.getOrDefault("Filters")
  valid_603932 = validateParameter(valid_603932, JArray, required = false,
                                 default = nil)
  if valid_603932 != nil:
    section.add "Filters", valid_603932
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603933 = query.getOrDefault("Action")
  valid_603933 = validateParameter(valid_603933, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_603933 != nil:
    section.add "Action", valid_603933
  var valid_603934 = query.getOrDefault("Version")
  valid_603934 = validateParameter(valid_603934, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603934 != nil:
    section.add "Version", valid_603934
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603935 = header.getOrDefault("X-Amz-Date")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-Date", valid_603935
  var valid_603936 = header.getOrDefault("X-Amz-Security-Token")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "X-Amz-Security-Token", valid_603936
  var valid_603937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Content-Sha256", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-Algorithm")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-Algorithm", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-Signature")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Signature", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-SignedHeaders", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Credential")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Credential", valid_603941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603942: Call_GetDescribeEventCategories_603928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_603942.validator(path, query, header, formData, body)
  let scheme = call_603942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603942.url(scheme.get, call_603942.host, call_603942.base,
                         call_603942.route, valid.getOrDefault("path"))
  result = hook(call_603942, url, valid)

proc call*(call_603943: Call_GetDescribeEventCategories_603928;
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
  var query_603944 = newJObject()
  add(query_603944, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_603944.add "Filters", Filters
  add(query_603944, "Action", newJString(Action))
  add(query_603944, "Version", newJString(Version))
  result = call_603943.call(nil, query_603944, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_603928(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_603929, base: "/",
    url: url_GetDescribeEventCategories_603930,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_603987 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEvents_603989(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_603988(path: JsonNode; query: JsonNode;
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
  var valid_603990 = query.getOrDefault("Action")
  valid_603990 = validateParameter(valid_603990, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_603990 != nil:
    section.add "Action", valid_603990
  var valid_603991 = query.getOrDefault("Version")
  valid_603991 = validateParameter(valid_603991, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603991 != nil:
    section.add "Version", valid_603991
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603992 = header.getOrDefault("X-Amz-Date")
  valid_603992 = validateParameter(valid_603992, JString, required = false,
                                 default = nil)
  if valid_603992 != nil:
    section.add "X-Amz-Date", valid_603992
  var valid_603993 = header.getOrDefault("X-Amz-Security-Token")
  valid_603993 = validateParameter(valid_603993, JString, required = false,
                                 default = nil)
  if valid_603993 != nil:
    section.add "X-Amz-Security-Token", valid_603993
  var valid_603994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603994 = validateParameter(valid_603994, JString, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "X-Amz-Content-Sha256", valid_603994
  var valid_603995 = header.getOrDefault("X-Amz-Algorithm")
  valid_603995 = validateParameter(valid_603995, JString, required = false,
                                 default = nil)
  if valid_603995 != nil:
    section.add "X-Amz-Algorithm", valid_603995
  var valid_603996 = header.getOrDefault("X-Amz-Signature")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "X-Amz-Signature", valid_603996
  var valid_603997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "X-Amz-SignedHeaders", valid_603997
  var valid_603998 = header.getOrDefault("X-Amz-Credential")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "X-Amz-Credential", valid_603998
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
  var valid_603999 = formData.getOrDefault("SourceIdentifier")
  valid_603999 = validateParameter(valid_603999, JString, required = false,
                                 default = nil)
  if valid_603999 != nil:
    section.add "SourceIdentifier", valid_603999
  var valid_604000 = formData.getOrDefault("EventCategories")
  valid_604000 = validateParameter(valid_604000, JArray, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "EventCategories", valid_604000
  var valid_604001 = formData.getOrDefault("Marker")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "Marker", valid_604001
  var valid_604002 = formData.getOrDefault("StartTime")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "StartTime", valid_604002
  var valid_604003 = formData.getOrDefault("Duration")
  valid_604003 = validateParameter(valid_604003, JInt, required = false, default = nil)
  if valid_604003 != nil:
    section.add "Duration", valid_604003
  var valid_604004 = formData.getOrDefault("Filters")
  valid_604004 = validateParameter(valid_604004, JArray, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "Filters", valid_604004
  var valid_604005 = formData.getOrDefault("EndTime")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "EndTime", valid_604005
  var valid_604006 = formData.getOrDefault("MaxRecords")
  valid_604006 = validateParameter(valid_604006, JInt, required = false, default = nil)
  if valid_604006 != nil:
    section.add "MaxRecords", valid_604006
  var valid_604007 = formData.getOrDefault("SourceType")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604007 != nil:
    section.add "SourceType", valid_604007
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604008: Call_PostDescribeEvents_603987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_604008.validator(path, query, header, formData, body)
  let scheme = call_604008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604008.url(scheme.get, call_604008.host, call_604008.base,
                         call_604008.route, valid.getOrDefault("path"))
  result = hook(call_604008, url, valid)

proc call*(call_604009: Call_PostDescribeEvents_603987;
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
  var query_604010 = newJObject()
  var formData_604011 = newJObject()
  add(formData_604011, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_604011.add "EventCategories", EventCategories
  add(formData_604011, "Marker", newJString(Marker))
  add(formData_604011, "StartTime", newJString(StartTime))
  add(query_604010, "Action", newJString(Action))
  add(formData_604011, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_604011.add "Filters", Filters
  add(formData_604011, "EndTime", newJString(EndTime))
  add(formData_604011, "MaxRecords", newJInt(MaxRecords))
  add(query_604010, "Version", newJString(Version))
  add(formData_604011, "SourceType", newJString(SourceType))
  result = call_604009.call(nil, query_604010, nil, formData_604011, nil)

var postDescribeEvents* = Call_PostDescribeEvents_603987(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_603988, base: "/",
    url: url_PostDescribeEvents_603989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_603963 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEvents_603965(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_603964(path: JsonNode; query: JsonNode;
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
  var valid_603966 = query.getOrDefault("SourceType")
  valid_603966 = validateParameter(valid_603966, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_603966 != nil:
    section.add "SourceType", valid_603966
  var valid_603967 = query.getOrDefault("MaxRecords")
  valid_603967 = validateParameter(valid_603967, JInt, required = false, default = nil)
  if valid_603967 != nil:
    section.add "MaxRecords", valid_603967
  var valid_603968 = query.getOrDefault("StartTime")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "StartTime", valid_603968
  var valid_603969 = query.getOrDefault("Filters")
  valid_603969 = validateParameter(valid_603969, JArray, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "Filters", valid_603969
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603970 = query.getOrDefault("Action")
  valid_603970 = validateParameter(valid_603970, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_603970 != nil:
    section.add "Action", valid_603970
  var valid_603971 = query.getOrDefault("SourceIdentifier")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "SourceIdentifier", valid_603971
  var valid_603972 = query.getOrDefault("Marker")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "Marker", valid_603972
  var valid_603973 = query.getOrDefault("EventCategories")
  valid_603973 = validateParameter(valid_603973, JArray, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "EventCategories", valid_603973
  var valid_603974 = query.getOrDefault("Duration")
  valid_603974 = validateParameter(valid_603974, JInt, required = false, default = nil)
  if valid_603974 != nil:
    section.add "Duration", valid_603974
  var valid_603975 = query.getOrDefault("EndTime")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "EndTime", valid_603975
  var valid_603976 = query.getOrDefault("Version")
  valid_603976 = validateParameter(valid_603976, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603976 != nil:
    section.add "Version", valid_603976
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603977 = header.getOrDefault("X-Amz-Date")
  valid_603977 = validateParameter(valid_603977, JString, required = false,
                                 default = nil)
  if valid_603977 != nil:
    section.add "X-Amz-Date", valid_603977
  var valid_603978 = header.getOrDefault("X-Amz-Security-Token")
  valid_603978 = validateParameter(valid_603978, JString, required = false,
                                 default = nil)
  if valid_603978 != nil:
    section.add "X-Amz-Security-Token", valid_603978
  var valid_603979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603979 = validateParameter(valid_603979, JString, required = false,
                                 default = nil)
  if valid_603979 != nil:
    section.add "X-Amz-Content-Sha256", valid_603979
  var valid_603980 = header.getOrDefault("X-Amz-Algorithm")
  valid_603980 = validateParameter(valid_603980, JString, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "X-Amz-Algorithm", valid_603980
  var valid_603981 = header.getOrDefault("X-Amz-Signature")
  valid_603981 = validateParameter(valid_603981, JString, required = false,
                                 default = nil)
  if valid_603981 != nil:
    section.add "X-Amz-Signature", valid_603981
  var valid_603982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "X-Amz-SignedHeaders", valid_603982
  var valid_603983 = header.getOrDefault("X-Amz-Credential")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Credential", valid_603983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603984: Call_GetDescribeEvents_603963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_603984.validator(path, query, header, formData, body)
  let scheme = call_603984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603984.url(scheme.get, call_603984.host, call_603984.base,
                         call_603984.route, valid.getOrDefault("path"))
  result = hook(call_603984, url, valid)

proc call*(call_603985: Call_GetDescribeEvents_603963;
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
  var query_603986 = newJObject()
  add(query_603986, "SourceType", newJString(SourceType))
  add(query_603986, "MaxRecords", newJInt(MaxRecords))
  add(query_603986, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_603986.add "Filters", Filters
  add(query_603986, "Action", newJString(Action))
  add(query_603986, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_603986, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_603986.add "EventCategories", EventCategories
  add(query_603986, "Duration", newJInt(Duration))
  add(query_603986, "EndTime", newJString(EndTime))
  add(query_603986, "Version", newJString(Version))
  result = call_603985.call(nil, query_603986, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_603963(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_603964,
    base: "/", url: url_GetDescribeEvents_603965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_604035 = ref object of OpenApiRestCall_602417
proc url_PostDescribeOrderableDBInstanceOptions_604037(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOrderableDBInstanceOptions_604036(path: JsonNode;
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
  var valid_604038 = query.getOrDefault("Action")
  valid_604038 = validateParameter(valid_604038, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604038 != nil:
    section.add "Action", valid_604038
  var valid_604039 = query.getOrDefault("Version")
  valid_604039 = validateParameter(valid_604039, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604039 != nil:
    section.add "Version", valid_604039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604040 = header.getOrDefault("X-Amz-Date")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Date", valid_604040
  var valid_604041 = header.getOrDefault("X-Amz-Security-Token")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-Security-Token", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Content-Sha256", valid_604042
  var valid_604043 = header.getOrDefault("X-Amz-Algorithm")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-Algorithm", valid_604043
  var valid_604044 = header.getOrDefault("X-Amz-Signature")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "X-Amz-Signature", valid_604044
  var valid_604045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-SignedHeaders", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-Credential")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-Credential", valid_604046
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
  var valid_604047 = formData.getOrDefault("Engine")
  valid_604047 = validateParameter(valid_604047, JString, required = true,
                                 default = nil)
  if valid_604047 != nil:
    section.add "Engine", valid_604047
  var valid_604048 = formData.getOrDefault("Marker")
  valid_604048 = validateParameter(valid_604048, JString, required = false,
                                 default = nil)
  if valid_604048 != nil:
    section.add "Marker", valid_604048
  var valid_604049 = formData.getOrDefault("Vpc")
  valid_604049 = validateParameter(valid_604049, JBool, required = false, default = nil)
  if valid_604049 != nil:
    section.add "Vpc", valid_604049
  var valid_604050 = formData.getOrDefault("DBInstanceClass")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "DBInstanceClass", valid_604050
  var valid_604051 = formData.getOrDefault("Filters")
  valid_604051 = validateParameter(valid_604051, JArray, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "Filters", valid_604051
  var valid_604052 = formData.getOrDefault("LicenseModel")
  valid_604052 = validateParameter(valid_604052, JString, required = false,
                                 default = nil)
  if valid_604052 != nil:
    section.add "LicenseModel", valid_604052
  var valid_604053 = formData.getOrDefault("MaxRecords")
  valid_604053 = validateParameter(valid_604053, JInt, required = false, default = nil)
  if valid_604053 != nil:
    section.add "MaxRecords", valid_604053
  var valid_604054 = formData.getOrDefault("EngineVersion")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "EngineVersion", valid_604054
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604055: Call_PostDescribeOrderableDBInstanceOptions_604035;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_604055.validator(path, query, header, formData, body)
  let scheme = call_604055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604055.url(scheme.get, call_604055.host, call_604055.base,
                         call_604055.route, valid.getOrDefault("path"))
  result = hook(call_604055, url, valid)

proc call*(call_604056: Call_PostDescribeOrderableDBInstanceOptions_604035;
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
  var query_604057 = newJObject()
  var formData_604058 = newJObject()
  add(formData_604058, "Engine", newJString(Engine))
  add(formData_604058, "Marker", newJString(Marker))
  add(query_604057, "Action", newJString(Action))
  add(formData_604058, "Vpc", newJBool(Vpc))
  add(formData_604058, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_604058.add "Filters", Filters
  add(formData_604058, "LicenseModel", newJString(LicenseModel))
  add(formData_604058, "MaxRecords", newJInt(MaxRecords))
  add(formData_604058, "EngineVersion", newJString(EngineVersion))
  add(query_604057, "Version", newJString(Version))
  result = call_604056.call(nil, query_604057, nil, formData_604058, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_604035(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_604036, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_604037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_604012 = ref object of OpenApiRestCall_602417
proc url_GetDescribeOrderableDBInstanceOptions_604014(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOrderableDBInstanceOptions_604013(path: JsonNode;
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
  var valid_604015 = query.getOrDefault("Engine")
  valid_604015 = validateParameter(valid_604015, JString, required = true,
                                 default = nil)
  if valid_604015 != nil:
    section.add "Engine", valid_604015
  var valid_604016 = query.getOrDefault("MaxRecords")
  valid_604016 = validateParameter(valid_604016, JInt, required = false, default = nil)
  if valid_604016 != nil:
    section.add "MaxRecords", valid_604016
  var valid_604017 = query.getOrDefault("Filters")
  valid_604017 = validateParameter(valid_604017, JArray, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "Filters", valid_604017
  var valid_604018 = query.getOrDefault("LicenseModel")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "LicenseModel", valid_604018
  var valid_604019 = query.getOrDefault("Vpc")
  valid_604019 = validateParameter(valid_604019, JBool, required = false, default = nil)
  if valid_604019 != nil:
    section.add "Vpc", valid_604019
  var valid_604020 = query.getOrDefault("DBInstanceClass")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "DBInstanceClass", valid_604020
  var valid_604021 = query.getOrDefault("Action")
  valid_604021 = validateParameter(valid_604021, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604021 != nil:
    section.add "Action", valid_604021
  var valid_604022 = query.getOrDefault("Marker")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "Marker", valid_604022
  var valid_604023 = query.getOrDefault("EngineVersion")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "EngineVersion", valid_604023
  var valid_604024 = query.getOrDefault("Version")
  valid_604024 = validateParameter(valid_604024, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604024 != nil:
    section.add "Version", valid_604024
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604025 = header.getOrDefault("X-Amz-Date")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-Date", valid_604025
  var valid_604026 = header.getOrDefault("X-Amz-Security-Token")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "X-Amz-Security-Token", valid_604026
  var valid_604027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "X-Amz-Content-Sha256", valid_604027
  var valid_604028 = header.getOrDefault("X-Amz-Algorithm")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "X-Amz-Algorithm", valid_604028
  var valid_604029 = header.getOrDefault("X-Amz-Signature")
  valid_604029 = validateParameter(valid_604029, JString, required = false,
                                 default = nil)
  if valid_604029 != nil:
    section.add "X-Amz-Signature", valid_604029
  var valid_604030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-SignedHeaders", valid_604030
  var valid_604031 = header.getOrDefault("X-Amz-Credential")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Credential", valid_604031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604032: Call_GetDescribeOrderableDBInstanceOptions_604012;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_604032.validator(path, query, header, formData, body)
  let scheme = call_604032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604032.url(scheme.get, call_604032.host, call_604032.base,
                         call_604032.route, valid.getOrDefault("path"))
  result = hook(call_604032, url, valid)

proc call*(call_604033: Call_GetDescribeOrderableDBInstanceOptions_604012;
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
  var query_604034 = newJObject()
  add(query_604034, "Engine", newJString(Engine))
  add(query_604034, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604034.add "Filters", Filters
  add(query_604034, "LicenseModel", newJString(LicenseModel))
  add(query_604034, "Vpc", newJBool(Vpc))
  add(query_604034, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604034, "Action", newJString(Action))
  add(query_604034, "Marker", newJString(Marker))
  add(query_604034, "EngineVersion", newJString(EngineVersion))
  add(query_604034, "Version", newJString(Version))
  result = call_604033.call(nil, query_604034, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_604012(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_604013, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_604014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePendingMaintenanceActions_604078 = ref object of OpenApiRestCall_602417
proc url_PostDescribePendingMaintenanceActions_604080(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribePendingMaintenanceActions_604079(path: JsonNode;
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
  var valid_604081 = query.getOrDefault("Action")
  valid_604081 = validateParameter(valid_604081, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_604081 != nil:
    section.add "Action", valid_604081
  var valid_604082 = query.getOrDefault("Version")
  valid_604082 = validateParameter(valid_604082, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604082 != nil:
    section.add "Version", valid_604082
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604083 = header.getOrDefault("X-Amz-Date")
  valid_604083 = validateParameter(valid_604083, JString, required = false,
                                 default = nil)
  if valid_604083 != nil:
    section.add "X-Amz-Date", valid_604083
  var valid_604084 = header.getOrDefault("X-Amz-Security-Token")
  valid_604084 = validateParameter(valid_604084, JString, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "X-Amz-Security-Token", valid_604084
  var valid_604085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = nil)
  if valid_604085 != nil:
    section.add "X-Amz-Content-Sha256", valid_604085
  var valid_604086 = header.getOrDefault("X-Amz-Algorithm")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "X-Amz-Algorithm", valid_604086
  var valid_604087 = header.getOrDefault("X-Amz-Signature")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "X-Amz-Signature", valid_604087
  var valid_604088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "X-Amz-SignedHeaders", valid_604088
  var valid_604089 = header.getOrDefault("X-Amz-Credential")
  valid_604089 = validateParameter(valid_604089, JString, required = false,
                                 default = nil)
  if valid_604089 != nil:
    section.add "X-Amz-Credential", valid_604089
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
  var valid_604090 = formData.getOrDefault("Marker")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "Marker", valid_604090
  var valid_604091 = formData.getOrDefault("ResourceIdentifier")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "ResourceIdentifier", valid_604091
  var valid_604092 = formData.getOrDefault("Filters")
  valid_604092 = validateParameter(valid_604092, JArray, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "Filters", valid_604092
  var valid_604093 = formData.getOrDefault("MaxRecords")
  valid_604093 = validateParameter(valid_604093, JInt, required = false, default = nil)
  if valid_604093 != nil:
    section.add "MaxRecords", valid_604093
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604094: Call_PostDescribePendingMaintenanceActions_604078;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_604094.validator(path, query, header, formData, body)
  let scheme = call_604094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604094.url(scheme.get, call_604094.host, call_604094.base,
                         call_604094.route, valid.getOrDefault("path"))
  result = hook(call_604094, url, valid)

proc call*(call_604095: Call_PostDescribePendingMaintenanceActions_604078;
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
  var query_604096 = newJObject()
  var formData_604097 = newJObject()
  add(formData_604097, "Marker", newJString(Marker))
  add(query_604096, "Action", newJString(Action))
  add(formData_604097, "ResourceIdentifier", newJString(ResourceIdentifier))
  if Filters != nil:
    formData_604097.add "Filters", Filters
  add(formData_604097, "MaxRecords", newJInt(MaxRecords))
  add(query_604096, "Version", newJString(Version))
  result = call_604095.call(nil, query_604096, nil, formData_604097, nil)

var postDescribePendingMaintenanceActions* = Call_PostDescribePendingMaintenanceActions_604078(
    name: "postDescribePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_PostDescribePendingMaintenanceActions_604079, base: "/",
    url: url_PostDescribePendingMaintenanceActions_604080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePendingMaintenanceActions_604059 = ref object of OpenApiRestCall_602417
proc url_GetDescribePendingMaintenanceActions_604061(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribePendingMaintenanceActions_604060(path: JsonNode;
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
  var valid_604062 = query.getOrDefault("MaxRecords")
  valid_604062 = validateParameter(valid_604062, JInt, required = false, default = nil)
  if valid_604062 != nil:
    section.add "MaxRecords", valid_604062
  var valid_604063 = query.getOrDefault("Filters")
  valid_604063 = validateParameter(valid_604063, JArray, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "Filters", valid_604063
  var valid_604064 = query.getOrDefault("ResourceIdentifier")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "ResourceIdentifier", valid_604064
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604065 = query.getOrDefault("Action")
  valid_604065 = validateParameter(valid_604065, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_604065 != nil:
    section.add "Action", valid_604065
  var valid_604066 = query.getOrDefault("Marker")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "Marker", valid_604066
  var valid_604067 = query.getOrDefault("Version")
  valid_604067 = validateParameter(valid_604067, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604067 != nil:
    section.add "Version", valid_604067
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604068 = header.getOrDefault("X-Amz-Date")
  valid_604068 = validateParameter(valid_604068, JString, required = false,
                                 default = nil)
  if valid_604068 != nil:
    section.add "X-Amz-Date", valid_604068
  var valid_604069 = header.getOrDefault("X-Amz-Security-Token")
  valid_604069 = validateParameter(valid_604069, JString, required = false,
                                 default = nil)
  if valid_604069 != nil:
    section.add "X-Amz-Security-Token", valid_604069
  var valid_604070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "X-Amz-Content-Sha256", valid_604070
  var valid_604071 = header.getOrDefault("X-Amz-Algorithm")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = nil)
  if valid_604071 != nil:
    section.add "X-Amz-Algorithm", valid_604071
  var valid_604072 = header.getOrDefault("X-Amz-Signature")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-Signature", valid_604072
  var valid_604073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-SignedHeaders", valid_604073
  var valid_604074 = header.getOrDefault("X-Amz-Credential")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "X-Amz-Credential", valid_604074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604075: Call_GetDescribePendingMaintenanceActions_604059;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_604075.validator(path, query, header, formData, body)
  let scheme = call_604075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604075.url(scheme.get, call_604075.host, call_604075.base,
                         call_604075.route, valid.getOrDefault("path"))
  result = hook(call_604075, url, valid)

proc call*(call_604076: Call_GetDescribePendingMaintenanceActions_604059;
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
  var query_604077 = newJObject()
  add(query_604077, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604077.add "Filters", Filters
  add(query_604077, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_604077, "Action", newJString(Action))
  add(query_604077, "Marker", newJString(Marker))
  add(query_604077, "Version", newJString(Version))
  result = call_604076.call(nil, query_604077, nil, nil, nil)

var getDescribePendingMaintenanceActions* = Call_GetDescribePendingMaintenanceActions_604059(
    name: "getDescribePendingMaintenanceActions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_GetDescribePendingMaintenanceActions_604060, base: "/",
    url: url_GetDescribePendingMaintenanceActions_604061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostFailoverDBCluster_604115 = ref object of OpenApiRestCall_602417
proc url_PostFailoverDBCluster_604117(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostFailoverDBCluster_604116(path: JsonNode; query: JsonNode;
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
  var valid_604118 = query.getOrDefault("Action")
  valid_604118 = validateParameter(valid_604118, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_604118 != nil:
    section.add "Action", valid_604118
  var valid_604119 = query.getOrDefault("Version")
  valid_604119 = validateParameter(valid_604119, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604119 != nil:
    section.add "Version", valid_604119
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604120 = header.getOrDefault("X-Amz-Date")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "X-Amz-Date", valid_604120
  var valid_604121 = header.getOrDefault("X-Amz-Security-Token")
  valid_604121 = validateParameter(valid_604121, JString, required = false,
                                 default = nil)
  if valid_604121 != nil:
    section.add "X-Amz-Security-Token", valid_604121
  var valid_604122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604122 = validateParameter(valid_604122, JString, required = false,
                                 default = nil)
  if valid_604122 != nil:
    section.add "X-Amz-Content-Sha256", valid_604122
  var valid_604123 = header.getOrDefault("X-Amz-Algorithm")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "X-Amz-Algorithm", valid_604123
  var valid_604124 = header.getOrDefault("X-Amz-Signature")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "X-Amz-Signature", valid_604124
  var valid_604125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "X-Amz-SignedHeaders", valid_604125
  var valid_604126 = header.getOrDefault("X-Amz-Credential")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-Credential", valid_604126
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_604127 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "TargetDBInstanceIdentifier", valid_604127
  var valid_604128 = formData.getOrDefault("DBClusterIdentifier")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "DBClusterIdentifier", valid_604128
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604129: Call_PostFailoverDBCluster_604115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_604129.validator(path, query, header, formData, body)
  let scheme = call_604129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604129.url(scheme.get, call_604129.host, call_604129.base,
                         call_604129.route, valid.getOrDefault("path"))
  result = hook(call_604129, url, valid)

proc call*(call_604130: Call_PostFailoverDBCluster_604115;
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
  var query_604131 = newJObject()
  var formData_604132 = newJObject()
  add(query_604131, "Action", newJString(Action))
  add(formData_604132, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_604132, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604131, "Version", newJString(Version))
  result = call_604130.call(nil, query_604131, nil, formData_604132, nil)

var postFailoverDBCluster* = Call_PostFailoverDBCluster_604115(
    name: "postFailoverDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_PostFailoverDBCluster_604116, base: "/",
    url: url_PostFailoverDBCluster_604117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFailoverDBCluster_604098 = ref object of OpenApiRestCall_602417
proc url_GetFailoverDBCluster_604100(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetFailoverDBCluster_604099(path: JsonNode; query: JsonNode;
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
  var valid_604101 = query.getOrDefault("DBClusterIdentifier")
  valid_604101 = validateParameter(valid_604101, JString, required = false,
                                 default = nil)
  if valid_604101 != nil:
    section.add "DBClusterIdentifier", valid_604101
  var valid_604102 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_604102 = validateParameter(valid_604102, JString, required = false,
                                 default = nil)
  if valid_604102 != nil:
    section.add "TargetDBInstanceIdentifier", valid_604102
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604103 = query.getOrDefault("Action")
  valid_604103 = validateParameter(valid_604103, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_604103 != nil:
    section.add "Action", valid_604103
  var valid_604104 = query.getOrDefault("Version")
  valid_604104 = validateParameter(valid_604104, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604104 != nil:
    section.add "Version", valid_604104
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604105 = header.getOrDefault("X-Amz-Date")
  valid_604105 = validateParameter(valid_604105, JString, required = false,
                                 default = nil)
  if valid_604105 != nil:
    section.add "X-Amz-Date", valid_604105
  var valid_604106 = header.getOrDefault("X-Amz-Security-Token")
  valid_604106 = validateParameter(valid_604106, JString, required = false,
                                 default = nil)
  if valid_604106 != nil:
    section.add "X-Amz-Security-Token", valid_604106
  var valid_604107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604107 = validateParameter(valid_604107, JString, required = false,
                                 default = nil)
  if valid_604107 != nil:
    section.add "X-Amz-Content-Sha256", valid_604107
  var valid_604108 = header.getOrDefault("X-Amz-Algorithm")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "X-Amz-Algorithm", valid_604108
  var valid_604109 = header.getOrDefault("X-Amz-Signature")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Signature", valid_604109
  var valid_604110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-SignedHeaders", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-Credential")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Credential", valid_604111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604112: Call_GetFailoverDBCluster_604098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_604112.validator(path, query, header, formData, body)
  let scheme = call_604112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604112.url(scheme.get, call_604112.host, call_604112.base,
                         call_604112.route, valid.getOrDefault("path"))
  result = hook(call_604112, url, valid)

proc call*(call_604113: Call_GetFailoverDBCluster_604098;
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
  var query_604114 = newJObject()
  add(query_604114, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604114, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_604114, "Action", newJString(Action))
  add(query_604114, "Version", newJString(Version))
  result = call_604113.call(nil, query_604114, nil, nil, nil)

var getFailoverDBCluster* = Call_GetFailoverDBCluster_604098(
    name: "getFailoverDBCluster", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_GetFailoverDBCluster_604099, base: "/",
    url: url_GetFailoverDBCluster_604100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_604150 = ref object of OpenApiRestCall_602417
proc url_PostListTagsForResource_604152(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_604151(path: JsonNode; query: JsonNode;
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
  var valid_604153 = query.getOrDefault("Action")
  valid_604153 = validateParameter(valid_604153, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604153 != nil:
    section.add "Action", valid_604153
  var valid_604154 = query.getOrDefault("Version")
  valid_604154 = validateParameter(valid_604154, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604154 != nil:
    section.add "Version", valid_604154
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604155 = header.getOrDefault("X-Amz-Date")
  valid_604155 = validateParameter(valid_604155, JString, required = false,
                                 default = nil)
  if valid_604155 != nil:
    section.add "X-Amz-Date", valid_604155
  var valid_604156 = header.getOrDefault("X-Amz-Security-Token")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "X-Amz-Security-Token", valid_604156
  var valid_604157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "X-Amz-Content-Sha256", valid_604157
  var valid_604158 = header.getOrDefault("X-Amz-Algorithm")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "X-Amz-Algorithm", valid_604158
  var valid_604159 = header.getOrDefault("X-Amz-Signature")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Signature", valid_604159
  var valid_604160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "X-Amz-SignedHeaders", valid_604160
  var valid_604161 = header.getOrDefault("X-Amz-Credential")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "X-Amz-Credential", valid_604161
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  var valid_604162 = formData.getOrDefault("Filters")
  valid_604162 = validateParameter(valid_604162, JArray, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "Filters", valid_604162
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_604163 = formData.getOrDefault("ResourceName")
  valid_604163 = validateParameter(valid_604163, JString, required = true,
                                 default = nil)
  if valid_604163 != nil:
    section.add "ResourceName", valid_604163
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604164: Call_PostListTagsForResource_604150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_604164.validator(path, query, header, formData, body)
  let scheme = call_604164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604164.url(scheme.get, call_604164.host, call_604164.base,
                         call_604164.route, valid.getOrDefault("path"))
  result = hook(call_604164, url, valid)

proc call*(call_604165: Call_PostListTagsForResource_604150; ResourceName: string;
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
  var query_604166 = newJObject()
  var formData_604167 = newJObject()
  add(query_604166, "Action", newJString(Action))
  if Filters != nil:
    formData_604167.add "Filters", Filters
  add(formData_604167, "ResourceName", newJString(ResourceName))
  add(query_604166, "Version", newJString(Version))
  result = call_604165.call(nil, query_604166, nil, formData_604167, nil)

var postListTagsForResource* = Call_PostListTagsForResource_604150(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_604151, base: "/",
    url: url_PostListTagsForResource_604152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_604133 = ref object of OpenApiRestCall_602417
proc url_GetListTagsForResource_604135(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_604134(path: JsonNode; query: JsonNode;
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
  var valid_604136 = query.getOrDefault("Filters")
  valid_604136 = validateParameter(valid_604136, JArray, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "Filters", valid_604136
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_604137 = query.getOrDefault("ResourceName")
  valid_604137 = validateParameter(valid_604137, JString, required = true,
                                 default = nil)
  if valid_604137 != nil:
    section.add "ResourceName", valid_604137
  var valid_604138 = query.getOrDefault("Action")
  valid_604138 = validateParameter(valid_604138, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604138 != nil:
    section.add "Action", valid_604138
  var valid_604139 = query.getOrDefault("Version")
  valid_604139 = validateParameter(valid_604139, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604139 != nil:
    section.add "Version", valid_604139
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604140 = header.getOrDefault("X-Amz-Date")
  valid_604140 = validateParameter(valid_604140, JString, required = false,
                                 default = nil)
  if valid_604140 != nil:
    section.add "X-Amz-Date", valid_604140
  var valid_604141 = header.getOrDefault("X-Amz-Security-Token")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "X-Amz-Security-Token", valid_604141
  var valid_604142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "X-Amz-Content-Sha256", valid_604142
  var valid_604143 = header.getOrDefault("X-Amz-Algorithm")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "X-Amz-Algorithm", valid_604143
  var valid_604144 = header.getOrDefault("X-Amz-Signature")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Signature", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-SignedHeaders", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-Credential")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-Credential", valid_604146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604147: Call_GetListTagsForResource_604133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_604147.validator(path, query, header, formData, body)
  let scheme = call_604147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604147.url(scheme.get, call_604147.host, call_604147.base,
                         call_604147.route, valid.getOrDefault("path"))
  result = hook(call_604147, url, valid)

proc call*(call_604148: Call_GetListTagsForResource_604133; ResourceName: string;
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
  var query_604149 = newJObject()
  if Filters != nil:
    query_604149.add "Filters", Filters
  add(query_604149, "ResourceName", newJString(ResourceName))
  add(query_604149, "Action", newJString(Action))
  add(query_604149, "Version", newJString(Version))
  result = call_604148.call(nil, query_604149, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_604133(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_604134, base: "/",
    url: url_GetListTagsForResource_604135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBCluster_604197 = ref object of OpenApiRestCall_602417
proc url_PostModifyDBCluster_604199(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBCluster_604198(path: JsonNode; query: JsonNode;
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
  var valid_604200 = query.getOrDefault("Action")
  valid_604200 = validateParameter(valid_604200, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_604200 != nil:
    section.add "Action", valid_604200
  var valid_604201 = query.getOrDefault("Version")
  valid_604201 = validateParameter(valid_604201, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604201 != nil:
    section.add "Version", valid_604201
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604202 = header.getOrDefault("X-Amz-Date")
  valid_604202 = validateParameter(valid_604202, JString, required = false,
                                 default = nil)
  if valid_604202 != nil:
    section.add "X-Amz-Date", valid_604202
  var valid_604203 = header.getOrDefault("X-Amz-Security-Token")
  valid_604203 = validateParameter(valid_604203, JString, required = false,
                                 default = nil)
  if valid_604203 != nil:
    section.add "X-Amz-Security-Token", valid_604203
  var valid_604204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604204 = validateParameter(valid_604204, JString, required = false,
                                 default = nil)
  if valid_604204 != nil:
    section.add "X-Amz-Content-Sha256", valid_604204
  var valid_604205 = header.getOrDefault("X-Amz-Algorithm")
  valid_604205 = validateParameter(valid_604205, JString, required = false,
                                 default = nil)
  if valid_604205 != nil:
    section.add "X-Amz-Algorithm", valid_604205
  var valid_604206 = header.getOrDefault("X-Amz-Signature")
  valid_604206 = validateParameter(valid_604206, JString, required = false,
                                 default = nil)
  if valid_604206 != nil:
    section.add "X-Amz-Signature", valid_604206
  var valid_604207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604207 = validateParameter(valid_604207, JString, required = false,
                                 default = nil)
  if valid_604207 != nil:
    section.add "X-Amz-SignedHeaders", valid_604207
  var valid_604208 = header.getOrDefault("X-Amz-Credential")
  valid_604208 = validateParameter(valid_604208, JString, required = false,
                                 default = nil)
  if valid_604208 != nil:
    section.add "X-Amz-Credential", valid_604208
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
  var valid_604209 = formData.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_604209 = validateParameter(valid_604209, JArray, required = false,
                                 default = nil)
  if valid_604209 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_604209
  var valid_604210 = formData.getOrDefault("ApplyImmediately")
  valid_604210 = validateParameter(valid_604210, JBool, required = false, default = nil)
  if valid_604210 != nil:
    section.add "ApplyImmediately", valid_604210
  var valid_604211 = formData.getOrDefault("Port")
  valid_604211 = validateParameter(valid_604211, JInt, required = false, default = nil)
  if valid_604211 != nil:
    section.add "Port", valid_604211
  var valid_604212 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_604212 = validateParameter(valid_604212, JArray, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "VpcSecurityGroupIds", valid_604212
  var valid_604213 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604213 = validateParameter(valid_604213, JInt, required = false, default = nil)
  if valid_604213 != nil:
    section.add "BackupRetentionPeriod", valid_604213
  var valid_604214 = formData.getOrDefault("MasterUserPassword")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "MasterUserPassword", valid_604214
  var valid_604215 = formData.getOrDefault("DeletionProtection")
  valid_604215 = validateParameter(valid_604215, JBool, required = false, default = nil)
  if valid_604215 != nil:
    section.add "DeletionProtection", valid_604215
  var valid_604216 = formData.getOrDefault("NewDBClusterIdentifier")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "NewDBClusterIdentifier", valid_604216
  var valid_604217 = formData.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_604217 = validateParameter(valid_604217, JArray, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_604217
  var valid_604218 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_604218 = validateParameter(valid_604218, JString, required = false,
                                 default = nil)
  if valid_604218 != nil:
    section.add "DBClusterParameterGroupName", valid_604218
  var valid_604219 = formData.getOrDefault("PreferredBackupWindow")
  valid_604219 = validateParameter(valid_604219, JString, required = false,
                                 default = nil)
  if valid_604219 != nil:
    section.add "PreferredBackupWindow", valid_604219
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_604220 = formData.getOrDefault("DBClusterIdentifier")
  valid_604220 = validateParameter(valid_604220, JString, required = true,
                                 default = nil)
  if valid_604220 != nil:
    section.add "DBClusterIdentifier", valid_604220
  var valid_604221 = formData.getOrDefault("EngineVersion")
  valid_604221 = validateParameter(valid_604221, JString, required = false,
                                 default = nil)
  if valid_604221 != nil:
    section.add "EngineVersion", valid_604221
  var valid_604222 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_604222 = validateParameter(valid_604222, JString, required = false,
                                 default = nil)
  if valid_604222 != nil:
    section.add "PreferredMaintenanceWindow", valid_604222
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604223: Call_PostModifyDBCluster_604197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_604223.validator(path, query, header, formData, body)
  let scheme = call_604223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604223.url(scheme.get, call_604223.host, call_604223.base,
                         call_604223.route, valid.getOrDefault("path"))
  result = hook(call_604223, url, valid)

proc call*(call_604224: Call_PostModifyDBCluster_604197;
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
  var query_604225 = newJObject()
  var formData_604226 = newJObject()
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    formData_604226.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                       CloudwatchLogsExportConfigurationEnableLogTypes
  add(formData_604226, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_604226, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_604226.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_604226, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_604226, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_604226, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_604226, "NewDBClusterIdentifier",
      newJString(NewDBClusterIdentifier))
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    formData_604226.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                       CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_604225, "Action", newJString(Action))
  add(formData_604226, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_604226, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_604226, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_604226, "EngineVersion", newJString(EngineVersion))
  add(query_604225, "Version", newJString(Version))
  add(formData_604226, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_604224.call(nil, query_604225, nil, formData_604226, nil)

var postModifyDBCluster* = Call_PostModifyDBCluster_604197(
    name: "postModifyDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBCluster",
    validator: validate_PostModifyDBCluster_604198, base: "/",
    url: url_PostModifyDBCluster_604199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBCluster_604168 = ref object of OpenApiRestCall_602417
proc url_GetModifyDBCluster_604170(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBCluster_604169(path: JsonNode; query: JsonNode;
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
  var valid_604171 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_604171 = validateParameter(valid_604171, JString, required = false,
                                 default = nil)
  if valid_604171 != nil:
    section.add "PreferredMaintenanceWindow", valid_604171
  var valid_604172 = query.getOrDefault("DBClusterParameterGroupName")
  valid_604172 = validateParameter(valid_604172, JString, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "DBClusterParameterGroupName", valid_604172
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_604173 = query.getOrDefault("DBClusterIdentifier")
  valid_604173 = validateParameter(valid_604173, JString, required = true,
                                 default = nil)
  if valid_604173 != nil:
    section.add "DBClusterIdentifier", valid_604173
  var valid_604174 = query.getOrDefault("MasterUserPassword")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "MasterUserPassword", valid_604174
  var valid_604175 = query.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_604175 = validateParameter(valid_604175, JArray, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_604175
  var valid_604176 = query.getOrDefault("VpcSecurityGroupIds")
  valid_604176 = validateParameter(valid_604176, JArray, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "VpcSecurityGroupIds", valid_604176
  var valid_604177 = query.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_604177 = validateParameter(valid_604177, JArray, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_604177
  var valid_604178 = query.getOrDefault("BackupRetentionPeriod")
  valid_604178 = validateParameter(valid_604178, JInt, required = false, default = nil)
  if valid_604178 != nil:
    section.add "BackupRetentionPeriod", valid_604178
  var valid_604179 = query.getOrDefault("NewDBClusterIdentifier")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "NewDBClusterIdentifier", valid_604179
  var valid_604180 = query.getOrDefault("DeletionProtection")
  valid_604180 = validateParameter(valid_604180, JBool, required = false, default = nil)
  if valid_604180 != nil:
    section.add "DeletionProtection", valid_604180
  var valid_604181 = query.getOrDefault("Action")
  valid_604181 = validateParameter(valid_604181, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_604181 != nil:
    section.add "Action", valid_604181
  var valid_604182 = query.getOrDefault("EngineVersion")
  valid_604182 = validateParameter(valid_604182, JString, required = false,
                                 default = nil)
  if valid_604182 != nil:
    section.add "EngineVersion", valid_604182
  var valid_604183 = query.getOrDefault("Port")
  valid_604183 = validateParameter(valid_604183, JInt, required = false, default = nil)
  if valid_604183 != nil:
    section.add "Port", valid_604183
  var valid_604184 = query.getOrDefault("PreferredBackupWindow")
  valid_604184 = validateParameter(valid_604184, JString, required = false,
                                 default = nil)
  if valid_604184 != nil:
    section.add "PreferredBackupWindow", valid_604184
  var valid_604185 = query.getOrDefault("Version")
  valid_604185 = validateParameter(valid_604185, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604185 != nil:
    section.add "Version", valid_604185
  var valid_604186 = query.getOrDefault("ApplyImmediately")
  valid_604186 = validateParameter(valid_604186, JBool, required = false, default = nil)
  if valid_604186 != nil:
    section.add "ApplyImmediately", valid_604186
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604187 = header.getOrDefault("X-Amz-Date")
  valid_604187 = validateParameter(valid_604187, JString, required = false,
                                 default = nil)
  if valid_604187 != nil:
    section.add "X-Amz-Date", valid_604187
  var valid_604188 = header.getOrDefault("X-Amz-Security-Token")
  valid_604188 = validateParameter(valid_604188, JString, required = false,
                                 default = nil)
  if valid_604188 != nil:
    section.add "X-Amz-Security-Token", valid_604188
  var valid_604189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604189 = validateParameter(valid_604189, JString, required = false,
                                 default = nil)
  if valid_604189 != nil:
    section.add "X-Amz-Content-Sha256", valid_604189
  var valid_604190 = header.getOrDefault("X-Amz-Algorithm")
  valid_604190 = validateParameter(valid_604190, JString, required = false,
                                 default = nil)
  if valid_604190 != nil:
    section.add "X-Amz-Algorithm", valid_604190
  var valid_604191 = header.getOrDefault("X-Amz-Signature")
  valid_604191 = validateParameter(valid_604191, JString, required = false,
                                 default = nil)
  if valid_604191 != nil:
    section.add "X-Amz-Signature", valid_604191
  var valid_604192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-SignedHeaders", valid_604192
  var valid_604193 = header.getOrDefault("X-Amz-Credential")
  valid_604193 = validateParameter(valid_604193, JString, required = false,
                                 default = nil)
  if valid_604193 != nil:
    section.add "X-Amz-Credential", valid_604193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604194: Call_GetModifyDBCluster_604168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_604194.validator(path, query, header, formData, body)
  let scheme = call_604194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604194.url(scheme.get, call_604194.host, call_604194.base,
                         call_604194.route, valid.getOrDefault("path"))
  result = hook(call_604194, url, valid)

proc call*(call_604195: Call_GetModifyDBCluster_604168;
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
  var query_604196 = newJObject()
  add(query_604196, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_604196, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_604196, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604196, "MasterUserPassword", newJString(MasterUserPassword))
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    query_604196.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                    CloudwatchLogsExportConfigurationEnableLogTypes
  if VpcSecurityGroupIds != nil:
    query_604196.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    query_604196.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                    CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_604196, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604196, "NewDBClusterIdentifier", newJString(NewDBClusterIdentifier))
  add(query_604196, "DeletionProtection", newJBool(DeletionProtection))
  add(query_604196, "Action", newJString(Action))
  add(query_604196, "EngineVersion", newJString(EngineVersion))
  add(query_604196, "Port", newJInt(Port))
  add(query_604196, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604196, "Version", newJString(Version))
  add(query_604196, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_604195.call(nil, query_604196, nil, nil, nil)

var getModifyDBCluster* = Call_GetModifyDBCluster_604168(
    name: "getModifyDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=ModifyDBCluster", validator: validate_GetModifyDBCluster_604169,
    base: "/", url: url_GetModifyDBCluster_604170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterParameterGroup_604244 = ref object of OpenApiRestCall_602417
proc url_PostModifyDBClusterParameterGroup_604246(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBClusterParameterGroup_604245(path: JsonNode;
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
  var valid_604247 = query.getOrDefault("Action")
  valid_604247 = validateParameter(valid_604247, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_604247 != nil:
    section.add "Action", valid_604247
  var valid_604248 = query.getOrDefault("Version")
  valid_604248 = validateParameter(valid_604248, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604248 != nil:
    section.add "Version", valid_604248
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604249 = header.getOrDefault("X-Amz-Date")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-Date", valid_604249
  var valid_604250 = header.getOrDefault("X-Amz-Security-Token")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "X-Amz-Security-Token", valid_604250
  var valid_604251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "X-Amz-Content-Sha256", valid_604251
  var valid_604252 = header.getOrDefault("X-Amz-Algorithm")
  valid_604252 = validateParameter(valid_604252, JString, required = false,
                                 default = nil)
  if valid_604252 != nil:
    section.add "X-Amz-Algorithm", valid_604252
  var valid_604253 = header.getOrDefault("X-Amz-Signature")
  valid_604253 = validateParameter(valid_604253, JString, required = false,
                                 default = nil)
  if valid_604253 != nil:
    section.add "X-Amz-Signature", valid_604253
  var valid_604254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604254 = validateParameter(valid_604254, JString, required = false,
                                 default = nil)
  if valid_604254 != nil:
    section.add "X-Amz-SignedHeaders", valid_604254
  var valid_604255 = header.getOrDefault("X-Amz-Credential")
  valid_604255 = validateParameter(valid_604255, JString, required = false,
                                 default = nil)
  if valid_604255 != nil:
    section.add "X-Amz-Credential", valid_604255
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Parameters` field"
  var valid_604256 = formData.getOrDefault("Parameters")
  valid_604256 = validateParameter(valid_604256, JArray, required = true, default = nil)
  if valid_604256 != nil:
    section.add "Parameters", valid_604256
  var valid_604257 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_604257 = validateParameter(valid_604257, JString, required = true,
                                 default = nil)
  if valid_604257 != nil:
    section.add "DBClusterParameterGroupName", valid_604257
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604258: Call_PostModifyDBClusterParameterGroup_604244;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_604258.validator(path, query, header, formData, body)
  let scheme = call_604258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604258.url(scheme.get, call_604258.host, call_604258.base,
                         call_604258.route, valid.getOrDefault("path"))
  result = hook(call_604258, url, valid)

proc call*(call_604259: Call_PostModifyDBClusterParameterGroup_604244;
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
  var query_604260 = newJObject()
  var formData_604261 = newJObject()
  if Parameters != nil:
    formData_604261.add "Parameters", Parameters
  add(query_604260, "Action", newJString(Action))
  add(formData_604261, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_604260, "Version", newJString(Version))
  result = call_604259.call(nil, query_604260, nil, formData_604261, nil)

var postModifyDBClusterParameterGroup* = Call_PostModifyDBClusterParameterGroup_604244(
    name: "postModifyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_PostModifyDBClusterParameterGroup_604245, base: "/",
    url: url_PostModifyDBClusterParameterGroup_604246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterParameterGroup_604227 = ref object of OpenApiRestCall_602417
proc url_GetModifyDBClusterParameterGroup_604229(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBClusterParameterGroup_604228(path: JsonNode;
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
  var valid_604230 = query.getOrDefault("DBClusterParameterGroupName")
  valid_604230 = validateParameter(valid_604230, JString, required = true,
                                 default = nil)
  if valid_604230 != nil:
    section.add "DBClusterParameterGroupName", valid_604230
  var valid_604231 = query.getOrDefault("Parameters")
  valid_604231 = validateParameter(valid_604231, JArray, required = true, default = nil)
  if valid_604231 != nil:
    section.add "Parameters", valid_604231
  var valid_604232 = query.getOrDefault("Action")
  valid_604232 = validateParameter(valid_604232, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_604232 != nil:
    section.add "Action", valid_604232
  var valid_604233 = query.getOrDefault("Version")
  valid_604233 = validateParameter(valid_604233, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604233 != nil:
    section.add "Version", valid_604233
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604234 = header.getOrDefault("X-Amz-Date")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "X-Amz-Date", valid_604234
  var valid_604235 = header.getOrDefault("X-Amz-Security-Token")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "X-Amz-Security-Token", valid_604235
  var valid_604236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604236 = validateParameter(valid_604236, JString, required = false,
                                 default = nil)
  if valid_604236 != nil:
    section.add "X-Amz-Content-Sha256", valid_604236
  var valid_604237 = header.getOrDefault("X-Amz-Algorithm")
  valid_604237 = validateParameter(valid_604237, JString, required = false,
                                 default = nil)
  if valid_604237 != nil:
    section.add "X-Amz-Algorithm", valid_604237
  var valid_604238 = header.getOrDefault("X-Amz-Signature")
  valid_604238 = validateParameter(valid_604238, JString, required = false,
                                 default = nil)
  if valid_604238 != nil:
    section.add "X-Amz-Signature", valid_604238
  var valid_604239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604239 = validateParameter(valid_604239, JString, required = false,
                                 default = nil)
  if valid_604239 != nil:
    section.add "X-Amz-SignedHeaders", valid_604239
  var valid_604240 = header.getOrDefault("X-Amz-Credential")
  valid_604240 = validateParameter(valid_604240, JString, required = false,
                                 default = nil)
  if valid_604240 != nil:
    section.add "X-Amz-Credential", valid_604240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604241: Call_GetModifyDBClusterParameterGroup_604227;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_604241.validator(path, query, header, formData, body)
  let scheme = call_604241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604241.url(scheme.get, call_604241.host, call_604241.base,
                         call_604241.route, valid.getOrDefault("path"))
  result = hook(call_604241, url, valid)

proc call*(call_604242: Call_GetModifyDBClusterParameterGroup_604227;
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
  var query_604243 = newJObject()
  add(query_604243, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_604243.add "Parameters", Parameters
  add(query_604243, "Action", newJString(Action))
  add(query_604243, "Version", newJString(Version))
  result = call_604242.call(nil, query_604243, nil, nil, nil)

var getModifyDBClusterParameterGroup* = Call_GetModifyDBClusterParameterGroup_604227(
    name: "getModifyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_GetModifyDBClusterParameterGroup_604228, base: "/",
    url: url_GetModifyDBClusterParameterGroup_604229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterSnapshotAttribute_604281 = ref object of OpenApiRestCall_602417
proc url_PostModifyDBClusterSnapshotAttribute_604283(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBClusterSnapshotAttribute_604282(path: JsonNode;
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
  var valid_604284 = query.getOrDefault("Action")
  valid_604284 = validateParameter(valid_604284, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_604284 != nil:
    section.add "Action", valid_604284
  var valid_604285 = query.getOrDefault("Version")
  valid_604285 = validateParameter(valid_604285, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604285 != nil:
    section.add "Version", valid_604285
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604286 = header.getOrDefault("X-Amz-Date")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "X-Amz-Date", valid_604286
  var valid_604287 = header.getOrDefault("X-Amz-Security-Token")
  valid_604287 = validateParameter(valid_604287, JString, required = false,
                                 default = nil)
  if valid_604287 != nil:
    section.add "X-Amz-Security-Token", valid_604287
  var valid_604288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604288 = validateParameter(valid_604288, JString, required = false,
                                 default = nil)
  if valid_604288 != nil:
    section.add "X-Amz-Content-Sha256", valid_604288
  var valid_604289 = header.getOrDefault("X-Amz-Algorithm")
  valid_604289 = validateParameter(valid_604289, JString, required = false,
                                 default = nil)
  if valid_604289 != nil:
    section.add "X-Amz-Algorithm", valid_604289
  var valid_604290 = header.getOrDefault("X-Amz-Signature")
  valid_604290 = validateParameter(valid_604290, JString, required = false,
                                 default = nil)
  if valid_604290 != nil:
    section.add "X-Amz-Signature", valid_604290
  var valid_604291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604291 = validateParameter(valid_604291, JString, required = false,
                                 default = nil)
  if valid_604291 != nil:
    section.add "X-Amz-SignedHeaders", valid_604291
  var valid_604292 = header.getOrDefault("X-Amz-Credential")
  valid_604292 = validateParameter(valid_604292, JString, required = false,
                                 default = nil)
  if valid_604292 != nil:
    section.add "X-Amz-Credential", valid_604292
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
  var valid_604293 = formData.getOrDefault("AttributeName")
  valid_604293 = validateParameter(valid_604293, JString, required = true,
                                 default = nil)
  if valid_604293 != nil:
    section.add "AttributeName", valid_604293
  var valid_604294 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_604294 = validateParameter(valid_604294, JString, required = true,
                                 default = nil)
  if valid_604294 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_604294
  var valid_604295 = formData.getOrDefault("ValuesToRemove")
  valid_604295 = validateParameter(valid_604295, JArray, required = false,
                                 default = nil)
  if valid_604295 != nil:
    section.add "ValuesToRemove", valid_604295
  var valid_604296 = formData.getOrDefault("ValuesToAdd")
  valid_604296 = validateParameter(valid_604296, JArray, required = false,
                                 default = nil)
  if valid_604296 != nil:
    section.add "ValuesToAdd", valid_604296
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604297: Call_PostModifyDBClusterSnapshotAttribute_604281;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_604297.validator(path, query, header, formData, body)
  let scheme = call_604297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604297.url(scheme.get, call_604297.host, call_604297.base,
                         call_604297.route, valid.getOrDefault("path"))
  result = hook(call_604297, url, valid)

proc call*(call_604298: Call_PostModifyDBClusterSnapshotAttribute_604281;
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
  var query_604299 = newJObject()
  var formData_604300 = newJObject()
  add(formData_604300, "AttributeName", newJString(AttributeName))
  add(formData_604300, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_604299, "Action", newJString(Action))
  if ValuesToRemove != nil:
    formData_604300.add "ValuesToRemove", ValuesToRemove
  if ValuesToAdd != nil:
    formData_604300.add "ValuesToAdd", ValuesToAdd
  add(query_604299, "Version", newJString(Version))
  result = call_604298.call(nil, query_604299, nil, formData_604300, nil)

var postModifyDBClusterSnapshotAttribute* = Call_PostModifyDBClusterSnapshotAttribute_604281(
    name: "postModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_PostModifyDBClusterSnapshotAttribute_604282, base: "/",
    url: url_PostModifyDBClusterSnapshotAttribute_604283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterSnapshotAttribute_604262 = ref object of OpenApiRestCall_602417
proc url_GetModifyDBClusterSnapshotAttribute_604264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBClusterSnapshotAttribute_604263(path: JsonNode;
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
  var valid_604265 = query.getOrDefault("AttributeName")
  valid_604265 = validateParameter(valid_604265, JString, required = true,
                                 default = nil)
  if valid_604265 != nil:
    section.add "AttributeName", valid_604265
  var valid_604266 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_604266 = validateParameter(valid_604266, JString, required = true,
                                 default = nil)
  if valid_604266 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_604266
  var valid_604267 = query.getOrDefault("ValuesToAdd")
  valid_604267 = validateParameter(valid_604267, JArray, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "ValuesToAdd", valid_604267
  var valid_604268 = query.getOrDefault("Action")
  valid_604268 = validateParameter(valid_604268, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_604268 != nil:
    section.add "Action", valid_604268
  var valid_604269 = query.getOrDefault("ValuesToRemove")
  valid_604269 = validateParameter(valid_604269, JArray, required = false,
                                 default = nil)
  if valid_604269 != nil:
    section.add "ValuesToRemove", valid_604269
  var valid_604270 = query.getOrDefault("Version")
  valid_604270 = validateParameter(valid_604270, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604270 != nil:
    section.add "Version", valid_604270
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604271 = header.getOrDefault("X-Amz-Date")
  valid_604271 = validateParameter(valid_604271, JString, required = false,
                                 default = nil)
  if valid_604271 != nil:
    section.add "X-Amz-Date", valid_604271
  var valid_604272 = header.getOrDefault("X-Amz-Security-Token")
  valid_604272 = validateParameter(valid_604272, JString, required = false,
                                 default = nil)
  if valid_604272 != nil:
    section.add "X-Amz-Security-Token", valid_604272
  var valid_604273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604273 = validateParameter(valid_604273, JString, required = false,
                                 default = nil)
  if valid_604273 != nil:
    section.add "X-Amz-Content-Sha256", valid_604273
  var valid_604274 = header.getOrDefault("X-Amz-Algorithm")
  valid_604274 = validateParameter(valid_604274, JString, required = false,
                                 default = nil)
  if valid_604274 != nil:
    section.add "X-Amz-Algorithm", valid_604274
  var valid_604275 = header.getOrDefault("X-Amz-Signature")
  valid_604275 = validateParameter(valid_604275, JString, required = false,
                                 default = nil)
  if valid_604275 != nil:
    section.add "X-Amz-Signature", valid_604275
  var valid_604276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604276 = validateParameter(valid_604276, JString, required = false,
                                 default = nil)
  if valid_604276 != nil:
    section.add "X-Amz-SignedHeaders", valid_604276
  var valid_604277 = header.getOrDefault("X-Amz-Credential")
  valid_604277 = validateParameter(valid_604277, JString, required = false,
                                 default = nil)
  if valid_604277 != nil:
    section.add "X-Amz-Credential", valid_604277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604278: Call_GetModifyDBClusterSnapshotAttribute_604262;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_604278.validator(path, query, header, formData, body)
  let scheme = call_604278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604278.url(scheme.get, call_604278.host, call_604278.base,
                         call_604278.route, valid.getOrDefault("path"))
  result = hook(call_604278, url, valid)

proc call*(call_604279: Call_GetModifyDBClusterSnapshotAttribute_604262;
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
  var query_604280 = newJObject()
  add(query_604280, "AttributeName", newJString(AttributeName))
  add(query_604280, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if ValuesToAdd != nil:
    query_604280.add "ValuesToAdd", ValuesToAdd
  add(query_604280, "Action", newJString(Action))
  if ValuesToRemove != nil:
    query_604280.add "ValuesToRemove", ValuesToRemove
  add(query_604280, "Version", newJString(Version))
  result = call_604279.call(nil, query_604280, nil, nil, nil)

var getModifyDBClusterSnapshotAttribute* = Call_GetModifyDBClusterSnapshotAttribute_604262(
    name: "getModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_GetModifyDBClusterSnapshotAttribute_604263, base: "/",
    url: url_GetModifyDBClusterSnapshotAttribute_604264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_604323 = ref object of OpenApiRestCall_602417
proc url_PostModifyDBInstance_604325(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBInstance_604324(path: JsonNode; query: JsonNode;
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
  var valid_604326 = query.getOrDefault("Action")
  valid_604326 = validateParameter(valid_604326, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604326 != nil:
    section.add "Action", valid_604326
  var valid_604327 = query.getOrDefault("Version")
  valid_604327 = validateParameter(valid_604327, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604327 != nil:
    section.add "Version", valid_604327
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604328 = header.getOrDefault("X-Amz-Date")
  valid_604328 = validateParameter(valid_604328, JString, required = false,
                                 default = nil)
  if valid_604328 != nil:
    section.add "X-Amz-Date", valid_604328
  var valid_604329 = header.getOrDefault("X-Amz-Security-Token")
  valid_604329 = validateParameter(valid_604329, JString, required = false,
                                 default = nil)
  if valid_604329 != nil:
    section.add "X-Amz-Security-Token", valid_604329
  var valid_604330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604330 = validateParameter(valid_604330, JString, required = false,
                                 default = nil)
  if valid_604330 != nil:
    section.add "X-Amz-Content-Sha256", valid_604330
  var valid_604331 = header.getOrDefault("X-Amz-Algorithm")
  valid_604331 = validateParameter(valid_604331, JString, required = false,
                                 default = nil)
  if valid_604331 != nil:
    section.add "X-Amz-Algorithm", valid_604331
  var valid_604332 = header.getOrDefault("X-Amz-Signature")
  valid_604332 = validateParameter(valid_604332, JString, required = false,
                                 default = nil)
  if valid_604332 != nil:
    section.add "X-Amz-Signature", valid_604332
  var valid_604333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604333 = validateParameter(valid_604333, JString, required = false,
                                 default = nil)
  if valid_604333 != nil:
    section.add "X-Amz-SignedHeaders", valid_604333
  var valid_604334 = header.getOrDefault("X-Amz-Credential")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "X-Amz-Credential", valid_604334
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
  var valid_604335 = formData.getOrDefault("ApplyImmediately")
  valid_604335 = validateParameter(valid_604335, JBool, required = false, default = nil)
  if valid_604335 != nil:
    section.add "ApplyImmediately", valid_604335
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604336 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604336 = validateParameter(valid_604336, JString, required = true,
                                 default = nil)
  if valid_604336 != nil:
    section.add "DBInstanceIdentifier", valid_604336
  var valid_604337 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_604337 = validateParameter(valid_604337, JString, required = false,
                                 default = nil)
  if valid_604337 != nil:
    section.add "NewDBInstanceIdentifier", valid_604337
  var valid_604338 = formData.getOrDefault("PromotionTier")
  valid_604338 = validateParameter(valid_604338, JInt, required = false, default = nil)
  if valid_604338 != nil:
    section.add "PromotionTier", valid_604338
  var valid_604339 = formData.getOrDefault("DBInstanceClass")
  valid_604339 = validateParameter(valid_604339, JString, required = false,
                                 default = nil)
  if valid_604339 != nil:
    section.add "DBInstanceClass", valid_604339
  var valid_604340 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604340 = validateParameter(valid_604340, JBool, required = false, default = nil)
  if valid_604340 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604340
  var valid_604341 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_604341 = validateParameter(valid_604341, JString, required = false,
                                 default = nil)
  if valid_604341 != nil:
    section.add "PreferredMaintenanceWindow", valid_604341
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604342: Call_PostModifyDBInstance_604323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_604342.validator(path, query, header, formData, body)
  let scheme = call_604342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604342.url(scheme.get, call_604342.host, call_604342.base,
                         call_604342.route, valid.getOrDefault("path"))
  result = hook(call_604342, url, valid)

proc call*(call_604343: Call_PostModifyDBInstance_604323;
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
  var query_604344 = newJObject()
  var formData_604345 = newJObject()
  add(formData_604345, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_604345, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604345, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_604344, "Action", newJString(Action))
  add(formData_604345, "PromotionTier", newJInt(PromotionTier))
  add(formData_604345, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604345, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_604344, "Version", newJString(Version))
  add(formData_604345, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_604343.call(nil, query_604344, nil, formData_604345, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_604323(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_604324, base: "/",
    url: url_PostModifyDBInstance_604325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_604301 = ref object of OpenApiRestCall_602417
proc url_GetModifyDBInstance_604303(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBInstance_604302(path: JsonNode; query: JsonNode;
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
  var valid_604304 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_604304 = validateParameter(valid_604304, JString, required = false,
                                 default = nil)
  if valid_604304 != nil:
    section.add "PreferredMaintenanceWindow", valid_604304
  var valid_604305 = query.getOrDefault("PromotionTier")
  valid_604305 = validateParameter(valid_604305, JInt, required = false, default = nil)
  if valid_604305 != nil:
    section.add "PromotionTier", valid_604305
  var valid_604306 = query.getOrDefault("DBInstanceClass")
  valid_604306 = validateParameter(valid_604306, JString, required = false,
                                 default = nil)
  if valid_604306 != nil:
    section.add "DBInstanceClass", valid_604306
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604307 = query.getOrDefault("Action")
  valid_604307 = validateParameter(valid_604307, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604307 != nil:
    section.add "Action", valid_604307
  var valid_604308 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_604308 = validateParameter(valid_604308, JString, required = false,
                                 default = nil)
  if valid_604308 != nil:
    section.add "NewDBInstanceIdentifier", valid_604308
  var valid_604309 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604309 = validateParameter(valid_604309, JBool, required = false, default = nil)
  if valid_604309 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604309
  var valid_604310 = query.getOrDefault("Version")
  valid_604310 = validateParameter(valid_604310, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604310 != nil:
    section.add "Version", valid_604310
  var valid_604311 = query.getOrDefault("DBInstanceIdentifier")
  valid_604311 = validateParameter(valid_604311, JString, required = true,
                                 default = nil)
  if valid_604311 != nil:
    section.add "DBInstanceIdentifier", valid_604311
  var valid_604312 = query.getOrDefault("ApplyImmediately")
  valid_604312 = validateParameter(valid_604312, JBool, required = false, default = nil)
  if valid_604312 != nil:
    section.add "ApplyImmediately", valid_604312
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604313 = header.getOrDefault("X-Amz-Date")
  valid_604313 = validateParameter(valid_604313, JString, required = false,
                                 default = nil)
  if valid_604313 != nil:
    section.add "X-Amz-Date", valid_604313
  var valid_604314 = header.getOrDefault("X-Amz-Security-Token")
  valid_604314 = validateParameter(valid_604314, JString, required = false,
                                 default = nil)
  if valid_604314 != nil:
    section.add "X-Amz-Security-Token", valid_604314
  var valid_604315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "X-Amz-Content-Sha256", valid_604315
  var valid_604316 = header.getOrDefault("X-Amz-Algorithm")
  valid_604316 = validateParameter(valid_604316, JString, required = false,
                                 default = nil)
  if valid_604316 != nil:
    section.add "X-Amz-Algorithm", valid_604316
  var valid_604317 = header.getOrDefault("X-Amz-Signature")
  valid_604317 = validateParameter(valid_604317, JString, required = false,
                                 default = nil)
  if valid_604317 != nil:
    section.add "X-Amz-Signature", valid_604317
  var valid_604318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "X-Amz-SignedHeaders", valid_604318
  var valid_604319 = header.getOrDefault("X-Amz-Credential")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "X-Amz-Credential", valid_604319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604320: Call_GetModifyDBInstance_604301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_604320.validator(path, query, header, formData, body)
  let scheme = call_604320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604320.url(scheme.get, call_604320.host, call_604320.base,
                         call_604320.route, valid.getOrDefault("path"))
  result = hook(call_604320, url, valid)

proc call*(call_604321: Call_GetModifyDBInstance_604301;
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
  var query_604322 = newJObject()
  add(query_604322, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_604322, "PromotionTier", newJInt(PromotionTier))
  add(query_604322, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604322, "Action", newJString(Action))
  add(query_604322, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_604322, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604322, "Version", newJString(Version))
  add(query_604322, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604322, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_604321.call(nil, query_604322, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_604301(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_604302, base: "/",
    url: url_GetModifyDBInstance_604303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_604364 = ref object of OpenApiRestCall_602417
proc url_PostModifyDBSubnetGroup_604366(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBSubnetGroup_604365(path: JsonNode; query: JsonNode;
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
  var valid_604367 = query.getOrDefault("Action")
  valid_604367 = validateParameter(valid_604367, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604367 != nil:
    section.add "Action", valid_604367
  var valid_604368 = query.getOrDefault("Version")
  valid_604368 = validateParameter(valid_604368, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604368 != nil:
    section.add "Version", valid_604368
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604369 = header.getOrDefault("X-Amz-Date")
  valid_604369 = validateParameter(valid_604369, JString, required = false,
                                 default = nil)
  if valid_604369 != nil:
    section.add "X-Amz-Date", valid_604369
  var valid_604370 = header.getOrDefault("X-Amz-Security-Token")
  valid_604370 = validateParameter(valid_604370, JString, required = false,
                                 default = nil)
  if valid_604370 != nil:
    section.add "X-Amz-Security-Token", valid_604370
  var valid_604371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604371 = validateParameter(valid_604371, JString, required = false,
                                 default = nil)
  if valid_604371 != nil:
    section.add "X-Amz-Content-Sha256", valid_604371
  var valid_604372 = header.getOrDefault("X-Amz-Algorithm")
  valid_604372 = validateParameter(valid_604372, JString, required = false,
                                 default = nil)
  if valid_604372 != nil:
    section.add "X-Amz-Algorithm", valid_604372
  var valid_604373 = header.getOrDefault("X-Amz-Signature")
  valid_604373 = validateParameter(valid_604373, JString, required = false,
                                 default = nil)
  if valid_604373 != nil:
    section.add "X-Amz-Signature", valid_604373
  var valid_604374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604374 = validateParameter(valid_604374, JString, required = false,
                                 default = nil)
  if valid_604374 != nil:
    section.add "X-Amz-SignedHeaders", valid_604374
  var valid_604375 = header.getOrDefault("X-Amz-Credential")
  valid_604375 = validateParameter(valid_604375, JString, required = false,
                                 default = nil)
  if valid_604375 != nil:
    section.add "X-Amz-Credential", valid_604375
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
  var valid_604376 = formData.getOrDefault("DBSubnetGroupName")
  valid_604376 = validateParameter(valid_604376, JString, required = true,
                                 default = nil)
  if valid_604376 != nil:
    section.add "DBSubnetGroupName", valid_604376
  var valid_604377 = formData.getOrDefault("SubnetIds")
  valid_604377 = validateParameter(valid_604377, JArray, required = true, default = nil)
  if valid_604377 != nil:
    section.add "SubnetIds", valid_604377
  var valid_604378 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_604378 = validateParameter(valid_604378, JString, required = false,
                                 default = nil)
  if valid_604378 != nil:
    section.add "DBSubnetGroupDescription", valid_604378
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604379: Call_PostModifyDBSubnetGroup_604364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_604379.validator(path, query, header, formData, body)
  let scheme = call_604379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604379.url(scheme.get, call_604379.host, call_604379.base,
                         call_604379.route, valid.getOrDefault("path"))
  result = hook(call_604379, url, valid)

proc call*(call_604380: Call_PostModifyDBSubnetGroup_604364;
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
  var query_604381 = newJObject()
  var formData_604382 = newJObject()
  add(formData_604382, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_604382.add "SubnetIds", SubnetIds
  add(query_604381, "Action", newJString(Action))
  add(formData_604382, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604381, "Version", newJString(Version))
  result = call_604380.call(nil, query_604381, nil, formData_604382, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_604364(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_604365, base: "/",
    url: url_PostModifyDBSubnetGroup_604366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_604346 = ref object of OpenApiRestCall_602417
proc url_GetModifyDBSubnetGroup_604348(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBSubnetGroup_604347(path: JsonNode; query: JsonNode;
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
  var valid_604349 = query.getOrDefault("Action")
  valid_604349 = validateParameter(valid_604349, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604349 != nil:
    section.add "Action", valid_604349
  var valid_604350 = query.getOrDefault("DBSubnetGroupName")
  valid_604350 = validateParameter(valid_604350, JString, required = true,
                                 default = nil)
  if valid_604350 != nil:
    section.add "DBSubnetGroupName", valid_604350
  var valid_604351 = query.getOrDefault("SubnetIds")
  valid_604351 = validateParameter(valid_604351, JArray, required = true, default = nil)
  if valid_604351 != nil:
    section.add "SubnetIds", valid_604351
  var valid_604352 = query.getOrDefault("DBSubnetGroupDescription")
  valid_604352 = validateParameter(valid_604352, JString, required = false,
                                 default = nil)
  if valid_604352 != nil:
    section.add "DBSubnetGroupDescription", valid_604352
  var valid_604353 = query.getOrDefault("Version")
  valid_604353 = validateParameter(valid_604353, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604353 != nil:
    section.add "Version", valid_604353
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604354 = header.getOrDefault("X-Amz-Date")
  valid_604354 = validateParameter(valid_604354, JString, required = false,
                                 default = nil)
  if valid_604354 != nil:
    section.add "X-Amz-Date", valid_604354
  var valid_604355 = header.getOrDefault("X-Amz-Security-Token")
  valid_604355 = validateParameter(valid_604355, JString, required = false,
                                 default = nil)
  if valid_604355 != nil:
    section.add "X-Amz-Security-Token", valid_604355
  var valid_604356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604356 = validateParameter(valid_604356, JString, required = false,
                                 default = nil)
  if valid_604356 != nil:
    section.add "X-Amz-Content-Sha256", valid_604356
  var valid_604357 = header.getOrDefault("X-Amz-Algorithm")
  valid_604357 = validateParameter(valid_604357, JString, required = false,
                                 default = nil)
  if valid_604357 != nil:
    section.add "X-Amz-Algorithm", valid_604357
  var valid_604358 = header.getOrDefault("X-Amz-Signature")
  valid_604358 = validateParameter(valid_604358, JString, required = false,
                                 default = nil)
  if valid_604358 != nil:
    section.add "X-Amz-Signature", valid_604358
  var valid_604359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604359 = validateParameter(valid_604359, JString, required = false,
                                 default = nil)
  if valid_604359 != nil:
    section.add "X-Amz-SignedHeaders", valid_604359
  var valid_604360 = header.getOrDefault("X-Amz-Credential")
  valid_604360 = validateParameter(valid_604360, JString, required = false,
                                 default = nil)
  if valid_604360 != nil:
    section.add "X-Amz-Credential", valid_604360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604361: Call_GetModifyDBSubnetGroup_604346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_604361.validator(path, query, header, formData, body)
  let scheme = call_604361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604361.url(scheme.get, call_604361.host, call_604361.base,
                         call_604361.route, valid.getOrDefault("path"))
  result = hook(call_604361, url, valid)

proc call*(call_604362: Call_GetModifyDBSubnetGroup_604346;
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
  var query_604363 = newJObject()
  add(query_604363, "Action", newJString(Action))
  add(query_604363, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_604363.add "SubnetIds", SubnetIds
  add(query_604363, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604363, "Version", newJString(Version))
  result = call_604362.call(nil, query_604363, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_604346(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_604347, base: "/",
    url: url_GetModifyDBSubnetGroup_604348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_604400 = ref object of OpenApiRestCall_602417
proc url_PostRebootDBInstance_604402(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebootDBInstance_604401(path: JsonNode; query: JsonNode;
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
  var valid_604403 = query.getOrDefault("Action")
  valid_604403 = validateParameter(valid_604403, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604403 != nil:
    section.add "Action", valid_604403
  var valid_604404 = query.getOrDefault("Version")
  valid_604404 = validateParameter(valid_604404, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604404 != nil:
    section.add "Version", valid_604404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604405 = header.getOrDefault("X-Amz-Date")
  valid_604405 = validateParameter(valid_604405, JString, required = false,
                                 default = nil)
  if valid_604405 != nil:
    section.add "X-Amz-Date", valid_604405
  var valid_604406 = header.getOrDefault("X-Amz-Security-Token")
  valid_604406 = validateParameter(valid_604406, JString, required = false,
                                 default = nil)
  if valid_604406 != nil:
    section.add "X-Amz-Security-Token", valid_604406
  var valid_604407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604407 = validateParameter(valid_604407, JString, required = false,
                                 default = nil)
  if valid_604407 != nil:
    section.add "X-Amz-Content-Sha256", valid_604407
  var valid_604408 = header.getOrDefault("X-Amz-Algorithm")
  valid_604408 = validateParameter(valid_604408, JString, required = false,
                                 default = nil)
  if valid_604408 != nil:
    section.add "X-Amz-Algorithm", valid_604408
  var valid_604409 = header.getOrDefault("X-Amz-Signature")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "X-Amz-Signature", valid_604409
  var valid_604410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "X-Amz-SignedHeaders", valid_604410
  var valid_604411 = header.getOrDefault("X-Amz-Credential")
  valid_604411 = validateParameter(valid_604411, JString, required = false,
                                 default = nil)
  if valid_604411 != nil:
    section.add "X-Amz-Credential", valid_604411
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604412 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604412 = validateParameter(valid_604412, JString, required = true,
                                 default = nil)
  if valid_604412 != nil:
    section.add "DBInstanceIdentifier", valid_604412
  var valid_604413 = formData.getOrDefault("ForceFailover")
  valid_604413 = validateParameter(valid_604413, JBool, required = false, default = nil)
  if valid_604413 != nil:
    section.add "ForceFailover", valid_604413
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604414: Call_PostRebootDBInstance_604400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_604414.validator(path, query, header, formData, body)
  let scheme = call_604414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604414.url(scheme.get, call_604414.host, call_604414.base,
                         call_604414.route, valid.getOrDefault("path"))
  result = hook(call_604414, url, valid)

proc call*(call_604415: Call_PostRebootDBInstance_604400;
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
  var query_604416 = newJObject()
  var formData_604417 = newJObject()
  add(formData_604417, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604416, "Action", newJString(Action))
  add(formData_604417, "ForceFailover", newJBool(ForceFailover))
  add(query_604416, "Version", newJString(Version))
  result = call_604415.call(nil, query_604416, nil, formData_604417, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_604400(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_604401, base: "/",
    url: url_PostRebootDBInstance_604402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_604383 = ref object of OpenApiRestCall_602417
proc url_GetRebootDBInstance_604385(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebootDBInstance_604384(path: JsonNode; query: JsonNode;
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
  var valid_604386 = query.getOrDefault("Action")
  valid_604386 = validateParameter(valid_604386, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604386 != nil:
    section.add "Action", valid_604386
  var valid_604387 = query.getOrDefault("ForceFailover")
  valid_604387 = validateParameter(valid_604387, JBool, required = false, default = nil)
  if valid_604387 != nil:
    section.add "ForceFailover", valid_604387
  var valid_604388 = query.getOrDefault("Version")
  valid_604388 = validateParameter(valid_604388, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604388 != nil:
    section.add "Version", valid_604388
  var valid_604389 = query.getOrDefault("DBInstanceIdentifier")
  valid_604389 = validateParameter(valid_604389, JString, required = true,
                                 default = nil)
  if valid_604389 != nil:
    section.add "DBInstanceIdentifier", valid_604389
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604390 = header.getOrDefault("X-Amz-Date")
  valid_604390 = validateParameter(valid_604390, JString, required = false,
                                 default = nil)
  if valid_604390 != nil:
    section.add "X-Amz-Date", valid_604390
  var valid_604391 = header.getOrDefault("X-Amz-Security-Token")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "X-Amz-Security-Token", valid_604391
  var valid_604392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604392 = validateParameter(valid_604392, JString, required = false,
                                 default = nil)
  if valid_604392 != nil:
    section.add "X-Amz-Content-Sha256", valid_604392
  var valid_604393 = header.getOrDefault("X-Amz-Algorithm")
  valid_604393 = validateParameter(valid_604393, JString, required = false,
                                 default = nil)
  if valid_604393 != nil:
    section.add "X-Amz-Algorithm", valid_604393
  var valid_604394 = header.getOrDefault("X-Amz-Signature")
  valid_604394 = validateParameter(valid_604394, JString, required = false,
                                 default = nil)
  if valid_604394 != nil:
    section.add "X-Amz-Signature", valid_604394
  var valid_604395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604395 = validateParameter(valid_604395, JString, required = false,
                                 default = nil)
  if valid_604395 != nil:
    section.add "X-Amz-SignedHeaders", valid_604395
  var valid_604396 = header.getOrDefault("X-Amz-Credential")
  valid_604396 = validateParameter(valid_604396, JString, required = false,
                                 default = nil)
  if valid_604396 != nil:
    section.add "X-Amz-Credential", valid_604396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604397: Call_GetRebootDBInstance_604383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_604397.validator(path, query, header, formData, body)
  let scheme = call_604397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604397.url(scheme.get, call_604397.host, call_604397.base,
                         call_604397.route, valid.getOrDefault("path"))
  result = hook(call_604397, url, valid)

proc call*(call_604398: Call_GetRebootDBInstance_604383;
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
  var query_604399 = newJObject()
  add(query_604399, "Action", newJString(Action))
  add(query_604399, "ForceFailover", newJBool(ForceFailover))
  add(query_604399, "Version", newJString(Version))
  add(query_604399, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604398.call(nil, query_604399, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_604383(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_604384, base: "/",
    url: url_GetRebootDBInstance_604385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_604435 = ref object of OpenApiRestCall_602417
proc url_PostRemoveTagsFromResource_604437(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTagsFromResource_604436(path: JsonNode; query: JsonNode;
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
  var valid_604438 = query.getOrDefault("Action")
  valid_604438 = validateParameter(valid_604438, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_604438 != nil:
    section.add "Action", valid_604438
  var valid_604439 = query.getOrDefault("Version")
  valid_604439 = validateParameter(valid_604439, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604439 != nil:
    section.add "Version", valid_604439
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604440 = header.getOrDefault("X-Amz-Date")
  valid_604440 = validateParameter(valid_604440, JString, required = false,
                                 default = nil)
  if valid_604440 != nil:
    section.add "X-Amz-Date", valid_604440
  var valid_604441 = header.getOrDefault("X-Amz-Security-Token")
  valid_604441 = validateParameter(valid_604441, JString, required = false,
                                 default = nil)
  if valid_604441 != nil:
    section.add "X-Amz-Security-Token", valid_604441
  var valid_604442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604442 = validateParameter(valid_604442, JString, required = false,
                                 default = nil)
  if valid_604442 != nil:
    section.add "X-Amz-Content-Sha256", valid_604442
  var valid_604443 = header.getOrDefault("X-Amz-Algorithm")
  valid_604443 = validateParameter(valid_604443, JString, required = false,
                                 default = nil)
  if valid_604443 != nil:
    section.add "X-Amz-Algorithm", valid_604443
  var valid_604444 = header.getOrDefault("X-Amz-Signature")
  valid_604444 = validateParameter(valid_604444, JString, required = false,
                                 default = nil)
  if valid_604444 != nil:
    section.add "X-Amz-Signature", valid_604444
  var valid_604445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604445 = validateParameter(valid_604445, JString, required = false,
                                 default = nil)
  if valid_604445 != nil:
    section.add "X-Amz-SignedHeaders", valid_604445
  var valid_604446 = header.getOrDefault("X-Amz-Credential")
  valid_604446 = validateParameter(valid_604446, JString, required = false,
                                 default = nil)
  if valid_604446 != nil:
    section.add "X-Amz-Credential", valid_604446
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_604447 = formData.getOrDefault("TagKeys")
  valid_604447 = validateParameter(valid_604447, JArray, required = true, default = nil)
  if valid_604447 != nil:
    section.add "TagKeys", valid_604447
  var valid_604448 = formData.getOrDefault("ResourceName")
  valid_604448 = validateParameter(valid_604448, JString, required = true,
                                 default = nil)
  if valid_604448 != nil:
    section.add "ResourceName", valid_604448
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604449: Call_PostRemoveTagsFromResource_604435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_604449.validator(path, query, header, formData, body)
  let scheme = call_604449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604449.url(scheme.get, call_604449.host, call_604449.base,
                         call_604449.route, valid.getOrDefault("path"))
  result = hook(call_604449, url, valid)

proc call*(call_604450: Call_PostRemoveTagsFromResource_604435; TagKeys: JsonNode;
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
  var query_604451 = newJObject()
  var formData_604452 = newJObject()
  add(query_604451, "Action", newJString(Action))
  if TagKeys != nil:
    formData_604452.add "TagKeys", TagKeys
  add(formData_604452, "ResourceName", newJString(ResourceName))
  add(query_604451, "Version", newJString(Version))
  result = call_604450.call(nil, query_604451, nil, formData_604452, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_604435(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_604436, base: "/",
    url: url_PostRemoveTagsFromResource_604437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_604418 = ref object of OpenApiRestCall_602417
proc url_GetRemoveTagsFromResource_604420(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTagsFromResource_604419(path: JsonNode; query: JsonNode;
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
  var valid_604421 = query.getOrDefault("ResourceName")
  valid_604421 = validateParameter(valid_604421, JString, required = true,
                                 default = nil)
  if valid_604421 != nil:
    section.add "ResourceName", valid_604421
  var valid_604422 = query.getOrDefault("Action")
  valid_604422 = validateParameter(valid_604422, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_604422 != nil:
    section.add "Action", valid_604422
  var valid_604423 = query.getOrDefault("TagKeys")
  valid_604423 = validateParameter(valid_604423, JArray, required = true, default = nil)
  if valid_604423 != nil:
    section.add "TagKeys", valid_604423
  var valid_604424 = query.getOrDefault("Version")
  valid_604424 = validateParameter(valid_604424, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604424 != nil:
    section.add "Version", valid_604424
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604425 = header.getOrDefault("X-Amz-Date")
  valid_604425 = validateParameter(valid_604425, JString, required = false,
                                 default = nil)
  if valid_604425 != nil:
    section.add "X-Amz-Date", valid_604425
  var valid_604426 = header.getOrDefault("X-Amz-Security-Token")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "X-Amz-Security-Token", valid_604426
  var valid_604427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604427 = validateParameter(valid_604427, JString, required = false,
                                 default = nil)
  if valid_604427 != nil:
    section.add "X-Amz-Content-Sha256", valid_604427
  var valid_604428 = header.getOrDefault("X-Amz-Algorithm")
  valid_604428 = validateParameter(valid_604428, JString, required = false,
                                 default = nil)
  if valid_604428 != nil:
    section.add "X-Amz-Algorithm", valid_604428
  var valid_604429 = header.getOrDefault("X-Amz-Signature")
  valid_604429 = validateParameter(valid_604429, JString, required = false,
                                 default = nil)
  if valid_604429 != nil:
    section.add "X-Amz-Signature", valid_604429
  var valid_604430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604430 = validateParameter(valid_604430, JString, required = false,
                                 default = nil)
  if valid_604430 != nil:
    section.add "X-Amz-SignedHeaders", valid_604430
  var valid_604431 = header.getOrDefault("X-Amz-Credential")
  valid_604431 = validateParameter(valid_604431, JString, required = false,
                                 default = nil)
  if valid_604431 != nil:
    section.add "X-Amz-Credential", valid_604431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604432: Call_GetRemoveTagsFromResource_604418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_604432.validator(path, query, header, formData, body)
  let scheme = call_604432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604432.url(scheme.get, call_604432.host, call_604432.base,
                         call_604432.route, valid.getOrDefault("path"))
  result = hook(call_604432, url, valid)

proc call*(call_604433: Call_GetRemoveTagsFromResource_604418;
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
  var query_604434 = newJObject()
  add(query_604434, "ResourceName", newJString(ResourceName))
  add(query_604434, "Action", newJString(Action))
  if TagKeys != nil:
    query_604434.add "TagKeys", TagKeys
  add(query_604434, "Version", newJString(Version))
  result = call_604433.call(nil, query_604434, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_604418(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_604419, base: "/",
    url: url_GetRemoveTagsFromResource_604420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBClusterParameterGroup_604471 = ref object of OpenApiRestCall_602417
proc url_PostResetDBClusterParameterGroup_604473(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostResetDBClusterParameterGroup_604472(path: JsonNode;
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
  var valid_604474 = query.getOrDefault("Action")
  valid_604474 = validateParameter(valid_604474, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_604474 != nil:
    section.add "Action", valid_604474
  var valid_604475 = query.getOrDefault("Version")
  valid_604475 = validateParameter(valid_604475, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604475 != nil:
    section.add "Version", valid_604475
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604476 = header.getOrDefault("X-Amz-Date")
  valid_604476 = validateParameter(valid_604476, JString, required = false,
                                 default = nil)
  if valid_604476 != nil:
    section.add "X-Amz-Date", valid_604476
  var valid_604477 = header.getOrDefault("X-Amz-Security-Token")
  valid_604477 = validateParameter(valid_604477, JString, required = false,
                                 default = nil)
  if valid_604477 != nil:
    section.add "X-Amz-Security-Token", valid_604477
  var valid_604478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604478 = validateParameter(valid_604478, JString, required = false,
                                 default = nil)
  if valid_604478 != nil:
    section.add "X-Amz-Content-Sha256", valid_604478
  var valid_604479 = header.getOrDefault("X-Amz-Algorithm")
  valid_604479 = validateParameter(valid_604479, JString, required = false,
                                 default = nil)
  if valid_604479 != nil:
    section.add "X-Amz-Algorithm", valid_604479
  var valid_604480 = header.getOrDefault("X-Amz-Signature")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "X-Amz-Signature", valid_604480
  var valid_604481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604481 = validateParameter(valid_604481, JString, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "X-Amz-SignedHeaders", valid_604481
  var valid_604482 = header.getOrDefault("X-Amz-Credential")
  valid_604482 = validateParameter(valid_604482, JString, required = false,
                                 default = nil)
  if valid_604482 != nil:
    section.add "X-Amz-Credential", valid_604482
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  section = newJObject()
  var valid_604483 = formData.getOrDefault("Parameters")
  valid_604483 = validateParameter(valid_604483, JArray, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "Parameters", valid_604483
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_604484 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_604484 = validateParameter(valid_604484, JString, required = true,
                                 default = nil)
  if valid_604484 != nil:
    section.add "DBClusterParameterGroupName", valid_604484
  var valid_604485 = formData.getOrDefault("ResetAllParameters")
  valid_604485 = validateParameter(valid_604485, JBool, required = false, default = nil)
  if valid_604485 != nil:
    section.add "ResetAllParameters", valid_604485
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604486: Call_PostResetDBClusterParameterGroup_604471;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_604486.validator(path, query, header, formData, body)
  let scheme = call_604486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604486.url(scheme.get, call_604486.host, call_604486.base,
                         call_604486.route, valid.getOrDefault("path"))
  result = hook(call_604486, url, valid)

proc call*(call_604487: Call_PostResetDBClusterParameterGroup_604471;
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
  var query_604488 = newJObject()
  var formData_604489 = newJObject()
  if Parameters != nil:
    formData_604489.add "Parameters", Parameters
  add(query_604488, "Action", newJString(Action))
  add(formData_604489, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_604489, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_604488, "Version", newJString(Version))
  result = call_604487.call(nil, query_604488, nil, formData_604489, nil)

var postResetDBClusterParameterGroup* = Call_PostResetDBClusterParameterGroup_604471(
    name: "postResetDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_PostResetDBClusterParameterGroup_604472, base: "/",
    url: url_PostResetDBClusterParameterGroup_604473,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBClusterParameterGroup_604453 = ref object of OpenApiRestCall_602417
proc url_GetResetDBClusterParameterGroup_604455(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResetDBClusterParameterGroup_604454(path: JsonNode;
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
  var valid_604456 = query.getOrDefault("DBClusterParameterGroupName")
  valid_604456 = validateParameter(valid_604456, JString, required = true,
                                 default = nil)
  if valid_604456 != nil:
    section.add "DBClusterParameterGroupName", valid_604456
  var valid_604457 = query.getOrDefault("Parameters")
  valid_604457 = validateParameter(valid_604457, JArray, required = false,
                                 default = nil)
  if valid_604457 != nil:
    section.add "Parameters", valid_604457
  var valid_604458 = query.getOrDefault("Action")
  valid_604458 = validateParameter(valid_604458, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_604458 != nil:
    section.add "Action", valid_604458
  var valid_604459 = query.getOrDefault("ResetAllParameters")
  valid_604459 = validateParameter(valid_604459, JBool, required = false, default = nil)
  if valid_604459 != nil:
    section.add "ResetAllParameters", valid_604459
  var valid_604460 = query.getOrDefault("Version")
  valid_604460 = validateParameter(valid_604460, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604460 != nil:
    section.add "Version", valid_604460
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604461 = header.getOrDefault("X-Amz-Date")
  valid_604461 = validateParameter(valid_604461, JString, required = false,
                                 default = nil)
  if valid_604461 != nil:
    section.add "X-Amz-Date", valid_604461
  var valid_604462 = header.getOrDefault("X-Amz-Security-Token")
  valid_604462 = validateParameter(valid_604462, JString, required = false,
                                 default = nil)
  if valid_604462 != nil:
    section.add "X-Amz-Security-Token", valid_604462
  var valid_604463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604463 = validateParameter(valid_604463, JString, required = false,
                                 default = nil)
  if valid_604463 != nil:
    section.add "X-Amz-Content-Sha256", valid_604463
  var valid_604464 = header.getOrDefault("X-Amz-Algorithm")
  valid_604464 = validateParameter(valid_604464, JString, required = false,
                                 default = nil)
  if valid_604464 != nil:
    section.add "X-Amz-Algorithm", valid_604464
  var valid_604465 = header.getOrDefault("X-Amz-Signature")
  valid_604465 = validateParameter(valid_604465, JString, required = false,
                                 default = nil)
  if valid_604465 != nil:
    section.add "X-Amz-Signature", valid_604465
  var valid_604466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604466 = validateParameter(valid_604466, JString, required = false,
                                 default = nil)
  if valid_604466 != nil:
    section.add "X-Amz-SignedHeaders", valid_604466
  var valid_604467 = header.getOrDefault("X-Amz-Credential")
  valid_604467 = validateParameter(valid_604467, JString, required = false,
                                 default = nil)
  if valid_604467 != nil:
    section.add "X-Amz-Credential", valid_604467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604468: Call_GetResetDBClusterParameterGroup_604453;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_604468.validator(path, query, header, formData, body)
  let scheme = call_604468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604468.url(scheme.get, call_604468.host, call_604468.base,
                         call_604468.route, valid.getOrDefault("path"))
  result = hook(call_604468, url, valid)

proc call*(call_604469: Call_GetResetDBClusterParameterGroup_604453;
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
  var query_604470 = newJObject()
  add(query_604470, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_604470.add "Parameters", Parameters
  add(query_604470, "Action", newJString(Action))
  add(query_604470, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_604470, "Version", newJString(Version))
  result = call_604469.call(nil, query_604470, nil, nil, nil)

var getResetDBClusterParameterGroup* = Call_GetResetDBClusterParameterGroup_604453(
    name: "getResetDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_GetResetDBClusterParameterGroup_604454, base: "/",
    url: url_GetResetDBClusterParameterGroup_604455,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterFromSnapshot_604517 = ref object of OpenApiRestCall_602417
proc url_PostRestoreDBClusterFromSnapshot_604519(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBClusterFromSnapshot_604518(path: JsonNode;
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
  var valid_604520 = query.getOrDefault("Action")
  valid_604520 = validateParameter(valid_604520, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_604520 != nil:
    section.add "Action", valid_604520
  var valid_604521 = query.getOrDefault("Version")
  valid_604521 = validateParameter(valid_604521, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604521 != nil:
    section.add "Version", valid_604521
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604522 = header.getOrDefault("X-Amz-Date")
  valid_604522 = validateParameter(valid_604522, JString, required = false,
                                 default = nil)
  if valid_604522 != nil:
    section.add "X-Amz-Date", valid_604522
  var valid_604523 = header.getOrDefault("X-Amz-Security-Token")
  valid_604523 = validateParameter(valid_604523, JString, required = false,
                                 default = nil)
  if valid_604523 != nil:
    section.add "X-Amz-Security-Token", valid_604523
  var valid_604524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604524 = validateParameter(valid_604524, JString, required = false,
                                 default = nil)
  if valid_604524 != nil:
    section.add "X-Amz-Content-Sha256", valid_604524
  var valid_604525 = header.getOrDefault("X-Amz-Algorithm")
  valid_604525 = validateParameter(valid_604525, JString, required = false,
                                 default = nil)
  if valid_604525 != nil:
    section.add "X-Amz-Algorithm", valid_604525
  var valid_604526 = header.getOrDefault("X-Amz-Signature")
  valid_604526 = validateParameter(valid_604526, JString, required = false,
                                 default = nil)
  if valid_604526 != nil:
    section.add "X-Amz-Signature", valid_604526
  var valid_604527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604527 = validateParameter(valid_604527, JString, required = false,
                                 default = nil)
  if valid_604527 != nil:
    section.add "X-Amz-SignedHeaders", valid_604527
  var valid_604528 = header.getOrDefault("X-Amz-Credential")
  valid_604528 = validateParameter(valid_604528, JString, required = false,
                                 default = nil)
  if valid_604528 != nil:
    section.add "X-Amz-Credential", valid_604528
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
  var valid_604529 = formData.getOrDefault("Port")
  valid_604529 = validateParameter(valid_604529, JInt, required = false, default = nil)
  if valid_604529 != nil:
    section.add "Port", valid_604529
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_604530 = formData.getOrDefault("Engine")
  valid_604530 = validateParameter(valid_604530, JString, required = true,
                                 default = nil)
  if valid_604530 != nil:
    section.add "Engine", valid_604530
  var valid_604531 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_604531 = validateParameter(valid_604531, JArray, required = false,
                                 default = nil)
  if valid_604531 != nil:
    section.add "VpcSecurityGroupIds", valid_604531
  var valid_604532 = formData.getOrDefault("Tags")
  valid_604532 = validateParameter(valid_604532, JArray, required = false,
                                 default = nil)
  if valid_604532 != nil:
    section.add "Tags", valid_604532
  var valid_604533 = formData.getOrDefault("DeletionProtection")
  valid_604533 = validateParameter(valid_604533, JBool, required = false, default = nil)
  if valid_604533 != nil:
    section.add "DeletionProtection", valid_604533
  var valid_604534 = formData.getOrDefault("DBSubnetGroupName")
  valid_604534 = validateParameter(valid_604534, JString, required = false,
                                 default = nil)
  if valid_604534 != nil:
    section.add "DBSubnetGroupName", valid_604534
  var valid_604535 = formData.getOrDefault("AvailabilityZones")
  valid_604535 = validateParameter(valid_604535, JArray, required = false,
                                 default = nil)
  if valid_604535 != nil:
    section.add "AvailabilityZones", valid_604535
  var valid_604536 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_604536 = validateParameter(valid_604536, JArray, required = false,
                                 default = nil)
  if valid_604536 != nil:
    section.add "EnableCloudwatchLogsExports", valid_604536
  var valid_604537 = formData.getOrDefault("KmsKeyId")
  valid_604537 = validateParameter(valid_604537, JString, required = false,
                                 default = nil)
  if valid_604537 != nil:
    section.add "KmsKeyId", valid_604537
  var valid_604538 = formData.getOrDefault("SnapshotIdentifier")
  valid_604538 = validateParameter(valid_604538, JString, required = true,
                                 default = nil)
  if valid_604538 != nil:
    section.add "SnapshotIdentifier", valid_604538
  var valid_604539 = formData.getOrDefault("DBClusterIdentifier")
  valid_604539 = validateParameter(valid_604539, JString, required = true,
                                 default = nil)
  if valid_604539 != nil:
    section.add "DBClusterIdentifier", valid_604539
  var valid_604540 = formData.getOrDefault("EngineVersion")
  valid_604540 = validateParameter(valid_604540, JString, required = false,
                                 default = nil)
  if valid_604540 != nil:
    section.add "EngineVersion", valid_604540
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604541: Call_PostRestoreDBClusterFromSnapshot_604517;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_604541.validator(path, query, header, formData, body)
  let scheme = call_604541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604541.url(scheme.get, call_604541.host, call_604541.base,
                         call_604541.route, valid.getOrDefault("path"))
  result = hook(call_604541, url, valid)

proc call*(call_604542: Call_PostRestoreDBClusterFromSnapshot_604517;
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
  var query_604543 = newJObject()
  var formData_604544 = newJObject()
  add(formData_604544, "Port", newJInt(Port))
  add(formData_604544, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_604544.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if Tags != nil:
    formData_604544.add "Tags", Tags
  add(formData_604544, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_604544, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604543, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_604544.add "AvailabilityZones", AvailabilityZones
  if EnableCloudwatchLogsExports != nil:
    formData_604544.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_604544, "KmsKeyId", newJString(KmsKeyId))
  add(formData_604544, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(formData_604544, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_604544, "EngineVersion", newJString(EngineVersion))
  add(query_604543, "Version", newJString(Version))
  result = call_604542.call(nil, query_604543, nil, formData_604544, nil)

var postRestoreDBClusterFromSnapshot* = Call_PostRestoreDBClusterFromSnapshot_604517(
    name: "postRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_PostRestoreDBClusterFromSnapshot_604518, base: "/",
    url: url_PostRestoreDBClusterFromSnapshot_604519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterFromSnapshot_604490 = ref object of OpenApiRestCall_602417
proc url_GetRestoreDBClusterFromSnapshot_604492(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBClusterFromSnapshot_604491(path: JsonNode;
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
  var valid_604493 = query.getOrDefault("Engine")
  valid_604493 = validateParameter(valid_604493, JString, required = true,
                                 default = nil)
  if valid_604493 != nil:
    section.add "Engine", valid_604493
  var valid_604494 = query.getOrDefault("AvailabilityZones")
  valid_604494 = validateParameter(valid_604494, JArray, required = false,
                                 default = nil)
  if valid_604494 != nil:
    section.add "AvailabilityZones", valid_604494
  var valid_604495 = query.getOrDefault("DBClusterIdentifier")
  valid_604495 = validateParameter(valid_604495, JString, required = true,
                                 default = nil)
  if valid_604495 != nil:
    section.add "DBClusterIdentifier", valid_604495
  var valid_604496 = query.getOrDefault("VpcSecurityGroupIds")
  valid_604496 = validateParameter(valid_604496, JArray, required = false,
                                 default = nil)
  if valid_604496 != nil:
    section.add "VpcSecurityGroupIds", valid_604496
  var valid_604497 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_604497 = validateParameter(valid_604497, JArray, required = false,
                                 default = nil)
  if valid_604497 != nil:
    section.add "EnableCloudwatchLogsExports", valid_604497
  var valid_604498 = query.getOrDefault("Tags")
  valid_604498 = validateParameter(valid_604498, JArray, required = false,
                                 default = nil)
  if valid_604498 != nil:
    section.add "Tags", valid_604498
  var valid_604499 = query.getOrDefault("DeletionProtection")
  valid_604499 = validateParameter(valid_604499, JBool, required = false, default = nil)
  if valid_604499 != nil:
    section.add "DeletionProtection", valid_604499
  var valid_604500 = query.getOrDefault("Action")
  valid_604500 = validateParameter(valid_604500, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_604500 != nil:
    section.add "Action", valid_604500
  var valid_604501 = query.getOrDefault("DBSubnetGroupName")
  valid_604501 = validateParameter(valid_604501, JString, required = false,
                                 default = nil)
  if valid_604501 != nil:
    section.add "DBSubnetGroupName", valid_604501
  var valid_604502 = query.getOrDefault("KmsKeyId")
  valid_604502 = validateParameter(valid_604502, JString, required = false,
                                 default = nil)
  if valid_604502 != nil:
    section.add "KmsKeyId", valid_604502
  var valid_604503 = query.getOrDefault("EngineVersion")
  valid_604503 = validateParameter(valid_604503, JString, required = false,
                                 default = nil)
  if valid_604503 != nil:
    section.add "EngineVersion", valid_604503
  var valid_604504 = query.getOrDefault("Port")
  valid_604504 = validateParameter(valid_604504, JInt, required = false, default = nil)
  if valid_604504 != nil:
    section.add "Port", valid_604504
  var valid_604505 = query.getOrDefault("SnapshotIdentifier")
  valid_604505 = validateParameter(valid_604505, JString, required = true,
                                 default = nil)
  if valid_604505 != nil:
    section.add "SnapshotIdentifier", valid_604505
  var valid_604506 = query.getOrDefault("Version")
  valid_604506 = validateParameter(valid_604506, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604506 != nil:
    section.add "Version", valid_604506
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604507 = header.getOrDefault("X-Amz-Date")
  valid_604507 = validateParameter(valid_604507, JString, required = false,
                                 default = nil)
  if valid_604507 != nil:
    section.add "X-Amz-Date", valid_604507
  var valid_604508 = header.getOrDefault("X-Amz-Security-Token")
  valid_604508 = validateParameter(valid_604508, JString, required = false,
                                 default = nil)
  if valid_604508 != nil:
    section.add "X-Amz-Security-Token", valid_604508
  var valid_604509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604509 = validateParameter(valid_604509, JString, required = false,
                                 default = nil)
  if valid_604509 != nil:
    section.add "X-Amz-Content-Sha256", valid_604509
  var valid_604510 = header.getOrDefault("X-Amz-Algorithm")
  valid_604510 = validateParameter(valid_604510, JString, required = false,
                                 default = nil)
  if valid_604510 != nil:
    section.add "X-Amz-Algorithm", valid_604510
  var valid_604511 = header.getOrDefault("X-Amz-Signature")
  valid_604511 = validateParameter(valid_604511, JString, required = false,
                                 default = nil)
  if valid_604511 != nil:
    section.add "X-Amz-Signature", valid_604511
  var valid_604512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604512 = validateParameter(valid_604512, JString, required = false,
                                 default = nil)
  if valid_604512 != nil:
    section.add "X-Amz-SignedHeaders", valid_604512
  var valid_604513 = header.getOrDefault("X-Amz-Credential")
  valid_604513 = validateParameter(valid_604513, JString, required = false,
                                 default = nil)
  if valid_604513 != nil:
    section.add "X-Amz-Credential", valid_604513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604514: Call_GetRestoreDBClusterFromSnapshot_604490;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_604514.validator(path, query, header, formData, body)
  let scheme = call_604514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604514.url(scheme.get, call_604514.host, call_604514.base,
                         call_604514.route, valid.getOrDefault("path"))
  result = hook(call_604514, url, valid)

proc call*(call_604515: Call_GetRestoreDBClusterFromSnapshot_604490;
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
  var query_604516 = newJObject()
  add(query_604516, "Engine", newJString(Engine))
  if AvailabilityZones != nil:
    query_604516.add "AvailabilityZones", AvailabilityZones
  add(query_604516, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_604516.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_604516.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_604516.add "Tags", Tags
  add(query_604516, "DeletionProtection", newJBool(DeletionProtection))
  add(query_604516, "Action", newJString(Action))
  add(query_604516, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604516, "KmsKeyId", newJString(KmsKeyId))
  add(query_604516, "EngineVersion", newJString(EngineVersion))
  add(query_604516, "Port", newJInt(Port))
  add(query_604516, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(query_604516, "Version", newJString(Version))
  result = call_604515.call(nil, query_604516, nil, nil, nil)

var getRestoreDBClusterFromSnapshot* = Call_GetRestoreDBClusterFromSnapshot_604490(
    name: "getRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_GetRestoreDBClusterFromSnapshot_604491, base: "/",
    url: url_GetRestoreDBClusterFromSnapshot_604492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterToPointInTime_604571 = ref object of OpenApiRestCall_602417
proc url_PostRestoreDBClusterToPointInTime_604573(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBClusterToPointInTime_604572(path: JsonNode;
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
  var valid_604574 = query.getOrDefault("Action")
  valid_604574 = validateParameter(valid_604574, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_604574 != nil:
    section.add "Action", valid_604574
  var valid_604575 = query.getOrDefault("Version")
  valid_604575 = validateParameter(valid_604575, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604575 != nil:
    section.add "Version", valid_604575
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604576 = header.getOrDefault("X-Amz-Date")
  valid_604576 = validateParameter(valid_604576, JString, required = false,
                                 default = nil)
  if valid_604576 != nil:
    section.add "X-Amz-Date", valid_604576
  var valid_604577 = header.getOrDefault("X-Amz-Security-Token")
  valid_604577 = validateParameter(valid_604577, JString, required = false,
                                 default = nil)
  if valid_604577 != nil:
    section.add "X-Amz-Security-Token", valid_604577
  var valid_604578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604578 = validateParameter(valid_604578, JString, required = false,
                                 default = nil)
  if valid_604578 != nil:
    section.add "X-Amz-Content-Sha256", valid_604578
  var valid_604579 = header.getOrDefault("X-Amz-Algorithm")
  valid_604579 = validateParameter(valid_604579, JString, required = false,
                                 default = nil)
  if valid_604579 != nil:
    section.add "X-Amz-Algorithm", valid_604579
  var valid_604580 = header.getOrDefault("X-Amz-Signature")
  valid_604580 = validateParameter(valid_604580, JString, required = false,
                                 default = nil)
  if valid_604580 != nil:
    section.add "X-Amz-Signature", valid_604580
  var valid_604581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604581 = validateParameter(valid_604581, JString, required = false,
                                 default = nil)
  if valid_604581 != nil:
    section.add "X-Amz-SignedHeaders", valid_604581
  var valid_604582 = header.getOrDefault("X-Amz-Credential")
  valid_604582 = validateParameter(valid_604582, JString, required = false,
                                 default = nil)
  if valid_604582 != nil:
    section.add "X-Amz-Credential", valid_604582
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
  var valid_604583 = formData.getOrDefault("SourceDBClusterIdentifier")
  valid_604583 = validateParameter(valid_604583, JString, required = true,
                                 default = nil)
  if valid_604583 != nil:
    section.add "SourceDBClusterIdentifier", valid_604583
  var valid_604584 = formData.getOrDefault("UseLatestRestorableTime")
  valid_604584 = validateParameter(valid_604584, JBool, required = false, default = nil)
  if valid_604584 != nil:
    section.add "UseLatestRestorableTime", valid_604584
  var valid_604585 = formData.getOrDefault("Port")
  valid_604585 = validateParameter(valid_604585, JInt, required = false, default = nil)
  if valid_604585 != nil:
    section.add "Port", valid_604585
  var valid_604586 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_604586 = validateParameter(valid_604586, JArray, required = false,
                                 default = nil)
  if valid_604586 != nil:
    section.add "VpcSecurityGroupIds", valid_604586
  var valid_604587 = formData.getOrDefault("RestoreToTime")
  valid_604587 = validateParameter(valid_604587, JString, required = false,
                                 default = nil)
  if valid_604587 != nil:
    section.add "RestoreToTime", valid_604587
  var valid_604588 = formData.getOrDefault("Tags")
  valid_604588 = validateParameter(valid_604588, JArray, required = false,
                                 default = nil)
  if valid_604588 != nil:
    section.add "Tags", valid_604588
  var valid_604589 = formData.getOrDefault("DeletionProtection")
  valid_604589 = validateParameter(valid_604589, JBool, required = false, default = nil)
  if valid_604589 != nil:
    section.add "DeletionProtection", valid_604589
  var valid_604590 = formData.getOrDefault("DBSubnetGroupName")
  valid_604590 = validateParameter(valid_604590, JString, required = false,
                                 default = nil)
  if valid_604590 != nil:
    section.add "DBSubnetGroupName", valid_604590
  var valid_604591 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_604591 = validateParameter(valid_604591, JArray, required = false,
                                 default = nil)
  if valid_604591 != nil:
    section.add "EnableCloudwatchLogsExports", valid_604591
  var valid_604592 = formData.getOrDefault("KmsKeyId")
  valid_604592 = validateParameter(valid_604592, JString, required = false,
                                 default = nil)
  if valid_604592 != nil:
    section.add "KmsKeyId", valid_604592
  var valid_604593 = formData.getOrDefault("DBClusterIdentifier")
  valid_604593 = validateParameter(valid_604593, JString, required = true,
                                 default = nil)
  if valid_604593 != nil:
    section.add "DBClusterIdentifier", valid_604593
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604594: Call_PostRestoreDBClusterToPointInTime_604571;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_604594.validator(path, query, header, formData, body)
  let scheme = call_604594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604594.url(scheme.get, call_604594.host, call_604594.base,
                         call_604594.route, valid.getOrDefault("path"))
  result = hook(call_604594, url, valid)

proc call*(call_604595: Call_PostRestoreDBClusterToPointInTime_604571;
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
  var query_604596 = newJObject()
  var formData_604597 = newJObject()
  add(formData_604597, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(formData_604597, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_604597, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_604597.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_604597, "RestoreToTime", newJString(RestoreToTime))
  if Tags != nil:
    formData_604597.add "Tags", Tags
  add(formData_604597, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_604597, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604596, "Action", newJString(Action))
  if EnableCloudwatchLogsExports != nil:
    formData_604597.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_604597, "KmsKeyId", newJString(KmsKeyId))
  add(formData_604597, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604596, "Version", newJString(Version))
  result = call_604595.call(nil, query_604596, nil, formData_604597, nil)

var postRestoreDBClusterToPointInTime* = Call_PostRestoreDBClusterToPointInTime_604571(
    name: "postRestoreDBClusterToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_PostRestoreDBClusterToPointInTime_604572, base: "/",
    url: url_PostRestoreDBClusterToPointInTime_604573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterToPointInTime_604545 = ref object of OpenApiRestCall_602417
proc url_GetRestoreDBClusterToPointInTime_604547(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBClusterToPointInTime_604546(path: JsonNode;
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
  var valid_604548 = query.getOrDefault("RestoreToTime")
  valid_604548 = validateParameter(valid_604548, JString, required = false,
                                 default = nil)
  if valid_604548 != nil:
    section.add "RestoreToTime", valid_604548
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_604549 = query.getOrDefault("DBClusterIdentifier")
  valid_604549 = validateParameter(valid_604549, JString, required = true,
                                 default = nil)
  if valid_604549 != nil:
    section.add "DBClusterIdentifier", valid_604549
  var valid_604550 = query.getOrDefault("VpcSecurityGroupIds")
  valid_604550 = validateParameter(valid_604550, JArray, required = false,
                                 default = nil)
  if valid_604550 != nil:
    section.add "VpcSecurityGroupIds", valid_604550
  var valid_604551 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_604551 = validateParameter(valid_604551, JArray, required = false,
                                 default = nil)
  if valid_604551 != nil:
    section.add "EnableCloudwatchLogsExports", valid_604551
  var valid_604552 = query.getOrDefault("Tags")
  valid_604552 = validateParameter(valid_604552, JArray, required = false,
                                 default = nil)
  if valid_604552 != nil:
    section.add "Tags", valid_604552
  var valid_604553 = query.getOrDefault("DeletionProtection")
  valid_604553 = validateParameter(valid_604553, JBool, required = false, default = nil)
  if valid_604553 != nil:
    section.add "DeletionProtection", valid_604553
  var valid_604554 = query.getOrDefault("UseLatestRestorableTime")
  valid_604554 = validateParameter(valid_604554, JBool, required = false, default = nil)
  if valid_604554 != nil:
    section.add "UseLatestRestorableTime", valid_604554
  var valid_604555 = query.getOrDefault("Action")
  valid_604555 = validateParameter(valid_604555, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_604555 != nil:
    section.add "Action", valid_604555
  var valid_604556 = query.getOrDefault("DBSubnetGroupName")
  valid_604556 = validateParameter(valid_604556, JString, required = false,
                                 default = nil)
  if valid_604556 != nil:
    section.add "DBSubnetGroupName", valid_604556
  var valid_604557 = query.getOrDefault("KmsKeyId")
  valid_604557 = validateParameter(valid_604557, JString, required = false,
                                 default = nil)
  if valid_604557 != nil:
    section.add "KmsKeyId", valid_604557
  var valid_604558 = query.getOrDefault("Port")
  valid_604558 = validateParameter(valid_604558, JInt, required = false, default = nil)
  if valid_604558 != nil:
    section.add "Port", valid_604558
  var valid_604559 = query.getOrDefault("SourceDBClusterIdentifier")
  valid_604559 = validateParameter(valid_604559, JString, required = true,
                                 default = nil)
  if valid_604559 != nil:
    section.add "SourceDBClusterIdentifier", valid_604559
  var valid_604560 = query.getOrDefault("Version")
  valid_604560 = validateParameter(valid_604560, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604560 != nil:
    section.add "Version", valid_604560
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604561 = header.getOrDefault("X-Amz-Date")
  valid_604561 = validateParameter(valid_604561, JString, required = false,
                                 default = nil)
  if valid_604561 != nil:
    section.add "X-Amz-Date", valid_604561
  var valid_604562 = header.getOrDefault("X-Amz-Security-Token")
  valid_604562 = validateParameter(valid_604562, JString, required = false,
                                 default = nil)
  if valid_604562 != nil:
    section.add "X-Amz-Security-Token", valid_604562
  var valid_604563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604563 = validateParameter(valid_604563, JString, required = false,
                                 default = nil)
  if valid_604563 != nil:
    section.add "X-Amz-Content-Sha256", valid_604563
  var valid_604564 = header.getOrDefault("X-Amz-Algorithm")
  valid_604564 = validateParameter(valid_604564, JString, required = false,
                                 default = nil)
  if valid_604564 != nil:
    section.add "X-Amz-Algorithm", valid_604564
  var valid_604565 = header.getOrDefault("X-Amz-Signature")
  valid_604565 = validateParameter(valid_604565, JString, required = false,
                                 default = nil)
  if valid_604565 != nil:
    section.add "X-Amz-Signature", valid_604565
  var valid_604566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604566 = validateParameter(valid_604566, JString, required = false,
                                 default = nil)
  if valid_604566 != nil:
    section.add "X-Amz-SignedHeaders", valid_604566
  var valid_604567 = header.getOrDefault("X-Amz-Credential")
  valid_604567 = validateParameter(valid_604567, JString, required = false,
                                 default = nil)
  if valid_604567 != nil:
    section.add "X-Amz-Credential", valid_604567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604568: Call_GetRestoreDBClusterToPointInTime_604545;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_604568.validator(path, query, header, formData, body)
  let scheme = call_604568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604568.url(scheme.get, call_604568.host, call_604568.base,
                         call_604568.route, valid.getOrDefault("path"))
  result = hook(call_604568, url, valid)

proc call*(call_604569: Call_GetRestoreDBClusterToPointInTime_604545;
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
  var query_604570 = newJObject()
  add(query_604570, "RestoreToTime", newJString(RestoreToTime))
  add(query_604570, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_604570.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_604570.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_604570.add "Tags", Tags
  add(query_604570, "DeletionProtection", newJBool(DeletionProtection))
  add(query_604570, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_604570, "Action", newJString(Action))
  add(query_604570, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604570, "KmsKeyId", newJString(KmsKeyId))
  add(query_604570, "Port", newJInt(Port))
  add(query_604570, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(query_604570, "Version", newJString(Version))
  result = call_604569.call(nil, query_604570, nil, nil, nil)

var getRestoreDBClusterToPointInTime* = Call_GetRestoreDBClusterToPointInTime_604545(
    name: "getRestoreDBClusterToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_GetRestoreDBClusterToPointInTime_604546, base: "/",
    url: url_GetRestoreDBClusterToPointInTime_604547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStartDBCluster_604614 = ref object of OpenApiRestCall_602417
proc url_PostStartDBCluster_604616(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostStartDBCluster_604615(path: JsonNode; query: JsonNode;
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
  var valid_604617 = query.getOrDefault("Action")
  valid_604617 = validateParameter(valid_604617, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_604617 != nil:
    section.add "Action", valid_604617
  var valid_604618 = query.getOrDefault("Version")
  valid_604618 = validateParameter(valid_604618, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604618 != nil:
    section.add "Version", valid_604618
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604619 = header.getOrDefault("X-Amz-Date")
  valid_604619 = validateParameter(valid_604619, JString, required = false,
                                 default = nil)
  if valid_604619 != nil:
    section.add "X-Amz-Date", valid_604619
  var valid_604620 = header.getOrDefault("X-Amz-Security-Token")
  valid_604620 = validateParameter(valid_604620, JString, required = false,
                                 default = nil)
  if valid_604620 != nil:
    section.add "X-Amz-Security-Token", valid_604620
  var valid_604621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604621 = validateParameter(valid_604621, JString, required = false,
                                 default = nil)
  if valid_604621 != nil:
    section.add "X-Amz-Content-Sha256", valid_604621
  var valid_604622 = header.getOrDefault("X-Amz-Algorithm")
  valid_604622 = validateParameter(valid_604622, JString, required = false,
                                 default = nil)
  if valid_604622 != nil:
    section.add "X-Amz-Algorithm", valid_604622
  var valid_604623 = header.getOrDefault("X-Amz-Signature")
  valid_604623 = validateParameter(valid_604623, JString, required = false,
                                 default = nil)
  if valid_604623 != nil:
    section.add "X-Amz-Signature", valid_604623
  var valid_604624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604624 = validateParameter(valid_604624, JString, required = false,
                                 default = nil)
  if valid_604624 != nil:
    section.add "X-Amz-SignedHeaders", valid_604624
  var valid_604625 = header.getOrDefault("X-Amz-Credential")
  valid_604625 = validateParameter(valid_604625, JString, required = false,
                                 default = nil)
  if valid_604625 != nil:
    section.add "X-Amz-Credential", valid_604625
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_604626 = formData.getOrDefault("DBClusterIdentifier")
  valid_604626 = validateParameter(valid_604626, JString, required = true,
                                 default = nil)
  if valid_604626 != nil:
    section.add "DBClusterIdentifier", valid_604626
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604627: Call_PostStartDBCluster_604614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_604627.validator(path, query, header, formData, body)
  let scheme = call_604627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604627.url(scheme.get, call_604627.host, call_604627.base,
                         call_604627.route, valid.getOrDefault("path"))
  result = hook(call_604627, url, valid)

proc call*(call_604628: Call_PostStartDBCluster_604614;
          DBClusterIdentifier: string; Action: string = "StartDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## postStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_604629 = newJObject()
  var formData_604630 = newJObject()
  add(query_604629, "Action", newJString(Action))
  add(formData_604630, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604629, "Version", newJString(Version))
  result = call_604628.call(nil, query_604629, nil, formData_604630, nil)

var postStartDBCluster* = Call_PostStartDBCluster_604614(
    name: "postStartDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=StartDBCluster",
    validator: validate_PostStartDBCluster_604615, base: "/",
    url: url_PostStartDBCluster_604616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStartDBCluster_604598 = ref object of OpenApiRestCall_602417
proc url_GetStartDBCluster_604600(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetStartDBCluster_604599(path: JsonNode; query: JsonNode;
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
  var valid_604601 = query.getOrDefault("DBClusterIdentifier")
  valid_604601 = validateParameter(valid_604601, JString, required = true,
                                 default = nil)
  if valid_604601 != nil:
    section.add "DBClusterIdentifier", valid_604601
  var valid_604602 = query.getOrDefault("Action")
  valid_604602 = validateParameter(valid_604602, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_604602 != nil:
    section.add "Action", valid_604602
  var valid_604603 = query.getOrDefault("Version")
  valid_604603 = validateParameter(valid_604603, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604603 != nil:
    section.add "Version", valid_604603
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604604 = header.getOrDefault("X-Amz-Date")
  valid_604604 = validateParameter(valid_604604, JString, required = false,
                                 default = nil)
  if valid_604604 != nil:
    section.add "X-Amz-Date", valid_604604
  var valid_604605 = header.getOrDefault("X-Amz-Security-Token")
  valid_604605 = validateParameter(valid_604605, JString, required = false,
                                 default = nil)
  if valid_604605 != nil:
    section.add "X-Amz-Security-Token", valid_604605
  var valid_604606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604606 = validateParameter(valid_604606, JString, required = false,
                                 default = nil)
  if valid_604606 != nil:
    section.add "X-Amz-Content-Sha256", valid_604606
  var valid_604607 = header.getOrDefault("X-Amz-Algorithm")
  valid_604607 = validateParameter(valid_604607, JString, required = false,
                                 default = nil)
  if valid_604607 != nil:
    section.add "X-Amz-Algorithm", valid_604607
  var valid_604608 = header.getOrDefault("X-Amz-Signature")
  valid_604608 = validateParameter(valid_604608, JString, required = false,
                                 default = nil)
  if valid_604608 != nil:
    section.add "X-Amz-Signature", valid_604608
  var valid_604609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604609 = validateParameter(valid_604609, JString, required = false,
                                 default = nil)
  if valid_604609 != nil:
    section.add "X-Amz-SignedHeaders", valid_604609
  var valid_604610 = header.getOrDefault("X-Amz-Credential")
  valid_604610 = validateParameter(valid_604610, JString, required = false,
                                 default = nil)
  if valid_604610 != nil:
    section.add "X-Amz-Credential", valid_604610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604611: Call_GetStartDBCluster_604598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_604611.validator(path, query, header, formData, body)
  let scheme = call_604611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604611.url(scheme.get, call_604611.host, call_604611.base,
                         call_604611.route, valid.getOrDefault("path"))
  result = hook(call_604611, url, valid)

proc call*(call_604612: Call_GetStartDBCluster_604598; DBClusterIdentifier: string;
          Action: string = "StartDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604613 = newJObject()
  add(query_604613, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604613, "Action", newJString(Action))
  add(query_604613, "Version", newJString(Version))
  result = call_604612.call(nil, query_604613, nil, nil, nil)

var getStartDBCluster* = Call_GetStartDBCluster_604598(name: "getStartDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StartDBCluster", validator: validate_GetStartDBCluster_604599,
    base: "/", url: url_GetStartDBCluster_604600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStopDBCluster_604647 = ref object of OpenApiRestCall_602417
proc url_PostStopDBCluster_604649(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostStopDBCluster_604648(path: JsonNode; query: JsonNode;
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
  var valid_604650 = query.getOrDefault("Action")
  valid_604650 = validateParameter(valid_604650, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_604650 != nil:
    section.add "Action", valid_604650
  var valid_604651 = query.getOrDefault("Version")
  valid_604651 = validateParameter(valid_604651, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604651 != nil:
    section.add "Version", valid_604651
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604652 = header.getOrDefault("X-Amz-Date")
  valid_604652 = validateParameter(valid_604652, JString, required = false,
                                 default = nil)
  if valid_604652 != nil:
    section.add "X-Amz-Date", valid_604652
  var valid_604653 = header.getOrDefault("X-Amz-Security-Token")
  valid_604653 = validateParameter(valid_604653, JString, required = false,
                                 default = nil)
  if valid_604653 != nil:
    section.add "X-Amz-Security-Token", valid_604653
  var valid_604654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604654 = validateParameter(valid_604654, JString, required = false,
                                 default = nil)
  if valid_604654 != nil:
    section.add "X-Amz-Content-Sha256", valid_604654
  var valid_604655 = header.getOrDefault("X-Amz-Algorithm")
  valid_604655 = validateParameter(valid_604655, JString, required = false,
                                 default = nil)
  if valid_604655 != nil:
    section.add "X-Amz-Algorithm", valid_604655
  var valid_604656 = header.getOrDefault("X-Amz-Signature")
  valid_604656 = validateParameter(valid_604656, JString, required = false,
                                 default = nil)
  if valid_604656 != nil:
    section.add "X-Amz-Signature", valid_604656
  var valid_604657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604657 = validateParameter(valid_604657, JString, required = false,
                                 default = nil)
  if valid_604657 != nil:
    section.add "X-Amz-SignedHeaders", valid_604657
  var valid_604658 = header.getOrDefault("X-Amz-Credential")
  valid_604658 = validateParameter(valid_604658, JString, required = false,
                                 default = nil)
  if valid_604658 != nil:
    section.add "X-Amz-Credential", valid_604658
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_604659 = formData.getOrDefault("DBClusterIdentifier")
  valid_604659 = validateParameter(valid_604659, JString, required = true,
                                 default = nil)
  if valid_604659 != nil:
    section.add "DBClusterIdentifier", valid_604659
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604660: Call_PostStopDBCluster_604647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_604660.validator(path, query, header, formData, body)
  let scheme = call_604660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604660.url(scheme.get, call_604660.host, call_604660.base,
                         call_604660.route, valid.getOrDefault("path"))
  result = hook(call_604660, url, valid)

proc call*(call_604661: Call_PostStopDBCluster_604647; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## postStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_604662 = newJObject()
  var formData_604663 = newJObject()
  add(query_604662, "Action", newJString(Action))
  add(formData_604663, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604662, "Version", newJString(Version))
  result = call_604661.call(nil, query_604662, nil, formData_604663, nil)

var postStopDBCluster* = Call_PostStopDBCluster_604647(name: "postStopDBCluster",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_PostStopDBCluster_604648,
    base: "/", url: url_PostStopDBCluster_604649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStopDBCluster_604631 = ref object of OpenApiRestCall_602417
proc url_GetStopDBCluster_604633(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetStopDBCluster_604632(path: JsonNode; query: JsonNode;
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
  var valid_604634 = query.getOrDefault("DBClusterIdentifier")
  valid_604634 = validateParameter(valid_604634, JString, required = true,
                                 default = nil)
  if valid_604634 != nil:
    section.add "DBClusterIdentifier", valid_604634
  var valid_604635 = query.getOrDefault("Action")
  valid_604635 = validateParameter(valid_604635, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_604635 != nil:
    section.add "Action", valid_604635
  var valid_604636 = query.getOrDefault("Version")
  valid_604636 = validateParameter(valid_604636, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_604636 != nil:
    section.add "Version", valid_604636
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604637 = header.getOrDefault("X-Amz-Date")
  valid_604637 = validateParameter(valid_604637, JString, required = false,
                                 default = nil)
  if valid_604637 != nil:
    section.add "X-Amz-Date", valid_604637
  var valid_604638 = header.getOrDefault("X-Amz-Security-Token")
  valid_604638 = validateParameter(valid_604638, JString, required = false,
                                 default = nil)
  if valid_604638 != nil:
    section.add "X-Amz-Security-Token", valid_604638
  var valid_604639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604639 = validateParameter(valid_604639, JString, required = false,
                                 default = nil)
  if valid_604639 != nil:
    section.add "X-Amz-Content-Sha256", valid_604639
  var valid_604640 = header.getOrDefault("X-Amz-Algorithm")
  valid_604640 = validateParameter(valid_604640, JString, required = false,
                                 default = nil)
  if valid_604640 != nil:
    section.add "X-Amz-Algorithm", valid_604640
  var valid_604641 = header.getOrDefault("X-Amz-Signature")
  valid_604641 = validateParameter(valid_604641, JString, required = false,
                                 default = nil)
  if valid_604641 != nil:
    section.add "X-Amz-Signature", valid_604641
  var valid_604642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604642 = validateParameter(valid_604642, JString, required = false,
                                 default = nil)
  if valid_604642 != nil:
    section.add "X-Amz-SignedHeaders", valid_604642
  var valid_604643 = header.getOrDefault("X-Amz-Credential")
  valid_604643 = validateParameter(valid_604643, JString, required = false,
                                 default = nil)
  if valid_604643 != nil:
    section.add "X-Amz-Credential", valid_604643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604644: Call_GetStopDBCluster_604631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_604644.validator(path, query, header, formData, body)
  let scheme = call_604644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604644.url(scheme.get, call_604644.host, call_604644.base,
                         call_604644.route, valid.getOrDefault("path"))
  result = hook(call_604644, url, valid)

proc call*(call_604645: Call_GetStopDBCluster_604631; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604646 = newJObject()
  add(query_604646, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_604646, "Action", newJString(Action))
  add(query_604646, "Version", newJString(Version))
  result = call_604645.call(nil, query_604646, nil, nil, nil)

var getStopDBCluster* = Call_GetStopDBCluster_604631(name: "getStopDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_GetStopDBCluster_604632,
    base: "/", url: url_GetStopDBCluster_604633,
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

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
